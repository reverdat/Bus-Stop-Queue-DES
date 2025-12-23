import numpy as np

def generate_Q_matrix(n, x, lam, mu):
     # Genera la matriu Q. Com que el problma és tan senzill, generem el grafic directament
    q = np.zeros((n, n))
    
    # add lambdas to the next element over the diagonal
    for i in range(n-1):
        q[i, i+1] = lam
    
    # add mus. start at 1 due to row zero not having anything similar
    for i in range(1, n):
        j = max(0, i-x)
        q[i, j] = mu
    
    # compute the diagonal
    for i in range(n):
        diagonal = np
        suma_sortides = np.sum(q[i, :])
        q[i, i] = -suma_sortides
    
    return q

"""
Computes the average passangers (L) with a closed formula
"""
def mmx1k_solver(lam, mu, x, k):
    q = generate_Q_matrix(k+1, x, lam, mu)
    print("Matrix Q")
    print(np.round(q, 2))

    b = np.zeros(k+1)
    
    # condició sum_(i=0)^inf P_i = 1
    q[:, -1] = 1 # last COLUMN all ones (we later transpose it, so will end up as a row :)
    b[-1] = 1 # b vector all ones
    
    print("Matrix Q^T")
    print(q.T)
    # Solve Q^T P = 0
    p = np.linalg.solve(q.T, b) #thank you numpy

    print("Stationary State Probability:")
    print(''.join([f"p_{i}: {prob:.4f}\n" for i, prob in enumerate(p)]))
    print(f"\nTotal probability sum: {np.sum(p):.4f}")

    l = sum(i * p[i] for i in range(k+1))
    
    return l


if __name__ == "__main__":
    k = 9            # capacitat del sistema (estats 0..9)
    x = 3            # mida del lot de servei
    lam = 5.0        # tasa d'arribades (lambda)
    mu = 4.0         # tasa de servei (mu)

    result = mmx1k_solver(lam, mu, x, k)

    print(f"(Result) L = {result:.4f}")
