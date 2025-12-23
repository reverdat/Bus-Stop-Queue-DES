import marimo

__generated_with = "0.16.5"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import scipy.stats as stats
    return (stats,)


@app.cell
def _(stats):
    x = [stats.poisson.rvs(3) for _ in range(20)]
    x
    return (x,)


@app.cell
def _(x):
    def ecdf(data, value) -> float:
        return sum(1 for x in data if x <= value)/len(data)

    ecdf(x, 4)
    return (ecdf,)


@app.cell
def _(ecdf, x):
    import numpy as np

    domain = np.unique(x)

    prob = [ecdf(x, i) for i in domain]
    print(prob)
    F = np.cumsum(prob)
    return F, domain


@app.cell
def _(F, domain):
    import matplotlib.pyplot as plt

    plt.hist(F, bins=len(domain))
    plt.show()
    return


@app.cell
def _():
    return


if __name__ == "__main__":
    app.run()
