# Lesson 2: The first boot sector

## Goal

Write the first 512 bytes that a PC runs from a disk, and use them to print the letter `A`.

## What you'll see

QEMU starts, the BIOS prints a few lines, and then:

```
Booting from Hard Disk...
A
```

That `A` comes from our code. There's no operating system and no bootloader under it. There's only the BIOS and 512 bytes we wrote ourselves.

## New words

- **Instruction**: one command the CPU understands, like "copy this number" or "jump over there".
- **Register**: a tiny storage slot inside the CPU.
- **Real mode**: the old 16-bit mode that every PC starts in.
- **Boot sector**: the first 512 bytes of a disk. The BIOS loads it and runs it.
- **Interrupt**: the CPU pauses what it's doing, runs some other code, then comes back. The `int` instruction asks for one on purpose.
- **Label**: a name for a place in our code.
- **Directive**: a line written for the assembler, not for the CPU.
- **Hexadecimal**: numbers in base 16, written with `0x` in front.
- **Little-endian**: storing a number with its lowest byte first.

They're all in the [glossary](../glossary.md) too.

## The idea

### The CPU in one picture

The CPU only understands bytes. The two bytes `B0 41`, for example, mean "put the number 0x41 into the register `al`". Assembly is a way to write those bytes with short names. We write `mov al, 0x41`, and `nasm` turns it into `B0 41`.

One line of assembly is one instruction. There are no variables, no functions and no types. The whole machine is three things:

- **Registers.** A handful of tiny storage slots inside the CPU, each with a fixed name. They're the fastest memory there is, and the CPU does all its work on them. If you know TypeScript, picture a few global `let` variables that always exist.
- **RAM.** One long row of bytes. If you know TypeScript, picture one huge `Uint8Array`. An **address** is just a position in that row.
- **The instruction pointer**, a register called `ip`. It holds the address of the next instruction.

The CPU does the same thing over and over, forever: read the instruction at `ip`, do it, move `ip` to the next one. Everything else, C++ and the whole OS included, is built on top of that loop.

### Hexadecimal, quickly

Low-level code is full of numbers like `0x7C00`. The `0x` means **hexadecimal**, which counts in base 16. After the digits 0 to 9 come A to F, which stand for 10 to 15.

Why base 16? Because two hex digits make exactly one byte: from `0x00` (0) to `0xFF` (255). That's why every tool shows bytes as pairs of hex digits.

`0x41` is 65, which is the letter `A` in **ASCII**, the old table that gives every English letter, digit and symbol a number.

Hex is only a way to *write* a number, though. It doesn't make the number a letter. A byte has no type, and it means whatever the code reading it decides:

| The byte | Read as ASCII text | Read as an instruction | Read as a number |
|---|---|---|---|
| `0x41` | the letter `A` | `inc cx` (add 1 to `cx`) | 65 |
| `0xF4` | not ASCII (above 127) | `hlt` | 244 |
| `0x0E` | "Shift Out", an old control code for printers | `push cs` (lesson 3 explains `push`) | 14 |

In our file, `0x41` and `0x0E` come right after `b0` and `b4`, so the CPU reads them as the values those `mov` instructions copy, not as instructions of their own. And the BIOS reads `0x0E` in `ah` as a job number, so nobody reads it as text.

### Where we start: real mode

When a PC turns on, even a modern 64-bit CPU behaves like the Intel 8086 from 1978. That's called **real mode**:

- the registers are 16 bits wide
- only 1 MiB of memory can be reached
- there's no protection, so any code can touch anything

PCs still start this way so that old software keeps working. Later we'll leave real mode for 64-bit mode. In lesson 6, the Limine bootloader will do that for us.

### How the BIOS starts our code

When the BIOS has finished checking the machine, it looks for a disk to start from. For each disk it does this:

1. It reads the first 512 bytes of the disk. A 512-byte block is called a **sector**, so this one is the **boot sector**.
2. It checks the last two bytes. If they're `55 AA`, the disk is bootable. This mark is called the **boot signature**.
3. It copies the 512 bytes into memory at address `0x7C00` and jumps there. From that moment, the CPU is running our code.

`0x7C00` looks random. IBM picked it for its first PC in 1981. It's 1 KiB below 32 KiB, which was the least memory that PC needed to start DOS, so the boot sector sat near the top, out of the way. Every PC since has kept it.

### The registers we use

In real mode, `ax` is a 16-bit register. Its two halves have names of their own:

```
ax = [ ah | al ]
      high  low
```

`ah` is the high byte and `al` is the low byte. They aren't separate registers. Writing to `al` changes the low half of `ax`.

There are more registers, like `bx`, `cx`, `dx`, `si`, `di` and `sp`. We'll meet them in lesson 3.

### Asking the BIOS for help

The BIOS doesn't only start the machine. It also stays in memory and offers small services, like "print a character" or "read a disk sector". We call them with the `int` instruction, short for **interrupt**.

`int 0x10` means "run BIOS service number 0x10", which is the video service. The CPU keeps a table at the very start of memory with one address for each number, and the BIOS filled that table in when it started. The CPU looks up entry `0x10`, runs the code there, and comes back to the line after `int`. In lesson 13 we'll build a table like that for our own kernel.

A service needs arguments, but there are no parentheses in assembly. Instead, we put the arguments in registers before the call:

- `ah` picks the job. `0x0E` means "teletype": print one character and move the cursor forward, like a typewriter.
- `al` holds the character to print.

In TypeScript terms, it's like calling `video(0x0E, 'A')`.

### The CPU never stops by itself

There's no "end of program" in machine code. After our last instruction, the CPU would just carry on and run the next bytes in memory as if they were code, whatever they are. Even the zero bytes we pad the sector with are a real instruction: `00 00` means "add `al` to a byte somewhere in memory".

So we stop it ourselves:

- `cli` ("clear interrupts") tells the CPU to ignore interrupts from the hardware, like the timer and the keyboard.
- `hlt` ("halt") puts the CPU to sleep until an interrupt arrives.

`cli` works like a switch, not a timer. Interrupts stay off until an `sti` ("set interrupts") turns them back on, and `hlt` doesn't do that. While they're off, the hardware's requests aren't lost. They wait until interrupts come back on, which for us is never.

So with interrupts off, the CPU should sleep forever. A few interrupts can't be turned off, though, so if one wakes the CPU up, we jump straight back to `hlt`.

Turning interrupts off has another use, which we'll need much later. When the kernel changes something that an interrupt handler also uses, it turns interrupts off for those few lines, so nothing can cut in halfway through.

## Build it

We need one file, `warmup/boot.asm`. The `warmup/` folder holds the first lessons only. It isn't part of the real OS.

Here it is piece by piece. A `;` starts a comment, and everything after it on that line is ignored.

### 1. Tell nasm what we're making

```nasm
bits 16
org 0x7C00
```

These are **directives**. They don't turn into bytes. They're instructions for `nasm` itself.

- `bits 16` means "make 16-bit code", because the CPU is in real mode.
- `org 0x7C00` means "this code will sit at address 0x7C00". Whenever nasm works out the address of something in our file, it adds 0x7C00. We don't use any addresses yet, but in lesson 3 we will.

### 2. Print the letter

```nasm
mov al, 0x41              ; al = 'A'
mov ah, 0x0E              ; ah = the "print one character" job
int 0x10                  ; call the BIOS video service
```

`mov` copies a value. Its order is **destination, then source**, so `mov al, 0x41` reads like `al = 0x41`.

You can also write `mov al, 'A'`. nasm turns the letter into its ASCII number, and the bytes come out the same.

The order of the two `mov` lines doesn't matter. What matters is that both are set before `int 0x10`.

### 3. Stop the CPU

```nasm
cli                       ; ignore hardware interrupts
hang:                     ; a name for the address of the next line
    hlt                   ; sleep until an interrupt arrives
    jmp hang              ; if something woke us, go back to sleep
```

`hang:` is a **label**. It's a name for the address of the instruction after it, like a bookmark. It isn't a function and it doesn't contain anything. The CPU runs from `cli` straight into `hlt` without noticing it's there. A label only matters when something jumps to it.

The usual style is: labels at the start of the line, instructions indented.

### 4. Fill the sector and sign it

```nasm
times 510-($-$$) db 0     ; fill with zeros up to byte 510
dw 0xAA55                 ; the boot signature
```

- `db 0` means "put one byte with the value 0 here" (*define byte*).
- `times N` repeats whatever follows N times.
- `$` is the address of the current line, and `$$` is the address where our code starts. So `$-$$` is how many bytes we've written so far.
- `510-($-$$)` is how many zeros we need to reach byte 510.
- `dw 0xAA55` writes a two-byte value (*define word*). Those are bytes 510 and 511, so the file ends up exactly 512 bytes long.

**Why `0xAA55` and not `0x55AA`?** x86 CPUs are **little-endian**: they store a number with its lowest byte first. The number `0xAA55` is stored as the bytes `55 AA`, and that's the order the BIOS looks for.

### The whole file

```nasm
; The first boot sector: print the letter A, then stop.
; The BIOS loads these 512 bytes to address 0x7C00 and runs them.

bits 16                   ; real mode: make 16-bit code
org 0x7C00                ; the address this code will be loaded at

mov al, 0x41              ; al = 'A' (0x41 in ASCII)
mov ah, 0x0E              ; ah = 0x0E: the BIOS "print one character" job
int 0x10                  ; call the BIOS video service

cli                       ; ignore hardware interrupts
hang:                     ; a name for the address of the next line
    hlt                   ; sleep until an interrupt arrives
    jmp hang              ; if something woke us, go back to sleep

times 510-($-$$) db 0     ; fill with zeros up to byte 510
dw 0xAA55                 ; the boot signature: bytes 510 and 511 are 55 AA
```

Lesson 3 changes this file, so the version in the repo looks different now. The code above is how it looks at the end of this lesson. Write your comments in your own words, because they're your notes.

## Run it

In the Ubuntu terminal, from the project folder:

```bash
mkdir -p build/warmup
nasm -f bin warmup/boot.asm -o build/warmup/boot.bin
qemu-system-x86_64 -drive format=raw,file=build/warmup/boot.bin
```

- `mkdir -p` creates the folder, and its parent folders too. If they already exist, it does nothing.
- `-f bin` tells nasm to write plain bytes, with nothing around them. Later, our kernel will be a file with a header that describes it, but a boot sector is just raw bytes.
- `-o` names the output file.
- `-drive format=raw,file=...` gives QEMU a disk made from our file. `format=raw` says "this is plain bytes". Without it, QEMU has to guess and prints a warning.

To check the size:

```bash
ls -l build/warmup/boot.bin
```

It should say `512`.

## What just happened

1. QEMU turned on a virtual PC, and SeaBIOS started.
2. The BIOS found our disk and read its first 512 bytes.
3. It checked bytes 510 and 511, found `55 AA`, and decided the disk is bootable.
4. It copied the 512 bytes to address `0x7C00` and jumped there. The CPU, still in real mode, started running our code.
5. We put `0x0E` in `ah` and `0x41` in `al`, and called `int 0x10`. The BIOS printed an `A` where the cursor was.
6. `cli` and `hlt` put the CPU to sleep, and it stays asleep until you close the window.

### Look at the bytes

`od` ("octal dump") prints a file as raw bytes. Let's look at what nasm made:

```bash
od -A x -t x1z build/warmup/boot.bin
```

`-A x` shows the positions in hex, and `-t x1z` shows each byte in hex, with the printable characters on the right.

```
000000 b0 41 b4 0e cd 10 fa f4 eb fd 00 00 00 00 00 00  >.A..............<
000010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
0001f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa  >..............U.<
000200
```

Here's each line of our code next to the bytes it became:

| Bytes | Our line |
|---|---|
| `b0 41` | `mov al, 0x41` |
| `b4 0e` | `mov ah, 0x0E` |
| `cd 10` | `int 0x10` |
| `fa` | `cli` |
| `f4` | `hlt` |
| `eb fd` | `jmp hang` |

A few things to notice:

- **The whole program is 10 bytes.** Everything after it is the zeros from `times`, and the last two bytes are `55 aa`, our signature, low byte first.
- **The `*` line** means "the lines here are the same as the one above". `od` skips the repeated rows of zeros.
- **The directives left no bytes.** `bits 16` and `org 0x7C00` changed how nasm built the file, but you won't find them in it.
- **The label is gone too.** `eb` means "short jump", and `fd` is how one byte writes **-3**. So `jmp hang` became "jump back 3 bytes". The jump is measured from the end of the jump instruction itself, so 3 bytes back lands exactly on `f4`, the `hlt`. A jump like this is called *relative*, and it works wherever the code sits in memory.

## Common problems

- **nasm says `error: parser: instruction expected`.** nasm errors show the file, the line number and the problem, like `warmup/boot.asm:5: error: ...`. This one means that line has a word nasm doesn't know as an instruction. It's usually a typo, like `htl` instead of `hlt`.
- **The BIOS says `Boot failed: not a bootable disk`.** The last two bytes aren't `55 AA`. Check that `dw 0xAA55` is the very last line, and that it isn't written as `0x55AA` (see little-endian above).
- **`ls -l` doesn't say 512.** Check that the `times` line uses 510, and that nothing comes after `dw 0xAA55`.
- **QEMU prints `WARNING: Image format was not specified`.** Add `format=raw` to the `-drive` option, as in "Run it".
- **It works even without `bits 16` and `org 0x7C00`.** It does, by luck. `-f bin` makes 16-bit code by default, and `jmp hang` is a relative jump, so it doesn't care where the code sits. Keep both lines anyway. In lesson 3 we print a string, and without `org`, every address nasm works out would be 0x7C00 too low.

## Try this

- **Print your initials.** Repeat the three printing lines with another letter. Rebuild, run, and then use `od` to find which bytes changed.
- **Break the signature.** Change `dw 0xAA55` to `dw 0x55AA`, rebuild and run. The BIOS says `Boot failed: not a bootable disk`. The bytes on disk are now `AA 55`, the wrong order. That's little-endian at work.
- **Look at the registers.** With QEMU running, press `Ctrl+Alt+2` (or pick **View → compatmonitor0**) and type `info registers`.
  - `EAX` ends in `0e41`. That's `ah` (`0e`) and `al` (`41`) side by side, still holding what we put there. `EAX` is the 32-bit version of `ax`.
  - `EIP` is `00007c08`. Our code starts at `0x7C00`, and byte 8 of it is the `jmp`. The CPU is asleep, and `EIP` points to the next instruction it will run when it wakes up.
  - `HLT=1` means the CPU is halted.

  Press `Ctrl+Alt+1` to go back to the screen.

In lesson 3, we'll print a whole sentence with a loop, and meet the stack.
