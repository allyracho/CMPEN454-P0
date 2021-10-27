import time
import sys

from dask.distributed import Client
from dask import delayed

def increment(x, sleeptime=1):
    ''' returns 1+x after sleeping '''
    print(f"I am about to increment {x}")
    time.sleep(sleeptime)
    return x+1

def add(x, y, sleeptime=1):
    '''returns x+y after sleeping '''
    print(f"going to add {x} and {y}")
    time.sleep(sleeptime)
    return x+y

@delayed
# delayed decorator 
def double(x, sleeptime=1):
    "returns 2x after sleeping"
    time.sleep(sleeptime)
    return 2*x

def serial():
    ''' computes (1+1) + (2+1) serially (each operation performed after the other'''
    start = time.perf_counter()
    x = increment(1)
    y = increment(2)
    z = add(x,y)
    end = time.perf_counter()
    print(f"the result is {z}")
    print(f"Computation time: {end-start}")

def parallel():
    c = Client(n_workers = 4)
    setup_start = time.perf_counter() # begin time for setting up the computation graph
    x = delayed(increment)(1)
    y = delayed(increment)(2)
    z = delayed(add)(x+y)
    setup_end = time.perf_counter() # end time for setting up the computation grpah
    print(f"Setup time: {setup_end - setup_start}")
    z.visualize("z-visualize.png")
    start = time.perf_counter() # start time for computation 
    result = z.compute() # compute the value of z
    end = time.perf_counter() # end time for computation 
    print(f"The result is {result}")
    print(f"Computation time: {end-start}")
    c.close()
    return z

def loopy(n, version = 0):
    ''' going to add up the increments of the first n numbers '''
    c = Client(n_workers = 4)
    operations = [delayed(increment)(i) for i in range(n)]
    if version == 0:
        z = delayed(sum)(operations)
    else:
        z = sum(operations)
    z.visualize("loopyz.png")
    start = time.perf_counter()
    result = z.compute()
    end = time.perf_counter()
    print(f"The result is {result}")
    print(f"Computation time: {end - start}")

def control(n):
    c = Client(n_workers=n)
    operations = [delayed(increment)(i) if i % 2 == 0 else double(i) for i in range(n)]
    z = delayed(sum)(operations)
    z.visualize("control.png")
    start = time.perf_counter()
    result = z.compute()
    end = time.perf_counter()
    print(f'The result is {result}')
    print(f'Computation time: {end-start}')
    c.close()

def explore_graph():
    c = Client(n_workers = 4)
    x = delayed(increment)(1)
    y = delayed(increment)(2)
    z = delayed(add)(x,y)
    result = z.compute()
    c.close()
    return z











