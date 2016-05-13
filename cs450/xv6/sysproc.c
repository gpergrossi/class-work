#include "types.h"
#include "x86.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
  return fork();
}

int
sys_exit(void)
{
  exit();
  return 0;  // not reached
}

int
sys_wait(void)
{
  return wait();
}

int
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

int
sys_getpid(void)
{
  return proc->pid;
}

int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

int
sys_sleep(void)
{
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(proc->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

// return how many clock tick interrupts have occurred since start.
int
sys_uptime(void)
{
  uint xticks;
  
  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// CS 450
// return how many calls to the given syscall (by ID) occurred since start
int
sys_getcount(void)
{
  int n;
  argint(0, &n); // get argument syscall ID

  if (n < 0 || n >= NELEM(proc->callcounts))
    return -1;

  return proc->callcounts[n];
}

int
sys_thread_create(void)
{
  void (*tmain)(void*);
  void *stack;
  void *arg;

  argint(0, (int *) &(tmain)); // int is same size as pointer
  argint(1, (int *) &(stack));
  argint(2, (int *) &(arg));


  //if (tmain == 0 || stack == 0)
  //  return -1;

  return thread_create(tmain, stack, arg);
}

int
sys_thread_join(void)
{
  void **stack;

  argint(0, (int *) &stack);

  //if (stack == 0)
  //  return -1;

  return thread_join(stack);
}

int 
sys_mtx_create(void)
{
  int locked;
  argint(0, &locked);
  return mtx_create(locked);
}

int
sys_mtx_lock(void)
{
  int lock_id;
  argint(0, &lock_id);
  return mtx_lock(lock_id);
}


int
sys_mtx_unlock(void)
{
  int lock_id;
  argint(0, &lock_id);
  return mtx_unlock(lock_id);
}
