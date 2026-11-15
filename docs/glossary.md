# Glossary

Every new word from the lessons, in simple terms. The number in brackets is the lesson where the word first shows up.

**Address** (2): a position in memory. Memory is one long row of bytes, and an address says which byte you mean, like an index into an array.

**ASCII** (2): an old table that gives every English letter, digit and symbol a number. `A` is `0x41` (65).

**Assembler** (1): a program that turns assembly language into machine code. We use `nasm`.

**Assembly language** (1): a way to write machine code with short names instead of numbers. `hlt` means "stop the CPU until something happens", and the assembler turns it into the single byte `F4`.

**Binary file** (1): a file that isn't text, like a picture or a program. Its bytes must be kept exactly as they are.

**BIOS** (1): the older kind of firmware in PCs. It runs first when the computer turns on, and its last job is to find something to boot. It also offers small services, like printing a character, that code can call with `int`. QEMU uses an open-source BIOS called SeaBIOS.

**Bit and byte** (2): a bit is a single 0 or 1. A byte is 8 bits, enough for a number from 0 to 255. Memory and files are counted in bytes.

**Boot** (1): starting a computer, from power-on until an operating system is running.

**Boot sector** (2): the first 512 bytes of a disk. The BIOS copies it into memory at address `0x7C00` and runs it.

**Boot signature** (2): the two bytes `55 AA` at the very end of a boot sector. Without them, the BIOS won't boot from the disk.

**Bootloader** (1): a small program that the firmware starts. It loads the kernel into memory and jumps to it. We'll use one called Limine.

**Compiler** (1): a program that turns source code you can read, like C++, into machine code. We use `clang`.

**Conditional jump** (3): a jump that only happens when a flag says so. `je` ("jump if equal") jumps only when the zero flag is 1. It's how assembly writes `if` and `while`.

**CRLF and LF** (1): the invisible characters at the end of each line of text. Windows uses two (CRLF, `\r\n`) and Linux uses one (LF, `\n`). Linux tools can break on CRLF. On the BIOS screen, CR (`0x0D`) moves the cursor back to the start of the line and LF (`0x0A`) moves it down one line.

**Debugger** (1): a program that can pause another program, run it one step at a time, and show its memory and registers. We use `gdb`.

**Directive** (2): a line in an assembly file that's meant for the assembler, not the CPU. `bits 16` and `org 0x7C00` are directives. They change how the file is built, but they don't become instructions.

**Distribution** (1): a kernel plus a large bundle of programs, packaged together so you can install them as one system. Ubuntu is a Linux distribution.

**Emulator** (1): a program that pretends to be a whole computer in software. We use QEMU.

**Firmware** (1): the small program built into a computer that runs first when you turn it on. BIOS and UEFI are the two kinds on PCs.

**Flags** (3): single bits inside the CPU that describe the result of the last calculation. The zero flag (ZF), for example, is 1 when the result was zero. `cmp` sets the flags, and conditional jumps read them.

**Function** (3): a piece of code you jump to with `call` and come back from with `ret`. `call` saves the return address on the stack, and `ret` takes it back off.

**Hexadecimal** (2): counting in base 16, with the digits 0 to 9 and then A to F. It's written with `0x` in front, like `0x7C00`. Two hex digits make exactly one byte, which is why low-level tools show bytes in hex.

**Include** (3): pasting the text of one file into another while building. In nasm it's `%include "file.asm"`, and in C++ it's `#include`.

**Instruction** (2): one command the CPU understands, like "copy this number into a register" or "jump over there". One line of assembly is one instruction.

**Instruction pointer** (2): the register that holds the address of the next instruction the CPU will run. It's called `ip` in 16-bit mode, `eip` in 32-bit mode and `rip` in 64-bit mode.

**Interrupt** (2): the CPU pauses what it's doing, runs some other code, and then comes back. Hardware like the timer or the keyboard causes interrupts, and the `int` instruction causes one on purpose, which is how we call the BIOS.

**ISO file** (1): one file that holds the whole contents of a CD, in a format called ISO 9660. A computer or QEMU can boot from it.

**Kernel** (1): the core of an operating system. It controls the CPU, the memory and the devices, and it runs every program.

**Label** (2): a name for a place in assembly code, like `hang:`. The assembler swaps it for a real address or distance, so it doesn't exist in the finished bytes.

**Linker** (1): a program that joins compiled pieces (object files) into one finished program and connects the calls between them. We use `lld`.

**Little-endian** (2): storing a number with its lowest byte first. x86 CPUs work this way, so the number `0xAA55` is stored as the bytes `55 AA`.

**Local label** (3): a label that starts with a dot, like `.loop`. It belongs to the normal label above it, so nasm reads `.loop` under `print:` as `print.loop`. Two functions can each have their own `.loop`.

**Machine code** (1): the bytes a CPU actually runs. Every other language gets turned into this in the end.

**Object file** (1): the output of compiling or assembling one source file, ending in `.o`. It holds machine code, plus notes about what it still needs from other files.

**Operating system** (1): the software that sits between programs and the hardware. It shares out the CPU and memory, hides the details of each device, and keeps programs from breaking each other.

**Preprocessor** (1): the first step inside the compiler. It removes comments and copies in the files named by `#include`.

**QEMU** (1): the emulator we use. It runs our OS as a virtual PC that starts in a second and can't harm your real computer.

**Real mode** (2): the 16-bit mode every x86 PC starts in, to stay compatible with the Intel 8086 from 1978. Only 1 MiB of memory can be reached, and nothing is protected.

**Register** (1): a tiny, very fast storage slot inside the CPU. The CPU does all its work on registers. In real mode, `ax` is a 16-bit register, and its two halves are called `ah` (the high byte) and `al` (the low byte).

**Sector** (2): a 512-byte block of a disk. Disks are read and written a whole sector at a time.

**Segment register** (3): a register that holds the "base" part of an address in real mode. The CPU builds an address as segment × 16 + offset, so `ds:si` means `ds × 16 + si`. `ds` is used for data and `ss` for the stack.

**Stack** (3): a part of memory used like a pile of plates. `push` puts a value on top and `pop` takes the top value off, last in, first out. On x86 it grows down, toward lower addresses.

**Stack pointer** (3): the register `sp`, which holds the address of the top of the stack. `push` lowers it by 2 and `pop` raises it by 2.

**String** (3): text stored as bytes in memory, one byte per character. Ours end with a `0` byte, because nothing else marks where the text stops.

**Terminal** (1): a window where you type commands instead of clicking.

**UEFI** (1): the newer kind of PC firmware, which has replaced the BIOS on most modern computers.

**WSL** (1): Windows Subsystem for Linux. It runs a real Linux inside Windows.
