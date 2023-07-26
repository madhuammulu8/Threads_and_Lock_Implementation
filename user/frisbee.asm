
user/_frisbee:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_fn>:
 
lock_t lock; 
int n_threads, n_passes, cur_turn, cur_pass; 
 
void* thread_fn(void *arg) 
{
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	e062                	sd	s8,0(sp)
  16:	0880                	addi	s0,sp,80
  int thread_id = (uint64)arg; 
  18:	00050a9b          	sext.w	s5,a0
  int done = 0; 
  while (!done) { 
    lock_acquire(&lock); 
  1c:	00001497          	auipc	s1,0x1
  20:	a9c48493          	addi	s1,s1,-1380 # ab8 <lock>
    if (cur_pass >= n_passes) done = 1; 
  24:	00001917          	auipc	s2,0x1
  28:	a8490913          	addi	s2,s2,-1404 # aa8 <cur_pass>
  2c:	00001997          	auipc	s3,0x1
  30:	a8498993          	addi	s3,s3,-1404 # ab0 <n_passes>
    else if (cur_turn == thread_id) { 
  34:	00001a17          	auipc	s4,0x1
  38:	a78a0a13          	addi	s4,s4,-1416 # aac <cur_turn>
      cur_turn = (cur_turn + 1) % n_threads; 
  3c:	00150b1b          	addiw	s6,a0,1
  40:	00001c17          	auipc	s8,0x1
  44:	a74c0c13          	addi	s8,s8,-1420 # ab4 <n_threads>
      printf("Round %d: thread %d is passing the token to thread %d\n",  
  48:	00001b97          	auipc	s7,0x1
  4c:	9a0b8b93          	addi	s7,s7,-1632 # 9e8 <lock_release+0x1a>
  50:	a825                	j	88 <thread_fn+0x88>
      cur_turn = (cur_turn + 1) % n_threads; 
  52:	000c2683          	lw	a3,0(s8)
  56:	02db66bb          	remw	a3,s6,a3
  5a:	00da2023          	sw	a3,0(s4)
      printf("Round %d: thread %d is passing the token to thread %d\n",  
  5e:	2585                	addiw	a1,a1,1
  60:	00b92023          	sw	a1,0(s2)
  64:	2681                	sext.w	a3,a3
  66:	8656                	mv	a2,s5
  68:	2581                	sext.w	a1,a1
  6a:	855e                	mv	a0,s7
  6c:	00000097          	auipc	ra,0x0
  70:	754080e7          	jalr	1876(ra) # 7c0 <printf>
        ++cur_pass, thread_id, cur_turn); 
    } 
    lock_release(&lock); 
  74:	8526                	mv	a0,s1
  76:	00001097          	auipc	ra,0x1
  7a:	958080e7          	jalr	-1704(ra) # 9ce <lock_release>
    sleep(0); 
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	450080e7          	jalr	1104(ra) # 4d0 <sleep>
    lock_acquire(&lock); 
  88:	8526                	mv	a0,s1
  8a:	00001097          	auipc	ra,0x1
  8e:	928080e7          	jalr	-1752(ra) # 9b2 <lock_acquire>
    if (cur_pass >= n_passes) done = 1; 
  92:	00092583          	lw	a1,0(s2)
  96:	0009a783          	lw	a5,0(s3)
  9a:	00f5d763          	bge	a1,a5,a8 <thread_fn+0xa8>
    else if (cur_turn == thread_id) { 
  9e:	000a2783          	lw	a5,0(s4)
  a2:	fd5799e3          	bne	a5,s5,74 <thread_fn+0x74>
  a6:	b775                	j	52 <thread_fn+0x52>
    lock_release(&lock); 
  a8:	00001517          	auipc	a0,0x1
  ac:	a1050513          	addi	a0,a0,-1520 # ab8 <lock>
  b0:	00001097          	auipc	ra,0x1
  b4:	91e080e7          	jalr	-1762(ra) # 9ce <lock_release>
    sleep(0); 
  b8:	4501                	li	a0,0
  ba:	00000097          	auipc	ra,0x0
  be:	416080e7          	jalr	1046(ra) # 4d0 <sleep>
  } 
  return 0; 
} 
  c2:	4501                	li	a0,0
  c4:	60a6                	ld	ra,72(sp)
  c6:	6406                	ld	s0,64(sp)
  c8:	74e2                	ld	s1,56(sp)
  ca:	7942                	ld	s2,48(sp)
  cc:	79a2                	ld	s3,40(sp)
  ce:	7a02                	ld	s4,32(sp)
  d0:	6ae2                	ld	s5,24(sp)
  d2:	6b42                	ld	s6,16(sp)
  d4:	6ba2                	ld	s7,8(sp)
  d6:	6c02                	ld	s8,0(sp)
  d8:	6161                	addi	sp,sp,80
  da:	8082                	ret

00000000000000dc <main>:
 
int main(int argc, char *argv[]) 
{ 
  dc:	7179                	addi	sp,sp,-48
  de:	f406                	sd	ra,40(sp)
  e0:	f022                	sd	s0,32(sp)
  e2:	ec26                	sd	s1,24(sp)
  e4:	e84a                	sd	s2,16(sp)
  e6:	e44e                	sd	s3,8(sp)
  e8:	1800                	addi	s0,sp,48
  ea:	84ae                	mv	s1,a1
  if (argc < 3) { 
  ec:	4789                	li	a5,2
  ee:	02a7c063          	blt	a5,a0,10e <main+0x32>
    printf("Usage: %s [N_PASSES] [N_THREADS]\n", argv[0]); 
  f2:	618c                	ld	a1,0(a1)
  f4:	00001517          	auipc	a0,0x1
  f8:	92c50513          	addi	a0,a0,-1748 # a20 <lock_release+0x52>
  fc:	00000097          	auipc	ra,0x0
 100:	6c4080e7          	jalr	1732(ra) # 7c0 <printf>
    exit(-1); 
 104:	557d                	li	a0,-1
 106:	00000097          	auipc	ra,0x0
 10a:	33a080e7          	jalr	826(ra) # 440 <exit>
  }  
  n_passes = atoi(argv[1]); 
 10e:	6588                	ld	a0,8(a1)
 110:	00000097          	auipc	ra,0x0
 114:	230080e7          	jalr	560(ra) # 340 <atoi>
 118:	00001797          	auipc	a5,0x1
 11c:	98a7ac23          	sw	a0,-1640(a5) # ab0 <n_passes>
  n_threads = atoi(argv[2]); 
 120:	6888                	ld	a0,16(s1)
 122:	00000097          	auipc	ra,0x0
 126:	21e080e7          	jalr	542(ra) # 340 <atoi>
 12a:	00001497          	auipc	s1,0x1
 12e:	98a48493          	addi	s1,s1,-1654 # ab4 <n_threads>
 132:	c088                	sw	a0,0(s1)
  cur_turn = 0; 
 134:	00001797          	auipc	a5,0x1
 138:	9607ac23          	sw	zero,-1672(a5) # aac <cur_turn>
  cur_pass = 0; 
 13c:	00001797          	auipc	a5,0x1
 140:	9607a623          	sw	zero,-1684(a5) # aa8 <cur_pass>
  lock_init(&lock); 
 144:	00001517          	auipc	a0,0x1
 148:	97450513          	addi	a0,a0,-1676 # ab8 <lock>
 14c:	00001097          	auipc	ra,0x1
 150:	856080e7          	jalr	-1962(ra) # 9a2 <lock_init>
  for (int i = 0; i < n_threads; i++) { 
 154:	409c                	lw	a5,0(s1)
 156:	04f05963          	blez	a5,1a8 <main+0xcc>
 15a:	4481                	li	s1,0
    thread_create(thread_fn, (void*)(uint64)i); 
 15c:	00000997          	auipc	s3,0x0
 160:	ea498993          	addi	s3,s3,-348 # 0 <thread_fn>
  for (int i = 0; i < n_threads; i++) { 
 164:	00001917          	auipc	s2,0x1
 168:	95090913          	addi	s2,s2,-1712 # ab4 <n_threads>
    thread_create(thread_fn, (void*)(uint64)i); 
 16c:	85a6                	mv	a1,s1
 16e:	854e                	mv	a0,s3
 170:	00000097          	auipc	ra,0x0
 174:	7f2080e7          	jalr	2034(ra) # 962 <thread_create>
  for (int i = 0; i < n_threads; i++) { 
 178:	00092783          	lw	a5,0(s2)
 17c:	0485                	addi	s1,s1,1
 17e:	0004871b          	sext.w	a4,s1
 182:	fef745e3          	blt	a4,a5,16c <main+0x90>
  } 
  for (int i = 0; i < n_threads; i++) { 
 186:	02f05163          	blez	a5,1a8 <main+0xcc>
 18a:	4481                	li	s1,0
 18c:	00001917          	auipc	s2,0x1
 190:	92890913          	addi	s2,s2,-1752 # ab4 <n_threads>
    wait(0); 
 194:	4501                	li	a0,0
 196:	00000097          	auipc	ra,0x0
 19a:	2b2080e7          	jalr	690(ra) # 448 <wait>
  for (int i = 0; i < n_threads; i++) { 
 19e:	2485                	addiw	s1,s1,1
 1a0:	00092783          	lw	a5,0(s2)
 1a4:	fef4c8e3          	blt	s1,a5,194 <main+0xb8>
  } 
  printf("Frisbee simulation has finished, %d rounds played in total!\n", n_passes); 
 1a8:	00001597          	auipc	a1,0x1
 1ac:	9085a583          	lw	a1,-1784(a1) # ab0 <n_passes>
 1b0:	00001517          	auipc	a0,0x1
 1b4:	89850513          	addi	a0,a0,-1896 # a48 <lock_release+0x7a>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	608080e7          	jalr	1544(ra) # 7c0 <printf>
 
  exit(0); 
 1c0:	4501                	li	a0,0
 1c2:	00000097          	auipc	ra,0x0
 1c6:	27e080e7          	jalr	638(ra) # 440 <exit>

00000000000001ca <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1ca:	1141                	addi	sp,sp,-16
 1cc:	e422                	sd	s0,8(sp)
 1ce:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1d0:	87aa                	mv	a5,a0
 1d2:	0585                	addi	a1,a1,1
 1d4:	0785                	addi	a5,a5,1
 1d6:	fff5c703          	lbu	a4,-1(a1)
 1da:	fee78fa3          	sb	a4,-1(a5)
 1de:	fb75                	bnez	a4,1d2 <strcpy+0x8>
    ;
  return os;
}
 1e0:	6422                	ld	s0,8(sp)
 1e2:	0141                	addi	sp,sp,16
 1e4:	8082                	ret

00000000000001e6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1e6:	1141                	addi	sp,sp,-16
 1e8:	e422                	sd	s0,8(sp)
 1ea:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1ec:	00054783          	lbu	a5,0(a0)
 1f0:	cb91                	beqz	a5,204 <strcmp+0x1e>
 1f2:	0005c703          	lbu	a4,0(a1)
 1f6:	00f71763          	bne	a4,a5,204 <strcmp+0x1e>
    p++, q++;
 1fa:	0505                	addi	a0,a0,1
 1fc:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1fe:	00054783          	lbu	a5,0(a0)
 202:	fbe5                	bnez	a5,1f2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 204:	0005c503          	lbu	a0,0(a1)
}
 208:	40a7853b          	subw	a0,a5,a0
 20c:	6422                	ld	s0,8(sp)
 20e:	0141                	addi	sp,sp,16
 210:	8082                	ret

0000000000000212 <strlen>:

uint
strlen(const char *s)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 218:	00054783          	lbu	a5,0(a0)
 21c:	cf91                	beqz	a5,238 <strlen+0x26>
 21e:	0505                	addi	a0,a0,1
 220:	87aa                	mv	a5,a0
 222:	4685                	li	a3,1
 224:	9e89                	subw	a3,a3,a0
 226:	00f6853b          	addw	a0,a3,a5
 22a:	0785                	addi	a5,a5,1
 22c:	fff7c703          	lbu	a4,-1(a5)
 230:	fb7d                	bnez	a4,226 <strlen+0x14>
    ;
  return n;
}
 232:	6422                	ld	s0,8(sp)
 234:	0141                	addi	sp,sp,16
 236:	8082                	ret
  for(n = 0; s[n]; n++)
 238:	4501                	li	a0,0
 23a:	bfe5                	j	232 <strlen+0x20>

000000000000023c <memset>:

void*
memset(void *dst, int c, uint n)
{
 23c:	1141                	addi	sp,sp,-16
 23e:	e422                	sd	s0,8(sp)
 240:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 242:	ce09                	beqz	a2,25c <memset+0x20>
 244:	87aa                	mv	a5,a0
 246:	fff6071b          	addiw	a4,a2,-1
 24a:	1702                	slli	a4,a4,0x20
 24c:	9301                	srli	a4,a4,0x20
 24e:	0705                	addi	a4,a4,1
 250:	972a                	add	a4,a4,a0
    cdst[i] = c;
 252:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 256:	0785                	addi	a5,a5,1
 258:	fee79de3          	bne	a5,a4,252 <memset+0x16>
  }
  return dst;
}
 25c:	6422                	ld	s0,8(sp)
 25e:	0141                	addi	sp,sp,16
 260:	8082                	ret

0000000000000262 <strchr>:

char*
strchr(const char *s, char c)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  for(; *s; s++)
 268:	00054783          	lbu	a5,0(a0)
 26c:	cb99                	beqz	a5,282 <strchr+0x20>
    if(*s == c)
 26e:	00f58763          	beq	a1,a5,27c <strchr+0x1a>
  for(; *s; s++)
 272:	0505                	addi	a0,a0,1
 274:	00054783          	lbu	a5,0(a0)
 278:	fbfd                	bnez	a5,26e <strchr+0xc>
      return (char*)s;
  return 0;
 27a:	4501                	li	a0,0
}
 27c:	6422                	ld	s0,8(sp)
 27e:	0141                	addi	sp,sp,16
 280:	8082                	ret
  return 0;
 282:	4501                	li	a0,0
 284:	bfe5                	j	27c <strchr+0x1a>

0000000000000286 <gets>:

char*
gets(char *buf, int max)
{
 286:	711d                	addi	sp,sp,-96
 288:	ec86                	sd	ra,88(sp)
 28a:	e8a2                	sd	s0,80(sp)
 28c:	e4a6                	sd	s1,72(sp)
 28e:	e0ca                	sd	s2,64(sp)
 290:	fc4e                	sd	s3,56(sp)
 292:	f852                	sd	s4,48(sp)
 294:	f456                	sd	s5,40(sp)
 296:	f05a                	sd	s6,32(sp)
 298:	ec5e                	sd	s7,24(sp)
 29a:	1080                	addi	s0,sp,96
 29c:	8baa                	mv	s7,a0
 29e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2a0:	892a                	mv	s2,a0
 2a2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2a4:	4aa9                	li	s5,10
 2a6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2a8:	89a6                	mv	s3,s1
 2aa:	2485                	addiw	s1,s1,1
 2ac:	0344d863          	bge	s1,s4,2dc <gets+0x56>
    cc = read(0, &c, 1);
 2b0:	4605                	li	a2,1
 2b2:	faf40593          	addi	a1,s0,-81
 2b6:	4501                	li	a0,0
 2b8:	00000097          	auipc	ra,0x0
 2bc:	1a0080e7          	jalr	416(ra) # 458 <read>
    if(cc < 1)
 2c0:	00a05e63          	blez	a0,2dc <gets+0x56>
    buf[i++] = c;
 2c4:	faf44783          	lbu	a5,-81(s0)
 2c8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2cc:	01578763          	beq	a5,s5,2da <gets+0x54>
 2d0:	0905                	addi	s2,s2,1
 2d2:	fd679be3          	bne	a5,s6,2a8 <gets+0x22>
  for(i=0; i+1 < max; ){
 2d6:	89a6                	mv	s3,s1
 2d8:	a011                	j	2dc <gets+0x56>
 2da:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2dc:	99de                	add	s3,s3,s7
 2de:	00098023          	sb	zero,0(s3)
  return buf;
}
 2e2:	855e                	mv	a0,s7
 2e4:	60e6                	ld	ra,88(sp)
 2e6:	6446                	ld	s0,80(sp)
 2e8:	64a6                	ld	s1,72(sp)
 2ea:	6906                	ld	s2,64(sp)
 2ec:	79e2                	ld	s3,56(sp)
 2ee:	7a42                	ld	s4,48(sp)
 2f0:	7aa2                	ld	s5,40(sp)
 2f2:	7b02                	ld	s6,32(sp)
 2f4:	6be2                	ld	s7,24(sp)
 2f6:	6125                	addi	sp,sp,96
 2f8:	8082                	ret

00000000000002fa <stat>:

int
stat(const char *n, struct stat *st)
{
 2fa:	1101                	addi	sp,sp,-32
 2fc:	ec06                	sd	ra,24(sp)
 2fe:	e822                	sd	s0,16(sp)
 300:	e426                	sd	s1,8(sp)
 302:	e04a                	sd	s2,0(sp)
 304:	1000                	addi	s0,sp,32
 306:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 308:	4581                	li	a1,0
 30a:	00000097          	auipc	ra,0x0
 30e:	176080e7          	jalr	374(ra) # 480 <open>
  if(fd < 0)
 312:	02054563          	bltz	a0,33c <stat+0x42>
 316:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 318:	85ca                	mv	a1,s2
 31a:	00000097          	auipc	ra,0x0
 31e:	17e080e7          	jalr	382(ra) # 498 <fstat>
 322:	892a                	mv	s2,a0
  close(fd);
 324:	8526                	mv	a0,s1
 326:	00000097          	auipc	ra,0x0
 32a:	142080e7          	jalr	322(ra) # 468 <close>
  return r;
}
 32e:	854a                	mv	a0,s2
 330:	60e2                	ld	ra,24(sp)
 332:	6442                	ld	s0,16(sp)
 334:	64a2                	ld	s1,8(sp)
 336:	6902                	ld	s2,0(sp)
 338:	6105                	addi	sp,sp,32
 33a:	8082                	ret
    return -1;
 33c:	597d                	li	s2,-1
 33e:	bfc5                	j	32e <stat+0x34>

0000000000000340 <atoi>:

int
atoi(const char *s)
{
 340:	1141                	addi	sp,sp,-16
 342:	e422                	sd	s0,8(sp)
 344:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 346:	00054603          	lbu	a2,0(a0)
 34a:	fd06079b          	addiw	a5,a2,-48
 34e:	0ff7f793          	andi	a5,a5,255
 352:	4725                	li	a4,9
 354:	02f76963          	bltu	a4,a5,386 <atoi+0x46>
 358:	86aa                	mv	a3,a0
  n = 0;
 35a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 35c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 35e:	0685                	addi	a3,a3,1
 360:	0025179b          	slliw	a5,a0,0x2
 364:	9fa9                	addw	a5,a5,a0
 366:	0017979b          	slliw	a5,a5,0x1
 36a:	9fb1                	addw	a5,a5,a2
 36c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 370:	0006c603          	lbu	a2,0(a3)
 374:	fd06071b          	addiw	a4,a2,-48
 378:	0ff77713          	andi	a4,a4,255
 37c:	fee5f1e3          	bgeu	a1,a4,35e <atoi+0x1e>
  return n;
}
 380:	6422                	ld	s0,8(sp)
 382:	0141                	addi	sp,sp,16
 384:	8082                	ret
  n = 0;
 386:	4501                	li	a0,0
 388:	bfe5                	j	380 <atoi+0x40>

000000000000038a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 38a:	1141                	addi	sp,sp,-16
 38c:	e422                	sd	s0,8(sp)
 38e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 390:	02b57663          	bgeu	a0,a1,3bc <memmove+0x32>
    while(n-- > 0)
 394:	02c05163          	blez	a2,3b6 <memmove+0x2c>
 398:	fff6079b          	addiw	a5,a2,-1
 39c:	1782                	slli	a5,a5,0x20
 39e:	9381                	srli	a5,a5,0x20
 3a0:	0785                	addi	a5,a5,1
 3a2:	97aa                	add	a5,a5,a0
  dst = vdst;
 3a4:	872a                	mv	a4,a0
      *dst++ = *src++;
 3a6:	0585                	addi	a1,a1,1
 3a8:	0705                	addi	a4,a4,1
 3aa:	fff5c683          	lbu	a3,-1(a1)
 3ae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3b2:	fee79ae3          	bne	a5,a4,3a6 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3b6:	6422                	ld	s0,8(sp)
 3b8:	0141                	addi	sp,sp,16
 3ba:	8082                	ret
    dst += n;
 3bc:	00c50733          	add	a4,a0,a2
    src += n;
 3c0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3c2:	fec05ae3          	blez	a2,3b6 <memmove+0x2c>
 3c6:	fff6079b          	addiw	a5,a2,-1
 3ca:	1782                	slli	a5,a5,0x20
 3cc:	9381                	srli	a5,a5,0x20
 3ce:	fff7c793          	not	a5,a5
 3d2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3d4:	15fd                	addi	a1,a1,-1
 3d6:	177d                	addi	a4,a4,-1
 3d8:	0005c683          	lbu	a3,0(a1)
 3dc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3e0:	fee79ae3          	bne	a5,a4,3d4 <memmove+0x4a>
 3e4:	bfc9                	j	3b6 <memmove+0x2c>

00000000000003e6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3e6:	1141                	addi	sp,sp,-16
 3e8:	e422                	sd	s0,8(sp)
 3ea:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3ec:	ca05                	beqz	a2,41c <memcmp+0x36>
 3ee:	fff6069b          	addiw	a3,a2,-1
 3f2:	1682                	slli	a3,a3,0x20
 3f4:	9281                	srli	a3,a3,0x20
 3f6:	0685                	addi	a3,a3,1
 3f8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3fa:	00054783          	lbu	a5,0(a0)
 3fe:	0005c703          	lbu	a4,0(a1)
 402:	00e79863          	bne	a5,a4,412 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 406:	0505                	addi	a0,a0,1
    p2++;
 408:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 40a:	fed518e3          	bne	a0,a3,3fa <memcmp+0x14>
  }
  return 0;
 40e:	4501                	li	a0,0
 410:	a019                	j	416 <memcmp+0x30>
      return *p1 - *p2;
 412:	40e7853b          	subw	a0,a5,a4
}
 416:	6422                	ld	s0,8(sp)
 418:	0141                	addi	sp,sp,16
 41a:	8082                	ret
  return 0;
 41c:	4501                	li	a0,0
 41e:	bfe5                	j	416 <memcmp+0x30>

0000000000000420 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 420:	1141                	addi	sp,sp,-16
 422:	e406                	sd	ra,8(sp)
 424:	e022                	sd	s0,0(sp)
 426:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 428:	00000097          	auipc	ra,0x0
 42c:	f62080e7          	jalr	-158(ra) # 38a <memmove>
}
 430:	60a2                	ld	ra,8(sp)
 432:	6402                	ld	s0,0(sp)
 434:	0141                	addi	sp,sp,16
 436:	8082                	ret

0000000000000438 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 438:	4885                	li	a7,1
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <exit>:
.global exit
exit:
 li a7, SYS_exit
 440:	4889                	li	a7,2
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <wait>:
.global wait
wait:
 li a7, SYS_wait
 448:	488d                	li	a7,3
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 450:	4891                	li	a7,4
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <read>:
.global read
read:
 li a7, SYS_read
 458:	4895                	li	a7,5
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <write>:
.global write
write:
 li a7, SYS_write
 460:	48c1                	li	a7,16
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <close>:
.global close
close:
 li a7, SYS_close
 468:	48d5                	li	a7,21
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <kill>:
.global kill
kill:
 li a7, SYS_kill
 470:	4899                	li	a7,6
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <exec>:
.global exec
exec:
 li a7, SYS_exec
 478:	489d                	li	a7,7
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <open>:
.global open
open:
 li a7, SYS_open
 480:	48bd                	li	a7,15
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 488:	48c5                	li	a7,17
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 490:	48c9                	li	a7,18
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 498:	48a1                	li	a7,8
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <link>:
.global link
link:
 li a7, SYS_link
 4a0:	48cd                	li	a7,19
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4a8:	48d1                	li	a7,20
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4b0:	48a5                	li	a7,9
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4b8:	48a9                	li	a7,10
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4c0:	48ad                	li	a7,11
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4c8:	48b1                	li	a7,12
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4d0:	48b5                	li	a7,13
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4d8:	48b9                	li	a7,14
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <clone>:
.global clone
clone:
 li a7, SYS_clone
 4e0:	48d9                	li	a7,22
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4e8:	1101                	addi	sp,sp,-32
 4ea:	ec06                	sd	ra,24(sp)
 4ec:	e822                	sd	s0,16(sp)
 4ee:	1000                	addi	s0,sp,32
 4f0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4f4:	4605                	li	a2,1
 4f6:	fef40593          	addi	a1,s0,-17
 4fa:	00000097          	auipc	ra,0x0
 4fe:	f66080e7          	jalr	-154(ra) # 460 <write>
}
 502:	60e2                	ld	ra,24(sp)
 504:	6442                	ld	s0,16(sp)
 506:	6105                	addi	sp,sp,32
 508:	8082                	ret

000000000000050a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 50a:	7139                	addi	sp,sp,-64
 50c:	fc06                	sd	ra,56(sp)
 50e:	f822                	sd	s0,48(sp)
 510:	f426                	sd	s1,40(sp)
 512:	f04a                	sd	s2,32(sp)
 514:	ec4e                	sd	s3,24(sp)
 516:	0080                	addi	s0,sp,64
 518:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 51a:	c299                	beqz	a3,520 <printint+0x16>
 51c:	0805c863          	bltz	a1,5ac <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 520:	2581                	sext.w	a1,a1
  neg = 0;
 522:	4881                	li	a7,0
 524:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 528:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 52a:	2601                	sext.w	a2,a2
 52c:	00000517          	auipc	a0,0x0
 530:	56450513          	addi	a0,a0,1380 # a90 <digits>
 534:	883a                	mv	a6,a4
 536:	2705                	addiw	a4,a4,1
 538:	02c5f7bb          	remuw	a5,a1,a2
 53c:	1782                	slli	a5,a5,0x20
 53e:	9381                	srli	a5,a5,0x20
 540:	97aa                	add	a5,a5,a0
 542:	0007c783          	lbu	a5,0(a5)
 546:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 54a:	0005879b          	sext.w	a5,a1
 54e:	02c5d5bb          	divuw	a1,a1,a2
 552:	0685                	addi	a3,a3,1
 554:	fec7f0e3          	bgeu	a5,a2,534 <printint+0x2a>
  if(neg)
 558:	00088b63          	beqz	a7,56e <printint+0x64>
    buf[i++] = '-';
 55c:	fd040793          	addi	a5,s0,-48
 560:	973e                	add	a4,a4,a5
 562:	02d00793          	li	a5,45
 566:	fef70823          	sb	a5,-16(a4)
 56a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 56e:	02e05863          	blez	a4,59e <printint+0x94>
 572:	fc040793          	addi	a5,s0,-64
 576:	00e78933          	add	s2,a5,a4
 57a:	fff78993          	addi	s3,a5,-1
 57e:	99ba                	add	s3,s3,a4
 580:	377d                	addiw	a4,a4,-1
 582:	1702                	slli	a4,a4,0x20
 584:	9301                	srli	a4,a4,0x20
 586:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 58a:	fff94583          	lbu	a1,-1(s2)
 58e:	8526                	mv	a0,s1
 590:	00000097          	auipc	ra,0x0
 594:	f58080e7          	jalr	-168(ra) # 4e8 <putc>
  while(--i >= 0)
 598:	197d                	addi	s2,s2,-1
 59a:	ff3918e3          	bne	s2,s3,58a <printint+0x80>
}
 59e:	70e2                	ld	ra,56(sp)
 5a0:	7442                	ld	s0,48(sp)
 5a2:	74a2                	ld	s1,40(sp)
 5a4:	7902                	ld	s2,32(sp)
 5a6:	69e2                	ld	s3,24(sp)
 5a8:	6121                	addi	sp,sp,64
 5aa:	8082                	ret
    x = -xx;
 5ac:	40b005bb          	negw	a1,a1
    neg = 1;
 5b0:	4885                	li	a7,1
    x = -xx;
 5b2:	bf8d                	j	524 <printint+0x1a>

00000000000005b4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5b4:	7119                	addi	sp,sp,-128
 5b6:	fc86                	sd	ra,120(sp)
 5b8:	f8a2                	sd	s0,112(sp)
 5ba:	f4a6                	sd	s1,104(sp)
 5bc:	f0ca                	sd	s2,96(sp)
 5be:	ecce                	sd	s3,88(sp)
 5c0:	e8d2                	sd	s4,80(sp)
 5c2:	e4d6                	sd	s5,72(sp)
 5c4:	e0da                	sd	s6,64(sp)
 5c6:	fc5e                	sd	s7,56(sp)
 5c8:	f862                	sd	s8,48(sp)
 5ca:	f466                	sd	s9,40(sp)
 5cc:	f06a                	sd	s10,32(sp)
 5ce:	ec6e                	sd	s11,24(sp)
 5d0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5d2:	0005c903          	lbu	s2,0(a1)
 5d6:	18090f63          	beqz	s2,774 <vprintf+0x1c0>
 5da:	8aaa                	mv	s5,a0
 5dc:	8b32                	mv	s6,a2
 5de:	00158493          	addi	s1,a1,1
  state = 0;
 5e2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5e4:	02500a13          	li	s4,37
      if(c == 'd'){
 5e8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5ec:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5f0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5f4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f8:	00000b97          	auipc	s7,0x0
 5fc:	498b8b93          	addi	s7,s7,1176 # a90 <digits>
 600:	a839                	j	61e <vprintf+0x6a>
        putc(fd, c);
 602:	85ca                	mv	a1,s2
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	ee2080e7          	jalr	-286(ra) # 4e8 <putc>
 60e:	a019                	j	614 <vprintf+0x60>
    } else if(state == '%'){
 610:	01498f63          	beq	s3,s4,62e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 614:	0485                	addi	s1,s1,1
 616:	fff4c903          	lbu	s2,-1(s1)
 61a:	14090d63          	beqz	s2,774 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 61e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 622:	fe0997e3          	bnez	s3,610 <vprintf+0x5c>
      if(c == '%'){
 626:	fd479ee3          	bne	a5,s4,602 <vprintf+0x4e>
        state = '%';
 62a:	89be                	mv	s3,a5
 62c:	b7e5                	j	614 <vprintf+0x60>
      if(c == 'd'){
 62e:	05878063          	beq	a5,s8,66e <vprintf+0xba>
      } else if(c == 'l') {
 632:	05978c63          	beq	a5,s9,68a <vprintf+0xd6>
      } else if(c == 'x') {
 636:	07a78863          	beq	a5,s10,6a6 <vprintf+0xf2>
      } else if(c == 'p') {
 63a:	09b78463          	beq	a5,s11,6c2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 63e:	07300713          	li	a4,115
 642:	0ce78663          	beq	a5,a4,70e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 646:	06300713          	li	a4,99
 64a:	0ee78e63          	beq	a5,a4,746 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 64e:	11478863          	beq	a5,s4,75e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 652:	85d2                	mv	a1,s4
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	e92080e7          	jalr	-366(ra) # 4e8 <putc>
        putc(fd, c);
 65e:	85ca                	mv	a1,s2
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	e86080e7          	jalr	-378(ra) # 4e8 <putc>
      }
      state = 0;
 66a:	4981                	li	s3,0
 66c:	b765                	j	614 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 66e:	008b0913          	addi	s2,s6,8
 672:	4685                	li	a3,1
 674:	4629                	li	a2,10
 676:	000b2583          	lw	a1,0(s6)
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	e8e080e7          	jalr	-370(ra) # 50a <printint>
 684:	8b4a                	mv	s6,s2
      state = 0;
 686:	4981                	li	s3,0
 688:	b771                	j	614 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 68a:	008b0913          	addi	s2,s6,8
 68e:	4681                	li	a3,0
 690:	4629                	li	a2,10
 692:	000b2583          	lw	a1,0(s6)
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	e72080e7          	jalr	-398(ra) # 50a <printint>
 6a0:	8b4a                	mv	s6,s2
      state = 0;
 6a2:	4981                	li	s3,0
 6a4:	bf85                	j	614 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6a6:	008b0913          	addi	s2,s6,8
 6aa:	4681                	li	a3,0
 6ac:	4641                	li	a2,16
 6ae:	000b2583          	lw	a1,0(s6)
 6b2:	8556                	mv	a0,s5
 6b4:	00000097          	auipc	ra,0x0
 6b8:	e56080e7          	jalr	-426(ra) # 50a <printint>
 6bc:	8b4a                	mv	s6,s2
      state = 0;
 6be:	4981                	li	s3,0
 6c0:	bf91                	j	614 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6c2:	008b0793          	addi	a5,s6,8
 6c6:	f8f43423          	sd	a5,-120(s0)
 6ca:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6ce:	03000593          	li	a1,48
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e14080e7          	jalr	-492(ra) # 4e8 <putc>
  putc(fd, 'x');
 6dc:	85ea                	mv	a1,s10
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e08080e7          	jalr	-504(ra) # 4e8 <putc>
 6e8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ea:	03c9d793          	srli	a5,s3,0x3c
 6ee:	97de                	add	a5,a5,s7
 6f0:	0007c583          	lbu	a1,0(a5)
 6f4:	8556                	mv	a0,s5
 6f6:	00000097          	auipc	ra,0x0
 6fa:	df2080e7          	jalr	-526(ra) # 4e8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6fe:	0992                	slli	s3,s3,0x4
 700:	397d                	addiw	s2,s2,-1
 702:	fe0914e3          	bnez	s2,6ea <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 706:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 70a:	4981                	li	s3,0
 70c:	b721                	j	614 <vprintf+0x60>
        s = va_arg(ap, char*);
 70e:	008b0993          	addi	s3,s6,8
 712:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 716:	02090163          	beqz	s2,738 <vprintf+0x184>
        while(*s != 0){
 71a:	00094583          	lbu	a1,0(s2)
 71e:	c9a1                	beqz	a1,76e <vprintf+0x1ba>
          putc(fd, *s);
 720:	8556                	mv	a0,s5
 722:	00000097          	auipc	ra,0x0
 726:	dc6080e7          	jalr	-570(ra) # 4e8 <putc>
          s++;
 72a:	0905                	addi	s2,s2,1
        while(*s != 0){
 72c:	00094583          	lbu	a1,0(s2)
 730:	f9e5                	bnez	a1,720 <vprintf+0x16c>
        s = va_arg(ap, char*);
 732:	8b4e                	mv	s6,s3
      state = 0;
 734:	4981                	li	s3,0
 736:	bdf9                	j	614 <vprintf+0x60>
          s = "(null)";
 738:	00000917          	auipc	s2,0x0
 73c:	35090913          	addi	s2,s2,848 # a88 <lock_release+0xba>
        while(*s != 0){
 740:	02800593          	li	a1,40
 744:	bff1                	j	720 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 746:	008b0913          	addi	s2,s6,8
 74a:	000b4583          	lbu	a1,0(s6)
 74e:	8556                	mv	a0,s5
 750:	00000097          	auipc	ra,0x0
 754:	d98080e7          	jalr	-616(ra) # 4e8 <putc>
 758:	8b4a                	mv	s6,s2
      state = 0;
 75a:	4981                	li	s3,0
 75c:	bd65                	j	614 <vprintf+0x60>
        putc(fd, c);
 75e:	85d2                	mv	a1,s4
 760:	8556                	mv	a0,s5
 762:	00000097          	auipc	ra,0x0
 766:	d86080e7          	jalr	-634(ra) # 4e8 <putc>
      state = 0;
 76a:	4981                	li	s3,0
 76c:	b565                	j	614 <vprintf+0x60>
        s = va_arg(ap, char*);
 76e:	8b4e                	mv	s6,s3
      state = 0;
 770:	4981                	li	s3,0
 772:	b54d                	j	614 <vprintf+0x60>
    }
  }
}
 774:	70e6                	ld	ra,120(sp)
 776:	7446                	ld	s0,112(sp)
 778:	74a6                	ld	s1,104(sp)
 77a:	7906                	ld	s2,96(sp)
 77c:	69e6                	ld	s3,88(sp)
 77e:	6a46                	ld	s4,80(sp)
 780:	6aa6                	ld	s5,72(sp)
 782:	6b06                	ld	s6,64(sp)
 784:	7be2                	ld	s7,56(sp)
 786:	7c42                	ld	s8,48(sp)
 788:	7ca2                	ld	s9,40(sp)
 78a:	7d02                	ld	s10,32(sp)
 78c:	6de2                	ld	s11,24(sp)
 78e:	6109                	addi	sp,sp,128
 790:	8082                	ret

0000000000000792 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 792:	715d                	addi	sp,sp,-80
 794:	ec06                	sd	ra,24(sp)
 796:	e822                	sd	s0,16(sp)
 798:	1000                	addi	s0,sp,32
 79a:	e010                	sd	a2,0(s0)
 79c:	e414                	sd	a3,8(s0)
 79e:	e818                	sd	a4,16(s0)
 7a0:	ec1c                	sd	a5,24(s0)
 7a2:	03043023          	sd	a6,32(s0)
 7a6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7aa:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7ae:	8622                	mv	a2,s0
 7b0:	00000097          	auipc	ra,0x0
 7b4:	e04080e7          	jalr	-508(ra) # 5b4 <vprintf>
}
 7b8:	60e2                	ld	ra,24(sp)
 7ba:	6442                	ld	s0,16(sp)
 7bc:	6161                	addi	sp,sp,80
 7be:	8082                	ret

00000000000007c0 <printf>:

void
printf(const char *fmt, ...)
{
 7c0:	711d                	addi	sp,sp,-96
 7c2:	ec06                	sd	ra,24(sp)
 7c4:	e822                	sd	s0,16(sp)
 7c6:	1000                	addi	s0,sp,32
 7c8:	e40c                	sd	a1,8(s0)
 7ca:	e810                	sd	a2,16(s0)
 7cc:	ec14                	sd	a3,24(s0)
 7ce:	f018                	sd	a4,32(s0)
 7d0:	f41c                	sd	a5,40(s0)
 7d2:	03043823          	sd	a6,48(s0)
 7d6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7da:	00840613          	addi	a2,s0,8
 7de:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7e2:	85aa                	mv	a1,a0
 7e4:	4505                	li	a0,1
 7e6:	00000097          	auipc	ra,0x0
 7ea:	dce080e7          	jalr	-562(ra) # 5b4 <vprintf>
}
 7ee:	60e2                	ld	ra,24(sp)
 7f0:	6442                	ld	s0,16(sp)
 7f2:	6125                	addi	sp,sp,96
 7f4:	8082                	ret

00000000000007f6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7f6:	1141                	addi	sp,sp,-16
 7f8:	e422                	sd	s0,8(sp)
 7fa:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7fc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 800:	00000797          	auipc	a5,0x0
 804:	2c07b783          	ld	a5,704(a5) # ac0 <freep>
 808:	a805                	j	838 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 80a:	4618                	lw	a4,8(a2)
 80c:	9db9                	addw	a1,a1,a4
 80e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 812:	6398                	ld	a4,0(a5)
 814:	6318                	ld	a4,0(a4)
 816:	fee53823          	sd	a4,-16(a0)
 81a:	a091                	j	85e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 81c:	ff852703          	lw	a4,-8(a0)
 820:	9e39                	addw	a2,a2,a4
 822:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 824:	ff053703          	ld	a4,-16(a0)
 828:	e398                	sd	a4,0(a5)
 82a:	a099                	j	870 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 82c:	6398                	ld	a4,0(a5)
 82e:	00e7e463          	bltu	a5,a4,836 <free+0x40>
 832:	00e6ea63          	bltu	a3,a4,846 <free+0x50>
{
 836:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 838:	fed7fae3          	bgeu	a5,a3,82c <free+0x36>
 83c:	6398                	ld	a4,0(a5)
 83e:	00e6e463          	bltu	a3,a4,846 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 842:	fee7eae3          	bltu	a5,a4,836 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 846:	ff852583          	lw	a1,-8(a0)
 84a:	6390                	ld	a2,0(a5)
 84c:	02059713          	slli	a4,a1,0x20
 850:	9301                	srli	a4,a4,0x20
 852:	0712                	slli	a4,a4,0x4
 854:	9736                	add	a4,a4,a3
 856:	fae60ae3          	beq	a2,a4,80a <free+0x14>
    bp->s.ptr = p->s.ptr;
 85a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 85e:	4790                	lw	a2,8(a5)
 860:	02061713          	slli	a4,a2,0x20
 864:	9301                	srli	a4,a4,0x20
 866:	0712                	slli	a4,a4,0x4
 868:	973e                	add	a4,a4,a5
 86a:	fae689e3          	beq	a3,a4,81c <free+0x26>
  } else
    p->s.ptr = bp;
 86e:	e394                	sd	a3,0(a5)
  freep = p;
 870:	00000717          	auipc	a4,0x0
 874:	24f73823          	sd	a5,592(a4) # ac0 <freep>
}
 878:	6422                	ld	s0,8(sp)
 87a:	0141                	addi	sp,sp,16
 87c:	8082                	ret

000000000000087e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 87e:	7139                	addi	sp,sp,-64
 880:	fc06                	sd	ra,56(sp)
 882:	f822                	sd	s0,48(sp)
 884:	f426                	sd	s1,40(sp)
 886:	f04a                	sd	s2,32(sp)
 888:	ec4e                	sd	s3,24(sp)
 88a:	e852                	sd	s4,16(sp)
 88c:	e456                	sd	s5,8(sp)
 88e:	e05a                	sd	s6,0(sp)
 890:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 892:	02051493          	slli	s1,a0,0x20
 896:	9081                	srli	s1,s1,0x20
 898:	04bd                	addi	s1,s1,15
 89a:	8091                	srli	s1,s1,0x4
 89c:	0014899b          	addiw	s3,s1,1
 8a0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8a2:	00000517          	auipc	a0,0x0
 8a6:	21e53503          	ld	a0,542(a0) # ac0 <freep>
 8aa:	c515                	beqz	a0,8d6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ac:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ae:	4798                	lw	a4,8(a5)
 8b0:	02977f63          	bgeu	a4,s1,8ee <malloc+0x70>
 8b4:	8a4e                	mv	s4,s3
 8b6:	0009871b          	sext.w	a4,s3
 8ba:	6685                	lui	a3,0x1
 8bc:	00d77363          	bgeu	a4,a3,8c2 <malloc+0x44>
 8c0:	6a05                	lui	s4,0x1
 8c2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8c6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8ca:	00000917          	auipc	s2,0x0
 8ce:	1f690913          	addi	s2,s2,502 # ac0 <freep>
  if(p == (char*)-1)
 8d2:	5afd                	li	s5,-1
 8d4:	a88d                	j	946 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8d6:	00000797          	auipc	a5,0x0
 8da:	1f278793          	addi	a5,a5,498 # ac8 <base>
 8de:	00000717          	auipc	a4,0x0
 8e2:	1ef73123          	sd	a5,482(a4) # ac0 <freep>
 8e6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8e8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8ec:	b7e1                	j	8b4 <malloc+0x36>
      if(p->s.size == nunits)
 8ee:	02e48b63          	beq	s1,a4,924 <malloc+0xa6>
        p->s.size -= nunits;
 8f2:	4137073b          	subw	a4,a4,s3
 8f6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8f8:	1702                	slli	a4,a4,0x20
 8fa:	9301                	srli	a4,a4,0x20
 8fc:	0712                	slli	a4,a4,0x4
 8fe:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 900:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 904:	00000717          	auipc	a4,0x0
 908:	1aa73e23          	sd	a0,444(a4) # ac0 <freep>
      return (void*)(p + 1);
 90c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 910:	70e2                	ld	ra,56(sp)
 912:	7442                	ld	s0,48(sp)
 914:	74a2                	ld	s1,40(sp)
 916:	7902                	ld	s2,32(sp)
 918:	69e2                	ld	s3,24(sp)
 91a:	6a42                	ld	s4,16(sp)
 91c:	6aa2                	ld	s5,8(sp)
 91e:	6b02                	ld	s6,0(sp)
 920:	6121                	addi	sp,sp,64
 922:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 924:	6398                	ld	a4,0(a5)
 926:	e118                	sd	a4,0(a0)
 928:	bff1                	j	904 <malloc+0x86>
  hp->s.size = nu;
 92a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 92e:	0541                	addi	a0,a0,16
 930:	00000097          	auipc	ra,0x0
 934:	ec6080e7          	jalr	-314(ra) # 7f6 <free>
  return freep;
 938:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 93c:	d971                	beqz	a0,910 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 93e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 940:	4798                	lw	a4,8(a5)
 942:	fa9776e3          	bgeu	a4,s1,8ee <malloc+0x70>
    if(p == freep)
 946:	00093703          	ld	a4,0(s2)
 94a:	853e                	mv	a0,a5
 94c:	fef719e3          	bne	a4,a5,93e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 950:	8552                	mv	a0,s4
 952:	00000097          	auipc	ra,0x0
 956:	b76080e7          	jalr	-1162(ra) # 4c8 <sbrk>
  if(p == (char*)-1)
 95a:	fd5518e3          	bne	a0,s5,92a <malloc+0xac>
        return 0;
 95e:	4501                	li	a0,0
 960:	bf45                	j	910 <malloc+0x92>

0000000000000962 <thread_create>:
#include "kernel/stat.h"
#include "user/user.h"
#include "user/thread.h"
#include "kernel/spinlock.h"

int thread_create(void *(*thread_fn)(void*), void *arg) {
 962:	1101                	addi	sp,sp,-32
 964:	ec06                	sd	ra,24(sp)
 966:	e822                	sd	s0,16(sp)
 968:	e426                	sd	s1,8(sp)
 96a:	e04a                	sd	s2,0(sp)
 96c:	1000                	addi	s0,sp,32
 96e:	84aa                	mv	s1,a0
 970:	892e                	mv	s2,a1
	int threadid;
	void* stack = (void*)malloc(4096 * sizeof(void));
 972:	6505                	lui	a0,0x1
 974:	00000097          	auipc	ra,0x0
 978:	f0a080e7          	jalr	-246(ra) # 87e <malloc>
	threadid  = clone(stack);
 97c:	00000097          	auipc	ra,0x0
 980:	b64080e7          	jalr	-1180(ra) # 4e0 <clone>
	if(threadid != 0) {
 984:	c901                	beqz	a0,994 <thread_create+0x32>
    else{
    (*thread_fn) (arg);
	exit(0);
    }
	return 0;
}
 986:	4501                	li	a0,0
 988:	60e2                	ld	ra,24(sp)
 98a:	6442                	ld	s0,16(sp)
 98c:	64a2                	ld	s1,8(sp)
 98e:	6902                	ld	s2,0(sp)
 990:	6105                	addi	sp,sp,32
 992:	8082                	ret
    (*thread_fn) (arg);
 994:	854a                	mv	a0,s2
 996:	9482                	jalr	s1
	exit(0);
 998:	4501                	li	a0,0
 99a:	00000097          	auipc	ra,0x0
 99e:	aa6080e7          	jalr	-1370(ra) # 440 <exit>

00000000000009a2 <lock_init>:

//Lock implementation
void lock_init(lock_t *lock)
{
 9a2:	1141                	addi	sp,sp,-16
 9a4:	e422                	sd	s0,8(sp)
 9a6:	0800                	addi	s0,sp,16
	lock->unlocked = 0;
 9a8:	00052023          	sw	zero,0(a0) # 1000 <__BSS_END__+0x528>
}
 9ac:	6422                	ld	s0,8(sp)
 9ae:	0141                	addi	sp,sp,16
 9b0:	8082                	ret

00000000000009b2 <lock_acquire>:

void lock_acquire(lock_t *lock)
{
 9b2:	1141                	addi	sp,sp,-16
 9b4:	e422                	sd	s0,8(sp)
 9b6:	0800                	addi	s0,sp,16
	while(__sync_lock_test_and_set(&lock->unlocked, 1) != 0);
 9b8:	4705                	li	a4,1
 9ba:	87ba                	mv	a5,a4
 9bc:	0cf527af          	amoswap.w.aq	a5,a5,(a0)
 9c0:	2781                	sext.w	a5,a5
 9c2:	ffe5                	bnez	a5,9ba <lock_acquire+0x8>
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
	__sync_synchronize();
 9c4:	0ff0000f          	fence
}
 9c8:	6422                	ld	s0,8(sp)
 9ca:	0141                	addi	sp,sp,16
 9cc:	8082                	ret

00000000000009ce <lock_release>:
void lock_release(lock_t *lock)
{
 9ce:	1141                	addi	sp,sp,-16
 9d0:	e422                	sd	s0,8(sp)
 9d2:	0800                	addi	s0,sp,16
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
	__sync_synchronize();
 9d4:	0ff0000f          	fence
  // implies that an assignment might be implemented with
  // multiple store instructions.
  // On RISC-V, sync_lock_release turns into an atomic swap:
  //   s1 = &lk->locked
  //   amoswap.w zero, zero, (s1)
	__sync_lock_release(&lock->unlocked,0);
 9d8:	0f50000f          	fence	iorw,ow
 9dc:	0805202f          	amoswap.w	zero,zero,(a0)
 9e0:	6422                	ld	s0,8(sp)
 9e2:	0141                	addi	sp,sp,16
 9e4:	8082                	ret
