# Lesson 5: C++ with no OS underneath

## Goal

Write the first piece of the real kernel in C++, and turn it into one file: `build/kernel.elf`. It doesn't boot yet. That comes in lesson 6.

## In short

This lesson has a lot of new words, but the story is small:

1. A normal program gets help from the operating system. Our kernel **is** the operating system, so nobody helps it.
2. So we tell the compiler: "don't use anything that needs an OS". That's what the long list of flags is for.
3. The compiler turns each `.cpp` file into a piece. The linker glues the pieces into one finished file.
4. A small file, the linker script, is the floor plan. It tells the linker where in memory each part of the kernel goes.
5. The finished file is an ELF file: a box with a label on the outside and compartments inside. In lesson 6, Limine reads the label and unpacks the box.

```
 kernel/main.cpp ──(clang++ compiles)──► build/kernel/main.o ──┐
 more .cpp files later ────────────────► more .o files ────────┤
                                                               ├──(ld.lld links)──► build/kernel.elf
 kernel/linker.ld  (the floor plan) ───────────────────────────┘
```

If you only remember this picture, that's enough to go on.

## What you'll see

```
$ make
mkdir -p build/kernel/
clang++ --target=x86_64-unknown-none-elf -ffreestanding ... -c kernel/main.cpp -o build/kernel/main.o
ld.lld -T kernel/linker.ld -nostdlib -static -o build/kernel.elf build/kernel/main.o

$ file build/kernel.elf
build/kernel.elf: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

No window opens this time. The result is a file. The kernel can't start by itself yet: it needs Limine to load it and jump into it, and that's lesson 6.

## New words

- **Hosted and freestanding**: hosted code runs on top of an operating system and can ask it for things. Freestanding code runs with nothing underneath.
- **Compiler flag**: an option you give the compiler, like `-O2`. It changes how the code gets built.
- **Linker script**: a file that tells the linker where each part of the program goes in memory.
- **ELF file**: the file format for programs on Linux, and for our kernel. It has a header (the label) and sections (the compartments).
- **Section**: one compartment of an ELF file, like `.text` for the code.
- **Segment**: a group of sections that get the same permissions in memory: read, write or run.
- **Entry point**: the address where a program starts running.
- **Name mangling**: C++ secretly renames functions, like `kmain` to `_Z5kmainv`. `extern "C"` turns that off.
- **Page**: a 4 KiB block of memory. Permissions are set one page at a time.
- **Inline assembly**: one or more assembly instructions written right inside C++, like `__asm__("hlt")`.
- **Type alias**: a second name for a type that already exists, like `u64` for `unsigned long`.
- **Pattern rule**: a make rule with `%` in it. One rule works for many files.
- **Dependency file**: a `.d` file that clang writes next to each `.o` file. It lists every header the `.cpp` file used, like a receipt.

They're all in the [glossary](../glossary.md) too.

## The idea

### 1. A program with nobody to help it

Think of a hotel. When you write TypeScript, Node or the browser is the hotel. `console.log`, files, timers and memory are room service: you ask, and someone does it for you.

A normal C++ program on Linux lives in a hotel too. `printf` asks Linux to print. `new` asks Linux for memory. Even `main()` is called by Linux.

Our kernel **is** the hotel. There's nobody underneath to ask. So inside the kernel:

- **No standard library.** `#include <iostream>`, `std::string` and `std::vector` all need an OS, so they're not there.
- **No `new` and `delete`** for now. We build them ourselves in lesson 19.
- **No `main()`.** Limine will call our function, and we name it `kmain()`.

What still works is everything that's just the CPU doing work: variables, functions, `if`, loops, structs, classes, pointers and templates.

C++ like this is called **freestanding**. Normal C++ is **hosted**.

### 2. Compiling and linking

Think of a book with many chapters:

- Each writer writes one chapter alone. That's the **compiler** (`clang++`). It turns one `.cpp` file into one **object file** (`.o`). When a chapter says "see chapter 7", the writer leaves a note, because they don't know the page number yet.
- The editor puts all the chapters together into one book, sets the page numbers and fills in every "see chapter 7" note. That's the **linker** (`ld.lld`). Its output is the finished program.

In lessons 2 to 4, nasm did both jobs at once, for one small file. A kernel has many files, so the work is split in two.

### 3. The flags: "don't do things that need an OS"

By default, clang builds programs for the computer it runs on, which is Linux. Each flag switches off one habit that expects Linux to be there:

| Flag | In plain words | Why |
|---|---|---|
| `--target=x86_64-unknown-none-elf` | "Build for a 64-bit x86 CPU with **no** OS" (`none`) | Without it, clang builds a Linux program |
| `-ffreestanding` | "There's no standard library here" | So clang doesn't expect `printf` and friends |
| `-fno-exceptions` | "No `throw` or `catch`" | Exceptions need a helper library we don't have |
| `-fno-rtti` | "No `typeid` or `dynamic_cast`" | Same reason: they need extra helpers |
| `-fno-stack-protector` | "Don't add hidden safety checks to functions" | The checks call a Linux library function that doesn't exist here |
| `-fno-pic` | "This code always stays at one address" | Linux programs can be moved around in memory. Our kernel never moves |
| `-mcmodel=kernel` | "The code lives at the very top of memory" | It matches the address in the linker script (part 4 below) |
| `-mno-red-zone` | "No secret scratch space below the stack" | See below |
| `-mno-mmx -mno-sse -mno-sse2 -mno-80387` | "Don't use the decimal-number registers" | See below |
| `-std=c++20` | Use the C++20 version of the language | |
| `-O2` | Make the code fast and small | |
| `-g` | Add debug notes to the file | The debugger uses them in lesson 11 |
| `-Wall -Wextra` | Show more warnings | Like `strict` mode in TypeScript |
| `-MMD -MP` | Write down which headers each file used | Part 8 below |

Two of these need a little more explaining.

**The red zone.** On Linux, a function may scribble on a small area just past the top of the stack, without reserving it first. It's like writing on the desk next to your notebook instead of on a page. On Linux that's safe. In a kernel, an **interrupt** can come at any moment, and it puts its own things on the stack, right on that desk. Your notes get covered. So we say: no red zone.

**The decimal-number registers.** Besides the normal registers, the CPU has extra ones for decimal numbers like `3.14` and for fast math. If the kernel used them, every interrupt would have to save and restore them too. The easy rule is that the kernel never touches them. Clang sometimes uses them on its own, for example to copy a struct quickly, even if you never write a decimal number. That's why it takes a flag to stop it.

### 4. Where the kernel lives in memory

Think of memory as a very long street, where every house has a number. The house number is the **address**.

Our kernel lives in the last houses of the street, starting at `0xffffffff80000000`, the beginning of the last 2 GiB. There are three reasons for this:

1. Limine's rules say so: the kernel must be at that address or higher.
2. It keeps the start of the street free for programs, which arrive in lesson 23.
3. `-mcmodel=kernel` tells the compiler the same thing, so it can write shorter instructions.

Your PC doesn't need that much RAM. These are pretend addresses, and Limine connects them to real RAM behind the scenes. Lesson 17 shows how that works. For now, just remember that the kernel's street number starts with `0xffffffff8`.

### 5. The ELF file: a box with a label

In lessons 2 to 4, `boot.bin` was only raw machine code. The BIOS copied it to `0x7C00` and ran it, with no questions asked. `kernel.elf` is smarter. It's like a moving box.

On the outside it has a **label**, the header. It says "64-bit, for an x86-64 CPU, start running at `0xffffffff80000000`". That start address is the **entry point**.

Inside it has **compartments**, the sections:

| Section | What goes in it | Like |
|---|---|---|
| `.text` | the machine code | a recipe's steps |
| `.rodata` | constants, like text in quotes: `"Hello"` | a printed sign: you can read it, not change it |
| `.data` | variables with a starting value: `u64 counter = 42;` | a whiteboard with something already written on it |
| `.bss` | variables that start at zero: `u8 buffer[4096];` | an empty whiteboard |

`.bss` has a trick. The file doesn't carry the zeros. It only carries a note: "I need 4096 zero bytes here". It's like a note in the moving box that says "buy an empty whiteboard when you arrive", so you don't carry one. A huge `.bss` doesn't make the file bigger. There's an experiment for this in "Try this".

### 6. Segments: rooms with locks

When the kernel is in memory, each part gets **permissions**: what the CPU is allowed to do with it.

| Segment | Holds | Permissions |
|---|---|---|
| text | `.text` | read and run |
| rodata | `.rodata` | read only |
| data | `.data` and `.bss` | read and write |

A group of sections with the same permissions is called a **segment**. The permissions protect us from bugs. If buggy code tries to write over the kernel's own code, the CPU can stop it.

Permissions work on whole **pages**, 4 KiB blocks of memory. One page can only have one set of permissions, just like one room can only have one lock. So every segment has to start on a new page. In the linker script, `ALIGN(4096)` does that: it skips ahead to the start of the next page.

### 7. The linker script: the floor plan

The linker needs to know a few things:

- where the kernel starts: `0xffffffff80000000`
- the order of the sections
- which segment each section goes in, with which permissions
- where to start running: the function `kmain`

Its default plan is made for Linux programs, so we give it our own: `kernel/linker.ld`.

### 8. `extern "C"`: keep the plain name

In C++, two functions can share a name if their parameters are different: `print(int)` and `print(const char*)`. To tell them apart, the compiler secretly gives each one a longer name. `void kmain()` becomes `_Z5kmainv`:

- `_Z` means "a C++ name"
- `5` is the length of the name
- `kmain` is the name itself
- `v` means "no parameters" (void)

This is called **name mangling**. It's like two students called Ana in one class: the teacher calls them "Ana B." and "Ana K." so nobody gets confused.

The linker script says `ENTRY(kmain)`, so it looks for the plain name. `extern "C"` tells the compiler "keep this name plain, the way C does". Without it, the linker can't find `kmain`, and the kernel would start at address 0. There's more on this in "Common problems".

### 9. kmain never returns

In TypeScript, when your code ends, Node exits and gives control back to the terminal. Our kernel has nobody to go back to.

Limine even puts a fake return address, `0`, on the stack. A `return` from `kmain` would jump to address 0 and crash. So `kmain` ends with a loop that never stops, and inside it is `hlt`, from lesson 2: "sleep until something happens". It's a loop because `hlt` wakes up whenever an interrupt comes, so we go straight back to sleep.

### 10. Our own number types

TypeScript has one `number`. C++ has many whole-number types, and their sizes depend on the system. `long` is 8 bytes on Linux but only 4 bytes on Windows. In a kernel, sizes really matter: the hardware expects exact sizes. So we make names that say the size:

- `u8`, `u16`, `u32`, `u64`: `u` means unsigned (no minus numbers), and the number is how many bits it holds.
- `usize`: for sizes and counts, like a string's length or an array index. It's always as wide as an address.

`using u64 = unsigned long;` is the same idea as TypeScript's `type UserId = string;`. It's a new name for a type that already exists.

`static_assert` is a check that runs while compiling, like a TypeScript type error. If a size is wrong, the build stops before anything runs.

`u64` and `usize` are both `unsigned long` here, and that's on purpose. They're the same type with different meanings: "exactly 64 bits" and "the size of something in memory".

### 11. The Makefile gets smarter

Lesson 4's Makefile named every file by hand. The kernel will have about a hundred files, so this Makefile finds them by itself:

| Make piece | What it does | TypeScript feel |
|---|---|---|
| `$(shell find kernel/ -name "*.cpp")` | lists every `.cpp` file | `glob('kernel/**/*.cpp')` |
| `$(SOURCE_FILES:%.cpp=build/%.o)` | turns each `.cpp` name into a `.o` name | `.map(f => ...)` |
| `build/%.o: %.cpp` | one rule for every `.cpp` file | a function instead of copy-paste |
| `$(dir $@)` | the folder part of the target | `path.dirname()` |

In a pattern rule, `%` is the same text on both sides. To make `build/kernel/main.o`, make sets `%` to `kernel/main` and looks for `kernel/main.cpp`.

**The receipt.** `main.cpp` includes `types.hpp`, but the Makefile doesn't know that. If you change `types.hpp`, make thinks nothing changed. The fix:

- `-MMD -MP` makes clang write a receipt next to each `.o` file: a `.d` file that lists every file it read.
- `-include` at the bottom of the Makefile reads those receipts. The `-` means "don't complain if a receipt doesn't exist yet", which is the case on the very first build.

Here's a real receipt. It's a tiny Makefile rule, written by clang:

```
build/kernel/main.o: kernel/main.cpp kernel/../shared/types.hpp
kernel/../shared/types.hpp:
```

## Build it

There are four files. The comments here are for the lesson; the files in the repo have fewer.

### `shared/types.hpp`

```cpp
// Include guard: if this file gets included twice, the second copy is skipped.
#ifndef DATA_TYPE
#define DATA_TYPE

// New names for types that already exist. The number is the size in bits.
using u8 = unsigned char;
using u16 = unsigned short;
using u32 = unsigned int;
using u64 = unsigned long;
// For sizes and counts: as wide as an address.
using usize = unsigned long;

// Checks that run while compiling. A wrong size stops the build.
static_assert(sizeof(u8) == 1, "u8 must be 1 byte long");
static_assert(sizeof(u16) == 2, "u16 must be 2 bytes long");
static_assert(sizeof(u32) == 4, "u32 must be 4 bytes long");
static_assert(sizeof(u64) == 8, "u64 must be 8 bytes long");
static_assert(sizeof(usize) == sizeof(void*), "usize must be as wide as a pointer");

#endif
```

The folder is `shared/`, not `kernel/`, because programs will use these types too, later on.

### `kernel/main.cpp`

```cpp
#include "../shared/types.hpp"

// extern "C": keep the plain name "kmain", so the linker script can find it.
extern "C" void kmain() {
  // Never return: there's nobody to return to.
  while(1) {
    // Sleep until something happens, then sleep again.
    __asm__("hlt");
  }
}
```

- `#include "../shared/types.hpp"`: the path is relative to this file, so `..` goes up from `kernel/` to the project folder.
- `__asm__("hlt")` puts one assembly instruction right inside C++. This is called **inline assembly**.
- `kmain` doesn't use the types yet. They're ready for the next lessons.

### `kernel/linker.ld`

```
/* Start running at the function kmain. */
ENTRY(kmain)

/* Make a 64-bit ELF file for x86-64. */
OUTPUT_FORMAT(elf64-x86-64)

/* The segments and their permissions: read = 4, write = 2, run = 1, added together. */
PHDRS {
  text PT_LOAD FLAGS(5);     /* read + run */
  rodata PT_LOAD FLAGS(4);   /* read only */
  data PT_LOAD FLAGS(6);     /* read + write */
}

SECTIONS {
  /* The dot is "where we are now", like a cursor. Start at the top 2 GiB. */
  . = 0xffffffff80000000;

  /* From every file (*), take every section whose name starts with .text. */
  .text : {
    *(.text*)
  }: text

  /* Skip ahead to the next page, so each segment gets its own page. */
  . = ALIGN(4096);
  .rodata : {
    *(.rodata*)
  }: rodata

  . = ALIGN(4096);
  .data : {
    *(.data*)
  }: data

  /* .bss goes last, in the same segment as .data. */
  .bss : {
    *(COMMON)
    *(.bss*)
  }: data

  /* Throw away compiler notes and exception tables. We don't need them. */
  /DISCARD/ : {
    *(.note*)
    *(.eh_frame*)
  }
}
```

- `FLAGS(5)` uses the same numbers as `chmod` on Linux: read is 4, write is 2 and run is 1. So 5 means read and run, and 6 means read and write.
- `PT_LOAD` means "load this into memory".
- `: text` at the end of a section puts it in the `text` segment. A section without one joins the segment of the section above it.
- `*(COMMON)` is an old name some compilers use for zeroed variables. It belongs with `.bss`.
- `.eh_frame` holds tables that `throw` and `catch` need. We turned exceptions off, so it can go.

### `Makefile`

This is the one in the project folder, not `warmup/Makefile`. Recipe lines start with a TAB, like in lesson 4.

```makefile
.PHONY: build clean

CXX := clang++

# Compiler flags: build for "no OS". The \ joins the lines into one.
CXXFLAGS = --target=x86_64-unknown-none-elf \
-ffreestanding \
-fno-exceptions -fno-rtti \
-fno-stack-protector \
-fno-pic \
-mno-red-zone \
-mcmodel=kernel \
-mno-mmx -mno-sse -mno-sse2 -mno-80387 \
-std=c++20 -O2 -g -Wall -Wextra \
-MMD \
-MP

BUILD := build/

TARGET := $(BUILD)kernel.elf

KERNEL := kernel/

# Every .cpp file in kernel/. := runs find only once.
SOURCE_FILES := $(shell find $(KERNEL) -name "*.cpp")

# kernel/main.cpp becomes build/kernel/main.o. No spaces around the = here.
OBJECT_FILES = $(SOURCE_FILES:%.cpp=$(BUILD)%.o)

LINKER := $(KERNEL)linker.ld

LD := ld.lld

LDFLAGS = -T $(LINKER) -nostdlib -static

# The first rule is the default, so plain "make" builds the kernel.
build: $(TARGET)

# Link: all the object files, plus the floor plan.
$(TARGET): $(OBJECT_FILES) $(LINKER)
	$(LD) $(LDFLAGS) -o $@ $(OBJECT_FILES)

# Compile: one rule for every .cpp file.
$(BUILD)%.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD)

# Read clang's receipts, so a changed header rebuilds the files that use it.
-include $(OBJECT_FILES:.o=.d)
```

- `-T $(LINKER)` gives the linker our floor plan.
- `-nostdlib` and `-static` say "don't add any Linux libraries".
- `$(LINKER)` is a prerequisite of the kernel, so changing the floor plan links again.
- `.PHONY: build` matters here, because the target `build` and the folder `build/` have the same name. Without it, make would see the folder and say "'build' is up to date".
- `make clean` deletes all of `build/`, including the warm-up's `build/warmup/`. That's fine, because everything in `build/` can be made again.

## Run it

From the project folder:

```
make
```

You should see the three lines from "What you'll see". Run `make` again and you get `make: Nothing to be done for 'build'.`

Now open the box and look inside. These tools came with the other build tools in lesson 1.

**The label:**

```
$ readelf -h build/kernel.elf
  Class:                             ELF64
  Type:                              EXEC (Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Entry point address:               0xffffffff80000000
  ...
```

The entry point is the top-2-GiB address from the floor plan, and that's where `kmain` is. The machine says AMD because AMD designed the 64-bit version of x86. Intel CPUs run it too.

**The segments:**

```
$ readelf -l build/kernel.elf
...
Program Headers:
  Type           Offset             VirtAddr           PhysAddr
                 FileSiz            MemSiz              Flags  Align
  LOAD           0x0000000000001000 0xffffffff80000000 0xffffffff80000000
                 0x0000000000000013 0x0000000000000013  R E    0x1000
```

Each segment takes two lines. `FileSiz` is its size in the file and `MemSiz` is its size in memory. Here both are `0x13`, which is 19 bytes.

There's only one segment, read and run (`R E`), because the kernel has no constants or variables yet. The empty ones are left out. "Try this" adds some.

**The machine code:**

```
$ objdump -d -M intel build/kernel.elf

ffffffff80000000 <kmain>:
ffffffff80000000:  55                    push   rbp
ffffffff80000001:  48 89 e5              mov    rbp,rsp
ffffffff80000004:  66 66 66 2e 0f 1f 84  data16 data16 cs nop WORD PTR [rax+rax*1+0x0]
ffffffff8000000b:  00 00 00 00 00
ffffffff80000010:  f4                    hlt
ffffffff80000011:  eb fd                 jmp    ffffffff80000010 <kmain+0x10>
```

`-M intel` shows the same style of assembly we wrote with nasm.

- `push rbp` and `mov rbp, rsp`: the usual first lines of a function. They leave a bookmark on the stack, so a debugger can find its way back later.
- The long `nop` line: "do nothing". Clang adds it so the loop starts at an address that ends in `0`, which the CPU likes. It's like starting a new chapter on a fresh page.
- `hlt`, then `jmp` back to the `hlt`: our `while(1)` loop. `f4` and `eb fd` are the same bytes as lesson 2's loop.

**The receipt at work:**

```
$ touch shared/types.hpp
$ make
```

`main.cpp` gets compiled again, because its receipt says it uses `types.hpp`.

## What just happened

1. Make ran `find` and got `kernel/main.cpp`. It turned that into `build/kernel/main.o`.
2. The pattern rule compiled it. Clang used the "no OS" flags, wrote the object file, and wrote a receipt, `main.d`, next to it.
3. The linker read the floor plan. It put the code at `0xffffffff80000000`, gave it read and run permission, and wrote the address of `kmain` on the label as the entry point.
4. The result is `build/kernel.elf`. Only 19 bytes of it are code. The rest is the label, the debug notes and empty space up to the start of the first page.
5. Nothing ran. In lesson 6, Limine will read the label, put the code at its address and jump to `kmain`.

## Common problems

- **`symbol not found: R`** in the linker script: `FLAGS()` only takes numbers. Read is 4, write is 2, run is 1. Add them together.
- **`malformed number: 0x...`**: count the digits. A 64-bit address has 16 hex digits after `0x`: `0xffffffff80000000`.
- **`; expected, but got .text`**: the line `. = 0xffffffff80000000` needs a `;` at the end.
- **`malformed number: {`**: put a space before the colon: `.text : {`, not `.text: {`.
- **`readelf -l` shows `.rodata` in the `R E` segment**: the section has no `: rodata` at the end. A section without one joins the segment above it.
- **Two segments start in the same page** (the second address doesn't end in `000`): add `. = ALIGN(4096);` before the section that starts the new segment.
- **`warning: cannot find entry symbol kmain; not setting start address`**: the linker can't find a function with the plain name `kmain`. Check that it has `extern "C"` and is spelled the same as in `ENTRY(kmain)`. This is only a warning, so the build still finishes, with an entry point of `0x0`. Check it with `readelf -h`.
- **`undefined symbol: f()`** from the linker: the code calls a function that no file defines. The compiler doesn't mind, only the linker does, because only the linker sees all the files together.
- **`fatal error: 'iostream' file not found`**: the standard library doesn't exist here. If you need something like it, we write our own (lesson 9 brings the first pieces).
- **`error: cannot use 'throw' with exceptions disabled`**: exceptions are off on purpose. Return an error value instead.
- **`error: unknown type name 'u64'`**: the file is missing `#include "../shared/types.hpp"`.
- **`warning: extra tokens at end of #include directive`**: there's a `;` after the `#include` line. `#include` lines don't end with `;`.
- **`ld.lld: error: cannot find linker script :=`**: a variable line has two operators, like `LINKER = := ...`. Keep only one: `=` or `:=`.
- **`No rule to make target 'build/kernel/main.o'`**: check the slashes. If `BUILD` already ends with `/`, write `$(BUILD)%.o`, not `$(BUILD)/%.o`. Also check that the `.cpp` file exists.
- **`kernel/main.cpp:1: *** missing separator.  Stop.`**: there are spaces in a renaming like `$(SOURCE_FILES:%.cpp = ...)`. With the spaces, make renames nothing, so the `-include` line tries to read your `.cpp` file as a Makefile. Remove the spaces.
- **You change a header and nothing rebuilds**: check that `-MMD -MP` is in the flags and that the `-include` line is at the bottom.
- **`Clock skew detected`**: harmless, the same as in lesson 4. It comes from Windows and Linux sharing the folder.

## Try this

1. **Fill the compartments.** Add three lines above `kmain` in `main.cpp`:

   ```cpp
   const char* greeting = "Hello";
   u64 counter = 42;
   u8 buffer[4096];
   ```

   Run `make`, then `readelf -S build/kernel.elf`. Now there are four sections: `.text`, `.rodata` (the text `Hello`), `.data` (`greeting` and `counter`) and `.bss` (`buffer`). `readelf -l` shows three segments, `R E`, `R` and `RW`, each starting on a new page. Then run `nm -n build/kernel.elf` to see every name with its address.

2. **The empty whiteboard.** Change `buffer[4096]` to `buffer[1000000]` and run `make`. Check the file size with `ls -l build/kernel.elf`: it doesn't change. Then run `readelf -l build/kernel.elf`. The `RW` segment's `MemSiz` grows to `0xf4250` while its `FileSiz` stays small. The zeros only get made in memory. Remove the three lines when you're done.

3. **Mangled names.** Remove `extern "C"` and run `make`. The linker warns that it can't find `kmain`, `readelf -h` shows the entry point as `0x0`, and `nm build/kernel.elf` shows `_Z5kmainv`. Put `extern "C"` back.

4. **Found by itself.** Create an empty file, `kernel/test/empty.cpp`, and run `make`. It gets compiled into `build/kernel/test/` without changing the Makefile. Delete it afterwards.

5. **Ask make why.** Run `touch shared/types.hpp`, then `make --trace`. Make says it rebuilds `main.o` "due to" `types.hpp`.

Next, in lesson 6, Limine loads `kernel.elf`, jumps to `kmain`, and we fill the screen with one color. That's the first proof that our C++ is really running.
