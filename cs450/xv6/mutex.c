// Mutual exclusion spin locks.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "x86.h"
#include "memlayout.h"
#include "mmu.h"
#include "mutex.h"

// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquirem(struct mutex *mtx)
{
  int x = 1;
  while(x != 0) {
    //pushcli();
    x = xchg(&mtx->locked, 1);
    //popcli();
  }
}

// Release the lock.
void
releasem(struct mutex *mtx)
{
  //pushcli();
  xchg(&mtx->locked, 0);
  //popcli();
}

