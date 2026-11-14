# Glossary

Every new word from the lessons, in simple terms. The number in brackets is the lesson where the word first shows up.

**Assembler** (1): a program that turns assembly language into machine code. We use `nasm`.

**Assembly language** (1): a way to write machine code with short names instead of numbers. `hlt` means "stop the CPU until something happens", and the assembler turns it into the single byte `F4`.

**BIOS** (1): the older kind of firmware in PCs. It runs first when the computer turns on, and its last job is to find something to boot. QEMU uses an open-source one called SeaBIOS.

**Binary file** (1): a file that isn't text, like a picture or a program. Its bytes must be kept exactly as they are.

**Boot** (1): starting a computer, from power-on until an operating system is running.

**Bootloader** (1): a small program that the firmware starts. It loads the kernel into memory and jumps to it. We'll use one called Limine.

**Compiler** (1): a program that turns source code you can read, like C++, into machine code. We use `clang`.

**CRLF and LF** (1): the invisible characters at the end of each line of text. Windows uses two (CRLF, `\r\n`) and Linux uses one (LF, `\n`). Linux tools can break on CRLF.

**Debugger** (1): a program that can pause another program, run it one step at a time, and show its memory and registers. We use `gdb`.

**Distribution** (1): a kernel plus a large bundle of programs, packaged together so you can install them as one system. Ubuntu is a Linux distribution.

**Emulator** (1): a program that pretends to be a whole computer in software. We use QEMU.

**Firmware** (1): the small program built into a computer that runs first when you turn it on. BIOS and UEFI are the two kinds on PCs.

**ISO file** (1): one file that holds the whole contents of a CD, in a format called ISO 9660. A computer or QEMU can boot from it.

**Kernel** (1): the core of an operating system. It controls the CPU, the memory and the devices, and it runs every program.

**Linker** (1): a program that joins compiled pieces (object files) into one finished program and connects the calls between them. We use `lld`.

**Machine code** (1): the bytes a CPU actually runs. Every other language gets turned into this in the end.

**Object file** (1): the output of compiling or assembling one source file, ending in `.o`. It holds machine code, plus notes about what it still needs from other files.

**Operating system** (1): the software that sits between programs and the hardware. It shares out the CPU and memory, hides the details of each device, and keeps programs from breaking each other.

**Preprocessor** (1): the first step inside the compiler. It removes comments and copies in the files named by `#include`.

**QEMU** (1): the emulator we use. It runs our OS as a virtual PC that starts in a second and can't harm your real computer.

**Register** (1): a tiny, very fast storage slot inside the CPU. The CPU does all its work on registers. More on these in lesson 2.

**Terminal** (1): a window where you type commands instead of clicking.

**UEFI** (1): the newer kind of PC firmware, which has replaced the BIOS on most modern computers.

**WSL** (1): Windows Subsystem for Linux. It runs a real Linux inside Windows.
