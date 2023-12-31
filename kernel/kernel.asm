
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d3c78793          	addi	a5,a5,-708 # 80005da0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	584080e7          	jalr	1412(ra) # 800026b0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	804080e7          	jalr	-2044(ra) # 800019c8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	0ce080e7          	jalr	206(ra) # 800022a2 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	44a080e7          	jalr	1098(ra) # 8000265a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	414080e7          	jalr	1044(ra) # 80002706 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fe8080e7          	jalr	-24(ra) # 8000242e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0b878793          	addi	a5,a5,184 # 80021530 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b8e080e7          	jalr	-1138(ra) # 8000242e <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	976080e7          	jalr	-1674(ra) # 800022a2 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e2e080e7          	jalr	-466(ra) # 800019ac <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dfc080e7          	jalr	-516(ra) # 800019ac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df0080e7          	jalr	-528(ra) # 800019ac <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dd8080e7          	jalr	-552(ra) # 800019ac <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d98080e7          	jalr	-616(ra) # 800019ac <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d6c080e7          	jalr	-660(ra) # 800019ac <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b06080e7          	jalr	-1274(ra) # 8000199c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	aea080e7          	jalr	-1302(ra) # 8000199c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	972080e7          	jalr	-1678(ra) # 80002846 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f04080e7          	jalr	-252(ra) # 80005de0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	20c080e7          	jalr	524(ra) # 800020f0 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	8d2080e7          	jalr	-1838(ra) # 8000281e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8f2080e7          	jalr	-1806(ra) # 80002846 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e6e080e7          	jalr	-402(ra) # 80005dca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e7c080e7          	jalr	-388(ra) # 80005de0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	05a080e7          	jalr	90(ra) # 80002fc6 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6ea080e7          	jalr	1770(ra) # 8000365e <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	694080e7          	jalr	1684(ra) # 80004610 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f7e080e7          	jalr	-130(ra) # 80005f02 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d44080e7          	jalr	-700(ra) # 80001cd0 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e9448493          	addi	s1,s1,-364 # 800116e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	a7aa0a13          	addi	s4,s4,-1414 # 800172e8 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17048493          	addi	s1,s1,368
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  initlock(&threadid_lock, "nextthreadid");
    80001918:	00007597          	auipc	a1,0x7
    8000191c:	8e058593          	addi	a1,a1,-1824 # 800081f8 <digits+0x1b8>
    80001920:	00010517          	auipc	a0,0x10
    80001924:	9b050513          	addi	a0,a0,-1616 # 800112d0 <threadid_lock>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	22c080e7          	jalr	556(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00010497          	auipc	s1,0x10
    80001934:	db848493          	addi	s1,s1,-584 # 800116e8 <proc>
      initlock(&p->lock, "proc");
    80001938:	00007b17          	auipc	s6,0x7
    8000193c:	8d0b0b13          	addi	s6,s6,-1840 # 80008208 <digits+0x1c8>
      p->kstack = KSTACK((int) (p - proc));
    80001940:	8aa6                	mv	s5,s1
    80001942:	00006a17          	auipc	s4,0x6
    80001946:	6bea0a13          	addi	s4,s4,1726 # 80008000 <etext>
    8000194a:	04000937          	lui	s2,0x4000
    8000194e:	197d                	addi	s2,s2,-1
    80001950:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001952:	00016997          	auipc	s3,0x16
    80001956:	99698993          	addi	s3,s3,-1642 # 800172e8 <tickslock>
      initlock(&p->lock, "proc");
    8000195a:	85da                	mv	a1,s6
    8000195c:	8526                	mv	a0,s1
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	1f6080e7          	jalr	502(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001966:	415487b3          	sub	a5,s1,s5
    8000196a:	8791                	srai	a5,a5,0x4
    8000196c:	000a3703          	ld	a4,0(s4)
    80001970:	02e787b3          	mul	a5,a5,a4
    80001974:	2785                	addiw	a5,a5,1
    80001976:	00d7979b          	slliw	a5,a5,0xd
    8000197a:	40f907b3          	sub	a5,s2,a5
    8000197e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001980:	17048493          	addi	s1,s1,368
    80001984:	fd349be3          	bne	s1,s3,8000195a <procinit+0x86>
  }
}
    80001988:	70e2                	ld	ra,56(sp)
    8000198a:	7442                	ld	s0,48(sp)
    8000198c:	74a2                	ld	s1,40(sp)
    8000198e:	7902                	ld	s2,32(sp)
    80001990:	69e2                	ld	s3,24(sp)
    80001992:	6a42                	ld	s4,16(sp)
    80001994:	6aa2                	ld	s5,8(sp)
    80001996:	6b02                	ld	s6,0(sp)
    80001998:	6121                	addi	sp,sp,64
    8000199a:	8082                	ret

000000008000199c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a4:	2501                	sext.w	a0,a0
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
    800019b2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b4:	2781                	sext.w	a5,a5
    800019b6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b8:	00010517          	auipc	a0,0x10
    800019bc:	93050513          	addi	a0,a0,-1744 # 800112e8 <cpus>
    800019c0:	953e                	add	a0,a0,a5
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	addi	sp,sp,16
    800019c6:	8082                	ret

00000000800019c8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c8:	1101                	addi	sp,sp,-32
    800019ca:	ec06                	sd	ra,24(sp)
    800019cc:	e822                	sd	s0,16(sp)
    800019ce:	e426                	sd	s1,8(sp)
    800019d0:	1000                	addi	s0,sp,32
  push_off();
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1c6080e7          	jalr	454(ra) # 80000b98 <push_off>
    800019da:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019dc:	2781                	sext.w	a5,a5
    800019de:	079e                	slli	a5,a5,0x7
    800019e0:	00010717          	auipc	a4,0x10
    800019e4:	8c070713          	addi	a4,a4,-1856 # 800112a0 <pid_lock>
    800019e8:	97ba                	add	a5,a5,a4
    800019ea:	67a4                	ld	s1,72(a5)
  pop_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	24c080e7          	jalr	588(ra) # 80000c38 <pop_off>
  return p;
}
    800019f4:	8526                	mv	a0,s1
    800019f6:	60e2                	ld	ra,24(sp)
    800019f8:	6442                	ld	s0,16(sp)
    800019fa:	64a2                	ld	s1,8(sp)
    800019fc:	6105                	addi	sp,sp,32
    800019fe:	8082                	ret

0000000080001a00 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e406                	sd	ra,8(sp)
    80001a04:	e022                	sd	s0,0(sp)
    80001a06:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	fc0080e7          	jalr	-64(ra) # 800019c8 <myproc>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	288080e7          	jalr	648(ra) # 80000c98 <release>

  if (first) {
    80001a18:	00007797          	auipc	a5,0x7
    80001a1c:	e187a783          	lw	a5,-488(a5) # 80008830 <first.1696>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	e3c080e7          	jalr	-452(ra) # 8000285e <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
    first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	de07af23          	sw	zero,-514(a5) # 80008830 <first.1696>
    fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	ba2080e7          	jalr	-1118(ra) # 800035de <fsinit>
    80001a44:	bff9                	j	80001a22 <forkret+0x22>

0000000080001a46 <allocpid>:
allocpid() {
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	e04a                	sd	s2,0(sp)
    80001a50:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a52:	00010917          	auipc	s2,0x10
    80001a56:	84e90913          	addi	s2,s2,-1970 # 800112a0 <pid_lock>
    80001a5a:	854a                	mv	a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	188080e7          	jalr	392(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a64:	00007797          	auipc	a5,0x7
    80001a68:	dd478793          	addi	a5,a5,-556 # 80008838 <nextpid>
    80001a6c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6e:	0014871b          	addiw	a4,s1,1
    80001a72:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	222080e7          	jalr	546(ra) # 80000c98 <release>
}
    80001a7e:	8526                	mv	a0,s1
    80001a80:	60e2                	ld	ra,24(sp)
    80001a82:	6442                	ld	s0,16(sp)
    80001a84:	64a2                	ld	s1,8(sp)
    80001a86:	6902                	ld	s2,0(sp)
    80001a88:	6105                	addi	sp,sp,32
    80001a8a:	8082                	ret

0000000080001a8c <proc_pagetable>:
{
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
    80001a98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	8a0080e7          	jalr	-1888(ra) # 8000133a <uvmcreate>
    80001aa2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa6:	4729                	li	a4,10
    80001aa8:	00005697          	auipc	a3,0x5
    80001aac:	55868693          	addi	a3,a3,1368 # 80007000 <_trampoline>
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	040005b7          	lui	a1,0x4000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b2                	slli	a1,a1,0xc
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	5f6080e7          	jalr	1526(ra) # 800010b0 <mappages>
    80001ac2:	02054863          	bltz	a0,80001af2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac6:	4719                	li	a4,6
    80001ac8:	05893683          	ld	a3,88(s2)
    80001acc:	6605                	lui	a2,0x1
    80001ace:	020005b7          	lui	a1,0x2000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b6                	slli	a1,a1,0xd
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	5d8080e7          	jalr	1496(ra) # 800010b0 <mappages>
    80001ae0:	02054163          	bltz	a0,80001b02 <proc_pagetable+0x76>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret
    uvmfree(pagetable, 0);
    80001af2:	4581                	li	a1,0
    80001af4:	8526                	mv	a0,s1
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	a40080e7          	jalr	-1472(ra) # 80001536 <uvmfree>
    return 0;
    80001afe:	4481                	li	s1,0
    80001b00:	b7d5                	j	80001ae4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	766080e7          	jalr	1894(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b18:	4581                	li	a1,0
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	a1a080e7          	jalr	-1510(ra) # 80001536 <uvmfree>
    return 0;
    80001b24:	4481                	li	s1,0
    80001b26:	bf7d                	j	80001ae4 <proc_pagetable+0x58>

0000000080001b28 <proc_freepagetable>:
{
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	84aa                	mv	s1,a0
    80001b36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	732080e7          	jalr	1842(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4c:	4681                	li	a3,0
    80001b4e:	4605                	li	a2,1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	71c080e7          	jalr	1820(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b62:	85ca                	mv	a1,s2
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	9d0080e7          	jalr	-1584(ra) # 80001536 <uvmfree>
}
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <freeproc>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	1000                	addi	s0,sp,32
    80001b84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b86:	6d28                	ld	a0,88(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b92:	0404bc23          	sd	zero,88(s1)
  if (p->threadid !=0 && p->pagetable!=0) {
    80001b96:	1684a583          	lw	a1,360(s1)
    80001b9a:	c195                	beqz	a1,80001bbe <freeproc+0x44>
    80001b9c:	68a8                	ld	a0,80(s1)
    80001b9e:	c51d                	beqz	a0,80001bcc <freeproc+0x52>
    uvmunmap(p->pagetable, TRAPFRAME - 4096 *(p->threadid), 1, 0);
    80001ba0:	00c5959b          	slliw	a1,a1,0xc
    80001ba4:	020007b7          	lui	a5,0x2000
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	17fd                	addi	a5,a5,-1
    80001bae:	07b6                	slli	a5,a5,0xd
    80001bb0:	40b785b3          	sub	a1,a5,a1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	6c2080e7          	jalr	1730(ra) # 80001276 <uvmunmap>
    80001bbc:	a801                	j	80001bcc <freeproc+0x52>
  } else if (p->pagetable !=0) {
    80001bbe:	68a8                	ld	a0,80(s1)
    80001bc0:	c511                	beqz	a0,80001bcc <freeproc+0x52>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc2:	64ac                	ld	a1,72(s1)
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	f64080e7          	jalr	-156(ra) # 80001b28 <proc_freepagetable>
  p->pagetable = 0;
    80001bcc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd4:	0204a823          	sw	zero,48(s1)
  p->threadid =0;
    80001bd8:	1604a423          	sw	zero,360(s1)
  p->parent = 0;
    80001bdc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001be0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001be8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bec:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bf0:	0004ac23          	sw	zero,24(s1)
}
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret

0000000080001bfe <allocproc>:
{
    80001bfe:	1101                	addi	sp,sp,-32
    80001c00:	ec06                	sd	ra,24(sp)
    80001c02:	e822                	sd	s0,16(sp)
    80001c04:	e426                	sd	s1,8(sp)
    80001c06:	e04a                	sd	s2,0(sp)
    80001c08:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	00010497          	auipc	s1,0x10
    80001c0e:	ade48493          	addi	s1,s1,-1314 # 800116e8 <proc>
    80001c12:	00015917          	auipc	s2,0x15
    80001c16:	6d690913          	addi	s2,s2,1750 # 800172e8 <tickslock>
    acquire(&p->lock);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	fc8080e7          	jalr	-56(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c24:	4c9c                	lw	a5,24(s1)
    80001c26:	cf81                	beqz	a5,80001c3e <allocproc+0x40>
      release(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	17048493          	addi	s1,s1,368
    80001c36:	ff2492e3          	bne	s1,s2,80001c1a <allocproc+0x1c>
  return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	a899                	j	80001c92 <allocproc+0x94>
  p->pid = allocpid();
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e08080e7          	jalr	-504(ra) # 80001a46 <allocpid>
    80001c46:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c48:	4785                	li	a5,1
    80001c4a:	cc9c                	sw	a5,24(s1)
  p->threadid = 0;
    80001c4c:	1604a423          	sw	zero,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	ea4080e7          	jalr	-348(ra) # 80000af4 <kalloc>
    80001c58:	892a                	mv	s2,a0
    80001c5a:	eca8                	sd	a0,88(s1)
    80001c5c:	c131                	beqz	a0,80001ca0 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	e2c080e7          	jalr	-468(ra) # 80001a8c <proc_pagetable>
    80001c68:	892a                	mv	s2,a0
    80001c6a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6c:	c531                	beqz	a0,80001cb8 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c6e:	07000613          	li	a2,112
    80001c72:	4581                	li	a1,0
    80001c74:	06048513          	addi	a0,s1,96
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	068080e7          	jalr	104(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c80:	00000797          	auipc	a5,0x0
    80001c84:	d8078793          	addi	a5,a5,-640 # 80001a00 <forkret>
    80001c88:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c8a:	60bc                	ld	a5,64(s1)
    80001c8c:	6705                	lui	a4,0x1
    80001c8e:	97ba                	add	a5,a5,a4
    80001c90:	f4bc                	sd	a5,104(s1)
}
    80001c92:	8526                	mv	a0,s1
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6902                	ld	s2,0(sp)
    80001c9c:	6105                	addi	sp,sp,32
    80001c9e:	8082                	ret
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ed8080e7          	jalr	-296(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fec080e7          	jalr	-20(ra) # 80000c98 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	bff1                	j	80001c92 <allocproc+0x94>
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	ec0080e7          	jalr	-320(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fd4080e7          	jalr	-44(ra) # 80000c98 <release>
    return 0;
    80001ccc:	84ca                	mv	s1,s2
    80001cce:	b7d1                	j	80001c92 <allocproc+0x94>

0000000080001cd0 <userinit>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f24080e7          	jalr	-220(ra) # 80001bfe <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	34a7b223          	sd	a0,836(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cec:	03400613          	li	a2,52
    80001cf0:	00007597          	auipc	a1,0x7
    80001cf4:	b5058593          	addi	a1,a1,-1200 # 80008840 <initcode>
    80001cf8:	6928                	ld	a0,80(a0)
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	66e080e7          	jalr	1646(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d02:	6785                	lui	a5,0x1
    80001d04:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d10:	4641                	li	a2,16
    80001d12:	00006597          	auipc	a1,0x6
    80001d16:	4fe58593          	addi	a1,a1,1278 # 80008210 <digits+0x1d0>
    80001d1a:	15848513          	addi	a0,s1,344
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	114080e7          	jalr	276(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d26:	00006517          	auipc	a0,0x6
    80001d2a:	4fa50513          	addi	a0,a0,1274 # 80008220 <digits+0x1e0>
    80001d2e:	00002097          	auipc	ra,0x2
    80001d32:	2de080e7          	jalr	734(ra) # 8000400c <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	478d                	li	a5,3
    80001d3c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f58080e7          	jalr	-168(ra) # 80000c98 <release>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <growproc>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	c68080e7          	jalr	-920(ra) # 800019c8 <myproc>
    80001d68:	892a                	mv	s2,a0
  sz = p->sz;
    80001d6a:	652c                	ld	a1,72(a0)
    80001d6c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d70:	00904f63          	bgtz	s1,80001d8e <growproc+0x3c>
  } else if(n < 0){
    80001d74:	0204cc63          	bltz	s1,80001dac <growproc+0x5a>
  p->sz = sz;
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d80:	4501                	li	a0,0
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6902                	ld	s2,0(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d8e:	9e25                	addw	a2,a2,s1
    80001d90:	1602                	slli	a2,a2,0x20
    80001d92:	9201                	srli	a2,a2,0x20
    80001d94:	1582                	slli	a1,a1,0x20
    80001d96:	9181                	srli	a1,a1,0x20
    80001d98:	6928                	ld	a0,80(a0)
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	688080e7          	jalr	1672(ra) # 80001422 <uvmalloc>
    80001da2:	0005061b          	sext.w	a2,a0
    80001da6:	fa69                	bnez	a2,80001d78 <growproc+0x26>
      return -1;
    80001da8:	557d                	li	a0,-1
    80001daa:	bfe1                	j	80001d82 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dac:	9e25                	addw	a2,a2,s1
    80001dae:	1602                	slli	a2,a2,0x20
    80001db0:	9201                	srli	a2,a2,0x20
    80001db2:	1582                	slli	a1,a1,0x20
    80001db4:	9181                	srli	a1,a1,0x20
    80001db6:	6928                	ld	a0,80(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	622080e7          	jalr	1570(ra) # 800013da <uvmdealloc>
    80001dc0:	0005061b          	sext.w	a2,a0
    80001dc4:	bf55                	j	80001d78 <growproc+0x26>

0000000080001dc6 <fork>:
{
    80001dc6:	7179                	addi	sp,sp,-48
    80001dc8:	f406                	sd	ra,40(sp)
    80001dca:	f022                	sd	s0,32(sp)
    80001dcc:	ec26                	sd	s1,24(sp)
    80001dce:	e84a                	sd	s2,16(sp)
    80001dd0:	e44e                	sd	s3,8(sp)
    80001dd2:	e052                	sd	s4,0(sp)
    80001dd4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	bf2080e7          	jalr	-1038(ra) # 800019c8 <myproc>
    80001dde:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	e1e080e7          	jalr	-482(ra) # 80001bfe <allocproc>
    80001de8:	10050b63          	beqz	a0,80001efe <fork+0x138>
    80001dec:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dee:	04893603          	ld	a2,72(s2)
    80001df2:	692c                	ld	a1,80(a0)
    80001df4:	05093503          	ld	a0,80(s2)
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	776080e7          	jalr	1910(ra) # 8000156e <uvmcopy>
    80001e00:	04054663          	bltz	a0,80001e4c <fork+0x86>
  np->sz = p->sz;
    80001e04:	04893783          	ld	a5,72(s2)
    80001e08:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e0c:	05893683          	ld	a3,88(s2)
    80001e10:	87b6                	mv	a5,a3
    80001e12:	0589b703          	ld	a4,88(s3)
    80001e16:	12068693          	addi	a3,a3,288
    80001e1a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1e:	6788                	ld	a0,8(a5)
    80001e20:	6b8c                	ld	a1,16(a5)
    80001e22:	6f90                	ld	a2,24(a5)
    80001e24:	01073023          	sd	a6,0(a4)
    80001e28:	e708                	sd	a0,8(a4)
    80001e2a:	eb0c                	sd	a1,16(a4)
    80001e2c:	ef10                	sd	a2,24(a4)
    80001e2e:	02078793          	addi	a5,a5,32
    80001e32:	02070713          	addi	a4,a4,32
    80001e36:	fed792e3          	bne	a5,a3,80001e1a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e3a:	0589b783          	ld	a5,88(s3)
    80001e3e:	0607b823          	sd	zero,112(a5)
    80001e42:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e46:	15000a13          	li	s4,336
    80001e4a:	a03d                	j	80001e78 <fork+0xb2>
    freeproc(np);
    80001e4c:	854e                	mv	a0,s3
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	d2c080e7          	jalr	-724(ra) # 80001b7a <freeproc>
    release(&np->lock);
    80001e56:	854e                	mv	a0,s3
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e40080e7          	jalr	-448(ra) # 80000c98 <release>
    return -1;
    80001e60:	5a7d                	li	s4,-1
    80001e62:	a069                	j	80001eec <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e64:	00003097          	auipc	ra,0x3
    80001e68:	83e080e7          	jalr	-1986(ra) # 800046a2 <filedup>
    80001e6c:	009987b3          	add	a5,s3,s1
    80001e70:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e72:	04a1                	addi	s1,s1,8
    80001e74:	01448763          	beq	s1,s4,80001e82 <fork+0xbc>
    if(p->ofile[i])
    80001e78:	009907b3          	add	a5,s2,s1
    80001e7c:	6388                	ld	a0,0(a5)
    80001e7e:	f17d                	bnez	a0,80001e64 <fork+0x9e>
    80001e80:	bfcd                	j	80001e72 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e82:	15093503          	ld	a0,336(s2)
    80001e86:	00002097          	auipc	ra,0x2
    80001e8a:	992080e7          	jalr	-1646(ra) # 80003818 <idup>
    80001e8e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e92:	4641                	li	a2,16
    80001e94:	15890593          	addi	a1,s2,344
    80001e98:	15898513          	addi	a0,s3,344
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	f96080e7          	jalr	-106(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ea4:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ea8:	854e                	mv	a0,s3
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eb2:	0000f497          	auipc	s1,0xf
    80001eb6:	40648493          	addi	s1,s1,1030 # 800112b8 <wait_lock>
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ec4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ed2:	854e                	mv	a0,s3
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	d10080e7          	jalr	-752(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001edc:	478d                	li	a5,3
    80001ede:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	db4080e7          	jalr	-588(ra) # 80000c98 <release>
}
    80001eec:	8552                	mv	a0,s4
    80001eee:	70a2                	ld	ra,40(sp)
    80001ef0:	7402                	ld	s0,32(sp)
    80001ef2:	64e2                	ld	s1,24(sp)
    80001ef4:	6942                	ld	s2,16(sp)
    80001ef6:	69a2                	ld	s3,8(sp)
    80001ef8:	6a02                	ld	s4,0(sp)
    80001efa:	6145                	addi	sp,sp,48
    80001efc:	8082                	ret
    return -1;
    80001efe:	5a7d                	li	s4,-1
    80001f00:	b7f5                	j	80001eec <fork+0x126>

0000000080001f02 <clone>:
{
    80001f02:	7179                	addi	sp,sp,-48
    80001f04:	f406                	sd	ra,40(sp)
    80001f06:	f022                	sd	s0,32(sp)
    80001f08:	ec26                	sd	s1,24(sp)
    80001f0a:	e84a                	sd	s2,16(sp)
    80001f0c:	e44e                	sd	s3,8(sp)
    80001f0e:	e052                	sd	s4,0(sp)
    80001f10:	1800                	addi	s0,sp,48
    80001f12:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	ab4080e7          	jalr	-1356(ra) # 800019c8 <myproc>
  if (stack == 0) {
    80001f1c:	1c0a0863          	beqz	s4,800020ec <clone+0x1ea>
    80001f20:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f22:	0000f497          	auipc	s1,0xf
    80001f26:	7c648493          	addi	s1,s1,1990 # 800116e8 <proc>
    80001f2a:	00015917          	auipc	s2,0x15
    80001f2e:	3be90913          	addi	s2,s2,958 # 800172e8 <tickslock>
    acquire(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f3c:	4c9c                	lw	a5,24(s1)
    80001f3e:	cf81                	beqz	a5,80001f56 <clone+0x54>
      release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f4a:	17048493          	addi	s1,s1,368
    80001f4e:	ff2492e3          	bne	s1,s2,80001f32 <clone+0x30>
    return -1;
    80001f52:	5a7d                	li	s4,-1
    80001f54:	a259                	j	800020da <clone+0x1d8>
  p->pid = allocpid();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	af0080e7          	jalr	-1296(ra) # 80001a46 <allocpid>
    80001f5e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f60:	4785                	li	a5,1
    80001f62:	cc9c                	sw	a5,24(s1)
  p->threadid = allocpid();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	ae2080e7          	jalr	-1310(ra) # 80001a46 <allocpid>
    80001f6c:	16a4a423          	sw	a0,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	b84080e7          	jalr	-1148(ra) # 80000af4 <kalloc>
    80001f78:	eca8                	sd	a0,88(s1)
    80001f7a:	cd59                	beqz	a0,80002018 <clone+0x116>
  memset(&p->context, 0, sizeof(p->context));
    80001f7c:	07000613          	li	a2,112
    80001f80:	4581                	li	a1,0
    80001f82:	06048513          	addi	a0,s1,96
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d5a080e7          	jalr	-678(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f8e:	00000797          	auipc	a5,0x0
    80001f92:	a7278793          	addi	a5,a5,-1422 # 80001a00 <forkret>
    80001f96:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f98:	60bc                	ld	a5,64(s1)
    80001f9a:	6705                	lui	a4,0x1
    80001f9c:	97ba                	add	a5,a5,a4
    80001f9e:	f4bc                	sd	a5,104(s1)
  np->pagetable = p->pagetable;
    80001fa0:	0509b503          	ld	a0,80(s3)
    80001fa4:	e8a8                	sd	a0,80(s1)
  if(mappages(np->pagetable, TRAPFRAME - (4096 * np->threadid), 4096, 
    80001fa6:	1684a583          	lw	a1,360(s1)
    80001faa:	00c5959b          	slliw	a1,a1,0xc
    80001fae:	020007b7          	lui	a5,0x2000
    80001fb2:	4719                	li	a4,6
    80001fb4:	6cb4                	ld	a3,88(s1)
    80001fb6:	6605                	lui	a2,0x1
    80001fb8:	17fd                	addi	a5,a5,-1
    80001fba:	07b6                	slli	a5,a5,0xd
    80001fbc:	40b785b3          	sub	a1,a5,a1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	0f0080e7          	jalr	240(ra) # 800010b0 <mappages>
    80001fc8:	06054363          	bltz	a0,8000202e <clone+0x12c>
  np->sz = p->sz;
    80001fcc:	0489b783          	ld	a5,72(s3)
    80001fd0:	e4bc                	sd	a5,72(s1)
  *(np->trapframe) = *(p->trapframe);  
    80001fd2:	0589b683          	ld	a3,88(s3)
    80001fd6:	87b6                	mv	a5,a3
    80001fd8:	6cb8                	ld	a4,88(s1)
    80001fda:	12068693          	addi	a3,a3,288
    80001fde:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001fe2:	6788                	ld	a0,8(a5)
    80001fe4:	6b8c                	ld	a1,16(a5)
    80001fe6:	6f90                	ld	a2,24(a5)
    80001fe8:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001fec:	e708                	sd	a0,8(a4)
    80001fee:	eb0c                	sd	a1,16(a4)
    80001ff0:	ef10                	sd	a2,24(a4)
    80001ff2:	02078793          	addi	a5,a5,32
    80001ff6:	02070713          	addi	a4,a4,32
    80001ffa:	fed792e3          	bne	a5,a3,80001fde <clone+0xdc>
  np->trapframe->sp = (uint64) (stack + size);
    80001ffe:	6cbc                	ld	a5,88(s1)
    80002000:	6705                	lui	a4,0x1
    80002002:	9a3a                	add	s4,s4,a4
    80002004:	0347b823          	sd	s4,48(a5)
  np->trapframe->a0 = 0;  
    80002008:	6cbc                	ld	a5,88(s1)
    8000200a:	0607b823          	sd	zero,112(a5)
    8000200e:	0d000913          	li	s2,208
  for(i = 0; i < NOFILE; i++)// increment reference counts on open file descriptors
    80002012:	15000a13          	li	s4,336
    80002016:	a889                	j	80002068 <clone+0x166>
    freeproc(p);
    80002018:	8526                	mv	a0,s1
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	b60080e7          	jalr	-1184(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c74080e7          	jalr	-908(ra) # 80000c98 <release>
    return 0;
    8000202c:	b71d                	j	80001f52 <clone+0x50>
    uvmunmap(np->pagetable, TRAMPOLINE, 1, 0);
    8000202e:	4681                	li	a3,0
    80002030:	4605                	li	a2,1
    80002032:	040005b7          	lui	a1,0x4000
    80002036:	15fd                	addi	a1,a1,-1
    80002038:	05b2                	slli	a1,a1,0xc
    8000203a:	68a8                	ld	a0,80(s1)
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	23a080e7          	jalr	570(ra) # 80001276 <uvmunmap>
    uvmfree(np->pagetable, 0);
    80002044:	4581                	li	a1,0
    80002046:	68a8                	ld	a0,80(s1)
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	4ee080e7          	jalr	1262(ra) # 80001536 <uvmfree>
    return 0;
    80002050:	4a01                	li	s4,0
    80002052:	a061                	j	800020da <clone+0x1d8>
      np->ofile[i] = filedup(p->ofile[i]);
    80002054:	00002097          	auipc	ra,0x2
    80002058:	64e080e7          	jalr	1614(ra) # 800046a2 <filedup>
    8000205c:	012487b3          	add	a5,s1,s2
    80002060:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)// increment reference counts on open file descriptors
    80002062:	0921                	addi	s2,s2,8
    80002064:	01490763          	beq	s2,s4,80002072 <clone+0x170>
    if(p->ofile[i])
    80002068:	012987b3          	add	a5,s3,s2
    8000206c:	6388                	ld	a0,0(a5)
    8000206e:	f17d                	bnez	a0,80002054 <clone+0x152>
    80002070:	bfcd                	j	80002062 <clone+0x160>
  np->cwd = idup(p->cwd);
    80002072:	1509b503          	ld	a0,336(s3)
    80002076:	00001097          	auipc	ra,0x1
    8000207a:	7a2080e7          	jalr	1954(ra) # 80003818 <idup>
    8000207e:	14a4b823          	sd	a0,336(s1)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002082:	4641                	li	a2,16
    80002084:	15898593          	addi	a1,s3,344
    80002088:	15848513          	addi	a0,s1,344
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	da6080e7          	jalr	-602(ra) # 80000e32 <safestrcpy>
  threadid = np->threadid;
    80002094:	1684aa03          	lw	s4,360(s1)
  release(&np->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800020a2:	0000f917          	auipc	s2,0xf
    800020a6:	21690913          	addi	s2,s2,534 # 800112b8 <wait_lock>
    800020aa:	854a                	mv	a0,s2
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
  np->parent = p;
    800020b4:	0334bc23          	sd	s3,56(s1)
  release(&wait_lock);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bde080e7          	jalr	-1058(ra) # 80000c98 <release>
  acquire(&np->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b20080e7          	jalr	-1248(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	cc9c                	sw	a5,24(s1)
  release(&np->lock);
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	bc6080e7          	jalr	-1082(ra) # 80000c98 <release>
}
    800020da:	8552                	mv	a0,s4
    800020dc:	70a2                	ld	ra,40(sp)
    800020de:	7402                	ld	s0,32(sp)
    800020e0:	64e2                	ld	s1,24(sp)
    800020e2:	6942                	ld	s2,16(sp)
    800020e4:	69a2                	ld	s3,8(sp)
    800020e6:	6a02                	ld	s4,0(sp)
    800020e8:	6145                	addi	sp,sp,48
    800020ea:	8082                	ret
    return -1;
    800020ec:	5a7d                	li	s4,-1
    800020ee:	b7f5                	j	800020da <clone+0x1d8>

00000000800020f0 <scheduler>:
{
    800020f0:	7139                	addi	sp,sp,-64
    800020f2:	fc06                	sd	ra,56(sp)
    800020f4:	f822                	sd	s0,48(sp)
    800020f6:	f426                	sd	s1,40(sp)
    800020f8:	f04a                	sd	s2,32(sp)
    800020fa:	ec4e                	sd	s3,24(sp)
    800020fc:	e852                	sd	s4,16(sp)
    800020fe:	e456                	sd	s5,8(sp)
    80002100:	e05a                	sd	s6,0(sp)
    80002102:	0080                	addi	s0,sp,64
    80002104:	8792                	mv	a5,tp
  int id = r_tp();
    80002106:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002108:	00779a93          	slli	s5,a5,0x7
    8000210c:	0000f717          	auipc	a4,0xf
    80002110:	19470713          	addi	a4,a4,404 # 800112a0 <pid_lock>
    80002114:	9756                	add	a4,a4,s5
    80002116:	04073423          	sd	zero,72(a4)
        swtch(&c->context, &p->context);
    8000211a:	0000f717          	auipc	a4,0xf
    8000211e:	1d670713          	addi	a4,a4,470 # 800112f0 <cpus+0x8>
    80002122:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002124:	498d                	li	s3,3
        p->state = RUNNING;
    80002126:	4b11                	li	s6,4
        c->proc = p;
    80002128:	079e                	slli	a5,a5,0x7
    8000212a:	0000fa17          	auipc	s4,0xf
    8000212e:	176a0a13          	addi	s4,s4,374 # 800112a0 <pid_lock>
    80002132:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002134:	00015917          	auipc	s2,0x15
    80002138:	1b490913          	addi	s2,s2,436 # 800172e8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000213c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002140:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002144:	10079073          	csrw	sstatus,a5
    80002148:	0000f497          	auipc	s1,0xf
    8000214c:	5a048493          	addi	s1,s1,1440 # 800116e8 <proc>
    80002150:	a03d                	j	8000217e <scheduler+0x8e>
        p->state = RUNNING;
    80002152:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002156:	049a3423          	sd	s1,72(s4)
        swtch(&c->context, &p->context);
    8000215a:	06048593          	addi	a1,s1,96
    8000215e:	8556                	mv	a0,s5
    80002160:	00000097          	auipc	ra,0x0
    80002164:	654080e7          	jalr	1620(ra) # 800027b4 <swtch>
        c->proc = 0;
    80002168:	040a3423          	sd	zero,72(s4)
      release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002176:	17048493          	addi	s1,s1,368
    8000217a:	fd2481e3          	beq	s1,s2,8000213c <scheduler+0x4c>
      acquire(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a64080e7          	jalr	-1436(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002188:	4c9c                	lw	a5,24(s1)
    8000218a:	ff3791e3          	bne	a5,s3,8000216c <scheduler+0x7c>
    8000218e:	b7d1                	j	80002152 <scheduler+0x62>

0000000080002190 <sched>:
{
    80002190:	7179                	addi	sp,sp,-48
    80002192:	f406                	sd	ra,40(sp)
    80002194:	f022                	sd	s0,32(sp)
    80002196:	ec26                	sd	s1,24(sp)
    80002198:	e84a                	sd	s2,16(sp)
    8000219a:	e44e                	sd	s3,8(sp)
    8000219c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	82a080e7          	jalr	-2006(ra) # 800019c8 <myproc>
    800021a6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	9c2080e7          	jalr	-1598(ra) # 80000b6a <holding>
    800021b0:	c93d                	beqz	a0,80002226 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021b4:	2781                	sext.w	a5,a5
    800021b6:	079e                	slli	a5,a5,0x7
    800021b8:	0000f717          	auipc	a4,0xf
    800021bc:	0e870713          	addi	a4,a4,232 # 800112a0 <pid_lock>
    800021c0:	97ba                	add	a5,a5,a4
    800021c2:	0c07a703          	lw	a4,192(a5)
    800021c6:	4785                	li	a5,1
    800021c8:	06f71763          	bne	a4,a5,80002236 <sched+0xa6>
  if(p->state == RUNNING)
    800021cc:	4c98                	lw	a4,24(s1)
    800021ce:	4791                	li	a5,4
    800021d0:	06f70b63          	beq	a4,a5,80002246 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021d4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021d8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021da:	efb5                	bnez	a5,80002256 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021dc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021de:	0000f917          	auipc	s2,0xf
    800021e2:	0c290913          	addi	s2,s2,194 # 800112a0 <pid_lock>
    800021e6:	2781                	sext.w	a5,a5
    800021e8:	079e                	slli	a5,a5,0x7
    800021ea:	97ca                	add	a5,a5,s2
    800021ec:	0c47a983          	lw	s3,196(a5)
    800021f0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021f2:	2781                	sext.w	a5,a5
    800021f4:	079e                	slli	a5,a5,0x7
    800021f6:	0000f597          	auipc	a1,0xf
    800021fa:	0fa58593          	addi	a1,a1,250 # 800112f0 <cpus+0x8>
    800021fe:	95be                	add	a1,a1,a5
    80002200:	06048513          	addi	a0,s1,96
    80002204:	00000097          	auipc	ra,0x0
    80002208:	5b0080e7          	jalr	1456(ra) # 800027b4 <swtch>
    8000220c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000220e:	2781                	sext.w	a5,a5
    80002210:	079e                	slli	a5,a5,0x7
    80002212:	97ca                	add	a5,a5,s2
    80002214:	0d37a223          	sw	s3,196(a5)
}
    80002218:	70a2                	ld	ra,40(sp)
    8000221a:	7402                	ld	s0,32(sp)
    8000221c:	64e2                	ld	s1,24(sp)
    8000221e:	6942                	ld	s2,16(sp)
    80002220:	69a2                	ld	s3,8(sp)
    80002222:	6145                	addi	sp,sp,48
    80002224:	8082                	ret
    panic("sched p->lock");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	00250513          	addi	a0,a0,2 # 80008228 <digits+0x1e8>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    panic("sched locks");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	00250513          	addi	a0,a0,2 # 80008238 <digits+0x1f8>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	300080e7          	jalr	768(ra) # 8000053e <panic>
    panic("sched running");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	00250513          	addi	a0,a0,2 # 80008248 <digits+0x208>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2f0080e7          	jalr	752(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002256:	00006517          	auipc	a0,0x6
    8000225a:	00250513          	addi	a0,a0,2 # 80008258 <digits+0x218>
    8000225e:	ffffe097          	auipc	ra,0xffffe
    80002262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>

0000000080002266 <yield>:
{
    80002266:	1101                	addi	sp,sp,-32
    80002268:	ec06                	sd	ra,24(sp)
    8000226a:	e822                	sd	s0,16(sp)
    8000226c:	e426                	sd	s1,8(sp)
    8000226e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	758080e7          	jalr	1880(ra) # 800019c8 <myproc>
    80002278:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	96a080e7          	jalr	-1686(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002282:	478d                	li	a5,3
    80002284:	cc9c                	sw	a5,24(s1)
  sched();
    80002286:	00000097          	auipc	ra,0x0
    8000228a:	f0a080e7          	jalr	-246(ra) # 80002190 <sched>
  release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a08080e7          	jalr	-1528(ra) # 80000c98 <release>
}
    80002298:	60e2                	ld	ra,24(sp)
    8000229a:	6442                	ld	s0,16(sp)
    8000229c:	64a2                	ld	s1,8(sp)
    8000229e:	6105                	addi	sp,sp,32
    800022a0:	8082                	ret

00000000800022a2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022a2:	7179                	addi	sp,sp,-48
    800022a4:	f406                	sd	ra,40(sp)
    800022a6:	f022                	sd	s0,32(sp)
    800022a8:	ec26                	sd	s1,24(sp)
    800022aa:	e84a                	sd	s2,16(sp)
    800022ac:	e44e                	sd	s3,8(sp)
    800022ae:	1800                	addi	s0,sp,48
    800022b0:	89aa                	mv	s3,a0
    800022b2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	714080e7          	jalr	1812(ra) # 800019c8 <myproc>
    800022bc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  release(lk);
    800022c6:	854a                	mv	a0,s2
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9d0080e7          	jalr	-1584(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800022d0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022d4:	4789                	li	a5,2
    800022d6:	cc9c                	sw	a5,24(s1)

  sched();
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	eb8080e7          	jalr	-328(ra) # 80002190 <sched>

  p->chan = 0;
    800022e0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9b2080e7          	jalr	-1614(ra) # 80000c98 <release>
  acquire(lk);
    800022ee:	854a                	mv	a0,s2
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	8f4080e7          	jalr	-1804(ra) # 80000be4 <acquire>
}
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6145                	addi	sp,sp,48
    80002304:	8082                	ret

0000000080002306 <wait>:
{
    80002306:	715d                	addi	sp,sp,-80
    80002308:	e486                	sd	ra,72(sp)
    8000230a:	e0a2                	sd	s0,64(sp)
    8000230c:	fc26                	sd	s1,56(sp)
    8000230e:	f84a                	sd	s2,48(sp)
    80002310:	f44e                	sd	s3,40(sp)
    80002312:	f052                	sd	s4,32(sp)
    80002314:	ec56                	sd	s5,24(sp)
    80002316:	e85a                	sd	s6,16(sp)
    80002318:	e45e                	sd	s7,8(sp)
    8000231a:	e062                	sd	s8,0(sp)
    8000231c:	0880                	addi	s0,sp,80
    8000231e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	6a8080e7          	jalr	1704(ra) # 800019c8 <myproc>
    80002328:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000232a:	0000f517          	auipc	a0,0xf
    8000232e:	f8e50513          	addi	a0,a0,-114 # 800112b8 <wait_lock>
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
    havekids = 0;
    8000233a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000233c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000233e:	00015997          	auipc	s3,0x15
    80002342:	faa98993          	addi	s3,s3,-86 # 800172e8 <tickslock>
        havekids = 1;
    80002346:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002348:	0000fc17          	auipc	s8,0xf
    8000234c:	f70c0c13          	addi	s8,s8,-144 # 800112b8 <wait_lock>
    havekids = 0;
    80002350:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002352:	0000f497          	auipc	s1,0xf
    80002356:	39648493          	addi	s1,s1,918 # 800116e8 <proc>
    8000235a:	a0bd                	j	800023c8 <wait+0xc2>
          pid = np->pid;
    8000235c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002360:	000b0e63          	beqz	s6,8000237c <wait+0x76>
    80002364:	4691                	li	a3,4
    80002366:	02c48613          	addi	a2,s1,44
    8000236a:	85da                	mv	a1,s6
    8000236c:	05093503          	ld	a0,80(s2)
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	302080e7          	jalr	770(ra) # 80001672 <copyout>
    80002378:	02054563          	bltz	a0,800023a2 <wait+0x9c>
          freeproc(np);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	7fc080e7          	jalr	2044(ra) # 80001b7a <freeproc>
          release(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
          release(&wait_lock);
    80002390:	0000f517          	auipc	a0,0xf
    80002394:	f2850513          	addi	a0,a0,-216 # 800112b8 <wait_lock>
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
          return pid;
    800023a0:	a09d                	j	80002406 <wait+0x100>
            release(&np->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
            release(&wait_lock);
    800023ac:	0000f517          	auipc	a0,0xf
    800023b0:	f0c50513          	addi	a0,a0,-244 # 800112b8 <wait_lock>
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8e4080e7          	jalr	-1820(ra) # 80000c98 <release>
            return -1;
    800023bc:	59fd                	li	s3,-1
    800023be:	a0a1                	j	80002406 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023c0:	17048493          	addi	s1,s1,368
    800023c4:	03348463          	beq	s1,s3,800023ec <wait+0xe6>
      if(np->parent == p){
    800023c8:	7c9c                	ld	a5,56(s1)
    800023ca:	ff279be3          	bne	a5,s2,800023c0 <wait+0xba>
        acquire(&np->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	814080e7          	jalr	-2028(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023d8:	4c9c                	lw	a5,24(s1)
    800023da:	f94781e3          	beq	a5,s4,8000235c <wait+0x56>
        release(&np->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
        havekids = 1;
    800023e8:	8756                	mv	a4,s5
    800023ea:	bfd9                	j	800023c0 <wait+0xba>
    if(!havekids || p->killed){
    800023ec:	c701                	beqz	a4,800023f4 <wait+0xee>
    800023ee:	02892783          	lw	a5,40(s2)
    800023f2:	c79d                	beqz	a5,80002420 <wait+0x11a>
      release(&wait_lock);
    800023f4:	0000f517          	auipc	a0,0xf
    800023f8:	ec450513          	addi	a0,a0,-316 # 800112b8 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
      return -1;
    80002404:	59fd                	li	s3,-1
}
    80002406:	854e                	mv	a0,s3
    80002408:	60a6                	ld	ra,72(sp)
    8000240a:	6406                	ld	s0,64(sp)
    8000240c:	74e2                	ld	s1,56(sp)
    8000240e:	7942                	ld	s2,48(sp)
    80002410:	79a2                	ld	s3,40(sp)
    80002412:	7a02                	ld	s4,32(sp)
    80002414:	6ae2                	ld	s5,24(sp)
    80002416:	6b42                	ld	s6,16(sp)
    80002418:	6ba2                	ld	s7,8(sp)
    8000241a:	6c02                	ld	s8,0(sp)
    8000241c:	6161                	addi	sp,sp,80
    8000241e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002420:	85e2                	mv	a1,s8
    80002422:	854a                	mv	a0,s2
    80002424:	00000097          	auipc	ra,0x0
    80002428:	e7e080e7          	jalr	-386(ra) # 800022a2 <sleep>
    havekids = 0;
    8000242c:	b715                	j	80002350 <wait+0x4a>

000000008000242e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000242e:	7139                	addi	sp,sp,-64
    80002430:	fc06                	sd	ra,56(sp)
    80002432:	f822                	sd	s0,48(sp)
    80002434:	f426                	sd	s1,40(sp)
    80002436:	f04a                	sd	s2,32(sp)
    80002438:	ec4e                	sd	s3,24(sp)
    8000243a:	e852                	sd	s4,16(sp)
    8000243c:	e456                	sd	s5,8(sp)
    8000243e:	0080                	addi	s0,sp,64
    80002440:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002442:	0000f497          	auipc	s1,0xf
    80002446:	2a648493          	addi	s1,s1,678 # 800116e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000244a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000244c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000244e:	00015917          	auipc	s2,0x15
    80002452:	e9a90913          	addi	s2,s2,-358 # 800172e8 <tickslock>
    80002456:	a821                	j	8000246e <wakeup+0x40>
        p->state = RUNNABLE;
    80002458:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	83a080e7          	jalr	-1990(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002466:	17048493          	addi	s1,s1,368
    8000246a:	03248463          	beq	s1,s2,80002492 <wakeup+0x64>
    if(p != myproc()){
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	55a080e7          	jalr	1370(ra) # 800019c8 <myproc>
    80002476:	fea488e3          	beq	s1,a0,80002466 <wakeup+0x38>
      acquire(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	ffffe097          	auipc	ra,0xffffe
    80002480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002484:	4c9c                	lw	a5,24(s1)
    80002486:	fd379be3          	bne	a5,s3,8000245c <wakeup+0x2e>
    8000248a:	709c                	ld	a5,32(s1)
    8000248c:	fd4798e3          	bne	a5,s4,8000245c <wakeup+0x2e>
    80002490:	b7e1                	j	80002458 <wakeup+0x2a>
    }
  }
}
    80002492:	70e2                	ld	ra,56(sp)
    80002494:	7442                	ld	s0,48(sp)
    80002496:	74a2                	ld	s1,40(sp)
    80002498:	7902                	ld	s2,32(sp)
    8000249a:	69e2                	ld	s3,24(sp)
    8000249c:	6a42                	ld	s4,16(sp)
    8000249e:	6aa2                	ld	s5,8(sp)
    800024a0:	6121                	addi	sp,sp,64
    800024a2:	8082                	ret

00000000800024a4 <reparent>:
{
    800024a4:	7179                	addi	sp,sp,-48
    800024a6:	f406                	sd	ra,40(sp)
    800024a8:	f022                	sd	s0,32(sp)
    800024aa:	ec26                	sd	s1,24(sp)
    800024ac:	e84a                	sd	s2,16(sp)
    800024ae:	e44e                	sd	s3,8(sp)
    800024b0:	e052                	sd	s4,0(sp)
    800024b2:	1800                	addi	s0,sp,48
    800024b4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b6:	0000f497          	auipc	s1,0xf
    800024ba:	23248493          	addi	s1,s1,562 # 800116e8 <proc>
      pp->parent = initproc;
    800024be:	00007a17          	auipc	s4,0x7
    800024c2:	b6aa0a13          	addi	s4,s4,-1174 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024c6:	00015997          	auipc	s3,0x15
    800024ca:	e2298993          	addi	s3,s3,-478 # 800172e8 <tickslock>
    800024ce:	a029                	j	800024d8 <reparent+0x34>
    800024d0:	17048493          	addi	s1,s1,368
    800024d4:	01348d63          	beq	s1,s3,800024ee <reparent+0x4a>
    if(pp->parent == p){
    800024d8:	7c9c                	ld	a5,56(s1)
    800024da:	ff279be3          	bne	a5,s2,800024d0 <reparent+0x2c>
      pp->parent = initproc;
    800024de:	000a3503          	ld	a0,0(s4)
    800024e2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	f4a080e7          	jalr	-182(ra) # 8000242e <wakeup>
    800024ec:	b7d5                	j	800024d0 <reparent+0x2c>
}
    800024ee:	70a2                	ld	ra,40(sp)
    800024f0:	7402                	ld	s0,32(sp)
    800024f2:	64e2                	ld	s1,24(sp)
    800024f4:	6942                	ld	s2,16(sp)
    800024f6:	69a2                	ld	s3,8(sp)
    800024f8:	6a02                	ld	s4,0(sp)
    800024fa:	6145                	addi	sp,sp,48
    800024fc:	8082                	ret

00000000800024fe <exit>:
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	4b8080e7          	jalr	1208(ra) # 800019c8 <myproc>
  if(p == initproc)
    80002518:	00007797          	auipc	a5,0x7
    8000251c:	b107b783          	ld	a5,-1264(a5) # 80009028 <initproc>
    80002520:	00a78b63          	beq	a5,a0,80002536 <exit+0x38>
    80002524:	892a                	mv	s2,a0
  if (p->threadid ==0) {
    80002526:	16852783          	lw	a5,360(a0)
    8000252a:	eb95                	bnez	a5,8000255e <exit+0x60>
    8000252c:	0d050493          	addi	s1,a0,208
    80002530:	15050993          	addi	s3,a0,336
    80002534:	a015                	j	80002558 <exit+0x5a>
    panic("init exiting");
    80002536:	00006517          	auipc	a0,0x6
    8000253a:	d3a50513          	addi	a0,a0,-710 # 80008270 <digits+0x230>
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	000080e7          	jalr	ra # 8000053e <panic>
          fileclose(f);
    80002546:	00002097          	auipc	ra,0x2
    8000254a:	1ae080e7          	jalr	430(ra) # 800046f4 <fileclose>
          p->ofile[fd] = 0;
    8000254e:	0004b023          	sd	zero,0(s1)
      for(int fd = 0; fd < NOFILE; fd++){
    80002552:	04a1                	addi	s1,s1,8
    80002554:	01348563          	beq	s1,s3,8000255e <exit+0x60>
        if(p->ofile[fd]){
    80002558:	6088                	ld	a0,0(s1)
    8000255a:	f575                	bnez	a0,80002546 <exit+0x48>
    8000255c:	bfdd                	j	80002552 <exit+0x54>
  begin_op();
    8000255e:	00002097          	auipc	ra,0x2
    80002562:	cca080e7          	jalr	-822(ra) # 80004228 <begin_op>
  iput(p->cwd);
    80002566:	15093503          	ld	a0,336(s2)
    8000256a:	00001097          	auipc	ra,0x1
    8000256e:	4a6080e7          	jalr	1190(ra) # 80003a10 <iput>
  end_op();
    80002572:	00002097          	auipc	ra,0x2
    80002576:	d36080e7          	jalr	-714(ra) # 800042a8 <end_op>
  p->cwd = 0;
    8000257a:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    8000257e:	0000f517          	auipc	a0,0xf
    80002582:	d3a50513          	addi	a0,a0,-710 # 800112b8 <wait_lock>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	65e080e7          	jalr	1630(ra) # 80000be4 <acquire>
  if(p->threadid == 0) 
    8000258e:	16892783          	lw	a5,360(s2)
    80002592:	c7a9                	beqz	a5,800025dc <exit+0xde>
  wakeup(p->parent);
    80002594:	03893503          	ld	a0,56(s2)
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	e96080e7          	jalr	-362(ra) # 8000242e <wakeup>
  acquire(&p->lock);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	642080e7          	jalr	1602(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025aa:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    800025ae:	4795                	li	a5,5
    800025b0:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    800025b4:	0000f517          	auipc	a0,0xf
    800025b8:	d0450513          	addi	a0,a0,-764 # 800112b8 <wait_lock>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6dc080e7          	jalr	1756(ra) # 80000c98 <release>
  sched();
    800025c4:	00000097          	auipc	ra,0x0
    800025c8:	bcc080e7          	jalr	-1076(ra) # 80002190 <sched>
  panic("zombie exit");
    800025cc:	00006517          	auipc	a0,0x6
    800025d0:	cb450513          	addi	a0,a0,-844 # 80008280 <digits+0x240>
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>
  reparent(p);//remoditfication for Lab3
    800025dc:	854a                	mv	a0,s2
    800025de:	00000097          	auipc	ra,0x0
    800025e2:	ec6080e7          	jalr	-314(ra) # 800024a4 <reparent>
    800025e6:	b77d                	j	80002594 <exit+0x96>

00000000800025e8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025e8:	7179                	addi	sp,sp,-48
    800025ea:	f406                	sd	ra,40(sp)
    800025ec:	f022                	sd	s0,32(sp)
    800025ee:	ec26                	sd	s1,24(sp)
    800025f0:	e84a                	sd	s2,16(sp)
    800025f2:	e44e                	sd	s3,8(sp)
    800025f4:	1800                	addi	s0,sp,48
    800025f6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025f8:	0000f497          	auipc	s1,0xf
    800025fc:	0f048493          	addi	s1,s1,240 # 800116e8 <proc>
    80002600:	00015997          	auipc	s3,0x15
    80002604:	ce898993          	addi	s3,s3,-792 # 800172e8 <tickslock>
    acquire(&p->lock);
    80002608:	8526                	mv	a0,s1
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	5da080e7          	jalr	1498(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002612:	589c                	lw	a5,48(s1)
    80002614:	01278d63          	beq	a5,s2,8000262e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002618:	8526                	mv	a0,s1
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	67e080e7          	jalr	1662(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002622:	17048493          	addi	s1,s1,368
    80002626:	ff3491e3          	bne	s1,s3,80002608 <kill+0x20>
  }
  return -1;
    8000262a:	557d                	li	a0,-1
    8000262c:	a829                	j	80002646 <kill+0x5e>
      p->killed = 1;
    8000262e:	4785                	li	a5,1
    80002630:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002632:	4c98                	lw	a4,24(s1)
    80002634:	4789                	li	a5,2
    80002636:	00f70f63          	beq	a4,a5,80002654 <kill+0x6c>
      release(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>
      return 0;
    80002644:	4501                	li	a0,0
}
    80002646:	70a2                	ld	ra,40(sp)
    80002648:	7402                	ld	s0,32(sp)
    8000264a:	64e2                	ld	s1,24(sp)
    8000264c:	6942                	ld	s2,16(sp)
    8000264e:	69a2                	ld	s3,8(sp)
    80002650:	6145                	addi	sp,sp,48
    80002652:	8082                	ret
        p->state = RUNNABLE;
    80002654:	478d                	li	a5,3
    80002656:	cc9c                	sw	a5,24(s1)
    80002658:	b7cd                	j	8000263a <kill+0x52>

000000008000265a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000265a:	7179                	addi	sp,sp,-48
    8000265c:	f406                	sd	ra,40(sp)
    8000265e:	f022                	sd	s0,32(sp)
    80002660:	ec26                	sd	s1,24(sp)
    80002662:	e84a                	sd	s2,16(sp)
    80002664:	e44e                	sd	s3,8(sp)
    80002666:	e052                	sd	s4,0(sp)
    80002668:	1800                	addi	s0,sp,48
    8000266a:	84aa                	mv	s1,a0
    8000266c:	892e                	mv	s2,a1
    8000266e:	89b2                	mv	s3,a2
    80002670:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	356080e7          	jalr	854(ra) # 800019c8 <myproc>
  if(user_dst){
    8000267a:	c08d                	beqz	s1,8000269c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000267c:	86d2                	mv	a3,s4
    8000267e:	864e                	mv	a2,s3
    80002680:	85ca                	mv	a1,s2
    80002682:	6928                	ld	a0,80(a0)
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	fee080e7          	jalr	-18(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000268c:	70a2                	ld	ra,40(sp)
    8000268e:	7402                	ld	s0,32(sp)
    80002690:	64e2                	ld	s1,24(sp)
    80002692:	6942                	ld	s2,16(sp)
    80002694:	69a2                	ld	s3,8(sp)
    80002696:	6a02                	ld	s4,0(sp)
    80002698:	6145                	addi	sp,sp,48
    8000269a:	8082                	ret
    memmove((char *)dst, src, len);
    8000269c:	000a061b          	sext.w	a2,s4
    800026a0:	85ce                	mv	a1,s3
    800026a2:	854a                	mv	a0,s2
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	69c080e7          	jalr	1692(ra) # 80000d40 <memmove>
    return 0;
    800026ac:	8526                	mv	a0,s1
    800026ae:	bff9                	j	8000268c <either_copyout+0x32>

00000000800026b0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	892a                	mv	s2,a0
    800026c2:	84ae                	mv	s1,a1
    800026c4:	89b2                	mv	s3,a2
    800026c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	300080e7          	jalr	768(ra) # 800019c8 <myproc>
  if(user_src){
    800026d0:	c08d                	beqz	s1,800026f2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026d2:	86d2                	mv	a3,s4
    800026d4:	864e                	mv	a2,s3
    800026d6:	85ca                	mv	a1,s2
    800026d8:	6928                	ld	a0,80(a0)
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	024080e7          	jalr	36(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026e2:	70a2                	ld	ra,40(sp)
    800026e4:	7402                	ld	s0,32(sp)
    800026e6:	64e2                	ld	s1,24(sp)
    800026e8:	6942                	ld	s2,16(sp)
    800026ea:	69a2                	ld	s3,8(sp)
    800026ec:	6a02                	ld	s4,0(sp)
    800026ee:	6145                	addi	sp,sp,48
    800026f0:	8082                	ret
    memmove(dst, (char*)src, len);
    800026f2:	000a061b          	sext.w	a2,s4
    800026f6:	85ce                	mv	a1,s3
    800026f8:	854a                	mv	a0,s2
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	646080e7          	jalr	1606(ra) # 80000d40 <memmove>
    return 0;
    80002702:	8526                	mv	a0,s1
    80002704:	bff9                	j	800026e2 <either_copyin+0x32>

0000000080002706 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002706:	715d                	addi	sp,sp,-80
    80002708:	e486                	sd	ra,72(sp)
    8000270a:	e0a2                	sd	s0,64(sp)
    8000270c:	fc26                	sd	s1,56(sp)
    8000270e:	f84a                	sd	s2,48(sp)
    80002710:	f44e                	sd	s3,40(sp)
    80002712:	f052                	sd	s4,32(sp)
    80002714:	ec56                	sd	s5,24(sp)
    80002716:	e85a                	sd	s6,16(sp)
    80002718:	e45e                	sd	s7,8(sp)
    8000271a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000271c:	00006517          	auipc	a0,0x6
    80002720:	9ac50513          	addi	a0,a0,-1620 # 800080c8 <digits+0x88>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	e64080e7          	jalr	-412(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000272c:	0000f497          	auipc	s1,0xf
    80002730:	11448493          	addi	s1,s1,276 # 80011840 <proc+0x158>
    80002734:	00015917          	auipc	s2,0x15
    80002738:	d0c90913          	addi	s2,s2,-756 # 80017440 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000273c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000273e:	00006997          	auipc	s3,0x6
    80002742:	b5298993          	addi	s3,s3,-1198 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002746:	00006a97          	auipc	s5,0x6
    8000274a:	b52a8a93          	addi	s5,s5,-1198 # 80008298 <digits+0x258>
    printf("\n");
    8000274e:	00006a17          	auipc	s4,0x6
    80002752:	97aa0a13          	addi	s4,s4,-1670 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002756:	00006b97          	auipc	s7,0x6
    8000275a:	b7ab8b93          	addi	s7,s7,-1158 # 800082d0 <states.1733>
    8000275e:	a00d                	j	80002780 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002760:	ed86a583          	lw	a1,-296(a3)
    80002764:	8556                	mv	a0,s5
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	e22080e7          	jalr	-478(ra) # 80000588 <printf>
    printf("\n");
    8000276e:	8552                	mv	a0,s4
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	e18080e7          	jalr	-488(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002778:	17048493          	addi	s1,s1,368
    8000277c:	03248163          	beq	s1,s2,8000279e <procdump+0x98>
    if(p->state == UNUSED)
    80002780:	86a6                	mv	a3,s1
    80002782:	ec04a783          	lw	a5,-320(s1)
    80002786:	dbed                	beqz	a5,80002778 <procdump+0x72>
      state = "???";
    80002788:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278a:	fcfb6be3          	bltu	s6,a5,80002760 <procdump+0x5a>
    8000278e:	1782                	slli	a5,a5,0x20
    80002790:	9381                	srli	a5,a5,0x20
    80002792:	078e                	slli	a5,a5,0x3
    80002794:	97de                	add	a5,a5,s7
    80002796:	6390                	ld	a2,0(a5)
    80002798:	f661                	bnez	a2,80002760 <procdump+0x5a>
      state = "???";
    8000279a:	864e                	mv	a2,s3
    8000279c:	b7d1                	j	80002760 <procdump+0x5a>
  }
}
    8000279e:	60a6                	ld	ra,72(sp)
    800027a0:	6406                	ld	s0,64(sp)
    800027a2:	74e2                	ld	s1,56(sp)
    800027a4:	7942                	ld	s2,48(sp)
    800027a6:	79a2                	ld	s3,40(sp)
    800027a8:	7a02                	ld	s4,32(sp)
    800027aa:	6ae2                	ld	s5,24(sp)
    800027ac:	6b42                	ld	s6,16(sp)
    800027ae:	6ba2                	ld	s7,8(sp)
    800027b0:	6161                	addi	sp,sp,80
    800027b2:	8082                	ret

00000000800027b4 <swtch>:
    800027b4:	00153023          	sd	ra,0(a0)
    800027b8:	00253423          	sd	sp,8(a0)
    800027bc:	e900                	sd	s0,16(a0)
    800027be:	ed04                	sd	s1,24(a0)
    800027c0:	03253023          	sd	s2,32(a0)
    800027c4:	03353423          	sd	s3,40(a0)
    800027c8:	03453823          	sd	s4,48(a0)
    800027cc:	03553c23          	sd	s5,56(a0)
    800027d0:	05653023          	sd	s6,64(a0)
    800027d4:	05753423          	sd	s7,72(a0)
    800027d8:	05853823          	sd	s8,80(a0)
    800027dc:	05953c23          	sd	s9,88(a0)
    800027e0:	07a53023          	sd	s10,96(a0)
    800027e4:	07b53423          	sd	s11,104(a0)
    800027e8:	0005b083          	ld	ra,0(a1)
    800027ec:	0085b103          	ld	sp,8(a1)
    800027f0:	6980                	ld	s0,16(a1)
    800027f2:	6d84                	ld	s1,24(a1)
    800027f4:	0205b903          	ld	s2,32(a1)
    800027f8:	0285b983          	ld	s3,40(a1)
    800027fc:	0305ba03          	ld	s4,48(a1)
    80002800:	0385ba83          	ld	s5,56(a1)
    80002804:	0405bb03          	ld	s6,64(a1)
    80002808:	0485bb83          	ld	s7,72(a1)
    8000280c:	0505bc03          	ld	s8,80(a1)
    80002810:	0585bc83          	ld	s9,88(a1)
    80002814:	0605bd03          	ld	s10,96(a1)
    80002818:	0685bd83          	ld	s11,104(a1)
    8000281c:	8082                	ret

000000008000281e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000281e:	1141                	addi	sp,sp,-16
    80002820:	e406                	sd	ra,8(sp)
    80002822:	e022                	sd	s0,0(sp)
    80002824:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002826:	00006597          	auipc	a1,0x6
    8000282a:	ada58593          	addi	a1,a1,-1318 # 80008300 <states.1733+0x30>
    8000282e:	00015517          	auipc	a0,0x15
    80002832:	aba50513          	addi	a0,a0,-1350 # 800172e8 <tickslock>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	31e080e7          	jalr	798(ra) # 80000b54 <initlock>
}
    8000283e:	60a2                	ld	ra,8(sp)
    80002840:	6402                	ld	s0,0(sp)
    80002842:	0141                	addi	sp,sp,16
    80002844:	8082                	ret

0000000080002846 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002846:	1141                	addi	sp,sp,-16
    80002848:	e422                	sd	s0,8(sp)
    8000284a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284c:	00003797          	auipc	a5,0x3
    80002850:	4c478793          	addi	a5,a5,1220 # 80005d10 <kernelvec>
    80002854:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002858:	6422                	ld	s0,8(sp)
    8000285a:	0141                	addi	sp,sp,16
    8000285c:	8082                	ret

000000008000285e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000285e:	1141                	addi	sp,sp,-16
    80002860:	e406                	sd	ra,8(sp)
    80002862:	e022                	sd	s0,0(sp)
    80002864:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	162080e7          	jalr	354(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002872:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002874:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002878:	00004617          	auipc	a2,0x4
    8000287c:	78860613          	addi	a2,a2,1928 # 80007000 <_trampoline>
    80002880:	00004697          	auipc	a3,0x4
    80002884:	78068693          	addi	a3,a3,1920 # 80007000 <_trampoline>
    80002888:	8e91                	sub	a3,a3,a2
    8000288a:	040007b7          	lui	a5,0x4000
    8000288e:	17fd                	addi	a5,a5,-1
    80002890:	07b2                	slli	a5,a5,0xc
    80002892:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002894:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002898:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000289a:	180026f3          	csrr	a3,satp
    8000289e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028a0:	6d38                	ld	a4,88(a0)
    800028a2:	6134                	ld	a3,64(a0)
    800028a4:	6585                	lui	a1,0x1
    800028a6:	96ae                	add	a3,a3,a1
    800028a8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028aa:	6d38                	ld	a4,88(a0)
    800028ac:	00000697          	auipc	a3,0x0
    800028b0:	14468693          	addi	a3,a3,324 # 800029f0 <usertrap>
    800028b4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028b6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b8:	8692                	mv	a3,tp
    800028ba:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028bc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028c0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028cc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ce:	6f18                	ld	a4,24(a4)
    800028d0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d4:	692c                	ld	a1,80(a0)
    800028d6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME - (4096 * p->threadid), satp);
    800028d8:	16852503          	lw	a0,360(a0)
    800028dc:	00c5151b          	slliw	a0,a0,0xc
    800028e0:	020006b7          	lui	a3,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028e4:	00004717          	auipc	a4,0x4
    800028e8:	7ac70713          	addi	a4,a4,1964 # 80007090 <userret>
    800028ec:	8f11                	sub	a4,a4,a2
    800028ee:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME - (4096 * p->threadid), satp);
    800028f0:	577d                	li	a4,-1
    800028f2:	177e                	slli	a4,a4,0x3f
    800028f4:	8dd9                	or	a1,a1,a4
    800028f6:	16fd                	addi	a3,a3,-1
    800028f8:	06b6                	slli	a3,a3,0xd
    800028fa:	40a68533          	sub	a0,a3,a0
    800028fe:	9782                	jalr	a5

}
    80002900:	60a2                	ld	ra,8(sp)
    80002902:	6402                	ld	s0,0(sp)
    80002904:	0141                	addi	sp,sp,16
    80002906:	8082                	ret

0000000080002908 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002908:	1101                	addi	sp,sp,-32
    8000290a:	ec06                	sd	ra,24(sp)
    8000290c:	e822                	sd	s0,16(sp)
    8000290e:	e426                	sd	s1,8(sp)
    80002910:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002912:	00015497          	auipc	s1,0x15
    80002916:	9d648493          	addi	s1,s1,-1578 # 800172e8 <tickslock>
    8000291a:	8526                	mv	a0,s1
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
  ticks++;
    80002924:	00006517          	auipc	a0,0x6
    80002928:	70c50513          	addi	a0,a0,1804 # 80009030 <ticks>
    8000292c:	411c                	lw	a5,0(a0)
    8000292e:	2785                	addiw	a5,a5,1
    80002930:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002932:	00000097          	auipc	ra,0x0
    80002936:	afc080e7          	jalr	-1284(ra) # 8000242e <wakeup>
  release(&tickslock);
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
}
    80002944:	60e2                	ld	ra,24(sp)
    80002946:	6442                	ld	s0,16(sp)
    80002948:	64a2                	ld	s1,8(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret

000000008000294e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000294e:	1101                	addi	sp,sp,-32
    80002950:	ec06                	sd	ra,24(sp)
    80002952:	e822                	sd	s0,16(sp)
    80002954:	e426                	sd	s1,8(sp)
    80002956:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002958:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000295c:	00074d63          	bltz	a4,80002976 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002960:	57fd                	li	a5,-1
    80002962:	17fe                	slli	a5,a5,0x3f
    80002964:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002966:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002968:	06f70363          	beq	a4,a5,800029ce <devintr+0x80>
  }
}
    8000296c:	60e2                	ld	ra,24(sp)
    8000296e:	6442                	ld	s0,16(sp)
    80002970:	64a2                	ld	s1,8(sp)
    80002972:	6105                	addi	sp,sp,32
    80002974:	8082                	ret
     (scause & 0xff) == 9){
    80002976:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000297a:	46a5                	li	a3,9
    8000297c:	fed792e3          	bne	a5,a3,80002960 <devintr+0x12>
    int irq = plic_claim();
    80002980:	00003097          	auipc	ra,0x3
    80002984:	498080e7          	jalr	1176(ra) # 80005e18 <plic_claim>
    80002988:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000298a:	47a9                	li	a5,10
    8000298c:	02f50763          	beq	a0,a5,800029ba <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002990:	4785                	li	a5,1
    80002992:	02f50963          	beq	a0,a5,800029c4 <devintr+0x76>
    return 1;
    80002996:	4505                	li	a0,1
    } else if(irq){
    80002998:	d8f1                	beqz	s1,8000296c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000299a:	85a6                	mv	a1,s1
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	96c50513          	addi	a0,a0,-1684 # 80008308 <states.1733+0x38>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	be4080e7          	jalr	-1052(ra) # 80000588 <printf>
      plic_complete(irq);
    800029ac:	8526                	mv	a0,s1
    800029ae:	00003097          	auipc	ra,0x3
    800029b2:	48e080e7          	jalr	1166(ra) # 80005e3c <plic_complete>
    return 1;
    800029b6:	4505                	li	a0,1
    800029b8:	bf55                	j	8000296c <devintr+0x1e>
      uartintr();
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	fee080e7          	jalr	-18(ra) # 800009a8 <uartintr>
    800029c2:	b7ed                	j	800029ac <devintr+0x5e>
      virtio_disk_intr();
    800029c4:	00004097          	auipc	ra,0x4
    800029c8:	958080e7          	jalr	-1704(ra) # 8000631c <virtio_disk_intr>
    800029cc:	b7c5                	j	800029ac <devintr+0x5e>
    if(cpuid() == 0){
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	fce080e7          	jalr	-50(ra) # 8000199c <cpuid>
    800029d6:	c901                	beqz	a0,800029e6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029d8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029dc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029de:	14479073          	csrw	sip,a5
    return 2;
    800029e2:	4509                	li	a0,2
    800029e4:	b761                	j	8000296c <devintr+0x1e>
      clockintr();
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	f22080e7          	jalr	-222(ra) # 80002908 <clockintr>
    800029ee:	b7ed                	j	800029d8 <devintr+0x8a>

00000000800029f0 <usertrap>:
{
    800029f0:	1101                	addi	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a00:	1007f793          	andi	a5,a5,256
    80002a04:	e3ad                	bnez	a5,80002a66 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a06:	00003797          	auipc	a5,0x3
    80002a0a:	30a78793          	addi	a5,a5,778 # 80005d10 <kernelvec>
    80002a0e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	fb6080e7          	jalr	-74(ra) # 800019c8 <myproc>
    80002a1a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a1c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	14102773          	csrr	a4,sepc
    80002a22:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a28:	47a1                	li	a5,8
    80002a2a:	04f71c63          	bne	a4,a5,80002a82 <usertrap+0x92>
    if(p->killed)
    80002a2e:	551c                	lw	a5,40(a0)
    80002a30:	e3b9                	bnez	a5,80002a76 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a32:	6cb8                	ld	a4,88(s1)
    80002a34:	6f1c                	ld	a5,24(a4)
    80002a36:	0791                	addi	a5,a5,4
    80002a38:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a42:	10079073          	csrw	sstatus,a5
    syscall();
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	2e0080e7          	jalr	736(ra) # 80002d26 <syscall>
  if(p->killed)
    80002a4e:	549c                	lw	a5,40(s1)
    80002a50:	ebc1                	bnez	a5,80002ae0 <usertrap+0xf0>
  usertrapret();
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	e0c080e7          	jalr	-500(ra) # 8000285e <usertrapret>
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6902                	ld	s2,0(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret
    panic("usertrap: not from user mode");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	8c250513          	addi	a0,a0,-1854 # 80008328 <states.1733+0x58>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
      exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	a86080e7          	jalr	-1402(ra) # 800024fe <exit>
    80002a80:	bf4d                	j	80002a32 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	ecc080e7          	jalr	-308(ra) # 8000294e <devintr>
    80002a8a:	892a                	mv	s2,a0
    80002a8c:	c501                	beqz	a0,80002a94 <usertrap+0xa4>
  if(p->killed)
    80002a8e:	549c                	lw	a5,40(s1)
    80002a90:	c3a1                	beqz	a5,80002ad0 <usertrap+0xe0>
    80002a92:	a815                	j	80002ac6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a98:	5890                	lw	a2,48(s1)
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8ae50513          	addi	a0,a0,-1874 # 80008348 <states.1733+0x78>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae6080e7          	jalr	-1306(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aaa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aae:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	8c650513          	addi	a0,a0,-1850 # 80008378 <states.1733+0xa8>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ace080e7          	jalr	-1330(ra) # 80000588 <printf>
    p->killed = 1;
    80002ac2:	4785                	li	a5,1
    80002ac4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ac6:	557d                	li	a0,-1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	a36080e7          	jalr	-1482(ra) # 800024fe <exit>
  if(which_dev == 2)
    80002ad0:	4789                	li	a5,2
    80002ad2:	f8f910e3          	bne	s2,a5,80002a52 <usertrap+0x62>
    yield();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	790080e7          	jalr	1936(ra) # 80002266 <yield>
    80002ade:	bf95                	j	80002a52 <usertrap+0x62>
  int which_dev = 0;
    80002ae0:	4901                	li	s2,0
    80002ae2:	b7d5                	j	80002ac6 <usertrap+0xd6>

0000000080002ae4 <kerneltrap>:
{
    80002ae4:	7179                	addi	sp,sp,-48
    80002ae6:	f406                	sd	ra,40(sp)
    80002ae8:	f022                	sd	s0,32(sp)
    80002aea:	ec26                	sd	s1,24(sp)
    80002aec:	e84a                	sd	s2,16(sp)
    80002aee:	e44e                	sd	s3,8(sp)
    80002af0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002afe:	1004f793          	andi	a5,s1,256
    80002b02:	cb85                	beqz	a5,80002b32 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b04:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b08:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b0a:	ef85                	bnez	a5,80002b42 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	e42080e7          	jalr	-446(ra) # 8000294e <devintr>
    80002b14:	cd1d                	beqz	a0,80002b52 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b16:	4789                	li	a5,2
    80002b18:	06f50a63          	beq	a0,a5,80002b8c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b1c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b20:	10049073          	csrw	sstatus,s1
}
    80002b24:	70a2                	ld	ra,40(sp)
    80002b26:	7402                	ld	s0,32(sp)
    80002b28:	64e2                	ld	s1,24(sp)
    80002b2a:	6942                	ld	s2,16(sp)
    80002b2c:	69a2                	ld	s3,8(sp)
    80002b2e:	6145                	addi	sp,sp,48
    80002b30:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	86650513          	addi	a0,a0,-1946 # 80008398 <states.1733+0xc8>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a04080e7          	jalr	-1532(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	87e50513          	addi	a0,a0,-1922 # 800083c0 <states.1733+0xf0>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	9f4080e7          	jalr	-1548(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b52:	85ce                	mv	a1,s3
    80002b54:	00006517          	auipc	a0,0x6
    80002b58:	88c50513          	addi	a0,a0,-1908 # 800083e0 <states.1733+0x110>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	a2c080e7          	jalr	-1492(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b64:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b68:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b6c:	00006517          	auipc	a0,0x6
    80002b70:	88450513          	addi	a0,a0,-1916 # 800083f0 <states.1733+0x120>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	a14080e7          	jalr	-1516(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	88c50513          	addi	a0,a0,-1908 # 80008408 <states.1733+0x138>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e3c080e7          	jalr	-452(ra) # 800019c8 <myproc>
    80002b94:	d541                	beqz	a0,80002b1c <kerneltrap+0x38>
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	e32080e7          	jalr	-462(ra) # 800019c8 <myproc>
    80002b9e:	4d18                	lw	a4,24(a0)
    80002ba0:	4791                	li	a5,4
    80002ba2:	f6f71de3          	bne	a4,a5,80002b1c <kerneltrap+0x38>
    yield();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	6c0080e7          	jalr	1728(ra) # 80002266 <yield>
    80002bae:	b7bd                	j	80002b1c <kerneltrap+0x38>

0000000080002bb0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	e0c080e7          	jalr	-500(ra) # 800019c8 <myproc>
  switch (n) {
    80002bc4:	4795                	li	a5,5
    80002bc6:	0497e163          	bltu	a5,s1,80002c08 <argraw+0x58>
    80002bca:	048a                	slli	s1,s1,0x2
    80002bcc:	00006717          	auipc	a4,0x6
    80002bd0:	87470713          	addi	a4,a4,-1932 # 80008440 <states.1733+0x170>
    80002bd4:	94ba                	add	s1,s1,a4
    80002bd6:	409c                	lw	a5,0(s1)
    80002bd8:	97ba                	add	a5,a5,a4
    80002bda:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bdc:	6d3c                	ld	a5,88(a0)
    80002bde:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be0:	60e2                	ld	ra,24(sp)
    80002be2:	6442                	ld	s0,16(sp)
    80002be4:	64a2                	ld	s1,8(sp)
    80002be6:	6105                	addi	sp,sp,32
    80002be8:	8082                	ret
    return p->trapframe->a1;
    80002bea:	6d3c                	ld	a5,88(a0)
    80002bec:	7fa8                	ld	a0,120(a5)
    80002bee:	bfcd                	j	80002be0 <argraw+0x30>
    return p->trapframe->a2;
    80002bf0:	6d3c                	ld	a5,88(a0)
    80002bf2:	63c8                	ld	a0,128(a5)
    80002bf4:	b7f5                	j	80002be0 <argraw+0x30>
    return p->trapframe->a3;
    80002bf6:	6d3c                	ld	a5,88(a0)
    80002bf8:	67c8                	ld	a0,136(a5)
    80002bfa:	b7dd                	j	80002be0 <argraw+0x30>
    return p->trapframe->a4;
    80002bfc:	6d3c                	ld	a5,88(a0)
    80002bfe:	6bc8                	ld	a0,144(a5)
    80002c00:	b7c5                	j	80002be0 <argraw+0x30>
    return p->trapframe->a5;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	6fc8                	ld	a0,152(a5)
    80002c06:	bfe9                	j	80002be0 <argraw+0x30>
  panic("argraw");
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	81050513          	addi	a0,a0,-2032 # 80008418 <states.1733+0x148>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>

0000000080002c18 <fetchaddr>:
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	e04a                	sd	s2,0(sp)
    80002c22:	1000                	addi	s0,sp,32
    80002c24:	84aa                	mv	s1,a0
    80002c26:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	da0080e7          	jalr	-608(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c30:	653c                	ld	a5,72(a0)
    80002c32:	02f4f863          	bgeu	s1,a5,80002c62 <fetchaddr+0x4a>
    80002c36:	00848713          	addi	a4,s1,8
    80002c3a:	02e7e663          	bltu	a5,a4,80002c66 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c3e:	46a1                	li	a3,8
    80002c40:	8626                	mv	a2,s1
    80002c42:	85ca                	mv	a1,s2
    80002c44:	6928                	ld	a0,80(a0)
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	ab8080e7          	jalr	-1352(ra) # 800016fe <copyin>
    80002c4e:	00a03533          	snez	a0,a0
    80002c52:	40a00533          	neg	a0,a0
}
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	64a2                	ld	s1,8(sp)
    80002c5c:	6902                	ld	s2,0(sp)
    80002c5e:	6105                	addi	sp,sp,32
    80002c60:	8082                	ret
    return -1;
    80002c62:	557d                	li	a0,-1
    80002c64:	bfcd                	j	80002c56 <fetchaddr+0x3e>
    80002c66:	557d                	li	a0,-1
    80002c68:	b7fd                	j	80002c56 <fetchaddr+0x3e>

0000000080002c6a <fetchstr>:
{
    80002c6a:	7179                	addi	sp,sp,-48
    80002c6c:	f406                	sd	ra,40(sp)
    80002c6e:	f022                	sd	s0,32(sp)
    80002c70:	ec26                	sd	s1,24(sp)
    80002c72:	e84a                	sd	s2,16(sp)
    80002c74:	e44e                	sd	s3,8(sp)
    80002c76:	1800                	addi	s0,sp,48
    80002c78:	892a                	mv	s2,a0
    80002c7a:	84ae                	mv	s1,a1
    80002c7c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	d4a080e7          	jalr	-694(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c86:	86ce                	mv	a3,s3
    80002c88:	864a                	mv	a2,s2
    80002c8a:	85a6                	mv	a1,s1
    80002c8c:	6928                	ld	a0,80(a0)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	afc080e7          	jalr	-1284(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c96:	00054763          	bltz	a0,80002ca4 <fetchstr+0x3a>
  return strlen(buf);
    80002c9a:	8526                	mv	a0,s1
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	1c8080e7          	jalr	456(ra) # 80000e64 <strlen>
}
    80002ca4:	70a2                	ld	ra,40(sp)
    80002ca6:	7402                	ld	s0,32(sp)
    80002ca8:	64e2                	ld	s1,24(sp)
    80002caa:	6942                	ld	s2,16(sp)
    80002cac:	69a2                	ld	s3,8(sp)
    80002cae:	6145                	addi	sp,sp,48
    80002cb0:	8082                	ret

0000000080002cb2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	e426                	sd	s1,8(sp)
    80002cba:	1000                	addi	s0,sp,32
    80002cbc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	ef2080e7          	jalr	-270(ra) # 80002bb0 <argraw>
    80002cc6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cc8:	4501                	li	a0,0
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	e426                	sd	s1,8(sp)
    80002cdc:	1000                	addi	s0,sp,32
    80002cde:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	ed0080e7          	jalr	-304(ra) # 80002bb0 <argraw>
    80002ce8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cea:	4501                	li	a0,0
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret

0000000080002cf6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	e04a                	sd	s2,0(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84ae                	mv	s1,a1
    80002d04:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	eaa080e7          	jalr	-342(ra) # 80002bb0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d0e:	864a                	mv	a2,s2
    80002d10:	85a6                	mv	a1,s1
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f58080e7          	jalr	-168(ra) # 80002c6a <fetchstr>
}
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	64a2                	ld	s1,8(sp)
    80002d20:	6902                	ld	s2,0(sp)
    80002d22:	6105                	addi	sp,sp,32
    80002d24:	8082                	ret

0000000080002d26 <syscall>:

};

void
syscall(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c96080e7          	jalr	-874(ra) # 800019c8 <myproc>
    80002d3a:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002d3c:	05853903          	ld	s2,88(a0)
    80002d40:	0a893783          	ld	a5,168(s2)
    80002d44:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d48:	37fd                	addiw	a5,a5,-1
    80002d4a:	4755                	li	a4,21
    80002d4c:	00f76f63          	bltu	a4,a5,80002d6a <syscall+0x44>
    80002d50:	00369713          	slli	a4,a3,0x3
    80002d54:	00005797          	auipc	a5,0x5
    80002d58:	70478793          	addi	a5,a5,1796 # 80008458 <syscalls>
    80002d5c:	97ba                	add	a5,a5,a4
    80002d5e:	639c                	ld	a5,0(a5)
    80002d60:	c789                	beqz	a5,80002d6a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();    
    80002d62:	9782                	jalr	a5
    80002d64:	06a93823          	sd	a0,112(s2)
    80002d68:	a839                	j	80002d86 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d6a:	15848613          	addi	a2,s1,344
    80002d6e:	588c                	lw	a1,48(s1)
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	6b050513          	addi	a0,a0,1712 # 80008420 <states.1733+0x150>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	810080e7          	jalr	-2032(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d80:	6cbc                	ld	a5,88(s1)
    80002d82:	577d                	li	a4,-1
    80002d84:	fbb8                	sd	a4,112(a5)
  }
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	64a2                	ld	s1,8(sp)
    80002d8c:	6902                	ld	s2,0(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret

0000000080002d92 <sys_exit>:
#include "proc.h"
#include "stddef.h"

uint64
sys_exit(void)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d9a:	fec40593          	addi	a1,s0,-20
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	f12080e7          	jalr	-238(ra) # 80002cb2 <argint>
    return -1;
    80002da8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002daa:	00054963          	bltz	a0,80002dbc <sys_exit+0x2a>
  exit(n);
    80002dae:	fec42503          	lw	a0,-20(s0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	74c080e7          	jalr	1868(ra) # 800024fe <exit>
  return 0;  // not reached
    80002dba:	4781                	li	a5,0
}
    80002dbc:	853e                	mv	a0,a5
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dc6:	1141                	addi	sp,sp,-16
    80002dc8:	e406                	sd	ra,8(sp)
    80002dca:	e022                	sd	s0,0(sp)
    80002dcc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	bfa080e7          	jalr	-1030(ra) # 800019c8 <myproc>
}
    80002dd6:	5908                	lw	a0,48(a0)
    80002dd8:	60a2                	ld	ra,8(sp)
    80002dda:	6402                	ld	s0,0(sp)
    80002ddc:	0141                	addi	sp,sp,16
    80002dde:	8082                	ret

0000000080002de0 <sys_fork>:

uint64
sys_fork(void)
{
    80002de0:	1141                	addi	sp,sp,-16
    80002de2:	e406                	sd	ra,8(sp)
    80002de4:	e022                	sd	s0,0(sp)
    80002de6:	0800                	addi	s0,sp,16
  return fork();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	fde080e7          	jalr	-34(ra) # 80001dc6 <fork>
}
    80002df0:	60a2                	ld	ra,8(sp)
    80002df2:	6402                	ld	s0,0(sp)
    80002df4:	0141                	addi	sp,sp,16
    80002df6:	8082                	ret

0000000080002df8 <sys_wait>:

uint64
sys_wait(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e00:	fe840593          	addi	a1,s0,-24
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	ece080e7          	jalr	-306(ra) # 80002cd4 <argaddr>
    80002e0e:	87aa                	mv	a5,a0
    return -1;
    80002e10:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e12:	0007c863          	bltz	a5,80002e22 <sys_wait+0x2a>
  return wait(p);
    80002e16:	fe843503          	ld	a0,-24(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	4ec080e7          	jalr	1260(ra) # 80002306 <wait>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e34:	fdc40593          	addi	a1,s0,-36
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	e78080e7          	jalr	-392(ra) # 80002cb2 <argint>
    80002e42:	87aa                	mv	a5,a0
    return -1;
    80002e44:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e46:	0207c063          	bltz	a5,80002e66 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b7e080e7          	jalr	-1154(ra) # 800019c8 <myproc>
    80002e52:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e54:	fdc42503          	lw	a0,-36(s0)
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	efa080e7          	jalr	-262(ra) # 80001d52 <growproc>
    80002e60:	00054863          	bltz	a0,80002e70 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e64:	8526                	mv	a0,s1
}
    80002e66:	70a2                	ld	ra,40(sp)
    80002e68:	7402                	ld	s0,32(sp)
    80002e6a:	64e2                	ld	s1,24(sp)
    80002e6c:	6145                	addi	sp,sp,48
    80002e6e:	8082                	ret
    return -1;
    80002e70:	557d                	li	a0,-1
    80002e72:	bfd5                	j	80002e66 <sys_sbrk+0x3c>

0000000080002e74 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e74:	7139                	addi	sp,sp,-64
    80002e76:	fc06                	sd	ra,56(sp)
    80002e78:	f822                	sd	s0,48(sp)
    80002e7a:	f426                	sd	s1,40(sp)
    80002e7c:	f04a                	sd	s2,32(sp)
    80002e7e:	ec4e                	sd	s3,24(sp)
    80002e80:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e82:	fcc40593          	addi	a1,s0,-52
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	e2a080e7          	jalr	-470(ra) # 80002cb2 <argint>
    return -1;
    80002e90:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e92:	06054563          	bltz	a0,80002efc <sys_sleep+0x88>
  acquire(&tickslock);
    80002e96:	00014517          	auipc	a0,0x14
    80002e9a:	45250513          	addi	a0,a0,1106 # 800172e8 <tickslock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	d46080e7          	jalr	-698(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002ea6:	00006917          	auipc	s2,0x6
    80002eaa:	18a92903          	lw	s2,394(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002eae:	fcc42783          	lw	a5,-52(s0)
    80002eb2:	cf85                	beqz	a5,80002eea <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eb4:	00014997          	auipc	s3,0x14
    80002eb8:	43498993          	addi	s3,s3,1076 # 800172e8 <tickslock>
    80002ebc:	00006497          	auipc	s1,0x6
    80002ec0:	17448493          	addi	s1,s1,372 # 80009030 <ticks>
    if(myproc()->killed){
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	b04080e7          	jalr	-1276(ra) # 800019c8 <myproc>
    80002ecc:	551c                	lw	a5,40(a0)
    80002ece:	ef9d                	bnez	a5,80002f0c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ed0:	85ce                	mv	a1,s3
    80002ed2:	8526                	mv	a0,s1
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	3ce080e7          	jalr	974(ra) # 800022a2 <sleep>
  while(ticks - ticks0 < n){
    80002edc:	409c                	lw	a5,0(s1)
    80002ede:	412787bb          	subw	a5,a5,s2
    80002ee2:	fcc42703          	lw	a4,-52(s0)
    80002ee6:	fce7efe3          	bltu	a5,a4,80002ec4 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	3fe50513          	addi	a0,a0,1022 # 800172e8 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
  return 0;
    80002efa:	4781                	li	a5,0
}
    80002efc:	853e                	mv	a0,a5
    80002efe:	70e2                	ld	ra,56(sp)
    80002f00:	7442                	ld	s0,48(sp)
    80002f02:	74a2                	ld	s1,40(sp)
    80002f04:	7902                	ld	s2,32(sp)
    80002f06:	69e2                	ld	s3,24(sp)
    80002f08:	6121                	addi	sp,sp,64
    80002f0a:	8082                	ret
      release(&tickslock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	3dc50513          	addi	a0,a0,988 # 800172e8 <tickslock>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	d84080e7          	jalr	-636(ra) # 80000c98 <release>
      return -1;
    80002f1c:	57fd                	li	a5,-1
    80002f1e:	bff9                	j	80002efc <sys_sleep+0x88>

0000000080002f20 <sys_kill>:

uint64
sys_kill(void)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f28:	fec40593          	addi	a1,s0,-20
    80002f2c:	4501                	li	a0,0
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	d84080e7          	jalr	-636(ra) # 80002cb2 <argint>
    80002f36:	87aa                	mv	a5,a0
    return -1;
    80002f38:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f3a:	0007c863          	bltz	a5,80002f4a <sys_kill+0x2a>
  return kill(pid);
    80002f3e:	fec42503          	lw	a0,-20(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	6a6080e7          	jalr	1702(ra) # 800025e8 <kill>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	e426                	sd	s1,8(sp)
    80002f5a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f5c:	00014517          	auipc	a0,0x14
    80002f60:	38c50513          	addi	a0,a0,908 # 800172e8 <tickslock>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	c80080e7          	jalr	-896(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f6c:	00006497          	auipc	s1,0x6
    80002f70:	0c44a483          	lw	s1,196(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f74:	00014517          	auipc	a0,0x14
    80002f78:	37450513          	addi	a0,a0,884 # 800172e8 <tickslock>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	d1c080e7          	jalr	-740(ra) # 80000c98 <release>
  return xticks;
}
    80002f84:	02049513          	slli	a0,s1,0x20
    80002f88:	9101                	srli	a0,a0,0x20
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	64a2                	ld	s1,8(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <sys_clone>:

uint64
sys_clone(void)
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	1000                	addi	s0,sp,32
  uint64 var;
  // int s;
  if(argaddr(0, &var) < 0)
    80002f9c:	fe840593          	addi	a1,s0,-24
    80002fa0:	4501                	li	a0,0
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	d32080e7          	jalr	-718(ra) # 80002cd4 <argaddr>
    80002faa:	87aa                	mv	a5,a0
  {
    return -1;
    80002fac:	557d                	li	a0,-1
  if(argaddr(0, &var) < 0)
    80002fae:	0007c863          	bltz	a5,80002fbe <sys_clone+0x2a>
  }
  // if(argint(1, &s) < 0)
  //   {
  //   return -1;
  // }
  return clone((void *)var);
    80002fb2:	fe843503          	ld	a0,-24(s0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	f4c080e7          	jalr	-180(ra) # 80001f02 <clone>
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	6105                	addi	sp,sp,32
    80002fc4:	8082                	ret

0000000080002fc6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fc6:	7179                	addi	sp,sp,-48
    80002fc8:	f406                	sd	ra,40(sp)
    80002fca:	f022                	sd	s0,32(sp)
    80002fcc:	ec26                	sd	s1,24(sp)
    80002fce:	e84a                	sd	s2,16(sp)
    80002fd0:	e44e                	sd	s3,8(sp)
    80002fd2:	e052                	sd	s4,0(sp)
    80002fd4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fd6:	00005597          	auipc	a1,0x5
    80002fda:	53a58593          	addi	a1,a1,1338 # 80008510 <syscalls+0xb8>
    80002fde:	00014517          	auipc	a0,0x14
    80002fe2:	32250513          	addi	a0,a0,802 # 80017300 <bcache>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	b6e080e7          	jalr	-1170(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fee:	0001c797          	auipc	a5,0x1c
    80002ff2:	31278793          	addi	a5,a5,786 # 8001f300 <bcache+0x8000>
    80002ff6:	0001c717          	auipc	a4,0x1c
    80002ffa:	57270713          	addi	a4,a4,1394 # 8001f568 <bcache+0x8268>
    80002ffe:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003002:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003006:	00014497          	auipc	s1,0x14
    8000300a:	31248493          	addi	s1,s1,786 # 80017318 <bcache+0x18>
    b->next = bcache.head.next;
    8000300e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003010:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003012:	00005a17          	auipc	s4,0x5
    80003016:	506a0a13          	addi	s4,s4,1286 # 80008518 <syscalls+0xc0>
    b->next = bcache.head.next;
    8000301a:	2b893783          	ld	a5,696(s2)
    8000301e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003020:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003024:	85d2                	mv	a1,s4
    80003026:	01048513          	addi	a0,s1,16
    8000302a:	00001097          	auipc	ra,0x1
    8000302e:	4bc080e7          	jalr	1212(ra) # 800044e6 <initsleeplock>
    bcache.head.next->prev = b;
    80003032:	2b893783          	ld	a5,696(s2)
    80003036:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003038:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000303c:	45848493          	addi	s1,s1,1112
    80003040:	fd349de3          	bne	s1,s3,8000301a <binit+0x54>
  }
}
    80003044:	70a2                	ld	ra,40(sp)
    80003046:	7402                	ld	s0,32(sp)
    80003048:	64e2                	ld	s1,24(sp)
    8000304a:	6942                	ld	s2,16(sp)
    8000304c:	69a2                	ld	s3,8(sp)
    8000304e:	6a02                	ld	s4,0(sp)
    80003050:	6145                	addi	sp,sp,48
    80003052:	8082                	ret

0000000080003054 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003054:	7179                	addi	sp,sp,-48
    80003056:	f406                	sd	ra,40(sp)
    80003058:	f022                	sd	s0,32(sp)
    8000305a:	ec26                	sd	s1,24(sp)
    8000305c:	e84a                	sd	s2,16(sp)
    8000305e:	e44e                	sd	s3,8(sp)
    80003060:	1800                	addi	s0,sp,48
    80003062:	89aa                	mv	s3,a0
    80003064:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003066:	00014517          	auipc	a0,0x14
    8000306a:	29a50513          	addi	a0,a0,666 # 80017300 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	b76080e7          	jalr	-1162(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003076:	0001c497          	auipc	s1,0x1c
    8000307a:	5424b483          	ld	s1,1346(s1) # 8001f5b8 <bcache+0x82b8>
    8000307e:	0001c797          	auipc	a5,0x1c
    80003082:	4ea78793          	addi	a5,a5,1258 # 8001f568 <bcache+0x8268>
    80003086:	02f48f63          	beq	s1,a5,800030c4 <bread+0x70>
    8000308a:	873e                	mv	a4,a5
    8000308c:	a021                	j	80003094 <bread+0x40>
    8000308e:	68a4                	ld	s1,80(s1)
    80003090:	02e48a63          	beq	s1,a4,800030c4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003094:	449c                	lw	a5,8(s1)
    80003096:	ff379ce3          	bne	a5,s3,8000308e <bread+0x3a>
    8000309a:	44dc                	lw	a5,12(s1)
    8000309c:	ff2799e3          	bne	a5,s2,8000308e <bread+0x3a>
      b->refcnt++;
    800030a0:	40bc                	lw	a5,64(s1)
    800030a2:	2785                	addiw	a5,a5,1
    800030a4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a6:	00014517          	auipc	a0,0x14
    800030aa:	25a50513          	addi	a0,a0,602 # 80017300 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030b6:	01048513          	addi	a0,s1,16
    800030ba:	00001097          	auipc	ra,0x1
    800030be:	466080e7          	jalr	1126(ra) # 80004520 <acquiresleep>
      return b;
    800030c2:	a8b9                	j	80003120 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c4:	0001c497          	auipc	s1,0x1c
    800030c8:	4ec4b483          	ld	s1,1260(s1) # 8001f5b0 <bcache+0x82b0>
    800030cc:	0001c797          	auipc	a5,0x1c
    800030d0:	49c78793          	addi	a5,a5,1180 # 8001f568 <bcache+0x8268>
    800030d4:	00f48863          	beq	s1,a5,800030e4 <bread+0x90>
    800030d8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030da:	40bc                	lw	a5,64(s1)
    800030dc:	cf81                	beqz	a5,800030f4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030de:	64a4                	ld	s1,72(s1)
    800030e0:	fee49de3          	bne	s1,a4,800030da <bread+0x86>
  panic("bget: no buffers");
    800030e4:	00005517          	auipc	a0,0x5
    800030e8:	43c50513          	addi	a0,a0,1084 # 80008520 <syscalls+0xc8>
    800030ec:	ffffd097          	auipc	ra,0xffffd
    800030f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>
      b->dev = dev;
    800030f4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030f8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030fc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003100:	4785                	li	a5,1
    80003102:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003104:	00014517          	auipc	a0,0x14
    80003108:	1fc50513          	addi	a0,a0,508 # 80017300 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003114:	01048513          	addi	a0,s1,16
    80003118:	00001097          	auipc	ra,0x1
    8000311c:	408080e7          	jalr	1032(ra) # 80004520 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003120:	409c                	lw	a5,0(s1)
    80003122:	cb89                	beqz	a5,80003134 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003124:	8526                	mv	a0,s1
    80003126:	70a2                	ld	ra,40(sp)
    80003128:	7402                	ld	s0,32(sp)
    8000312a:	64e2                	ld	s1,24(sp)
    8000312c:	6942                	ld	s2,16(sp)
    8000312e:	69a2                	ld	s3,8(sp)
    80003130:	6145                	addi	sp,sp,48
    80003132:	8082                	ret
    virtio_disk_rw(b, 0);
    80003134:	4581                	li	a1,0
    80003136:	8526                	mv	a0,s1
    80003138:	00003097          	auipc	ra,0x3
    8000313c:	f0e080e7          	jalr	-242(ra) # 80006046 <virtio_disk_rw>
    b->valid = 1;
    80003140:	4785                	li	a5,1
    80003142:	c09c                	sw	a5,0(s1)
  return b;
    80003144:	b7c5                	j	80003124 <bread+0xd0>

0000000080003146 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	1000                	addi	s0,sp,32
    80003150:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003152:	0541                	addi	a0,a0,16
    80003154:	00001097          	auipc	ra,0x1
    80003158:	466080e7          	jalr	1126(ra) # 800045ba <holdingsleep>
    8000315c:	cd01                	beqz	a0,80003174 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000315e:	4585                	li	a1,1
    80003160:	8526                	mv	a0,s1
    80003162:	00003097          	auipc	ra,0x3
    80003166:	ee4080e7          	jalr	-284(ra) # 80006046 <virtio_disk_rw>
}
    8000316a:	60e2                	ld	ra,24(sp)
    8000316c:	6442                	ld	s0,16(sp)
    8000316e:	64a2                	ld	s1,8(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret
    panic("bwrite");
    80003174:	00005517          	auipc	a0,0x5
    80003178:	3c450513          	addi	a0,a0,964 # 80008538 <syscalls+0xe0>
    8000317c:	ffffd097          	auipc	ra,0xffffd
    80003180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>

0000000080003184 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	e04a                	sd	s2,0(sp)
    8000318e:	1000                	addi	s0,sp,32
    80003190:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003192:	01050913          	addi	s2,a0,16
    80003196:	854a                	mv	a0,s2
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	422080e7          	jalr	1058(ra) # 800045ba <holdingsleep>
    800031a0:	c92d                	beqz	a0,80003212 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031a2:	854a                	mv	a0,s2
    800031a4:	00001097          	auipc	ra,0x1
    800031a8:	3d2080e7          	jalr	978(ra) # 80004576 <releasesleep>

  acquire(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	15450513          	addi	a0,a0,340 # 80017300 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a30080e7          	jalr	-1488(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	37fd                	addiw	a5,a5,-1
    800031c0:	0007871b          	sext.w	a4,a5
    800031c4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031c6:	eb05                	bnez	a4,800031f6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c8:	68bc                	ld	a5,80(s1)
    800031ca:	64b8                	ld	a4,72(s1)
    800031cc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031ce:	64bc                	ld	a5,72(s1)
    800031d0:	68b8                	ld	a4,80(s1)
    800031d2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031d4:	0001c797          	auipc	a5,0x1c
    800031d8:	12c78793          	addi	a5,a5,300 # 8001f300 <bcache+0x8000>
    800031dc:	2b87b703          	ld	a4,696(a5)
    800031e0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031e2:	0001c717          	auipc	a4,0x1c
    800031e6:	38670713          	addi	a4,a4,902 # 8001f568 <bcache+0x8268>
    800031ea:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031ec:	2b87b703          	ld	a4,696(a5)
    800031f0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031f2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	10a50513          	addi	a0,a0,266 # 80017300 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6902                	ld	s2,0(sp)
    8000320e:	6105                	addi	sp,sp,32
    80003210:	8082                	ret
    panic("brelse");
    80003212:	00005517          	auipc	a0,0x5
    80003216:	32e50513          	addi	a0,a0,814 # 80008540 <syscalls+0xe8>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	324080e7          	jalr	804(ra) # 8000053e <panic>

0000000080003222 <bpin>:

void
bpin(struct buf *b) {
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	0d250513          	addi	a0,a0,210 # 80017300 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	9ae080e7          	jalr	-1618(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000323e:	40bc                	lw	a5,64(s1)
    80003240:	2785                	addiw	a5,a5,1
    80003242:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003244:	00014517          	auipc	a0,0x14
    80003248:	0bc50513          	addi	a0,a0,188 # 80017300 <bcache>
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
}
    80003254:	60e2                	ld	ra,24(sp)
    80003256:	6442                	ld	s0,16(sp)
    80003258:	64a2                	ld	s1,8(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <bunpin>:

void
bunpin(struct buf *b) {
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	e426                	sd	s1,8(sp)
    80003266:	1000                	addi	s0,sp,32
    80003268:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000326a:	00014517          	auipc	a0,0x14
    8000326e:	09650513          	addi	a0,a0,150 # 80017300 <bcache>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	972080e7          	jalr	-1678(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000327a:	40bc                	lw	a5,64(s1)
    8000327c:	37fd                	addiw	a5,a5,-1
    8000327e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003280:	00014517          	auipc	a0,0x14
    80003284:	08050513          	addi	a0,a0,128 # 80017300 <bcache>
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	a10080e7          	jalr	-1520(ra) # 80000c98 <release>
}
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	64a2                	ld	s1,8(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret

000000008000329a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	e04a                	sd	s2,0(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a8:	00d5d59b          	srliw	a1,a1,0xd
    800032ac:	0001c797          	auipc	a5,0x1c
    800032b0:	7307a783          	lw	a5,1840(a5) # 8001f9dc <sb+0x1c>
    800032b4:	9dbd                	addw	a1,a1,a5
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	d9e080e7          	jalr	-610(ra) # 80003054 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032be:	0074f713          	andi	a4,s1,7
    800032c2:	4785                	li	a5,1
    800032c4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c8:	14ce                	slli	s1,s1,0x33
    800032ca:	90d9                	srli	s1,s1,0x36
    800032cc:	00950733          	add	a4,a0,s1
    800032d0:	05874703          	lbu	a4,88(a4)
    800032d4:	00e7f6b3          	and	a3,a5,a4
    800032d8:	c69d                	beqz	a3,80003306 <bfree+0x6c>
    800032da:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032dc:	94aa                	add	s1,s1,a0
    800032de:	fff7c793          	not	a5,a5
    800032e2:	8ff9                	and	a5,a5,a4
    800032e4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	118080e7          	jalr	280(ra) # 80004400 <log_write>
  brelse(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	e92080e7          	jalr	-366(ra) # 80003184 <brelse>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6902                	ld	s2,0(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret
    panic("freeing free block");
    80003306:	00005517          	auipc	a0,0x5
    8000330a:	24250513          	addi	a0,a0,578 # 80008548 <syscalls+0xf0>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	230080e7          	jalr	560(ra) # 8000053e <panic>

0000000080003316 <balloc>:
{
    80003316:	711d                	addi	sp,sp,-96
    80003318:	ec86                	sd	ra,88(sp)
    8000331a:	e8a2                	sd	s0,80(sp)
    8000331c:	e4a6                	sd	s1,72(sp)
    8000331e:	e0ca                	sd	s2,64(sp)
    80003320:	fc4e                	sd	s3,56(sp)
    80003322:	f852                	sd	s4,48(sp)
    80003324:	f456                	sd	s5,40(sp)
    80003326:	f05a                	sd	s6,32(sp)
    80003328:	ec5e                	sd	s7,24(sp)
    8000332a:	e862                	sd	s8,16(sp)
    8000332c:	e466                	sd	s9,8(sp)
    8000332e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003330:	0001c797          	auipc	a5,0x1c
    80003334:	6947a783          	lw	a5,1684(a5) # 8001f9c4 <sb+0x4>
    80003338:	cbd1                	beqz	a5,800033cc <balloc+0xb6>
    8000333a:	8baa                	mv	s7,a0
    8000333c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000333e:	0001cb17          	auipc	s6,0x1c
    80003342:	682b0b13          	addi	s6,s6,1666 # 8001f9c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003348:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000334c:	6c89                	lui	s9,0x2
    8000334e:	a831                	j	8000336a <balloc+0x54>
    brelse(bp);
    80003350:	854a                	mv	a0,s2
    80003352:	00000097          	auipc	ra,0x0
    80003356:	e32080e7          	jalr	-462(ra) # 80003184 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000335a:	015c87bb          	addw	a5,s9,s5
    8000335e:	00078a9b          	sext.w	s5,a5
    80003362:	004b2703          	lw	a4,4(s6)
    80003366:	06eaf363          	bgeu	s5,a4,800033cc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000336a:	41fad79b          	sraiw	a5,s5,0x1f
    8000336e:	0137d79b          	srliw	a5,a5,0x13
    80003372:	015787bb          	addw	a5,a5,s5
    80003376:	40d7d79b          	sraiw	a5,a5,0xd
    8000337a:	01cb2583          	lw	a1,28(s6)
    8000337e:	9dbd                	addw	a1,a1,a5
    80003380:	855e                	mv	a0,s7
    80003382:	00000097          	auipc	ra,0x0
    80003386:	cd2080e7          	jalr	-814(ra) # 80003054 <bread>
    8000338a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338c:	004b2503          	lw	a0,4(s6)
    80003390:	000a849b          	sext.w	s1,s5
    80003394:	8662                	mv	a2,s8
    80003396:	faa4fde3          	bgeu	s1,a0,80003350 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000339a:	41f6579b          	sraiw	a5,a2,0x1f
    8000339e:	01d7d69b          	srliw	a3,a5,0x1d
    800033a2:	00c6873b          	addw	a4,a3,a2
    800033a6:	00777793          	andi	a5,a4,7
    800033aa:	9f95                	subw	a5,a5,a3
    800033ac:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033b0:	4037571b          	sraiw	a4,a4,0x3
    800033b4:	00e906b3          	add	a3,s2,a4
    800033b8:	0586c683          	lbu	a3,88(a3) # 2000058 <_entry-0x7dffffa8>
    800033bc:	00d7f5b3          	and	a1,a5,a3
    800033c0:	cd91                	beqz	a1,800033dc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c2:	2605                	addiw	a2,a2,1
    800033c4:	2485                	addiw	s1,s1,1
    800033c6:	fd4618e3          	bne	a2,s4,80003396 <balloc+0x80>
    800033ca:	b759                	j	80003350 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	19450513          	addi	a0,a0,404 # 80008560 <syscalls+0x108>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	16a080e7          	jalr	362(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033dc:	974a                	add	a4,a4,s2
    800033de:	8fd5                	or	a5,a5,a3
    800033e0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033e4:	854a                	mv	a0,s2
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	01a080e7          	jalr	26(ra) # 80004400 <log_write>
        brelse(bp);
    800033ee:	854a                	mv	a0,s2
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	d94080e7          	jalr	-620(ra) # 80003184 <brelse>
  bp = bread(dev, bno);
    800033f8:	85a6                	mv	a1,s1
    800033fa:	855e                	mv	a0,s7
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	c58080e7          	jalr	-936(ra) # 80003054 <bread>
    80003404:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003406:	40000613          	li	a2,1024
    8000340a:	4581                	li	a1,0
    8000340c:	05850513          	addi	a0,a0,88
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	8d0080e7          	jalr	-1840(ra) # 80000ce0 <memset>
  log_write(bp);
    80003418:	854a                	mv	a0,s2
    8000341a:	00001097          	auipc	ra,0x1
    8000341e:	fe6080e7          	jalr	-26(ra) # 80004400 <log_write>
  brelse(bp);
    80003422:	854a                	mv	a0,s2
    80003424:	00000097          	auipc	ra,0x0
    80003428:	d60080e7          	jalr	-672(ra) # 80003184 <brelse>
}
    8000342c:	8526                	mv	a0,s1
    8000342e:	60e6                	ld	ra,88(sp)
    80003430:	6446                	ld	s0,80(sp)
    80003432:	64a6                	ld	s1,72(sp)
    80003434:	6906                	ld	s2,64(sp)
    80003436:	79e2                	ld	s3,56(sp)
    80003438:	7a42                	ld	s4,48(sp)
    8000343a:	7aa2                	ld	s5,40(sp)
    8000343c:	7b02                	ld	s6,32(sp)
    8000343e:	6be2                	ld	s7,24(sp)
    80003440:	6c42                	ld	s8,16(sp)
    80003442:	6ca2                	ld	s9,8(sp)
    80003444:	6125                	addi	sp,sp,96
    80003446:	8082                	ret

0000000080003448 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003448:	7179                	addi	sp,sp,-48
    8000344a:	f406                	sd	ra,40(sp)
    8000344c:	f022                	sd	s0,32(sp)
    8000344e:	ec26                	sd	s1,24(sp)
    80003450:	e84a                	sd	s2,16(sp)
    80003452:	e44e                	sd	s3,8(sp)
    80003454:	e052                	sd	s4,0(sp)
    80003456:	1800                	addi	s0,sp,48
    80003458:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000345a:	47ad                	li	a5,11
    8000345c:	04b7fe63          	bgeu	a5,a1,800034b8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003460:	ff45849b          	addiw	s1,a1,-12
    80003464:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003468:	0ff00793          	li	a5,255
    8000346c:	0ae7e363          	bltu	a5,a4,80003512 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003470:	08052583          	lw	a1,128(a0)
    80003474:	c5ad                	beqz	a1,800034de <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003476:	00092503          	lw	a0,0(s2)
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	bda080e7          	jalr	-1062(ra) # 80003054 <bread>
    80003482:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003484:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003488:	02049593          	slli	a1,s1,0x20
    8000348c:	9181                	srli	a1,a1,0x20
    8000348e:	058a                	slli	a1,a1,0x2
    80003490:	00b784b3          	add	s1,a5,a1
    80003494:	0004a983          	lw	s3,0(s1)
    80003498:	04098d63          	beqz	s3,800034f2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000349c:	8552                	mv	a0,s4
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	ce6080e7          	jalr	-794(ra) # 80003184 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034a6:	854e                	mv	a0,s3
    800034a8:	70a2                	ld	ra,40(sp)
    800034aa:	7402                	ld	s0,32(sp)
    800034ac:	64e2                	ld	s1,24(sp)
    800034ae:	6942                	ld	s2,16(sp)
    800034b0:	69a2                	ld	s3,8(sp)
    800034b2:	6a02                	ld	s4,0(sp)
    800034b4:	6145                	addi	sp,sp,48
    800034b6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b8:	02059493          	slli	s1,a1,0x20
    800034bc:	9081                	srli	s1,s1,0x20
    800034be:	048a                	slli	s1,s1,0x2
    800034c0:	94aa                	add	s1,s1,a0
    800034c2:	0504a983          	lw	s3,80(s1)
    800034c6:	fe0990e3          	bnez	s3,800034a6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034ca:	4108                	lw	a0,0(a0)
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	e4a080e7          	jalr	-438(ra) # 80003316 <balloc>
    800034d4:	0005099b          	sext.w	s3,a0
    800034d8:	0534a823          	sw	s3,80(s1)
    800034dc:	b7e9                	j	800034a6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034de:	4108                	lw	a0,0(a0)
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	e36080e7          	jalr	-458(ra) # 80003316 <balloc>
    800034e8:	0005059b          	sext.w	a1,a0
    800034ec:	08b92023          	sw	a1,128(s2)
    800034f0:	b759                	j	80003476 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034f2:	00092503          	lw	a0,0(s2)
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	e20080e7          	jalr	-480(ra) # 80003316 <balloc>
    800034fe:	0005099b          	sext.w	s3,a0
    80003502:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003506:	8552                	mv	a0,s4
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	ef8080e7          	jalr	-264(ra) # 80004400 <log_write>
    80003510:	b771                	j	8000349c <bmap+0x54>
  panic("bmap: out of range");
    80003512:	00005517          	auipc	a0,0x5
    80003516:	06650513          	addi	a0,a0,102 # 80008578 <syscalls+0x120>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	024080e7          	jalr	36(ra) # 8000053e <panic>

0000000080003522 <iget>:
{
    80003522:	7179                	addi	sp,sp,-48
    80003524:	f406                	sd	ra,40(sp)
    80003526:	f022                	sd	s0,32(sp)
    80003528:	ec26                	sd	s1,24(sp)
    8000352a:	e84a                	sd	s2,16(sp)
    8000352c:	e44e                	sd	s3,8(sp)
    8000352e:	e052                	sd	s4,0(sp)
    80003530:	1800                	addi	s0,sp,48
    80003532:	89aa                	mv	s3,a0
    80003534:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003536:	0001c517          	auipc	a0,0x1c
    8000353a:	4aa50513          	addi	a0,a0,1194 # 8001f9e0 <itable>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	6a6080e7          	jalr	1702(ra) # 80000be4 <acquire>
  empty = 0;
    80003546:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003548:	0001c497          	auipc	s1,0x1c
    8000354c:	4b048493          	addi	s1,s1,1200 # 8001f9f8 <itable+0x18>
    80003550:	0001e697          	auipc	a3,0x1e
    80003554:	f3868693          	addi	a3,a3,-200 # 80021488 <log>
    80003558:	a039                	j	80003566 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000355a:	02090b63          	beqz	s2,80003590 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000355e:	08848493          	addi	s1,s1,136
    80003562:	02d48a63          	beq	s1,a3,80003596 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003566:	449c                	lw	a5,8(s1)
    80003568:	fef059e3          	blez	a5,8000355a <iget+0x38>
    8000356c:	4098                	lw	a4,0(s1)
    8000356e:	ff3716e3          	bne	a4,s3,8000355a <iget+0x38>
    80003572:	40d8                	lw	a4,4(s1)
    80003574:	ff4713e3          	bne	a4,s4,8000355a <iget+0x38>
      ip->ref++;
    80003578:	2785                	addiw	a5,a5,1
    8000357a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000357c:	0001c517          	auipc	a0,0x1c
    80003580:	46450513          	addi	a0,a0,1124 # 8001f9e0 <itable>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	714080e7          	jalr	1812(ra) # 80000c98 <release>
      return ip;
    8000358c:	8926                	mv	s2,s1
    8000358e:	a03d                	j	800035bc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003590:	f7f9                	bnez	a5,8000355e <iget+0x3c>
    80003592:	8926                	mv	s2,s1
    80003594:	b7e9                	j	8000355e <iget+0x3c>
  if(empty == 0)
    80003596:	02090c63          	beqz	s2,800035ce <iget+0xac>
  ip->dev = dev;
    8000359a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000359e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035a2:	4785                	li	a5,1
    800035a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035ac:	0001c517          	auipc	a0,0x1c
    800035b0:	43450513          	addi	a0,a0,1076 # 8001f9e0 <itable>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
}
    800035bc:	854a                	mv	a0,s2
    800035be:	70a2                	ld	ra,40(sp)
    800035c0:	7402                	ld	s0,32(sp)
    800035c2:	64e2                	ld	s1,24(sp)
    800035c4:	6942                	ld	s2,16(sp)
    800035c6:	69a2                	ld	s3,8(sp)
    800035c8:	6a02                	ld	s4,0(sp)
    800035ca:	6145                	addi	sp,sp,48
    800035cc:	8082                	ret
    panic("iget: no inodes");
    800035ce:	00005517          	auipc	a0,0x5
    800035d2:	fc250513          	addi	a0,a0,-62 # 80008590 <syscalls+0x138>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	f68080e7          	jalr	-152(ra) # 8000053e <panic>

00000000800035de <fsinit>:
fsinit(int dev) {
    800035de:	7179                	addi	sp,sp,-48
    800035e0:	f406                	sd	ra,40(sp)
    800035e2:	f022                	sd	s0,32(sp)
    800035e4:	ec26                	sd	s1,24(sp)
    800035e6:	e84a                	sd	s2,16(sp)
    800035e8:	e44e                	sd	s3,8(sp)
    800035ea:	1800                	addi	s0,sp,48
    800035ec:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ee:	4585                	li	a1,1
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	a64080e7          	jalr	-1436(ra) # 80003054 <bread>
    800035f8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035fa:	0001c997          	auipc	s3,0x1c
    800035fe:	3c698993          	addi	s3,s3,966 # 8001f9c0 <sb>
    80003602:	02000613          	li	a2,32
    80003606:	05850593          	addi	a1,a0,88
    8000360a:	854e                	mv	a0,s3
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	734080e7          	jalr	1844(ra) # 80000d40 <memmove>
  brelse(bp);
    80003614:	8526                	mv	a0,s1
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	b6e080e7          	jalr	-1170(ra) # 80003184 <brelse>
  if(sb.magic != FSMAGIC)
    8000361e:	0009a703          	lw	a4,0(s3)
    80003622:	102037b7          	lui	a5,0x10203
    80003626:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000362a:	02f71263          	bne	a4,a5,8000364e <fsinit+0x70>
  initlog(dev, &sb);
    8000362e:	0001c597          	auipc	a1,0x1c
    80003632:	39258593          	addi	a1,a1,914 # 8001f9c0 <sb>
    80003636:	854a                	mv	a0,s2
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	b4c080e7          	jalr	-1204(ra) # 80004184 <initlog>
}
    80003640:	70a2                	ld	ra,40(sp)
    80003642:	7402                	ld	s0,32(sp)
    80003644:	64e2                	ld	s1,24(sp)
    80003646:	6942                	ld	s2,16(sp)
    80003648:	69a2                	ld	s3,8(sp)
    8000364a:	6145                	addi	sp,sp,48
    8000364c:	8082                	ret
    panic("invalid file system");
    8000364e:	00005517          	auipc	a0,0x5
    80003652:	f5250513          	addi	a0,a0,-174 # 800085a0 <syscalls+0x148>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>

000000008000365e <iinit>:
{
    8000365e:	7179                	addi	sp,sp,-48
    80003660:	f406                	sd	ra,40(sp)
    80003662:	f022                	sd	s0,32(sp)
    80003664:	ec26                	sd	s1,24(sp)
    80003666:	e84a                	sd	s2,16(sp)
    80003668:	e44e                	sd	s3,8(sp)
    8000366a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000366c:	00005597          	auipc	a1,0x5
    80003670:	f4c58593          	addi	a1,a1,-180 # 800085b8 <syscalls+0x160>
    80003674:	0001c517          	auipc	a0,0x1c
    80003678:	36c50513          	addi	a0,a0,876 # 8001f9e0 <itable>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	4d8080e7          	jalr	1240(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003684:	0001c497          	auipc	s1,0x1c
    80003688:	38448493          	addi	s1,s1,900 # 8001fa08 <itable+0x28>
    8000368c:	0001e997          	auipc	s3,0x1e
    80003690:	e0c98993          	addi	s3,s3,-500 # 80021498 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003694:	00005917          	auipc	s2,0x5
    80003698:	f2c90913          	addi	s2,s2,-212 # 800085c0 <syscalls+0x168>
    8000369c:	85ca                	mv	a1,s2
    8000369e:	8526                	mv	a0,s1
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	e46080e7          	jalr	-442(ra) # 800044e6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a8:	08848493          	addi	s1,s1,136
    800036ac:	ff3498e3          	bne	s1,s3,8000369c <iinit+0x3e>
}
    800036b0:	70a2                	ld	ra,40(sp)
    800036b2:	7402                	ld	s0,32(sp)
    800036b4:	64e2                	ld	s1,24(sp)
    800036b6:	6942                	ld	s2,16(sp)
    800036b8:	69a2                	ld	s3,8(sp)
    800036ba:	6145                	addi	sp,sp,48
    800036bc:	8082                	ret

00000000800036be <ialloc>:
{
    800036be:	715d                	addi	sp,sp,-80
    800036c0:	e486                	sd	ra,72(sp)
    800036c2:	e0a2                	sd	s0,64(sp)
    800036c4:	fc26                	sd	s1,56(sp)
    800036c6:	f84a                	sd	s2,48(sp)
    800036c8:	f44e                	sd	s3,40(sp)
    800036ca:	f052                	sd	s4,32(sp)
    800036cc:	ec56                	sd	s5,24(sp)
    800036ce:	e85a                	sd	s6,16(sp)
    800036d0:	e45e                	sd	s7,8(sp)
    800036d2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d4:	0001c717          	auipc	a4,0x1c
    800036d8:	2f872703          	lw	a4,760(a4) # 8001f9cc <sb+0xc>
    800036dc:	4785                	li	a5,1
    800036de:	04e7fa63          	bgeu	a5,a4,80003732 <ialloc+0x74>
    800036e2:	8aaa                	mv	s5,a0
    800036e4:	8bae                	mv	s7,a1
    800036e6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e8:	0001ca17          	auipc	s4,0x1c
    800036ec:	2d8a0a13          	addi	s4,s4,728 # 8001f9c0 <sb>
    800036f0:	00048b1b          	sext.w	s6,s1
    800036f4:	0044d593          	srli	a1,s1,0x4
    800036f8:	018a2783          	lw	a5,24(s4)
    800036fc:	9dbd                	addw	a1,a1,a5
    800036fe:	8556                	mv	a0,s5
    80003700:	00000097          	auipc	ra,0x0
    80003704:	954080e7          	jalr	-1708(ra) # 80003054 <bread>
    80003708:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000370a:	05850993          	addi	s3,a0,88
    8000370e:	00f4f793          	andi	a5,s1,15
    80003712:	079a                	slli	a5,a5,0x6
    80003714:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003716:	00099783          	lh	a5,0(s3)
    8000371a:	c785                	beqz	a5,80003742 <ialloc+0x84>
    brelse(bp);
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	a68080e7          	jalr	-1432(ra) # 80003184 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003724:	0485                	addi	s1,s1,1
    80003726:	00ca2703          	lw	a4,12(s4)
    8000372a:	0004879b          	sext.w	a5,s1
    8000372e:	fce7e1e3          	bltu	a5,a4,800036f0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	e9650513          	addi	a0,a0,-362 # 800085c8 <syscalls+0x170>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e04080e7          	jalr	-508(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003742:	04000613          	li	a2,64
    80003746:	4581                	li	a1,0
    80003748:	854e                	mv	a0,s3
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	596080e7          	jalr	1430(ra) # 80000ce0 <memset>
      dip->type = type;
    80003752:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	ca8080e7          	jalr	-856(ra) # 80004400 <log_write>
      brelse(bp);
    80003760:	854a                	mv	a0,s2
    80003762:	00000097          	auipc	ra,0x0
    80003766:	a22080e7          	jalr	-1502(ra) # 80003184 <brelse>
      return iget(dev, inum);
    8000376a:	85da                	mv	a1,s6
    8000376c:	8556                	mv	a0,s5
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	db4080e7          	jalr	-588(ra) # 80003522 <iget>
}
    80003776:	60a6                	ld	ra,72(sp)
    80003778:	6406                	ld	s0,64(sp)
    8000377a:	74e2                	ld	s1,56(sp)
    8000377c:	7942                	ld	s2,48(sp)
    8000377e:	79a2                	ld	s3,40(sp)
    80003780:	7a02                	ld	s4,32(sp)
    80003782:	6ae2                	ld	s5,24(sp)
    80003784:	6b42                	ld	s6,16(sp)
    80003786:	6ba2                	ld	s7,8(sp)
    80003788:	6161                	addi	sp,sp,80
    8000378a:	8082                	ret

000000008000378c <iupdate>:
{
    8000378c:	1101                	addi	sp,sp,-32
    8000378e:	ec06                	sd	ra,24(sp)
    80003790:	e822                	sd	s0,16(sp)
    80003792:	e426                	sd	s1,8(sp)
    80003794:	e04a                	sd	s2,0(sp)
    80003796:	1000                	addi	s0,sp,32
    80003798:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000379a:	415c                	lw	a5,4(a0)
    8000379c:	0047d79b          	srliw	a5,a5,0x4
    800037a0:	0001c597          	auipc	a1,0x1c
    800037a4:	2385a583          	lw	a1,568(a1) # 8001f9d8 <sb+0x18>
    800037a8:	9dbd                	addw	a1,a1,a5
    800037aa:	4108                	lw	a0,0(a0)
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	8a8080e7          	jalr	-1880(ra) # 80003054 <bread>
    800037b4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b6:	05850793          	addi	a5,a0,88
    800037ba:	40c8                	lw	a0,4(s1)
    800037bc:	893d                	andi	a0,a0,15
    800037be:	051a                	slli	a0,a0,0x6
    800037c0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037c2:	04449703          	lh	a4,68(s1)
    800037c6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037ca:	04649703          	lh	a4,70(s1)
    800037ce:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037d2:	04849703          	lh	a4,72(s1)
    800037d6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037da:	04a49703          	lh	a4,74(s1)
    800037de:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037e2:	44f8                	lw	a4,76(s1)
    800037e4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e6:	03400613          	li	a2,52
    800037ea:	05048593          	addi	a1,s1,80
    800037ee:	0531                	addi	a0,a0,12
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	550080e7          	jalr	1360(ra) # 80000d40 <memmove>
  log_write(bp);
    800037f8:	854a                	mv	a0,s2
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	c06080e7          	jalr	-1018(ra) # 80004400 <log_write>
  brelse(bp);
    80003802:	854a                	mv	a0,s2
    80003804:	00000097          	auipc	ra,0x0
    80003808:	980080e7          	jalr	-1664(ra) # 80003184 <brelse>
}
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6902                	ld	s2,0(sp)
    80003814:	6105                	addi	sp,sp,32
    80003816:	8082                	ret

0000000080003818 <idup>:
{
    80003818:	1101                	addi	sp,sp,-32
    8000381a:	ec06                	sd	ra,24(sp)
    8000381c:	e822                	sd	s0,16(sp)
    8000381e:	e426                	sd	s1,8(sp)
    80003820:	1000                	addi	s0,sp,32
    80003822:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	1bc50513          	addi	a0,a0,444 # 8001f9e0 <itable>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	3b8080e7          	jalr	952(ra) # 80000be4 <acquire>
  ip->ref++;
    80003834:	449c                	lw	a5,8(s1)
    80003836:	2785                	addiw	a5,a5,1
    80003838:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	1a650513          	addi	a0,a0,422 # 8001f9e0 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	456080e7          	jalr	1110(ra) # 80000c98 <release>
}
    8000384a:	8526                	mv	a0,s1
    8000384c:	60e2                	ld	ra,24(sp)
    8000384e:	6442                	ld	s0,16(sp)
    80003850:	64a2                	ld	s1,8(sp)
    80003852:	6105                	addi	sp,sp,32
    80003854:	8082                	ret

0000000080003856 <ilock>:
{
    80003856:	1101                	addi	sp,sp,-32
    80003858:	ec06                	sd	ra,24(sp)
    8000385a:	e822                	sd	s0,16(sp)
    8000385c:	e426                	sd	s1,8(sp)
    8000385e:	e04a                	sd	s2,0(sp)
    80003860:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003862:	c115                	beqz	a0,80003886 <ilock+0x30>
    80003864:	84aa                	mv	s1,a0
    80003866:	451c                	lw	a5,8(a0)
    80003868:	00f05f63          	blez	a5,80003886 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000386c:	0541                	addi	a0,a0,16
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	cb2080e7          	jalr	-846(ra) # 80004520 <acquiresleep>
  if(ip->valid == 0){
    80003876:	40bc                	lw	a5,64(s1)
    80003878:	cf99                	beqz	a5,80003896 <ilock+0x40>
}
    8000387a:	60e2                	ld	ra,24(sp)
    8000387c:	6442                	ld	s0,16(sp)
    8000387e:	64a2                	ld	s1,8(sp)
    80003880:	6902                	ld	s2,0(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret
    panic("ilock");
    80003886:	00005517          	auipc	a0,0x5
    8000388a:	d5a50513          	addi	a0,a0,-678 # 800085e0 <syscalls+0x188>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003896:	40dc                	lw	a5,4(s1)
    80003898:	0047d79b          	srliw	a5,a5,0x4
    8000389c:	0001c597          	auipc	a1,0x1c
    800038a0:	13c5a583          	lw	a1,316(a1) # 8001f9d8 <sb+0x18>
    800038a4:	9dbd                	addw	a1,a1,a5
    800038a6:	4088                	lw	a0,0(s1)
    800038a8:	fffff097          	auipc	ra,0xfffff
    800038ac:	7ac080e7          	jalr	1964(ra) # 80003054 <bread>
    800038b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b2:	05850593          	addi	a1,a0,88
    800038b6:	40dc                	lw	a5,4(s1)
    800038b8:	8bbd                	andi	a5,a5,15
    800038ba:	079a                	slli	a5,a5,0x6
    800038bc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038be:	00059783          	lh	a5,0(a1)
    800038c2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c6:	00259783          	lh	a5,2(a1)
    800038ca:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038ce:	00459783          	lh	a5,4(a1)
    800038d2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d6:	00659783          	lh	a5,6(a1)
    800038da:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038de:	459c                	lw	a5,8(a1)
    800038e0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038e2:	03400613          	li	a2,52
    800038e6:	05b1                	addi	a1,a1,12
    800038e8:	05048513          	addi	a0,s1,80
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	454080e7          	jalr	1108(ra) # 80000d40 <memmove>
    brelse(bp);
    800038f4:	854a                	mv	a0,s2
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	88e080e7          	jalr	-1906(ra) # 80003184 <brelse>
    ip->valid = 1;
    800038fe:	4785                	li	a5,1
    80003900:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003902:	04449783          	lh	a5,68(s1)
    80003906:	fbb5                	bnez	a5,8000387a <ilock+0x24>
      panic("ilock: no type");
    80003908:	00005517          	auipc	a0,0x5
    8000390c:	ce050513          	addi	a0,a0,-800 # 800085e8 <syscalls+0x190>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	c2e080e7          	jalr	-978(ra) # 8000053e <panic>

0000000080003918 <iunlock>:
{
    80003918:	1101                	addi	sp,sp,-32
    8000391a:	ec06                	sd	ra,24(sp)
    8000391c:	e822                	sd	s0,16(sp)
    8000391e:	e426                	sd	s1,8(sp)
    80003920:	e04a                	sd	s2,0(sp)
    80003922:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003924:	c905                	beqz	a0,80003954 <iunlock+0x3c>
    80003926:	84aa                	mv	s1,a0
    80003928:	01050913          	addi	s2,a0,16
    8000392c:	854a                	mv	a0,s2
    8000392e:	00001097          	auipc	ra,0x1
    80003932:	c8c080e7          	jalr	-884(ra) # 800045ba <holdingsleep>
    80003936:	cd19                	beqz	a0,80003954 <iunlock+0x3c>
    80003938:	449c                	lw	a5,8(s1)
    8000393a:	00f05d63          	blez	a5,80003954 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000393e:	854a                	mv	a0,s2
    80003940:	00001097          	auipc	ra,0x1
    80003944:	c36080e7          	jalr	-970(ra) # 80004576 <releasesleep>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6902                	ld	s2,0(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret
    panic("iunlock");
    80003954:	00005517          	auipc	a0,0x5
    80003958:	ca450513          	addi	a0,a0,-860 # 800085f8 <syscalls+0x1a0>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>

0000000080003964 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003964:	7179                	addi	sp,sp,-48
    80003966:	f406                	sd	ra,40(sp)
    80003968:	f022                	sd	s0,32(sp)
    8000396a:	ec26                	sd	s1,24(sp)
    8000396c:	e84a                	sd	s2,16(sp)
    8000396e:	e44e                	sd	s3,8(sp)
    80003970:	e052                	sd	s4,0(sp)
    80003972:	1800                	addi	s0,sp,48
    80003974:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003976:	05050493          	addi	s1,a0,80
    8000397a:	08050913          	addi	s2,a0,128
    8000397e:	a021                	j	80003986 <itrunc+0x22>
    80003980:	0491                	addi	s1,s1,4
    80003982:	01248d63          	beq	s1,s2,8000399c <itrunc+0x38>
    if(ip->addrs[i]){
    80003986:	408c                	lw	a1,0(s1)
    80003988:	dde5                	beqz	a1,80003980 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000398a:	0009a503          	lw	a0,0(s3)
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	90c080e7          	jalr	-1780(ra) # 8000329a <bfree>
      ip->addrs[i] = 0;
    80003996:	0004a023          	sw	zero,0(s1)
    8000399a:	b7dd                	j	80003980 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000399c:	0809a583          	lw	a1,128(s3)
    800039a0:	e185                	bnez	a1,800039c0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039a2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a6:	854e                	mv	a0,s3
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	de4080e7          	jalr	-540(ra) # 8000378c <iupdate>
}
    800039b0:	70a2                	ld	ra,40(sp)
    800039b2:	7402                	ld	s0,32(sp)
    800039b4:	64e2                	ld	s1,24(sp)
    800039b6:	6942                	ld	s2,16(sp)
    800039b8:	69a2                	ld	s3,8(sp)
    800039ba:	6a02                	ld	s4,0(sp)
    800039bc:	6145                	addi	sp,sp,48
    800039be:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039c0:	0009a503          	lw	a0,0(s3)
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	690080e7          	jalr	1680(ra) # 80003054 <bread>
    800039cc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039ce:	05850493          	addi	s1,a0,88
    800039d2:	45850913          	addi	s2,a0,1112
    800039d6:	a811                	j	800039ea <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039d8:	0009a503          	lw	a0,0(s3)
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	8be080e7          	jalr	-1858(ra) # 8000329a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039e4:	0491                	addi	s1,s1,4
    800039e6:	01248563          	beq	s1,s2,800039f0 <itrunc+0x8c>
      if(a[j])
    800039ea:	408c                	lw	a1,0(s1)
    800039ec:	dde5                	beqz	a1,800039e4 <itrunc+0x80>
    800039ee:	b7ed                	j	800039d8 <itrunc+0x74>
    brelse(bp);
    800039f0:	8552                	mv	a0,s4
    800039f2:	fffff097          	auipc	ra,0xfffff
    800039f6:	792080e7          	jalr	1938(ra) # 80003184 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039fa:	0809a583          	lw	a1,128(s3)
    800039fe:	0009a503          	lw	a0,0(s3)
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	898080e7          	jalr	-1896(ra) # 8000329a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a0a:	0809a023          	sw	zero,128(s3)
    80003a0e:	bf51                	j	800039a2 <itrunc+0x3e>

0000000080003a10 <iput>:
{
    80003a10:	1101                	addi	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	e426                	sd	s1,8(sp)
    80003a18:	e04a                	sd	s2,0(sp)
    80003a1a:	1000                	addi	s0,sp,32
    80003a1c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	fc250513          	addi	a0,a0,-62 # 8001f9e0 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	1be080e7          	jalr	446(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2e:	4498                	lw	a4,8(s1)
    80003a30:	4785                	li	a5,1
    80003a32:	02f70363          	beq	a4,a5,80003a58 <iput+0x48>
  ip->ref--;
    80003a36:	449c                	lw	a5,8(s1)
    80003a38:	37fd                	addiw	a5,a5,-1
    80003a3a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a3c:	0001c517          	auipc	a0,0x1c
    80003a40:	fa450513          	addi	a0,a0,-92 # 8001f9e0 <itable>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	254080e7          	jalr	596(ra) # 80000c98 <release>
}
    80003a4c:	60e2                	ld	ra,24(sp)
    80003a4e:	6442                	ld	s0,16(sp)
    80003a50:	64a2                	ld	s1,8(sp)
    80003a52:	6902                	ld	s2,0(sp)
    80003a54:	6105                	addi	sp,sp,32
    80003a56:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a58:	40bc                	lw	a5,64(s1)
    80003a5a:	dff1                	beqz	a5,80003a36 <iput+0x26>
    80003a5c:	04a49783          	lh	a5,74(s1)
    80003a60:	fbf9                	bnez	a5,80003a36 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a62:	01048913          	addi	s2,s1,16
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	ab8080e7          	jalr	-1352(ra) # 80004520 <acquiresleep>
    release(&itable.lock);
    80003a70:	0001c517          	auipc	a0,0x1c
    80003a74:	f7050513          	addi	a0,a0,-144 # 8001f9e0 <itable>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	220080e7          	jalr	544(ra) # 80000c98 <release>
    itrunc(ip);
    80003a80:	8526                	mv	a0,s1
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	ee2080e7          	jalr	-286(ra) # 80003964 <itrunc>
    ip->type = 0;
    80003a8a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a8e:	8526                	mv	a0,s1
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	cfc080e7          	jalr	-772(ra) # 8000378c <iupdate>
    ip->valid = 0;
    80003a98:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00001097          	auipc	ra,0x1
    80003aa2:	ad8080e7          	jalr	-1320(ra) # 80004576 <releasesleep>
    acquire(&itable.lock);
    80003aa6:	0001c517          	auipc	a0,0x1c
    80003aaa:	f3a50513          	addi	a0,a0,-198 # 8001f9e0 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	136080e7          	jalr	310(ra) # 80000be4 <acquire>
    80003ab6:	b741                	j	80003a36 <iput+0x26>

0000000080003ab8 <iunlockput>:
{
    80003ab8:	1101                	addi	sp,sp,-32
    80003aba:	ec06                	sd	ra,24(sp)
    80003abc:	e822                	sd	s0,16(sp)
    80003abe:	e426                	sd	s1,8(sp)
    80003ac0:	1000                	addi	s0,sp,32
    80003ac2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	e54080e7          	jalr	-428(ra) # 80003918 <iunlock>
  iput(ip);
    80003acc:	8526                	mv	a0,s1
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	f42080e7          	jalr	-190(ra) # 80003a10 <iput>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	64a2                	ld	s1,8(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret

0000000080003ae0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ae0:	1141                	addi	sp,sp,-16
    80003ae2:	e422                	sd	s0,8(sp)
    80003ae4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae6:	411c                	lw	a5,0(a0)
    80003ae8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aea:	415c                	lw	a5,4(a0)
    80003aec:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aee:	04451783          	lh	a5,68(a0)
    80003af2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af6:	04a51783          	lh	a5,74(a0)
    80003afa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003afe:	04c56783          	lwu	a5,76(a0)
    80003b02:	e99c                	sd	a5,16(a1)
}
    80003b04:	6422                	ld	s0,8(sp)
    80003b06:	0141                	addi	sp,sp,16
    80003b08:	8082                	ret

0000000080003b0a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b0a:	457c                	lw	a5,76(a0)
    80003b0c:	0ed7e963          	bltu	a5,a3,80003bfe <readi+0xf4>
{
    80003b10:	7159                	addi	sp,sp,-112
    80003b12:	f486                	sd	ra,104(sp)
    80003b14:	f0a2                	sd	s0,96(sp)
    80003b16:	eca6                	sd	s1,88(sp)
    80003b18:	e8ca                	sd	s2,80(sp)
    80003b1a:	e4ce                	sd	s3,72(sp)
    80003b1c:	e0d2                	sd	s4,64(sp)
    80003b1e:	fc56                	sd	s5,56(sp)
    80003b20:	f85a                	sd	s6,48(sp)
    80003b22:	f45e                	sd	s7,40(sp)
    80003b24:	f062                	sd	s8,32(sp)
    80003b26:	ec66                	sd	s9,24(sp)
    80003b28:	e86a                	sd	s10,16(sp)
    80003b2a:	e46e                	sd	s11,8(sp)
    80003b2c:	1880                	addi	s0,sp,112
    80003b2e:	8baa                	mv	s7,a0
    80003b30:	8c2e                	mv	s8,a1
    80003b32:	8ab2                	mv	s5,a2
    80003b34:	84b6                	mv	s1,a3
    80003b36:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b38:	9f35                	addw	a4,a4,a3
    return 0;
    80003b3a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b3c:	0ad76063          	bltu	a4,a3,80003bdc <readi+0xd2>
  if(off + n > ip->size)
    80003b40:	00e7f463          	bgeu	a5,a4,80003b48 <readi+0x3e>
    n = ip->size - off;
    80003b44:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b48:	0a0b0963          	beqz	s6,80003bfa <readi+0xf0>
    80003b4c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b52:	5cfd                	li	s9,-1
    80003b54:	a82d                	j	80003b8e <readi+0x84>
    80003b56:	020a1d93          	slli	s11,s4,0x20
    80003b5a:	020ddd93          	srli	s11,s11,0x20
    80003b5e:	05890613          	addi	a2,s2,88
    80003b62:	86ee                	mv	a3,s11
    80003b64:	963a                	add	a2,a2,a4
    80003b66:	85d6                	mv	a1,s5
    80003b68:	8562                	mv	a0,s8
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	af0080e7          	jalr	-1296(ra) # 8000265a <either_copyout>
    80003b72:	05950d63          	beq	a0,s9,80003bcc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b76:	854a                	mv	a0,s2
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	60c080e7          	jalr	1548(ra) # 80003184 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b80:	013a09bb          	addw	s3,s4,s3
    80003b84:	009a04bb          	addw	s1,s4,s1
    80003b88:	9aee                	add	s5,s5,s11
    80003b8a:	0569f763          	bgeu	s3,s6,80003bd8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8e:	000ba903          	lw	s2,0(s7)
    80003b92:	00a4d59b          	srliw	a1,s1,0xa
    80003b96:	855e                	mv	a0,s7
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	8b0080e7          	jalr	-1872(ra) # 80003448 <bmap>
    80003ba0:	0005059b          	sext.w	a1,a0
    80003ba4:	854a                	mv	a0,s2
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	4ae080e7          	jalr	1198(ra) # 80003054 <bread>
    80003bae:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb0:	3ff4f713          	andi	a4,s1,1023
    80003bb4:	40ed07bb          	subw	a5,s10,a4
    80003bb8:	413b06bb          	subw	a3,s6,s3
    80003bbc:	8a3e                	mv	s4,a5
    80003bbe:	2781                	sext.w	a5,a5
    80003bc0:	0006861b          	sext.w	a2,a3
    80003bc4:	f8f679e3          	bgeu	a2,a5,80003b56 <readi+0x4c>
    80003bc8:	8a36                	mv	s4,a3
    80003bca:	b771                	j	80003b56 <readi+0x4c>
      brelse(bp);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	5b6080e7          	jalr	1462(ra) # 80003184 <brelse>
      tot = -1;
    80003bd6:	59fd                	li	s3,-1
  }
  return tot;
    80003bd8:	0009851b          	sext.w	a0,s3
}
    80003bdc:	70a6                	ld	ra,104(sp)
    80003bde:	7406                	ld	s0,96(sp)
    80003be0:	64e6                	ld	s1,88(sp)
    80003be2:	6946                	ld	s2,80(sp)
    80003be4:	69a6                	ld	s3,72(sp)
    80003be6:	6a06                	ld	s4,64(sp)
    80003be8:	7ae2                	ld	s5,56(sp)
    80003bea:	7b42                	ld	s6,48(sp)
    80003bec:	7ba2                	ld	s7,40(sp)
    80003bee:	7c02                	ld	s8,32(sp)
    80003bf0:	6ce2                	ld	s9,24(sp)
    80003bf2:	6d42                	ld	s10,16(sp)
    80003bf4:	6da2                	ld	s11,8(sp)
    80003bf6:	6165                	addi	sp,sp,112
    80003bf8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfa:	89da                	mv	s3,s6
    80003bfc:	bff1                	j	80003bd8 <readi+0xce>
    return 0;
    80003bfe:	4501                	li	a0,0
}
    80003c00:	8082                	ret

0000000080003c02 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c02:	457c                	lw	a5,76(a0)
    80003c04:	10d7e863          	bltu	a5,a3,80003d14 <writei+0x112>
{
    80003c08:	7159                	addi	sp,sp,-112
    80003c0a:	f486                	sd	ra,104(sp)
    80003c0c:	f0a2                	sd	s0,96(sp)
    80003c0e:	eca6                	sd	s1,88(sp)
    80003c10:	e8ca                	sd	s2,80(sp)
    80003c12:	e4ce                	sd	s3,72(sp)
    80003c14:	e0d2                	sd	s4,64(sp)
    80003c16:	fc56                	sd	s5,56(sp)
    80003c18:	f85a                	sd	s6,48(sp)
    80003c1a:	f45e                	sd	s7,40(sp)
    80003c1c:	f062                	sd	s8,32(sp)
    80003c1e:	ec66                	sd	s9,24(sp)
    80003c20:	e86a                	sd	s10,16(sp)
    80003c22:	e46e                	sd	s11,8(sp)
    80003c24:	1880                	addi	s0,sp,112
    80003c26:	8b2a                	mv	s6,a0
    80003c28:	8c2e                	mv	s8,a1
    80003c2a:	8ab2                	mv	s5,a2
    80003c2c:	8936                	mv	s2,a3
    80003c2e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c30:	00e687bb          	addw	a5,a3,a4
    80003c34:	0ed7e263          	bltu	a5,a3,80003d18 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c38:	00043737          	lui	a4,0x43
    80003c3c:	0ef76063          	bltu	a4,a5,80003d1c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c40:	0c0b8863          	beqz	s7,80003d10 <writei+0x10e>
    80003c44:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c46:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c4a:	5cfd                	li	s9,-1
    80003c4c:	a091                	j	80003c90 <writei+0x8e>
    80003c4e:	02099d93          	slli	s11,s3,0x20
    80003c52:	020ddd93          	srli	s11,s11,0x20
    80003c56:	05848513          	addi	a0,s1,88
    80003c5a:	86ee                	mv	a3,s11
    80003c5c:	8656                	mv	a2,s5
    80003c5e:	85e2                	mv	a1,s8
    80003c60:	953a                	add	a0,a0,a4
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	a4e080e7          	jalr	-1458(ra) # 800026b0 <either_copyin>
    80003c6a:	07950263          	beq	a0,s9,80003cce <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c6e:	8526                	mv	a0,s1
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	790080e7          	jalr	1936(ra) # 80004400 <log_write>
    brelse(bp);
    80003c78:	8526                	mv	a0,s1
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	50a080e7          	jalr	1290(ra) # 80003184 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c82:	01498a3b          	addw	s4,s3,s4
    80003c86:	0129893b          	addw	s2,s3,s2
    80003c8a:	9aee                	add	s5,s5,s11
    80003c8c:	057a7663          	bgeu	s4,s7,80003cd8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c90:	000b2483          	lw	s1,0(s6)
    80003c94:	00a9559b          	srliw	a1,s2,0xa
    80003c98:	855a                	mv	a0,s6
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	7ae080e7          	jalr	1966(ra) # 80003448 <bmap>
    80003ca2:	0005059b          	sext.w	a1,a0
    80003ca6:	8526                	mv	a0,s1
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	3ac080e7          	jalr	940(ra) # 80003054 <bread>
    80003cb0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb2:	3ff97713          	andi	a4,s2,1023
    80003cb6:	40ed07bb          	subw	a5,s10,a4
    80003cba:	414b86bb          	subw	a3,s7,s4
    80003cbe:	89be                	mv	s3,a5
    80003cc0:	2781                	sext.w	a5,a5
    80003cc2:	0006861b          	sext.w	a2,a3
    80003cc6:	f8f674e3          	bgeu	a2,a5,80003c4e <writei+0x4c>
    80003cca:	89b6                	mv	s3,a3
    80003ccc:	b749                	j	80003c4e <writei+0x4c>
      brelse(bp);
    80003cce:	8526                	mv	a0,s1
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	4b4080e7          	jalr	1204(ra) # 80003184 <brelse>
  }

  if(off > ip->size)
    80003cd8:	04cb2783          	lw	a5,76(s6)
    80003cdc:	0127f463          	bgeu	a5,s2,80003ce4 <writei+0xe2>
    ip->size = off;
    80003ce0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ce4:	855a                	mv	a0,s6
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	aa6080e7          	jalr	-1370(ra) # 8000378c <iupdate>

  return tot;
    80003cee:	000a051b          	sext.w	a0,s4
}
    80003cf2:	70a6                	ld	ra,104(sp)
    80003cf4:	7406                	ld	s0,96(sp)
    80003cf6:	64e6                	ld	s1,88(sp)
    80003cf8:	6946                	ld	s2,80(sp)
    80003cfa:	69a6                	ld	s3,72(sp)
    80003cfc:	6a06                	ld	s4,64(sp)
    80003cfe:	7ae2                	ld	s5,56(sp)
    80003d00:	7b42                	ld	s6,48(sp)
    80003d02:	7ba2                	ld	s7,40(sp)
    80003d04:	7c02                	ld	s8,32(sp)
    80003d06:	6ce2                	ld	s9,24(sp)
    80003d08:	6d42                	ld	s10,16(sp)
    80003d0a:	6da2                	ld	s11,8(sp)
    80003d0c:	6165                	addi	sp,sp,112
    80003d0e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d10:	8a5e                	mv	s4,s7
    80003d12:	bfc9                	j	80003ce4 <writei+0xe2>
    return -1;
    80003d14:	557d                	li	a0,-1
}
    80003d16:	8082                	ret
    return -1;
    80003d18:	557d                	li	a0,-1
    80003d1a:	bfe1                	j	80003cf2 <writei+0xf0>
    return -1;
    80003d1c:	557d                	li	a0,-1
    80003d1e:	bfd1                	j	80003cf2 <writei+0xf0>

0000000080003d20 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d20:	1141                	addi	sp,sp,-16
    80003d22:	e406                	sd	ra,8(sp)
    80003d24:	e022                	sd	s0,0(sp)
    80003d26:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d28:	4639                	li	a2,14
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	08e080e7          	jalr	142(ra) # 80000db8 <strncmp>
}
    80003d32:	60a2                	ld	ra,8(sp)
    80003d34:	6402                	ld	s0,0(sp)
    80003d36:	0141                	addi	sp,sp,16
    80003d38:	8082                	ret

0000000080003d3a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d3a:	7139                	addi	sp,sp,-64
    80003d3c:	fc06                	sd	ra,56(sp)
    80003d3e:	f822                	sd	s0,48(sp)
    80003d40:	f426                	sd	s1,40(sp)
    80003d42:	f04a                	sd	s2,32(sp)
    80003d44:	ec4e                	sd	s3,24(sp)
    80003d46:	e852                	sd	s4,16(sp)
    80003d48:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d4a:	04451703          	lh	a4,68(a0)
    80003d4e:	4785                	li	a5,1
    80003d50:	00f71a63          	bne	a4,a5,80003d64 <dirlookup+0x2a>
    80003d54:	892a                	mv	s2,a0
    80003d56:	89ae                	mv	s3,a1
    80003d58:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5a:	457c                	lw	a5,76(a0)
    80003d5c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d5e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d60:	e79d                	bnez	a5,80003d8e <dirlookup+0x54>
    80003d62:	a8a5                	j	80003dda <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d64:	00005517          	auipc	a0,0x5
    80003d68:	89c50513          	addi	a0,a0,-1892 # 80008600 <syscalls+0x1a8>
    80003d6c:	ffffc097          	auipc	ra,0xffffc
    80003d70:	7d2080e7          	jalr	2002(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d74:	00005517          	auipc	a0,0x5
    80003d78:	8a450513          	addi	a0,a0,-1884 # 80008618 <syscalls+0x1c0>
    80003d7c:	ffffc097          	auipc	ra,0xffffc
    80003d80:	7c2080e7          	jalr	1986(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d84:	24c1                	addiw	s1,s1,16
    80003d86:	04c92783          	lw	a5,76(s2)
    80003d8a:	04f4f763          	bgeu	s1,a5,80003dd8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d8e:	4741                	li	a4,16
    80003d90:	86a6                	mv	a3,s1
    80003d92:	fc040613          	addi	a2,s0,-64
    80003d96:	4581                	li	a1,0
    80003d98:	854a                	mv	a0,s2
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	d70080e7          	jalr	-656(ra) # 80003b0a <readi>
    80003da2:	47c1                	li	a5,16
    80003da4:	fcf518e3          	bne	a0,a5,80003d74 <dirlookup+0x3a>
    if(de.inum == 0)
    80003da8:	fc045783          	lhu	a5,-64(s0)
    80003dac:	dfe1                	beqz	a5,80003d84 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dae:	fc240593          	addi	a1,s0,-62
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	f6c080e7          	jalr	-148(ra) # 80003d20 <namecmp>
    80003dbc:	f561                	bnez	a0,80003d84 <dirlookup+0x4a>
      if(poff)
    80003dbe:	000a0463          	beqz	s4,80003dc6 <dirlookup+0x8c>
        *poff = off;
    80003dc2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc6:	fc045583          	lhu	a1,-64(s0)
    80003dca:	00092503          	lw	a0,0(s2)
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	754080e7          	jalr	1876(ra) # 80003522 <iget>
    80003dd6:	a011                	j	80003dda <dirlookup+0xa0>
  return 0;
    80003dd8:	4501                	li	a0,0
}
    80003dda:	70e2                	ld	ra,56(sp)
    80003ddc:	7442                	ld	s0,48(sp)
    80003dde:	74a2                	ld	s1,40(sp)
    80003de0:	7902                	ld	s2,32(sp)
    80003de2:	69e2                	ld	s3,24(sp)
    80003de4:	6a42                	ld	s4,16(sp)
    80003de6:	6121                	addi	sp,sp,64
    80003de8:	8082                	ret

0000000080003dea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dea:	711d                	addi	sp,sp,-96
    80003dec:	ec86                	sd	ra,88(sp)
    80003dee:	e8a2                	sd	s0,80(sp)
    80003df0:	e4a6                	sd	s1,72(sp)
    80003df2:	e0ca                	sd	s2,64(sp)
    80003df4:	fc4e                	sd	s3,56(sp)
    80003df6:	f852                	sd	s4,48(sp)
    80003df8:	f456                	sd	s5,40(sp)
    80003dfa:	f05a                	sd	s6,32(sp)
    80003dfc:	ec5e                	sd	s7,24(sp)
    80003dfe:	e862                	sd	s8,16(sp)
    80003e00:	e466                	sd	s9,8(sp)
    80003e02:	1080                	addi	s0,sp,96
    80003e04:	84aa                	mv	s1,a0
    80003e06:	8b2e                	mv	s6,a1
    80003e08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e0a:	00054703          	lbu	a4,0(a0)
    80003e0e:	02f00793          	li	a5,47
    80003e12:	02f70363          	beq	a4,a5,80003e38 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e16:	ffffe097          	auipc	ra,0xffffe
    80003e1a:	bb2080e7          	jalr	-1102(ra) # 800019c8 <myproc>
    80003e1e:	15053503          	ld	a0,336(a0)
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	9f6080e7          	jalr	-1546(ra) # 80003818 <idup>
    80003e2a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e2c:	02f00913          	li	s2,47
  len = path - s;
    80003e30:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e32:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e34:	4c05                	li	s8,1
    80003e36:	a865                	j	80003eee <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e38:	4585                	li	a1,1
    80003e3a:	4505                	li	a0,1
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	6e6080e7          	jalr	1766(ra) # 80003522 <iget>
    80003e44:	89aa                	mv	s3,a0
    80003e46:	b7dd                	j	80003e2c <namex+0x42>
      iunlockput(ip);
    80003e48:	854e                	mv	a0,s3
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	c6e080e7          	jalr	-914(ra) # 80003ab8 <iunlockput>
      return 0;
    80003e52:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e54:	854e                	mv	a0,s3
    80003e56:	60e6                	ld	ra,88(sp)
    80003e58:	6446                	ld	s0,80(sp)
    80003e5a:	64a6                	ld	s1,72(sp)
    80003e5c:	6906                	ld	s2,64(sp)
    80003e5e:	79e2                	ld	s3,56(sp)
    80003e60:	7a42                	ld	s4,48(sp)
    80003e62:	7aa2                	ld	s5,40(sp)
    80003e64:	7b02                	ld	s6,32(sp)
    80003e66:	6be2                	ld	s7,24(sp)
    80003e68:	6c42                	ld	s8,16(sp)
    80003e6a:	6ca2                	ld	s9,8(sp)
    80003e6c:	6125                	addi	sp,sp,96
    80003e6e:	8082                	ret
      iunlock(ip);
    80003e70:	854e                	mv	a0,s3
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	aa6080e7          	jalr	-1370(ra) # 80003918 <iunlock>
      return ip;
    80003e7a:	bfe9                	j	80003e54 <namex+0x6a>
      iunlockput(ip);
    80003e7c:	854e                	mv	a0,s3
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	c3a080e7          	jalr	-966(ra) # 80003ab8 <iunlockput>
      return 0;
    80003e86:	89d2                	mv	s3,s4
    80003e88:	b7f1                	j	80003e54 <namex+0x6a>
  len = path - s;
    80003e8a:	40b48633          	sub	a2,s1,a1
    80003e8e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e92:	094cd463          	bge	s9,s4,80003f1a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e96:	4639                	li	a2,14
    80003e98:	8556                	mv	a0,s5
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	ea6080e7          	jalr	-346(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	01279763          	bne	a5,s2,80003eb4 <namex+0xca>
    path++;
    80003eaa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eac:	0004c783          	lbu	a5,0(s1)
    80003eb0:	ff278de3          	beq	a5,s2,80003eaa <namex+0xc0>
    ilock(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	9a0080e7          	jalr	-1632(ra) # 80003856 <ilock>
    if(ip->type != T_DIR){
    80003ebe:	04499783          	lh	a5,68(s3)
    80003ec2:	f98793e3          	bne	a5,s8,80003e48 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ec6:	000b0563          	beqz	s6,80003ed0 <namex+0xe6>
    80003eca:	0004c783          	lbu	a5,0(s1)
    80003ece:	d3cd                	beqz	a5,80003e70 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ed0:	865e                	mv	a2,s7
    80003ed2:	85d6                	mv	a1,s5
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	e64080e7          	jalr	-412(ra) # 80003d3a <dirlookup>
    80003ede:	8a2a                	mv	s4,a0
    80003ee0:	dd51                	beqz	a0,80003e7c <namex+0x92>
    iunlockput(ip);
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	bd4080e7          	jalr	-1068(ra) # 80003ab8 <iunlockput>
    ip = next;
    80003eec:	89d2                	mv	s3,s4
  while(*path == '/')
    80003eee:	0004c783          	lbu	a5,0(s1)
    80003ef2:	05279763          	bne	a5,s2,80003f40 <namex+0x156>
    path++;
    80003ef6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef8:	0004c783          	lbu	a5,0(s1)
    80003efc:	ff278de3          	beq	a5,s2,80003ef6 <namex+0x10c>
  if(*path == 0)
    80003f00:	c79d                	beqz	a5,80003f2e <namex+0x144>
    path++;
    80003f02:	85a6                	mv	a1,s1
  len = path - s;
    80003f04:	8a5e                	mv	s4,s7
    80003f06:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f08:	01278963          	beq	a5,s2,80003f1a <namex+0x130>
    80003f0c:	dfbd                	beqz	a5,80003e8a <namex+0xa0>
    path++;
    80003f0e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f10:	0004c783          	lbu	a5,0(s1)
    80003f14:	ff279ce3          	bne	a5,s2,80003f0c <namex+0x122>
    80003f18:	bf8d                	j	80003e8a <namex+0xa0>
    memmove(name, s, len);
    80003f1a:	2601                	sext.w	a2,a2
    80003f1c:	8556                	mv	a0,s5
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	e22080e7          	jalr	-478(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f26:	9a56                	add	s4,s4,s5
    80003f28:	000a0023          	sb	zero,0(s4)
    80003f2c:	bf9d                	j	80003ea2 <namex+0xb8>
  if(nameiparent){
    80003f2e:	f20b03e3          	beqz	s6,80003e54 <namex+0x6a>
    iput(ip);
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	adc080e7          	jalr	-1316(ra) # 80003a10 <iput>
    return 0;
    80003f3c:	4981                	li	s3,0
    80003f3e:	bf19                	j	80003e54 <namex+0x6a>
  if(*path == 0)
    80003f40:	d7fd                	beqz	a5,80003f2e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	85a6                	mv	a1,s1
    80003f48:	b7d1                	j	80003f0c <namex+0x122>

0000000080003f4a <dirlink>:
{
    80003f4a:	7139                	addi	sp,sp,-64
    80003f4c:	fc06                	sd	ra,56(sp)
    80003f4e:	f822                	sd	s0,48(sp)
    80003f50:	f426                	sd	s1,40(sp)
    80003f52:	f04a                	sd	s2,32(sp)
    80003f54:	ec4e                	sd	s3,24(sp)
    80003f56:	e852                	sd	s4,16(sp)
    80003f58:	0080                	addi	s0,sp,64
    80003f5a:	892a                	mv	s2,a0
    80003f5c:	8a2e                	mv	s4,a1
    80003f5e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f60:	4601                	li	a2,0
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	dd8080e7          	jalr	-552(ra) # 80003d3a <dirlookup>
    80003f6a:	e93d                	bnez	a0,80003fe0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6c:	04c92483          	lw	s1,76(s2)
    80003f70:	c49d                	beqz	s1,80003f9e <dirlink+0x54>
    80003f72:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f74:	4741                	li	a4,16
    80003f76:	86a6                	mv	a3,s1
    80003f78:	fc040613          	addi	a2,s0,-64
    80003f7c:	4581                	li	a1,0
    80003f7e:	854a                	mv	a0,s2
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	b8a080e7          	jalr	-1142(ra) # 80003b0a <readi>
    80003f88:	47c1                	li	a5,16
    80003f8a:	06f51163          	bne	a0,a5,80003fec <dirlink+0xa2>
    if(de.inum == 0)
    80003f8e:	fc045783          	lhu	a5,-64(s0)
    80003f92:	c791                	beqz	a5,80003f9e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f94:	24c1                	addiw	s1,s1,16
    80003f96:	04c92783          	lw	a5,76(s2)
    80003f9a:	fcf4ede3          	bltu	s1,a5,80003f74 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f9e:	4639                	li	a2,14
    80003fa0:	85d2                	mv	a1,s4
    80003fa2:	fc240513          	addi	a0,s0,-62
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	e4e080e7          	jalr	-434(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fae:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb2:	4741                	li	a4,16
    80003fb4:	86a6                	mv	a3,s1
    80003fb6:	fc040613          	addi	a2,s0,-64
    80003fba:	4581                	li	a1,0
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	c44080e7          	jalr	-956(ra) # 80003c02 <writei>
    80003fc6:	872a                	mv	a4,a0
    80003fc8:	47c1                	li	a5,16
  return 0;
    80003fca:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fcc:	02f71863          	bne	a4,a5,80003ffc <dirlink+0xb2>
}
    80003fd0:	70e2                	ld	ra,56(sp)
    80003fd2:	7442                	ld	s0,48(sp)
    80003fd4:	74a2                	ld	s1,40(sp)
    80003fd6:	7902                	ld	s2,32(sp)
    80003fd8:	69e2                	ld	s3,24(sp)
    80003fda:	6a42                	ld	s4,16(sp)
    80003fdc:	6121                	addi	sp,sp,64
    80003fde:	8082                	ret
    iput(ip);
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	a30080e7          	jalr	-1488(ra) # 80003a10 <iput>
    return -1;
    80003fe8:	557d                	li	a0,-1
    80003fea:	b7dd                	j	80003fd0 <dirlink+0x86>
      panic("dirlink read");
    80003fec:	00004517          	auipc	a0,0x4
    80003ff0:	63c50513          	addi	a0,a0,1596 # 80008628 <syscalls+0x1d0>
    80003ff4:	ffffc097          	auipc	ra,0xffffc
    80003ff8:	54a080e7          	jalr	1354(ra) # 8000053e <panic>
    panic("dirlink");
    80003ffc:	00004517          	auipc	a0,0x4
    80004000:	73c50513          	addi	a0,a0,1852 # 80008738 <syscalls+0x2e0>
    80004004:	ffffc097          	auipc	ra,0xffffc
    80004008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>

000000008000400c <namei>:

struct inode*
namei(char *path)
{
    8000400c:	1101                	addi	sp,sp,-32
    8000400e:	ec06                	sd	ra,24(sp)
    80004010:	e822                	sd	s0,16(sp)
    80004012:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004014:	fe040613          	addi	a2,s0,-32
    80004018:	4581                	li	a1,0
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	dd0080e7          	jalr	-560(ra) # 80003dea <namex>
}
    80004022:	60e2                	ld	ra,24(sp)
    80004024:	6442                	ld	s0,16(sp)
    80004026:	6105                	addi	sp,sp,32
    80004028:	8082                	ret

000000008000402a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000402a:	1141                	addi	sp,sp,-16
    8000402c:	e406                	sd	ra,8(sp)
    8000402e:	e022                	sd	s0,0(sp)
    80004030:	0800                	addi	s0,sp,16
    80004032:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004034:	4585                	li	a1,1
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	db4080e7          	jalr	-588(ra) # 80003dea <namex>
}
    8000403e:	60a2                	ld	ra,8(sp)
    80004040:	6402                	ld	s0,0(sp)
    80004042:	0141                	addi	sp,sp,16
    80004044:	8082                	ret

0000000080004046 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	e426                	sd	s1,8(sp)
    8000404e:	e04a                	sd	s2,0(sp)
    80004050:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004052:	0001d917          	auipc	s2,0x1d
    80004056:	43690913          	addi	s2,s2,1078 # 80021488 <log>
    8000405a:	01892583          	lw	a1,24(s2)
    8000405e:	02892503          	lw	a0,40(s2)
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	ff2080e7          	jalr	-14(ra) # 80003054 <bread>
    8000406a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000406c:	02c92683          	lw	a3,44(s2)
    80004070:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004072:	02d05763          	blez	a3,800040a0 <write_head+0x5a>
    80004076:	0001d797          	auipc	a5,0x1d
    8000407a:	44278793          	addi	a5,a5,1090 # 800214b8 <log+0x30>
    8000407e:	05c50713          	addi	a4,a0,92
    80004082:	36fd                	addiw	a3,a3,-1
    80004084:	1682                	slli	a3,a3,0x20
    80004086:	9281                	srli	a3,a3,0x20
    80004088:	068a                	slli	a3,a3,0x2
    8000408a:	0001d617          	auipc	a2,0x1d
    8000408e:	43260613          	addi	a2,a2,1074 # 800214bc <log+0x34>
    80004092:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004094:	4390                	lw	a2,0(a5)
    80004096:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004098:	0791                	addi	a5,a5,4
    8000409a:	0711                	addi	a4,a4,4
    8000409c:	fed79ce3          	bne	a5,a3,80004094 <write_head+0x4e>
  }
  bwrite(buf);
    800040a0:	8526                	mv	a0,s1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	0a4080e7          	jalr	164(ra) # 80003146 <bwrite>
  brelse(buf);
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	0d8080e7          	jalr	216(ra) # 80003184 <brelse>
}
    800040b4:	60e2                	ld	ra,24(sp)
    800040b6:	6442                	ld	s0,16(sp)
    800040b8:	64a2                	ld	s1,8(sp)
    800040ba:	6902                	ld	s2,0(sp)
    800040bc:	6105                	addi	sp,sp,32
    800040be:	8082                	ret

00000000800040c0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c0:	0001d797          	auipc	a5,0x1d
    800040c4:	3f47a783          	lw	a5,1012(a5) # 800214b4 <log+0x2c>
    800040c8:	0af05d63          	blez	a5,80004182 <install_trans+0xc2>
{
    800040cc:	7139                	addi	sp,sp,-64
    800040ce:	fc06                	sd	ra,56(sp)
    800040d0:	f822                	sd	s0,48(sp)
    800040d2:	f426                	sd	s1,40(sp)
    800040d4:	f04a                	sd	s2,32(sp)
    800040d6:	ec4e                	sd	s3,24(sp)
    800040d8:	e852                	sd	s4,16(sp)
    800040da:	e456                	sd	s5,8(sp)
    800040dc:	e05a                	sd	s6,0(sp)
    800040de:	0080                	addi	s0,sp,64
    800040e0:	8b2a                	mv	s6,a0
    800040e2:	0001da97          	auipc	s5,0x1d
    800040e6:	3d6a8a93          	addi	s5,s5,982 # 800214b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ea:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ec:	0001d997          	auipc	s3,0x1d
    800040f0:	39c98993          	addi	s3,s3,924 # 80021488 <log>
    800040f4:	a035                	j	80004120 <install_trans+0x60>
      bunpin(dbuf);
    800040f6:	8526                	mv	a0,s1
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	166080e7          	jalr	358(ra) # 8000325e <bunpin>
    brelse(lbuf);
    80004100:	854a                	mv	a0,s2
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	082080e7          	jalr	130(ra) # 80003184 <brelse>
    brelse(dbuf);
    8000410a:	8526                	mv	a0,s1
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	078080e7          	jalr	120(ra) # 80003184 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004114:	2a05                	addiw	s4,s4,1
    80004116:	0a91                	addi	s5,s5,4
    80004118:	02c9a783          	lw	a5,44(s3)
    8000411c:	04fa5963          	bge	s4,a5,8000416e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004120:	0189a583          	lw	a1,24(s3)
    80004124:	014585bb          	addw	a1,a1,s4
    80004128:	2585                	addiw	a1,a1,1
    8000412a:	0289a503          	lw	a0,40(s3)
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	f26080e7          	jalr	-218(ra) # 80003054 <bread>
    80004136:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004138:	000aa583          	lw	a1,0(s5)
    8000413c:	0289a503          	lw	a0,40(s3)
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	f14080e7          	jalr	-236(ra) # 80003054 <bread>
    80004148:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000414a:	40000613          	li	a2,1024
    8000414e:	05890593          	addi	a1,s2,88
    80004152:	05850513          	addi	a0,a0,88
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	bea080e7          	jalr	-1046(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000415e:	8526                	mv	a0,s1
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	fe6080e7          	jalr	-26(ra) # 80003146 <bwrite>
    if(recovering == 0)
    80004168:	f80b1ce3          	bnez	s6,80004100 <install_trans+0x40>
    8000416c:	b769                	j	800040f6 <install_trans+0x36>
}
    8000416e:	70e2                	ld	ra,56(sp)
    80004170:	7442                	ld	s0,48(sp)
    80004172:	74a2                	ld	s1,40(sp)
    80004174:	7902                	ld	s2,32(sp)
    80004176:	69e2                	ld	s3,24(sp)
    80004178:	6a42                	ld	s4,16(sp)
    8000417a:	6aa2                	ld	s5,8(sp)
    8000417c:	6b02                	ld	s6,0(sp)
    8000417e:	6121                	addi	sp,sp,64
    80004180:	8082                	ret
    80004182:	8082                	ret

0000000080004184 <initlog>:
{
    80004184:	7179                	addi	sp,sp,-48
    80004186:	f406                	sd	ra,40(sp)
    80004188:	f022                	sd	s0,32(sp)
    8000418a:	ec26                	sd	s1,24(sp)
    8000418c:	e84a                	sd	s2,16(sp)
    8000418e:	e44e                	sd	s3,8(sp)
    80004190:	1800                	addi	s0,sp,48
    80004192:	892a                	mv	s2,a0
    80004194:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004196:	0001d497          	auipc	s1,0x1d
    8000419a:	2f248493          	addi	s1,s1,754 # 80021488 <log>
    8000419e:	00004597          	auipc	a1,0x4
    800041a2:	49a58593          	addi	a1,a1,1178 # 80008638 <syscalls+0x1e0>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	9ac080e7          	jalr	-1620(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041b0:	0149a583          	lw	a1,20(s3)
    800041b4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041b6:	0109a783          	lw	a5,16(s3)
    800041ba:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041bc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041c0:	854a                	mv	a0,s2
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	e92080e7          	jalr	-366(ra) # 80003054 <bread>
  log.lh.n = lh->n;
    800041ca:	4d3c                	lw	a5,88(a0)
    800041cc:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041ce:	02f05563          	blez	a5,800041f8 <initlog+0x74>
    800041d2:	05c50713          	addi	a4,a0,92
    800041d6:	0001d697          	auipc	a3,0x1d
    800041da:	2e268693          	addi	a3,a3,738 # 800214b8 <log+0x30>
    800041de:	37fd                	addiw	a5,a5,-1
    800041e0:	1782                	slli	a5,a5,0x20
    800041e2:	9381                	srli	a5,a5,0x20
    800041e4:	078a                	slli	a5,a5,0x2
    800041e6:	06050613          	addi	a2,a0,96
    800041ea:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041ec:	4310                	lw	a2,0(a4)
    800041ee:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	0711                	addi	a4,a4,4
    800041f2:	0691                	addi	a3,a3,4
    800041f4:	fef71ce3          	bne	a4,a5,800041ec <initlog+0x68>
  brelse(buf);
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	f8c080e7          	jalr	-116(ra) # 80003184 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004200:	4505                	li	a0,1
    80004202:	00000097          	auipc	ra,0x0
    80004206:	ebe080e7          	jalr	-322(ra) # 800040c0 <install_trans>
  log.lh.n = 0;
    8000420a:	0001d797          	auipc	a5,0x1d
    8000420e:	2a07a523          	sw	zero,682(a5) # 800214b4 <log+0x2c>
  write_head(); // clear the log
    80004212:	00000097          	auipc	ra,0x0
    80004216:	e34080e7          	jalr	-460(ra) # 80004046 <write_head>
}
    8000421a:	70a2                	ld	ra,40(sp)
    8000421c:	7402                	ld	s0,32(sp)
    8000421e:	64e2                	ld	s1,24(sp)
    80004220:	6942                	ld	s2,16(sp)
    80004222:	69a2                	ld	s3,8(sp)
    80004224:	6145                	addi	sp,sp,48
    80004226:	8082                	ret

0000000080004228 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004228:	1101                	addi	sp,sp,-32
    8000422a:	ec06                	sd	ra,24(sp)
    8000422c:	e822                	sd	s0,16(sp)
    8000422e:	e426                	sd	s1,8(sp)
    80004230:	e04a                	sd	s2,0(sp)
    80004232:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004234:	0001d517          	auipc	a0,0x1d
    80004238:	25450513          	addi	a0,a0,596 # 80021488 <log>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	24448493          	addi	s1,s1,580 # 80021488 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424c:	4979                	li	s2,30
    8000424e:	a039                	j	8000425c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004250:	85a6                	mv	a1,s1
    80004252:	8526                	mv	a0,s1
    80004254:	ffffe097          	auipc	ra,0xffffe
    80004258:	04e080e7          	jalr	78(ra) # 800022a2 <sleep>
    if(log.committing){
    8000425c:	50dc                	lw	a5,36(s1)
    8000425e:	fbed                	bnez	a5,80004250 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004260:	509c                	lw	a5,32(s1)
    80004262:	0017871b          	addiw	a4,a5,1
    80004266:	0007069b          	sext.w	a3,a4
    8000426a:	0027179b          	slliw	a5,a4,0x2
    8000426e:	9fb9                	addw	a5,a5,a4
    80004270:	0017979b          	slliw	a5,a5,0x1
    80004274:	54d8                	lw	a4,44(s1)
    80004276:	9fb9                	addw	a5,a5,a4
    80004278:	00f95963          	bge	s2,a5,8000428a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000427c:	85a6                	mv	a1,s1
    8000427e:	8526                	mv	a0,s1
    80004280:	ffffe097          	auipc	ra,0xffffe
    80004284:	022080e7          	jalr	34(ra) # 800022a2 <sleep>
    80004288:	bfd1                	j	8000425c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000428a:	0001d517          	auipc	a0,0x1d
    8000428e:	1fe50513          	addi	a0,a0,510 # 80021488 <log>
    80004292:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	a04080e7          	jalr	-1532(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000429c:	60e2                	ld	ra,24(sp)
    8000429e:	6442                	ld	s0,16(sp)
    800042a0:	64a2                	ld	s1,8(sp)
    800042a2:	6902                	ld	s2,0(sp)
    800042a4:	6105                	addi	sp,sp,32
    800042a6:	8082                	ret

00000000800042a8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042a8:	7139                	addi	sp,sp,-64
    800042aa:	fc06                	sd	ra,56(sp)
    800042ac:	f822                	sd	s0,48(sp)
    800042ae:	f426                	sd	s1,40(sp)
    800042b0:	f04a                	sd	s2,32(sp)
    800042b2:	ec4e                	sd	s3,24(sp)
    800042b4:	e852                	sd	s4,16(sp)
    800042b6:	e456                	sd	s5,8(sp)
    800042b8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ba:	0001d497          	auipc	s1,0x1d
    800042be:	1ce48493          	addi	s1,s1,462 # 80021488 <log>
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042cc:	509c                	lw	a5,32(s1)
    800042ce:	37fd                	addiw	a5,a5,-1
    800042d0:	0007891b          	sext.w	s2,a5
    800042d4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042d6:	50dc                	lw	a5,36(s1)
    800042d8:	efb9                	bnez	a5,80004336 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042da:	06091663          	bnez	s2,80004346 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042de:	0001d497          	auipc	s1,0x1d
    800042e2:	1aa48493          	addi	s1,s1,426 # 80021488 <log>
    800042e6:	4785                	li	a5,1
    800042e8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	9ac080e7          	jalr	-1620(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042f4:	54dc                	lw	a5,44(s1)
    800042f6:	06f04763          	bgtz	a5,80004364 <end_op+0xbc>
    acquire(&log.lock);
    800042fa:	0001d497          	auipc	s1,0x1d
    800042fe:	18e48493          	addi	s1,s1,398 # 80021488 <log>
    80004302:	8526                	mv	a0,s1
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	8e0080e7          	jalr	-1824(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000430c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004310:	8526                	mv	a0,s1
    80004312:	ffffe097          	auipc	ra,0xffffe
    80004316:	11c080e7          	jalr	284(ra) # 8000242e <wakeup>
    release(&log.lock);
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
}
    80004324:	70e2                	ld	ra,56(sp)
    80004326:	7442                	ld	s0,48(sp)
    80004328:	74a2                	ld	s1,40(sp)
    8000432a:	7902                	ld	s2,32(sp)
    8000432c:	69e2                	ld	s3,24(sp)
    8000432e:	6a42                	ld	s4,16(sp)
    80004330:	6aa2                	ld	s5,8(sp)
    80004332:	6121                	addi	sp,sp,64
    80004334:	8082                	ret
    panic("log.committing");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	30a50513          	addi	a0,a0,778 # 80008640 <syscalls+0x1e8>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    wakeup(&log);
    80004346:	0001d497          	auipc	s1,0x1d
    8000434a:	14248493          	addi	s1,s1,322 # 80021488 <log>
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	0de080e7          	jalr	222(ra) # 8000242e <wakeup>
  release(&log.lock);
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	93e080e7          	jalr	-1730(ra) # 80000c98 <release>
  if(do_commit){
    80004362:	b7c9                	j	80004324 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004364:	0001da97          	auipc	s5,0x1d
    80004368:	154a8a93          	addi	s5,s5,340 # 800214b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000436c:	0001da17          	auipc	s4,0x1d
    80004370:	11ca0a13          	addi	s4,s4,284 # 80021488 <log>
    80004374:	018a2583          	lw	a1,24(s4)
    80004378:	012585bb          	addw	a1,a1,s2
    8000437c:	2585                	addiw	a1,a1,1
    8000437e:	028a2503          	lw	a0,40(s4)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	cd2080e7          	jalr	-814(ra) # 80003054 <bread>
    8000438a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000438c:	000aa583          	lw	a1,0(s5)
    80004390:	028a2503          	lw	a0,40(s4)
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	cc0080e7          	jalr	-832(ra) # 80003054 <bread>
    8000439c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000439e:	40000613          	li	a2,1024
    800043a2:	05850593          	addi	a1,a0,88
    800043a6:	05848513          	addi	a0,s1,88
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	996080e7          	jalr	-1642(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	d92080e7          	jalr	-622(ra) # 80003146 <bwrite>
    brelse(from);
    800043bc:	854e                	mv	a0,s3
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	dc6080e7          	jalr	-570(ra) # 80003184 <brelse>
    brelse(to);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	dbc080e7          	jalr	-580(ra) # 80003184 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	2905                	addiw	s2,s2,1
    800043d2:	0a91                	addi	s5,s5,4
    800043d4:	02ca2783          	lw	a5,44(s4)
    800043d8:	f8f94ee3          	blt	s2,a5,80004374 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	c6a080e7          	jalr	-918(ra) # 80004046 <write_head>
    install_trans(0); // Now install writes to home locations
    800043e4:	4501                	li	a0,0
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	cda080e7          	jalr	-806(ra) # 800040c0 <install_trans>
    log.lh.n = 0;
    800043ee:	0001d797          	auipc	a5,0x1d
    800043f2:	0c07a323          	sw	zero,198(a5) # 800214b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	c50080e7          	jalr	-944(ra) # 80004046 <write_head>
    800043fe:	bdf5                	j	800042fa <end_op+0x52>

0000000080004400 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004400:	1101                	addi	sp,sp,-32
    80004402:	ec06                	sd	ra,24(sp)
    80004404:	e822                	sd	s0,16(sp)
    80004406:	e426                	sd	s1,8(sp)
    80004408:	e04a                	sd	s2,0(sp)
    8000440a:	1000                	addi	s0,sp,32
    8000440c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000440e:	0001d917          	auipc	s2,0x1d
    80004412:	07a90913          	addi	s2,s2,122 # 80021488 <log>
    80004416:	854a                	mv	a0,s2
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7cc080e7          	jalr	1996(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004420:	02c92603          	lw	a2,44(s2)
    80004424:	47f5                	li	a5,29
    80004426:	06c7c563          	blt	a5,a2,80004490 <log_write+0x90>
    8000442a:	0001d797          	auipc	a5,0x1d
    8000442e:	07a7a783          	lw	a5,122(a5) # 800214a4 <log+0x1c>
    80004432:	37fd                	addiw	a5,a5,-1
    80004434:	04f65e63          	bge	a2,a5,80004490 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004438:	0001d797          	auipc	a5,0x1d
    8000443c:	0707a783          	lw	a5,112(a5) # 800214a8 <log+0x20>
    80004440:	06f05063          	blez	a5,800044a0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004444:	4781                	li	a5,0
    80004446:	06c05563          	blez	a2,800044b0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000444a:	44cc                	lw	a1,12(s1)
    8000444c:	0001d717          	auipc	a4,0x1d
    80004450:	06c70713          	addi	a4,a4,108 # 800214b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004454:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004456:	4314                	lw	a3,0(a4)
    80004458:	04b68c63          	beq	a3,a1,800044b0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000445c:	2785                	addiw	a5,a5,1
    8000445e:	0711                	addi	a4,a4,4
    80004460:	fef61be3          	bne	a2,a5,80004456 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004464:	0621                	addi	a2,a2,8
    80004466:	060a                	slli	a2,a2,0x2
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	02078793          	addi	a5,a5,32 # 80021488 <log>
    80004470:	963e                	add	a2,a2,a5
    80004472:	44dc                	lw	a5,12(s1)
    80004474:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004476:	8526                	mv	a0,s1
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	daa080e7          	jalr	-598(ra) # 80003222 <bpin>
    log.lh.n++;
    80004480:	0001d717          	auipc	a4,0x1d
    80004484:	00870713          	addi	a4,a4,8 # 80021488 <log>
    80004488:	575c                	lw	a5,44(a4)
    8000448a:	2785                	addiw	a5,a5,1
    8000448c:	d75c                	sw	a5,44(a4)
    8000448e:	a835                	j	800044ca <log_write+0xca>
    panic("too big a transaction");
    80004490:	00004517          	auipc	a0,0x4
    80004494:	1c050513          	addi	a0,a0,448 # 80008650 <syscalls+0x1f8>
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	0a6080e7          	jalr	166(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044a0:	00004517          	auipc	a0,0x4
    800044a4:	1c850513          	addi	a0,a0,456 # 80008668 <syscalls+0x210>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	096080e7          	jalr	150(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044b0:	00878713          	addi	a4,a5,8
    800044b4:	00271693          	slli	a3,a4,0x2
    800044b8:	0001d717          	auipc	a4,0x1d
    800044bc:	fd070713          	addi	a4,a4,-48 # 80021488 <log>
    800044c0:	9736                	add	a4,a4,a3
    800044c2:	44d4                	lw	a3,12(s1)
    800044c4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044c6:	faf608e3          	beq	a2,a5,80004476 <log_write+0x76>
  }
  release(&log.lock);
    800044ca:	0001d517          	auipc	a0,0x1d
    800044ce:	fbe50513          	addi	a0,a0,-66 # 80021488 <log>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
}
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	64a2                	ld	s1,8(sp)
    800044e0:	6902                	ld	s2,0(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
    800044f2:	84aa                	mv	s1,a0
    800044f4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044f6:	00004597          	auipc	a1,0x4
    800044fa:	19258593          	addi	a1,a1,402 # 80008688 <syscalls+0x230>
    800044fe:	0521                	addi	a0,a0,8
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	654080e7          	jalr	1620(ra) # 80000b54 <initlock>
  lk->name = name;
    80004508:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000450c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004510:	0204a423          	sw	zero,40(s1)
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	e04a                	sd	s2,0(sp)
    8000452a:	1000                	addi	s0,sp,32
    8000452c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000452e:	00850913          	addi	s2,a0,8
    80004532:	854a                	mv	a0,s2
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	6b0080e7          	jalr	1712(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000453c:	409c                	lw	a5,0(s1)
    8000453e:	cb89                	beqz	a5,80004550 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004540:	85ca                	mv	a1,s2
    80004542:	8526                	mv	a0,s1
    80004544:	ffffe097          	auipc	ra,0xffffe
    80004548:	d5e080e7          	jalr	-674(ra) # 800022a2 <sleep>
  while (lk->locked) {
    8000454c:	409c                	lw	a5,0(s1)
    8000454e:	fbed                	bnez	a5,80004540 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004550:	4785                	li	a5,1
    80004552:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004554:	ffffd097          	auipc	ra,0xffffd
    80004558:	474080e7          	jalr	1140(ra) # 800019c8 <myproc>
    8000455c:	591c                	lw	a5,48(a0)
    8000455e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004560:	854a                	mv	a0,s2
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6902                	ld	s2,0(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	e04a                	sd	s2,0(sp)
    80004580:	1000                	addi	s0,sp,32
    80004582:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004584:	00850913          	addi	s2,a0,8
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	65a080e7          	jalr	1626(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004592:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004596:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000459a:	8526                	mv	a0,s1
    8000459c:	ffffe097          	auipc	ra,0xffffe
    800045a0:	e92080e7          	jalr	-366(ra) # 8000242e <wakeup>
  release(&lk->lk);
    800045a4:	854a                	mv	a0,s2
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	6f2080e7          	jalr	1778(ra) # 80000c98 <release>
}
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6902                	ld	s2,0(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ba:	7179                	addi	sp,sp,-48
    800045bc:	f406                	sd	ra,40(sp)
    800045be:	f022                	sd	s0,32(sp)
    800045c0:	ec26                	sd	s1,24(sp)
    800045c2:	e84a                	sd	s2,16(sp)
    800045c4:	e44e                	sd	s3,8(sp)
    800045c6:	1800                	addi	s0,sp,48
    800045c8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045ca:	00850913          	addi	s2,a0,8
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d8:	409c                	lw	a5,0(s1)
    800045da:	ef99                	bnez	a5,800045f8 <holdingsleep+0x3e>
    800045dc:	4481                	li	s1,0
  release(&lk->lk);
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
  return r;
}
    800045e8:	8526                	mv	a0,s1
    800045ea:	70a2                	ld	ra,40(sp)
    800045ec:	7402                	ld	s0,32(sp)
    800045ee:	64e2                	ld	s1,24(sp)
    800045f0:	6942                	ld	s2,16(sp)
    800045f2:	69a2                	ld	s3,8(sp)
    800045f4:	6145                	addi	sp,sp,48
    800045f6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045f8:	0284a983          	lw	s3,40(s1)
    800045fc:	ffffd097          	auipc	ra,0xffffd
    80004600:	3cc080e7          	jalr	972(ra) # 800019c8 <myproc>
    80004604:	5904                	lw	s1,48(a0)
    80004606:	413484b3          	sub	s1,s1,s3
    8000460a:	0014b493          	seqz	s1,s1
    8000460e:	bfc1                	j	800045de <holdingsleep+0x24>

0000000080004610 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004610:	1141                	addi	sp,sp,-16
    80004612:	e406                	sd	ra,8(sp)
    80004614:	e022                	sd	s0,0(sp)
    80004616:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004618:	00004597          	auipc	a1,0x4
    8000461c:	08058593          	addi	a1,a1,128 # 80008698 <syscalls+0x240>
    80004620:	0001d517          	auipc	a0,0x1d
    80004624:	fb050513          	addi	a0,a0,-80 # 800215d0 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	52c080e7          	jalr	1324(ra) # 80000b54 <initlock>
}
    80004630:	60a2                	ld	ra,8(sp)
    80004632:	6402                	ld	s0,0(sp)
    80004634:	0141                	addi	sp,sp,16
    80004636:	8082                	ret

0000000080004638 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	e426                	sd	s1,8(sp)
    80004640:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	f8e50513          	addi	a0,a0,-114 # 800215d0 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	59a080e7          	jalr	1434(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004652:	0001d497          	auipc	s1,0x1d
    80004656:	f9648493          	addi	s1,s1,-106 # 800215e8 <ftable+0x18>
    8000465a:	0001e717          	auipc	a4,0x1e
    8000465e:	f2e70713          	addi	a4,a4,-210 # 80022588 <ftable+0xfb8>
    if(f->ref == 0){
    80004662:	40dc                	lw	a5,4(s1)
    80004664:	cf99                	beqz	a5,80004682 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004666:	02848493          	addi	s1,s1,40
    8000466a:	fee49ce3          	bne	s1,a4,80004662 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	f6250513          	addi	a0,a0,-158 # 800215d0 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
  return 0;
    8000467e:	4481                	li	s1,0
    80004680:	a819                	j	80004696 <filealloc+0x5e>
      f->ref = 1;
    80004682:	4785                	li	a5,1
    80004684:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004686:	0001d517          	auipc	a0,0x1d
    8000468a:	f4a50513          	addi	a0,a0,-182 # 800215d0 <ftable>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
}
    80004696:	8526                	mv	a0,s1
    80004698:	60e2                	ld	ra,24(sp)
    8000469a:	6442                	ld	s0,16(sp)
    8000469c:	64a2                	ld	s1,8(sp)
    8000469e:	6105                	addi	sp,sp,32
    800046a0:	8082                	ret

00000000800046a2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046a2:	1101                	addi	sp,sp,-32
    800046a4:	ec06                	sd	ra,24(sp)
    800046a6:	e822                	sd	s0,16(sp)
    800046a8:	e426                	sd	s1,8(sp)
    800046aa:	1000                	addi	s0,sp,32
    800046ac:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046ae:	0001d517          	auipc	a0,0x1d
    800046b2:	f2250513          	addi	a0,a0,-222 # 800215d0 <ftable>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	52e080e7          	jalr	1326(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046be:	40dc                	lw	a5,4(s1)
    800046c0:	02f05263          	blez	a5,800046e4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046c4:	2785                	addiw	a5,a5,1
    800046c6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046c8:	0001d517          	auipc	a0,0x1d
    800046cc:	f0850513          	addi	a0,a0,-248 # 800215d0 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5c8080e7          	jalr	1480(ra) # 80000c98 <release>
  return f;
}
    800046d8:	8526                	mv	a0,s1
    800046da:	60e2                	ld	ra,24(sp)
    800046dc:	6442                	ld	s0,16(sp)
    800046de:	64a2                	ld	s1,8(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret
    panic("filedup");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	fbc50513          	addi	a0,a0,-68 # 800086a0 <syscalls+0x248>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>

00000000800046f4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046f4:	7139                	addi	sp,sp,-64
    800046f6:	fc06                	sd	ra,56(sp)
    800046f8:	f822                	sd	s0,48(sp)
    800046fa:	f426                	sd	s1,40(sp)
    800046fc:	f04a                	sd	s2,32(sp)
    800046fe:	ec4e                	sd	s3,24(sp)
    80004700:	e852                	sd	s4,16(sp)
    80004702:	e456                	sd	s5,8(sp)
    80004704:	0080                	addi	s0,sp,64
    80004706:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004708:	0001d517          	auipc	a0,0x1d
    8000470c:	ec850513          	addi	a0,a0,-312 # 800215d0 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004718:	40dc                	lw	a5,4(s1)
    8000471a:	06f05163          	blez	a5,8000477c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000471e:	37fd                	addiw	a5,a5,-1
    80004720:	0007871b          	sext.w	a4,a5
    80004724:	c0dc                	sw	a5,4(s1)
    80004726:	06e04363          	bgtz	a4,8000478c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000472a:	0004a903          	lw	s2,0(s1)
    8000472e:	0094ca83          	lbu	s5,9(s1)
    80004732:	0104ba03          	ld	s4,16(s1)
    80004736:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000473a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000473e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	e8e50513          	addi	a0,a0,-370 # 800215d0 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	54e080e7          	jalr	1358(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004752:	4785                	li	a5,1
    80004754:	04f90d63          	beq	s2,a5,800047ae <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004758:	3979                	addiw	s2,s2,-2
    8000475a:	4785                	li	a5,1
    8000475c:	0527e063          	bltu	a5,s2,8000479c <fileclose+0xa8>
    begin_op();
    80004760:	00000097          	auipc	ra,0x0
    80004764:	ac8080e7          	jalr	-1336(ra) # 80004228 <begin_op>
    iput(ff.ip);
    80004768:	854e                	mv	a0,s3
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	2a6080e7          	jalr	678(ra) # 80003a10 <iput>
    end_op();
    80004772:	00000097          	auipc	ra,0x0
    80004776:	b36080e7          	jalr	-1226(ra) # 800042a8 <end_op>
    8000477a:	a00d                	j	8000479c <fileclose+0xa8>
    panic("fileclose");
    8000477c:	00004517          	auipc	a0,0x4
    80004780:	f2c50513          	addi	a0,a0,-212 # 800086a8 <syscalls+0x250>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	dba080e7          	jalr	-582(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000478c:	0001d517          	auipc	a0,0x1d
    80004790:	e4450513          	addi	a0,a0,-444 # 800215d0 <ftable>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
  }
}
    8000479c:	70e2                	ld	ra,56(sp)
    8000479e:	7442                	ld	s0,48(sp)
    800047a0:	74a2                	ld	s1,40(sp)
    800047a2:	7902                	ld	s2,32(sp)
    800047a4:	69e2                	ld	s3,24(sp)
    800047a6:	6a42                	ld	s4,16(sp)
    800047a8:	6aa2                	ld	s5,8(sp)
    800047aa:	6121                	addi	sp,sp,64
    800047ac:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047ae:	85d6                	mv	a1,s5
    800047b0:	8552                	mv	a0,s4
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	34c080e7          	jalr	844(ra) # 80004afe <pipeclose>
    800047ba:	b7cd                	j	8000479c <fileclose+0xa8>

00000000800047bc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047bc:	715d                	addi	sp,sp,-80
    800047be:	e486                	sd	ra,72(sp)
    800047c0:	e0a2                	sd	s0,64(sp)
    800047c2:	fc26                	sd	s1,56(sp)
    800047c4:	f84a                	sd	s2,48(sp)
    800047c6:	f44e                	sd	s3,40(sp)
    800047c8:	0880                	addi	s0,sp,80
    800047ca:	84aa                	mv	s1,a0
    800047cc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ce:	ffffd097          	auipc	ra,0xffffd
    800047d2:	1fa080e7          	jalr	506(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047d6:	409c                	lw	a5,0(s1)
    800047d8:	37f9                	addiw	a5,a5,-2
    800047da:	4705                	li	a4,1
    800047dc:	04f76763          	bltu	a4,a5,8000482a <filestat+0x6e>
    800047e0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	072080e7          	jalr	114(ra) # 80003856 <ilock>
    stati(f->ip, &st);
    800047ec:	fb840593          	addi	a1,s0,-72
    800047f0:	6c88                	ld	a0,24(s1)
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	2ee080e7          	jalr	750(ra) # 80003ae0 <stati>
    iunlock(f->ip);
    800047fa:	6c88                	ld	a0,24(s1)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	11c080e7          	jalr	284(ra) # 80003918 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004804:	46e1                	li	a3,24
    80004806:	fb840613          	addi	a2,s0,-72
    8000480a:	85ce                	mv	a1,s3
    8000480c:	05093503          	ld	a0,80(s2)
    80004810:	ffffd097          	auipc	ra,0xffffd
    80004814:	e62080e7          	jalr	-414(ra) # 80001672 <copyout>
    80004818:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000481c:	60a6                	ld	ra,72(sp)
    8000481e:	6406                	ld	s0,64(sp)
    80004820:	74e2                	ld	s1,56(sp)
    80004822:	7942                	ld	s2,48(sp)
    80004824:	79a2                	ld	s3,40(sp)
    80004826:	6161                	addi	sp,sp,80
    80004828:	8082                	ret
  return -1;
    8000482a:	557d                	li	a0,-1
    8000482c:	bfc5                	j	8000481c <filestat+0x60>

000000008000482e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000482e:	7179                	addi	sp,sp,-48
    80004830:	f406                	sd	ra,40(sp)
    80004832:	f022                	sd	s0,32(sp)
    80004834:	ec26                	sd	s1,24(sp)
    80004836:	e84a                	sd	s2,16(sp)
    80004838:	e44e                	sd	s3,8(sp)
    8000483a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000483c:	00854783          	lbu	a5,8(a0)
    80004840:	c3d5                	beqz	a5,800048e4 <fileread+0xb6>
    80004842:	84aa                	mv	s1,a0
    80004844:	89ae                	mv	s3,a1
    80004846:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004848:	411c                	lw	a5,0(a0)
    8000484a:	4705                	li	a4,1
    8000484c:	04e78963          	beq	a5,a4,8000489e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004850:	470d                	li	a4,3
    80004852:	04e78d63          	beq	a5,a4,800048ac <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004856:	4709                	li	a4,2
    80004858:	06e79e63          	bne	a5,a4,800048d4 <fileread+0xa6>
    ilock(f->ip);
    8000485c:	6d08                	ld	a0,24(a0)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	ff8080e7          	jalr	-8(ra) # 80003856 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004866:	874a                	mv	a4,s2
    80004868:	5094                	lw	a3,32(s1)
    8000486a:	864e                	mv	a2,s3
    8000486c:	4585                	li	a1,1
    8000486e:	6c88                	ld	a0,24(s1)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	29a080e7          	jalr	666(ra) # 80003b0a <readi>
    80004878:	892a                	mv	s2,a0
    8000487a:	00a05563          	blez	a0,80004884 <fileread+0x56>
      f->off += r;
    8000487e:	509c                	lw	a5,32(s1)
    80004880:	9fa9                	addw	a5,a5,a0
    80004882:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004884:	6c88                	ld	a0,24(s1)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	092080e7          	jalr	146(ra) # 80003918 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000488e:	854a                	mv	a0,s2
    80004890:	70a2                	ld	ra,40(sp)
    80004892:	7402                	ld	s0,32(sp)
    80004894:	64e2                	ld	s1,24(sp)
    80004896:	6942                	ld	s2,16(sp)
    80004898:	69a2                	ld	s3,8(sp)
    8000489a:	6145                	addi	sp,sp,48
    8000489c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000489e:	6908                	ld	a0,16(a0)
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	3c8080e7          	jalr	968(ra) # 80004c68 <piperead>
    800048a8:	892a                	mv	s2,a0
    800048aa:	b7d5                	j	8000488e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ac:	02451783          	lh	a5,36(a0)
    800048b0:	03079693          	slli	a3,a5,0x30
    800048b4:	92c1                	srli	a3,a3,0x30
    800048b6:	4725                	li	a4,9
    800048b8:	02d76863          	bltu	a4,a3,800048e8 <fileread+0xba>
    800048bc:	0792                	slli	a5,a5,0x4
    800048be:	0001d717          	auipc	a4,0x1d
    800048c2:	c7270713          	addi	a4,a4,-910 # 80021530 <devsw>
    800048c6:	97ba                	add	a5,a5,a4
    800048c8:	639c                	ld	a5,0(a5)
    800048ca:	c38d                	beqz	a5,800048ec <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048cc:	4505                	li	a0,1
    800048ce:	9782                	jalr	a5
    800048d0:	892a                	mv	s2,a0
    800048d2:	bf75                	j	8000488e <fileread+0x60>
    panic("fileread");
    800048d4:	00004517          	auipc	a0,0x4
    800048d8:	de450513          	addi	a0,a0,-540 # 800086b8 <syscalls+0x260>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>
    return -1;
    800048e4:	597d                	li	s2,-1
    800048e6:	b765                	j	8000488e <fileread+0x60>
      return -1;
    800048e8:	597d                	li	s2,-1
    800048ea:	b755                	j	8000488e <fileread+0x60>
    800048ec:	597d                	li	s2,-1
    800048ee:	b745                	j	8000488e <fileread+0x60>

00000000800048f0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048f0:	715d                	addi	sp,sp,-80
    800048f2:	e486                	sd	ra,72(sp)
    800048f4:	e0a2                	sd	s0,64(sp)
    800048f6:	fc26                	sd	s1,56(sp)
    800048f8:	f84a                	sd	s2,48(sp)
    800048fa:	f44e                	sd	s3,40(sp)
    800048fc:	f052                	sd	s4,32(sp)
    800048fe:	ec56                	sd	s5,24(sp)
    80004900:	e85a                	sd	s6,16(sp)
    80004902:	e45e                	sd	s7,8(sp)
    80004904:	e062                	sd	s8,0(sp)
    80004906:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004908:	00954783          	lbu	a5,9(a0)
    8000490c:	10078663          	beqz	a5,80004a18 <filewrite+0x128>
    80004910:	892a                	mv	s2,a0
    80004912:	8aae                	mv	s5,a1
    80004914:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004916:	411c                	lw	a5,0(a0)
    80004918:	4705                	li	a4,1
    8000491a:	02e78263          	beq	a5,a4,8000493e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000491e:	470d                	li	a4,3
    80004920:	02e78663          	beq	a5,a4,8000494c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004924:	4709                	li	a4,2
    80004926:	0ee79163          	bne	a5,a4,80004a08 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000492a:	0ac05d63          	blez	a2,800049e4 <filewrite+0xf4>
    int i = 0;
    8000492e:	4981                	li	s3,0
    80004930:	6b05                	lui	s6,0x1
    80004932:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004936:	6b85                	lui	s7,0x1
    80004938:	c00b8b9b          	addiw	s7,s7,-1024
    8000493c:	a861                	j	800049d4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000493e:	6908                	ld	a0,16(a0)
    80004940:	00000097          	auipc	ra,0x0
    80004944:	22e080e7          	jalr	558(ra) # 80004b6e <pipewrite>
    80004948:	8a2a                	mv	s4,a0
    8000494a:	a045                	j	800049ea <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000494c:	02451783          	lh	a5,36(a0)
    80004950:	03079693          	slli	a3,a5,0x30
    80004954:	92c1                	srli	a3,a3,0x30
    80004956:	4725                	li	a4,9
    80004958:	0cd76263          	bltu	a4,a3,80004a1c <filewrite+0x12c>
    8000495c:	0792                	slli	a5,a5,0x4
    8000495e:	0001d717          	auipc	a4,0x1d
    80004962:	bd270713          	addi	a4,a4,-1070 # 80021530 <devsw>
    80004966:	97ba                	add	a5,a5,a4
    80004968:	679c                	ld	a5,8(a5)
    8000496a:	cbdd                	beqz	a5,80004a20 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000496c:	4505                	li	a0,1
    8000496e:	9782                	jalr	a5
    80004970:	8a2a                	mv	s4,a0
    80004972:	a8a5                	j	800049ea <filewrite+0xfa>
    80004974:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	8b0080e7          	jalr	-1872(ra) # 80004228 <begin_op>
      ilock(f->ip);
    80004980:	01893503          	ld	a0,24(s2)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	ed2080e7          	jalr	-302(ra) # 80003856 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000498c:	8762                	mv	a4,s8
    8000498e:	02092683          	lw	a3,32(s2)
    80004992:	01598633          	add	a2,s3,s5
    80004996:	4585                	li	a1,1
    80004998:	01893503          	ld	a0,24(s2)
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	266080e7          	jalr	614(ra) # 80003c02 <writei>
    800049a4:	84aa                	mv	s1,a0
    800049a6:	00a05763          	blez	a0,800049b4 <filewrite+0xc4>
        f->off += r;
    800049aa:	02092783          	lw	a5,32(s2)
    800049ae:	9fa9                	addw	a5,a5,a0
    800049b0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049b4:	01893503          	ld	a0,24(s2)
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	f60080e7          	jalr	-160(ra) # 80003918 <iunlock>
      end_op();
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	8e8080e7          	jalr	-1816(ra) # 800042a8 <end_op>

      if(r != n1){
    800049c8:	009c1f63          	bne	s8,s1,800049e6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049cc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049d0:	0149db63          	bge	s3,s4,800049e6 <filewrite+0xf6>
      int n1 = n - i;
    800049d4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049d8:	84be                	mv	s1,a5
    800049da:	2781                	sext.w	a5,a5
    800049dc:	f8fb5ce3          	bge	s6,a5,80004974 <filewrite+0x84>
    800049e0:	84de                	mv	s1,s7
    800049e2:	bf49                	j	80004974 <filewrite+0x84>
    int i = 0;
    800049e4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049e6:	013a1f63          	bne	s4,s3,80004a04 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ea:	8552                	mv	a0,s4
    800049ec:	60a6                	ld	ra,72(sp)
    800049ee:	6406                	ld	s0,64(sp)
    800049f0:	74e2                	ld	s1,56(sp)
    800049f2:	7942                	ld	s2,48(sp)
    800049f4:	79a2                	ld	s3,40(sp)
    800049f6:	7a02                	ld	s4,32(sp)
    800049f8:	6ae2                	ld	s5,24(sp)
    800049fa:	6b42                	ld	s6,16(sp)
    800049fc:	6ba2                	ld	s7,8(sp)
    800049fe:	6c02                	ld	s8,0(sp)
    80004a00:	6161                	addi	sp,sp,80
    80004a02:	8082                	ret
    ret = (i == n ? n : -1);
    80004a04:	5a7d                	li	s4,-1
    80004a06:	b7d5                	j	800049ea <filewrite+0xfa>
    panic("filewrite");
    80004a08:	00004517          	auipc	a0,0x4
    80004a0c:	cc050513          	addi	a0,a0,-832 # 800086c8 <syscalls+0x270>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>
    return -1;
    80004a18:	5a7d                	li	s4,-1
    80004a1a:	bfc1                	j	800049ea <filewrite+0xfa>
      return -1;
    80004a1c:	5a7d                	li	s4,-1
    80004a1e:	b7f1                	j	800049ea <filewrite+0xfa>
    80004a20:	5a7d                	li	s4,-1
    80004a22:	b7e1                	j	800049ea <filewrite+0xfa>

0000000080004a24 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a24:	7179                	addi	sp,sp,-48
    80004a26:	f406                	sd	ra,40(sp)
    80004a28:	f022                	sd	s0,32(sp)
    80004a2a:	ec26                	sd	s1,24(sp)
    80004a2c:	e84a                	sd	s2,16(sp)
    80004a2e:	e44e                	sd	s3,8(sp)
    80004a30:	e052                	sd	s4,0(sp)
    80004a32:	1800                	addi	s0,sp,48
    80004a34:	84aa                	mv	s1,a0
    80004a36:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a38:	0005b023          	sd	zero,0(a1)
    80004a3c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	bf8080e7          	jalr	-1032(ra) # 80004638 <filealloc>
    80004a48:	e088                	sd	a0,0(s1)
    80004a4a:	c551                	beqz	a0,80004ad6 <pipealloc+0xb2>
    80004a4c:	00000097          	auipc	ra,0x0
    80004a50:	bec080e7          	jalr	-1044(ra) # 80004638 <filealloc>
    80004a54:	00aa3023          	sd	a0,0(s4)
    80004a58:	c92d                	beqz	a0,80004aca <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	09a080e7          	jalr	154(ra) # 80000af4 <kalloc>
    80004a62:	892a                	mv	s2,a0
    80004a64:	c125                	beqz	a0,80004ac4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a66:	4985                	li	s3,1
    80004a68:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a6c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a70:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a74:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a78:	00004597          	auipc	a1,0x4
    80004a7c:	c6058593          	addi	a1,a1,-928 # 800086d8 <syscalls+0x280>
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	0d4080e7          	jalr	212(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a88:	609c                	ld	a5,0(s1)
    80004a8a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a8e:	609c                	ld	a5,0(s1)
    80004a90:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a94:	609c                	ld	a5,0(s1)
    80004a96:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a9a:	609c                	ld	a5,0(s1)
    80004a9c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aa0:	000a3783          	ld	a5,0(s4)
    80004aa4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aa8:	000a3783          	ld	a5,0(s4)
    80004aac:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ab0:	000a3783          	ld	a5,0(s4)
    80004ab4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ab8:	000a3783          	ld	a5,0(s4)
    80004abc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ac0:	4501                	li	a0,0
    80004ac2:	a025                	j	80004aea <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ac4:	6088                	ld	a0,0(s1)
    80004ac6:	e501                	bnez	a0,80004ace <pipealloc+0xaa>
    80004ac8:	a039                	j	80004ad6 <pipealloc+0xb2>
    80004aca:	6088                	ld	a0,0(s1)
    80004acc:	c51d                	beqz	a0,80004afa <pipealloc+0xd6>
    fileclose(*f0);
    80004ace:	00000097          	auipc	ra,0x0
    80004ad2:	c26080e7          	jalr	-986(ra) # 800046f4 <fileclose>
  if(*f1)
    80004ad6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ada:	557d                	li	a0,-1
  if(*f1)
    80004adc:	c799                	beqz	a5,80004aea <pipealloc+0xc6>
    fileclose(*f1);
    80004ade:	853e                	mv	a0,a5
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	c14080e7          	jalr	-1004(ra) # 800046f4 <fileclose>
  return -1;
    80004ae8:	557d                	li	a0,-1
}
    80004aea:	70a2                	ld	ra,40(sp)
    80004aec:	7402                	ld	s0,32(sp)
    80004aee:	64e2                	ld	s1,24(sp)
    80004af0:	6942                	ld	s2,16(sp)
    80004af2:	69a2                	ld	s3,8(sp)
    80004af4:	6a02                	ld	s4,0(sp)
    80004af6:	6145                	addi	sp,sp,48
    80004af8:	8082                	ret
  return -1;
    80004afa:	557d                	li	a0,-1
    80004afc:	b7fd                	j	80004aea <pipealloc+0xc6>

0000000080004afe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004afe:	1101                	addi	sp,sp,-32
    80004b00:	ec06                	sd	ra,24(sp)
    80004b02:	e822                	sd	s0,16(sp)
    80004b04:	e426                	sd	s1,8(sp)
    80004b06:	e04a                	sd	s2,0(sp)
    80004b08:	1000                	addi	s0,sp,32
    80004b0a:	84aa                	mv	s1,a0
    80004b0c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	0d6080e7          	jalr	214(ra) # 80000be4 <acquire>
  if(writable){
    80004b16:	02090d63          	beqz	s2,80004b50 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b1a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b1e:	21848513          	addi	a0,s1,536
    80004b22:	ffffe097          	auipc	ra,0xffffe
    80004b26:	90c080e7          	jalr	-1780(ra) # 8000242e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b2a:	2204b783          	ld	a5,544(s1)
    80004b2e:	eb95                	bnez	a5,80004b62 <pipeclose+0x64>
    release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	ebc080e7          	jalr	-324(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b44:	60e2                	ld	ra,24(sp)
    80004b46:	6442                	ld	s0,16(sp)
    80004b48:	64a2                	ld	s1,8(sp)
    80004b4a:	6902                	ld	s2,0(sp)
    80004b4c:	6105                	addi	sp,sp,32
    80004b4e:	8082                	ret
    pi->readopen = 0;
    80004b50:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b54:	21c48513          	addi	a0,s1,540
    80004b58:	ffffe097          	auipc	ra,0xffffe
    80004b5c:	8d6080e7          	jalr	-1834(ra) # 8000242e <wakeup>
    80004b60:	b7e9                	j	80004b2a <pipeclose+0x2c>
    release(&pi->lock);
    80004b62:	8526                	mv	a0,s1
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
}
    80004b6c:	bfe1                	j	80004b44 <pipeclose+0x46>

0000000080004b6e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b6e:	7159                	addi	sp,sp,-112
    80004b70:	f486                	sd	ra,104(sp)
    80004b72:	f0a2                	sd	s0,96(sp)
    80004b74:	eca6                	sd	s1,88(sp)
    80004b76:	e8ca                	sd	s2,80(sp)
    80004b78:	e4ce                	sd	s3,72(sp)
    80004b7a:	e0d2                	sd	s4,64(sp)
    80004b7c:	fc56                	sd	s5,56(sp)
    80004b7e:	f85a                	sd	s6,48(sp)
    80004b80:	f45e                	sd	s7,40(sp)
    80004b82:	f062                	sd	s8,32(sp)
    80004b84:	ec66                	sd	s9,24(sp)
    80004b86:	1880                	addi	s0,sp,112
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	8aae                	mv	s5,a1
    80004b8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	e3a080e7          	jalr	-454(ra) # 800019c8 <myproc>
    80004b96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	04a080e7          	jalr	74(ra) # 80000be4 <acquire>
  while(i < n){
    80004ba2:	0d405163          	blez	s4,80004c64 <pipewrite+0xf6>
    80004ba6:	8ba6                	mv	s7,s1
  int i = 0;
    80004ba8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004baa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bac:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bb0:	21c48c13          	addi	s8,s1,540
    80004bb4:	a08d                	j	80004c16 <pipewrite+0xa8>
      release(&pi->lock);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	0e0080e7          	jalr	224(ra) # 80000c98 <release>
      return -1;
    80004bc0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	70a6                	ld	ra,104(sp)
    80004bc6:	7406                	ld	s0,96(sp)
    80004bc8:	64e6                	ld	s1,88(sp)
    80004bca:	6946                	ld	s2,80(sp)
    80004bcc:	69a6                	ld	s3,72(sp)
    80004bce:	6a06                	ld	s4,64(sp)
    80004bd0:	7ae2                	ld	s5,56(sp)
    80004bd2:	7b42                	ld	s6,48(sp)
    80004bd4:	7ba2                	ld	s7,40(sp)
    80004bd6:	7c02                	ld	s8,32(sp)
    80004bd8:	6ce2                	ld	s9,24(sp)
    80004bda:	6165                	addi	sp,sp,112
    80004bdc:	8082                	ret
      wakeup(&pi->nread);
    80004bde:	8566                	mv	a0,s9
    80004be0:	ffffe097          	auipc	ra,0xffffe
    80004be4:	84e080e7          	jalr	-1970(ra) # 8000242e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004be8:	85de                	mv	a1,s7
    80004bea:	8562                	mv	a0,s8
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	6b6080e7          	jalr	1718(ra) # 800022a2 <sleep>
    80004bf4:	a839                	j	80004c12 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bf6:	21c4a783          	lw	a5,540(s1)
    80004bfa:	0017871b          	addiw	a4,a5,1
    80004bfe:	20e4ae23          	sw	a4,540(s1)
    80004c02:	1ff7f793          	andi	a5,a5,511
    80004c06:	97a6                	add	a5,a5,s1
    80004c08:	f9f44703          	lbu	a4,-97(s0)
    80004c0c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c10:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c12:	03495d63          	bge	s2,s4,80004c4c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c16:	2204a783          	lw	a5,544(s1)
    80004c1a:	dfd1                	beqz	a5,80004bb6 <pipewrite+0x48>
    80004c1c:	0289a783          	lw	a5,40(s3)
    80004c20:	fbd9                	bnez	a5,80004bb6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c22:	2184a783          	lw	a5,536(s1)
    80004c26:	21c4a703          	lw	a4,540(s1)
    80004c2a:	2007879b          	addiw	a5,a5,512
    80004c2e:	faf708e3          	beq	a4,a5,80004bde <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c32:	4685                	li	a3,1
    80004c34:	01590633          	add	a2,s2,s5
    80004c38:	f9f40593          	addi	a1,s0,-97
    80004c3c:	0509b503          	ld	a0,80(s3)
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	abe080e7          	jalr	-1346(ra) # 800016fe <copyin>
    80004c48:	fb6517e3          	bne	a0,s6,80004bf6 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c4c:	21848513          	addi	a0,s1,536
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	7de080e7          	jalr	2014(ra) # 8000242e <wakeup>
  release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	03e080e7          	jalr	62(ra) # 80000c98 <release>
  return i;
    80004c62:	b785                	j	80004bc2 <pipewrite+0x54>
  int i = 0;
    80004c64:	4901                	li	s2,0
    80004c66:	b7dd                	j	80004c4c <pipewrite+0xde>

0000000080004c68 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c68:	715d                	addi	sp,sp,-80
    80004c6a:	e486                	sd	ra,72(sp)
    80004c6c:	e0a2                	sd	s0,64(sp)
    80004c6e:	fc26                	sd	s1,56(sp)
    80004c70:	f84a                	sd	s2,48(sp)
    80004c72:	f44e                	sd	s3,40(sp)
    80004c74:	f052                	sd	s4,32(sp)
    80004c76:	ec56                	sd	s5,24(sp)
    80004c78:	e85a                	sd	s6,16(sp)
    80004c7a:	0880                	addi	s0,sp,80
    80004c7c:	84aa                	mv	s1,a0
    80004c7e:	892e                	mv	s2,a1
    80004c80:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	d46080e7          	jalr	-698(ra) # 800019c8 <myproc>
    80004c8a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c8c:	8b26                	mv	s6,s1
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	f54080e7          	jalr	-172(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c98:	2184a703          	lw	a4,536(s1)
    80004c9c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca4:	02f71463          	bne	a4,a5,80004ccc <piperead+0x64>
    80004ca8:	2244a783          	lw	a5,548(s1)
    80004cac:	c385                	beqz	a5,80004ccc <piperead+0x64>
    if(pr->killed){
    80004cae:	028a2783          	lw	a5,40(s4)
    80004cb2:	ebc1                	bnez	a5,80004d42 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb4:	85da                	mv	a1,s6
    80004cb6:	854e                	mv	a0,s3
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	5ea080e7          	jalr	1514(ra) # 800022a2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc0:	2184a703          	lw	a4,536(s1)
    80004cc4:	21c4a783          	lw	a5,540(s1)
    80004cc8:	fef700e3          	beq	a4,a5,80004ca8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ccc:	09505263          	blez	s5,80004d50 <piperead+0xe8>
    80004cd0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cd4:	2184a783          	lw	a5,536(s1)
    80004cd8:	21c4a703          	lw	a4,540(s1)
    80004cdc:	02f70d63          	beq	a4,a5,80004d16 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ce0:	0017871b          	addiw	a4,a5,1
    80004ce4:	20e4ac23          	sw	a4,536(s1)
    80004ce8:	1ff7f793          	andi	a5,a5,511
    80004cec:	97a6                	add	a5,a5,s1
    80004cee:	0187c783          	lbu	a5,24(a5)
    80004cf2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf6:	4685                	li	a3,1
    80004cf8:	fbf40613          	addi	a2,s0,-65
    80004cfc:	85ca                	mv	a1,s2
    80004cfe:	050a3503          	ld	a0,80(s4)
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	970080e7          	jalr	-1680(ra) # 80001672 <copyout>
    80004d0a:	01650663          	beq	a0,s6,80004d16 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d0e:	2985                	addiw	s3,s3,1
    80004d10:	0905                	addi	s2,s2,1
    80004d12:	fd3a91e3          	bne	s5,s3,80004cd4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d16:	21c48513          	addi	a0,s1,540
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	714080e7          	jalr	1812(ra) # 8000242e <wakeup>
  release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f74080e7          	jalr	-140(ra) # 80000c98 <release>
  return i;
}
    80004d2c:	854e                	mv	a0,s3
    80004d2e:	60a6                	ld	ra,72(sp)
    80004d30:	6406                	ld	s0,64(sp)
    80004d32:	74e2                	ld	s1,56(sp)
    80004d34:	7942                	ld	s2,48(sp)
    80004d36:	79a2                	ld	s3,40(sp)
    80004d38:	7a02                	ld	s4,32(sp)
    80004d3a:	6ae2                	ld	s5,24(sp)
    80004d3c:	6b42                	ld	s6,16(sp)
    80004d3e:	6161                	addi	sp,sp,80
    80004d40:	8082                	ret
      release(&pi->lock);
    80004d42:	8526                	mv	a0,s1
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	f54080e7          	jalr	-172(ra) # 80000c98 <release>
      return -1;
    80004d4c:	59fd                	li	s3,-1
    80004d4e:	bff9                	j	80004d2c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d50:	4981                	li	s3,0
    80004d52:	b7d1                	j	80004d16 <piperead+0xae>

0000000080004d54 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d54:	df010113          	addi	sp,sp,-528
    80004d58:	20113423          	sd	ra,520(sp)
    80004d5c:	20813023          	sd	s0,512(sp)
    80004d60:	ffa6                	sd	s1,504(sp)
    80004d62:	fbca                	sd	s2,496(sp)
    80004d64:	f7ce                	sd	s3,488(sp)
    80004d66:	f3d2                	sd	s4,480(sp)
    80004d68:	efd6                	sd	s5,472(sp)
    80004d6a:	ebda                	sd	s6,464(sp)
    80004d6c:	e7de                	sd	s7,456(sp)
    80004d6e:	e3e2                	sd	s8,448(sp)
    80004d70:	ff66                	sd	s9,440(sp)
    80004d72:	fb6a                	sd	s10,432(sp)
    80004d74:	f76e                	sd	s11,424(sp)
    80004d76:	0c00                	addi	s0,sp,528
    80004d78:	84aa                	mv	s1,a0
    80004d7a:	dea43c23          	sd	a0,-520(s0)
    80004d7e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	c46080e7          	jalr	-954(ra) # 800019c8 <myproc>
    80004d8a:	892a                	mv	s2,a0

  begin_op();
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	49c080e7          	jalr	1180(ra) # 80004228 <begin_op>

  if((ip = namei(path)) == 0){
    80004d94:	8526                	mv	a0,s1
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	276080e7          	jalr	630(ra) # 8000400c <namei>
    80004d9e:	c92d                	beqz	a0,80004e10 <exec+0xbc>
    80004da0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	ab4080e7          	jalr	-1356(ra) # 80003856 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004daa:	04000713          	li	a4,64
    80004dae:	4681                	li	a3,0
    80004db0:	e5040613          	addi	a2,s0,-432
    80004db4:	4581                	li	a1,0
    80004db6:	8526                	mv	a0,s1
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	d52080e7          	jalr	-686(ra) # 80003b0a <readi>
    80004dc0:	04000793          	li	a5,64
    80004dc4:	00f51a63          	bne	a0,a5,80004dd8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dc8:	e5042703          	lw	a4,-432(s0)
    80004dcc:	464c47b7          	lui	a5,0x464c4
    80004dd0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dd4:	04f70463          	beq	a4,a5,80004e1c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	cde080e7          	jalr	-802(ra) # 80003ab8 <iunlockput>
    end_op();
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	4c6080e7          	jalr	1222(ra) # 800042a8 <end_op>
  }
  return -1;
    80004dea:	557d                	li	a0,-1
}
    80004dec:	20813083          	ld	ra,520(sp)
    80004df0:	20013403          	ld	s0,512(sp)
    80004df4:	74fe                	ld	s1,504(sp)
    80004df6:	795e                	ld	s2,496(sp)
    80004df8:	79be                	ld	s3,488(sp)
    80004dfa:	7a1e                	ld	s4,480(sp)
    80004dfc:	6afe                	ld	s5,472(sp)
    80004dfe:	6b5e                	ld	s6,464(sp)
    80004e00:	6bbe                	ld	s7,456(sp)
    80004e02:	6c1e                	ld	s8,448(sp)
    80004e04:	7cfa                	ld	s9,440(sp)
    80004e06:	7d5a                	ld	s10,432(sp)
    80004e08:	7dba                	ld	s11,424(sp)
    80004e0a:	21010113          	addi	sp,sp,528
    80004e0e:	8082                	ret
    end_op();
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	498080e7          	jalr	1176(ra) # 800042a8 <end_op>
    return -1;
    80004e18:	557d                	li	a0,-1
    80004e1a:	bfc9                	j	80004dec <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e1c:	854a                	mv	a0,s2
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	c6e080e7          	jalr	-914(ra) # 80001a8c <proc_pagetable>
    80004e26:	8baa                	mv	s7,a0
    80004e28:	d945                	beqz	a0,80004dd8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e2a:	e7042983          	lw	s3,-400(s0)
    80004e2e:	e8845783          	lhu	a5,-376(s0)
    80004e32:	c7ad                	beqz	a5,80004e9c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e34:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e36:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e38:	6c85                	lui	s9,0x1
    80004e3a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e3e:	def43823          	sd	a5,-528(s0)
    80004e42:	a42d                	j	8000506c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e44:	00004517          	auipc	a0,0x4
    80004e48:	89c50513          	addi	a0,a0,-1892 # 800086e0 <syscalls+0x288>
    80004e4c:	ffffb097          	auipc	ra,0xffffb
    80004e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e54:	8756                	mv	a4,s5
    80004e56:	012d86bb          	addw	a3,s11,s2
    80004e5a:	4581                	li	a1,0
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	cac080e7          	jalr	-852(ra) # 80003b0a <readi>
    80004e66:	2501                	sext.w	a0,a0
    80004e68:	1aaa9963          	bne	s5,a0,8000501a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e6c:	6785                	lui	a5,0x1
    80004e6e:	0127893b          	addw	s2,a5,s2
    80004e72:	77fd                	lui	a5,0xfffff
    80004e74:	01478a3b          	addw	s4,a5,s4
    80004e78:	1f897163          	bgeu	s2,s8,8000505a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e7c:	02091593          	slli	a1,s2,0x20
    80004e80:	9181                	srli	a1,a1,0x20
    80004e82:	95ea                	add	a1,a1,s10
    80004e84:	855e                	mv	a0,s7
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	1e8080e7          	jalr	488(ra) # 8000106e <walkaddr>
    80004e8e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e90:	d955                	beqz	a0,80004e44 <exec+0xf0>
      n = PGSIZE;
    80004e92:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e94:	fd9a70e3          	bgeu	s4,s9,80004e54 <exec+0x100>
      n = sz - i;
    80004e98:	8ad2                	mv	s5,s4
    80004e9a:	bf6d                	j	80004e54 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e9c:	4901                	li	s2,0
  iunlockput(ip);
    80004e9e:	8526                	mv	a0,s1
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	c18080e7          	jalr	-1000(ra) # 80003ab8 <iunlockput>
  end_op();
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	400080e7          	jalr	1024(ra) # 800042a8 <end_op>
  p = myproc();
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	b18080e7          	jalr	-1256(ra) # 800019c8 <myproc>
    80004eb8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eba:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ebe:	6785                	lui	a5,0x1
    80004ec0:	17fd                	addi	a5,a5,-1
    80004ec2:	993e                	add	s2,s2,a5
    80004ec4:	757d                	lui	a0,0xfffff
    80004ec6:	00a977b3          	and	a5,s2,a0
    80004eca:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ece:	6609                	lui	a2,0x2
    80004ed0:	963e                	add	a2,a2,a5
    80004ed2:	85be                	mv	a1,a5
    80004ed4:	855e                	mv	a0,s7
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	54c080e7          	jalr	1356(ra) # 80001422 <uvmalloc>
    80004ede:	8b2a                	mv	s6,a0
  ip = 0;
    80004ee0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ee2:	12050c63          	beqz	a0,8000501a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ee6:	75f9                	lui	a1,0xffffe
    80004ee8:	95aa                	add	a1,a1,a0
    80004eea:	855e                	mv	a0,s7
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	754080e7          	jalr	1876(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ef4:	7c7d                	lui	s8,0xfffff
    80004ef6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ef8:	e0043783          	ld	a5,-512(s0)
    80004efc:	6388                	ld	a0,0(a5)
    80004efe:	c535                	beqz	a0,80004f6a <exec+0x216>
    80004f00:	e9040993          	addi	s3,s0,-368
    80004f04:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f08:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	f5a080e7          	jalr	-166(ra) # 80000e64 <strlen>
    80004f12:	2505                	addiw	a0,a0,1
    80004f14:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f18:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f1c:	13896363          	bltu	s2,s8,80005042 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f20:	e0043d83          	ld	s11,-512(s0)
    80004f24:	000dba03          	ld	s4,0(s11)
    80004f28:	8552                	mv	a0,s4
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	f3a080e7          	jalr	-198(ra) # 80000e64 <strlen>
    80004f32:	0015069b          	addiw	a3,a0,1
    80004f36:	8652                	mv	a2,s4
    80004f38:	85ca                	mv	a1,s2
    80004f3a:	855e                	mv	a0,s7
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	736080e7          	jalr	1846(ra) # 80001672 <copyout>
    80004f44:	10054363          	bltz	a0,8000504a <exec+0x2f6>
    ustack[argc] = sp;
    80004f48:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f4c:	0485                	addi	s1,s1,1
    80004f4e:	008d8793          	addi	a5,s11,8
    80004f52:	e0f43023          	sd	a5,-512(s0)
    80004f56:	008db503          	ld	a0,8(s11)
    80004f5a:	c911                	beqz	a0,80004f6e <exec+0x21a>
    if(argc >= MAXARG)
    80004f5c:	09a1                	addi	s3,s3,8
    80004f5e:	fb3c96e3          	bne	s9,s3,80004f0a <exec+0x1b6>
  sz = sz1;
    80004f62:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f66:	4481                	li	s1,0
    80004f68:	a84d                	j	8000501a <exec+0x2c6>
  sp = sz;
    80004f6a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f6c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f6e:	00349793          	slli	a5,s1,0x3
    80004f72:	f9040713          	addi	a4,s0,-112
    80004f76:	97ba                	add	a5,a5,a4
    80004f78:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f7c:	00148693          	addi	a3,s1,1
    80004f80:	068e                	slli	a3,a3,0x3
    80004f82:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f86:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f8a:	01897663          	bgeu	s2,s8,80004f96 <exec+0x242>
  sz = sz1;
    80004f8e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f92:	4481                	li	s1,0
    80004f94:	a059                	j	8000501a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f96:	e9040613          	addi	a2,s0,-368
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	855e                	mv	a0,s7
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	6d4080e7          	jalr	1748(ra) # 80001672 <copyout>
    80004fa6:	0a054663          	bltz	a0,80005052 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004faa:	058ab783          	ld	a5,88(s5)
    80004fae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fb2:	df843783          	ld	a5,-520(s0)
    80004fb6:	0007c703          	lbu	a4,0(a5)
    80004fba:	cf11                	beqz	a4,80004fd6 <exec+0x282>
    80004fbc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fbe:	02f00693          	li	a3,47
    80004fc2:	a039                	j	80004fd0 <exec+0x27c>
      last = s+1;
    80004fc4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fc8:	0785                	addi	a5,a5,1
    80004fca:	fff7c703          	lbu	a4,-1(a5)
    80004fce:	c701                	beqz	a4,80004fd6 <exec+0x282>
    if(*s == '/')
    80004fd0:	fed71ce3          	bne	a4,a3,80004fc8 <exec+0x274>
    80004fd4:	bfc5                	j	80004fc4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fd6:	4641                	li	a2,16
    80004fd8:	df843583          	ld	a1,-520(s0)
    80004fdc:	158a8513          	addi	a0,s5,344
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	e52080e7          	jalr	-430(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fe8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fec:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ff0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ff4:	058ab783          	ld	a5,88(s5)
    80004ff8:	e6843703          	ld	a4,-408(s0)
    80004ffc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ffe:	058ab783          	ld	a5,88(s5)
    80005002:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005006:	85ea                	mv	a1,s10
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	b20080e7          	jalr	-1248(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005010:	0004851b          	sext.w	a0,s1
    80005014:	bbe1                	j	80004dec <exec+0x98>
    80005016:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000501a:	e0843583          	ld	a1,-504(s0)
    8000501e:	855e                	mv	a0,s7
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	b08080e7          	jalr	-1272(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    80005028:	da0498e3          	bnez	s1,80004dd8 <exec+0x84>
  return -1;
    8000502c:	557d                	li	a0,-1
    8000502e:	bb7d                	j	80004dec <exec+0x98>
    80005030:	e1243423          	sd	s2,-504(s0)
    80005034:	b7dd                	j	8000501a <exec+0x2c6>
    80005036:	e1243423          	sd	s2,-504(s0)
    8000503a:	b7c5                	j	8000501a <exec+0x2c6>
    8000503c:	e1243423          	sd	s2,-504(s0)
    80005040:	bfe9                	j	8000501a <exec+0x2c6>
  sz = sz1;
    80005042:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005046:	4481                	li	s1,0
    80005048:	bfc9                	j	8000501a <exec+0x2c6>
  sz = sz1;
    8000504a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504e:	4481                	li	s1,0
    80005050:	b7e9                	j	8000501a <exec+0x2c6>
  sz = sz1;
    80005052:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005056:	4481                	li	s1,0
    80005058:	b7c9                	j	8000501a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000505a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000505e:	2b05                	addiw	s6,s6,1
    80005060:	0389899b          	addiw	s3,s3,56
    80005064:	e8845783          	lhu	a5,-376(s0)
    80005068:	e2fb5be3          	bge	s6,a5,80004e9e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000506c:	2981                	sext.w	s3,s3
    8000506e:	03800713          	li	a4,56
    80005072:	86ce                	mv	a3,s3
    80005074:	e1840613          	addi	a2,s0,-488
    80005078:	4581                	li	a1,0
    8000507a:	8526                	mv	a0,s1
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	a8e080e7          	jalr	-1394(ra) # 80003b0a <readi>
    80005084:	03800793          	li	a5,56
    80005088:	f8f517e3          	bne	a0,a5,80005016 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000508c:	e1842783          	lw	a5,-488(s0)
    80005090:	4705                	li	a4,1
    80005092:	fce796e3          	bne	a5,a4,8000505e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005096:	e4043603          	ld	a2,-448(s0)
    8000509a:	e3843783          	ld	a5,-456(s0)
    8000509e:	f8f669e3          	bltu	a2,a5,80005030 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050a2:	e2843783          	ld	a5,-472(s0)
    800050a6:	963e                	add	a2,a2,a5
    800050a8:	f8f667e3          	bltu	a2,a5,80005036 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ac:	85ca                	mv	a1,s2
    800050ae:	855e                	mv	a0,s7
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	372080e7          	jalr	882(ra) # 80001422 <uvmalloc>
    800050b8:	e0a43423          	sd	a0,-504(s0)
    800050bc:	d141                	beqz	a0,8000503c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050be:	e2843d03          	ld	s10,-472(s0)
    800050c2:	df043783          	ld	a5,-528(s0)
    800050c6:	00fd77b3          	and	a5,s10,a5
    800050ca:	fba1                	bnez	a5,8000501a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050cc:	e2042d83          	lw	s11,-480(s0)
    800050d0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050d4:	f80c03e3          	beqz	s8,8000505a <exec+0x306>
    800050d8:	8a62                	mv	s4,s8
    800050da:	4901                	li	s2,0
    800050dc:	b345                	j	80004e7c <exec+0x128>

00000000800050de <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050de:	7179                	addi	sp,sp,-48
    800050e0:	f406                	sd	ra,40(sp)
    800050e2:	f022                	sd	s0,32(sp)
    800050e4:	ec26                	sd	s1,24(sp)
    800050e6:	e84a                	sd	s2,16(sp)
    800050e8:	1800                	addi	s0,sp,48
    800050ea:	892e                	mv	s2,a1
    800050ec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050ee:	fdc40593          	addi	a1,s0,-36
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	bc0080e7          	jalr	-1088(ra) # 80002cb2 <argint>
    800050fa:	04054063          	bltz	a0,8000513a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050fe:	fdc42703          	lw	a4,-36(s0)
    80005102:	47bd                	li	a5,15
    80005104:	02e7ed63          	bltu	a5,a4,8000513e <argfd+0x60>
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	8c0080e7          	jalr	-1856(ra) # 800019c8 <myproc>
    80005110:	fdc42703          	lw	a4,-36(s0)
    80005114:	01a70793          	addi	a5,a4,26
    80005118:	078e                	slli	a5,a5,0x3
    8000511a:	953e                	add	a0,a0,a5
    8000511c:	611c                	ld	a5,0(a0)
    8000511e:	c395                	beqz	a5,80005142 <argfd+0x64>
    return -1;
  if(pfd)
    80005120:	00090463          	beqz	s2,80005128 <argfd+0x4a>
    *pfd = fd;
    80005124:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005128:	4501                	li	a0,0
  if(pf)
    8000512a:	c091                	beqz	s1,8000512e <argfd+0x50>
    *pf = f;
    8000512c:	e09c                	sd	a5,0(s1)
}
    8000512e:	70a2                	ld	ra,40(sp)
    80005130:	7402                	ld	s0,32(sp)
    80005132:	64e2                	ld	s1,24(sp)
    80005134:	6942                	ld	s2,16(sp)
    80005136:	6145                	addi	sp,sp,48
    80005138:	8082                	ret
    return -1;
    8000513a:	557d                	li	a0,-1
    8000513c:	bfcd                	j	8000512e <argfd+0x50>
    return -1;
    8000513e:	557d                	li	a0,-1
    80005140:	b7fd                	j	8000512e <argfd+0x50>
    80005142:	557d                	li	a0,-1
    80005144:	b7ed                	j	8000512e <argfd+0x50>

0000000080005146 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005146:	1101                	addi	sp,sp,-32
    80005148:	ec06                	sd	ra,24(sp)
    8000514a:	e822                	sd	s0,16(sp)
    8000514c:	e426                	sd	s1,8(sp)
    8000514e:	1000                	addi	s0,sp,32
    80005150:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	876080e7          	jalr	-1930(ra) # 800019c8 <myproc>
    8000515a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000515c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005160:	4501                	li	a0,0
    80005162:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005164:	6398                	ld	a4,0(a5)
    80005166:	cb19                	beqz	a4,8000517c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005168:	2505                	addiw	a0,a0,1
    8000516a:	07a1                	addi	a5,a5,8
    8000516c:	fed51ce3          	bne	a0,a3,80005164 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005170:	557d                	li	a0,-1
}
    80005172:	60e2                	ld	ra,24(sp)
    80005174:	6442                	ld	s0,16(sp)
    80005176:	64a2                	ld	s1,8(sp)
    80005178:	6105                	addi	sp,sp,32
    8000517a:	8082                	ret
      p->ofile[fd] = f;
    8000517c:	01a50793          	addi	a5,a0,26
    80005180:	078e                	slli	a5,a5,0x3
    80005182:	963e                	add	a2,a2,a5
    80005184:	e204                	sd	s1,0(a2)
      return fd;
    80005186:	b7f5                	j	80005172 <fdalloc+0x2c>

0000000080005188 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005188:	715d                	addi	sp,sp,-80
    8000518a:	e486                	sd	ra,72(sp)
    8000518c:	e0a2                	sd	s0,64(sp)
    8000518e:	fc26                	sd	s1,56(sp)
    80005190:	f84a                	sd	s2,48(sp)
    80005192:	f44e                	sd	s3,40(sp)
    80005194:	f052                	sd	s4,32(sp)
    80005196:	ec56                	sd	s5,24(sp)
    80005198:	0880                	addi	s0,sp,80
    8000519a:	89ae                	mv	s3,a1
    8000519c:	8ab2                	mv	s5,a2
    8000519e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051a0:	fb040593          	addi	a1,s0,-80
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	e86080e7          	jalr	-378(ra) # 8000402a <nameiparent>
    800051ac:	892a                	mv	s2,a0
    800051ae:	12050f63          	beqz	a0,800052ec <create+0x164>
    return 0;

  ilock(dp);
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	6a4080e7          	jalr	1700(ra) # 80003856 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ba:	4601                	li	a2,0
    800051bc:	fb040593          	addi	a1,s0,-80
    800051c0:	854a                	mv	a0,s2
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	b78080e7          	jalr	-1160(ra) # 80003d3a <dirlookup>
    800051ca:	84aa                	mv	s1,a0
    800051cc:	c921                	beqz	a0,8000521c <create+0x94>
    iunlockput(dp);
    800051ce:	854a                	mv	a0,s2
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	8e8080e7          	jalr	-1816(ra) # 80003ab8 <iunlockput>
    ilock(ip);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	67c080e7          	jalr	1660(ra) # 80003856 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051e2:	2981                	sext.w	s3,s3
    800051e4:	4789                	li	a5,2
    800051e6:	02f99463          	bne	s3,a5,8000520e <create+0x86>
    800051ea:	0444d783          	lhu	a5,68(s1)
    800051ee:	37f9                	addiw	a5,a5,-2
    800051f0:	17c2                	slli	a5,a5,0x30
    800051f2:	93c1                	srli	a5,a5,0x30
    800051f4:	4705                	li	a4,1
    800051f6:	00f76c63          	bltu	a4,a5,8000520e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051fa:	8526                	mv	a0,s1
    800051fc:	60a6                	ld	ra,72(sp)
    800051fe:	6406                	ld	s0,64(sp)
    80005200:	74e2                	ld	s1,56(sp)
    80005202:	7942                	ld	s2,48(sp)
    80005204:	79a2                	ld	s3,40(sp)
    80005206:	7a02                	ld	s4,32(sp)
    80005208:	6ae2                	ld	s5,24(sp)
    8000520a:	6161                	addi	sp,sp,80
    8000520c:	8082                	ret
    iunlockput(ip);
    8000520e:	8526                	mv	a0,s1
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	8a8080e7          	jalr	-1880(ra) # 80003ab8 <iunlockput>
    return 0;
    80005218:	4481                	li	s1,0
    8000521a:	b7c5                	j	800051fa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000521c:	85ce                	mv	a1,s3
    8000521e:	00092503          	lw	a0,0(s2)
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	49c080e7          	jalr	1180(ra) # 800036be <ialloc>
    8000522a:	84aa                	mv	s1,a0
    8000522c:	c529                	beqz	a0,80005276 <create+0xee>
  ilock(ip);
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	628080e7          	jalr	1576(ra) # 80003856 <ilock>
  ip->major = major;
    80005236:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000523a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000523e:	4785                	li	a5,1
    80005240:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	546080e7          	jalr	1350(ra) # 8000378c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000524e:	2981                	sext.w	s3,s3
    80005250:	4785                	li	a5,1
    80005252:	02f98a63          	beq	s3,a5,80005286 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005256:	40d0                	lw	a2,4(s1)
    80005258:	fb040593          	addi	a1,s0,-80
    8000525c:	854a                	mv	a0,s2
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	cec080e7          	jalr	-788(ra) # 80003f4a <dirlink>
    80005266:	06054b63          	bltz	a0,800052dc <create+0x154>
  iunlockput(dp);
    8000526a:	854a                	mv	a0,s2
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	84c080e7          	jalr	-1972(ra) # 80003ab8 <iunlockput>
  return ip;
    80005274:	b759                	j	800051fa <create+0x72>
    panic("create: ialloc");
    80005276:	00003517          	auipc	a0,0x3
    8000527a:	48a50513          	addi	a0,a0,1162 # 80008700 <syscalls+0x2a8>
    8000527e:	ffffb097          	auipc	ra,0xffffb
    80005282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005286:	04a95783          	lhu	a5,74(s2)
    8000528a:	2785                	addiw	a5,a5,1
    8000528c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005290:	854a                	mv	a0,s2
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	4fa080e7          	jalr	1274(ra) # 8000378c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000529a:	40d0                	lw	a2,4(s1)
    8000529c:	00003597          	auipc	a1,0x3
    800052a0:	47458593          	addi	a1,a1,1140 # 80008710 <syscalls+0x2b8>
    800052a4:	8526                	mv	a0,s1
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	ca4080e7          	jalr	-860(ra) # 80003f4a <dirlink>
    800052ae:	00054f63          	bltz	a0,800052cc <create+0x144>
    800052b2:	00492603          	lw	a2,4(s2)
    800052b6:	00003597          	auipc	a1,0x3
    800052ba:	46258593          	addi	a1,a1,1122 # 80008718 <syscalls+0x2c0>
    800052be:	8526                	mv	a0,s1
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	c8a080e7          	jalr	-886(ra) # 80003f4a <dirlink>
    800052c8:	f80557e3          	bgez	a0,80005256 <create+0xce>
      panic("create dots");
    800052cc:	00003517          	auipc	a0,0x3
    800052d0:	45450513          	addi	a0,a0,1108 # 80008720 <syscalls+0x2c8>
    800052d4:	ffffb097          	auipc	ra,0xffffb
    800052d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052dc:	00003517          	auipc	a0,0x3
    800052e0:	45450513          	addi	a0,a0,1108 # 80008730 <syscalls+0x2d8>
    800052e4:	ffffb097          	auipc	ra,0xffffb
    800052e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
    return 0;
    800052ec:	84aa                	mv	s1,a0
    800052ee:	b731                	j	800051fa <create+0x72>

00000000800052f0 <sys_dup>:
{
    800052f0:	7179                	addi	sp,sp,-48
    800052f2:	f406                	sd	ra,40(sp)
    800052f4:	f022                	sd	s0,32(sp)
    800052f6:	ec26                	sd	s1,24(sp)
    800052f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052fa:	fd840613          	addi	a2,s0,-40
    800052fe:	4581                	li	a1,0
    80005300:	4501                	li	a0,0
    80005302:	00000097          	auipc	ra,0x0
    80005306:	ddc080e7          	jalr	-548(ra) # 800050de <argfd>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000530c:	02054363          	bltz	a0,80005332 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005310:	fd843503          	ld	a0,-40(s0)
    80005314:	00000097          	auipc	ra,0x0
    80005318:	e32080e7          	jalr	-462(ra) # 80005146 <fdalloc>
    8000531c:	84aa                	mv	s1,a0
    return -1;
    8000531e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005320:	00054963          	bltz	a0,80005332 <sys_dup+0x42>
  filedup(f);
    80005324:	fd843503          	ld	a0,-40(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	37a080e7          	jalr	890(ra) # 800046a2 <filedup>
  return fd;
    80005330:	87a6                	mv	a5,s1
}
    80005332:	853e                	mv	a0,a5
    80005334:	70a2                	ld	ra,40(sp)
    80005336:	7402                	ld	s0,32(sp)
    80005338:	64e2                	ld	s1,24(sp)
    8000533a:	6145                	addi	sp,sp,48
    8000533c:	8082                	ret

000000008000533e <sys_read>:
{
    8000533e:	7179                	addi	sp,sp,-48
    80005340:	f406                	sd	ra,40(sp)
    80005342:	f022                	sd	s0,32(sp)
    80005344:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005346:	fe840613          	addi	a2,s0,-24
    8000534a:	4581                	li	a1,0
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	d90080e7          	jalr	-624(ra) # 800050de <argfd>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	04054163          	bltz	a0,8000539a <sys_read+0x5c>
    8000535c:	fe440593          	addi	a1,s0,-28
    80005360:	4509                	li	a0,2
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	950080e7          	jalr	-1712(ra) # 80002cb2 <argint>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536c:	02054763          	bltz	a0,8000539a <sys_read+0x5c>
    80005370:	fd840593          	addi	a1,s0,-40
    80005374:	4505                	li	a0,1
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	95e080e7          	jalr	-1698(ra) # 80002cd4 <argaddr>
    return -1;
    8000537e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005380:	00054d63          	bltz	a0,8000539a <sys_read+0x5c>
  return fileread(f, p, n);
    80005384:	fe442603          	lw	a2,-28(s0)
    80005388:	fd843583          	ld	a1,-40(s0)
    8000538c:	fe843503          	ld	a0,-24(s0)
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	49e080e7          	jalr	1182(ra) # 8000482e <fileread>
    80005398:	87aa                	mv	a5,a0
}
    8000539a:	853e                	mv	a0,a5
    8000539c:	70a2                	ld	ra,40(sp)
    8000539e:	7402                	ld	s0,32(sp)
    800053a0:	6145                	addi	sp,sp,48
    800053a2:	8082                	ret

00000000800053a4 <sys_write>:
{
    800053a4:	7179                	addi	sp,sp,-48
    800053a6:	f406                	sd	ra,40(sp)
    800053a8:	f022                	sd	s0,32(sp)
    800053aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ac:	fe840613          	addi	a2,s0,-24
    800053b0:	4581                	li	a1,0
    800053b2:	4501                	li	a0,0
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	d2a080e7          	jalr	-726(ra) # 800050de <argfd>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	04054163          	bltz	a0,80005400 <sys_write+0x5c>
    800053c2:	fe440593          	addi	a1,s0,-28
    800053c6:	4509                	li	a0,2
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	8ea080e7          	jalr	-1814(ra) # 80002cb2 <argint>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	02054763          	bltz	a0,80005400 <sys_write+0x5c>
    800053d6:	fd840593          	addi	a1,s0,-40
    800053da:	4505                	li	a0,1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	8f8080e7          	jalr	-1800(ra) # 80002cd4 <argaddr>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e6:	00054d63          	bltz	a0,80005400 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053ea:	fe442603          	lw	a2,-28(s0)
    800053ee:	fd843583          	ld	a1,-40(s0)
    800053f2:	fe843503          	ld	a0,-24(s0)
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	4fa080e7          	jalr	1274(ra) # 800048f0 <filewrite>
    800053fe:	87aa                	mv	a5,a0
}
    80005400:	853e                	mv	a0,a5
    80005402:	70a2                	ld	ra,40(sp)
    80005404:	7402                	ld	s0,32(sp)
    80005406:	6145                	addi	sp,sp,48
    80005408:	8082                	ret

000000008000540a <sys_close>:
{
    8000540a:	1101                	addi	sp,sp,-32
    8000540c:	ec06                	sd	ra,24(sp)
    8000540e:	e822                	sd	s0,16(sp)
    80005410:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005412:	fe040613          	addi	a2,s0,-32
    80005416:	fec40593          	addi	a1,s0,-20
    8000541a:	4501                	li	a0,0
    8000541c:	00000097          	auipc	ra,0x0
    80005420:	cc2080e7          	jalr	-830(ra) # 800050de <argfd>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005426:	02054463          	bltz	a0,8000544e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	59e080e7          	jalr	1438(ra) # 800019c8 <myproc>
    80005432:	fec42783          	lw	a5,-20(s0)
    80005436:	07e9                	addi	a5,a5,26
    80005438:	078e                	slli	a5,a5,0x3
    8000543a:	97aa                	add	a5,a5,a0
    8000543c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005440:	fe043503          	ld	a0,-32(s0)
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	2b0080e7          	jalr	688(ra) # 800046f4 <fileclose>
  return 0;
    8000544c:	4781                	li	a5,0
}
    8000544e:	853e                	mv	a0,a5
    80005450:	60e2                	ld	ra,24(sp)
    80005452:	6442                	ld	s0,16(sp)
    80005454:	6105                	addi	sp,sp,32
    80005456:	8082                	ret

0000000080005458 <sys_fstat>:
{
    80005458:	1101                	addi	sp,sp,-32
    8000545a:	ec06                	sd	ra,24(sp)
    8000545c:	e822                	sd	s0,16(sp)
    8000545e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005460:	fe840613          	addi	a2,s0,-24
    80005464:	4581                	li	a1,0
    80005466:	4501                	li	a0,0
    80005468:	00000097          	auipc	ra,0x0
    8000546c:	c76080e7          	jalr	-906(ra) # 800050de <argfd>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005472:	02054563          	bltz	a0,8000549c <sys_fstat+0x44>
    80005476:	fe040593          	addi	a1,s0,-32
    8000547a:	4505                	li	a0,1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	858080e7          	jalr	-1960(ra) # 80002cd4 <argaddr>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005486:	00054b63          	bltz	a0,8000549c <sys_fstat+0x44>
  return filestat(f, st);
    8000548a:	fe043583          	ld	a1,-32(s0)
    8000548e:	fe843503          	ld	a0,-24(s0)
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	32a080e7          	jalr	810(ra) # 800047bc <filestat>
    8000549a:	87aa                	mv	a5,a0
}
    8000549c:	853e                	mv	a0,a5
    8000549e:	60e2                	ld	ra,24(sp)
    800054a0:	6442                	ld	s0,16(sp)
    800054a2:	6105                	addi	sp,sp,32
    800054a4:	8082                	ret

00000000800054a6 <sys_link>:
{
    800054a6:	7169                	addi	sp,sp,-304
    800054a8:	f606                	sd	ra,296(sp)
    800054aa:	f222                	sd	s0,288(sp)
    800054ac:	ee26                	sd	s1,280(sp)
    800054ae:	ea4a                	sd	s2,272(sp)
    800054b0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b2:	08000613          	li	a2,128
    800054b6:	ed040593          	addi	a1,s0,-304
    800054ba:	4501                	li	a0,0
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	83a080e7          	jalr	-1990(ra) # 80002cf6 <argstr>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c6:	10054e63          	bltz	a0,800055e2 <sys_link+0x13c>
    800054ca:	08000613          	li	a2,128
    800054ce:	f5040593          	addi	a1,s0,-176
    800054d2:	4505                	li	a0,1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	822080e7          	jalr	-2014(ra) # 80002cf6 <argstr>
    return -1;
    800054dc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054de:	10054263          	bltz	a0,800055e2 <sys_link+0x13c>
  begin_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	d46080e7          	jalr	-698(ra) # 80004228 <begin_op>
  if((ip = namei(old)) == 0){
    800054ea:	ed040513          	addi	a0,s0,-304
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	b1e080e7          	jalr	-1250(ra) # 8000400c <namei>
    800054f6:	84aa                	mv	s1,a0
    800054f8:	c551                	beqz	a0,80005584 <sys_link+0xde>
  ilock(ip);
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	35c080e7          	jalr	860(ra) # 80003856 <ilock>
  if(ip->type == T_DIR){
    80005502:	04449703          	lh	a4,68(s1)
    80005506:	4785                	li	a5,1
    80005508:	08f70463          	beq	a4,a5,80005590 <sys_link+0xea>
  ip->nlink++;
    8000550c:	04a4d783          	lhu	a5,74(s1)
    80005510:	2785                	addiw	a5,a5,1
    80005512:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	274080e7          	jalr	628(ra) # 8000378c <iupdate>
  iunlock(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	3f6080e7          	jalr	1014(ra) # 80003918 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000552a:	fd040593          	addi	a1,s0,-48
    8000552e:	f5040513          	addi	a0,s0,-176
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	af8080e7          	jalr	-1288(ra) # 8000402a <nameiparent>
    8000553a:	892a                	mv	s2,a0
    8000553c:	c935                	beqz	a0,800055b0 <sys_link+0x10a>
  ilock(dp);
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	318080e7          	jalr	792(ra) # 80003856 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005546:	00092703          	lw	a4,0(s2)
    8000554a:	409c                	lw	a5,0(s1)
    8000554c:	04f71d63          	bne	a4,a5,800055a6 <sys_link+0x100>
    80005550:	40d0                	lw	a2,4(s1)
    80005552:	fd040593          	addi	a1,s0,-48
    80005556:	854a                	mv	a0,s2
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	9f2080e7          	jalr	-1550(ra) # 80003f4a <dirlink>
    80005560:	04054363          	bltz	a0,800055a6 <sys_link+0x100>
  iunlockput(dp);
    80005564:	854a                	mv	a0,s2
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	552080e7          	jalr	1362(ra) # 80003ab8 <iunlockput>
  iput(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	4a0080e7          	jalr	1184(ra) # 80003a10 <iput>
  end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	d30080e7          	jalr	-720(ra) # 800042a8 <end_op>
  return 0;
    80005580:	4781                	li	a5,0
    80005582:	a085                	j	800055e2 <sys_link+0x13c>
    end_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	d24080e7          	jalr	-732(ra) # 800042a8 <end_op>
    return -1;
    8000558c:	57fd                	li	a5,-1
    8000558e:	a891                	j	800055e2 <sys_link+0x13c>
    iunlockput(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	526080e7          	jalr	1318(ra) # 80003ab8 <iunlockput>
    end_op();
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	d0e080e7          	jalr	-754(ra) # 800042a8 <end_op>
    return -1;
    800055a2:	57fd                	li	a5,-1
    800055a4:	a83d                	j	800055e2 <sys_link+0x13c>
    iunlockput(dp);
    800055a6:	854a                	mv	a0,s2
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	510080e7          	jalr	1296(ra) # 80003ab8 <iunlockput>
  ilock(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	2a4080e7          	jalr	676(ra) # 80003856 <ilock>
  ip->nlink--;
    800055ba:	04a4d783          	lhu	a5,74(s1)
    800055be:	37fd                	addiw	a5,a5,-1
    800055c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	1c6080e7          	jalr	454(ra) # 8000378c <iupdate>
  iunlockput(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	4e8080e7          	jalr	1256(ra) # 80003ab8 <iunlockput>
  end_op();
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	cd0080e7          	jalr	-816(ra) # 800042a8 <end_op>
  return -1;
    800055e0:	57fd                	li	a5,-1
}
    800055e2:	853e                	mv	a0,a5
    800055e4:	70b2                	ld	ra,296(sp)
    800055e6:	7412                	ld	s0,288(sp)
    800055e8:	64f2                	ld	s1,280(sp)
    800055ea:	6952                	ld	s2,272(sp)
    800055ec:	6155                	addi	sp,sp,304
    800055ee:	8082                	ret

00000000800055f0 <sys_unlink>:
{
    800055f0:	7151                	addi	sp,sp,-240
    800055f2:	f586                	sd	ra,232(sp)
    800055f4:	f1a2                	sd	s0,224(sp)
    800055f6:	eda6                	sd	s1,216(sp)
    800055f8:	e9ca                	sd	s2,208(sp)
    800055fa:	e5ce                	sd	s3,200(sp)
    800055fc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055fe:	08000613          	li	a2,128
    80005602:	f3040593          	addi	a1,s0,-208
    80005606:	4501                	li	a0,0
    80005608:	ffffd097          	auipc	ra,0xffffd
    8000560c:	6ee080e7          	jalr	1774(ra) # 80002cf6 <argstr>
    80005610:	18054163          	bltz	a0,80005792 <sys_unlink+0x1a2>
  begin_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	c14080e7          	jalr	-1004(ra) # 80004228 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000561c:	fb040593          	addi	a1,s0,-80
    80005620:	f3040513          	addi	a0,s0,-208
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	a06080e7          	jalr	-1530(ra) # 8000402a <nameiparent>
    8000562c:	84aa                	mv	s1,a0
    8000562e:	c979                	beqz	a0,80005704 <sys_unlink+0x114>
  ilock(dp);
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	226080e7          	jalr	550(ra) # 80003856 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005638:	00003597          	auipc	a1,0x3
    8000563c:	0d858593          	addi	a1,a1,216 # 80008710 <syscalls+0x2b8>
    80005640:	fb040513          	addi	a0,s0,-80
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	6dc080e7          	jalr	1756(ra) # 80003d20 <namecmp>
    8000564c:	14050a63          	beqz	a0,800057a0 <sys_unlink+0x1b0>
    80005650:	00003597          	auipc	a1,0x3
    80005654:	0c858593          	addi	a1,a1,200 # 80008718 <syscalls+0x2c0>
    80005658:	fb040513          	addi	a0,s0,-80
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	6c4080e7          	jalr	1732(ra) # 80003d20 <namecmp>
    80005664:	12050e63          	beqz	a0,800057a0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005668:	f2c40613          	addi	a2,s0,-212
    8000566c:	fb040593          	addi	a1,s0,-80
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	6c8080e7          	jalr	1736(ra) # 80003d3a <dirlookup>
    8000567a:	892a                	mv	s2,a0
    8000567c:	12050263          	beqz	a0,800057a0 <sys_unlink+0x1b0>
  ilock(ip);
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	1d6080e7          	jalr	470(ra) # 80003856 <ilock>
  if(ip->nlink < 1)
    80005688:	04a91783          	lh	a5,74(s2)
    8000568c:	08f05263          	blez	a5,80005710 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005690:	04491703          	lh	a4,68(s2)
    80005694:	4785                	li	a5,1
    80005696:	08f70563          	beq	a4,a5,80005720 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000569a:	4641                	li	a2,16
    8000569c:	4581                	li	a1,0
    8000569e:	fc040513          	addi	a0,s0,-64
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	63e080e7          	jalr	1598(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056aa:	4741                	li	a4,16
    800056ac:	f2c42683          	lw	a3,-212(s0)
    800056b0:	fc040613          	addi	a2,s0,-64
    800056b4:	4581                	li	a1,0
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	54a080e7          	jalr	1354(ra) # 80003c02 <writei>
    800056c0:	47c1                	li	a5,16
    800056c2:	0af51563          	bne	a0,a5,8000576c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056c6:	04491703          	lh	a4,68(s2)
    800056ca:	4785                	li	a5,1
    800056cc:	0af70863          	beq	a4,a5,8000577c <sys_unlink+0x18c>
  iunlockput(dp);
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	3e6080e7          	jalr	998(ra) # 80003ab8 <iunlockput>
  ip->nlink--;
    800056da:	04a95783          	lhu	a5,74(s2)
    800056de:	37fd                	addiw	a5,a5,-1
    800056e0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056e4:	854a                	mv	a0,s2
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	0a6080e7          	jalr	166(ra) # 8000378c <iupdate>
  iunlockput(ip);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	3c8080e7          	jalr	968(ra) # 80003ab8 <iunlockput>
  end_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	bb0080e7          	jalr	-1104(ra) # 800042a8 <end_op>
  return 0;
    80005700:	4501                	li	a0,0
    80005702:	a84d                	j	800057b4 <sys_unlink+0x1c4>
    end_op();
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	ba4080e7          	jalr	-1116(ra) # 800042a8 <end_op>
    return -1;
    8000570c:	557d                	li	a0,-1
    8000570e:	a05d                	j	800057b4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	03050513          	addi	a0,a0,48 # 80008740 <syscalls+0x2e8>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e26080e7          	jalr	-474(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005720:	04c92703          	lw	a4,76(s2)
    80005724:	02000793          	li	a5,32
    80005728:	f6e7f9e3          	bgeu	a5,a4,8000569a <sys_unlink+0xaa>
    8000572c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005730:	4741                	li	a4,16
    80005732:	86ce                	mv	a3,s3
    80005734:	f1840613          	addi	a2,s0,-232
    80005738:	4581                	li	a1,0
    8000573a:	854a                	mv	a0,s2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	3ce080e7          	jalr	974(ra) # 80003b0a <readi>
    80005744:	47c1                	li	a5,16
    80005746:	00f51b63          	bne	a0,a5,8000575c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000574a:	f1845783          	lhu	a5,-232(s0)
    8000574e:	e7a1                	bnez	a5,80005796 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005750:	29c1                	addiw	s3,s3,16
    80005752:	04c92783          	lw	a5,76(s2)
    80005756:	fcf9ede3          	bltu	s3,a5,80005730 <sys_unlink+0x140>
    8000575a:	b781                	j	8000569a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000575c:	00003517          	auipc	a0,0x3
    80005760:	ffc50513          	addi	a0,a0,-4 # 80008758 <syscalls+0x300>
    80005764:	ffffb097          	auipc	ra,0xffffb
    80005768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000576c:	00003517          	auipc	a0,0x3
    80005770:	00450513          	addi	a0,a0,4 # 80008770 <syscalls+0x318>
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>
    dp->nlink--;
    8000577c:	04a4d783          	lhu	a5,74(s1)
    80005780:	37fd                	addiw	a5,a5,-1
    80005782:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	004080e7          	jalr	4(ra) # 8000378c <iupdate>
    80005790:	b781                	j	800056d0 <sys_unlink+0xe0>
    return -1;
    80005792:	557d                	li	a0,-1
    80005794:	a005                	j	800057b4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005796:	854a                	mv	a0,s2
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	320080e7          	jalr	800(ra) # 80003ab8 <iunlockput>
  iunlockput(dp);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	316080e7          	jalr	790(ra) # 80003ab8 <iunlockput>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	afe080e7          	jalr	-1282(ra) # 800042a8 <end_op>
  return -1;
    800057b2:	557d                	li	a0,-1
}
    800057b4:	70ae                	ld	ra,232(sp)
    800057b6:	740e                	ld	s0,224(sp)
    800057b8:	64ee                	ld	s1,216(sp)
    800057ba:	694e                	ld	s2,208(sp)
    800057bc:	69ae                	ld	s3,200(sp)
    800057be:	616d                	addi	sp,sp,240
    800057c0:	8082                	ret

00000000800057c2 <sys_open>:

uint64
sys_open(void)
{
    800057c2:	7131                	addi	sp,sp,-192
    800057c4:	fd06                	sd	ra,184(sp)
    800057c6:	f922                	sd	s0,176(sp)
    800057c8:	f526                	sd	s1,168(sp)
    800057ca:	f14a                	sd	s2,160(sp)
    800057cc:	ed4e                	sd	s3,152(sp)
    800057ce:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d0:	08000613          	li	a2,128
    800057d4:	f5040593          	addi	a1,s0,-176
    800057d8:	4501                	li	a0,0
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	51c080e7          	jalr	1308(ra) # 80002cf6 <argstr>
    return -1;
    800057e2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e4:	0c054163          	bltz	a0,800058a6 <sys_open+0xe4>
    800057e8:	f4c40593          	addi	a1,s0,-180
    800057ec:	4505                	li	a0,1
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	4c4080e7          	jalr	1220(ra) # 80002cb2 <argint>
    800057f6:	0a054863          	bltz	a0,800058a6 <sys_open+0xe4>

  begin_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	a2e080e7          	jalr	-1490(ra) # 80004228 <begin_op>

  if(omode & O_CREATE){
    80005802:	f4c42783          	lw	a5,-180(s0)
    80005806:	2007f793          	andi	a5,a5,512
    8000580a:	cbdd                	beqz	a5,800058c0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000580c:	4681                	li	a3,0
    8000580e:	4601                	li	a2,0
    80005810:	4589                	li	a1,2
    80005812:	f5040513          	addi	a0,s0,-176
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	972080e7          	jalr	-1678(ra) # 80005188 <create>
    8000581e:	892a                	mv	s2,a0
    if(ip == 0){
    80005820:	c959                	beqz	a0,800058b6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005822:	04491703          	lh	a4,68(s2)
    80005826:	478d                	li	a5,3
    80005828:	00f71763          	bne	a4,a5,80005836 <sys_open+0x74>
    8000582c:	04695703          	lhu	a4,70(s2)
    80005830:	47a5                	li	a5,9
    80005832:	0ce7ec63          	bltu	a5,a4,8000590a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	e02080e7          	jalr	-510(ra) # 80004638 <filealloc>
    8000583e:	89aa                	mv	s3,a0
    80005840:	10050263          	beqz	a0,80005944 <sys_open+0x182>
    80005844:	00000097          	auipc	ra,0x0
    80005848:	902080e7          	jalr	-1790(ra) # 80005146 <fdalloc>
    8000584c:	84aa                	mv	s1,a0
    8000584e:	0e054663          	bltz	a0,8000593a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	478d                	li	a5,3
    80005858:	0cf70463          	beq	a4,a5,80005920 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000585c:	4789                	li	a5,2
    8000585e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005862:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005866:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000586a:	f4c42783          	lw	a5,-180(s0)
    8000586e:	0017c713          	xori	a4,a5,1
    80005872:	8b05                	andi	a4,a4,1
    80005874:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005878:	0037f713          	andi	a4,a5,3
    8000587c:	00e03733          	snez	a4,a4
    80005880:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005884:	4007f793          	andi	a5,a5,1024
    80005888:	c791                	beqz	a5,80005894 <sys_open+0xd2>
    8000588a:	04491703          	lh	a4,68(s2)
    8000588e:	4789                	li	a5,2
    80005890:	08f70f63          	beq	a4,a5,8000592e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	082080e7          	jalr	130(ra) # 80003918 <iunlock>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	a0a080e7          	jalr	-1526(ra) # 800042a8 <end_op>

  return fd;
}
    800058a6:	8526                	mv	a0,s1
    800058a8:	70ea                	ld	ra,184(sp)
    800058aa:	744a                	ld	s0,176(sp)
    800058ac:	74aa                	ld	s1,168(sp)
    800058ae:	790a                	ld	s2,160(sp)
    800058b0:	69ea                	ld	s3,152(sp)
    800058b2:	6129                	addi	sp,sp,192
    800058b4:	8082                	ret
      end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	9f2080e7          	jalr	-1550(ra) # 800042a8 <end_op>
      return -1;
    800058be:	b7e5                	j	800058a6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058c0:	f5040513          	addi	a0,s0,-176
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	748080e7          	jalr	1864(ra) # 8000400c <namei>
    800058cc:	892a                	mv	s2,a0
    800058ce:	c905                	beqz	a0,800058fe <sys_open+0x13c>
    ilock(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	f86080e7          	jalr	-122(ra) # 80003856 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058d8:	04491703          	lh	a4,68(s2)
    800058dc:	4785                	li	a5,1
    800058de:	f4f712e3          	bne	a4,a5,80005822 <sys_open+0x60>
    800058e2:	f4c42783          	lw	a5,-180(s0)
    800058e6:	dba1                	beqz	a5,80005836 <sys_open+0x74>
      iunlockput(ip);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	1ce080e7          	jalr	462(ra) # 80003ab8 <iunlockput>
      end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	9b6080e7          	jalr	-1610(ra) # 800042a8 <end_op>
      return -1;
    800058fa:	54fd                	li	s1,-1
    800058fc:	b76d                	j	800058a6 <sys_open+0xe4>
      end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	9aa080e7          	jalr	-1622(ra) # 800042a8 <end_op>
      return -1;
    80005906:	54fd                	li	s1,-1
    80005908:	bf79                	j	800058a6 <sys_open+0xe4>
    iunlockput(ip);
    8000590a:	854a                	mv	a0,s2
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	1ac080e7          	jalr	428(ra) # 80003ab8 <iunlockput>
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	994080e7          	jalr	-1644(ra) # 800042a8 <end_op>
    return -1;
    8000591c:	54fd                	li	s1,-1
    8000591e:	b761                	j	800058a6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005920:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005924:	04691783          	lh	a5,70(s2)
    80005928:	02f99223          	sh	a5,36(s3)
    8000592c:	bf2d                	j	80005866 <sys_open+0xa4>
    itrunc(ip);
    8000592e:	854a                	mv	a0,s2
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	034080e7          	jalr	52(ra) # 80003964 <itrunc>
    80005938:	bfb1                	j	80005894 <sys_open+0xd2>
      fileclose(f);
    8000593a:	854e                	mv	a0,s3
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	db8080e7          	jalr	-584(ra) # 800046f4 <fileclose>
    iunlockput(ip);
    80005944:	854a                	mv	a0,s2
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	172080e7          	jalr	370(ra) # 80003ab8 <iunlockput>
    end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	95a080e7          	jalr	-1702(ra) # 800042a8 <end_op>
    return -1;
    80005956:	54fd                	li	s1,-1
    80005958:	b7b9                	j	800058a6 <sys_open+0xe4>

000000008000595a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000595a:	7175                	addi	sp,sp,-144
    8000595c:	e506                	sd	ra,136(sp)
    8000595e:	e122                	sd	s0,128(sp)
    80005960:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	8c6080e7          	jalr	-1850(ra) # 80004228 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000596a:	08000613          	li	a2,128
    8000596e:	f7040593          	addi	a1,s0,-144
    80005972:	4501                	li	a0,0
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	382080e7          	jalr	898(ra) # 80002cf6 <argstr>
    8000597c:	02054963          	bltz	a0,800059ae <sys_mkdir+0x54>
    80005980:	4681                	li	a3,0
    80005982:	4601                	li	a2,0
    80005984:	4585                	li	a1,1
    80005986:	f7040513          	addi	a0,s0,-144
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	7fe080e7          	jalr	2046(ra) # 80005188 <create>
    80005992:	cd11                	beqz	a0,800059ae <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	124080e7          	jalr	292(ra) # 80003ab8 <iunlockput>
  end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	90c080e7          	jalr	-1780(ra) # 800042a8 <end_op>
  return 0;
    800059a4:	4501                	li	a0,0
}
    800059a6:	60aa                	ld	ra,136(sp)
    800059a8:	640a                	ld	s0,128(sp)
    800059aa:	6149                	addi	sp,sp,144
    800059ac:	8082                	ret
    end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	8fa080e7          	jalr	-1798(ra) # 800042a8 <end_op>
    return -1;
    800059b6:	557d                	li	a0,-1
    800059b8:	b7fd                	j	800059a6 <sys_mkdir+0x4c>

00000000800059ba <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ba:	7135                	addi	sp,sp,-160
    800059bc:	ed06                	sd	ra,152(sp)
    800059be:	e922                	sd	s0,144(sp)
    800059c0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	866080e7          	jalr	-1946(ra) # 80004228 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ca:	08000613          	li	a2,128
    800059ce:	f7040593          	addi	a1,s0,-144
    800059d2:	4501                	li	a0,0
    800059d4:	ffffd097          	auipc	ra,0xffffd
    800059d8:	322080e7          	jalr	802(ra) # 80002cf6 <argstr>
    800059dc:	04054a63          	bltz	a0,80005a30 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059e0:	f6c40593          	addi	a1,s0,-148
    800059e4:	4505                	li	a0,1
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	2cc080e7          	jalr	716(ra) # 80002cb2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ee:	04054163          	bltz	a0,80005a30 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059f2:	f6840593          	addi	a1,s0,-152
    800059f6:	4509                	li	a0,2
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	2ba080e7          	jalr	698(ra) # 80002cb2 <argint>
     argint(1, &major) < 0 ||
    80005a00:	02054863          	bltz	a0,80005a30 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a04:	f6841683          	lh	a3,-152(s0)
    80005a08:	f6c41603          	lh	a2,-148(s0)
    80005a0c:	458d                	li	a1,3
    80005a0e:	f7040513          	addi	a0,s0,-144
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	776080e7          	jalr	1910(ra) # 80005188 <create>
     argint(2, &minor) < 0 ||
    80005a1a:	c919                	beqz	a0,80005a30 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	09c080e7          	jalr	156(ra) # 80003ab8 <iunlockput>
  end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	884080e7          	jalr	-1916(ra) # 800042a8 <end_op>
  return 0;
    80005a2c:	4501                	li	a0,0
    80005a2e:	a031                	j	80005a3a <sys_mknod+0x80>
    end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	878080e7          	jalr	-1928(ra) # 800042a8 <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
}
    80005a3a:	60ea                	ld	ra,152(sp)
    80005a3c:	644a                	ld	s0,144(sp)
    80005a3e:	610d                	addi	sp,sp,160
    80005a40:	8082                	ret

0000000080005a42 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a42:	7135                	addi	sp,sp,-160
    80005a44:	ed06                	sd	ra,152(sp)
    80005a46:	e922                	sd	s0,144(sp)
    80005a48:	e526                	sd	s1,136(sp)
    80005a4a:	e14a                	sd	s2,128(sp)
    80005a4c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a4e:	ffffc097          	auipc	ra,0xffffc
    80005a52:	f7a080e7          	jalr	-134(ra) # 800019c8 <myproc>
    80005a56:	892a                	mv	s2,a0
  
  begin_op();
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	7d0080e7          	jalr	2000(ra) # 80004228 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a60:	08000613          	li	a2,128
    80005a64:	f6040593          	addi	a1,s0,-160
    80005a68:	4501                	li	a0,0
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	28c080e7          	jalr	652(ra) # 80002cf6 <argstr>
    80005a72:	04054b63          	bltz	a0,80005ac8 <sys_chdir+0x86>
    80005a76:	f6040513          	addi	a0,s0,-160
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	592080e7          	jalr	1426(ra) # 8000400c <namei>
    80005a82:	84aa                	mv	s1,a0
    80005a84:	c131                	beqz	a0,80005ac8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	dd0080e7          	jalr	-560(ra) # 80003856 <ilock>
  if(ip->type != T_DIR){
    80005a8e:	04449703          	lh	a4,68(s1)
    80005a92:	4785                	li	a5,1
    80005a94:	04f71063          	bne	a4,a5,80005ad4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	e7e080e7          	jalr	-386(ra) # 80003918 <iunlock>
  iput(p->cwd);
    80005aa2:	15093503          	ld	a0,336(s2)
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	f6a080e7          	jalr	-150(ra) # 80003a10 <iput>
  end_op();
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	7fa080e7          	jalr	2042(ra) # 800042a8 <end_op>
  p->cwd = ip;
    80005ab6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aba:	4501                	li	a0,0
}
    80005abc:	60ea                	ld	ra,152(sp)
    80005abe:	644a                	ld	s0,144(sp)
    80005ac0:	64aa                	ld	s1,136(sp)
    80005ac2:	690a                	ld	s2,128(sp)
    80005ac4:	610d                	addi	sp,sp,160
    80005ac6:	8082                	ret
    end_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	7e0080e7          	jalr	2016(ra) # 800042a8 <end_op>
    return -1;
    80005ad0:	557d                	li	a0,-1
    80005ad2:	b7ed                	j	80005abc <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	fe2080e7          	jalr	-30(ra) # 80003ab8 <iunlockput>
    end_op();
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	7ca080e7          	jalr	1994(ra) # 800042a8 <end_op>
    return -1;
    80005ae6:	557d                	li	a0,-1
    80005ae8:	bfd1                	j	80005abc <sys_chdir+0x7a>

0000000080005aea <sys_exec>:

uint64
sys_exec(void)
{
    80005aea:	7145                	addi	sp,sp,-464
    80005aec:	e786                	sd	ra,456(sp)
    80005aee:	e3a2                	sd	s0,448(sp)
    80005af0:	ff26                	sd	s1,440(sp)
    80005af2:	fb4a                	sd	s2,432(sp)
    80005af4:	f74e                	sd	s3,424(sp)
    80005af6:	f352                	sd	s4,416(sp)
    80005af8:	ef56                	sd	s5,408(sp)
    80005afa:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005afc:	08000613          	li	a2,128
    80005b00:	f4040593          	addi	a1,s0,-192
    80005b04:	4501                	li	a0,0
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	1f0080e7          	jalr	496(ra) # 80002cf6 <argstr>
    return -1;
    80005b0e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b10:	0c054a63          	bltz	a0,80005be4 <sys_exec+0xfa>
    80005b14:	e3840593          	addi	a1,s0,-456
    80005b18:	4505                	li	a0,1
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	1ba080e7          	jalr	442(ra) # 80002cd4 <argaddr>
    80005b22:	0c054163          	bltz	a0,80005be4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b26:	10000613          	li	a2,256
    80005b2a:	4581                	li	a1,0
    80005b2c:	e4040513          	addi	a0,s0,-448
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	1b0080e7          	jalr	432(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b38:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b3c:	89a6                	mv	s3,s1
    80005b3e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b40:	02000a13          	li	s4,32
    80005b44:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b48:	00391513          	slli	a0,s2,0x3
    80005b4c:	e3040593          	addi	a1,s0,-464
    80005b50:	e3843783          	ld	a5,-456(s0)
    80005b54:	953e                	add	a0,a0,a5
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	0c2080e7          	jalr	194(ra) # 80002c18 <fetchaddr>
    80005b5e:	02054a63          	bltz	a0,80005b92 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b62:	e3043783          	ld	a5,-464(s0)
    80005b66:	c3b9                	beqz	a5,80005bac <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	f8c080e7          	jalr	-116(ra) # 80000af4 <kalloc>
    80005b70:	85aa                	mv	a1,a0
    80005b72:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b76:	cd11                	beqz	a0,80005b92 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b78:	6605                	lui	a2,0x1
    80005b7a:	e3043503          	ld	a0,-464(s0)
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	0ec080e7          	jalr	236(ra) # 80002c6a <fetchstr>
    80005b86:	00054663          	bltz	a0,80005b92 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b8a:	0905                	addi	s2,s2,1
    80005b8c:	09a1                	addi	s3,s3,8
    80005b8e:	fb491be3          	bne	s2,s4,80005b44 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b92:	10048913          	addi	s2,s1,256
    80005b96:	6088                	ld	a0,0(s1)
    80005b98:	c529                	beqz	a0,80005be2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b9a:	ffffb097          	auipc	ra,0xffffb
    80005b9e:	e5e080e7          	jalr	-418(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	04a1                	addi	s1,s1,8
    80005ba4:	ff2499e3          	bne	s1,s2,80005b96 <sys_exec+0xac>
  return -1;
    80005ba8:	597d                	li	s2,-1
    80005baa:	a82d                	j	80005be4 <sys_exec+0xfa>
      argv[i] = 0;
    80005bac:	0a8e                	slli	s5,s5,0x3
    80005bae:	fc040793          	addi	a5,s0,-64
    80005bb2:	9abe                	add	s5,s5,a5
    80005bb4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb8:	e4040593          	addi	a1,s0,-448
    80005bbc:	f4040513          	addi	a0,s0,-192
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	194080e7          	jalr	404(ra) # 80004d54 <exec>
    80005bc8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bca:	10048993          	addi	s3,s1,256
    80005bce:	6088                	ld	a0,0(s1)
    80005bd0:	c911                	beqz	a0,80005be4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	e26080e7          	jalr	-474(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	04a1                	addi	s1,s1,8
    80005bdc:	ff3499e3          	bne	s1,s3,80005bce <sys_exec+0xe4>
    80005be0:	a011                	j	80005be4 <sys_exec+0xfa>
  return -1;
    80005be2:	597d                	li	s2,-1
}
    80005be4:	854a                	mv	a0,s2
    80005be6:	60be                	ld	ra,456(sp)
    80005be8:	641e                	ld	s0,448(sp)
    80005bea:	74fa                	ld	s1,440(sp)
    80005bec:	795a                	ld	s2,432(sp)
    80005bee:	79ba                	ld	s3,424(sp)
    80005bf0:	7a1a                	ld	s4,416(sp)
    80005bf2:	6afa                	ld	s5,408(sp)
    80005bf4:	6179                	addi	sp,sp,464
    80005bf6:	8082                	ret

0000000080005bf8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf8:	7139                	addi	sp,sp,-64
    80005bfa:	fc06                	sd	ra,56(sp)
    80005bfc:	f822                	sd	s0,48(sp)
    80005bfe:	f426                	sd	s1,40(sp)
    80005c00:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	dc6080e7          	jalr	-570(ra) # 800019c8 <myproc>
    80005c0a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c0c:	fd840593          	addi	a1,s0,-40
    80005c10:	4501                	li	a0,0
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	0c2080e7          	jalr	194(ra) # 80002cd4 <argaddr>
    return -1;
    80005c1a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c1c:	0e054063          	bltz	a0,80005cfc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c20:	fc840593          	addi	a1,s0,-56
    80005c24:	fd040513          	addi	a0,s0,-48
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	dfc080e7          	jalr	-516(ra) # 80004a24 <pipealloc>
    return -1;
    80005c30:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c32:	0c054563          	bltz	a0,80005cfc <sys_pipe+0x104>
  fd0 = -1;
    80005c36:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c3a:	fd043503          	ld	a0,-48(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	508080e7          	jalr	1288(ra) # 80005146 <fdalloc>
    80005c46:	fca42223          	sw	a0,-60(s0)
    80005c4a:	08054c63          	bltz	a0,80005ce2 <sys_pipe+0xea>
    80005c4e:	fc843503          	ld	a0,-56(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	4f4080e7          	jalr	1268(ra) # 80005146 <fdalloc>
    80005c5a:	fca42023          	sw	a0,-64(s0)
    80005c5e:	06054863          	bltz	a0,80005cce <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c62:	4691                	li	a3,4
    80005c64:	fc440613          	addi	a2,s0,-60
    80005c68:	fd843583          	ld	a1,-40(s0)
    80005c6c:	68a8                	ld	a0,80(s1)
    80005c6e:	ffffc097          	auipc	ra,0xffffc
    80005c72:	a04080e7          	jalr	-1532(ra) # 80001672 <copyout>
    80005c76:	02054063          	bltz	a0,80005c96 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c7a:	4691                	li	a3,4
    80005c7c:	fc040613          	addi	a2,s0,-64
    80005c80:	fd843583          	ld	a1,-40(s0)
    80005c84:	0591                	addi	a1,a1,4
    80005c86:	68a8                	ld	a0,80(s1)
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	9ea080e7          	jalr	-1558(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c90:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c92:	06055563          	bgez	a0,80005cfc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c96:	fc442783          	lw	a5,-60(s0)
    80005c9a:	07e9                	addi	a5,a5,26
    80005c9c:	078e                	slli	a5,a5,0x3
    80005c9e:	97a6                	add	a5,a5,s1
    80005ca0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ca4:	fc042503          	lw	a0,-64(s0)
    80005ca8:	0569                	addi	a0,a0,26
    80005caa:	050e                	slli	a0,a0,0x3
    80005cac:	9526                	add	a0,a0,s1
    80005cae:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cb2:	fd043503          	ld	a0,-48(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	a3e080e7          	jalr	-1474(ra) # 800046f4 <fileclose>
    fileclose(wf);
    80005cbe:	fc843503          	ld	a0,-56(s0)
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	a32080e7          	jalr	-1486(ra) # 800046f4 <fileclose>
    return -1;
    80005cca:	57fd                	li	a5,-1
    80005ccc:	a805                	j	80005cfc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cce:	fc442783          	lw	a5,-60(s0)
    80005cd2:	0007c863          	bltz	a5,80005ce2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cd6:	01a78513          	addi	a0,a5,26
    80005cda:	050e                	slli	a0,a0,0x3
    80005cdc:	9526                	add	a0,a0,s1
    80005cde:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ce2:	fd043503          	ld	a0,-48(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a0e080e7          	jalr	-1522(ra) # 800046f4 <fileclose>
    fileclose(wf);
    80005cee:	fc843503          	ld	a0,-56(s0)
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	a02080e7          	jalr	-1534(ra) # 800046f4 <fileclose>
    return -1;
    80005cfa:	57fd                	li	a5,-1
}
    80005cfc:	853e                	mv	a0,a5
    80005cfe:	70e2                	ld	ra,56(sp)
    80005d00:	7442                	ld	s0,48(sp)
    80005d02:	74a2                	ld	s1,40(sp)
    80005d04:	6121                	addi	sp,sp,64
    80005d06:	8082                	ret
	...

0000000080005d10 <kernelvec>:
    80005d10:	7111                	addi	sp,sp,-256
    80005d12:	e006                	sd	ra,0(sp)
    80005d14:	e40a                	sd	sp,8(sp)
    80005d16:	e80e                	sd	gp,16(sp)
    80005d18:	ec12                	sd	tp,24(sp)
    80005d1a:	f016                	sd	t0,32(sp)
    80005d1c:	f41a                	sd	t1,40(sp)
    80005d1e:	f81e                	sd	t2,48(sp)
    80005d20:	fc22                	sd	s0,56(sp)
    80005d22:	e0a6                	sd	s1,64(sp)
    80005d24:	e4aa                	sd	a0,72(sp)
    80005d26:	e8ae                	sd	a1,80(sp)
    80005d28:	ecb2                	sd	a2,88(sp)
    80005d2a:	f0b6                	sd	a3,96(sp)
    80005d2c:	f4ba                	sd	a4,104(sp)
    80005d2e:	f8be                	sd	a5,112(sp)
    80005d30:	fcc2                	sd	a6,120(sp)
    80005d32:	e146                	sd	a7,128(sp)
    80005d34:	e54a                	sd	s2,136(sp)
    80005d36:	e94e                	sd	s3,144(sp)
    80005d38:	ed52                	sd	s4,152(sp)
    80005d3a:	f156                	sd	s5,160(sp)
    80005d3c:	f55a                	sd	s6,168(sp)
    80005d3e:	f95e                	sd	s7,176(sp)
    80005d40:	fd62                	sd	s8,184(sp)
    80005d42:	e1e6                	sd	s9,192(sp)
    80005d44:	e5ea                	sd	s10,200(sp)
    80005d46:	e9ee                	sd	s11,208(sp)
    80005d48:	edf2                	sd	t3,216(sp)
    80005d4a:	f1f6                	sd	t4,224(sp)
    80005d4c:	f5fa                	sd	t5,232(sp)
    80005d4e:	f9fe                	sd	t6,240(sp)
    80005d50:	d95fc0ef          	jal	ra,80002ae4 <kerneltrap>
    80005d54:	6082                	ld	ra,0(sp)
    80005d56:	6122                	ld	sp,8(sp)
    80005d58:	61c2                	ld	gp,16(sp)
    80005d5a:	7282                	ld	t0,32(sp)
    80005d5c:	7322                	ld	t1,40(sp)
    80005d5e:	73c2                	ld	t2,48(sp)
    80005d60:	7462                	ld	s0,56(sp)
    80005d62:	6486                	ld	s1,64(sp)
    80005d64:	6526                	ld	a0,72(sp)
    80005d66:	65c6                	ld	a1,80(sp)
    80005d68:	6666                	ld	a2,88(sp)
    80005d6a:	7686                	ld	a3,96(sp)
    80005d6c:	7726                	ld	a4,104(sp)
    80005d6e:	77c6                	ld	a5,112(sp)
    80005d70:	7866                	ld	a6,120(sp)
    80005d72:	688a                	ld	a7,128(sp)
    80005d74:	692a                	ld	s2,136(sp)
    80005d76:	69ca                	ld	s3,144(sp)
    80005d78:	6a6a                	ld	s4,152(sp)
    80005d7a:	7a8a                	ld	s5,160(sp)
    80005d7c:	7b2a                	ld	s6,168(sp)
    80005d7e:	7bca                	ld	s7,176(sp)
    80005d80:	7c6a                	ld	s8,184(sp)
    80005d82:	6c8e                	ld	s9,192(sp)
    80005d84:	6d2e                	ld	s10,200(sp)
    80005d86:	6dce                	ld	s11,208(sp)
    80005d88:	6e6e                	ld	t3,216(sp)
    80005d8a:	7e8e                	ld	t4,224(sp)
    80005d8c:	7f2e                	ld	t5,232(sp)
    80005d8e:	7fce                	ld	t6,240(sp)
    80005d90:	6111                	addi	sp,sp,256
    80005d92:	10200073          	sret
    80005d96:	00000013          	nop
    80005d9a:	00000013          	nop
    80005d9e:	0001                	nop

0000000080005da0 <timervec>:
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	e10c                	sd	a1,0(a0)
    80005da6:	e510                	sd	a2,8(a0)
    80005da8:	e914                	sd	a3,16(a0)
    80005daa:	6d0c                	ld	a1,24(a0)
    80005dac:	7110                	ld	a2,32(a0)
    80005dae:	6194                	ld	a3,0(a1)
    80005db0:	96b2                	add	a3,a3,a2
    80005db2:	e194                	sd	a3,0(a1)
    80005db4:	4589                	li	a1,2
    80005db6:	14459073          	csrw	sip,a1
    80005dba:	6914                	ld	a3,16(a0)
    80005dbc:	6510                	ld	a2,8(a0)
    80005dbe:	610c                	ld	a1,0(a0)
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	30200073          	mret
	...

0000000080005dca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dca:	1141                	addi	sp,sp,-16
    80005dcc:	e422                	sd	s0,8(sp)
    80005dce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dd0:	0c0007b7          	lui	a5,0xc000
    80005dd4:	4705                	li	a4,1
    80005dd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dd8:	c3d8                	sw	a4,4(a5)
}
    80005dda:	6422                	ld	s0,8(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret

0000000080005de0 <plicinithart>:

void
plicinithart(void)
{
    80005de0:	1141                	addi	sp,sp,-16
    80005de2:	e406                	sd	ra,8(sp)
    80005de4:	e022                	sd	s0,0(sp)
    80005de6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	bb4080e7          	jalr	-1100(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005df0:	0085171b          	slliw	a4,a0,0x8
    80005df4:	0c0027b7          	lui	a5,0xc002
    80005df8:	97ba                	add	a5,a5,a4
    80005dfa:	40200713          	li	a4,1026
    80005dfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e02:	00d5151b          	slliw	a0,a0,0xd
    80005e06:	0c2017b7          	lui	a5,0xc201
    80005e0a:	953e                	add	a0,a0,a5
    80005e0c:	00052023          	sw	zero,0(a0)
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret

0000000080005e18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e18:	1141                	addi	sp,sp,-16
    80005e1a:	e406                	sd	ra,8(sp)
    80005e1c:	e022                	sd	s0,0(sp)
    80005e1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	b7c080e7          	jalr	-1156(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e28:	00d5179b          	slliw	a5,a0,0xd
    80005e2c:	0c201537          	lui	a0,0xc201
    80005e30:	953e                	add	a0,a0,a5
  return irq;
}
    80005e32:	4148                	lw	a0,4(a0)
    80005e34:	60a2                	ld	ra,8(sp)
    80005e36:	6402                	ld	s0,0(sp)
    80005e38:	0141                	addi	sp,sp,16
    80005e3a:	8082                	ret

0000000080005e3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e3c:	1101                	addi	sp,sp,-32
    80005e3e:	ec06                	sd	ra,24(sp)
    80005e40:	e822                	sd	s0,16(sp)
    80005e42:	e426                	sd	s1,8(sp)
    80005e44:	1000                	addi	s0,sp,32
    80005e46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	b54080e7          	jalr	-1196(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e50:	00d5151b          	slliw	a0,a0,0xd
    80005e54:	0c2017b7          	lui	a5,0xc201
    80005e58:	97aa                	add	a5,a5,a0
    80005e5a:	c3c4                	sw	s1,4(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret

0000000080005e66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e66:	1141                	addi	sp,sp,-16
    80005e68:	e406                	sd	ra,8(sp)
    80005e6a:	e022                	sd	s0,0(sp)
    80005e6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e6e:	479d                	li	a5,7
    80005e70:	06a7c963          	blt	a5,a0,80005ee2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e74:	0001d797          	auipc	a5,0x1d
    80005e78:	18c78793          	addi	a5,a5,396 # 80023000 <disk>
    80005e7c:	00a78733          	add	a4,a5,a0
    80005e80:	6789                	lui	a5,0x2
    80005e82:	97ba                	add	a5,a5,a4
    80005e84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e88:	e7ad                	bnez	a5,80005ef2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e8a:	00451793          	slli	a5,a0,0x4
    80005e8e:	0001f717          	auipc	a4,0x1f
    80005e92:	17270713          	addi	a4,a4,370 # 80025000 <disk+0x2000>
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e9e:	6314                	ld	a3,0(a4)
    80005ea0:	96be                	add	a3,a3,a5
    80005ea2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ea6:	6314                	ld	a3,0(a4)
    80005ea8:	96be                	add	a3,a3,a5
    80005eaa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eae:	6318                	ld	a4,0(a4)
    80005eb0:	97ba                	add	a5,a5,a4
    80005eb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005eb6:	0001d797          	auipc	a5,0x1d
    80005eba:	14a78793          	addi	a5,a5,330 # 80023000 <disk>
    80005ebe:	97aa                	add	a5,a5,a0
    80005ec0:	6509                	lui	a0,0x2
    80005ec2:	953e                	add	a0,a0,a5
    80005ec4:	4785                	li	a5,1
    80005ec6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eca:	0001f517          	auipc	a0,0x1f
    80005ece:	14e50513          	addi	a0,a0,334 # 80025018 <disk+0x2018>
    80005ed2:	ffffc097          	auipc	ra,0xffffc
    80005ed6:	55c080e7          	jalr	1372(ra) # 8000242e <wakeup>
}
    80005eda:	60a2                	ld	ra,8(sp)
    80005edc:	6402                	ld	s0,0(sp)
    80005ede:	0141                	addi	sp,sp,16
    80005ee0:	8082                	ret
    panic("free_desc 1");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	89e50513          	addi	a0,a0,-1890 # 80008780 <syscalls+0x328>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	89e50513          	addi	a0,a0,-1890 # 80008790 <syscalls+0x338>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	644080e7          	jalr	1604(ra) # 8000053e <panic>

0000000080005f02 <virtio_disk_init>:
{
    80005f02:	1101                	addi	sp,sp,-32
    80005f04:	ec06                	sd	ra,24(sp)
    80005f06:	e822                	sd	s0,16(sp)
    80005f08:	e426                	sd	s1,8(sp)
    80005f0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f0c:	00003597          	auipc	a1,0x3
    80005f10:	89458593          	addi	a1,a1,-1900 # 800087a0 <syscalls+0x348>
    80005f14:	0001f517          	auipc	a0,0x1f
    80005f18:	21450513          	addi	a0,a0,532 # 80025128 <disk+0x2128>
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	c38080e7          	jalr	-968(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f24:	100017b7          	lui	a5,0x10001
    80005f28:	4398                	lw	a4,0(a5)
    80005f2a:	2701                	sext.w	a4,a4
    80005f2c:	747277b7          	lui	a5,0x74727
    80005f30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f34:	0ef71163          	bne	a4,a5,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	43dc                	lw	a5,4(a5)
    80005f3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f40:	4705                	li	a4,1
    80005f42:	0ce79a63          	bne	a5,a4,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f46:	100017b7          	lui	a5,0x10001
    80005f4a:	479c                	lw	a5,8(a5)
    80005f4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f4e:	4709                	li	a4,2
    80005f50:	0ce79363          	bne	a5,a4,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f54:	100017b7          	lui	a5,0x10001
    80005f58:	47d8                	lw	a4,12(a5)
    80005f5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f5c:	554d47b7          	lui	a5,0x554d4
    80005f60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f64:	0af71963          	bne	a4,a5,80006016 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f68:	100017b7          	lui	a5,0x10001
    80005f6c:	4705                	li	a4,1
    80005f6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f70:	470d                	li	a4,3
    80005f72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f76:	c7ffe737          	lui	a4,0xc7ffe
    80005f7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f80:	2701                	sext.w	a4,a4
    80005f82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f84:	472d                	li	a4,11
    80005f86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f88:	473d                	li	a4,15
    80005f8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f8c:	6705                	lui	a4,0x1
    80005f8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f94:	5bdc                	lw	a5,52(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f98:	c7d9                	beqz	a5,80006026 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f9a:	471d                	li	a4,7
    80005f9c:	08f77d63          	bgeu	a4,a5,80006036 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa0:	100014b7          	lui	s1,0x10001
    80005fa4:	47a1                	li	a5,8
    80005fa6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fa8:	6609                	lui	a2,0x2
    80005faa:	4581                	li	a1,0
    80005fac:	0001d517          	auipc	a0,0x1d
    80005fb0:	05450513          	addi	a0,a0,84 # 80023000 <disk>
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	d2c080e7          	jalr	-724(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fbc:	0001d717          	auipc	a4,0x1d
    80005fc0:	04470713          	addi	a4,a4,68 # 80023000 <disk>
    80005fc4:	00c75793          	srli	a5,a4,0xc
    80005fc8:	2781                	sext.w	a5,a5
    80005fca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fcc:	0001f797          	auipc	a5,0x1f
    80005fd0:	03478793          	addi	a5,a5,52 # 80025000 <disk+0x2000>
    80005fd4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fd6:	0001d717          	auipc	a4,0x1d
    80005fda:	0aa70713          	addi	a4,a4,170 # 80023080 <disk+0x80>
    80005fde:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fe0:	0001e717          	auipc	a4,0x1e
    80005fe4:	02070713          	addi	a4,a4,32 # 80024000 <disk+0x1000>
    80005fe8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fea:	4705                	li	a4,1
    80005fec:	00e78c23          	sb	a4,24(a5)
    80005ff0:	00e78ca3          	sb	a4,25(a5)
    80005ff4:	00e78d23          	sb	a4,26(a5)
    80005ff8:	00e78da3          	sb	a4,27(a5)
    80005ffc:	00e78e23          	sb	a4,28(a5)
    80006000:	00e78ea3          	sb	a4,29(a5)
    80006004:	00e78f23          	sb	a4,30(a5)
    80006008:	00e78fa3          	sb	a4,31(a5)
}
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	64a2                	ld	s1,8(sp)
    80006012:	6105                	addi	sp,sp,32
    80006014:	8082                	ret
    panic("could not find virtio disk");
    80006016:	00002517          	auipc	a0,0x2
    8000601a:	79a50513          	addi	a0,a0,1946 # 800087b0 <syscalls+0x358>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006026:	00002517          	auipc	a0,0x2
    8000602a:	7aa50513          	addi	a0,a0,1962 # 800087d0 <syscalls+0x378>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006036:	00002517          	auipc	a0,0x2
    8000603a:	7ba50513          	addi	a0,a0,1978 # 800087f0 <syscalls+0x398>
    8000603e:	ffffa097          	auipc	ra,0xffffa
    80006042:	500080e7          	jalr	1280(ra) # 8000053e <panic>

0000000080006046 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006046:	7159                	addi	sp,sp,-112
    80006048:	f486                	sd	ra,104(sp)
    8000604a:	f0a2                	sd	s0,96(sp)
    8000604c:	eca6                	sd	s1,88(sp)
    8000604e:	e8ca                	sd	s2,80(sp)
    80006050:	e4ce                	sd	s3,72(sp)
    80006052:	e0d2                	sd	s4,64(sp)
    80006054:	fc56                	sd	s5,56(sp)
    80006056:	f85a                	sd	s6,48(sp)
    80006058:	f45e                	sd	s7,40(sp)
    8000605a:	f062                	sd	s8,32(sp)
    8000605c:	ec66                	sd	s9,24(sp)
    8000605e:	e86a                	sd	s10,16(sp)
    80006060:	1880                	addi	s0,sp,112
    80006062:	892a                	mv	s2,a0
    80006064:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006066:	00c52c83          	lw	s9,12(a0)
    8000606a:	001c9c9b          	slliw	s9,s9,0x1
    8000606e:	1c82                	slli	s9,s9,0x20
    80006070:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006074:	0001f517          	auipc	a0,0x1f
    80006078:	0b450513          	addi	a0,a0,180 # 80025128 <disk+0x2128>
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006084:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006086:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006088:	0001db97          	auipc	s7,0x1d
    8000608c:	f78b8b93          	addi	s7,s7,-136 # 80023000 <disk>
    80006090:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006092:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006094:	8a4e                	mv	s4,s3
    80006096:	a051                	j	8000611a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006098:	00fb86b3          	add	a3,s7,a5
    8000609c:	96da                	add	a3,a3,s6
    8000609e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060a4:	0207c563          	bltz	a5,800060ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060a8:	2485                	addiw	s1,s1,1
    800060aa:	0711                	addi	a4,a4,4
    800060ac:	25548063          	beq	s1,s5,800062ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060b2:	0001f697          	auipc	a3,0x1f
    800060b6:	f6668693          	addi	a3,a3,-154 # 80025018 <disk+0x2018>
    800060ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060bc:	0006c583          	lbu	a1,0(a3)
    800060c0:	fde1                	bnez	a1,80006098 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	0685                	addi	a3,a3,1
    800060c6:	ff879be3          	bne	a5,s8,800060bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ca:	57fd                	li	a5,-1
    800060cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ce:	02905a63          	blez	s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d2:	f9042503          	lw	a0,-112(s0)
    800060d6:	00000097          	auipc	ra,0x0
    800060da:	d90080e7          	jalr	-624(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060de:	4785                	li	a5,1
    800060e0:	0297d163          	bge	a5,s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e4:	f9442503          	lw	a0,-108(s0)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	d7e080e7          	jalr	-642(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	4789                	li	a5,2
    800060f2:	0097d863          	bge	a5,s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060f6:	f9842503          	lw	a0,-104(s0)
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	d6c080e7          	jalr	-660(ra) # 80005e66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006102:	0001f597          	auipc	a1,0x1f
    80006106:	02658593          	addi	a1,a1,38 # 80025128 <disk+0x2128>
    8000610a:	0001f517          	auipc	a0,0x1f
    8000610e:	f0e50513          	addi	a0,a0,-242 # 80025018 <disk+0x2018>
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	190080e7          	jalr	400(ra) # 800022a2 <sleep>
  for(int i = 0; i < 3; i++){
    8000611a:	f9040713          	addi	a4,s0,-112
    8000611e:	84ce                	mv	s1,s3
    80006120:	bf41                	j	800060b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006122:	20058713          	addi	a4,a1,512
    80006126:	00471693          	slli	a3,a4,0x4
    8000612a:	0001d717          	auipc	a4,0x1d
    8000612e:	ed670713          	addi	a4,a4,-298 # 80023000 <disk>
    80006132:	9736                	add	a4,a4,a3
    80006134:	4685                	li	a3,1
    80006136:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000613a:	20058713          	addi	a4,a1,512
    8000613e:	00471693          	slli	a3,a4,0x4
    80006142:	0001d717          	auipc	a4,0x1d
    80006146:	ebe70713          	addi	a4,a4,-322 # 80023000 <disk>
    8000614a:	9736                	add	a4,a4,a3
    8000614c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006150:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006154:	7679                	lui	a2,0xffffe
    80006156:	963e                	add	a2,a2,a5
    80006158:	0001f697          	auipc	a3,0x1f
    8000615c:	ea868693          	addi	a3,a3,-344 # 80025000 <disk+0x2000>
    80006160:	6298                	ld	a4,0(a3)
    80006162:	9732                	add	a4,a4,a2
    80006164:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006166:	6298                	ld	a4,0(a3)
    80006168:	9732                	add	a4,a4,a2
    8000616a:	4541                	li	a0,16
    8000616c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000616e:	6298                	ld	a4,0(a3)
    80006170:	9732                	add	a4,a4,a2
    80006172:	4505                	li	a0,1
    80006174:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f9442703          	lw	a4,-108(s0)
    8000617c:	6288                	ld	a0,0(a3)
    8000617e:	962a                	add	a2,a2,a0
    80006180:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	6290                	ld	a2,0(a3)
    80006188:	963a                	add	a2,a2,a4
    8000618a:	05890513          	addi	a0,s2,88
    8000618e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006190:	6294                	ld	a3,0(a3)
    80006192:	96ba                	add	a3,a3,a4
    80006194:	40000613          	li	a2,1024
    80006198:	c690                	sw	a2,8(a3)
  if(write)
    8000619a:	140d0063          	beqz	s10,800062da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000619e:	0001f697          	auipc	a3,0x1f
    800061a2:	e626b683          	ld	a3,-414(a3) # 80025000 <disk+0x2000>
    800061a6:	96ba                	add	a3,a3,a4
    800061a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ac:	0001d817          	auipc	a6,0x1d
    800061b0:	e5480813          	addi	a6,a6,-428 # 80023000 <disk>
    800061b4:	0001f517          	auipc	a0,0x1f
    800061b8:	e4c50513          	addi	a0,a0,-436 # 80025000 <disk+0x2000>
    800061bc:	6114                	ld	a3,0(a0)
    800061be:	96ba                	add	a3,a3,a4
    800061c0:	00c6d603          	lhu	a2,12(a3)
    800061c4:	00166613          	ori	a2,a2,1
    800061c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061cc:	f9842683          	lw	a3,-104(s0)
    800061d0:	6110                	ld	a2,0(a0)
    800061d2:	9732                	add	a4,a4,a2
    800061d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061d8:	20058613          	addi	a2,a1,512
    800061dc:	0612                	slli	a2,a2,0x4
    800061de:	9642                	add	a2,a2,a6
    800061e0:	577d                	li	a4,-1
    800061e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061e6:	00469713          	slli	a4,a3,0x4
    800061ea:	6114                	ld	a3,0(a0)
    800061ec:	96ba                	add	a3,a3,a4
    800061ee:	03078793          	addi	a5,a5,48
    800061f2:	97c2                	add	a5,a5,a6
    800061f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061f6:	611c                	ld	a5,0(a0)
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	4685                	li	a3,1
    800061fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061fe:	611c                	ld	a5,0(a0)
    80006200:	97ba                	add	a5,a5,a4
    80006202:	4809                	li	a6,2
    80006204:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006208:	611c                	ld	a5,0(a0)
    8000620a:	973e                	add	a4,a4,a5
    8000620c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006210:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006214:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006218:	6518                	ld	a4,8(a0)
    8000621a:	00275783          	lhu	a5,2(a4)
    8000621e:	8b9d                	andi	a5,a5,7
    80006220:	0786                	slli	a5,a5,0x1
    80006222:	97ba                	add	a5,a5,a4
    80006224:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000622c:	6518                	ld	a4,8(a0)
    8000622e:	00275783          	lhu	a5,2(a4)
    80006232:	2785                	addiw	a5,a5,1
    80006234:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006238:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006244:	00492703          	lw	a4,4(s2)
    80006248:	4785                	li	a5,1
    8000624a:	02f71163          	bne	a4,a5,8000626c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000624e:	0001f997          	auipc	s3,0x1f
    80006252:	eda98993          	addi	s3,s3,-294 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006256:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006258:	85ce                	mv	a1,s3
    8000625a:	854a                	mv	a0,s2
    8000625c:	ffffc097          	auipc	ra,0xffffc
    80006260:	046080e7          	jalr	70(ra) # 800022a2 <sleep>
  while(b->disk == 1) {
    80006264:	00492783          	lw	a5,4(s2)
    80006268:	fe9788e3          	beq	a5,s1,80006258 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000626c:	f9042903          	lw	s2,-112(s0)
    80006270:	20090793          	addi	a5,s2,512
    80006274:	00479713          	slli	a4,a5,0x4
    80006278:	0001d797          	auipc	a5,0x1d
    8000627c:	d8878793          	addi	a5,a5,-632 # 80023000 <disk>
    80006280:	97ba                	add	a5,a5,a4
    80006282:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006286:	0001f997          	auipc	s3,0x1f
    8000628a:	d7a98993          	addi	s3,s3,-646 # 80025000 <disk+0x2000>
    8000628e:	00491713          	slli	a4,s2,0x4
    80006292:	0009b783          	ld	a5,0(s3)
    80006296:	97ba                	add	a5,a5,a4
    80006298:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000629c:	854a                	mv	a0,s2
    8000629e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062a2:	00000097          	auipc	ra,0x0
    800062a6:	bc4080e7          	jalr	-1084(ra) # 80005e66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062aa:	8885                	andi	s1,s1,1
    800062ac:	f0ed                	bnez	s1,8000628e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ae:	0001f517          	auipc	a0,0x1f
    800062b2:	e7a50513          	addi	a0,a0,-390 # 80025128 <disk+0x2128>
    800062b6:	ffffb097          	auipc	ra,0xffffb
    800062ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
}
    800062be:	70a6                	ld	ra,104(sp)
    800062c0:	7406                	ld	s0,96(sp)
    800062c2:	64e6                	ld	s1,88(sp)
    800062c4:	6946                	ld	s2,80(sp)
    800062c6:	69a6                	ld	s3,72(sp)
    800062c8:	6a06                	ld	s4,64(sp)
    800062ca:	7ae2                	ld	s5,56(sp)
    800062cc:	7b42                	ld	s6,48(sp)
    800062ce:	7ba2                	ld	s7,40(sp)
    800062d0:	7c02                	ld	s8,32(sp)
    800062d2:	6ce2                	ld	s9,24(sp)
    800062d4:	6d42                	ld	s10,16(sp)
    800062d6:	6165                	addi	sp,sp,112
    800062d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062da:	0001f697          	auipc	a3,0x1f
    800062de:	d266b683          	ld	a3,-730(a3) # 80025000 <disk+0x2000>
    800062e2:	96ba                	add	a3,a3,a4
    800062e4:	4609                	li	a2,2
    800062e6:	00c69623          	sh	a2,12(a3)
    800062ea:	b5c9                	j	800061ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062ec:	f9042583          	lw	a1,-112(s0)
    800062f0:	20058793          	addi	a5,a1,512
    800062f4:	0792                	slli	a5,a5,0x4
    800062f6:	0001d517          	auipc	a0,0x1d
    800062fa:	db250513          	addi	a0,a0,-590 # 800230a8 <disk+0xa8>
    800062fe:	953e                	add	a0,a0,a5
  if(write)
    80006300:	e20d11e3          	bnez	s10,80006122 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006304:	20058713          	addi	a4,a1,512
    80006308:	00471693          	slli	a3,a4,0x4
    8000630c:	0001d717          	auipc	a4,0x1d
    80006310:	cf470713          	addi	a4,a4,-780 # 80023000 <disk>
    80006314:	9736                	add	a4,a4,a3
    80006316:	0a072423          	sw	zero,168(a4)
    8000631a:	b505                	j	8000613a <virtio_disk_rw+0xf4>

000000008000631c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	e04a                	sd	s2,0(sp)
    80006326:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006328:	0001f517          	auipc	a0,0x1f
    8000632c:	e0050513          	addi	a0,a0,-512 # 80025128 <disk+0x2128>
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006338:	10001737          	lui	a4,0x10001
    8000633c:	533c                	lw	a5,96(a4)
    8000633e:	8b8d                	andi	a5,a5,3
    80006340:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006342:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006346:	0001f797          	auipc	a5,0x1f
    8000634a:	cba78793          	addi	a5,a5,-838 # 80025000 <disk+0x2000>
    8000634e:	6b94                	ld	a3,16(a5)
    80006350:	0207d703          	lhu	a4,32(a5)
    80006354:	0026d783          	lhu	a5,2(a3)
    80006358:	06f70163          	beq	a4,a5,800063ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000635c:	0001d917          	auipc	s2,0x1d
    80006360:	ca490913          	addi	s2,s2,-860 # 80023000 <disk>
    80006364:	0001f497          	auipc	s1,0x1f
    80006368:	c9c48493          	addi	s1,s1,-868 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000636c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006370:	6898                	ld	a4,16(s1)
    80006372:	0204d783          	lhu	a5,32(s1)
    80006376:	8b9d                	andi	a5,a5,7
    80006378:	078e                	slli	a5,a5,0x3
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000637e:	20078713          	addi	a4,a5,512
    80006382:	0712                	slli	a4,a4,0x4
    80006384:	974a                	add	a4,a4,s2
    80006386:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000638a:	e731                	bnez	a4,800063d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000638c:	20078793          	addi	a5,a5,512
    80006390:	0792                	slli	a5,a5,0x4
    80006392:	97ca                	add	a5,a5,s2
    80006394:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006396:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000639a:	ffffc097          	auipc	ra,0xffffc
    8000639e:	094080e7          	jalr	148(ra) # 8000242e <wakeup>

    disk.used_idx += 1;
    800063a2:	0204d783          	lhu	a5,32(s1)
    800063a6:	2785                	addiw	a5,a5,1
    800063a8:	17c2                	slli	a5,a5,0x30
    800063aa:	93c1                	srli	a5,a5,0x30
    800063ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063b0:	6898                	ld	a4,16(s1)
    800063b2:	00275703          	lhu	a4,2(a4)
    800063b6:	faf71be3          	bne	a4,a5,8000636c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063ba:	0001f517          	auipc	a0,0x1f
    800063be:	d6e50513          	addi	a0,a0,-658 # 80025128 <disk+0x2128>
    800063c2:	ffffb097          	auipc	ra,0xffffb
    800063c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
}
    800063ca:	60e2                	ld	ra,24(sp)
    800063cc:	6442                	ld	s0,16(sp)
    800063ce:	64a2                	ld	s1,8(sp)
    800063d0:	6902                	ld	s2,0(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret
      panic("virtio_disk_intr status");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	43a50513          	addi	a0,a0,1082 # 80008810 <syscalls+0x3b8>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
