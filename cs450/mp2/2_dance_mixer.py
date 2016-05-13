from threading import Thread, Semaphore
from time import sleep
from collections import deque
from itertools import cycle
import sys
import random


# Tunable parameters
number_of_leaders   = 2
number_of_followers = 5
dance_time_min = 2.0
dance_time_max = 3.0
dance_style_time = 5.0
dance_style_down_time = 2.0



# Utilities
class FIFOSemaphore:
    def __init__(self, val):
        self.val = val
        self.mutex = Semaphore(1)
        self.queue = deque()
    def acquire(self):
        barrier = Semaphore(0)
        block = False
        self.mutex.acquire()
        self.val -= 1
        if self.val < 0:
            self.queue.append(barrier)
            block = True
        self.mutex.release()
        if block:
            barrier.acquire()
    def release(self):
        self.mutex.acquire()
        self.val += 1
        if self.queue:
            barrier = self.queue.popleft()
            barrier.release()
        self.mutex.release()

print_mutex = Semaphore(1)
def atomic_print(*args):
    print_mutex.acquire()
    print(*args)
    sys.stdout.flush()
    print_mutex.release()



# Global variables
pairing_allowed = FIFOSemaphore(0)      # To control entry
pairing_leader_lock = FIFOSemaphore(1)  # For Exclusivity
pairing_follower_lock = FIFOSemaphore(1)
pairing_leader_ready = Semaphore(0)     # For Rendezvous
pairing_follower_ready = Semaphore(0)

pairing_leader_num = 0      # To communicate pairs
pairing_follower_num = 0

floor_empty = Semaphore(0)  # To keep track of dancers
floor_count = 0
floor_mutex = Semaphore(1)

running = True  # To allow the program to end Ctrl+C



def dancer(is_leader, id):
    global running, pairing_leader_num, pairing_follower_num, floor_count

    rng = random.Random()
    rng.seed(id*14327)

    type = "Follower"
    if is_leader:
        type = "Leader"
    
    while running:
        # Entry turnstile
        pairing_allowed.acquire()
        pairing_allowed.release()
        
        # Begin Pairing
        if is_leader:
            pairing_leader_lock.acquire()
            pairing_leader_num = id     # Doesn't need mutex because not read until after rendezvous
        else:
            pairing_follower_lock.acquire()
            pairing_follower_num = id   # Doesn't need mutex because not read until after rendezvous

        # Grab Partner
        if is_leader:
            pairing_leader_ready.release()      # Release Follower
            pairing_follower_ready.acquire()    # Wait for Follower
        else:
            pairing_follower_ready.release()    # Release Leader
            pairing_leader_ready.acquire()      # Wait for Leader

        # Enter Floor 
        floor_mutex.acquire()
        floor_count += 1
        atomic_print("[ Dancers:",floor_count,"]",type,id,"entering floor.")
        if floor_count == 1:
            floor_empty.acquire()
        floor_mutex.release()

        # Wait for Partner
        if is_leader:
            pairing_leader_ready.release()      # Release Follower
            pairing_follower_ready.acquire()    # Wait for Follower
        else:
            pairing_follower_ready.release()    # Release Leader
            pairing_leader_ready.acquire()      # Wait for Leader

        # Begin Dancing
        if is_leader:
            atomic_print("Leader",pairing_leader_num,"and Follower",pairing_follower_num,"are dancing.")
            pairing_leader_ready.release()      # Release Follower
        else:
            pairing_leader_ready.acquire()      # Wait for Leader
        
        # Pairing complete
        if is_leader:
            pairing_leader_lock.release()
        else:
            pairing_follower_lock.release()



        # Dance for some time
        sleep(dance_time_min + rng.random()*(dance_time_max - dance_time_min))

        # Leave (according to example, ignoring partner is acceptable)
        floor_mutex.acquire()
        floor_count -= 1
        atomic_print("[ Dancers:",floor_count,"]",type,id,"getting back in line.")
        if floor_count == 0:
            floor_empty.release()
        floor_mutex.release()

        

def band():
    global running
    for music in cycle(['walts', 'tango', 'foxtrot']):
        # Start Music
        atomic_print("** Band leader started playing",music,"**")

        # Open Floor for Dancing
        floor_empty.release()
        pairing_allowed.release()

        sleep(dance_style_time)

        # Begin Winding Down
        pairing_allowed.acquire()   # Allow no more pairs
        floor_empty.acquire()       # Wait for last dancers to finish

        # Stop Music
        atomic_print("** Band leader stopped playing",music,"**\n")
        sleep(dance_style_down_time)
        
        if not running:
            break


print("Beginning simulation")

# Start the leader threads
for i in range(number_of_leaders):
    t = Thread(target=dancer, args=[True,i])
    t.setDaemon(True)
    t.start()

# Start the follower threads
for i in range(number_of_followers):
    t = Thread(target=dancer, args=[False,i])
    t.setDaemon(True)
    t.start()

# Start the band thread            
tCart = Thread(target=band)
tCart.setDaemon(True)
tCart.start()
    
try:
    while running:
        sleep(1)
except KeyboardInterrupt:
    running = False

sys.exit(0)
print("...")
    
