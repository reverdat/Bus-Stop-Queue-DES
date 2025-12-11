#    Step 1: Open Command Prompt. Press “Window+R” to open the “Run” box and type “cmd” in the drop-down menu to open Command Prompt:
#    Step 2: Move to Python Script Directory. Execute the “cd” command and also define a path where the Python script is placed: ...
#    Step 3: Run Python Script. (p.ex:  > python m.py)
#    This runs the script showing output on the MS-DOS window, and the window does not disappear
#    If showing output on the window is not required, then simply double-click on the .py
#     Files with extension .pyw  do not issue a (vanishing) command window

def claveSORT(A):
	return A[1]

def TServei(mu0):
	u = rn.random()
	t = -(1/mu0)*math.log(u)
	return t

def TArribada(landa0):
	u = rn.random()
	t = -(1/landa0)*math.log(u)
	return t

def Arribada(Ev0, it, ncli):
	global tCK, EvL, N, S, landa, mu
	N = N + 1
	if S == 'libre':
		S = 'ocup'
		tservei = TServei(mu) # Hay que generar salida
		EvS = ('S',tCK + tservei, it, ncli)
		EvL.append(EvS)   # se añade al final de la lista
		EvL.sort(key=claveSORT, reverse=False) # se reordena EvL 
		
#	if S == 'ocup':
	# Se genera nueva llegada
	tArr  = TArribada(landa) 
	EvA = ('A',tCK + tArr, it, ncli+1)
	EvL.append(EvA)
	EvL.sort(key=claveSORT, reverse=False) # se reordena EvL 	

def FiServei(Ev1, it):
	global tCK, EvL, N, S, landa, mu
	N = N - 1
	if N == 0:
		S = 'libre'
	if N > 0:
		tservei = TServei(mu)
		# En caso de volver a quedar ocupado el servidor 
		# por no haber cola vacía, entonces, como se supone FIFO,
		# el nuevo servicio se supone que corresponde al siguiente cliente 
		# del que salió.
		EvS = ('S', tCK + tservei, it, Ev1[3]+1)
		EvL.append(EvS)   # se añade al final de la lista
		EvL.sort(key=claveSORT, reverse=False) # se reordena EvL 

# Código Python para simulación 
# de una M/M/1 usando Event-Scheduling (el registro de clientes supone FIFO)
import math
import random as rn
#Inicialización de la lista de eventos.
#Posiciones:
#0  = tipo de suceso
#1  = instante en el que se da
#2  = Iteración en el que se genera (=identificador de suceso)
#3  = Identificador de cliente al que corresponde

ncliente= 1
EvL =[('A',0.0,0,ncliente)]
N = 0                   # Número de clientes   
S = 'libre'             # Estado del servidor: 'libre' o 'ocup'
tCK = 0
nseed = 42924
rn.seed(nseed)
landa = 0.333333333
mu = 1
j = 1
T =1000000

L = 0
Lt = 0

while tCK < T:
#	print('j=', j, ' *********************')
	tCK0 = tCK
	N0 = N
	Ev = EvL[0]
	tCK = Ev[1]
#	print(EvL, 'cliente = ', Ev[3], 'servidor =', S, ' N = ', N)
	if Ev[0] == 'A': 
		Arribada(Ev, j, ncliente)
		ncliente = ncliente + 1
	if Ev[0] == 'S': FiServei(Ev, j)
	del EvL[0]

	if j > 1:
		L = L + N0*(tCK - tCK0)
		Lt = L/tCK  # Se supone inicio en t=0
		
#	print(EvL, 'SUCESO  =  ', Ev[0], 'servidor =', S, ' N = ', N, 'L(t)=', Lt)
	j = j+1
#	print('  ')
print(Lt, j-1)

	



		
