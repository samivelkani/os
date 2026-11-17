# Roadmap

This is the plan, from an empty folder to version 1.0. Each lesson should take about two days and end with something you can see working. Some will take longer, and that's fine, because understanding comes first.

The plan will change as we learn. When it does, this page changes with it.

## Phase 0: Tools and a warm-up

Before the real kernel, we write a tiny program in pure assembly that the computer runs straight from the disk. There's no bootloader and no C++, just the CPU and us.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 1 | [Setting up the tools](lessons/01-setup.md) | A QEMU window saying "No bootable device" | done |
| 2 | [The first boot sector](lessons/02-first-boot-sector.md) | The letter `A` on the screen | done |
| 3 | [Strings, loops and the stack](lessons/03-strings-loops-stack.md) | A sentence on the screen: "Hello There" | done |
| 4 | [The first Makefile](lessons/04-first-makefile.md) | One command, `make run`, builds and starts it | done |

## Phase 1: The real kernel

A C++ kernel, loaded by the Limine bootloader, that can draw and write text.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 5 | [C++ with no OS underneath](lessons/05-cpp-with-no-os.md) | `kernel.elf` builds | done |
| 6 | Booting with Limine | The screen fills with one color, so our code is running | |
| 7 | The serial port | "Hello" appears in the Ubuntu terminal | |
| 8 | Drawing pixels | Rectangles on the screen | |
| 9 | A font and a text console | Text on the screen | |
| 10 | `kprintf` and logging | A table of the machine's memory regions | |

## Phase 2: Setting up the CPU

Teaching the CPU what to do when something happens: an error, a timer tick, a key press.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 11 | Debugging with QEMU and GDB | The kernel paused, with its registers on screen | |
| 12 | The GDT | "GDT loaded", and no reboot | |
| 13 | Interrupts and exceptions | A divide by zero shows a panic screen | |
| 14 | The interrupt controller and the timer | A counter ticking on the screen | |
| 15 | The keyboard | You type, and letters appear | |

## Phase 3: Memory

Keeping track of every byte of RAM, and giving each program its own private view of it.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 16 | Physical memory | How much RAM is free | |
| 17 | Paging | A page mapped by hand, and a page fault on purpose | |
| 18 | The kernel heap | `kmalloc` and `kfree` work | |
| 19 | The C++ runtime | `new` and `delete` work, and objects live on the heap | |

## Phase 4: Multitasking

One CPU, many things running. The trick is switching between them fast enough.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 20 | Threads and the context switch | Two threads taking turns | |
| 21 | A preemptive scheduler | The timer switches them, so they don't have to ask | |
| 22 | Sleeping and waiting | `sleep(1000)` waits one second without wasting the CPU | |

## Phase 5: User mode

Running programs with restricted rights, so a broken program can't break the kernel.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 23 | Ring 3 | A program running with restricted rights | |
| 24 | System calls | That program asks the kernel to print for it | |
| 25 | Processes and address spaces | Two programs that can't see each other's memory | |
| 26 | Loading ELF programs | A program built separately from the kernel runs | |
| 27 | The RAM disk | Programs loaded from `/bin`, and a crashing program killed while the kernel survives | |

## Phase 6: Files

One way to open, read and write anything: files, folders, even the keyboard and the screen.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 28 | The virtual file system | The contents of `/` listed | |
| 29 | File descriptors | A program opens and reads a file | |
| 30 | Files in RAM | Creating and writing files | |
| 31 | Device files | The keyboard and the screen become files | |

## Phase 7: The shell

The program you actually talk to.

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 32 | The terminal layer | Typing with Backspace, sent to a program one line at a time | |
| 33 | A small C library | `printf` in programs | |
| 34 | The shell | A `$` prompt that runs programs | |
| 35 | Built-in and file commands | `cd`, `ls`, `cat`, `echo`, `pwd`, `mkdir`, `touch`, `rm` | |
| 36 | Processes and Ctrl+C | `ps` and `kill` | |

## Phase 8: Version 1.0

| # | Lesson | What you'll see | Status |
|---|---|---|---|
| 37 | The clock and system commands | `date`, `uptime`, `mem`, `clear`, `reboot` | |
| 38 | Release | Cleanup, final docs, version 1.0.0 | |

## After 1.0

These are ideas, not plans yet: a disk driver and a real file system (FAT or ext2), a mouse, a simple GUI, using more than one CPU core, networking, and maybe our own programming language.
