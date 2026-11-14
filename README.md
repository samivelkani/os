# os

A small Unix-like operating system for 64-bit x86 computers, written from scratch in C++ and assembly. It's built to learn how a computer really works, one small step at a time.

The name is temporary. A real one will come later.

## What is this?

This is a hobby operating system written from zero. There's no Linux inside it and no code taken from other operating systems. When it starts, nothing exists yet: no `printf`, no memory allocator, no files, no keyboard. Each of those things gets built here by hand, and explained.

It's also a course. Every step is written up as a short lesson in [`docs/`](docs/README.md). The lessons use plain language and are meant for people who already know a high-level language, like TypeScript, Dart, Python or Java, and want to see what happens underneath.

### Is this a Linux distribution?

No. A Linux distribution (Ubuntu, Arch, Fedora and so on) is the Linux kernel plus thousands of programs written by other people, packaged together. Here we write the kernel itself.

We borrow Unix *ideas*, like files, processes and a shell, but not Unix code. Linux is only the workshop where our tools run.

## The goal

Most OS tutorials stop after printing "hello" or reading the keyboard. Real operating systems have tens of millions of lines of code and are far too big to read. This project sits in between: complete enough to actually use, and small enough to read from start to finish.

Version 1.0 is done when:

- [ ] It boots from an `.iso` file in QEMU, with both BIOS and UEFI firmware.
- [ ] It writes text to the screen and to a serial log. When something crashes, it shows a panic screen with every CPU register.
- [ ] Programs are isolated. A program that writes to memory address 0 gets killed, and the shell keeps running.
- [ ] Two programs can run at the same time (preemptive multitasking).
- [ ] It has a shell with about 15 commands. Each command is a separate program in `/bin`.
- [ ] Files can be read from a RAM disk, and created and written in memory.
- [ ] Every lesson is written, every file stays short, and the whole system stays small enough to read.

## Status

**Lesson 2 of 38 is done:** a 512-byte boot sector, written in assembly, prints a letter on the screen. The real kernel starts in lesson 5.

The [roadmap](docs/roadmap.md) lists every lesson and what each one adds.

## How it works

An operating system sits between programs and the hardware:

```
┌──────────────────────────────────────────────┐
│ Programs: the shell, ls, cat                 │  user mode    (ring 3)
├──────────────── system calls ────────────────┤
│ Kernel: memory, processes, files, drivers    │  kernel mode  (ring 0)
├──────────────────────────────────────────────┤
│ Bootloader (Limine)                          │
├──────────────────────────────────────────────┤
│ Hardware: CPU, RAM, keyboard, screen         │  emulated by QEMU
└──────────────────────────────────────────────┘
```

From power-on to the shell prompt, this is roughly what happens:

1. The firmware (BIOS or UEFI) checks the machine and loads the **bootloader** from the disk.
2. The bootloader switches the CPU into 64-bit mode, copies our **kernel** into memory and jumps to it.
3. The kernel sets up the CPU, takes control of the memory, and starts its **drivers** for the screen, the keyboard and the timer.
4. It loads the first program, the **shell**, and runs it in a restricted CPU mode so it can't damage the kernel.
5. The shell waits for you to type a command. It asks the kernel to start that program, then waits for it to finish.

The lessons build these pieces one at a time, from the bottom up.

## What you need

To **build** it:

| Tool | What it does |
|---|---|
| Linux, or Windows with WSL | the workshop where everything runs (we use Ubuntu 24.04) |
| `clang` | compiles C++ into machine code |
| `lld` | links the compiled pieces into one program |
| `nasm` | turns assembly into machine code |
| `make` | runs the build steps in the right order |
| `xorriso` | packs everything into a bootable `.iso` file |
| `qemu` | a whole PC in software, to run the OS |
| `gdb` | a debugger, to pause the OS and look inside |

On Ubuntu, one command installs all of them:

```bash
sudo apt update
sudo apt install clang lld nasm make xorriso qemu-system-x86 qemu-system-gui gdb
```

To **run** it, you only need QEMU. The OS is made for a 64-bit Intel or AMD PC with one CPU core, at least 64 MiB of RAM, and BIOS or UEFI firmware. Running on real hardware isn't a goal for now.

## Build and run

These commands arrive as the lessons add them:

| Command | What it does | From lesson |
|---|---|---|
| `make` | build everything | 5 |
| `make clean` | delete everything that was built | 5 |
| `make run` | build, then start the OS in QEMU | 6 |
| `make debug` | start QEMU paused, waiting for GDB | 11 |

## Project layout

```
os/
├── warmup/        a tiny boot sector in pure assembly (only the first lessons)
├── kernel/        the kernel: CPU setup, drivers, memory, tasks, files, system calls
├── user/          programs that run on top of the kernel: a small C library, the shell, commands
├── shared/        definitions the kernel and programs both need, like system call numbers
├── rootfs/        files that appear inside the OS at /
├── third_party/   code we didn't write, each piece with its own license
├── tools/         helpers for debugging
├── docs/          the lessons, the roadmap and a map of every file
└── build/         everything the build creates (never committed)
```

Most of these folders don't exist yet. Each lesson adds what it needs. [`docs/architecture.md`](docs/architecture.md) lists every file, its one job, and the lesson that adds it.

## Lessons

Start at [`docs/README.md`](docs/README.md). Each lesson is short and ends with something you can see running. It explains every new word and every line of code.

## Contributing

For now this is a learning project with one author, so it isn't open for contributions yet. Later the plan is to welcome issues, ideas and pull requests. Corrections to the lessons will be especially welcome.

## Versions

The project follows [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`). It stays at `0.x` while it's being built, and becomes `1.0.0` when every box in [the goal](#the-goal) is ticked.

## How this was made

The code is written by the author while learning, with guidance from an AI assistant. The documentation is written with the help of the same assistant and reviewed by the author.

## License

[MIT](LICENSE). You can use, copy, change and share this code, as long as you keep the license notice.
