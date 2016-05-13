from threading import Thread, Semaphore
from time import sleep
import sys
import random


# Tunable parameters
number_of_frolfers = 3
initial_stash_size = 20
discs_per_bucket   = 5


# Program code
collection_needed = Semaphore(0)
collection_completed = Semaphore(0)
bucket_request_mutex = Semaphore(1)
stash_mutex = Semaphore(1)
field_mutex = Semaphore(1)
print_mutex = Semaphore(1)

registration_mutex = Semaphore(1)
frolfer_locks = []

discs_in_stash = initial_stash_size
discs_on_field = 0

running = True


def atomic_print(*args):
    print_mutex.acquire()
    print(*args)
    sys.stdout.flush()
    print_mutex.release()


def frolfer(id):
    global discs_in_stash, discs_on_field, running
    
    # Initialization (Create thread-local lock, add to global list)
    local_lock = Semaphore(1)
    registration_mutex.acquire()
    frolfer_locks.append(local_lock)
    registration_mutex.release()

    rng = random.Random()
    rng.seed(id*14327)

    while running:
        # GET A BUCKET (One frolfer at a time)
        bucket_request_mutex.acquire()

        atomic_print("Frolfer",id,"calling for bucket")
        
        wait = False
            
        stash_mutex.acquire()
        if discs_in_stash < discs_per_bucket:
            wait = True
        else:
            discs_in_stash -= discs_per_bucket
        stash_mutex.release()

        if wait:
            collection_needed.release()
            collection_completed.acquire()
            stash_mutex.acquire()
            if discs_in_stash < discs_per_bucket:
                atomic_print("ERROR! Frolfer", id, "could not acquire a bucket after collection. ")
                atomic_print("       Stash =",discs_in_stash,"; Requesting ",discs_per_bucket)
                atomic_print("Frolfer",id,"thread stopped")
                running = False
                for lock in frolfer_locks:  # Acquire all frolfer locks (no more throws)
                    lock.acquire()
                sys.exit(1)
            else:
                discs_in_stash -= discs_per_bucket
                atomic_print("Frolfer", id, "got", discs_per_bucket, "discs; Stash =", discs_in_stash)
            stash_mutex.release()
                    
        bucket_request_mutex.release()

        # THROW DISCS
        for i in range(discs_per_bucket):
            local_lock.acquire()
            field_mutex.acquire()
            
            atomic_print("Frolfer",id,"threw disc",i)
            discs_on_field += 1
            
            field_mutex.release()
            local_lock.release()

            sleep(rng.random())
            if not running:
                atomic_print("Frolfer",id,"thread stopped")
                sys.exit(0)

            
def cart():
    global discs_in_stash, discs_on_field, running

    while running:
        collection_needed.acquire() # Only do this when requested
        if not running:
            atomic_print("Cart thread stopped")
            sys.exit(0)        
        registration_mutex.acquire()

        for lock in frolfer_locks:  # Acquire all frolfer locks
            lock.acquire()

        atomic_print("################################################################################")

        gathered = 0
        stash = 0

        stash_mutex.acquire()
        field_mutex.acquire()
        
        atomic_print("Stash =",discs_in_stash,"; Cart entering field")
        gathered = discs_on_field
        discs_in_stash += discs_on_field
        discs_on_field = 0
        stash = discs_in_stash
        
        stash_mutex.release()
        field_mutex.release()
        
        sys.stdout.write("Gathering")
        for i in range(gathered):
            sys.stdout.write(".")
            sleep(0.1)
        sys.stdout.write("\n")
            
        atomic_print("Cart done, gathered",gathered,"; Stash =",stash)


        atomic_print("################################################################################")

        for lock in frolfer_locks:  # Acquire all frolfer locks
            lock.release()

        registration_mutex.release()
        collection_completed.release() # Notify the waiting frolfer
    

print("Beginning simulation")


# Start the cart thread            
tCart = Thread(target=cart)
tCart.setDaemon(True)
tCart.start()

# Start the frolfer threads
for i in range(number_of_frolfers):
    t = Thread(target=frolfer, args=[i])
    t.setDaemon(True)
    t.start()
    
try:
    while running:
        sleep(1)
except KeyboardInterrupt:
    running = False

sleep(1)

print("...")
    
