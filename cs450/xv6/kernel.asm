
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 7b 36 10 80       	mov    $0x8010367b,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 c4 82 10 	movl   $0x801082c4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 bd 4c 00 00       	call   80104d0b <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 6a 4c 00 00       	call   80104d2c <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 85 4c 00 00       	call   80104d8e <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 3e 49 00 00       	call   80104a62 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 0d 4c 00 00       	call   80104d8e <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 cb 82 10 80 	movl   $0x801082cb,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 7f 28 00 00       	call   80102a57 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 dc 82 10 80 	movl   $0x801082dc,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 42 28 00 00       	call   80102a57 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 e3 82 10 80 	movl   $0x801082e3,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 eb 4a 00 00       	call   80104d2c <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 99 48 00 00       	call   80104b3b <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 e0 4a 00 00       	call   80104d8e <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 c1 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 6c 49 00 00       	call   80104d2c <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 ea 82 10 80 	movl   $0x801082ea,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 5a 03 00 00       	call   80100750 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec f3 82 10 80 	movl   $0x801082f3,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 84 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 56 48 00 00       	call   80104d8e <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 fa 82 10 80 	movl   $0x801082fa,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 09 83 10 80 	movl   $0x80108309,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 49 48 00 00       	call   80104ddd <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 0b 83 10 80 	movl   $0x8010830b,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x11c>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 98 49 00 00       	call   8010504f <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 90 10 80       	mov    0x80109000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 9a 48 00 00       	call   80104f80 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 d3 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 ba fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 a6 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 90 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 87 fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 8a 61 00 00       	call   80106905 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 7e 61 00 00       	call   80106905 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 72 61 00 00       	call   80106905 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 65 61 00 00       	call   80106905 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 1f fe ff ff       	call   801005ca <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 6d 45 00 00       	call   80104d2c <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 37 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 64                	je     8010083a <consoleintr+0x8d>
801007d6:	e9 91 00 00 00       	jmp    8010086c <consoleintr+0xbf>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 55                	je     8010083a <consoleintr+0x8d>
801007e5:	e9 82 00 00 00       	jmp    8010086c <consoleintr+0xbf>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 ef 43 00 00       	call   80104bde <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100831:	3c 0a                	cmp    $0xa,%al
80100833:	75 bf                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100835:	e9 c1 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083a:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100840:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 5c de 10 80       	mov    0x8010de5c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100856:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010085d:	e8 ee fe ff ff       	call   80100750 <consputc>
      }
      break;
80100862:	e9 94 00 00 00       	jmp    801008fb <consoleintr+0x14e>
80100867:	e9 8f 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100870:	0f 84 84 00 00 00    	je     801008fa <consoleintr+0x14d>
80100876:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087c:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100881:	29 c2                	sub    %eax,%edx
80100883:	89 d0                	mov    %edx,%eax
80100885:	83 f8 7f             	cmp    $0x7f,%eax
80100888:	77 70                	ja     801008fa <consoleintr+0x14d>
        c = (c == '\r') ? '\n' : c;
8010088a:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010088e:	74 05                	je     80100895 <consoleintr+0xe8>
80100890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100893:	eb 05                	jmp    8010089a <consoleintr+0xed>
80100895:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
8010089d:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 5c de 10 80    	mov    %edx,0x8010de5c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 d4 dd 10 80    	mov    %al,-0x7fef222c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d5:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008e7:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008ec:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f3:	e8 43 42 00 00       	call   80104b3b <wakeup>
        }
      }
      break;
801008f8:	eb 00                	jmp    801008fa <consoleintr+0x14d>
801008fa:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
801008fb:	8b 45 08             	mov    0x8(%ebp),%eax
801008fe:	ff d0                	call   *%eax
80100900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100907:	0f 89 b7 fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
8010090d:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100914:	e8 75 44 00 00       	call   80104d8e <release>
}
80100919:	c9                   	leave  
8010091a:	c3                   	ret    

8010091b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010091b:	55                   	push   %ebp
8010091c:	89 e5                	mov    %esp,%ebp
8010091e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100921:	8b 45 08             	mov    0x8(%ebp),%eax
80100924:	89 04 24             	mov    %eax,(%esp)
80100927:	e8 69 10 00 00       	call   80101995 <iunlock>
  target = n;
8010092c:	8b 45 10             	mov    0x10(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100939:	e8 ee 43 00 00       	call   80104d2c <acquire>
  while(n > 0){
8010093e:	e9 aa 00 00 00       	jmp    801009ed <consoleread+0xd2>
    while(input.r == input.w){
80100943:	eb 42                	jmp    80100987 <consoleread+0x6c>
      if(proc->killed){
80100945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010094b:	8b 40 24             	mov    0x24(%eax),%eax
8010094e:	85 c0                	test   %eax,%eax
80100950:	74 21                	je     80100973 <consoleread+0x58>
        release(&input.lock);
80100952:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100959:	e8 30 44 00 00       	call   80104d8e <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 de 0e 00 00       	call   80101847 <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
80100982:	e8 db 40 00 00       	call   80104a62 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
8010098d:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 54 de 10 80       	mov    0x8010de54,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 54 de 10 80    	mov    %edx,0x8010de54
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
801009ae:	0f be c0             	movsbl %al,%eax
801009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009b4:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009b8:	75 19                	jne    801009d3 <consoleread+0xb8>
      if(n < target){
801009ba:	8b 45 10             	mov    0x10(%ebp),%eax
801009bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009c0:	73 0f                	jae    801009d1 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009c2:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009cf:	eb 26                	jmp    801009f7 <consoleread+0xdc>
801009d1:	eb 24                	jmp    801009f7 <consoleread+0xdc>
    }
    *dst++ = c;
801009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801009d6:	8d 50 01             	lea    0x1(%eax),%edx
801009d9:	89 55 0c             	mov    %edx,0xc(%ebp)
801009dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801009df:	88 10                	mov    %dl,(%eax)
    --n;
801009e1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009e5:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009e9:	75 02                	jne    801009ed <consoleread+0xd2>
      break;
801009eb:	eb 0a                	jmp    801009f7 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009ed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f1:	0f 8f 4c ff ff ff    	jg     80100943 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
801009f7:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801009fe:	e8 8b 43 00 00       	call   80104d8e <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 39 0e 00 00       	call   80101847 <ilock>

  return target - n;
80100a0e:	8b 45 10             	mov    0x10(%ebp),%eax
80100a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a14:	29 c2                	sub    %eax,%edx
80100a16:	89 d0                	mov    %edx,%eax
}
80100a18:	c9                   	leave  
80100a19:	c3                   	ret    

80100a1a <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a1a:	55                   	push   %ebp
80100a1b:	89 e5                	mov    %esp,%ebp
80100a1d:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a20:	8b 45 08             	mov    0x8(%ebp),%eax
80100a23:	89 04 24             	mov    %eax,(%esp)
80100a26:	e8 6a 0f 00 00       	call   80101995 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a32:	e8 f5 42 00 00       	call   80104d2c <acquire>
  for(i = 0; i < n; i++)
80100a37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a3e:	eb 1d                	jmp    80100a5d <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a46:	01 d0                	add    %edx,%eax
80100a48:	0f b6 00             	movzbl (%eax),%eax
80100a4b:	0f be c0             	movsbl %al,%eax
80100a4e:	0f b6 c0             	movzbl %al,%eax
80100a51:	89 04 24             	mov    %eax,(%esp)
80100a54:	e8 f7 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a60:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a63:	7c db                	jl     80100a40 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a65:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a6c:	e8 1d 43 00 00       	call   80104d8e <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 cb 0d 00 00       	call   80101847 <ilock>

  return n;
80100a7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a7f:	c9                   	leave  
80100a80:	c3                   	ret    

80100a81 <consoleinit>:

void
consoleinit(void)
{
80100a81:	55                   	push   %ebp
80100a82:	89 e5                	mov    %esp,%ebp
80100a84:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a87:	c7 44 24 04 0f 83 10 	movl   $0x8010830f,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a96:	e8 70 42 00 00       	call   80104d0b <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 17 83 10 	movl   $0x80108317,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100aaa:	e8 5c 42 00 00       	call   80104d0b <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 0c e8 10 80 1a 	movl   $0x80100a1a,0x8010e80c
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 08 e8 10 80 1b 	movl   $0x8010091b,0x8010e808
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 3f 32 00 00       	call   80103d18 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 26 21 00 00       	call   80102c13 <ioapicenable>
}
80100aed:	c9                   	leave  
80100aee:	c3                   	ret    

80100aef <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100aef:	55                   	push   %ebp
80100af0:	89 e5                	mov    %esp,%ebp
80100af2:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100af8:	8b 45 08             	mov    0x8(%ebp),%eax
80100afb:	89 04 24             	mov    %eax,(%esp)
80100afe:	e8 b9 1b 00 00       	call   801026bc <namei>
80100b03:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b06:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b0a:	75 0a                	jne    80100b16 <exec+0x27>
    return -1;
80100b0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b11:	e9 de 03 00 00       	jmp    80100ef4 <exec+0x405>
  ilock(ip);
80100b16:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b19:	89 04 24             	mov    %eax,(%esp)
80100b1c:	e8 26 0d 00 00       	call   80101847 <ilock>
  pgdir = 0;
80100b21:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b28:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b2f:	00 
80100b30:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b37:	00 
80100b38:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b42:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b45:	89 04 24             	mov    %eax,(%esp)
80100b48:	e8 d1 14 00 00       	call   8010201e <readi>
80100b4d:	83 f8 33             	cmp    $0x33,%eax
80100b50:	77 05                	ja     80100b57 <exec+0x68>
    goto bad;
80100b52:	e9 76 03 00 00       	jmp    80100ecd <exec+0x3de>
  if(elf.magic != ELF_MAGIC)
80100b57:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b5d:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b62:	74 05                	je     80100b69 <exec+0x7a>
    goto bad;
80100b64:	e9 64 03 00 00       	jmp    80100ecd <exec+0x3de>

  if((pgdir = setupkvm()) == 0)
80100b69:	e8 e8 6e 00 00       	call   80107a56 <setupkvm>
80100b6e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b71:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b75:	75 05                	jne    80100b7c <exec+0x8d>
    goto bad;
80100b77:	e9 51 03 00 00       	jmp    80100ecd <exec+0x3de>

  // Load program into memory.
  sz = 0;
80100b7c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b83:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b8a:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b90:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b93:	e9 cb 00 00 00       	jmp    80100c63 <exec+0x174>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100b98:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100b9b:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100ba2:	00 
80100ba3:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ba7:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bad:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bb1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bb4:	89 04 24             	mov    %eax,(%esp)
80100bb7:	e8 62 14 00 00       	call   8010201e <readi>
80100bbc:	83 f8 20             	cmp    $0x20,%eax
80100bbf:	74 05                	je     80100bc6 <exec+0xd7>
      goto bad;
80100bc1:	e9 07 03 00 00       	jmp    80100ecd <exec+0x3de>
    if(ph.type != ELF_PROG_LOAD)
80100bc6:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bcc:	83 f8 01             	cmp    $0x1,%eax
80100bcf:	74 05                	je     80100bd6 <exec+0xe7>
      continue;
80100bd1:	e9 80 00 00 00       	jmp    80100c56 <exec+0x167>
    if(ph.memsz < ph.filesz)
80100bd6:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100bdc:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100be2:	39 c2                	cmp    %eax,%edx
80100be4:	73 05                	jae    80100beb <exec+0xfc>
      goto bad;
80100be6:	e9 e2 02 00 00       	jmp    80100ecd <exec+0x3de>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100beb:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bf1:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100bf7:	01 d0                	add    %edx,%eax
80100bf9:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bfd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c00:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c07:	89 04 24             	mov    %eax,(%esp)
80100c0a:	e8 15 72 00 00       	call   80107e24 <allocuvm>
80100c0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c12:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c16:	75 05                	jne    80100c1d <exec+0x12e>
      goto bad;
80100c18:	e9 b0 02 00 00       	jmp    80100ecd <exec+0x3de>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c1d:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c23:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c29:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c2f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c33:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c37:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c3a:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c45:	89 04 24             	mov    %eax,(%esp)
80100c48:	e8 ec 70 00 00       	call   80107d39 <loaduvm>
80100c4d:	85 c0                	test   %eax,%eax
80100c4f:	79 05                	jns    80100c56 <exec+0x167>
      goto bad;
80100c51:	e9 77 02 00 00       	jmp    80100ecd <exec+0x3de>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c56:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c5a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c5d:	83 c0 20             	add    $0x20,%eax
80100c60:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c63:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c6a:	0f b7 c0             	movzwl %ax,%eax
80100c6d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c70:	0f 8f 22 ff ff ff    	jg     80100b98 <exec+0xa9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c76:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c79:	89 04 24             	mov    %eax,(%esp)
80100c7c:	e8 4a 0e 00 00       	call   80101acb <iunlockput>
  ip = 0;
80100c81:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c88:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c8b:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100c95:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100c98:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c9b:	05 00 20 00 00       	add    $0x2000,%eax
80100ca0:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ca4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cae:	89 04 24             	mov    %eax,(%esp)
80100cb1:	e8 6e 71 00 00       	call   80107e24 <allocuvm>
80100cb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cb9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cbd:	75 05                	jne    80100cc4 <exec+0x1d5>
    goto bad;
80100cbf:	e9 09 02 00 00       	jmp    80100ecd <exec+0x3de>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc7:	2d 00 20 00 00       	sub    $0x2000,%eax
80100ccc:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cd3:	89 04 24             	mov    %eax,(%esp)
80100cd6:	e8 79 73 00 00       	call   80108054 <clearpteu>
  sp = sz;
80100cdb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cde:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ce1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100ce8:	e9 9a 00 00 00       	jmp    80100d87 <exec+0x298>
    if(argc >= MAXARG)
80100ced:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100cf1:	76 05                	jbe    80100cf8 <exec+0x209>
      goto bad;
80100cf3:	e9 d5 01 00 00       	jmp    80100ecd <exec+0x3de>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100cf8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100cfb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d02:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d05:	01 d0                	add    %edx,%eax
80100d07:	8b 00                	mov    (%eax),%eax
80100d09:	89 04 24             	mov    %eax,(%esp)
80100d0c:	e8 d9 44 00 00       	call   801051ea <strlen>
80100d11:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d14:	29 c2                	sub    %eax,%edx
80100d16:	89 d0                	mov    %edx,%eax
80100d18:	83 e8 01             	sub    $0x1,%eax
80100d1b:	83 e0 fc             	and    $0xfffffffc,%eax
80100d1e:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d24:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d2e:	01 d0                	add    %edx,%eax
80100d30:	8b 00                	mov    (%eax),%eax
80100d32:	89 04 24             	mov    %eax,(%esp)
80100d35:	e8 b0 44 00 00       	call   801051ea <strlen>
80100d3a:	83 c0 01             	add    $0x1,%eax
80100d3d:	89 c2                	mov    %eax,%edx
80100d3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d42:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d49:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d4c:	01 c8                	add    %ecx,%eax
80100d4e:	8b 00                	mov    (%eax),%eax
80100d50:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d54:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d58:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d5f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d62:	89 04 24             	mov    %eax,(%esp)
80100d65:	e8 af 74 00 00       	call   80108219 <copyout>
80100d6a:	85 c0                	test   %eax,%eax
80100d6c:	79 05                	jns    80100d73 <exec+0x284>
      goto bad;
80100d6e:	e9 5a 01 00 00       	jmp    80100ecd <exec+0x3de>
    ustack[3+argc] = sp;
80100d73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d76:	8d 50 03             	lea    0x3(%eax),%edx
80100d79:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d7c:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d83:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d8a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d91:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d94:	01 d0                	add    %edx,%eax
80100d96:	8b 00                	mov    (%eax),%eax
80100d98:	85 c0                	test   %eax,%eax
80100d9a:	0f 85 4d ff ff ff    	jne    80100ced <exec+0x1fe>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100da0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da3:	83 c0 03             	add    $0x3,%eax
80100da6:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dad:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100db1:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100db8:	ff ff ff 
  ustack[1] = argc;
80100dbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbe:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dc7:	83 c0 01             	add    $0x1,%eax
80100dca:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dd1:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dd4:	29 d0                	sub    %edx,%eax
80100dd6:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100ddc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ddf:	83 c0 04             	add    $0x4,%eax
80100de2:	c1 e0 02             	shl    $0x2,%eax
80100de5:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100deb:	83 c0 04             	add    $0x4,%eax
80100dee:	c1 e0 02             	shl    $0x2,%eax
80100df1:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100df5:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100dfb:	89 44 24 08          	mov    %eax,0x8(%esp)
80100dff:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e02:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e09:	89 04 24             	mov    %eax,(%esp)
80100e0c:	e8 08 74 00 00       	call   80108219 <copyout>
80100e11:	85 c0                	test   %eax,%eax
80100e13:	79 05                	jns    80100e1a <exec+0x32b>
    goto bad;
80100e15:	e9 b3 00 00 00       	jmp    80100ecd <exec+0x3de>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e1a:	8b 45 08             	mov    0x8(%ebp),%eax
80100e1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e23:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e26:	eb 17                	jmp    80100e3f <exec+0x350>
    if(*s == '/')
80100e28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e2b:	0f b6 00             	movzbl (%eax),%eax
80100e2e:	3c 2f                	cmp    $0x2f,%al
80100e30:	75 09                	jne    80100e3b <exec+0x34c>
      last = s+1;
80100e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e35:	83 c0 01             	add    $0x1,%eax
80100e38:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e3b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e42:	0f b6 00             	movzbl (%eax),%eax
80100e45:	84 c0                	test   %al,%al
80100e47:	75 df                	jne    80100e28 <exec+0x339>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e49:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e4f:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e52:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e59:	00 
80100e5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e61:	89 14 24             	mov    %edx,(%esp)
80100e64:	e8 37 43 00 00       	call   801051a0 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e6f:	8b 40 04             	mov    0x4(%eax),%eax
80100e72:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e75:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e7e:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e87:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e8a:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e8c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e92:	8b 40 18             	mov    0x18(%eax),%eax
80100e95:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100e9b:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100e9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea4:	8b 40 18             	mov    0x18(%eax),%eax
80100ea7:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eaa:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ead:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb3:	89 04 24             	mov    %eax,(%esp)
80100eb6:	e8 8c 6c 00 00       	call   80107b47 <switchuvm>
  freevm(oldpgdir);
80100ebb:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ebe:	89 04 24             	mov    %eax,(%esp)
80100ec1:	e8 f4 70 00 00       	call   80107fba <freevm>
  return 0;
80100ec6:	b8 00 00 00 00       	mov    $0x0,%eax
80100ecb:	eb 27                	jmp    80100ef4 <exec+0x405>

 bad:
  if(pgdir)
80100ecd:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ed1:	74 0b                	je     80100ede <exec+0x3ef>
    freevm(pgdir);
80100ed3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ed6:	89 04 24             	mov    %eax,(%esp)
80100ed9:	e8 dc 70 00 00       	call   80107fba <freevm>
  if(ip)
80100ede:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ee2:	74 0b                	je     80100eef <exec+0x400>
    iunlockput(ip);
80100ee4:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ee7:	89 04 24             	mov    %eax,(%esp)
80100eea:	e8 dc 0b 00 00       	call   80101acb <iunlockput>
  return -1;
80100eef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100ef4:	c9                   	leave  
80100ef5:	c3                   	ret    

80100ef6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100ef6:	55                   	push   %ebp
80100ef7:	89 e5                	mov    %esp,%ebp
80100ef9:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100efc:	c7 44 24 04 1d 83 10 	movl   $0x8010831d,0x4(%esp)
80100f03:	80 
80100f04:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f0b:	e8 fb 3d 00 00       	call   80104d0b <initlock>
}
80100f10:	c9                   	leave  
80100f11:	c3                   	ret    

80100f12 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f12:	55                   	push   %ebp
80100f13:	89 e5                	mov    %esp,%ebp
80100f15:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f18:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f1f:	e8 08 3e 00 00       	call   80104d2c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f24:	c7 45 f4 94 de 10 80 	movl   $0x8010de94,-0xc(%ebp)
80100f2b:	eb 29                	jmp    80100f56 <filealloc+0x44>
    if(f->ref == 0){
80100f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f30:	8b 40 04             	mov    0x4(%eax),%eax
80100f33:	85 c0                	test   %eax,%eax
80100f35:	75 1b                	jne    80100f52 <filealloc+0x40>
      f->ref = 1;
80100f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f3a:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f41:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f48:	e8 41 3e 00 00       	call   80104d8e <release>
      return f;
80100f4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f50:	eb 1e                	jmp    80100f70 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f52:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f56:	81 7d f4 f4 e7 10 80 	cmpl   $0x8010e7f4,-0xc(%ebp)
80100f5d:	72 ce                	jb     80100f2d <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f5f:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f66:	e8 23 3e 00 00       	call   80104d8e <release>
  return 0;
80100f6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f70:	c9                   	leave  
80100f71:	c3                   	ret    

80100f72 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f72:	55                   	push   %ebp
80100f73:	89 e5                	mov    %esp,%ebp
80100f75:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f78:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f7f:	e8 a8 3d 00 00       	call   80104d2c <acquire>
  if(f->ref < 1)
80100f84:	8b 45 08             	mov    0x8(%ebp),%eax
80100f87:	8b 40 04             	mov    0x4(%eax),%eax
80100f8a:	85 c0                	test   %eax,%eax
80100f8c:	7f 0c                	jg     80100f9a <filedup+0x28>
    panic("filedup");
80100f8e:	c7 04 24 24 83 10 80 	movl   $0x80108324,(%esp)
80100f95:	e8 a0 f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9d:	8b 40 04             	mov    0x4(%eax),%eax
80100fa0:	8d 50 01             	lea    0x1(%eax),%edx
80100fa3:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa6:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fa9:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fb0:	e8 d9 3d 00 00       	call   80104d8e <release>
  return f;
80100fb5:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fb8:	c9                   	leave  
80100fb9:	c3                   	ret    

80100fba <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fba:	55                   	push   %ebp
80100fbb:	89 e5                	mov    %esp,%ebp
80100fbd:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fc0:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fc7:	e8 60 3d 00 00       	call   80104d2c <acquire>
  if(f->ref < 1)
80100fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80100fcf:	8b 40 04             	mov    0x4(%eax),%eax
80100fd2:	85 c0                	test   %eax,%eax
80100fd4:	7f 0c                	jg     80100fe2 <fileclose+0x28>
    panic("fileclose");
80100fd6:	c7 04 24 2c 83 10 80 	movl   $0x8010832c,(%esp)
80100fdd:	e8 58 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80100fe2:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe5:	8b 40 04             	mov    0x4(%eax),%eax
80100fe8:	8d 50 ff             	lea    -0x1(%eax),%edx
80100feb:	8b 45 08             	mov    0x8(%ebp),%eax
80100fee:	89 50 04             	mov    %edx,0x4(%eax)
80100ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff4:	8b 40 04             	mov    0x4(%eax),%eax
80100ff7:	85 c0                	test   %eax,%eax
80100ff9:	7e 11                	jle    8010100c <fileclose+0x52>
    release(&ftable.lock);
80100ffb:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80101002:	e8 87 3d 00 00       	call   80104d8e <release>
80101007:	e9 82 00 00 00       	jmp    8010108e <fileclose+0xd4>
    return;
  }
  ff = *f;
8010100c:	8b 45 08             	mov    0x8(%ebp),%eax
8010100f:	8b 10                	mov    (%eax),%edx
80101011:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101014:	8b 50 04             	mov    0x4(%eax),%edx
80101017:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010101a:	8b 50 08             	mov    0x8(%eax),%edx
8010101d:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101020:	8b 50 0c             	mov    0xc(%eax),%edx
80101023:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101026:	8b 50 10             	mov    0x10(%eax),%edx
80101029:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010102c:	8b 40 14             	mov    0x14(%eax),%eax
8010102f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101032:	8b 45 08             	mov    0x8(%ebp),%eax
80101035:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010103c:	8b 45 08             	mov    0x8(%ebp),%eax
8010103f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101045:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
8010104c:	e8 3d 3d 00 00       	call   80104d8e <release>
  
  if(ff.type == FD_PIPE)
80101051:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101054:	83 f8 01             	cmp    $0x1,%eax
80101057:	75 18                	jne    80101071 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101059:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010105d:	0f be d0             	movsbl %al,%edx
80101060:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101063:	89 54 24 04          	mov    %edx,0x4(%esp)
80101067:	89 04 24             	mov    %eax,(%esp)
8010106a:	e8 59 2f 00 00       	call   80103fc8 <pipeclose>
8010106f:	eb 1d                	jmp    8010108e <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101071:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101074:	83 f8 02             	cmp    $0x2,%eax
80101077:	75 15                	jne    8010108e <fileclose+0xd4>
    begin_trans();
80101079:	e8 1d 24 00 00       	call   8010349b <begin_trans>
    iput(ff.ip);
8010107e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101081:	89 04 24             	mov    %eax,(%esp)
80101084:	e8 71 09 00 00       	call   801019fa <iput>
    commit_trans();
80101089:	e8 56 24 00 00       	call   801034e4 <commit_trans>
  }
}
8010108e:	c9                   	leave  
8010108f:	c3                   	ret    

80101090 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101090:	55                   	push   %ebp
80101091:	89 e5                	mov    %esp,%ebp
80101093:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101096:	8b 45 08             	mov    0x8(%ebp),%eax
80101099:	8b 00                	mov    (%eax),%eax
8010109b:	83 f8 02             	cmp    $0x2,%eax
8010109e:	75 38                	jne    801010d8 <filestat+0x48>
    ilock(f->ip);
801010a0:	8b 45 08             	mov    0x8(%ebp),%eax
801010a3:	8b 40 10             	mov    0x10(%eax),%eax
801010a6:	89 04 24             	mov    %eax,(%esp)
801010a9:	e8 99 07 00 00       	call   80101847 <ilock>
    stati(f->ip, st);
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 10             	mov    0x10(%eax),%eax
801010b4:	8b 55 0c             	mov    0xc(%ebp),%edx
801010b7:	89 54 24 04          	mov    %edx,0x4(%esp)
801010bb:	89 04 24             	mov    %eax,(%esp)
801010be:	e8 16 0f 00 00       	call   80101fd9 <stati>
    iunlock(f->ip);
801010c3:	8b 45 08             	mov    0x8(%ebp),%eax
801010c6:	8b 40 10             	mov    0x10(%eax),%eax
801010c9:	89 04 24             	mov    %eax,(%esp)
801010cc:	e8 c4 08 00 00       	call   80101995 <iunlock>
    return 0;
801010d1:	b8 00 00 00 00       	mov    $0x0,%eax
801010d6:	eb 05                	jmp    801010dd <filestat+0x4d>
  }
  return -1;
801010d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010dd:	c9                   	leave  
801010de:	c3                   	ret    

801010df <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010df:	55                   	push   %ebp
801010e0:	89 e5                	mov    %esp,%ebp
801010e2:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010e5:	8b 45 08             	mov    0x8(%ebp),%eax
801010e8:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801010ec:	84 c0                	test   %al,%al
801010ee:	75 0a                	jne    801010fa <fileread+0x1b>
    return -1;
801010f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010f5:	e9 9f 00 00 00       	jmp    80101199 <fileread+0xba>
  if(f->type == FD_PIPE)
801010fa:	8b 45 08             	mov    0x8(%ebp),%eax
801010fd:	8b 00                	mov    (%eax),%eax
801010ff:	83 f8 01             	cmp    $0x1,%eax
80101102:	75 1e                	jne    80101122 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101104:	8b 45 08             	mov    0x8(%ebp),%eax
80101107:	8b 40 0c             	mov    0xc(%eax),%eax
8010110a:	8b 55 10             	mov    0x10(%ebp),%edx
8010110d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101111:	8b 55 0c             	mov    0xc(%ebp),%edx
80101114:	89 54 24 04          	mov    %edx,0x4(%esp)
80101118:	89 04 24             	mov    %eax,(%esp)
8010111b:	e8 29 30 00 00       	call   80104149 <piperead>
80101120:	eb 77                	jmp    80101199 <fileread+0xba>
  if(f->type == FD_INODE){
80101122:	8b 45 08             	mov    0x8(%ebp),%eax
80101125:	8b 00                	mov    (%eax),%eax
80101127:	83 f8 02             	cmp    $0x2,%eax
8010112a:	75 61                	jne    8010118d <fileread+0xae>
    ilock(f->ip);
8010112c:	8b 45 08             	mov    0x8(%ebp),%eax
8010112f:	8b 40 10             	mov    0x10(%eax),%eax
80101132:	89 04 24             	mov    %eax,(%esp)
80101135:	e8 0d 07 00 00       	call   80101847 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010113a:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010113d:	8b 45 08             	mov    0x8(%ebp),%eax
80101140:	8b 50 14             	mov    0x14(%eax),%edx
80101143:	8b 45 08             	mov    0x8(%ebp),%eax
80101146:	8b 40 10             	mov    0x10(%eax),%eax
80101149:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010114d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101151:	8b 55 0c             	mov    0xc(%ebp),%edx
80101154:	89 54 24 04          	mov    %edx,0x4(%esp)
80101158:	89 04 24             	mov    %eax,(%esp)
8010115b:	e8 be 0e 00 00       	call   8010201e <readi>
80101160:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101163:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101167:	7e 11                	jle    8010117a <fileread+0x9b>
      f->off += r;
80101169:	8b 45 08             	mov    0x8(%ebp),%eax
8010116c:	8b 50 14             	mov    0x14(%eax),%edx
8010116f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101172:	01 c2                	add    %eax,%edx
80101174:	8b 45 08             	mov    0x8(%ebp),%eax
80101177:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010117a:	8b 45 08             	mov    0x8(%ebp),%eax
8010117d:	8b 40 10             	mov    0x10(%eax),%eax
80101180:	89 04 24             	mov    %eax,(%esp)
80101183:	e8 0d 08 00 00       	call   80101995 <iunlock>
    return r;
80101188:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010118b:	eb 0c                	jmp    80101199 <fileread+0xba>
  }
  panic("fileread");
8010118d:	c7 04 24 36 83 10 80 	movl   $0x80108336,(%esp)
80101194:	e8 a1 f3 ff ff       	call   8010053a <panic>
}
80101199:	c9                   	leave  
8010119a:	c3                   	ret    

8010119b <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
8010119b:	55                   	push   %ebp
8010119c:	89 e5                	mov    %esp,%ebp
8010119e:	53                   	push   %ebx
8010119f:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011a2:	8b 45 08             	mov    0x8(%ebp),%eax
801011a5:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011a9:	84 c0                	test   %al,%al
801011ab:	75 0a                	jne    801011b7 <filewrite+0x1c>
    return -1;
801011ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011b2:	e9 20 01 00 00       	jmp    801012d7 <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011b7:	8b 45 08             	mov    0x8(%ebp),%eax
801011ba:	8b 00                	mov    (%eax),%eax
801011bc:	83 f8 01             	cmp    $0x1,%eax
801011bf:	75 21                	jne    801011e2 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011c1:	8b 45 08             	mov    0x8(%ebp),%eax
801011c4:	8b 40 0c             	mov    0xc(%eax),%eax
801011c7:	8b 55 10             	mov    0x10(%ebp),%edx
801011ca:	89 54 24 08          	mov    %edx,0x8(%esp)
801011ce:	8b 55 0c             	mov    0xc(%ebp),%edx
801011d1:	89 54 24 04          	mov    %edx,0x4(%esp)
801011d5:	89 04 24             	mov    %eax,(%esp)
801011d8:	e8 7d 2e 00 00       	call   8010405a <pipewrite>
801011dd:	e9 f5 00 00 00       	jmp    801012d7 <filewrite+0x13c>
  if(f->type == FD_INODE){
801011e2:	8b 45 08             	mov    0x8(%ebp),%eax
801011e5:	8b 00                	mov    (%eax),%eax
801011e7:	83 f8 02             	cmp    $0x2,%eax
801011ea:	0f 85 db 00 00 00    	jne    801012cb <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801011f0:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
801011f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
801011fe:	e9 a8 00 00 00       	jmp    801012ab <filewrite+0x110>
      int n1 = n - i;
80101203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101206:	8b 55 10             	mov    0x10(%ebp),%edx
80101209:	29 c2                	sub    %eax,%edx
8010120b:	89 d0                	mov    %edx,%eax
8010120d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101210:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101213:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101216:	7e 06                	jle    8010121e <filewrite+0x83>
        n1 = max;
80101218:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010121b:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010121e:	e8 78 22 00 00       	call   8010349b <begin_trans>
      ilock(f->ip);
80101223:	8b 45 08             	mov    0x8(%ebp),%eax
80101226:	8b 40 10             	mov    0x10(%eax),%eax
80101229:	89 04 24             	mov    %eax,(%esp)
8010122c:	e8 16 06 00 00       	call   80101847 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101231:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101234:	8b 45 08             	mov    0x8(%ebp),%eax
80101237:	8b 50 14             	mov    0x14(%eax),%edx
8010123a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010123d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101240:	01 c3                	add    %eax,%ebx
80101242:	8b 45 08             	mov    0x8(%ebp),%eax
80101245:	8b 40 10             	mov    0x10(%eax),%eax
80101248:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010124c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101250:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101254:	89 04 24             	mov    %eax,(%esp)
80101257:	e8 26 0f 00 00       	call   80102182 <writei>
8010125c:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010125f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101263:	7e 11                	jle    80101276 <filewrite+0xdb>
        f->off += r;
80101265:	8b 45 08             	mov    0x8(%ebp),%eax
80101268:	8b 50 14             	mov    0x14(%eax),%edx
8010126b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010126e:	01 c2                	add    %eax,%edx
80101270:	8b 45 08             	mov    0x8(%ebp),%eax
80101273:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101276:	8b 45 08             	mov    0x8(%ebp),%eax
80101279:	8b 40 10             	mov    0x10(%eax),%eax
8010127c:	89 04 24             	mov    %eax,(%esp)
8010127f:	e8 11 07 00 00       	call   80101995 <iunlock>
      commit_trans();
80101284:	e8 5b 22 00 00       	call   801034e4 <commit_trans>

      if(r < 0)
80101289:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010128d:	79 02                	jns    80101291 <filewrite+0xf6>
        break;
8010128f:	eb 26                	jmp    801012b7 <filewrite+0x11c>
      if(r != n1)
80101291:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101294:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101297:	74 0c                	je     801012a5 <filewrite+0x10a>
        panic("short filewrite");
80101299:	c7 04 24 3f 83 10 80 	movl   $0x8010833f,(%esp)
801012a0:	e8 95 f2 ff ff       	call   8010053a <panic>
      i += r;
801012a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a8:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ae:	3b 45 10             	cmp    0x10(%ebp),%eax
801012b1:	0f 8c 4c ff ff ff    	jl     80101203 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ba:	3b 45 10             	cmp    0x10(%ebp),%eax
801012bd:	75 05                	jne    801012c4 <filewrite+0x129>
801012bf:	8b 45 10             	mov    0x10(%ebp),%eax
801012c2:	eb 05                	jmp    801012c9 <filewrite+0x12e>
801012c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012c9:	eb 0c                	jmp    801012d7 <filewrite+0x13c>
  }
  panic("filewrite");
801012cb:	c7 04 24 4f 83 10 80 	movl   $0x8010834f,(%esp)
801012d2:	e8 63 f2 ff ff       	call   8010053a <panic>
}
801012d7:	83 c4 24             	add    $0x24,%esp
801012da:	5b                   	pop    %ebx
801012db:	5d                   	pop    %ebp
801012dc:	c3                   	ret    

801012dd <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012dd:	55                   	push   %ebp
801012de:	89 e5                	mov    %esp,%ebp
801012e0:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012e3:	8b 45 08             	mov    0x8(%ebp),%eax
801012e6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801012ed:	00 
801012ee:	89 04 24             	mov    %eax,(%esp)
801012f1:	e8 b0 ee ff ff       	call   801001a6 <bread>
801012f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801012f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012fc:	83 c0 18             	add    $0x18,%eax
801012ff:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101306:	00 
80101307:	89 44 24 04          	mov    %eax,0x4(%esp)
8010130b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010130e:	89 04 24             	mov    %eax,(%esp)
80101311:	e8 39 3d 00 00       	call   8010504f <memmove>
  brelse(bp);
80101316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101319:	89 04 24             	mov    %eax,(%esp)
8010131c:	e8 f6 ee ff ff       	call   80100217 <brelse>
}
80101321:	c9                   	leave  
80101322:	c3                   	ret    

80101323 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101323:	55                   	push   %ebp
80101324:	89 e5                	mov    %esp,%ebp
80101326:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101329:	8b 55 0c             	mov    0xc(%ebp),%edx
8010132c:	8b 45 08             	mov    0x8(%ebp),%eax
8010132f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101333:	89 04 24             	mov    %eax,(%esp)
80101336:	e8 6b ee ff ff       	call   801001a6 <bread>
8010133b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010133e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101341:	83 c0 18             	add    $0x18,%eax
80101344:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010134b:	00 
8010134c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101353:	00 
80101354:	89 04 24             	mov    %eax,(%esp)
80101357:	e8 24 3c 00 00       	call   80104f80 <memset>
  log_write(bp);
8010135c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010135f:	89 04 24             	mov    %eax,(%esp)
80101362:	e8 d5 21 00 00       	call   8010353c <log_write>
  brelse(bp);
80101367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136a:	89 04 24             	mov    %eax,(%esp)
8010136d:	e8 a5 ee ff ff       	call   80100217 <brelse>
}
80101372:	c9                   	leave  
80101373:	c3                   	ret    

80101374 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101374:	55                   	push   %ebp
80101375:	89 e5                	mov    %esp,%ebp
80101377:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010137a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101381:	8b 45 08             	mov    0x8(%ebp),%eax
80101384:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101387:	89 54 24 04          	mov    %edx,0x4(%esp)
8010138b:	89 04 24             	mov    %eax,(%esp)
8010138e:	e8 4a ff ff ff       	call   801012dd <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101393:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010139a:	e9 07 01 00 00       	jmp    801014a6 <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
8010139f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013a8:	85 c0                	test   %eax,%eax
801013aa:	0f 48 c2             	cmovs  %edx,%eax
801013ad:	c1 f8 0c             	sar    $0xc,%eax
801013b0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013b3:	c1 ea 03             	shr    $0x3,%edx
801013b6:	01 d0                	add    %edx,%eax
801013b8:	83 c0 03             	add    $0x3,%eax
801013bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801013bf:	8b 45 08             	mov    0x8(%ebp),%eax
801013c2:	89 04 24             	mov    %eax,(%esp)
801013c5:	e8 dc ed ff ff       	call   801001a6 <bread>
801013ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013cd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013d4:	e9 9d 00 00 00       	jmp    80101476 <balloc+0x102>
      m = 1 << (bi % 8);
801013d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013dc:	99                   	cltd   
801013dd:	c1 ea 1d             	shr    $0x1d,%edx
801013e0:	01 d0                	add    %edx,%eax
801013e2:	83 e0 07             	and    $0x7,%eax
801013e5:	29 d0                	sub    %edx,%eax
801013e7:	ba 01 00 00 00       	mov    $0x1,%edx
801013ec:	89 c1                	mov    %eax,%ecx
801013ee:	d3 e2                	shl    %cl,%edx
801013f0:	89 d0                	mov    %edx,%eax
801013f2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801013f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013f8:	8d 50 07             	lea    0x7(%eax),%edx
801013fb:	85 c0                	test   %eax,%eax
801013fd:	0f 48 c2             	cmovs  %edx,%eax
80101400:	c1 f8 03             	sar    $0x3,%eax
80101403:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101406:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010140b:	0f b6 c0             	movzbl %al,%eax
8010140e:	23 45 e8             	and    -0x18(%ebp),%eax
80101411:	85 c0                	test   %eax,%eax
80101413:	75 5d                	jne    80101472 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101415:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101418:	8d 50 07             	lea    0x7(%eax),%edx
8010141b:	85 c0                	test   %eax,%eax
8010141d:	0f 48 c2             	cmovs  %edx,%eax
80101420:	c1 f8 03             	sar    $0x3,%eax
80101423:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101426:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010142b:	89 d1                	mov    %edx,%ecx
8010142d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101430:	09 ca                	or     %ecx,%edx
80101432:	89 d1                	mov    %edx,%ecx
80101434:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101437:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010143b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010143e:	89 04 24             	mov    %eax,(%esp)
80101441:	e8 f6 20 00 00       	call   8010353c <log_write>
        brelse(bp);
80101446:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101449:	89 04 24             	mov    %eax,(%esp)
8010144c:	e8 c6 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101451:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101454:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101457:	01 c2                	add    %eax,%edx
80101459:	8b 45 08             	mov    0x8(%ebp),%eax
8010145c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101460:	89 04 24             	mov    %eax,(%esp)
80101463:	e8 bb fe ff ff       	call   80101323 <bzero>
        return b + bi;
80101468:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010146b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010146e:	01 d0                	add    %edx,%eax
80101470:	eb 4e                	jmp    801014c0 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101472:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101476:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010147d:	7f 15                	jg     80101494 <balloc+0x120>
8010147f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101482:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101485:	01 d0                	add    %edx,%eax
80101487:	89 c2                	mov    %eax,%edx
80101489:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010148c:	39 c2                	cmp    %eax,%edx
8010148e:	0f 82 45 ff ff ff    	jb     801013d9 <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101494:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101497:	89 04 24             	mov    %eax,(%esp)
8010149a:	e8 78 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
8010149f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014a9:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014ac:	39 c2                	cmp    %eax,%edx
801014ae:	0f 82 eb fe ff ff    	jb     8010139f <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014b4:	c7 04 24 59 83 10 80 	movl   $0x80108359,(%esp)
801014bb:	e8 7a f0 ff ff       	call   8010053a <panic>
}
801014c0:	c9                   	leave  
801014c1:	c3                   	ret    

801014c2 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014c2:	55                   	push   %ebp
801014c3:	89 e5                	mov    %esp,%ebp
801014c5:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014c8:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801014cf:	8b 45 08             	mov    0x8(%ebp),%eax
801014d2:	89 04 24             	mov    %eax,(%esp)
801014d5:	e8 03 fe ff ff       	call   801012dd <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014da:	8b 45 0c             	mov    0xc(%ebp),%eax
801014dd:	c1 e8 0c             	shr    $0xc,%eax
801014e0:	89 c2                	mov    %eax,%edx
801014e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014e5:	c1 e8 03             	shr    $0x3,%eax
801014e8:	01 d0                	add    %edx,%eax
801014ea:	8d 50 03             	lea    0x3(%eax),%edx
801014ed:	8b 45 08             	mov    0x8(%ebp),%eax
801014f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801014f4:	89 04 24             	mov    %eax,(%esp)
801014f7:	e8 aa ec ff ff       	call   801001a6 <bread>
801014fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801014ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80101502:	25 ff 0f 00 00       	and    $0xfff,%eax
80101507:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010150a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010150d:	99                   	cltd   
8010150e:	c1 ea 1d             	shr    $0x1d,%edx
80101511:	01 d0                	add    %edx,%eax
80101513:	83 e0 07             	and    $0x7,%eax
80101516:	29 d0                	sub    %edx,%eax
80101518:	ba 01 00 00 00       	mov    $0x1,%edx
8010151d:	89 c1                	mov    %eax,%ecx
8010151f:	d3 e2                	shl    %cl,%edx
80101521:	89 d0                	mov    %edx,%eax
80101523:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101526:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101529:	8d 50 07             	lea    0x7(%eax),%edx
8010152c:	85 c0                	test   %eax,%eax
8010152e:	0f 48 c2             	cmovs  %edx,%eax
80101531:	c1 f8 03             	sar    $0x3,%eax
80101534:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101537:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010153c:	0f b6 c0             	movzbl %al,%eax
8010153f:	23 45 ec             	and    -0x14(%ebp),%eax
80101542:	85 c0                	test   %eax,%eax
80101544:	75 0c                	jne    80101552 <bfree+0x90>
    panic("freeing free block");
80101546:	c7 04 24 6f 83 10 80 	movl   $0x8010836f,(%esp)
8010154d:	e8 e8 ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101552:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101555:	8d 50 07             	lea    0x7(%eax),%edx
80101558:	85 c0                	test   %eax,%eax
8010155a:	0f 48 c2             	cmovs  %edx,%eax
8010155d:	c1 f8 03             	sar    $0x3,%eax
80101560:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101563:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101568:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010156b:	f7 d1                	not    %ecx
8010156d:	21 ca                	and    %ecx,%edx
8010156f:	89 d1                	mov    %edx,%ecx
80101571:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101574:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101578:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010157b:	89 04 24             	mov    %eax,(%esp)
8010157e:	e8 b9 1f 00 00       	call   8010353c <log_write>
  brelse(bp);
80101583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101586:	89 04 24             	mov    %eax,(%esp)
80101589:	e8 89 ec ff ff       	call   80100217 <brelse>
}
8010158e:	c9                   	leave  
8010158f:	c3                   	ret    

80101590 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80101590:	55                   	push   %ebp
80101591:	89 e5                	mov    %esp,%ebp
80101593:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80101596:	c7 44 24 04 82 83 10 	movl   $0x80108382,0x4(%esp)
8010159d:	80 
8010159e:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801015a5:	e8 61 37 00 00       	call   80104d0b <initlock>
}
801015aa:	c9                   	leave  
801015ab:	c3                   	ret    

801015ac <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015ac:	55                   	push   %ebp
801015ad:	89 e5                	mov    %esp,%ebp
801015af:	83 ec 38             	sub    $0x38,%esp
801015b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801015b5:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015b9:	8b 45 08             	mov    0x8(%ebp),%eax
801015bc:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801015c3:	89 04 24             	mov    %eax,(%esp)
801015c6:	e8 12 fd ff ff       	call   801012dd <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015cb:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015d2:	e9 98 00 00 00       	jmp    8010166f <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015da:	c1 e8 03             	shr    $0x3,%eax
801015dd:	83 c0 02             	add    $0x2,%eax
801015e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801015e4:	8b 45 08             	mov    0x8(%ebp),%eax
801015e7:	89 04 24             	mov    %eax,(%esp)
801015ea:	e8 b7 eb ff ff       	call   801001a6 <bread>
801015ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801015f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015f5:	8d 50 18             	lea    0x18(%eax),%edx
801015f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015fb:	83 e0 07             	and    $0x7,%eax
801015fe:	c1 e0 06             	shl    $0x6,%eax
80101601:	01 d0                	add    %edx,%eax
80101603:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101606:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101609:	0f b7 00             	movzwl (%eax),%eax
8010160c:	66 85 c0             	test   %ax,%ax
8010160f:	75 4f                	jne    80101660 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101611:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101618:	00 
80101619:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101620:	00 
80101621:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101624:	89 04 24             	mov    %eax,(%esp)
80101627:	e8 54 39 00 00       	call   80104f80 <memset>
      dip->type = type;
8010162c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010162f:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101633:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101636:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101639:	89 04 24             	mov    %eax,(%esp)
8010163c:	e8 fb 1e 00 00       	call   8010353c <log_write>
      brelse(bp);
80101641:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101644:	89 04 24             	mov    %eax,(%esp)
80101647:	e8 cb eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
8010164c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010164f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101653:	8b 45 08             	mov    0x8(%ebp),%eax
80101656:	89 04 24             	mov    %eax,(%esp)
80101659:	e8 e5 00 00 00       	call   80101743 <iget>
8010165e:	eb 29                	jmp    80101689 <ialloc+0xdd>
    }
    brelse(bp);
80101660:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101663:	89 04 24             	mov    %eax,(%esp)
80101666:	e8 ac eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010166b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010166f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101672:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101675:	39 c2                	cmp    %eax,%edx
80101677:	0f 82 5a ff ff ff    	jb     801015d7 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010167d:	c7 04 24 89 83 10 80 	movl   $0x80108389,(%esp)
80101684:	e8 b1 ee ff ff       	call   8010053a <panic>
}
80101689:	c9                   	leave  
8010168a:	c3                   	ret    

8010168b <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010168b:	55                   	push   %ebp
8010168c:	89 e5                	mov    %esp,%ebp
8010168e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80101691:	8b 45 08             	mov    0x8(%ebp),%eax
80101694:	8b 40 04             	mov    0x4(%eax),%eax
80101697:	c1 e8 03             	shr    $0x3,%eax
8010169a:	8d 50 02             	lea    0x2(%eax),%edx
8010169d:	8b 45 08             	mov    0x8(%ebp),%eax
801016a0:	8b 00                	mov    (%eax),%eax
801016a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801016a6:	89 04 24             	mov    %eax,(%esp)
801016a9:	e8 f8 ea ff ff       	call   801001a6 <bread>
801016ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016b4:	8d 50 18             	lea    0x18(%eax),%edx
801016b7:	8b 45 08             	mov    0x8(%ebp),%eax
801016ba:	8b 40 04             	mov    0x4(%eax),%eax
801016bd:	83 e0 07             	and    $0x7,%eax
801016c0:	c1 e0 06             	shl    $0x6,%eax
801016c3:	01 d0                	add    %edx,%eax
801016c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016c8:	8b 45 08             	mov    0x8(%ebp),%eax
801016cb:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016d2:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016d5:	8b 45 08             	mov    0x8(%ebp),%eax
801016d8:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016df:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801016e3:	8b 45 08             	mov    0x8(%ebp),%eax
801016e6:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801016ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016ed:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801016f1:	8b 45 08             	mov    0x8(%ebp),%eax
801016f4:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801016f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016fb:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801016ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101702:	8b 50 18             	mov    0x18(%eax),%edx
80101705:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101708:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010170b:	8b 45 08             	mov    0x8(%ebp),%eax
8010170e:	8d 50 1c             	lea    0x1c(%eax),%edx
80101711:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101714:	83 c0 0c             	add    $0xc,%eax
80101717:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010171e:	00 
8010171f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101723:	89 04 24             	mov    %eax,(%esp)
80101726:	e8 24 39 00 00       	call   8010504f <memmove>
  log_write(bp);
8010172b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010172e:	89 04 24             	mov    %eax,(%esp)
80101731:	e8 06 1e 00 00       	call   8010353c <log_write>
  brelse(bp);
80101736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101739:	89 04 24             	mov    %eax,(%esp)
8010173c:	e8 d6 ea ff ff       	call   80100217 <brelse>
}
80101741:	c9                   	leave  
80101742:	c3                   	ret    

80101743 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101743:	55                   	push   %ebp
80101744:	89 e5                	mov    %esp,%ebp
80101746:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101749:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101750:	e8 d7 35 00 00       	call   80104d2c <acquire>

  // Is the inode already cached?
  empty = 0;
80101755:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010175c:	c7 45 f4 94 e8 10 80 	movl   $0x8010e894,-0xc(%ebp)
80101763:	eb 59                	jmp    801017be <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101765:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101768:	8b 40 08             	mov    0x8(%eax),%eax
8010176b:	85 c0                	test   %eax,%eax
8010176d:	7e 35                	jle    801017a4 <iget+0x61>
8010176f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101772:	8b 00                	mov    (%eax),%eax
80101774:	3b 45 08             	cmp    0x8(%ebp),%eax
80101777:	75 2b                	jne    801017a4 <iget+0x61>
80101779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177c:	8b 40 04             	mov    0x4(%eax),%eax
8010177f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101782:	75 20                	jne    801017a4 <iget+0x61>
      ip->ref++;
80101784:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101787:	8b 40 08             	mov    0x8(%eax),%eax
8010178a:	8d 50 01             	lea    0x1(%eax),%edx
8010178d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101790:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101793:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010179a:	e8 ef 35 00 00       	call   80104d8e <release>
      return ip;
8010179f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a2:	eb 6f                	jmp    80101813 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017a8:	75 10                	jne    801017ba <iget+0x77>
801017aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ad:	8b 40 08             	mov    0x8(%eax),%eax
801017b0:	85 c0                	test   %eax,%eax
801017b2:	75 06                	jne    801017ba <iget+0x77>
      empty = ip;
801017b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b7:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017ba:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017be:	81 7d f4 34 f8 10 80 	cmpl   $0x8010f834,-0xc(%ebp)
801017c5:	72 9e                	jb     80101765 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017c7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017cb:	75 0c                	jne    801017d9 <iget+0x96>
    panic("iget: no inodes");
801017cd:	c7 04 24 9b 83 10 80 	movl   $0x8010839b,(%esp)
801017d4:	e8 61 ed ff ff       	call   8010053a <panic>

  ip = empty;
801017d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801017df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e2:	8b 55 08             	mov    0x8(%ebp),%edx
801017e5:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801017e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ea:	8b 55 0c             	mov    0xc(%ebp),%edx
801017ed:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801017f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f3:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801017fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101804:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010180b:	e8 7e 35 00 00       	call   80104d8e <release>

  return ip;
80101810:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101813:	c9                   	leave  
80101814:	c3                   	ret    

80101815 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101815:	55                   	push   %ebp
80101816:	89 e5                	mov    %esp,%ebp
80101818:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010181b:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101822:	e8 05 35 00 00       	call   80104d2c <acquire>
  ip->ref++;
80101827:	8b 45 08             	mov    0x8(%ebp),%eax
8010182a:	8b 40 08             	mov    0x8(%eax),%eax
8010182d:	8d 50 01             	lea    0x1(%eax),%edx
80101830:	8b 45 08             	mov    0x8(%ebp),%eax
80101833:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101836:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010183d:	e8 4c 35 00 00       	call   80104d8e <release>
  return ip;
80101842:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101845:	c9                   	leave  
80101846:	c3                   	ret    

80101847 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101847:	55                   	push   %ebp
80101848:	89 e5                	mov    %esp,%ebp
8010184a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
8010184d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101851:	74 0a                	je     8010185d <ilock+0x16>
80101853:	8b 45 08             	mov    0x8(%ebp),%eax
80101856:	8b 40 08             	mov    0x8(%eax),%eax
80101859:	85 c0                	test   %eax,%eax
8010185b:	7f 0c                	jg     80101869 <ilock+0x22>
    panic("ilock");
8010185d:	c7 04 24 ab 83 10 80 	movl   $0x801083ab,(%esp)
80101864:	e8 d1 ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101869:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101870:	e8 b7 34 00 00       	call   80104d2c <acquire>
  while(ip->flags & I_BUSY)
80101875:	eb 13                	jmp    8010188a <ilock+0x43>
    sleep(ip, &icache.lock);
80101877:	c7 44 24 04 60 e8 10 	movl   $0x8010e860,0x4(%esp)
8010187e:	80 
8010187f:	8b 45 08             	mov    0x8(%ebp),%eax
80101882:	89 04 24             	mov    %eax,(%esp)
80101885:	e8 d8 31 00 00       	call   80104a62 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010188a:	8b 45 08             	mov    0x8(%ebp),%eax
8010188d:	8b 40 0c             	mov    0xc(%eax),%eax
80101890:	83 e0 01             	and    $0x1,%eax
80101893:	85 c0                	test   %eax,%eax
80101895:	75 e0                	jne    80101877 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101897:	8b 45 08             	mov    0x8(%ebp),%eax
8010189a:	8b 40 0c             	mov    0xc(%eax),%eax
8010189d:	83 c8 01             	or     $0x1,%eax
801018a0:	89 c2                	mov    %eax,%edx
801018a2:	8b 45 08             	mov    0x8(%ebp),%eax
801018a5:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018a8:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801018af:	e8 da 34 00 00       	call   80104d8e <release>

  if(!(ip->flags & I_VALID)){
801018b4:	8b 45 08             	mov    0x8(%ebp),%eax
801018b7:	8b 40 0c             	mov    0xc(%eax),%eax
801018ba:	83 e0 02             	and    $0x2,%eax
801018bd:	85 c0                	test   %eax,%eax
801018bf:	0f 85 ce 00 00 00    	jne    80101993 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018c5:	8b 45 08             	mov    0x8(%ebp),%eax
801018c8:	8b 40 04             	mov    0x4(%eax),%eax
801018cb:	c1 e8 03             	shr    $0x3,%eax
801018ce:	8d 50 02             	lea    0x2(%eax),%edx
801018d1:	8b 45 08             	mov    0x8(%ebp),%eax
801018d4:	8b 00                	mov    (%eax),%eax
801018d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801018da:	89 04 24             	mov    %eax,(%esp)
801018dd:	e8 c4 e8 ff ff       	call   801001a6 <bread>
801018e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801018e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018e8:	8d 50 18             	lea    0x18(%eax),%edx
801018eb:	8b 45 08             	mov    0x8(%ebp),%eax
801018ee:	8b 40 04             	mov    0x4(%eax),%eax
801018f1:	83 e0 07             	and    $0x7,%eax
801018f4:	c1 e0 06             	shl    $0x6,%eax
801018f7:	01 d0                	add    %edx,%eax
801018f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801018fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018ff:	0f b7 10             	movzwl (%eax),%edx
80101902:	8b 45 08             	mov    0x8(%ebp),%eax
80101905:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101909:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010190c:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101910:	8b 45 08             	mov    0x8(%ebp),%eax
80101913:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101917:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010191a:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101925:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101928:	0f b7 50 06          	movzwl 0x6(%eax),%edx
8010192c:	8b 45 08             	mov    0x8(%ebp),%eax
8010192f:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101936:	8b 50 08             	mov    0x8(%eax),%edx
80101939:	8b 45 08             	mov    0x8(%ebp),%eax
8010193c:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
8010193f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101942:	8d 50 0c             	lea    0xc(%eax),%edx
80101945:	8b 45 08             	mov    0x8(%ebp),%eax
80101948:	83 c0 1c             	add    $0x1c,%eax
8010194b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101952:	00 
80101953:	89 54 24 04          	mov    %edx,0x4(%esp)
80101957:	89 04 24             	mov    %eax,(%esp)
8010195a:	e8 f0 36 00 00       	call   8010504f <memmove>
    brelse(bp);
8010195f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101962:	89 04 24             	mov    %eax,(%esp)
80101965:	e8 ad e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010196a:	8b 45 08             	mov    0x8(%ebp),%eax
8010196d:	8b 40 0c             	mov    0xc(%eax),%eax
80101970:	83 c8 02             	or     $0x2,%eax
80101973:	89 c2                	mov    %eax,%edx
80101975:	8b 45 08             	mov    0x8(%ebp),%eax
80101978:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010197b:	8b 45 08             	mov    0x8(%ebp),%eax
8010197e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101982:	66 85 c0             	test   %ax,%ax
80101985:	75 0c                	jne    80101993 <ilock+0x14c>
      panic("ilock: no type");
80101987:	c7 04 24 b1 83 10 80 	movl   $0x801083b1,(%esp)
8010198e:	e8 a7 eb ff ff       	call   8010053a <panic>
  }
}
80101993:	c9                   	leave  
80101994:	c3                   	ret    

80101995 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101995:	55                   	push   %ebp
80101996:	89 e5                	mov    %esp,%ebp
80101998:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
8010199b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010199f:	74 17                	je     801019b8 <iunlock+0x23>
801019a1:	8b 45 08             	mov    0x8(%ebp),%eax
801019a4:	8b 40 0c             	mov    0xc(%eax),%eax
801019a7:	83 e0 01             	and    $0x1,%eax
801019aa:	85 c0                	test   %eax,%eax
801019ac:	74 0a                	je     801019b8 <iunlock+0x23>
801019ae:	8b 45 08             	mov    0x8(%ebp),%eax
801019b1:	8b 40 08             	mov    0x8(%eax),%eax
801019b4:	85 c0                	test   %eax,%eax
801019b6:	7f 0c                	jg     801019c4 <iunlock+0x2f>
    panic("iunlock");
801019b8:	c7 04 24 c0 83 10 80 	movl   $0x801083c0,(%esp)
801019bf:	e8 76 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019c4:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801019cb:	e8 5c 33 00 00       	call   80104d2c <acquire>
  ip->flags &= ~I_BUSY;
801019d0:	8b 45 08             	mov    0x8(%ebp),%eax
801019d3:	8b 40 0c             	mov    0xc(%eax),%eax
801019d6:	83 e0 fe             	and    $0xfffffffe,%eax
801019d9:	89 c2                	mov    %eax,%edx
801019db:	8b 45 08             	mov    0x8(%ebp),%eax
801019de:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801019e1:	8b 45 08             	mov    0x8(%ebp),%eax
801019e4:	89 04 24             	mov    %eax,(%esp)
801019e7:	e8 4f 31 00 00       	call   80104b3b <wakeup>
  release(&icache.lock);
801019ec:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801019f3:	e8 96 33 00 00       	call   80104d8e <release>
}
801019f8:	c9                   	leave  
801019f9:	c3                   	ret    

801019fa <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
801019fa:	55                   	push   %ebp
801019fb:	89 e5                	mov    %esp,%ebp
801019fd:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a00:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a07:	e8 20 33 00 00       	call   80104d2c <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0f:	8b 40 08             	mov    0x8(%eax),%eax
80101a12:	83 f8 01             	cmp    $0x1,%eax
80101a15:	0f 85 93 00 00 00    	jne    80101aae <iput+0xb4>
80101a1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1e:	8b 40 0c             	mov    0xc(%eax),%eax
80101a21:	83 e0 02             	and    $0x2,%eax
80101a24:	85 c0                	test   %eax,%eax
80101a26:	0f 84 82 00 00 00    	je     80101aae <iput+0xb4>
80101a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a33:	66 85 c0             	test   %ax,%ax
80101a36:	75 76                	jne    80101aae <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101a38:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3b:	8b 40 0c             	mov    0xc(%eax),%eax
80101a3e:	83 e0 01             	and    $0x1,%eax
80101a41:	85 c0                	test   %eax,%eax
80101a43:	74 0c                	je     80101a51 <iput+0x57>
      panic("iput busy");
80101a45:	c7 04 24 c8 83 10 80 	movl   $0x801083c8,(%esp)
80101a4c:	e8 e9 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101a51:	8b 45 08             	mov    0x8(%ebp),%eax
80101a54:	8b 40 0c             	mov    0xc(%eax),%eax
80101a57:	83 c8 01             	or     $0x1,%eax
80101a5a:	89 c2                	mov    %eax,%edx
80101a5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5f:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a62:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a69:	e8 20 33 00 00       	call   80104d8e <release>
    itrunc(ip);
80101a6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a71:	89 04 24             	mov    %eax,(%esp)
80101a74:	e8 d8 02 00 00       	call   80101d51 <itrunc>
    ip->type = 0;
80101a79:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7c:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101a82:	8b 45 08             	mov    0x8(%ebp),%eax
80101a85:	89 04 24             	mov    %eax,(%esp)
80101a88:	e8 fe fb ff ff       	call   8010168b <iupdate>
    acquire(&icache.lock);
80101a8d:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a94:	e8 93 32 00 00       	call   80104d2c <acquire>
    ip->flags = 0;
80101a99:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101aa3:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa6:	89 04 24             	mov    %eax,(%esp)
80101aa9:	e8 8d 30 00 00       	call   80104b3b <wakeup>
  }
  ip->ref--;
80101aae:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab1:	8b 40 08             	mov    0x8(%eax),%eax
80101ab4:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aba:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101abd:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101ac4:	e8 c5 32 00 00       	call   80104d8e <release>
}
80101ac9:	c9                   	leave  
80101aca:	c3                   	ret    

80101acb <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101acb:	55                   	push   %ebp
80101acc:	89 e5                	mov    %esp,%ebp
80101ace:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101ad1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad4:	89 04 24             	mov    %eax,(%esp)
80101ad7:	e8 b9 fe ff ff       	call   80101995 <iunlock>
  iput(ip);
80101adc:	8b 45 08             	mov    0x8(%ebp),%eax
80101adf:	89 04 24             	mov    %eax,(%esp)
80101ae2:	e8 13 ff ff ff       	call   801019fa <iput>
}
80101ae7:	c9                   	leave  
80101ae8:	c3                   	ret    

80101ae9 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101ae9:	55                   	push   %ebp
80101aea:	89 e5                	mov    %esp,%ebp
80101aec:	53                   	push   %ebx
80101aed:	83 ec 34             	sub    $0x34,%esp
  uint addr, *a;
  struct buf *bp;

  // Handle direct blocks
  if(bn < NDIRECT){
80101af0:	83 7d 0c 09          	cmpl   $0x9,0xc(%ebp)
80101af4:	77 3e                	ja     80101b34 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101af6:	8b 45 08             	mov    0x8(%ebp),%eax
80101af9:	8b 55 0c             	mov    0xc(%ebp),%edx
80101afc:	83 c2 04             	add    $0x4,%edx
80101aff:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b03:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b06:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b0a:	75 20                	jne    80101b2c <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0f:	8b 00                	mov    (%eax),%eax
80101b11:	89 04 24             	mov    %eax,(%esp)
80101b14:	e8 5b f8 ff ff       	call   80101374 <balloc>
80101b19:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b22:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b25:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b28:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b2f:	e9 17 02 00 00       	jmp    80101d4b <bmap+0x262>
  }
  bn -= NDIRECT;
80101b34:	83 6d 0c 0a          	subl   $0xa,0xc(%ebp)

  // Handle indirect blocks
  uint addrsi = NDIRECT;
80101b38:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
  if (bn >= NINDIRECT) {
80101b3f:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b43:	76 08                	jbe    80101b4d <bmap+0x64>
      addrsi++;
80101b45:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
      bn -= NINDIRECT;
80101b49:	83 45 0c 80          	addl   $0xffffff80,0xc(%ebp)
  }
  if(bn < NINDIRECT){
80101b4d:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b51:	0f 87 b3 00 00 00    	ja     80101c0a <bmap+0x121>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[addrsi]) == 0)
80101b57:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b5d:	83 c2 04             	add    $0x4,%edx
80101b60:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b64:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b6b:	75 20                	jne    80101b8d <bmap+0xa4>
      ip->addrs[addrsi] = addr = balloc(ip->dev);
80101b6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b70:	8b 00                	mov    (%eax),%eax
80101b72:	89 04 24             	mov    %eax,(%esp)
80101b75:	e8 fa f7 ff ff       	call   80101374 <balloc>
80101b7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b80:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b83:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b86:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b89:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    bp = bread(ip->dev, addr);
80101b8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b90:	8b 00                	mov    (%eax),%eax
80101b92:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b95:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b99:	89 04 24             	mov    %eax,(%esp)
80101b9c:	e8 05 e6 ff ff       	call   801001a6 <bread>
80101ba1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101ba4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ba7:	83 c0 18             	add    $0x18,%eax
80101baa:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((addr = a[bn]) == 0){
80101bad:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bb0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bb7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101bba:	01 d0                	add    %edx,%eax
80101bbc:	8b 00                	mov    (%eax),%eax
80101bbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bc5:	75 30                	jne    80101bf7 <bmap+0x10e>
      a[bn] = addr = balloc(ip->dev);
80101bc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bca:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bd1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101bd4:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bda:	8b 00                	mov    (%eax),%eax
80101bdc:	89 04 24             	mov    %eax,(%esp)
80101bdf:	e8 90 f7 ff ff       	call   80101374 <balloc>
80101be4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101be7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bea:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bec:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bef:	89 04 24             	mov    %eax,(%esp)
80101bf2:	e8 45 19 00 00       	call   8010353c <log_write>
    }
    brelse(bp);
80101bf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bfa:	89 04 24             	mov    %eax,(%esp)
80101bfd:	e8 15 e6 ff ff       	call   80100217 <brelse>
    return addr;
80101c02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c05:	e9 41 01 00 00       	jmp    80101d4b <bmap+0x262>
  }
  bn -= NINDIRECT;
80101c0a:	83 45 0c 80          	addl   $0xffffff80,0xc(%ebp)
  
  // Handle double indirect blocks
  if (bn < NINDIRECT*NINDIRECT) {
80101c0e:	81 7d 0c ff 3f 00 00 	cmpl   $0x3fff,0xc(%ebp)
80101c15:	0f 87 24 01 00 00    	ja     80101d3f <bmap+0x256>
    if((addr = ip->addrs[NDIRECT+2]) == 0)
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c21:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c24:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c28:	75 19                	jne    80101c43 <bmap+0x15a>
      ip->addrs[NDIRECT+2] = addr = balloc(ip->dev);
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 00                	mov    (%eax),%eax
80101c2f:	89 04 24             	mov    %eax,(%esp)
80101c32:	e8 3d f7 ff ff       	call   80101374 <balloc>
80101c37:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c40:	89 50 4c             	mov    %edx,0x4c(%eax)
    uint bi = (bn / NINDIRECT);
80101c43:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c46:	c1 e8 07             	shr    $0x7,%eax
80101c49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    bn = bn % NINDIRECT;
80101c4c:	83 65 0c 7f          	andl   $0x7f,0xc(%ebp)
    bp = bread(ip->dev, addr); // double indirect block
80101c50:	8b 45 08             	mov    0x8(%ebp),%eax
80101c53:	8b 00                	mov    (%eax),%eax
80101c55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c58:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c5c:	89 04 24             	mov    %eax,(%esp)
80101c5f:	e8 42 e5 ff ff       	call   801001a6 <bread>
80101c64:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c67:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c6a:	83 c0 18             	add    $0x18,%eax
80101c6d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((addr = a[bi]) == 0){
80101c70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101c73:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101c7d:	01 d0                	add    %edx,%eax
80101c7f:	8b 00                	mov    (%eax),%eax
80101c81:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c88:	75 30                	jne    80101cba <bmap+0x1d1>
      a[bi] = addr = balloc(ip->dev);
80101c8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101c8d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c94:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101c97:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9d:	8b 00                	mov    (%eax),%eax
80101c9f:	89 04 24             	mov    %eax,(%esp)
80101ca2:	e8 cd f6 ff ff       	call   80101374 <balloc>
80101ca7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101caa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cad:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101caf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cb2:	89 04 24             	mov    %eax,(%esp)
80101cb5:	e8 82 18 00 00       	call   8010353c <log_write>
    }
    brelse(bp);
80101cba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cbd:	89 04 24             	mov    %eax,(%esp)
80101cc0:	e8 52 e5 ff ff       	call   80100217 <brelse>
    
    bp = bread(ip->dev, addr); // indirect block
80101cc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc8:	8b 00                	mov    (%eax),%eax
80101cca:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ccd:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cd1:	89 04 24             	mov    %eax,(%esp)
80101cd4:	e8 cd e4 ff ff       	call   801001a6 <bread>
80101cd9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101cdc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cdf:	83 c0 18             	add    $0x18,%eax
80101ce2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((addr = a[bn]) == 0){
80101ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ce8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cef:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cf2:	01 d0                	add    %edx,%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cf9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cfd:	75 30                	jne    80101d2f <bmap+0x246>
      a[bn] = addr = balloc(ip->dev);
80101cff:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d02:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d09:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d0c:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d12:	8b 00                	mov    (%eax),%eax
80101d14:	89 04 24             	mov    %eax,(%esp)
80101d17:	e8 58 f6 ff ff       	call   80101374 <balloc>
80101d1c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d22:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d24:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d27:	89 04 24             	mov    %eax,(%esp)
80101d2a:	e8 0d 18 00 00       	call   8010353c <log_write>
    }
    brelse(bp);
80101d2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d32:	89 04 24             	mov    %eax,(%esp)
80101d35:	e8 dd e4 ff ff       	call   80100217 <brelse>
    return addr;
80101d3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d3d:	eb 0c                	jmp    80101d4b <bmap+0x262>
  }

 
  panic("bmap: out of range");
80101d3f:	c7 04 24 d2 83 10 80 	movl   $0x801083d2,(%esp)
80101d46:	e8 ef e7 ff ff       	call   8010053a <panic>
}
80101d4b:	83 c4 34             	add    $0x34,%esp
80101d4e:	5b                   	pop    %ebx
80101d4f:	5d                   	pop    %ebp
80101d50:	c3                   	ret    

80101d51 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d51:	55                   	push   %ebp
80101d52:	89 e5                	mov    %esp,%ebp
80101d54:	83 ec 38             	sub    $0x38,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  // free direct blocks
  for(i = 0; i < NDIRECT; i++){
80101d57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d5e:	eb 44                	jmp    80101da4 <itrunc+0x53>
    if(ip->addrs[i]){
80101d60:	8b 45 08             	mov    0x8(%ebp),%eax
80101d63:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d66:	83 c2 04             	add    $0x4,%edx
80101d69:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d6d:	85 c0                	test   %eax,%eax
80101d6f:	74 2f                	je     80101da0 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d71:	8b 45 08             	mov    0x8(%ebp),%eax
80101d74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d77:	83 c2 04             	add    $0x4,%edx
80101d7a:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d81:	8b 00                	mov    (%eax),%eax
80101d83:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d87:	89 04 24             	mov    %eax,(%esp)
80101d8a:	e8 33 f7 ff ff       	call   801014c2 <bfree>
      ip->addrs[i] = 0;
80101d8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d92:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d95:	83 c2 04             	add    $0x4,%edx
80101d98:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d9f:	00 
  int i, j;
  struct buf *bp;
  uint *a;

  // free direct blocks
  for(i = 0; i < NDIRECT; i++){
80101da0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101da4:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80101da8:	7e b6                	jle    80101d60 <itrunc+0xf>
    }
  }
  
  // free indirect blocks
  uint addrsi;
  for(addrsi = NDIRECT; addrsi < NDIRECT+2; addrsi++){
80101daa:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
80101db1:	e9 c9 00 00 00       	jmp    80101e7f <itrunc+0x12e>
    if(ip->addrs[addrsi]){
80101db6:	8b 45 08             	mov    0x8(%ebp),%eax
80101db9:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101dbc:	83 c2 04             	add    $0x4,%edx
80101dbf:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101dc3:	85 c0                	test   %eax,%eax
80101dc5:	0f 84 b0 00 00 00    	je     80101e7b <itrunc+0x12a>
      bp = bread(ip->dev, ip->addrs[addrsi]);
80101dcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dce:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101dd1:	83 c2 04             	add    $0x4,%edx
80101dd4:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101dd8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ddb:	8b 00                	mov    (%eax),%eax
80101ddd:	89 54 24 04          	mov    %edx,0x4(%esp)
80101de1:	89 04 24             	mov    %eax,(%esp)
80101de4:	e8 bd e3 ff ff       	call   801001a6 <bread>
80101de9:	89 45 e8             	mov    %eax,-0x18(%ebp)
      a = (uint*)bp->data;
80101dec:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101def:	83 c0 18             	add    $0x18,%eax
80101df2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      for(j = 0; j < NINDIRECT; j++){
80101df5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101dfc:	eb 3b                	jmp    80101e39 <itrunc+0xe8>
        if(a[j])
80101dfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e01:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e08:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101e0b:	01 d0                	add    %edx,%eax
80101e0d:	8b 00                	mov    (%eax),%eax
80101e0f:	85 c0                	test   %eax,%eax
80101e11:	74 22                	je     80101e35 <itrunc+0xe4>
          bfree(ip->dev, a[j]);
80101e13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e16:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101e20:	01 d0                	add    %edx,%eax
80101e22:	8b 10                	mov    (%eax),%edx
80101e24:	8b 45 08             	mov    0x8(%ebp),%eax
80101e27:	8b 00                	mov    (%eax),%eax
80101e29:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e2d:	89 04 24             	mov    %eax,(%esp)
80101e30:	e8 8d f6 ff ff       	call   801014c2 <bfree>
  uint addrsi;
  for(addrsi = NDIRECT; addrsi < NDIRECT+2; addrsi++){
    if(ip->addrs[addrsi]){
      bp = bread(ip->dev, ip->addrs[addrsi]);
      a = (uint*)bp->data;
      for(j = 0; j < NINDIRECT; j++){
80101e35:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e3c:	83 f8 7f             	cmp    $0x7f,%eax
80101e3f:	76 bd                	jbe    80101dfe <itrunc+0xad>
        if(a[j])
          bfree(ip->dev, a[j]);
      }
      brelse(bp);
80101e41:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e44:	89 04 24             	mov    %eax,(%esp)
80101e47:	e8 cb e3 ff ff       	call   80100217 <brelse>
      bfree(ip->dev, ip->addrs[addrsi]);
80101e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101e52:	83 c2 04             	add    $0x4,%edx
80101e55:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101e59:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5c:	8b 00                	mov    (%eax),%eax
80101e5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e62:	89 04 24             	mov    %eax,(%esp)
80101e65:	e8 58 f6 ff ff       	call   801014c2 <bfree>
      ip->addrs[addrsi] = 0;
80101e6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e6d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101e70:	83 c2 04             	add    $0x4,%edx
80101e73:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101e7a:	00 
    }
  }
  
  // free indirect blocks
  uint addrsi;
  for(addrsi = NDIRECT; addrsi < NDIRECT+2; addrsi++){
80101e7b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80101e7f:	83 7d ec 0b          	cmpl   $0xb,-0x14(%ebp)
80101e83:	0f 86 2d ff ff ff    	jbe    80101db6 <itrunc+0x65>
      ip->addrs[addrsi] = 0;
    }
  }

  // free double indirect blocks
  if(ip->addrs[NDIRECT+2]) {
80101e89:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8c:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e8f:	85 c0                	test   %eax,%eax
80101e91:	0f 84 2b 01 00 00    	je     80101fc2 <itrunc+0x271>
    struct buf *bp2;
    uint *a2;
    bp = bread(ip->dev, ip->addrs[NDIRECT+2]);
80101e97:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9a:	8b 50 4c             	mov    0x4c(%eax),%edx
80101e9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea0:	8b 00                	mov    (%eax),%eax
80101ea2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ea6:	89 04 24             	mov    %eax,(%esp)
80101ea9:	e8 f8 e2 ff ff       	call   801001a6 <bread>
80101eae:	89 45 e8             	mov    %eax,-0x18(%ebp)
    a = (uint*)bp->data;
80101eb1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101eb4:	83 c0 18             	add    $0x18,%eax
80101eb7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(i = 0; i < NINDIRECT; i++) {
80101eba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ec1:	e9 c4 00 00 00       	jmp    80101f8a <itrunc+0x239>
      if (a[i]) {
80101ec6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ec9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ed0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101ed3:	01 d0                	add    %edx,%eax
80101ed5:	8b 00                	mov    (%eax),%eax
80101ed7:	85 c0                	test   %eax,%eax
80101ed9:	0f 84 a7 00 00 00    	je     80101f86 <itrunc+0x235>
        bp2 = bread(ip->dev, a[i]);
80101edf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ee2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ee9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101eec:	01 d0                	add    %edx,%eax
80101eee:	8b 10                	mov    (%eax),%edx
80101ef0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef3:	8b 00                	mov    (%eax),%eax
80101ef5:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ef9:	89 04 24             	mov    %eax,(%esp)
80101efc:	e8 a5 e2 ff ff       	call   801001a6 <bread>
80101f01:	89 45 e0             	mov    %eax,-0x20(%ebp)
        a2 = (uint*)bp2->data;
80101f04:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101f07:	83 c0 18             	add    $0x18,%eax
80101f0a:	89 45 dc             	mov    %eax,-0x24(%ebp)
        for(j = 0; j < NINDIRECT; j++) {
80101f0d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101f14:	eb 3b                	jmp    80101f51 <itrunc+0x200>
          if(a2[j])
80101f16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f19:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101f20:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101f23:	01 d0                	add    %edx,%eax
80101f25:	8b 00                	mov    (%eax),%eax
80101f27:	85 c0                	test   %eax,%eax
80101f29:	74 22                	je     80101f4d <itrunc+0x1fc>
            bfree(ip->dev, a2[j]);
80101f2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f2e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101f35:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101f38:	01 d0                	add    %edx,%eax
80101f3a:	8b 10                	mov    (%eax),%edx
80101f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3f:	8b 00                	mov    (%eax),%eax
80101f41:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f45:	89 04 24             	mov    %eax,(%esp)
80101f48:	e8 75 f5 ff ff       	call   801014c2 <bfree>
    a = (uint*)bp->data;
    for(i = 0; i < NINDIRECT; i++) {
      if (a[i]) {
        bp2 = bread(ip->dev, a[i]);
        a2 = (uint*)bp2->data;
        for(j = 0; j < NINDIRECT; j++) {
80101f4d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101f51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f54:	83 f8 7f             	cmp    $0x7f,%eax
80101f57:	76 bd                	jbe    80101f16 <itrunc+0x1c5>
          if(a2[j])
            bfree(ip->dev, a2[j]);
        }
        brelse(bp2);
80101f59:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101f5c:	89 04 24             	mov    %eax,(%esp)
80101f5f:	e8 b3 e2 ff ff       	call   80100217 <brelse>
        bfree(ip->dev, a[i]);
80101f64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f67:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101f6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f71:	01 d0                	add    %edx,%eax
80101f73:	8b 10                	mov    (%eax),%edx
80101f75:	8b 45 08             	mov    0x8(%ebp),%eax
80101f78:	8b 00                	mov    (%eax),%eax
80101f7a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f7e:	89 04 24             	mov    %eax,(%esp)
80101f81:	e8 3c f5 ff ff       	call   801014c2 <bfree>
  if(ip->addrs[NDIRECT+2]) {
    struct buf *bp2;
    uint *a2;
    bp = bread(ip->dev, ip->addrs[NDIRECT+2]);
    a = (uint*)bp->data;
    for(i = 0; i < NINDIRECT; i++) {
80101f86:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101f8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f8d:	83 f8 7f             	cmp    $0x7f,%eax
80101f90:	0f 86 30 ff ff ff    	jbe    80101ec6 <itrunc+0x175>
        brelse(bp2);
        bfree(ip->dev, a[i]);
        // set a[i] to 0?
      }
    }
    brelse(bp);
80101f96:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101f99:	89 04 24             	mov    %eax,(%esp)
80101f9c:	e8 76 e2 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT+2]);
80101fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa4:	8b 50 4c             	mov    0x4c(%eax),%edx
80101fa7:	8b 45 08             	mov    0x8(%ebp),%eax
80101faa:	8b 00                	mov    (%eax),%eax
80101fac:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fb0:	89 04 24             	mov    %eax,(%esp)
80101fb3:	e8 0a f5 ff ff       	call   801014c2 <bfree>
    ip->addrs[NDIRECT+2] = 0;
80101fb8:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbb:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }


  ip->size = 0;
80101fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc5:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fcf:	89 04 24             	mov    %eax,(%esp)
80101fd2:	e8 b4 f6 ff ff       	call   8010168b <iupdate>
}
80101fd7:	c9                   	leave  
80101fd8:	c3                   	ret    

80101fd9 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101fd9:	55                   	push   %ebp
80101fda:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101fdc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fdf:	8b 00                	mov    (%eax),%eax
80101fe1:	89 c2                	mov    %eax,%edx
80101fe3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fe6:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101fe9:	8b 45 08             	mov    0x8(%ebp),%eax
80101fec:	8b 50 04             	mov    0x4(%eax),%edx
80101fef:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ff2:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff8:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fff:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102002:	8b 45 08             	mov    0x8(%ebp),%eax
80102005:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102009:	8b 45 0c             	mov    0xc(%ebp),%eax
8010200c:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102010:	8b 45 08             	mov    0x8(%ebp),%eax
80102013:	8b 50 18             	mov    0x18(%eax),%edx
80102016:	8b 45 0c             	mov    0xc(%ebp),%eax
80102019:	89 50 10             	mov    %edx,0x10(%eax)
}
8010201c:	5d                   	pop    %ebp
8010201d:	c3                   	ret    

8010201e <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
8010201e:	55                   	push   %ebp
8010201f:	89 e5                	mov    %esp,%ebp
80102021:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102024:	8b 45 08             	mov    0x8(%ebp),%eax
80102027:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010202b:	66 83 f8 03          	cmp    $0x3,%ax
8010202f:	75 60                	jne    80102091 <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102031:	8b 45 08             	mov    0x8(%ebp),%eax
80102034:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102038:	66 85 c0             	test   %ax,%ax
8010203b:	78 20                	js     8010205d <readi+0x3f>
8010203d:	8b 45 08             	mov    0x8(%ebp),%eax
80102040:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102044:	66 83 f8 09          	cmp    $0x9,%ax
80102048:	7f 13                	jg     8010205d <readi+0x3f>
8010204a:	8b 45 08             	mov    0x8(%ebp),%eax
8010204d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102051:	98                   	cwtl   
80102052:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80102059:	85 c0                	test   %eax,%eax
8010205b:	75 0a                	jne    80102067 <readi+0x49>
      return -1;
8010205d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102062:	e9 19 01 00 00       	jmp    80102180 <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80102067:	8b 45 08             	mov    0x8(%ebp),%eax
8010206a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010206e:	98                   	cwtl   
8010206f:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80102076:	8b 55 14             	mov    0x14(%ebp),%edx
80102079:	89 54 24 08          	mov    %edx,0x8(%esp)
8010207d:	8b 55 0c             	mov    0xc(%ebp),%edx
80102080:	89 54 24 04          	mov    %edx,0x4(%esp)
80102084:	8b 55 08             	mov    0x8(%ebp),%edx
80102087:	89 14 24             	mov    %edx,(%esp)
8010208a:	ff d0                	call   *%eax
8010208c:	e9 ef 00 00 00       	jmp    80102180 <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80102091:	8b 45 08             	mov    0x8(%ebp),%eax
80102094:	8b 40 18             	mov    0x18(%eax),%eax
80102097:	3b 45 10             	cmp    0x10(%ebp),%eax
8010209a:	72 0d                	jb     801020a9 <readi+0x8b>
8010209c:	8b 45 14             	mov    0x14(%ebp),%eax
8010209f:	8b 55 10             	mov    0x10(%ebp),%edx
801020a2:	01 d0                	add    %edx,%eax
801020a4:	3b 45 10             	cmp    0x10(%ebp),%eax
801020a7:	73 0a                	jae    801020b3 <readi+0x95>
    return -1;
801020a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020ae:	e9 cd 00 00 00       	jmp    80102180 <readi+0x162>
  if(off + n > ip->size)
801020b3:	8b 45 14             	mov    0x14(%ebp),%eax
801020b6:	8b 55 10             	mov    0x10(%ebp),%edx
801020b9:	01 c2                	add    %eax,%edx
801020bb:	8b 45 08             	mov    0x8(%ebp),%eax
801020be:	8b 40 18             	mov    0x18(%eax),%eax
801020c1:	39 c2                	cmp    %eax,%edx
801020c3:	76 0c                	jbe    801020d1 <readi+0xb3>
    n = ip->size - off;
801020c5:	8b 45 08             	mov    0x8(%ebp),%eax
801020c8:	8b 40 18             	mov    0x18(%eax),%eax
801020cb:	2b 45 10             	sub    0x10(%ebp),%eax
801020ce:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801020d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020d8:	e9 94 00 00 00       	jmp    80102171 <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801020dd:	8b 45 10             	mov    0x10(%ebp),%eax
801020e0:	c1 e8 09             	shr    $0x9,%eax
801020e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801020e7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ea:	89 04 24             	mov    %eax,(%esp)
801020ed:	e8 f7 f9 ff ff       	call   80101ae9 <bmap>
801020f2:	8b 55 08             	mov    0x8(%ebp),%edx
801020f5:	8b 12                	mov    (%edx),%edx
801020f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801020fb:	89 14 24             	mov    %edx,(%esp)
801020fe:	e8 a3 e0 ff ff       	call   801001a6 <bread>
80102103:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102106:	8b 45 10             	mov    0x10(%ebp),%eax
80102109:	25 ff 01 00 00       	and    $0x1ff,%eax
8010210e:	89 c2                	mov    %eax,%edx
80102110:	b8 00 02 00 00       	mov    $0x200,%eax
80102115:	29 d0                	sub    %edx,%eax
80102117:	89 c2                	mov    %eax,%edx
80102119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010211c:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010211f:	29 c1                	sub    %eax,%ecx
80102121:	89 c8                	mov    %ecx,%eax
80102123:	39 c2                	cmp    %eax,%edx
80102125:	0f 46 c2             	cmovbe %edx,%eax
80102128:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
8010212b:	8b 45 10             	mov    0x10(%ebp),%eax
8010212e:	25 ff 01 00 00       	and    $0x1ff,%eax
80102133:	8d 50 10             	lea    0x10(%eax),%edx
80102136:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102139:	01 d0                	add    %edx,%eax
8010213b:	8d 50 08             	lea    0x8(%eax),%edx
8010213e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102141:	89 44 24 08          	mov    %eax,0x8(%esp)
80102145:	89 54 24 04          	mov    %edx,0x4(%esp)
80102149:	8b 45 0c             	mov    0xc(%ebp),%eax
8010214c:	89 04 24             	mov    %eax,(%esp)
8010214f:	e8 fb 2e 00 00       	call   8010504f <memmove>
    brelse(bp);
80102154:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102157:	89 04 24             	mov    %eax,(%esp)
8010215a:	e8 b8 e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010215f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102162:	01 45 f4             	add    %eax,-0xc(%ebp)
80102165:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102168:	01 45 10             	add    %eax,0x10(%ebp)
8010216b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010216e:	01 45 0c             	add    %eax,0xc(%ebp)
80102171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102174:	3b 45 14             	cmp    0x14(%ebp),%eax
80102177:	0f 82 60 ff ff ff    	jb     801020dd <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010217d:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102180:	c9                   	leave  
80102181:	c3                   	ret    

80102182 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102182:	55                   	push   %ebp
80102183:	89 e5                	mov    %esp,%ebp
80102185:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102188:	8b 45 08             	mov    0x8(%ebp),%eax
8010218b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010218f:	66 83 f8 03          	cmp    $0x3,%ax
80102193:	75 60                	jne    801021f5 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102195:	8b 45 08             	mov    0x8(%ebp),%eax
80102198:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010219c:	66 85 c0             	test   %ax,%ax
8010219f:	78 20                	js     801021c1 <writei+0x3f>
801021a1:	8b 45 08             	mov    0x8(%ebp),%eax
801021a4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021a8:	66 83 f8 09          	cmp    $0x9,%ax
801021ac:	7f 13                	jg     801021c1 <writei+0x3f>
801021ae:	8b 45 08             	mov    0x8(%ebp),%eax
801021b1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021b5:	98                   	cwtl   
801021b6:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
801021bd:	85 c0                	test   %eax,%eax
801021bf:	75 0a                	jne    801021cb <writei+0x49>
      return -1;
801021c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021c6:	e9 44 01 00 00       	jmp    8010230f <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
801021cb:	8b 45 08             	mov    0x8(%ebp),%eax
801021ce:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801021d2:	98                   	cwtl   
801021d3:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
801021da:	8b 55 14             	mov    0x14(%ebp),%edx
801021dd:	89 54 24 08          	mov    %edx,0x8(%esp)
801021e1:	8b 55 0c             	mov    0xc(%ebp),%edx
801021e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801021e8:	8b 55 08             	mov    0x8(%ebp),%edx
801021eb:	89 14 24             	mov    %edx,(%esp)
801021ee:	ff d0                	call   *%eax
801021f0:	e9 1a 01 00 00       	jmp    8010230f <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801021f5:	8b 45 08             	mov    0x8(%ebp),%eax
801021f8:	8b 40 18             	mov    0x18(%eax),%eax
801021fb:	3b 45 10             	cmp    0x10(%ebp),%eax
801021fe:	72 0d                	jb     8010220d <writei+0x8b>
80102200:	8b 45 14             	mov    0x14(%ebp),%eax
80102203:	8b 55 10             	mov    0x10(%ebp),%edx
80102206:	01 d0                	add    %edx,%eax
80102208:	3b 45 10             	cmp    0x10(%ebp),%eax
8010220b:	73 0a                	jae    80102217 <writei+0x95>
    return -1;
8010220d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102212:	e9 f8 00 00 00       	jmp    8010230f <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80102217:	8b 45 14             	mov    0x14(%ebp),%eax
8010221a:	8b 55 10             	mov    0x10(%ebp),%edx
8010221d:	01 d0                	add    %edx,%eax
8010221f:	3d 00 14 82 00       	cmp    $0x821400,%eax
80102224:	76 0a                	jbe    80102230 <writei+0xae>
    return -1;
80102226:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010222b:	e9 df 00 00 00       	jmp    8010230f <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102230:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102237:	e9 9f 00 00 00       	jmp    801022db <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010223c:	8b 45 10             	mov    0x10(%ebp),%eax
8010223f:	c1 e8 09             	shr    $0x9,%eax
80102242:	89 44 24 04          	mov    %eax,0x4(%esp)
80102246:	8b 45 08             	mov    0x8(%ebp),%eax
80102249:	89 04 24             	mov    %eax,(%esp)
8010224c:	e8 98 f8 ff ff       	call   80101ae9 <bmap>
80102251:	8b 55 08             	mov    0x8(%ebp),%edx
80102254:	8b 12                	mov    (%edx),%edx
80102256:	89 44 24 04          	mov    %eax,0x4(%esp)
8010225a:	89 14 24             	mov    %edx,(%esp)
8010225d:	e8 44 df ff ff       	call   801001a6 <bread>
80102262:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102265:	8b 45 10             	mov    0x10(%ebp),%eax
80102268:	25 ff 01 00 00       	and    $0x1ff,%eax
8010226d:	89 c2                	mov    %eax,%edx
8010226f:	b8 00 02 00 00       	mov    $0x200,%eax
80102274:	29 d0                	sub    %edx,%eax
80102276:	89 c2                	mov    %eax,%edx
80102278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010227b:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010227e:	29 c1                	sub    %eax,%ecx
80102280:	89 c8                	mov    %ecx,%eax
80102282:	39 c2                	cmp    %eax,%edx
80102284:	0f 46 c2             	cmovbe %edx,%eax
80102287:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010228a:	8b 45 10             	mov    0x10(%ebp),%eax
8010228d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102292:	8d 50 10             	lea    0x10(%eax),%edx
80102295:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102298:	01 d0                	add    %edx,%eax
8010229a:	8d 50 08             	lea    0x8(%eax),%edx
8010229d:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801022a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ab:	89 14 24             	mov    %edx,(%esp)
801022ae:	e8 9c 2d 00 00       	call   8010504f <memmove>
    log_write(bp);
801022b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b6:	89 04 24             	mov    %eax,(%esp)
801022b9:	e8 7e 12 00 00       	call   8010353c <log_write>
    brelse(bp);
801022be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022c1:	89 04 24             	mov    %eax,(%esp)
801022c4:	e8 4e df ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801022c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022cc:	01 45 f4             	add    %eax,-0xc(%ebp)
801022cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022d2:	01 45 10             	add    %eax,0x10(%ebp)
801022d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022d8:	01 45 0c             	add    %eax,0xc(%ebp)
801022db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022de:	3b 45 14             	cmp    0x14(%ebp),%eax
801022e1:	0f 82 55 ff ff ff    	jb     8010223c <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801022e7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801022eb:	74 1f                	je     8010230c <writei+0x18a>
801022ed:	8b 45 08             	mov    0x8(%ebp),%eax
801022f0:	8b 40 18             	mov    0x18(%eax),%eax
801022f3:	3b 45 10             	cmp    0x10(%ebp),%eax
801022f6:	73 14                	jae    8010230c <writei+0x18a>
    ip->size = off;
801022f8:	8b 45 08             	mov    0x8(%ebp),%eax
801022fb:	8b 55 10             	mov    0x10(%ebp),%edx
801022fe:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102301:	8b 45 08             	mov    0x8(%ebp),%eax
80102304:	89 04 24             	mov    %eax,(%esp)
80102307:	e8 7f f3 ff ff       	call   8010168b <iupdate>
  }
  return n;
8010230c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010230f:	c9                   	leave  
80102310:	c3                   	ret    

80102311 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102311:	55                   	push   %ebp
80102312:	89 e5                	mov    %esp,%ebp
80102314:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102317:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010231e:	00 
8010231f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102322:	89 44 24 04          	mov    %eax,0x4(%esp)
80102326:	8b 45 08             	mov    0x8(%ebp),%eax
80102329:	89 04 24             	mov    %eax,(%esp)
8010232c:	e8 c1 2d 00 00       	call   801050f2 <strncmp>
}
80102331:	c9                   	leave  
80102332:	c3                   	ret    

80102333 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102333:	55                   	push   %ebp
80102334:	89 e5                	mov    %esp,%ebp
80102336:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102339:	8b 45 08             	mov    0x8(%ebp),%eax
8010233c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102340:	66 83 f8 01          	cmp    $0x1,%ax
80102344:	74 0c                	je     80102352 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102346:	c7 04 24 e5 83 10 80 	movl   $0x801083e5,(%esp)
8010234d:	e8 e8 e1 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102352:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102359:	e9 88 00 00 00       	jmp    801023e6 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010235e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102365:	00 
80102366:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102369:	89 44 24 08          	mov    %eax,0x8(%esp)
8010236d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102370:	89 44 24 04          	mov    %eax,0x4(%esp)
80102374:	8b 45 08             	mov    0x8(%ebp),%eax
80102377:	89 04 24             	mov    %eax,(%esp)
8010237a:	e8 9f fc ff ff       	call   8010201e <readi>
8010237f:	83 f8 10             	cmp    $0x10,%eax
80102382:	74 0c                	je     80102390 <dirlookup+0x5d>
      panic("dirlink read");
80102384:	c7 04 24 f7 83 10 80 	movl   $0x801083f7,(%esp)
8010238b:	e8 aa e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102390:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102394:	66 85 c0             	test   %ax,%ax
80102397:	75 02                	jne    8010239b <dirlookup+0x68>
      continue;
80102399:	eb 47                	jmp    801023e2 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
8010239b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010239e:	83 c0 02             	add    $0x2,%eax
801023a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801023a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801023a8:	89 04 24             	mov    %eax,(%esp)
801023ab:	e8 61 ff ff ff       	call   80102311 <namecmp>
801023b0:	85 c0                	test   %eax,%eax
801023b2:	75 2e                	jne    801023e2 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801023b4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801023b8:	74 08                	je     801023c2 <dirlookup+0x8f>
        *poff = off;
801023ba:	8b 45 10             	mov    0x10(%ebp),%eax
801023bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023c0:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801023c2:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801023c6:	0f b7 c0             	movzwl %ax,%eax
801023c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801023cc:	8b 45 08             	mov    0x8(%ebp),%eax
801023cf:	8b 00                	mov    (%eax),%eax
801023d1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801023d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801023d8:	89 04 24             	mov    %eax,(%esp)
801023db:	e8 63 f3 ff ff       	call   80101743 <iget>
801023e0:	eb 18                	jmp    801023fa <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801023e2:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801023e6:	8b 45 08             	mov    0x8(%ebp),%eax
801023e9:	8b 40 18             	mov    0x18(%eax),%eax
801023ec:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801023ef:	0f 87 69 ff ff ff    	ja     8010235e <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801023f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801023fa:	c9                   	leave  
801023fb:	c3                   	ret    

801023fc <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801023fc:	55                   	push   %ebp
801023fd:	89 e5                	mov    %esp,%ebp
801023ff:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102402:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102409:	00 
8010240a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010240d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102411:	8b 45 08             	mov    0x8(%ebp),%eax
80102414:	89 04 24             	mov    %eax,(%esp)
80102417:	e8 17 ff ff ff       	call   80102333 <dirlookup>
8010241c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010241f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102423:	74 15                	je     8010243a <dirlink+0x3e>
    iput(ip);
80102425:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102428:	89 04 24             	mov    %eax,(%esp)
8010242b:	e8 ca f5 ff ff       	call   801019fa <iput>
    return -1;
80102430:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102435:	e9 b7 00 00 00       	jmp    801024f1 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010243a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102441:	eb 46                	jmp    80102489 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102446:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010244d:	00 
8010244e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102452:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102455:	89 44 24 04          	mov    %eax,0x4(%esp)
80102459:	8b 45 08             	mov    0x8(%ebp),%eax
8010245c:	89 04 24             	mov    %eax,(%esp)
8010245f:	e8 ba fb ff ff       	call   8010201e <readi>
80102464:	83 f8 10             	cmp    $0x10,%eax
80102467:	74 0c                	je     80102475 <dirlink+0x79>
      panic("dirlink read");
80102469:	c7 04 24 f7 83 10 80 	movl   $0x801083f7,(%esp)
80102470:	e8 c5 e0 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102475:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102479:	66 85 c0             	test   %ax,%ax
8010247c:	75 02                	jne    80102480 <dirlink+0x84>
      break;
8010247e:	eb 16                	jmp    80102496 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102480:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102483:	83 c0 10             	add    $0x10,%eax
80102486:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102489:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010248c:	8b 45 08             	mov    0x8(%ebp),%eax
8010248f:	8b 40 18             	mov    0x18(%eax),%eax
80102492:	39 c2                	cmp    %eax,%edx
80102494:	72 ad                	jb     80102443 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102496:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010249d:	00 
8010249e:	8b 45 0c             	mov    0xc(%ebp),%eax
801024a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801024a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801024a8:	83 c0 02             	add    $0x2,%eax
801024ab:	89 04 24             	mov    %eax,(%esp)
801024ae:	e8 95 2c 00 00       	call   80105148 <strncpy>
  de.inum = inum;
801024b3:	8b 45 10             	mov    0x10(%ebp),%eax
801024b6:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801024ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024bd:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801024c4:	00 
801024c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801024c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801024cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801024d0:	8b 45 08             	mov    0x8(%ebp),%eax
801024d3:	89 04 24             	mov    %eax,(%esp)
801024d6:	e8 a7 fc ff ff       	call   80102182 <writei>
801024db:	83 f8 10             	cmp    $0x10,%eax
801024de:	74 0c                	je     801024ec <dirlink+0xf0>
    panic("dirlink");
801024e0:	c7 04 24 04 84 10 80 	movl   $0x80108404,(%esp)
801024e7:	e8 4e e0 ff ff       	call   8010053a <panic>
  
  return 0;
801024ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
801024f1:	c9                   	leave  
801024f2:	c3                   	ret    

801024f3 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801024f3:	55                   	push   %ebp
801024f4:	89 e5                	mov    %esp,%ebp
801024f6:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801024f9:	eb 04                	jmp    801024ff <skipelem+0xc>
    path++;
801024fb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801024ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102502:	0f b6 00             	movzbl (%eax),%eax
80102505:	3c 2f                	cmp    $0x2f,%al
80102507:	74 f2                	je     801024fb <skipelem+0x8>
    path++;
  if(*path == 0)
80102509:	8b 45 08             	mov    0x8(%ebp),%eax
8010250c:	0f b6 00             	movzbl (%eax),%eax
8010250f:	84 c0                	test   %al,%al
80102511:	75 0a                	jne    8010251d <skipelem+0x2a>
    return 0;
80102513:	b8 00 00 00 00       	mov    $0x0,%eax
80102518:	e9 86 00 00 00       	jmp    801025a3 <skipelem+0xb0>
  s = path;
8010251d:	8b 45 08             	mov    0x8(%ebp),%eax
80102520:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102523:	eb 04                	jmp    80102529 <skipelem+0x36>
    path++;
80102525:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102529:	8b 45 08             	mov    0x8(%ebp),%eax
8010252c:	0f b6 00             	movzbl (%eax),%eax
8010252f:	3c 2f                	cmp    $0x2f,%al
80102531:	74 0a                	je     8010253d <skipelem+0x4a>
80102533:	8b 45 08             	mov    0x8(%ebp),%eax
80102536:	0f b6 00             	movzbl (%eax),%eax
80102539:	84 c0                	test   %al,%al
8010253b:	75 e8                	jne    80102525 <skipelem+0x32>
    path++;
  len = path - s;
8010253d:	8b 55 08             	mov    0x8(%ebp),%edx
80102540:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102543:	29 c2                	sub    %eax,%edx
80102545:	89 d0                	mov    %edx,%eax
80102547:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010254a:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010254e:	7e 1c                	jle    8010256c <skipelem+0x79>
    memmove(name, s, DIRSIZ);
80102550:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102557:	00 
80102558:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010255b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010255f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102562:	89 04 24             	mov    %eax,(%esp)
80102565:	e8 e5 2a 00 00       	call   8010504f <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010256a:	eb 2a                	jmp    80102596 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010256c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010256f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102573:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102576:	89 44 24 04          	mov    %eax,0x4(%esp)
8010257a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010257d:	89 04 24             	mov    %eax,(%esp)
80102580:	e8 ca 2a 00 00       	call   8010504f <memmove>
    name[len] = 0;
80102585:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102588:	8b 45 0c             	mov    0xc(%ebp),%eax
8010258b:	01 d0                	add    %edx,%eax
8010258d:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102590:	eb 04                	jmp    80102596 <skipelem+0xa3>
    path++;
80102592:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102596:	8b 45 08             	mov    0x8(%ebp),%eax
80102599:	0f b6 00             	movzbl (%eax),%eax
8010259c:	3c 2f                	cmp    $0x2f,%al
8010259e:	74 f2                	je     80102592 <skipelem+0x9f>
    path++;
  return path;
801025a0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801025a3:	c9                   	leave  
801025a4:	c3                   	ret    

801025a5 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801025a5:	55                   	push   %ebp
801025a6:	89 e5                	mov    %esp,%ebp
801025a8:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801025ab:	8b 45 08             	mov    0x8(%ebp),%eax
801025ae:	0f b6 00             	movzbl (%eax),%eax
801025b1:	3c 2f                	cmp    $0x2f,%al
801025b3:	75 1c                	jne    801025d1 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801025b5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801025bc:	00 
801025bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801025c4:	e8 7a f1 ff ff       	call   80101743 <iget>
801025c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801025cc:	e9 af 00 00 00       	jmp    80102680 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801025d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801025d7:	8b 40 68             	mov    0x68(%eax),%eax
801025da:	89 04 24             	mov    %eax,(%esp)
801025dd:	e8 33 f2 ff ff       	call   80101815 <idup>
801025e2:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801025e5:	e9 96 00 00 00       	jmp    80102680 <namex+0xdb>
    ilock(ip);
801025ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025ed:	89 04 24             	mov    %eax,(%esp)
801025f0:	e8 52 f2 ff ff       	call   80101847 <ilock>
    if(ip->type != T_DIR){
801025f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025f8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801025fc:	66 83 f8 01          	cmp    $0x1,%ax
80102600:	74 15                	je     80102617 <namex+0x72>
      iunlockput(ip);
80102602:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102605:	89 04 24             	mov    %eax,(%esp)
80102608:	e8 be f4 ff ff       	call   80101acb <iunlockput>
      return 0;
8010260d:	b8 00 00 00 00       	mov    $0x0,%eax
80102612:	e9 a3 00 00 00       	jmp    801026ba <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102617:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010261b:	74 1d                	je     8010263a <namex+0x95>
8010261d:	8b 45 08             	mov    0x8(%ebp),%eax
80102620:	0f b6 00             	movzbl (%eax),%eax
80102623:	84 c0                	test   %al,%al
80102625:	75 13                	jne    8010263a <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102627:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010262a:	89 04 24             	mov    %eax,(%esp)
8010262d:	e8 63 f3 ff ff       	call   80101995 <iunlock>
      return ip;
80102632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102635:	e9 80 00 00 00       	jmp    801026ba <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
8010263a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102641:	00 
80102642:	8b 45 10             	mov    0x10(%ebp),%eax
80102645:	89 44 24 04          	mov    %eax,0x4(%esp)
80102649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010264c:	89 04 24             	mov    %eax,(%esp)
8010264f:	e8 df fc ff ff       	call   80102333 <dirlookup>
80102654:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102657:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010265b:	75 12                	jne    8010266f <namex+0xca>
      iunlockput(ip);
8010265d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102660:	89 04 24             	mov    %eax,(%esp)
80102663:	e8 63 f4 ff ff       	call   80101acb <iunlockput>
      return 0;
80102668:	b8 00 00 00 00       	mov    $0x0,%eax
8010266d:	eb 4b                	jmp    801026ba <namex+0x115>
    }
    iunlockput(ip);
8010266f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102672:	89 04 24             	mov    %eax,(%esp)
80102675:	e8 51 f4 ff ff       	call   80101acb <iunlockput>
    ip = next;
8010267a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010267d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102680:	8b 45 10             	mov    0x10(%ebp),%eax
80102683:	89 44 24 04          	mov    %eax,0x4(%esp)
80102687:	8b 45 08             	mov    0x8(%ebp),%eax
8010268a:	89 04 24             	mov    %eax,(%esp)
8010268d:	e8 61 fe ff ff       	call   801024f3 <skipelem>
80102692:	89 45 08             	mov    %eax,0x8(%ebp)
80102695:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102699:	0f 85 4b ff ff ff    	jne    801025ea <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010269f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801026a3:	74 12                	je     801026b7 <namex+0x112>
    iput(ip);
801026a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026a8:	89 04 24             	mov    %eax,(%esp)
801026ab:	e8 4a f3 ff ff       	call   801019fa <iput>
    return 0;
801026b0:	b8 00 00 00 00       	mov    $0x0,%eax
801026b5:	eb 03                	jmp    801026ba <namex+0x115>
  }
  return ip;
801026b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801026ba:	c9                   	leave  
801026bb:	c3                   	ret    

801026bc <namei>:

struct inode*
namei(char *path)
{
801026bc:	55                   	push   %ebp
801026bd:	89 e5                	mov    %esp,%ebp
801026bf:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801026c2:	8d 45 ea             	lea    -0x16(%ebp),%eax
801026c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801026c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026d0:	00 
801026d1:	8b 45 08             	mov    0x8(%ebp),%eax
801026d4:	89 04 24             	mov    %eax,(%esp)
801026d7:	e8 c9 fe ff ff       	call   801025a5 <namex>
}
801026dc:	c9                   	leave  
801026dd:	c3                   	ret    

801026de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801026de:	55                   	push   %ebp
801026df:	89 e5                	mov    %esp,%ebp
801026e1:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801026e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801026e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801026eb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801026f2:	00 
801026f3:	8b 45 08             	mov    0x8(%ebp),%eax
801026f6:	89 04 24             	mov    %eax,(%esp)
801026f9:	e8 a7 fe ff ff       	call   801025a5 <namex>
}
801026fe:	c9                   	leave  
801026ff:	c3                   	ret    

80102700 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102700:	55                   	push   %ebp
80102701:	89 e5                	mov    %esp,%ebp
80102703:	83 ec 14             	sub    $0x14,%esp
80102706:	8b 45 08             	mov    0x8(%ebp),%eax
80102709:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010270d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102711:	89 c2                	mov    %eax,%edx
80102713:	ec                   	in     (%dx),%al
80102714:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102717:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010271b:	c9                   	leave  
8010271c:	c3                   	ret    

8010271d <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010271d:	55                   	push   %ebp
8010271e:	89 e5                	mov    %esp,%ebp
80102720:	57                   	push   %edi
80102721:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102722:	8b 55 08             	mov    0x8(%ebp),%edx
80102725:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102728:	8b 45 10             	mov    0x10(%ebp),%eax
8010272b:	89 cb                	mov    %ecx,%ebx
8010272d:	89 df                	mov    %ebx,%edi
8010272f:	89 c1                	mov    %eax,%ecx
80102731:	fc                   	cld    
80102732:	f3 6d                	rep insl (%dx),%es:(%edi)
80102734:	89 c8                	mov    %ecx,%eax
80102736:	89 fb                	mov    %edi,%ebx
80102738:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010273b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010273e:	5b                   	pop    %ebx
8010273f:	5f                   	pop    %edi
80102740:	5d                   	pop    %ebp
80102741:	c3                   	ret    

80102742 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102742:	55                   	push   %ebp
80102743:	89 e5                	mov    %esp,%ebp
80102745:	83 ec 08             	sub    $0x8,%esp
80102748:	8b 55 08             	mov    0x8(%ebp),%edx
8010274b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010274e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102752:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102755:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102759:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010275d:	ee                   	out    %al,(%dx)
}
8010275e:	c9                   	leave  
8010275f:	c3                   	ret    

80102760 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102760:	55                   	push   %ebp
80102761:	89 e5                	mov    %esp,%ebp
80102763:	56                   	push   %esi
80102764:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102765:	8b 55 08             	mov    0x8(%ebp),%edx
80102768:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010276b:	8b 45 10             	mov    0x10(%ebp),%eax
8010276e:	89 cb                	mov    %ecx,%ebx
80102770:	89 de                	mov    %ebx,%esi
80102772:	89 c1                	mov    %eax,%ecx
80102774:	fc                   	cld    
80102775:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102777:	89 c8                	mov    %ecx,%eax
80102779:	89 f3                	mov    %esi,%ebx
8010277b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010277e:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102781:	5b                   	pop    %ebx
80102782:	5e                   	pop    %esi
80102783:	5d                   	pop    %ebp
80102784:	c3                   	ret    

80102785 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102785:	55                   	push   %ebp
80102786:	89 e5                	mov    %esp,%ebp
80102788:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010278b:	90                   	nop
8010278c:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102793:	e8 68 ff ff ff       	call   80102700 <inb>
80102798:	0f b6 c0             	movzbl %al,%eax
8010279b:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010279e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801027a1:	25 c0 00 00 00       	and    $0xc0,%eax
801027a6:	83 f8 40             	cmp    $0x40,%eax
801027a9:	75 e1                	jne    8010278c <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801027ab:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801027af:	74 11                	je     801027c2 <idewait+0x3d>
801027b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801027b4:	83 e0 21             	and    $0x21,%eax
801027b7:	85 c0                	test   %eax,%eax
801027b9:	74 07                	je     801027c2 <idewait+0x3d>
    return -1;
801027bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801027c0:	eb 05                	jmp    801027c7 <idewait+0x42>
  return 0;
801027c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801027c7:	c9                   	leave  
801027c8:	c3                   	ret    

801027c9 <ideinit>:

void
ideinit(void)
{
801027c9:	55                   	push   %ebp
801027ca:	89 e5                	mov    %esp,%ebp
801027cc:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801027cf:	c7 44 24 04 0c 84 10 	movl   $0x8010840c,0x4(%esp)
801027d6:	80 
801027d7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027de:	e8 28 25 00 00       	call   80104d0b <initlock>
  picenable(IRQ_IDE);
801027e3:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801027ea:	e8 29 15 00 00       	call   80103d18 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801027ef:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801027f4:	83 e8 01             	sub    $0x1,%eax
801027f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801027fb:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102802:	e8 0c 04 00 00       	call   80102c13 <ioapicenable>
  idewait(0);
80102807:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010280e:	e8 72 ff ff ff       	call   80102785 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102813:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010281a:	00 
8010281b:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102822:	e8 1b ff ff ff       	call   80102742 <outb>
  for(i=0; i<1000; i++){
80102827:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010282e:	eb 20                	jmp    80102850 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102830:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102837:	e8 c4 fe ff ff       	call   80102700 <inb>
8010283c:	84 c0                	test   %al,%al
8010283e:	74 0c                	je     8010284c <ideinit+0x83>
      havedisk1 = 1;
80102840:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102847:	00 00 00 
      break;
8010284a:	eb 0d                	jmp    80102859 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
8010284c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102850:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102857:	7e d7                	jle    80102830 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102859:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102860:	00 
80102861:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102868:	e8 d5 fe ff ff       	call   80102742 <outb>
}
8010286d:	c9                   	leave  
8010286e:	c3                   	ret    

8010286f <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010286f:	55                   	push   %ebp
80102870:	89 e5                	mov    %esp,%ebp
80102872:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102875:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102879:	75 0c                	jne    80102887 <idestart+0x18>
    panic("idestart");
8010287b:	c7 04 24 10 84 10 80 	movl   $0x80108410,(%esp)
80102882:	e8 b3 dc ff ff       	call   8010053a <panic>

  idewait(0);
80102887:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010288e:	e8 f2 fe ff ff       	call   80102785 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102893:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010289a:	00 
8010289b:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801028a2:	e8 9b fe ff ff       	call   80102742 <outb>
  outb(0x1f2, 1);  // number of sectors
801028a7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801028ae:	00 
801028af:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801028b6:	e8 87 fe ff ff       	call   80102742 <outb>
  outb(0x1f3, b->sector & 0xff);
801028bb:	8b 45 08             	mov    0x8(%ebp),%eax
801028be:	8b 40 08             	mov    0x8(%eax),%eax
801028c1:	0f b6 c0             	movzbl %al,%eax
801028c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801028c8:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801028cf:	e8 6e fe ff ff       	call   80102742 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801028d4:	8b 45 08             	mov    0x8(%ebp),%eax
801028d7:	8b 40 08             	mov    0x8(%eax),%eax
801028da:	c1 e8 08             	shr    $0x8,%eax
801028dd:	0f b6 c0             	movzbl %al,%eax
801028e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801028e4:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801028eb:	e8 52 fe ff ff       	call   80102742 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801028f0:	8b 45 08             	mov    0x8(%ebp),%eax
801028f3:	8b 40 08             	mov    0x8(%eax),%eax
801028f6:	c1 e8 10             	shr    $0x10,%eax
801028f9:	0f b6 c0             	movzbl %al,%eax
801028fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102900:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102907:	e8 36 fe ff ff       	call   80102742 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
8010290c:	8b 45 08             	mov    0x8(%ebp),%eax
8010290f:	8b 40 04             	mov    0x4(%eax),%eax
80102912:	83 e0 01             	and    $0x1,%eax
80102915:	c1 e0 04             	shl    $0x4,%eax
80102918:	89 c2                	mov    %eax,%edx
8010291a:	8b 45 08             	mov    0x8(%ebp),%eax
8010291d:	8b 40 08             	mov    0x8(%eax),%eax
80102920:	c1 e8 18             	shr    $0x18,%eax
80102923:	83 e0 0f             	and    $0xf,%eax
80102926:	09 d0                	or     %edx,%eax
80102928:	83 c8 e0             	or     $0xffffffe0,%eax
8010292b:	0f b6 c0             	movzbl %al,%eax
8010292e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102932:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102939:	e8 04 fe ff ff       	call   80102742 <outb>
  if(b->flags & B_DIRTY){
8010293e:	8b 45 08             	mov    0x8(%ebp),%eax
80102941:	8b 00                	mov    (%eax),%eax
80102943:	83 e0 04             	and    $0x4,%eax
80102946:	85 c0                	test   %eax,%eax
80102948:	74 34                	je     8010297e <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010294a:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102951:	00 
80102952:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102959:	e8 e4 fd ff ff       	call   80102742 <outb>
    outsl(0x1f0, b->data, 512/4);
8010295e:	8b 45 08             	mov    0x8(%ebp),%eax
80102961:	83 c0 18             	add    $0x18,%eax
80102964:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010296b:	00 
8010296c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102970:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102977:	e8 e4 fd ff ff       	call   80102760 <outsl>
8010297c:	eb 14                	jmp    80102992 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010297e:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102985:	00 
80102986:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010298d:	e8 b0 fd ff ff       	call   80102742 <outb>
  }
}
80102992:	c9                   	leave  
80102993:	c3                   	ret    

80102994 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102994:	55                   	push   %ebp
80102995:	89 e5                	mov    %esp,%ebp
80102997:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010299a:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801029a1:	e8 86 23 00 00       	call   80104d2c <acquire>
  if((b = idequeue) == 0){
801029a6:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801029ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801029b2:	75 11                	jne    801029c5 <ideintr+0x31>
    release(&idelock);
801029b4:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801029bb:	e8 ce 23 00 00       	call   80104d8e <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801029c0:	e9 90 00 00 00       	jmp    80102a55 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801029c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029c8:	8b 40 14             	mov    0x14(%eax),%eax
801029cb:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801029d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029d3:	8b 00                	mov    (%eax),%eax
801029d5:	83 e0 04             	and    $0x4,%eax
801029d8:	85 c0                	test   %eax,%eax
801029da:	75 2e                	jne    80102a0a <ideintr+0x76>
801029dc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029e3:	e8 9d fd ff ff       	call   80102785 <idewait>
801029e8:	85 c0                	test   %eax,%eax
801029ea:	78 1e                	js     80102a0a <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801029ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ef:	83 c0 18             	add    $0x18,%eax
801029f2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801029f9:	00 
801029fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801029fe:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102a05:	e8 13 fd ff ff       	call   8010271d <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a0d:	8b 00                	mov    (%eax),%eax
80102a0f:	83 c8 02             	or     $0x2,%eax
80102a12:	89 c2                	mov    %eax,%edx
80102a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a17:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a1c:	8b 00                	mov    (%eax),%eax
80102a1e:	83 e0 fb             	and    $0xfffffffb,%eax
80102a21:	89 c2                	mov    %eax,%edx
80102a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a26:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a2b:	89 04 24             	mov    %eax,(%esp)
80102a2e:	e8 08 21 00 00       	call   80104b3b <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102a33:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102a38:	85 c0                	test   %eax,%eax
80102a3a:	74 0d                	je     80102a49 <ideintr+0xb5>
    idestart(idequeue);
80102a3c:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102a41:	89 04 24             	mov    %eax,(%esp)
80102a44:	e8 26 fe ff ff       	call   8010286f <idestart>

  release(&idelock);
80102a49:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102a50:	e8 39 23 00 00       	call   80104d8e <release>
}
80102a55:	c9                   	leave  
80102a56:	c3                   	ret    

80102a57 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102a57:	55                   	push   %ebp
80102a58:	89 e5                	mov    %esp,%ebp
80102a5a:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102a5d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a60:	8b 00                	mov    (%eax),%eax
80102a62:	83 e0 01             	and    $0x1,%eax
80102a65:	85 c0                	test   %eax,%eax
80102a67:	75 0c                	jne    80102a75 <iderw+0x1e>
    panic("iderw: buf not busy");
80102a69:	c7 04 24 19 84 10 80 	movl   $0x80108419,(%esp)
80102a70:	e8 c5 da ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102a75:	8b 45 08             	mov    0x8(%ebp),%eax
80102a78:	8b 00                	mov    (%eax),%eax
80102a7a:	83 e0 06             	and    $0x6,%eax
80102a7d:	83 f8 02             	cmp    $0x2,%eax
80102a80:	75 0c                	jne    80102a8e <iderw+0x37>
    panic("iderw: nothing to do");
80102a82:	c7 04 24 2d 84 10 80 	movl   $0x8010842d,(%esp)
80102a89:	e8 ac da ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102a8e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a91:	8b 40 04             	mov    0x4(%eax),%eax
80102a94:	85 c0                	test   %eax,%eax
80102a96:	74 15                	je     80102aad <iderw+0x56>
80102a98:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102a9d:	85 c0                	test   %eax,%eax
80102a9f:	75 0c                	jne    80102aad <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102aa1:	c7 04 24 42 84 10 80 	movl   $0x80108442,(%esp)
80102aa8:	e8 8d da ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102aad:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102ab4:	e8 73 22 00 00       	call   80104d2c <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102ab9:	8b 45 08             	mov    0x8(%ebp),%eax
80102abc:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102ac3:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102aca:	eb 0b                	jmp    80102ad7 <iderw+0x80>
80102acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102acf:	8b 00                	mov    (%eax),%eax
80102ad1:	83 c0 14             	add    $0x14,%eax
80102ad4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ada:	8b 00                	mov    (%eax),%eax
80102adc:	85 c0                	test   %eax,%eax
80102ade:	75 ec                	jne    80102acc <iderw+0x75>
    ;
  *pp = b;
80102ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ae3:	8b 55 08             	mov    0x8(%ebp),%edx
80102ae6:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102ae8:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102aed:	3b 45 08             	cmp    0x8(%ebp),%eax
80102af0:	75 0d                	jne    80102aff <iderw+0xa8>
    idestart(b);
80102af2:	8b 45 08             	mov    0x8(%ebp),%eax
80102af5:	89 04 24             	mov    %eax,(%esp)
80102af8:	e8 72 fd ff ff       	call   8010286f <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102afd:	eb 15                	jmp    80102b14 <iderw+0xbd>
80102aff:	eb 13                	jmp    80102b14 <iderw+0xbd>
    sleep(b, &idelock);
80102b01:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
80102b08:	80 
80102b09:	8b 45 08             	mov    0x8(%ebp),%eax
80102b0c:	89 04 24             	mov    %eax,(%esp)
80102b0f:	e8 4e 1f 00 00       	call   80104a62 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102b14:	8b 45 08             	mov    0x8(%ebp),%eax
80102b17:	8b 00                	mov    (%eax),%eax
80102b19:	83 e0 06             	and    $0x6,%eax
80102b1c:	83 f8 02             	cmp    $0x2,%eax
80102b1f:	75 e0                	jne    80102b01 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102b21:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102b28:	e8 61 22 00 00       	call   80104d8e <release>
}
80102b2d:	c9                   	leave  
80102b2e:	c3                   	ret    

80102b2f <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102b2f:	55                   	push   %ebp
80102b30:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102b32:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102b37:	8b 55 08             	mov    0x8(%ebp),%edx
80102b3a:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102b3c:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102b41:	8b 40 10             	mov    0x10(%eax),%eax
}
80102b44:	5d                   	pop    %ebp
80102b45:	c3                   	ret    

80102b46 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102b46:	55                   	push   %ebp
80102b47:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102b49:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102b4e:	8b 55 08             	mov    0x8(%ebp),%edx
80102b51:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102b53:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102b58:	8b 55 0c             	mov    0xc(%ebp),%edx
80102b5b:	89 50 10             	mov    %edx,0x10(%eax)
}
80102b5e:	5d                   	pop    %ebp
80102b5f:	c3                   	ret    

80102b60 <ioapicinit>:

void
ioapicinit(void)
{
80102b60:	55                   	push   %ebp
80102b61:	89 e5                	mov    %esp,%ebp
80102b63:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102b66:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80102b6b:	85 c0                	test   %eax,%eax
80102b6d:	75 05                	jne    80102b74 <ioapicinit+0x14>
    return;
80102b6f:	e9 9d 00 00 00       	jmp    80102c11 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102b74:	c7 05 34 f8 10 80 00 	movl   $0xfec00000,0x8010f834
80102b7b:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102b7e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102b85:	e8 a5 ff ff ff       	call   80102b2f <ioapicread>
80102b8a:	c1 e8 10             	shr    $0x10,%eax
80102b8d:	25 ff 00 00 00       	and    $0xff,%eax
80102b92:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102b95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102b9c:	e8 8e ff ff ff       	call   80102b2f <ioapicread>
80102ba1:	c1 e8 18             	shr    $0x18,%eax
80102ba4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102ba7:	0f b6 05 00 f9 10 80 	movzbl 0x8010f900,%eax
80102bae:	0f b6 c0             	movzbl %al,%eax
80102bb1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102bb4:	74 0c                	je     80102bc2 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102bb6:	c7 04 24 60 84 10 80 	movl   $0x80108460,(%esp)
80102bbd:	e8 de d7 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102bc2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bc9:	eb 3e                	jmp    80102c09 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bce:	83 c0 20             	add    $0x20,%eax
80102bd1:	0d 00 00 01 00       	or     $0x10000,%eax
80102bd6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102bd9:	83 c2 08             	add    $0x8,%edx
80102bdc:	01 d2                	add    %edx,%edx
80102bde:	89 44 24 04          	mov    %eax,0x4(%esp)
80102be2:	89 14 24             	mov    %edx,(%esp)
80102be5:	e8 5c ff ff ff       	call   80102b46 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102bea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bed:	83 c0 08             	add    $0x8,%eax
80102bf0:	01 c0                	add    %eax,%eax
80102bf2:	83 c0 01             	add    $0x1,%eax
80102bf5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102bfc:	00 
80102bfd:	89 04 24             	mov    %eax,(%esp)
80102c00:	e8 41 ff ff ff       	call   80102b46 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102c05:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c0c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102c0f:	7e ba                	jle    80102bcb <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102c11:	c9                   	leave  
80102c12:	c3                   	ret    

80102c13 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102c13:	55                   	push   %ebp
80102c14:	89 e5                	mov    %esp,%ebp
80102c16:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102c19:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80102c1e:	85 c0                	test   %eax,%eax
80102c20:	75 02                	jne    80102c24 <ioapicenable+0x11>
    return;
80102c22:	eb 37                	jmp    80102c5b <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102c24:	8b 45 08             	mov    0x8(%ebp),%eax
80102c27:	83 c0 20             	add    $0x20,%eax
80102c2a:	8b 55 08             	mov    0x8(%ebp),%edx
80102c2d:	83 c2 08             	add    $0x8,%edx
80102c30:	01 d2                	add    %edx,%edx
80102c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c36:	89 14 24             	mov    %edx,(%esp)
80102c39:	e8 08 ff ff ff       	call   80102b46 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102c3e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c41:	c1 e0 18             	shl    $0x18,%eax
80102c44:	8b 55 08             	mov    0x8(%ebp),%edx
80102c47:	83 c2 08             	add    $0x8,%edx
80102c4a:	01 d2                	add    %edx,%edx
80102c4c:	83 c2 01             	add    $0x1,%edx
80102c4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c53:	89 14 24             	mov    %edx,(%esp)
80102c56:	e8 eb fe ff ff       	call   80102b46 <ioapicwrite>
}
80102c5b:	c9                   	leave  
80102c5c:	c3                   	ret    

80102c5d <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102c5d:	55                   	push   %ebp
80102c5e:	89 e5                	mov    %esp,%ebp
80102c60:	8b 45 08             	mov    0x8(%ebp),%eax
80102c63:	05 00 00 00 80       	add    $0x80000000,%eax
80102c68:	5d                   	pop    %ebp
80102c69:	c3                   	ret    

80102c6a <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102c6a:	55                   	push   %ebp
80102c6b:	89 e5                	mov    %esp,%ebp
80102c6d:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102c70:	c7 44 24 04 92 84 10 	movl   $0x80108492,0x4(%esp)
80102c77:	80 
80102c78:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102c7f:	e8 87 20 00 00       	call   80104d0b <initlock>
  kmem.use_lock = 0;
80102c84:	c7 05 74 f8 10 80 00 	movl   $0x0,0x8010f874
80102c8b:	00 00 00 
  freerange(vstart, vend);
80102c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c91:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c95:	8b 45 08             	mov    0x8(%ebp),%eax
80102c98:	89 04 24             	mov    %eax,(%esp)
80102c9b:	e8 26 00 00 00       	call   80102cc6 <freerange>
}
80102ca0:	c9                   	leave  
80102ca1:	c3                   	ret    

80102ca2 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102ca2:	55                   	push   %ebp
80102ca3:	89 e5                	mov    %esp,%ebp
80102ca5:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102ca8:	8b 45 0c             	mov    0xc(%ebp),%eax
80102cab:	89 44 24 04          	mov    %eax,0x4(%esp)
80102caf:	8b 45 08             	mov    0x8(%ebp),%eax
80102cb2:	89 04 24             	mov    %eax,(%esp)
80102cb5:	e8 0c 00 00 00       	call   80102cc6 <freerange>
  kmem.use_lock = 1;
80102cba:	c7 05 74 f8 10 80 01 	movl   $0x1,0x8010f874
80102cc1:	00 00 00 
}
80102cc4:	c9                   	leave  
80102cc5:	c3                   	ret    

80102cc6 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102cc6:	55                   	push   %ebp
80102cc7:	89 e5                	mov    %esp,%ebp
80102cc9:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102ccc:	8b 45 08             	mov    0x8(%ebp),%eax
80102ccf:	05 ff 0f 00 00       	add    $0xfff,%eax
80102cd4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102cd9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102cdc:	eb 12                	jmp    80102cf0 <freerange+0x2a>
    kfree(p);
80102cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce1:	89 04 24             	mov    %eax,(%esp)
80102ce4:	e8 16 00 00 00       	call   80102cff <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102ce9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cf3:	05 00 10 00 00       	add    $0x1000,%eax
80102cf8:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102cfb:	76 e1                	jbe    80102cde <freerange+0x18>
    kfree(p);
}
80102cfd:	c9                   	leave  
80102cfe:	c3                   	ret    

80102cff <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102cff:	55                   	push   %ebp
80102d00:	89 e5                	mov    %esp,%ebp
80102d02:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102d05:	8b 45 08             	mov    0x8(%ebp),%eax
80102d08:	25 ff 0f 00 00       	and    $0xfff,%eax
80102d0d:	85 c0                	test   %eax,%eax
80102d0f:	75 1b                	jne    80102d2c <kfree+0x2d>
80102d11:	81 7d 08 fc 26 11 80 	cmpl   $0x801126fc,0x8(%ebp)
80102d18:	72 12                	jb     80102d2c <kfree+0x2d>
80102d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80102d1d:	89 04 24             	mov    %eax,(%esp)
80102d20:	e8 38 ff ff ff       	call   80102c5d <v2p>
80102d25:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102d2a:	76 0c                	jbe    80102d38 <kfree+0x39>
    panic("kfree");
80102d2c:	c7 04 24 97 84 10 80 	movl   $0x80108497,(%esp)
80102d33:	e8 02 d8 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102d38:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102d3f:	00 
80102d40:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d47:	00 
80102d48:	8b 45 08             	mov    0x8(%ebp),%eax
80102d4b:	89 04 24             	mov    %eax,(%esp)
80102d4e:	e8 2d 22 00 00       	call   80104f80 <memset>

  if(kmem.use_lock)
80102d53:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102d58:	85 c0                	test   %eax,%eax
80102d5a:	74 0c                	je     80102d68 <kfree+0x69>
    acquire(&kmem.lock);
80102d5c:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102d63:	e8 c4 1f 00 00       	call   80104d2c <acquire>
  r = (struct run*)v;
80102d68:	8b 45 08             	mov    0x8(%ebp),%eax
80102d6b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102d6e:	8b 15 78 f8 10 80    	mov    0x8010f878,%edx
80102d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d77:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d7c:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102d81:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102d86:	85 c0                	test   %eax,%eax
80102d88:	74 0c                	je     80102d96 <kfree+0x97>
    release(&kmem.lock);
80102d8a:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102d91:	e8 f8 1f 00 00       	call   80104d8e <release>
}
80102d96:	c9                   	leave  
80102d97:	c3                   	ret    

80102d98 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102d98:	55                   	push   %ebp
80102d99:	89 e5                	mov    %esp,%ebp
80102d9b:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102d9e:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102da3:	85 c0                	test   %eax,%eax
80102da5:	74 0c                	je     80102db3 <kalloc+0x1b>
    acquire(&kmem.lock);
80102da7:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102dae:	e8 79 1f 00 00       	call   80104d2c <acquire>
  r = kmem.freelist;
80102db3:	a1 78 f8 10 80       	mov    0x8010f878,%eax
80102db8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102dbb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102dbf:	74 0a                	je     80102dcb <kalloc+0x33>
    kmem.freelist = r->next;
80102dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc4:	8b 00                	mov    (%eax),%eax
80102dc6:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102dcb:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102dd0:	85 c0                	test   %eax,%eax
80102dd2:	74 0c                	je     80102de0 <kalloc+0x48>
    release(&kmem.lock);
80102dd4:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102ddb:	e8 ae 1f 00 00       	call   80104d8e <release>
  return (char*)r;
80102de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102de3:	c9                   	leave  
80102de4:	c3                   	ret    

80102de5 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102de5:	55                   	push   %ebp
80102de6:	89 e5                	mov    %esp,%ebp
80102de8:	83 ec 14             	sub    $0x14,%esp
80102deb:	8b 45 08             	mov    0x8(%ebp),%eax
80102dee:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102df2:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102df6:	89 c2                	mov    %eax,%edx
80102df8:	ec                   	in     (%dx),%al
80102df9:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102dfc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102e00:	c9                   	leave  
80102e01:	c3                   	ret    

80102e02 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102e02:	55                   	push   %ebp
80102e03:	89 e5                	mov    %esp,%ebp
80102e05:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102e08:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102e0f:	e8 d1 ff ff ff       	call   80102de5 <inb>
80102e14:	0f b6 c0             	movzbl %al,%eax
80102e17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e1d:	83 e0 01             	and    $0x1,%eax
80102e20:	85 c0                	test   %eax,%eax
80102e22:	75 0a                	jne    80102e2e <kbdgetc+0x2c>
    return -1;
80102e24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e29:	e9 25 01 00 00       	jmp    80102f53 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102e2e:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102e35:	e8 ab ff ff ff       	call   80102de5 <inb>
80102e3a:	0f b6 c0             	movzbl %al,%eax
80102e3d:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102e40:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102e47:	75 17                	jne    80102e60 <kbdgetc+0x5e>
    shift |= E0ESC;
80102e49:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e4e:	83 c8 40             	or     $0x40,%eax
80102e51:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102e56:	b8 00 00 00 00       	mov    $0x0,%eax
80102e5b:	e9 f3 00 00 00       	jmp    80102f53 <kbdgetc+0x151>
  } else if(data & 0x80){
80102e60:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e63:	25 80 00 00 00       	and    $0x80,%eax
80102e68:	85 c0                	test   %eax,%eax
80102e6a:	74 45                	je     80102eb1 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102e6c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e71:	83 e0 40             	and    $0x40,%eax
80102e74:	85 c0                	test   %eax,%eax
80102e76:	75 08                	jne    80102e80 <kbdgetc+0x7e>
80102e78:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e7b:	83 e0 7f             	and    $0x7f,%eax
80102e7e:	eb 03                	jmp    80102e83 <kbdgetc+0x81>
80102e80:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e83:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102e86:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e89:	05 20 90 10 80       	add    $0x80109020,%eax
80102e8e:	0f b6 00             	movzbl (%eax),%eax
80102e91:	83 c8 40             	or     $0x40,%eax
80102e94:	0f b6 c0             	movzbl %al,%eax
80102e97:	f7 d0                	not    %eax
80102e99:	89 c2                	mov    %eax,%edx
80102e9b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ea0:	21 d0                	and    %edx,%eax
80102ea2:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102ea7:	b8 00 00 00 00       	mov    $0x0,%eax
80102eac:	e9 a2 00 00 00       	jmp    80102f53 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102eb1:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102eb6:	83 e0 40             	and    $0x40,%eax
80102eb9:	85 c0                	test   %eax,%eax
80102ebb:	74 14                	je     80102ed1 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102ebd:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102ec4:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ec9:	83 e0 bf             	and    $0xffffffbf,%eax
80102ecc:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102ed1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ed4:	05 20 90 10 80       	add    $0x80109020,%eax
80102ed9:	0f b6 00             	movzbl (%eax),%eax
80102edc:	0f b6 d0             	movzbl %al,%edx
80102edf:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ee4:	09 d0                	or     %edx,%eax
80102ee6:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102eeb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102eee:	05 20 91 10 80       	add    $0x80109120,%eax
80102ef3:	0f b6 00             	movzbl (%eax),%eax
80102ef6:	0f b6 d0             	movzbl %al,%edx
80102ef9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102efe:	31 d0                	xor    %edx,%eax
80102f00:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102f05:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102f0a:	83 e0 03             	and    $0x3,%eax
80102f0d:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102f14:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102f17:	01 d0                	add    %edx,%eax
80102f19:	0f b6 00             	movzbl (%eax),%eax
80102f1c:	0f b6 c0             	movzbl %al,%eax
80102f1f:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102f22:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102f27:	83 e0 08             	and    $0x8,%eax
80102f2a:	85 c0                	test   %eax,%eax
80102f2c:	74 22                	je     80102f50 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102f2e:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102f32:	76 0c                	jbe    80102f40 <kbdgetc+0x13e>
80102f34:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102f38:	77 06                	ja     80102f40 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102f3a:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102f3e:	eb 10                	jmp    80102f50 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102f40:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102f44:	76 0a                	jbe    80102f50 <kbdgetc+0x14e>
80102f46:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102f4a:	77 04                	ja     80102f50 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102f4c:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102f50:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102f53:	c9                   	leave  
80102f54:	c3                   	ret    

80102f55 <kbdintr>:

void
kbdintr(void)
{
80102f55:	55                   	push   %ebp
80102f56:	89 e5                	mov    %esp,%ebp
80102f58:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102f5b:	c7 04 24 02 2e 10 80 	movl   $0x80102e02,(%esp)
80102f62:	e8 46 d8 ff ff       	call   801007ad <consoleintr>
}
80102f67:	c9                   	leave  
80102f68:	c3                   	ret    

80102f69 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102f69:	55                   	push   %ebp
80102f6a:	89 e5                	mov    %esp,%ebp
80102f6c:	83 ec 08             	sub    $0x8,%esp
80102f6f:	8b 55 08             	mov    0x8(%ebp),%edx
80102f72:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f75:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102f79:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f7c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102f80:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102f84:	ee                   	out    %al,(%dx)
}
80102f85:	c9                   	leave  
80102f86:	c3                   	ret    

80102f87 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102f87:	55                   	push   %ebp
80102f88:	89 e5                	mov    %esp,%ebp
80102f8a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102f8d:	9c                   	pushf  
80102f8e:	58                   	pop    %eax
80102f8f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102f92:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102f95:	c9                   	leave  
80102f96:	c3                   	ret    

80102f97 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102f97:	55                   	push   %ebp
80102f98:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102f9a:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102f9f:	8b 55 08             	mov    0x8(%ebp),%edx
80102fa2:	c1 e2 02             	shl    $0x2,%edx
80102fa5:	01 c2                	add    %eax,%edx
80102fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102faa:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102fac:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102fb1:	83 c0 20             	add    $0x20,%eax
80102fb4:	8b 00                	mov    (%eax),%eax
}
80102fb6:	5d                   	pop    %ebp
80102fb7:	c3                   	ret    

80102fb8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102fb8:	55                   	push   %ebp
80102fb9:	89 e5                	mov    %esp,%ebp
80102fbb:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102fbe:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102fc3:	85 c0                	test   %eax,%eax
80102fc5:	75 05                	jne    80102fcc <lapicinit+0x14>
    return;
80102fc7:	e9 43 01 00 00       	jmp    8010310f <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102fcc:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102fd3:	00 
80102fd4:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102fdb:	e8 b7 ff ff ff       	call   80102f97 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102fe0:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102fe7:	00 
80102fe8:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102fef:	e8 a3 ff ff ff       	call   80102f97 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102ff4:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102ffb:	00 
80102ffc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103003:	e8 8f ff ff ff       	call   80102f97 <lapicw>
  lapicw(TICR, 10000000); 
80103008:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010300f:	00 
80103010:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103017:	e8 7b ff ff ff       	call   80102f97 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010301c:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103023:	00 
80103024:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010302b:	e8 67 ff ff ff       	call   80102f97 <lapicw>
  lapicw(LINT1, MASKED);
80103030:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103037:	00 
80103038:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010303f:	e8 53 ff ff ff       	call   80102f97 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103044:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80103049:	83 c0 30             	add    $0x30,%eax
8010304c:	8b 00                	mov    (%eax),%eax
8010304e:	c1 e8 10             	shr    $0x10,%eax
80103051:	0f b6 c0             	movzbl %al,%eax
80103054:	83 f8 03             	cmp    $0x3,%eax
80103057:	76 14                	jbe    8010306d <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103059:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103060:	00 
80103061:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103068:	e8 2a ff ff ff       	call   80102f97 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010306d:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103074:	00 
80103075:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010307c:	e8 16 ff ff ff       	call   80102f97 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103081:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103088:	00 
80103089:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103090:	e8 02 ff ff ff       	call   80102f97 <lapicw>
  lapicw(ESR, 0);
80103095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010309c:	00 
8010309d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801030a4:	e8 ee fe ff ff       	call   80102f97 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801030a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030b0:	00 
801030b1:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801030b8:	e8 da fe ff ff       	call   80102f97 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801030bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030c4:	00 
801030c5:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030cc:	e8 c6 fe ff ff       	call   80102f97 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801030d1:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801030d8:	00 
801030d9:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030e0:	e8 b2 fe ff ff       	call   80102f97 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801030e5:	90                   	nop
801030e6:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
801030eb:	05 00 03 00 00       	add    $0x300,%eax
801030f0:	8b 00                	mov    (%eax),%eax
801030f2:	25 00 10 00 00       	and    $0x1000,%eax
801030f7:	85 c0                	test   %eax,%eax
801030f9:	75 eb                	jne    801030e6 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801030fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103102:	00 
80103103:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010310a:	e8 88 fe ff ff       	call   80102f97 <lapicw>
}
8010310f:	c9                   	leave  
80103110:	c3                   	ret    

80103111 <cpunum>:

int
cpunum(void)
{
80103111:	55                   	push   %ebp
80103112:	89 e5                	mov    %esp,%ebp
80103114:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103117:	e8 6b fe ff ff       	call   80102f87 <readeflags>
8010311c:	25 00 02 00 00       	and    $0x200,%eax
80103121:	85 c0                	test   %eax,%eax
80103123:	74 25                	je     8010314a <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103125:	a1 40 b6 10 80       	mov    0x8010b640,%eax
8010312a:	8d 50 01             	lea    0x1(%eax),%edx
8010312d:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
80103133:	85 c0                	test   %eax,%eax
80103135:	75 13                	jne    8010314a <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103137:	8b 45 04             	mov    0x4(%ebp),%eax
8010313a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010313e:	c7 04 24 a0 84 10 80 	movl   $0x801084a0,(%esp)
80103145:	e8 56 d2 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010314a:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
8010314f:	85 c0                	test   %eax,%eax
80103151:	74 0f                	je     80103162 <cpunum+0x51>
    return lapic[ID]>>24;
80103153:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80103158:	83 c0 20             	add    $0x20,%eax
8010315b:	8b 00                	mov    (%eax),%eax
8010315d:	c1 e8 18             	shr    $0x18,%eax
80103160:	eb 05                	jmp    80103167 <cpunum+0x56>
  return 0;
80103162:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103167:	c9                   	leave  
80103168:	c3                   	ret    

80103169 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103169:	55                   	push   %ebp
8010316a:	89 e5                	mov    %esp,%ebp
8010316c:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010316f:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80103174:	85 c0                	test   %eax,%eax
80103176:	74 14                	je     8010318c <lapiceoi+0x23>
    lapicw(EOI, 0);
80103178:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010317f:	00 
80103180:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103187:	e8 0b fe ff ff       	call   80102f97 <lapicw>
}
8010318c:	c9                   	leave  
8010318d:	c3                   	ret    

8010318e <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010318e:	55                   	push   %ebp
8010318f:	89 e5                	mov    %esp,%ebp
}
80103191:	5d                   	pop    %ebp
80103192:	c3                   	ret    

80103193 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103193:	55                   	push   %ebp
80103194:	89 e5                	mov    %esp,%ebp
80103196:	83 ec 1c             	sub    $0x1c,%esp
80103199:	8b 45 08             	mov    0x8(%ebp),%eax
8010319c:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010319f:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801031a6:	00 
801031a7:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801031ae:	e8 b6 fd ff ff       	call   80102f69 <outb>
  outb(IO_RTC+1, 0x0A);
801031b3:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801031ba:	00 
801031bb:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801031c2:	e8 a2 fd ff ff       	call   80102f69 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801031c7:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801031ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
801031d1:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801031d6:	8b 45 f8             	mov    -0x8(%ebp),%eax
801031d9:	8d 50 02             	lea    0x2(%eax),%edx
801031dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801031df:	c1 e8 04             	shr    $0x4,%eax
801031e2:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801031e5:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801031e9:	c1 e0 18             	shl    $0x18,%eax
801031ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801031f0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031f7:	e8 9b fd ff ff       	call   80102f97 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801031fc:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103203:	00 
80103204:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010320b:	e8 87 fd ff ff       	call   80102f97 <lapicw>
  microdelay(200);
80103210:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103217:	e8 72 ff ff ff       	call   8010318e <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010321c:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103223:	00 
80103224:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010322b:	e8 67 fd ff ff       	call   80102f97 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103230:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103237:	e8 52 ff ff ff       	call   8010318e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010323c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103243:	eb 40                	jmp    80103285 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103245:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103249:	c1 e0 18             	shl    $0x18,%eax
8010324c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103250:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103257:	e8 3b fd ff ff       	call   80102f97 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010325c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010325f:	c1 e8 0c             	shr    $0xc,%eax
80103262:	80 cc 06             	or     $0x6,%ah
80103265:	89 44 24 04          	mov    %eax,0x4(%esp)
80103269:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103270:	e8 22 fd ff ff       	call   80102f97 <lapicw>
    microdelay(200);
80103275:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010327c:	e8 0d ff ff ff       	call   8010318e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103281:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103285:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103289:	7e ba                	jle    80103245 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010328b:	c9                   	leave  
8010328c:	c3                   	ret    

8010328d <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010328d:	55                   	push   %ebp
8010328e:	89 e5                	mov    %esp,%ebp
80103290:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103293:	c7 44 24 04 cc 84 10 	movl   $0x801084cc,0x4(%esp)
8010329a:	80 
8010329b:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032a2:	e8 64 1a 00 00       	call   80104d0b <initlock>
  readsb(ROOTDEV, &sb);
801032a7:	8d 45 e8             	lea    -0x18(%ebp),%eax
801032aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801032ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032b5:	e8 23 e0 ff ff       	call   801012dd <readsb>
  log.start = sb.size - sb.nlog;
801032ba:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c0:	29 c2                	sub    %eax,%edx
801032c2:	89 d0                	mov    %edx,%eax
801032c4:	a3 b4 f8 10 80       	mov    %eax,0x8010f8b4
  log.size = sb.nlog;
801032c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032cc:	a3 b8 f8 10 80       	mov    %eax,0x8010f8b8
  log.dev = ROOTDEV;
801032d1:	c7 05 c0 f8 10 80 01 	movl   $0x1,0x8010f8c0
801032d8:	00 00 00 
  recover_from_log();
801032db:	e8 9a 01 00 00       	call   8010347a <recover_from_log>
}
801032e0:	c9                   	leave  
801032e1:	c3                   	ret    

801032e2 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801032e2:	55                   	push   %ebp
801032e3:	89 e5                	mov    %esp,%ebp
801032e5:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032ef:	e9 8c 00 00 00       	jmp    80103380 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032f4:	8b 15 b4 f8 10 80    	mov    0x8010f8b4,%edx
801032fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032fd:	01 d0                	add    %edx,%eax
801032ff:	83 c0 01             	add    $0x1,%eax
80103302:	89 c2                	mov    %eax,%edx
80103304:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103309:	89 54 24 04          	mov    %edx,0x4(%esp)
8010330d:	89 04 24             	mov    %eax,(%esp)
80103310:	e8 91 ce ff ff       	call   801001a6 <bread>
80103315:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010331b:	83 c0 10             	add    $0x10,%eax
8010331e:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
80103325:	89 c2                	mov    %eax,%edx
80103327:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
8010332c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103330:	89 04 24             	mov    %eax,(%esp)
80103333:	e8 6e ce ff ff       	call   801001a6 <bread>
80103338:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010333b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010333e:	8d 50 18             	lea    0x18(%eax),%edx
80103341:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103344:	83 c0 18             	add    $0x18,%eax
80103347:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010334e:	00 
8010334f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103353:	89 04 24             	mov    %eax,(%esp)
80103356:	e8 f4 1c 00 00       	call   8010504f <memmove>
    bwrite(dbuf);  // write dst to disk
8010335b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010335e:	89 04 24             	mov    %eax,(%esp)
80103361:	e8 77 ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103366:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103369:	89 04 24             	mov    %eax,(%esp)
8010336c:	e8 a6 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103371:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103374:	89 04 24             	mov    %eax,(%esp)
80103377:	e8 9b ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010337c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103380:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103385:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103388:	0f 8f 66 ff ff ff    	jg     801032f4 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010338e:	c9                   	leave  
8010338f:	c3                   	ret    

80103390 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103390:	55                   	push   %ebp
80103391:	89 e5                	mov    %esp,%ebp
80103393:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103396:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
8010339b:	89 c2                	mov    %eax,%edx
8010339d:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
801033a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801033a6:	89 04 24             	mov    %eax,(%esp)
801033a9:	e8 f8 cd ff ff       	call   801001a6 <bread>
801033ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801033b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033b4:	83 c0 18             	add    $0x18,%eax
801033b7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801033ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033bd:	8b 00                	mov    (%eax),%eax
801033bf:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  for (i = 0; i < log.lh.n; i++) {
801033c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033cb:	eb 1b                	jmp    801033e8 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801033cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033d3:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801033d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033da:	83 c2 10             	add    $0x10,%edx
801033dd:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801033e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033e8:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801033ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033f0:	7f db                	jg     801033cd <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801033f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033f5:	89 04 24             	mov    %eax,(%esp)
801033f8:	e8 1a ce ff ff       	call   80100217 <brelse>
}
801033fd:	c9                   	leave  
801033fe:	c3                   	ret    

801033ff <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033ff:	55                   	push   %ebp
80103400:	89 e5                	mov    %esp,%ebp
80103402:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103405:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
8010340a:	89 c2                	mov    %eax,%edx
8010340c:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103411:	89 54 24 04          	mov    %edx,0x4(%esp)
80103415:	89 04 24             	mov    %eax,(%esp)
80103418:	e8 89 cd ff ff       	call   801001a6 <bread>
8010341d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103420:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103423:	83 c0 18             	add    $0x18,%eax
80103426:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103429:	8b 15 c4 f8 10 80    	mov    0x8010f8c4,%edx
8010342f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103432:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103434:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010343b:	eb 1b                	jmp    80103458 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
8010343d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103440:	83 c0 10             	add    $0x10,%eax
80103443:	8b 0c 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%ecx
8010344a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010344d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103450:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103454:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103458:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010345d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103460:	7f db                	jg     8010343d <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103462:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103465:	89 04 24             	mov    %eax,(%esp)
80103468:	e8 70 cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010346d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103470:	89 04 24             	mov    %eax,(%esp)
80103473:	e8 9f cd ff ff       	call   80100217 <brelse>
}
80103478:	c9                   	leave  
80103479:	c3                   	ret    

8010347a <recover_from_log>:

static void
recover_from_log(void)
{
8010347a:	55                   	push   %ebp
8010347b:	89 e5                	mov    %esp,%ebp
8010347d:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103480:	e8 0b ff ff ff       	call   80103390 <read_head>
  install_trans(); // if committed, copy from log to disk
80103485:	e8 58 fe ff ff       	call   801032e2 <install_trans>
  log.lh.n = 0;
8010348a:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
80103491:	00 00 00 
  write_head(); // clear the log
80103494:	e8 66 ff ff ff       	call   801033ff <write_head>
}
80103499:	c9                   	leave  
8010349a:	c3                   	ret    

8010349b <begin_trans>:

void
begin_trans(void)
{
8010349b:	55                   	push   %ebp
8010349c:	89 e5                	mov    %esp,%ebp
8010349e:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801034a1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801034a8:	e8 7f 18 00 00       	call   80104d2c <acquire>
  while (log.busy) {
801034ad:	eb 14                	jmp    801034c3 <begin_trans+0x28>
    sleep(&log, &log.lock);
801034af:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
801034b6:	80 
801034b7:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801034be:	e8 9f 15 00 00       	call   80104a62 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801034c3:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
801034c8:	85 c0                	test   %eax,%eax
801034ca:	75 e3                	jne    801034af <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801034cc:	c7 05 bc f8 10 80 01 	movl   $0x1,0x8010f8bc
801034d3:	00 00 00 
  release(&log.lock);
801034d6:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801034dd:	e8 ac 18 00 00       	call   80104d8e <release>
}
801034e2:	c9                   	leave  
801034e3:	c3                   	ret    

801034e4 <commit_trans>:

void
commit_trans(void)
{
801034e4:	55                   	push   %ebp
801034e5:	89 e5                	mov    %esp,%ebp
801034e7:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801034ea:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801034ef:	85 c0                	test   %eax,%eax
801034f1:	7e 19                	jle    8010350c <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801034f3:	e8 07 ff ff ff       	call   801033ff <write_head>
    install_trans(); // Now install writes to home locations
801034f8:	e8 e5 fd ff ff       	call   801032e2 <install_trans>
    log.lh.n = 0; 
801034fd:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
80103504:	00 00 00 
    write_head();    // Erase the transaction from the log
80103507:	e8 f3 fe ff ff       	call   801033ff <write_head>
  }
  
  acquire(&log.lock);
8010350c:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103513:	e8 14 18 00 00       	call   80104d2c <acquire>
  log.busy = 0;
80103518:	c7 05 bc f8 10 80 00 	movl   $0x0,0x8010f8bc
8010351f:	00 00 00 
  wakeup(&log);
80103522:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103529:	e8 0d 16 00 00       	call   80104b3b <wakeup>
  release(&log.lock);
8010352e:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103535:	e8 54 18 00 00       	call   80104d8e <release>
}
8010353a:	c9                   	leave  
8010353b:	c3                   	ret    

8010353c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010353c:	55                   	push   %ebp
8010353d:	89 e5                	mov    %esp,%ebp
8010353f:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103542:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103547:	83 f8 09             	cmp    $0x9,%eax
8010354a:	7f 12                	jg     8010355e <log_write+0x22>
8010354c:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103551:	8b 15 b8 f8 10 80    	mov    0x8010f8b8,%edx
80103557:	83 ea 01             	sub    $0x1,%edx
8010355a:	39 d0                	cmp    %edx,%eax
8010355c:	7c 0c                	jl     8010356a <log_write+0x2e>
    panic("too big a transaction");
8010355e:	c7 04 24 d0 84 10 80 	movl   $0x801084d0,(%esp)
80103565:	e8 d0 cf ff ff       	call   8010053a <panic>
  if (!log.busy)
8010356a:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
8010356f:	85 c0                	test   %eax,%eax
80103571:	75 0c                	jne    8010357f <log_write+0x43>
    panic("write outside of trans");
80103573:	c7 04 24 e6 84 10 80 	movl   $0x801084e6,(%esp)
8010357a:	e8 bb cf ff ff       	call   8010053a <panic>

  for (i = 0; i < log.lh.n; i++) {
8010357f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103586:	eb 1f                	jmp    801035a7 <log_write+0x6b>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010358b:	83 c0 10             	add    $0x10,%eax
8010358e:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
80103595:	89 c2                	mov    %eax,%edx
80103597:	8b 45 08             	mov    0x8(%ebp),%eax
8010359a:	8b 40 08             	mov    0x8(%eax),%eax
8010359d:	39 c2                	cmp    %eax,%edx
8010359f:	75 02                	jne    801035a3 <log_write+0x67>
      break;
801035a1:	eb 0e                	jmp    801035b1 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801035a3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035a7:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801035ac:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035af:	7f d7                	jg     80103588 <log_write+0x4c>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
  }
  log.lh.sector[i] = b->sector;
801035b1:	8b 45 08             	mov    0x8(%ebp),%eax
801035b4:	8b 40 08             	mov    0x8(%eax),%eax
801035b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035ba:	83 c2 10             	add    $0x10,%edx
801035bd:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801035c4:	8b 15 b4 f8 10 80    	mov    0x8010f8b4,%edx
801035ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035cd:	01 d0                	add    %edx,%eax
801035cf:	83 c0 01             	add    $0x1,%eax
801035d2:	89 c2                	mov    %eax,%edx
801035d4:	8b 45 08             	mov    0x8(%ebp),%eax
801035d7:	8b 40 04             	mov    0x4(%eax),%eax
801035da:	89 54 24 04          	mov    %edx,0x4(%esp)
801035de:	89 04 24             	mov    %eax,(%esp)
801035e1:	e8 c0 cb ff ff       	call   801001a6 <bread>
801035e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801035e9:	8b 45 08             	mov    0x8(%ebp),%eax
801035ec:	8d 50 18             	lea    0x18(%eax),%edx
801035ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f2:	83 c0 18             	add    $0x18,%eax
801035f5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801035fc:	00 
801035fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80103601:	89 04 24             	mov    %eax,(%esp)
80103604:	e8 46 1a 00 00       	call   8010504f <memmove>
  bwrite(lbuf);
80103609:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010360c:	89 04 24             	mov    %eax,(%esp)
8010360f:	e8 c9 cb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103614:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103617:	89 04 24             	mov    %eax,(%esp)
8010361a:	e8 f8 cb ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
8010361f:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103624:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103627:	75 0d                	jne    80103636 <log_write+0xfa>
    log.lh.n++;
80103629:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010362e:	83 c0 01             	add    $0x1,%eax
80103631:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103636:	8b 45 08             	mov    0x8(%ebp),%eax
80103639:	8b 00                	mov    (%eax),%eax
8010363b:	83 c8 04             	or     $0x4,%eax
8010363e:	89 c2                	mov    %eax,%edx
80103640:	8b 45 08             	mov    0x8(%ebp),%eax
80103643:	89 10                	mov    %edx,(%eax)
}
80103645:	c9                   	leave  
80103646:	c3                   	ret    

80103647 <v2p>:
80103647:	55                   	push   %ebp
80103648:	89 e5                	mov    %esp,%ebp
8010364a:	8b 45 08             	mov    0x8(%ebp),%eax
8010364d:	05 00 00 00 80       	add    $0x80000000,%eax
80103652:	5d                   	pop    %ebp
80103653:	c3                   	ret    

80103654 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103654:	55                   	push   %ebp
80103655:	89 e5                	mov    %esp,%ebp
80103657:	8b 45 08             	mov    0x8(%ebp),%eax
8010365a:	05 00 00 00 80       	add    $0x80000000,%eax
8010365f:	5d                   	pop    %ebp
80103660:	c3                   	ret    

80103661 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103661:	55                   	push   %ebp
80103662:	89 e5                	mov    %esp,%ebp
80103664:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103667:	8b 55 08             	mov    0x8(%ebp),%edx
8010366a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010366d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103670:	f0 87 02             	lock xchg %eax,(%edx)
80103673:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103676:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103679:	c9                   	leave  
8010367a:	c3                   	ret    

8010367b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010367b:	55                   	push   %ebp
8010367c:	89 e5                	mov    %esp,%ebp
8010367e:	83 e4 f0             	and    $0xfffffff0,%esp
80103681:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103684:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010368b:	80 
8010368c:	c7 04 24 fc 26 11 80 	movl   $0x801126fc,(%esp)
80103693:	e8 d2 f5 ff ff       	call   80102c6a <kinit1>
  kvmalloc();      // kernel page table
80103698:	e8 76 44 00 00       	call   80107b13 <kvmalloc>
  mpinit();        // collect info about this machine
8010369d:	e8 46 04 00 00       	call   80103ae8 <mpinit>
  lapicinit();
801036a2:	e8 11 f9 ff ff       	call   80102fb8 <lapicinit>
  seginit();       // set up segments
801036a7:	e8 fa 3d 00 00       	call   801074a6 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801036ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801036b2:	0f b6 00             	movzbl (%eax),%eax
801036b5:	0f b6 c0             	movzbl %al,%eax
801036b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801036bc:	c7 04 24 fd 84 10 80 	movl   $0x801084fd,(%esp)
801036c3:	e8 d8 cc ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
801036c8:	e8 79 06 00 00       	call   80103d46 <picinit>
  ioapicinit();    // another interrupt controller
801036cd:	e8 8e f4 ff ff       	call   80102b60 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801036d2:	e8 aa d3 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
801036d7:	e8 19 31 00 00       	call   801067f5 <uartinit>
  pinit();         // process table
801036dc:	e8 6f 0b 00 00       	call   80104250 <pinit>
  tvinit();        // trap vectors
801036e1:	e8 c1 2c 00 00       	call   801063a7 <tvinit>
  binit();         // buffer cache
801036e6:	e8 49 c9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801036eb:	e8 06 d8 ff ff       	call   80100ef6 <fileinit>
  iinit();         // inode cache
801036f0:	e8 9b de ff ff       	call   80101590 <iinit>
  ideinit();       // disk
801036f5:	e8 cf f0 ff ff       	call   801027c9 <ideinit>
  if(!ismp)
801036fa:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801036ff:	85 c0                	test   %eax,%eax
80103701:	75 05                	jne    80103708 <main+0x8d>
    timerinit();   // uniprocessor timer
80103703:	e8 ea 2b 00 00       	call   801062f2 <timerinit>
  startothers();   // start other processors
80103708:	e8 7f 00 00 00       	call   8010378c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
8010370d:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103714:	8e 
80103715:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
8010371c:	e8 81 f5 ff ff       	call   80102ca2 <kinit2>
  userinit();      // first user process
80103721:	e8 45 0c 00 00       	call   8010436b <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103726:	e8 1a 00 00 00       	call   80103745 <mpmain>

8010372b <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010372b:	55                   	push   %ebp
8010372c:	89 e5                	mov    %esp,%ebp
8010372e:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103731:	e8 f4 43 00 00       	call   80107b2a <switchkvm>
  seginit();
80103736:	e8 6b 3d 00 00       	call   801074a6 <seginit>
  lapicinit();
8010373b:	e8 78 f8 ff ff       	call   80102fb8 <lapicinit>
  mpmain();
80103740:	e8 00 00 00 00       	call   80103745 <mpmain>

80103745 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103745:	55                   	push   %ebp
80103746:	89 e5                	mov    %esp,%ebp
80103748:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010374b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103751:	0f b6 00             	movzbl (%eax),%eax
80103754:	0f b6 c0             	movzbl %al,%eax
80103757:	89 44 24 04          	mov    %eax,0x4(%esp)
8010375b:	c7 04 24 14 85 10 80 	movl   $0x80108514,(%esp)
80103762:	e8 39 cc ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103767:	e8 af 2d 00 00       	call   8010651b <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010376c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103772:	05 a8 00 00 00       	add    $0xa8,%eax
80103777:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010377e:	00 
8010377f:	89 04 24             	mov    %eax,(%esp)
80103782:	e8 da fe ff ff       	call   80103661 <xchg>
  scheduler();     // start running processes
80103787:	e8 2e 11 00 00       	call   801048ba <scheduler>

8010378c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010378c:	55                   	push   %ebp
8010378d:	89 e5                	mov    %esp,%ebp
8010378f:	53                   	push   %ebx
80103790:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103793:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010379a:	e8 b5 fe ff ff       	call   80103654 <p2v>
8010379f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801037a2:	b8 8a 00 00 00       	mov    $0x8a,%eax
801037a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801037ab:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
801037b2:	80 
801037b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037b6:	89 04 24             	mov    %eax,(%esp)
801037b9:	e8 91 18 00 00       	call   8010504f <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801037be:	c7 45 f4 20 f9 10 80 	movl   $0x8010f920,-0xc(%ebp)
801037c5:	e9 85 00 00 00       	jmp    8010384f <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
801037ca:	e8 42 f9 ff ff       	call   80103111 <cpunum>
801037cf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801037d5:	05 20 f9 10 80       	add    $0x8010f920,%eax
801037da:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037dd:	75 02                	jne    801037e1 <startothers+0x55>
      continue;
801037df:	eb 67                	jmp    80103848 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801037e1:	e8 b2 f5 ff ff       	call   80102d98 <kalloc>
801037e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801037e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ec:	83 e8 04             	sub    $0x4,%eax
801037ef:	8b 55 ec             	mov    -0x14(%ebp),%edx
801037f2:	81 c2 00 10 00 00    	add    $0x1000,%edx
801037f8:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801037fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037fd:	83 e8 08             	sub    $0x8,%eax
80103800:	c7 00 2b 37 10 80    	movl   $0x8010372b,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103806:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103809:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010380c:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103813:	e8 2f fe ff ff       	call   80103647 <v2p>
80103818:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010381a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010381d:	89 04 24             	mov    %eax,(%esp)
80103820:	e8 22 fe ff ff       	call   80103647 <v2p>
80103825:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103828:	0f b6 12             	movzbl (%edx),%edx
8010382b:	0f b6 d2             	movzbl %dl,%edx
8010382e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103832:	89 14 24             	mov    %edx,(%esp)
80103835:	e8 59 f9 ff ff       	call   80103193 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010383a:	90                   	nop
8010383b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383e:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103844:	85 c0                	test   %eax,%eax
80103846:	74 f3                	je     8010383b <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103848:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
8010384f:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103854:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010385a:	05 20 f9 10 80       	add    $0x8010f920,%eax
8010385f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103862:	0f 87 62 ff ff ff    	ja     801037ca <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103868:	83 c4 24             	add    $0x24,%esp
8010386b:	5b                   	pop    %ebx
8010386c:	5d                   	pop    %ebp
8010386d:	c3                   	ret    

8010386e <p2v>:
8010386e:	55                   	push   %ebp
8010386f:	89 e5                	mov    %esp,%ebp
80103871:	8b 45 08             	mov    0x8(%ebp),%eax
80103874:	05 00 00 00 80       	add    $0x80000000,%eax
80103879:	5d                   	pop    %ebp
8010387a:	c3                   	ret    

8010387b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010387b:	55                   	push   %ebp
8010387c:	89 e5                	mov    %esp,%ebp
8010387e:	83 ec 14             	sub    $0x14,%esp
80103881:	8b 45 08             	mov    0x8(%ebp),%eax
80103884:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103888:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010388c:	89 c2                	mov    %eax,%edx
8010388e:	ec                   	in     (%dx),%al
8010388f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103892:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103896:	c9                   	leave  
80103897:	c3                   	ret    

80103898 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103898:	55                   	push   %ebp
80103899:	89 e5                	mov    %esp,%ebp
8010389b:	83 ec 08             	sub    $0x8,%esp
8010389e:	8b 55 08             	mov    0x8(%ebp),%edx
801038a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801038a4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801038a8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801038ab:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801038af:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801038b3:	ee                   	out    %al,(%dx)
}
801038b4:	c9                   	leave  
801038b5:	c3                   	ret    

801038b6 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801038b6:	55                   	push   %ebp
801038b7:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801038b9:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801038be:	89 c2                	mov    %eax,%edx
801038c0:	b8 20 f9 10 80       	mov    $0x8010f920,%eax
801038c5:	29 c2                	sub    %eax,%edx
801038c7:	89 d0                	mov    %edx,%eax
801038c9:	c1 f8 02             	sar    $0x2,%eax
801038cc:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801038d2:	5d                   	pop    %ebp
801038d3:	c3                   	ret    

801038d4 <sum>:

static uchar
sum(uchar *addr, int len)
{
801038d4:	55                   	push   %ebp
801038d5:	89 e5                	mov    %esp,%ebp
801038d7:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801038da:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801038e1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801038e8:	eb 15                	jmp    801038ff <sum+0x2b>
    sum += addr[i];
801038ea:	8b 55 fc             	mov    -0x4(%ebp),%edx
801038ed:	8b 45 08             	mov    0x8(%ebp),%eax
801038f0:	01 d0                	add    %edx,%eax
801038f2:	0f b6 00             	movzbl (%eax),%eax
801038f5:	0f b6 c0             	movzbl %al,%eax
801038f8:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801038fb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801038ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103902:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103905:	7c e3                	jl     801038ea <sum+0x16>
    sum += addr[i];
  return sum;
80103907:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010390a:	c9                   	leave  
8010390b:	c3                   	ret    

8010390c <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010390c:	55                   	push   %ebp
8010390d:	89 e5                	mov    %esp,%ebp
8010390f:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103912:	8b 45 08             	mov    0x8(%ebp),%eax
80103915:	89 04 24             	mov    %eax,(%esp)
80103918:	e8 51 ff ff ff       	call   8010386e <p2v>
8010391d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103920:	8b 55 0c             	mov    0xc(%ebp),%edx
80103923:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103926:	01 d0                	add    %edx,%eax
80103928:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010392b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010392e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103931:	eb 3f                	jmp    80103972 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103933:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010393a:	00 
8010393b:	c7 44 24 04 28 85 10 	movl   $0x80108528,0x4(%esp)
80103942:	80 
80103943:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103946:	89 04 24             	mov    %eax,(%esp)
80103949:	e8 a9 16 00 00       	call   80104ff7 <memcmp>
8010394e:	85 c0                	test   %eax,%eax
80103950:	75 1c                	jne    8010396e <mpsearch1+0x62>
80103952:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103959:	00 
8010395a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010395d:	89 04 24             	mov    %eax,(%esp)
80103960:	e8 6f ff ff ff       	call   801038d4 <sum>
80103965:	84 c0                	test   %al,%al
80103967:	75 05                	jne    8010396e <mpsearch1+0x62>
      return (struct mp*)p;
80103969:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010396c:	eb 11                	jmp    8010397f <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010396e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103975:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103978:	72 b9                	jb     80103933 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010397a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010397f:	c9                   	leave  
80103980:	c3                   	ret    

80103981 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103981:	55                   	push   %ebp
80103982:	89 e5                	mov    %esp,%ebp
80103984:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103987:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010398e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103991:	83 c0 0f             	add    $0xf,%eax
80103994:	0f b6 00             	movzbl (%eax),%eax
80103997:	0f b6 c0             	movzbl %al,%eax
8010399a:	c1 e0 08             	shl    $0x8,%eax
8010399d:	89 c2                	mov    %eax,%edx
8010399f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039a2:	83 c0 0e             	add    $0xe,%eax
801039a5:	0f b6 00             	movzbl (%eax),%eax
801039a8:	0f b6 c0             	movzbl %al,%eax
801039ab:	09 d0                	or     %edx,%eax
801039ad:	c1 e0 04             	shl    $0x4,%eax
801039b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801039b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801039b7:	74 21                	je     801039da <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801039b9:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801039c0:	00 
801039c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039c4:	89 04 24             	mov    %eax,(%esp)
801039c7:	e8 40 ff ff ff       	call   8010390c <mpsearch1>
801039cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801039cf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801039d3:	74 50                	je     80103a25 <mpsearch+0xa4>
      return mp;
801039d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039d8:	eb 5f                	jmp    80103a39 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801039da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039dd:	83 c0 14             	add    $0x14,%eax
801039e0:	0f b6 00             	movzbl (%eax),%eax
801039e3:	0f b6 c0             	movzbl %al,%eax
801039e6:	c1 e0 08             	shl    $0x8,%eax
801039e9:	89 c2                	mov    %eax,%edx
801039eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ee:	83 c0 13             	add    $0x13,%eax
801039f1:	0f b6 00             	movzbl (%eax),%eax
801039f4:	0f b6 c0             	movzbl %al,%eax
801039f7:	09 d0                	or     %edx,%eax
801039f9:	c1 e0 0a             	shl    $0xa,%eax
801039fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801039ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a02:	2d 00 04 00 00       	sub    $0x400,%eax
80103a07:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a0e:	00 
80103a0f:	89 04 24             	mov    %eax,(%esp)
80103a12:	e8 f5 fe ff ff       	call   8010390c <mpsearch1>
80103a17:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a1a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a1e:	74 05                	je     80103a25 <mpsearch+0xa4>
      return mp;
80103a20:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a23:	eb 14                	jmp    80103a39 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103a25:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103a2c:	00 
80103a2d:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103a34:	e8 d3 fe ff ff       	call   8010390c <mpsearch1>
}
80103a39:	c9                   	leave  
80103a3a:	c3                   	ret    

80103a3b <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103a3b:	55                   	push   %ebp
80103a3c:	89 e5                	mov    %esp,%ebp
80103a3e:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103a41:	e8 3b ff ff ff       	call   80103981 <mpsearch>
80103a46:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103a4d:	74 0a                	je     80103a59 <mpconfig+0x1e>
80103a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a52:	8b 40 04             	mov    0x4(%eax),%eax
80103a55:	85 c0                	test   %eax,%eax
80103a57:	75 0a                	jne    80103a63 <mpconfig+0x28>
    return 0;
80103a59:	b8 00 00 00 00       	mov    $0x0,%eax
80103a5e:	e9 83 00 00 00       	jmp    80103ae6 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a66:	8b 40 04             	mov    0x4(%eax),%eax
80103a69:	89 04 24             	mov    %eax,(%esp)
80103a6c:	e8 fd fd ff ff       	call   8010386e <p2v>
80103a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103a74:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103a7b:	00 
80103a7c:	c7 44 24 04 2d 85 10 	movl   $0x8010852d,0x4(%esp)
80103a83:	80 
80103a84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a87:	89 04 24             	mov    %eax,(%esp)
80103a8a:	e8 68 15 00 00       	call   80104ff7 <memcmp>
80103a8f:	85 c0                	test   %eax,%eax
80103a91:	74 07                	je     80103a9a <mpconfig+0x5f>
    return 0;
80103a93:	b8 00 00 00 00       	mov    $0x0,%eax
80103a98:	eb 4c                	jmp    80103ae6 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103a9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a9d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103aa1:	3c 01                	cmp    $0x1,%al
80103aa3:	74 12                	je     80103ab7 <mpconfig+0x7c>
80103aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa8:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103aac:	3c 04                	cmp    $0x4,%al
80103aae:	74 07                	je     80103ab7 <mpconfig+0x7c>
    return 0;
80103ab0:	b8 00 00 00 00       	mov    $0x0,%eax
80103ab5:	eb 2f                	jmp    80103ae6 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aba:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103abe:	0f b7 c0             	movzwl %ax,%eax
80103ac1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ac8:	89 04 24             	mov    %eax,(%esp)
80103acb:	e8 04 fe ff ff       	call   801038d4 <sum>
80103ad0:	84 c0                	test   %al,%al
80103ad2:	74 07                	je     80103adb <mpconfig+0xa0>
    return 0;
80103ad4:	b8 00 00 00 00       	mov    $0x0,%eax
80103ad9:	eb 0b                	jmp    80103ae6 <mpconfig+0xab>
  *pmp = mp;
80103adb:	8b 45 08             	mov    0x8(%ebp),%eax
80103ade:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ae1:	89 10                	mov    %edx,(%eax)
  return conf;
80103ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103ae6:	c9                   	leave  
80103ae7:	c3                   	ret    

80103ae8 <mpinit>:

void
mpinit(void)
{
80103ae8:	55                   	push   %ebp
80103ae9:	89 e5                	mov    %esp,%ebp
80103aeb:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103aee:	c7 05 44 b6 10 80 20 	movl   $0x8010f920,0x8010b644
80103af5:	f9 10 80 
  if((conf = mpconfig(&mp)) == 0)
80103af8:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103afb:	89 04 24             	mov    %eax,(%esp)
80103afe:	e8 38 ff ff ff       	call   80103a3b <mpconfig>
80103b03:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b06:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b0a:	75 05                	jne    80103b11 <mpinit+0x29>
    return;
80103b0c:	e9 9c 01 00 00       	jmp    80103cad <mpinit+0x1c5>
  ismp = 1;
80103b11:	c7 05 04 f9 10 80 01 	movl   $0x1,0x8010f904
80103b18:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103b1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1e:	8b 40 24             	mov    0x24(%eax),%eax
80103b21:	a3 7c f8 10 80       	mov    %eax,0x8010f87c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103b26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b29:	83 c0 2c             	add    $0x2c,%eax
80103b2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b32:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b36:	0f b7 d0             	movzwl %ax,%edx
80103b39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b3c:	01 d0                	add    %edx,%eax
80103b3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b41:	e9 f4 00 00 00       	jmp    80103c3a <mpinit+0x152>
    switch(*p){
80103b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b49:	0f b6 00             	movzbl (%eax),%eax
80103b4c:	0f b6 c0             	movzbl %al,%eax
80103b4f:	83 f8 04             	cmp    $0x4,%eax
80103b52:	0f 87 bf 00 00 00    	ja     80103c17 <mpinit+0x12f>
80103b58:	8b 04 85 70 85 10 80 	mov    -0x7fef7a90(,%eax,4),%eax
80103b5f:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b64:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103b67:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b6a:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b6e:	0f b6 d0             	movzbl %al,%edx
80103b71:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103b76:	39 c2                	cmp    %eax,%edx
80103b78:	74 2d                	je     80103ba7 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103b7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b7d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b81:	0f b6 d0             	movzbl %al,%edx
80103b84:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103b89:	89 54 24 08          	mov    %edx,0x8(%esp)
80103b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b91:	c7 04 24 32 85 10 80 	movl   $0x80108532,(%esp)
80103b98:	e8 03 c8 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103b9d:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
80103ba4:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103ba7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103baa:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103bae:	0f b6 c0             	movzbl %al,%eax
80103bb1:	83 e0 02             	and    $0x2,%eax
80103bb4:	85 c0                	test   %eax,%eax
80103bb6:	74 15                	je     80103bcd <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103bb8:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103bbd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103bc3:	05 20 f9 10 80       	add    $0x8010f920,%eax
80103bc8:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103bcd:	8b 15 00 ff 10 80    	mov    0x8010ff00,%edx
80103bd3:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103bd8:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103bde:	81 c2 20 f9 10 80    	add    $0x8010f920,%edx
80103be4:	88 02                	mov    %al,(%edx)
      ncpu++;
80103be6:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103beb:	83 c0 01             	add    $0x1,%eax
80103bee:	a3 00 ff 10 80       	mov    %eax,0x8010ff00
      p += sizeof(struct mpproc);
80103bf3:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103bf7:	eb 41                	jmp    80103c3a <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103bf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bfc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103bff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103c02:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c06:	a2 00 f9 10 80       	mov    %al,0x8010f900
      p += sizeof(struct mpioapic);
80103c0b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c0f:	eb 29                	jmp    80103c3a <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103c11:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c15:	eb 23                	jmp    80103c3a <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c1a:	0f b6 00             	movzbl (%eax),%eax
80103c1d:	0f b6 c0             	movzbl %al,%eax
80103c20:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c24:	c7 04 24 50 85 10 80 	movl   $0x80108550,(%esp)
80103c2b:	e8 70 c7 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103c30:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
80103c37:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c3d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c40:	0f 82 00 ff ff ff    	jb     80103b46 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103c46:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80103c4b:	85 c0                	test   %eax,%eax
80103c4d:	75 1d                	jne    80103c6c <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103c4f:	c7 05 00 ff 10 80 01 	movl   $0x1,0x8010ff00
80103c56:	00 00 00 
    lapic = 0;
80103c59:	c7 05 7c f8 10 80 00 	movl   $0x0,0x8010f87c
80103c60:	00 00 00 
    ioapicid = 0;
80103c63:	c6 05 00 f9 10 80 00 	movb   $0x0,0x8010f900
    return;
80103c6a:	eb 41                	jmp    80103cad <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103c6c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103c6f:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103c73:	84 c0                	test   %al,%al
80103c75:	74 36                	je     80103cad <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103c77:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103c7e:	00 
80103c7f:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103c86:	e8 0d fc ff ff       	call   80103898 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103c8b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103c92:	e8 e4 fb ff ff       	call   8010387b <inb>
80103c97:	83 c8 01             	or     $0x1,%eax
80103c9a:	0f b6 c0             	movzbl %al,%eax
80103c9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ca1:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103ca8:	e8 eb fb ff ff       	call   80103898 <outb>
  }
}
80103cad:	c9                   	leave  
80103cae:	c3                   	ret    

80103caf <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103caf:	55                   	push   %ebp
80103cb0:	89 e5                	mov    %esp,%ebp
80103cb2:	83 ec 08             	sub    $0x8,%esp
80103cb5:	8b 55 08             	mov    0x8(%ebp),%edx
80103cb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cbb:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103cbf:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103cc2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103cc6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103cca:	ee                   	out    %al,(%dx)
}
80103ccb:	c9                   	leave  
80103ccc:	c3                   	ret    

80103ccd <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103ccd:	55                   	push   %ebp
80103cce:	89 e5                	mov    %esp,%ebp
80103cd0:	83 ec 0c             	sub    $0xc,%esp
80103cd3:	8b 45 08             	mov    0x8(%ebp),%eax
80103cd6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103cda:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cde:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103ce4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ce8:	0f b6 c0             	movzbl %al,%eax
80103ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cef:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103cf6:	e8 b4 ff ff ff       	call   80103caf <outb>
  outb(IO_PIC2+1, mask >> 8);
80103cfb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cff:	66 c1 e8 08          	shr    $0x8,%ax
80103d03:	0f b6 c0             	movzbl %al,%eax
80103d06:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d0a:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d11:	e8 99 ff ff ff       	call   80103caf <outb>
}
80103d16:	c9                   	leave  
80103d17:	c3                   	ret    

80103d18 <picenable>:

void
picenable(int irq)
{
80103d18:	55                   	push   %ebp
80103d19:	89 e5                	mov    %esp,%ebp
80103d1b:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103d1e:	8b 45 08             	mov    0x8(%ebp),%eax
80103d21:	ba 01 00 00 00       	mov    $0x1,%edx
80103d26:	89 c1                	mov    %eax,%ecx
80103d28:	d3 e2                	shl    %cl,%edx
80103d2a:	89 d0                	mov    %edx,%eax
80103d2c:	f7 d0                	not    %eax
80103d2e:	89 c2                	mov    %eax,%edx
80103d30:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d37:	21 d0                	and    %edx,%eax
80103d39:	0f b7 c0             	movzwl %ax,%eax
80103d3c:	89 04 24             	mov    %eax,(%esp)
80103d3f:	e8 89 ff ff ff       	call   80103ccd <picsetmask>
}
80103d44:	c9                   	leave  
80103d45:	c3                   	ret    

80103d46 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103d46:	55                   	push   %ebp
80103d47:	89 e5                	mov    %esp,%ebp
80103d49:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d4c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d53:	00 
80103d54:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d5b:	e8 4f ff ff ff       	call   80103caf <outb>
  outb(IO_PIC2+1, 0xFF);
80103d60:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d67:	00 
80103d68:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d6f:	e8 3b ff ff ff       	call   80103caf <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103d74:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103d7b:	00 
80103d7c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d83:	e8 27 ff ff ff       	call   80103caf <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103d88:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103d8f:	00 
80103d90:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d97:	e8 13 ff ff ff       	call   80103caf <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103d9c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103da3:	00 
80103da4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103dab:	e8 ff fe ff ff       	call   80103caf <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103db0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103db7:	00 
80103db8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103dbf:	e8 eb fe ff ff       	call   80103caf <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103dc4:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103dcb:	00 
80103dcc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103dd3:	e8 d7 fe ff ff       	call   80103caf <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103dd8:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103ddf:	00 
80103de0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103de7:	e8 c3 fe ff ff       	call   80103caf <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103dec:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103df3:	00 
80103df4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103dfb:	e8 af fe ff ff       	call   80103caf <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103e00:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103e07:	00 
80103e08:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e0f:	e8 9b fe ff ff       	call   80103caf <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103e14:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e1b:	00 
80103e1c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e23:	e8 87 fe ff ff       	call   80103caf <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103e28:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e2f:	00 
80103e30:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e37:	e8 73 fe ff ff       	call   80103caf <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103e3c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e43:	00 
80103e44:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e4b:	e8 5f fe ff ff       	call   80103caf <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103e50:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e57:	00 
80103e58:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e5f:	e8 4b fe ff ff       	call   80103caf <outb>

  if(irqmask != 0xFFFF)
80103e64:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e6b:	66 83 f8 ff          	cmp    $0xffff,%ax
80103e6f:	74 12                	je     80103e83 <picinit+0x13d>
    picsetmask(irqmask);
80103e71:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e78:	0f b7 c0             	movzwl %ax,%eax
80103e7b:	89 04 24             	mov    %eax,(%esp)
80103e7e:	e8 4a fe ff ff       	call   80103ccd <picsetmask>
}
80103e83:	c9                   	leave  
80103e84:	c3                   	ret    

80103e85 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103e85:	55                   	push   %ebp
80103e86:	89 e5                	mov    %esp,%ebp
80103e88:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103e8b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103e92:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e95:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e9e:	8b 10                	mov    (%eax),%edx
80103ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea3:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103ea5:	e8 68 d0 ff ff       	call   80100f12 <filealloc>
80103eaa:	8b 55 08             	mov    0x8(%ebp),%edx
80103ead:	89 02                	mov    %eax,(%edx)
80103eaf:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb2:	8b 00                	mov    (%eax),%eax
80103eb4:	85 c0                	test   %eax,%eax
80103eb6:	0f 84 c8 00 00 00    	je     80103f84 <pipealloc+0xff>
80103ebc:	e8 51 d0 ff ff       	call   80100f12 <filealloc>
80103ec1:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ec4:	89 02                	mov    %eax,(%edx)
80103ec6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ec9:	8b 00                	mov    (%eax),%eax
80103ecb:	85 c0                	test   %eax,%eax
80103ecd:	0f 84 b1 00 00 00    	je     80103f84 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103ed3:	e8 c0 ee ff ff       	call   80102d98 <kalloc>
80103ed8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103edb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103edf:	75 05                	jne    80103ee6 <pipealloc+0x61>
    goto bad;
80103ee1:	e9 9e 00 00 00       	jmp    80103f84 <pipealloc+0xff>
  p->readopen = 1;
80103ee6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ee9:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103ef0:	00 00 00 
  p->writeopen = 1;
80103ef3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef6:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103efd:	00 00 00 
  p->nwrite = 0;
80103f00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f03:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103f0a:	00 00 00 
  p->nread = 0;
80103f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f10:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103f17:	00 00 00 
  initlock(&p->lock, "pipe");
80103f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f1d:	c7 44 24 04 84 85 10 	movl   $0x80108584,0x4(%esp)
80103f24:	80 
80103f25:	89 04 24             	mov    %eax,(%esp)
80103f28:	e8 de 0d 00 00       	call   80104d0b <initlock>
  (*f0)->type = FD_PIPE;
80103f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f30:	8b 00                	mov    (%eax),%eax
80103f32:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103f38:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3b:	8b 00                	mov    (%eax),%eax
80103f3d:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103f41:	8b 45 08             	mov    0x8(%ebp),%eax
80103f44:	8b 00                	mov    (%eax),%eax
80103f46:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4d:	8b 00                	mov    (%eax),%eax
80103f4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f52:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103f55:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f58:	8b 00                	mov    (%eax),%eax
80103f5a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103f60:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f63:	8b 00                	mov    (%eax),%eax
80103f65:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103f69:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f6c:	8b 00                	mov    (%eax),%eax
80103f6e:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103f72:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f75:	8b 00                	mov    (%eax),%eax
80103f77:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f7a:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103f7d:	b8 00 00 00 00       	mov    $0x0,%eax
80103f82:	eb 42                	jmp    80103fc6 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80103f84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103f88:	74 0b                	je     80103f95 <pipealloc+0x110>
    kfree((char*)p);
80103f8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f8d:	89 04 24             	mov    %eax,(%esp)
80103f90:	e8 6a ed ff ff       	call   80102cff <kfree>
  if(*f0)
80103f95:	8b 45 08             	mov    0x8(%ebp),%eax
80103f98:	8b 00                	mov    (%eax),%eax
80103f9a:	85 c0                	test   %eax,%eax
80103f9c:	74 0d                	je     80103fab <pipealloc+0x126>
    fileclose(*f0);
80103f9e:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa1:	8b 00                	mov    (%eax),%eax
80103fa3:	89 04 24             	mov    %eax,(%esp)
80103fa6:	e8 0f d0 ff ff       	call   80100fba <fileclose>
  if(*f1)
80103fab:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fae:	8b 00                	mov    (%eax),%eax
80103fb0:	85 c0                	test   %eax,%eax
80103fb2:	74 0d                	je     80103fc1 <pipealloc+0x13c>
    fileclose(*f1);
80103fb4:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fb7:	8b 00                	mov    (%eax),%eax
80103fb9:	89 04 24             	mov    %eax,(%esp)
80103fbc:	e8 f9 cf ff ff       	call   80100fba <fileclose>
  return -1;
80103fc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fc6:	c9                   	leave  
80103fc7:	c3                   	ret    

80103fc8 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103fc8:	55                   	push   %ebp
80103fc9:	89 e5                	mov    %esp,%ebp
80103fcb:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103fce:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd1:	89 04 24             	mov    %eax,(%esp)
80103fd4:	e8 53 0d 00 00       	call   80104d2c <acquire>
  if(writable){
80103fd9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103fdd:	74 1f                	je     80103ffe <pipeclose+0x36>
    p->writeopen = 0;
80103fdf:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe2:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103fe9:	00 00 00 
    wakeup(&p->nread);
80103fec:	8b 45 08             	mov    0x8(%ebp),%eax
80103fef:	05 34 02 00 00       	add    $0x234,%eax
80103ff4:	89 04 24             	mov    %eax,(%esp)
80103ff7:	e8 3f 0b 00 00       	call   80104b3b <wakeup>
80103ffc:	eb 1d                	jmp    8010401b <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80104001:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104008:	00 00 00 
    wakeup(&p->nwrite);
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	05 38 02 00 00       	add    $0x238,%eax
80104013:	89 04 24             	mov    %eax,(%esp)
80104016:	e8 20 0b 00 00       	call   80104b3b <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010401b:	8b 45 08             	mov    0x8(%ebp),%eax
8010401e:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104024:	85 c0                	test   %eax,%eax
80104026:	75 25                	jne    8010404d <pipeclose+0x85>
80104028:	8b 45 08             	mov    0x8(%ebp),%eax
8010402b:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104031:	85 c0                	test   %eax,%eax
80104033:	75 18                	jne    8010404d <pipeclose+0x85>
    release(&p->lock);
80104035:	8b 45 08             	mov    0x8(%ebp),%eax
80104038:	89 04 24             	mov    %eax,(%esp)
8010403b:	e8 4e 0d 00 00       	call   80104d8e <release>
    kfree((char*)p);
80104040:	8b 45 08             	mov    0x8(%ebp),%eax
80104043:	89 04 24             	mov    %eax,(%esp)
80104046:	e8 b4 ec ff ff       	call   80102cff <kfree>
8010404b:	eb 0b                	jmp    80104058 <pipeclose+0x90>
  } else
    release(&p->lock);
8010404d:	8b 45 08             	mov    0x8(%ebp),%eax
80104050:	89 04 24             	mov    %eax,(%esp)
80104053:	e8 36 0d 00 00       	call   80104d8e <release>
}
80104058:	c9                   	leave  
80104059:	c3                   	ret    

8010405a <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010405a:	55                   	push   %ebp
8010405b:	89 e5                	mov    %esp,%ebp
8010405d:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104060:	8b 45 08             	mov    0x8(%ebp),%eax
80104063:	89 04 24             	mov    %eax,(%esp)
80104066:	e8 c1 0c 00 00       	call   80104d2c <acquire>
  for(i = 0; i < n; i++){
8010406b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104072:	e9 a6 00 00 00       	jmp    8010411d <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104077:	eb 57                	jmp    801040d0 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104079:	8b 45 08             	mov    0x8(%ebp),%eax
8010407c:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104082:	85 c0                	test   %eax,%eax
80104084:	74 0d                	je     80104093 <pipewrite+0x39>
80104086:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010408c:	8b 40 24             	mov    0x24(%eax),%eax
8010408f:	85 c0                	test   %eax,%eax
80104091:	74 15                	je     801040a8 <pipewrite+0x4e>
        release(&p->lock);
80104093:	8b 45 08             	mov    0x8(%ebp),%eax
80104096:	89 04 24             	mov    %eax,(%esp)
80104099:	e8 f0 0c 00 00       	call   80104d8e <release>
        return -1;
8010409e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040a3:	e9 9f 00 00 00       	jmp    80104147 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801040a8:	8b 45 08             	mov    0x8(%ebp),%eax
801040ab:	05 34 02 00 00       	add    $0x234,%eax
801040b0:	89 04 24             	mov    %eax,(%esp)
801040b3:	e8 83 0a 00 00       	call   80104b3b <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801040b8:	8b 45 08             	mov    0x8(%ebp),%eax
801040bb:	8b 55 08             	mov    0x8(%ebp),%edx
801040be:	81 c2 38 02 00 00    	add    $0x238,%edx
801040c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801040c8:	89 14 24             	mov    %edx,(%esp)
801040cb:	e8 92 09 00 00       	call   80104a62 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801040d0:	8b 45 08             	mov    0x8(%ebp),%eax
801040d3:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801040d9:	8b 45 08             	mov    0x8(%ebp),%eax
801040dc:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801040e2:	05 00 02 00 00       	add    $0x200,%eax
801040e7:	39 c2                	cmp    %eax,%edx
801040e9:	74 8e                	je     80104079 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801040eb:	8b 45 08             	mov    0x8(%ebp),%eax
801040ee:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801040f4:	8d 48 01             	lea    0x1(%eax),%ecx
801040f7:	8b 55 08             	mov    0x8(%ebp),%edx
801040fa:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104100:	25 ff 01 00 00       	and    $0x1ff,%eax
80104105:	89 c1                	mov    %eax,%ecx
80104107:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010410a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010410d:	01 d0                	add    %edx,%eax
8010410f:	0f b6 10             	movzbl (%eax),%edx
80104112:	8b 45 08             	mov    0x8(%ebp),%eax
80104115:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104119:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010411d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104120:	3b 45 10             	cmp    0x10(%ebp),%eax
80104123:	0f 8c 4e ff ff ff    	jl     80104077 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104129:	8b 45 08             	mov    0x8(%ebp),%eax
8010412c:	05 34 02 00 00       	add    $0x234,%eax
80104131:	89 04 24             	mov    %eax,(%esp)
80104134:	e8 02 0a 00 00       	call   80104b3b <wakeup>
  release(&p->lock);
80104139:	8b 45 08             	mov    0x8(%ebp),%eax
8010413c:	89 04 24             	mov    %eax,(%esp)
8010413f:	e8 4a 0c 00 00       	call   80104d8e <release>
  return n;
80104144:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104147:	c9                   	leave  
80104148:	c3                   	ret    

80104149 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104149:	55                   	push   %ebp
8010414a:	89 e5                	mov    %esp,%ebp
8010414c:	53                   	push   %ebx
8010414d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104150:	8b 45 08             	mov    0x8(%ebp),%eax
80104153:	89 04 24             	mov    %eax,(%esp)
80104156:	e8 d1 0b 00 00       	call   80104d2c <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010415b:	eb 3a                	jmp    80104197 <piperead+0x4e>
    if(proc->killed){
8010415d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104163:	8b 40 24             	mov    0x24(%eax),%eax
80104166:	85 c0                	test   %eax,%eax
80104168:	74 15                	je     8010417f <piperead+0x36>
      release(&p->lock);
8010416a:	8b 45 08             	mov    0x8(%ebp),%eax
8010416d:	89 04 24             	mov    %eax,(%esp)
80104170:	e8 19 0c 00 00       	call   80104d8e <release>
      return -1;
80104175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417a:	e9 b5 00 00 00       	jmp    80104234 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010417f:	8b 45 08             	mov    0x8(%ebp),%eax
80104182:	8b 55 08             	mov    0x8(%ebp),%edx
80104185:	81 c2 34 02 00 00    	add    $0x234,%edx
8010418b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010418f:	89 14 24             	mov    %edx,(%esp)
80104192:	e8 cb 08 00 00       	call   80104a62 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104197:	8b 45 08             	mov    0x8(%ebp),%eax
8010419a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041a0:	8b 45 08             	mov    0x8(%ebp),%eax
801041a3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041a9:	39 c2                	cmp    %eax,%edx
801041ab:	75 0d                	jne    801041ba <piperead+0x71>
801041ad:	8b 45 08             	mov    0x8(%ebp),%eax
801041b0:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801041b6:	85 c0                	test   %eax,%eax
801041b8:	75 a3                	jne    8010415d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801041ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041c1:	eb 4b                	jmp    8010420e <piperead+0xc5>
    if(p->nread == p->nwrite)
801041c3:	8b 45 08             	mov    0x8(%ebp),%eax
801041c6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041cc:	8b 45 08             	mov    0x8(%ebp),%eax
801041cf:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041d5:	39 c2                	cmp    %eax,%edx
801041d7:	75 02                	jne    801041db <piperead+0x92>
      break;
801041d9:	eb 3b                	jmp    80104216 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801041db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041de:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801041e4:	8b 45 08             	mov    0x8(%ebp),%eax
801041e7:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801041ed:	8d 48 01             	lea    0x1(%eax),%ecx
801041f0:	8b 55 08             	mov    0x8(%ebp),%edx
801041f3:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801041f9:	25 ff 01 00 00       	and    $0x1ff,%eax
801041fe:	89 c2                	mov    %eax,%edx
80104200:	8b 45 08             	mov    0x8(%ebp),%eax
80104203:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104208:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010420a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010420e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104211:	3b 45 10             	cmp    0x10(%ebp),%eax
80104214:	7c ad                	jl     801041c3 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104216:	8b 45 08             	mov    0x8(%ebp),%eax
80104219:	05 38 02 00 00       	add    $0x238,%eax
8010421e:	89 04 24             	mov    %eax,(%esp)
80104221:	e8 15 09 00 00       	call   80104b3b <wakeup>
  release(&p->lock);
80104226:	8b 45 08             	mov    0x8(%ebp),%eax
80104229:	89 04 24             	mov    %eax,(%esp)
8010422c:	e8 5d 0b 00 00       	call   80104d8e <release>
  return i;
80104231:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104234:	83 c4 24             	add    $0x24,%esp
80104237:	5b                   	pop    %ebx
80104238:	5d                   	pop    %ebp
80104239:	c3                   	ret    

8010423a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010423a:	55                   	push   %ebp
8010423b:	89 e5                	mov    %esp,%ebp
8010423d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104240:	9c                   	pushf  
80104241:	58                   	pop    %eax
80104242:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104245:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104248:	c9                   	leave  
80104249:	c3                   	ret    

8010424a <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010424a:	55                   	push   %ebp
8010424b:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010424d:	fb                   	sti    
}
8010424e:	5d                   	pop    %ebp
8010424f:	c3                   	ret    

80104250 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104250:	55                   	push   %ebp
80104251:	89 e5                	mov    %esp,%ebp
80104253:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104256:	c7 44 24 04 89 85 10 	movl   $0x80108589,0x4(%esp)
8010425d:	80 
8010425e:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104265:	e8 a1 0a 00 00       	call   80104d0b <initlock>
}
8010426a:	c9                   	leave  
8010426b:	c3                   	ret    

8010426c <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010426c:	55                   	push   %ebp
8010426d:	89 e5                	mov    %esp,%ebp
8010426f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104272:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104279:	e8 ae 0a 00 00       	call   80104d2c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010427e:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104285:	eb 50                	jmp    801042d7 <allocproc+0x6b>
    if(p->state == UNUSED)
80104287:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428a:	8b 40 0c             	mov    0xc(%eax),%eax
8010428d:	85 c0                	test   %eax,%eax
8010428f:	75 42                	jne    801042d3 <allocproc+0x67>
      goto found;
80104291:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104292:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104295:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010429c:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801042a1:	8d 50 01             	lea    0x1(%eax),%edx
801042a4:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
801042aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042ad:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
801042b0:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801042b7:	e8 d2 0a 00 00       	call   80104d8e <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801042bc:	e8 d7 ea ff ff       	call   80102d98 <kalloc>
801042c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042c4:	89 42 08             	mov    %eax,0x8(%edx)
801042c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ca:	8b 40 08             	mov    0x8(%eax),%eax
801042cd:	85 c0                	test   %eax,%eax
801042cf:	75 33                	jne    80104304 <allocproc+0x98>
801042d1:	eb 20                	jmp    801042f3 <allocproc+0x87>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042d3:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801042d7:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
801042de:	72 a7                	jb     80104287 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801042e0:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801042e7:	e8 a2 0a 00 00       	call   80104d8e <release>
  return 0;
801042ec:	b8 00 00 00 00       	mov    $0x0,%eax
801042f1:	eb 76                	jmp    80104369 <allocproc+0xfd>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801042f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042f6:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801042fd:	b8 00 00 00 00       	mov    $0x0,%eax
80104302:	eb 65                	jmp    80104369 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104307:	8b 40 08             	mov    0x8(%eax),%eax
8010430a:	05 00 10 00 00       	add    $0x1000,%eax
8010430f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104312:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104319:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010431c:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010431f:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104323:	ba 62 63 10 80       	mov    $0x80106362,%edx
80104328:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010432b:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010432d:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104334:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104337:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010433a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433d:	8b 40 1c             	mov    0x1c(%eax),%eax
80104340:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104347:	00 
80104348:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010434f:	00 
80104350:	89 04 24             	mov    %eax,(%esp)
80104353:	e8 28 0c 00 00       	call   80104f80 <memset>
  p->context->eip = (uint)forkret;
80104358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010435e:	ba 36 4a 10 80       	mov    $0x80104a36,%edx
80104363:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104366:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104369:	c9                   	leave  
8010436a:	c3                   	ret    

8010436b <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010436b:	55                   	push   %ebp
8010436c:	89 e5                	mov    %esp,%ebp
8010436e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104371:	e8 f6 fe ff ff       	call   8010426c <allocproc>
80104376:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104379:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437c:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104381:	e8 d0 36 00 00       	call   80107a56 <setupkvm>
80104386:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104389:	89 42 04             	mov    %eax,0x4(%edx)
8010438c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010438f:	8b 40 04             	mov    0x4(%eax),%eax
80104392:	85 c0                	test   %eax,%eax
80104394:	75 0c                	jne    801043a2 <userinit+0x37>
    panic("userinit: out of memory?");
80104396:	c7 04 24 90 85 10 80 	movl   $0x80108590,(%esp)
8010439d:	e8 98 c1 ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801043a2:	ba 2c 00 00 00       	mov    $0x2c,%edx
801043a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043aa:	8b 40 04             	mov    0x4(%eax),%eax
801043ad:	89 54 24 08          	mov    %edx,0x8(%esp)
801043b1:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801043b8:	80 
801043b9:	89 04 24             	mov    %eax,(%esp)
801043bc:	e8 ed 38 00 00       	call   80107cae <inituvm>
  p->sz = PGSIZE;
801043c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c4:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801043ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043cd:	8b 40 18             	mov    0x18(%eax),%eax
801043d0:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801043d7:	00 
801043d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801043df:	00 
801043e0:	89 04 24             	mov    %eax,(%esp)
801043e3:	e8 98 0b 00 00       	call   80104f80 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801043e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043eb:	8b 40 18             	mov    0x18(%eax),%eax
801043ee:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801043f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043f7:	8b 40 18             	mov    0x18(%eax),%eax
801043fa:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104400:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104403:	8b 40 18             	mov    0x18(%eax),%eax
80104406:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104409:	8b 52 18             	mov    0x18(%edx),%edx
8010440c:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104410:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104414:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104417:	8b 40 18             	mov    0x18(%eax),%eax
8010441a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010441d:	8b 52 18             	mov    0x18(%edx),%edx
80104420:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104424:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442b:	8b 40 18             	mov    0x18(%eax),%eax
8010442e:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104438:	8b 40 18             	mov    0x18(%eax),%eax
8010443b:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104445:	8b 40 18             	mov    0x18(%eax),%eax
80104448:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010444f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104452:	83 c0 6c             	add    $0x6c,%eax
80104455:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010445c:	00 
8010445d:	c7 44 24 04 a9 85 10 	movl   $0x801085a9,0x4(%esp)
80104464:	80 
80104465:	89 04 24             	mov    %eax,(%esp)
80104468:	e8 33 0d 00 00       	call   801051a0 <safestrcpy>
  p->cwd = namei("/");
8010446d:	c7 04 24 b2 85 10 80 	movl   $0x801085b2,(%esp)
80104474:	e8 43 e2 ff ff       	call   801026bc <namei>
80104479:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010447c:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
8010447f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104482:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104489:	c9                   	leave  
8010448a:	c3                   	ret    

8010448b <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010448b:	55                   	push   %ebp
8010448c:	89 e5                	mov    %esp,%ebp
8010448e:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104491:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104497:	8b 00                	mov    (%eax),%eax
80104499:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010449c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801044a0:	7e 34                	jle    801044d6 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801044a2:	8b 55 08             	mov    0x8(%ebp),%edx
801044a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a8:	01 c2                	add    %eax,%edx
801044aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044b0:	8b 40 04             	mov    0x4(%eax),%eax
801044b3:	89 54 24 08          	mov    %edx,0x8(%esp)
801044b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801044be:	89 04 24             	mov    %eax,(%esp)
801044c1:	e8 5e 39 00 00       	call   80107e24 <allocuvm>
801044c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801044c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801044cd:	75 41                	jne    80104510 <growproc+0x85>
      return -1;
801044cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044d4:	eb 58                	jmp    8010452e <growproc+0xa3>
  } else if(n < 0){
801044d6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801044da:	79 34                	jns    80104510 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801044dc:	8b 55 08             	mov    0x8(%ebp),%edx
801044df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e2:	01 c2                	add    %eax,%edx
801044e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044ea:	8b 40 04             	mov    0x4(%eax),%eax
801044ed:	89 54 24 08          	mov    %edx,0x8(%esp)
801044f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801044f8:	89 04 24             	mov    %eax,(%esp)
801044fb:	e8 fe 39 00 00       	call   80107efe <deallocuvm>
80104500:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104503:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104507:	75 07                	jne    80104510 <growproc+0x85>
      return -1;
80104509:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010450e:	eb 1e                	jmp    8010452e <growproc+0xa3>
  }
  proc->sz = sz;
80104510:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104516:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104519:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010451b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104521:	89 04 24             	mov    %eax,(%esp)
80104524:	e8 1e 36 00 00       	call   80107b47 <switchuvm>
  return 0;
80104529:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010452e:	c9                   	leave  
8010452f:	c3                   	ret    

80104530 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104530:	55                   	push   %ebp
80104531:	89 e5                	mov    %esp,%ebp
80104533:	57                   	push   %edi
80104534:	56                   	push   %esi
80104535:	53                   	push   %ebx
80104536:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104539:	e8 2e fd ff ff       	call   8010426c <allocproc>
8010453e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104541:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104545:	75 0a                	jne    80104551 <fork+0x21>
    return -1;
80104547:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010454c:	e9 3a 01 00 00       	jmp    8010468b <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104551:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104557:	8b 10                	mov    (%eax),%edx
80104559:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010455f:	8b 40 04             	mov    0x4(%eax),%eax
80104562:	89 54 24 04          	mov    %edx,0x4(%esp)
80104566:	89 04 24             	mov    %eax,(%esp)
80104569:	e8 2c 3b 00 00       	call   8010809a <copyuvm>
8010456e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104571:	89 42 04             	mov    %eax,0x4(%edx)
80104574:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104577:	8b 40 04             	mov    0x4(%eax),%eax
8010457a:	85 c0                	test   %eax,%eax
8010457c:	75 2c                	jne    801045aa <fork+0x7a>
    kfree(np->kstack);
8010457e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104581:	8b 40 08             	mov    0x8(%eax),%eax
80104584:	89 04 24             	mov    %eax,(%esp)
80104587:	e8 73 e7 ff ff       	call   80102cff <kfree>
    np->kstack = 0;
8010458c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010458f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104596:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104599:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801045a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a5:	e9 e1 00 00 00       	jmp    8010468b <fork+0x15b>
  }
  np->sz = proc->sz;
801045aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045b0:	8b 10                	mov    (%eax),%edx
801045b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045b5:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801045b7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801045be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045c1:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801045c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045c7:	8b 50 18             	mov    0x18(%eax),%edx
801045ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045d0:	8b 40 18             	mov    0x18(%eax),%eax
801045d3:	89 c3                	mov    %eax,%ebx
801045d5:	b8 13 00 00 00       	mov    $0x13,%eax
801045da:	89 d7                	mov    %edx,%edi
801045dc:	89 de                	mov    %ebx,%esi
801045de:	89 c1                	mov    %eax,%ecx
801045e0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801045e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045e5:	8b 40 18             	mov    0x18(%eax),%eax
801045e8:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801045ef:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801045f6:	eb 3d                	jmp    80104635 <fork+0x105>
    if(proc->ofile[i])
801045f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045fe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104601:	83 c2 08             	add    $0x8,%edx
80104604:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104608:	85 c0                	test   %eax,%eax
8010460a:	74 25                	je     80104631 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010460c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104612:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104615:	83 c2 08             	add    $0x8,%edx
80104618:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010461c:	89 04 24             	mov    %eax,(%esp)
8010461f:	e8 4e c9 ff ff       	call   80100f72 <filedup>
80104624:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104627:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010462a:	83 c1 08             	add    $0x8,%ecx
8010462d:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104631:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104635:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104639:	7e bd                	jle    801045f8 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010463b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104641:	8b 40 68             	mov    0x68(%eax),%eax
80104644:	89 04 24             	mov    %eax,(%esp)
80104647:	e8 c9 d1 ff ff       	call   80101815 <idup>
8010464c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010464f:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104652:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104655:	8b 40 10             	mov    0x10(%eax),%eax
80104658:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
8010465b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010465e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104665:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010466b:	8d 50 6c             	lea    0x6c(%eax),%edx
8010466e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104671:	83 c0 6c             	add    $0x6c,%eax
80104674:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010467b:	00 
8010467c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104680:	89 04 24             	mov    %eax,(%esp)
80104683:	e8 18 0b 00 00       	call   801051a0 <safestrcpy>
  return pid;
80104688:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010468b:	83 c4 2c             	add    $0x2c,%esp
8010468e:	5b                   	pop    %ebx
8010468f:	5e                   	pop    %esi
80104690:	5f                   	pop    %edi
80104691:	5d                   	pop    %ebp
80104692:	c3                   	ret    

80104693 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104693:	55                   	push   %ebp
80104694:	89 e5                	mov    %esp,%ebp
80104696:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104699:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801046a0:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801046a5:	39 c2                	cmp    %eax,%edx
801046a7:	75 0c                	jne    801046b5 <exit+0x22>
    panic("init exiting");
801046a9:	c7 04 24 b4 85 10 80 	movl   $0x801085b4,(%esp)
801046b0:	e8 85 be ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801046b5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801046bc:	eb 44                	jmp    80104702 <exit+0x6f>
    if(proc->ofile[fd]){
801046be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046c7:	83 c2 08             	add    $0x8,%edx
801046ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046ce:	85 c0                	test   %eax,%eax
801046d0:	74 2c                	je     801046fe <exit+0x6b>
      fileclose(proc->ofile[fd]);
801046d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046db:	83 c2 08             	add    $0x8,%edx
801046de:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046e2:	89 04 24             	mov    %eax,(%esp)
801046e5:	e8 d0 c8 ff ff       	call   80100fba <fileclose>
      proc->ofile[fd] = 0;
801046ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046f3:	83 c2 08             	add    $0x8,%edx
801046f6:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801046fd:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801046fe:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104702:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104706:	7e b6                	jle    801046be <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104708:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010470e:	8b 40 68             	mov    0x68(%eax),%eax
80104711:	89 04 24             	mov    %eax,(%esp)
80104714:	e8 e1 d2 ff ff       	call   801019fa <iput>
  proc->cwd = 0;
80104719:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471f:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104726:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010472d:	e8 fa 05 00 00       	call   80104d2c <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104732:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104738:	8b 40 14             	mov    0x14(%eax),%eax
8010473b:	89 04 24             	mov    %eax,(%esp)
8010473e:	e8 ba 03 00 00       	call   80104afd <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104743:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
8010474a:	eb 38                	jmp    80104784 <exit+0xf1>
    if(p->parent == proc){
8010474c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474f:	8b 50 14             	mov    0x14(%eax),%edx
80104752:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104758:	39 c2                	cmp    %eax,%edx
8010475a:	75 24                	jne    80104780 <exit+0xed>
      p->parent = initproc;
8010475c:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104762:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104765:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104768:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010476b:	8b 40 0c             	mov    0xc(%eax),%eax
8010476e:	83 f8 05             	cmp    $0x5,%eax
80104771:	75 0d                	jne    80104780 <exit+0xed>
        wakeup1(initproc);
80104773:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104778:	89 04 24             	mov    %eax,(%esp)
8010477b:	e8 7d 03 00 00       	call   80104afd <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104780:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104784:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
8010478b:	72 bf                	jb     8010474c <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010478d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104793:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010479a:	e8 b3 01 00 00       	call   80104952 <sched>
  panic("zombie exit");
8010479f:	c7 04 24 c1 85 10 80 	movl   $0x801085c1,(%esp)
801047a6:	e8 8f bd ff ff       	call   8010053a <panic>

801047ab <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801047ab:	55                   	push   %ebp
801047ac:	89 e5                	mov    %esp,%ebp
801047ae:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801047b1:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801047b8:	e8 6f 05 00 00       	call   80104d2c <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801047bd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047c4:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801047cb:	e9 9a 00 00 00       	jmp    8010486a <wait+0xbf>
      if(p->parent != proc)
801047d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d3:	8b 50 14             	mov    0x14(%eax),%edx
801047d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047dc:	39 c2                	cmp    %eax,%edx
801047de:	74 05                	je     801047e5 <wait+0x3a>
        continue;
801047e0:	e9 81 00 00 00       	jmp    80104866 <wait+0xbb>
      havekids = 1;
801047e5:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801047ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ef:	8b 40 0c             	mov    0xc(%eax),%eax
801047f2:	83 f8 05             	cmp    $0x5,%eax
801047f5:	75 6f                	jne    80104866 <wait+0xbb>
        // Found one.
        pid = p->pid;
801047f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047fa:	8b 40 10             	mov    0x10(%eax),%eax
801047fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104803:	8b 40 08             	mov    0x8(%eax),%eax
80104806:	89 04 24             	mov    %eax,(%esp)
80104809:	e8 f1 e4 ff ff       	call   80102cff <kfree>
        p->kstack = 0;
8010480e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104811:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104818:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010481b:	8b 40 04             	mov    0x4(%eax),%eax
8010481e:	89 04 24             	mov    %eax,(%esp)
80104821:	e8 94 37 00 00       	call   80107fba <freevm>
        p->state = UNUSED;
80104826:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104829:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104830:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104833:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010483a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104847:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
8010484b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010484e:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104855:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010485c:	e8 2d 05 00 00       	call   80104d8e <release>
        return pid;
80104861:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104864:	eb 52                	jmp    801048b8 <wait+0x10d>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104866:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010486a:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
80104871:	0f 82 59 ff ff ff    	jb     801047d0 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104877:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010487b:	74 0d                	je     8010488a <wait+0xdf>
8010487d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104883:	8b 40 24             	mov    0x24(%eax),%eax
80104886:	85 c0                	test   %eax,%eax
80104888:	74 13                	je     8010489d <wait+0xf2>
      release(&ptable.lock);
8010488a:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104891:	e8 f8 04 00 00       	call   80104d8e <release>
      return -1;
80104896:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010489b:	eb 1b                	jmp    801048b8 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010489d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048a3:	c7 44 24 04 20 ff 10 	movl   $0x8010ff20,0x4(%esp)
801048aa:	80 
801048ab:	89 04 24             	mov    %eax,(%esp)
801048ae:	e8 af 01 00 00       	call   80104a62 <sleep>
  }
801048b3:	e9 05 ff ff ff       	jmp    801047bd <wait+0x12>
}
801048b8:	c9                   	leave  
801048b9:	c3                   	ret    

801048ba <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801048ba:	55                   	push   %ebp
801048bb:	89 e5                	mov    %esp,%ebp
801048bd:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801048c0:	e8 85 f9 ff ff       	call   8010424a <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801048c5:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048cc:	e8 5b 04 00 00       	call   80104d2c <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048d1:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801048d8:	eb 5e                	jmp    80104938 <scheduler+0x7e>
      if(p->state != RUNNABLE)
801048da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048dd:	8b 40 0c             	mov    0xc(%eax),%eax
801048e0:	83 f8 03             	cmp    $0x3,%eax
801048e3:	74 02                	je     801048e7 <scheduler+0x2d>
        continue;
801048e5:	eb 4d                	jmp    80104934 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801048e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048ea:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801048f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048f3:	89 04 24             	mov    %eax,(%esp)
801048f6:	e8 4c 32 00 00       	call   80107b47 <switchuvm>
      p->state = RUNNING;
801048fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048fe:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104905:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010490b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010490e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104915:	83 c2 04             	add    $0x4,%edx
80104918:	89 44 24 04          	mov    %eax,0x4(%esp)
8010491c:	89 14 24             	mov    %edx,(%esp)
8010491f:	e8 ed 08 00 00       	call   80105211 <swtch>
      switchkvm();
80104924:	e8 01 32 00 00       	call   80107b2a <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104929:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104930:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104934:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104938:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
8010493f:	72 99                	jb     801048da <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104941:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104948:	e8 41 04 00 00       	call   80104d8e <release>

  }
8010494d:	e9 6e ff ff ff       	jmp    801048c0 <scheduler+0x6>

80104952 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104952:	55                   	push   %ebp
80104953:	89 e5                	mov    %esp,%ebp
80104955:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104958:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010495f:	e8 f2 04 00 00       	call   80104e56 <holding>
80104964:	85 c0                	test   %eax,%eax
80104966:	75 0c                	jne    80104974 <sched+0x22>
    panic("sched ptable.lock");
80104968:	c7 04 24 cd 85 10 80 	movl   $0x801085cd,(%esp)
8010496f:	e8 c6 bb ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104974:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010497a:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104980:	83 f8 01             	cmp    $0x1,%eax
80104983:	74 0c                	je     80104991 <sched+0x3f>
    panic("sched locks");
80104985:	c7 04 24 df 85 10 80 	movl   $0x801085df,(%esp)
8010498c:	e8 a9 bb ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104991:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104997:	8b 40 0c             	mov    0xc(%eax),%eax
8010499a:	83 f8 04             	cmp    $0x4,%eax
8010499d:	75 0c                	jne    801049ab <sched+0x59>
    panic("sched running");
8010499f:	c7 04 24 eb 85 10 80 	movl   $0x801085eb,(%esp)
801049a6:	e8 8f bb ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
801049ab:	e8 8a f8 ff ff       	call   8010423a <readeflags>
801049b0:	25 00 02 00 00       	and    $0x200,%eax
801049b5:	85 c0                	test   %eax,%eax
801049b7:	74 0c                	je     801049c5 <sched+0x73>
    panic("sched interruptible");
801049b9:	c7 04 24 f9 85 10 80 	movl   $0x801085f9,(%esp)
801049c0:	e8 75 bb ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801049c5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801049cb:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801049d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801049d4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801049da:	8b 40 04             	mov    0x4(%eax),%eax
801049dd:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801049e4:	83 c2 1c             	add    $0x1c,%edx
801049e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801049eb:	89 14 24             	mov    %edx,(%esp)
801049ee:	e8 1e 08 00 00       	call   80105211 <swtch>
  cpu->intena = intena;
801049f3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801049f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049fc:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104a02:	c9                   	leave  
80104a03:	c3                   	ret    

80104a04 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104a04:	55                   	push   %ebp
80104a05:	89 e5                	mov    %esp,%ebp
80104a07:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104a0a:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a11:	e8 16 03 00 00       	call   80104d2c <acquire>
  proc->state = RUNNABLE;
80104a16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a1c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104a23:	e8 2a ff ff ff       	call   80104952 <sched>
  release(&ptable.lock);
80104a28:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a2f:	e8 5a 03 00 00       	call   80104d8e <release>
}
80104a34:	c9                   	leave  
80104a35:	c3                   	ret    

80104a36 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104a36:	55                   	push   %ebp
80104a37:	89 e5                	mov    %esp,%ebp
80104a39:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104a3c:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a43:	e8 46 03 00 00       	call   80104d8e <release>

  if (first) {
80104a48:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104a4d:	85 c0                	test   %eax,%eax
80104a4f:	74 0f                	je     80104a60 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104a51:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104a58:	00 00 00 
    initlog();
80104a5b:	e8 2d e8 ff ff       	call   8010328d <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104a60:	c9                   	leave  
80104a61:	c3                   	ret    

80104a62 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104a62:	55                   	push   %ebp
80104a63:	89 e5                	mov    %esp,%ebp
80104a65:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104a68:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a6e:	85 c0                	test   %eax,%eax
80104a70:	75 0c                	jne    80104a7e <sleep+0x1c>
    panic("sleep");
80104a72:	c7 04 24 0d 86 10 80 	movl   $0x8010860d,(%esp)
80104a79:	e8 bc ba ff ff       	call   8010053a <panic>

  if(lk == 0)
80104a7e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104a82:	75 0c                	jne    80104a90 <sleep+0x2e>
    panic("sleep without lk");
80104a84:	c7 04 24 13 86 10 80 	movl   $0x80108613,(%esp)
80104a8b:	e8 aa ba ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104a90:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
80104a97:	74 17                	je     80104ab0 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104a99:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104aa0:	e8 87 02 00 00       	call   80104d2c <acquire>
    release(lk);
80104aa5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104aa8:	89 04 24             	mov    %eax,(%esp)
80104aab:	e8 de 02 00 00       	call   80104d8e <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104ab0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ab6:	8b 55 08             	mov    0x8(%ebp),%edx
80104ab9:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104abc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ac2:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104ac9:	e8 84 fe ff ff       	call   80104952 <sched>

  // Tidy up.
  proc->chan = 0;
80104ace:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad4:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104adb:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
80104ae2:	74 17                	je     80104afb <sleep+0x99>
    release(&ptable.lock);
80104ae4:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104aeb:	e8 9e 02 00 00       	call   80104d8e <release>
    acquire(lk);
80104af0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104af3:	89 04 24             	mov    %eax,(%esp)
80104af6:	e8 31 02 00 00       	call   80104d2c <acquire>
  }
}
80104afb:	c9                   	leave  
80104afc:	c3                   	ret    

80104afd <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104afd:	55                   	push   %ebp
80104afe:	89 e5                	mov    %esp,%ebp
80104b00:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b03:	c7 45 fc 54 ff 10 80 	movl   $0x8010ff54,-0x4(%ebp)
80104b0a:	eb 24                	jmp    80104b30 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104b0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104b0f:	8b 40 0c             	mov    0xc(%eax),%eax
80104b12:	83 f8 02             	cmp    $0x2,%eax
80104b15:	75 15                	jne    80104b2c <wakeup1+0x2f>
80104b17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104b1a:	8b 40 20             	mov    0x20(%eax),%eax
80104b1d:	3b 45 08             	cmp    0x8(%ebp),%eax
80104b20:	75 0a                	jne    80104b2c <wakeup1+0x2f>
      p->state = RUNNABLE;
80104b22:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104b25:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b2c:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104b30:	81 7d fc 54 1e 11 80 	cmpl   $0x80111e54,-0x4(%ebp)
80104b37:	72 d3                	jb     80104b0c <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104b39:	c9                   	leave  
80104b3a:	c3                   	ret    

80104b3b <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104b3b:	55                   	push   %ebp
80104b3c:	89 e5                	mov    %esp,%ebp
80104b3e:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104b41:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104b48:	e8 df 01 00 00       	call   80104d2c <acquire>
  wakeup1(chan);
80104b4d:	8b 45 08             	mov    0x8(%ebp),%eax
80104b50:	89 04 24             	mov    %eax,(%esp)
80104b53:	e8 a5 ff ff ff       	call   80104afd <wakeup1>
  release(&ptable.lock);
80104b58:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104b5f:	e8 2a 02 00 00       	call   80104d8e <release>
}
80104b64:	c9                   	leave  
80104b65:	c3                   	ret    

80104b66 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104b66:	55                   	push   %ebp
80104b67:	89 e5                	mov    %esp,%ebp
80104b69:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104b6c:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104b73:	e8 b4 01 00 00       	call   80104d2c <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b78:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104b7f:	eb 41                	jmp    80104bc2 <kill+0x5c>
    if(p->pid == pid){
80104b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b84:	8b 40 10             	mov    0x10(%eax),%eax
80104b87:	3b 45 08             	cmp    0x8(%ebp),%eax
80104b8a:	75 32                	jne    80104bbe <kill+0x58>
      p->killed = 1;
80104b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b8f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b99:	8b 40 0c             	mov    0xc(%eax),%eax
80104b9c:	83 f8 02             	cmp    $0x2,%eax
80104b9f:	75 0a                	jne    80104bab <kill+0x45>
        p->state = RUNNABLE;
80104ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104bab:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104bb2:	e8 d7 01 00 00       	call   80104d8e <release>
      return 0;
80104bb7:	b8 00 00 00 00       	mov    $0x0,%eax
80104bbc:	eb 1e                	jmp    80104bdc <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bbe:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104bc2:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
80104bc9:	72 b6                	jb     80104b81 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104bcb:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104bd2:	e8 b7 01 00 00       	call   80104d8e <release>
  return -1;
80104bd7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104bdc:	c9                   	leave  
80104bdd:	c3                   	ret    

80104bde <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104bde:	55                   	push   %ebp
80104bdf:	89 e5                	mov    %esp,%ebp
80104be1:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104be4:	c7 45 f0 54 ff 10 80 	movl   $0x8010ff54,-0x10(%ebp)
80104beb:	e9 d6 00 00 00       	jmp    80104cc6 <procdump+0xe8>
    if(p->state == UNUSED)
80104bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf3:	8b 40 0c             	mov    0xc(%eax),%eax
80104bf6:	85 c0                	test   %eax,%eax
80104bf8:	75 05                	jne    80104bff <procdump+0x21>
      continue;
80104bfa:	e9 c3 00 00 00       	jmp    80104cc2 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104bff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c02:	8b 40 0c             	mov    0xc(%eax),%eax
80104c05:	83 f8 05             	cmp    $0x5,%eax
80104c08:	77 23                	ja     80104c2d <procdump+0x4f>
80104c0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c0d:	8b 40 0c             	mov    0xc(%eax),%eax
80104c10:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104c17:	85 c0                	test   %eax,%eax
80104c19:	74 12                	je     80104c2d <procdump+0x4f>
      state = states[p->state];
80104c1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c1e:	8b 40 0c             	mov    0xc(%eax),%eax
80104c21:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104c28:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104c2b:	eb 07                	jmp    80104c34 <procdump+0x56>
    else
      state = "???";
80104c2d:	c7 45 ec 24 86 10 80 	movl   $0x80108624,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104c34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c37:	8d 50 6c             	lea    0x6c(%eax),%edx
80104c3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c3d:	8b 40 10             	mov    0x10(%eax),%eax
80104c40:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104c44:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104c47:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c4f:	c7 04 24 28 86 10 80 	movl   $0x80108628,(%esp)
80104c56:	e8 45 b7 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104c5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c5e:	8b 40 0c             	mov    0xc(%eax),%eax
80104c61:	83 f8 02             	cmp    $0x2,%eax
80104c64:	75 50                	jne    80104cb6 <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104c66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c69:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c6c:	8b 40 0c             	mov    0xc(%eax),%eax
80104c6f:	83 c0 08             	add    $0x8,%eax
80104c72:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104c75:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c79:	89 04 24             	mov    %eax,(%esp)
80104c7c:	e8 5c 01 00 00       	call   80104ddd <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104c81:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c88:	eb 1b                	jmp    80104ca5 <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104c8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c8d:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c91:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c95:	c7 04 24 31 86 10 80 	movl   $0x80108631,(%esp)
80104c9c:	e8 ff b6 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104ca1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104ca5:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104ca9:	7f 0b                	jg     80104cb6 <procdump+0xd8>
80104cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cae:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104cb2:	85 c0                	test   %eax,%eax
80104cb4:	75 d4                	jne    80104c8a <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104cb6:	c7 04 24 35 86 10 80 	movl   $0x80108635,(%esp)
80104cbd:	e8 de b6 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cc2:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104cc6:	81 7d f0 54 1e 11 80 	cmpl   $0x80111e54,-0x10(%ebp)
80104ccd:	0f 82 1d ff ff ff    	jb     80104bf0 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104cd3:	c9                   	leave  
80104cd4:	c3                   	ret    

80104cd5 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104cd5:	55                   	push   %ebp
80104cd6:	89 e5                	mov    %esp,%ebp
80104cd8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104cdb:	9c                   	pushf  
80104cdc:	58                   	pop    %eax
80104cdd:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104ce0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104ce3:	c9                   	leave  
80104ce4:	c3                   	ret    

80104ce5 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104ce5:	55                   	push   %ebp
80104ce6:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104ce8:	fa                   	cli    
}
80104ce9:	5d                   	pop    %ebp
80104cea:	c3                   	ret    

80104ceb <sti>:

static inline void
sti(void)
{
80104ceb:	55                   	push   %ebp
80104cec:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104cee:	fb                   	sti    
}
80104cef:	5d                   	pop    %ebp
80104cf0:	c3                   	ret    

80104cf1 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104cf1:	55                   	push   %ebp
80104cf2:	89 e5                	mov    %esp,%ebp
80104cf4:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104cf7:	8b 55 08             	mov    0x8(%ebp),%edx
80104cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cfd:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104d00:	f0 87 02             	lock xchg %eax,(%edx)
80104d03:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104d06:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104d09:	c9                   	leave  
80104d0a:	c3                   	ret    

80104d0b <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104d0b:	55                   	push   %ebp
80104d0c:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104d0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d11:	8b 55 0c             	mov    0xc(%ebp),%edx
80104d14:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104d17:	8b 45 08             	mov    0x8(%ebp),%eax
80104d1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104d20:	8b 45 08             	mov    0x8(%ebp),%eax
80104d23:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104d2a:	5d                   	pop    %ebp
80104d2b:	c3                   	ret    

80104d2c <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104d2c:	55                   	push   %ebp
80104d2d:	89 e5                	mov    %esp,%ebp
80104d2f:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104d32:	e8 49 01 00 00       	call   80104e80 <pushcli>
  if(holding(lk))
80104d37:	8b 45 08             	mov    0x8(%ebp),%eax
80104d3a:	89 04 24             	mov    %eax,(%esp)
80104d3d:	e8 14 01 00 00       	call   80104e56 <holding>
80104d42:	85 c0                	test   %eax,%eax
80104d44:	74 0c                	je     80104d52 <acquire+0x26>
    panic("acquire");
80104d46:	c7 04 24 61 86 10 80 	movl   $0x80108661,(%esp)
80104d4d:	e8 e8 b7 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104d52:	90                   	nop
80104d53:	8b 45 08             	mov    0x8(%ebp),%eax
80104d56:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104d5d:	00 
80104d5e:	89 04 24             	mov    %eax,(%esp)
80104d61:	e8 8b ff ff ff       	call   80104cf1 <xchg>
80104d66:	85 c0                	test   %eax,%eax
80104d68:	75 e9                	jne    80104d53 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104d6a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d6d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104d74:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104d77:	8b 45 08             	mov    0x8(%ebp),%eax
80104d7a:	83 c0 0c             	add    $0xc,%eax
80104d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d81:	8d 45 08             	lea    0x8(%ebp),%eax
80104d84:	89 04 24             	mov    %eax,(%esp)
80104d87:	e8 51 00 00 00       	call   80104ddd <getcallerpcs>
}
80104d8c:	c9                   	leave  
80104d8d:	c3                   	ret    

80104d8e <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104d8e:	55                   	push   %ebp
80104d8f:	89 e5                	mov    %esp,%ebp
80104d91:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104d94:	8b 45 08             	mov    0x8(%ebp),%eax
80104d97:	89 04 24             	mov    %eax,(%esp)
80104d9a:	e8 b7 00 00 00       	call   80104e56 <holding>
80104d9f:	85 c0                	test   %eax,%eax
80104da1:	75 0c                	jne    80104daf <release+0x21>
    panic("release");
80104da3:	c7 04 24 69 86 10 80 	movl   $0x80108669,(%esp)
80104daa:	e8 8b b7 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80104daf:	8b 45 08             	mov    0x8(%ebp),%eax
80104db2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104db9:	8b 45 08             	mov    0x8(%ebp),%eax
80104dbc:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104dc3:	8b 45 08             	mov    0x8(%ebp),%eax
80104dc6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104dcd:	00 
80104dce:	89 04 24             	mov    %eax,(%esp)
80104dd1:	e8 1b ff ff ff       	call   80104cf1 <xchg>

  popcli();
80104dd6:	e8 e9 00 00 00       	call   80104ec4 <popcli>
}
80104ddb:	c9                   	leave  
80104ddc:	c3                   	ret    

80104ddd <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104ddd:	55                   	push   %ebp
80104dde:	89 e5                	mov    %esp,%ebp
80104de0:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104de3:	8b 45 08             	mov    0x8(%ebp),%eax
80104de6:	83 e8 08             	sub    $0x8,%eax
80104de9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104dec:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104df3:	eb 38                	jmp    80104e2d <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104df5:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104df9:	74 38                	je     80104e33 <getcallerpcs+0x56>
80104dfb:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104e02:	76 2f                	jbe    80104e33 <getcallerpcs+0x56>
80104e04:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104e08:	74 29                	je     80104e33 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104e0a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e0d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104e14:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e17:	01 c2                	add    %eax,%edx
80104e19:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e1c:	8b 40 04             	mov    0x4(%eax),%eax
80104e1f:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80104e21:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e24:	8b 00                	mov    (%eax),%eax
80104e26:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104e29:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104e2d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104e31:	7e c2                	jle    80104df5 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104e33:	eb 19                	jmp    80104e4e <getcallerpcs+0x71>
    pcs[i] = 0;
80104e35:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e38:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104e3f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e42:	01 d0                	add    %edx,%eax
80104e44:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104e4a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104e4e:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104e52:	7e e1                	jle    80104e35 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80104e54:	c9                   	leave  
80104e55:	c3                   	ret    

80104e56 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104e56:	55                   	push   %ebp
80104e57:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104e59:	8b 45 08             	mov    0x8(%ebp),%eax
80104e5c:	8b 00                	mov    (%eax),%eax
80104e5e:	85 c0                	test   %eax,%eax
80104e60:	74 17                	je     80104e79 <holding+0x23>
80104e62:	8b 45 08             	mov    0x8(%ebp),%eax
80104e65:	8b 50 08             	mov    0x8(%eax),%edx
80104e68:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e6e:	39 c2                	cmp    %eax,%edx
80104e70:	75 07                	jne    80104e79 <holding+0x23>
80104e72:	b8 01 00 00 00       	mov    $0x1,%eax
80104e77:	eb 05                	jmp    80104e7e <holding+0x28>
80104e79:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e7e:	5d                   	pop    %ebp
80104e7f:	c3                   	ret    

80104e80 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104e80:	55                   	push   %ebp
80104e81:	89 e5                	mov    %esp,%ebp
80104e83:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104e86:	e8 4a fe ff ff       	call   80104cd5 <readeflags>
80104e8b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104e8e:	e8 52 fe ff ff       	call   80104ce5 <cli>
  if(cpu->ncli++ == 0)
80104e93:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104e9a:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80104ea0:	8d 48 01             	lea    0x1(%eax),%ecx
80104ea3:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80104ea9:	85 c0                	test   %eax,%eax
80104eab:	75 15                	jne    80104ec2 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80104ead:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104eb3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104eb6:	81 e2 00 02 00 00    	and    $0x200,%edx
80104ebc:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ec2:	c9                   	leave  
80104ec3:	c3                   	ret    

80104ec4 <popcli>:

void
popcli(void)
{
80104ec4:	55                   	push   %ebp
80104ec5:	89 e5                	mov    %esp,%ebp
80104ec7:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104eca:	e8 06 fe ff ff       	call   80104cd5 <readeflags>
80104ecf:	25 00 02 00 00       	and    $0x200,%eax
80104ed4:	85 c0                	test   %eax,%eax
80104ed6:	74 0c                	je     80104ee4 <popcli+0x20>
    panic("popcli - interruptible");
80104ed8:	c7 04 24 71 86 10 80 	movl   $0x80108671,(%esp)
80104edf:	e8 56 b6 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80104ee4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104eea:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104ef0:	83 ea 01             	sub    $0x1,%edx
80104ef3:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104ef9:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104eff:	85 c0                	test   %eax,%eax
80104f01:	79 0c                	jns    80104f0f <popcli+0x4b>
    panic("popcli");
80104f03:	c7 04 24 88 86 10 80 	movl   $0x80108688,(%esp)
80104f0a:	e8 2b b6 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104f0f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f15:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104f1b:	85 c0                	test   %eax,%eax
80104f1d:	75 15                	jne    80104f34 <popcli+0x70>
80104f1f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f25:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104f2b:	85 c0                	test   %eax,%eax
80104f2d:	74 05                	je     80104f34 <popcli+0x70>
    sti();
80104f2f:	e8 b7 fd ff ff       	call   80104ceb <sti>
}
80104f34:	c9                   	leave  
80104f35:	c3                   	ret    

80104f36 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104f36:	55                   	push   %ebp
80104f37:	89 e5                	mov    %esp,%ebp
80104f39:	57                   	push   %edi
80104f3a:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104f3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f3e:	8b 55 10             	mov    0x10(%ebp),%edx
80104f41:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f44:	89 cb                	mov    %ecx,%ebx
80104f46:	89 df                	mov    %ebx,%edi
80104f48:	89 d1                	mov    %edx,%ecx
80104f4a:	fc                   	cld    
80104f4b:	f3 aa                	rep stos %al,%es:(%edi)
80104f4d:	89 ca                	mov    %ecx,%edx
80104f4f:	89 fb                	mov    %edi,%ebx
80104f51:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104f54:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104f57:	5b                   	pop    %ebx
80104f58:	5f                   	pop    %edi
80104f59:	5d                   	pop    %ebp
80104f5a:	c3                   	ret    

80104f5b <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104f5b:	55                   	push   %ebp
80104f5c:	89 e5                	mov    %esp,%ebp
80104f5e:	57                   	push   %edi
80104f5f:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104f60:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f63:	8b 55 10             	mov    0x10(%ebp),%edx
80104f66:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f69:	89 cb                	mov    %ecx,%ebx
80104f6b:	89 df                	mov    %ebx,%edi
80104f6d:	89 d1                	mov    %edx,%ecx
80104f6f:	fc                   	cld    
80104f70:	f3 ab                	rep stos %eax,%es:(%edi)
80104f72:	89 ca                	mov    %ecx,%edx
80104f74:	89 fb                	mov    %edi,%ebx
80104f76:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104f79:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104f7c:	5b                   	pop    %ebx
80104f7d:	5f                   	pop    %edi
80104f7e:	5d                   	pop    %ebp
80104f7f:	c3                   	ret    

80104f80 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104f80:	55                   	push   %ebp
80104f81:	89 e5                	mov    %esp,%ebp
80104f83:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104f86:	8b 45 08             	mov    0x8(%ebp),%eax
80104f89:	83 e0 03             	and    $0x3,%eax
80104f8c:	85 c0                	test   %eax,%eax
80104f8e:	75 49                	jne    80104fd9 <memset+0x59>
80104f90:	8b 45 10             	mov    0x10(%ebp),%eax
80104f93:	83 e0 03             	and    $0x3,%eax
80104f96:	85 c0                	test   %eax,%eax
80104f98:	75 3f                	jne    80104fd9 <memset+0x59>
    c &= 0xFF;
80104f9a:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104fa1:	8b 45 10             	mov    0x10(%ebp),%eax
80104fa4:	c1 e8 02             	shr    $0x2,%eax
80104fa7:	89 c2                	mov    %eax,%edx
80104fa9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fac:	c1 e0 18             	shl    $0x18,%eax
80104faf:	89 c1                	mov    %eax,%ecx
80104fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb4:	c1 e0 10             	shl    $0x10,%eax
80104fb7:	09 c1                	or     %eax,%ecx
80104fb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fbc:	c1 e0 08             	shl    $0x8,%eax
80104fbf:	09 c8                	or     %ecx,%eax
80104fc1:	0b 45 0c             	or     0xc(%ebp),%eax
80104fc4:	89 54 24 08          	mov    %edx,0x8(%esp)
80104fc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80104fcf:	89 04 24             	mov    %eax,(%esp)
80104fd2:	e8 84 ff ff ff       	call   80104f5b <stosl>
80104fd7:	eb 19                	jmp    80104ff2 <memset+0x72>
  } else
    stosb(dst, c, n);
80104fd9:	8b 45 10             	mov    0x10(%ebp),%eax
80104fdc:	89 44 24 08          	mov    %eax,0x8(%esp)
80104fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fe3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80104fea:	89 04 24             	mov    %eax,(%esp)
80104fed:	e8 44 ff ff ff       	call   80104f36 <stosb>
  return dst;
80104ff2:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104ff5:	c9                   	leave  
80104ff6:	c3                   	ret    

80104ff7 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104ff7:	55                   	push   %ebp
80104ff8:	89 e5                	mov    %esp,%ebp
80104ffa:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104ffd:	8b 45 08             	mov    0x8(%ebp),%eax
80105000:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105003:	8b 45 0c             	mov    0xc(%ebp),%eax
80105006:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105009:	eb 30                	jmp    8010503b <memcmp+0x44>
    if(*s1 != *s2)
8010500b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010500e:	0f b6 10             	movzbl (%eax),%edx
80105011:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105014:	0f b6 00             	movzbl (%eax),%eax
80105017:	38 c2                	cmp    %al,%dl
80105019:	74 18                	je     80105033 <memcmp+0x3c>
      return *s1 - *s2;
8010501b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010501e:	0f b6 00             	movzbl (%eax),%eax
80105021:	0f b6 d0             	movzbl %al,%edx
80105024:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105027:	0f b6 00             	movzbl (%eax),%eax
8010502a:	0f b6 c0             	movzbl %al,%eax
8010502d:	29 c2                	sub    %eax,%edx
8010502f:	89 d0                	mov    %edx,%eax
80105031:	eb 1a                	jmp    8010504d <memcmp+0x56>
    s1++, s2++;
80105033:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105037:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010503b:	8b 45 10             	mov    0x10(%ebp),%eax
8010503e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105041:	89 55 10             	mov    %edx,0x10(%ebp)
80105044:	85 c0                	test   %eax,%eax
80105046:	75 c3                	jne    8010500b <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105048:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010504d:	c9                   	leave  
8010504e:	c3                   	ret    

8010504f <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010504f:	55                   	push   %ebp
80105050:	89 e5                	mov    %esp,%ebp
80105052:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105055:	8b 45 0c             	mov    0xc(%ebp),%eax
80105058:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010505b:	8b 45 08             	mov    0x8(%ebp),%eax
8010505e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105061:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105064:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105067:	73 3d                	jae    801050a6 <memmove+0x57>
80105069:	8b 45 10             	mov    0x10(%ebp),%eax
8010506c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010506f:	01 d0                	add    %edx,%eax
80105071:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105074:	76 30                	jbe    801050a6 <memmove+0x57>
    s += n;
80105076:	8b 45 10             	mov    0x10(%ebp),%eax
80105079:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010507c:	8b 45 10             	mov    0x10(%ebp),%eax
8010507f:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105082:	eb 13                	jmp    80105097 <memmove+0x48>
      *--d = *--s;
80105084:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105088:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010508c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010508f:	0f b6 10             	movzbl (%eax),%edx
80105092:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105095:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105097:	8b 45 10             	mov    0x10(%ebp),%eax
8010509a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010509d:	89 55 10             	mov    %edx,0x10(%ebp)
801050a0:	85 c0                	test   %eax,%eax
801050a2:	75 e0                	jne    80105084 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801050a4:	eb 26                	jmp    801050cc <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801050a6:	eb 17                	jmp    801050bf <memmove+0x70>
      *d++ = *s++;
801050a8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050ab:	8d 50 01             	lea    0x1(%eax),%edx
801050ae:	89 55 f8             	mov    %edx,-0x8(%ebp)
801050b1:	8b 55 fc             	mov    -0x4(%ebp),%edx
801050b4:	8d 4a 01             	lea    0x1(%edx),%ecx
801050b7:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801050ba:	0f b6 12             	movzbl (%edx),%edx
801050bd:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801050bf:	8b 45 10             	mov    0x10(%ebp),%eax
801050c2:	8d 50 ff             	lea    -0x1(%eax),%edx
801050c5:	89 55 10             	mov    %edx,0x10(%ebp)
801050c8:	85 c0                	test   %eax,%eax
801050ca:	75 dc                	jne    801050a8 <memmove+0x59>
      *d++ = *s++;

  return dst;
801050cc:	8b 45 08             	mov    0x8(%ebp),%eax
}
801050cf:	c9                   	leave  
801050d0:	c3                   	ret    

801050d1 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801050d1:	55                   	push   %ebp
801050d2:	89 e5                	mov    %esp,%ebp
801050d4:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801050d7:	8b 45 10             	mov    0x10(%ebp),%eax
801050da:	89 44 24 08          	mov    %eax,0x8(%esp)
801050de:	8b 45 0c             	mov    0xc(%ebp),%eax
801050e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801050e5:	8b 45 08             	mov    0x8(%ebp),%eax
801050e8:	89 04 24             	mov    %eax,(%esp)
801050eb:	e8 5f ff ff ff       	call   8010504f <memmove>
}
801050f0:	c9                   	leave  
801050f1:	c3                   	ret    

801050f2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801050f2:	55                   	push   %ebp
801050f3:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801050f5:	eb 0c                	jmp    80105103 <strncmp+0x11>
    n--, p++, q++;
801050f7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050fb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050ff:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105103:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105107:	74 1a                	je     80105123 <strncmp+0x31>
80105109:	8b 45 08             	mov    0x8(%ebp),%eax
8010510c:	0f b6 00             	movzbl (%eax),%eax
8010510f:	84 c0                	test   %al,%al
80105111:	74 10                	je     80105123 <strncmp+0x31>
80105113:	8b 45 08             	mov    0x8(%ebp),%eax
80105116:	0f b6 10             	movzbl (%eax),%edx
80105119:	8b 45 0c             	mov    0xc(%ebp),%eax
8010511c:	0f b6 00             	movzbl (%eax),%eax
8010511f:	38 c2                	cmp    %al,%dl
80105121:	74 d4                	je     801050f7 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105123:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105127:	75 07                	jne    80105130 <strncmp+0x3e>
    return 0;
80105129:	b8 00 00 00 00       	mov    $0x0,%eax
8010512e:	eb 16                	jmp    80105146 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105130:	8b 45 08             	mov    0x8(%ebp),%eax
80105133:	0f b6 00             	movzbl (%eax),%eax
80105136:	0f b6 d0             	movzbl %al,%edx
80105139:	8b 45 0c             	mov    0xc(%ebp),%eax
8010513c:	0f b6 00             	movzbl (%eax),%eax
8010513f:	0f b6 c0             	movzbl %al,%eax
80105142:	29 c2                	sub    %eax,%edx
80105144:	89 d0                	mov    %edx,%eax
}
80105146:	5d                   	pop    %ebp
80105147:	c3                   	ret    

80105148 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105148:	55                   	push   %ebp
80105149:	89 e5                	mov    %esp,%ebp
8010514b:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010514e:	8b 45 08             	mov    0x8(%ebp),%eax
80105151:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105154:	90                   	nop
80105155:	8b 45 10             	mov    0x10(%ebp),%eax
80105158:	8d 50 ff             	lea    -0x1(%eax),%edx
8010515b:	89 55 10             	mov    %edx,0x10(%ebp)
8010515e:	85 c0                	test   %eax,%eax
80105160:	7e 1e                	jle    80105180 <strncpy+0x38>
80105162:	8b 45 08             	mov    0x8(%ebp),%eax
80105165:	8d 50 01             	lea    0x1(%eax),%edx
80105168:	89 55 08             	mov    %edx,0x8(%ebp)
8010516b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010516e:	8d 4a 01             	lea    0x1(%edx),%ecx
80105171:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105174:	0f b6 12             	movzbl (%edx),%edx
80105177:	88 10                	mov    %dl,(%eax)
80105179:	0f b6 00             	movzbl (%eax),%eax
8010517c:	84 c0                	test   %al,%al
8010517e:	75 d5                	jne    80105155 <strncpy+0xd>
    ;
  while(n-- > 0)
80105180:	eb 0c                	jmp    8010518e <strncpy+0x46>
    *s++ = 0;
80105182:	8b 45 08             	mov    0x8(%ebp),%eax
80105185:	8d 50 01             	lea    0x1(%eax),%edx
80105188:	89 55 08             	mov    %edx,0x8(%ebp)
8010518b:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010518e:	8b 45 10             	mov    0x10(%ebp),%eax
80105191:	8d 50 ff             	lea    -0x1(%eax),%edx
80105194:	89 55 10             	mov    %edx,0x10(%ebp)
80105197:	85 c0                	test   %eax,%eax
80105199:	7f e7                	jg     80105182 <strncpy+0x3a>
    *s++ = 0;
  return os;
8010519b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010519e:	c9                   	leave  
8010519f:	c3                   	ret    

801051a0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801051a0:	55                   	push   %ebp
801051a1:	89 e5                	mov    %esp,%ebp
801051a3:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801051a6:	8b 45 08             	mov    0x8(%ebp),%eax
801051a9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801051ac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801051b0:	7f 05                	jg     801051b7 <safestrcpy+0x17>
    return os;
801051b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051b5:	eb 31                	jmp    801051e8 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
801051b7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801051bb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801051bf:	7e 1e                	jle    801051df <safestrcpy+0x3f>
801051c1:	8b 45 08             	mov    0x8(%ebp),%eax
801051c4:	8d 50 01             	lea    0x1(%eax),%edx
801051c7:	89 55 08             	mov    %edx,0x8(%ebp)
801051ca:	8b 55 0c             	mov    0xc(%ebp),%edx
801051cd:	8d 4a 01             	lea    0x1(%edx),%ecx
801051d0:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801051d3:	0f b6 12             	movzbl (%edx),%edx
801051d6:	88 10                	mov    %dl,(%eax)
801051d8:	0f b6 00             	movzbl (%eax),%eax
801051db:	84 c0                	test   %al,%al
801051dd:	75 d8                	jne    801051b7 <safestrcpy+0x17>
    ;
  *s = 0;
801051df:	8b 45 08             	mov    0x8(%ebp),%eax
801051e2:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801051e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801051e8:	c9                   	leave  
801051e9:	c3                   	ret    

801051ea <strlen>:

int
strlen(const char *s)
{
801051ea:	55                   	push   %ebp
801051eb:	89 e5                	mov    %esp,%ebp
801051ed:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801051f0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801051f7:	eb 04                	jmp    801051fd <strlen+0x13>
801051f9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051fd:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105200:	8b 45 08             	mov    0x8(%ebp),%eax
80105203:	01 d0                	add    %edx,%eax
80105205:	0f b6 00             	movzbl (%eax),%eax
80105208:	84 c0                	test   %al,%al
8010520a:	75 ed                	jne    801051f9 <strlen+0xf>
    ;
  return n;
8010520c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010520f:	c9                   	leave  
80105210:	c3                   	ret    

80105211 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105211:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105215:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105219:	55                   	push   %ebp
  pushl %ebx
8010521a:	53                   	push   %ebx
  pushl %esi
8010521b:	56                   	push   %esi
  pushl %edi
8010521c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010521d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010521f:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105221:	5f                   	pop    %edi
  popl %esi
80105222:	5e                   	pop    %esi
  popl %ebx
80105223:	5b                   	pop    %ebx
  popl %ebp
80105224:	5d                   	pop    %ebp
  ret
80105225:	c3                   	ret    

80105226 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105226:	55                   	push   %ebp
80105227:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105229:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010522f:	8b 00                	mov    (%eax),%eax
80105231:	3b 45 08             	cmp    0x8(%ebp),%eax
80105234:	76 12                	jbe    80105248 <fetchint+0x22>
80105236:	8b 45 08             	mov    0x8(%ebp),%eax
80105239:	8d 50 04             	lea    0x4(%eax),%edx
8010523c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105242:	8b 00                	mov    (%eax),%eax
80105244:	39 c2                	cmp    %eax,%edx
80105246:	76 07                	jbe    8010524f <fetchint+0x29>
    return -1;
80105248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010524d:	eb 0f                	jmp    8010525e <fetchint+0x38>
  *ip = *(int*)(addr);
8010524f:	8b 45 08             	mov    0x8(%ebp),%eax
80105252:	8b 10                	mov    (%eax),%edx
80105254:	8b 45 0c             	mov    0xc(%ebp),%eax
80105257:	89 10                	mov    %edx,(%eax)
  return 0;
80105259:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010525e:	5d                   	pop    %ebp
8010525f:	c3                   	ret    

80105260 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105260:	55                   	push   %ebp
80105261:	89 e5                	mov    %esp,%ebp
80105263:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105266:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526c:	8b 00                	mov    (%eax),%eax
8010526e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105271:	77 07                	ja     8010527a <fetchstr+0x1a>
    return -1;
80105273:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105278:	eb 46                	jmp    801052c0 <fetchstr+0x60>
  *pp = (char*)addr;
8010527a:	8b 55 08             	mov    0x8(%ebp),%edx
8010527d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105280:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105282:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105288:	8b 00                	mov    (%eax),%eax
8010528a:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010528d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105290:	8b 00                	mov    (%eax),%eax
80105292:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105295:	eb 1c                	jmp    801052b3 <fetchstr+0x53>
    if(*s == 0)
80105297:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010529a:	0f b6 00             	movzbl (%eax),%eax
8010529d:	84 c0                	test   %al,%al
8010529f:	75 0e                	jne    801052af <fetchstr+0x4f>
      return s - *pp;
801052a1:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801052a7:	8b 00                	mov    (%eax),%eax
801052a9:	29 c2                	sub    %eax,%edx
801052ab:	89 d0                	mov    %edx,%eax
801052ad:	eb 11                	jmp    801052c0 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
801052af:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801052b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052b6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052b9:	72 dc                	jb     80105297 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
801052bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801052c0:	c9                   	leave  
801052c1:	c3                   	ret    

801052c2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801052c2:	55                   	push   %ebp
801052c3:	89 e5                	mov    %esp,%ebp
801052c5:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
801052c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ce:	8b 40 18             	mov    0x18(%eax),%eax
801052d1:	8b 50 44             	mov    0x44(%eax),%edx
801052d4:	8b 45 08             	mov    0x8(%ebp),%eax
801052d7:	c1 e0 02             	shl    $0x2,%eax
801052da:	01 d0                	add    %edx,%eax
801052dc:	8d 50 04             	lea    0x4(%eax),%edx
801052df:	8b 45 0c             	mov    0xc(%ebp),%eax
801052e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801052e6:	89 14 24             	mov    %edx,(%esp)
801052e9:	e8 38 ff ff ff       	call   80105226 <fetchint>
}
801052ee:	c9                   	leave  
801052ef:	c3                   	ret    

801052f0 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801052f0:	55                   	push   %ebp
801052f1:	89 e5                	mov    %esp,%ebp
801052f3:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801052f6:	8d 45 fc             	lea    -0x4(%ebp),%eax
801052f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801052fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105300:	89 04 24             	mov    %eax,(%esp)
80105303:	e8 ba ff ff ff       	call   801052c2 <argint>
80105308:	85 c0                	test   %eax,%eax
8010530a:	79 07                	jns    80105313 <argptr+0x23>
    return -1;
8010530c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105311:	eb 3d                	jmp    80105350 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105313:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105316:	89 c2                	mov    %eax,%edx
80105318:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010531e:	8b 00                	mov    (%eax),%eax
80105320:	39 c2                	cmp    %eax,%edx
80105322:	73 16                	jae    8010533a <argptr+0x4a>
80105324:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105327:	89 c2                	mov    %eax,%edx
80105329:	8b 45 10             	mov    0x10(%ebp),%eax
8010532c:	01 c2                	add    %eax,%edx
8010532e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105334:	8b 00                	mov    (%eax),%eax
80105336:	39 c2                	cmp    %eax,%edx
80105338:	76 07                	jbe    80105341 <argptr+0x51>
    return -1;
8010533a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010533f:	eb 0f                	jmp    80105350 <argptr+0x60>
  *pp = (char*)i;
80105341:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105344:	89 c2                	mov    %eax,%edx
80105346:	8b 45 0c             	mov    0xc(%ebp),%eax
80105349:	89 10                	mov    %edx,(%eax)
  return 0;
8010534b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105350:	c9                   	leave  
80105351:	c3                   	ret    

80105352 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105352:	55                   	push   %ebp
80105353:	89 e5                	mov    %esp,%ebp
80105355:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105358:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010535b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010535f:	8b 45 08             	mov    0x8(%ebp),%eax
80105362:	89 04 24             	mov    %eax,(%esp)
80105365:	e8 58 ff ff ff       	call   801052c2 <argint>
8010536a:	85 c0                	test   %eax,%eax
8010536c:	79 07                	jns    80105375 <argstr+0x23>
    return -1;
8010536e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105373:	eb 12                	jmp    80105387 <argstr+0x35>
  return fetchstr(addr, pp);
80105375:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105378:	8b 55 0c             	mov    0xc(%ebp),%edx
8010537b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010537f:	89 04 24             	mov    %eax,(%esp)
80105382:	e8 d9 fe ff ff       	call   80105260 <fetchstr>
}
80105387:	c9                   	leave  
80105388:	c3                   	ret    

80105389 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105389:	55                   	push   %ebp
8010538a:	89 e5                	mov    %esp,%ebp
8010538c:	53                   	push   %ebx
8010538d:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105390:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105396:	8b 40 18             	mov    0x18(%eax),%eax
80105399:	8b 40 1c             	mov    0x1c(%eax),%eax
8010539c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010539f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801053a3:	7e 30                	jle    801053d5 <syscall+0x4c>
801053a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053a8:	83 f8 15             	cmp    $0x15,%eax
801053ab:	77 28                	ja     801053d5 <syscall+0x4c>
801053ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053b0:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053b7:	85 c0                	test   %eax,%eax
801053b9:	74 1a                	je     801053d5 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801053bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c1:	8b 58 18             	mov    0x18(%eax),%ebx
801053c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c7:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053ce:	ff d0                	call   *%eax
801053d0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801053d3:	eb 3d                	jmp    80105412 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801053d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053db:	8d 48 6c             	lea    0x6c(%eax),%ecx
801053de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801053e4:	8b 40 10             	mov    0x10(%eax),%eax
801053e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
801053ee:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801053f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f6:	c7 04 24 8f 86 10 80 	movl   $0x8010868f,(%esp)
801053fd:	e8 9e af ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105402:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105408:	8b 40 18             	mov    0x18(%eax),%eax
8010540b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105412:	83 c4 24             	add    $0x24,%esp
80105415:	5b                   	pop    %ebx
80105416:	5d                   	pop    %ebp
80105417:	c3                   	ret    

80105418 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105418:	55                   	push   %ebp
80105419:	89 e5                	mov    %esp,%ebp
8010541b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010541e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105421:	89 44 24 04          	mov    %eax,0x4(%esp)
80105425:	8b 45 08             	mov    0x8(%ebp),%eax
80105428:	89 04 24             	mov    %eax,(%esp)
8010542b:	e8 92 fe ff ff       	call   801052c2 <argint>
80105430:	85 c0                	test   %eax,%eax
80105432:	79 07                	jns    8010543b <argfd+0x23>
    return -1;
80105434:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105439:	eb 50                	jmp    8010548b <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010543b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010543e:	85 c0                	test   %eax,%eax
80105440:	78 21                	js     80105463 <argfd+0x4b>
80105442:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105445:	83 f8 0f             	cmp    $0xf,%eax
80105448:	7f 19                	jg     80105463 <argfd+0x4b>
8010544a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105450:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105453:	83 c2 08             	add    $0x8,%edx
80105456:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010545a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010545d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105461:	75 07                	jne    8010546a <argfd+0x52>
    return -1;
80105463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105468:	eb 21                	jmp    8010548b <argfd+0x73>
  if(pfd)
8010546a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010546e:	74 08                	je     80105478 <argfd+0x60>
    *pfd = fd;
80105470:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105473:	8b 45 0c             	mov    0xc(%ebp),%eax
80105476:	89 10                	mov    %edx,(%eax)
  if(pf)
80105478:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010547c:	74 08                	je     80105486 <argfd+0x6e>
    *pf = f;
8010547e:	8b 45 10             	mov    0x10(%ebp),%eax
80105481:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105484:	89 10                	mov    %edx,(%eax)
  return 0;
80105486:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010548b:	c9                   	leave  
8010548c:	c3                   	ret    

8010548d <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010548d:	55                   	push   %ebp
8010548e:	89 e5                	mov    %esp,%ebp
80105490:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105493:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010549a:	eb 30                	jmp    801054cc <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
8010549c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054a2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054a5:	83 c2 08             	add    $0x8,%edx
801054a8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801054ac:	85 c0                	test   %eax,%eax
801054ae:	75 18                	jne    801054c8 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801054b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054b9:	8d 4a 08             	lea    0x8(%edx),%ecx
801054bc:	8b 55 08             	mov    0x8(%ebp),%edx
801054bf:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801054c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054c6:	eb 0f                	jmp    801054d7 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801054c8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054cc:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801054d0:	7e ca                	jle    8010549c <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801054d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801054d7:	c9                   	leave  
801054d8:	c3                   	ret    

801054d9 <sys_dup>:

int
sys_dup(void)
{
801054d9:	55                   	push   %ebp
801054da:	89 e5                	mov    %esp,%ebp
801054dc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801054df:	8d 45 f0             	lea    -0x10(%ebp),%eax
801054e2:	89 44 24 08          	mov    %eax,0x8(%esp)
801054e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054ed:	00 
801054ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801054f5:	e8 1e ff ff ff       	call   80105418 <argfd>
801054fa:	85 c0                	test   %eax,%eax
801054fc:	79 07                	jns    80105505 <sys_dup+0x2c>
    return -1;
801054fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105503:	eb 29                	jmp    8010552e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105505:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105508:	89 04 24             	mov    %eax,(%esp)
8010550b:	e8 7d ff ff ff       	call   8010548d <fdalloc>
80105510:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105513:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105517:	79 07                	jns    80105520 <sys_dup+0x47>
    return -1;
80105519:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010551e:	eb 0e                	jmp    8010552e <sys_dup+0x55>
  filedup(f);
80105520:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105523:	89 04 24             	mov    %eax,(%esp)
80105526:	e8 47 ba ff ff       	call   80100f72 <filedup>
  return fd;
8010552b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010552e:	c9                   	leave  
8010552f:	c3                   	ret    

80105530 <sys_read>:

int
sys_read(void)
{
80105530:	55                   	push   %ebp
80105531:	89 e5                	mov    %esp,%ebp
80105533:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105536:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105539:	89 44 24 08          	mov    %eax,0x8(%esp)
8010553d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105544:	00 
80105545:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010554c:	e8 c7 fe ff ff       	call   80105418 <argfd>
80105551:	85 c0                	test   %eax,%eax
80105553:	78 35                	js     8010558a <sys_read+0x5a>
80105555:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105558:	89 44 24 04          	mov    %eax,0x4(%esp)
8010555c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105563:	e8 5a fd ff ff       	call   801052c2 <argint>
80105568:	85 c0                	test   %eax,%eax
8010556a:	78 1e                	js     8010558a <sys_read+0x5a>
8010556c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010556f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105573:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105576:	89 44 24 04          	mov    %eax,0x4(%esp)
8010557a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105581:	e8 6a fd ff ff       	call   801052f0 <argptr>
80105586:	85 c0                	test   %eax,%eax
80105588:	79 07                	jns    80105591 <sys_read+0x61>
    return -1;
8010558a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010558f:	eb 19                	jmp    801055aa <sys_read+0x7a>
  return fileread(f, p, n);
80105591:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105594:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010559e:	89 54 24 04          	mov    %edx,0x4(%esp)
801055a2:	89 04 24             	mov    %eax,(%esp)
801055a5:	e8 35 bb ff ff       	call   801010df <fileread>
}
801055aa:	c9                   	leave  
801055ab:	c3                   	ret    

801055ac <sys_write>:

int
sys_write(void)
{
801055ac:	55                   	push   %ebp
801055ad:	89 e5                	mov    %esp,%ebp
801055af:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801055b2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055b5:	89 44 24 08          	mov    %eax,0x8(%esp)
801055b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801055c0:	00 
801055c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055c8:	e8 4b fe ff ff       	call   80105418 <argfd>
801055cd:	85 c0                	test   %eax,%eax
801055cf:	78 35                	js     80105606 <sys_write+0x5a>
801055d1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801055d8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801055df:	e8 de fc ff ff       	call   801052c2 <argint>
801055e4:	85 c0                	test   %eax,%eax
801055e6:	78 1e                	js     80105606 <sys_write+0x5a>
801055e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801055ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
801055f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801055f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801055fd:	e8 ee fc ff ff       	call   801052f0 <argptr>
80105602:	85 c0                	test   %eax,%eax
80105604:	79 07                	jns    8010560d <sys_write+0x61>
    return -1;
80105606:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010560b:	eb 19                	jmp    80105626 <sys_write+0x7a>
  return filewrite(f, p, n);
8010560d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105610:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105616:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010561a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010561e:	89 04 24             	mov    %eax,(%esp)
80105621:	e8 75 bb ff ff       	call   8010119b <filewrite>
}
80105626:	c9                   	leave  
80105627:	c3                   	ret    

80105628 <sys_close>:

int
sys_close(void)
{
80105628:	55                   	push   %ebp
80105629:	89 e5                	mov    %esp,%ebp
8010562b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010562e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105631:	89 44 24 08          	mov    %eax,0x8(%esp)
80105635:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105638:	89 44 24 04          	mov    %eax,0x4(%esp)
8010563c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105643:	e8 d0 fd ff ff       	call   80105418 <argfd>
80105648:	85 c0                	test   %eax,%eax
8010564a:	79 07                	jns    80105653 <sys_close+0x2b>
    return -1;
8010564c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105651:	eb 24                	jmp    80105677 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105653:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105659:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010565c:	83 c2 08             	add    $0x8,%edx
8010565f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105666:	00 
  fileclose(f);
80105667:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010566a:	89 04 24             	mov    %eax,(%esp)
8010566d:	e8 48 b9 ff ff       	call   80100fba <fileclose>
  return 0;
80105672:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105677:	c9                   	leave  
80105678:	c3                   	ret    

80105679 <sys_fstat>:

int
sys_fstat(void)
{
80105679:	55                   	push   %ebp
8010567a:	89 e5                	mov    %esp,%ebp
8010567c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010567f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105682:	89 44 24 08          	mov    %eax,0x8(%esp)
80105686:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010568d:	00 
8010568e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105695:	e8 7e fd ff ff       	call   80105418 <argfd>
8010569a:	85 c0                	test   %eax,%eax
8010569c:	78 1f                	js     801056bd <sys_fstat+0x44>
8010569e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801056a5:	00 
801056a6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801056ad:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801056b4:	e8 37 fc ff ff       	call   801052f0 <argptr>
801056b9:	85 c0                	test   %eax,%eax
801056bb:	79 07                	jns    801056c4 <sys_fstat+0x4b>
    return -1;
801056bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056c2:	eb 12                	jmp    801056d6 <sys_fstat+0x5d>
  return filestat(f, st);
801056c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801056ce:	89 04 24             	mov    %eax,(%esp)
801056d1:	e8 ba b9 ff ff       	call   80101090 <filestat>
}
801056d6:	c9                   	leave  
801056d7:	c3                   	ret    

801056d8 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801056d8:	55                   	push   %ebp
801056d9:	89 e5                	mov    %esp,%ebp
801056db:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801056de:	8d 45 d8             	lea    -0x28(%ebp),%eax
801056e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801056e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801056ec:	e8 61 fc ff ff       	call   80105352 <argstr>
801056f1:	85 c0                	test   %eax,%eax
801056f3:	78 17                	js     8010570c <sys_link+0x34>
801056f5:	8d 45 dc             	lea    -0x24(%ebp),%eax
801056f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801056fc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105703:	e8 4a fc ff ff       	call   80105352 <argstr>
80105708:	85 c0                	test   %eax,%eax
8010570a:	79 0a                	jns    80105716 <sys_link+0x3e>
    return -1;
8010570c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105711:	e9 3d 01 00 00       	jmp    80105853 <sys_link+0x17b>
  if((ip = namei(old)) == 0)
80105716:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105719:	89 04 24             	mov    %eax,(%esp)
8010571c:	e8 9b cf ff ff       	call   801026bc <namei>
80105721:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105724:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105728:	75 0a                	jne    80105734 <sys_link+0x5c>
    return -1;
8010572a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010572f:	e9 1f 01 00 00       	jmp    80105853 <sys_link+0x17b>

  begin_trans();
80105734:	e8 62 dd ff ff       	call   8010349b <begin_trans>

  ilock(ip);
80105739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010573c:	89 04 24             	mov    %eax,(%esp)
8010573f:	e8 03 c1 ff ff       	call   80101847 <ilock>
  if(ip->type == T_DIR){
80105744:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105747:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010574b:	66 83 f8 01          	cmp    $0x1,%ax
8010574f:	75 1a                	jne    8010576b <sys_link+0x93>
    iunlockput(ip);
80105751:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105754:	89 04 24             	mov    %eax,(%esp)
80105757:	e8 6f c3 ff ff       	call   80101acb <iunlockput>
    commit_trans();
8010575c:	e8 83 dd ff ff       	call   801034e4 <commit_trans>
    return -1;
80105761:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105766:	e9 e8 00 00 00       	jmp    80105853 <sys_link+0x17b>
  }

  ip->nlink++;
8010576b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010576e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105772:	8d 50 01             	lea    0x1(%eax),%edx
80105775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105778:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010577c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010577f:	89 04 24             	mov    %eax,(%esp)
80105782:	e8 04 bf ff ff       	call   8010168b <iupdate>
  iunlock(ip);
80105787:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010578a:	89 04 24             	mov    %eax,(%esp)
8010578d:	e8 03 c2 ff ff       	call   80101995 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105792:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105795:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105798:	89 54 24 04          	mov    %edx,0x4(%esp)
8010579c:	89 04 24             	mov    %eax,(%esp)
8010579f:	e8 3a cf ff ff       	call   801026de <nameiparent>
801057a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801057a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801057ab:	75 02                	jne    801057af <sys_link+0xd7>
    goto bad;
801057ad:	eb 68                	jmp    80105817 <sys_link+0x13f>
  ilock(dp);
801057af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057b2:	89 04 24             	mov    %eax,(%esp)
801057b5:	e8 8d c0 ff ff       	call   80101847 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801057ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057bd:	8b 10                	mov    (%eax),%edx
801057bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c2:	8b 00                	mov    (%eax),%eax
801057c4:	39 c2                	cmp    %eax,%edx
801057c6:	75 20                	jne    801057e8 <sys_link+0x110>
801057c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057cb:	8b 40 04             	mov    0x4(%eax),%eax
801057ce:	89 44 24 08          	mov    %eax,0x8(%esp)
801057d2:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801057d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801057d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057dc:	89 04 24             	mov    %eax,(%esp)
801057df:	e8 18 cc ff ff       	call   801023fc <dirlink>
801057e4:	85 c0                	test   %eax,%eax
801057e6:	79 0d                	jns    801057f5 <sys_link+0x11d>
    iunlockput(dp);
801057e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057eb:	89 04 24             	mov    %eax,(%esp)
801057ee:	e8 d8 c2 ff ff       	call   80101acb <iunlockput>
    goto bad;
801057f3:	eb 22                	jmp    80105817 <sys_link+0x13f>
  }
  iunlockput(dp);
801057f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057f8:	89 04 24             	mov    %eax,(%esp)
801057fb:	e8 cb c2 ff ff       	call   80101acb <iunlockput>
  iput(ip);
80105800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105803:	89 04 24             	mov    %eax,(%esp)
80105806:	e8 ef c1 ff ff       	call   801019fa <iput>

  commit_trans();
8010580b:	e8 d4 dc ff ff       	call   801034e4 <commit_trans>

  return 0;
80105810:	b8 00 00 00 00       	mov    $0x0,%eax
80105815:	eb 3c                	jmp    80105853 <sys_link+0x17b>

bad:
  ilock(ip);
80105817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010581a:	89 04 24             	mov    %eax,(%esp)
8010581d:	e8 25 c0 ff ff       	call   80101847 <ilock>
  ip->nlink--;
80105822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105825:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105829:	8d 50 ff             	lea    -0x1(%eax),%edx
8010582c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010582f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105836:	89 04 24             	mov    %eax,(%esp)
80105839:	e8 4d be ff ff       	call   8010168b <iupdate>
  iunlockput(ip);
8010583e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105841:	89 04 24             	mov    %eax,(%esp)
80105844:	e8 82 c2 ff ff       	call   80101acb <iunlockput>
  commit_trans();
80105849:	e8 96 dc ff ff       	call   801034e4 <commit_trans>
  return -1;
8010584e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105853:	c9                   	leave  
80105854:	c3                   	ret    

80105855 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105855:	55                   	push   %ebp
80105856:	89 e5                	mov    %esp,%ebp
80105858:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010585b:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105862:	eb 4b                	jmp    801058af <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105867:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010586e:	00 
8010586f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105873:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105876:	89 44 24 04          	mov    %eax,0x4(%esp)
8010587a:	8b 45 08             	mov    0x8(%ebp),%eax
8010587d:	89 04 24             	mov    %eax,(%esp)
80105880:	e8 99 c7 ff ff       	call   8010201e <readi>
80105885:	83 f8 10             	cmp    $0x10,%eax
80105888:	74 0c                	je     80105896 <isdirempty+0x41>
      panic("isdirempty: readi");
8010588a:	c7 04 24 ab 86 10 80 	movl   $0x801086ab,(%esp)
80105891:	e8 a4 ac ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105896:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010589a:	66 85 c0             	test   %ax,%ax
8010589d:	74 07                	je     801058a6 <isdirempty+0x51>
      return 0;
8010589f:	b8 00 00 00 00       	mov    $0x0,%eax
801058a4:	eb 1b                	jmp    801058c1 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801058a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a9:	83 c0 10             	add    $0x10,%eax
801058ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
801058af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801058b2:	8b 45 08             	mov    0x8(%ebp),%eax
801058b5:	8b 40 18             	mov    0x18(%eax),%eax
801058b8:	39 c2                	cmp    %eax,%edx
801058ba:	72 a8                	jb     80105864 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801058bc:	b8 01 00 00 00       	mov    $0x1,%eax
}
801058c1:	c9                   	leave  
801058c2:	c3                   	ret    

801058c3 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801058c3:	55                   	push   %ebp
801058c4:	89 e5                	mov    %esp,%ebp
801058c6:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801058c9:	8d 45 cc             	lea    -0x34(%ebp),%eax
801058cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801058d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058d7:	e8 76 fa ff ff       	call   80105352 <argstr>
801058dc:	85 c0                	test   %eax,%eax
801058de:	79 0a                	jns    801058ea <sys_unlink+0x27>
    return -1;
801058e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058e5:	e9 aa 01 00 00       	jmp    80105a94 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
801058ea:	8b 45 cc             	mov    -0x34(%ebp),%eax
801058ed:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801058f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801058f4:	89 04 24             	mov    %eax,(%esp)
801058f7:	e8 e2 cd ff ff       	call   801026de <nameiparent>
801058fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801058ff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105903:	75 0a                	jne    8010590f <sys_unlink+0x4c>
    return -1;
80105905:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010590a:	e9 85 01 00 00       	jmp    80105a94 <sys_unlink+0x1d1>

  begin_trans();
8010590f:	e8 87 db ff ff       	call   8010349b <begin_trans>

  ilock(dp);
80105914:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105917:	89 04 24             	mov    %eax,(%esp)
8010591a:	e8 28 bf ff ff       	call   80101847 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010591f:	c7 44 24 04 bd 86 10 	movl   $0x801086bd,0x4(%esp)
80105926:	80 
80105927:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010592a:	89 04 24             	mov    %eax,(%esp)
8010592d:	e8 df c9 ff ff       	call   80102311 <namecmp>
80105932:	85 c0                	test   %eax,%eax
80105934:	0f 84 45 01 00 00    	je     80105a7f <sys_unlink+0x1bc>
8010593a:	c7 44 24 04 bf 86 10 	movl   $0x801086bf,0x4(%esp)
80105941:	80 
80105942:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105945:	89 04 24             	mov    %eax,(%esp)
80105948:	e8 c4 c9 ff ff       	call   80102311 <namecmp>
8010594d:	85 c0                	test   %eax,%eax
8010594f:	0f 84 2a 01 00 00    	je     80105a7f <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105955:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105958:	89 44 24 08          	mov    %eax,0x8(%esp)
8010595c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010595f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105963:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105966:	89 04 24             	mov    %eax,(%esp)
80105969:	e8 c5 c9 ff ff       	call   80102333 <dirlookup>
8010596e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105971:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105975:	75 05                	jne    8010597c <sys_unlink+0xb9>
    goto bad;
80105977:	e9 03 01 00 00       	jmp    80105a7f <sys_unlink+0x1bc>
  ilock(ip);
8010597c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010597f:	89 04 24             	mov    %eax,(%esp)
80105982:	e8 c0 be ff ff       	call   80101847 <ilock>

  if(ip->nlink < 1)
80105987:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010598a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010598e:	66 85 c0             	test   %ax,%ax
80105991:	7f 0c                	jg     8010599f <sys_unlink+0xdc>
    panic("unlink: nlink < 1");
80105993:	c7 04 24 c2 86 10 80 	movl   $0x801086c2,(%esp)
8010599a:	e8 9b ab ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010599f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059a2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059a6:	66 83 f8 01          	cmp    $0x1,%ax
801059aa:	75 1f                	jne    801059cb <sys_unlink+0x108>
801059ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059af:	89 04 24             	mov    %eax,(%esp)
801059b2:	e8 9e fe ff ff       	call   80105855 <isdirempty>
801059b7:	85 c0                	test   %eax,%eax
801059b9:	75 10                	jne    801059cb <sys_unlink+0x108>
    iunlockput(ip);
801059bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059be:	89 04 24             	mov    %eax,(%esp)
801059c1:	e8 05 c1 ff ff       	call   80101acb <iunlockput>
    goto bad;
801059c6:	e9 b4 00 00 00       	jmp    80105a7f <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
801059cb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801059d2:	00 
801059d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801059da:	00 
801059db:	8d 45 e0             	lea    -0x20(%ebp),%eax
801059de:	89 04 24             	mov    %eax,(%esp)
801059e1:	e8 9a f5 ff ff       	call   80104f80 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801059e6:	8b 45 c8             	mov    -0x38(%ebp),%eax
801059e9:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801059f0:	00 
801059f1:	89 44 24 08          	mov    %eax,0x8(%esp)
801059f5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801059f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801059fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ff:	89 04 24             	mov    %eax,(%esp)
80105a02:	e8 7b c7 ff ff       	call   80102182 <writei>
80105a07:	83 f8 10             	cmp    $0x10,%eax
80105a0a:	74 0c                	je     80105a18 <sys_unlink+0x155>
    panic("unlink: writei");
80105a0c:	c7 04 24 d4 86 10 80 	movl   $0x801086d4,(%esp)
80105a13:	e8 22 ab ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105a18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a1b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105a1f:	66 83 f8 01          	cmp    $0x1,%ax
80105a23:	75 1c                	jne    80105a41 <sys_unlink+0x17e>
    dp->nlink--;
80105a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a28:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a32:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a39:	89 04 24             	mov    %eax,(%esp)
80105a3c:	e8 4a bc ff ff       	call   8010168b <iupdate>
  }
  iunlockput(dp);
80105a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a44:	89 04 24             	mov    %eax,(%esp)
80105a47:	e8 7f c0 ff ff       	call   80101acb <iunlockput>

  ip->nlink--;
80105a4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a4f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a53:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a59:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a60:	89 04 24             	mov    %eax,(%esp)
80105a63:	e8 23 bc ff ff       	call   8010168b <iupdate>
  iunlockput(ip);
80105a68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a6b:	89 04 24             	mov    %eax,(%esp)
80105a6e:	e8 58 c0 ff ff       	call   80101acb <iunlockput>

  commit_trans();
80105a73:	e8 6c da ff ff       	call   801034e4 <commit_trans>

  return 0;
80105a78:	b8 00 00 00 00       	mov    $0x0,%eax
80105a7d:	eb 15                	jmp    80105a94 <sys_unlink+0x1d1>

bad:
  iunlockput(dp);
80105a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a82:	89 04 24             	mov    %eax,(%esp)
80105a85:	e8 41 c0 ff ff       	call   80101acb <iunlockput>
  commit_trans();
80105a8a:	e8 55 da ff ff       	call   801034e4 <commit_trans>
  return -1;
80105a8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a94:	c9                   	leave  
80105a95:	c3                   	ret    

80105a96 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105a96:	55                   	push   %ebp
80105a97:	89 e5                	mov    %esp,%ebp
80105a99:	83 ec 48             	sub    $0x48,%esp
80105a9c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105a9f:	8b 55 10             	mov    0x10(%ebp),%edx
80105aa2:	8b 45 14             	mov    0x14(%ebp),%eax
80105aa5:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105aa9:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105aad:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105ab1:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ab8:	8b 45 08             	mov    0x8(%ebp),%eax
80105abb:	89 04 24             	mov    %eax,(%esp)
80105abe:	e8 1b cc ff ff       	call   801026de <nameiparent>
80105ac3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ac6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105aca:	75 0a                	jne    80105ad6 <create+0x40>
    return 0;
80105acc:	b8 00 00 00 00       	mov    $0x0,%eax
80105ad1:	e9 7e 01 00 00       	jmp    80105c54 <create+0x1be>
  ilock(dp);
80105ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad9:	89 04 24             	mov    %eax,(%esp)
80105adc:	e8 66 bd ff ff       	call   80101847 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105ae1:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ae4:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ae8:	8d 45 de             	lea    -0x22(%ebp),%eax
80105aeb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af2:	89 04 24             	mov    %eax,(%esp)
80105af5:	e8 39 c8 ff ff       	call   80102333 <dirlookup>
80105afa:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105afd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b01:	74 47                	je     80105b4a <create+0xb4>
    iunlockput(dp);
80105b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b06:	89 04 24             	mov    %eax,(%esp)
80105b09:	e8 bd bf ff ff       	call   80101acb <iunlockput>
    ilock(ip);
80105b0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b11:	89 04 24             	mov    %eax,(%esp)
80105b14:	e8 2e bd ff ff       	call   80101847 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105b19:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105b1e:	75 15                	jne    80105b35 <create+0x9f>
80105b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b23:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b27:	66 83 f8 02          	cmp    $0x2,%ax
80105b2b:	75 08                	jne    80105b35 <create+0x9f>
      return ip;
80105b2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b30:	e9 1f 01 00 00       	jmp    80105c54 <create+0x1be>
    iunlockput(ip);
80105b35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b38:	89 04 24             	mov    %eax,(%esp)
80105b3b:	e8 8b bf ff ff       	call   80101acb <iunlockput>
    return 0;
80105b40:	b8 00 00 00 00       	mov    $0x0,%eax
80105b45:	e9 0a 01 00 00       	jmp    80105c54 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105b4a:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b51:	8b 00                	mov    (%eax),%eax
80105b53:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b57:	89 04 24             	mov    %eax,(%esp)
80105b5a:	e8 4d ba ff ff       	call   801015ac <ialloc>
80105b5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b62:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b66:	75 0c                	jne    80105b74 <create+0xde>
    panic("create: ialloc");
80105b68:	c7 04 24 e3 86 10 80 	movl   $0x801086e3,(%esp)
80105b6f:	e8 c6 a9 ff ff       	call   8010053a <panic>

  ilock(ip);
80105b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b77:	89 04 24             	mov    %eax,(%esp)
80105b7a:	e8 c8 bc ff ff       	call   80101847 <ilock>
  ip->major = major;
80105b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b82:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105b86:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105b8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b8d:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105b91:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b98:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105b9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba1:	89 04 24             	mov    %eax,(%esp)
80105ba4:	e8 e2 ba ff ff       	call   8010168b <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105ba9:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105bae:	75 6a                	jne    80105c1a <create+0x184>
    dp->nlink++;  // for ".."
80105bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105bb7:	8d 50 01             	lea    0x1(%eax),%edx
80105bba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bbd:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc4:	89 04 24             	mov    %eax,(%esp)
80105bc7:	e8 bf ba ff ff       	call   8010168b <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bcf:	8b 40 04             	mov    0x4(%eax),%eax
80105bd2:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bd6:	c7 44 24 04 bd 86 10 	movl   $0x801086bd,0x4(%esp)
80105bdd:	80 
80105bde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105be1:	89 04 24             	mov    %eax,(%esp)
80105be4:	e8 13 c8 ff ff       	call   801023fc <dirlink>
80105be9:	85 c0                	test   %eax,%eax
80105beb:	78 21                	js     80105c0e <create+0x178>
80105bed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bf0:	8b 40 04             	mov    0x4(%eax),%eax
80105bf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bf7:	c7 44 24 04 bf 86 10 	movl   $0x801086bf,0x4(%esp)
80105bfe:	80 
80105bff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c02:	89 04 24             	mov    %eax,(%esp)
80105c05:	e8 f2 c7 ff ff       	call   801023fc <dirlink>
80105c0a:	85 c0                	test   %eax,%eax
80105c0c:	79 0c                	jns    80105c1a <create+0x184>
      panic("create dots");
80105c0e:	c7 04 24 f2 86 10 80 	movl   $0x801086f2,(%esp)
80105c15:	e8 20 a9 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105c1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c1d:	8b 40 04             	mov    0x4(%eax),%eax
80105c20:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c24:	8d 45 de             	lea    -0x22(%ebp),%eax
80105c27:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2e:	89 04 24             	mov    %eax,(%esp)
80105c31:	e8 c6 c7 ff ff       	call   801023fc <dirlink>
80105c36:	85 c0                	test   %eax,%eax
80105c38:	79 0c                	jns    80105c46 <create+0x1b0>
    panic("create: dirlink");
80105c3a:	c7 04 24 fe 86 10 80 	movl   $0x801086fe,(%esp)
80105c41:	e8 f4 a8 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80105c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c49:	89 04 24             	mov    %eax,(%esp)
80105c4c:	e8 7a be ff ff       	call   80101acb <iunlockput>

  return ip;
80105c51:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105c54:	c9                   	leave  
80105c55:	c3                   	ret    

80105c56 <sys_open>:

int
sys_open(void)
{
80105c56:	55                   	push   %ebp
80105c57:	89 e5                	mov    %esp,%ebp
80105c59:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105c5c:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105c5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c63:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c6a:	e8 e3 f6 ff ff       	call   80105352 <argstr>
80105c6f:	85 c0                	test   %eax,%eax
80105c71:	78 17                	js     80105c8a <sys_open+0x34>
80105c73:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c76:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c7a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c81:	e8 3c f6 ff ff       	call   801052c2 <argint>
80105c86:	85 c0                	test   %eax,%eax
80105c88:	79 0a                	jns    80105c94 <sys_open+0x3e>
    return -1;
80105c8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c8f:	e9 48 01 00 00       	jmp    80105ddc <sys_open+0x186>
  if(omode & O_CREATE){
80105c94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c97:	25 00 02 00 00       	and    $0x200,%eax
80105c9c:	85 c0                	test   %eax,%eax
80105c9e:	74 40                	je     80105ce0 <sys_open+0x8a>
    begin_trans();
80105ca0:	e8 f6 d7 ff ff       	call   8010349b <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105ca5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ca8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105caf:	00 
80105cb0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105cb7:	00 
80105cb8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105cbf:	00 
80105cc0:	89 04 24             	mov    %eax,(%esp)
80105cc3:	e8 ce fd ff ff       	call   80105a96 <create>
80105cc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105ccb:	e8 14 d8 ff ff       	call   801034e4 <commit_trans>
    if(ip == 0)
80105cd0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cd4:	75 5c                	jne    80105d32 <sys_open+0xdc>
      return -1;
80105cd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cdb:	e9 fc 00 00 00       	jmp    80105ddc <sys_open+0x186>
  } else {
    if((ip = namei(path)) == 0)
80105ce0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ce3:	89 04 24             	mov    %eax,(%esp)
80105ce6:	e8 d1 c9 ff ff       	call   801026bc <namei>
80105ceb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cee:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cf2:	75 0a                	jne    80105cfe <sys_open+0xa8>
      return -1;
80105cf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cf9:	e9 de 00 00 00       	jmp    80105ddc <sys_open+0x186>
    ilock(ip);
80105cfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d01:	89 04 24             	mov    %eax,(%esp)
80105d04:	e8 3e bb ff ff       	call   80101847 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105d09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d0c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d10:	66 83 f8 01          	cmp    $0x1,%ax
80105d14:	75 1c                	jne    80105d32 <sys_open+0xdc>
80105d16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d19:	85 c0                	test   %eax,%eax
80105d1b:	74 15                	je     80105d32 <sys_open+0xdc>
      iunlockput(ip);
80105d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d20:	89 04 24             	mov    %eax,(%esp)
80105d23:	e8 a3 bd ff ff       	call   80101acb <iunlockput>
      return -1;
80105d28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d2d:	e9 aa 00 00 00       	jmp    80105ddc <sys_open+0x186>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105d32:	e8 db b1 ff ff       	call   80100f12 <filealloc>
80105d37:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d3a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d3e:	74 14                	je     80105d54 <sys_open+0xfe>
80105d40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d43:	89 04 24             	mov    %eax,(%esp)
80105d46:	e8 42 f7 ff ff       	call   8010548d <fdalloc>
80105d4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105d4e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105d52:	79 23                	jns    80105d77 <sys_open+0x121>
    if(f)
80105d54:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d58:	74 0b                	je     80105d65 <sys_open+0x10f>
      fileclose(f);
80105d5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d5d:	89 04 24             	mov    %eax,(%esp)
80105d60:	e8 55 b2 ff ff       	call   80100fba <fileclose>
    iunlockput(ip);
80105d65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d68:	89 04 24             	mov    %eax,(%esp)
80105d6b:	e8 5b bd ff ff       	call   80101acb <iunlockput>
    return -1;
80105d70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d75:	eb 65                	jmp    80105ddc <sys_open+0x186>
  }
  iunlock(ip);
80105d77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d7a:	89 04 24             	mov    %eax,(%esp)
80105d7d:	e8 13 bc ff ff       	call   80101995 <iunlock>

  f->type = FD_INODE;
80105d82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d85:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d91:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105d94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d97:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105d9e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105da1:	83 e0 01             	and    $0x1,%eax
80105da4:	85 c0                	test   %eax,%eax
80105da6:	0f 94 c0             	sete   %al
80105da9:	89 c2                	mov    %eax,%edx
80105dab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dae:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105db1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105db4:	83 e0 01             	and    $0x1,%eax
80105db7:	85 c0                	test   %eax,%eax
80105db9:	75 0a                	jne    80105dc5 <sys_open+0x16f>
80105dbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dbe:	83 e0 02             	and    $0x2,%eax
80105dc1:	85 c0                	test   %eax,%eax
80105dc3:	74 07                	je     80105dcc <sys_open+0x176>
80105dc5:	b8 01 00 00 00       	mov    $0x1,%eax
80105dca:	eb 05                	jmp    80105dd1 <sys_open+0x17b>
80105dcc:	b8 00 00 00 00       	mov    $0x0,%eax
80105dd1:	89 c2                	mov    %eax,%edx
80105dd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd6:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105dd9:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105ddc:	c9                   	leave  
80105ddd:	c3                   	ret    

80105dde <sys_mkdir>:

int
sys_mkdir(void)
{
80105dde:	55                   	push   %ebp
80105ddf:	89 e5                	mov    %esp,%ebp
80105de1:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105de4:	e8 b2 d6 ff ff       	call   8010349b <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105de9:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105dec:	89 44 24 04          	mov    %eax,0x4(%esp)
80105df0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105df7:	e8 56 f5 ff ff       	call   80105352 <argstr>
80105dfc:	85 c0                	test   %eax,%eax
80105dfe:	78 2c                	js     80105e2c <sys_mkdir+0x4e>
80105e00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e03:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105e0a:	00 
80105e0b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105e12:	00 
80105e13:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105e1a:	00 
80105e1b:	89 04 24             	mov    %eax,(%esp)
80105e1e:	e8 73 fc ff ff       	call   80105a96 <create>
80105e23:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e2a:	75 0c                	jne    80105e38 <sys_mkdir+0x5a>
    commit_trans();
80105e2c:	e8 b3 d6 ff ff       	call   801034e4 <commit_trans>
    return -1;
80105e31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e36:	eb 15                	jmp    80105e4d <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e3b:	89 04 24             	mov    %eax,(%esp)
80105e3e:	e8 88 bc ff ff       	call   80101acb <iunlockput>
  commit_trans();
80105e43:	e8 9c d6 ff ff       	call   801034e4 <commit_trans>
  return 0;
80105e48:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e4d:	c9                   	leave  
80105e4e:	c3                   	ret    

80105e4f <sys_mknod>:

int
sys_mknod(void)
{
80105e4f:	55                   	push   %ebp
80105e50:	89 e5                	mov    %esp,%ebp
80105e52:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105e55:	e8 41 d6 ff ff       	call   8010349b <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105e5a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e68:	e8 e5 f4 ff ff       	call   80105352 <argstr>
80105e6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e70:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e74:	78 5e                	js     80105ed4 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105e76:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105e79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e7d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e84:	e8 39 f4 ff ff       	call   801052c2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105e89:	85 c0                	test   %eax,%eax
80105e8b:	78 47                	js     80105ed4 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e8d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e90:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e94:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e9b:	e8 22 f4 ff ff       	call   801052c2 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105ea0:	85 c0                	test   %eax,%eax
80105ea2:	78 30                	js     80105ed4 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105ea4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ea7:	0f bf c8             	movswl %ax,%ecx
80105eaa:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ead:	0f bf d0             	movswl %ax,%edx
80105eb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105eb3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105eb7:	89 54 24 08          	mov    %edx,0x8(%esp)
80105ebb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105ec2:	00 
80105ec3:	89 04 24             	mov    %eax,(%esp)
80105ec6:	e8 cb fb ff ff       	call   80105a96 <create>
80105ecb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ece:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ed2:	75 0c                	jne    80105ee0 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105ed4:	e8 0b d6 ff ff       	call   801034e4 <commit_trans>
    return -1;
80105ed9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ede:	eb 15                	jmp    80105ef5 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105ee0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ee3:	89 04 24             	mov    %eax,(%esp)
80105ee6:	e8 e0 bb ff ff       	call   80101acb <iunlockput>
  commit_trans();
80105eeb:	e8 f4 d5 ff ff       	call   801034e4 <commit_trans>
  return 0;
80105ef0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ef5:	c9                   	leave  
80105ef6:	c3                   	ret    

80105ef7 <sys_chdir>:

int
sys_chdir(void)
{
80105ef7:	55                   	push   %ebp
80105ef8:	89 e5                	mov    %esp,%ebp
80105efa:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105efd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f00:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f04:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f0b:	e8 42 f4 ff ff       	call   80105352 <argstr>
80105f10:	85 c0                	test   %eax,%eax
80105f12:	78 14                	js     80105f28 <sys_chdir+0x31>
80105f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f17:	89 04 24             	mov    %eax,(%esp)
80105f1a:	e8 9d c7 ff ff       	call   801026bc <namei>
80105f1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f22:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f26:	75 07                	jne    80105f2f <sys_chdir+0x38>
    return -1;
80105f28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f2d:	eb 57                	jmp    80105f86 <sys_chdir+0x8f>
  ilock(ip);
80105f2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f32:	89 04 24             	mov    %eax,(%esp)
80105f35:	e8 0d b9 ff ff       	call   80101847 <ilock>
  if(ip->type != T_DIR){
80105f3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f3d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f41:	66 83 f8 01          	cmp    $0x1,%ax
80105f45:	74 12                	je     80105f59 <sys_chdir+0x62>
    iunlockput(ip);
80105f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f4a:	89 04 24             	mov    %eax,(%esp)
80105f4d:	e8 79 bb ff ff       	call   80101acb <iunlockput>
    return -1;
80105f52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f57:	eb 2d                	jmp    80105f86 <sys_chdir+0x8f>
  }
  iunlock(ip);
80105f59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f5c:	89 04 24             	mov    %eax,(%esp)
80105f5f:	e8 31 ba ff ff       	call   80101995 <iunlock>
  iput(proc->cwd);
80105f64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f6a:	8b 40 68             	mov    0x68(%eax),%eax
80105f6d:	89 04 24             	mov    %eax,(%esp)
80105f70:	e8 85 ba ff ff       	call   801019fa <iput>
  proc->cwd = ip;
80105f75:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f7e:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105f81:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f86:	c9                   	leave  
80105f87:	c3                   	ret    

80105f88 <sys_exec>:

int
sys_exec(void)
{
80105f88:	55                   	push   %ebp
80105f89:	89 e5                	mov    %esp,%ebp
80105f8b:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105f91:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f94:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f98:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f9f:	e8 ae f3 ff ff       	call   80105352 <argstr>
80105fa4:	85 c0                	test   %eax,%eax
80105fa6:	78 1a                	js     80105fc2 <sys_exec+0x3a>
80105fa8:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105fae:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fb2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105fb9:	e8 04 f3 ff ff       	call   801052c2 <argint>
80105fbe:	85 c0                	test   %eax,%eax
80105fc0:	79 0a                	jns    80105fcc <sys_exec+0x44>
    return -1;
80105fc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fc7:	e9 c8 00 00 00       	jmp    80106094 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80105fcc:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105fd3:	00 
80105fd4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fdb:	00 
80105fdc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105fe2:	89 04 24             	mov    %eax,(%esp)
80105fe5:	e8 96 ef ff ff       	call   80104f80 <memset>
  for(i=0;; i++){
80105fea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105ff1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ff4:	83 f8 1f             	cmp    $0x1f,%eax
80105ff7:	76 0a                	jbe    80106003 <sys_exec+0x7b>
      return -1;
80105ff9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ffe:	e9 91 00 00 00       	jmp    80106094 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106003:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106006:	c1 e0 02             	shl    $0x2,%eax
80106009:	89 c2                	mov    %eax,%edx
8010600b:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106011:	01 c2                	add    %eax,%edx
80106013:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106019:	89 44 24 04          	mov    %eax,0x4(%esp)
8010601d:	89 14 24             	mov    %edx,(%esp)
80106020:	e8 01 f2 ff ff       	call   80105226 <fetchint>
80106025:	85 c0                	test   %eax,%eax
80106027:	79 07                	jns    80106030 <sys_exec+0xa8>
      return -1;
80106029:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010602e:	eb 64                	jmp    80106094 <sys_exec+0x10c>
    if(uarg == 0){
80106030:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106036:	85 c0                	test   %eax,%eax
80106038:	75 26                	jne    80106060 <sys_exec+0xd8>
      argv[i] = 0;
8010603a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010603d:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106044:	00 00 00 00 
      break;
80106048:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106049:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010604c:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106052:	89 54 24 04          	mov    %edx,0x4(%esp)
80106056:	89 04 24             	mov    %eax,(%esp)
80106059:	e8 91 aa ff ff       	call   80100aef <exec>
8010605e:	eb 34                	jmp    80106094 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106060:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106066:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106069:	c1 e2 02             	shl    $0x2,%edx
8010606c:	01 c2                	add    %eax,%edx
8010606e:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106074:	89 54 24 04          	mov    %edx,0x4(%esp)
80106078:	89 04 24             	mov    %eax,(%esp)
8010607b:	e8 e0 f1 ff ff       	call   80105260 <fetchstr>
80106080:	85 c0                	test   %eax,%eax
80106082:	79 07                	jns    8010608b <sys_exec+0x103>
      return -1;
80106084:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106089:	eb 09                	jmp    80106094 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010608b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
8010608f:	e9 5d ff ff ff       	jmp    80105ff1 <sys_exec+0x69>
  return exec(path, argv);
}
80106094:	c9                   	leave  
80106095:	c3                   	ret    

80106096 <sys_pipe>:

int
sys_pipe(void)
{
80106096:	55                   	push   %ebp
80106097:	89 e5                	mov    %esp,%ebp
80106099:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010609c:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801060a3:	00 
801060a4:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060b2:	e8 39 f2 ff ff       	call   801052f0 <argptr>
801060b7:	85 c0                	test   %eax,%eax
801060b9:	79 0a                	jns    801060c5 <sys_pipe+0x2f>
    return -1;
801060bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060c0:	e9 9b 00 00 00       	jmp    80106160 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801060c5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801060cc:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060cf:	89 04 24             	mov    %eax,(%esp)
801060d2:	e8 ae dd ff ff       	call   80103e85 <pipealloc>
801060d7:	85 c0                	test   %eax,%eax
801060d9:	79 07                	jns    801060e2 <sys_pipe+0x4c>
    return -1;
801060db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060e0:	eb 7e                	jmp    80106160 <sys_pipe+0xca>
  fd0 = -1;
801060e2:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801060e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060ec:	89 04 24             	mov    %eax,(%esp)
801060ef:	e8 99 f3 ff ff       	call   8010548d <fdalloc>
801060f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060f7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060fb:	78 14                	js     80106111 <sys_pipe+0x7b>
801060fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106100:	89 04 24             	mov    %eax,(%esp)
80106103:	e8 85 f3 ff ff       	call   8010548d <fdalloc>
80106108:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010610b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010610f:	79 37                	jns    80106148 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106111:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106115:	78 14                	js     8010612b <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106117:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010611d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106120:	83 c2 08             	add    $0x8,%edx
80106123:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010612a:	00 
    fileclose(rf);
8010612b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010612e:	89 04 24             	mov    %eax,(%esp)
80106131:	e8 84 ae ff ff       	call   80100fba <fileclose>
    fileclose(wf);
80106136:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106139:	89 04 24             	mov    %eax,(%esp)
8010613c:	e8 79 ae ff ff       	call   80100fba <fileclose>
    return -1;
80106141:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106146:	eb 18                	jmp    80106160 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106148:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010614b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010614e:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106150:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106153:	8d 50 04             	lea    0x4(%eax),%edx
80106156:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106159:	89 02                	mov    %eax,(%edx)
  return 0;
8010615b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106160:	c9                   	leave  
80106161:	c3                   	ret    

80106162 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106162:	55                   	push   %ebp
80106163:	89 e5                	mov    %esp,%ebp
80106165:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106168:	e8 c3 e3 ff ff       	call   80104530 <fork>
}
8010616d:	c9                   	leave  
8010616e:	c3                   	ret    

8010616f <sys_exit>:

int
sys_exit(void)
{
8010616f:	55                   	push   %ebp
80106170:	89 e5                	mov    %esp,%ebp
80106172:	83 ec 08             	sub    $0x8,%esp
  exit();
80106175:	e8 19 e5 ff ff       	call   80104693 <exit>
  return 0;  // not reached
8010617a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010617f:	c9                   	leave  
80106180:	c3                   	ret    

80106181 <sys_wait>:

int
sys_wait(void)
{
80106181:	55                   	push   %ebp
80106182:	89 e5                	mov    %esp,%ebp
80106184:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106187:	e8 1f e6 ff ff       	call   801047ab <wait>
}
8010618c:	c9                   	leave  
8010618d:	c3                   	ret    

8010618e <sys_kill>:

int
sys_kill(void)
{
8010618e:	55                   	push   %ebp
8010618f:	89 e5                	mov    %esp,%ebp
80106191:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106194:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106197:	89 44 24 04          	mov    %eax,0x4(%esp)
8010619b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061a2:	e8 1b f1 ff ff       	call   801052c2 <argint>
801061a7:	85 c0                	test   %eax,%eax
801061a9:	79 07                	jns    801061b2 <sys_kill+0x24>
    return -1;
801061ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061b0:	eb 0b                	jmp    801061bd <sys_kill+0x2f>
  return kill(pid);
801061b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b5:	89 04 24             	mov    %eax,(%esp)
801061b8:	e8 a9 e9 ff ff       	call   80104b66 <kill>
}
801061bd:	c9                   	leave  
801061be:	c3                   	ret    

801061bf <sys_getpid>:

int
sys_getpid(void)
{
801061bf:	55                   	push   %ebp
801061c0:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801061c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061c8:	8b 40 10             	mov    0x10(%eax),%eax
}
801061cb:	5d                   	pop    %ebp
801061cc:	c3                   	ret    

801061cd <sys_sbrk>:

int
sys_sbrk(void)
{
801061cd:	55                   	push   %ebp
801061ce:	89 e5                	mov    %esp,%ebp
801061d0:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801061d3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801061da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061e1:	e8 dc f0 ff ff       	call   801052c2 <argint>
801061e6:	85 c0                	test   %eax,%eax
801061e8:	79 07                	jns    801061f1 <sys_sbrk+0x24>
    return -1;
801061ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ef:	eb 24                	jmp    80106215 <sys_sbrk+0x48>
  addr = proc->sz;
801061f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061f7:	8b 00                	mov    (%eax),%eax
801061f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801061fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061ff:	89 04 24             	mov    %eax,(%esp)
80106202:	e8 84 e2 ff ff       	call   8010448b <growproc>
80106207:	85 c0                	test   %eax,%eax
80106209:	79 07                	jns    80106212 <sys_sbrk+0x45>
    return -1;
8010620b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106210:	eb 03                	jmp    80106215 <sys_sbrk+0x48>
  return addr;
80106212:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106215:	c9                   	leave  
80106216:	c3                   	ret    

80106217 <sys_sleep>:

int
sys_sleep(void)
{
80106217:	55                   	push   %ebp
80106218:	89 e5                	mov    %esp,%ebp
8010621a:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010621d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106220:	89 44 24 04          	mov    %eax,0x4(%esp)
80106224:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010622b:	e8 92 f0 ff ff       	call   801052c2 <argint>
80106230:	85 c0                	test   %eax,%eax
80106232:	79 07                	jns    8010623b <sys_sleep+0x24>
    return -1;
80106234:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106239:	eb 6c                	jmp    801062a7 <sys_sleep+0x90>
  acquire(&tickslock);
8010623b:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106242:	e8 e5 ea ff ff       	call   80104d2c <acquire>
  ticks0 = ticks;
80106247:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010624c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010624f:	eb 34                	jmp    80106285 <sys_sleep+0x6e>
    if(proc->killed){
80106251:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106257:	8b 40 24             	mov    0x24(%eax),%eax
8010625a:	85 c0                	test   %eax,%eax
8010625c:	74 13                	je     80106271 <sys_sleep+0x5a>
      release(&tickslock);
8010625e:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106265:	e8 24 eb ff ff       	call   80104d8e <release>
      return -1;
8010626a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010626f:	eb 36                	jmp    801062a7 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106271:	c7 44 24 04 60 1e 11 	movl   $0x80111e60,0x4(%esp)
80106278:	80 
80106279:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
80106280:	e8 dd e7 ff ff       	call   80104a62 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106285:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010628a:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010628d:	89 c2                	mov    %eax,%edx
8010628f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106292:	39 c2                	cmp    %eax,%edx
80106294:	72 bb                	jb     80106251 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106296:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
8010629d:	e8 ec ea ff ff       	call   80104d8e <release>
  return 0;
801062a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062a7:	c9                   	leave  
801062a8:	c3                   	ret    

801062a9 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801062a9:	55                   	push   %ebp
801062aa:	89 e5                	mov    %esp,%ebp
801062ac:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801062af:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801062b6:	e8 71 ea ff ff       	call   80104d2c <acquire>
  xticks = ticks;
801062bb:	a1 a0 26 11 80       	mov    0x801126a0,%eax
801062c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801062c3:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801062ca:	e8 bf ea ff ff       	call   80104d8e <release>
  return xticks;
801062cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801062d2:	c9                   	leave  
801062d3:	c3                   	ret    

801062d4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801062d4:	55                   	push   %ebp
801062d5:	89 e5                	mov    %esp,%ebp
801062d7:	83 ec 08             	sub    $0x8,%esp
801062da:	8b 55 08             	mov    0x8(%ebp),%edx
801062dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801062e0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801062e4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801062e7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801062eb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801062ef:	ee                   	out    %al,(%dx)
}
801062f0:	c9                   	leave  
801062f1:	c3                   	ret    

801062f2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801062f2:	55                   	push   %ebp
801062f3:	89 e5                	mov    %esp,%ebp
801062f5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801062f8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801062ff:	00 
80106300:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106307:	e8 c8 ff ff ff       	call   801062d4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010630c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106313:	00 
80106314:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010631b:	e8 b4 ff ff ff       	call   801062d4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106320:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106327:	00 
80106328:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010632f:	e8 a0 ff ff ff       	call   801062d4 <outb>
  picenable(IRQ_TIMER);
80106334:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010633b:	e8 d8 d9 ff ff       	call   80103d18 <picenable>
}
80106340:	c9                   	leave  
80106341:	c3                   	ret    

80106342 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106342:	1e                   	push   %ds
  pushl %es
80106343:	06                   	push   %es
  pushl %fs
80106344:	0f a0                	push   %fs
  pushl %gs
80106346:	0f a8                	push   %gs
  pushal
80106348:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106349:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010634d:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010634f:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106351:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106355:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106357:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106359:	54                   	push   %esp
  call trap
8010635a:	e8 d8 01 00 00       	call   80106537 <trap>
  addl $4, %esp
8010635f:	83 c4 04             	add    $0x4,%esp

80106362 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106362:	61                   	popa   
  popl %gs
80106363:	0f a9                	pop    %gs
  popl %fs
80106365:	0f a1                	pop    %fs
  popl %es
80106367:	07                   	pop    %es
  popl %ds
80106368:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106369:	83 c4 08             	add    $0x8,%esp
  iret
8010636c:	cf                   	iret   

8010636d <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010636d:	55                   	push   %ebp
8010636e:	89 e5                	mov    %esp,%ebp
80106370:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106373:	8b 45 0c             	mov    0xc(%ebp),%eax
80106376:	83 e8 01             	sub    $0x1,%eax
80106379:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010637d:	8b 45 08             	mov    0x8(%ebp),%eax
80106380:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106384:	8b 45 08             	mov    0x8(%ebp),%eax
80106387:	c1 e8 10             	shr    $0x10,%eax
8010638a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010638e:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106391:	0f 01 18             	lidtl  (%eax)
}
80106394:	c9                   	leave  
80106395:	c3                   	ret    

80106396 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106396:	55                   	push   %ebp
80106397:	89 e5                	mov    %esp,%ebp
80106399:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010639c:	0f 20 d0             	mov    %cr2,%eax
8010639f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801063a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801063a5:	c9                   	leave  
801063a6:	c3                   	ret    

801063a7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801063a7:	55                   	push   %ebp
801063a8:	89 e5                	mov    %esp,%ebp
801063aa:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801063ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801063b4:	e9 c3 00 00 00       	jmp    8010647c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801063b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063bc:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801063c3:	89 c2                	mov    %eax,%edx
801063c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c8:	66 89 14 c5 a0 1e 11 	mov    %dx,-0x7feee160(,%eax,8)
801063cf:	80 
801063d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d3:	66 c7 04 c5 a2 1e 11 	movw   $0x8,-0x7feee15e(,%eax,8)
801063da:	80 08 00 
801063dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e0:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
801063e7:	80 
801063e8:	83 e2 e0             	and    $0xffffffe0,%edx
801063eb:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
801063f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f5:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
801063fc:	80 
801063fd:	83 e2 1f             	and    $0x1f,%edx
80106400:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
80106407:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010640a:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
80106411:	80 
80106412:	83 e2 f0             	and    $0xfffffff0,%edx
80106415:	83 ca 0e             	or     $0xe,%edx
80106418:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
8010641f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106422:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
80106429:	80 
8010642a:	83 e2 ef             	and    $0xffffffef,%edx
8010642d:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
80106434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106437:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
8010643e:	80 
8010643f:	83 e2 9f             	and    $0xffffff9f,%edx
80106442:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
80106449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644c:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
80106453:	80 
80106454:	83 ca 80             	or     $0xffffff80,%edx
80106457:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
8010645e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106461:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106468:	c1 e8 10             	shr    $0x10,%eax
8010646b:	89 c2                	mov    %eax,%edx
8010646d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106470:	66 89 14 c5 a6 1e 11 	mov    %dx,-0x7feee15a(,%eax,8)
80106477:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106478:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010647c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106483:	0f 8e 30 ff ff ff    	jle    801063b9 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106489:	a1 98 b1 10 80       	mov    0x8010b198,%eax
8010648e:	66 a3 a0 20 11 80    	mov    %ax,0x801120a0
80106494:	66 c7 05 a2 20 11 80 	movw   $0x8,0x801120a2
8010649b:	08 00 
8010649d:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
801064a4:	83 e0 e0             	and    $0xffffffe0,%eax
801064a7:	a2 a4 20 11 80       	mov    %al,0x801120a4
801064ac:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
801064b3:	83 e0 1f             	and    $0x1f,%eax
801064b6:	a2 a4 20 11 80       	mov    %al,0x801120a4
801064bb:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
801064c2:	83 c8 0f             	or     $0xf,%eax
801064c5:	a2 a5 20 11 80       	mov    %al,0x801120a5
801064ca:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
801064d1:	83 e0 ef             	and    $0xffffffef,%eax
801064d4:	a2 a5 20 11 80       	mov    %al,0x801120a5
801064d9:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
801064e0:	83 c8 60             	or     $0x60,%eax
801064e3:	a2 a5 20 11 80       	mov    %al,0x801120a5
801064e8:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
801064ef:	83 c8 80             	or     $0xffffff80,%eax
801064f2:	a2 a5 20 11 80       	mov    %al,0x801120a5
801064f7:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801064fc:	c1 e8 10             	shr    $0x10,%eax
801064ff:	66 a3 a6 20 11 80    	mov    %ax,0x801120a6
  
  initlock(&tickslock, "time");
80106505:	c7 44 24 04 10 87 10 	movl   $0x80108710,0x4(%esp)
8010650c:	80 
8010650d:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106514:	e8 f2 e7 ff ff       	call   80104d0b <initlock>
}
80106519:	c9                   	leave  
8010651a:	c3                   	ret    

8010651b <idtinit>:

void
idtinit(void)
{
8010651b:	55                   	push   %ebp
8010651c:	89 e5                	mov    %esp,%ebp
8010651e:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106521:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106528:	00 
80106529:	c7 04 24 a0 1e 11 80 	movl   $0x80111ea0,(%esp)
80106530:	e8 38 fe ff ff       	call   8010636d <lidt>
}
80106535:	c9                   	leave  
80106536:	c3                   	ret    

80106537 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106537:	55                   	push   %ebp
80106538:	89 e5                	mov    %esp,%ebp
8010653a:	57                   	push   %edi
8010653b:	56                   	push   %esi
8010653c:	53                   	push   %ebx
8010653d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106540:	8b 45 08             	mov    0x8(%ebp),%eax
80106543:	8b 40 30             	mov    0x30(%eax),%eax
80106546:	83 f8 40             	cmp    $0x40,%eax
80106549:	75 3f                	jne    8010658a <trap+0x53>
    if(proc->killed)
8010654b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106551:	8b 40 24             	mov    0x24(%eax),%eax
80106554:	85 c0                	test   %eax,%eax
80106556:	74 05                	je     8010655d <trap+0x26>
      exit();
80106558:	e8 36 e1 ff ff       	call   80104693 <exit>
    proc->tf = tf;
8010655d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106563:	8b 55 08             	mov    0x8(%ebp),%edx
80106566:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106569:	e8 1b ee ff ff       	call   80105389 <syscall>
    if(proc->killed)
8010656e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106574:	8b 40 24             	mov    0x24(%eax),%eax
80106577:	85 c0                	test   %eax,%eax
80106579:	74 0a                	je     80106585 <trap+0x4e>
      exit();
8010657b:	e8 13 e1 ff ff       	call   80104693 <exit>
    return;
80106580:	e9 2d 02 00 00       	jmp    801067b2 <trap+0x27b>
80106585:	e9 28 02 00 00       	jmp    801067b2 <trap+0x27b>
  }

  switch(tf->trapno){
8010658a:	8b 45 08             	mov    0x8(%ebp),%eax
8010658d:	8b 40 30             	mov    0x30(%eax),%eax
80106590:	83 e8 20             	sub    $0x20,%eax
80106593:	83 f8 1f             	cmp    $0x1f,%eax
80106596:	0f 87 bc 00 00 00    	ja     80106658 <trap+0x121>
8010659c:	8b 04 85 b8 87 10 80 	mov    -0x7fef7848(,%eax,4),%eax
801065a3:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801065a5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801065ab:	0f b6 00             	movzbl (%eax),%eax
801065ae:	84 c0                	test   %al,%al
801065b0:	75 31                	jne    801065e3 <trap+0xac>
      acquire(&tickslock);
801065b2:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801065b9:	e8 6e e7 ff ff       	call   80104d2c <acquire>
      ticks++;
801065be:	a1 a0 26 11 80       	mov    0x801126a0,%eax
801065c3:	83 c0 01             	add    $0x1,%eax
801065c6:	a3 a0 26 11 80       	mov    %eax,0x801126a0
      wakeup(&ticks);
801065cb:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
801065d2:	e8 64 e5 ff ff       	call   80104b3b <wakeup>
      release(&tickslock);
801065d7:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801065de:	e8 ab e7 ff ff       	call   80104d8e <release>
    }
    lapiceoi();
801065e3:	e8 81 cb ff ff       	call   80103169 <lapiceoi>
    break;
801065e8:	e9 41 01 00 00       	jmp    8010672e <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801065ed:	e8 a2 c3 ff ff       	call   80102994 <ideintr>
    lapiceoi();
801065f2:	e8 72 cb ff ff       	call   80103169 <lapiceoi>
    break;
801065f7:	e9 32 01 00 00       	jmp    8010672e <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801065fc:	e8 54 c9 ff ff       	call   80102f55 <kbdintr>
    lapiceoi();
80106601:	e8 63 cb ff ff       	call   80103169 <lapiceoi>
    break;
80106606:	e9 23 01 00 00       	jmp    8010672e <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010660b:	e8 97 03 00 00       	call   801069a7 <uartintr>
    lapiceoi();
80106610:	e8 54 cb ff ff       	call   80103169 <lapiceoi>
    break;
80106615:	e9 14 01 00 00       	jmp    8010672e <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010661a:	8b 45 08             	mov    0x8(%ebp),%eax
8010661d:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106620:	8b 45 08             	mov    0x8(%ebp),%eax
80106623:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106627:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010662a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106630:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106633:	0f b6 c0             	movzbl %al,%eax
80106636:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010663a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010663e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106642:	c7 04 24 18 87 10 80 	movl   $0x80108718,(%esp)
80106649:	e8 52 9d ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010664e:	e8 16 cb ff ff       	call   80103169 <lapiceoi>
    break;
80106653:	e9 d6 00 00 00       	jmp    8010672e <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106658:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010665e:	85 c0                	test   %eax,%eax
80106660:	74 11                	je     80106673 <trap+0x13c>
80106662:	8b 45 08             	mov    0x8(%ebp),%eax
80106665:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106669:	0f b7 c0             	movzwl %ax,%eax
8010666c:	83 e0 03             	and    $0x3,%eax
8010666f:	85 c0                	test   %eax,%eax
80106671:	75 46                	jne    801066b9 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106673:	e8 1e fd ff ff       	call   80106396 <rcr2>
80106678:	8b 55 08             	mov    0x8(%ebp),%edx
8010667b:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010667e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106685:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106688:	0f b6 ca             	movzbl %dl,%ecx
8010668b:	8b 55 08             	mov    0x8(%ebp),%edx
8010668e:	8b 52 30             	mov    0x30(%edx),%edx
80106691:	89 44 24 10          	mov    %eax,0x10(%esp)
80106695:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106699:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010669d:	89 54 24 04          	mov    %edx,0x4(%esp)
801066a1:	c7 04 24 3c 87 10 80 	movl   $0x8010873c,(%esp)
801066a8:	e8 f3 9c ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801066ad:	c7 04 24 6e 87 10 80 	movl   $0x8010876e,(%esp)
801066b4:	e8 81 9e ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066b9:	e8 d8 fc ff ff       	call   80106396 <rcr2>
801066be:	89 c2                	mov    %eax,%edx
801066c0:	8b 45 08             	mov    0x8(%ebp),%eax
801066c3:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066c6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801066cc:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066cf:	0f b6 f0             	movzbl %al,%esi
801066d2:	8b 45 08             	mov    0x8(%ebp),%eax
801066d5:	8b 58 34             	mov    0x34(%eax),%ebx
801066d8:	8b 45 08             	mov    0x8(%ebp),%eax
801066db:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066e4:	83 c0 6c             	add    $0x6c,%eax
801066e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801066ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066f0:	8b 40 10             	mov    0x10(%eax),%eax
801066f3:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801066f7:	89 7c 24 18          	mov    %edi,0x18(%esp)
801066fb:	89 74 24 14          	mov    %esi,0x14(%esp)
801066ff:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106703:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106707:	8b 75 e4             	mov    -0x1c(%ebp),%esi
8010670a:	89 74 24 08          	mov    %esi,0x8(%esp)
8010670e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106712:	c7 04 24 74 87 10 80 	movl   $0x80108774,(%esp)
80106719:	e8 82 9c ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010671e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106724:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010672b:	eb 01                	jmp    8010672e <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010672d:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010672e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106734:	85 c0                	test   %eax,%eax
80106736:	74 24                	je     8010675c <trap+0x225>
80106738:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010673e:	8b 40 24             	mov    0x24(%eax),%eax
80106741:	85 c0                	test   %eax,%eax
80106743:	74 17                	je     8010675c <trap+0x225>
80106745:	8b 45 08             	mov    0x8(%ebp),%eax
80106748:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010674c:	0f b7 c0             	movzwl %ax,%eax
8010674f:	83 e0 03             	and    $0x3,%eax
80106752:	83 f8 03             	cmp    $0x3,%eax
80106755:	75 05                	jne    8010675c <trap+0x225>
    exit();
80106757:	e8 37 df ff ff       	call   80104693 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010675c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106762:	85 c0                	test   %eax,%eax
80106764:	74 1e                	je     80106784 <trap+0x24d>
80106766:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010676c:	8b 40 0c             	mov    0xc(%eax),%eax
8010676f:	83 f8 04             	cmp    $0x4,%eax
80106772:	75 10                	jne    80106784 <trap+0x24d>
80106774:	8b 45 08             	mov    0x8(%ebp),%eax
80106777:	8b 40 30             	mov    0x30(%eax),%eax
8010677a:	83 f8 20             	cmp    $0x20,%eax
8010677d:	75 05                	jne    80106784 <trap+0x24d>
    yield();
8010677f:	e8 80 e2 ff ff       	call   80104a04 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106784:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010678a:	85 c0                	test   %eax,%eax
8010678c:	74 24                	je     801067b2 <trap+0x27b>
8010678e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106794:	8b 40 24             	mov    0x24(%eax),%eax
80106797:	85 c0                	test   %eax,%eax
80106799:	74 17                	je     801067b2 <trap+0x27b>
8010679b:	8b 45 08             	mov    0x8(%ebp),%eax
8010679e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801067a2:	0f b7 c0             	movzwl %ax,%eax
801067a5:	83 e0 03             	and    $0x3,%eax
801067a8:	83 f8 03             	cmp    $0x3,%eax
801067ab:	75 05                	jne    801067b2 <trap+0x27b>
    exit();
801067ad:	e8 e1 de ff ff       	call   80104693 <exit>
}
801067b2:	83 c4 3c             	add    $0x3c,%esp
801067b5:	5b                   	pop    %ebx
801067b6:	5e                   	pop    %esi
801067b7:	5f                   	pop    %edi
801067b8:	5d                   	pop    %ebp
801067b9:	c3                   	ret    

801067ba <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801067ba:	55                   	push   %ebp
801067bb:	89 e5                	mov    %esp,%ebp
801067bd:	83 ec 14             	sub    $0x14,%esp
801067c0:	8b 45 08             	mov    0x8(%ebp),%eax
801067c3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801067c7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801067cb:	89 c2                	mov    %eax,%edx
801067cd:	ec                   	in     (%dx),%al
801067ce:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801067d1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801067d5:	c9                   	leave  
801067d6:	c3                   	ret    

801067d7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801067d7:	55                   	push   %ebp
801067d8:	89 e5                	mov    %esp,%ebp
801067da:	83 ec 08             	sub    $0x8,%esp
801067dd:	8b 55 08             	mov    0x8(%ebp),%edx
801067e0:	8b 45 0c             	mov    0xc(%ebp),%eax
801067e3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801067e7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801067ea:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801067ee:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801067f2:	ee                   	out    %al,(%dx)
}
801067f3:	c9                   	leave  
801067f4:	c3                   	ret    

801067f5 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801067f5:	55                   	push   %ebp
801067f6:	89 e5                	mov    %esp,%ebp
801067f8:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801067fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106802:	00 
80106803:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010680a:	e8 c8 ff ff ff       	call   801067d7 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010680f:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106816:	00 
80106817:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010681e:	e8 b4 ff ff ff       	call   801067d7 <outb>
  outb(COM1+0, 115200/9600);
80106823:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010682a:	00 
8010682b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106832:	e8 a0 ff ff ff       	call   801067d7 <outb>
  outb(COM1+1, 0);
80106837:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010683e:	00 
8010683f:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106846:	e8 8c ff ff ff       	call   801067d7 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010684b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106852:	00 
80106853:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010685a:	e8 78 ff ff ff       	call   801067d7 <outb>
  outb(COM1+4, 0);
8010685f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106866:	00 
80106867:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
8010686e:	e8 64 ff ff ff       	call   801067d7 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106873:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010687a:	00 
8010687b:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106882:	e8 50 ff ff ff       	call   801067d7 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106887:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010688e:	e8 27 ff ff ff       	call   801067ba <inb>
80106893:	3c ff                	cmp    $0xff,%al
80106895:	75 02                	jne    80106899 <uartinit+0xa4>
    return;
80106897:	eb 6a                	jmp    80106903 <uartinit+0x10e>
  uart = 1;
80106899:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
801068a0:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801068a3:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801068aa:	e8 0b ff ff ff       	call   801067ba <inb>
  inb(COM1+0);
801068af:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801068b6:	e8 ff fe ff ff       	call   801067ba <inb>
  picenable(IRQ_COM1);
801068bb:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068c2:	e8 51 d4 ff ff       	call   80103d18 <picenable>
  ioapicenable(IRQ_COM1, 0);
801068c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068ce:	00 
801068cf:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068d6:	e8 38 c3 ff ff       	call   80102c13 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068db:	c7 45 f4 38 88 10 80 	movl   $0x80108838,-0xc(%ebp)
801068e2:	eb 15                	jmp    801068f9 <uartinit+0x104>
    uartputc(*p);
801068e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e7:	0f b6 00             	movzbl (%eax),%eax
801068ea:	0f be c0             	movsbl %al,%eax
801068ed:	89 04 24             	mov    %eax,(%esp)
801068f0:	e8 10 00 00 00       	call   80106905 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801068f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068fc:	0f b6 00             	movzbl (%eax),%eax
801068ff:	84 c0                	test   %al,%al
80106901:	75 e1                	jne    801068e4 <uartinit+0xef>
    uartputc(*p);
}
80106903:	c9                   	leave  
80106904:	c3                   	ret    

80106905 <uartputc>:

void
uartputc(int c)
{
80106905:	55                   	push   %ebp
80106906:	89 e5                	mov    %esp,%ebp
80106908:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010690b:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106910:	85 c0                	test   %eax,%eax
80106912:	75 02                	jne    80106916 <uartputc+0x11>
    return;
80106914:	eb 4b                	jmp    80106961 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106916:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010691d:	eb 10                	jmp    8010692f <uartputc+0x2a>
    microdelay(10);
8010691f:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106926:	e8 63 c8 ff ff       	call   8010318e <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010692b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010692f:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106933:	7f 16                	jg     8010694b <uartputc+0x46>
80106935:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010693c:	e8 79 fe ff ff       	call   801067ba <inb>
80106941:	0f b6 c0             	movzbl %al,%eax
80106944:	83 e0 20             	and    $0x20,%eax
80106947:	85 c0                	test   %eax,%eax
80106949:	74 d4                	je     8010691f <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
8010694b:	8b 45 08             	mov    0x8(%ebp),%eax
8010694e:	0f b6 c0             	movzbl %al,%eax
80106951:	89 44 24 04          	mov    %eax,0x4(%esp)
80106955:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010695c:	e8 76 fe ff ff       	call   801067d7 <outb>
}
80106961:	c9                   	leave  
80106962:	c3                   	ret    

80106963 <uartgetc>:

static int
uartgetc(void)
{
80106963:	55                   	push   %ebp
80106964:	89 e5                	mov    %esp,%ebp
80106966:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106969:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
8010696e:	85 c0                	test   %eax,%eax
80106970:	75 07                	jne    80106979 <uartgetc+0x16>
    return -1;
80106972:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106977:	eb 2c                	jmp    801069a5 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106979:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106980:	e8 35 fe ff ff       	call   801067ba <inb>
80106985:	0f b6 c0             	movzbl %al,%eax
80106988:	83 e0 01             	and    $0x1,%eax
8010698b:	85 c0                	test   %eax,%eax
8010698d:	75 07                	jne    80106996 <uartgetc+0x33>
    return -1;
8010698f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106994:	eb 0f                	jmp    801069a5 <uartgetc+0x42>
  return inb(COM1+0);
80106996:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010699d:	e8 18 fe ff ff       	call   801067ba <inb>
801069a2:	0f b6 c0             	movzbl %al,%eax
}
801069a5:	c9                   	leave  
801069a6:	c3                   	ret    

801069a7 <uartintr>:

void
uartintr(void)
{
801069a7:	55                   	push   %ebp
801069a8:	89 e5                	mov    %esp,%ebp
801069aa:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801069ad:	c7 04 24 63 69 10 80 	movl   $0x80106963,(%esp)
801069b4:	e8 f4 9d ff ff       	call   801007ad <consoleintr>
}
801069b9:	c9                   	leave  
801069ba:	c3                   	ret    

801069bb <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801069bb:	6a 00                	push   $0x0
  pushl $0
801069bd:	6a 00                	push   $0x0
  jmp alltraps
801069bf:	e9 7e f9 ff ff       	jmp    80106342 <alltraps>

801069c4 <vector1>:
.globl vector1
vector1:
  pushl $0
801069c4:	6a 00                	push   $0x0
  pushl $1
801069c6:	6a 01                	push   $0x1
  jmp alltraps
801069c8:	e9 75 f9 ff ff       	jmp    80106342 <alltraps>

801069cd <vector2>:
.globl vector2
vector2:
  pushl $0
801069cd:	6a 00                	push   $0x0
  pushl $2
801069cf:	6a 02                	push   $0x2
  jmp alltraps
801069d1:	e9 6c f9 ff ff       	jmp    80106342 <alltraps>

801069d6 <vector3>:
.globl vector3
vector3:
  pushl $0
801069d6:	6a 00                	push   $0x0
  pushl $3
801069d8:	6a 03                	push   $0x3
  jmp alltraps
801069da:	e9 63 f9 ff ff       	jmp    80106342 <alltraps>

801069df <vector4>:
.globl vector4
vector4:
  pushl $0
801069df:	6a 00                	push   $0x0
  pushl $4
801069e1:	6a 04                	push   $0x4
  jmp alltraps
801069e3:	e9 5a f9 ff ff       	jmp    80106342 <alltraps>

801069e8 <vector5>:
.globl vector5
vector5:
  pushl $0
801069e8:	6a 00                	push   $0x0
  pushl $5
801069ea:	6a 05                	push   $0x5
  jmp alltraps
801069ec:	e9 51 f9 ff ff       	jmp    80106342 <alltraps>

801069f1 <vector6>:
.globl vector6
vector6:
  pushl $0
801069f1:	6a 00                	push   $0x0
  pushl $6
801069f3:	6a 06                	push   $0x6
  jmp alltraps
801069f5:	e9 48 f9 ff ff       	jmp    80106342 <alltraps>

801069fa <vector7>:
.globl vector7
vector7:
  pushl $0
801069fa:	6a 00                	push   $0x0
  pushl $7
801069fc:	6a 07                	push   $0x7
  jmp alltraps
801069fe:	e9 3f f9 ff ff       	jmp    80106342 <alltraps>

80106a03 <vector8>:
.globl vector8
vector8:
  pushl $8
80106a03:	6a 08                	push   $0x8
  jmp alltraps
80106a05:	e9 38 f9 ff ff       	jmp    80106342 <alltraps>

80106a0a <vector9>:
.globl vector9
vector9:
  pushl $0
80106a0a:	6a 00                	push   $0x0
  pushl $9
80106a0c:	6a 09                	push   $0x9
  jmp alltraps
80106a0e:	e9 2f f9 ff ff       	jmp    80106342 <alltraps>

80106a13 <vector10>:
.globl vector10
vector10:
  pushl $10
80106a13:	6a 0a                	push   $0xa
  jmp alltraps
80106a15:	e9 28 f9 ff ff       	jmp    80106342 <alltraps>

80106a1a <vector11>:
.globl vector11
vector11:
  pushl $11
80106a1a:	6a 0b                	push   $0xb
  jmp alltraps
80106a1c:	e9 21 f9 ff ff       	jmp    80106342 <alltraps>

80106a21 <vector12>:
.globl vector12
vector12:
  pushl $12
80106a21:	6a 0c                	push   $0xc
  jmp alltraps
80106a23:	e9 1a f9 ff ff       	jmp    80106342 <alltraps>

80106a28 <vector13>:
.globl vector13
vector13:
  pushl $13
80106a28:	6a 0d                	push   $0xd
  jmp alltraps
80106a2a:	e9 13 f9 ff ff       	jmp    80106342 <alltraps>

80106a2f <vector14>:
.globl vector14
vector14:
  pushl $14
80106a2f:	6a 0e                	push   $0xe
  jmp alltraps
80106a31:	e9 0c f9 ff ff       	jmp    80106342 <alltraps>

80106a36 <vector15>:
.globl vector15
vector15:
  pushl $0
80106a36:	6a 00                	push   $0x0
  pushl $15
80106a38:	6a 0f                	push   $0xf
  jmp alltraps
80106a3a:	e9 03 f9 ff ff       	jmp    80106342 <alltraps>

80106a3f <vector16>:
.globl vector16
vector16:
  pushl $0
80106a3f:	6a 00                	push   $0x0
  pushl $16
80106a41:	6a 10                	push   $0x10
  jmp alltraps
80106a43:	e9 fa f8 ff ff       	jmp    80106342 <alltraps>

80106a48 <vector17>:
.globl vector17
vector17:
  pushl $17
80106a48:	6a 11                	push   $0x11
  jmp alltraps
80106a4a:	e9 f3 f8 ff ff       	jmp    80106342 <alltraps>

80106a4f <vector18>:
.globl vector18
vector18:
  pushl $0
80106a4f:	6a 00                	push   $0x0
  pushl $18
80106a51:	6a 12                	push   $0x12
  jmp alltraps
80106a53:	e9 ea f8 ff ff       	jmp    80106342 <alltraps>

80106a58 <vector19>:
.globl vector19
vector19:
  pushl $0
80106a58:	6a 00                	push   $0x0
  pushl $19
80106a5a:	6a 13                	push   $0x13
  jmp alltraps
80106a5c:	e9 e1 f8 ff ff       	jmp    80106342 <alltraps>

80106a61 <vector20>:
.globl vector20
vector20:
  pushl $0
80106a61:	6a 00                	push   $0x0
  pushl $20
80106a63:	6a 14                	push   $0x14
  jmp alltraps
80106a65:	e9 d8 f8 ff ff       	jmp    80106342 <alltraps>

80106a6a <vector21>:
.globl vector21
vector21:
  pushl $0
80106a6a:	6a 00                	push   $0x0
  pushl $21
80106a6c:	6a 15                	push   $0x15
  jmp alltraps
80106a6e:	e9 cf f8 ff ff       	jmp    80106342 <alltraps>

80106a73 <vector22>:
.globl vector22
vector22:
  pushl $0
80106a73:	6a 00                	push   $0x0
  pushl $22
80106a75:	6a 16                	push   $0x16
  jmp alltraps
80106a77:	e9 c6 f8 ff ff       	jmp    80106342 <alltraps>

80106a7c <vector23>:
.globl vector23
vector23:
  pushl $0
80106a7c:	6a 00                	push   $0x0
  pushl $23
80106a7e:	6a 17                	push   $0x17
  jmp alltraps
80106a80:	e9 bd f8 ff ff       	jmp    80106342 <alltraps>

80106a85 <vector24>:
.globl vector24
vector24:
  pushl $0
80106a85:	6a 00                	push   $0x0
  pushl $24
80106a87:	6a 18                	push   $0x18
  jmp alltraps
80106a89:	e9 b4 f8 ff ff       	jmp    80106342 <alltraps>

80106a8e <vector25>:
.globl vector25
vector25:
  pushl $0
80106a8e:	6a 00                	push   $0x0
  pushl $25
80106a90:	6a 19                	push   $0x19
  jmp alltraps
80106a92:	e9 ab f8 ff ff       	jmp    80106342 <alltraps>

80106a97 <vector26>:
.globl vector26
vector26:
  pushl $0
80106a97:	6a 00                	push   $0x0
  pushl $26
80106a99:	6a 1a                	push   $0x1a
  jmp alltraps
80106a9b:	e9 a2 f8 ff ff       	jmp    80106342 <alltraps>

80106aa0 <vector27>:
.globl vector27
vector27:
  pushl $0
80106aa0:	6a 00                	push   $0x0
  pushl $27
80106aa2:	6a 1b                	push   $0x1b
  jmp alltraps
80106aa4:	e9 99 f8 ff ff       	jmp    80106342 <alltraps>

80106aa9 <vector28>:
.globl vector28
vector28:
  pushl $0
80106aa9:	6a 00                	push   $0x0
  pushl $28
80106aab:	6a 1c                	push   $0x1c
  jmp alltraps
80106aad:	e9 90 f8 ff ff       	jmp    80106342 <alltraps>

80106ab2 <vector29>:
.globl vector29
vector29:
  pushl $0
80106ab2:	6a 00                	push   $0x0
  pushl $29
80106ab4:	6a 1d                	push   $0x1d
  jmp alltraps
80106ab6:	e9 87 f8 ff ff       	jmp    80106342 <alltraps>

80106abb <vector30>:
.globl vector30
vector30:
  pushl $0
80106abb:	6a 00                	push   $0x0
  pushl $30
80106abd:	6a 1e                	push   $0x1e
  jmp alltraps
80106abf:	e9 7e f8 ff ff       	jmp    80106342 <alltraps>

80106ac4 <vector31>:
.globl vector31
vector31:
  pushl $0
80106ac4:	6a 00                	push   $0x0
  pushl $31
80106ac6:	6a 1f                	push   $0x1f
  jmp alltraps
80106ac8:	e9 75 f8 ff ff       	jmp    80106342 <alltraps>

80106acd <vector32>:
.globl vector32
vector32:
  pushl $0
80106acd:	6a 00                	push   $0x0
  pushl $32
80106acf:	6a 20                	push   $0x20
  jmp alltraps
80106ad1:	e9 6c f8 ff ff       	jmp    80106342 <alltraps>

80106ad6 <vector33>:
.globl vector33
vector33:
  pushl $0
80106ad6:	6a 00                	push   $0x0
  pushl $33
80106ad8:	6a 21                	push   $0x21
  jmp alltraps
80106ada:	e9 63 f8 ff ff       	jmp    80106342 <alltraps>

80106adf <vector34>:
.globl vector34
vector34:
  pushl $0
80106adf:	6a 00                	push   $0x0
  pushl $34
80106ae1:	6a 22                	push   $0x22
  jmp alltraps
80106ae3:	e9 5a f8 ff ff       	jmp    80106342 <alltraps>

80106ae8 <vector35>:
.globl vector35
vector35:
  pushl $0
80106ae8:	6a 00                	push   $0x0
  pushl $35
80106aea:	6a 23                	push   $0x23
  jmp alltraps
80106aec:	e9 51 f8 ff ff       	jmp    80106342 <alltraps>

80106af1 <vector36>:
.globl vector36
vector36:
  pushl $0
80106af1:	6a 00                	push   $0x0
  pushl $36
80106af3:	6a 24                	push   $0x24
  jmp alltraps
80106af5:	e9 48 f8 ff ff       	jmp    80106342 <alltraps>

80106afa <vector37>:
.globl vector37
vector37:
  pushl $0
80106afa:	6a 00                	push   $0x0
  pushl $37
80106afc:	6a 25                	push   $0x25
  jmp alltraps
80106afe:	e9 3f f8 ff ff       	jmp    80106342 <alltraps>

80106b03 <vector38>:
.globl vector38
vector38:
  pushl $0
80106b03:	6a 00                	push   $0x0
  pushl $38
80106b05:	6a 26                	push   $0x26
  jmp alltraps
80106b07:	e9 36 f8 ff ff       	jmp    80106342 <alltraps>

80106b0c <vector39>:
.globl vector39
vector39:
  pushl $0
80106b0c:	6a 00                	push   $0x0
  pushl $39
80106b0e:	6a 27                	push   $0x27
  jmp alltraps
80106b10:	e9 2d f8 ff ff       	jmp    80106342 <alltraps>

80106b15 <vector40>:
.globl vector40
vector40:
  pushl $0
80106b15:	6a 00                	push   $0x0
  pushl $40
80106b17:	6a 28                	push   $0x28
  jmp alltraps
80106b19:	e9 24 f8 ff ff       	jmp    80106342 <alltraps>

80106b1e <vector41>:
.globl vector41
vector41:
  pushl $0
80106b1e:	6a 00                	push   $0x0
  pushl $41
80106b20:	6a 29                	push   $0x29
  jmp alltraps
80106b22:	e9 1b f8 ff ff       	jmp    80106342 <alltraps>

80106b27 <vector42>:
.globl vector42
vector42:
  pushl $0
80106b27:	6a 00                	push   $0x0
  pushl $42
80106b29:	6a 2a                	push   $0x2a
  jmp alltraps
80106b2b:	e9 12 f8 ff ff       	jmp    80106342 <alltraps>

80106b30 <vector43>:
.globl vector43
vector43:
  pushl $0
80106b30:	6a 00                	push   $0x0
  pushl $43
80106b32:	6a 2b                	push   $0x2b
  jmp alltraps
80106b34:	e9 09 f8 ff ff       	jmp    80106342 <alltraps>

80106b39 <vector44>:
.globl vector44
vector44:
  pushl $0
80106b39:	6a 00                	push   $0x0
  pushl $44
80106b3b:	6a 2c                	push   $0x2c
  jmp alltraps
80106b3d:	e9 00 f8 ff ff       	jmp    80106342 <alltraps>

80106b42 <vector45>:
.globl vector45
vector45:
  pushl $0
80106b42:	6a 00                	push   $0x0
  pushl $45
80106b44:	6a 2d                	push   $0x2d
  jmp alltraps
80106b46:	e9 f7 f7 ff ff       	jmp    80106342 <alltraps>

80106b4b <vector46>:
.globl vector46
vector46:
  pushl $0
80106b4b:	6a 00                	push   $0x0
  pushl $46
80106b4d:	6a 2e                	push   $0x2e
  jmp alltraps
80106b4f:	e9 ee f7 ff ff       	jmp    80106342 <alltraps>

80106b54 <vector47>:
.globl vector47
vector47:
  pushl $0
80106b54:	6a 00                	push   $0x0
  pushl $47
80106b56:	6a 2f                	push   $0x2f
  jmp alltraps
80106b58:	e9 e5 f7 ff ff       	jmp    80106342 <alltraps>

80106b5d <vector48>:
.globl vector48
vector48:
  pushl $0
80106b5d:	6a 00                	push   $0x0
  pushl $48
80106b5f:	6a 30                	push   $0x30
  jmp alltraps
80106b61:	e9 dc f7 ff ff       	jmp    80106342 <alltraps>

80106b66 <vector49>:
.globl vector49
vector49:
  pushl $0
80106b66:	6a 00                	push   $0x0
  pushl $49
80106b68:	6a 31                	push   $0x31
  jmp alltraps
80106b6a:	e9 d3 f7 ff ff       	jmp    80106342 <alltraps>

80106b6f <vector50>:
.globl vector50
vector50:
  pushl $0
80106b6f:	6a 00                	push   $0x0
  pushl $50
80106b71:	6a 32                	push   $0x32
  jmp alltraps
80106b73:	e9 ca f7 ff ff       	jmp    80106342 <alltraps>

80106b78 <vector51>:
.globl vector51
vector51:
  pushl $0
80106b78:	6a 00                	push   $0x0
  pushl $51
80106b7a:	6a 33                	push   $0x33
  jmp alltraps
80106b7c:	e9 c1 f7 ff ff       	jmp    80106342 <alltraps>

80106b81 <vector52>:
.globl vector52
vector52:
  pushl $0
80106b81:	6a 00                	push   $0x0
  pushl $52
80106b83:	6a 34                	push   $0x34
  jmp alltraps
80106b85:	e9 b8 f7 ff ff       	jmp    80106342 <alltraps>

80106b8a <vector53>:
.globl vector53
vector53:
  pushl $0
80106b8a:	6a 00                	push   $0x0
  pushl $53
80106b8c:	6a 35                	push   $0x35
  jmp alltraps
80106b8e:	e9 af f7 ff ff       	jmp    80106342 <alltraps>

80106b93 <vector54>:
.globl vector54
vector54:
  pushl $0
80106b93:	6a 00                	push   $0x0
  pushl $54
80106b95:	6a 36                	push   $0x36
  jmp alltraps
80106b97:	e9 a6 f7 ff ff       	jmp    80106342 <alltraps>

80106b9c <vector55>:
.globl vector55
vector55:
  pushl $0
80106b9c:	6a 00                	push   $0x0
  pushl $55
80106b9e:	6a 37                	push   $0x37
  jmp alltraps
80106ba0:	e9 9d f7 ff ff       	jmp    80106342 <alltraps>

80106ba5 <vector56>:
.globl vector56
vector56:
  pushl $0
80106ba5:	6a 00                	push   $0x0
  pushl $56
80106ba7:	6a 38                	push   $0x38
  jmp alltraps
80106ba9:	e9 94 f7 ff ff       	jmp    80106342 <alltraps>

80106bae <vector57>:
.globl vector57
vector57:
  pushl $0
80106bae:	6a 00                	push   $0x0
  pushl $57
80106bb0:	6a 39                	push   $0x39
  jmp alltraps
80106bb2:	e9 8b f7 ff ff       	jmp    80106342 <alltraps>

80106bb7 <vector58>:
.globl vector58
vector58:
  pushl $0
80106bb7:	6a 00                	push   $0x0
  pushl $58
80106bb9:	6a 3a                	push   $0x3a
  jmp alltraps
80106bbb:	e9 82 f7 ff ff       	jmp    80106342 <alltraps>

80106bc0 <vector59>:
.globl vector59
vector59:
  pushl $0
80106bc0:	6a 00                	push   $0x0
  pushl $59
80106bc2:	6a 3b                	push   $0x3b
  jmp alltraps
80106bc4:	e9 79 f7 ff ff       	jmp    80106342 <alltraps>

80106bc9 <vector60>:
.globl vector60
vector60:
  pushl $0
80106bc9:	6a 00                	push   $0x0
  pushl $60
80106bcb:	6a 3c                	push   $0x3c
  jmp alltraps
80106bcd:	e9 70 f7 ff ff       	jmp    80106342 <alltraps>

80106bd2 <vector61>:
.globl vector61
vector61:
  pushl $0
80106bd2:	6a 00                	push   $0x0
  pushl $61
80106bd4:	6a 3d                	push   $0x3d
  jmp alltraps
80106bd6:	e9 67 f7 ff ff       	jmp    80106342 <alltraps>

80106bdb <vector62>:
.globl vector62
vector62:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $62
80106bdd:	6a 3e                	push   $0x3e
  jmp alltraps
80106bdf:	e9 5e f7 ff ff       	jmp    80106342 <alltraps>

80106be4 <vector63>:
.globl vector63
vector63:
  pushl $0
80106be4:	6a 00                	push   $0x0
  pushl $63
80106be6:	6a 3f                	push   $0x3f
  jmp alltraps
80106be8:	e9 55 f7 ff ff       	jmp    80106342 <alltraps>

80106bed <vector64>:
.globl vector64
vector64:
  pushl $0
80106bed:	6a 00                	push   $0x0
  pushl $64
80106bef:	6a 40                	push   $0x40
  jmp alltraps
80106bf1:	e9 4c f7 ff ff       	jmp    80106342 <alltraps>

80106bf6 <vector65>:
.globl vector65
vector65:
  pushl $0
80106bf6:	6a 00                	push   $0x0
  pushl $65
80106bf8:	6a 41                	push   $0x41
  jmp alltraps
80106bfa:	e9 43 f7 ff ff       	jmp    80106342 <alltraps>

80106bff <vector66>:
.globl vector66
vector66:
  pushl $0
80106bff:	6a 00                	push   $0x0
  pushl $66
80106c01:	6a 42                	push   $0x42
  jmp alltraps
80106c03:	e9 3a f7 ff ff       	jmp    80106342 <alltraps>

80106c08 <vector67>:
.globl vector67
vector67:
  pushl $0
80106c08:	6a 00                	push   $0x0
  pushl $67
80106c0a:	6a 43                	push   $0x43
  jmp alltraps
80106c0c:	e9 31 f7 ff ff       	jmp    80106342 <alltraps>

80106c11 <vector68>:
.globl vector68
vector68:
  pushl $0
80106c11:	6a 00                	push   $0x0
  pushl $68
80106c13:	6a 44                	push   $0x44
  jmp alltraps
80106c15:	e9 28 f7 ff ff       	jmp    80106342 <alltraps>

80106c1a <vector69>:
.globl vector69
vector69:
  pushl $0
80106c1a:	6a 00                	push   $0x0
  pushl $69
80106c1c:	6a 45                	push   $0x45
  jmp alltraps
80106c1e:	e9 1f f7 ff ff       	jmp    80106342 <alltraps>

80106c23 <vector70>:
.globl vector70
vector70:
  pushl $0
80106c23:	6a 00                	push   $0x0
  pushl $70
80106c25:	6a 46                	push   $0x46
  jmp alltraps
80106c27:	e9 16 f7 ff ff       	jmp    80106342 <alltraps>

80106c2c <vector71>:
.globl vector71
vector71:
  pushl $0
80106c2c:	6a 00                	push   $0x0
  pushl $71
80106c2e:	6a 47                	push   $0x47
  jmp alltraps
80106c30:	e9 0d f7 ff ff       	jmp    80106342 <alltraps>

80106c35 <vector72>:
.globl vector72
vector72:
  pushl $0
80106c35:	6a 00                	push   $0x0
  pushl $72
80106c37:	6a 48                	push   $0x48
  jmp alltraps
80106c39:	e9 04 f7 ff ff       	jmp    80106342 <alltraps>

80106c3e <vector73>:
.globl vector73
vector73:
  pushl $0
80106c3e:	6a 00                	push   $0x0
  pushl $73
80106c40:	6a 49                	push   $0x49
  jmp alltraps
80106c42:	e9 fb f6 ff ff       	jmp    80106342 <alltraps>

80106c47 <vector74>:
.globl vector74
vector74:
  pushl $0
80106c47:	6a 00                	push   $0x0
  pushl $74
80106c49:	6a 4a                	push   $0x4a
  jmp alltraps
80106c4b:	e9 f2 f6 ff ff       	jmp    80106342 <alltraps>

80106c50 <vector75>:
.globl vector75
vector75:
  pushl $0
80106c50:	6a 00                	push   $0x0
  pushl $75
80106c52:	6a 4b                	push   $0x4b
  jmp alltraps
80106c54:	e9 e9 f6 ff ff       	jmp    80106342 <alltraps>

80106c59 <vector76>:
.globl vector76
vector76:
  pushl $0
80106c59:	6a 00                	push   $0x0
  pushl $76
80106c5b:	6a 4c                	push   $0x4c
  jmp alltraps
80106c5d:	e9 e0 f6 ff ff       	jmp    80106342 <alltraps>

80106c62 <vector77>:
.globl vector77
vector77:
  pushl $0
80106c62:	6a 00                	push   $0x0
  pushl $77
80106c64:	6a 4d                	push   $0x4d
  jmp alltraps
80106c66:	e9 d7 f6 ff ff       	jmp    80106342 <alltraps>

80106c6b <vector78>:
.globl vector78
vector78:
  pushl $0
80106c6b:	6a 00                	push   $0x0
  pushl $78
80106c6d:	6a 4e                	push   $0x4e
  jmp alltraps
80106c6f:	e9 ce f6 ff ff       	jmp    80106342 <alltraps>

80106c74 <vector79>:
.globl vector79
vector79:
  pushl $0
80106c74:	6a 00                	push   $0x0
  pushl $79
80106c76:	6a 4f                	push   $0x4f
  jmp alltraps
80106c78:	e9 c5 f6 ff ff       	jmp    80106342 <alltraps>

80106c7d <vector80>:
.globl vector80
vector80:
  pushl $0
80106c7d:	6a 00                	push   $0x0
  pushl $80
80106c7f:	6a 50                	push   $0x50
  jmp alltraps
80106c81:	e9 bc f6 ff ff       	jmp    80106342 <alltraps>

80106c86 <vector81>:
.globl vector81
vector81:
  pushl $0
80106c86:	6a 00                	push   $0x0
  pushl $81
80106c88:	6a 51                	push   $0x51
  jmp alltraps
80106c8a:	e9 b3 f6 ff ff       	jmp    80106342 <alltraps>

80106c8f <vector82>:
.globl vector82
vector82:
  pushl $0
80106c8f:	6a 00                	push   $0x0
  pushl $82
80106c91:	6a 52                	push   $0x52
  jmp alltraps
80106c93:	e9 aa f6 ff ff       	jmp    80106342 <alltraps>

80106c98 <vector83>:
.globl vector83
vector83:
  pushl $0
80106c98:	6a 00                	push   $0x0
  pushl $83
80106c9a:	6a 53                	push   $0x53
  jmp alltraps
80106c9c:	e9 a1 f6 ff ff       	jmp    80106342 <alltraps>

80106ca1 <vector84>:
.globl vector84
vector84:
  pushl $0
80106ca1:	6a 00                	push   $0x0
  pushl $84
80106ca3:	6a 54                	push   $0x54
  jmp alltraps
80106ca5:	e9 98 f6 ff ff       	jmp    80106342 <alltraps>

80106caa <vector85>:
.globl vector85
vector85:
  pushl $0
80106caa:	6a 00                	push   $0x0
  pushl $85
80106cac:	6a 55                	push   $0x55
  jmp alltraps
80106cae:	e9 8f f6 ff ff       	jmp    80106342 <alltraps>

80106cb3 <vector86>:
.globl vector86
vector86:
  pushl $0
80106cb3:	6a 00                	push   $0x0
  pushl $86
80106cb5:	6a 56                	push   $0x56
  jmp alltraps
80106cb7:	e9 86 f6 ff ff       	jmp    80106342 <alltraps>

80106cbc <vector87>:
.globl vector87
vector87:
  pushl $0
80106cbc:	6a 00                	push   $0x0
  pushl $87
80106cbe:	6a 57                	push   $0x57
  jmp alltraps
80106cc0:	e9 7d f6 ff ff       	jmp    80106342 <alltraps>

80106cc5 <vector88>:
.globl vector88
vector88:
  pushl $0
80106cc5:	6a 00                	push   $0x0
  pushl $88
80106cc7:	6a 58                	push   $0x58
  jmp alltraps
80106cc9:	e9 74 f6 ff ff       	jmp    80106342 <alltraps>

80106cce <vector89>:
.globl vector89
vector89:
  pushl $0
80106cce:	6a 00                	push   $0x0
  pushl $89
80106cd0:	6a 59                	push   $0x59
  jmp alltraps
80106cd2:	e9 6b f6 ff ff       	jmp    80106342 <alltraps>

80106cd7 <vector90>:
.globl vector90
vector90:
  pushl $0
80106cd7:	6a 00                	push   $0x0
  pushl $90
80106cd9:	6a 5a                	push   $0x5a
  jmp alltraps
80106cdb:	e9 62 f6 ff ff       	jmp    80106342 <alltraps>

80106ce0 <vector91>:
.globl vector91
vector91:
  pushl $0
80106ce0:	6a 00                	push   $0x0
  pushl $91
80106ce2:	6a 5b                	push   $0x5b
  jmp alltraps
80106ce4:	e9 59 f6 ff ff       	jmp    80106342 <alltraps>

80106ce9 <vector92>:
.globl vector92
vector92:
  pushl $0
80106ce9:	6a 00                	push   $0x0
  pushl $92
80106ceb:	6a 5c                	push   $0x5c
  jmp alltraps
80106ced:	e9 50 f6 ff ff       	jmp    80106342 <alltraps>

80106cf2 <vector93>:
.globl vector93
vector93:
  pushl $0
80106cf2:	6a 00                	push   $0x0
  pushl $93
80106cf4:	6a 5d                	push   $0x5d
  jmp alltraps
80106cf6:	e9 47 f6 ff ff       	jmp    80106342 <alltraps>

80106cfb <vector94>:
.globl vector94
vector94:
  pushl $0
80106cfb:	6a 00                	push   $0x0
  pushl $94
80106cfd:	6a 5e                	push   $0x5e
  jmp alltraps
80106cff:	e9 3e f6 ff ff       	jmp    80106342 <alltraps>

80106d04 <vector95>:
.globl vector95
vector95:
  pushl $0
80106d04:	6a 00                	push   $0x0
  pushl $95
80106d06:	6a 5f                	push   $0x5f
  jmp alltraps
80106d08:	e9 35 f6 ff ff       	jmp    80106342 <alltraps>

80106d0d <vector96>:
.globl vector96
vector96:
  pushl $0
80106d0d:	6a 00                	push   $0x0
  pushl $96
80106d0f:	6a 60                	push   $0x60
  jmp alltraps
80106d11:	e9 2c f6 ff ff       	jmp    80106342 <alltraps>

80106d16 <vector97>:
.globl vector97
vector97:
  pushl $0
80106d16:	6a 00                	push   $0x0
  pushl $97
80106d18:	6a 61                	push   $0x61
  jmp alltraps
80106d1a:	e9 23 f6 ff ff       	jmp    80106342 <alltraps>

80106d1f <vector98>:
.globl vector98
vector98:
  pushl $0
80106d1f:	6a 00                	push   $0x0
  pushl $98
80106d21:	6a 62                	push   $0x62
  jmp alltraps
80106d23:	e9 1a f6 ff ff       	jmp    80106342 <alltraps>

80106d28 <vector99>:
.globl vector99
vector99:
  pushl $0
80106d28:	6a 00                	push   $0x0
  pushl $99
80106d2a:	6a 63                	push   $0x63
  jmp alltraps
80106d2c:	e9 11 f6 ff ff       	jmp    80106342 <alltraps>

80106d31 <vector100>:
.globl vector100
vector100:
  pushl $0
80106d31:	6a 00                	push   $0x0
  pushl $100
80106d33:	6a 64                	push   $0x64
  jmp alltraps
80106d35:	e9 08 f6 ff ff       	jmp    80106342 <alltraps>

80106d3a <vector101>:
.globl vector101
vector101:
  pushl $0
80106d3a:	6a 00                	push   $0x0
  pushl $101
80106d3c:	6a 65                	push   $0x65
  jmp alltraps
80106d3e:	e9 ff f5 ff ff       	jmp    80106342 <alltraps>

80106d43 <vector102>:
.globl vector102
vector102:
  pushl $0
80106d43:	6a 00                	push   $0x0
  pushl $102
80106d45:	6a 66                	push   $0x66
  jmp alltraps
80106d47:	e9 f6 f5 ff ff       	jmp    80106342 <alltraps>

80106d4c <vector103>:
.globl vector103
vector103:
  pushl $0
80106d4c:	6a 00                	push   $0x0
  pushl $103
80106d4e:	6a 67                	push   $0x67
  jmp alltraps
80106d50:	e9 ed f5 ff ff       	jmp    80106342 <alltraps>

80106d55 <vector104>:
.globl vector104
vector104:
  pushl $0
80106d55:	6a 00                	push   $0x0
  pushl $104
80106d57:	6a 68                	push   $0x68
  jmp alltraps
80106d59:	e9 e4 f5 ff ff       	jmp    80106342 <alltraps>

80106d5e <vector105>:
.globl vector105
vector105:
  pushl $0
80106d5e:	6a 00                	push   $0x0
  pushl $105
80106d60:	6a 69                	push   $0x69
  jmp alltraps
80106d62:	e9 db f5 ff ff       	jmp    80106342 <alltraps>

80106d67 <vector106>:
.globl vector106
vector106:
  pushl $0
80106d67:	6a 00                	push   $0x0
  pushl $106
80106d69:	6a 6a                	push   $0x6a
  jmp alltraps
80106d6b:	e9 d2 f5 ff ff       	jmp    80106342 <alltraps>

80106d70 <vector107>:
.globl vector107
vector107:
  pushl $0
80106d70:	6a 00                	push   $0x0
  pushl $107
80106d72:	6a 6b                	push   $0x6b
  jmp alltraps
80106d74:	e9 c9 f5 ff ff       	jmp    80106342 <alltraps>

80106d79 <vector108>:
.globl vector108
vector108:
  pushl $0
80106d79:	6a 00                	push   $0x0
  pushl $108
80106d7b:	6a 6c                	push   $0x6c
  jmp alltraps
80106d7d:	e9 c0 f5 ff ff       	jmp    80106342 <alltraps>

80106d82 <vector109>:
.globl vector109
vector109:
  pushl $0
80106d82:	6a 00                	push   $0x0
  pushl $109
80106d84:	6a 6d                	push   $0x6d
  jmp alltraps
80106d86:	e9 b7 f5 ff ff       	jmp    80106342 <alltraps>

80106d8b <vector110>:
.globl vector110
vector110:
  pushl $0
80106d8b:	6a 00                	push   $0x0
  pushl $110
80106d8d:	6a 6e                	push   $0x6e
  jmp alltraps
80106d8f:	e9 ae f5 ff ff       	jmp    80106342 <alltraps>

80106d94 <vector111>:
.globl vector111
vector111:
  pushl $0
80106d94:	6a 00                	push   $0x0
  pushl $111
80106d96:	6a 6f                	push   $0x6f
  jmp alltraps
80106d98:	e9 a5 f5 ff ff       	jmp    80106342 <alltraps>

80106d9d <vector112>:
.globl vector112
vector112:
  pushl $0
80106d9d:	6a 00                	push   $0x0
  pushl $112
80106d9f:	6a 70                	push   $0x70
  jmp alltraps
80106da1:	e9 9c f5 ff ff       	jmp    80106342 <alltraps>

80106da6 <vector113>:
.globl vector113
vector113:
  pushl $0
80106da6:	6a 00                	push   $0x0
  pushl $113
80106da8:	6a 71                	push   $0x71
  jmp alltraps
80106daa:	e9 93 f5 ff ff       	jmp    80106342 <alltraps>

80106daf <vector114>:
.globl vector114
vector114:
  pushl $0
80106daf:	6a 00                	push   $0x0
  pushl $114
80106db1:	6a 72                	push   $0x72
  jmp alltraps
80106db3:	e9 8a f5 ff ff       	jmp    80106342 <alltraps>

80106db8 <vector115>:
.globl vector115
vector115:
  pushl $0
80106db8:	6a 00                	push   $0x0
  pushl $115
80106dba:	6a 73                	push   $0x73
  jmp alltraps
80106dbc:	e9 81 f5 ff ff       	jmp    80106342 <alltraps>

80106dc1 <vector116>:
.globl vector116
vector116:
  pushl $0
80106dc1:	6a 00                	push   $0x0
  pushl $116
80106dc3:	6a 74                	push   $0x74
  jmp alltraps
80106dc5:	e9 78 f5 ff ff       	jmp    80106342 <alltraps>

80106dca <vector117>:
.globl vector117
vector117:
  pushl $0
80106dca:	6a 00                	push   $0x0
  pushl $117
80106dcc:	6a 75                	push   $0x75
  jmp alltraps
80106dce:	e9 6f f5 ff ff       	jmp    80106342 <alltraps>

80106dd3 <vector118>:
.globl vector118
vector118:
  pushl $0
80106dd3:	6a 00                	push   $0x0
  pushl $118
80106dd5:	6a 76                	push   $0x76
  jmp alltraps
80106dd7:	e9 66 f5 ff ff       	jmp    80106342 <alltraps>

80106ddc <vector119>:
.globl vector119
vector119:
  pushl $0
80106ddc:	6a 00                	push   $0x0
  pushl $119
80106dde:	6a 77                	push   $0x77
  jmp alltraps
80106de0:	e9 5d f5 ff ff       	jmp    80106342 <alltraps>

80106de5 <vector120>:
.globl vector120
vector120:
  pushl $0
80106de5:	6a 00                	push   $0x0
  pushl $120
80106de7:	6a 78                	push   $0x78
  jmp alltraps
80106de9:	e9 54 f5 ff ff       	jmp    80106342 <alltraps>

80106dee <vector121>:
.globl vector121
vector121:
  pushl $0
80106dee:	6a 00                	push   $0x0
  pushl $121
80106df0:	6a 79                	push   $0x79
  jmp alltraps
80106df2:	e9 4b f5 ff ff       	jmp    80106342 <alltraps>

80106df7 <vector122>:
.globl vector122
vector122:
  pushl $0
80106df7:	6a 00                	push   $0x0
  pushl $122
80106df9:	6a 7a                	push   $0x7a
  jmp alltraps
80106dfb:	e9 42 f5 ff ff       	jmp    80106342 <alltraps>

80106e00 <vector123>:
.globl vector123
vector123:
  pushl $0
80106e00:	6a 00                	push   $0x0
  pushl $123
80106e02:	6a 7b                	push   $0x7b
  jmp alltraps
80106e04:	e9 39 f5 ff ff       	jmp    80106342 <alltraps>

80106e09 <vector124>:
.globl vector124
vector124:
  pushl $0
80106e09:	6a 00                	push   $0x0
  pushl $124
80106e0b:	6a 7c                	push   $0x7c
  jmp alltraps
80106e0d:	e9 30 f5 ff ff       	jmp    80106342 <alltraps>

80106e12 <vector125>:
.globl vector125
vector125:
  pushl $0
80106e12:	6a 00                	push   $0x0
  pushl $125
80106e14:	6a 7d                	push   $0x7d
  jmp alltraps
80106e16:	e9 27 f5 ff ff       	jmp    80106342 <alltraps>

80106e1b <vector126>:
.globl vector126
vector126:
  pushl $0
80106e1b:	6a 00                	push   $0x0
  pushl $126
80106e1d:	6a 7e                	push   $0x7e
  jmp alltraps
80106e1f:	e9 1e f5 ff ff       	jmp    80106342 <alltraps>

80106e24 <vector127>:
.globl vector127
vector127:
  pushl $0
80106e24:	6a 00                	push   $0x0
  pushl $127
80106e26:	6a 7f                	push   $0x7f
  jmp alltraps
80106e28:	e9 15 f5 ff ff       	jmp    80106342 <alltraps>

80106e2d <vector128>:
.globl vector128
vector128:
  pushl $0
80106e2d:	6a 00                	push   $0x0
  pushl $128
80106e2f:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106e34:	e9 09 f5 ff ff       	jmp    80106342 <alltraps>

80106e39 <vector129>:
.globl vector129
vector129:
  pushl $0
80106e39:	6a 00                	push   $0x0
  pushl $129
80106e3b:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106e40:	e9 fd f4 ff ff       	jmp    80106342 <alltraps>

80106e45 <vector130>:
.globl vector130
vector130:
  pushl $0
80106e45:	6a 00                	push   $0x0
  pushl $130
80106e47:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106e4c:	e9 f1 f4 ff ff       	jmp    80106342 <alltraps>

80106e51 <vector131>:
.globl vector131
vector131:
  pushl $0
80106e51:	6a 00                	push   $0x0
  pushl $131
80106e53:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106e58:	e9 e5 f4 ff ff       	jmp    80106342 <alltraps>

80106e5d <vector132>:
.globl vector132
vector132:
  pushl $0
80106e5d:	6a 00                	push   $0x0
  pushl $132
80106e5f:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106e64:	e9 d9 f4 ff ff       	jmp    80106342 <alltraps>

80106e69 <vector133>:
.globl vector133
vector133:
  pushl $0
80106e69:	6a 00                	push   $0x0
  pushl $133
80106e6b:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106e70:	e9 cd f4 ff ff       	jmp    80106342 <alltraps>

80106e75 <vector134>:
.globl vector134
vector134:
  pushl $0
80106e75:	6a 00                	push   $0x0
  pushl $134
80106e77:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106e7c:	e9 c1 f4 ff ff       	jmp    80106342 <alltraps>

80106e81 <vector135>:
.globl vector135
vector135:
  pushl $0
80106e81:	6a 00                	push   $0x0
  pushl $135
80106e83:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106e88:	e9 b5 f4 ff ff       	jmp    80106342 <alltraps>

80106e8d <vector136>:
.globl vector136
vector136:
  pushl $0
80106e8d:	6a 00                	push   $0x0
  pushl $136
80106e8f:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106e94:	e9 a9 f4 ff ff       	jmp    80106342 <alltraps>

80106e99 <vector137>:
.globl vector137
vector137:
  pushl $0
80106e99:	6a 00                	push   $0x0
  pushl $137
80106e9b:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106ea0:	e9 9d f4 ff ff       	jmp    80106342 <alltraps>

80106ea5 <vector138>:
.globl vector138
vector138:
  pushl $0
80106ea5:	6a 00                	push   $0x0
  pushl $138
80106ea7:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106eac:	e9 91 f4 ff ff       	jmp    80106342 <alltraps>

80106eb1 <vector139>:
.globl vector139
vector139:
  pushl $0
80106eb1:	6a 00                	push   $0x0
  pushl $139
80106eb3:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106eb8:	e9 85 f4 ff ff       	jmp    80106342 <alltraps>

80106ebd <vector140>:
.globl vector140
vector140:
  pushl $0
80106ebd:	6a 00                	push   $0x0
  pushl $140
80106ebf:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106ec4:	e9 79 f4 ff ff       	jmp    80106342 <alltraps>

80106ec9 <vector141>:
.globl vector141
vector141:
  pushl $0
80106ec9:	6a 00                	push   $0x0
  pushl $141
80106ecb:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106ed0:	e9 6d f4 ff ff       	jmp    80106342 <alltraps>

80106ed5 <vector142>:
.globl vector142
vector142:
  pushl $0
80106ed5:	6a 00                	push   $0x0
  pushl $142
80106ed7:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106edc:	e9 61 f4 ff ff       	jmp    80106342 <alltraps>

80106ee1 <vector143>:
.globl vector143
vector143:
  pushl $0
80106ee1:	6a 00                	push   $0x0
  pushl $143
80106ee3:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106ee8:	e9 55 f4 ff ff       	jmp    80106342 <alltraps>

80106eed <vector144>:
.globl vector144
vector144:
  pushl $0
80106eed:	6a 00                	push   $0x0
  pushl $144
80106eef:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106ef4:	e9 49 f4 ff ff       	jmp    80106342 <alltraps>

80106ef9 <vector145>:
.globl vector145
vector145:
  pushl $0
80106ef9:	6a 00                	push   $0x0
  pushl $145
80106efb:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106f00:	e9 3d f4 ff ff       	jmp    80106342 <alltraps>

80106f05 <vector146>:
.globl vector146
vector146:
  pushl $0
80106f05:	6a 00                	push   $0x0
  pushl $146
80106f07:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106f0c:	e9 31 f4 ff ff       	jmp    80106342 <alltraps>

80106f11 <vector147>:
.globl vector147
vector147:
  pushl $0
80106f11:	6a 00                	push   $0x0
  pushl $147
80106f13:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106f18:	e9 25 f4 ff ff       	jmp    80106342 <alltraps>

80106f1d <vector148>:
.globl vector148
vector148:
  pushl $0
80106f1d:	6a 00                	push   $0x0
  pushl $148
80106f1f:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106f24:	e9 19 f4 ff ff       	jmp    80106342 <alltraps>

80106f29 <vector149>:
.globl vector149
vector149:
  pushl $0
80106f29:	6a 00                	push   $0x0
  pushl $149
80106f2b:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106f30:	e9 0d f4 ff ff       	jmp    80106342 <alltraps>

80106f35 <vector150>:
.globl vector150
vector150:
  pushl $0
80106f35:	6a 00                	push   $0x0
  pushl $150
80106f37:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106f3c:	e9 01 f4 ff ff       	jmp    80106342 <alltraps>

80106f41 <vector151>:
.globl vector151
vector151:
  pushl $0
80106f41:	6a 00                	push   $0x0
  pushl $151
80106f43:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106f48:	e9 f5 f3 ff ff       	jmp    80106342 <alltraps>

80106f4d <vector152>:
.globl vector152
vector152:
  pushl $0
80106f4d:	6a 00                	push   $0x0
  pushl $152
80106f4f:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106f54:	e9 e9 f3 ff ff       	jmp    80106342 <alltraps>

80106f59 <vector153>:
.globl vector153
vector153:
  pushl $0
80106f59:	6a 00                	push   $0x0
  pushl $153
80106f5b:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106f60:	e9 dd f3 ff ff       	jmp    80106342 <alltraps>

80106f65 <vector154>:
.globl vector154
vector154:
  pushl $0
80106f65:	6a 00                	push   $0x0
  pushl $154
80106f67:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106f6c:	e9 d1 f3 ff ff       	jmp    80106342 <alltraps>

80106f71 <vector155>:
.globl vector155
vector155:
  pushl $0
80106f71:	6a 00                	push   $0x0
  pushl $155
80106f73:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106f78:	e9 c5 f3 ff ff       	jmp    80106342 <alltraps>

80106f7d <vector156>:
.globl vector156
vector156:
  pushl $0
80106f7d:	6a 00                	push   $0x0
  pushl $156
80106f7f:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106f84:	e9 b9 f3 ff ff       	jmp    80106342 <alltraps>

80106f89 <vector157>:
.globl vector157
vector157:
  pushl $0
80106f89:	6a 00                	push   $0x0
  pushl $157
80106f8b:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106f90:	e9 ad f3 ff ff       	jmp    80106342 <alltraps>

80106f95 <vector158>:
.globl vector158
vector158:
  pushl $0
80106f95:	6a 00                	push   $0x0
  pushl $158
80106f97:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106f9c:	e9 a1 f3 ff ff       	jmp    80106342 <alltraps>

80106fa1 <vector159>:
.globl vector159
vector159:
  pushl $0
80106fa1:	6a 00                	push   $0x0
  pushl $159
80106fa3:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106fa8:	e9 95 f3 ff ff       	jmp    80106342 <alltraps>

80106fad <vector160>:
.globl vector160
vector160:
  pushl $0
80106fad:	6a 00                	push   $0x0
  pushl $160
80106faf:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106fb4:	e9 89 f3 ff ff       	jmp    80106342 <alltraps>

80106fb9 <vector161>:
.globl vector161
vector161:
  pushl $0
80106fb9:	6a 00                	push   $0x0
  pushl $161
80106fbb:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106fc0:	e9 7d f3 ff ff       	jmp    80106342 <alltraps>

80106fc5 <vector162>:
.globl vector162
vector162:
  pushl $0
80106fc5:	6a 00                	push   $0x0
  pushl $162
80106fc7:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106fcc:	e9 71 f3 ff ff       	jmp    80106342 <alltraps>

80106fd1 <vector163>:
.globl vector163
vector163:
  pushl $0
80106fd1:	6a 00                	push   $0x0
  pushl $163
80106fd3:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106fd8:	e9 65 f3 ff ff       	jmp    80106342 <alltraps>

80106fdd <vector164>:
.globl vector164
vector164:
  pushl $0
80106fdd:	6a 00                	push   $0x0
  pushl $164
80106fdf:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106fe4:	e9 59 f3 ff ff       	jmp    80106342 <alltraps>

80106fe9 <vector165>:
.globl vector165
vector165:
  pushl $0
80106fe9:	6a 00                	push   $0x0
  pushl $165
80106feb:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106ff0:	e9 4d f3 ff ff       	jmp    80106342 <alltraps>

80106ff5 <vector166>:
.globl vector166
vector166:
  pushl $0
80106ff5:	6a 00                	push   $0x0
  pushl $166
80106ff7:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106ffc:	e9 41 f3 ff ff       	jmp    80106342 <alltraps>

80107001 <vector167>:
.globl vector167
vector167:
  pushl $0
80107001:	6a 00                	push   $0x0
  pushl $167
80107003:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107008:	e9 35 f3 ff ff       	jmp    80106342 <alltraps>

8010700d <vector168>:
.globl vector168
vector168:
  pushl $0
8010700d:	6a 00                	push   $0x0
  pushl $168
8010700f:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107014:	e9 29 f3 ff ff       	jmp    80106342 <alltraps>

80107019 <vector169>:
.globl vector169
vector169:
  pushl $0
80107019:	6a 00                	push   $0x0
  pushl $169
8010701b:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107020:	e9 1d f3 ff ff       	jmp    80106342 <alltraps>

80107025 <vector170>:
.globl vector170
vector170:
  pushl $0
80107025:	6a 00                	push   $0x0
  pushl $170
80107027:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010702c:	e9 11 f3 ff ff       	jmp    80106342 <alltraps>

80107031 <vector171>:
.globl vector171
vector171:
  pushl $0
80107031:	6a 00                	push   $0x0
  pushl $171
80107033:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107038:	e9 05 f3 ff ff       	jmp    80106342 <alltraps>

8010703d <vector172>:
.globl vector172
vector172:
  pushl $0
8010703d:	6a 00                	push   $0x0
  pushl $172
8010703f:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107044:	e9 f9 f2 ff ff       	jmp    80106342 <alltraps>

80107049 <vector173>:
.globl vector173
vector173:
  pushl $0
80107049:	6a 00                	push   $0x0
  pushl $173
8010704b:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107050:	e9 ed f2 ff ff       	jmp    80106342 <alltraps>

80107055 <vector174>:
.globl vector174
vector174:
  pushl $0
80107055:	6a 00                	push   $0x0
  pushl $174
80107057:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010705c:	e9 e1 f2 ff ff       	jmp    80106342 <alltraps>

80107061 <vector175>:
.globl vector175
vector175:
  pushl $0
80107061:	6a 00                	push   $0x0
  pushl $175
80107063:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107068:	e9 d5 f2 ff ff       	jmp    80106342 <alltraps>

8010706d <vector176>:
.globl vector176
vector176:
  pushl $0
8010706d:	6a 00                	push   $0x0
  pushl $176
8010706f:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107074:	e9 c9 f2 ff ff       	jmp    80106342 <alltraps>

80107079 <vector177>:
.globl vector177
vector177:
  pushl $0
80107079:	6a 00                	push   $0x0
  pushl $177
8010707b:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107080:	e9 bd f2 ff ff       	jmp    80106342 <alltraps>

80107085 <vector178>:
.globl vector178
vector178:
  pushl $0
80107085:	6a 00                	push   $0x0
  pushl $178
80107087:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010708c:	e9 b1 f2 ff ff       	jmp    80106342 <alltraps>

80107091 <vector179>:
.globl vector179
vector179:
  pushl $0
80107091:	6a 00                	push   $0x0
  pushl $179
80107093:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107098:	e9 a5 f2 ff ff       	jmp    80106342 <alltraps>

8010709d <vector180>:
.globl vector180
vector180:
  pushl $0
8010709d:	6a 00                	push   $0x0
  pushl $180
8010709f:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801070a4:	e9 99 f2 ff ff       	jmp    80106342 <alltraps>

801070a9 <vector181>:
.globl vector181
vector181:
  pushl $0
801070a9:	6a 00                	push   $0x0
  pushl $181
801070ab:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801070b0:	e9 8d f2 ff ff       	jmp    80106342 <alltraps>

801070b5 <vector182>:
.globl vector182
vector182:
  pushl $0
801070b5:	6a 00                	push   $0x0
  pushl $182
801070b7:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801070bc:	e9 81 f2 ff ff       	jmp    80106342 <alltraps>

801070c1 <vector183>:
.globl vector183
vector183:
  pushl $0
801070c1:	6a 00                	push   $0x0
  pushl $183
801070c3:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801070c8:	e9 75 f2 ff ff       	jmp    80106342 <alltraps>

801070cd <vector184>:
.globl vector184
vector184:
  pushl $0
801070cd:	6a 00                	push   $0x0
  pushl $184
801070cf:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801070d4:	e9 69 f2 ff ff       	jmp    80106342 <alltraps>

801070d9 <vector185>:
.globl vector185
vector185:
  pushl $0
801070d9:	6a 00                	push   $0x0
  pushl $185
801070db:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801070e0:	e9 5d f2 ff ff       	jmp    80106342 <alltraps>

801070e5 <vector186>:
.globl vector186
vector186:
  pushl $0
801070e5:	6a 00                	push   $0x0
  pushl $186
801070e7:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801070ec:	e9 51 f2 ff ff       	jmp    80106342 <alltraps>

801070f1 <vector187>:
.globl vector187
vector187:
  pushl $0
801070f1:	6a 00                	push   $0x0
  pushl $187
801070f3:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801070f8:	e9 45 f2 ff ff       	jmp    80106342 <alltraps>

801070fd <vector188>:
.globl vector188
vector188:
  pushl $0
801070fd:	6a 00                	push   $0x0
  pushl $188
801070ff:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107104:	e9 39 f2 ff ff       	jmp    80106342 <alltraps>

80107109 <vector189>:
.globl vector189
vector189:
  pushl $0
80107109:	6a 00                	push   $0x0
  pushl $189
8010710b:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107110:	e9 2d f2 ff ff       	jmp    80106342 <alltraps>

80107115 <vector190>:
.globl vector190
vector190:
  pushl $0
80107115:	6a 00                	push   $0x0
  pushl $190
80107117:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010711c:	e9 21 f2 ff ff       	jmp    80106342 <alltraps>

80107121 <vector191>:
.globl vector191
vector191:
  pushl $0
80107121:	6a 00                	push   $0x0
  pushl $191
80107123:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107128:	e9 15 f2 ff ff       	jmp    80106342 <alltraps>

8010712d <vector192>:
.globl vector192
vector192:
  pushl $0
8010712d:	6a 00                	push   $0x0
  pushl $192
8010712f:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107134:	e9 09 f2 ff ff       	jmp    80106342 <alltraps>

80107139 <vector193>:
.globl vector193
vector193:
  pushl $0
80107139:	6a 00                	push   $0x0
  pushl $193
8010713b:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107140:	e9 fd f1 ff ff       	jmp    80106342 <alltraps>

80107145 <vector194>:
.globl vector194
vector194:
  pushl $0
80107145:	6a 00                	push   $0x0
  pushl $194
80107147:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010714c:	e9 f1 f1 ff ff       	jmp    80106342 <alltraps>

80107151 <vector195>:
.globl vector195
vector195:
  pushl $0
80107151:	6a 00                	push   $0x0
  pushl $195
80107153:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107158:	e9 e5 f1 ff ff       	jmp    80106342 <alltraps>

8010715d <vector196>:
.globl vector196
vector196:
  pushl $0
8010715d:	6a 00                	push   $0x0
  pushl $196
8010715f:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107164:	e9 d9 f1 ff ff       	jmp    80106342 <alltraps>

80107169 <vector197>:
.globl vector197
vector197:
  pushl $0
80107169:	6a 00                	push   $0x0
  pushl $197
8010716b:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107170:	e9 cd f1 ff ff       	jmp    80106342 <alltraps>

80107175 <vector198>:
.globl vector198
vector198:
  pushl $0
80107175:	6a 00                	push   $0x0
  pushl $198
80107177:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010717c:	e9 c1 f1 ff ff       	jmp    80106342 <alltraps>

80107181 <vector199>:
.globl vector199
vector199:
  pushl $0
80107181:	6a 00                	push   $0x0
  pushl $199
80107183:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107188:	e9 b5 f1 ff ff       	jmp    80106342 <alltraps>

8010718d <vector200>:
.globl vector200
vector200:
  pushl $0
8010718d:	6a 00                	push   $0x0
  pushl $200
8010718f:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107194:	e9 a9 f1 ff ff       	jmp    80106342 <alltraps>

80107199 <vector201>:
.globl vector201
vector201:
  pushl $0
80107199:	6a 00                	push   $0x0
  pushl $201
8010719b:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801071a0:	e9 9d f1 ff ff       	jmp    80106342 <alltraps>

801071a5 <vector202>:
.globl vector202
vector202:
  pushl $0
801071a5:	6a 00                	push   $0x0
  pushl $202
801071a7:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801071ac:	e9 91 f1 ff ff       	jmp    80106342 <alltraps>

801071b1 <vector203>:
.globl vector203
vector203:
  pushl $0
801071b1:	6a 00                	push   $0x0
  pushl $203
801071b3:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801071b8:	e9 85 f1 ff ff       	jmp    80106342 <alltraps>

801071bd <vector204>:
.globl vector204
vector204:
  pushl $0
801071bd:	6a 00                	push   $0x0
  pushl $204
801071bf:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801071c4:	e9 79 f1 ff ff       	jmp    80106342 <alltraps>

801071c9 <vector205>:
.globl vector205
vector205:
  pushl $0
801071c9:	6a 00                	push   $0x0
  pushl $205
801071cb:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801071d0:	e9 6d f1 ff ff       	jmp    80106342 <alltraps>

801071d5 <vector206>:
.globl vector206
vector206:
  pushl $0
801071d5:	6a 00                	push   $0x0
  pushl $206
801071d7:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801071dc:	e9 61 f1 ff ff       	jmp    80106342 <alltraps>

801071e1 <vector207>:
.globl vector207
vector207:
  pushl $0
801071e1:	6a 00                	push   $0x0
  pushl $207
801071e3:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801071e8:	e9 55 f1 ff ff       	jmp    80106342 <alltraps>

801071ed <vector208>:
.globl vector208
vector208:
  pushl $0
801071ed:	6a 00                	push   $0x0
  pushl $208
801071ef:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801071f4:	e9 49 f1 ff ff       	jmp    80106342 <alltraps>

801071f9 <vector209>:
.globl vector209
vector209:
  pushl $0
801071f9:	6a 00                	push   $0x0
  pushl $209
801071fb:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107200:	e9 3d f1 ff ff       	jmp    80106342 <alltraps>

80107205 <vector210>:
.globl vector210
vector210:
  pushl $0
80107205:	6a 00                	push   $0x0
  pushl $210
80107207:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010720c:	e9 31 f1 ff ff       	jmp    80106342 <alltraps>

80107211 <vector211>:
.globl vector211
vector211:
  pushl $0
80107211:	6a 00                	push   $0x0
  pushl $211
80107213:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107218:	e9 25 f1 ff ff       	jmp    80106342 <alltraps>

8010721d <vector212>:
.globl vector212
vector212:
  pushl $0
8010721d:	6a 00                	push   $0x0
  pushl $212
8010721f:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107224:	e9 19 f1 ff ff       	jmp    80106342 <alltraps>

80107229 <vector213>:
.globl vector213
vector213:
  pushl $0
80107229:	6a 00                	push   $0x0
  pushl $213
8010722b:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107230:	e9 0d f1 ff ff       	jmp    80106342 <alltraps>

80107235 <vector214>:
.globl vector214
vector214:
  pushl $0
80107235:	6a 00                	push   $0x0
  pushl $214
80107237:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010723c:	e9 01 f1 ff ff       	jmp    80106342 <alltraps>

80107241 <vector215>:
.globl vector215
vector215:
  pushl $0
80107241:	6a 00                	push   $0x0
  pushl $215
80107243:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107248:	e9 f5 f0 ff ff       	jmp    80106342 <alltraps>

8010724d <vector216>:
.globl vector216
vector216:
  pushl $0
8010724d:	6a 00                	push   $0x0
  pushl $216
8010724f:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107254:	e9 e9 f0 ff ff       	jmp    80106342 <alltraps>

80107259 <vector217>:
.globl vector217
vector217:
  pushl $0
80107259:	6a 00                	push   $0x0
  pushl $217
8010725b:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107260:	e9 dd f0 ff ff       	jmp    80106342 <alltraps>

80107265 <vector218>:
.globl vector218
vector218:
  pushl $0
80107265:	6a 00                	push   $0x0
  pushl $218
80107267:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010726c:	e9 d1 f0 ff ff       	jmp    80106342 <alltraps>

80107271 <vector219>:
.globl vector219
vector219:
  pushl $0
80107271:	6a 00                	push   $0x0
  pushl $219
80107273:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107278:	e9 c5 f0 ff ff       	jmp    80106342 <alltraps>

8010727d <vector220>:
.globl vector220
vector220:
  pushl $0
8010727d:	6a 00                	push   $0x0
  pushl $220
8010727f:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107284:	e9 b9 f0 ff ff       	jmp    80106342 <alltraps>

80107289 <vector221>:
.globl vector221
vector221:
  pushl $0
80107289:	6a 00                	push   $0x0
  pushl $221
8010728b:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107290:	e9 ad f0 ff ff       	jmp    80106342 <alltraps>

80107295 <vector222>:
.globl vector222
vector222:
  pushl $0
80107295:	6a 00                	push   $0x0
  pushl $222
80107297:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010729c:	e9 a1 f0 ff ff       	jmp    80106342 <alltraps>

801072a1 <vector223>:
.globl vector223
vector223:
  pushl $0
801072a1:	6a 00                	push   $0x0
  pushl $223
801072a3:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801072a8:	e9 95 f0 ff ff       	jmp    80106342 <alltraps>

801072ad <vector224>:
.globl vector224
vector224:
  pushl $0
801072ad:	6a 00                	push   $0x0
  pushl $224
801072af:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801072b4:	e9 89 f0 ff ff       	jmp    80106342 <alltraps>

801072b9 <vector225>:
.globl vector225
vector225:
  pushl $0
801072b9:	6a 00                	push   $0x0
  pushl $225
801072bb:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801072c0:	e9 7d f0 ff ff       	jmp    80106342 <alltraps>

801072c5 <vector226>:
.globl vector226
vector226:
  pushl $0
801072c5:	6a 00                	push   $0x0
  pushl $226
801072c7:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801072cc:	e9 71 f0 ff ff       	jmp    80106342 <alltraps>

801072d1 <vector227>:
.globl vector227
vector227:
  pushl $0
801072d1:	6a 00                	push   $0x0
  pushl $227
801072d3:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801072d8:	e9 65 f0 ff ff       	jmp    80106342 <alltraps>

801072dd <vector228>:
.globl vector228
vector228:
  pushl $0
801072dd:	6a 00                	push   $0x0
  pushl $228
801072df:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801072e4:	e9 59 f0 ff ff       	jmp    80106342 <alltraps>

801072e9 <vector229>:
.globl vector229
vector229:
  pushl $0
801072e9:	6a 00                	push   $0x0
  pushl $229
801072eb:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801072f0:	e9 4d f0 ff ff       	jmp    80106342 <alltraps>

801072f5 <vector230>:
.globl vector230
vector230:
  pushl $0
801072f5:	6a 00                	push   $0x0
  pushl $230
801072f7:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801072fc:	e9 41 f0 ff ff       	jmp    80106342 <alltraps>

80107301 <vector231>:
.globl vector231
vector231:
  pushl $0
80107301:	6a 00                	push   $0x0
  pushl $231
80107303:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107308:	e9 35 f0 ff ff       	jmp    80106342 <alltraps>

8010730d <vector232>:
.globl vector232
vector232:
  pushl $0
8010730d:	6a 00                	push   $0x0
  pushl $232
8010730f:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107314:	e9 29 f0 ff ff       	jmp    80106342 <alltraps>

80107319 <vector233>:
.globl vector233
vector233:
  pushl $0
80107319:	6a 00                	push   $0x0
  pushl $233
8010731b:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107320:	e9 1d f0 ff ff       	jmp    80106342 <alltraps>

80107325 <vector234>:
.globl vector234
vector234:
  pushl $0
80107325:	6a 00                	push   $0x0
  pushl $234
80107327:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010732c:	e9 11 f0 ff ff       	jmp    80106342 <alltraps>

80107331 <vector235>:
.globl vector235
vector235:
  pushl $0
80107331:	6a 00                	push   $0x0
  pushl $235
80107333:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107338:	e9 05 f0 ff ff       	jmp    80106342 <alltraps>

8010733d <vector236>:
.globl vector236
vector236:
  pushl $0
8010733d:	6a 00                	push   $0x0
  pushl $236
8010733f:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107344:	e9 f9 ef ff ff       	jmp    80106342 <alltraps>

80107349 <vector237>:
.globl vector237
vector237:
  pushl $0
80107349:	6a 00                	push   $0x0
  pushl $237
8010734b:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107350:	e9 ed ef ff ff       	jmp    80106342 <alltraps>

80107355 <vector238>:
.globl vector238
vector238:
  pushl $0
80107355:	6a 00                	push   $0x0
  pushl $238
80107357:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010735c:	e9 e1 ef ff ff       	jmp    80106342 <alltraps>

80107361 <vector239>:
.globl vector239
vector239:
  pushl $0
80107361:	6a 00                	push   $0x0
  pushl $239
80107363:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107368:	e9 d5 ef ff ff       	jmp    80106342 <alltraps>

8010736d <vector240>:
.globl vector240
vector240:
  pushl $0
8010736d:	6a 00                	push   $0x0
  pushl $240
8010736f:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107374:	e9 c9 ef ff ff       	jmp    80106342 <alltraps>

80107379 <vector241>:
.globl vector241
vector241:
  pushl $0
80107379:	6a 00                	push   $0x0
  pushl $241
8010737b:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107380:	e9 bd ef ff ff       	jmp    80106342 <alltraps>

80107385 <vector242>:
.globl vector242
vector242:
  pushl $0
80107385:	6a 00                	push   $0x0
  pushl $242
80107387:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010738c:	e9 b1 ef ff ff       	jmp    80106342 <alltraps>

80107391 <vector243>:
.globl vector243
vector243:
  pushl $0
80107391:	6a 00                	push   $0x0
  pushl $243
80107393:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107398:	e9 a5 ef ff ff       	jmp    80106342 <alltraps>

8010739d <vector244>:
.globl vector244
vector244:
  pushl $0
8010739d:	6a 00                	push   $0x0
  pushl $244
8010739f:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801073a4:	e9 99 ef ff ff       	jmp    80106342 <alltraps>

801073a9 <vector245>:
.globl vector245
vector245:
  pushl $0
801073a9:	6a 00                	push   $0x0
  pushl $245
801073ab:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801073b0:	e9 8d ef ff ff       	jmp    80106342 <alltraps>

801073b5 <vector246>:
.globl vector246
vector246:
  pushl $0
801073b5:	6a 00                	push   $0x0
  pushl $246
801073b7:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801073bc:	e9 81 ef ff ff       	jmp    80106342 <alltraps>

801073c1 <vector247>:
.globl vector247
vector247:
  pushl $0
801073c1:	6a 00                	push   $0x0
  pushl $247
801073c3:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801073c8:	e9 75 ef ff ff       	jmp    80106342 <alltraps>

801073cd <vector248>:
.globl vector248
vector248:
  pushl $0
801073cd:	6a 00                	push   $0x0
  pushl $248
801073cf:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801073d4:	e9 69 ef ff ff       	jmp    80106342 <alltraps>

801073d9 <vector249>:
.globl vector249
vector249:
  pushl $0
801073d9:	6a 00                	push   $0x0
  pushl $249
801073db:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801073e0:	e9 5d ef ff ff       	jmp    80106342 <alltraps>

801073e5 <vector250>:
.globl vector250
vector250:
  pushl $0
801073e5:	6a 00                	push   $0x0
  pushl $250
801073e7:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801073ec:	e9 51 ef ff ff       	jmp    80106342 <alltraps>

801073f1 <vector251>:
.globl vector251
vector251:
  pushl $0
801073f1:	6a 00                	push   $0x0
  pushl $251
801073f3:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801073f8:	e9 45 ef ff ff       	jmp    80106342 <alltraps>

801073fd <vector252>:
.globl vector252
vector252:
  pushl $0
801073fd:	6a 00                	push   $0x0
  pushl $252
801073ff:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107404:	e9 39 ef ff ff       	jmp    80106342 <alltraps>

80107409 <vector253>:
.globl vector253
vector253:
  pushl $0
80107409:	6a 00                	push   $0x0
  pushl $253
8010740b:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107410:	e9 2d ef ff ff       	jmp    80106342 <alltraps>

80107415 <vector254>:
.globl vector254
vector254:
  pushl $0
80107415:	6a 00                	push   $0x0
  pushl $254
80107417:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010741c:	e9 21 ef ff ff       	jmp    80106342 <alltraps>

80107421 <vector255>:
.globl vector255
vector255:
  pushl $0
80107421:	6a 00                	push   $0x0
  pushl $255
80107423:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107428:	e9 15 ef ff ff       	jmp    80106342 <alltraps>

8010742d <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010742d:	55                   	push   %ebp
8010742e:	89 e5                	mov    %esp,%ebp
80107430:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107433:	8b 45 0c             	mov    0xc(%ebp),%eax
80107436:	83 e8 01             	sub    $0x1,%eax
80107439:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010743d:	8b 45 08             	mov    0x8(%ebp),%eax
80107440:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107444:	8b 45 08             	mov    0x8(%ebp),%eax
80107447:	c1 e8 10             	shr    $0x10,%eax
8010744a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010744e:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107451:	0f 01 10             	lgdtl  (%eax)
}
80107454:	c9                   	leave  
80107455:	c3                   	ret    

80107456 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107456:	55                   	push   %ebp
80107457:	89 e5                	mov    %esp,%ebp
80107459:	83 ec 04             	sub    $0x4,%esp
8010745c:	8b 45 08             	mov    0x8(%ebp),%eax
8010745f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107463:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107467:	0f 00 d8             	ltr    %ax
}
8010746a:	c9                   	leave  
8010746b:	c3                   	ret    

8010746c <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010746c:	55                   	push   %ebp
8010746d:	89 e5                	mov    %esp,%ebp
8010746f:	83 ec 04             	sub    $0x4,%esp
80107472:	8b 45 08             	mov    0x8(%ebp),%eax
80107475:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107479:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010747d:	8e e8                	mov    %eax,%gs
}
8010747f:	c9                   	leave  
80107480:	c3                   	ret    

80107481 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107481:	55                   	push   %ebp
80107482:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107484:	8b 45 08             	mov    0x8(%ebp),%eax
80107487:	0f 22 d8             	mov    %eax,%cr3
}
8010748a:	5d                   	pop    %ebp
8010748b:	c3                   	ret    

8010748c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010748c:	55                   	push   %ebp
8010748d:	89 e5                	mov    %esp,%ebp
8010748f:	8b 45 08             	mov    0x8(%ebp),%eax
80107492:	05 00 00 00 80       	add    $0x80000000,%eax
80107497:	5d                   	pop    %ebp
80107498:	c3                   	ret    

80107499 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107499:	55                   	push   %ebp
8010749a:	89 e5                	mov    %esp,%ebp
8010749c:	8b 45 08             	mov    0x8(%ebp),%eax
8010749f:	05 00 00 00 80       	add    $0x80000000,%eax
801074a4:	5d                   	pop    %ebp
801074a5:	c3                   	ret    

801074a6 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801074a6:	55                   	push   %ebp
801074a7:	89 e5                	mov    %esp,%ebp
801074a9:	53                   	push   %ebx
801074aa:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801074ad:	e8 5f bc ff ff       	call   80103111 <cpunum>
801074b2:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801074b8:	05 20 f9 10 80       	add    $0x8010f920,%eax
801074bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801074c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c3:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801074c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074cc:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801074d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d5:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801074d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074dc:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074e0:	83 e2 f0             	and    $0xfffffff0,%edx
801074e3:	83 ca 0a             	or     $0xa,%edx
801074e6:	88 50 7d             	mov    %dl,0x7d(%eax)
801074e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ec:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074f0:	83 ca 10             	or     $0x10,%edx
801074f3:	88 50 7d             	mov    %dl,0x7d(%eax)
801074f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f9:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074fd:	83 e2 9f             	and    $0xffffff9f,%edx
80107500:	88 50 7d             	mov    %dl,0x7d(%eax)
80107503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107506:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010750a:	83 ca 80             	or     $0xffffff80,%edx
8010750d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107510:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107513:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107517:	83 ca 0f             	or     $0xf,%edx
8010751a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010751d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107520:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107524:	83 e2 ef             	and    $0xffffffef,%edx
80107527:	88 50 7e             	mov    %dl,0x7e(%eax)
8010752a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010752d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107531:	83 e2 df             	and    $0xffffffdf,%edx
80107534:	88 50 7e             	mov    %dl,0x7e(%eax)
80107537:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010753a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010753e:	83 ca 40             	or     $0x40,%edx
80107541:	88 50 7e             	mov    %dl,0x7e(%eax)
80107544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107547:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010754b:	83 ca 80             	or     $0xffffff80,%edx
8010754e:	88 50 7e             	mov    %dl,0x7e(%eax)
80107551:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107554:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107558:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010755b:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107562:	ff ff 
80107564:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107567:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010756e:	00 00 
80107570:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107573:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010757a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010757d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107584:	83 e2 f0             	and    $0xfffffff0,%edx
80107587:	83 ca 02             	or     $0x2,%edx
8010758a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107590:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107593:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010759a:	83 ca 10             	or     $0x10,%edx
8010759d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075a6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075ad:	83 e2 9f             	and    $0xffffff9f,%edx
801075b0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075c0:	83 ca 80             	or     $0xffffff80,%edx
801075c3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075cc:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075d3:	83 ca 0f             	or     $0xf,%edx
801075d6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075df:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075e6:	83 e2 ef             	and    $0xffffffef,%edx
801075e9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075f2:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075f9:	83 e2 df             	and    $0xffffffdf,%edx
801075fc:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107602:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107605:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010760c:	83 ca 40             	or     $0x40,%edx
8010760f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107615:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107618:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010761f:	83 ca 80             	or     $0xffffff80,%edx
80107622:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107628:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010762b:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107635:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010763c:	ff ff 
8010763e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107641:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107648:	00 00 
8010764a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764d:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107654:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107657:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010765e:	83 e2 f0             	and    $0xfffffff0,%edx
80107661:	83 ca 0a             	or     $0xa,%edx
80107664:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010766a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010766d:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107674:	83 ca 10             	or     $0x10,%edx
80107677:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010767d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107680:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107687:	83 ca 60             	or     $0x60,%edx
8010768a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107690:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107693:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010769a:	83 ca 80             	or     $0xffffff80,%edx
8010769d:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801076a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a6:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076ad:	83 ca 0f             	or     $0xf,%edx
801076b0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076c0:	83 e2 ef             	and    $0xffffffef,%edx
801076c3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076cc:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076d3:	83 e2 df             	and    $0xffffffdf,%edx
801076d6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076df:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076e6:	83 ca 40             	or     $0x40,%edx
801076e9:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f2:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076f9:	83 ca 80             	or     $0xffffff80,%edx
801076fc:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107702:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107705:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010770c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770f:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107716:	ff ff 
80107718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010771b:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107722:	00 00 
80107724:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107727:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010772e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107731:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107738:	83 e2 f0             	and    $0xfffffff0,%edx
8010773b:	83 ca 02             	or     $0x2,%edx
8010773e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107744:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107747:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010774e:	83 ca 10             	or     $0x10,%edx
80107751:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107761:	83 ca 60             	or     $0x60,%edx
80107764:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010776a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010776d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107774:	83 ca 80             	or     $0xffffff80,%edx
80107777:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010777d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107780:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107787:	83 ca 0f             	or     $0xf,%edx
8010778a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107793:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010779a:	83 e2 ef             	and    $0xffffffef,%edx
8010779d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077ad:	83 e2 df             	and    $0xffffffdf,%edx
801077b0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077c0:	83 ca 40             	or     $0x40,%edx
801077c3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077cc:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077d3:	83 ca 80             	or     $0xffffff80,%edx
801077d6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077df:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801077e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e9:	05 b4 00 00 00       	add    $0xb4,%eax
801077ee:	89 c3                	mov    %eax,%ebx
801077f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f3:	05 b4 00 00 00       	add    $0xb4,%eax
801077f8:	c1 e8 10             	shr    $0x10,%eax
801077fb:	89 c1                	mov    %eax,%ecx
801077fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107800:	05 b4 00 00 00       	add    $0xb4,%eax
80107805:	c1 e8 18             	shr    $0x18,%eax
80107808:	89 c2                	mov    %eax,%edx
8010780a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780d:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107814:	00 00 
80107816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107819:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107820:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107823:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107833:	83 e1 f0             	and    $0xfffffff0,%ecx
80107836:	83 c9 02             	or     $0x2,%ecx
80107839:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010783f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107842:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107849:	83 c9 10             	or     $0x10,%ecx
8010784c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107852:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107855:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010785c:	83 e1 9f             	and    $0xffffff9f,%ecx
8010785f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107868:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010786f:	83 c9 80             	or     $0xffffff80,%ecx
80107872:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010787b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107882:	83 e1 f0             	and    $0xfffffff0,%ecx
80107885:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010788b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010788e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107895:	83 e1 ef             	and    $0xffffffef,%ecx
80107898:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010789e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078a8:	83 e1 df             	and    $0xffffffdf,%ecx
801078ab:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078bb:	83 c9 40             	or     $0x40,%ecx
801078be:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078ce:	83 c9 80             	or     $0xffffff80,%ecx
801078d1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078da:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801078e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e3:	83 c0 70             	add    $0x70,%eax
801078e6:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801078ed:	00 
801078ee:	89 04 24             	mov    %eax,(%esp)
801078f1:	e8 37 fb ff ff       	call   8010742d <lgdt>
  loadgs(SEG_KCPU << 3);
801078f6:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801078fd:	e8 6a fb ff ff       	call   8010746c <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107902:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107905:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010790b:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107912:	00 00 00 00 
}
80107916:	83 c4 24             	add    $0x24,%esp
80107919:	5b                   	pop    %ebx
8010791a:	5d                   	pop    %ebp
8010791b:	c3                   	ret    

8010791c <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010791c:	55                   	push   %ebp
8010791d:	89 e5                	mov    %esp,%ebp
8010791f:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107922:	8b 45 0c             	mov    0xc(%ebp),%eax
80107925:	c1 e8 16             	shr    $0x16,%eax
80107928:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010792f:	8b 45 08             	mov    0x8(%ebp),%eax
80107932:	01 d0                	add    %edx,%eax
80107934:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107937:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010793a:	8b 00                	mov    (%eax),%eax
8010793c:	83 e0 01             	and    $0x1,%eax
8010793f:	85 c0                	test   %eax,%eax
80107941:	74 17                	je     8010795a <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107943:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107946:	8b 00                	mov    (%eax),%eax
80107948:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010794d:	89 04 24             	mov    %eax,(%esp)
80107950:	e8 44 fb ff ff       	call   80107499 <p2v>
80107955:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107958:	eb 4b                	jmp    801079a5 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010795a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010795e:	74 0e                	je     8010796e <walkpgdir+0x52>
80107960:	e8 33 b4 ff ff       	call   80102d98 <kalloc>
80107965:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107968:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010796c:	75 07                	jne    80107975 <walkpgdir+0x59>
      return 0;
8010796e:	b8 00 00 00 00       	mov    $0x0,%eax
80107973:	eb 47                	jmp    801079bc <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107975:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010797c:	00 
8010797d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107984:	00 
80107985:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107988:	89 04 24             	mov    %eax,(%esp)
8010798b:	e8 f0 d5 ff ff       	call   80104f80 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107993:	89 04 24             	mov    %eax,(%esp)
80107996:	e8 f1 fa ff ff       	call   8010748c <v2p>
8010799b:	83 c8 07             	or     $0x7,%eax
8010799e:	89 c2                	mov    %eax,%edx
801079a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079a3:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801079a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801079a8:	c1 e8 0c             	shr    $0xc,%eax
801079ab:	25 ff 03 00 00       	and    $0x3ff,%eax
801079b0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801079b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ba:	01 d0                	add    %edx,%eax
}
801079bc:	c9                   	leave  
801079bd:	c3                   	ret    

801079be <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801079be:	55                   	push   %ebp
801079bf:	89 e5                	mov    %esp,%ebp
801079c1:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801079c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801079c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801079cf:	8b 55 0c             	mov    0xc(%ebp),%edx
801079d2:	8b 45 10             	mov    0x10(%ebp),%eax
801079d5:	01 d0                	add    %edx,%eax
801079d7:	83 e8 01             	sub    $0x1,%eax
801079da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079df:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801079e2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801079e9:	00 
801079ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801079f1:	8b 45 08             	mov    0x8(%ebp),%eax
801079f4:	89 04 24             	mov    %eax,(%esp)
801079f7:	e8 20 ff ff ff       	call   8010791c <walkpgdir>
801079fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801079ff:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107a03:	75 07                	jne    80107a0c <mappages+0x4e>
      return -1;
80107a05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a0a:	eb 48                	jmp    80107a54 <mappages+0x96>
    if(*pte & PTE_P)
80107a0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a0f:	8b 00                	mov    (%eax),%eax
80107a11:	83 e0 01             	and    $0x1,%eax
80107a14:	85 c0                	test   %eax,%eax
80107a16:	74 0c                	je     80107a24 <mappages+0x66>
      panic("remap");
80107a18:	c7 04 24 40 88 10 80 	movl   $0x80108840,(%esp)
80107a1f:	e8 16 8b ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107a24:	8b 45 18             	mov    0x18(%ebp),%eax
80107a27:	0b 45 14             	or     0x14(%ebp),%eax
80107a2a:	83 c8 01             	or     $0x1,%eax
80107a2d:	89 c2                	mov    %eax,%edx
80107a2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a32:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a37:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107a3a:	75 08                	jne    80107a44 <mappages+0x86>
      break;
80107a3c:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107a3d:	b8 00 00 00 00       	mov    $0x0,%eax
80107a42:	eb 10                	jmp    80107a54 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107a44:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107a4b:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107a52:	eb 8e                	jmp    801079e2 <mappages+0x24>
  return 0;
}
80107a54:	c9                   	leave  
80107a55:	c3                   	ret    

80107a56 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107a56:	55                   	push   %ebp
80107a57:	89 e5                	mov    %esp,%ebp
80107a59:	53                   	push   %ebx
80107a5a:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107a5d:	e8 36 b3 ff ff       	call   80102d98 <kalloc>
80107a62:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107a65:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107a69:	75 0a                	jne    80107a75 <setupkvm+0x1f>
    return 0;
80107a6b:	b8 00 00 00 00       	mov    $0x0,%eax
80107a70:	e9 98 00 00 00       	jmp    80107b0d <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107a75:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107a7c:	00 
80107a7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a84:	00 
80107a85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a88:	89 04 24             	mov    %eax,(%esp)
80107a8b:	e8 f0 d4 ff ff       	call   80104f80 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107a90:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107a97:	e8 fd f9 ff ff       	call   80107499 <p2v>
80107a9c:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107aa1:	76 0c                	jbe    80107aaf <setupkvm+0x59>
    panic("PHYSTOP too high");
80107aa3:	c7 04 24 46 88 10 80 	movl   $0x80108846,(%esp)
80107aaa:	e8 8b 8a ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107aaf:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107ab6:	eb 49                	jmp    80107b01 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107abb:	8b 48 0c             	mov    0xc(%eax),%ecx
80107abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac1:	8b 50 04             	mov    0x4(%eax),%edx
80107ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac7:	8b 58 08             	mov    0x8(%eax),%ebx
80107aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107acd:	8b 40 04             	mov    0x4(%eax),%eax
80107ad0:	29 c3                	sub    %eax,%ebx
80107ad2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad5:	8b 00                	mov    (%eax),%eax
80107ad7:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107adb:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107adf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ae7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107aea:	89 04 24             	mov    %eax,(%esp)
80107aed:	e8 cc fe ff ff       	call   801079be <mappages>
80107af2:	85 c0                	test   %eax,%eax
80107af4:	79 07                	jns    80107afd <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107af6:	b8 00 00 00 00       	mov    $0x0,%eax
80107afb:	eb 10                	jmp    80107b0d <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107afd:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107b01:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107b08:	72 ae                	jb     80107ab8 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107b0d:	83 c4 34             	add    $0x34,%esp
80107b10:	5b                   	pop    %ebx
80107b11:	5d                   	pop    %ebp
80107b12:	c3                   	ret    

80107b13 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107b13:	55                   	push   %ebp
80107b14:	89 e5                	mov    %esp,%ebp
80107b16:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107b19:	e8 38 ff ff ff       	call   80107a56 <setupkvm>
80107b1e:	a3 f8 26 11 80       	mov    %eax,0x801126f8
  switchkvm();
80107b23:	e8 02 00 00 00       	call   80107b2a <switchkvm>
}
80107b28:	c9                   	leave  
80107b29:	c3                   	ret    

80107b2a <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107b2a:	55                   	push   %ebp
80107b2b:	89 e5                	mov    %esp,%ebp
80107b2d:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107b30:	a1 f8 26 11 80       	mov    0x801126f8,%eax
80107b35:	89 04 24             	mov    %eax,(%esp)
80107b38:	e8 4f f9 ff ff       	call   8010748c <v2p>
80107b3d:	89 04 24             	mov    %eax,(%esp)
80107b40:	e8 3c f9 ff ff       	call   80107481 <lcr3>
}
80107b45:	c9                   	leave  
80107b46:	c3                   	ret    

80107b47 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107b47:	55                   	push   %ebp
80107b48:	89 e5                	mov    %esp,%ebp
80107b4a:	53                   	push   %ebx
80107b4b:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107b4e:	e8 2d d3 ff ff       	call   80104e80 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107b53:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b59:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b60:	83 c2 08             	add    $0x8,%edx
80107b63:	89 d3                	mov    %edx,%ebx
80107b65:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b6c:	83 c2 08             	add    $0x8,%edx
80107b6f:	c1 ea 10             	shr    $0x10,%edx
80107b72:	89 d1                	mov    %edx,%ecx
80107b74:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b7b:	83 c2 08             	add    $0x8,%edx
80107b7e:	c1 ea 18             	shr    $0x18,%edx
80107b81:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107b88:	67 00 
80107b8a:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107b91:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107b97:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b9e:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ba1:	83 c9 09             	or     $0x9,%ecx
80107ba4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107baa:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bb1:	83 c9 10             	or     $0x10,%ecx
80107bb4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bba:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bc1:	83 e1 9f             	and    $0xffffff9f,%ecx
80107bc4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bca:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bd1:	83 c9 80             	or     $0xffffff80,%ecx
80107bd4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bda:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107be1:	83 e1 f0             	and    $0xfffffff0,%ecx
80107be4:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bea:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bf1:	83 e1 ef             	and    $0xffffffef,%ecx
80107bf4:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bfa:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c01:	83 e1 df             	and    $0xffffffdf,%ecx
80107c04:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c0a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c11:	83 c9 40             	or     $0x40,%ecx
80107c14:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c1a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c21:	83 e1 7f             	and    $0x7f,%ecx
80107c24:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c2a:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107c30:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c36:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107c3d:	83 e2 ef             	and    $0xffffffef,%edx
80107c40:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107c46:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c4c:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107c52:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c58:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107c5f:	8b 52 08             	mov    0x8(%edx),%edx
80107c62:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107c68:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107c6b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107c72:	e8 df f7 ff ff       	call   80107456 <ltr>
  if(p->pgdir == 0)
80107c77:	8b 45 08             	mov    0x8(%ebp),%eax
80107c7a:	8b 40 04             	mov    0x4(%eax),%eax
80107c7d:	85 c0                	test   %eax,%eax
80107c7f:	75 0c                	jne    80107c8d <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107c81:	c7 04 24 57 88 10 80 	movl   $0x80108857,(%esp)
80107c88:	e8 ad 88 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107c8d:	8b 45 08             	mov    0x8(%ebp),%eax
80107c90:	8b 40 04             	mov    0x4(%eax),%eax
80107c93:	89 04 24             	mov    %eax,(%esp)
80107c96:	e8 f1 f7 ff ff       	call   8010748c <v2p>
80107c9b:	89 04 24             	mov    %eax,(%esp)
80107c9e:	e8 de f7 ff ff       	call   80107481 <lcr3>
  popcli();
80107ca3:	e8 1c d2 ff ff       	call   80104ec4 <popcli>
}
80107ca8:	83 c4 14             	add    $0x14,%esp
80107cab:	5b                   	pop    %ebx
80107cac:	5d                   	pop    %ebp
80107cad:	c3                   	ret    

80107cae <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107cae:	55                   	push   %ebp
80107caf:	89 e5                	mov    %esp,%ebp
80107cb1:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107cb4:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107cbb:	76 0c                	jbe    80107cc9 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107cbd:	c7 04 24 6b 88 10 80 	movl   $0x8010886b,(%esp)
80107cc4:	e8 71 88 ff ff       	call   8010053a <panic>
  mem = kalloc();
80107cc9:	e8 ca b0 ff ff       	call   80102d98 <kalloc>
80107cce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107cd1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107cd8:	00 
80107cd9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ce0:	00 
80107ce1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce4:	89 04 24             	mov    %eax,(%esp)
80107ce7:	e8 94 d2 ff ff       	call   80104f80 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cef:	89 04 24             	mov    %eax,(%esp)
80107cf2:	e8 95 f7 ff ff       	call   8010748c <v2p>
80107cf7:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107cfe:	00 
80107cff:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107d03:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d0a:	00 
80107d0b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d12:	00 
80107d13:	8b 45 08             	mov    0x8(%ebp),%eax
80107d16:	89 04 24             	mov    %eax,(%esp)
80107d19:	e8 a0 fc ff ff       	call   801079be <mappages>
  memmove(mem, init, sz);
80107d1e:	8b 45 10             	mov    0x10(%ebp),%eax
80107d21:	89 44 24 08          	mov    %eax,0x8(%esp)
80107d25:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d28:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d2f:	89 04 24             	mov    %eax,(%esp)
80107d32:	e8 18 d3 ff ff       	call   8010504f <memmove>
}
80107d37:	c9                   	leave  
80107d38:	c3                   	ret    

80107d39 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107d39:	55                   	push   %ebp
80107d3a:	89 e5                	mov    %esp,%ebp
80107d3c:	53                   	push   %ebx
80107d3d:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107d40:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d43:	25 ff 0f 00 00       	and    $0xfff,%eax
80107d48:	85 c0                	test   %eax,%eax
80107d4a:	74 0c                	je     80107d58 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107d4c:	c7 04 24 88 88 10 80 	movl   $0x80108888,(%esp)
80107d53:	e8 e2 87 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107d58:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d5f:	e9 a9 00 00 00       	jmp    80107e0d <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107d64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d67:	8b 55 0c             	mov    0xc(%ebp),%edx
80107d6a:	01 d0                	add    %edx,%eax
80107d6c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107d73:	00 
80107d74:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d78:	8b 45 08             	mov    0x8(%ebp),%eax
80107d7b:	89 04 24             	mov    %eax,(%esp)
80107d7e:	e8 99 fb ff ff       	call   8010791c <walkpgdir>
80107d83:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d86:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d8a:	75 0c                	jne    80107d98 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107d8c:	c7 04 24 ab 88 10 80 	movl   $0x801088ab,(%esp)
80107d93:	e8 a2 87 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80107d98:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d9b:	8b 00                	mov    (%eax),%eax
80107d9d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107da2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da8:	8b 55 18             	mov    0x18(%ebp),%edx
80107dab:	29 c2                	sub    %eax,%edx
80107dad:	89 d0                	mov    %edx,%eax
80107daf:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107db4:	77 0f                	ja     80107dc5 <loaduvm+0x8c>
      n = sz - i;
80107db6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db9:	8b 55 18             	mov    0x18(%ebp),%edx
80107dbc:	29 c2                	sub    %eax,%edx
80107dbe:	89 d0                	mov    %edx,%eax
80107dc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107dc3:	eb 07                	jmp    80107dcc <loaduvm+0x93>
    else
      n = PGSIZE;
80107dc5:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107dcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dcf:	8b 55 14             	mov    0x14(%ebp),%edx
80107dd2:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107dd5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107dd8:	89 04 24             	mov    %eax,(%esp)
80107ddb:	e8 b9 f6 ff ff       	call   80107499 <p2v>
80107de0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107de3:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107de7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107deb:	89 44 24 04          	mov    %eax,0x4(%esp)
80107def:	8b 45 10             	mov    0x10(%ebp),%eax
80107df2:	89 04 24             	mov    %eax,(%esp)
80107df5:	e8 24 a2 ff ff       	call   8010201e <readi>
80107dfa:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107dfd:	74 07                	je     80107e06 <loaduvm+0xcd>
      return -1;
80107dff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e04:	eb 18                	jmp    80107e1e <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107e06:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e10:	3b 45 18             	cmp    0x18(%ebp),%eax
80107e13:	0f 82 4b ff ff ff    	jb     80107d64 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107e19:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e1e:	83 c4 24             	add    $0x24,%esp
80107e21:	5b                   	pop    %ebx
80107e22:	5d                   	pop    %ebp
80107e23:	c3                   	ret    

80107e24 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e24:	55                   	push   %ebp
80107e25:	89 e5                	mov    %esp,%ebp
80107e27:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107e2a:	8b 45 10             	mov    0x10(%ebp),%eax
80107e2d:	85 c0                	test   %eax,%eax
80107e2f:	79 0a                	jns    80107e3b <allocuvm+0x17>
    return 0;
80107e31:	b8 00 00 00 00       	mov    $0x0,%eax
80107e36:	e9 c1 00 00 00       	jmp    80107efc <allocuvm+0xd8>
  if(newsz < oldsz)
80107e3b:	8b 45 10             	mov    0x10(%ebp),%eax
80107e3e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e41:	73 08                	jae    80107e4b <allocuvm+0x27>
    return oldsz;
80107e43:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e46:	e9 b1 00 00 00       	jmp    80107efc <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107e4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e4e:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e58:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107e5b:	e9 8d 00 00 00       	jmp    80107eed <allocuvm+0xc9>
    mem = kalloc();
80107e60:	e8 33 af ff ff       	call   80102d98 <kalloc>
80107e65:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107e68:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e6c:	75 2c                	jne    80107e9a <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107e6e:	c7 04 24 c9 88 10 80 	movl   $0x801088c9,(%esp)
80107e75:	e8 26 85 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107e7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e7d:	89 44 24 08          	mov    %eax,0x8(%esp)
80107e81:	8b 45 10             	mov    0x10(%ebp),%eax
80107e84:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e88:	8b 45 08             	mov    0x8(%ebp),%eax
80107e8b:	89 04 24             	mov    %eax,(%esp)
80107e8e:	e8 6b 00 00 00       	call   80107efe <deallocuvm>
      return 0;
80107e93:	b8 00 00 00 00       	mov    $0x0,%eax
80107e98:	eb 62                	jmp    80107efc <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107e9a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ea1:	00 
80107ea2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ea9:	00 
80107eaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ead:	89 04 24             	mov    %eax,(%esp)
80107eb0:	e8 cb d0 ff ff       	call   80104f80 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107eb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107eb8:	89 04 24             	mov    %eax,(%esp)
80107ebb:	e8 cc f5 ff ff       	call   8010748c <v2p>
80107ec0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107ec3:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107eca:	00 
80107ecb:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107ecf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ed6:	00 
80107ed7:	89 54 24 04          	mov    %edx,0x4(%esp)
80107edb:	8b 45 08             	mov    0x8(%ebp),%eax
80107ede:	89 04 24             	mov    %eax,(%esp)
80107ee1:	e8 d8 fa ff ff       	call   801079be <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107ee6:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ef0:	3b 45 10             	cmp    0x10(%ebp),%eax
80107ef3:	0f 82 67 ff ff ff    	jb     80107e60 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107ef9:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107efc:	c9                   	leave  
80107efd:	c3                   	ret    

80107efe <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107efe:	55                   	push   %ebp
80107eff:	89 e5                	mov    %esp,%ebp
80107f01:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107f04:	8b 45 10             	mov    0x10(%ebp),%eax
80107f07:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f0a:	72 08                	jb     80107f14 <deallocuvm+0x16>
    return oldsz;
80107f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f0f:	e9 a4 00 00 00       	jmp    80107fb8 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107f14:	8b 45 10             	mov    0x10(%ebp),%eax
80107f17:	05 ff 0f 00 00       	add    $0xfff,%eax
80107f1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f21:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107f24:	e9 80 00 00 00       	jmp    80107fa9 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107f29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f2c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f33:	00 
80107f34:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f38:	8b 45 08             	mov    0x8(%ebp),%eax
80107f3b:	89 04 24             	mov    %eax,(%esp)
80107f3e:	e8 d9 f9 ff ff       	call   8010791c <walkpgdir>
80107f43:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107f46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107f4a:	75 09                	jne    80107f55 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107f4c:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107f53:	eb 4d                	jmp    80107fa2 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107f55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f58:	8b 00                	mov    (%eax),%eax
80107f5a:	83 e0 01             	and    $0x1,%eax
80107f5d:	85 c0                	test   %eax,%eax
80107f5f:	74 41                	je     80107fa2 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107f61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f64:	8b 00                	mov    (%eax),%eax
80107f66:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f6b:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107f6e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f72:	75 0c                	jne    80107f80 <deallocuvm+0x82>
        panic("kfree");
80107f74:	c7 04 24 e1 88 10 80 	movl   $0x801088e1,(%esp)
80107f7b:	e8 ba 85 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80107f80:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f83:	89 04 24             	mov    %eax,(%esp)
80107f86:	e8 0e f5 ff ff       	call   80107499 <p2v>
80107f8b:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107f8e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f91:	89 04 24             	mov    %eax,(%esp)
80107f94:	e8 66 ad ff ff       	call   80102cff <kfree>
      *pte = 0;
80107f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f9c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107fa2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fac:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107faf:	0f 82 74 ff ff ff    	jb     80107f29 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107fb5:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107fb8:	c9                   	leave  
80107fb9:	c3                   	ret    

80107fba <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107fba:	55                   	push   %ebp
80107fbb:	89 e5                	mov    %esp,%ebp
80107fbd:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107fc0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107fc4:	75 0c                	jne    80107fd2 <freevm+0x18>
    panic("freevm: no pgdir");
80107fc6:	c7 04 24 e7 88 10 80 	movl   $0x801088e7,(%esp)
80107fcd:	e8 68 85 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107fd2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107fd9:	00 
80107fda:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107fe1:	80 
80107fe2:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe5:	89 04 24             	mov    %eax,(%esp)
80107fe8:	e8 11 ff ff ff       	call   80107efe <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107fed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107ff4:	eb 48                	jmp    8010803e <freevm+0x84>
    if(pgdir[i] & PTE_P){
80107ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108000:	8b 45 08             	mov    0x8(%ebp),%eax
80108003:	01 d0                	add    %edx,%eax
80108005:	8b 00                	mov    (%eax),%eax
80108007:	83 e0 01             	and    $0x1,%eax
8010800a:	85 c0                	test   %eax,%eax
8010800c:	74 2c                	je     8010803a <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010800e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108011:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108018:	8b 45 08             	mov    0x8(%ebp),%eax
8010801b:	01 d0                	add    %edx,%eax
8010801d:	8b 00                	mov    (%eax),%eax
8010801f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108024:	89 04 24             	mov    %eax,(%esp)
80108027:	e8 6d f4 ff ff       	call   80107499 <p2v>
8010802c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010802f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108032:	89 04 24             	mov    %eax,(%esp)
80108035:	e8 c5 ac ff ff       	call   80102cff <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010803a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010803e:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108045:	76 af                	jbe    80107ff6 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108047:	8b 45 08             	mov    0x8(%ebp),%eax
8010804a:	89 04 24             	mov    %eax,(%esp)
8010804d:	e8 ad ac ff ff       	call   80102cff <kfree>
}
80108052:	c9                   	leave  
80108053:	c3                   	ret    

80108054 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108054:	55                   	push   %ebp
80108055:	89 e5                	mov    %esp,%ebp
80108057:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010805a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108061:	00 
80108062:	8b 45 0c             	mov    0xc(%ebp),%eax
80108065:	89 44 24 04          	mov    %eax,0x4(%esp)
80108069:	8b 45 08             	mov    0x8(%ebp),%eax
8010806c:	89 04 24             	mov    %eax,(%esp)
8010806f:	e8 a8 f8 ff ff       	call   8010791c <walkpgdir>
80108074:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108077:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010807b:	75 0c                	jne    80108089 <clearpteu+0x35>
    panic("clearpteu");
8010807d:	c7 04 24 f8 88 10 80 	movl   $0x801088f8,(%esp)
80108084:	e8 b1 84 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108089:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808c:	8b 00                	mov    (%eax),%eax
8010808e:	83 e0 fb             	and    $0xfffffffb,%eax
80108091:	89 c2                	mov    %eax,%edx
80108093:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108096:	89 10                	mov    %edx,(%eax)
}
80108098:	c9                   	leave  
80108099:	c3                   	ret    

8010809a <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010809a:	55                   	push   %ebp
8010809b:	89 e5                	mov    %esp,%ebp
8010809d:	53                   	push   %ebx
8010809e:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801080a1:	e8 b0 f9 ff ff       	call   80107a56 <setupkvm>
801080a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801080a9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801080ad:	75 0a                	jne    801080b9 <copyuvm+0x1f>
    return 0;
801080af:	b8 00 00 00 00       	mov    $0x0,%eax
801080b4:	e9 fd 00 00 00       	jmp    801081b6 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
801080b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801080c0:	e9 d0 00 00 00       	jmp    80108195 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801080c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080cf:	00 
801080d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d4:	8b 45 08             	mov    0x8(%ebp),%eax
801080d7:	89 04 24             	mov    %eax,(%esp)
801080da:	e8 3d f8 ff ff       	call   8010791c <walkpgdir>
801080df:	89 45 ec             	mov    %eax,-0x14(%ebp)
801080e2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801080e6:	75 0c                	jne    801080f4 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
801080e8:	c7 04 24 02 89 10 80 	movl   $0x80108902,(%esp)
801080ef:	e8 46 84 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
801080f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080f7:	8b 00                	mov    (%eax),%eax
801080f9:	83 e0 01             	and    $0x1,%eax
801080fc:	85 c0                	test   %eax,%eax
801080fe:	75 0c                	jne    8010810c <copyuvm+0x72>
      panic("copyuvm: page not present");
80108100:	c7 04 24 1c 89 10 80 	movl   $0x8010891c,(%esp)
80108107:	e8 2e 84 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
8010810c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010810f:	8b 00                	mov    (%eax),%eax
80108111:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108116:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108119:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010811c:	8b 00                	mov    (%eax),%eax
8010811e:	25 ff 0f 00 00       	and    $0xfff,%eax
80108123:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108126:	e8 6d ac ff ff       	call   80102d98 <kalloc>
8010812b:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010812e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108132:	75 02                	jne    80108136 <copyuvm+0x9c>
      goto bad;
80108134:	eb 70                	jmp    801081a6 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108136:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108139:	89 04 24             	mov    %eax,(%esp)
8010813c:	e8 58 f3 ff ff       	call   80107499 <p2v>
80108141:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108148:	00 
80108149:	89 44 24 04          	mov    %eax,0x4(%esp)
8010814d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108150:	89 04 24             	mov    %eax,(%esp)
80108153:	e8 f7 ce ff ff       	call   8010504f <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108158:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010815b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010815e:	89 04 24             	mov    %eax,(%esp)
80108161:	e8 26 f3 ff ff       	call   8010748c <v2p>
80108166:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108169:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010816d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108171:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108178:	00 
80108179:	89 54 24 04          	mov    %edx,0x4(%esp)
8010817d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108180:	89 04 24             	mov    %eax,(%esp)
80108183:	e8 36 f8 ff ff       	call   801079be <mappages>
80108188:	85 c0                	test   %eax,%eax
8010818a:	79 02                	jns    8010818e <copyuvm+0xf4>
      goto bad;
8010818c:	eb 18                	jmp    801081a6 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010818e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108198:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010819b:	0f 82 24 ff ff ff    	jb     801080c5 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
801081a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081a4:	eb 10                	jmp    801081b6 <copyuvm+0x11c>

bad:
  freevm(d);
801081a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081a9:	89 04 24             	mov    %eax,(%esp)
801081ac:	e8 09 fe ff ff       	call   80107fba <freevm>
  return 0;
801081b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801081b6:	83 c4 44             	add    $0x44,%esp
801081b9:	5b                   	pop    %ebx
801081ba:	5d                   	pop    %ebp
801081bb:	c3                   	ret    

801081bc <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801081bc:	55                   	push   %ebp
801081bd:	89 e5                	mov    %esp,%ebp
801081bf:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801081c2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801081c9:	00 
801081ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801081cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801081d1:	8b 45 08             	mov    0x8(%ebp),%eax
801081d4:	89 04 24             	mov    %eax,(%esp)
801081d7:	e8 40 f7 ff ff       	call   8010791c <walkpgdir>
801081dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801081df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e2:	8b 00                	mov    (%eax),%eax
801081e4:	83 e0 01             	and    $0x1,%eax
801081e7:	85 c0                	test   %eax,%eax
801081e9:	75 07                	jne    801081f2 <uva2ka+0x36>
    return 0;
801081eb:	b8 00 00 00 00       	mov    $0x0,%eax
801081f0:	eb 25                	jmp    80108217 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801081f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f5:	8b 00                	mov    (%eax),%eax
801081f7:	83 e0 04             	and    $0x4,%eax
801081fa:	85 c0                	test   %eax,%eax
801081fc:	75 07                	jne    80108205 <uva2ka+0x49>
    return 0;
801081fe:	b8 00 00 00 00       	mov    $0x0,%eax
80108203:	eb 12                	jmp    80108217 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108205:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108208:	8b 00                	mov    (%eax),%eax
8010820a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010820f:	89 04 24             	mov    %eax,(%esp)
80108212:	e8 82 f2 ff ff       	call   80107499 <p2v>
}
80108217:	c9                   	leave  
80108218:	c3                   	ret    

80108219 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108219:	55                   	push   %ebp
8010821a:	89 e5                	mov    %esp,%ebp
8010821c:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010821f:	8b 45 10             	mov    0x10(%ebp),%eax
80108222:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108225:	e9 87 00 00 00       	jmp    801082b1 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010822a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010822d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108232:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108235:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108238:	89 44 24 04          	mov    %eax,0x4(%esp)
8010823c:	8b 45 08             	mov    0x8(%ebp),%eax
8010823f:	89 04 24             	mov    %eax,(%esp)
80108242:	e8 75 ff ff ff       	call   801081bc <uva2ka>
80108247:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010824a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010824e:	75 07                	jne    80108257 <copyout+0x3e>
      return -1;
80108250:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108255:	eb 69                	jmp    801082c0 <copyout+0xa7>
    n = PGSIZE - (va - va0);
80108257:	8b 45 0c             	mov    0xc(%ebp),%eax
8010825a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010825d:	29 c2                	sub    %eax,%edx
8010825f:	89 d0                	mov    %edx,%eax
80108261:	05 00 10 00 00       	add    $0x1000,%eax
80108266:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108269:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010826c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010826f:	76 06                	jbe    80108277 <copyout+0x5e>
      n = len;
80108271:	8b 45 14             	mov    0x14(%ebp),%eax
80108274:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108277:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010827a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010827d:	29 c2                	sub    %eax,%edx
8010827f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108282:	01 c2                	add    %eax,%edx
80108284:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108287:	89 44 24 08          	mov    %eax,0x8(%esp)
8010828b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108292:	89 14 24             	mov    %edx,(%esp)
80108295:	e8 b5 cd ff ff       	call   8010504f <memmove>
    len -= n;
8010829a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010829d:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801082a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082a3:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801082a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082a9:	05 00 10 00 00       	add    $0x1000,%eax
801082ae:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801082b1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801082b5:	0f 85 6f ff ff ff    	jne    8010822a <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801082bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801082c0:	c9                   	leave  
801082c1:	c3                   	ret    
