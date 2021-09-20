from hwfunctions import fun_factor, fun_inc
from dask import delayed
from dask.distributed import wait

def delayed_increment(c, start, end):
    c = c
    x = delayed([fun_inc(i) for i in range(start, end)])
    result = x.compute()
    c.close()
    return(delayed(result))


def delayed_factor(c, start, end):
    c = c
    x = delayed([fun_factor(i) for i in range(start, end)])
    result = x.compute()
    c.close()
    return (delayed(result))


def future_increment(c, start, end):
    x = c.submit([fun_inc(i) for i in range(start, end)])
    wait(x)
    result = x.result()
    return(result)


def future_factor(c, start, end):
    x = c.submit([fun_factor(i) for i in range(start, end)])
    wait(x)
    result = x.result()
    return (result)

