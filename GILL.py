#    Step 1: Open Command Prompt. Press “Window+R” to open the “Run” box and type “cmd” in the drop-down menu to open Command Prompt:
#    Step 2: Move to Python Script Directory. Execute the “cd” command and also define a path where the Python script is placed: ...
#    Step 3: Run Python Script. (p.ex:  > python m.py)
#    This runs the script showing output on the MS-DOS window, and the window does not disappear
#    If showing output on the window is not required, then simply double-click on the .py
#     Files with extension .pyw  do not issue a (vanishing) command window
import math
import random as rn
#import numpy as np

def h(a,theta,t):
	Tpax = 5  # tiempo entre subida y subida de un pax en segundos
	landaB = 1/300 #tasa de llegada de buses en seg^-1 (1 cada 5 minutos)
	landaP = 1/60  #tasa de llegada de pax. en seg^-1 (1 cada minuto)
	MM = 10000000 # Maxinteger
	if a=='A': hh = landaP
	if a=='B': hh = landaB
	if a=='C': 
		hh = 0
		if t >= Tpax - theta:
			hh = MM
	return hh
	  
st = {'nus':0, 'cap':0}  # diccionario que implementa la variable de estado. Se parte de (0,0)

#  F lista de fuentes A,B,C. Para cada una se especifica 
#  su memoria y si está activa (1) o no (0)

F = [{'nom':'A','mem': 0.0, 'act':1}, {'nom':'B','mem': 0.0, 'act':1}, {'nom':'C','mem': 0.0, 'act':0} ]
tCK =0
j = 1  # contador de transiciones
Tpx = 5 # deberà manternerse siempre igual a Tpax de la function h

rn.seed(23526)
   
while j < 50:
	st0 = st # estado anterior
	u = rn.random()  # se genera u~unif[0,1] para el deltat del siguiente suceso
	print('j = ',j,' ######################################################')
	print('\t\t', F)
	H = 0
	for Font in F:
		if Font['act'] == 1 and Font['nom'] != 'C': 
			H = H + h(Font['nom'],Font['mem'],0) #se acumula H para las fuentes activas
			                                     #se parte de deltat =0           
			print('\t\t', 'u = ',u, h(Font['nom'],Font['mem'],0), H)
	deltat = -(1/H)*math.log(u)                  #tentativa inicial para deltat   
	#
	#   Si se quiere un valor mejor de deltat implementar método de la tangente en este punto.
	#
	u2 = rn.random() # se genera u~unif[0,1] para saber qué suceso
	Pi = 0
	flagP = 0
	j1 = 0    # contador de fuentes en la lista de Fuentes
	trans =''
	if F[2]['act'] == 1:
		H = H + h('C',F[2]['mem'],deltat)
		if deltat + F[2]['mem']> Tpx: deltat =  Tpx - F[2]['mem']
#		if deltat > Tpx: deltat =  Tpx
	for Font in F:
		if Font['act'] == 1: 
			h1 = h(Font['nom'],Font['mem'],deltat)   # se calcula la función de azar, h, en theta+deltat
			Pi = Pi + h1/H
			print ('\t\t', 'u2= ',u2, H, Pi, h1/H)
			if Pi > u2 and flagP == 0: 
				flagP = 1
				trans = Font['nom']
				j2 = j1     # elemento de la lista de fuentes que resulta elegida
			j1 = j1 + 1
	for Font in F:   # se incrementa la memoria de las fuentes activas
		if Font['act'] == 1:
			Font['mem'] = Font['mem'] + deltat 
#
#	reset de la memoria de la fuente que ha salido elegida
# 
	F[j2]['mem'] = 0  # 
#     
#  implementar el cambio de estado de acuerdo con trans 
#  y activar/desactivar fuentes
#
	if F[j2]['nom'] =='A': st['nus']=st['nus']+1
	if F[j2]['nom'] =='B' and st['cap']==0 and st['nus'] > 0: # llega un bus con (n,0)
		c=3               #se genera la capacidad de bus
		st['cap'] = c    # cambio de estado
		F[2]['act'] = 1   # activación de la fuente C (con índice =2)
		F[2]['mem'] = 0.0 # conlleva poner a 0 su memoria
	if F[j2]['nom'] =='C': 
		st['nus']=st['nus']-1
		st['cap']=st['cap']-1
		if st['nus'] == 0: st['cap']= 0 # un estado (0,m) conduce immediatamente al (0,0)
		if st['cap'] == 0: F[2]['act'] = 0 # si no queda capacidad para nadie más, se desactiva la subida (C)
	j = j+1
#   traza 
	print("deltat",deltat, '\t\t' "I=", tCK, st0, "\t Ev=", F[j2]['nom'], '\t\t', "J=", tCK + deltat, st)
	tCK = tCK + deltat  

	
   

