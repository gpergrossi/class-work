
_bigtest:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "user.h"
#include "fcntl.h"

int
main()
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	81 ec 30 02 00 00    	sub    $0x230,%esp
  char buf[512];
  int fd, i, sectors;

  fd = open("big.file", O_CREATE | O_WRONLY);
   c:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
  13:	00 
  14:	c7 04 24 c4 09 00 00 	movl   $0x9c4,(%esp)
  1b:	e8 98 04 00 00       	call   4b8 <open>
  20:	89 84 24 24 02 00 00 	mov    %eax,0x224(%esp)
  if(fd < 0){
  27:	83 bc 24 24 02 00 00 	cmpl   $0x0,0x224(%esp)
  2e:	00 
  2f:	79 19                	jns    4a <main+0x4a>
    printf(2, "big: cannot open big.file for writing\n");
  31:	c7 44 24 04 d0 09 00 	movl   $0x9d0,0x4(%esp)
  38:	00 
  39:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  40:	e8 b3 05 00 00       	call   5f8 <printf>
    exit();
  45:	e8 2e 04 00 00       	call   478 <exit>
  }

  sectors = 0;
  4a:	c7 84 24 28 02 00 00 	movl   $0x0,0x228(%esp)
  51:	00 00 00 00 
  while(1){
    *(int*)buf = sectors;
  55:	8d 44 24 1c          	lea    0x1c(%esp),%eax
  59:	8b 94 24 28 02 00 00 	mov    0x228(%esp),%edx
  60:	89 10                	mov    %edx,(%eax)
    int cc = write(fd, buf, sizeof(buf));
  62:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
  69:	00 
  6a:	8d 44 24 1c          	lea    0x1c(%esp),%eax
  6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  72:	8b 84 24 24 02 00 00 	mov    0x224(%esp),%eax
  79:	89 04 24             	mov    %eax,(%esp)
  7c:	e8 17 04 00 00       	call   498 <write>
  81:	89 84 24 20 02 00 00 	mov    %eax,0x220(%esp)
    if(cc <= 0)
  88:	83 bc 24 20 02 00 00 	cmpl   $0x0,0x220(%esp)
  8f:	00 
  90:	7f 56                	jg     e8 <main+0xe8>
      break;
  92:	90                   	nop
    sectors++;
	if (sectors % 100 == 0)
		printf(2, ".");
  }

  printf(1, "\nwrote %d sectors\n", sectors);
  93:	8b 84 24 28 02 00 00 	mov    0x228(%esp),%eax
  9a:	89 44 24 08          	mov    %eax,0x8(%esp)
  9e:	c7 44 24 04 f9 09 00 	movl   $0x9f9,0x4(%esp)
  a5:	00 
  a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  ad:	e8 46 05 00 00       	call   5f8 <printf>

  close(fd);
  b2:	8b 84 24 24 02 00 00 	mov    0x224(%esp),%eax
  b9:	89 04 24             	mov    %eax,(%esp)
  bc:	e8 df 03 00 00       	call   4a0 <close>
  fd = open("big.file", O_RDONLY);
  c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  c8:	00 
  c9:	c7 04 24 c4 09 00 00 	movl   $0x9c4,(%esp)
  d0:	e8 e3 03 00 00       	call   4b8 <open>
  d5:	89 84 24 24 02 00 00 	mov    %eax,0x224(%esp)
  if(fd < 0){
  dc:	83 bc 24 24 02 00 00 	cmpl   $0x0,0x224(%esp)
  e3:	00 
  e4:	79 68                	jns    14e <main+0x14e>
  e6:	eb 4d                	jmp    135 <main+0x135>
  while(1){
    *(int*)buf = sectors;
    int cc = write(fd, buf, sizeof(buf));
    if(cc <= 0)
      break;
    sectors++;
  e8:	83 84 24 28 02 00 00 	addl   $0x1,0x228(%esp)
  ef:	01 
	if (sectors % 100 == 0)
  f0:	8b 8c 24 28 02 00 00 	mov    0x228(%esp),%ecx
  f7:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
  fc:	89 c8                	mov    %ecx,%eax
  fe:	f7 ea                	imul   %edx
 100:	c1 fa 05             	sar    $0x5,%edx
 103:	89 c8                	mov    %ecx,%eax
 105:	c1 f8 1f             	sar    $0x1f,%eax
 108:	29 c2                	sub    %eax,%edx
 10a:	89 d0                	mov    %edx,%eax
 10c:	6b c0 64             	imul   $0x64,%eax,%eax
 10f:	29 c1                	sub    %eax,%ecx
 111:	89 c8                	mov    %ecx,%eax
 113:	85 c0                	test   %eax,%eax
 115:	75 19                	jne    130 <main+0x130>
		printf(2, ".");
 117:	c7 44 24 04 f7 09 00 	movl   $0x9f7,0x4(%esp)
 11e:	00 
 11f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 126:	e8 cd 04 00 00       	call   5f8 <printf>
  }
 12b:	e9 25 ff ff ff       	jmp    55 <main+0x55>
 130:	e9 20 ff ff ff       	jmp    55 <main+0x55>
  printf(1, "\nwrote %d sectors\n", sectors);

  close(fd);
  fd = open("big.file", O_RDONLY);
  if(fd < 0){
    printf(2, "big: cannot re-open big.file for reading\n");
 135:	c7 44 24 04 0c 0a 00 	movl   $0xa0c,0x4(%esp)
 13c:	00 
 13d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 144:	e8 af 04 00 00       	call   5f8 <printf>
    exit();
 149:	e8 2a 03 00 00       	call   478 <exit>
  }
  for(i = 0; i < sectors; i++){
 14e:	c7 84 24 2c 02 00 00 	movl   $0x0,0x22c(%esp)
 155:	00 00 00 00 
 159:	e9 99 00 00 00       	jmp    1f7 <main+0x1f7>
    int cc = read(fd, buf, sizeof(buf));
 15e:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
 165:	00 
 166:	8d 44 24 1c          	lea    0x1c(%esp),%eax
 16a:	89 44 24 04          	mov    %eax,0x4(%esp)
 16e:	8b 84 24 24 02 00 00 	mov    0x224(%esp),%eax
 175:	89 04 24             	mov    %eax,(%esp)
 178:	e8 13 03 00 00       	call   490 <read>
 17d:	89 84 24 1c 02 00 00 	mov    %eax,0x21c(%esp)
    if(cc <= 0){
 184:	83 bc 24 1c 02 00 00 	cmpl   $0x0,0x21c(%esp)
 18b:	00 
 18c:	7f 24                	jg     1b2 <main+0x1b2>
      printf(2, "big: read error at sector %d\n", i);
 18e:	8b 84 24 2c 02 00 00 	mov    0x22c(%esp),%eax
 195:	89 44 24 08          	mov    %eax,0x8(%esp)
 199:	c7 44 24 04 36 0a 00 	movl   $0xa36,0x4(%esp)
 1a0:	00 
 1a1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 1a8:	e8 4b 04 00 00       	call   5f8 <printf>
      exit();
 1ad:	e8 c6 02 00 00       	call   478 <exit>
    }
    if(*(int*)buf != i){
 1b2:	8d 44 24 1c          	lea    0x1c(%esp),%eax
 1b6:	8b 00                	mov    (%eax),%eax
 1b8:	3b 84 24 2c 02 00 00 	cmp    0x22c(%esp),%eax
 1bf:	74 2e                	je     1ef <main+0x1ef>
      printf(2, "big: read the wrong data (%d) for sector %d\n",
             *(int*)buf, i);
 1c1:	8d 44 24 1c          	lea    0x1c(%esp),%eax
    if(cc <= 0){
      printf(2, "big: read error at sector %d\n", i);
      exit();
    }
    if(*(int*)buf != i){
      printf(2, "big: read the wrong data (%d) for sector %d\n",
 1c5:	8b 00                	mov    (%eax),%eax
 1c7:	8b 94 24 2c 02 00 00 	mov    0x22c(%esp),%edx
 1ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
 1d2:	89 44 24 08          	mov    %eax,0x8(%esp)
 1d6:	c7 44 24 04 54 0a 00 	movl   $0xa54,0x4(%esp)
 1dd:	00 
 1de:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 1e5:	e8 0e 04 00 00       	call   5f8 <printf>
             *(int*)buf, i);
      exit();
 1ea:	e8 89 02 00 00       	call   478 <exit>
  fd = open("big.file", O_RDONLY);
  if(fd < 0){
    printf(2, "big: cannot re-open big.file for reading\n");
    exit();
  }
  for(i = 0; i < sectors; i++){
 1ef:	83 84 24 2c 02 00 00 	addl   $0x1,0x22c(%esp)
 1f6:	01 
 1f7:	8b 84 24 2c 02 00 00 	mov    0x22c(%esp),%eax
 1fe:	3b 84 24 28 02 00 00 	cmp    0x228(%esp),%eax
 205:	0f 8c 53 ff ff ff    	jl     15e <main+0x15e>
             *(int*)buf, i);
      exit();
    }
  }

  exit();
 20b:	e8 68 02 00 00       	call   478 <exit>

00000210 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 210:	55                   	push   %ebp
 211:	89 e5                	mov    %esp,%ebp
 213:	57                   	push   %edi
 214:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 215:	8b 4d 08             	mov    0x8(%ebp),%ecx
 218:	8b 55 10             	mov    0x10(%ebp),%edx
 21b:	8b 45 0c             	mov    0xc(%ebp),%eax
 21e:	89 cb                	mov    %ecx,%ebx
 220:	89 df                	mov    %ebx,%edi
 222:	89 d1                	mov    %edx,%ecx
 224:	fc                   	cld    
 225:	f3 aa                	rep stos %al,%es:(%edi)
 227:	89 ca                	mov    %ecx,%edx
 229:	89 fb                	mov    %edi,%ebx
 22b:	89 5d 08             	mov    %ebx,0x8(%ebp)
 22e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 231:	5b                   	pop    %ebx
 232:	5f                   	pop    %edi
 233:	5d                   	pop    %ebp
 234:	c3                   	ret    

00000235 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 235:	55                   	push   %ebp
 236:	89 e5                	mov    %esp,%ebp
 238:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 23b:	8b 45 08             	mov    0x8(%ebp),%eax
 23e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 241:	90                   	nop
 242:	8b 45 08             	mov    0x8(%ebp),%eax
 245:	8d 50 01             	lea    0x1(%eax),%edx
 248:	89 55 08             	mov    %edx,0x8(%ebp)
 24b:	8b 55 0c             	mov    0xc(%ebp),%edx
 24e:	8d 4a 01             	lea    0x1(%edx),%ecx
 251:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 254:	0f b6 12             	movzbl (%edx),%edx
 257:	88 10                	mov    %dl,(%eax)
 259:	0f b6 00             	movzbl (%eax),%eax
 25c:	84 c0                	test   %al,%al
 25e:	75 e2                	jne    242 <strcpy+0xd>
    ;
  return os;
 260:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 263:	c9                   	leave  
 264:	c3                   	ret    

00000265 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 265:	55                   	push   %ebp
 266:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 268:	eb 08                	jmp    272 <strcmp+0xd>
    p++, q++;
 26a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 26e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 272:	8b 45 08             	mov    0x8(%ebp),%eax
 275:	0f b6 00             	movzbl (%eax),%eax
 278:	84 c0                	test   %al,%al
 27a:	74 10                	je     28c <strcmp+0x27>
 27c:	8b 45 08             	mov    0x8(%ebp),%eax
 27f:	0f b6 10             	movzbl (%eax),%edx
 282:	8b 45 0c             	mov    0xc(%ebp),%eax
 285:	0f b6 00             	movzbl (%eax),%eax
 288:	38 c2                	cmp    %al,%dl
 28a:	74 de                	je     26a <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 28c:	8b 45 08             	mov    0x8(%ebp),%eax
 28f:	0f b6 00             	movzbl (%eax),%eax
 292:	0f b6 d0             	movzbl %al,%edx
 295:	8b 45 0c             	mov    0xc(%ebp),%eax
 298:	0f b6 00             	movzbl (%eax),%eax
 29b:	0f b6 c0             	movzbl %al,%eax
 29e:	29 c2                	sub    %eax,%edx
 2a0:	89 d0                	mov    %edx,%eax
}
 2a2:	5d                   	pop    %ebp
 2a3:	c3                   	ret    

000002a4 <strlen>:

uint
strlen(char *s)
{
 2a4:	55                   	push   %ebp
 2a5:	89 e5                	mov    %esp,%ebp
 2a7:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 2aa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 2b1:	eb 04                	jmp    2b7 <strlen+0x13>
 2b3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 2b7:	8b 55 fc             	mov    -0x4(%ebp),%edx
 2ba:	8b 45 08             	mov    0x8(%ebp),%eax
 2bd:	01 d0                	add    %edx,%eax
 2bf:	0f b6 00             	movzbl (%eax),%eax
 2c2:	84 c0                	test   %al,%al
 2c4:	75 ed                	jne    2b3 <strlen+0xf>
    ;
  return n;
 2c6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 2c9:	c9                   	leave  
 2ca:	c3                   	ret    

000002cb <memset>:

void*
memset(void *dst, int c, uint n)
{
 2cb:	55                   	push   %ebp
 2cc:	89 e5                	mov    %esp,%ebp
 2ce:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 2d1:	8b 45 10             	mov    0x10(%ebp),%eax
 2d4:	89 44 24 08          	mov    %eax,0x8(%esp)
 2d8:	8b 45 0c             	mov    0xc(%ebp),%eax
 2db:	89 44 24 04          	mov    %eax,0x4(%esp)
 2df:	8b 45 08             	mov    0x8(%ebp),%eax
 2e2:	89 04 24             	mov    %eax,(%esp)
 2e5:	e8 26 ff ff ff       	call   210 <stosb>
  return dst;
 2ea:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2ed:	c9                   	leave  
 2ee:	c3                   	ret    

000002ef <strchr>:

char*
strchr(const char *s, char c)
{
 2ef:	55                   	push   %ebp
 2f0:	89 e5                	mov    %esp,%ebp
 2f2:	83 ec 04             	sub    $0x4,%esp
 2f5:	8b 45 0c             	mov    0xc(%ebp),%eax
 2f8:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 2fb:	eb 14                	jmp    311 <strchr+0x22>
    if(*s == c)
 2fd:	8b 45 08             	mov    0x8(%ebp),%eax
 300:	0f b6 00             	movzbl (%eax),%eax
 303:	3a 45 fc             	cmp    -0x4(%ebp),%al
 306:	75 05                	jne    30d <strchr+0x1e>
      return (char*)s;
 308:	8b 45 08             	mov    0x8(%ebp),%eax
 30b:	eb 13                	jmp    320 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 30d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 311:	8b 45 08             	mov    0x8(%ebp),%eax
 314:	0f b6 00             	movzbl (%eax),%eax
 317:	84 c0                	test   %al,%al
 319:	75 e2                	jne    2fd <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 31b:	b8 00 00 00 00       	mov    $0x0,%eax
}
 320:	c9                   	leave  
 321:	c3                   	ret    

00000322 <gets>:

char*
gets(char *buf, int max)
{
 322:	55                   	push   %ebp
 323:	89 e5                	mov    %esp,%ebp
 325:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 328:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 32f:	eb 4c                	jmp    37d <gets+0x5b>
    cc = read(0, &c, 1);
 331:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 338:	00 
 339:	8d 45 ef             	lea    -0x11(%ebp),%eax
 33c:	89 44 24 04          	mov    %eax,0x4(%esp)
 340:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 347:	e8 44 01 00 00       	call   490 <read>
 34c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 34f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 353:	7f 02                	jg     357 <gets+0x35>
      break;
 355:	eb 31                	jmp    388 <gets+0x66>
    buf[i++] = c;
 357:	8b 45 f4             	mov    -0xc(%ebp),%eax
 35a:	8d 50 01             	lea    0x1(%eax),%edx
 35d:	89 55 f4             	mov    %edx,-0xc(%ebp)
 360:	89 c2                	mov    %eax,%edx
 362:	8b 45 08             	mov    0x8(%ebp),%eax
 365:	01 c2                	add    %eax,%edx
 367:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 36b:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 36d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 371:	3c 0a                	cmp    $0xa,%al
 373:	74 13                	je     388 <gets+0x66>
 375:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 379:	3c 0d                	cmp    $0xd,%al
 37b:	74 0b                	je     388 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 37d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 380:	83 c0 01             	add    $0x1,%eax
 383:	3b 45 0c             	cmp    0xc(%ebp),%eax
 386:	7c a9                	jl     331 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 388:	8b 55 f4             	mov    -0xc(%ebp),%edx
 38b:	8b 45 08             	mov    0x8(%ebp),%eax
 38e:	01 d0                	add    %edx,%eax
 390:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 393:	8b 45 08             	mov    0x8(%ebp),%eax
}
 396:	c9                   	leave  
 397:	c3                   	ret    

00000398 <stat>:

int
stat(char *n, struct stat *st)
{
 398:	55                   	push   %ebp
 399:	89 e5                	mov    %esp,%ebp
 39b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 39e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 3a5:	00 
 3a6:	8b 45 08             	mov    0x8(%ebp),%eax
 3a9:	89 04 24             	mov    %eax,(%esp)
 3ac:	e8 07 01 00 00       	call   4b8 <open>
 3b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 3b4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 3b8:	79 07                	jns    3c1 <stat+0x29>
    return -1;
 3ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 3bf:	eb 23                	jmp    3e4 <stat+0x4c>
  r = fstat(fd, st);
 3c1:	8b 45 0c             	mov    0xc(%ebp),%eax
 3c4:	89 44 24 04          	mov    %eax,0x4(%esp)
 3c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3cb:	89 04 24             	mov    %eax,(%esp)
 3ce:	e8 fd 00 00 00       	call   4d0 <fstat>
 3d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 3d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3d9:	89 04 24             	mov    %eax,(%esp)
 3dc:	e8 bf 00 00 00       	call   4a0 <close>
  return r;
 3e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 3e4:	c9                   	leave  
 3e5:	c3                   	ret    

000003e6 <atoi>:

int
atoi(const char *s)
{
 3e6:	55                   	push   %ebp
 3e7:	89 e5                	mov    %esp,%ebp
 3e9:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 3ec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 3f3:	eb 25                	jmp    41a <atoi+0x34>
    n = n*10 + *s++ - '0';
 3f5:	8b 55 fc             	mov    -0x4(%ebp),%edx
 3f8:	89 d0                	mov    %edx,%eax
 3fa:	c1 e0 02             	shl    $0x2,%eax
 3fd:	01 d0                	add    %edx,%eax
 3ff:	01 c0                	add    %eax,%eax
 401:	89 c1                	mov    %eax,%ecx
 403:	8b 45 08             	mov    0x8(%ebp),%eax
 406:	8d 50 01             	lea    0x1(%eax),%edx
 409:	89 55 08             	mov    %edx,0x8(%ebp)
 40c:	0f b6 00             	movzbl (%eax),%eax
 40f:	0f be c0             	movsbl %al,%eax
 412:	01 c8                	add    %ecx,%eax
 414:	83 e8 30             	sub    $0x30,%eax
 417:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 41a:	8b 45 08             	mov    0x8(%ebp),%eax
 41d:	0f b6 00             	movzbl (%eax),%eax
 420:	3c 2f                	cmp    $0x2f,%al
 422:	7e 0a                	jle    42e <atoi+0x48>
 424:	8b 45 08             	mov    0x8(%ebp),%eax
 427:	0f b6 00             	movzbl (%eax),%eax
 42a:	3c 39                	cmp    $0x39,%al
 42c:	7e c7                	jle    3f5 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 42e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 431:	c9                   	leave  
 432:	c3                   	ret    

00000433 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 433:	55                   	push   %ebp
 434:	89 e5                	mov    %esp,%ebp
 436:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 439:	8b 45 08             	mov    0x8(%ebp),%eax
 43c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 43f:	8b 45 0c             	mov    0xc(%ebp),%eax
 442:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 445:	eb 17                	jmp    45e <memmove+0x2b>
    *dst++ = *src++;
 447:	8b 45 fc             	mov    -0x4(%ebp),%eax
 44a:	8d 50 01             	lea    0x1(%eax),%edx
 44d:	89 55 fc             	mov    %edx,-0x4(%ebp)
 450:	8b 55 f8             	mov    -0x8(%ebp),%edx
 453:	8d 4a 01             	lea    0x1(%edx),%ecx
 456:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 459:	0f b6 12             	movzbl (%edx),%edx
 45c:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 45e:	8b 45 10             	mov    0x10(%ebp),%eax
 461:	8d 50 ff             	lea    -0x1(%eax),%edx
 464:	89 55 10             	mov    %edx,0x10(%ebp)
 467:	85 c0                	test   %eax,%eax
 469:	7f dc                	jg     447 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 46b:	8b 45 08             	mov    0x8(%ebp),%eax
}
 46e:	c9                   	leave  
 46f:	c3                   	ret    

00000470 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 470:	b8 01 00 00 00       	mov    $0x1,%eax
 475:	cd 40                	int    $0x40
 477:	c3                   	ret    

00000478 <exit>:
SYSCALL(exit)
 478:	b8 02 00 00 00       	mov    $0x2,%eax
 47d:	cd 40                	int    $0x40
 47f:	c3                   	ret    

00000480 <wait>:
SYSCALL(wait)
 480:	b8 03 00 00 00       	mov    $0x3,%eax
 485:	cd 40                	int    $0x40
 487:	c3                   	ret    

00000488 <pipe>:
SYSCALL(pipe)
 488:	b8 04 00 00 00       	mov    $0x4,%eax
 48d:	cd 40                	int    $0x40
 48f:	c3                   	ret    

00000490 <read>:
SYSCALL(read)
 490:	b8 05 00 00 00       	mov    $0x5,%eax
 495:	cd 40                	int    $0x40
 497:	c3                   	ret    

00000498 <write>:
SYSCALL(write)
 498:	b8 10 00 00 00       	mov    $0x10,%eax
 49d:	cd 40                	int    $0x40
 49f:	c3                   	ret    

000004a0 <close>:
SYSCALL(close)
 4a0:	b8 15 00 00 00       	mov    $0x15,%eax
 4a5:	cd 40                	int    $0x40
 4a7:	c3                   	ret    

000004a8 <kill>:
SYSCALL(kill)
 4a8:	b8 06 00 00 00       	mov    $0x6,%eax
 4ad:	cd 40                	int    $0x40
 4af:	c3                   	ret    

000004b0 <exec>:
SYSCALL(exec)
 4b0:	b8 07 00 00 00       	mov    $0x7,%eax
 4b5:	cd 40                	int    $0x40
 4b7:	c3                   	ret    

000004b8 <open>:
SYSCALL(open)
 4b8:	b8 0f 00 00 00       	mov    $0xf,%eax
 4bd:	cd 40                	int    $0x40
 4bf:	c3                   	ret    

000004c0 <mknod>:
SYSCALL(mknod)
 4c0:	b8 11 00 00 00       	mov    $0x11,%eax
 4c5:	cd 40                	int    $0x40
 4c7:	c3                   	ret    

000004c8 <unlink>:
SYSCALL(unlink)
 4c8:	b8 12 00 00 00       	mov    $0x12,%eax
 4cd:	cd 40                	int    $0x40
 4cf:	c3                   	ret    

000004d0 <fstat>:
SYSCALL(fstat)
 4d0:	b8 08 00 00 00       	mov    $0x8,%eax
 4d5:	cd 40                	int    $0x40
 4d7:	c3                   	ret    

000004d8 <link>:
SYSCALL(link)
 4d8:	b8 13 00 00 00       	mov    $0x13,%eax
 4dd:	cd 40                	int    $0x40
 4df:	c3                   	ret    

000004e0 <mkdir>:
SYSCALL(mkdir)
 4e0:	b8 14 00 00 00       	mov    $0x14,%eax
 4e5:	cd 40                	int    $0x40
 4e7:	c3                   	ret    

000004e8 <chdir>:
SYSCALL(chdir)
 4e8:	b8 09 00 00 00       	mov    $0x9,%eax
 4ed:	cd 40                	int    $0x40
 4ef:	c3                   	ret    

000004f0 <dup>:
SYSCALL(dup)
 4f0:	b8 0a 00 00 00       	mov    $0xa,%eax
 4f5:	cd 40                	int    $0x40
 4f7:	c3                   	ret    

000004f8 <getpid>:
SYSCALL(getpid)
 4f8:	b8 0b 00 00 00       	mov    $0xb,%eax
 4fd:	cd 40                	int    $0x40
 4ff:	c3                   	ret    

00000500 <sbrk>:
SYSCALL(sbrk)
 500:	b8 0c 00 00 00       	mov    $0xc,%eax
 505:	cd 40                	int    $0x40
 507:	c3                   	ret    

00000508 <sleep>:
SYSCALL(sleep)
 508:	b8 0d 00 00 00       	mov    $0xd,%eax
 50d:	cd 40                	int    $0x40
 50f:	c3                   	ret    

00000510 <uptime>:
SYSCALL(uptime)
 510:	b8 0e 00 00 00       	mov    $0xe,%eax
 515:	cd 40                	int    $0x40
 517:	c3                   	ret    

00000518 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 518:	55                   	push   %ebp
 519:	89 e5                	mov    %esp,%ebp
 51b:	83 ec 18             	sub    $0x18,%esp
 51e:	8b 45 0c             	mov    0xc(%ebp),%eax
 521:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 524:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 52b:	00 
 52c:	8d 45 f4             	lea    -0xc(%ebp),%eax
 52f:	89 44 24 04          	mov    %eax,0x4(%esp)
 533:	8b 45 08             	mov    0x8(%ebp),%eax
 536:	89 04 24             	mov    %eax,(%esp)
 539:	e8 5a ff ff ff       	call   498 <write>
}
 53e:	c9                   	leave  
 53f:	c3                   	ret    

00000540 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 540:	55                   	push   %ebp
 541:	89 e5                	mov    %esp,%ebp
 543:	56                   	push   %esi
 544:	53                   	push   %ebx
 545:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 548:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 54f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 553:	74 17                	je     56c <printint+0x2c>
 555:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 559:	79 11                	jns    56c <printint+0x2c>
    neg = 1;
 55b:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 562:	8b 45 0c             	mov    0xc(%ebp),%eax
 565:	f7 d8                	neg    %eax
 567:	89 45 ec             	mov    %eax,-0x14(%ebp)
 56a:	eb 06                	jmp    572 <printint+0x32>
  } else {
    x = xx;
 56c:	8b 45 0c             	mov    0xc(%ebp),%eax
 56f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 572:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 579:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 57c:	8d 41 01             	lea    0x1(%ecx),%eax
 57f:	89 45 f4             	mov    %eax,-0xc(%ebp)
 582:	8b 5d 10             	mov    0x10(%ebp),%ebx
 585:	8b 45 ec             	mov    -0x14(%ebp),%eax
 588:	ba 00 00 00 00       	mov    $0x0,%edx
 58d:	f7 f3                	div    %ebx
 58f:	89 d0                	mov    %edx,%eax
 591:	0f b6 80 cc 0c 00 00 	movzbl 0xccc(%eax),%eax
 598:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 59c:	8b 75 10             	mov    0x10(%ebp),%esi
 59f:	8b 45 ec             	mov    -0x14(%ebp),%eax
 5a2:	ba 00 00 00 00       	mov    $0x0,%edx
 5a7:	f7 f6                	div    %esi
 5a9:	89 45 ec             	mov    %eax,-0x14(%ebp)
 5ac:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 5b0:	75 c7                	jne    579 <printint+0x39>
  if(neg)
 5b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 5b6:	74 10                	je     5c8 <printint+0x88>
    buf[i++] = '-';
 5b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5bb:	8d 50 01             	lea    0x1(%eax),%edx
 5be:	89 55 f4             	mov    %edx,-0xc(%ebp)
 5c1:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 5c6:	eb 1f                	jmp    5e7 <printint+0xa7>
 5c8:	eb 1d                	jmp    5e7 <printint+0xa7>
    putc(fd, buf[i]);
 5ca:	8d 55 dc             	lea    -0x24(%ebp),%edx
 5cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5d0:	01 d0                	add    %edx,%eax
 5d2:	0f b6 00             	movzbl (%eax),%eax
 5d5:	0f be c0             	movsbl %al,%eax
 5d8:	89 44 24 04          	mov    %eax,0x4(%esp)
 5dc:	8b 45 08             	mov    0x8(%ebp),%eax
 5df:	89 04 24             	mov    %eax,(%esp)
 5e2:	e8 31 ff ff ff       	call   518 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 5e7:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 5eb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 5ef:	79 d9                	jns    5ca <printint+0x8a>
    putc(fd, buf[i]);
}
 5f1:	83 c4 30             	add    $0x30,%esp
 5f4:	5b                   	pop    %ebx
 5f5:	5e                   	pop    %esi
 5f6:	5d                   	pop    %ebp
 5f7:	c3                   	ret    

000005f8 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 5f8:	55                   	push   %ebp
 5f9:	89 e5                	mov    %esp,%ebp
 5fb:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 5fe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 605:	8d 45 0c             	lea    0xc(%ebp),%eax
 608:	83 c0 04             	add    $0x4,%eax
 60b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 60e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 615:	e9 7c 01 00 00       	jmp    796 <printf+0x19e>
    c = fmt[i] & 0xff;
 61a:	8b 55 0c             	mov    0xc(%ebp),%edx
 61d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 620:	01 d0                	add    %edx,%eax
 622:	0f b6 00             	movzbl (%eax),%eax
 625:	0f be c0             	movsbl %al,%eax
 628:	25 ff 00 00 00       	and    $0xff,%eax
 62d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 630:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 634:	75 2c                	jne    662 <printf+0x6a>
      if(c == '%'){
 636:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 63a:	75 0c                	jne    648 <printf+0x50>
        state = '%';
 63c:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 643:	e9 4a 01 00 00       	jmp    792 <printf+0x19a>
      } else {
        putc(fd, c);
 648:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 64b:	0f be c0             	movsbl %al,%eax
 64e:	89 44 24 04          	mov    %eax,0x4(%esp)
 652:	8b 45 08             	mov    0x8(%ebp),%eax
 655:	89 04 24             	mov    %eax,(%esp)
 658:	e8 bb fe ff ff       	call   518 <putc>
 65d:	e9 30 01 00 00       	jmp    792 <printf+0x19a>
      }
    } else if(state == '%'){
 662:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 666:	0f 85 26 01 00 00    	jne    792 <printf+0x19a>
      if(c == 'd'){
 66c:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 670:	75 2d                	jne    69f <printf+0xa7>
        printint(fd, *ap, 10, 1);
 672:	8b 45 e8             	mov    -0x18(%ebp),%eax
 675:	8b 00                	mov    (%eax),%eax
 677:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 67e:	00 
 67f:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 686:	00 
 687:	89 44 24 04          	mov    %eax,0x4(%esp)
 68b:	8b 45 08             	mov    0x8(%ebp),%eax
 68e:	89 04 24             	mov    %eax,(%esp)
 691:	e8 aa fe ff ff       	call   540 <printint>
        ap++;
 696:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 69a:	e9 ec 00 00 00       	jmp    78b <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 69f:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 6a3:	74 06                	je     6ab <printf+0xb3>
 6a5:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 6a9:	75 2d                	jne    6d8 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 6ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
 6ae:	8b 00                	mov    (%eax),%eax
 6b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 6b7:	00 
 6b8:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 6bf:	00 
 6c0:	89 44 24 04          	mov    %eax,0x4(%esp)
 6c4:	8b 45 08             	mov    0x8(%ebp),%eax
 6c7:	89 04 24             	mov    %eax,(%esp)
 6ca:	e8 71 fe ff ff       	call   540 <printint>
        ap++;
 6cf:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 6d3:	e9 b3 00 00 00       	jmp    78b <printf+0x193>
      } else if(c == 's'){
 6d8:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 6dc:	75 45                	jne    723 <printf+0x12b>
        s = (char*)*ap;
 6de:	8b 45 e8             	mov    -0x18(%ebp),%eax
 6e1:	8b 00                	mov    (%eax),%eax
 6e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 6e6:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 6ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 6ee:	75 09                	jne    6f9 <printf+0x101>
          s = "(null)";
 6f0:	c7 45 f4 81 0a 00 00 	movl   $0xa81,-0xc(%ebp)
        while(*s != 0){
 6f7:	eb 1e                	jmp    717 <printf+0x11f>
 6f9:	eb 1c                	jmp    717 <printf+0x11f>
          putc(fd, *s);
 6fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6fe:	0f b6 00             	movzbl (%eax),%eax
 701:	0f be c0             	movsbl %al,%eax
 704:	89 44 24 04          	mov    %eax,0x4(%esp)
 708:	8b 45 08             	mov    0x8(%ebp),%eax
 70b:	89 04 24             	mov    %eax,(%esp)
 70e:	e8 05 fe ff ff       	call   518 <putc>
          s++;
 713:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 717:	8b 45 f4             	mov    -0xc(%ebp),%eax
 71a:	0f b6 00             	movzbl (%eax),%eax
 71d:	84 c0                	test   %al,%al
 71f:	75 da                	jne    6fb <printf+0x103>
 721:	eb 68                	jmp    78b <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 723:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 727:	75 1d                	jne    746 <printf+0x14e>
        putc(fd, *ap);
 729:	8b 45 e8             	mov    -0x18(%ebp),%eax
 72c:	8b 00                	mov    (%eax),%eax
 72e:	0f be c0             	movsbl %al,%eax
 731:	89 44 24 04          	mov    %eax,0x4(%esp)
 735:	8b 45 08             	mov    0x8(%ebp),%eax
 738:	89 04 24             	mov    %eax,(%esp)
 73b:	e8 d8 fd ff ff       	call   518 <putc>
        ap++;
 740:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 744:	eb 45                	jmp    78b <printf+0x193>
      } else if(c == '%'){
 746:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 74a:	75 17                	jne    763 <printf+0x16b>
        putc(fd, c);
 74c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 74f:	0f be c0             	movsbl %al,%eax
 752:	89 44 24 04          	mov    %eax,0x4(%esp)
 756:	8b 45 08             	mov    0x8(%ebp),%eax
 759:	89 04 24             	mov    %eax,(%esp)
 75c:	e8 b7 fd ff ff       	call   518 <putc>
 761:	eb 28                	jmp    78b <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 763:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 76a:	00 
 76b:	8b 45 08             	mov    0x8(%ebp),%eax
 76e:	89 04 24             	mov    %eax,(%esp)
 771:	e8 a2 fd ff ff       	call   518 <putc>
        putc(fd, c);
 776:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 779:	0f be c0             	movsbl %al,%eax
 77c:	89 44 24 04          	mov    %eax,0x4(%esp)
 780:	8b 45 08             	mov    0x8(%ebp),%eax
 783:	89 04 24             	mov    %eax,(%esp)
 786:	e8 8d fd ff ff       	call   518 <putc>
      }
      state = 0;
 78b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 792:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 796:	8b 55 0c             	mov    0xc(%ebp),%edx
 799:	8b 45 f0             	mov    -0x10(%ebp),%eax
 79c:	01 d0                	add    %edx,%eax
 79e:	0f b6 00             	movzbl (%eax),%eax
 7a1:	84 c0                	test   %al,%al
 7a3:	0f 85 71 fe ff ff    	jne    61a <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 7a9:	c9                   	leave  
 7aa:	c3                   	ret    

000007ab <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ab:	55                   	push   %ebp
 7ac:	89 e5                	mov    %esp,%ebp
 7ae:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7b1:	8b 45 08             	mov    0x8(%ebp),%eax
 7b4:	83 e8 08             	sub    $0x8,%eax
 7b7:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ba:	a1 e8 0c 00 00       	mov    0xce8,%eax
 7bf:	89 45 fc             	mov    %eax,-0x4(%ebp)
 7c2:	eb 24                	jmp    7e8 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7c7:	8b 00                	mov    (%eax),%eax
 7c9:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 7cc:	77 12                	ja     7e0 <free+0x35>
 7ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7d1:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 7d4:	77 24                	ja     7fa <free+0x4f>
 7d6:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7d9:	8b 00                	mov    (%eax),%eax
 7db:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 7de:	77 1a                	ja     7fa <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7e3:	8b 00                	mov    (%eax),%eax
 7e5:	89 45 fc             	mov    %eax,-0x4(%ebp)
 7e8:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7eb:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 7ee:	76 d4                	jbe    7c4 <free+0x19>
 7f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7f3:	8b 00                	mov    (%eax),%eax
 7f5:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 7f8:	76 ca                	jbe    7c4 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 7fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7fd:	8b 40 04             	mov    0x4(%eax),%eax
 800:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 807:	8b 45 f8             	mov    -0x8(%ebp),%eax
 80a:	01 c2                	add    %eax,%edx
 80c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 80f:	8b 00                	mov    (%eax),%eax
 811:	39 c2                	cmp    %eax,%edx
 813:	75 24                	jne    839 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 815:	8b 45 f8             	mov    -0x8(%ebp),%eax
 818:	8b 50 04             	mov    0x4(%eax),%edx
 81b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 81e:	8b 00                	mov    (%eax),%eax
 820:	8b 40 04             	mov    0x4(%eax),%eax
 823:	01 c2                	add    %eax,%edx
 825:	8b 45 f8             	mov    -0x8(%ebp),%eax
 828:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 82b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 82e:	8b 00                	mov    (%eax),%eax
 830:	8b 10                	mov    (%eax),%edx
 832:	8b 45 f8             	mov    -0x8(%ebp),%eax
 835:	89 10                	mov    %edx,(%eax)
 837:	eb 0a                	jmp    843 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 839:	8b 45 fc             	mov    -0x4(%ebp),%eax
 83c:	8b 10                	mov    (%eax),%edx
 83e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 841:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 843:	8b 45 fc             	mov    -0x4(%ebp),%eax
 846:	8b 40 04             	mov    0x4(%eax),%eax
 849:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 850:	8b 45 fc             	mov    -0x4(%ebp),%eax
 853:	01 d0                	add    %edx,%eax
 855:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 858:	75 20                	jne    87a <free+0xcf>
    p->s.size += bp->s.size;
 85a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 85d:	8b 50 04             	mov    0x4(%eax),%edx
 860:	8b 45 f8             	mov    -0x8(%ebp),%eax
 863:	8b 40 04             	mov    0x4(%eax),%eax
 866:	01 c2                	add    %eax,%edx
 868:	8b 45 fc             	mov    -0x4(%ebp),%eax
 86b:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 86e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 871:	8b 10                	mov    (%eax),%edx
 873:	8b 45 fc             	mov    -0x4(%ebp),%eax
 876:	89 10                	mov    %edx,(%eax)
 878:	eb 08                	jmp    882 <free+0xd7>
  } else
    p->s.ptr = bp;
 87a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 87d:	8b 55 f8             	mov    -0x8(%ebp),%edx
 880:	89 10                	mov    %edx,(%eax)
  freep = p;
 882:	8b 45 fc             	mov    -0x4(%ebp),%eax
 885:	a3 e8 0c 00 00       	mov    %eax,0xce8
}
 88a:	c9                   	leave  
 88b:	c3                   	ret    

0000088c <morecore>:

static Header*
morecore(uint nu)
{
 88c:	55                   	push   %ebp
 88d:	89 e5                	mov    %esp,%ebp
 88f:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 892:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 899:	77 07                	ja     8a2 <morecore+0x16>
    nu = 4096;
 89b:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 8a2:	8b 45 08             	mov    0x8(%ebp),%eax
 8a5:	c1 e0 03             	shl    $0x3,%eax
 8a8:	89 04 24             	mov    %eax,(%esp)
 8ab:	e8 50 fc ff ff       	call   500 <sbrk>
 8b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 8b3:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 8b7:	75 07                	jne    8c0 <morecore+0x34>
    return 0;
 8b9:	b8 00 00 00 00       	mov    $0x0,%eax
 8be:	eb 22                	jmp    8e2 <morecore+0x56>
  hp = (Header*)p;
 8c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 8c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8c9:	8b 55 08             	mov    0x8(%ebp),%edx
 8cc:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 8cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8d2:	83 c0 08             	add    $0x8,%eax
 8d5:	89 04 24             	mov    %eax,(%esp)
 8d8:	e8 ce fe ff ff       	call   7ab <free>
  return freep;
 8dd:	a1 e8 0c 00 00       	mov    0xce8,%eax
}
 8e2:	c9                   	leave  
 8e3:	c3                   	ret    

000008e4 <malloc>:

void*
malloc(uint nbytes)
{
 8e4:	55                   	push   %ebp
 8e5:	89 e5                	mov    %esp,%ebp
 8e7:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8ea:	8b 45 08             	mov    0x8(%ebp),%eax
 8ed:	83 c0 07             	add    $0x7,%eax
 8f0:	c1 e8 03             	shr    $0x3,%eax
 8f3:	83 c0 01             	add    $0x1,%eax
 8f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 8f9:	a1 e8 0c 00 00       	mov    0xce8,%eax
 8fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
 901:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 905:	75 23                	jne    92a <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 907:	c7 45 f0 e0 0c 00 00 	movl   $0xce0,-0x10(%ebp)
 90e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 911:	a3 e8 0c 00 00       	mov    %eax,0xce8
 916:	a1 e8 0c 00 00       	mov    0xce8,%eax
 91b:	a3 e0 0c 00 00       	mov    %eax,0xce0
    base.s.size = 0;
 920:	c7 05 e4 0c 00 00 00 	movl   $0x0,0xce4
 927:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 92a:	8b 45 f0             	mov    -0x10(%ebp),%eax
 92d:	8b 00                	mov    (%eax),%eax
 92f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 932:	8b 45 f4             	mov    -0xc(%ebp),%eax
 935:	8b 40 04             	mov    0x4(%eax),%eax
 938:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 93b:	72 4d                	jb     98a <malloc+0xa6>
      if(p->s.size == nunits)
 93d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 940:	8b 40 04             	mov    0x4(%eax),%eax
 943:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 946:	75 0c                	jne    954 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 948:	8b 45 f4             	mov    -0xc(%ebp),%eax
 94b:	8b 10                	mov    (%eax),%edx
 94d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 950:	89 10                	mov    %edx,(%eax)
 952:	eb 26                	jmp    97a <malloc+0x96>
      else {
        p->s.size -= nunits;
 954:	8b 45 f4             	mov    -0xc(%ebp),%eax
 957:	8b 40 04             	mov    0x4(%eax),%eax
 95a:	2b 45 ec             	sub    -0x14(%ebp),%eax
 95d:	89 c2                	mov    %eax,%edx
 95f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 962:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 965:	8b 45 f4             	mov    -0xc(%ebp),%eax
 968:	8b 40 04             	mov    0x4(%eax),%eax
 96b:	c1 e0 03             	shl    $0x3,%eax
 96e:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 971:	8b 45 f4             	mov    -0xc(%ebp),%eax
 974:	8b 55 ec             	mov    -0x14(%ebp),%edx
 977:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 97a:	8b 45 f0             	mov    -0x10(%ebp),%eax
 97d:	a3 e8 0c 00 00       	mov    %eax,0xce8
      return (void*)(p + 1);
 982:	8b 45 f4             	mov    -0xc(%ebp),%eax
 985:	83 c0 08             	add    $0x8,%eax
 988:	eb 38                	jmp    9c2 <malloc+0xde>
    }
    if(p == freep)
 98a:	a1 e8 0c 00 00       	mov    0xce8,%eax
 98f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 992:	75 1b                	jne    9af <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 994:	8b 45 ec             	mov    -0x14(%ebp),%eax
 997:	89 04 24             	mov    %eax,(%esp)
 99a:	e8 ed fe ff ff       	call   88c <morecore>
 99f:	89 45 f4             	mov    %eax,-0xc(%ebp)
 9a2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 9a6:	75 07                	jne    9af <malloc+0xcb>
        return 0;
 9a8:	b8 00 00 00 00       	mov    $0x0,%eax
 9ad:	eb 13                	jmp    9c2 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9af:	8b 45 f4             	mov    -0xc(%ebp),%eax
 9b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
 9b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 9b8:	8b 00                	mov    (%eax),%eax
 9ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 9bd:	e9 70 ff ff ff       	jmp    932 <malloc+0x4e>
}
 9c2:	c9                   	leave  
 9c3:	c3                   	ret    
