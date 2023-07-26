#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/thread.h"
#include "kernel/spinlock.h"

int thread_create(void *(*thread_fn)(void*), void *arg) {
	int threadid;
	void* stack = (void*)malloc(4096 * sizeof(void));
	threadid  = clone(stack);
	if(threadid != 0) {
	}
    else{
    (*thread_fn) (arg);
	exit(0);
    }
	return 0;
}

//Lock implementation
void lock_init(lock_t *lock)
{
	lock->unlocked = 0;
}

void lock_acquire(lock_t *lock)
{
	while(__sync_lock_test_and_set(&lock->unlocked, 1) != 0);
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
	__sync_synchronize();
}
void lock_release(lock_t *lock)
{
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
	__sync_synchronize();
	  // Release the lock, equivalent to lk->locked = 0.
  // This code doesn't use a C assignment, since the C standard
  // implies that an assignment might be implemented with
  // multiple store instructions.
  // On RISC-V, sync_lock_release turns into an atomic swap:
  //   s1 = &lk->locked
  //   amoswap.w zero, zero, (s1)
	__sync_lock_release(&lock->unlocked,0);
}