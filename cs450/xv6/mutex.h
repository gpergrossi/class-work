// Mutex
enum mutexstate { UNCLAIMED, CLAIMED };

struct mutex {
  uint locked;       // Is the lock held?
  enum mutexstate state;
};

//void            acquirem(struct mutex*);
//void            releasem(struct mutex*);

