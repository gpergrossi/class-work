from threading import Thread, Semaphore
from time import sleep
from timeit import Timer
import sys
import random
import logging

# Setup Log File
logging.basicConfig(filename='output.log',level=logging.DEBUG)

# Parameters
num_philosophers = 10
num_meals_each = 200
repetitions = 100     # Repetitions * Meals = real total (Logged seperately in case of error)

# All
def left(i): return i
def right(i): return (i + 1) % num_philosophers

# Basic, Footman, & Lefty
forks = [Semaphore(1) for i in range(num_philosophers)]

# Footman
footman = Semaphore(num_philosophers-1)
eaters = 0
eaters_mutex = Semaphore(1)

# Tanenbaum
state = ['thinking'] * num_philosophers
sem = [Semaphore(0) for i in range(num_philosophers)]
mutex = Semaphore(1)
def t_left(i): return (i + num_philosophers - 1) % num_philosophers
def t_right(i): return (i + 1) % num_philosophers
def test(id):
  if state[id] == 'hungry' \
    and state[t_left(id)] != 'eating' \
    and state[t_right(id)] != 'eating':
      state[id] = 'eating'
      sem[id].release()      # this signals me OR a neighbor


print_mutex = Semaphore(1)
def atomic_print(*args):
    print_mutex.acquire()
    print(*args)
    sys.stdout.flush()
    print_mutex.release()

class Philosopher:
  def __init__(self, id):
    self.id = id
    self.meals = 0
    self.rng = random.Random()
    self.rng.seed(id*id+167*id)
  def start(self):
    self.meals = 0
    self.thread = Thread(target=Philosopher.run, args=[self])
    self.thread.setDaemon(True)
    self.thread.start()
  def join(self):
    self.thread.join()
  def run(self):
    while self.meals < num_meals_each:
      # atomic_print("Philosopher", self.id, "is waiting for forks") ##
      self.get_forks()
      self.meals += 1
      #atomic_print("Philosopher", self.id, "is eating (",self.meals,"/",num_meals_each,")") ##
      sys.stdout.write(".")
      sleep(self.rng.random()*0.1)
      self.put_forks()
      # atomic_print("Philosopher", self.id, "is thinking...") ##
      sleep(self.rng.random()*0.1)
  def get_forks(self):
    global eaters
    forks[right(self.id)].acquire()
    forks[left(self.id)].acquire()
    eaters_mutex.acquire()
    eaters += 1
    print(eaters)
    eaters_mutex.release()
  def put_forks(self):
    global eaters
    eaters_mutex.acquire()
    eaters -= 1
    eaters_mutex.release()
    forks[right(self.id)].release()
    forks[left(self.id)].release()
    
class FootmanPhilosopher(Philosopher):
  def get_forks(self):
    #global eaters
    footman.acquire()
    forks[right(self.id)].acquire()
    forks[left(self.id)].acquire()
    #eaters_mutex.acquire()
    #eaters += 1
    #print(eaters)
    #eaters_mutex.release()
  def put_forks(self):
    #global eaters
    #eaters_mutex.acquire()
    #eaters -= 1
    #eaters_mutex.release()
    forks[right(self.id)].release()
    forks[left(self.id)].release()
    footman.release()
    
class LeftyPhilosopher(Philosopher):
  def get_forks(self):
    global eaters
    forks[left(self.id)].acquire()
    forks[right(self.id)].acquire()
    eaters_mutex.acquire()
    eaters += 1
    print(eaters)
    eaters_mutex.release()
  def put_forks(self):
    global eaters
    eaters_mutex.acquire()
    eaters -= 1
    eaters_mutex.release()
    forks[left(self.id)].release()
    forks[right(self.id)].release()
    
class TanenbaumPhilosopher(Philosopher):
  def get_forks(self):
    mutex.acquire()
    #atomic_print("Philosopher", self.id, "is hungry") #
    state[self.id] = 'hungry'
    test(self.id)             # check neighbors' states
    mutex.release()
    sem[self.id].acquire()    # wait on my own semaphore
    
  def put_forks(self):
    mutex.acquire()
    #atomic_print("Philosopher", self.id, "is thinking") #
    state[self.id] = 'thinking'
    test(t_right(self.id))      # signal neighbors if they can eat
    test(t_left(self.id))
    mutex.release()
        
def sim(philosophers):
  for philosopher in philosophers:
    philosopher.start()
  for philosopher in philosophers:
    philosopher.join()
  sys.stdout.write(';')


footmen = [FootmanPhilosopher(i) for i in range(num_philosophers)]
one_lefty = [Philosopher(i) for i in range(num_philosophers-1)]
one_lefty.append(LeftyPhilosopher(num_philosophers-1))
tanenbaums = [TanenbaumPhilosopher(i) for i in range(num_philosophers)]

def sim_footman(): sim(footmen)
def sim_lefty(): sim(one_lefty)
def sim_tanenbaum(): sim(tanenbaums)

if __name__ == '__main__':
  print("Running dining philosophers simulation:",\
          num_philosophers,"philosophers,",\
          num_meals_each,"meals each",\
          repetitions,"repetitions")
  logging.info("Running dining philosophers simulation: %d philosophers, %d meals each, %d repetitions" \
               % (num_philosophers, num_meals_each, repetitions))

  times = []
  timer = Timer(sim_footman)
  print("\n1. Footman solution, time elapsed:")
  logging.info("1. Footman solution, time elapsed:")
  for i in range(repetitions):
      time = timer.timeit(1)
      times.append(time)
      print("\n\tTime: {:0.3f}s".format(time))
      logging.info("\tTime: {:0.3f}s".format(time))
  averageA = sum(times) / float(len(times))
  print("1. Footman solution, average time:\t",\
          "{:0.3f}s".format(averageA))
  logging.info("1. Footman solution, average time:\t\
          {:0.3f}s".format(averageA))
  
  times = []
  timer = Timer(sim_lefty)
  print("\n2. Left-handed solution, time elapsed:")
  logging.info("2. Left-handed solution, time elapsed:")
  for i in range(repetitions):
      time = timer.timeit(1)
      times.append(time)
      print("\n\tTime: {:0.3f}s".format(time))
      logging.info("\tTime: {:0.3f}s".format(time))
  averageB = sum(times) / float(len(times))
  print("2. Left-handed solution, average time:\t",\
          "{:0.3f}s".format(averageB))
  logging.info("2. Left-handed solution, average time:\t\
          {:0.3f}s".format(averageB))

  times = []
  timer = Timer(sim_tanenbaum)
  print("\n3. Tanenbaum's solution, time elapsed:")
  logging.info("3. Tanenbaum's solution, time elapsed:")
  for i in range(repetitions):
      time = timer.timeit(1)
      times.append(time)
      print("\n\tTime: {:0.3f}s".format(time))
      logging.info("\tTime: {:0.3f}s".format(time))
  averageC = sum(times) / float(len(times))
  print("3. Tanenbaum's solution, average time:\t",\
          "{:0.3f}s".format(averageC))
  logging.info("3. Tanenbaum's solution, average time:\t\
          {:0.3f}s".format(averageC))

  print("Complete!")
  print("1. Footman solution, average time:\t",\
          "{:0.3f}s".format(averageA))
  print("2. Left-handed solution, average time:\t",\
          "{:0.3f}s".format(averageB))
  print("3. Tanenbaum's solution, average time:\t",\
          "{:0.3f}s".format(averageC))

  logging.info("Complete!")
  logging.info("1. Footman solution, average time:\t\
               {:0.3f}s".format(averageA))
  logging.info("2. Left-handed solution, average time:\t\
          {:0.3f}s".format(averageB))
  logging.info("3. Tanenbaum's solution, average time:\t\
          {:0.3f}s".format(averageC))
