# Lesson 1: Setting up the tools

## Goal

Install everything we need to build and run an operating system, and start a virtual PC for the first time.

## What you'll see

A QEMU window: a virtual PC that turns on, looks for something to start, finds nothing, and says **"No bootable device"**.

For today, that's the right result. The machine works, it just has nothing to run yet. In lesson 2 we'll give it something.

## New words

- **Terminal**: a window where you type commands instead of clicking.
- **WSL**: Windows Subsystem for Linux, a way to run a real Linux inside Windows.
- **Distribution**: a Linux kernel plus a bundle of programs, packaged together. Ubuntu is one.
- **Compiler**: turns code you can read into machine code the CPU can run.
- **Assembler**: does the same job for assembly language.
- **Linker**: joins compiled pieces into one finished program.
- **Emulator**: a program that pretends to be a whole computer.
- **Firmware**: the small program built into a computer that runs first when you turn it on. BIOS and UEFI are the two kinds on PCs.

They're all in the [glossary](../glossary.md) too.

## The idea

### A workshop, not part of the OS

We use Linux (Ubuntu) to *build* our operating system, but no part of Linux ends up *inside* it. Think of Ubuntu as a workshop. It's where the tools live. What we build there is a separate OS that runs on its own machine, a virtual one.

On Windows, WSL gives us that workshop without leaving Windows. If you're already on Linux, you have it.

### The tools, and how they fit

Most of our code will be C++. The few places where only assembly will do get assembly. Here's the trip every file makes, from text to a running OS:

```
main.cpp ── clang ──► main.o ┐
boot.asm ── nasm ───► boot.o ├── lld ──► kernel.elf ── xorriso ──► os.iso ──► QEMU ◄── gdb
                             ┘
      make runs every step in the right order, and only when something changed
```

- **clang** is the compiler. It reads a `.cpp` file and writes an **object file** (`.o`) full of machine code. Inside, it works in three stages:
  1. The *preprocessor* removes the comments and copies in every file named by `#include`.
  2. The compiler proper turns the C++ into CPU instructions.
  3. The assembler turns those instructions into machine code.
- **nasm**, the Netwide Assembler, does the same job for assembly files. Assembly is almost a one-to-one spelling of machine code: each line becomes one CPU instruction, a few bytes long. `hlt` ("stop until something happens") becomes the single byte `F4`.
- **lld** is the linker. Each `.o` file was made on its own, so when `main.o` calls a function that lives in `serial.o`, it only holds a note: "put the address of that function here". The linker reads all the `.o` files, fills in every note, decides where in memory each piece goes, and writes one program, `kernel.elf`.
- **xorriso** packs the kernel and the bootloader into an `.iso` file. That's one file holding a whole CD, in a format called ISO 9660, and a computer or QEMU can boot from it.
- **QEMU** (Quick EMUlator) is a whole PC in software: CPU, RAM, screen, keyboard and disks. It's where our OS runs. It's safe to crash, and it restarts in a second.
- **gdb**, the GNU debugger, can connect to QEMU. It can freeze the virtual CPU at any moment, run it one instruction at a time, and show the registers and memory.
- **make** reads a file called `Makefile`, which lists every build step and what each step needs. It runs the steps in the right order, and skips any step whose inputs haven't changed since the last time.

Why clang and not gcc, the other well-known C++ compiler? One clang install can build code for any kind of CPU, including "a bare x86-64 machine with no OS on it". With gcc, we'd first have to build a special version of gcc for that.

## Set it up

### 1. Install Ubuntu (Windows only)

Open PowerShell and run:

```powershell
wsl --install -d Ubuntu-24.04
```

When it's done, Ubuntu asks you for a username and a password. While you type the password, nothing appears on the screen, not even stars. That's normal in Linux terminals, so just type it and press Enter.

If you're already on Linux, skip to step 3.

### 2. Make Ubuntu the default

Some programs, like Docker Desktop, install their own small Linux inside WSL. If one of those is the default, typing `wsl` opens it instead of Ubuntu. Check with:

```powershell
wsl -l -v
```

The star marks the default. To make Ubuntu the default:

```powershell
wsl --set-default Ubuntu-24.04
```

### 3. Install the tools

In the Ubuntu terminal:

```bash
sudo apt update
sudo apt install clang lld nasm make xorriso qemu-system-x86 qemu-system-gui gdb
```

- `sudo` runs a command as the administrator, so it asks for your password.
- `apt` is Ubuntu's package manager, like an app store you use by typing. `apt update` refreshes the list of what's available, and `apt install` installs the packages you name.
- `qemu-system-x86` is QEMU for x86 PCs. `qemu-system-gui` adds the window that shows the virtual screen.

Ubuntu and all the tools together take a few gigabytes of disk space.

### 4. Check that everything is there

Each of these should print a version number:

```bash
clang --version
ld.lld --version
nasm -v
make --version
xorriso -version
qemu-system-x86_64 --version
gdb --version
```

### 5. Open the project in VS Code

Create a folder for the project (ours is called `os`) and open it in VS Code. Open a terminal inside VS Code with **Terminal → New Terminal**, click the small arrow next to **+**, and choose **Ubuntu-24.04 (WSL)**. To make it the default, press `Ctrl+Shift+P`, run **Terminal: Select Default Profile**, and pick it there.

Type `pwd` ("print working directory"). You should see something like:

```
/mnt/c/Users/yourname/Desktop/os
```

`/mnt/c/` is your Windows C: drive, seen from Linux. They're the same files, reached two different ways.

If your Windows username has a space in it, this path has one too. Many build tools trip over spaces, which is why our Makefiles will only ever use paths *relative* to the project folder.

### 6. Start a git repository

Git keeps the history of the project. Every lesson ends with a commit, so you can always go back and see exactly how the code looked at that point.

On Windows we run git from Windows (VS Code's Source Control panel, or PowerShell) and use Ubuntu only to build. Using one git per project keeps things simple.

```bash
git init
```

Then create two small files.

**`.gitignore`** tells git which files to leave out. Everything the build creates goes into a `build` folder. It can always be built again, so it doesn't belong in the history:

```
# build

/build
```

The `/` at the start means "the `build` folder at the top of the project".

**`.gitattributes`** solves a line-ending problem. Every line of text ends with invisible characters. Windows uses two of them (`\r\n`, called CRLF), and Linux uses one (`\n`, called LF). Git on Windows likes to convert files to CRLF, and then Linux tools break on them. A shell script, for example, fails with `bad interpreter`, because Linux reads the extra `\r` as part of the command. This file tells git to always use LF:

```
# Save every text file with Unix line endings (LF)
* text=auto eol=lf

# Binary files: git must never change their bytes
*.bin binary
*.iso binary
*.png binary
*.jpg binary
```

- `*` means "every file". `text=auto` lets git work out which files are text, and `eol=lf` makes those use LF.
- `binary` tells git to treat a file as raw bytes and never change it. A boot sector with even one changed byte won't boot.

VS Code shows the line ending of the open file in the bottom-right corner, as **LF** or **CRLF**. You can click it to switch.

**Pick your email before the first commit.** Every commit stores the author's name and email, and once the project is public, anyone can read them. To keep your email private, GitHub gives you a private address. Go to **Settings → Emails**, tick **Keep my email addresses private**, and copy the address it shows (it ends in `@users.noreply.github.com`). Then set it for this project:

```bash
git config user.email "your-id+your-name@users.noreply.github.com"
```

Then make the first commit:

```bash
git add .
git commit -m "Lesson 1: project setup"
```

## Run it

In the Ubuntu terminal:

```bash
qemu-system-x86_64
```

A window opens. You'll see a few lines from the virtual PC's firmware as it tries each place it knows how to start from. Then it gives up:

```
No bootable device.
```

Close the window to stop it. If QEMU has taken over your mouse, press `Ctrl+Alt+G` first to get it back.

## What just happened

1. QEMU built a virtual PC with a CPU, some RAM, a screen, a keyboard and some empty drives.
2. It turned that PC on. Just like on a real PC, the first thing to run was the **firmware**. QEMU uses SeaBIOS, an open-source BIOS.
3. The BIOS looked for something to start: the disks, the CD drive, the network. On a disk, it reads the very first 512 bytes, called the **boot sector**, and checks them for a special mark that says "I'm bootable".
4. Every drive was empty, so it printed "No bootable device" and stopped.

In lesson 2, we'll write those 512 bytes ourselves.

## Common problems

- **`wsl` opens the wrong Linux.** Programs like Docker Desktop install their own small Linux, and it can end up as the WSL default. `wsl --set-default Ubuntu-24.04` fixes it (step 2).
- **`make` says `No targets specified and no makefile found`.** The file must be named exactly `Makefile` (or `makefile`, or `GNUmakefile`). A file called `MakeFile` might seem to work on Windows, because Windows treats capital and small letters in file names as the same. On Linux and on a Mac it doesn't, so anyone who downloads the project gets this error.
- **Easy things to mix up** when you read about the tools elsewhere:
  - *lld* doesn't stand for "low level design". It's the linker from the LLVM project, the same project clang comes from.
  - The preprocessor removes comments, but it doesn't remove headers. `#include` does the opposite: it copies the whole header file in, so the compiler knows what the other files offer.
  - nasm doesn't run after clang. They work side by side. Each one turns its own files into `.o` files, and then the linker joins all of them.
  - make doesn't connect the files together. It only runs commands in the right order, and connecting the pieces is the linker's job.

## Try this

- **Look inside the virtual CPU.** With QEMU running, open the **View** menu and pick **compatmonitor0** (or press `Ctrl+Alt+2`). This is QEMU's own console. Type `info registers` and press Enter. Names like `EAX`, `EBX`, `ESP` and `EIP` are the CPU's **registers**, and in the next lesson you'll put values in them yourself. Press `Ctrl+Alt+1` to go back to the screen.
- **See how big a distribution is.** In Ubuntu, run `ls /usr/bin | wc -l`. That's the number of programs in just one of Ubuntu's folders. A distribution is mostly this: lots of programs that other people wrote. Our OS will have about fifteen, and we'll write every one.
- **Find where a tool lives.** `which nasm` prints the full path of the program that runs when you type `nasm`.
