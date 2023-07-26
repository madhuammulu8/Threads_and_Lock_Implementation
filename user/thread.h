struct  lock_t
{
    uint unlocked;
};
typedef struct lock_t lock_t;  
int thread_create(void *(*thread_fn)(void*), void *arg);
void lock_init(lock_t *lock);
void lock_acquire(lock_t *);
void lock_release(lock_t *);