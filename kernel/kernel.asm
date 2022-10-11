
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8a070713          	addi	a4,a4,-1888 # 800088f0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	c9e78793          	addi	a5,a5,-866 # 80005d00 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbe9f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4e2080e7          	jalr	1250(ra) # 8000260c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	81c080e7          	jalr	-2020(ra) # 800019dc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	28e080e7          	jalr	654(ra) # 80002456 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fd8080e7          	jalr	-40(ra) # 800021ae <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3a4080e7          	jalr	932(ra) # 800025b6 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	370080e7          	jalr	880(ra) # 80002662 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dcc080e7          	jalr	-564(ra) # 80002212 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	35078793          	addi	a5,a5,848 # 800217c8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
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
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
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
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5a07a223          	sw	zero,1444(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	32f72823          	sw	a5,816(a4) # 800088b0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	534dad83          	lw	s11,1332(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4de50513          	addi	a0,a0,1246 # 80010ad8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	38050513          	addi	a0,a0,896 # 80010ad8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	36448493          	addi	s1,s1,868 # 80010ad8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	32450513          	addi	a0,a0,804 # 80010af8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0b07a783          	lw	a5,176(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0807b783          	ld	a5,128(a5) # 800088b8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	08073703          	ld	a4,128(a4) # 800088c0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	296a0a13          	addi	s4,s4,662 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	04e48493          	addi	s1,s1,78 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	04e98993          	addi	s3,s3,78 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	97e080e7          	jalr	-1666(ra) # 80002212 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	22850513          	addi	a0,a0,552 # 80010af8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	fd07a783          	lw	a5,-48(a5) # 800088b0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	fd673703          	ld	a4,-42(a4) # 800088c0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fc67b783          	ld	a5,-58(a5) # 800088b8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	1fa98993          	addi	s3,s3,506 # 80010af8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fb248493          	addi	s1,s1,-78 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fb290913          	addi	s2,s2,-78 # 800088c0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	890080e7          	jalr	-1904(ra) # 800021ae <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1c448493          	addi	s1,s1,452 # 80010af8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f6e7bc23          	sd	a4,-136(a5) # 800088c0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	13e48493          	addi	s1,s1,318 # 80010af8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	f6478793          	addi	a5,a5,-156 # 80022960 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	11490913          	addi	s2,s2,276 # 80010b30 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	07650513          	addi	a0,a0,118 # 80010b30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	e9250513          	addi	a0,a0,-366 # 80022960 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	04048493          	addi	s1,s1,64 # 80010b30 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	02850513          	addi	a0,a0,40 # 80010b30 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	ffc50513          	addi	a0,a0,-4 # 80010b30 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e50080e7          	jalr	-432(ra) # 800019c0 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e1e080e7          	jalr	-482(ra) # 800019c0 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e12080e7          	jalr	-494(ra) # 800019c0 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dfa080e7          	jalr	-518(ra) # 800019c0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dba080e7          	jalr	-582(ra) # 800019c0 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d8e080e7          	jalr	-626(ra) # 800019c0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc6a1>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b30080e7          	jalr	-1232(ra) # 800019b0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a4070713          	addi	a4,a4,-1472 # 800088c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b14080e7          	jalr	-1260(ra) # 800019b0 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	8e6080e7          	jalr	-1818(ra) # 800027a4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e7a080e7          	jalr	-390(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	18e080e7          	jalr	398(ra) # 8000205c <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9ce080e7          	jalr	-1586(ra) # 800018fc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	846080e7          	jalr	-1978(ra) # 8000277c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	866080e7          	jalr	-1946(ra) # 800027a4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	de4080e7          	jalr	-540(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	df2080e7          	jalr	-526(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f8a080e7          	jalr	-118(ra) # 80002ee0 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	62a080e7          	jalr	1578(ra) # 80003588 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5d0080e7          	jalr	1488(ra) # 80004536 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	eda080e7          	jalr	-294(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d66080e7          	jalr	-666(ra) # 80001cdc <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72223          	sw	a5,-1724(a4) # 800088c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9387b783          	ld	a5,-1736(a5) # 800088d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc697>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	66a7be23          	sd	a0,1660(a5) # 800088d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc6a0>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	d1aa0a13          	addi	s4,s4,-742 # 80017580 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19848493          	addi	s1,s1,408
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <max>:

int max(int a, int b)
{
    800018cc:	1141                	addi	sp,sp,-16
    800018ce:	e422                	sd	s0,8(sp)
    800018d0:	0800                	addi	s0,sp,16
  if (a > b)
    return a;
  return b;
}
    800018d2:	87aa                	mv	a5,a0
    800018d4:	00b55363          	bge	a0,a1,800018da <max+0xe>
    800018d8:	87ae                	mv	a5,a1
    800018da:	0007851b          	sext.w	a0,a5
    800018de:	6422                	ld	s0,8(sp)
    800018e0:	0141                	addi	sp,sp,16
    800018e2:	8082                	ret

00000000800018e4 <min>:
int min(int a, int b)
{
    800018e4:	1141                	addi	sp,sp,-16
    800018e6:	e422                	sd	s0,8(sp)
    800018e8:	0800                	addi	s0,sp,16
  if (a < b)
    return a;
  return b;
}
    800018ea:	87aa                	mv	a5,a0
    800018ec:	00a5d363          	bge	a1,a0,800018f2 <min+0xe>
    800018f0:	87ae                	mv	a5,a1
    800018f2:	0007851b          	sext.w	a0,a5
    800018f6:	6422                	ld	s0,8(sp)
    800018f8:	0141                	addi	sp,sp,16
    800018fa:	8082                	ret

00000000800018fc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018fc:	7139                	addi	sp,sp,-64
    800018fe:	fc06                	sd	ra,56(sp)
    80001900:	f822                	sd	s0,48(sp)
    80001902:	f426                	sd	s1,40(sp)
    80001904:	f04a                	sd	s2,32(sp)
    80001906:	ec4e                	sd	s3,24(sp)
    80001908:	e852                	sd	s4,16(sp)
    8000190a:	e456                	sd	s5,8(sp)
    8000190c:	e05a                	sd	s6,0(sp)
    8000190e:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8d058593          	addi	a1,a1,-1840 # 800081e0 <digits+0x1a0>
    80001918:	0000f517          	auipc	a0,0xf
    8000191c:	23850513          	addi	a0,a0,568 # 80010b50 <pid_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	226080e7          	jalr	550(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	8c058593          	addi	a1,a1,-1856 # 800081e8 <digits+0x1a8>
    80001930:	0000f517          	auipc	a0,0xf
    80001934:	23850513          	addi	a0,a0,568 # 80010b68 <wait_lock>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20e080e7          	jalr	526(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001940:	0000f497          	auipc	s1,0xf
    80001944:	64048493          	addi	s1,s1,1600 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    80001948:	00007b17          	auipc	s6,0x7
    8000194c:	8b0b0b13          	addi	s6,s6,-1872 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001950:	8aa6                	mv	s5,s1
    80001952:	00006a17          	auipc	s4,0x6
    80001956:	6aea0a13          	addi	s4,s4,1710 # 80008000 <etext>
    8000195a:	04000937          	lui	s2,0x4000
    8000195e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001960:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001962:	00016997          	auipc	s3,0x16
    80001966:	c1e98993          	addi	s3,s3,-994 # 80017580 <tickslock>
    initlock(&p->lock, "proc");
    8000196a:	85da                	mv	a1,s6
    8000196c:	8526                	mv	a0,s1
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1d8080e7          	jalr	472(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001976:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000197a:	415487b3          	sub	a5,s1,s5
    8000197e:	878d                	srai	a5,a5,0x3
    80001980:	000a3703          	ld	a4,0(s4)
    80001984:	02e787b3          	mul	a5,a5,a4
    80001988:	2785                	addiw	a5,a5,1
    8000198a:	00d7979b          	slliw	a5,a5,0xd
    8000198e:	40f907b3          	sub	a5,s2,a5
    80001992:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001994:	19848493          	addi	s1,s1,408
    80001998:	fd3499e3          	bne	s1,s3,8000196a <procinit+0x6e>
  }
}
    8000199c:	70e2                	ld	ra,56(sp)
    8000199e:	7442                	ld	s0,48(sp)
    800019a0:	74a2                	ld	s1,40(sp)
    800019a2:	7902                	ld	s2,32(sp)
    800019a4:	69e2                	ld	s3,24(sp)
    800019a6:	6a42                	ld	s4,16(sp)
    800019a8:	6aa2                	ld	s5,8(sp)
    800019aa:	6b02                	ld	s6,0(sp)
    800019ac:	6121                	addi	sp,sp,64
    800019ae:	8082                	ret

00000000800019b0 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019b0:	1141                	addi	sp,sp,-16
    800019b2:	e422                	sd	s0,8(sp)
    800019b4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b8:	2501                	sext.w	a0,a0
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019c0:	1141                	addi	sp,sp,-16
    800019c2:	e422                	sd	s0,8(sp)
    800019c4:	0800                	addi	s0,sp,16
    800019c6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
  return c;
}
    800019cc:	0000f517          	auipc	a0,0xf
    800019d0:	1b450513          	addi	a0,a0,436 # 80010b80 <cpus>
    800019d4:	953e                	add	a0,a0,a5
    800019d6:	6422                	ld	s0,8(sp)
    800019d8:	0141                	addi	sp,sp,16
    800019da:	8082                	ret

00000000800019dc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019dc:	1101                	addi	sp,sp,-32
    800019de:	ec06                	sd	ra,24(sp)
    800019e0:	e822                	sd	s0,16(sp)
    800019e2:	e426                	sd	s1,8(sp)
    800019e4:	1000                	addi	s0,sp,32
  push_off();
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	1a4080e7          	jalr	420(ra) # 80000b8a <push_off>
    800019ee:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f0:	2781                	sext.w	a5,a5
    800019f2:	079e                	slli	a5,a5,0x7
    800019f4:	0000f717          	auipc	a4,0xf
    800019f8:	15c70713          	addi	a4,a4,348 # 80010b50 <pid_lock>
    800019fc:	97ba                	add	a5,a5,a4
    800019fe:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	22a080e7          	jalr	554(ra) # 80000c2a <pop_off>
  return p;
}
    80001a08:	8526                	mv	a0,s1
    80001a0a:	60e2                	ld	ra,24(sp)
    80001a0c:	6442                	ld	s0,16(sp)
    80001a0e:	64a2                	ld	s1,8(sp)
    80001a10:	6105                	addi	sp,sp,32
    80001a12:	8082                	ret

0000000080001a14 <forkret>:
}

// A child'fork s very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e406                	sd	ra,8(sp)
    80001a18:	e022                	sd	s0,0(sp)
    80001a1a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a1c:	00000097          	auipc	ra,0x0
    80001a20:	fc0080e7          	jalr	-64(ra) # 800019dc <myproc>
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	266080e7          	jalr	614(ra) # 80000c8a <release>

  if (first)
    80001a2c:	00007797          	auipc	a5,0x7
    80001a30:	e147a783          	lw	a5,-492(a5) # 80008840 <first.1>
    80001a34:	eb89                	bnez	a5,80001a46 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a36:	00001097          	auipc	ra,0x1
    80001a3a:	d86080e7          	jalr	-634(ra) # 800027bc <usertrapret>
}
    80001a3e:	60a2                	ld	ra,8(sp)
    80001a40:	6402                	ld	s0,0(sp)
    80001a42:	0141                	addi	sp,sp,16
    80001a44:	8082                	ret
    first = 0;
    80001a46:	00007797          	auipc	a5,0x7
    80001a4a:	de07ad23          	sw	zero,-518(a5) # 80008840 <first.1>
    fsinit(ROOTDEV);
    80001a4e:	4505                	li	a0,1
    80001a50:	00002097          	auipc	ra,0x2
    80001a54:	ab8080e7          	jalr	-1352(ra) # 80003508 <fsinit>
    80001a58:	bff9                	j	80001a36 <forkret+0x22>

0000000080001a5a <allocpid>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a66:	0000f917          	auipc	s2,0xf
    80001a6a:	0ea90913          	addi	s2,s2,234 # 80010b50 <pid_lock>
    80001a6e:	854a                	mv	a0,s2
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	166080e7          	jalr	358(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	dcc78793          	addi	a5,a5,-564 # 80008844 <nextpid>
    80001a80:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a82:	0014871b          	addiw	a4,s1,1
    80001a86:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	200080e7          	jalr	512(ra) # 80000c8a <release>
}
    80001a92:	8526                	mv	a0,s1
    80001a94:	60e2                	ld	ra,24(sp)
    80001a96:	6442                	ld	s0,16(sp)
    80001a98:	64a2                	ld	s1,8(sp)
    80001a9a:	6902                	ld	s2,0(sp)
    80001a9c:	6105                	addi	sp,sp,32
    80001a9e:	8082                	ret

0000000080001aa0 <proc_pagetable>:
{
    80001aa0:	1101                	addi	sp,sp,-32
    80001aa2:	ec06                	sd	ra,24(sp)
    80001aa4:	e822                	sd	s0,16(sp)
    80001aa6:	e426                	sd	s1,8(sp)
    80001aa8:	e04a                	sd	s2,0(sp)
    80001aaa:	1000                	addi	s0,sp,32
    80001aac:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aae:	00000097          	auipc	ra,0x0
    80001ab2:	87a080e7          	jalr	-1926(ra) # 80001328 <uvmcreate>
    80001ab6:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ab8:	c121                	beqz	a0,80001af8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aba:	4729                	li	a4,10
    80001abc:	00005697          	auipc	a3,0x5
    80001ac0:	54468693          	addi	a3,a3,1348 # 80007000 <_trampoline>
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	040005b7          	lui	a1,0x4000
    80001aca:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001acc:	05b2                	slli	a1,a1,0xc
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	5d0080e7          	jalr	1488(ra) # 8000109e <mappages>
    80001ad6:	02054863          	bltz	a0,80001b06 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ada:	4719                	li	a4,6
    80001adc:	05893683          	ld	a3,88(s2)
    80001ae0:	6605                	lui	a2,0x1
    80001ae2:	020005b7          	lui	a1,0x2000
    80001ae6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ae8:	05b6                	slli	a1,a1,0xd
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	5b2080e7          	jalr	1458(ra) # 8000109e <mappages>
    80001af4:	02054163          	bltz	a0,80001b16 <proc_pagetable+0x76>
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6902                	ld	s2,0(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret
    uvmfree(pagetable, 0);
    80001b06:	4581                	li	a1,0
    80001b08:	8526                	mv	a0,s1
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	a24080e7          	jalr	-1500(ra) # 8000152e <uvmfree>
    return 0;
    80001b12:	4481                	li	s1,0
    80001b14:	b7d5                	j	80001af8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	8526                	mv	a0,s1
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	740080e7          	jalr	1856(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b2c:	4581                	li	a1,0
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	9fe080e7          	jalr	-1538(ra) # 8000152e <uvmfree>
    return 0;
    80001b38:	4481                	li	s1,0
    80001b3a:	bf7d                	j	80001af8 <proc_pagetable+0x58>

0000000080001b3c <proc_freepagetable>:
{
    80001b3c:	1101                	addi	sp,sp,-32
    80001b3e:	ec06                	sd	ra,24(sp)
    80001b40:	e822                	sd	s0,16(sp)
    80001b42:	e426                	sd	s1,8(sp)
    80001b44:	e04a                	sd	s2,0(sp)
    80001b46:	1000                	addi	s0,sp,32
    80001b48:	84aa                	mv	s1,a0
    80001b4a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b4c:	4681                	li	a3,0
    80001b4e:	4605                	li	a2,1
    80001b50:	040005b7          	lui	a1,0x4000
    80001b54:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b56:	05b2                	slli	a1,a1,0xc
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	70c080e7          	jalr	1804(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b60:	4681                	li	a3,0
    80001b62:	4605                	li	a2,1
    80001b64:	020005b7          	lui	a1,0x2000
    80001b68:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b6a:	05b6                	slli	a1,a1,0xd
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	6f6080e7          	jalr	1782(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b76:	85ca                	mv	a1,s2
    80001b78:	8526                	mv	a0,s1
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	9b4080e7          	jalr	-1612(ra) # 8000152e <uvmfree>
}
    80001b82:	60e2                	ld	ra,24(sp)
    80001b84:	6442                	ld	s0,16(sp)
    80001b86:	64a2                	ld	s1,8(sp)
    80001b88:	6902                	ld	s2,0(sp)
    80001b8a:	6105                	addi	sp,sp,32
    80001b8c:	8082                	ret

0000000080001b8e <freeproc>:
{
    80001b8e:	1101                	addi	sp,sp,-32
    80001b90:	ec06                	sd	ra,24(sp)
    80001b92:	e822                	sd	s0,16(sp)
    80001b94:	e426                	sd	s1,8(sp)
    80001b96:	1000                	addi	s0,sp,32
    80001b98:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b9a:	6d28                	ld	a0,88(a0)
    80001b9c:	c509                	beqz	a0,80001ba6 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	e4a080e7          	jalr	-438(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001ba6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001baa:	68a8                	ld	a0,80(s1)
    80001bac:	c511                	beqz	a0,80001bb8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bae:	64ac                	ld	a1,72(s1)
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	f8c080e7          	jalr	-116(ra) # 80001b3c <proc_freepagetable>
  p->pagetable = 0;
    80001bb8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bbc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bc4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bc8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bcc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bd0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bd4:	0204a623          	sw	zero,44(s1)
  p->ctime = 0;
    80001bd8:	1604a423          	sw	zero,360(s1)
  p->state = UNUSED;
    80001bdc:	0004ac23          	sw	zero,24(s1)
}
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <allocproc>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	e04a                	sd	s2,0(sp)
    80001bf4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf6:	0000f497          	auipc	s1,0xf
    80001bfa:	38a48493          	addi	s1,s1,906 # 80010f80 <proc>
    80001bfe:	00016917          	auipc	s2,0x16
    80001c02:	98290913          	addi	s2,s2,-1662 # 80017580 <tickslock>
    acquire(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	fce080e7          	jalr	-50(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001c10:	4c9c                	lw	a5,24(s1)
    80001c12:	cf81                	beqz	a5,80001c2a <allocproc+0x40>
      release(&p->lock);
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	074080e7          	jalr	116(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c1e:	19848493          	addi	s1,s1,408
    80001c22:	ff2492e3          	bne	s1,s2,80001c06 <allocproc+0x1c>
  return 0;
    80001c26:	4481                	li	s1,0
    80001c28:	a89d                	j	80001c9e <allocproc+0xb4>
  p->pid = allocpid();
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	e30080e7          	jalr	-464(ra) # 80001a5a <allocpid>
    80001c32:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c34:	4785                	li	a5,1
    80001c36:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c38:	00007797          	auipc	a5,0x7
    80001c3c:	ca87a783          	lw	a5,-856(a5) # 800088e0 <ticks>
    80001c40:	16f4a423          	sw	a5,360(s1)
  p->run_time = 0;
    80001c44:	1604b823          	sd	zero,368(s1)
  p->start_time = 0;
    80001c48:	1604bc23          	sd	zero,376(s1)
  p->sleep_time = 0;
    80001c4c:	1804b023          	sd	zero,384(s1)
  p->n_runs = 0;
    80001c50:	1804b423          	sd	zero,392(s1)
  p->priority = 60;
    80001c54:	03c00793          	li	a5,60
    80001c58:	18f4b823          	sd	a5,400(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	e8a080e7          	jalr	-374(ra) # 80000ae6 <kalloc>
    80001c64:	892a                	mv	s2,a0
    80001c66:	eca8                	sd	a0,88(s1)
    80001c68:	c131                	beqz	a0,80001cac <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	e34080e7          	jalr	-460(ra) # 80001aa0 <proc_pagetable>
    80001c74:	892a                	mv	s2,a0
    80001c76:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c78:	c531                	beqz	a0,80001cc4 <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001c7a:	07000613          	li	a2,112
    80001c7e:	4581                	li	a1,0
    80001c80:	06048513          	addi	a0,s1,96
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	04e080e7          	jalr	78(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c8c:	00000797          	auipc	a5,0x0
    80001c90:	d8878793          	addi	a5,a5,-632 # 80001a14 <forkret>
    80001c94:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c96:	60bc                	ld	a5,64(s1)
    80001c98:	6705                	lui	a4,0x1
    80001c9a:	97ba                	add	a5,a5,a4
    80001c9c:	f4bc                	sd	a5,104(s1)
}
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	60e2                	ld	ra,24(sp)
    80001ca2:	6442                	ld	s0,16(sp)
    80001ca4:	64a2                	ld	s1,8(sp)
    80001ca6:	6902                	ld	s2,0(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret
    freeproc(p);
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	ee0080e7          	jalr	-288(ra) # 80001b8e <freeproc>
    release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
    return 0;
    80001cc0:	84ca                	mv	s1,s2
    80001cc2:	bff1                	j	80001c9e <allocproc+0xb4>
    freeproc(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	ec8080e7          	jalr	-312(ra) # 80001b8e <freeproc>
    release(&p->lock);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	fba080e7          	jalr	-70(ra) # 80000c8a <release>
    return 0;
    80001cd8:	84ca                	mv	s1,s2
    80001cda:	b7d1                	j	80001c9e <allocproc+0xb4>

0000000080001cdc <userinit>:
{
    80001cdc:	1101                	addi	sp,sp,-32
    80001cde:	ec06                	sd	ra,24(sp)
    80001ce0:	e822                	sd	s0,16(sp)
    80001ce2:	e426                	sd	s1,8(sp)
    80001ce4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	f04080e7          	jalr	-252(ra) # 80001bea <allocproc>
    80001cee:	84aa                	mv	s1,a0
  initproc = p;
    80001cf0:	00007797          	auipc	a5,0x7
    80001cf4:	bea7b423          	sd	a0,-1048(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cf8:	03400613          	li	a2,52
    80001cfc:	00007597          	auipc	a1,0x7
    80001d00:	b5458593          	addi	a1,a1,-1196 # 80008850 <initcode>
    80001d04:	6928                	ld	a0,80(a0)
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	650080e7          	jalr	1616(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d0e:	6785                	lui	a5,0x1
    80001d10:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d12:	6cb8                	ld	a4,88(s1)
    80001d14:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d18:	6cb8                	ld	a4,88(s1)
    80001d1a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d1c:	4641                	li	a2,16
    80001d1e:	00006597          	auipc	a1,0x6
    80001d22:	4e258593          	addi	a1,a1,1250 # 80008200 <digits+0x1c0>
    80001d26:	15848513          	addi	a0,s1,344
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	0f2080e7          	jalr	242(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d32:	00006517          	auipc	a0,0x6
    80001d36:	4de50513          	addi	a0,a0,1246 # 80008210 <digits+0x1d0>
    80001d3a:	00002097          	auipc	ra,0x2
    80001d3e:	1f8080e7          	jalr	504(ra) # 80003f32 <namei>
    80001d42:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d46:	478d                	li	a5,3
    80001d48:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	f3e080e7          	jalr	-194(ra) # 80000c8a <release>
}
    80001d54:	60e2                	ld	ra,24(sp)
    80001d56:	6442                	ld	s0,16(sp)
    80001d58:	64a2                	ld	s1,8(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret

0000000080001d5e <growproc>:
{
    80001d5e:	1101                	addi	sp,sp,-32
    80001d60:	ec06                	sd	ra,24(sp)
    80001d62:	e822                	sd	s0,16(sp)
    80001d64:	e426                	sd	s1,8(sp)
    80001d66:	e04a                	sd	s2,0(sp)
    80001d68:	1000                	addi	s0,sp,32
    80001d6a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	c70080e7          	jalr	-912(ra) # 800019dc <myproc>
    80001d74:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d76:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d78:	01204c63          	bgtz	s2,80001d90 <growproc+0x32>
  else if (n < 0)
    80001d7c:	02094663          	bltz	s2,80001da8 <growproc+0x4a>
  p->sz = sz;
    80001d80:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d82:	4501                	li	a0,0
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6902                	ld	s2,0(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d90:	4691                	li	a3,4
    80001d92:	00b90633          	add	a2,s2,a1
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	678080e7          	jalr	1656(ra) # 80001410 <uvmalloc>
    80001da0:	85aa                	mv	a1,a0
    80001da2:	fd79                	bnez	a0,80001d80 <growproc+0x22>
      return -1;
    80001da4:	557d                	li	a0,-1
    80001da6:	bff9                	j	80001d84 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da8:	00b90633          	add	a2,s2,a1
    80001dac:	6928                	ld	a0,80(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	61a080e7          	jalr	1562(ra) # 800013c8 <uvmdealloc>
    80001db6:	85aa                	mv	a1,a0
    80001db8:	b7e1                	j	80001d80 <growproc+0x22>

0000000080001dba <fork>:
{
    80001dba:	7139                	addi	sp,sp,-64
    80001dbc:	fc06                	sd	ra,56(sp)
    80001dbe:	f822                	sd	s0,48(sp)
    80001dc0:	f426                	sd	s1,40(sp)
    80001dc2:	f04a                	sd	s2,32(sp)
    80001dc4:	ec4e                	sd	s3,24(sp)
    80001dc6:	e852                	sd	s4,16(sp)
    80001dc8:	e456                	sd	s5,8(sp)
    80001dca:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	c10080e7          	jalr	-1008(ra) # 800019dc <myproc>
    80001dd4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	e14080e7          	jalr	-492(ra) # 80001bea <allocproc>
    80001dde:	10050c63          	beqz	a0,80001ef6 <fork+0x13c>
    80001de2:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001de4:	048ab603          	ld	a2,72(s5)
    80001de8:	692c                	ld	a1,80(a0)
    80001dea:	050ab503          	ld	a0,80(s5)
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	77a080e7          	jalr	1914(ra) # 80001568 <uvmcopy>
    80001df6:	04054863          	bltz	a0,80001e46 <fork+0x8c>
  np->sz = p->sz;
    80001dfa:	048ab783          	ld	a5,72(s5)
    80001dfe:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e02:	058ab683          	ld	a3,88(s5)
    80001e06:	87b6                	mv	a5,a3
    80001e08:	058a3703          	ld	a4,88(s4)
    80001e0c:	12068693          	addi	a3,a3,288
    80001e10:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e14:	6788                	ld	a0,8(a5)
    80001e16:	6b8c                	ld	a1,16(a5)
    80001e18:	6f90                	ld	a2,24(a5)
    80001e1a:	01073023          	sd	a6,0(a4)
    80001e1e:	e708                	sd	a0,8(a4)
    80001e20:	eb0c                	sd	a1,16(a4)
    80001e22:	ef10                	sd	a2,24(a4)
    80001e24:	02078793          	addi	a5,a5,32
    80001e28:	02070713          	addi	a4,a4,32
    80001e2c:	fed792e3          	bne	a5,a3,80001e10 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e30:	058a3783          	ld	a5,88(s4)
    80001e34:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e38:	0d0a8493          	addi	s1,s5,208
    80001e3c:	0d0a0913          	addi	s2,s4,208
    80001e40:	150a8993          	addi	s3,s5,336
    80001e44:	a00d                	j	80001e66 <fork+0xac>
    freeproc(np);
    80001e46:	8552                	mv	a0,s4
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	d46080e7          	jalr	-698(ra) # 80001b8e <freeproc>
    release(&np->lock);
    80001e50:	8552                	mv	a0,s4
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e38080e7          	jalr	-456(ra) # 80000c8a <release>
    return -1;
    80001e5a:	597d                	li	s2,-1
    80001e5c:	a059                	j	80001ee2 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e5e:	04a1                	addi	s1,s1,8
    80001e60:	0921                	addi	s2,s2,8
    80001e62:	01348b63          	beq	s1,s3,80001e78 <fork+0xbe>
    if (p->ofile[i])
    80001e66:	6088                	ld	a0,0(s1)
    80001e68:	d97d                	beqz	a0,80001e5e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	75e080e7          	jalr	1886(ra) # 800045c8 <filedup>
    80001e72:	00a93023          	sd	a0,0(s2)
    80001e76:	b7e5                	j	80001e5e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e78:	150ab503          	ld	a0,336(s5)
    80001e7c:	00002097          	auipc	ra,0x2
    80001e80:	8cc080e7          	jalr	-1844(ra) # 80003748 <idup>
    80001e84:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	158a8593          	addi	a1,s5,344
    80001e8e:	158a0513          	addi	a0,s4,344
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	f8a080e7          	jalr	-118(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e9a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	dea080e7          	jalr	-534(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001ea8:	0000f497          	auipc	s1,0xf
    80001eac:	cc048493          	addi	s1,s1,-832 # 80010b68 <wait_lock>
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eba:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dca080e7          	jalr	-566(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ec8:	8552                	mv	a0,s4
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	d0c080e7          	jalr	-756(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ed2:	478d                	li	a5,3
    80001ed4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ed8:	8552                	mv	a0,s4
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	db0080e7          	jalr	-592(ra) # 80000c8a <release>
}
    80001ee2:	854a                	mv	a0,s2
    80001ee4:	70e2                	ld	ra,56(sp)
    80001ee6:	7442                	ld	s0,48(sp)
    80001ee8:	74a2                	ld	s1,40(sp)
    80001eea:	7902                	ld	s2,32(sp)
    80001eec:	69e2                	ld	s3,24(sp)
    80001eee:	6a42                	ld	s4,16(sp)
    80001ef0:	6aa2                	ld	s5,8(sp)
    80001ef2:	6121                	addi	sp,sp,64
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	597d                	li	s2,-1
    80001ef8:	b7ed                	j	80001ee2 <fork+0x128>

0000000080001efa <priorityBasedScheduling>:
{
    80001efa:	7159                	addi	sp,sp,-112
    80001efc:	f486                	sd	ra,104(sp)
    80001efe:	f0a2                	sd	s0,96(sp)
    80001f00:	eca6                	sd	s1,88(sp)
    80001f02:	e8ca                	sd	s2,80(sp)
    80001f04:	e4ce                	sd	s3,72(sp)
    80001f06:	e0d2                	sd	s4,64(sp)
    80001f08:	fc56                	sd	s5,56(sp)
    80001f0a:	f85a                	sd	s6,48(sp)
    80001f0c:	f45e                	sd	s7,40(sp)
    80001f0e:	f062                	sd	s8,32(sp)
    80001f10:	ec66                	sd	s9,24(sp)
    80001f12:	e86a                	sd	s10,16(sp)
    80001f14:	e46e                	sd	s11,8(sp)
    80001f16:	1880                	addi	s0,sp,112
    80001f18:	8d2a                	mv	s10,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f22:	10079073          	csrw	sstatus,a5
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f26:	0000f497          	auipc	s1,0xf
    80001f2a:	05a48493          	addi	s1,s1,90 # 80010f80 <proc>
  int dynamic_priority = 101; // Lower dynamic_priority value => higher preference in scheduling
    80001f2e:	06500b13          	li	s6,101
  high_priority_proc = 0;
    80001f32:	4901                	li	s2,0
      nice = 5; // Defualt value of nice;
    80001f34:	4a95                	li	s5,5
    if (p->state == RUNNABLE)
    80001f36:	4a0d                	li	s4,3
    80001f38:	06400b93          	li	s7,100
      int check_1 = 0, check_2 = 0;
    80001f3c:	4c81                	li	s9,0
    80001f3e:	06400c13          	li	s8,100
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f42:	00015997          	auipc	s3,0x15
    80001f46:	63e98993          	addi	s3,s3,1598 # 80017580 <tickslock>
    80001f4a:	a025                	j	80001f72 <priorityBasedScheduling+0x78>
      if (dp_check && p->n_runs < high_priority_proc->n_runs)
    80001f4c:	1884b703          	ld	a4,392(s1)
    80001f50:	18893783          	ld	a5,392(s2)
      int check_1 = 0, check_2 = 0;
    80001f54:	86e6                	mv	a3,s9
      if (dp_check && high_priority_proc->n_runs == p->n_runs && p->ctime < high_priority_proc->ctime)
    80001f56:	08f70563          	beq	a4,a5,80001fe0 <priorityBasedScheduling+0xe6>
      if (high_priority_proc == 0 || curr_dynamic_priority > dynamic_priority || (dp_check && check_1) || check_2)
    80001f5a:	06f76b63          	bltu	a4,a5,80001fd0 <priorityBasedScheduling+0xd6>
    80001f5e:	eaad                	bnez	a3,80001fd0 <priorityBasedScheduling+0xd6>
    release(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d28080e7          	jalr	-728(ra) # 80000c8a <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f6a:	19848493          	addi	s1,s1,408
    80001f6e:	09348363          	beq	s1,s3,80001ff4 <priorityBasedScheduling+0xfa>
    acquire(&p->lock);
    80001f72:	8526                	mv	a0,s1
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	c62080e7          	jalr	-926(ra) # 80000bd6 <acquire>
    if (p->run_time + p->sleep_time > 0)
    80001f7c:	1804b683          	ld	a3,384(s1)
    80001f80:	1704b703          	ld	a4,368(s1)
    80001f84:	9736                	add	a4,a4,a3
      nice = 5; // Defualt value of nice;
    80001f86:	87d6                	mv	a5,s5
    if (p->run_time + p->sleep_time > 0)
    80001f88:	cb09                	beqz	a4,80001f9a <priorityBasedScheduling+0xa0>
      nice = p->sleep_time * 10;
    80001f8a:	0026979b          	slliw	a5,a3,0x2
    80001f8e:	9fb5                	addw	a5,a5,a3
      nice = nice / (p->sleep_time + p->run_time);
    80001f90:	0017979b          	slliw	a5,a5,0x1
    80001f94:	02e7d7b3          	divu	a5,a5,a4
    80001f98:	2781                	sext.w	a5,a5
    curr_dynamic_priority = max(0, min(p->priority - nice + 5, 100));
    80001f9a:	1904b703          	ld	a4,400(s1)
    if (p->state == RUNNABLE)
    80001f9e:	4c94                	lw	a3,24(s1)
    80001fa0:	fd4690e3          	bne	a3,s4,80001f60 <priorityBasedScheduling+0x66>
    curr_dynamic_priority = max(0, min(p->priority - nice + 5, 100));
    80001fa4:	2715                	addiw	a4,a4,5
    80001fa6:	40f707bb          	subw	a5,a4,a5
    80001faa:	0007871b          	sext.w	a4,a5
    80001fae:	00ebd363          	bge	s7,a4,80001fb4 <priorityBasedScheduling+0xba>
    80001fb2:	87e2                	mv	a5,s8
    80001fb4:	0007871b          	sext.w	a4,a5
    80001fb8:	fff74713          	not	a4,a4
    80001fbc:	977d                	srai	a4,a4,0x3f
    80001fbe:	8ff9                	and	a5,a5,a4
    80001fc0:	00078d9b          	sext.w	s11,a5
      if (dynamic_priority == curr_dynamic_priority)
    80001fc4:	f96d84e3          	beq	s11,s6,80001f4c <priorityBasedScheduling+0x52>
      if (high_priority_proc == 0 || curr_dynamic_priority > dynamic_priority || (dp_check && check_1) || check_2)
    80001fc8:	02090363          	beqz	s2,80001fee <priorityBasedScheduling+0xf4>
    80001fcc:	f9bb5ae3          	bge	s6,s11,80001f60 <priorityBasedScheduling+0x66>
          release(&high_priority_proc->lock);
    80001fd0:	854a                	mv	a0,s2
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	cb8080e7          	jalr	-840(ra) # 80000c8a <release>
        dynamic_priority = curr_dynamic_priority;
    80001fda:	8b6e                	mv	s6,s11
          release(&high_priority_proc->lock);
    80001fdc:	8926                	mv	s2,s1
    80001fde:	b771                	j	80001f6a <priorityBasedScheduling+0x70>
      if (dp_check && high_priority_proc->n_runs == p->n_runs && p->ctime < high_priority_proc->ctime)
    80001fe0:	1684a683          	lw	a3,360(s1)
    80001fe4:	16892603          	lw	a2,360(s2)
      int check_1 = 0, check_2 = 0;
    80001fe8:	00c6b6b3          	sltu	a3,a3,a2
    80001fec:	b7bd                	j	80001f5a <priorityBasedScheduling+0x60>
        dynamic_priority = curr_dynamic_priority;
    80001fee:	8b6e                	mv	s6,s11
    80001ff0:	8926                	mv	s2,s1
    80001ff2:	bfa5                	j	80001f6a <priorityBasedScheduling+0x70>
  if (high_priority_proc != 0)
    80001ff4:	04090563          	beqz	s2,8000203e <priorityBasedScheduling+0x144>
    high_priority_proc->state = RUNNING;
    80001ff8:	4791                	li	a5,4
    80001ffa:	00f92c23          	sw	a5,24(s2)
    high_priority_proc->start_time = ticks;
    80001ffe:	00007797          	auipc	a5,0x7
    80002002:	8e27e783          	lwu	a5,-1822(a5) # 800088e0 <ticks>
    80002006:	16f93c23          	sd	a5,376(s2)
    high_priority_proc->run_time = 0;
    8000200a:	16093823          	sd	zero,368(s2)
    high_priority_proc->sleep_time = 0;
    8000200e:	18093023          	sd	zero,384(s2)
    high_priority_proc->n_runs += 1;
    80002012:	18893783          	ld	a5,392(s2)
    80002016:	0785                	addi	a5,a5,1
    80002018:	18f93423          	sd	a5,392(s2)
    c->proc = high_priority_proc;
    8000201c:	012d3023          	sd	s2,0(s10)
    swtch(&c->context, &high_priority_proc->context);
    80002020:	06090593          	addi	a1,s2,96
    80002024:	008d0513          	addi	a0,s10,8
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	6ea080e7          	jalr	1770(ra) # 80002712 <swtch>
    c->proc = 0;
    80002030:	000d3023          	sd	zero,0(s10)
    release(&high_priority_proc->lock);
    80002034:	854a                	mv	a0,s2
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	c54080e7          	jalr	-940(ra) # 80000c8a <release>
}
    8000203e:	70a6                	ld	ra,104(sp)
    80002040:	7406                	ld	s0,96(sp)
    80002042:	64e6                	ld	s1,88(sp)
    80002044:	6946                	ld	s2,80(sp)
    80002046:	69a6                	ld	s3,72(sp)
    80002048:	6a06                	ld	s4,64(sp)
    8000204a:	7ae2                	ld	s5,56(sp)
    8000204c:	7b42                	ld	s6,48(sp)
    8000204e:	7ba2                	ld	s7,40(sp)
    80002050:	7c02                	ld	s8,32(sp)
    80002052:	6ce2                	ld	s9,24(sp)
    80002054:	6d42                	ld	s10,16(sp)
    80002056:	6da2                	ld	s11,8(sp)
    80002058:	6165                	addi	sp,sp,112
    8000205a:	8082                	ret

000000008000205c <scheduler>:
{
    8000205c:	1101                	addi	sp,sp,-32
    8000205e:	ec06                	sd	ra,24(sp)
    80002060:	e822                	sd	s0,16(sp)
    80002062:	e426                	sd	s1,8(sp)
    80002064:	1000                	addi	s0,sp,32
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  int id = r_tp();
    80002068:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f497          	auipc	s1,0xf
    80002070:	b1448493          	addi	s1,s1,-1260 # 80010b80 <cpus>
    80002074:	94be                	add	s1,s1,a5
  c->proc = 0;
    80002076:	0000f717          	auipc	a4,0xf
    8000207a:	ada70713          	addi	a4,a4,-1318 # 80010b50 <pid_lock>
    8000207e:	97ba                	add	a5,a5,a4
    80002080:	0207b823          	sd	zero,48(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002084:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002088:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000208c:	10079073          	csrw	sstatus,a5
    priorityBasedScheduling(c);
    80002090:	8526                	mv	a0,s1
    80002092:	00000097          	auipc	ra,0x0
    80002096:	e68080e7          	jalr	-408(ra) # 80001efa <priorityBasedScheduling>
  for (;;)
    8000209a:	b7ed                	j	80002084 <scheduler+0x28>

000000008000209c <sched>:
{
    8000209c:	7179                	addi	sp,sp,-48
    8000209e:	f406                	sd	ra,40(sp)
    800020a0:	f022                	sd	s0,32(sp)
    800020a2:	ec26                	sd	s1,24(sp)
    800020a4:	e84a                	sd	s2,16(sp)
    800020a6:	e44e                	sd	s3,8(sp)
    800020a8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	932080e7          	jalr	-1742(ra) # 800019dc <myproc>
    800020b2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	aa8080e7          	jalr	-1368(ra) # 80000b5c <holding>
    800020bc:	c93d                	beqz	a0,80002132 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020be:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020c0:	2781                	sext.w	a5,a5
    800020c2:	079e                	slli	a5,a5,0x7
    800020c4:	0000f717          	auipc	a4,0xf
    800020c8:	a8c70713          	addi	a4,a4,-1396 # 80010b50 <pid_lock>
    800020cc:	97ba                	add	a5,a5,a4
    800020ce:	0a87a703          	lw	a4,168(a5)
    800020d2:	4785                	li	a5,1
    800020d4:	06f71763          	bne	a4,a5,80002142 <sched+0xa6>
  if (p->state == RUNNING)
    800020d8:	4c98                	lw	a4,24(s1)
    800020da:	4791                	li	a5,4
    800020dc:	06f70b63          	beq	a4,a5,80002152 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020e4:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020e6:	efb5                	bnez	a5,80002162 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ea:	0000f917          	auipc	s2,0xf
    800020ee:	a6690913          	addi	s2,s2,-1434 # 80010b50 <pid_lock>
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	079e                	slli	a5,a5,0x7
    800020f6:	97ca                	add	a5,a5,s2
    800020f8:	0ac7a983          	lw	s3,172(a5)
    800020fc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020fe:	2781                	sext.w	a5,a5
    80002100:	079e                	slli	a5,a5,0x7
    80002102:	0000f597          	auipc	a1,0xf
    80002106:	a8658593          	addi	a1,a1,-1402 # 80010b88 <cpus+0x8>
    8000210a:	95be                	add	a1,a1,a5
    8000210c:	06048513          	addi	a0,s1,96
    80002110:	00000097          	auipc	ra,0x0
    80002114:	602080e7          	jalr	1538(ra) # 80002712 <swtch>
    80002118:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000211a:	2781                	sext.w	a5,a5
    8000211c:	079e                	slli	a5,a5,0x7
    8000211e:	993e                	add	s2,s2,a5
    80002120:	0b392623          	sw	s3,172(s2)
}
    80002124:	70a2                	ld	ra,40(sp)
    80002126:	7402                	ld	s0,32(sp)
    80002128:	64e2                	ld	s1,24(sp)
    8000212a:	6942                	ld	s2,16(sp)
    8000212c:	69a2                	ld	s3,8(sp)
    8000212e:	6145                	addi	sp,sp,48
    80002130:	8082                	ret
    panic("sched p->lock");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	0e650513          	addi	a0,a0,230 # 80008218 <digits+0x1d8>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	406080e7          	jalr	1030(ra) # 80000540 <panic>
    panic("sched locks");
    80002142:	00006517          	auipc	a0,0x6
    80002146:	0e650513          	addi	a0,a0,230 # 80008228 <digits+0x1e8>
    8000214a:	ffffe097          	auipc	ra,0xffffe
    8000214e:	3f6080e7          	jalr	1014(ra) # 80000540 <panic>
    panic("sched running");
    80002152:	00006517          	auipc	a0,0x6
    80002156:	0e650513          	addi	a0,a0,230 # 80008238 <digits+0x1f8>
    8000215a:	ffffe097          	auipc	ra,0xffffe
    8000215e:	3e6080e7          	jalr	998(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002162:	00006517          	auipc	a0,0x6
    80002166:	0e650513          	addi	a0,a0,230 # 80008248 <digits+0x208>
    8000216a:	ffffe097          	auipc	ra,0xffffe
    8000216e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>

0000000080002172 <yield>:
{
    80002172:	1101                	addi	sp,sp,-32
    80002174:	ec06                	sd	ra,24(sp)
    80002176:	e822                	sd	s0,16(sp)
    80002178:	e426                	sd	s1,8(sp)
    8000217a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	860080e7          	jalr	-1952(ra) # 800019dc <myproc>
    80002184:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000218e:	478d                	li	a5,3
    80002190:	cc9c                	sw	a5,24(s1)
  sched();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	f0a080e7          	jalr	-246(ra) # 8000209c <sched>
  release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	aee080e7          	jalr	-1298(ra) # 80000c8a <release>
}
    800021a4:	60e2                	ld	ra,24(sp)
    800021a6:	6442                	ld	s0,16(sp)
    800021a8:	64a2                	ld	s1,8(sp)
    800021aa:	6105                	addi	sp,sp,32
    800021ac:	8082                	ret

00000000800021ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021ae:	7179                	addi	sp,sp,-48
    800021b0:	f406                	sd	ra,40(sp)
    800021b2:	f022                	sd	s0,32(sp)
    800021b4:	ec26                	sd	s1,24(sp)
    800021b6:	e84a                	sd	s2,16(sp)
    800021b8:	e44e                	sd	s3,8(sp)
    800021ba:	1800                	addi	s0,sp,48
    800021bc:	89aa                	mv	s3,a0
    800021be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	81c080e7          	jalr	-2020(ra) # 800019dc <myproc>
    800021c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	a0c080e7          	jalr	-1524(ra) # 80000bd6 <acquire>
  release(lk);
    800021d2:	854a                	mv	a0,s2
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	ab6080e7          	jalr	-1354(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021e0:	4789                	li	a5,2
    800021e2:	cc9c                	sw	a5,24(s1)

  sched();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	eb8080e7          	jalr	-328(ra) # 8000209c <sched>

  // Tidy up.
  p->chan = 0;
    800021ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	a98080e7          	jalr	-1384(ra) # 80000c8a <release>
  acquire(lk);
    800021fa:	854a                	mv	a0,s2
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9da080e7          	jalr	-1574(ra) # 80000bd6 <acquire>
}
    80002204:	70a2                	ld	ra,40(sp)
    80002206:	7402                	ld	s0,32(sp)
    80002208:	64e2                	ld	s1,24(sp)
    8000220a:	6942                	ld	s2,16(sp)
    8000220c:	69a2                	ld	s3,8(sp)
    8000220e:	6145                	addi	sp,sp,48
    80002210:	8082                	ret

0000000080002212 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002212:	7139                	addi	sp,sp,-64
    80002214:	fc06                	sd	ra,56(sp)
    80002216:	f822                	sd	s0,48(sp)
    80002218:	f426                	sd	s1,40(sp)
    8000221a:	f04a                	sd	s2,32(sp)
    8000221c:	ec4e                	sd	s3,24(sp)
    8000221e:	e852                	sd	s4,16(sp)
    80002220:	e456                	sd	s5,8(sp)
    80002222:	0080                	addi	s0,sp,64
    80002224:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002226:	0000f497          	auipc	s1,0xf
    8000222a:	d5a48493          	addi	s1,s1,-678 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000222e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002230:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002232:	00015917          	auipc	s2,0x15
    80002236:	34e90913          	addi	s2,s2,846 # 80017580 <tickslock>
    8000223a:	a811                	j	8000224e <wakeup+0x3c>
      }
      release(&p->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002246:	19848493          	addi	s1,s1,408
    8000224a:	03248663          	beq	s1,s2,80002276 <wakeup+0x64>
    if (p != myproc())
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	78e080e7          	jalr	1934(ra) # 800019dc <myproc>
    80002256:	fea488e3          	beq	s1,a0,80002246 <wakeup+0x34>
      acquire(&p->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	97a080e7          	jalr	-1670(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002264:	4c9c                	lw	a5,24(s1)
    80002266:	fd379be3          	bne	a5,s3,8000223c <wakeup+0x2a>
    8000226a:	709c                	ld	a5,32(s1)
    8000226c:	fd4798e3          	bne	a5,s4,8000223c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002270:	0154ac23          	sw	s5,24(s1)
    80002274:	b7e1                	j	8000223c <wakeup+0x2a>
    }
  }
}
    80002276:	70e2                	ld	ra,56(sp)
    80002278:	7442                	ld	s0,48(sp)
    8000227a:	74a2                	ld	s1,40(sp)
    8000227c:	7902                	ld	s2,32(sp)
    8000227e:	69e2                	ld	s3,24(sp)
    80002280:	6a42                	ld	s4,16(sp)
    80002282:	6aa2                	ld	s5,8(sp)
    80002284:	6121                	addi	sp,sp,64
    80002286:	8082                	ret

0000000080002288 <reparent>:
{
    80002288:	7179                	addi	sp,sp,-48
    8000228a:	f406                	sd	ra,40(sp)
    8000228c:	f022                	sd	s0,32(sp)
    8000228e:	ec26                	sd	s1,24(sp)
    80002290:	e84a                	sd	s2,16(sp)
    80002292:	e44e                	sd	s3,8(sp)
    80002294:	e052                	sd	s4,0(sp)
    80002296:	1800                	addi	s0,sp,48
    80002298:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000229a:	0000f497          	auipc	s1,0xf
    8000229e:	ce648493          	addi	s1,s1,-794 # 80010f80 <proc>
      pp->parent = initproc;
    800022a2:	00006a17          	auipc	s4,0x6
    800022a6:	636a0a13          	addi	s4,s4,1590 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022aa:	00015997          	auipc	s3,0x15
    800022ae:	2d698993          	addi	s3,s3,726 # 80017580 <tickslock>
    800022b2:	a029                	j	800022bc <reparent+0x34>
    800022b4:	19848493          	addi	s1,s1,408
    800022b8:	01348d63          	beq	s1,s3,800022d2 <reparent+0x4a>
    if (pp->parent == p)
    800022bc:	7c9c                	ld	a5,56(s1)
    800022be:	ff279be3          	bne	a5,s2,800022b4 <reparent+0x2c>
      pp->parent = initproc;
    800022c2:	000a3503          	ld	a0,0(s4)
    800022c6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	f4a080e7          	jalr	-182(ra) # 80002212 <wakeup>
    800022d0:	b7d5                	j	800022b4 <reparent+0x2c>
}
    800022d2:	70a2                	ld	ra,40(sp)
    800022d4:	7402                	ld	s0,32(sp)
    800022d6:	64e2                	ld	s1,24(sp)
    800022d8:	6942                	ld	s2,16(sp)
    800022da:	69a2                	ld	s3,8(sp)
    800022dc:	6a02                	ld	s4,0(sp)
    800022de:	6145                	addi	sp,sp,48
    800022e0:	8082                	ret

00000000800022e2 <exit>:
{
    800022e2:	7179                	addi	sp,sp,-48
    800022e4:	f406                	sd	ra,40(sp)
    800022e6:	f022                	sd	s0,32(sp)
    800022e8:	ec26                	sd	s1,24(sp)
    800022ea:	e84a                	sd	s2,16(sp)
    800022ec:	e44e                	sd	s3,8(sp)
    800022ee:	e052                	sd	s4,0(sp)
    800022f0:	1800                	addi	s0,sp,48
    800022f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	6e8080e7          	jalr	1768(ra) # 800019dc <myproc>
    800022fc:	89aa                	mv	s3,a0
  if (p == initproc)
    800022fe:	00006797          	auipc	a5,0x6
    80002302:	5da7b783          	ld	a5,1498(a5) # 800088d8 <initproc>
    80002306:	0d050493          	addi	s1,a0,208
    8000230a:	15050913          	addi	s2,a0,336
    8000230e:	02a79363          	bne	a5,a0,80002334 <exit+0x52>
    panic("init exiting");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	f4e50513          	addi	a0,a0,-178 # 80008260 <digits+0x220>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	226080e7          	jalr	550(ra) # 80000540 <panic>
      fileclose(f);
    80002322:	00002097          	auipc	ra,0x2
    80002326:	2f8080e7          	jalr	760(ra) # 8000461a <fileclose>
      p->ofile[fd] = 0;
    8000232a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000232e:	04a1                	addi	s1,s1,8
    80002330:	01248563          	beq	s1,s2,8000233a <exit+0x58>
    if (p->ofile[fd])
    80002334:	6088                	ld	a0,0(s1)
    80002336:	f575                	bnez	a0,80002322 <exit+0x40>
    80002338:	bfdd                	j	8000232e <exit+0x4c>
  begin_op();
    8000233a:	00002097          	auipc	ra,0x2
    8000233e:	e18080e7          	jalr	-488(ra) # 80004152 <begin_op>
  iput(p->cwd);
    80002342:	1509b503          	ld	a0,336(s3)
    80002346:	00001097          	auipc	ra,0x1
    8000234a:	5fa080e7          	jalr	1530(ra) # 80003940 <iput>
  end_op();
    8000234e:	00002097          	auipc	ra,0x2
    80002352:	e82080e7          	jalr	-382(ra) # 800041d0 <end_op>
  p->cwd = 0;
    80002356:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000235a:	0000f497          	auipc	s1,0xf
    8000235e:	80e48493          	addi	s1,s1,-2034 # 80010b68 <wait_lock>
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	872080e7          	jalr	-1934(ra) # 80000bd6 <acquire>
  reparent(p);
    8000236c:	854e                	mv	a0,s3
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	f1a080e7          	jalr	-230(ra) # 80002288 <reparent>
  wakeup(p->parent);
    80002376:	0389b503          	ld	a0,56(s3)
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	e98080e7          	jalr	-360(ra) # 80002212 <wakeup>
  acquire(&p->lock);
    80002382:	854e                	mv	a0,s3
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	852080e7          	jalr	-1966(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000238c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002390:	4795                	li	a5,5
    80002392:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
  sched();
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	cfc080e7          	jalr	-772(ra) # 8000209c <sched>
  panic("zombie exit");
    800023a8:	00006517          	auipc	a0,0x6
    800023ac:	ec850513          	addi	a0,a0,-312 # 80008270 <digits+0x230>
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	190080e7          	jalr	400(ra) # 80000540 <panic>

00000000800023b8 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023b8:	7179                	addi	sp,sp,-48
    800023ba:	f406                	sd	ra,40(sp)
    800023bc:	f022                	sd	s0,32(sp)
    800023be:	ec26                	sd	s1,24(sp)
    800023c0:	e84a                	sd	s2,16(sp)
    800023c2:	e44e                	sd	s3,8(sp)
    800023c4:	1800                	addi	s0,sp,48
    800023c6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023c8:	0000f497          	auipc	s1,0xf
    800023cc:	bb848493          	addi	s1,s1,-1096 # 80010f80 <proc>
    800023d0:	00015997          	auipc	s3,0x15
    800023d4:	1b098993          	addi	s3,s3,432 # 80017580 <tickslock>
  {
    acquire(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	7fc080e7          	jalr	2044(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800023e2:	589c                	lw	a5,48(s1)
    800023e4:	01278d63          	beq	a5,s2,800023fe <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8a0080e7          	jalr	-1888(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023f2:	19848493          	addi	s1,s1,408
    800023f6:	ff3491e3          	bne	s1,s3,800023d8 <kill+0x20>
  }
  return -1;
    800023fa:	557d                	li	a0,-1
    800023fc:	a829                	j	80002416 <kill+0x5e>
      p->killed = 1;
    800023fe:	4785                	li	a5,1
    80002400:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002402:	4c98                	lw	a4,24(s1)
    80002404:	4789                	li	a5,2
    80002406:	00f70f63          	beq	a4,a5,80002424 <kill+0x6c>
      release(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
      return 0;
    80002414:	4501                	li	a0,0
}
    80002416:	70a2                	ld	ra,40(sp)
    80002418:	7402                	ld	s0,32(sp)
    8000241a:	64e2                	ld	s1,24(sp)
    8000241c:	6942                	ld	s2,16(sp)
    8000241e:	69a2                	ld	s3,8(sp)
    80002420:	6145                	addi	sp,sp,48
    80002422:	8082                	ret
        p->state = RUNNABLE;
    80002424:	478d                	li	a5,3
    80002426:	cc9c                	sw	a5,24(s1)
    80002428:	b7cd                	j	8000240a <kill+0x52>

000000008000242a <setkilled>:

void setkilled(struct proc *p)
{
    8000242a:	1101                	addi	sp,sp,-32
    8000242c:	ec06                	sd	ra,24(sp)
    8000242e:	e822                	sd	s0,16(sp)
    80002430:	e426                	sd	s1,8(sp)
    80002432:	1000                	addi	s0,sp,32
    80002434:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000243e:	4785                	li	a5,1
    80002440:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
}
    8000244c:	60e2                	ld	ra,24(sp)
    8000244e:	6442                	ld	s0,16(sp)
    80002450:	64a2                	ld	s1,8(sp)
    80002452:	6105                	addi	sp,sp,32
    80002454:	8082                	ret

0000000080002456 <killed>:

int killed(struct proc *p)
{
    80002456:	1101                	addi	sp,sp,-32
    80002458:	ec06                	sd	ra,24(sp)
    8000245a:	e822                	sd	s0,16(sp)
    8000245c:	e426                	sd	s1,8(sp)
    8000245e:	e04a                	sd	s2,0(sp)
    80002460:	1000                	addi	s0,sp,32
    80002462:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	772080e7          	jalr	1906(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000246c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	818080e7          	jalr	-2024(ra) # 80000c8a <release>
  return k;
}
    8000247a:	854a                	mv	a0,s2
    8000247c:	60e2                	ld	ra,24(sp)
    8000247e:	6442                	ld	s0,16(sp)
    80002480:	64a2                	ld	s1,8(sp)
    80002482:	6902                	ld	s2,0(sp)
    80002484:	6105                	addi	sp,sp,32
    80002486:	8082                	ret

0000000080002488 <wait>:
{
    80002488:	715d                	addi	sp,sp,-80
    8000248a:	e486                	sd	ra,72(sp)
    8000248c:	e0a2                	sd	s0,64(sp)
    8000248e:	fc26                	sd	s1,56(sp)
    80002490:	f84a                	sd	s2,48(sp)
    80002492:	f44e                	sd	s3,40(sp)
    80002494:	f052                	sd	s4,32(sp)
    80002496:	ec56                	sd	s5,24(sp)
    80002498:	e85a                	sd	s6,16(sp)
    8000249a:	e45e                	sd	s7,8(sp)
    8000249c:	e062                	sd	s8,0(sp)
    8000249e:	0880                	addi	s0,sp,80
    800024a0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	53a080e7          	jalr	1338(ra) # 800019dc <myproc>
    800024aa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024ac:	0000e517          	auipc	a0,0xe
    800024b0:	6bc50513          	addi	a0,a0,1724 # 80010b68 <wait_lock>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	722080e7          	jalr	1826(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024bc:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024be:	4a15                	li	s4,5
        havekids = 1;
    800024c0:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c2:	00015997          	auipc	s3,0x15
    800024c6:	0be98993          	addi	s3,s3,190 # 80017580 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024ca:	0000ec17          	auipc	s8,0xe
    800024ce:	69ec0c13          	addi	s8,s8,1694 # 80010b68 <wait_lock>
    havekids = 0;
    800024d2:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d4:	0000f497          	auipc	s1,0xf
    800024d8:	aac48493          	addi	s1,s1,-1364 # 80010f80 <proc>
    800024dc:	a0bd                	j	8000254a <wait+0xc2>
          pid = pp->pid;
    800024de:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024e2:	000b0e63          	beqz	s6,800024fe <wait+0x76>
    800024e6:	4691                	li	a3,4
    800024e8:	02c48613          	addi	a2,s1,44
    800024ec:	85da                	mv	a1,s6
    800024ee:	05093503          	ld	a0,80(s2)
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	17a080e7          	jalr	378(ra) # 8000166c <copyout>
    800024fa:	02054563          	bltz	a0,80002524 <wait+0x9c>
          freeproc(pp);
    800024fe:	8526                	mv	a0,s1
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	68e080e7          	jalr	1678(ra) # 80001b8e <freeproc>
          release(&pp->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	780080e7          	jalr	1920(ra) # 80000c8a <release>
          release(&wait_lock);
    80002512:	0000e517          	auipc	a0,0xe
    80002516:	65650513          	addi	a0,a0,1622 # 80010b68 <wait_lock>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	770080e7          	jalr	1904(ra) # 80000c8a <release>
          return pid;
    80002522:	a0b5                	j	8000258e <wait+0x106>
            release(&pp->lock);
    80002524:	8526                	mv	a0,s1
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	764080e7          	jalr	1892(ra) # 80000c8a <release>
            release(&wait_lock);
    8000252e:	0000e517          	auipc	a0,0xe
    80002532:	63a50513          	addi	a0,a0,1594 # 80010b68 <wait_lock>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	754080e7          	jalr	1876(ra) # 80000c8a <release>
            return -1;
    8000253e:	59fd                	li	s3,-1
    80002540:	a0b9                	j	8000258e <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002542:	19848493          	addi	s1,s1,408
    80002546:	03348463          	beq	s1,s3,8000256e <wait+0xe6>
      if (pp->parent == p)
    8000254a:	7c9c                	ld	a5,56(s1)
    8000254c:	ff279be3          	bne	a5,s2,80002542 <wait+0xba>
        acquire(&pp->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	684080e7          	jalr	1668(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000255a:	4c9c                	lw	a5,24(s1)
    8000255c:	f94781e3          	beq	a5,s4,800024de <wait+0x56>
        release(&pp->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	728080e7          	jalr	1832(ra) # 80000c8a <release>
        havekids = 1;
    8000256a:	8756                	mv	a4,s5
    8000256c:	bfd9                	j	80002542 <wait+0xba>
    if (!havekids || killed(p))
    8000256e:	c719                	beqz	a4,8000257c <wait+0xf4>
    80002570:	854a                	mv	a0,s2
    80002572:	00000097          	auipc	ra,0x0
    80002576:	ee4080e7          	jalr	-284(ra) # 80002456 <killed>
    8000257a:	c51d                	beqz	a0,800025a8 <wait+0x120>
      release(&wait_lock);
    8000257c:	0000e517          	auipc	a0,0xe
    80002580:	5ec50513          	addi	a0,a0,1516 # 80010b68 <wait_lock>
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	706080e7          	jalr	1798(ra) # 80000c8a <release>
      return -1;
    8000258c:	59fd                	li	s3,-1
}
    8000258e:	854e                	mv	a0,s3
    80002590:	60a6                	ld	ra,72(sp)
    80002592:	6406                	ld	s0,64(sp)
    80002594:	74e2                	ld	s1,56(sp)
    80002596:	7942                	ld	s2,48(sp)
    80002598:	79a2                	ld	s3,40(sp)
    8000259a:	7a02                	ld	s4,32(sp)
    8000259c:	6ae2                	ld	s5,24(sp)
    8000259e:	6b42                	ld	s6,16(sp)
    800025a0:	6ba2                	ld	s7,8(sp)
    800025a2:	6c02                	ld	s8,0(sp)
    800025a4:	6161                	addi	sp,sp,80
    800025a6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025a8:	85e2                	mv	a1,s8
    800025aa:	854a                	mv	a0,s2
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	c02080e7          	jalr	-1022(ra) # 800021ae <sleep>
    havekids = 0;
    800025b4:	bf39                	j	800024d2 <wait+0x4a>

00000000800025b6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025b6:	7179                	addi	sp,sp,-48
    800025b8:	f406                	sd	ra,40(sp)
    800025ba:	f022                	sd	s0,32(sp)
    800025bc:	ec26                	sd	s1,24(sp)
    800025be:	e84a                	sd	s2,16(sp)
    800025c0:	e44e                	sd	s3,8(sp)
    800025c2:	e052                	sd	s4,0(sp)
    800025c4:	1800                	addi	s0,sp,48
    800025c6:	84aa                	mv	s1,a0
    800025c8:	892e                	mv	s2,a1
    800025ca:	89b2                	mv	s3,a2
    800025cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ce:	fffff097          	auipc	ra,0xfffff
    800025d2:	40e080e7          	jalr	1038(ra) # 800019dc <myproc>
  if (user_dst)
    800025d6:	c08d                	beqz	s1,800025f8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800025d8:	86d2                	mv	a3,s4
    800025da:	864e                	mv	a2,s3
    800025dc:	85ca                	mv	a1,s2
    800025de:	6928                	ld	a0,80(a0)
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	08c080e7          	jalr	140(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025e8:	70a2                	ld	ra,40(sp)
    800025ea:	7402                	ld	s0,32(sp)
    800025ec:	64e2                	ld	s1,24(sp)
    800025ee:	6942                	ld	s2,16(sp)
    800025f0:	69a2                	ld	s3,8(sp)
    800025f2:	6a02                	ld	s4,0(sp)
    800025f4:	6145                	addi	sp,sp,48
    800025f6:	8082                	ret
    memmove((char *)dst, src, len);
    800025f8:	000a061b          	sext.w	a2,s4
    800025fc:	85ce                	mv	a1,s3
    800025fe:	854a                	mv	a0,s2
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	72e080e7          	jalr	1838(ra) # 80000d2e <memmove>
    return 0;
    80002608:	8526                	mv	a0,s1
    8000260a:	bff9                	j	800025e8 <either_copyout+0x32>

000000008000260c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000260c:	7179                	addi	sp,sp,-48
    8000260e:	f406                	sd	ra,40(sp)
    80002610:	f022                	sd	s0,32(sp)
    80002612:	ec26                	sd	s1,24(sp)
    80002614:	e84a                	sd	s2,16(sp)
    80002616:	e44e                	sd	s3,8(sp)
    80002618:	e052                	sd	s4,0(sp)
    8000261a:	1800                	addi	s0,sp,48
    8000261c:	892a                	mv	s2,a0
    8000261e:	84ae                	mv	s1,a1
    80002620:	89b2                	mv	s3,a2
    80002622:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	3b8080e7          	jalr	952(ra) # 800019dc <myproc>
  if (user_src)
    8000262c:	c08d                	beqz	s1,8000264e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000262e:	86d2                	mv	a3,s4
    80002630:	864e                	mv	a2,s3
    80002632:	85ca                	mv	a1,s2
    80002634:	6928                	ld	a0,80(a0)
    80002636:	fffff097          	auipc	ra,0xfffff
    8000263a:	0c2080e7          	jalr	194(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000263e:	70a2                	ld	ra,40(sp)
    80002640:	7402                	ld	s0,32(sp)
    80002642:	64e2                	ld	s1,24(sp)
    80002644:	6942                	ld	s2,16(sp)
    80002646:	69a2                	ld	s3,8(sp)
    80002648:	6a02                	ld	s4,0(sp)
    8000264a:	6145                	addi	sp,sp,48
    8000264c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000264e:	000a061b          	sext.w	a2,s4
    80002652:	85ce                	mv	a1,s3
    80002654:	854a                	mv	a0,s2
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	6d8080e7          	jalr	1752(ra) # 80000d2e <memmove>
    return 0;
    8000265e:	8526                	mv	a0,s1
    80002660:	bff9                	j	8000263e <either_copyin+0x32>

0000000080002662 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002662:	715d                	addi	sp,sp,-80
    80002664:	e486                	sd	ra,72(sp)
    80002666:	e0a2                	sd	s0,64(sp)
    80002668:	fc26                	sd	s1,56(sp)
    8000266a:	f84a                	sd	s2,48(sp)
    8000266c:	f44e                	sd	s3,40(sp)
    8000266e:	f052                	sd	s4,32(sp)
    80002670:	ec56                	sd	s5,24(sp)
    80002672:	e85a                	sd	s6,16(sp)
    80002674:	e45e                	sd	s7,8(sp)
    80002676:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002678:	00006517          	auipc	a0,0x6
    8000267c:	a5050513          	addi	a0,a0,-1456 # 800080c8 <digits+0x88>
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	f0a080e7          	jalr	-246(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002688:	0000f497          	auipc	s1,0xf
    8000268c:	a5048493          	addi	s1,s1,-1456 # 800110d8 <proc+0x158>
    80002690:	00015917          	auipc	s2,0x15
    80002694:	04890913          	addi	s2,s2,72 # 800176d8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002698:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000269a:	00006997          	auipc	s3,0x6
    8000269e:	be698993          	addi	s3,s3,-1050 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026a2:	00006a97          	auipc	s5,0x6
    800026a6:	be6a8a93          	addi	s5,s5,-1050 # 80008288 <digits+0x248>
    printf("\n");
    800026aa:	00006a17          	auipc	s4,0x6
    800026ae:	a1ea0a13          	addi	s4,s4,-1506 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b2:	00006b97          	auipc	s7,0x6
    800026b6:	c16b8b93          	addi	s7,s7,-1002 # 800082c8 <states.0>
    800026ba:	a00d                	j	800026dc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026bc:	ed86a583          	lw	a1,-296(a3)
    800026c0:	8556                	mv	a0,s5
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	ec8080e7          	jalr	-312(ra) # 8000058a <printf>
    printf("\n");
    800026ca:	8552                	mv	a0,s4
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	ebe080e7          	jalr	-322(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026d4:	19848493          	addi	s1,s1,408
    800026d8:	03248263          	beq	s1,s2,800026fc <procdump+0x9a>
    if (p->state == UNUSED)
    800026dc:	86a6                	mv	a3,s1
    800026de:	ec04a783          	lw	a5,-320(s1)
    800026e2:	dbed                	beqz	a5,800026d4 <procdump+0x72>
      state = "???";
    800026e4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e6:	fcfb6be3          	bltu	s6,a5,800026bc <procdump+0x5a>
    800026ea:	02079713          	slli	a4,a5,0x20
    800026ee:	01d75793          	srli	a5,a4,0x1d
    800026f2:	97de                	add	a5,a5,s7
    800026f4:	6390                	ld	a2,0(a5)
    800026f6:	f279                	bnez	a2,800026bc <procdump+0x5a>
      state = "???";
    800026f8:	864e                	mv	a2,s3
    800026fa:	b7c9                	j	800026bc <procdump+0x5a>
  }
}
    800026fc:	60a6                	ld	ra,72(sp)
    800026fe:	6406                	ld	s0,64(sp)
    80002700:	74e2                	ld	s1,56(sp)
    80002702:	7942                	ld	s2,48(sp)
    80002704:	79a2                	ld	s3,40(sp)
    80002706:	7a02                	ld	s4,32(sp)
    80002708:	6ae2                	ld	s5,24(sp)
    8000270a:	6b42                	ld	s6,16(sp)
    8000270c:	6ba2                	ld	s7,8(sp)
    8000270e:	6161                	addi	sp,sp,80
    80002710:	8082                	ret

0000000080002712 <swtch>:
    80002712:	00153023          	sd	ra,0(a0)
    80002716:	00253423          	sd	sp,8(a0)
    8000271a:	e900                	sd	s0,16(a0)
    8000271c:	ed04                	sd	s1,24(a0)
    8000271e:	03253023          	sd	s2,32(a0)
    80002722:	03353423          	sd	s3,40(a0)
    80002726:	03453823          	sd	s4,48(a0)
    8000272a:	03553c23          	sd	s5,56(a0)
    8000272e:	05653023          	sd	s6,64(a0)
    80002732:	05753423          	sd	s7,72(a0)
    80002736:	05853823          	sd	s8,80(a0)
    8000273a:	05953c23          	sd	s9,88(a0)
    8000273e:	07a53023          	sd	s10,96(a0)
    80002742:	07b53423          	sd	s11,104(a0)
    80002746:	0005b083          	ld	ra,0(a1)
    8000274a:	0085b103          	ld	sp,8(a1)
    8000274e:	6980                	ld	s0,16(a1)
    80002750:	6d84                	ld	s1,24(a1)
    80002752:	0205b903          	ld	s2,32(a1)
    80002756:	0285b983          	ld	s3,40(a1)
    8000275a:	0305ba03          	ld	s4,48(a1)
    8000275e:	0385ba83          	ld	s5,56(a1)
    80002762:	0405bb03          	ld	s6,64(a1)
    80002766:	0485bb83          	ld	s7,72(a1)
    8000276a:	0505bc03          	ld	s8,80(a1)
    8000276e:	0585bc83          	ld	s9,88(a1)
    80002772:	0605bd03          	ld	s10,96(a1)
    80002776:	0685bd83          	ld	s11,104(a1)
    8000277a:	8082                	ret

000000008000277c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000277c:	1141                	addi	sp,sp,-16
    8000277e:	e406                	sd	ra,8(sp)
    80002780:	e022                	sd	s0,0(sp)
    80002782:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002784:	00006597          	auipc	a1,0x6
    80002788:	b7458593          	addi	a1,a1,-1164 # 800082f8 <states.0+0x30>
    8000278c:	00015517          	auipc	a0,0x15
    80002790:	df450513          	addi	a0,a0,-524 # 80017580 <tickslock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	3b2080e7          	jalr	946(ra) # 80000b46 <initlock>
}
    8000279c:	60a2                	ld	ra,8(sp)
    8000279e:	6402                	ld	s0,0(sp)
    800027a0:	0141                	addi	sp,sp,16
    800027a2:	8082                	ret

00000000800027a4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027a4:	1141                	addi	sp,sp,-16
    800027a6:	e422                	sd	s0,8(sp)
    800027a8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027aa:	00003797          	auipc	a5,0x3
    800027ae:	4c678793          	addi	a5,a5,1222 # 80005c70 <kernelvec>
    800027b2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027b6:	6422                	ld	s0,8(sp)
    800027b8:	0141                	addi	sp,sp,16
    800027ba:	8082                	ret

00000000800027bc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027bc:	1141                	addi	sp,sp,-16
    800027be:	e406                	sd	ra,8(sp)
    800027c0:	e022                	sd	s0,0(sp)
    800027c2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	218080e7          	jalr	536(ra) # 800019dc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027d6:	00005697          	auipc	a3,0x5
    800027da:	82a68693          	addi	a3,a3,-2006 # 80007000 <_trampoline>
    800027de:	00005717          	auipc	a4,0x5
    800027e2:	82270713          	addi	a4,a4,-2014 # 80007000 <_trampoline>
    800027e6:	8f15                	sub	a4,a4,a3
    800027e8:	040007b7          	lui	a5,0x4000
    800027ec:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800027ee:	07b2                	slli	a5,a5,0xc
    800027f0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027f6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027f8:	18002673          	csrr	a2,satp
    800027fc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027fe:	6d30                	ld	a2,88(a0)
    80002800:	6138                	ld	a4,64(a0)
    80002802:	6585                	lui	a1,0x1
    80002804:	972e                	add	a4,a4,a1
    80002806:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002808:	6d38                	ld	a4,88(a0)
    8000280a:	00000617          	auipc	a2,0x0
    8000280e:	13060613          	addi	a2,a2,304 # 8000293a <usertrap>
    80002812:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002814:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002816:	8612                	mv	a2,tp
    80002818:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000281e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002822:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002826:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000282a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000282c:	6f18                	ld	a4,24(a4)
    8000282e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002832:	6928                	ld	a0,80(a0)
    80002834:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002836:	00005717          	auipc	a4,0x5
    8000283a:	86670713          	addi	a4,a4,-1946 # 8000709c <userret>
    8000283e:	8f15                	sub	a4,a4,a3
    80002840:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002842:	577d                	li	a4,-1
    80002844:	177e                	slli	a4,a4,0x3f
    80002846:	8d59                	or	a0,a0,a4
    80002848:	9782                	jalr	a5
}
    8000284a:	60a2                	ld	ra,8(sp)
    8000284c:	6402                	ld	s0,0(sp)
    8000284e:	0141                	addi	sp,sp,16
    80002850:	8082                	ret

0000000080002852 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000285c:	00015497          	auipc	s1,0x15
    80002860:	d2448493          	addi	s1,s1,-732 # 80017580 <tickslock>
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	370080e7          	jalr	880(ra) # 80000bd6 <acquire>
  ticks++;
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	07250513          	addi	a0,a0,114 # 800088e0 <ticks>
    80002876:	411c                	lw	a5,0(a0)
    80002878:	2785                	addiw	a5,a5,1
    8000287a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	996080e7          	jalr	-1642(ra) # 80002212 <wakeup>
  release(&tickslock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	404080e7          	jalr	1028(ra) # 80000c8a <release>
}
    8000288e:	60e2                	ld	ra,24(sp)
    80002890:	6442                	ld	s0,16(sp)
    80002892:	64a2                	ld	s1,8(sp)
    80002894:	6105                	addi	sp,sp,32
    80002896:	8082                	ret

0000000080002898 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002898:	1101                	addi	sp,sp,-32
    8000289a:	ec06                	sd	ra,24(sp)
    8000289c:	e822                	sd	s0,16(sp)
    8000289e:	e426                	sd	s1,8(sp)
    800028a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028a6:	00074d63          	bltz	a4,800028c0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028aa:	57fd                	li	a5,-1
    800028ac:	17fe                	slli	a5,a5,0x3f
    800028ae:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028b0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028b2:	06f70363          	beq	a4,a5,80002918 <devintr+0x80>
  }
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret
     (scause & 0xff) == 9){
    800028c0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800028c4:	46a5                	li	a3,9
    800028c6:	fed792e3          	bne	a5,a3,800028aa <devintr+0x12>
    int irq = plic_claim();
    800028ca:	00003097          	auipc	ra,0x3
    800028ce:	4ae080e7          	jalr	1198(ra) # 80005d78 <plic_claim>
    800028d2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028d4:	47a9                	li	a5,10
    800028d6:	02f50763          	beq	a0,a5,80002904 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028da:	4785                	li	a5,1
    800028dc:	02f50963          	beq	a0,a5,8000290e <devintr+0x76>
    return 1;
    800028e0:	4505                	li	a0,1
    } else if(irq){
    800028e2:	d8f1                	beqz	s1,800028b6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028e4:	85a6                	mv	a1,s1
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a1a50513          	addi	a0,a0,-1510 # 80008300 <states.0+0x38>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c9c080e7          	jalr	-868(ra) # 8000058a <printf>
      plic_complete(irq);
    800028f6:	8526                	mv	a0,s1
    800028f8:	00003097          	auipc	ra,0x3
    800028fc:	4a4080e7          	jalr	1188(ra) # 80005d9c <plic_complete>
    return 1;
    80002900:	4505                	li	a0,1
    80002902:	bf55                	j	800028b6 <devintr+0x1e>
      uartintr();
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	094080e7          	jalr	148(ra) # 80000998 <uartintr>
    8000290c:	b7ed                	j	800028f6 <devintr+0x5e>
      virtio_disk_intr();
    8000290e:	00004097          	auipc	ra,0x4
    80002912:	956080e7          	jalr	-1706(ra) # 80006264 <virtio_disk_intr>
    80002916:	b7c5                	j	800028f6 <devintr+0x5e>
    if(cpuid() == 0){
    80002918:	fffff097          	auipc	ra,0xfffff
    8000291c:	098080e7          	jalr	152(ra) # 800019b0 <cpuid>
    80002920:	c901                	beqz	a0,80002930 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002922:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002926:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002928:	14479073          	csrw	sip,a5
    return 2;
    8000292c:	4509                	li	a0,2
    8000292e:	b761                	j	800028b6 <devintr+0x1e>
      clockintr();
    80002930:	00000097          	auipc	ra,0x0
    80002934:	f22080e7          	jalr	-222(ra) # 80002852 <clockintr>
    80002938:	b7ed                	j	80002922 <devintr+0x8a>

000000008000293a <usertrap>:
{
    8000293a:	1101                	addi	sp,sp,-32
    8000293c:	ec06                	sd	ra,24(sp)
    8000293e:	e822                	sd	s0,16(sp)
    80002940:	e426                	sd	s1,8(sp)
    80002942:	e04a                	sd	s2,0(sp)
    80002944:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000294a:	1007f793          	andi	a5,a5,256
    8000294e:	e3b1                	bnez	a5,80002992 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002950:	00003797          	auipc	a5,0x3
    80002954:	32078793          	addi	a5,a5,800 # 80005c70 <kernelvec>
    80002958:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000295c:	fffff097          	auipc	ra,0xfffff
    80002960:	080080e7          	jalr	128(ra) # 800019dc <myproc>
    80002964:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002966:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002968:	14102773          	csrr	a4,sepc
    8000296c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002972:	47a1                	li	a5,8
    80002974:	02f70763          	beq	a4,a5,800029a2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002978:	00000097          	auipc	ra,0x0
    8000297c:	f20080e7          	jalr	-224(ra) # 80002898 <devintr>
    80002980:	892a                	mv	s2,a0
    80002982:	c151                	beqz	a0,80002a06 <usertrap+0xcc>
  if(killed(p))
    80002984:	8526                	mv	a0,s1
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	ad0080e7          	jalr	-1328(ra) # 80002456 <killed>
    8000298e:	c929                	beqz	a0,800029e0 <usertrap+0xa6>
    80002990:	a099                	j	800029d6 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002992:	00006517          	auipc	a0,0x6
    80002996:	98e50513          	addi	a0,a0,-1650 # 80008320 <states.0+0x58>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	ba6080e7          	jalr	-1114(ra) # 80000540 <panic>
    if(killed(p))
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	ab4080e7          	jalr	-1356(ra) # 80002456 <killed>
    800029aa:	e921                	bnez	a0,800029fa <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029ac:	6cb8                	ld	a4,88(s1)
    800029ae:	6f1c                	ld	a5,24(a4)
    800029b0:	0791                	addi	a5,a5,4
    800029b2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10079073          	csrw	sstatus,a5
    syscall();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	2d4080e7          	jalr	724(ra) # 80002c94 <syscall>
  if(killed(p))
    800029c8:	8526                	mv	a0,s1
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	a8c080e7          	jalr	-1396(ra) # 80002456 <killed>
    800029d2:	c911                	beqz	a0,800029e6 <usertrap+0xac>
    800029d4:	4901                	li	s2,0
    exit(-1);
    800029d6:	557d                	li	a0,-1
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	90a080e7          	jalr	-1782(ra) # 800022e2 <exit>
  if(which_dev == 2)
    800029e0:	4789                	li	a5,2
    800029e2:	04f90f63          	beq	s2,a5,80002a40 <usertrap+0x106>
  usertrapret();
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	dd6080e7          	jalr	-554(ra) # 800027bc <usertrapret>
}
    800029ee:	60e2                	ld	ra,24(sp)
    800029f0:	6442                	ld	s0,16(sp)
    800029f2:	64a2                	ld	s1,8(sp)
    800029f4:	6902                	ld	s2,0(sp)
    800029f6:	6105                	addi	sp,sp,32
    800029f8:	8082                	ret
      exit(-1);
    800029fa:	557d                	li	a0,-1
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	8e6080e7          	jalr	-1818(ra) # 800022e2 <exit>
    80002a04:	b765                	j	800029ac <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a06:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a0a:	5890                	lw	a2,48(s1)
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	93450513          	addi	a0,a0,-1740 # 80008340 <states.0+0x78>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b76080e7          	jalr	-1162(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a20:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a24:	00006517          	auipc	a0,0x6
    80002a28:	94c50513          	addi	a0,a0,-1716 # 80008370 <states.0+0xa8>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	b5e080e7          	jalr	-1186(ra) # 8000058a <printf>
    setkilled(p);
    80002a34:	8526                	mv	a0,s1
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	9f4080e7          	jalr	-1548(ra) # 8000242a <setkilled>
    80002a3e:	b769                	j	800029c8 <usertrap+0x8e>
    yield();
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	732080e7          	jalr	1842(ra) # 80002172 <yield>
    80002a48:	bf79                	j	800029e6 <usertrap+0xac>

0000000080002a4a <kerneltrap>:
{
    80002a4a:	7179                	addi	sp,sp,-48
    80002a4c:	f406                	sd	ra,40(sp)
    80002a4e:	f022                	sd	s0,32(sp)
    80002a50:	ec26                	sd	s1,24(sp)
    80002a52:	e84a                	sd	s2,16(sp)
    80002a54:	e44e                	sd	s3,8(sp)
    80002a56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a60:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a64:	1004f793          	andi	a5,s1,256
    80002a68:	cb85                	beqz	a5,80002a98 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a6e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a70:	ef85                	bnez	a5,80002aa8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	e26080e7          	jalr	-474(ra) # 80002898 <devintr>
    80002a7a:	cd1d                	beqz	a0,80002ab8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a7c:	4789                	li	a5,2
    80002a7e:	06f50a63          	beq	a0,a5,80002af2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a82:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a86:	10049073          	csrw	sstatus,s1
}
    80002a8a:	70a2                	ld	ra,40(sp)
    80002a8c:	7402                	ld	s0,32(sp)
    80002a8e:	64e2                	ld	s1,24(sp)
    80002a90:	6942                	ld	s2,16(sp)
    80002a92:	69a2                	ld	s3,8(sp)
    80002a94:	6145                	addi	sp,sp,48
    80002a96:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	8f850513          	addi	a0,a0,-1800 # 80008390 <states.0+0xc8>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aa0080e7          	jalr	-1376(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	91050513          	addi	a0,a0,-1776 # 800083b8 <states.0+0xf0>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a90080e7          	jalr	-1392(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002ab8:	85ce                	mv	a1,s3
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	91e50513          	addi	a0,a0,-1762 # 800083d8 <states.0+0x110>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	ac8080e7          	jalr	-1336(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ace:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	91650513          	addi	a0,a0,-1770 # 800083e8 <states.0+0x120>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	ab0080e7          	jalr	-1360(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	91e50513          	addi	a0,a0,-1762 # 80008400 <states.0+0x138>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a56080e7          	jalr	-1450(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	eea080e7          	jalr	-278(ra) # 800019dc <myproc>
    80002afa:	d541                	beqz	a0,80002a82 <kerneltrap+0x38>
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	ee0080e7          	jalr	-288(ra) # 800019dc <myproc>
    80002b04:	4d18                	lw	a4,24(a0)
    80002b06:	4791                	li	a5,4
    80002b08:	f6f71de3          	bne	a4,a5,80002a82 <kerneltrap+0x38>
    yield();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	666080e7          	jalr	1638(ra) # 80002172 <yield>
    80002b14:	b7bd                	j	80002a82 <kerneltrap+0x38>

0000000080002b16 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
    80002b20:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	eba080e7          	jalr	-326(ra) # 800019dc <myproc>
  switch (n) {
    80002b2a:	4795                	li	a5,5
    80002b2c:	0497e163          	bltu	a5,s1,80002b6e <argraw+0x58>
    80002b30:	048a                	slli	s1,s1,0x2
    80002b32:	00006717          	auipc	a4,0x6
    80002b36:	90670713          	addi	a4,a4,-1786 # 80008438 <states.0+0x170>
    80002b3a:	94ba                	add	s1,s1,a4
    80002b3c:	409c                	lw	a5,0(s1)
    80002b3e:	97ba                	add	a5,a5,a4
    80002b40:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b42:	6d3c                	ld	a5,88(a0)
    80002b44:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret
    return p->trapframe->a1;
    80002b50:	6d3c                	ld	a5,88(a0)
    80002b52:	7fa8                	ld	a0,120(a5)
    80002b54:	bfcd                	j	80002b46 <argraw+0x30>
    return p->trapframe->a2;
    80002b56:	6d3c                	ld	a5,88(a0)
    80002b58:	63c8                	ld	a0,128(a5)
    80002b5a:	b7f5                	j	80002b46 <argraw+0x30>
    return p->trapframe->a3;
    80002b5c:	6d3c                	ld	a5,88(a0)
    80002b5e:	67c8                	ld	a0,136(a5)
    80002b60:	b7dd                	j	80002b46 <argraw+0x30>
    return p->trapframe->a4;
    80002b62:	6d3c                	ld	a5,88(a0)
    80002b64:	6bc8                	ld	a0,144(a5)
    80002b66:	b7c5                	j	80002b46 <argraw+0x30>
    return p->trapframe->a5;
    80002b68:	6d3c                	ld	a5,88(a0)
    80002b6a:	6fc8                	ld	a0,152(a5)
    80002b6c:	bfe9                	j	80002b46 <argraw+0x30>
  panic("argraw");
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	8a250513          	addi	a0,a0,-1886 # 80008410 <states.0+0x148>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>

0000000080002b7e <fetchaddr>:
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	e04a                	sd	s2,0(sp)
    80002b88:	1000                	addi	s0,sp,32
    80002b8a:	84aa                	mv	s1,a0
    80002b8c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	e4e080e7          	jalr	-434(ra) # 800019dc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b96:	653c                	ld	a5,72(a0)
    80002b98:	02f4f863          	bgeu	s1,a5,80002bc8 <fetchaddr+0x4a>
    80002b9c:	00848713          	addi	a4,s1,8
    80002ba0:	02e7e663          	bltu	a5,a4,80002bcc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ba4:	46a1                	li	a3,8
    80002ba6:	8626                	mv	a2,s1
    80002ba8:	85ca                	mv	a1,s2
    80002baa:	6928                	ld	a0,80(a0)
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	b4c080e7          	jalr	-1204(ra) # 800016f8 <copyin>
    80002bb4:	00a03533          	snez	a0,a0
    80002bb8:	40a00533          	neg	a0,a0
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret
    return -1;
    80002bc8:	557d                	li	a0,-1
    80002bca:	bfcd                	j	80002bbc <fetchaddr+0x3e>
    80002bcc:	557d                	li	a0,-1
    80002bce:	b7fd                	j	80002bbc <fetchaddr+0x3e>

0000000080002bd0 <fetchstr>:
{
    80002bd0:	7179                	addi	sp,sp,-48
    80002bd2:	f406                	sd	ra,40(sp)
    80002bd4:	f022                	sd	s0,32(sp)
    80002bd6:	ec26                	sd	s1,24(sp)
    80002bd8:	e84a                	sd	s2,16(sp)
    80002bda:	e44e                	sd	s3,8(sp)
    80002bdc:	1800                	addi	s0,sp,48
    80002bde:	892a                	mv	s2,a0
    80002be0:	84ae                	mv	s1,a1
    80002be2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	df8080e7          	jalr	-520(ra) # 800019dc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bec:	86ce                	mv	a3,s3
    80002bee:	864a                	mv	a2,s2
    80002bf0:	85a6                	mv	a1,s1
    80002bf2:	6928                	ld	a0,80(a0)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	b92080e7          	jalr	-1134(ra) # 80001786 <copyinstr>
    80002bfc:	00054e63          	bltz	a0,80002c18 <fetchstr+0x48>
  return strlen(buf);
    80002c00:	8526                	mv	a0,s1
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	24c080e7          	jalr	588(ra) # 80000e4e <strlen>
}
    80002c0a:	70a2                	ld	ra,40(sp)
    80002c0c:	7402                	ld	s0,32(sp)
    80002c0e:	64e2                	ld	s1,24(sp)
    80002c10:	6942                	ld	s2,16(sp)
    80002c12:	69a2                	ld	s3,8(sp)
    80002c14:	6145                	addi	sp,sp,48
    80002c16:	8082                	ret
    return -1;
    80002c18:	557d                	li	a0,-1
    80002c1a:	bfc5                	j	80002c0a <fetchstr+0x3a>

0000000080002c1c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	e426                	sd	s1,8(sp)
    80002c24:	1000                	addi	s0,sp,32
    80002c26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	eee080e7          	jalr	-274(ra) # 80002b16 <argraw>
    80002c30:	c088                	sw	a0,0(s1)
}
    80002c32:	60e2                	ld	ra,24(sp)
    80002c34:	6442                	ld	s0,16(sp)
    80002c36:	64a2                	ld	s1,8(sp)
    80002c38:	6105                	addi	sp,sp,32
    80002c3a:	8082                	ret

0000000080002c3c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	1000                	addi	s0,sp,32
    80002c46:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	ece080e7          	jalr	-306(ra) # 80002b16 <argraw>
    80002c50:	e088                	sd	a0,0(s1)
}
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c5c:	7179                	addi	sp,sp,-48
    80002c5e:	f406                	sd	ra,40(sp)
    80002c60:	f022                	sd	s0,32(sp)
    80002c62:	ec26                	sd	s1,24(sp)
    80002c64:	e84a                	sd	s2,16(sp)
    80002c66:	1800                	addi	s0,sp,48
    80002c68:	84ae                	mv	s1,a1
    80002c6a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c6c:	fd840593          	addi	a1,s0,-40
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	fcc080e7          	jalr	-52(ra) # 80002c3c <argaddr>
  return fetchstr(addr, buf, max);
    80002c78:	864a                	mv	a2,s2
    80002c7a:	85a6                	mv	a1,s1
    80002c7c:	fd843503          	ld	a0,-40(s0)
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	f50080e7          	jalr	-176(ra) # 80002bd0 <fetchstr>
}
    80002c88:	70a2                	ld	ra,40(sp)
    80002c8a:	7402                	ld	s0,32(sp)
    80002c8c:	64e2                	ld	s1,24(sp)
    80002c8e:	6942                	ld	s2,16(sp)
    80002c90:	6145                	addi	sp,sp,48
    80002c92:	8082                	ret

0000000080002c94 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	e04a                	sd	s2,0(sp)
    80002c9e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d3c080e7          	jalr	-708(ra) # 800019dc <myproc>
    80002ca8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002caa:	05853903          	ld	s2,88(a0)
    80002cae:	0a893783          	ld	a5,168(s2)
    80002cb2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cb6:	37fd                	addiw	a5,a5,-1
    80002cb8:	4751                	li	a4,20
    80002cba:	00f76f63          	bltu	a4,a5,80002cd8 <syscall+0x44>
    80002cbe:	00369713          	slli	a4,a3,0x3
    80002cc2:	00005797          	auipc	a5,0x5
    80002cc6:	78e78793          	addi	a5,a5,1934 # 80008450 <syscalls>
    80002cca:	97ba                	add	a5,a5,a4
    80002ccc:	639c                	ld	a5,0(a5)
    80002cce:	c789                	beqz	a5,80002cd8 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cd0:	9782                	jalr	a5
    80002cd2:	06a93823          	sd	a0,112(s2)
    80002cd6:	a839                	j	80002cf4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cd8:	15848613          	addi	a2,s1,344
    80002cdc:	588c                	lw	a1,48(s1)
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	73a50513          	addi	a0,a0,1850 # 80008418 <states.0+0x150>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	8a4080e7          	jalr	-1884(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cee:	6cbc                	ld	a5,88(s1)
    80002cf0:	577d                	li	a4,-1
    80002cf2:	fbb8                	sd	a4,112(a5)
  }
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6902                	ld	s2,0(sp)
    80002cfc:	6105                	addi	sp,sp,32
    80002cfe:	8082                	ret

0000000080002d00 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d08:	fec40593          	addi	a1,s0,-20
    80002d0c:	4501                	li	a0,0
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	f0e080e7          	jalr	-242(ra) # 80002c1c <argint>
  exit(n);
    80002d16:	fec42503          	lw	a0,-20(s0)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	5c8080e7          	jalr	1480(ra) # 800022e2 <exit>
  return 0;  // not reached
}
    80002d22:	4501                	li	a0,0
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d2c:	1141                	addi	sp,sp,-16
    80002d2e:	e406                	sd	ra,8(sp)
    80002d30:	e022                	sd	s0,0(sp)
    80002d32:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	ca8080e7          	jalr	-856(ra) # 800019dc <myproc>
}
    80002d3c:	5908                	lw	a0,48(a0)
    80002d3e:	60a2                	ld	ra,8(sp)
    80002d40:	6402                	ld	s0,0(sp)
    80002d42:	0141                	addi	sp,sp,16
    80002d44:	8082                	ret

0000000080002d46 <sys_fork>:

uint64
sys_fork(void)
{
    80002d46:	1141                	addi	sp,sp,-16
    80002d48:	e406                	sd	ra,8(sp)
    80002d4a:	e022                	sd	s0,0(sp)
    80002d4c:	0800                	addi	s0,sp,16
  return fork();
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	06c080e7          	jalr	108(ra) # 80001dba <fork>
}
    80002d56:	60a2                	ld	ra,8(sp)
    80002d58:	6402                	ld	s0,0(sp)
    80002d5a:	0141                	addi	sp,sp,16
    80002d5c:	8082                	ret

0000000080002d5e <sys_wait>:

uint64
sys_wait(void)
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d66:	fe840593          	addi	a1,s0,-24
    80002d6a:	4501                	li	a0,0
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	ed0080e7          	jalr	-304(ra) # 80002c3c <argaddr>
  return wait(p);
    80002d74:	fe843503          	ld	a0,-24(s0)
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	710080e7          	jalr	1808(ra) # 80002488 <wait>
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d88:	7179                	addi	sp,sp,-48
    80002d8a:	f406                	sd	ra,40(sp)
    80002d8c:	f022                	sd	s0,32(sp)
    80002d8e:	ec26                	sd	s1,24(sp)
    80002d90:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d92:	fdc40593          	addi	a1,s0,-36
    80002d96:	4501                	li	a0,0
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	e84080e7          	jalr	-380(ra) # 80002c1c <argint>
  addr = myproc()->sz;
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c3c080e7          	jalr	-964(ra) # 800019dc <myproc>
    80002da8:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002daa:	fdc42503          	lw	a0,-36(s0)
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	fb0080e7          	jalr	-80(ra) # 80001d5e <growproc>
    80002db6:	00054863          	bltz	a0,80002dc6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dba:	8526                	mv	a0,s1
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6145                	addi	sp,sp,48
    80002dc4:	8082                	ret
    return -1;
    80002dc6:	54fd                	li	s1,-1
    80002dc8:	bfcd                	j	80002dba <sys_sbrk+0x32>

0000000080002dca <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dca:	7139                	addi	sp,sp,-64
    80002dcc:	fc06                	sd	ra,56(sp)
    80002dce:	f822                	sd	s0,48(sp)
    80002dd0:	f426                	sd	s1,40(sp)
    80002dd2:	f04a                	sd	s2,32(sp)
    80002dd4:	ec4e                	sd	s3,24(sp)
    80002dd6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dd8:	fcc40593          	addi	a1,s0,-52
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	e3e080e7          	jalr	-450(ra) # 80002c1c <argint>
  acquire(&tickslock);
    80002de6:	00014517          	auipc	a0,0x14
    80002dea:	79a50513          	addi	a0,a0,1946 # 80017580 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	de8080e7          	jalr	-536(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002df6:	00006917          	auipc	s2,0x6
    80002dfa:	aea92903          	lw	s2,-1302(s2) # 800088e0 <ticks>
  while(ticks - ticks0 < n){
    80002dfe:	fcc42783          	lw	a5,-52(s0)
    80002e02:	cf9d                	beqz	a5,80002e40 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e04:	00014997          	auipc	s3,0x14
    80002e08:	77c98993          	addi	s3,s3,1916 # 80017580 <tickslock>
    80002e0c:	00006497          	auipc	s1,0x6
    80002e10:	ad448493          	addi	s1,s1,-1324 # 800088e0 <ticks>
    if(killed(myproc())){
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	bc8080e7          	jalr	-1080(ra) # 800019dc <myproc>
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	63a080e7          	jalr	1594(ra) # 80002456 <killed>
    80002e24:	ed15                	bnez	a0,80002e60 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e26:	85ce                	mv	a1,s3
    80002e28:	8526                	mv	a0,s1
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	384080e7          	jalr	900(ra) # 800021ae <sleep>
  while(ticks - ticks0 < n){
    80002e32:	409c                	lw	a5,0(s1)
    80002e34:	412787bb          	subw	a5,a5,s2
    80002e38:	fcc42703          	lw	a4,-52(s0)
    80002e3c:	fce7ece3          	bltu	a5,a4,80002e14 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e40:	00014517          	auipc	a0,0x14
    80002e44:	74050513          	addi	a0,a0,1856 # 80017580 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  return 0;
    80002e50:	4501                	li	a0,0
}
    80002e52:	70e2                	ld	ra,56(sp)
    80002e54:	7442                	ld	s0,48(sp)
    80002e56:	74a2                	ld	s1,40(sp)
    80002e58:	7902                	ld	s2,32(sp)
    80002e5a:	69e2                	ld	s3,24(sp)
    80002e5c:	6121                	addi	sp,sp,64
    80002e5e:	8082                	ret
      release(&tickslock);
    80002e60:	00014517          	auipc	a0,0x14
    80002e64:	72050513          	addi	a0,a0,1824 # 80017580 <tickslock>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
      return -1;
    80002e70:	557d                	li	a0,-1
    80002e72:	b7c5                	j	80002e52 <sys_sleep+0x88>

0000000080002e74 <sys_kill>:

uint64
sys_kill(void)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e7c:	fec40593          	addi	a1,s0,-20
    80002e80:	4501                	li	a0,0
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	d9a080e7          	jalr	-614(ra) # 80002c1c <argint>
  return kill(pid);
    80002e8a:	fec42503          	lw	a0,-20(s0)
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	52a080e7          	jalr	1322(ra) # 800023b8 <kill>
}
    80002e96:	60e2                	ld	ra,24(sp)
    80002e98:	6442                	ld	s0,16(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	e426                	sd	s1,8(sp)
    80002ea6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	6d850513          	addi	a0,a0,1752 # 80017580 <tickslock>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d26080e7          	jalr	-730(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002eb8:	00006497          	auipc	s1,0x6
    80002ebc:	a284a483          	lw	s1,-1496(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	6c050513          	addi	a0,a0,1728 # 80017580 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
  return xticks;
}
    80002ed0:	02049513          	slli	a0,s1,0x20
    80002ed4:	9101                	srli	a0,a0,0x20
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	64a2                	ld	s1,8(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ee0:	7179                	addi	sp,sp,-48
    80002ee2:	f406                	sd	ra,40(sp)
    80002ee4:	f022                	sd	s0,32(sp)
    80002ee6:	ec26                	sd	s1,24(sp)
    80002ee8:	e84a                	sd	s2,16(sp)
    80002eea:	e44e                	sd	s3,8(sp)
    80002eec:	e052                	sd	s4,0(sp)
    80002eee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ef0:	00005597          	auipc	a1,0x5
    80002ef4:	61058593          	addi	a1,a1,1552 # 80008500 <syscalls+0xb0>
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	6a050513          	addi	a0,a0,1696 # 80017598 <bcache>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	c46080e7          	jalr	-954(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f08:	0001c797          	auipc	a5,0x1c
    80002f0c:	69078793          	addi	a5,a5,1680 # 8001f598 <bcache+0x8000>
    80002f10:	0001d717          	auipc	a4,0x1d
    80002f14:	8f070713          	addi	a4,a4,-1808 # 8001f800 <bcache+0x8268>
    80002f18:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f1c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	00014497          	auipc	s1,0x14
    80002f24:	69048493          	addi	s1,s1,1680 # 800175b0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f28:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f2a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f2c:	00005a17          	auipc	s4,0x5
    80002f30:	5dca0a13          	addi	s4,s4,1500 # 80008508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f34:	2b893783          	ld	a5,696(s2)
    80002f38:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f3a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f3e:	85d2                	mv	a1,s4
    80002f40:	01048513          	addi	a0,s1,16
    80002f44:	00001097          	auipc	ra,0x1
    80002f48:	4c8080e7          	jalr	1224(ra) # 8000440c <initsleeplock>
    bcache.head.next->prev = b;
    80002f4c:	2b893783          	ld	a5,696(s2)
    80002f50:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f52:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f56:	45848493          	addi	s1,s1,1112
    80002f5a:	fd349de3          	bne	s1,s3,80002f34 <binit+0x54>
  }
}
    80002f5e:	70a2                	ld	ra,40(sp)
    80002f60:	7402                	ld	s0,32(sp)
    80002f62:	64e2                	ld	s1,24(sp)
    80002f64:	6942                	ld	s2,16(sp)
    80002f66:	69a2                	ld	s3,8(sp)
    80002f68:	6a02                	ld	s4,0(sp)
    80002f6a:	6145                	addi	sp,sp,48
    80002f6c:	8082                	ret

0000000080002f6e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f6e:	7179                	addi	sp,sp,-48
    80002f70:	f406                	sd	ra,40(sp)
    80002f72:	f022                	sd	s0,32(sp)
    80002f74:	ec26                	sd	s1,24(sp)
    80002f76:	e84a                	sd	s2,16(sp)
    80002f78:	e44e                	sd	s3,8(sp)
    80002f7a:	1800                	addi	s0,sp,48
    80002f7c:	892a                	mv	s2,a0
    80002f7e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f80:	00014517          	auipc	a0,0x14
    80002f84:	61850513          	addi	a0,a0,1560 # 80017598 <bcache>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	c4e080e7          	jalr	-946(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f90:	0001d497          	auipc	s1,0x1d
    80002f94:	8c04b483          	ld	s1,-1856(s1) # 8001f850 <bcache+0x82b8>
    80002f98:	0001d797          	auipc	a5,0x1d
    80002f9c:	86878793          	addi	a5,a5,-1944 # 8001f800 <bcache+0x8268>
    80002fa0:	02f48f63          	beq	s1,a5,80002fde <bread+0x70>
    80002fa4:	873e                	mv	a4,a5
    80002fa6:	a021                	j	80002fae <bread+0x40>
    80002fa8:	68a4                	ld	s1,80(s1)
    80002faa:	02e48a63          	beq	s1,a4,80002fde <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fae:	449c                	lw	a5,8(s1)
    80002fb0:	ff279ce3          	bne	a5,s2,80002fa8 <bread+0x3a>
    80002fb4:	44dc                	lw	a5,12(s1)
    80002fb6:	ff3799e3          	bne	a5,s3,80002fa8 <bread+0x3a>
      b->refcnt++;
    80002fba:	40bc                	lw	a5,64(s1)
    80002fbc:	2785                	addiw	a5,a5,1
    80002fbe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	5d850513          	addi	a0,a0,1496 # 80017598 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fd0:	01048513          	addi	a0,s1,16
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	472080e7          	jalr	1138(ra) # 80004446 <acquiresleep>
      return b;
    80002fdc:	a8b9                	j	8000303a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fde:	0001d497          	auipc	s1,0x1d
    80002fe2:	86a4b483          	ld	s1,-1942(s1) # 8001f848 <bcache+0x82b0>
    80002fe6:	0001d797          	auipc	a5,0x1d
    80002fea:	81a78793          	addi	a5,a5,-2022 # 8001f800 <bcache+0x8268>
    80002fee:	00f48863          	beq	s1,a5,80002ffe <bread+0x90>
    80002ff2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ff4:	40bc                	lw	a5,64(s1)
    80002ff6:	cf81                	beqz	a5,8000300e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff8:	64a4                	ld	s1,72(s1)
    80002ffa:	fee49de3          	bne	s1,a4,80002ff4 <bread+0x86>
  panic("bget: no buffers");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	51250513          	addi	a0,a0,1298 # 80008510 <syscalls+0xc0>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	53a080e7          	jalr	1338(ra) # 80000540 <panic>
      b->dev = dev;
    8000300e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003012:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003016:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000301a:	4785                	li	a5,1
    8000301c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301e:	00014517          	auipc	a0,0x14
    80003022:	57a50513          	addi	a0,a0,1402 # 80017598 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	c64080e7          	jalr	-924(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000302e:	01048513          	addi	a0,s1,16
    80003032:	00001097          	auipc	ra,0x1
    80003036:	414080e7          	jalr	1044(ra) # 80004446 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000303a:	409c                	lw	a5,0(s1)
    8000303c:	cb89                	beqz	a5,8000304e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000303e:	8526                	mv	a0,s1
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	69a2                	ld	s3,8(sp)
    8000304a:	6145                	addi	sp,sp,48
    8000304c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000304e:	4581                	li	a1,0
    80003050:	8526                	mv	a0,s1
    80003052:	00003097          	auipc	ra,0x3
    80003056:	fe0080e7          	jalr	-32(ra) # 80006032 <virtio_disk_rw>
    b->valid = 1;
    8000305a:	4785                	li	a5,1
    8000305c:	c09c                	sw	a5,0(s1)
  return b;
    8000305e:	b7c5                	j	8000303e <bread+0xd0>

0000000080003060 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	1000                	addi	s0,sp,32
    8000306a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306c:	0541                	addi	a0,a0,16
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	472080e7          	jalr	1138(ra) # 800044e0 <holdingsleep>
    80003076:	cd01                	beqz	a0,8000308e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003078:	4585                	li	a1,1
    8000307a:	8526                	mv	a0,s1
    8000307c:	00003097          	auipc	ra,0x3
    80003080:	fb6080e7          	jalr	-74(ra) # 80006032 <virtio_disk_rw>
}
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	64a2                	ld	s1,8(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret
    panic("bwrite");
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	49a50513          	addi	a0,a0,1178 # 80008528 <syscalls+0xd8>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>

000000008000309e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	e04a                	sd	s2,0(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ac:	01050913          	addi	s2,a0,16
    800030b0:	854a                	mv	a0,s2
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	42e080e7          	jalr	1070(ra) # 800044e0 <holdingsleep>
    800030ba:	c92d                	beqz	a0,8000312c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030bc:	854a                	mv	a0,s2
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	3de080e7          	jalr	990(ra) # 8000449c <releasesleep>

  acquire(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	4d250513          	addi	a0,a0,1234 # 80017598 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	b08080e7          	jalr	-1272(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	37fd                	addiw	a5,a5,-1
    800030da:	0007871b          	sext.w	a4,a5
    800030de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030e0:	eb05                	bnez	a4,80003110 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030e2:	68bc                	ld	a5,80(s1)
    800030e4:	64b8                	ld	a4,72(s1)
    800030e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030e8:	64bc                	ld	a5,72(s1)
    800030ea:	68b8                	ld	a4,80(s1)
    800030ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ee:	0001c797          	auipc	a5,0x1c
    800030f2:	4aa78793          	addi	a5,a5,1194 # 8001f598 <bcache+0x8000>
    800030f6:	2b87b703          	ld	a4,696(a5)
    800030fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030fc:	0001c717          	auipc	a4,0x1c
    80003100:	70470713          	addi	a4,a4,1796 # 8001f800 <bcache+0x8268>
    80003104:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003106:	2b87b703          	ld	a4,696(a5)
    8000310a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000310c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	48850513          	addi	a0,a0,1160 # 80017598 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	b72080e7          	jalr	-1166(ra) # 80000c8a <release>
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6902                	ld	s2,0(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret
    panic("brelse");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	40450513          	addi	a0,a0,1028 # 80008530 <syscalls+0xe0>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	40c080e7          	jalr	1036(ra) # 80000540 <panic>

000000008000313c <bpin>:

void
bpin(struct buf *b) {
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	1000                	addi	s0,sp,32
    80003146:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	45050513          	addi	a0,a0,1104 # 80017598 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	a86080e7          	jalr	-1402(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003158:	40bc                	lw	a5,64(s1)
    8000315a:	2785                	addiw	a5,a5,1
    8000315c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315e:	00014517          	auipc	a0,0x14
    80003162:	43a50513          	addi	a0,a0,1082 # 80017598 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <bunpin>:

void
bunpin(struct buf *b) {
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	41450513          	addi	a0,a0,1044 # 80017598 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003194:	40bc                	lw	a5,64(s1)
    80003196:	37fd                	addiw	a5,a5,-1
    80003198:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000319a:	00014517          	auipc	a0,0x14
    8000319e:	3fe50513          	addi	a0,a0,1022 # 80017598 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	e04a                	sd	s2,0(sp)
    800031be:	1000                	addi	s0,sp,32
    800031c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031c2:	00d5d59b          	srliw	a1,a1,0xd
    800031c6:	0001d797          	auipc	a5,0x1d
    800031ca:	aae7a783          	lw	a5,-1362(a5) # 8001fc74 <sb+0x1c>
    800031ce:	9dbd                	addw	a1,a1,a5
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	d9e080e7          	jalr	-610(ra) # 80002f6e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031d8:	0074f713          	andi	a4,s1,7
    800031dc:	4785                	li	a5,1
    800031de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031e2:	14ce                	slli	s1,s1,0x33
    800031e4:	90d9                	srli	s1,s1,0x36
    800031e6:	00950733          	add	a4,a0,s1
    800031ea:	05874703          	lbu	a4,88(a4)
    800031ee:	00e7f6b3          	and	a3,a5,a4
    800031f2:	c69d                	beqz	a3,80003220 <bfree+0x6c>
    800031f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031f6:	94aa                	add	s1,s1,a0
    800031f8:	fff7c793          	not	a5,a5
    800031fc:	8f7d                	and	a4,a4,a5
    800031fe:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003202:	00001097          	auipc	ra,0x1
    80003206:	126080e7          	jalr	294(ra) # 80004328 <log_write>
  brelse(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	e92080e7          	jalr	-366(ra) # 8000309e <brelse>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	64a2                	ld	s1,8(sp)
    8000321a:	6902                	ld	s2,0(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret
    panic("freeing free block");
    80003220:	00005517          	auipc	a0,0x5
    80003224:	31850513          	addi	a0,a0,792 # 80008538 <syscalls+0xe8>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	318080e7          	jalr	792(ra) # 80000540 <panic>

0000000080003230 <balloc>:
{
    80003230:	711d                	addi	sp,sp,-96
    80003232:	ec86                	sd	ra,88(sp)
    80003234:	e8a2                	sd	s0,80(sp)
    80003236:	e4a6                	sd	s1,72(sp)
    80003238:	e0ca                	sd	s2,64(sp)
    8000323a:	fc4e                	sd	s3,56(sp)
    8000323c:	f852                	sd	s4,48(sp)
    8000323e:	f456                	sd	s5,40(sp)
    80003240:	f05a                	sd	s6,32(sp)
    80003242:	ec5e                	sd	s7,24(sp)
    80003244:	e862                	sd	s8,16(sp)
    80003246:	e466                	sd	s9,8(sp)
    80003248:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000324a:	0001d797          	auipc	a5,0x1d
    8000324e:	a127a783          	lw	a5,-1518(a5) # 8001fc5c <sb+0x4>
    80003252:	cff5                	beqz	a5,8000334e <balloc+0x11e>
    80003254:	8baa                	mv	s7,a0
    80003256:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003258:	0001db17          	auipc	s6,0x1d
    8000325c:	a00b0b13          	addi	s6,s6,-1536 # 8001fc58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003260:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003262:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003264:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003266:	6c89                	lui	s9,0x2
    80003268:	a061                	j	800032f0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000326a:	97ca                	add	a5,a5,s2
    8000326c:	8e55                	or	a2,a2,a3
    8000326e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003272:	854a                	mv	a0,s2
    80003274:	00001097          	auipc	ra,0x1
    80003278:	0b4080e7          	jalr	180(ra) # 80004328 <log_write>
        brelse(bp);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	e20080e7          	jalr	-480(ra) # 8000309e <brelse>
  bp = bread(dev, bno);
    80003286:	85a6                	mv	a1,s1
    80003288:	855e                	mv	a0,s7
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	ce4080e7          	jalr	-796(ra) # 80002f6e <bread>
    80003292:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003294:	40000613          	li	a2,1024
    80003298:	4581                	li	a1,0
    8000329a:	05850513          	addi	a0,a0,88
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	a34080e7          	jalr	-1484(ra) # 80000cd2 <memset>
  log_write(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	080080e7          	jalr	128(ra) # 80004328 <log_write>
  brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	dec080e7          	jalr	-532(ra) # 8000309e <brelse>
}
    800032ba:	8526                	mv	a0,s1
    800032bc:	60e6                	ld	ra,88(sp)
    800032be:	6446                	ld	s0,80(sp)
    800032c0:	64a6                	ld	s1,72(sp)
    800032c2:	6906                	ld	s2,64(sp)
    800032c4:	79e2                	ld	s3,56(sp)
    800032c6:	7a42                	ld	s4,48(sp)
    800032c8:	7aa2                	ld	s5,40(sp)
    800032ca:	7b02                	ld	s6,32(sp)
    800032cc:	6be2                	ld	s7,24(sp)
    800032ce:	6c42                	ld	s8,16(sp)
    800032d0:	6ca2                	ld	s9,8(sp)
    800032d2:	6125                	addi	sp,sp,96
    800032d4:	8082                	ret
    brelse(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	dc6080e7          	jalr	-570(ra) # 8000309e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032e0:	015c87bb          	addw	a5,s9,s5
    800032e4:	00078a9b          	sext.w	s5,a5
    800032e8:	004b2703          	lw	a4,4(s6)
    800032ec:	06eaf163          	bgeu	s5,a4,8000334e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032f0:	41fad79b          	sraiw	a5,s5,0x1f
    800032f4:	0137d79b          	srliw	a5,a5,0x13
    800032f8:	015787bb          	addw	a5,a5,s5
    800032fc:	40d7d79b          	sraiw	a5,a5,0xd
    80003300:	01cb2583          	lw	a1,28(s6)
    80003304:	9dbd                	addw	a1,a1,a5
    80003306:	855e                	mv	a0,s7
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	c66080e7          	jalr	-922(ra) # 80002f6e <bread>
    80003310:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003312:	004b2503          	lw	a0,4(s6)
    80003316:	000a849b          	sext.w	s1,s5
    8000331a:	8762                	mv	a4,s8
    8000331c:	faa4fde3          	bgeu	s1,a0,800032d6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003320:	00777693          	andi	a3,a4,7
    80003324:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003328:	41f7579b          	sraiw	a5,a4,0x1f
    8000332c:	01d7d79b          	srliw	a5,a5,0x1d
    80003330:	9fb9                	addw	a5,a5,a4
    80003332:	4037d79b          	sraiw	a5,a5,0x3
    80003336:	00f90633          	add	a2,s2,a5
    8000333a:	05864603          	lbu	a2,88(a2)
    8000333e:	00c6f5b3          	and	a1,a3,a2
    80003342:	d585                	beqz	a1,8000326a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003344:	2705                	addiw	a4,a4,1
    80003346:	2485                	addiw	s1,s1,1
    80003348:	fd471ae3          	bne	a4,s4,8000331c <balloc+0xec>
    8000334c:	b769                	j	800032d6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000334e:	00005517          	auipc	a0,0x5
    80003352:	20250513          	addi	a0,a0,514 # 80008550 <syscalls+0x100>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	234080e7          	jalr	564(ra) # 8000058a <printf>
  return 0;
    8000335e:	4481                	li	s1,0
    80003360:	bfa9                	j	800032ba <balloc+0x8a>

0000000080003362 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003362:	7179                	addi	sp,sp,-48
    80003364:	f406                	sd	ra,40(sp)
    80003366:	f022                	sd	s0,32(sp)
    80003368:	ec26                	sd	s1,24(sp)
    8000336a:	e84a                	sd	s2,16(sp)
    8000336c:	e44e                	sd	s3,8(sp)
    8000336e:	e052                	sd	s4,0(sp)
    80003370:	1800                	addi	s0,sp,48
    80003372:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003374:	47ad                	li	a5,11
    80003376:	02b7e863          	bltu	a5,a1,800033a6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000337a:	02059793          	slli	a5,a1,0x20
    8000337e:	01e7d593          	srli	a1,a5,0x1e
    80003382:	00b504b3          	add	s1,a0,a1
    80003386:	0504a903          	lw	s2,80(s1)
    8000338a:	06091e63          	bnez	s2,80003406 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000338e:	4108                	lw	a0,0(a0)
    80003390:	00000097          	auipc	ra,0x0
    80003394:	ea0080e7          	jalr	-352(ra) # 80003230 <balloc>
    80003398:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000339c:	06090563          	beqz	s2,80003406 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033a0:	0524a823          	sw	s2,80(s1)
    800033a4:	a08d                	j	80003406 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033a6:	ff45849b          	addiw	s1,a1,-12
    800033aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ae:	0ff00793          	li	a5,255
    800033b2:	08e7e563          	bltu	a5,a4,8000343c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033b6:	08052903          	lw	s2,128(a0)
    800033ba:	00091d63          	bnez	s2,800033d4 <bmap+0x72>
      addr = balloc(ip->dev);
    800033be:	4108                	lw	a0,0(a0)
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	e70080e7          	jalr	-400(ra) # 80003230 <balloc>
    800033c8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033cc:	02090d63          	beqz	s2,80003406 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033d0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033d4:	85ca                	mv	a1,s2
    800033d6:	0009a503          	lw	a0,0(s3)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	b94080e7          	jalr	-1132(ra) # 80002f6e <bread>
    800033e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e8:	02049713          	slli	a4,s1,0x20
    800033ec:	01e75593          	srli	a1,a4,0x1e
    800033f0:	00b784b3          	add	s1,a5,a1
    800033f4:	0004a903          	lw	s2,0(s1)
    800033f8:	02090063          	beqz	s2,80003418 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033fc:	8552                	mv	a0,s4
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	ca0080e7          	jalr	-864(ra) # 8000309e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003406:	854a                	mv	a0,s2
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6a02                	ld	s4,0(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret
      addr = balloc(ip->dev);
    80003418:	0009a503          	lw	a0,0(s3)
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	e14080e7          	jalr	-492(ra) # 80003230 <balloc>
    80003424:	0005091b          	sext.w	s2,a0
      if(addr){
    80003428:	fc090ae3          	beqz	s2,800033fc <bmap+0x9a>
        a[bn] = addr;
    8000342c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003430:	8552                	mv	a0,s4
    80003432:	00001097          	auipc	ra,0x1
    80003436:	ef6080e7          	jalr	-266(ra) # 80004328 <log_write>
    8000343a:	b7c9                	j	800033fc <bmap+0x9a>
  panic("bmap: out of range");
    8000343c:	00005517          	auipc	a0,0x5
    80003440:	12c50513          	addi	a0,a0,300 # 80008568 <syscalls+0x118>
    80003444:	ffffd097          	auipc	ra,0xffffd
    80003448:	0fc080e7          	jalr	252(ra) # 80000540 <panic>

000000008000344c <iget>:
{
    8000344c:	7179                	addi	sp,sp,-48
    8000344e:	f406                	sd	ra,40(sp)
    80003450:	f022                	sd	s0,32(sp)
    80003452:	ec26                	sd	s1,24(sp)
    80003454:	e84a                	sd	s2,16(sp)
    80003456:	e44e                	sd	s3,8(sp)
    80003458:	e052                	sd	s4,0(sp)
    8000345a:	1800                	addi	s0,sp,48
    8000345c:	89aa                	mv	s3,a0
    8000345e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003460:	0001d517          	auipc	a0,0x1d
    80003464:	81850513          	addi	a0,a0,-2024 # 8001fc78 <itable>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	76e080e7          	jalr	1902(ra) # 80000bd6 <acquire>
  empty = 0;
    80003470:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003472:	0001d497          	auipc	s1,0x1d
    80003476:	81e48493          	addi	s1,s1,-2018 # 8001fc90 <itable+0x18>
    8000347a:	0001e697          	auipc	a3,0x1e
    8000347e:	2a668693          	addi	a3,a3,678 # 80021720 <log>
    80003482:	a039                	j	80003490 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003484:	02090b63          	beqz	s2,800034ba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003488:	08848493          	addi	s1,s1,136
    8000348c:	02d48a63          	beq	s1,a3,800034c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003490:	449c                	lw	a5,8(s1)
    80003492:	fef059e3          	blez	a5,80003484 <iget+0x38>
    80003496:	4098                	lw	a4,0(s1)
    80003498:	ff3716e3          	bne	a4,s3,80003484 <iget+0x38>
    8000349c:	40d8                	lw	a4,4(s1)
    8000349e:	ff4713e3          	bne	a4,s4,80003484 <iget+0x38>
      ip->ref++;
    800034a2:	2785                	addiw	a5,a5,1
    800034a4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034a6:	0001c517          	auipc	a0,0x1c
    800034aa:	7d250513          	addi	a0,a0,2002 # 8001fc78 <itable>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
      return ip;
    800034b6:	8926                	mv	s2,s1
    800034b8:	a03d                	j	800034e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ba:	f7f9                	bnez	a5,80003488 <iget+0x3c>
    800034bc:	8926                	mv	s2,s1
    800034be:	b7e9                	j	80003488 <iget+0x3c>
  if(empty == 0)
    800034c0:	02090c63          	beqz	s2,800034f8 <iget+0xac>
  ip->dev = dev;
    800034c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034cc:	4785                	li	a5,1
    800034ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034d2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034d6:	0001c517          	auipc	a0,0x1c
    800034da:	7a250513          	addi	a0,a0,1954 # 8001fc78 <itable>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7ac080e7          	jalr	1964(ra) # 80000c8a <release>
}
    800034e6:	854a                	mv	a0,s2
    800034e8:	70a2                	ld	ra,40(sp)
    800034ea:	7402                	ld	s0,32(sp)
    800034ec:	64e2                	ld	s1,24(sp)
    800034ee:	6942                	ld	s2,16(sp)
    800034f0:	69a2                	ld	s3,8(sp)
    800034f2:	6a02                	ld	s4,0(sp)
    800034f4:	6145                	addi	sp,sp,48
    800034f6:	8082                	ret
    panic("iget: no inodes");
    800034f8:	00005517          	auipc	a0,0x5
    800034fc:	08850513          	addi	a0,a0,136 # 80008580 <syscalls+0x130>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	040080e7          	jalr	64(ra) # 80000540 <panic>

0000000080003508 <fsinit>:
fsinit(int dev) {
    80003508:	7179                	addi	sp,sp,-48
    8000350a:	f406                	sd	ra,40(sp)
    8000350c:	f022                	sd	s0,32(sp)
    8000350e:	ec26                	sd	s1,24(sp)
    80003510:	e84a                	sd	s2,16(sp)
    80003512:	e44e                	sd	s3,8(sp)
    80003514:	1800                	addi	s0,sp,48
    80003516:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003518:	4585                	li	a1,1
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	a54080e7          	jalr	-1452(ra) # 80002f6e <bread>
    80003522:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003524:	0001c997          	auipc	s3,0x1c
    80003528:	73498993          	addi	s3,s3,1844 # 8001fc58 <sb>
    8000352c:	02000613          	li	a2,32
    80003530:	05850593          	addi	a1,a0,88
    80003534:	854e                	mv	a0,s3
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	7f8080e7          	jalr	2040(ra) # 80000d2e <memmove>
  brelse(bp);
    8000353e:	8526                	mv	a0,s1
    80003540:	00000097          	auipc	ra,0x0
    80003544:	b5e080e7          	jalr	-1186(ra) # 8000309e <brelse>
  if(sb.magic != FSMAGIC)
    80003548:	0009a703          	lw	a4,0(s3)
    8000354c:	102037b7          	lui	a5,0x10203
    80003550:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003554:	02f71263          	bne	a4,a5,80003578 <fsinit+0x70>
  initlog(dev, &sb);
    80003558:	0001c597          	auipc	a1,0x1c
    8000355c:	70058593          	addi	a1,a1,1792 # 8001fc58 <sb>
    80003560:	854a                	mv	a0,s2
    80003562:	00001097          	auipc	ra,0x1
    80003566:	b4a080e7          	jalr	-1206(ra) # 800040ac <initlog>
}
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret
    panic("invalid file system");
    80003578:	00005517          	auipc	a0,0x5
    8000357c:	01850513          	addi	a0,a0,24 # 80008590 <syscalls+0x140>
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	fc0080e7          	jalr	-64(ra) # 80000540 <panic>

0000000080003588 <iinit>:
{
    80003588:	7179                	addi	sp,sp,-48
    8000358a:	f406                	sd	ra,40(sp)
    8000358c:	f022                	sd	s0,32(sp)
    8000358e:	ec26                	sd	s1,24(sp)
    80003590:	e84a                	sd	s2,16(sp)
    80003592:	e44e                	sd	s3,8(sp)
    80003594:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003596:	00005597          	auipc	a1,0x5
    8000359a:	01258593          	addi	a1,a1,18 # 800085a8 <syscalls+0x158>
    8000359e:	0001c517          	auipc	a0,0x1c
    800035a2:	6da50513          	addi	a0,a0,1754 # 8001fc78 <itable>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	5a0080e7          	jalr	1440(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ae:	0001c497          	auipc	s1,0x1c
    800035b2:	6f248493          	addi	s1,s1,1778 # 8001fca0 <itable+0x28>
    800035b6:	0001e997          	auipc	s3,0x1e
    800035ba:	17a98993          	addi	s3,s3,378 # 80021730 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035be:	00005917          	auipc	s2,0x5
    800035c2:	ff290913          	addi	s2,s2,-14 # 800085b0 <syscalls+0x160>
    800035c6:	85ca                	mv	a1,s2
    800035c8:	8526                	mv	a0,s1
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	e42080e7          	jalr	-446(ra) # 8000440c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035d2:	08848493          	addi	s1,s1,136
    800035d6:	ff3498e3          	bne	s1,s3,800035c6 <iinit+0x3e>
}
    800035da:	70a2                	ld	ra,40(sp)
    800035dc:	7402                	ld	s0,32(sp)
    800035de:	64e2                	ld	s1,24(sp)
    800035e0:	6942                	ld	s2,16(sp)
    800035e2:	69a2                	ld	s3,8(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret

00000000800035e8 <ialloc>:
{
    800035e8:	715d                	addi	sp,sp,-80
    800035ea:	e486                	sd	ra,72(sp)
    800035ec:	e0a2                	sd	s0,64(sp)
    800035ee:	fc26                	sd	s1,56(sp)
    800035f0:	f84a                	sd	s2,48(sp)
    800035f2:	f44e                	sd	s3,40(sp)
    800035f4:	f052                	sd	s4,32(sp)
    800035f6:	ec56                	sd	s5,24(sp)
    800035f8:	e85a                	sd	s6,16(sp)
    800035fa:	e45e                	sd	s7,8(sp)
    800035fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035fe:	0001c717          	auipc	a4,0x1c
    80003602:	66672703          	lw	a4,1638(a4) # 8001fc64 <sb+0xc>
    80003606:	4785                	li	a5,1
    80003608:	04e7fa63          	bgeu	a5,a4,8000365c <ialloc+0x74>
    8000360c:	8aaa                	mv	s5,a0
    8000360e:	8bae                	mv	s7,a1
    80003610:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003612:	0001ca17          	auipc	s4,0x1c
    80003616:	646a0a13          	addi	s4,s4,1606 # 8001fc58 <sb>
    8000361a:	00048b1b          	sext.w	s6,s1
    8000361e:	0044d593          	srli	a1,s1,0x4
    80003622:	018a2783          	lw	a5,24(s4)
    80003626:	9dbd                	addw	a1,a1,a5
    80003628:	8556                	mv	a0,s5
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	944080e7          	jalr	-1724(ra) # 80002f6e <bread>
    80003632:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003634:	05850993          	addi	s3,a0,88
    80003638:	00f4f793          	andi	a5,s1,15
    8000363c:	079a                	slli	a5,a5,0x6
    8000363e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003640:	00099783          	lh	a5,0(s3)
    80003644:	c3a1                	beqz	a5,80003684 <ialloc+0x9c>
    brelse(bp);
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	a58080e7          	jalr	-1448(ra) # 8000309e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364e:	0485                	addi	s1,s1,1
    80003650:	00ca2703          	lw	a4,12(s4)
    80003654:	0004879b          	sext.w	a5,s1
    80003658:	fce7e1e3          	bltu	a5,a4,8000361a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000365c:	00005517          	auipc	a0,0x5
    80003660:	f5c50513          	addi	a0,a0,-164 # 800085b8 <syscalls+0x168>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	f26080e7          	jalr	-218(ra) # 8000058a <printf>
  return 0;
    8000366c:	4501                	li	a0,0
}
    8000366e:	60a6                	ld	ra,72(sp)
    80003670:	6406                	ld	s0,64(sp)
    80003672:	74e2                	ld	s1,56(sp)
    80003674:	7942                	ld	s2,48(sp)
    80003676:	79a2                	ld	s3,40(sp)
    80003678:	7a02                	ld	s4,32(sp)
    8000367a:	6ae2                	ld	s5,24(sp)
    8000367c:	6b42                	ld	s6,16(sp)
    8000367e:	6ba2                	ld	s7,8(sp)
    80003680:	6161                	addi	sp,sp,80
    80003682:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003684:	04000613          	li	a2,64
    80003688:	4581                	li	a1,0
    8000368a:	854e                	mv	a0,s3
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	646080e7          	jalr	1606(ra) # 80000cd2 <memset>
      dip->type = type;
    80003694:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003698:	854a                	mv	a0,s2
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	c8e080e7          	jalr	-882(ra) # 80004328 <log_write>
      brelse(bp);
    800036a2:	854a                	mv	a0,s2
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	9fa080e7          	jalr	-1542(ra) # 8000309e <brelse>
      return iget(dev, inum);
    800036ac:	85da                	mv	a1,s6
    800036ae:	8556                	mv	a0,s5
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	d9c080e7          	jalr	-612(ra) # 8000344c <iget>
    800036b8:	bf5d                	j	8000366e <ialloc+0x86>

00000000800036ba <iupdate>:
{
    800036ba:	1101                	addi	sp,sp,-32
    800036bc:	ec06                	sd	ra,24(sp)
    800036be:	e822                	sd	s0,16(sp)
    800036c0:	e426                	sd	s1,8(sp)
    800036c2:	e04a                	sd	s2,0(sp)
    800036c4:	1000                	addi	s0,sp,32
    800036c6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036c8:	415c                	lw	a5,4(a0)
    800036ca:	0047d79b          	srliw	a5,a5,0x4
    800036ce:	0001c597          	auipc	a1,0x1c
    800036d2:	5a25a583          	lw	a1,1442(a1) # 8001fc70 <sb+0x18>
    800036d6:	9dbd                	addw	a1,a1,a5
    800036d8:	4108                	lw	a0,0(a0)
    800036da:	00000097          	auipc	ra,0x0
    800036de:	894080e7          	jalr	-1900(ra) # 80002f6e <bread>
    800036e2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036e4:	05850793          	addi	a5,a0,88
    800036e8:	40d8                	lw	a4,4(s1)
    800036ea:	8b3d                	andi	a4,a4,15
    800036ec:	071a                	slli	a4,a4,0x6
    800036ee:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036f0:	04449703          	lh	a4,68(s1)
    800036f4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036f8:	04649703          	lh	a4,70(s1)
    800036fc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003700:	04849703          	lh	a4,72(s1)
    80003704:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003708:	04a49703          	lh	a4,74(s1)
    8000370c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003710:	44f8                	lw	a4,76(s1)
    80003712:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003714:	03400613          	li	a2,52
    80003718:	05048593          	addi	a1,s1,80
    8000371c:	00c78513          	addi	a0,a5,12
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	60e080e7          	jalr	1550(ra) # 80000d2e <memmove>
  log_write(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	bfe080e7          	jalr	-1026(ra) # 80004328 <log_write>
  brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00000097          	auipc	ra,0x0
    80003738:	96a080e7          	jalr	-1686(ra) # 8000309e <brelse>
}
    8000373c:	60e2                	ld	ra,24(sp)
    8000373e:	6442                	ld	s0,16(sp)
    80003740:	64a2                	ld	s1,8(sp)
    80003742:	6902                	ld	s2,0(sp)
    80003744:	6105                	addi	sp,sp,32
    80003746:	8082                	ret

0000000080003748 <idup>:
{
    80003748:	1101                	addi	sp,sp,-32
    8000374a:	ec06                	sd	ra,24(sp)
    8000374c:	e822                	sd	s0,16(sp)
    8000374e:	e426                	sd	s1,8(sp)
    80003750:	1000                	addi	s0,sp,32
    80003752:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003754:	0001c517          	auipc	a0,0x1c
    80003758:	52450513          	addi	a0,a0,1316 # 8001fc78 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	47a080e7          	jalr	1146(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003764:	449c                	lw	a5,8(s1)
    80003766:	2785                	addiw	a5,a5,1
    80003768:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000376a:	0001c517          	auipc	a0,0x1c
    8000376e:	50e50513          	addi	a0,a0,1294 # 8001fc78 <itable>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	518080e7          	jalr	1304(ra) # 80000c8a <release>
}
    8000377a:	8526                	mv	a0,s1
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6105                	addi	sp,sp,32
    80003784:	8082                	ret

0000000080003786 <ilock>:
{
    80003786:	1101                	addi	sp,sp,-32
    80003788:	ec06                	sd	ra,24(sp)
    8000378a:	e822                	sd	s0,16(sp)
    8000378c:	e426                	sd	s1,8(sp)
    8000378e:	e04a                	sd	s2,0(sp)
    80003790:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003792:	c115                	beqz	a0,800037b6 <ilock+0x30>
    80003794:	84aa                	mv	s1,a0
    80003796:	451c                	lw	a5,8(a0)
    80003798:	00f05f63          	blez	a5,800037b6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000379c:	0541                	addi	a0,a0,16
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	ca8080e7          	jalr	-856(ra) # 80004446 <acquiresleep>
  if(ip->valid == 0){
    800037a6:	40bc                	lw	a5,64(s1)
    800037a8:	cf99                	beqz	a5,800037c6 <ilock+0x40>
}
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6902                	ld	s2,0(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret
    panic("ilock");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	e1a50513          	addi	a0,a0,-486 # 800085d0 <syscalls+0x180>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d82080e7          	jalr	-638(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c6:	40dc                	lw	a5,4(s1)
    800037c8:	0047d79b          	srliw	a5,a5,0x4
    800037cc:	0001c597          	auipc	a1,0x1c
    800037d0:	4a45a583          	lw	a1,1188(a1) # 8001fc70 <sb+0x18>
    800037d4:	9dbd                	addw	a1,a1,a5
    800037d6:	4088                	lw	a0,0(s1)
    800037d8:	fffff097          	auipc	ra,0xfffff
    800037dc:	796080e7          	jalr	1942(ra) # 80002f6e <bread>
    800037e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e2:	05850593          	addi	a1,a0,88
    800037e6:	40dc                	lw	a5,4(s1)
    800037e8:	8bbd                	andi	a5,a5,15
    800037ea:	079a                	slli	a5,a5,0x6
    800037ec:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ee:	00059783          	lh	a5,0(a1)
    800037f2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037f6:	00259783          	lh	a5,2(a1)
    800037fa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037fe:	00459783          	lh	a5,4(a1)
    80003802:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003806:	00659783          	lh	a5,6(a1)
    8000380a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000380e:	459c                	lw	a5,8(a1)
    80003810:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003812:	03400613          	li	a2,52
    80003816:	05b1                	addi	a1,a1,12
    80003818:	05048513          	addi	a0,s1,80
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	512080e7          	jalr	1298(ra) # 80000d2e <memmove>
    brelse(bp);
    80003824:	854a                	mv	a0,s2
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	878080e7          	jalr	-1928(ra) # 8000309e <brelse>
    ip->valid = 1;
    8000382e:	4785                	li	a5,1
    80003830:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003832:	04449783          	lh	a5,68(s1)
    80003836:	fbb5                	bnez	a5,800037aa <ilock+0x24>
      panic("ilock: no type");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	da050513          	addi	a0,a0,-608 # 800085d8 <syscalls+0x188>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	d00080e7          	jalr	-768(ra) # 80000540 <panic>

0000000080003848 <iunlock>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	e04a                	sd	s2,0(sp)
    80003852:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003854:	c905                	beqz	a0,80003884 <iunlock+0x3c>
    80003856:	84aa                	mv	s1,a0
    80003858:	01050913          	addi	s2,a0,16
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	c82080e7          	jalr	-894(ra) # 800044e0 <holdingsleep>
    80003866:	cd19                	beqz	a0,80003884 <iunlock+0x3c>
    80003868:	449c                	lw	a5,8(s1)
    8000386a:	00f05d63          	blez	a5,80003884 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000386e:	854a                	mv	a0,s2
    80003870:	00001097          	auipc	ra,0x1
    80003874:	c2c080e7          	jalr	-980(ra) # 8000449c <releasesleep>
}
    80003878:	60e2                	ld	ra,24(sp)
    8000387a:	6442                	ld	s0,16(sp)
    8000387c:	64a2                	ld	s1,8(sp)
    8000387e:	6902                	ld	s2,0(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret
    panic("iunlock");
    80003884:	00005517          	auipc	a0,0x5
    80003888:	d6450513          	addi	a0,a0,-668 # 800085e8 <syscalls+0x198>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	cb4080e7          	jalr	-844(ra) # 80000540 <panic>

0000000080003894 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003894:	7179                	addi	sp,sp,-48
    80003896:	f406                	sd	ra,40(sp)
    80003898:	f022                	sd	s0,32(sp)
    8000389a:	ec26                	sd	s1,24(sp)
    8000389c:	e84a                	sd	s2,16(sp)
    8000389e:	e44e                	sd	s3,8(sp)
    800038a0:	e052                	sd	s4,0(sp)
    800038a2:	1800                	addi	s0,sp,48
    800038a4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038a6:	05050493          	addi	s1,a0,80
    800038aa:	08050913          	addi	s2,a0,128
    800038ae:	a021                	j	800038b6 <itrunc+0x22>
    800038b0:	0491                	addi	s1,s1,4
    800038b2:	01248d63          	beq	s1,s2,800038cc <itrunc+0x38>
    if(ip->addrs[i]){
    800038b6:	408c                	lw	a1,0(s1)
    800038b8:	dde5                	beqz	a1,800038b0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	8f6080e7          	jalr	-1802(ra) # 800031b4 <bfree>
      ip->addrs[i] = 0;
    800038c6:	0004a023          	sw	zero,0(s1)
    800038ca:	b7dd                	j	800038b0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038cc:	0809a583          	lw	a1,128(s3)
    800038d0:	e185                	bnez	a1,800038f0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038d2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038d6:	854e                	mv	a0,s3
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	de2080e7          	jalr	-542(ra) # 800036ba <iupdate>
}
    800038e0:	70a2                	ld	ra,40(sp)
    800038e2:	7402                	ld	s0,32(sp)
    800038e4:	64e2                	ld	s1,24(sp)
    800038e6:	6942                	ld	s2,16(sp)
    800038e8:	69a2                	ld	s3,8(sp)
    800038ea:	6a02                	ld	s4,0(sp)
    800038ec:	6145                	addi	sp,sp,48
    800038ee:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038f0:	0009a503          	lw	a0,0(s3)
    800038f4:	fffff097          	auipc	ra,0xfffff
    800038f8:	67a080e7          	jalr	1658(ra) # 80002f6e <bread>
    800038fc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038fe:	05850493          	addi	s1,a0,88
    80003902:	45850913          	addi	s2,a0,1112
    80003906:	a021                	j	8000390e <itrunc+0x7a>
    80003908:	0491                	addi	s1,s1,4
    8000390a:	01248b63          	beq	s1,s2,80003920 <itrunc+0x8c>
      if(a[j])
    8000390e:	408c                	lw	a1,0(s1)
    80003910:	dde5                	beqz	a1,80003908 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	89e080e7          	jalr	-1890(ra) # 800031b4 <bfree>
    8000391e:	b7ed                	j	80003908 <itrunc+0x74>
    brelse(bp);
    80003920:	8552                	mv	a0,s4
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	77c080e7          	jalr	1916(ra) # 8000309e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000392a:	0809a583          	lw	a1,128(s3)
    8000392e:	0009a503          	lw	a0,0(s3)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	882080e7          	jalr	-1918(ra) # 800031b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000393a:	0809a023          	sw	zero,128(s3)
    8000393e:	bf51                	j	800038d2 <itrunc+0x3e>

0000000080003940 <iput>:
{
    80003940:	1101                	addi	sp,sp,-32
    80003942:	ec06                	sd	ra,24(sp)
    80003944:	e822                	sd	s0,16(sp)
    80003946:	e426                	sd	s1,8(sp)
    80003948:	e04a                	sd	s2,0(sp)
    8000394a:	1000                	addi	s0,sp,32
    8000394c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000394e:	0001c517          	auipc	a0,0x1c
    80003952:	32a50513          	addi	a0,a0,810 # 8001fc78 <itable>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	280080e7          	jalr	640(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000395e:	4498                	lw	a4,8(s1)
    80003960:	4785                	li	a5,1
    80003962:	02f70363          	beq	a4,a5,80003988 <iput+0x48>
  ip->ref--;
    80003966:	449c                	lw	a5,8(s1)
    80003968:	37fd                	addiw	a5,a5,-1
    8000396a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000396c:	0001c517          	auipc	a0,0x1c
    80003970:	30c50513          	addi	a0,a0,780 # 8001fc78 <itable>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	316080e7          	jalr	790(ra) # 80000c8a <release>
}
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6902                	ld	s2,0(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003988:	40bc                	lw	a5,64(s1)
    8000398a:	dff1                	beqz	a5,80003966 <iput+0x26>
    8000398c:	04a49783          	lh	a5,74(s1)
    80003990:	fbf9                	bnez	a5,80003966 <iput+0x26>
    acquiresleep(&ip->lock);
    80003992:	01048913          	addi	s2,s1,16
    80003996:	854a                	mv	a0,s2
    80003998:	00001097          	auipc	ra,0x1
    8000399c:	aae080e7          	jalr	-1362(ra) # 80004446 <acquiresleep>
    release(&itable.lock);
    800039a0:	0001c517          	auipc	a0,0x1c
    800039a4:	2d850513          	addi	a0,a0,728 # 8001fc78 <itable>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	2e2080e7          	jalr	738(ra) # 80000c8a <release>
    itrunc(ip);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	ee2080e7          	jalr	-286(ra) # 80003894 <itrunc>
    ip->type = 0;
    800039ba:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039be:	8526                	mv	a0,s1
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	cfa080e7          	jalr	-774(ra) # 800036ba <iupdate>
    ip->valid = 0;
    800039c8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	ace080e7          	jalr	-1330(ra) # 8000449c <releasesleep>
    acquire(&itable.lock);
    800039d6:	0001c517          	auipc	a0,0x1c
    800039da:	2a250513          	addi	a0,a0,674 # 8001fc78 <itable>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	1f8080e7          	jalr	504(ra) # 80000bd6 <acquire>
    800039e6:	b741                	j	80003966 <iput+0x26>

00000000800039e8 <iunlockput>:
{
    800039e8:	1101                	addi	sp,sp,-32
    800039ea:	ec06                	sd	ra,24(sp)
    800039ec:	e822                	sd	s0,16(sp)
    800039ee:	e426                	sd	s1,8(sp)
    800039f0:	1000                	addi	s0,sp,32
    800039f2:	84aa                	mv	s1,a0
  iunlock(ip);
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	e54080e7          	jalr	-428(ra) # 80003848 <iunlock>
  iput(ip);
    800039fc:	8526                	mv	a0,s1
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	f42080e7          	jalr	-190(ra) # 80003940 <iput>
}
    80003a06:	60e2                	ld	ra,24(sp)
    80003a08:	6442                	ld	s0,16(sp)
    80003a0a:	64a2                	ld	s1,8(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret

0000000080003a10 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a10:	1141                	addi	sp,sp,-16
    80003a12:	e422                	sd	s0,8(sp)
    80003a14:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a16:	411c                	lw	a5,0(a0)
    80003a18:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a1a:	415c                	lw	a5,4(a0)
    80003a1c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a1e:	04451783          	lh	a5,68(a0)
    80003a22:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a26:	04a51783          	lh	a5,74(a0)
    80003a2a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a2e:	04c56783          	lwu	a5,76(a0)
    80003a32:	e99c                	sd	a5,16(a1)
}
    80003a34:	6422                	ld	s0,8(sp)
    80003a36:	0141                	addi	sp,sp,16
    80003a38:	8082                	ret

0000000080003a3a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a3a:	457c                	lw	a5,76(a0)
    80003a3c:	0ed7e963          	bltu	a5,a3,80003b2e <readi+0xf4>
{
    80003a40:	7159                	addi	sp,sp,-112
    80003a42:	f486                	sd	ra,104(sp)
    80003a44:	f0a2                	sd	s0,96(sp)
    80003a46:	eca6                	sd	s1,88(sp)
    80003a48:	e8ca                	sd	s2,80(sp)
    80003a4a:	e4ce                	sd	s3,72(sp)
    80003a4c:	e0d2                	sd	s4,64(sp)
    80003a4e:	fc56                	sd	s5,56(sp)
    80003a50:	f85a                	sd	s6,48(sp)
    80003a52:	f45e                	sd	s7,40(sp)
    80003a54:	f062                	sd	s8,32(sp)
    80003a56:	ec66                	sd	s9,24(sp)
    80003a58:	e86a                	sd	s10,16(sp)
    80003a5a:	e46e                	sd	s11,8(sp)
    80003a5c:	1880                	addi	s0,sp,112
    80003a5e:	8b2a                	mv	s6,a0
    80003a60:	8bae                	mv	s7,a1
    80003a62:	8a32                	mv	s4,a2
    80003a64:	84b6                	mv	s1,a3
    80003a66:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a68:	9f35                	addw	a4,a4,a3
    return 0;
    80003a6a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a6c:	0ad76063          	bltu	a4,a3,80003b0c <readi+0xd2>
  if(off + n > ip->size)
    80003a70:	00e7f463          	bgeu	a5,a4,80003a78 <readi+0x3e>
    n = ip->size - off;
    80003a74:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a78:	0a0a8963          	beqz	s5,80003b2a <readi+0xf0>
    80003a7c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a82:	5c7d                	li	s8,-1
    80003a84:	a82d                	j	80003abe <readi+0x84>
    80003a86:	020d1d93          	slli	s11,s10,0x20
    80003a8a:	020ddd93          	srli	s11,s11,0x20
    80003a8e:	05890613          	addi	a2,s2,88
    80003a92:	86ee                	mv	a3,s11
    80003a94:	963a                	add	a2,a2,a4
    80003a96:	85d2                	mv	a1,s4
    80003a98:	855e                	mv	a0,s7
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	b1c080e7          	jalr	-1252(ra) # 800025b6 <either_copyout>
    80003aa2:	05850d63          	beq	a0,s8,80003afc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	5f6080e7          	jalr	1526(ra) # 8000309e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab0:	013d09bb          	addw	s3,s10,s3
    80003ab4:	009d04bb          	addw	s1,s10,s1
    80003ab8:	9a6e                	add	s4,s4,s11
    80003aba:	0559f763          	bgeu	s3,s5,80003b08 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003abe:	00a4d59b          	srliw	a1,s1,0xa
    80003ac2:	855a                	mv	a0,s6
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	89e080e7          	jalr	-1890(ra) # 80003362 <bmap>
    80003acc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ad0:	cd85                	beqz	a1,80003b08 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ad2:	000b2503          	lw	a0,0(s6)
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	498080e7          	jalr	1176(ra) # 80002f6e <bread>
    80003ade:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae0:	3ff4f713          	andi	a4,s1,1023
    80003ae4:	40ec87bb          	subw	a5,s9,a4
    80003ae8:	413a86bb          	subw	a3,s5,s3
    80003aec:	8d3e                	mv	s10,a5
    80003aee:	2781                	sext.w	a5,a5
    80003af0:	0006861b          	sext.w	a2,a3
    80003af4:	f8f679e3          	bgeu	a2,a5,80003a86 <readi+0x4c>
    80003af8:	8d36                	mv	s10,a3
    80003afa:	b771                	j	80003a86 <readi+0x4c>
      brelse(bp);
    80003afc:	854a                	mv	a0,s2
    80003afe:	fffff097          	auipc	ra,0xfffff
    80003b02:	5a0080e7          	jalr	1440(ra) # 8000309e <brelse>
      tot = -1;
    80003b06:	59fd                	li	s3,-1
  }
  return tot;
    80003b08:	0009851b          	sext.w	a0,s3
}
    80003b0c:	70a6                	ld	ra,104(sp)
    80003b0e:	7406                	ld	s0,96(sp)
    80003b10:	64e6                	ld	s1,88(sp)
    80003b12:	6946                	ld	s2,80(sp)
    80003b14:	69a6                	ld	s3,72(sp)
    80003b16:	6a06                	ld	s4,64(sp)
    80003b18:	7ae2                	ld	s5,56(sp)
    80003b1a:	7b42                	ld	s6,48(sp)
    80003b1c:	7ba2                	ld	s7,40(sp)
    80003b1e:	7c02                	ld	s8,32(sp)
    80003b20:	6ce2                	ld	s9,24(sp)
    80003b22:	6d42                	ld	s10,16(sp)
    80003b24:	6da2                	ld	s11,8(sp)
    80003b26:	6165                	addi	sp,sp,112
    80003b28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b2a:	89d6                	mv	s3,s5
    80003b2c:	bff1                	j	80003b08 <readi+0xce>
    return 0;
    80003b2e:	4501                	li	a0,0
}
    80003b30:	8082                	ret

0000000080003b32 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b32:	457c                	lw	a5,76(a0)
    80003b34:	10d7e863          	bltu	a5,a3,80003c44 <writei+0x112>
{
    80003b38:	7159                	addi	sp,sp,-112
    80003b3a:	f486                	sd	ra,104(sp)
    80003b3c:	f0a2                	sd	s0,96(sp)
    80003b3e:	eca6                	sd	s1,88(sp)
    80003b40:	e8ca                	sd	s2,80(sp)
    80003b42:	e4ce                	sd	s3,72(sp)
    80003b44:	e0d2                	sd	s4,64(sp)
    80003b46:	fc56                	sd	s5,56(sp)
    80003b48:	f85a                	sd	s6,48(sp)
    80003b4a:	f45e                	sd	s7,40(sp)
    80003b4c:	f062                	sd	s8,32(sp)
    80003b4e:	ec66                	sd	s9,24(sp)
    80003b50:	e86a                	sd	s10,16(sp)
    80003b52:	e46e                	sd	s11,8(sp)
    80003b54:	1880                	addi	s0,sp,112
    80003b56:	8aaa                	mv	s5,a0
    80003b58:	8bae                	mv	s7,a1
    80003b5a:	8a32                	mv	s4,a2
    80003b5c:	8936                	mv	s2,a3
    80003b5e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b60:	00e687bb          	addw	a5,a3,a4
    80003b64:	0ed7e263          	bltu	a5,a3,80003c48 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b68:	00043737          	lui	a4,0x43
    80003b6c:	0ef76063          	bltu	a4,a5,80003c4c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b70:	0c0b0863          	beqz	s6,80003c40 <writei+0x10e>
    80003b74:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b76:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b7a:	5c7d                	li	s8,-1
    80003b7c:	a091                	j	80003bc0 <writei+0x8e>
    80003b7e:	020d1d93          	slli	s11,s10,0x20
    80003b82:	020ddd93          	srli	s11,s11,0x20
    80003b86:	05848513          	addi	a0,s1,88
    80003b8a:	86ee                	mv	a3,s11
    80003b8c:	8652                	mv	a2,s4
    80003b8e:	85de                	mv	a1,s7
    80003b90:	953a                	add	a0,a0,a4
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	a7a080e7          	jalr	-1414(ra) # 8000260c <either_copyin>
    80003b9a:	07850263          	beq	a0,s8,80003bfe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	788080e7          	jalr	1928(ra) # 80004328 <log_write>
    brelse(bp);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	4f4080e7          	jalr	1268(ra) # 8000309e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb2:	013d09bb          	addw	s3,s10,s3
    80003bb6:	012d093b          	addw	s2,s10,s2
    80003bba:	9a6e                	add	s4,s4,s11
    80003bbc:	0569f663          	bgeu	s3,s6,80003c08 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bc0:	00a9559b          	srliw	a1,s2,0xa
    80003bc4:	8556                	mv	a0,s5
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	79c080e7          	jalr	1948(ra) # 80003362 <bmap>
    80003bce:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bd2:	c99d                	beqz	a1,80003c08 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bd4:	000aa503          	lw	a0,0(s5)
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	396080e7          	jalr	918(ra) # 80002f6e <bread>
    80003be0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be2:	3ff97713          	andi	a4,s2,1023
    80003be6:	40ec87bb          	subw	a5,s9,a4
    80003bea:	413b06bb          	subw	a3,s6,s3
    80003bee:	8d3e                	mv	s10,a5
    80003bf0:	2781                	sext.w	a5,a5
    80003bf2:	0006861b          	sext.w	a2,a3
    80003bf6:	f8f674e3          	bgeu	a2,a5,80003b7e <writei+0x4c>
    80003bfa:	8d36                	mv	s10,a3
    80003bfc:	b749                	j	80003b7e <writei+0x4c>
      brelse(bp);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	49e080e7          	jalr	1182(ra) # 8000309e <brelse>
  }

  if(off > ip->size)
    80003c08:	04caa783          	lw	a5,76(s5)
    80003c0c:	0127f463          	bgeu	a5,s2,80003c14 <writei+0xe2>
    ip->size = off;
    80003c10:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c14:	8556                	mv	a0,s5
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	aa4080e7          	jalr	-1372(ra) # 800036ba <iupdate>

  return tot;
    80003c1e:	0009851b          	sext.w	a0,s3
}
    80003c22:	70a6                	ld	ra,104(sp)
    80003c24:	7406                	ld	s0,96(sp)
    80003c26:	64e6                	ld	s1,88(sp)
    80003c28:	6946                	ld	s2,80(sp)
    80003c2a:	69a6                	ld	s3,72(sp)
    80003c2c:	6a06                	ld	s4,64(sp)
    80003c2e:	7ae2                	ld	s5,56(sp)
    80003c30:	7b42                	ld	s6,48(sp)
    80003c32:	7ba2                	ld	s7,40(sp)
    80003c34:	7c02                	ld	s8,32(sp)
    80003c36:	6ce2                	ld	s9,24(sp)
    80003c38:	6d42                	ld	s10,16(sp)
    80003c3a:	6da2                	ld	s11,8(sp)
    80003c3c:	6165                	addi	sp,sp,112
    80003c3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c40:	89da                	mv	s3,s6
    80003c42:	bfc9                	j	80003c14 <writei+0xe2>
    return -1;
    80003c44:	557d                	li	a0,-1
}
    80003c46:	8082                	ret
    return -1;
    80003c48:	557d                	li	a0,-1
    80003c4a:	bfe1                	j	80003c22 <writei+0xf0>
    return -1;
    80003c4c:	557d                	li	a0,-1
    80003c4e:	bfd1                	j	80003c22 <writei+0xf0>

0000000080003c50 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c50:	1141                	addi	sp,sp,-16
    80003c52:	e406                	sd	ra,8(sp)
    80003c54:	e022                	sd	s0,0(sp)
    80003c56:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c58:	4639                	li	a2,14
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	148080e7          	jalr	328(ra) # 80000da2 <strncmp>
}
    80003c62:	60a2                	ld	ra,8(sp)
    80003c64:	6402                	ld	s0,0(sp)
    80003c66:	0141                	addi	sp,sp,16
    80003c68:	8082                	ret

0000000080003c6a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c6a:	7139                	addi	sp,sp,-64
    80003c6c:	fc06                	sd	ra,56(sp)
    80003c6e:	f822                	sd	s0,48(sp)
    80003c70:	f426                	sd	s1,40(sp)
    80003c72:	f04a                	sd	s2,32(sp)
    80003c74:	ec4e                	sd	s3,24(sp)
    80003c76:	e852                	sd	s4,16(sp)
    80003c78:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c7a:	04451703          	lh	a4,68(a0)
    80003c7e:	4785                	li	a5,1
    80003c80:	00f71a63          	bne	a4,a5,80003c94 <dirlookup+0x2a>
    80003c84:	892a                	mv	s2,a0
    80003c86:	89ae                	mv	s3,a1
    80003c88:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c8a:	457c                	lw	a5,76(a0)
    80003c8c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c8e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c90:	e79d                	bnez	a5,80003cbe <dirlookup+0x54>
    80003c92:	a8a5                	j	80003d0a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c94:	00005517          	auipc	a0,0x5
    80003c98:	95c50513          	addi	a0,a0,-1700 # 800085f0 <syscalls+0x1a0>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	8a4080e7          	jalr	-1884(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	96450513          	addi	a0,a0,-1692 # 80008608 <syscalls+0x1b8>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	894080e7          	jalr	-1900(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb4:	24c1                	addiw	s1,s1,16
    80003cb6:	04c92783          	lw	a5,76(s2)
    80003cba:	04f4f763          	bgeu	s1,a5,80003d08 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cbe:	4741                	li	a4,16
    80003cc0:	86a6                	mv	a3,s1
    80003cc2:	fc040613          	addi	a2,s0,-64
    80003cc6:	4581                	li	a1,0
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	d70080e7          	jalr	-656(ra) # 80003a3a <readi>
    80003cd2:	47c1                	li	a5,16
    80003cd4:	fcf518e3          	bne	a0,a5,80003ca4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cd8:	fc045783          	lhu	a5,-64(s0)
    80003cdc:	dfe1                	beqz	a5,80003cb4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cde:	fc240593          	addi	a1,s0,-62
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	f6c080e7          	jalr	-148(ra) # 80003c50 <namecmp>
    80003cec:	f561                	bnez	a0,80003cb4 <dirlookup+0x4a>
      if(poff)
    80003cee:	000a0463          	beqz	s4,80003cf6 <dirlookup+0x8c>
        *poff = off;
    80003cf2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cf6:	fc045583          	lhu	a1,-64(s0)
    80003cfa:	00092503          	lw	a0,0(s2)
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	74e080e7          	jalr	1870(ra) # 8000344c <iget>
    80003d06:	a011                	j	80003d0a <dirlookup+0xa0>
  return 0;
    80003d08:	4501                	li	a0,0
}
    80003d0a:	70e2                	ld	ra,56(sp)
    80003d0c:	7442                	ld	s0,48(sp)
    80003d0e:	74a2                	ld	s1,40(sp)
    80003d10:	7902                	ld	s2,32(sp)
    80003d12:	69e2                	ld	s3,24(sp)
    80003d14:	6a42                	ld	s4,16(sp)
    80003d16:	6121                	addi	sp,sp,64
    80003d18:	8082                	ret

0000000080003d1a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d1a:	711d                	addi	sp,sp,-96
    80003d1c:	ec86                	sd	ra,88(sp)
    80003d1e:	e8a2                	sd	s0,80(sp)
    80003d20:	e4a6                	sd	s1,72(sp)
    80003d22:	e0ca                	sd	s2,64(sp)
    80003d24:	fc4e                	sd	s3,56(sp)
    80003d26:	f852                	sd	s4,48(sp)
    80003d28:	f456                	sd	s5,40(sp)
    80003d2a:	f05a                	sd	s6,32(sp)
    80003d2c:	ec5e                	sd	s7,24(sp)
    80003d2e:	e862                	sd	s8,16(sp)
    80003d30:	e466                	sd	s9,8(sp)
    80003d32:	e06a                	sd	s10,0(sp)
    80003d34:	1080                	addi	s0,sp,96
    80003d36:	84aa                	mv	s1,a0
    80003d38:	8b2e                	mv	s6,a1
    80003d3a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d3c:	00054703          	lbu	a4,0(a0)
    80003d40:	02f00793          	li	a5,47
    80003d44:	02f70363          	beq	a4,a5,80003d6a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d48:	ffffe097          	auipc	ra,0xffffe
    80003d4c:	c94080e7          	jalr	-876(ra) # 800019dc <myproc>
    80003d50:	15053503          	ld	a0,336(a0)
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	9f4080e7          	jalr	-1548(ra) # 80003748 <idup>
    80003d5c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d5e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d62:	4cb5                	li	s9,13
  len = path - s;
    80003d64:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d66:	4c05                	li	s8,1
    80003d68:	a87d                	j	80003e26 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d6a:	4585                	li	a1,1
    80003d6c:	4505                	li	a0,1
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	6de080e7          	jalr	1758(ra) # 8000344c <iget>
    80003d76:	8a2a                	mv	s4,a0
    80003d78:	b7dd                	j	80003d5e <namex+0x44>
      iunlockput(ip);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	c6c080e7          	jalr	-916(ra) # 800039e8 <iunlockput>
      return 0;
    80003d84:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d86:	8552                	mv	a0,s4
    80003d88:	60e6                	ld	ra,88(sp)
    80003d8a:	6446                	ld	s0,80(sp)
    80003d8c:	64a6                	ld	s1,72(sp)
    80003d8e:	6906                	ld	s2,64(sp)
    80003d90:	79e2                	ld	s3,56(sp)
    80003d92:	7a42                	ld	s4,48(sp)
    80003d94:	7aa2                	ld	s5,40(sp)
    80003d96:	7b02                	ld	s6,32(sp)
    80003d98:	6be2                	ld	s7,24(sp)
    80003d9a:	6c42                	ld	s8,16(sp)
    80003d9c:	6ca2                	ld	s9,8(sp)
    80003d9e:	6d02                	ld	s10,0(sp)
    80003da0:	6125                	addi	sp,sp,96
    80003da2:	8082                	ret
      iunlock(ip);
    80003da4:	8552                	mv	a0,s4
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	aa2080e7          	jalr	-1374(ra) # 80003848 <iunlock>
      return ip;
    80003dae:	bfe1                	j	80003d86 <namex+0x6c>
      iunlockput(ip);
    80003db0:	8552                	mv	a0,s4
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	c36080e7          	jalr	-970(ra) # 800039e8 <iunlockput>
      return 0;
    80003dba:	8a4e                	mv	s4,s3
    80003dbc:	b7e9                	j	80003d86 <namex+0x6c>
  len = path - s;
    80003dbe:	40998633          	sub	a2,s3,s1
    80003dc2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dc6:	09acd863          	bge	s9,s10,80003e56 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dca:	4639                	li	a2,14
    80003dcc:	85a6                	mv	a1,s1
    80003dce:	8556                	mv	a0,s5
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	f5e080e7          	jalr	-162(ra) # 80000d2e <memmove>
    80003dd8:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	01279763          	bne	a5,s2,80003dec <namex+0xd2>
    path++;
    80003de2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	ff278de3          	beq	a5,s2,80003de2 <namex+0xc8>
    ilock(ip);
    80003dec:	8552                	mv	a0,s4
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	998080e7          	jalr	-1640(ra) # 80003786 <ilock>
    if(ip->type != T_DIR){
    80003df6:	044a1783          	lh	a5,68(s4)
    80003dfa:	f98790e3          	bne	a5,s8,80003d7a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003dfe:	000b0563          	beqz	s6,80003e08 <namex+0xee>
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	dfd9                	beqz	a5,80003da4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e08:	865e                	mv	a2,s7
    80003e0a:	85d6                	mv	a1,s5
    80003e0c:	8552                	mv	a0,s4
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	e5c080e7          	jalr	-420(ra) # 80003c6a <dirlookup>
    80003e16:	89aa                	mv	s3,a0
    80003e18:	dd41                	beqz	a0,80003db0 <namex+0x96>
    iunlockput(ip);
    80003e1a:	8552                	mv	a0,s4
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	bcc080e7          	jalr	-1076(ra) # 800039e8 <iunlockput>
    ip = next;
    80003e24:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	01279763          	bne	a5,s2,80003e38 <namex+0x11e>
    path++;
    80003e2e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e30:	0004c783          	lbu	a5,0(s1)
    80003e34:	ff278de3          	beq	a5,s2,80003e2e <namex+0x114>
  if(*path == 0)
    80003e38:	cb9d                	beqz	a5,80003e6e <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e3a:	0004c783          	lbu	a5,0(s1)
    80003e3e:	89a6                	mv	s3,s1
  len = path - s;
    80003e40:	8d5e                	mv	s10,s7
    80003e42:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e44:	01278963          	beq	a5,s2,80003e56 <namex+0x13c>
    80003e48:	dbbd                	beqz	a5,80003dbe <namex+0xa4>
    path++;
    80003e4a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e4c:	0009c783          	lbu	a5,0(s3)
    80003e50:	ff279ce3          	bne	a5,s2,80003e48 <namex+0x12e>
    80003e54:	b7ad                	j	80003dbe <namex+0xa4>
    memmove(name, s, len);
    80003e56:	2601                	sext.w	a2,a2
    80003e58:	85a6                	mv	a1,s1
    80003e5a:	8556                	mv	a0,s5
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	ed2080e7          	jalr	-302(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e64:	9d56                	add	s10,s10,s5
    80003e66:	000d0023          	sb	zero,0(s10)
    80003e6a:	84ce                	mv	s1,s3
    80003e6c:	b7bd                	j	80003dda <namex+0xc0>
  if(nameiparent){
    80003e6e:	f00b0ce3          	beqz	s6,80003d86 <namex+0x6c>
    iput(ip);
    80003e72:	8552                	mv	a0,s4
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	acc080e7          	jalr	-1332(ra) # 80003940 <iput>
    return 0;
    80003e7c:	4a01                	li	s4,0
    80003e7e:	b721                	j	80003d86 <namex+0x6c>

0000000080003e80 <dirlink>:
{
    80003e80:	7139                	addi	sp,sp,-64
    80003e82:	fc06                	sd	ra,56(sp)
    80003e84:	f822                	sd	s0,48(sp)
    80003e86:	f426                	sd	s1,40(sp)
    80003e88:	f04a                	sd	s2,32(sp)
    80003e8a:	ec4e                	sd	s3,24(sp)
    80003e8c:	e852                	sd	s4,16(sp)
    80003e8e:	0080                	addi	s0,sp,64
    80003e90:	892a                	mv	s2,a0
    80003e92:	8a2e                	mv	s4,a1
    80003e94:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e96:	4601                	li	a2,0
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	dd2080e7          	jalr	-558(ra) # 80003c6a <dirlookup>
    80003ea0:	e93d                	bnez	a0,80003f16 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea2:	04c92483          	lw	s1,76(s2)
    80003ea6:	c49d                	beqz	s1,80003ed4 <dirlink+0x54>
    80003ea8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eaa:	4741                	li	a4,16
    80003eac:	86a6                	mv	a3,s1
    80003eae:	fc040613          	addi	a2,s0,-64
    80003eb2:	4581                	li	a1,0
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	b84080e7          	jalr	-1148(ra) # 80003a3a <readi>
    80003ebe:	47c1                	li	a5,16
    80003ec0:	06f51163          	bne	a0,a5,80003f22 <dirlink+0xa2>
    if(de.inum == 0)
    80003ec4:	fc045783          	lhu	a5,-64(s0)
    80003ec8:	c791                	beqz	a5,80003ed4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	24c1                	addiw	s1,s1,16
    80003ecc:	04c92783          	lw	a5,76(s2)
    80003ed0:	fcf4ede3          	bltu	s1,a5,80003eaa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ed4:	4639                	li	a2,14
    80003ed6:	85d2                	mv	a1,s4
    80003ed8:	fc240513          	addi	a0,s0,-62
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	f02080e7          	jalr	-254(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003ee4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee8:	4741                	li	a4,16
    80003eea:	86a6                	mv	a3,s1
    80003eec:	fc040613          	addi	a2,s0,-64
    80003ef0:	4581                	li	a1,0
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	c3e080e7          	jalr	-962(ra) # 80003b32 <writei>
    80003efc:	1541                	addi	a0,a0,-16
    80003efe:	00a03533          	snez	a0,a0
    80003f02:	40a00533          	neg	a0,a0
}
    80003f06:	70e2                	ld	ra,56(sp)
    80003f08:	7442                	ld	s0,48(sp)
    80003f0a:	74a2                	ld	s1,40(sp)
    80003f0c:	7902                	ld	s2,32(sp)
    80003f0e:	69e2                	ld	s3,24(sp)
    80003f10:	6a42                	ld	s4,16(sp)
    80003f12:	6121                	addi	sp,sp,64
    80003f14:	8082                	ret
    iput(ip);
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	a2a080e7          	jalr	-1494(ra) # 80003940 <iput>
    return -1;
    80003f1e:	557d                	li	a0,-1
    80003f20:	b7dd                	j	80003f06 <dirlink+0x86>
      panic("dirlink read");
    80003f22:	00004517          	auipc	a0,0x4
    80003f26:	6f650513          	addi	a0,a0,1782 # 80008618 <syscalls+0x1c8>
    80003f2a:	ffffc097          	auipc	ra,0xffffc
    80003f2e:	616080e7          	jalr	1558(ra) # 80000540 <panic>

0000000080003f32 <namei>:

struct inode*
namei(char *path)
{
    80003f32:	1101                	addi	sp,sp,-32
    80003f34:	ec06                	sd	ra,24(sp)
    80003f36:	e822                	sd	s0,16(sp)
    80003f38:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f3a:	fe040613          	addi	a2,s0,-32
    80003f3e:	4581                	li	a1,0
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	dda080e7          	jalr	-550(ra) # 80003d1a <namex>
}
    80003f48:	60e2                	ld	ra,24(sp)
    80003f4a:	6442                	ld	s0,16(sp)
    80003f4c:	6105                	addi	sp,sp,32
    80003f4e:	8082                	ret

0000000080003f50 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f50:	1141                	addi	sp,sp,-16
    80003f52:	e406                	sd	ra,8(sp)
    80003f54:	e022                	sd	s0,0(sp)
    80003f56:	0800                	addi	s0,sp,16
    80003f58:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f5a:	4585                	li	a1,1
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	dbe080e7          	jalr	-578(ra) # 80003d1a <namex>
}
    80003f64:	60a2                	ld	ra,8(sp)
    80003f66:	6402                	ld	s0,0(sp)
    80003f68:	0141                	addi	sp,sp,16
    80003f6a:	8082                	ret

0000000080003f6c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	e426                	sd	s1,8(sp)
    80003f74:	e04a                	sd	s2,0(sp)
    80003f76:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f78:	0001d917          	auipc	s2,0x1d
    80003f7c:	7a890913          	addi	s2,s2,1960 # 80021720 <log>
    80003f80:	01892583          	lw	a1,24(s2)
    80003f84:	02892503          	lw	a0,40(s2)
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	fe6080e7          	jalr	-26(ra) # 80002f6e <bread>
    80003f90:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f92:	02c92683          	lw	a3,44(s2)
    80003f96:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f98:	02d05863          	blez	a3,80003fc8 <write_head+0x5c>
    80003f9c:	0001d797          	auipc	a5,0x1d
    80003fa0:	7b478793          	addi	a5,a5,1972 # 80021750 <log+0x30>
    80003fa4:	05c50713          	addi	a4,a0,92
    80003fa8:	36fd                	addiw	a3,a3,-1
    80003faa:	02069613          	slli	a2,a3,0x20
    80003fae:	01e65693          	srli	a3,a2,0x1e
    80003fb2:	0001d617          	auipc	a2,0x1d
    80003fb6:	7a260613          	addi	a2,a2,1954 # 80021754 <log+0x34>
    80003fba:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fbc:	4390                	lw	a2,0(a5)
    80003fbe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fc0:	0791                	addi	a5,a5,4
    80003fc2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fc4:	fed79ce3          	bne	a5,a3,80003fbc <write_head+0x50>
  }
  bwrite(buf);
    80003fc8:	8526                	mv	a0,s1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	096080e7          	jalr	150(ra) # 80003060 <bwrite>
  brelse(buf);
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	0ca080e7          	jalr	202(ra) # 8000309e <brelse>
}
    80003fdc:	60e2                	ld	ra,24(sp)
    80003fde:	6442                	ld	s0,16(sp)
    80003fe0:	64a2                	ld	s1,8(sp)
    80003fe2:	6902                	ld	s2,0(sp)
    80003fe4:	6105                	addi	sp,sp,32
    80003fe6:	8082                	ret

0000000080003fe8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fe8:	0001d797          	auipc	a5,0x1d
    80003fec:	7647a783          	lw	a5,1892(a5) # 8002174c <log+0x2c>
    80003ff0:	0af05d63          	blez	a5,800040aa <install_trans+0xc2>
{
    80003ff4:	7139                	addi	sp,sp,-64
    80003ff6:	fc06                	sd	ra,56(sp)
    80003ff8:	f822                	sd	s0,48(sp)
    80003ffa:	f426                	sd	s1,40(sp)
    80003ffc:	f04a                	sd	s2,32(sp)
    80003ffe:	ec4e                	sd	s3,24(sp)
    80004000:	e852                	sd	s4,16(sp)
    80004002:	e456                	sd	s5,8(sp)
    80004004:	e05a                	sd	s6,0(sp)
    80004006:	0080                	addi	s0,sp,64
    80004008:	8b2a                	mv	s6,a0
    8000400a:	0001da97          	auipc	s5,0x1d
    8000400e:	746a8a93          	addi	s5,s5,1862 # 80021750 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004012:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004014:	0001d997          	auipc	s3,0x1d
    80004018:	70c98993          	addi	s3,s3,1804 # 80021720 <log>
    8000401c:	a00d                	j	8000403e <install_trans+0x56>
    brelse(lbuf);
    8000401e:	854a                	mv	a0,s2
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	07e080e7          	jalr	126(ra) # 8000309e <brelse>
    brelse(dbuf);
    80004028:	8526                	mv	a0,s1
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	074080e7          	jalr	116(ra) # 8000309e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004032:	2a05                	addiw	s4,s4,1
    80004034:	0a91                	addi	s5,s5,4
    80004036:	02c9a783          	lw	a5,44(s3)
    8000403a:	04fa5e63          	bge	s4,a5,80004096 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403e:	0189a583          	lw	a1,24(s3)
    80004042:	014585bb          	addw	a1,a1,s4
    80004046:	2585                	addiw	a1,a1,1
    80004048:	0289a503          	lw	a0,40(s3)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	f22080e7          	jalr	-222(ra) # 80002f6e <bread>
    80004054:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004056:	000aa583          	lw	a1,0(s5)
    8000405a:	0289a503          	lw	a0,40(s3)
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	f10080e7          	jalr	-240(ra) # 80002f6e <bread>
    80004066:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004068:	40000613          	li	a2,1024
    8000406c:	05890593          	addi	a1,s2,88
    80004070:	05850513          	addi	a0,a0,88
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	cba080e7          	jalr	-838(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	fe2080e7          	jalr	-30(ra) # 80003060 <bwrite>
    if(recovering == 0)
    80004086:	f80b1ce3          	bnez	s6,8000401e <install_trans+0x36>
      bunpin(dbuf);
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	0ec080e7          	jalr	236(ra) # 80003178 <bunpin>
    80004094:	b769                	j	8000401e <install_trans+0x36>
}
    80004096:	70e2                	ld	ra,56(sp)
    80004098:	7442                	ld	s0,48(sp)
    8000409a:	74a2                	ld	s1,40(sp)
    8000409c:	7902                	ld	s2,32(sp)
    8000409e:	69e2                	ld	s3,24(sp)
    800040a0:	6a42                	ld	s4,16(sp)
    800040a2:	6aa2                	ld	s5,8(sp)
    800040a4:	6b02                	ld	s6,0(sp)
    800040a6:	6121                	addi	sp,sp,64
    800040a8:	8082                	ret
    800040aa:	8082                	ret

00000000800040ac <initlog>:
{
    800040ac:	7179                	addi	sp,sp,-48
    800040ae:	f406                	sd	ra,40(sp)
    800040b0:	f022                	sd	s0,32(sp)
    800040b2:	ec26                	sd	s1,24(sp)
    800040b4:	e84a                	sd	s2,16(sp)
    800040b6:	e44e                	sd	s3,8(sp)
    800040b8:	1800                	addi	s0,sp,48
    800040ba:	892a                	mv	s2,a0
    800040bc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040be:	0001d497          	auipc	s1,0x1d
    800040c2:	66248493          	addi	s1,s1,1634 # 80021720 <log>
    800040c6:	00004597          	auipc	a1,0x4
    800040ca:	56258593          	addi	a1,a1,1378 # 80008628 <syscalls+0x1d8>
    800040ce:	8526                	mv	a0,s1
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	a76080e7          	jalr	-1418(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040d8:	0149a583          	lw	a1,20(s3)
    800040dc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040de:	0109a783          	lw	a5,16(s3)
    800040e2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040e4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040e8:	854a                	mv	a0,s2
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	e84080e7          	jalr	-380(ra) # 80002f6e <bread>
  log.lh.n = lh->n;
    800040f2:	4d34                	lw	a3,88(a0)
    800040f4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040f6:	02d05663          	blez	a3,80004122 <initlog+0x76>
    800040fa:	05c50793          	addi	a5,a0,92
    800040fe:	0001d717          	auipc	a4,0x1d
    80004102:	65270713          	addi	a4,a4,1618 # 80021750 <log+0x30>
    80004106:	36fd                	addiw	a3,a3,-1
    80004108:	02069613          	slli	a2,a3,0x20
    8000410c:	01e65693          	srli	a3,a2,0x1e
    80004110:	06050613          	addi	a2,a0,96
    80004114:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004116:	4390                	lw	a2,0(a5)
    80004118:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000411a:	0791                	addi	a5,a5,4
    8000411c:	0711                	addi	a4,a4,4
    8000411e:	fed79ce3          	bne	a5,a3,80004116 <initlog+0x6a>
  brelse(buf);
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	f7c080e7          	jalr	-132(ra) # 8000309e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000412a:	4505                	li	a0,1
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	ebc080e7          	jalr	-324(ra) # 80003fe8 <install_trans>
  log.lh.n = 0;
    80004134:	0001d797          	auipc	a5,0x1d
    80004138:	6007ac23          	sw	zero,1560(a5) # 8002174c <log+0x2c>
  write_head(); // clear the log
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	e30080e7          	jalr	-464(ra) # 80003f6c <write_head>
}
    80004144:	70a2                	ld	ra,40(sp)
    80004146:	7402                	ld	s0,32(sp)
    80004148:	64e2                	ld	s1,24(sp)
    8000414a:	6942                	ld	s2,16(sp)
    8000414c:	69a2                	ld	s3,8(sp)
    8000414e:	6145                	addi	sp,sp,48
    80004150:	8082                	ret

0000000080004152 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004152:	1101                	addi	sp,sp,-32
    80004154:	ec06                	sd	ra,24(sp)
    80004156:	e822                	sd	s0,16(sp)
    80004158:	e426                	sd	s1,8(sp)
    8000415a:	e04a                	sd	s2,0(sp)
    8000415c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000415e:	0001d517          	auipc	a0,0x1d
    80004162:	5c250513          	addi	a0,a0,1474 # 80021720 <log>
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	a70080e7          	jalr	-1424(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000416e:	0001d497          	auipc	s1,0x1d
    80004172:	5b248493          	addi	s1,s1,1458 # 80021720 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004176:	4979                	li	s2,30
    80004178:	a039                	j	80004186 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000417a:	85a6                	mv	a1,s1
    8000417c:	8526                	mv	a0,s1
    8000417e:	ffffe097          	auipc	ra,0xffffe
    80004182:	030080e7          	jalr	48(ra) # 800021ae <sleep>
    if(log.committing){
    80004186:	50dc                	lw	a5,36(s1)
    80004188:	fbed                	bnez	a5,8000417a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418a:	5098                	lw	a4,32(s1)
    8000418c:	2705                	addiw	a4,a4,1
    8000418e:	0007069b          	sext.w	a3,a4
    80004192:	0027179b          	slliw	a5,a4,0x2
    80004196:	9fb9                	addw	a5,a5,a4
    80004198:	0017979b          	slliw	a5,a5,0x1
    8000419c:	54d8                	lw	a4,44(s1)
    8000419e:	9fb9                	addw	a5,a5,a4
    800041a0:	00f95963          	bge	s2,a5,800041b2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041a4:	85a6                	mv	a1,s1
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffe097          	auipc	ra,0xffffe
    800041ac:	006080e7          	jalr	6(ra) # 800021ae <sleep>
    800041b0:	bfd9                	j	80004186 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041b2:	0001d517          	auipc	a0,0x1d
    800041b6:	56e50513          	addi	a0,a0,1390 # 80021720 <log>
    800041ba:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	ace080e7          	jalr	-1330(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041c4:	60e2                	ld	ra,24(sp)
    800041c6:	6442                	ld	s0,16(sp)
    800041c8:	64a2                	ld	s1,8(sp)
    800041ca:	6902                	ld	s2,0(sp)
    800041cc:	6105                	addi	sp,sp,32
    800041ce:	8082                	ret

00000000800041d0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041d0:	7139                	addi	sp,sp,-64
    800041d2:	fc06                	sd	ra,56(sp)
    800041d4:	f822                	sd	s0,48(sp)
    800041d6:	f426                	sd	s1,40(sp)
    800041d8:	f04a                	sd	s2,32(sp)
    800041da:	ec4e                	sd	s3,24(sp)
    800041dc:	e852                	sd	s4,16(sp)
    800041de:	e456                	sd	s5,8(sp)
    800041e0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041e2:	0001d497          	auipc	s1,0x1d
    800041e6:	53e48493          	addi	s1,s1,1342 # 80021720 <log>
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffd097          	auipc	ra,0xffffd
    800041f0:	9ea080e7          	jalr	-1558(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800041f4:	509c                	lw	a5,32(s1)
    800041f6:	37fd                	addiw	a5,a5,-1
    800041f8:	0007891b          	sext.w	s2,a5
    800041fc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041fe:	50dc                	lw	a5,36(s1)
    80004200:	e7b9                	bnez	a5,8000424e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004202:	04091e63          	bnez	s2,8000425e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004206:	0001d497          	auipc	s1,0x1d
    8000420a:	51a48493          	addi	s1,s1,1306 # 80021720 <log>
    8000420e:	4785                	li	a5,1
    80004210:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	a76080e7          	jalr	-1418(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000421c:	54dc                	lw	a5,44(s1)
    8000421e:	06f04763          	bgtz	a5,8000428c <end_op+0xbc>
    acquire(&log.lock);
    80004222:	0001d497          	auipc	s1,0x1d
    80004226:	4fe48493          	addi	s1,s1,1278 # 80021720 <log>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004234:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	fd8080e7          	jalr	-40(ra) # 80002212 <wakeup>
    release(&log.lock);
    80004242:	8526                	mv	a0,s1
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
}
    8000424c:	a03d                	j	8000427a <end_op+0xaa>
    panic("log.committing");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	3e250513          	addi	a0,a0,994 # 80008630 <syscalls+0x1e0>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>
    wakeup(&log);
    8000425e:	0001d497          	auipc	s1,0x1d
    80004262:	4c248493          	addi	s1,s1,1218 # 80021720 <log>
    80004266:	8526                	mv	a0,s1
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	faa080e7          	jalr	-86(ra) # 80002212 <wakeup>
  release(&log.lock);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	69e2                	ld	s3,24(sp)
    80004284:	6a42                	ld	s4,16(sp)
    80004286:	6aa2                	ld	s5,8(sp)
    80004288:	6121                	addi	sp,sp,64
    8000428a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	0001da97          	auipc	s5,0x1d
    80004290:	4c4a8a93          	addi	s5,s5,1220 # 80021750 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004294:	0001da17          	auipc	s4,0x1d
    80004298:	48ca0a13          	addi	s4,s4,1164 # 80021720 <log>
    8000429c:	018a2583          	lw	a1,24(s4)
    800042a0:	012585bb          	addw	a1,a1,s2
    800042a4:	2585                	addiw	a1,a1,1
    800042a6:	028a2503          	lw	a0,40(s4)
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	cc4080e7          	jalr	-828(ra) # 80002f6e <bread>
    800042b2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042b4:	000aa583          	lw	a1,0(s5)
    800042b8:	028a2503          	lw	a0,40(s4)
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	cb2080e7          	jalr	-846(ra) # 80002f6e <bread>
    800042c4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042c6:	40000613          	li	a2,1024
    800042ca:	05850593          	addi	a1,a0,88
    800042ce:	05848513          	addi	a0,s1,88
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	a5c080e7          	jalr	-1444(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800042da:	8526                	mv	a0,s1
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	d84080e7          	jalr	-636(ra) # 80003060 <bwrite>
    brelse(from);
    800042e4:	854e                	mv	a0,s3
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	db8080e7          	jalr	-584(ra) # 8000309e <brelse>
    brelse(to);
    800042ee:	8526                	mv	a0,s1
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	dae080e7          	jalr	-594(ra) # 8000309e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f8:	2905                	addiw	s2,s2,1
    800042fa:	0a91                	addi	s5,s5,4
    800042fc:	02ca2783          	lw	a5,44(s4)
    80004300:	f8f94ee3          	blt	s2,a5,8000429c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004304:	00000097          	auipc	ra,0x0
    80004308:	c68080e7          	jalr	-920(ra) # 80003f6c <write_head>
    install_trans(0); // Now install writes to home locations
    8000430c:	4501                	li	a0,0
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	cda080e7          	jalr	-806(ra) # 80003fe8 <install_trans>
    log.lh.n = 0;
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	4207ab23          	sw	zero,1078(a5) # 8002174c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	c4e080e7          	jalr	-946(ra) # 80003f6c <write_head>
    80004326:	bdf5                	j	80004222 <end_op+0x52>

0000000080004328 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004328:	1101                	addi	sp,sp,-32
    8000432a:	ec06                	sd	ra,24(sp)
    8000432c:	e822                	sd	s0,16(sp)
    8000432e:	e426                	sd	s1,8(sp)
    80004330:	e04a                	sd	s2,0(sp)
    80004332:	1000                	addi	s0,sp,32
    80004334:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004336:	0001d917          	auipc	s2,0x1d
    8000433a:	3ea90913          	addi	s2,s2,1002 # 80021720 <log>
    8000433e:	854a                	mv	a0,s2
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	896080e7          	jalr	-1898(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004348:	02c92603          	lw	a2,44(s2)
    8000434c:	47f5                	li	a5,29
    8000434e:	06c7c563          	blt	a5,a2,800043b8 <log_write+0x90>
    80004352:	0001d797          	auipc	a5,0x1d
    80004356:	3ea7a783          	lw	a5,1002(a5) # 8002173c <log+0x1c>
    8000435a:	37fd                	addiw	a5,a5,-1
    8000435c:	04f65e63          	bge	a2,a5,800043b8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004360:	0001d797          	auipc	a5,0x1d
    80004364:	3e07a783          	lw	a5,992(a5) # 80021740 <log+0x20>
    80004368:	06f05063          	blez	a5,800043c8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000436c:	4781                	li	a5,0
    8000436e:	06c05563          	blez	a2,800043d8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004372:	44cc                	lw	a1,12(s1)
    80004374:	0001d717          	auipc	a4,0x1d
    80004378:	3dc70713          	addi	a4,a4,988 # 80021750 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000437c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000437e:	4314                	lw	a3,0(a4)
    80004380:	04b68c63          	beq	a3,a1,800043d8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004384:	2785                	addiw	a5,a5,1
    80004386:	0711                	addi	a4,a4,4
    80004388:	fef61be3          	bne	a2,a5,8000437e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000438c:	0621                	addi	a2,a2,8
    8000438e:	060a                	slli	a2,a2,0x2
    80004390:	0001d797          	auipc	a5,0x1d
    80004394:	39078793          	addi	a5,a5,912 # 80021720 <log>
    80004398:	97b2                	add	a5,a5,a2
    8000439a:	44d8                	lw	a4,12(s1)
    8000439c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	d9c080e7          	jalr	-612(ra) # 8000313c <bpin>
    log.lh.n++;
    800043a8:	0001d717          	auipc	a4,0x1d
    800043ac:	37870713          	addi	a4,a4,888 # 80021720 <log>
    800043b0:	575c                	lw	a5,44(a4)
    800043b2:	2785                	addiw	a5,a5,1
    800043b4:	d75c                	sw	a5,44(a4)
    800043b6:	a82d                	j	800043f0 <log_write+0xc8>
    panic("too big a transaction");
    800043b8:	00004517          	auipc	a0,0x4
    800043bc:	28850513          	addi	a0,a0,648 # 80008640 <syscalls+0x1f0>
    800043c0:	ffffc097          	auipc	ra,0xffffc
    800043c4:	180080e7          	jalr	384(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043c8:	00004517          	auipc	a0,0x4
    800043cc:	29050513          	addi	a0,a0,656 # 80008658 <syscalls+0x208>
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	170080e7          	jalr	368(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043d8:	00878693          	addi	a3,a5,8
    800043dc:	068a                	slli	a3,a3,0x2
    800043de:	0001d717          	auipc	a4,0x1d
    800043e2:	34270713          	addi	a4,a4,834 # 80021720 <log>
    800043e6:	9736                	add	a4,a4,a3
    800043e8:	44d4                	lw	a3,12(s1)
    800043ea:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043ec:	faf609e3          	beq	a2,a5,8000439e <log_write+0x76>
  }
  release(&log.lock);
    800043f0:	0001d517          	auipc	a0,0x1d
    800043f4:	33050513          	addi	a0,a0,816 # 80021720 <log>
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	892080e7          	jalr	-1902(ra) # 80000c8a <release>
}
    80004400:	60e2                	ld	ra,24(sp)
    80004402:	6442                	ld	s0,16(sp)
    80004404:	64a2                	ld	s1,8(sp)
    80004406:	6902                	ld	s2,0(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000440c:	1101                	addi	sp,sp,-32
    8000440e:	ec06                	sd	ra,24(sp)
    80004410:	e822                	sd	s0,16(sp)
    80004412:	e426                	sd	s1,8(sp)
    80004414:	e04a                	sd	s2,0(sp)
    80004416:	1000                	addi	s0,sp,32
    80004418:	84aa                	mv	s1,a0
    8000441a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000441c:	00004597          	auipc	a1,0x4
    80004420:	25c58593          	addi	a1,a1,604 # 80008678 <syscalls+0x228>
    80004424:	0521                	addi	a0,a0,8
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	720080e7          	jalr	1824(ra) # 80000b46 <initlock>
  lk->name = name;
    8000442e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004432:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004436:	0204a423          	sw	zero,40(s1)
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004462:	409c                	lw	a5,0(s1)
    80004464:	cb89                	beqz	a5,80004476 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004466:	85ca                	mv	a1,s2
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffe097          	auipc	ra,0xffffe
    8000446e:	d44080e7          	jalr	-700(ra) # 800021ae <sleep>
  while (lk->locked) {
    80004472:	409c                	lw	a5,0(s1)
    80004474:	fbed                	bnez	a5,80004466 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004476:	4785                	li	a5,1
    80004478:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	562080e7          	jalr	1378(ra) # 800019dc <myproc>
    80004482:	591c                	lw	a5,48(a0)
    80004484:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004486:	854a                	mv	a0,s2
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
}
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6902                	ld	s2,0(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec06                	sd	ra,24(sp)
    800044a0:	e822                	sd	s0,16(sp)
    800044a2:	e426                	sd	s1,8(sp)
    800044a4:	e04a                	sd	s2,0(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044aa:	00850913          	addi	s2,a0,8
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	726080e7          	jalr	1830(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044bc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffe097          	auipc	ra,0xffffe
    800044c6:	d50080e7          	jalr	-688(ra) # 80002212 <wakeup>
  release(&lk->lk);
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7be080e7          	jalr	1982(ra) # 80000c8a <release>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044e0:	7179                	addi	sp,sp,-48
    800044e2:	f406                	sd	ra,40(sp)
    800044e4:	f022                	sd	s0,32(sp)
    800044e6:	ec26                	sd	s1,24(sp)
    800044e8:	e84a                	sd	s2,16(sp)
    800044ea:	e44e                	sd	s3,8(sp)
    800044ec:	1800                	addi	s0,sp,48
    800044ee:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044f0:	00850913          	addi	s2,a0,8
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6e0080e7          	jalr	1760(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044fe:	409c                	lw	a5,0(s1)
    80004500:	ef99                	bnez	a5,8000451e <holdingsleep+0x3e>
    80004502:	4481                	li	s1,0
  release(&lk->lk);
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	784080e7          	jalr	1924(ra) # 80000c8a <release>
  return r;
}
    8000450e:	8526                	mv	a0,s1
    80004510:	70a2                	ld	ra,40(sp)
    80004512:	7402                	ld	s0,32(sp)
    80004514:	64e2                	ld	s1,24(sp)
    80004516:	6942                	ld	s2,16(sp)
    80004518:	69a2                	ld	s3,8(sp)
    8000451a:	6145                	addi	sp,sp,48
    8000451c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000451e:	0284a983          	lw	s3,40(s1)
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	4ba080e7          	jalr	1210(ra) # 800019dc <myproc>
    8000452a:	5904                	lw	s1,48(a0)
    8000452c:	413484b3          	sub	s1,s1,s3
    80004530:	0014b493          	seqz	s1,s1
    80004534:	bfc1                	j	80004504 <holdingsleep+0x24>

0000000080004536 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004536:	1141                	addi	sp,sp,-16
    80004538:	e406                	sd	ra,8(sp)
    8000453a:	e022                	sd	s0,0(sp)
    8000453c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000453e:	00004597          	auipc	a1,0x4
    80004542:	14a58593          	addi	a1,a1,330 # 80008688 <syscalls+0x238>
    80004546:	0001d517          	auipc	a0,0x1d
    8000454a:	32250513          	addi	a0,a0,802 # 80021868 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	5f8080e7          	jalr	1528(ra) # 80000b46 <initlock>
}
    80004556:	60a2                	ld	ra,8(sp)
    80004558:	6402                	ld	s0,0(sp)
    8000455a:	0141                	addi	sp,sp,16
    8000455c:	8082                	ret

000000008000455e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004568:	0001d517          	auipc	a0,0x1d
    8000456c:	30050513          	addi	a0,a0,768 # 80021868 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	666080e7          	jalr	1638(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004578:	0001d497          	auipc	s1,0x1d
    8000457c:	30848493          	addi	s1,s1,776 # 80021880 <ftable+0x18>
    80004580:	0001e717          	auipc	a4,0x1e
    80004584:	2a070713          	addi	a4,a4,672 # 80022820 <disk>
    if(f->ref == 0){
    80004588:	40dc                	lw	a5,4(s1)
    8000458a:	cf99                	beqz	a5,800045a8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000458c:	02848493          	addi	s1,s1,40
    80004590:	fee49ce3          	bne	s1,a4,80004588 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004594:	0001d517          	auipc	a0,0x1d
    80004598:	2d450513          	addi	a0,a0,724 # 80021868 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6ee080e7          	jalr	1774(ra) # 80000c8a <release>
  return 0;
    800045a4:	4481                	li	s1,0
    800045a6:	a819                	j	800045bc <filealloc+0x5e>
      f->ref = 1;
    800045a8:	4785                	li	a5,1
    800045aa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	2bc50513          	addi	a0,a0,700 # 80021868 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6d6080e7          	jalr	1750(ra) # 80000c8a <release>
}
    800045bc:	8526                	mv	a0,s1
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	1000                	addi	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045d4:	0001d517          	auipc	a0,0x1d
    800045d8:	29450513          	addi	a0,a0,660 # 80021868 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	5fa080e7          	jalr	1530(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045e4:	40dc                	lw	a5,4(s1)
    800045e6:	02f05263          	blez	a5,8000460a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045ea:	2785                	addiw	a5,a5,1
    800045ec:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	27a50513          	addi	a0,a0,634 # 80021868 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
  return f;
}
    800045fe:	8526                	mv	a0,s1
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret
    panic("filedup");
    8000460a:	00004517          	auipc	a0,0x4
    8000460e:	08650513          	addi	a0,a0,134 # 80008690 <syscalls+0x240>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	f2e080e7          	jalr	-210(ra) # 80000540 <panic>

000000008000461a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000461a:	7139                	addi	sp,sp,-64
    8000461c:	fc06                	sd	ra,56(sp)
    8000461e:	f822                	sd	s0,48(sp)
    80004620:	f426                	sd	s1,40(sp)
    80004622:	f04a                	sd	s2,32(sp)
    80004624:	ec4e                	sd	s3,24(sp)
    80004626:	e852                	sd	s4,16(sp)
    80004628:	e456                	sd	s5,8(sp)
    8000462a:	0080                	addi	s0,sp,64
    8000462c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	23a50513          	addi	a0,a0,570 # 80021868 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5a0080e7          	jalr	1440(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000463e:	40dc                	lw	a5,4(s1)
    80004640:	06f05163          	blez	a5,800046a2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004644:	37fd                	addiw	a5,a5,-1
    80004646:	0007871b          	sext.w	a4,a5
    8000464a:	c0dc                	sw	a5,4(s1)
    8000464c:	06e04363          	bgtz	a4,800046b2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004650:	0004a903          	lw	s2,0(s1)
    80004654:	0094ca83          	lbu	s5,9(s1)
    80004658:	0104ba03          	ld	s4,16(s1)
    8000465c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004660:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004664:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004668:	0001d517          	auipc	a0,0x1d
    8000466c:	20050513          	addi	a0,a0,512 # 80021868 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	61a080e7          	jalr	1562(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004678:	4785                	li	a5,1
    8000467a:	04f90d63          	beq	s2,a5,800046d4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000467e:	3979                	addiw	s2,s2,-2
    80004680:	4785                	li	a5,1
    80004682:	0527e063          	bltu	a5,s2,800046c2 <fileclose+0xa8>
    begin_op();
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	acc080e7          	jalr	-1332(ra) # 80004152 <begin_op>
    iput(ff.ip);
    8000468e:	854e                	mv	a0,s3
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	2b0080e7          	jalr	688(ra) # 80003940 <iput>
    end_op();
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	b38080e7          	jalr	-1224(ra) # 800041d0 <end_op>
    800046a0:	a00d                	j	800046c2 <fileclose+0xa8>
    panic("fileclose");
    800046a2:	00004517          	auipc	a0,0x4
    800046a6:	ff650513          	addi	a0,a0,-10 # 80008698 <syscalls+0x248>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	e96080e7          	jalr	-362(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046b2:	0001d517          	auipc	a0,0x1d
    800046b6:	1b650513          	addi	a0,a0,438 # 80021868 <ftable>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>
  }
}
    800046c2:	70e2                	ld	ra,56(sp)
    800046c4:	7442                	ld	s0,48(sp)
    800046c6:	74a2                	ld	s1,40(sp)
    800046c8:	7902                	ld	s2,32(sp)
    800046ca:	69e2                	ld	s3,24(sp)
    800046cc:	6a42                	ld	s4,16(sp)
    800046ce:	6aa2                	ld	s5,8(sp)
    800046d0:	6121                	addi	sp,sp,64
    800046d2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046d4:	85d6                	mv	a1,s5
    800046d6:	8552                	mv	a0,s4
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	34c080e7          	jalr	844(ra) # 80004a24 <pipeclose>
    800046e0:	b7cd                	j	800046c2 <fileclose+0xa8>

00000000800046e2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046e2:	715d                	addi	sp,sp,-80
    800046e4:	e486                	sd	ra,72(sp)
    800046e6:	e0a2                	sd	s0,64(sp)
    800046e8:	fc26                	sd	s1,56(sp)
    800046ea:	f84a                	sd	s2,48(sp)
    800046ec:	f44e                	sd	s3,40(sp)
    800046ee:	0880                	addi	s0,sp,80
    800046f0:	84aa                	mv	s1,a0
    800046f2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	2e8080e7          	jalr	744(ra) # 800019dc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	37f9                	addiw	a5,a5,-2
    80004700:	4705                	li	a4,1
    80004702:	04f76763          	bltu	a4,a5,80004750 <filestat+0x6e>
    80004706:	892a                	mv	s2,a0
    ilock(f->ip);
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	07c080e7          	jalr	124(ra) # 80003786 <ilock>
    stati(f->ip, &st);
    80004712:	fb840593          	addi	a1,s0,-72
    80004716:	6c88                	ld	a0,24(s1)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	2f8080e7          	jalr	760(ra) # 80003a10 <stati>
    iunlock(f->ip);
    80004720:	6c88                	ld	a0,24(s1)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	126080e7          	jalr	294(ra) # 80003848 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000472a:	46e1                	li	a3,24
    8000472c:	fb840613          	addi	a2,s0,-72
    80004730:	85ce                	mv	a1,s3
    80004732:	05093503          	ld	a0,80(s2)
    80004736:	ffffd097          	auipc	ra,0xffffd
    8000473a:	f36080e7          	jalr	-202(ra) # 8000166c <copyout>
    8000473e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004742:	60a6                	ld	ra,72(sp)
    80004744:	6406                	ld	s0,64(sp)
    80004746:	74e2                	ld	s1,56(sp)
    80004748:	7942                	ld	s2,48(sp)
    8000474a:	79a2                	ld	s3,40(sp)
    8000474c:	6161                	addi	sp,sp,80
    8000474e:	8082                	ret
  return -1;
    80004750:	557d                	li	a0,-1
    80004752:	bfc5                	j	80004742 <filestat+0x60>

0000000080004754 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004754:	7179                	addi	sp,sp,-48
    80004756:	f406                	sd	ra,40(sp)
    80004758:	f022                	sd	s0,32(sp)
    8000475a:	ec26                	sd	s1,24(sp)
    8000475c:	e84a                	sd	s2,16(sp)
    8000475e:	e44e                	sd	s3,8(sp)
    80004760:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004762:	00854783          	lbu	a5,8(a0)
    80004766:	c3d5                	beqz	a5,8000480a <fileread+0xb6>
    80004768:	84aa                	mv	s1,a0
    8000476a:	89ae                	mv	s3,a1
    8000476c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000476e:	411c                	lw	a5,0(a0)
    80004770:	4705                	li	a4,1
    80004772:	04e78963          	beq	a5,a4,800047c4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004776:	470d                	li	a4,3
    80004778:	04e78d63          	beq	a5,a4,800047d2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000477c:	4709                	li	a4,2
    8000477e:	06e79e63          	bne	a5,a4,800047fa <fileread+0xa6>
    ilock(f->ip);
    80004782:	6d08                	ld	a0,24(a0)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	002080e7          	jalr	2(ra) # 80003786 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000478c:	874a                	mv	a4,s2
    8000478e:	5094                	lw	a3,32(s1)
    80004790:	864e                	mv	a2,s3
    80004792:	4585                	li	a1,1
    80004794:	6c88                	ld	a0,24(s1)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	2a4080e7          	jalr	676(ra) # 80003a3a <readi>
    8000479e:	892a                	mv	s2,a0
    800047a0:	00a05563          	blez	a0,800047aa <fileread+0x56>
      f->off += r;
    800047a4:	509c                	lw	a5,32(s1)
    800047a6:	9fa9                	addw	a5,a5,a0
    800047a8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047aa:	6c88                	ld	a0,24(s1)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	09c080e7          	jalr	156(ra) # 80003848 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047b4:	854a                	mv	a0,s2
    800047b6:	70a2                	ld	ra,40(sp)
    800047b8:	7402                	ld	s0,32(sp)
    800047ba:	64e2                	ld	s1,24(sp)
    800047bc:	6942                	ld	s2,16(sp)
    800047be:	69a2                	ld	s3,8(sp)
    800047c0:	6145                	addi	sp,sp,48
    800047c2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047c4:	6908                	ld	a0,16(a0)
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	3c6080e7          	jalr	966(ra) # 80004b8c <piperead>
    800047ce:	892a                	mv	s2,a0
    800047d0:	b7d5                	j	800047b4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047d2:	02451783          	lh	a5,36(a0)
    800047d6:	03079693          	slli	a3,a5,0x30
    800047da:	92c1                	srli	a3,a3,0x30
    800047dc:	4725                	li	a4,9
    800047de:	02d76863          	bltu	a4,a3,8000480e <fileread+0xba>
    800047e2:	0792                	slli	a5,a5,0x4
    800047e4:	0001d717          	auipc	a4,0x1d
    800047e8:	fe470713          	addi	a4,a4,-28 # 800217c8 <devsw>
    800047ec:	97ba                	add	a5,a5,a4
    800047ee:	639c                	ld	a5,0(a5)
    800047f0:	c38d                	beqz	a5,80004812 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047f2:	4505                	li	a0,1
    800047f4:	9782                	jalr	a5
    800047f6:	892a                	mv	s2,a0
    800047f8:	bf75                	j	800047b4 <fileread+0x60>
    panic("fileread");
    800047fa:	00004517          	auipc	a0,0x4
    800047fe:	eae50513          	addi	a0,a0,-338 # 800086a8 <syscalls+0x258>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	d3e080e7          	jalr	-706(ra) # 80000540 <panic>
    return -1;
    8000480a:	597d                	li	s2,-1
    8000480c:	b765                	j	800047b4 <fileread+0x60>
      return -1;
    8000480e:	597d                	li	s2,-1
    80004810:	b755                	j	800047b4 <fileread+0x60>
    80004812:	597d                	li	s2,-1
    80004814:	b745                	j	800047b4 <fileread+0x60>

0000000080004816 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004816:	715d                	addi	sp,sp,-80
    80004818:	e486                	sd	ra,72(sp)
    8000481a:	e0a2                	sd	s0,64(sp)
    8000481c:	fc26                	sd	s1,56(sp)
    8000481e:	f84a                	sd	s2,48(sp)
    80004820:	f44e                	sd	s3,40(sp)
    80004822:	f052                	sd	s4,32(sp)
    80004824:	ec56                	sd	s5,24(sp)
    80004826:	e85a                	sd	s6,16(sp)
    80004828:	e45e                	sd	s7,8(sp)
    8000482a:	e062                	sd	s8,0(sp)
    8000482c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000482e:	00954783          	lbu	a5,9(a0)
    80004832:	10078663          	beqz	a5,8000493e <filewrite+0x128>
    80004836:	892a                	mv	s2,a0
    80004838:	8b2e                	mv	s6,a1
    8000483a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000483c:	411c                	lw	a5,0(a0)
    8000483e:	4705                	li	a4,1
    80004840:	02e78263          	beq	a5,a4,80004864 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004844:	470d                	li	a4,3
    80004846:	02e78663          	beq	a5,a4,80004872 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000484a:	4709                	li	a4,2
    8000484c:	0ee79163          	bne	a5,a4,8000492e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004850:	0ac05d63          	blez	a2,8000490a <filewrite+0xf4>
    int i = 0;
    80004854:	4981                	li	s3,0
    80004856:	6b85                	lui	s7,0x1
    80004858:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000485c:	6c05                	lui	s8,0x1
    8000485e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004862:	a861                	j	800048fa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004864:	6908                	ld	a0,16(a0)
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	22e080e7          	jalr	558(ra) # 80004a94 <pipewrite>
    8000486e:	8a2a                	mv	s4,a0
    80004870:	a045                	j	80004910 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004872:	02451783          	lh	a5,36(a0)
    80004876:	03079693          	slli	a3,a5,0x30
    8000487a:	92c1                	srli	a3,a3,0x30
    8000487c:	4725                	li	a4,9
    8000487e:	0cd76263          	bltu	a4,a3,80004942 <filewrite+0x12c>
    80004882:	0792                	slli	a5,a5,0x4
    80004884:	0001d717          	auipc	a4,0x1d
    80004888:	f4470713          	addi	a4,a4,-188 # 800217c8 <devsw>
    8000488c:	97ba                	add	a5,a5,a4
    8000488e:	679c                	ld	a5,8(a5)
    80004890:	cbdd                	beqz	a5,80004946 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004892:	4505                	li	a0,1
    80004894:	9782                	jalr	a5
    80004896:	8a2a                	mv	s4,a0
    80004898:	a8a5                	j	80004910 <filewrite+0xfa>
    8000489a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	8b4080e7          	jalr	-1868(ra) # 80004152 <begin_op>
      ilock(f->ip);
    800048a6:	01893503          	ld	a0,24(s2)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	edc080e7          	jalr	-292(ra) # 80003786 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048b2:	8756                	mv	a4,s5
    800048b4:	02092683          	lw	a3,32(s2)
    800048b8:	01698633          	add	a2,s3,s6
    800048bc:	4585                	li	a1,1
    800048be:	01893503          	ld	a0,24(s2)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	270080e7          	jalr	624(ra) # 80003b32 <writei>
    800048ca:	84aa                	mv	s1,a0
    800048cc:	00a05763          	blez	a0,800048da <filewrite+0xc4>
        f->off += r;
    800048d0:	02092783          	lw	a5,32(s2)
    800048d4:	9fa9                	addw	a5,a5,a0
    800048d6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048da:	01893503          	ld	a0,24(s2)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	f6a080e7          	jalr	-150(ra) # 80003848 <iunlock>
      end_op();
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	8ea080e7          	jalr	-1814(ra) # 800041d0 <end_op>

      if(r != n1){
    800048ee:	009a9f63          	bne	s5,s1,8000490c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048f2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048f6:	0149db63          	bge	s3,s4,8000490c <filewrite+0xf6>
      int n1 = n - i;
    800048fa:	413a04bb          	subw	s1,s4,s3
    800048fe:	0004879b          	sext.w	a5,s1
    80004902:	f8fbdce3          	bge	s7,a5,8000489a <filewrite+0x84>
    80004906:	84e2                	mv	s1,s8
    80004908:	bf49                	j	8000489a <filewrite+0x84>
    int i = 0;
    8000490a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000490c:	013a1f63          	bne	s4,s3,8000492a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004910:	8552                	mv	a0,s4
    80004912:	60a6                	ld	ra,72(sp)
    80004914:	6406                	ld	s0,64(sp)
    80004916:	74e2                	ld	s1,56(sp)
    80004918:	7942                	ld	s2,48(sp)
    8000491a:	79a2                	ld	s3,40(sp)
    8000491c:	7a02                	ld	s4,32(sp)
    8000491e:	6ae2                	ld	s5,24(sp)
    80004920:	6b42                	ld	s6,16(sp)
    80004922:	6ba2                	ld	s7,8(sp)
    80004924:	6c02                	ld	s8,0(sp)
    80004926:	6161                	addi	sp,sp,80
    80004928:	8082                	ret
    ret = (i == n ? n : -1);
    8000492a:	5a7d                	li	s4,-1
    8000492c:	b7d5                	j	80004910 <filewrite+0xfa>
    panic("filewrite");
    8000492e:	00004517          	auipc	a0,0x4
    80004932:	d8a50513          	addi	a0,a0,-630 # 800086b8 <syscalls+0x268>
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	c0a080e7          	jalr	-1014(ra) # 80000540 <panic>
    return -1;
    8000493e:	5a7d                	li	s4,-1
    80004940:	bfc1                	j	80004910 <filewrite+0xfa>
      return -1;
    80004942:	5a7d                	li	s4,-1
    80004944:	b7f1                	j	80004910 <filewrite+0xfa>
    80004946:	5a7d                	li	s4,-1
    80004948:	b7e1                	j	80004910 <filewrite+0xfa>

000000008000494a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000494a:	7179                	addi	sp,sp,-48
    8000494c:	f406                	sd	ra,40(sp)
    8000494e:	f022                	sd	s0,32(sp)
    80004950:	ec26                	sd	s1,24(sp)
    80004952:	e84a                	sd	s2,16(sp)
    80004954:	e44e                	sd	s3,8(sp)
    80004956:	e052                	sd	s4,0(sp)
    80004958:	1800                	addi	s0,sp,48
    8000495a:	84aa                	mv	s1,a0
    8000495c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000495e:	0005b023          	sd	zero,0(a1)
    80004962:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	bf8080e7          	jalr	-1032(ra) # 8000455e <filealloc>
    8000496e:	e088                	sd	a0,0(s1)
    80004970:	c551                	beqz	a0,800049fc <pipealloc+0xb2>
    80004972:	00000097          	auipc	ra,0x0
    80004976:	bec080e7          	jalr	-1044(ra) # 8000455e <filealloc>
    8000497a:	00aa3023          	sd	a0,0(s4)
    8000497e:	c92d                	beqz	a0,800049f0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	166080e7          	jalr	358(ra) # 80000ae6 <kalloc>
    80004988:	892a                	mv	s2,a0
    8000498a:	c125                	beqz	a0,800049ea <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000498c:	4985                	li	s3,1
    8000498e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004992:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004996:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000499a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000499e:	00004597          	auipc	a1,0x4
    800049a2:	d2a58593          	addi	a1,a1,-726 # 800086c8 <syscalls+0x278>
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	1a0080e7          	jalr	416(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049ae:	609c                	ld	a5,0(s1)
    800049b0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049b4:	609c                	ld	a5,0(s1)
    800049b6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ba:	609c                	ld	a5,0(s1)
    800049bc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049c0:	609c                	ld	a5,0(s1)
    800049c2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049c6:	000a3783          	ld	a5,0(s4)
    800049ca:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049ce:	000a3783          	ld	a5,0(s4)
    800049d2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049d6:	000a3783          	ld	a5,0(s4)
    800049da:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049de:	000a3783          	ld	a5,0(s4)
    800049e2:	0127b823          	sd	s2,16(a5)
  return 0;
    800049e6:	4501                	li	a0,0
    800049e8:	a025                	j	80004a10 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049ea:	6088                	ld	a0,0(s1)
    800049ec:	e501                	bnez	a0,800049f4 <pipealloc+0xaa>
    800049ee:	a039                	j	800049fc <pipealloc+0xb2>
    800049f0:	6088                	ld	a0,0(s1)
    800049f2:	c51d                	beqz	a0,80004a20 <pipealloc+0xd6>
    fileclose(*f0);
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	c26080e7          	jalr	-986(ra) # 8000461a <fileclose>
  if(*f1)
    800049fc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a00:	557d                	li	a0,-1
  if(*f1)
    80004a02:	c799                	beqz	a5,80004a10 <pipealloc+0xc6>
    fileclose(*f1);
    80004a04:	853e                	mv	a0,a5
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	c14080e7          	jalr	-1004(ra) # 8000461a <fileclose>
  return -1;
    80004a0e:	557d                	li	a0,-1
}
    80004a10:	70a2                	ld	ra,40(sp)
    80004a12:	7402                	ld	s0,32(sp)
    80004a14:	64e2                	ld	s1,24(sp)
    80004a16:	6942                	ld	s2,16(sp)
    80004a18:	69a2                	ld	s3,8(sp)
    80004a1a:	6a02                	ld	s4,0(sp)
    80004a1c:	6145                	addi	sp,sp,48
    80004a1e:	8082                	ret
  return -1;
    80004a20:	557d                	li	a0,-1
    80004a22:	b7fd                	j	80004a10 <pipealloc+0xc6>

0000000080004a24 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a24:	1101                	addi	sp,sp,-32
    80004a26:	ec06                	sd	ra,24(sp)
    80004a28:	e822                	sd	s0,16(sp)
    80004a2a:	e426                	sd	s1,8(sp)
    80004a2c:	e04a                	sd	s2,0(sp)
    80004a2e:	1000                	addi	s0,sp,32
    80004a30:	84aa                	mv	s1,a0
    80004a32:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	1a2080e7          	jalr	418(ra) # 80000bd6 <acquire>
  if(writable){
    80004a3c:	02090d63          	beqz	s2,80004a76 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a40:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a44:	21848513          	addi	a0,s1,536
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	7ca080e7          	jalr	1994(ra) # 80002212 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a50:	2204b783          	ld	a5,544(s1)
    80004a54:	eb95                	bnez	a5,80004a88 <pipeclose+0x64>
    release(&pi->lock);
    80004a56:	8526                	mv	a0,s1
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	232080e7          	jalr	562(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	f86080e7          	jalr	-122(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a6a:	60e2                	ld	ra,24(sp)
    80004a6c:	6442                	ld	s0,16(sp)
    80004a6e:	64a2                	ld	s1,8(sp)
    80004a70:	6902                	ld	s2,0(sp)
    80004a72:	6105                	addi	sp,sp,32
    80004a74:	8082                	ret
    pi->readopen = 0;
    80004a76:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a7a:	21c48513          	addi	a0,s1,540
    80004a7e:	ffffd097          	auipc	ra,0xffffd
    80004a82:	794080e7          	jalr	1940(ra) # 80002212 <wakeup>
    80004a86:	b7e9                	j	80004a50 <pipeclose+0x2c>
    release(&pi->lock);
    80004a88:	8526                	mv	a0,s1
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	200080e7          	jalr	512(ra) # 80000c8a <release>
}
    80004a92:	bfe1                	j	80004a6a <pipeclose+0x46>

0000000080004a94 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a94:	711d                	addi	sp,sp,-96
    80004a96:	ec86                	sd	ra,88(sp)
    80004a98:	e8a2                	sd	s0,80(sp)
    80004a9a:	e4a6                	sd	s1,72(sp)
    80004a9c:	e0ca                	sd	s2,64(sp)
    80004a9e:	fc4e                	sd	s3,56(sp)
    80004aa0:	f852                	sd	s4,48(sp)
    80004aa2:	f456                	sd	s5,40(sp)
    80004aa4:	f05a                	sd	s6,32(sp)
    80004aa6:	ec5e                	sd	s7,24(sp)
    80004aa8:	e862                	sd	s8,16(sp)
    80004aaa:	1080                	addi	s0,sp,96
    80004aac:	84aa                	mv	s1,a0
    80004aae:	8aae                	mv	s5,a1
    80004ab0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	f2a080e7          	jalr	-214(ra) # 800019dc <myproc>
    80004aba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	118080e7          	jalr	280(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ac6:	0b405663          	blez	s4,80004b72 <pipewrite+0xde>
  int i = 0;
    80004aca:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004acc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ace:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ad2:	21c48b93          	addi	s7,s1,540
    80004ad6:	a089                	j	80004b18 <pipewrite+0x84>
      release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1b0080e7          	jalr	432(ra) # 80000c8a <release>
      return -1;
    80004ae2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ae4:	854a                	mv	a0,s2
    80004ae6:	60e6                	ld	ra,88(sp)
    80004ae8:	6446                	ld	s0,80(sp)
    80004aea:	64a6                	ld	s1,72(sp)
    80004aec:	6906                	ld	s2,64(sp)
    80004aee:	79e2                	ld	s3,56(sp)
    80004af0:	7a42                	ld	s4,48(sp)
    80004af2:	7aa2                	ld	s5,40(sp)
    80004af4:	7b02                	ld	s6,32(sp)
    80004af6:	6be2                	ld	s7,24(sp)
    80004af8:	6c42                	ld	s8,16(sp)
    80004afa:	6125                	addi	sp,sp,96
    80004afc:	8082                	ret
      wakeup(&pi->nread);
    80004afe:	8562                	mv	a0,s8
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	712080e7          	jalr	1810(ra) # 80002212 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b08:	85a6                	mv	a1,s1
    80004b0a:	855e                	mv	a0,s7
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	6a2080e7          	jalr	1698(ra) # 800021ae <sleep>
  while(i < n){
    80004b14:	07495063          	bge	s2,s4,80004b74 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b18:	2204a783          	lw	a5,544(s1)
    80004b1c:	dfd5                	beqz	a5,80004ad8 <pipewrite+0x44>
    80004b1e:	854e                	mv	a0,s3
    80004b20:	ffffe097          	auipc	ra,0xffffe
    80004b24:	936080e7          	jalr	-1738(ra) # 80002456 <killed>
    80004b28:	f945                	bnez	a0,80004ad8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b2a:	2184a783          	lw	a5,536(s1)
    80004b2e:	21c4a703          	lw	a4,540(s1)
    80004b32:	2007879b          	addiw	a5,a5,512
    80004b36:	fcf704e3          	beq	a4,a5,80004afe <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3a:	4685                	li	a3,1
    80004b3c:	01590633          	add	a2,s2,s5
    80004b40:	faf40593          	addi	a1,s0,-81
    80004b44:	0509b503          	ld	a0,80(s3)
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	bb0080e7          	jalr	-1104(ra) # 800016f8 <copyin>
    80004b50:	03650263          	beq	a0,s6,80004b74 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b54:	21c4a783          	lw	a5,540(s1)
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ae23          	sw	a4,540(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	faf44703          	lbu	a4,-81(s0)
    80004b6a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b6e:	2905                	addiw	s2,s2,1
    80004b70:	b755                	j	80004b14 <pipewrite+0x80>
  int i = 0;
    80004b72:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b74:	21848513          	addi	a0,s1,536
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	69a080e7          	jalr	1690(ra) # 80002212 <wakeup>
  release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	108080e7          	jalr	264(ra) # 80000c8a <release>
  return i;
    80004b8a:	bfa9                	j	80004ae4 <pipewrite+0x50>

0000000080004b8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b8c:	715d                	addi	sp,sp,-80
    80004b8e:	e486                	sd	ra,72(sp)
    80004b90:	e0a2                	sd	s0,64(sp)
    80004b92:	fc26                	sd	s1,56(sp)
    80004b94:	f84a                	sd	s2,48(sp)
    80004b96:	f44e                	sd	s3,40(sp)
    80004b98:	f052                	sd	s4,32(sp)
    80004b9a:	ec56                	sd	s5,24(sp)
    80004b9c:	e85a                	sd	s6,16(sp)
    80004b9e:	0880                	addi	s0,sp,80
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	892e                	mv	s2,a1
    80004ba4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	e36080e7          	jalr	-458(ra) # 800019dc <myproc>
    80004bae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	024080e7          	jalr	36(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bba:	2184a703          	lw	a4,536(s1)
    80004bbe:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc6:	02f71763          	bne	a4,a5,80004bf4 <piperead+0x68>
    80004bca:	2244a783          	lw	a5,548(s1)
    80004bce:	c39d                	beqz	a5,80004bf4 <piperead+0x68>
    if(killed(pr)){
    80004bd0:	8552                	mv	a0,s4
    80004bd2:	ffffe097          	auipc	ra,0xffffe
    80004bd6:	884080e7          	jalr	-1916(ra) # 80002456 <killed>
    80004bda:	e949                	bnez	a0,80004c6c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bdc:	85a6                	mv	a1,s1
    80004bde:	854e                	mv	a0,s3
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	5ce080e7          	jalr	1486(ra) # 800021ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	2184a703          	lw	a4,536(s1)
    80004bec:	21c4a783          	lw	a5,540(s1)
    80004bf0:	fcf70de3          	beq	a4,a5,80004bca <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf8:	05505463          	blez	s5,80004c40 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004bfc:	2184a783          	lw	a5,536(s1)
    80004c00:	21c4a703          	lw	a4,540(s1)
    80004c04:	02f70e63          	beq	a4,a5,80004c40 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c08:	0017871b          	addiw	a4,a5,1
    80004c0c:	20e4ac23          	sw	a4,536(s1)
    80004c10:	1ff7f793          	andi	a5,a5,511
    80004c14:	97a6                	add	a5,a5,s1
    80004c16:	0187c783          	lbu	a5,24(a5)
    80004c1a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1e:	4685                	li	a3,1
    80004c20:	fbf40613          	addi	a2,s0,-65
    80004c24:	85ca                	mv	a1,s2
    80004c26:	050a3503          	ld	a0,80(s4)
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	a42080e7          	jalr	-1470(ra) # 8000166c <copyout>
    80004c32:	01650763          	beq	a0,s6,80004c40 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c36:	2985                	addiw	s3,s3,1
    80004c38:	0905                	addi	s2,s2,1
    80004c3a:	fd3a91e3          	bne	s5,s3,80004bfc <piperead+0x70>
    80004c3e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c40:	21c48513          	addi	a0,s1,540
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	5ce080e7          	jalr	1486(ra) # 80002212 <wakeup>
  release(&pi->lock);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	03c080e7          	jalr	60(ra) # 80000c8a <release>
  return i;
}
    80004c56:	854e                	mv	a0,s3
    80004c58:	60a6                	ld	ra,72(sp)
    80004c5a:	6406                	ld	s0,64(sp)
    80004c5c:	74e2                	ld	s1,56(sp)
    80004c5e:	7942                	ld	s2,48(sp)
    80004c60:	79a2                	ld	s3,40(sp)
    80004c62:	7a02                	ld	s4,32(sp)
    80004c64:	6ae2                	ld	s5,24(sp)
    80004c66:	6b42                	ld	s6,16(sp)
    80004c68:	6161                	addi	sp,sp,80
    80004c6a:	8082                	ret
      release(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	01c080e7          	jalr	28(ra) # 80000c8a <release>
      return -1;
    80004c76:	59fd                	li	s3,-1
    80004c78:	bff9                	j	80004c56 <piperead+0xca>

0000000080004c7a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c7a:	1141                	addi	sp,sp,-16
    80004c7c:	e422                	sd	s0,8(sp)
    80004c7e:	0800                	addi	s0,sp,16
    80004c80:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c82:	8905                	andi	a0,a0,1
    80004c84:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c86:	8b89                	andi	a5,a5,2
    80004c88:	c399                	beqz	a5,80004c8e <flags2perm+0x14>
      perm |= PTE_W;
    80004c8a:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c8e:	6422                	ld	s0,8(sp)
    80004c90:	0141                	addi	sp,sp,16
    80004c92:	8082                	ret

0000000080004c94 <exec>:

int
exec(char *path, char **argv)
{
    80004c94:	de010113          	addi	sp,sp,-544
    80004c98:	20113c23          	sd	ra,536(sp)
    80004c9c:	20813823          	sd	s0,528(sp)
    80004ca0:	20913423          	sd	s1,520(sp)
    80004ca4:	21213023          	sd	s2,512(sp)
    80004ca8:	ffce                	sd	s3,504(sp)
    80004caa:	fbd2                	sd	s4,496(sp)
    80004cac:	f7d6                	sd	s5,488(sp)
    80004cae:	f3da                	sd	s6,480(sp)
    80004cb0:	efde                	sd	s7,472(sp)
    80004cb2:	ebe2                	sd	s8,464(sp)
    80004cb4:	e7e6                	sd	s9,456(sp)
    80004cb6:	e3ea                	sd	s10,448(sp)
    80004cb8:	ff6e                	sd	s11,440(sp)
    80004cba:	1400                	addi	s0,sp,544
    80004cbc:	892a                	mv	s2,a0
    80004cbe:	dea43423          	sd	a0,-536(s0)
    80004cc2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	d16080e7          	jalr	-746(ra) # 800019dc <myproc>
    80004cce:	84aa                	mv	s1,a0

  begin_op();
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	482080e7          	jalr	1154(ra) # 80004152 <begin_op>

  if((ip = namei(path)) == 0){
    80004cd8:	854a                	mv	a0,s2
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	258080e7          	jalr	600(ra) # 80003f32 <namei>
    80004ce2:	c93d                	beqz	a0,80004d58 <exec+0xc4>
    80004ce4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	aa0080e7          	jalr	-1376(ra) # 80003786 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cee:	04000713          	li	a4,64
    80004cf2:	4681                	li	a3,0
    80004cf4:	e5040613          	addi	a2,s0,-432
    80004cf8:	4581                	li	a1,0
    80004cfa:	8556                	mv	a0,s5
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	d3e080e7          	jalr	-706(ra) # 80003a3a <readi>
    80004d04:	04000793          	li	a5,64
    80004d08:	00f51a63          	bne	a0,a5,80004d1c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d0c:	e5042703          	lw	a4,-432(s0)
    80004d10:	464c47b7          	lui	a5,0x464c4
    80004d14:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d18:	04f70663          	beq	a4,a5,80004d64 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d1c:	8556                	mv	a0,s5
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	cca080e7          	jalr	-822(ra) # 800039e8 <iunlockput>
    end_op();
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	4aa080e7          	jalr	1194(ra) # 800041d0 <end_op>
  }
  return -1;
    80004d2e:	557d                	li	a0,-1
}
    80004d30:	21813083          	ld	ra,536(sp)
    80004d34:	21013403          	ld	s0,528(sp)
    80004d38:	20813483          	ld	s1,520(sp)
    80004d3c:	20013903          	ld	s2,512(sp)
    80004d40:	79fe                	ld	s3,504(sp)
    80004d42:	7a5e                	ld	s4,496(sp)
    80004d44:	7abe                	ld	s5,488(sp)
    80004d46:	7b1e                	ld	s6,480(sp)
    80004d48:	6bfe                	ld	s7,472(sp)
    80004d4a:	6c5e                	ld	s8,464(sp)
    80004d4c:	6cbe                	ld	s9,456(sp)
    80004d4e:	6d1e                	ld	s10,448(sp)
    80004d50:	7dfa                	ld	s11,440(sp)
    80004d52:	22010113          	addi	sp,sp,544
    80004d56:	8082                	ret
    end_op();
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	478080e7          	jalr	1144(ra) # 800041d0 <end_op>
    return -1;
    80004d60:	557d                	li	a0,-1
    80004d62:	b7f9                	j	80004d30 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	d3a080e7          	jalr	-710(ra) # 80001aa0 <proc_pagetable>
    80004d6e:	8b2a                	mv	s6,a0
    80004d70:	d555                	beqz	a0,80004d1c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d72:	e7042783          	lw	a5,-400(s0)
    80004d76:	e8845703          	lhu	a4,-376(s0)
    80004d7a:	c735                	beqz	a4,80004de6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d7c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d82:	6a05                	lui	s4,0x1
    80004d84:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d88:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d8c:	6d85                	lui	s11,0x1
    80004d8e:	7d7d                	lui	s10,0xfffff
    80004d90:	ac3d                	j	80004fce <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d92:	00004517          	auipc	a0,0x4
    80004d96:	93e50513          	addi	a0,a0,-1730 # 800086d0 <syscalls+0x280>
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	7a6080e7          	jalr	1958(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004da2:	874a                	mv	a4,s2
    80004da4:	009c86bb          	addw	a3,s9,s1
    80004da8:	4581                	li	a1,0
    80004daa:	8556                	mv	a0,s5
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	c8e080e7          	jalr	-882(ra) # 80003a3a <readi>
    80004db4:	2501                	sext.w	a0,a0
    80004db6:	1aa91963          	bne	s2,a0,80004f68 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004dba:	009d84bb          	addw	s1,s11,s1
    80004dbe:	013d09bb          	addw	s3,s10,s3
    80004dc2:	1f74f663          	bgeu	s1,s7,80004fae <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004dc6:	02049593          	slli	a1,s1,0x20
    80004dca:	9181                	srli	a1,a1,0x20
    80004dcc:	95e2                	add	a1,a1,s8
    80004dce:	855a                	mv	a0,s6
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	28c080e7          	jalr	652(ra) # 8000105c <walkaddr>
    80004dd8:	862a                	mv	a2,a0
    if(pa == 0)
    80004dda:	dd45                	beqz	a0,80004d92 <exec+0xfe>
      n = PGSIZE;
    80004ddc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dde:	fd49f2e3          	bgeu	s3,s4,80004da2 <exec+0x10e>
      n = sz - i;
    80004de2:	894e                	mv	s2,s3
    80004de4:	bf7d                	j	80004da2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004de6:	4901                	li	s2,0
  iunlockput(ip);
    80004de8:	8556                	mv	a0,s5
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	bfe080e7          	jalr	-1026(ra) # 800039e8 <iunlockput>
  end_op();
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	3de080e7          	jalr	990(ra) # 800041d0 <end_op>
  p = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	be2080e7          	jalr	-1054(ra) # 800019dc <myproc>
    80004e02:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e04:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e08:	6785                	lui	a5,0x1
    80004e0a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e0c:	97ca                	add	a5,a5,s2
    80004e0e:	777d                	lui	a4,0xfffff
    80004e10:	8ff9                	and	a5,a5,a4
    80004e12:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e16:	4691                	li	a3,4
    80004e18:	6609                	lui	a2,0x2
    80004e1a:	963e                	add	a2,a2,a5
    80004e1c:	85be                	mv	a1,a5
    80004e1e:	855a                	mv	a0,s6
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	5f0080e7          	jalr	1520(ra) # 80001410 <uvmalloc>
    80004e28:	8c2a                	mv	s8,a0
  ip = 0;
    80004e2a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e2c:	12050e63          	beqz	a0,80004f68 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e30:	75f9                	lui	a1,0xffffe
    80004e32:	95aa                	add	a1,a1,a0
    80004e34:	855a                	mv	a0,s6
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	804080e7          	jalr	-2044(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e3e:	7afd                	lui	s5,0xfffff
    80004e40:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e42:	df043783          	ld	a5,-528(s0)
    80004e46:	6388                	ld	a0,0(a5)
    80004e48:	c925                	beqz	a0,80004eb8 <exec+0x224>
    80004e4a:	e9040993          	addi	s3,s0,-368
    80004e4e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e52:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e54:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	ff8080e7          	jalr	-8(ra) # 80000e4e <strlen>
    80004e5e:	0015079b          	addiw	a5,a0,1
    80004e62:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e66:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e6a:	13596663          	bltu	s2,s5,80004f96 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e6e:	df043d83          	ld	s11,-528(s0)
    80004e72:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e76:	8552                	mv	a0,s4
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	fd6080e7          	jalr	-42(ra) # 80000e4e <strlen>
    80004e80:	0015069b          	addiw	a3,a0,1
    80004e84:	8652                	mv	a2,s4
    80004e86:	85ca                	mv	a1,s2
    80004e88:	855a                	mv	a0,s6
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	7e2080e7          	jalr	2018(ra) # 8000166c <copyout>
    80004e92:	10054663          	bltz	a0,80004f9e <exec+0x30a>
    ustack[argc] = sp;
    80004e96:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e9a:	0485                	addi	s1,s1,1
    80004e9c:	008d8793          	addi	a5,s11,8
    80004ea0:	def43823          	sd	a5,-528(s0)
    80004ea4:	008db503          	ld	a0,8(s11)
    80004ea8:	c911                	beqz	a0,80004ebc <exec+0x228>
    if(argc >= MAXARG)
    80004eaa:	09a1                	addi	s3,s3,8
    80004eac:	fb3c95e3          	bne	s9,s3,80004e56 <exec+0x1c2>
  sz = sz1;
    80004eb0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eb4:	4a81                	li	s5,0
    80004eb6:	a84d                	j	80004f68 <exec+0x2d4>
  sp = sz;
    80004eb8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eba:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ebc:	00349793          	slli	a5,s1,0x3
    80004ec0:	f9078793          	addi	a5,a5,-112
    80004ec4:	97a2                	add	a5,a5,s0
    80004ec6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eca:	00148693          	addi	a3,s1,1
    80004ece:	068e                	slli	a3,a3,0x3
    80004ed0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ed4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ed8:	01597663          	bgeu	s2,s5,80004ee4 <exec+0x250>
  sz = sz1;
    80004edc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ee0:	4a81                	li	s5,0
    80004ee2:	a059                	j	80004f68 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ee4:	e9040613          	addi	a2,s0,-368
    80004ee8:	85ca                	mv	a1,s2
    80004eea:	855a                	mv	a0,s6
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	780080e7          	jalr	1920(ra) # 8000166c <copyout>
    80004ef4:	0a054963          	bltz	a0,80004fa6 <exec+0x312>
  p->trapframe->a1 = sp;
    80004ef8:	058bb783          	ld	a5,88(s7)
    80004efc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f00:	de843783          	ld	a5,-536(s0)
    80004f04:	0007c703          	lbu	a4,0(a5)
    80004f08:	cf11                	beqz	a4,80004f24 <exec+0x290>
    80004f0a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f0c:	02f00693          	li	a3,47
    80004f10:	a039                	j	80004f1e <exec+0x28a>
      last = s+1;
    80004f12:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f16:	0785                	addi	a5,a5,1
    80004f18:	fff7c703          	lbu	a4,-1(a5)
    80004f1c:	c701                	beqz	a4,80004f24 <exec+0x290>
    if(*s == '/')
    80004f1e:	fed71ce3          	bne	a4,a3,80004f16 <exec+0x282>
    80004f22:	bfc5                	j	80004f12 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f24:	4641                	li	a2,16
    80004f26:	de843583          	ld	a1,-536(s0)
    80004f2a:	158b8513          	addi	a0,s7,344
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	eee080e7          	jalr	-274(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f36:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f3a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f3e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f42:	058bb783          	ld	a5,88(s7)
    80004f46:	e6843703          	ld	a4,-408(s0)
    80004f4a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f4c:	058bb783          	ld	a5,88(s7)
    80004f50:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f54:	85ea                	mv	a1,s10
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	be6080e7          	jalr	-1050(ra) # 80001b3c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f5e:	0004851b          	sext.w	a0,s1
    80004f62:	b3f9                	j	80004d30 <exec+0x9c>
    80004f64:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f68:	df843583          	ld	a1,-520(s0)
    80004f6c:	855a                	mv	a0,s6
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	bce080e7          	jalr	-1074(ra) # 80001b3c <proc_freepagetable>
  if(ip){
    80004f76:	da0a93e3          	bnez	s5,80004d1c <exec+0x88>
  return -1;
    80004f7a:	557d                	li	a0,-1
    80004f7c:	bb55                	j	80004d30 <exec+0x9c>
    80004f7e:	df243c23          	sd	s2,-520(s0)
    80004f82:	b7dd                	j	80004f68 <exec+0x2d4>
    80004f84:	df243c23          	sd	s2,-520(s0)
    80004f88:	b7c5                	j	80004f68 <exec+0x2d4>
    80004f8a:	df243c23          	sd	s2,-520(s0)
    80004f8e:	bfe9                	j	80004f68 <exec+0x2d4>
    80004f90:	df243c23          	sd	s2,-520(s0)
    80004f94:	bfd1                	j	80004f68 <exec+0x2d4>
  sz = sz1;
    80004f96:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9a:	4a81                	li	s5,0
    80004f9c:	b7f1                	j	80004f68 <exec+0x2d4>
  sz = sz1;
    80004f9e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fa2:	4a81                	li	s5,0
    80004fa4:	b7d1                	j	80004f68 <exec+0x2d4>
  sz = sz1;
    80004fa6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004faa:	4a81                	li	s5,0
    80004fac:	bf75                	j	80004f68 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fae:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb2:	e0843783          	ld	a5,-504(s0)
    80004fb6:	0017869b          	addiw	a3,a5,1
    80004fba:	e0d43423          	sd	a3,-504(s0)
    80004fbe:	e0043783          	ld	a5,-512(s0)
    80004fc2:	0387879b          	addiw	a5,a5,56
    80004fc6:	e8845703          	lhu	a4,-376(s0)
    80004fca:	e0e6dfe3          	bge	a3,a4,80004de8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fce:	2781                	sext.w	a5,a5
    80004fd0:	e0f43023          	sd	a5,-512(s0)
    80004fd4:	03800713          	li	a4,56
    80004fd8:	86be                	mv	a3,a5
    80004fda:	e1840613          	addi	a2,s0,-488
    80004fde:	4581                	li	a1,0
    80004fe0:	8556                	mv	a0,s5
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	a58080e7          	jalr	-1448(ra) # 80003a3a <readi>
    80004fea:	03800793          	li	a5,56
    80004fee:	f6f51be3          	bne	a0,a5,80004f64 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004ff2:	e1842783          	lw	a5,-488(s0)
    80004ff6:	4705                	li	a4,1
    80004ff8:	fae79de3          	bne	a5,a4,80004fb2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004ffc:	e4043483          	ld	s1,-448(s0)
    80005000:	e3843783          	ld	a5,-456(s0)
    80005004:	f6f4ede3          	bltu	s1,a5,80004f7e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005008:	e2843783          	ld	a5,-472(s0)
    8000500c:	94be                	add	s1,s1,a5
    8000500e:	f6f4ebe3          	bltu	s1,a5,80004f84 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005012:	de043703          	ld	a4,-544(s0)
    80005016:	8ff9                	and	a5,a5,a4
    80005018:	fbad                	bnez	a5,80004f8a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000501a:	e1c42503          	lw	a0,-484(s0)
    8000501e:	00000097          	auipc	ra,0x0
    80005022:	c5c080e7          	jalr	-932(ra) # 80004c7a <flags2perm>
    80005026:	86aa                	mv	a3,a0
    80005028:	8626                	mv	a2,s1
    8000502a:	85ca                	mv	a1,s2
    8000502c:	855a                	mv	a0,s6
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	3e2080e7          	jalr	994(ra) # 80001410 <uvmalloc>
    80005036:	dea43c23          	sd	a0,-520(s0)
    8000503a:	d939                	beqz	a0,80004f90 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000503c:	e2843c03          	ld	s8,-472(s0)
    80005040:	e2042c83          	lw	s9,-480(s0)
    80005044:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005048:	f60b83e3          	beqz	s7,80004fae <exec+0x31a>
    8000504c:	89de                	mv	s3,s7
    8000504e:	4481                	li	s1,0
    80005050:	bb9d                	j	80004dc6 <exec+0x132>

0000000080005052 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005052:	7179                	addi	sp,sp,-48
    80005054:	f406                	sd	ra,40(sp)
    80005056:	f022                	sd	s0,32(sp)
    80005058:	ec26                	sd	s1,24(sp)
    8000505a:	e84a                	sd	s2,16(sp)
    8000505c:	1800                	addi	s0,sp,48
    8000505e:	892e                	mv	s2,a1
    80005060:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005062:	fdc40593          	addi	a1,s0,-36
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	bb6080e7          	jalr	-1098(ra) # 80002c1c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000506e:	fdc42703          	lw	a4,-36(s0)
    80005072:	47bd                	li	a5,15
    80005074:	02e7eb63          	bltu	a5,a4,800050aa <argfd+0x58>
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	964080e7          	jalr	-1692(ra) # 800019dc <myproc>
    80005080:	fdc42703          	lw	a4,-36(s0)
    80005084:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc6ba>
    80005088:	078e                	slli	a5,a5,0x3
    8000508a:	953e                	add	a0,a0,a5
    8000508c:	611c                	ld	a5,0(a0)
    8000508e:	c385                	beqz	a5,800050ae <argfd+0x5c>
    return -1;
  if(pfd)
    80005090:	00090463          	beqz	s2,80005098 <argfd+0x46>
    *pfd = fd;
    80005094:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005098:	4501                	li	a0,0
  if(pf)
    8000509a:	c091                	beqz	s1,8000509e <argfd+0x4c>
    *pf = f;
    8000509c:	e09c                	sd	a5,0(s1)
}
    8000509e:	70a2                	ld	ra,40(sp)
    800050a0:	7402                	ld	s0,32(sp)
    800050a2:	64e2                	ld	s1,24(sp)
    800050a4:	6942                	ld	s2,16(sp)
    800050a6:	6145                	addi	sp,sp,48
    800050a8:	8082                	ret
    return -1;
    800050aa:	557d                	li	a0,-1
    800050ac:	bfcd                	j	8000509e <argfd+0x4c>
    800050ae:	557d                	li	a0,-1
    800050b0:	b7fd                	j	8000509e <argfd+0x4c>

00000000800050b2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050b2:	1101                	addi	sp,sp,-32
    800050b4:	ec06                	sd	ra,24(sp)
    800050b6:	e822                	sd	s0,16(sp)
    800050b8:	e426                	sd	s1,8(sp)
    800050ba:	1000                	addi	s0,sp,32
    800050bc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050be:	ffffd097          	auipc	ra,0xffffd
    800050c2:	91e080e7          	jalr	-1762(ra) # 800019dc <myproc>
    800050c6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c8:	0d050793          	addi	a5,a0,208
    800050cc:	4501                	li	a0,0
    800050ce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050d0:	6398                	ld	a4,0(a5)
    800050d2:	cb19                	beqz	a4,800050e8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050d4:	2505                	addiw	a0,a0,1
    800050d6:	07a1                	addi	a5,a5,8
    800050d8:	fed51ce3          	bne	a0,a3,800050d0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050dc:	557d                	li	a0,-1
}
    800050de:	60e2                	ld	ra,24(sp)
    800050e0:	6442                	ld	s0,16(sp)
    800050e2:	64a2                	ld	s1,8(sp)
    800050e4:	6105                	addi	sp,sp,32
    800050e6:	8082                	ret
      p->ofile[fd] = f;
    800050e8:	01a50793          	addi	a5,a0,26
    800050ec:	078e                	slli	a5,a5,0x3
    800050ee:	963e                	add	a2,a2,a5
    800050f0:	e204                	sd	s1,0(a2)
      return fd;
    800050f2:	b7f5                	j	800050de <fdalloc+0x2c>

00000000800050f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050f4:	715d                	addi	sp,sp,-80
    800050f6:	e486                	sd	ra,72(sp)
    800050f8:	e0a2                	sd	s0,64(sp)
    800050fa:	fc26                	sd	s1,56(sp)
    800050fc:	f84a                	sd	s2,48(sp)
    800050fe:	f44e                	sd	s3,40(sp)
    80005100:	f052                	sd	s4,32(sp)
    80005102:	ec56                	sd	s5,24(sp)
    80005104:	e85a                	sd	s6,16(sp)
    80005106:	0880                	addi	s0,sp,80
    80005108:	8b2e                	mv	s6,a1
    8000510a:	89b2                	mv	s3,a2
    8000510c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000510e:	fb040593          	addi	a1,s0,-80
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	e3e080e7          	jalr	-450(ra) # 80003f50 <nameiparent>
    8000511a:	84aa                	mv	s1,a0
    8000511c:	14050f63          	beqz	a0,8000527a <create+0x186>
    return 0;

  ilock(dp);
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	666080e7          	jalr	1638(ra) # 80003786 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005128:	4601                	li	a2,0
    8000512a:	fb040593          	addi	a1,s0,-80
    8000512e:	8526                	mv	a0,s1
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	b3a080e7          	jalr	-1222(ra) # 80003c6a <dirlookup>
    80005138:	8aaa                	mv	s5,a0
    8000513a:	c931                	beqz	a0,8000518e <create+0x9a>
    iunlockput(dp);
    8000513c:	8526                	mv	a0,s1
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	8aa080e7          	jalr	-1878(ra) # 800039e8 <iunlockput>
    ilock(ip);
    80005146:	8556                	mv	a0,s5
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	63e080e7          	jalr	1598(ra) # 80003786 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005150:	000b059b          	sext.w	a1,s6
    80005154:	4789                	li	a5,2
    80005156:	02f59563          	bne	a1,a5,80005180 <create+0x8c>
    8000515a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6e4>
    8000515e:	37f9                	addiw	a5,a5,-2
    80005160:	17c2                	slli	a5,a5,0x30
    80005162:	93c1                	srli	a5,a5,0x30
    80005164:	4705                	li	a4,1
    80005166:	00f76d63          	bltu	a4,a5,80005180 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000516a:	8556                	mv	a0,s5
    8000516c:	60a6                	ld	ra,72(sp)
    8000516e:	6406                	ld	s0,64(sp)
    80005170:	74e2                	ld	s1,56(sp)
    80005172:	7942                	ld	s2,48(sp)
    80005174:	79a2                	ld	s3,40(sp)
    80005176:	7a02                	ld	s4,32(sp)
    80005178:	6ae2                	ld	s5,24(sp)
    8000517a:	6b42                	ld	s6,16(sp)
    8000517c:	6161                	addi	sp,sp,80
    8000517e:	8082                	ret
    iunlockput(ip);
    80005180:	8556                	mv	a0,s5
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	866080e7          	jalr	-1946(ra) # 800039e8 <iunlockput>
    return 0;
    8000518a:	4a81                	li	s5,0
    8000518c:	bff9                	j	8000516a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000518e:	85da                	mv	a1,s6
    80005190:	4088                	lw	a0,0(s1)
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	456080e7          	jalr	1110(ra) # 800035e8 <ialloc>
    8000519a:	8a2a                	mv	s4,a0
    8000519c:	c539                	beqz	a0,800051ea <create+0xf6>
  ilock(ip);
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	5e8080e7          	jalr	1512(ra) # 80003786 <ilock>
  ip->major = major;
    800051a6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051aa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051ae:	4905                	li	s2,1
    800051b0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051b4:	8552                	mv	a0,s4
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	504080e7          	jalr	1284(ra) # 800036ba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051be:	000b059b          	sext.w	a1,s6
    800051c2:	03258b63          	beq	a1,s2,800051f8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051c6:	004a2603          	lw	a2,4(s4)
    800051ca:	fb040593          	addi	a1,s0,-80
    800051ce:	8526                	mv	a0,s1
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	cb0080e7          	jalr	-848(ra) # 80003e80 <dirlink>
    800051d8:	06054f63          	bltz	a0,80005256 <create+0x162>
  iunlockput(dp);
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	80a080e7          	jalr	-2038(ra) # 800039e8 <iunlockput>
  return ip;
    800051e6:	8ad2                	mv	s5,s4
    800051e8:	b749                	j	8000516a <create+0x76>
    iunlockput(dp);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffe097          	auipc	ra,0xffffe
    800051f0:	7fc080e7          	jalr	2044(ra) # 800039e8 <iunlockput>
    return 0;
    800051f4:	8ad2                	mv	s5,s4
    800051f6:	bf95                	j	8000516a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f8:	004a2603          	lw	a2,4(s4)
    800051fc:	00003597          	auipc	a1,0x3
    80005200:	4f458593          	addi	a1,a1,1268 # 800086f0 <syscalls+0x2a0>
    80005204:	8552                	mv	a0,s4
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	c7a080e7          	jalr	-902(ra) # 80003e80 <dirlink>
    8000520e:	04054463          	bltz	a0,80005256 <create+0x162>
    80005212:	40d0                	lw	a2,4(s1)
    80005214:	00003597          	auipc	a1,0x3
    80005218:	4e458593          	addi	a1,a1,1252 # 800086f8 <syscalls+0x2a8>
    8000521c:	8552                	mv	a0,s4
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	c62080e7          	jalr	-926(ra) # 80003e80 <dirlink>
    80005226:	02054863          	bltz	a0,80005256 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000522a:	004a2603          	lw	a2,4(s4)
    8000522e:	fb040593          	addi	a1,s0,-80
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c4c080e7          	jalr	-948(ra) # 80003e80 <dirlink>
    8000523c:	00054d63          	bltz	a0,80005256 <create+0x162>
    dp->nlink++;  // for ".."
    80005240:	04a4d783          	lhu	a5,74(s1)
    80005244:	2785                	addiw	a5,a5,1
    80005246:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000524a:	8526                	mv	a0,s1
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	46e080e7          	jalr	1134(ra) # 800036ba <iupdate>
    80005254:	b761                	j	800051dc <create+0xe8>
  ip->nlink = 0;
    80005256:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000525a:	8552                	mv	a0,s4
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	45e080e7          	jalr	1118(ra) # 800036ba <iupdate>
  iunlockput(ip);
    80005264:	8552                	mv	a0,s4
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	782080e7          	jalr	1922(ra) # 800039e8 <iunlockput>
  iunlockput(dp);
    8000526e:	8526                	mv	a0,s1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	778080e7          	jalr	1912(ra) # 800039e8 <iunlockput>
  return 0;
    80005278:	bdcd                	j	8000516a <create+0x76>
    return 0;
    8000527a:	8aaa                	mv	s5,a0
    8000527c:	b5fd                	j	8000516a <create+0x76>

000000008000527e <sys_dup>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	ec26                	sd	s1,24(sp)
    80005286:	e84a                	sd	s2,16(sp)
    80005288:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000528a:	fd840613          	addi	a2,s0,-40
    8000528e:	4581                	li	a1,0
    80005290:	4501                	li	a0,0
    80005292:	00000097          	auipc	ra,0x0
    80005296:	dc0080e7          	jalr	-576(ra) # 80005052 <argfd>
    return -1;
    8000529a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000529c:	02054363          	bltz	a0,800052c2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052a0:	fd843903          	ld	s2,-40(s0)
    800052a4:	854a                	mv	a0,s2
    800052a6:	00000097          	auipc	ra,0x0
    800052aa:	e0c080e7          	jalr	-500(ra) # 800050b2 <fdalloc>
    800052ae:	84aa                	mv	s1,a0
    return -1;
    800052b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052b2:	00054863          	bltz	a0,800052c2 <sys_dup+0x44>
  filedup(f);
    800052b6:	854a                	mv	a0,s2
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	310080e7          	jalr	784(ra) # 800045c8 <filedup>
  return fd;
    800052c0:	87a6                	mv	a5,s1
}
    800052c2:	853e                	mv	a0,a5
    800052c4:	70a2                	ld	ra,40(sp)
    800052c6:	7402                	ld	s0,32(sp)
    800052c8:	64e2                	ld	s1,24(sp)
    800052ca:	6942                	ld	s2,16(sp)
    800052cc:	6145                	addi	sp,sp,48
    800052ce:	8082                	ret

00000000800052d0 <sys_read>:
{
    800052d0:	7179                	addi	sp,sp,-48
    800052d2:	f406                	sd	ra,40(sp)
    800052d4:	f022                	sd	s0,32(sp)
    800052d6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d8:	fd840593          	addi	a1,s0,-40
    800052dc:	4505                	li	a0,1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	95e080e7          	jalr	-1698(ra) # 80002c3c <argaddr>
  argint(2, &n);
    800052e6:	fe440593          	addi	a1,s0,-28
    800052ea:	4509                	li	a0,2
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	930080e7          	jalr	-1744(ra) # 80002c1c <argint>
  if(argfd(0, 0, &f) < 0)
    800052f4:	fe840613          	addi	a2,s0,-24
    800052f8:	4581                	li	a1,0
    800052fa:	4501                	li	a0,0
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	d56080e7          	jalr	-682(ra) # 80005052 <argfd>
    80005304:	87aa                	mv	a5,a0
    return -1;
    80005306:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005308:	0007cc63          	bltz	a5,80005320 <sys_read+0x50>
  return fileread(f, p, n);
    8000530c:	fe442603          	lw	a2,-28(s0)
    80005310:	fd843583          	ld	a1,-40(s0)
    80005314:	fe843503          	ld	a0,-24(s0)
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	43c080e7          	jalr	1084(ra) # 80004754 <fileread>
}
    80005320:	70a2                	ld	ra,40(sp)
    80005322:	7402                	ld	s0,32(sp)
    80005324:	6145                	addi	sp,sp,48
    80005326:	8082                	ret

0000000080005328 <sys_write>:
{
    80005328:	7179                	addi	sp,sp,-48
    8000532a:	f406                	sd	ra,40(sp)
    8000532c:	f022                	sd	s0,32(sp)
    8000532e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005330:	fd840593          	addi	a1,s0,-40
    80005334:	4505                	li	a0,1
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	906080e7          	jalr	-1786(ra) # 80002c3c <argaddr>
  argint(2, &n);
    8000533e:	fe440593          	addi	a1,s0,-28
    80005342:	4509                	li	a0,2
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	8d8080e7          	jalr	-1832(ra) # 80002c1c <argint>
  if(argfd(0, 0, &f) < 0)
    8000534c:	fe840613          	addi	a2,s0,-24
    80005350:	4581                	li	a1,0
    80005352:	4501                	li	a0,0
    80005354:	00000097          	auipc	ra,0x0
    80005358:	cfe080e7          	jalr	-770(ra) # 80005052 <argfd>
    8000535c:	87aa                	mv	a5,a0
    return -1;
    8000535e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005360:	0007cc63          	bltz	a5,80005378 <sys_write+0x50>
  return filewrite(f, p, n);
    80005364:	fe442603          	lw	a2,-28(s0)
    80005368:	fd843583          	ld	a1,-40(s0)
    8000536c:	fe843503          	ld	a0,-24(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	4a6080e7          	jalr	1190(ra) # 80004816 <filewrite>
}
    80005378:	70a2                	ld	ra,40(sp)
    8000537a:	7402                	ld	s0,32(sp)
    8000537c:	6145                	addi	sp,sp,48
    8000537e:	8082                	ret

0000000080005380 <sys_close>:
{
    80005380:	1101                	addi	sp,sp,-32
    80005382:	ec06                	sd	ra,24(sp)
    80005384:	e822                	sd	s0,16(sp)
    80005386:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005388:	fe040613          	addi	a2,s0,-32
    8000538c:	fec40593          	addi	a1,s0,-20
    80005390:	4501                	li	a0,0
    80005392:	00000097          	auipc	ra,0x0
    80005396:	cc0080e7          	jalr	-832(ra) # 80005052 <argfd>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000539c:	02054463          	bltz	a0,800053c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	63c080e7          	jalr	1596(ra) # 800019dc <myproc>
    800053a8:	fec42783          	lw	a5,-20(s0)
    800053ac:	07e9                	addi	a5,a5,26
    800053ae:	078e                	slli	a5,a5,0x3
    800053b0:	953e                	add	a0,a0,a5
    800053b2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053b6:	fe043503          	ld	a0,-32(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	260080e7          	jalr	608(ra) # 8000461a <fileclose>
  return 0;
    800053c2:	4781                	li	a5,0
}
    800053c4:	853e                	mv	a0,a5
    800053c6:	60e2                	ld	ra,24(sp)
    800053c8:	6442                	ld	s0,16(sp)
    800053ca:	6105                	addi	sp,sp,32
    800053cc:	8082                	ret

00000000800053ce <sys_fstat>:
{
    800053ce:	1101                	addi	sp,sp,-32
    800053d0:	ec06                	sd	ra,24(sp)
    800053d2:	e822                	sd	s0,16(sp)
    800053d4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053d6:	fe040593          	addi	a1,s0,-32
    800053da:	4505                	li	a0,1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	860080e7          	jalr	-1952(ra) # 80002c3c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053e4:	fe840613          	addi	a2,s0,-24
    800053e8:	4581                	li	a1,0
    800053ea:	4501                	li	a0,0
    800053ec:	00000097          	auipc	ra,0x0
    800053f0:	c66080e7          	jalr	-922(ra) # 80005052 <argfd>
    800053f4:	87aa                	mv	a5,a0
    return -1;
    800053f6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f8:	0007ca63          	bltz	a5,8000540c <sys_fstat+0x3e>
  return filestat(f, st);
    800053fc:	fe043583          	ld	a1,-32(s0)
    80005400:	fe843503          	ld	a0,-24(s0)
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	2de080e7          	jalr	734(ra) # 800046e2 <filestat>
}
    8000540c:	60e2                	ld	ra,24(sp)
    8000540e:	6442                	ld	s0,16(sp)
    80005410:	6105                	addi	sp,sp,32
    80005412:	8082                	ret

0000000080005414 <sys_link>:
{
    80005414:	7169                	addi	sp,sp,-304
    80005416:	f606                	sd	ra,296(sp)
    80005418:	f222                	sd	s0,288(sp)
    8000541a:	ee26                	sd	s1,280(sp)
    8000541c:	ea4a                	sd	s2,272(sp)
    8000541e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005420:	08000613          	li	a2,128
    80005424:	ed040593          	addi	a1,s0,-304
    80005428:	4501                	li	a0,0
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	832080e7          	jalr	-1998(ra) # 80002c5c <argstr>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005434:	10054e63          	bltz	a0,80005550 <sys_link+0x13c>
    80005438:	08000613          	li	a2,128
    8000543c:	f5040593          	addi	a1,s0,-176
    80005440:	4505                	li	a0,1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	81a080e7          	jalr	-2022(ra) # 80002c5c <argstr>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000544c:	10054263          	bltz	a0,80005550 <sys_link+0x13c>
  begin_op();
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	d02080e7          	jalr	-766(ra) # 80004152 <begin_op>
  if((ip = namei(old)) == 0){
    80005458:	ed040513          	addi	a0,s0,-304
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	ad6080e7          	jalr	-1322(ra) # 80003f32 <namei>
    80005464:	84aa                	mv	s1,a0
    80005466:	c551                	beqz	a0,800054f2 <sys_link+0xde>
  ilock(ip);
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	31e080e7          	jalr	798(ra) # 80003786 <ilock>
  if(ip->type == T_DIR){
    80005470:	04449703          	lh	a4,68(s1)
    80005474:	4785                	li	a5,1
    80005476:	08f70463          	beq	a4,a5,800054fe <sys_link+0xea>
  ip->nlink++;
    8000547a:	04a4d783          	lhu	a5,74(s1)
    8000547e:	2785                	addiw	a5,a5,1
    80005480:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	234080e7          	jalr	564(ra) # 800036ba <iupdate>
  iunlock(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	3b8080e7          	jalr	952(ra) # 80003848 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005498:	fd040593          	addi	a1,s0,-48
    8000549c:	f5040513          	addi	a0,s0,-176
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	ab0080e7          	jalr	-1360(ra) # 80003f50 <nameiparent>
    800054a8:	892a                	mv	s2,a0
    800054aa:	c935                	beqz	a0,8000551e <sys_link+0x10a>
  ilock(dp);
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	2da080e7          	jalr	730(ra) # 80003786 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054b4:	00092703          	lw	a4,0(s2)
    800054b8:	409c                	lw	a5,0(s1)
    800054ba:	04f71d63          	bne	a4,a5,80005514 <sys_link+0x100>
    800054be:	40d0                	lw	a2,4(s1)
    800054c0:	fd040593          	addi	a1,s0,-48
    800054c4:	854a                	mv	a0,s2
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	9ba080e7          	jalr	-1606(ra) # 80003e80 <dirlink>
    800054ce:	04054363          	bltz	a0,80005514 <sys_link+0x100>
  iunlockput(dp);
    800054d2:	854a                	mv	a0,s2
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	514080e7          	jalr	1300(ra) # 800039e8 <iunlockput>
  iput(ip);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	462080e7          	jalr	1122(ra) # 80003940 <iput>
  end_op();
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	cea080e7          	jalr	-790(ra) # 800041d0 <end_op>
  return 0;
    800054ee:	4781                	li	a5,0
    800054f0:	a085                	j	80005550 <sys_link+0x13c>
    end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cde080e7          	jalr	-802(ra) # 800041d0 <end_op>
    return -1;
    800054fa:	57fd                	li	a5,-1
    800054fc:	a891                	j	80005550 <sys_link+0x13c>
    iunlockput(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	4e8080e7          	jalr	1256(ra) # 800039e8 <iunlockput>
    end_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	cc8080e7          	jalr	-824(ra) # 800041d0 <end_op>
    return -1;
    80005510:	57fd                	li	a5,-1
    80005512:	a83d                	j	80005550 <sys_link+0x13c>
    iunlockput(dp);
    80005514:	854a                	mv	a0,s2
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	4d2080e7          	jalr	1234(ra) # 800039e8 <iunlockput>
  ilock(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	266080e7          	jalr	614(ra) # 80003786 <ilock>
  ip->nlink--;
    80005528:	04a4d783          	lhu	a5,74(s1)
    8000552c:	37fd                	addiw	a5,a5,-1
    8000552e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	186080e7          	jalr	390(ra) # 800036ba <iupdate>
  iunlockput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	4aa080e7          	jalr	1194(ra) # 800039e8 <iunlockput>
  end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	c8a080e7          	jalr	-886(ra) # 800041d0 <end_op>
  return -1;
    8000554e:	57fd                	li	a5,-1
}
    80005550:	853e                	mv	a0,a5
    80005552:	70b2                	ld	ra,296(sp)
    80005554:	7412                	ld	s0,288(sp)
    80005556:	64f2                	ld	s1,280(sp)
    80005558:	6952                	ld	s2,272(sp)
    8000555a:	6155                	addi	sp,sp,304
    8000555c:	8082                	ret

000000008000555e <sys_unlink>:
{
    8000555e:	7151                	addi	sp,sp,-240
    80005560:	f586                	sd	ra,232(sp)
    80005562:	f1a2                	sd	s0,224(sp)
    80005564:	eda6                	sd	s1,216(sp)
    80005566:	e9ca                	sd	s2,208(sp)
    80005568:	e5ce                	sd	s3,200(sp)
    8000556a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000556c:	08000613          	li	a2,128
    80005570:	f3040593          	addi	a1,s0,-208
    80005574:	4501                	li	a0,0
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	6e6080e7          	jalr	1766(ra) # 80002c5c <argstr>
    8000557e:	18054163          	bltz	a0,80005700 <sys_unlink+0x1a2>
  begin_op();
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	bd0080e7          	jalr	-1072(ra) # 80004152 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000558a:	fb040593          	addi	a1,s0,-80
    8000558e:	f3040513          	addi	a0,s0,-208
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	9be080e7          	jalr	-1602(ra) # 80003f50 <nameiparent>
    8000559a:	84aa                	mv	s1,a0
    8000559c:	c979                	beqz	a0,80005672 <sys_unlink+0x114>
  ilock(dp);
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	1e8080e7          	jalr	488(ra) # 80003786 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055a6:	00003597          	auipc	a1,0x3
    800055aa:	14a58593          	addi	a1,a1,330 # 800086f0 <syscalls+0x2a0>
    800055ae:	fb040513          	addi	a0,s0,-80
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	69e080e7          	jalr	1694(ra) # 80003c50 <namecmp>
    800055ba:	14050a63          	beqz	a0,8000570e <sys_unlink+0x1b0>
    800055be:	00003597          	auipc	a1,0x3
    800055c2:	13a58593          	addi	a1,a1,314 # 800086f8 <syscalls+0x2a8>
    800055c6:	fb040513          	addi	a0,s0,-80
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	686080e7          	jalr	1670(ra) # 80003c50 <namecmp>
    800055d2:	12050e63          	beqz	a0,8000570e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055d6:	f2c40613          	addi	a2,s0,-212
    800055da:	fb040593          	addi	a1,s0,-80
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	68a080e7          	jalr	1674(ra) # 80003c6a <dirlookup>
    800055e8:	892a                	mv	s2,a0
    800055ea:	12050263          	beqz	a0,8000570e <sys_unlink+0x1b0>
  ilock(ip);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	198080e7          	jalr	408(ra) # 80003786 <ilock>
  if(ip->nlink < 1)
    800055f6:	04a91783          	lh	a5,74(s2)
    800055fa:	08f05263          	blez	a5,8000567e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055fe:	04491703          	lh	a4,68(s2)
    80005602:	4785                	li	a5,1
    80005604:	08f70563          	beq	a4,a5,8000568e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005608:	4641                	li	a2,16
    8000560a:	4581                	li	a1,0
    8000560c:	fc040513          	addi	a0,s0,-64
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	6c2080e7          	jalr	1730(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005618:	4741                	li	a4,16
    8000561a:	f2c42683          	lw	a3,-212(s0)
    8000561e:	fc040613          	addi	a2,s0,-64
    80005622:	4581                	li	a1,0
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	50c080e7          	jalr	1292(ra) # 80003b32 <writei>
    8000562e:	47c1                	li	a5,16
    80005630:	0af51563          	bne	a0,a5,800056da <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005634:	04491703          	lh	a4,68(s2)
    80005638:	4785                	li	a5,1
    8000563a:	0af70863          	beq	a4,a5,800056ea <sys_unlink+0x18c>
  iunlockput(dp);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	3a8080e7          	jalr	936(ra) # 800039e8 <iunlockput>
  ip->nlink--;
    80005648:	04a95783          	lhu	a5,74(s2)
    8000564c:	37fd                	addiw	a5,a5,-1
    8000564e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005652:	854a                	mv	a0,s2
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	066080e7          	jalr	102(ra) # 800036ba <iupdate>
  iunlockput(ip);
    8000565c:	854a                	mv	a0,s2
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	38a080e7          	jalr	906(ra) # 800039e8 <iunlockput>
  end_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	b6a080e7          	jalr	-1174(ra) # 800041d0 <end_op>
  return 0;
    8000566e:	4501                	li	a0,0
    80005670:	a84d                	j	80005722 <sys_unlink+0x1c4>
    end_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	b5e080e7          	jalr	-1186(ra) # 800041d0 <end_op>
    return -1;
    8000567a:	557d                	li	a0,-1
    8000567c:	a05d                	j	80005722 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000567e:	00003517          	auipc	a0,0x3
    80005682:	08250513          	addi	a0,a0,130 # 80008700 <syscalls+0x2b0>
    80005686:	ffffb097          	auipc	ra,0xffffb
    8000568a:	eba080e7          	jalr	-326(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568e:	04c92703          	lw	a4,76(s2)
    80005692:	02000793          	li	a5,32
    80005696:	f6e7f9e3          	bgeu	a5,a4,80005608 <sys_unlink+0xaa>
    8000569a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569e:	4741                	li	a4,16
    800056a0:	86ce                	mv	a3,s3
    800056a2:	f1840613          	addi	a2,s0,-232
    800056a6:	4581                	li	a1,0
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	390080e7          	jalr	912(ra) # 80003a3a <readi>
    800056b2:	47c1                	li	a5,16
    800056b4:	00f51b63          	bne	a0,a5,800056ca <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b8:	f1845783          	lhu	a5,-232(s0)
    800056bc:	e7a1                	bnez	a5,80005704 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056be:	29c1                	addiw	s3,s3,16
    800056c0:	04c92783          	lw	a5,76(s2)
    800056c4:	fcf9ede3          	bltu	s3,a5,8000569e <sys_unlink+0x140>
    800056c8:	b781                	j	80005608 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ca:	00003517          	auipc	a0,0x3
    800056ce:	04e50513          	addi	a0,a0,78 # 80008718 <syscalls+0x2c8>
    800056d2:	ffffb097          	auipc	ra,0xffffb
    800056d6:	e6e080e7          	jalr	-402(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056da:	00003517          	auipc	a0,0x3
    800056de:	05650513          	addi	a0,a0,86 # 80008730 <syscalls+0x2e0>
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	e5e080e7          	jalr	-418(ra) # 80000540 <panic>
    dp->nlink--;
    800056ea:	04a4d783          	lhu	a5,74(s1)
    800056ee:	37fd                	addiw	a5,a5,-1
    800056f0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	fc4080e7          	jalr	-60(ra) # 800036ba <iupdate>
    800056fe:	b781                	j	8000563e <sys_unlink+0xe0>
    return -1;
    80005700:	557d                	li	a0,-1
    80005702:	a005                	j	80005722 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005704:	854a                	mv	a0,s2
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	2e2080e7          	jalr	738(ra) # 800039e8 <iunlockput>
  iunlockput(dp);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	2d8080e7          	jalr	728(ra) # 800039e8 <iunlockput>
  end_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	ab8080e7          	jalr	-1352(ra) # 800041d0 <end_op>
  return -1;
    80005720:	557d                	li	a0,-1
}
    80005722:	70ae                	ld	ra,232(sp)
    80005724:	740e                	ld	s0,224(sp)
    80005726:	64ee                	ld	s1,216(sp)
    80005728:	694e                	ld	s2,208(sp)
    8000572a:	69ae                	ld	s3,200(sp)
    8000572c:	616d                	addi	sp,sp,240
    8000572e:	8082                	ret

0000000080005730 <sys_open>:

uint64
sys_open(void)
{
    80005730:	7131                	addi	sp,sp,-192
    80005732:	fd06                	sd	ra,184(sp)
    80005734:	f922                	sd	s0,176(sp)
    80005736:	f526                	sd	s1,168(sp)
    80005738:	f14a                	sd	s2,160(sp)
    8000573a:	ed4e                	sd	s3,152(sp)
    8000573c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000573e:	f4c40593          	addi	a1,s0,-180
    80005742:	4505                	li	a0,1
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	4d8080e7          	jalr	1240(ra) # 80002c1c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000574c:	08000613          	li	a2,128
    80005750:	f5040593          	addi	a1,s0,-176
    80005754:	4501                	li	a0,0
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	506080e7          	jalr	1286(ra) # 80002c5c <argstr>
    8000575e:	87aa                	mv	a5,a0
    return -1;
    80005760:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005762:	0a07c963          	bltz	a5,80005814 <sys_open+0xe4>

  begin_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	9ec080e7          	jalr	-1556(ra) # 80004152 <begin_op>

  if(omode & O_CREATE){
    8000576e:	f4c42783          	lw	a5,-180(s0)
    80005772:	2007f793          	andi	a5,a5,512
    80005776:	cfc5                	beqz	a5,8000582e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005778:	4681                	li	a3,0
    8000577a:	4601                	li	a2,0
    8000577c:	4589                	li	a1,2
    8000577e:	f5040513          	addi	a0,s0,-176
    80005782:	00000097          	auipc	ra,0x0
    80005786:	972080e7          	jalr	-1678(ra) # 800050f4 <create>
    8000578a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000578c:	c959                	beqz	a0,80005822 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000578e:	04449703          	lh	a4,68(s1)
    80005792:	478d                	li	a5,3
    80005794:	00f71763          	bne	a4,a5,800057a2 <sys_open+0x72>
    80005798:	0464d703          	lhu	a4,70(s1)
    8000579c:	47a5                	li	a5,9
    8000579e:	0ce7ed63          	bltu	a5,a4,80005878 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	dbc080e7          	jalr	-580(ra) # 8000455e <filealloc>
    800057aa:	89aa                	mv	s3,a0
    800057ac:	10050363          	beqz	a0,800058b2 <sys_open+0x182>
    800057b0:	00000097          	auipc	ra,0x0
    800057b4:	902080e7          	jalr	-1790(ra) # 800050b2 <fdalloc>
    800057b8:	892a                	mv	s2,a0
    800057ba:	0e054763          	bltz	a0,800058a8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057be:	04449703          	lh	a4,68(s1)
    800057c2:	478d                	li	a5,3
    800057c4:	0cf70563          	beq	a4,a5,8000588e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c8:	4789                	li	a5,2
    800057ca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057d2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d6:	f4c42783          	lw	a5,-180(s0)
    800057da:	0017c713          	xori	a4,a5,1
    800057de:	8b05                	andi	a4,a4,1
    800057e0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057e4:	0037f713          	andi	a4,a5,3
    800057e8:	00e03733          	snez	a4,a4
    800057ec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057f0:	4007f793          	andi	a5,a5,1024
    800057f4:	c791                	beqz	a5,80005800 <sys_open+0xd0>
    800057f6:	04449703          	lh	a4,68(s1)
    800057fa:	4789                	li	a5,2
    800057fc:	0af70063          	beq	a4,a5,8000589c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	046080e7          	jalr	70(ra) # 80003848 <iunlock>
  end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	9c6080e7          	jalr	-1594(ra) # 800041d0 <end_op>

  return fd;
    80005812:	854a                	mv	a0,s2
}
    80005814:	70ea                	ld	ra,184(sp)
    80005816:	744a                	ld	s0,176(sp)
    80005818:	74aa                	ld	s1,168(sp)
    8000581a:	790a                	ld	s2,160(sp)
    8000581c:	69ea                	ld	s3,152(sp)
    8000581e:	6129                	addi	sp,sp,192
    80005820:	8082                	ret
      end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	9ae080e7          	jalr	-1618(ra) # 800041d0 <end_op>
      return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	b7e5                	j	80005814 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000582e:	f5040513          	addi	a0,s0,-176
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	700080e7          	jalr	1792(ra) # 80003f32 <namei>
    8000583a:	84aa                	mv	s1,a0
    8000583c:	c905                	beqz	a0,8000586c <sys_open+0x13c>
    ilock(ip);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	f48080e7          	jalr	-184(ra) # 80003786 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005846:	04449703          	lh	a4,68(s1)
    8000584a:	4785                	li	a5,1
    8000584c:	f4f711e3          	bne	a4,a5,8000578e <sys_open+0x5e>
    80005850:	f4c42783          	lw	a5,-180(s0)
    80005854:	d7b9                	beqz	a5,800057a2 <sys_open+0x72>
      iunlockput(ip);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	190080e7          	jalr	400(ra) # 800039e8 <iunlockput>
      end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	970080e7          	jalr	-1680(ra) # 800041d0 <end_op>
      return -1;
    80005868:	557d                	li	a0,-1
    8000586a:	b76d                	j	80005814 <sys_open+0xe4>
      end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	964080e7          	jalr	-1692(ra) # 800041d0 <end_op>
      return -1;
    80005874:	557d                	li	a0,-1
    80005876:	bf79                	j	80005814 <sys_open+0xe4>
    iunlockput(ip);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	16e080e7          	jalr	366(ra) # 800039e8 <iunlockput>
    end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	94e080e7          	jalr	-1714(ra) # 800041d0 <end_op>
    return -1;
    8000588a:	557d                	li	a0,-1
    8000588c:	b761                	j	80005814 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000588e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005892:	04649783          	lh	a5,70(s1)
    80005896:	02f99223          	sh	a5,36(s3)
    8000589a:	bf25                	j	800057d2 <sys_open+0xa2>
    itrunc(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	ff6080e7          	jalr	-10(ra) # 80003894 <itrunc>
    800058a6:	bfa9                	j	80005800 <sys_open+0xd0>
      fileclose(f);
    800058a8:	854e                	mv	a0,s3
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	d70080e7          	jalr	-656(ra) # 8000461a <fileclose>
    iunlockput(ip);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	134080e7          	jalr	308(ra) # 800039e8 <iunlockput>
    end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	914080e7          	jalr	-1772(ra) # 800041d0 <end_op>
    return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	b7b9                	j	80005814 <sys_open+0xe4>

00000000800058c8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c8:	7175                	addi	sp,sp,-144
    800058ca:	e506                	sd	ra,136(sp)
    800058cc:	e122                	sd	s0,128(sp)
    800058ce:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	882080e7          	jalr	-1918(ra) # 80004152 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d8:	08000613          	li	a2,128
    800058dc:	f7040593          	addi	a1,s0,-144
    800058e0:	4501                	li	a0,0
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	37a080e7          	jalr	890(ra) # 80002c5c <argstr>
    800058ea:	02054963          	bltz	a0,8000591c <sys_mkdir+0x54>
    800058ee:	4681                	li	a3,0
    800058f0:	4601                	li	a2,0
    800058f2:	4585                	li	a1,1
    800058f4:	f7040513          	addi	a0,s0,-144
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	7fc080e7          	jalr	2044(ra) # 800050f4 <create>
    80005900:	cd11                	beqz	a0,8000591c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	0e6080e7          	jalr	230(ra) # 800039e8 <iunlockput>
  end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	8c6080e7          	jalr	-1850(ra) # 800041d0 <end_op>
  return 0;
    80005912:	4501                	li	a0,0
}
    80005914:	60aa                	ld	ra,136(sp)
    80005916:	640a                	ld	s0,128(sp)
    80005918:	6149                	addi	sp,sp,144
    8000591a:	8082                	ret
    end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	8b4080e7          	jalr	-1868(ra) # 800041d0 <end_op>
    return -1;
    80005924:	557d                	li	a0,-1
    80005926:	b7fd                	j	80005914 <sys_mkdir+0x4c>

0000000080005928 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005928:	7135                	addi	sp,sp,-160
    8000592a:	ed06                	sd	ra,152(sp)
    8000592c:	e922                	sd	s0,144(sp)
    8000592e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	822080e7          	jalr	-2014(ra) # 80004152 <begin_op>
  argint(1, &major);
    80005938:	f6c40593          	addi	a1,s0,-148
    8000593c:	4505                	li	a0,1
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	2de080e7          	jalr	734(ra) # 80002c1c <argint>
  argint(2, &minor);
    80005946:	f6840593          	addi	a1,s0,-152
    8000594a:	4509                	li	a0,2
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	2d0080e7          	jalr	720(ra) # 80002c1c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005954:	08000613          	li	a2,128
    80005958:	f7040593          	addi	a1,s0,-144
    8000595c:	4501                	li	a0,0
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	2fe080e7          	jalr	766(ra) # 80002c5c <argstr>
    80005966:	02054b63          	bltz	a0,8000599c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000596a:	f6841683          	lh	a3,-152(s0)
    8000596e:	f6c41603          	lh	a2,-148(s0)
    80005972:	458d                	li	a1,3
    80005974:	f7040513          	addi	a0,s0,-144
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	77c080e7          	jalr	1916(ra) # 800050f4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005980:	cd11                	beqz	a0,8000599c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	066080e7          	jalr	102(ra) # 800039e8 <iunlockput>
  end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	846080e7          	jalr	-1978(ra) # 800041d0 <end_op>
  return 0;
    80005992:	4501                	li	a0,0
}
    80005994:	60ea                	ld	ra,152(sp)
    80005996:	644a                	ld	s0,144(sp)
    80005998:	610d                	addi	sp,sp,160
    8000599a:	8082                	ret
    end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	834080e7          	jalr	-1996(ra) # 800041d0 <end_op>
    return -1;
    800059a4:	557d                	li	a0,-1
    800059a6:	b7fd                	j	80005994 <sys_mknod+0x6c>

00000000800059a8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a8:	7135                	addi	sp,sp,-160
    800059aa:	ed06                	sd	ra,152(sp)
    800059ac:	e922                	sd	s0,144(sp)
    800059ae:	e526                	sd	s1,136(sp)
    800059b0:	e14a                	sd	s2,128(sp)
    800059b2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b4:	ffffc097          	auipc	ra,0xffffc
    800059b8:	028080e7          	jalr	40(ra) # 800019dc <myproc>
    800059bc:	892a                	mv	s2,a0
  
  begin_op();
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	794080e7          	jalr	1940(ra) # 80004152 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c6:	08000613          	li	a2,128
    800059ca:	f6040593          	addi	a1,s0,-160
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	28c080e7          	jalr	652(ra) # 80002c5c <argstr>
    800059d8:	04054b63          	bltz	a0,80005a2e <sys_chdir+0x86>
    800059dc:	f6040513          	addi	a0,s0,-160
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	552080e7          	jalr	1362(ra) # 80003f32 <namei>
    800059e8:	84aa                	mv	s1,a0
    800059ea:	c131                	beqz	a0,80005a2e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	d9a080e7          	jalr	-614(ra) # 80003786 <ilock>
  if(ip->type != T_DIR){
    800059f4:	04449703          	lh	a4,68(s1)
    800059f8:	4785                	li	a5,1
    800059fa:	04f71063          	bne	a4,a5,80005a3a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	e48080e7          	jalr	-440(ra) # 80003848 <iunlock>
  iput(p->cwd);
    80005a08:	15093503          	ld	a0,336(s2)
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	f34080e7          	jalr	-204(ra) # 80003940 <iput>
  end_op();
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	7bc080e7          	jalr	1980(ra) # 800041d0 <end_op>
  p->cwd = ip;
    80005a1c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a20:	4501                	li	a0,0
}
    80005a22:	60ea                	ld	ra,152(sp)
    80005a24:	644a                	ld	s0,144(sp)
    80005a26:	64aa                	ld	s1,136(sp)
    80005a28:	690a                	ld	s2,128(sp)
    80005a2a:	610d                	addi	sp,sp,160
    80005a2c:	8082                	ret
    end_op();
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	7a2080e7          	jalr	1954(ra) # 800041d0 <end_op>
    return -1;
    80005a36:	557d                	li	a0,-1
    80005a38:	b7ed                	j	80005a22 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	fac080e7          	jalr	-84(ra) # 800039e8 <iunlockput>
    end_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	78c080e7          	jalr	1932(ra) # 800041d0 <end_op>
    return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	bfd1                	j	80005a22 <sys_chdir+0x7a>

0000000080005a50 <sys_exec>:

uint64
sys_exec(void)
{
    80005a50:	7145                	addi	sp,sp,-464
    80005a52:	e786                	sd	ra,456(sp)
    80005a54:	e3a2                	sd	s0,448(sp)
    80005a56:	ff26                	sd	s1,440(sp)
    80005a58:	fb4a                	sd	s2,432(sp)
    80005a5a:	f74e                	sd	s3,424(sp)
    80005a5c:	f352                	sd	s4,416(sp)
    80005a5e:	ef56                	sd	s5,408(sp)
    80005a60:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a62:	e3840593          	addi	a1,s0,-456
    80005a66:	4505                	li	a0,1
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	1d4080e7          	jalr	468(ra) # 80002c3c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a70:	08000613          	li	a2,128
    80005a74:	f4040593          	addi	a1,s0,-192
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	1e2080e7          	jalr	482(ra) # 80002c5c <argstr>
    80005a82:	87aa                	mv	a5,a0
    return -1;
    80005a84:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a86:	0c07c363          	bltz	a5,80005b4c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a8a:	10000613          	li	a2,256
    80005a8e:	4581                	li	a1,0
    80005a90:	e4040513          	addi	a0,s0,-448
    80005a94:	ffffb097          	auipc	ra,0xffffb
    80005a98:	23e080e7          	jalr	574(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a9c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aa0:	89a6                	mv	s3,s1
    80005aa2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa4:	02000a13          	li	s4,32
    80005aa8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aac:	00391513          	slli	a0,s2,0x3
    80005ab0:	e3040593          	addi	a1,s0,-464
    80005ab4:	e3843783          	ld	a5,-456(s0)
    80005ab8:	953e                	add	a0,a0,a5
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	0c4080e7          	jalr	196(ra) # 80002b7e <fetchaddr>
    80005ac2:	02054a63          	bltz	a0,80005af6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ac6:	e3043783          	ld	a5,-464(s0)
    80005aca:	c3b9                	beqz	a5,80005b10 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005acc:	ffffb097          	auipc	ra,0xffffb
    80005ad0:	01a080e7          	jalr	26(ra) # 80000ae6 <kalloc>
    80005ad4:	85aa                	mv	a1,a0
    80005ad6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ada:	cd11                	beqz	a0,80005af6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005adc:	6605                	lui	a2,0x1
    80005ade:	e3043503          	ld	a0,-464(s0)
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	0ee080e7          	jalr	238(ra) # 80002bd0 <fetchstr>
    80005aea:	00054663          	bltz	a0,80005af6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005aee:	0905                	addi	s2,s2,1
    80005af0:	09a1                	addi	s3,s3,8
    80005af2:	fb491be3          	bne	s2,s4,80005aa8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af6:	f4040913          	addi	s2,s0,-192
    80005afa:	6088                	ld	a0,0(s1)
    80005afc:	c539                	beqz	a0,80005b4a <sys_exec+0xfa>
    kfree(argv[i]);
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	eea080e7          	jalr	-278(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	04a1                	addi	s1,s1,8
    80005b08:	ff2499e3          	bne	s1,s2,80005afa <sys_exec+0xaa>
  return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	a83d                	j	80005b4c <sys_exec+0xfc>
      argv[i] = 0;
    80005b10:	0a8e                	slli	s5,s5,0x3
    80005b12:	fc0a8793          	addi	a5,s5,-64
    80005b16:	00878ab3          	add	s5,a5,s0
    80005b1a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b1e:	e4040593          	addi	a1,s0,-448
    80005b22:	f4040513          	addi	a0,s0,-192
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	16e080e7          	jalr	366(ra) # 80004c94 <exec>
    80005b2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b30:	f4040993          	addi	s3,s0,-192
    80005b34:	6088                	ld	a0,0(s1)
    80005b36:	c901                	beqz	a0,80005b46 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	eb0080e7          	jalr	-336(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	04a1                	addi	s1,s1,8
    80005b42:	ff3499e3          	bne	s1,s3,80005b34 <sys_exec+0xe4>
  return ret;
    80005b46:	854a                	mv	a0,s2
    80005b48:	a011                	j	80005b4c <sys_exec+0xfc>
  return -1;
    80005b4a:	557d                	li	a0,-1
}
    80005b4c:	60be                	ld	ra,456(sp)
    80005b4e:	641e                	ld	s0,448(sp)
    80005b50:	74fa                	ld	s1,440(sp)
    80005b52:	795a                	ld	s2,432(sp)
    80005b54:	79ba                	ld	s3,424(sp)
    80005b56:	7a1a                	ld	s4,416(sp)
    80005b58:	6afa                	ld	s5,408(sp)
    80005b5a:	6179                	addi	sp,sp,464
    80005b5c:	8082                	ret

0000000080005b5e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b5e:	7139                	addi	sp,sp,-64
    80005b60:	fc06                	sd	ra,56(sp)
    80005b62:	f822                	sd	s0,48(sp)
    80005b64:	f426                	sd	s1,40(sp)
    80005b66:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b68:	ffffc097          	auipc	ra,0xffffc
    80005b6c:	e74080e7          	jalr	-396(ra) # 800019dc <myproc>
    80005b70:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b72:	fd840593          	addi	a1,s0,-40
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	0c4080e7          	jalr	196(ra) # 80002c3c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b80:	fc840593          	addi	a1,s0,-56
    80005b84:	fd040513          	addi	a0,s0,-48
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	dc2080e7          	jalr	-574(ra) # 8000494a <pipealloc>
    return -1;
    80005b90:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b92:	0c054463          	bltz	a0,80005c5a <sys_pipe+0xfc>
  fd0 = -1;
    80005b96:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b9a:	fd043503          	ld	a0,-48(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	514080e7          	jalr	1300(ra) # 800050b2 <fdalloc>
    80005ba6:	fca42223          	sw	a0,-60(s0)
    80005baa:	08054b63          	bltz	a0,80005c40 <sys_pipe+0xe2>
    80005bae:	fc843503          	ld	a0,-56(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	500080e7          	jalr	1280(ra) # 800050b2 <fdalloc>
    80005bba:	fca42023          	sw	a0,-64(s0)
    80005bbe:	06054863          	bltz	a0,80005c2e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc2:	4691                	li	a3,4
    80005bc4:	fc440613          	addi	a2,s0,-60
    80005bc8:	fd843583          	ld	a1,-40(s0)
    80005bcc:	68a8                	ld	a0,80(s1)
    80005bce:	ffffc097          	auipc	ra,0xffffc
    80005bd2:	a9e080e7          	jalr	-1378(ra) # 8000166c <copyout>
    80005bd6:	02054063          	bltz	a0,80005bf6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bda:	4691                	li	a3,4
    80005bdc:	fc040613          	addi	a2,s0,-64
    80005be0:	fd843583          	ld	a1,-40(s0)
    80005be4:	0591                	addi	a1,a1,4
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	a84080e7          	jalr	-1404(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf2:	06055463          	bgez	a0,80005c5a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	07e9                	addi	a5,a5,26
    80005bfc:	078e                	slli	a5,a5,0x3
    80005bfe:	97a6                	add	a5,a5,s1
    80005c00:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c04:	fc042783          	lw	a5,-64(s0)
    80005c08:	07e9                	addi	a5,a5,26
    80005c0a:	078e                	slli	a5,a5,0x3
    80005c0c:	94be                	add	s1,s1,a5
    80005c0e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c12:	fd043503          	ld	a0,-48(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	a04080e7          	jalr	-1532(ra) # 8000461a <fileclose>
    fileclose(wf);
    80005c1e:	fc843503          	ld	a0,-56(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9f8080e7          	jalr	-1544(ra) # 8000461a <fileclose>
    return -1;
    80005c2a:	57fd                	li	a5,-1
    80005c2c:	a03d                	j	80005c5a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c2e:	fc442783          	lw	a5,-60(s0)
    80005c32:	0007c763          	bltz	a5,80005c40 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c36:	07e9                	addi	a5,a5,26
    80005c38:	078e                	slli	a5,a5,0x3
    80005c3a:	97a6                	add	a5,a5,s1
    80005c3c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9d6080e7          	jalr	-1578(ra) # 8000461a <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	9ca080e7          	jalr	-1590(ra) # 8000461a <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
}
    80005c5a:	853e                	mv	a0,a5
    80005c5c:	70e2                	ld	ra,56(sp)
    80005c5e:	7442                	ld	s0,48(sp)
    80005c60:	74a2                	ld	s1,40(sp)
    80005c62:	6121                	addi	sp,sp,64
    80005c64:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	d9bfc0ef          	jal	ra,80002a4a <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	6d0c                	ld	a1,24(a0)
    80005d0c:	7110                	ld	a2,32(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c68080e7          	jalr	-920(ra) # 800019b0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	97aa                	add	a5,a5,a0
    80005d6c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c30080e7          	jalr	-976(ra) # 800019b0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5151b          	slliw	a0,a0,0xd
    80005d8c:	0c2017b7          	lui	a5,0xc201
    80005d90:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d92:	43c8                	lw	a0,4(a5)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c08080e7          	jalr	-1016(ra) # 800019b0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005dd4:	0001d797          	auipc	a5,0x1d
    80005dd8:	a4c78793          	addi	a5,a5,-1460 # 80022820 <disk>
    80005ddc:	97aa                	add	a5,a5,a0
    80005dde:	0187c783          	lbu	a5,24(a5)
    80005de2:	ebb9                	bnez	a5,80005e38 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005de4:	00451693          	slli	a3,a0,0x4
    80005de8:	0001d797          	auipc	a5,0x1d
    80005dec:	a3878793          	addi	a5,a5,-1480 # 80022820 <disk>
    80005df0:	6398                	ld	a4,0(a5)
    80005df2:	9736                	add	a4,a4,a3
    80005df4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005df8:	6398                	ld	a4,0(a5)
    80005dfa:	9736                	add	a4,a4,a3
    80005dfc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e00:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e04:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	4705                	li	a4,1
    80005e0c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e10:	0001d517          	auipc	a0,0x1d
    80005e14:	a2850513          	addi	a0,a0,-1496 # 80022838 <disk+0x18>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	3fa080e7          	jalr	1018(ra) # 80002212 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("free_desc 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	91850513          	addi	a0,a0,-1768 # 80008740 <syscalls+0x2f0>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	710080e7          	jalr	1808(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	91850513          	addi	a0,a0,-1768 # 80008750 <syscalls+0x300>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	700080e7          	jalr	1792(ra) # 80000540 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	e04a                	sd	s2,0(sp)
    80005e52:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e54:	00003597          	auipc	a1,0x3
    80005e58:	90c58593          	addi	a1,a1,-1780 # 80008760 <syscalls+0x310>
    80005e5c:	0001d517          	auipc	a0,0x1d
    80005e60:	aec50513          	addi	a0,a0,-1300 # 80022948 <disk+0x128>
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	ce2080e7          	jalr	-798(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	4398                	lw	a4,0(a5)
    80005e72:	2701                	sext.w	a4,a4
    80005e74:	747277b7          	lui	a5,0x74727
    80005e78:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7c:	14f71b63          	bne	a4,a5,80005fd2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e80:	100017b7          	lui	a5,0x10001
    80005e84:	43dc                	lw	a5,4(a5)
    80005e86:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e88:	4709                	li	a4,2
    80005e8a:	14e79463          	bne	a5,a4,80005fd2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	479c                	lw	a5,8(a5)
    80005e94:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e96:	12e79e63          	bne	a5,a4,80005fd2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	12f71463          	bne	a4,a5,80005fd2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	4705                	li	a4,1
    80005eb8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eba:	470d                	li	a4,3
    80005ebc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ebe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ec4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbdff>
    80005ec8:	8f75                	and	a4,a4,a3
    80005eca:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ecc:	472d                	li	a4,11
    80005ece:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ed0:	5bbc                	lw	a5,112(a5)
    80005ed2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ed6:	8ba1                	andi	a5,a5,8
    80005ed8:	10078563          	beqz	a5,80005fe2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ee4:	43fc                	lw	a5,68(a5)
    80005ee6:	2781                	sext.w	a5,a5
    80005ee8:	10079563          	bnez	a5,80005ff2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	5bdc                	lw	a5,52(a5)
    80005ef2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ef4:	10078763          	beqz	a5,80006002 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ef8:	471d                	li	a4,7
    80005efa:	10f77c63          	bgeu	a4,a5,80006012 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005efe:	ffffb097          	auipc	ra,0xffffb
    80005f02:	be8080e7          	jalr	-1048(ra) # 80000ae6 <kalloc>
    80005f06:	0001d497          	auipc	s1,0x1d
    80005f0a:	91a48493          	addi	s1,s1,-1766 # 80022820 <disk>
    80005f0e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	bd6080e7          	jalr	-1066(ra) # 80000ae6 <kalloc>
    80005f18:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f1a:	ffffb097          	auipc	ra,0xffffb
    80005f1e:	bcc080e7          	jalr	-1076(ra) # 80000ae6 <kalloc>
    80005f22:	87aa                	mv	a5,a0
    80005f24:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f26:	6088                	ld	a0,0(s1)
    80005f28:	cd6d                	beqz	a0,80006022 <virtio_disk_init+0x1da>
    80005f2a:	0001d717          	auipc	a4,0x1d
    80005f2e:	8fe73703          	ld	a4,-1794(a4) # 80022828 <disk+0x8>
    80005f32:	cb65                	beqz	a4,80006022 <virtio_disk_init+0x1da>
    80005f34:	c7fd                	beqz	a5,80006022 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f36:	6605                	lui	a2,0x1
    80005f38:	4581                	li	a1,0
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	d98080e7          	jalr	-616(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f42:	0001d497          	auipc	s1,0x1d
    80005f46:	8de48493          	addi	s1,s1,-1826 # 80022820 <disk>
    80005f4a:	6605                	lui	a2,0x1
    80005f4c:	4581                	li	a1,0
    80005f4e:	6488                	ld	a0,8(s1)
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	d82080e7          	jalr	-638(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f58:	6605                	lui	a2,0x1
    80005f5a:	4581                	li	a1,0
    80005f5c:	6888                	ld	a0,16(s1)
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	d74080e7          	jalr	-652(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f66:	100017b7          	lui	a5,0x10001
    80005f6a:	4721                	li	a4,8
    80005f6c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f6e:	4098                	lw	a4,0(s1)
    80005f70:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f74:	40d8                	lw	a4,4(s1)
    80005f76:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f7a:	6498                	ld	a4,8(s1)
    80005f7c:	0007069b          	sext.w	a3,a4
    80005f80:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f84:	9701                	srai	a4,a4,0x20
    80005f86:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f8a:	6898                	ld	a4,16(s1)
    80005f8c:	0007069b          	sext.w	a3,a4
    80005f90:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f94:	9701                	srai	a4,a4,0x20
    80005f96:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f9a:	4705                	li	a4,1
    80005f9c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f9e:	00e48c23          	sb	a4,24(s1)
    80005fa2:	00e48ca3          	sb	a4,25(s1)
    80005fa6:	00e48d23          	sb	a4,26(s1)
    80005faa:	00e48da3          	sb	a4,27(s1)
    80005fae:	00e48e23          	sb	a4,28(s1)
    80005fb2:	00e48ea3          	sb	a4,29(s1)
    80005fb6:	00e48f23          	sb	a4,30(s1)
    80005fba:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fbe:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc2:	0727a823          	sw	s2,112(a5)
}
    80005fc6:	60e2                	ld	ra,24(sp)
    80005fc8:	6442                	ld	s0,16(sp)
    80005fca:	64a2                	ld	s1,8(sp)
    80005fcc:	6902                	ld	s2,0(sp)
    80005fce:	6105                	addi	sp,sp,32
    80005fd0:	8082                	ret
    panic("could not find virtio disk");
    80005fd2:	00002517          	auipc	a0,0x2
    80005fd6:	79e50513          	addi	a0,a0,1950 # 80008770 <syscalls+0x320>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fe2:	00002517          	auipc	a0,0x2
    80005fe6:	7ae50513          	addi	a0,a0,1966 # 80008790 <syscalls+0x340>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005ff2:	00002517          	auipc	a0,0x2
    80005ff6:	7be50513          	addi	a0,a0,1982 # 800087b0 <syscalls+0x360>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006002:	00002517          	auipc	a0,0x2
    80006006:	7ce50513          	addi	a0,a0,1998 # 800087d0 <syscalls+0x380>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006012:	00002517          	auipc	a0,0x2
    80006016:	7de50513          	addi	a0,a0,2014 # 800087f0 <syscalls+0x3a0>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006022:	00002517          	auipc	a0,0x2
    80006026:	7ee50513          	addi	a0,a0,2030 # 80008810 <syscalls+0x3c0>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>

0000000080006032 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006032:	7119                	addi	sp,sp,-128
    80006034:	fc86                	sd	ra,120(sp)
    80006036:	f8a2                	sd	s0,112(sp)
    80006038:	f4a6                	sd	s1,104(sp)
    8000603a:	f0ca                	sd	s2,96(sp)
    8000603c:	ecce                	sd	s3,88(sp)
    8000603e:	e8d2                	sd	s4,80(sp)
    80006040:	e4d6                	sd	s5,72(sp)
    80006042:	e0da                	sd	s6,64(sp)
    80006044:	fc5e                	sd	s7,56(sp)
    80006046:	f862                	sd	s8,48(sp)
    80006048:	f466                	sd	s9,40(sp)
    8000604a:	f06a                	sd	s10,32(sp)
    8000604c:	ec6e                	sd	s11,24(sp)
    8000604e:	0100                	addi	s0,sp,128
    80006050:	8aaa                	mv	s5,a0
    80006052:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006054:	00c52d03          	lw	s10,12(a0)
    80006058:	001d1d1b          	slliw	s10,s10,0x1
    8000605c:	1d02                	slli	s10,s10,0x20
    8000605e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006062:	0001d517          	auipc	a0,0x1d
    80006066:	8e650513          	addi	a0,a0,-1818 # 80022948 <disk+0x128>
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	b6c080e7          	jalr	-1172(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006072:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006074:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006076:	0001cb97          	auipc	s7,0x1c
    8000607a:	7aab8b93          	addi	s7,s7,1962 # 80022820 <disk>
  for(int i = 0; i < 3; i++){
    8000607e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006080:	0001dc97          	auipc	s9,0x1d
    80006084:	8c8c8c93          	addi	s9,s9,-1848 # 80022948 <disk+0x128>
    80006088:	a08d                	j	800060ea <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000608a:	00fb8733          	add	a4,s7,a5
    8000608e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006092:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006098:	2905                	addiw	s2,s2,1
    8000609a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000609c:	05690c63          	beq	s2,s6,800060f4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060a2:	0001c717          	auipc	a4,0x1c
    800060a6:	77e70713          	addi	a4,a4,1918 # 80022820 <disk>
    800060aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060ac:	01874683          	lbu	a3,24(a4)
    800060b0:	fee9                	bnez	a3,8000608a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0705                	addi	a4,a4,1
    800060b6:	fe979be3          	bne	a5,s1,800060ac <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060be:	01205d63          	blez	s2,800060d8 <virtio_disk_rw+0xa6>
    800060c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060c4:	000a2503          	lw	a0,0(s4)
    800060c8:	00000097          	auipc	ra,0x0
    800060cc:	cfe080e7          	jalr	-770(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    800060d0:	2d85                	addiw	s11,s11,1
    800060d2:	0a11                	addi	s4,s4,4
    800060d4:	ff2d98e3          	bne	s11,s2,800060c4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d8:	85e6                	mv	a1,s9
    800060da:	0001c517          	auipc	a0,0x1c
    800060de:	75e50513          	addi	a0,a0,1886 # 80022838 <disk+0x18>
    800060e2:	ffffc097          	auipc	ra,0xffffc
    800060e6:	0cc080e7          	jalr	204(ra) # 800021ae <sleep>
  for(int i = 0; i < 3; i++){
    800060ea:	f8040a13          	addi	s4,s0,-128
{
    800060ee:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060f0:	894e                	mv	s2,s3
    800060f2:	b77d                	j	800060a0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060f4:	f8042503          	lw	a0,-128(s0)
    800060f8:	00a50713          	addi	a4,a0,10
    800060fc:	0712                	slli	a4,a4,0x4

  if(write)
    800060fe:	0001c797          	auipc	a5,0x1c
    80006102:	72278793          	addi	a5,a5,1826 # 80022820 <disk>
    80006106:	00e786b3          	add	a3,a5,a4
    8000610a:	01803633          	snez	a2,s8
    8000610e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006110:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006114:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006118:	f6070613          	addi	a2,a4,-160
    8000611c:	6394                	ld	a3,0(a5)
    8000611e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006120:	00870593          	addi	a1,a4,8
    80006124:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006126:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006128:	0007b803          	ld	a6,0(a5)
    8000612c:	9642                	add	a2,a2,a6
    8000612e:	46c1                	li	a3,16
    80006130:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006132:	4585                	li	a1,1
    80006134:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006138:	f8442683          	lw	a3,-124(s0)
    8000613c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006140:	0692                	slli	a3,a3,0x4
    80006142:	9836                	add	a6,a6,a3
    80006144:	058a8613          	addi	a2,s5,88
    80006148:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000614c:	0007b803          	ld	a6,0(a5)
    80006150:	96c2                	add	a3,a3,a6
    80006152:	40000613          	li	a2,1024
    80006156:	c690                	sw	a2,8(a3)
  if(write)
    80006158:	001c3613          	seqz	a2,s8
    8000615c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006160:	00166613          	ori	a2,a2,1
    80006164:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006168:	f8842603          	lw	a2,-120(s0)
    8000616c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006170:	00250693          	addi	a3,a0,2
    80006174:	0692                	slli	a3,a3,0x4
    80006176:	96be                	add	a3,a3,a5
    80006178:	58fd                	li	a7,-1
    8000617a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000617e:	0612                	slli	a2,a2,0x4
    80006180:	9832                	add	a6,a6,a2
    80006182:	f9070713          	addi	a4,a4,-112
    80006186:	973e                	add	a4,a4,a5
    80006188:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000618c:	6398                	ld	a4,0(a5)
    8000618e:	9732                	add	a4,a4,a2
    80006190:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006192:	4609                	li	a2,2
    80006194:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006198:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000619c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061a0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061a4:	6794                	ld	a3,8(a5)
    800061a6:	0026d703          	lhu	a4,2(a3)
    800061aa:	8b1d                	andi	a4,a4,7
    800061ac:	0706                	slli	a4,a4,0x1
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061b8:	6798                	ld	a4,8(a5)
    800061ba:	00275783          	lhu	a5,2(a4)
    800061be:	2785                	addiw	a5,a5,1
    800061c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061c8:	100017b7          	lui	a5,0x10001
    800061cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061d0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061d4:	0001c917          	auipc	s2,0x1c
    800061d8:	77490913          	addi	s2,s2,1908 # 80022948 <disk+0x128>
  while(b->disk == 1) {
    800061dc:	4485                	li	s1,1
    800061de:	00b79c63          	bne	a5,a1,800061f6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061e2:	85ca                	mv	a1,s2
    800061e4:	8556                	mv	a0,s5
    800061e6:	ffffc097          	auipc	ra,0xffffc
    800061ea:	fc8080e7          	jalr	-56(ra) # 800021ae <sleep>
  while(b->disk == 1) {
    800061ee:	004aa783          	lw	a5,4(s5)
    800061f2:	fe9788e3          	beq	a5,s1,800061e2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800061f6:	f8042903          	lw	s2,-128(s0)
    800061fa:	00290713          	addi	a4,s2,2
    800061fe:	0712                	slli	a4,a4,0x4
    80006200:	0001c797          	auipc	a5,0x1c
    80006204:	62078793          	addi	a5,a5,1568 # 80022820 <disk>
    80006208:	97ba                	add	a5,a5,a4
    8000620a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000620e:	0001c997          	auipc	s3,0x1c
    80006212:	61298993          	addi	s3,s3,1554 # 80022820 <disk>
    80006216:	00491713          	slli	a4,s2,0x4
    8000621a:	0009b783          	ld	a5,0(s3)
    8000621e:	97ba                	add	a5,a5,a4
    80006220:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006224:	854a                	mv	a0,s2
    80006226:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000622a:	00000097          	auipc	ra,0x0
    8000622e:	b9c080e7          	jalr	-1124(ra) # 80005dc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006232:	8885                	andi	s1,s1,1
    80006234:	f0ed                	bnez	s1,80006216 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006236:	0001c517          	auipc	a0,0x1c
    8000623a:	71250513          	addi	a0,a0,1810 # 80022948 <disk+0x128>
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
}
    80006246:	70e6                	ld	ra,120(sp)
    80006248:	7446                	ld	s0,112(sp)
    8000624a:	74a6                	ld	s1,104(sp)
    8000624c:	7906                	ld	s2,96(sp)
    8000624e:	69e6                	ld	s3,88(sp)
    80006250:	6a46                	ld	s4,80(sp)
    80006252:	6aa6                	ld	s5,72(sp)
    80006254:	6b06                	ld	s6,64(sp)
    80006256:	7be2                	ld	s7,56(sp)
    80006258:	7c42                	ld	s8,48(sp)
    8000625a:	7ca2                	ld	s9,40(sp)
    8000625c:	7d02                	ld	s10,32(sp)
    8000625e:	6de2                	ld	s11,24(sp)
    80006260:	6109                	addi	sp,sp,128
    80006262:	8082                	ret

0000000080006264 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006264:	1101                	addi	sp,sp,-32
    80006266:	ec06                	sd	ra,24(sp)
    80006268:	e822                	sd	s0,16(sp)
    8000626a:	e426                	sd	s1,8(sp)
    8000626c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000626e:	0001c497          	auipc	s1,0x1c
    80006272:	5b248493          	addi	s1,s1,1458 # 80022820 <disk>
    80006276:	0001c517          	auipc	a0,0x1c
    8000627a:	6d250513          	addi	a0,a0,1746 # 80022948 <disk+0x128>
    8000627e:	ffffb097          	auipc	ra,0xffffb
    80006282:	958080e7          	jalr	-1704(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006286:	10001737          	lui	a4,0x10001
    8000628a:	533c                	lw	a5,96(a4)
    8000628c:	8b8d                	andi	a5,a5,3
    8000628e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006290:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006294:	689c                	ld	a5,16(s1)
    80006296:	0204d703          	lhu	a4,32(s1)
    8000629a:	0027d783          	lhu	a5,2(a5)
    8000629e:	04f70863          	beq	a4,a5,800062ee <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062a2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062a6:	6898                	ld	a4,16(s1)
    800062a8:	0204d783          	lhu	a5,32(s1)
    800062ac:	8b9d                	andi	a5,a5,7
    800062ae:	078e                	slli	a5,a5,0x3
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062b4:	00278713          	addi	a4,a5,2
    800062b8:	0712                	slli	a4,a4,0x4
    800062ba:	9726                	add	a4,a4,s1
    800062bc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062c0:	e721                	bnez	a4,80006308 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062c2:	0789                	addi	a5,a5,2
    800062c4:	0792                	slli	a5,a5,0x4
    800062c6:	97a6                	add	a5,a5,s1
    800062c8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ca:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ce:	ffffc097          	auipc	ra,0xffffc
    800062d2:	f44080e7          	jalr	-188(ra) # 80002212 <wakeup>

    disk.used_idx += 1;
    800062d6:	0204d783          	lhu	a5,32(s1)
    800062da:	2785                	addiw	a5,a5,1
    800062dc:	17c2                	slli	a5,a5,0x30
    800062de:	93c1                	srli	a5,a5,0x30
    800062e0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062e4:	6898                	ld	a4,16(s1)
    800062e6:	00275703          	lhu	a4,2(a4)
    800062ea:	faf71ce3          	bne	a4,a5,800062a2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062ee:	0001c517          	auipc	a0,0x1c
    800062f2:	65a50513          	addi	a0,a0,1626 # 80022948 <disk+0x128>
    800062f6:	ffffb097          	auipc	ra,0xffffb
    800062fa:	994080e7          	jalr	-1644(ra) # 80000c8a <release>
}
    800062fe:	60e2                	ld	ra,24(sp)
    80006300:	6442                	ld	s0,16(sp)
    80006302:	64a2                	ld	s1,8(sp)
    80006304:	6105                	addi	sp,sp,32
    80006306:	8082                	ret
      panic("virtio_disk_intr status");
    80006308:	00002517          	auipc	a0,0x2
    8000630c:	52050513          	addi	a0,a0,1312 # 80008828 <syscalls+0x3d8>
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	230080e7          	jalr	560(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
