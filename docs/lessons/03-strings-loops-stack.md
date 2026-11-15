# Lesson 3: Strings, loops and the stack

## Goal

Print a whole sentence instead of one letter. To do that, we keep a string inside the boot sector, walk through it with a loop, and put the loop in a function we can call.

## What you'll see

```
Booting from Hard Disk...
Hello There
```

The code is still only our 512 bytes and the BIOS. What's new is how it's built: a string, a loop, a function, and a stack for the function to use.

## New words

- **String**: text stored as bytes in memory, one byte per character. Ours ends with a `0` byte, which marks the end.
- **Segment register**: a register that holds the "base" part of an address in real mode, like `ds` or `ss`.
- **Flags**: single bits inside the CPU that describe the result of the last calculation, like "it was zero".
- **Conditional jump**: a jump that only happens when a flag says so, like `je` ("jump if equal").
- **Local label**: a label starting with a dot, like `.loop`, that belongs to the normal label above it.
- **Function**: a piece of code you jump to with `call` and come back from with `ret`.
- **Stack**: a part of memory used like a pile of plates. You put things on top and take them off the top.
- **Stack pointer**: the register `sp`, which holds the address of the top of the stack.
- **Include**: pasting the text of one file into another while building.

They're all in the [glossary](../glossary.md) too.

## The idea

### Text is just bytes

In lesson 2 we saw that a byte has no type. The letter `H` is the byte `0x48`, and a string is just those bytes one after another:

```nasm
msg: db 'Hello There', 0
```

`db` with quotes writes one byte per character, so this line makes 12 bytes: 11 letters and a space, plus a `0`.

In TypeScript, a string knows its own length. Here nothing does. Memory is only a long row of bytes, and nothing marks where our text stops. So we agree on a rule: **the string ends at the first `0` byte**. C strings work the same way.

`msg` is a label, so it's the address of the first byte, the `H`.

There's one more rule: **keep data out of the CPU's way.** The CPU runs every byte it reaches as an instruction, and it can't tell text from code. `0x48`, our `H`, is also the instruction `dec ax` ("subtract 1 from `ax`"). So the string goes after the `hang` loop, where the CPU never arrives.

### An address and the value at it

Think of RAM as one huge array called `memory`. There are two different things you can put in a register:

```nasm
mov si, msg        ; si = the address of the string    (like: si = index)
mov al, [si]       ; al = the byte at that address     (like: al = memory[si])
```

The square brackets mean "go to this address and read what's there". Without them you get the address itself, a plain number.

**This is where `org` starts to matter.** nasm works out `msg` as `org` plus the string's position in the file. Our string is 34 bytes into the file, so `msg` is `0x7C00 + 34 = 0x7C22`. Without `org 0x7C00`, nasm would say `msg` is 34, and `si` would point into the BIOS's table at the start of memory instead of at our text.

### Segments: how 16-bit registers reach 1 MiB

A 16-bit register can only count up to 65,535, which is 64 KiB. But real mode can reach 1 MiB. To get there, the CPU builds every address from two registers:

```
address = segment × 16 + offset
```

The **segment** comes from a segment register, and the **offset** comes from a normal register. When we read `[si]`, the CPU really reads `ds:si`, which means `ds × 16 + si`. `ds` is the *data segment* register, and it's used for reading data unless we say otherwise.

If `ds` is 0, the address is just `si`. That's what we want, because `org` already gave us the full address. But the BIOS doesn't promise what's in `ds` when it jumps to us. QEMU happens to leave a 0 there, but other machines might not. **So we set it ourselves.**

There's one catch: you can't put a number straight into a segment register. `mov ds, 0` isn't a real instruction. You go through another register instead:

```nasm
xor ax, ax         ; ax = 0
mov ds, ax         ; ds = ax
```

`xor ax, ax` is the usual way to write "make `ax` zero". It does the same job as `mov ax, 0`, but in 2 bytes instead of 3.

### Making decisions: flags and jumps

Assembly has no `if` and no `while`. It has **flags** and **jumps** instead.

- `cmp al, 0` subtracts 0 from `al`, throws the answer away and keeps only the flags. If the two values were equal, the answer was zero, so the **zero flag** (ZF) is set to 1.
- `je .done` means "jump to `.done` if equal", which is "if ZF is 1". `jz` ("jump if zero") is the same instruction under another name.
- `jmp .loop` always jumps.

Here's our print loop in TypeScript and in assembly, line by line:

```ts
while (true) {
  const c = memory[si];   // mov al, [ds:si]
  if (c === 0) break;     // cmp al, 0x00   +   je .done
  printChar(c);           // mov ah, 0x0E   +   int 0x10
  si = si + 1;            // inc si
}                         // jmp .loop
```

A loop in assembly is a label at the top, a test that jumps out, and a `jmp` back to the top.

### Functions: `call` and `ret`

We want to print more than one string one day, so the loop goes in a function.

- `call print` jumps to `print`, and before that, it saves the **return address**: the address of the instruction right after the `call`.
- `ret` jumps back to that saved address.

So `ret` needs to find the return address somewhere. That somewhere is the stack.

### The stack

The stack is a piece of normal memory, used like a pile of plates. Two instructions use it:

- `push ax` puts the value of `ax` on top.
- `pop ax` takes the top value off and puts it in `ax`.

Last in, first out. If you push `ax` and then `bx`, you have to pop `bx` first.

The register `sp` (*stack pointer*) holds the address of the top. On x86, the stack **grows down**:

- `push` first does `sp = sp - 2`, then writes 2 bytes at `sp`.
- `pop` reads the 2 bytes at `sp`, then does `sp = sp + 2`.

`call` is really "push the return address, then jump". `ret` is "pop an address, then jump to it".

**Where do we put it?** The full address of the top is `ss:sp`, where `ss` is the *stack segment* register. We use `ss = 0` and `sp = 0x7C00`, which puts the top right below our code:

```
0x00000  +---------------------------+
         | BIOS table and BIOS data  |
0x00500  +---------------------------+
         | free memory               |
         |            ^              |   the stack grows down from 0x7C00
         |            |              |   into this free space
0x07C00  +---------------------------+   <- sp starts here
         | our 512 bytes             |
0x07E00  +---------------------------+
         | more free memory          |
```

The first `push` writes at `0x7BFE`, just below our code, and each push after that goes lower. The stack never grows up into our code.

The BIOS had already set up a stack before it jumped to us, but we don't know where it is or how big it is. And it isn't only `call` that uses the stack: `int 0x10` uses it too, because the CPU saves its place there before it runs the BIOS code. So we set our own.

One detail: `mov sp` comes **right after** `mov ss`. If an interrupt arrived between those two, it would use a stack that's only half set up. The CPU knows this, so it holds back interrupts for one instruction after `mov ss`. That one instruction should be `mov sp`.

### One file inside another: `%include`

`%include "print.asm"` tells nasm to paste the whole text of `print.asm` right there, before it builds anything. It works like `#include` in C++.

Because it's a paste, **where you write it matters.** The pasted code ends up at that exact spot in the sector. If it's in the CPU's path, the CPU walks into the function without calling it. So we put it after the `hang` loop, next to the string.

## Build it

We need one new file, `warmup/print.asm`, and some changes to `warmup/boot.asm`.

### 1. The print function: `warmup/print.asm`

```nasm
print:
  .loop:
    mov al, [ds:si]       ; al = the byte at address ds:si
    cmp al, 0x00          ; is it the 0 at the end?
    je .done              ; yes: we're finished
    mov ah, 0x0E          ; ah = the "print one character" job
    int 0x10              ; call the BIOS video service
    inc si                ; si = si + 1: move to the next character
    jmp .loop             ; go back and do the next one
  .done:
    ret                   ; go back to the line after "call print"
```

- **How to use it:** put the address of a string in `si`, then `call print`. In TypeScript terms, it's `print(si)`, except the argument travels in a register.
- **This file has no `bits`, `org` or padding.** It isn't a program on its own. It only gets pasted into `boot.asm`, which already has those.
- **`.loop` and `.done` are local labels.** They start with a dot, so they belong to `print`, and nasm reads them as `print.loop` and `print.done`. Another function can have its own `.done` without a clash.
- **`[ds:si]`** names the segment out loud. Plain `[si]` means the same thing, because `ds` is the default.
- **`mov ah, 0x0E` is inside the loop**, so it's set again before every `int 0x10`. That way we don't depend on the BIOS leaving `ah` alone.
- **`inc si`** is short for "increment": add 1.

x86 also has an instruction called `lodsb` that does `mov al, [ds:si]` and `inc si` in one go. We used the two plain instructions because they show what's happening. See "Try this".

### 2. Set up the segments and the stack

At the top of `boot.asm`, after `bits 16` and `org 0x7C00`:

```nasm
xor ax, ax                ; ax = 0
mov ss, ax                ; stack segment = 0
mov sp, 0x7C00            ; the stack starts right below our code
mov ds, ax                ; data segment = 0, so [si] means address si
```

### 3. Print the string

```nasm
mov si, msg               ; si = the address of the string
call print                ; print it, then come back here
```

### 4. Stop the CPU

This is the same as in lesson 2:

```nasm
cli
hang:
  hlt
  jmp hang
```

### 5. The function and the data, out of the CPU's way

```nasm
%include "print.asm"      ; paste print.asm here, after the hang loop
msg:
  db 'Hello There', 0     ; the string, with a 0 to mark its end
```

### 6. Fill the sector and sign it

This is the same as in lesson 2, and it must stay at the very end:

```nasm
times 510-($-$$) db 0
dw 0xAA55
```

### The whole file: `warmup/boot.asm`

```nasm
bits 16                   ; real mode: make 16-bit code
org 0x7C00                ; the address this code will be loaded at

xor ax, ax                ; ax = 0
mov ss, ax                ; stack segment = 0
mov sp, 0x7C00            ; the stack starts right below our code
mov ds, ax                ; data segment = 0, so [si] means address si

mov si, msg               ; si = the address of the string
call print                ; print it, then come back here

cli                       ; ignore hardware interrupts
hang:
  hlt                     ; sleep until an interrupt arrives
  jmp hang                ; if something woke us, go back to sleep

%include "print.asm"      ; paste the print function here, out of the CPU's way
msg:
  db 'Hello There', 0     ; the string, with a 0 to mark its end

times 510-($-$$) db 0     ; fill with zeros up to byte 510
dw 0xAA55                 ; the boot signature
```

In the repo, the files have no comments, because this page explains them. The repo also writes the string as numbers: `db 0x48, 0x65, 0x6C, ...`. Those are exactly the same 12 bytes. A byte has no type, so nasm doesn't care how you write it.

## Run it

In the Ubuntu terminal, from the project folder:

```bash
mkdir -p build/warmup
nasm -f bin -i warmup/ warmup/boot.asm -o build/warmup/boot.bin
qemu-system-x86_64 -drive format=raw,file=build/warmup/boot.bin
```

The only new part is `-i warmup/`. nasm looks for `%include` files in the folder you run it from, not in the folder where `boot.asm` lives. We run it from the project folder, so `-i warmup/` tells nasm to look in `warmup/` as well.

`ls -l build/warmup/boot.bin` should still say `512`.

## What just happened

1. The BIOS loaded our 512 bytes to `0x7C00` and jumped there, like in lesson 2.
2. We set `ss`, `sp` and `ds` to values we chose, instead of trusting whatever the BIOS left.
3. `mov si, msg` put `0x7C22`, the address of the `H`, into `si`.
4. `call print` pushed the return address `0x7C0F` onto the stack, so `sp` went from `0x7C00` to `0x7BFE`. Then it jumped to `print`.
5. The loop read `H`, saw that it isn't 0, printed it, and moved `si` to the next byte. It did that 11 times.
6. The 12th byte was the 0, so `je .done` jumped out of the loop.
7. `ret` popped `0x7C0F` off the stack, so `sp` went back to `0x7C00`, and the CPU carried on at `cli`, right after the `call`.
8. `cli` and `hlt` put the CPU to sleep, like before.

### Look at the bytes

`ndisasm` turns bytes back into assembly. `-b 16` means "read it as 16-bit code", and `-o 0x7C00` tells it where the code sits, so the addresses it prints match the real ones:

```bash
ndisasm -b 16 -o 0x7C00 build/warmup/boot.bin | head -20
```

```
00007C00  31C0              xor ax,ax
00007C02  8ED0              mov ss,ax
00007C04  BC007C            mov sp,0x7c00
00007C07  8ED8              mov ds,ax
00007C09  BE227C            mov si,0x7c22
00007C0C  E80400            call 0x7c13
00007C0F  FA                cli
00007C10  F4                hlt
00007C11  EBFD              jmp short 0x7c10
00007C13  3E8A04            mov al,[ds:si]
00007C16  3C00              cmp al,0x0
00007C18  7407              jz 0x7c21
00007C1A  B40E              mov ah,0xe
00007C1C  CD10              int 0x10
00007C1E  46                inc si
00007C1F  EBF2              jmp short 0x7c13
00007C21  C3                ret
00007C22  48                dec ax
00007C23  656C              gs insb
00007C25  6C                insb
```

Each line shows an address, the bytes, and the instruction those bytes mean. A few things to notice:

- **`mov si, msg` became `BE 22 7C`.** The `22 7C` is `0x7C22` stored low byte first, so that's `org` and little-endian together.
- **`call print` became `E8 04 00`.** Like `jmp`, `call` is relative: "jump 4 bytes forward from the next instruction". The next instruction is at `0x7C0F`, and `0x7C0F + 4 = 0x7C13`, which is `print`.
- **`je` shows up as `jz`.** It's the same byte, `74`, with two names.
- **`mov al, [ds:si]` is 3 bytes, `3E 8A 04`.** The `3E` means "use `ds`". `ds` is already the default, so plain `mov al, [si]` gives the same result in 2 bytes.
- **After `ret`, ndisasm reads our string as code.** `48` becomes `dec ax`, and `65 6C` becomes `gs insb`. ndisasm can't tell code from data, and neither can the CPU. That's why the string lives where the CPU never goes.
- **The whole program is 46 bytes:** 34 bytes of code and 12 bytes of string.

## Common problems

- **nasm says ``unable to open include file `print.asm'``.** nasm looks for included files in the folder you run it from. Add `-i warmup/` to the nasm command, as in "Run it".
- **nasm says `comma, colon, decorator or end of line expected after operand`.** A comma is missing between two operands. For example, `cmp al 0` should be `cmp al, 0`.
- **nasm says `invalid combination of opcode and operands`.** This often means a number went straight into a segment register, like `mov ds, 0`. Put the number in `ax` first, then do `mov ds, ax`.
- **The text prints, then the machine does something strange or restarts.** The `%include` is probably above the code that calls `print`. The CPU walks into the function without a `call`, so when it reaches `ret`, there's no return address on the stack. `ret` pops 2 random bytes and jumps there. Move the `%include` below the `hang` loop.
- **Nothing prints, or `ls -l` says more than 512.** Something comes after `dw 0xAA55`, probably the string. The BIOS only loads the first 512 bytes, so anything after the signature never reaches memory. Move the string above the `times` line.
- **Random characters appear instead of the text.** Check that `org 0x7C00` is there. Without it, every address nasm works out is `0x7C00` too low, and `si` points into the BIOS's table instead of our string.
- **It works even without the `0` at the end of the string.** It does, by luck: the padding after the string is all zeros, so the loop stops at the first one anyway. Keep the `0`. Once other data sits right after a string, the loop would print that data too.

## Try this

- **Print two lines.** Change the string to `db 'Hello', 0x0D, 0x0A, 'There', 0`. `0x0D` (CR, *carriage return*) moves the cursor back to the start of the line, and `0x0A` (LF, *line feed*) moves it down one line, like an old typewriter. That's the same CRLF that Windows puts at the end of lines in text files, which we met in lesson 1.
- **Call it twice.** Add a second string, `msg2`, after the first one. Then add `mov si, msg2` and another `call print` before `cli`. That's the point of a function: write the loop once, use it many times.
- **Look at the stack.** With QEMU running, open the monitor (`Ctrl+Alt+2`) and type `info registers`:
  - `ESP` is `00007c00`. `call` pushed one address and `ret` popped it, so `sp` is back where it started.
  - `ESI` is `00007c2d`. That's `0x7C22 + 11`, the address of the 0 at the end of our string, where the loop stopped.
  - `EIP` is `00007c11`, the `jmp` after `hlt`.

  Then type `xp /1xh 0x7bfe`, which means "show 1 two-byte value, in hex, at address `0x7BFE`". It shows `0x7c0f`, our return address, still sitting there. `pop` only moves `sp`. It doesn't erase anything.
- **Use `lodsb`.** In `print.asm`, replace `mov al, [ds:si]` and `inc si` with the single instruction `lodsb` (*load string byte*). It reads the byte at `ds:si` into `al` and adds 1 to `si`. It only counts up if the CPU's *direction flag* is 0, so add `cld` (*clear direction flag*) at the top of `boot.asm`. Rebuild and compare the size of the program with `ndisasm`.
- **Save a register.** Put `push si` between `print:` and `.loop:` (not inside the loop, or it would push once per character), and `pop si` right before `ret`. Now `si` still points at the start of the string after the call, so the caller gets its register back unchanged. Check it with `info registers`.

In lesson 4, we'll stop typing the long nasm and QEMU commands by hand and write our first Makefile.
