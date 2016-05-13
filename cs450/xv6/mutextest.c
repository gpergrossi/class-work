//#include <stdlib.h>
//#include <stdio.h>
#include "types.h"
#include "user.h"
#include "syscall.h"

int counter = 0;

void threadfunc(void *arg) {
    //int imutex = *((int*) arg);

    mtx_lock(imutex);

    int read = counter; // Read
    sleep(1);           // Pause
    counter = read + 1; // Write

    printf(1, "lock acquired, counter = %d\n", counter);

    mtx_unlock(imutex);

    exit();
}

int main(int argc, char *argv[]) {    
    int NUM_THREADS = 60;
    int STACK_SIZE = 2048;

    //void *stackmem = malloc(STACK_SIZE*NUM_THREADS);
    //void *stacks[NUM_THREADS];
    
    int imutex = mtx_create(0);
 
    printf(1, "parent starting %d threads...\n", NUM_THREADS);
    
    int i;
    for (i = 0; i < NUM_THREADS; i++) {
        void *stack = malloc(STACK_SIZE);
        int thread_id = thread_create(&threadfunc, stack, &imutex);
        printf(1, "spawned thread %d\n", thread_id);
    }

    printf(1, "parent joining threads...\n");

    int thread_id;
    while ((thread_id = thread_join((void **)0)) != -1) {
        printf(1, "joined thread %d\n", thread_id);
    }
    
    printf(1, "parent closing, counter = %d\n", counter);

    exit();
}


