# Architecture

This page is a map of the project: every file, and the one job it does. It's updated whenever a file is added, moved or removed, so it always matches the code.

## Rules

A few rules keep the code easy to read:

- **One file, one job.** If a file's job doesn't fit in one short line, the file should be split. Files aim to stay under about 200 lines.
- **`.hpp` and `.cpp` come in pairs.** The `.hpp` file (the header) says what a file offers to others, and the `.cpp` file does the work. To learn how to use something, you only need to read its header.
- **CPU-specific code lives in one place:** `kernel/arch/x86_64/`. Everything else could, in theory, work on another kind of CPU.
- **Assembly only where C++ can't do it.** A few things, like loading special CPU registers or switching between threads, can only be written in assembly. Each `.asm` file starts by explaining why it has to be assembly.
- **`kernel/` and `user/` never include each other's files.** Anything both of them need goes in `shared/`.
- **Code we didn't write lives in `third_party/`**, next to its license.
- **Everything the build creates goes into `build/`.** It's never committed, and `make clean` deletes it.

## Naming

| What | Style | Example |
|---|---|---|
| Files and folders | `snake_case` | `context_switch.asm` |
| Classes | `PascalCase` | `Framebuffer` |
| Functions and variables | `snake_case` | `draw_pixel`, `free_pages` |
| Constants | `UPPER_SNAKE` | `PAGE_SIZE` |

## Files that exist now

```
os/
├── README.md                what this project is, and how to build it
├── LICENSE                  the MIT license
├── Makefile                 build recipes (empty until lesson 5)
├── .gitignore               files git leaves out: the build folder
├── .gitattributes           store text files with Unix line endings
├── .vscode/
│   └── settings.json        editor settings: new files get Unix line endings
├── warmup/                  the first lessons only, not part of the OS
│   └── boot.asm             the 512-byte boot sector: prints A, then stops
└── docs/
    ├── README.md            start here: how the lessons work
    ├── roadmap.md           every planned lesson
    ├── architecture.md      this page
    ├── glossary.md          every new word, in simple terms
    └── lessons/
        ├── 01-setup.md      lesson 1: setting up the tools
        └── 02-first-boot-sector.md   lesson 2: the first boot sector
```

## Planned files

Nothing below exists yet. `L05` means the file arrives in lesson 5. When a file is created, it moves up into the section above. The lesson numbers are a guide, and they can shift as the work goes.

```
os/
├── make/                             the Makefile split into parts once it grows:   (~L26)
│                                     flags.mk kernel.mk user.mk image.mk run.mk
├── warmup/                           the first lessons only, not part of the OS
│   ├── Makefile                      build and run the boot sector                  (L04)
│   └── print.asm                     print a string using the BIOS                  (L03)
├── third_party/                      other people's code, each with its license
│   ├── limine/limine.h               how we ask Limine for things                   (L06)
│   └── font/                         a bitmap font with an MIT-compatible license   (L09)
├── shared/                           headers both the kernel and programs use
│   ├── types.hpp                     u8 u16 u32 u64 usize                           (L05)
│   ├── syscall_numbers.hpp           the number of each system call                 (L24)
│   └── errors.hpp                    error codes                                    (L24)
├── kernel/
│   ├── main.cpp                      kmain(): starts every part in order            (L05)
│   ├── linker.ld                     where the kernel sits in memory                (L05)
│   ├── boot/
│   │   ├── limine.conf               boot menu, and the files Limine loads          (L06)
│   │   └── requests.hpp/.cpp         ask Limine for the screen, memory map, files   (L06)
│   ├── arch/x86_64/                  only code that's specific to this CPU
│   │   ├── cpu.hpp                   halt, interrupts on/off, read cr2/cr3          (L06)
│   │   ├── io.hpp                    inb/outb: talk to I/O ports                    (L07)
│   │   ├── gdt.hpp/.cpp, gdt_load.asm   segment table: kernel and user modes        (L12)
│   │   ├── idt.hpp/.cpp              interrupt number → handler                     (L13)
│   │   ├── isr_stubs.asm             every interrupt enters here and saves registers (L13)
│   │   ├── interrupt_frame.hpp       the saved registers, as a struct               (L13)
│   │   ├── exceptions.cpp            CPU errors → panic                             (L13)
│   │   ├── pic.hpp/.cpp              interrupt controller: remap, mask, "done"      (L14)
│   │   ├── paging.hpp/.cpp           page-table entries, load cr3                   (L17)
│   │   ├── context_switch.asm        save one thread's registers, load another's    (L20)
│   │   ├── tss.hpp/.cpp              the kernel stack used when a program is interrupted (L23)
│   │   ├── enter_user.asm            the first jump into ring 3                     (L23)
│   │   ├── msr.hpp                   read and write CPU setting registers           (L24)
│   │   └── syscall_entry.asm, syscall_setup.cpp   where `syscall` lands             (L24)
│   ├── drivers/
│   │   ├── serial.hpp/.cpp           COM1: logs in your terminal                    (L07)
│   │   ├── framebuffer.hpp/.cpp      pixels, rectangles                             (L08)
│   │   ├── font.hpp/.cpp             draw one letter                                (L09)
│   │   ├── console.hpp/.cpp          text: cursor, new lines, scrolling             (L09)
│   │   ├── pit.hpp/.cpp              timer chip: 100 ticks a second                 (L14)
│   │   ├── keyboard.hpp/.cpp, keymap.cpp   PS/2 keyboard, key code → letter         (L15)
│   │   └── rtc.hpp/.cpp              clock chip: date and time                      (L37)
│   ├── lib/                          our own small standard library (no std::)
│   │   ├── string.hpp/.cpp           memcpy memset strlen strcmp                    (L06)
│   │   ├── print.hpp/.cpp            kprintf                                        (L10)
│   │   ├── log.hpp/.cpp              log to the serial port and the screen          (L10)
│   │   ├── panic.hpp/.cpp, assert.hpp   stop and show the error                     (L13)
│   │   ├── bitmap.hpp                a row of bits                                  (L16)
│   │   ├── list.hpp                  a linked list                                  (L19)
│   │   ├── cxx_runtime.cpp           new/delete, global constructors                (L19)
│   │   └── irq_lock.hpp              interrupts off around shared data              (L21)
│   ├── memory/
│   │   ├── pmm.hpp/.cpp              physical pages: which 4 KiB pieces are free    (L16)
│   │   ├── vmm.hpp/.cpp              address spaces: map and unmap pages            (L17)
│   │   └── heap.hpp/.cpp             kmalloc / kfree                                (L18)
│   ├── tasks/
│   │   ├── thread.hpp/.cpp           registers + a stack                            (L20)
│   │   ├── scheduler.hpp/.cpp        who runs next                                  (L21)
│   │   ├── wait_queue.hpp/.cpp       sleep until something happens                  (L22)
│   │   ├── process.hpp/.cpp          an address space + open files + threads        (L25)
│   │   └── elf.hpp/.cpp              load a program file                            (L26)
│   ├── syscalls/
│   │   ├── dispatch.hpp/.cpp         system call number → handler                   (L24)
│   │   ├── user_memory.hpp/.cpp      check the pointers programs hand us            (L24)
│   │   ├── sys_process.cpp           exit spawn wait getpid kill                    (L25)
│   │   ├── sys_file.cpp              open read write close readdir                  (L29)
│   │   ├── sys_memory.cpp            sbrk                                           (L33)
│   │   └── sys_time.cpp              uptime sleep time                              (L37)
│   ├── fs/
│   │   ├── tar.hpp/.cpp              read a tar archive                             (L27)
│   │   ├── initrd.hpp/.cpp           the read-only archive Limine loaded            (L27)
│   │   ├── node.hpp                  the base class of every file and folder        (L28)
│   │   ├── vfs.hpp/.cpp              paths and mount points                         (L28)
│   │   ├── file_table.hpp/.cpp       a process's file descriptors                   (L29)
│   │   ├── tmpfs.hpp/.cpp            files that live in RAM                         (L30)
│   │   └── devfs.hpp/.cpp            /dev/tty, /dev/null                            (L31)
│   └── tty/tty.hpp/.cpp              line editing, echo, Ctrl+C                     (L32)
├── user/
│   ├── linker.ld                     where programs sit in memory                   (L26)
│   ├── libc/
│   │   ├── syscall.hpp/.cpp          the raw `syscall` instruction                  (L24)
│   │   ├── crt0.asm                  program start: call main, then exit            (L26)
│   │   ├── unistd.hpp/.cpp           read write open spawn wait exit                (L26)
│   │   ├── string.hpp/.cpp           strlen strcmp memcpy                           (L33)
│   │   ├── stdio.hpp/.cpp            printf getline                                 (L33)
│   │   └── stdlib.hpp/.cpp           malloc free atoi                               (L33)
│   ├── shell/
│   │   ├── main.cpp                  prompt → read → run                            (L34)
│   │   ├── parser.hpp/.cpp           split a line into words                        (L34)
│   │   └── builtins.hpp/.cpp         cd exit help                                   (L35)
│   └── bin/                          one .cpp file per command                      (L35–L37)
│                                     echo cat ls pwd mkdir touch rm ps kill
│                                     clear uptime date mem reboot
├── rootfs/                           files that appear inside the OS at /           (L27)
├── tools/gdb/kernel.gdb              debugger setup for `make debug`                (L11)
└── docs/images/                      diagrams and screenshots, when a lesson needs them
```

## After 1.0

Not planned in detail yet: PCI, a disk driver, FAT or ext2, a mouse, a GUI, more than one CPU core, networking, and our own programming language. Each one will get its own place in this map when it's planned.
