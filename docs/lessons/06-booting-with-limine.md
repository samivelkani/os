# Lesson 6: Booting with Limine

## Goal

Boot our kernel for the first time. The Limine bootloader loads `kernel.elf` and jumps into `kmain`, and `kmain` paints the whole screen with one color.

## In short

1. Our kernel can't start by itself. **Limine** is like a stage crew: it does all the setup work, and then the actor (our kernel) walks on stage.
2. Our kernel can leave **notes** for Limine inside `kernel.elf`, like "please give me a screen". Limine reads them before it starts us, and writes its answers into them.
3. The firmware can't open folders, only disks. So we pack Limine, a small settings file and our kernel into a **CD inside one file**: `os.iso`.
4. The screen is a big grid of dots in memory. If we write a color number into a dot's 4 bytes, that dot changes on the screen.
5. `kmain` reads Limine's answer, paints every dot, and then sleeps forever.

```
 make run
    │
    ├─► build/kernel.elf      our kernel, with the notes inside
    ├─► build/limine/         Limine's files, downloaded once
    └─► build/os.iso          everything packed into one CD file
           │
           ▼
      QEMU: firmware ──► Limine ──► reads our notes, writes answers ──► kmain()
                                                                         │
                                                       the screen fills with one color
```

If you only remember this picture, that's enough to go on.

## What you'll see

```
make run
```

A QEMU window opens:

1. Limine's menu, with one entry, **os**, and the line `Booting automatically in 3, press any key to stop the countdown...`
2. After 3 seconds, the whole window fills with one color. Our code uses white, `0x00ffffff`.

That color is the first proof that our C++ is really running on a (virtual) computer.

## New words

- **Bootloader**: a small program that loads the kernel and jumps to it. Ours is Limine.
- **Request** and **response**: a note our kernel leaves for Limine ("give me a screen"), and the answer Limine writes back into it.
- **Base revision**: the version of Limine's rules our kernel follows. We use 6.
- **Paging**: the CPU's address map. It lets the kernel use a made-up address, and the CPU looks up where in RAM that really is.
- **`volatile`**: tells the compiler that someone outside our code can change this memory, so it must always read the real memory.
- **Attribute**: an extra instruction for the compiler, written as `__attribute__((...))`.
- **Anonymous namespace**: `namespace { ... }`. Everything inside is private to its file.
- **Pixel**: one dot on the screen.
- **Framebuffer**: the part of memory that the screen shows. One pixel is 4 bytes in it.
- **Pitch**: how many bytes one row of the screen takes in memory, including any extra bytes at the end.
- **Cast**: telling the compiler to look at a value as a different type, like `as` in TypeScript.

They're all in the [glossary](../glossary.md) too.

## The idea

### 1. Limine is the stage crew

Think of a theater. Our kernel is the actor. The actor knows the lines, but somebody has to set up the stage first. That's the stage crew, and our crew is called **Limine**.

```
power on
   │
   ▼
firmware (BIOS or UEFI)        wakes up first, like in lessons 2 to 4
   │  loads
   ▼
Limine  (the stage crew)
   │  1. reads limine.conf             "which kernel? where is it?"
   │  2. puts kernel.elf in memory     following our floor plan (linker.ld)
   │  3. makes sure the CPU is in 64-bit mode
   │  4. sets up the address map       so 0xffffffff80000000 works
   │  5. gives us a stack (64 KiB)     the scratch paper from lesson 3
   │  6. answers our notes             "here is your screen"
   ▼
kmain()  (the actor walks on stage)
```

In lessons 2 to 4, our boot sector was the first code after the BIOS. It was stuck in 16-bit mode with only 512 bytes. Getting to 64-bit mode takes many careful steps. Limine does all of them for us.

When `kmain` starts, the crew has left. Limine never runs again. From now on, our code is in charge of the whole computer.

### 2. The address map

In lesson 5, we told the linker to put the kernel at `0xffffffff80000000`. That's about 18 billion billion. No computer has that much RAM.

It works because of an **address map**. Think of the contacts on your phone. You tap "Mom", and the phone dials the real number. Our code uses the big "name" address. The CPU looks it up in a table and finds the real spot in RAM.

Limine builds that table before it starts us. The CPU feature is called **paging**. It gets a whole lesson later (lesson 17). For now, it's enough to know that the crew set it up.

### 3. Notes for the crew: requests

How does our kernel ask Limine for things, if Limine is gone once `kmain` runs? It writes notes in advance, right inside `kernel.elf`.

A note is just a small block of numbers in our file:

```
the "screen" note, inside kernel.elf
┌───────────────────────────────────────────────┐
│ id:        c7b1dd30…  0a82e883…  9d5827dc…  … │  "I am a SCREEN note"
│ revision:  0                                  │  which version of this note
│ response:  nullptr     ← Limine writes here   │  the empty "answer" line
└───────────────────────────────────────────────┘
```

- **id**: a long, unusual number. Limine knows every id, so it can tell what kind of note this is.
- **response**: the empty answer line. Before it starts us, Limine writes the address of its answer here.

All our notes sit together, between two bookmarks:

```
.limine_requests  (a section of kernel.elf)
   [start marker]       bookmark: "notes start here"
   [base revision 6]    "I follow version 6 of Limine's rules"
   [screen note]        "please give me a screen"
   [end marker]         bookmark: "notes end here"
```

Limine searches our loaded kernel for the bookmark numbers, then reads every note between them.

**The base revision** is like "Form version 6" printed at the top of a form. If Limine understands version 6, it changes our last number from 6 to 0. So `kmain` checks first: "is it 0? Good, the crew understood me." If it isn't, we stop.

We don't type those long numbers ourselves. They come from **`limine.h`**, a file written by the Limine project. It's not our code, so it lives in `third_party/limine/`, next to its license. The license is called 0BSD, and it lets anyone use the file for anything.

### 4. Three new C++ words for the notes

```cpp
__attribute__((used, section(".limine_requests")))
volatile u64 base_revision[] = LIMINE_BASE_REVISION(6);
```

- **`volatile`**: the compiler is a clever assistant that memorizes things. It sees `response = nullptr`, sees that none of *our* code changes it, and could decide it's always `nullptr`. `volatile` tells it: "someone outside our code (Limine) writes here, so always look at the real memory."
- **`used`**: "keep this, even if no code seems to read it." In lesson 5, `-O2` deleted data that nothing used. Our bookmarks are never read by our code, only by Limine, so without `used` they could disappear.
- **`section(".limine_requests")`**: "put this in that compartment of the ELF file." Remember the whiteboards from lesson 5? This picks the whiteboard.

We put all four notes inside **`namespace { ... }`**, an anonymous namespace. Everything inside it is private to `requests.cpp`, like a TypeScript file that doesn't export something. Other files can't touch the notes. Instead, `requests.hpp` offers two small functions, like a reception desk:

- `validate_base_revision()` answers "did Limine understand version 6?"
- `get_framebuffer()` gives back the first screen, or `nullptr` if there's none.

### 5. A new room in the floor plan

The notes need their own place in `kernel.elf`, so the linker script gets one more segment:

```
0xffffffff80000000   notes     RW    Limine writes the answers here, so it must be writable
0xffffffff80001000   code      R E
...                  constants R, variables RW (when we have some)
```

It goes **first**, at the very start of the kernel. `KEEP(...)` tells the linker "never throw this away", and the three `KEEP` lines put the start bookmark first and the end bookmark last.

Because the notes come first, `kmain` is no longer at the very start. It moves to the next page, `0xffffffff80001000` and up. The entry point on the ELF label moves with it, so Limine still finds it.

### 6. The workbench and the suitcase: the ISO

The firmware can't open folders. It only knows how to read a **disk**. So we make an **ISO file**: a whole CD inside one file.

Think of packing a suitcase for a trip. `build/` is your **workbench**: it's messy, with `.o` files, `.d` files and the downloaded Limine. The CD must only hold what it needs, so we make a clean **suitcase folder**, `build/iso_root/`, and pack that:

```
build/                         the workbench
├── kernel/...  .o .d          from compiling
├── kernel.elf                 made by the link rule
├── limine/                    Limine's files, downloaded
├── iso_root/                  the suitcase: only what the CD needs
│   ├── boot/kernel.elf        the actor
│   ├── boot/limine/
│   │   ├── limine.conf        the instruction card
│   │   ├── limine-bios.sys    the crew, for the BIOS door
│   │   ├── limine-bios-cd.bin the BIOS door's first step
│   │   └── limine-uefi-cd.bin the UEFI door
│   └── EFI/BOOT/BOOTX64.EFI   the crew, in the usual UEFI spot
└── os.iso                     the packed suitcase
```

**Two doors.** Older PCs start with BIOS, like our warmup did. Newer ones start with UEFI. Our CD gets both doors, so it boots either way.

**Two tools pack it:**

- `xorriso` is the suitcase packer. It turns the folder into `os.iso`. It also needs to know where the two doors are, and those paths are **inside the suitcase**, like `boot/limine/limine-bios-cd.bin`. Think of a note in the suitcase saying "the BIOS door is in the boot/limine pocket", not "on my desk".
- `limine bios-install` writes Limine's own boot sector into the first 512 bytes, like the one you wrote in lesson 2. That's what lets BIOS start the file when it's copied to a USB stick instead of used as a CD. Limine's guide says never to skip it.

**Where Limine comes from.** The Makefile downloads Limine version 11.2.1 with `git clone`, once, into `build/limine/`. Then it builds Limine's small `limine` tool from its source file, `limine.c`. The version is pinned, so the files never change under us. `make clean` deletes them, and the next build downloads them again in a few seconds.

### 7. The instruction card: `limine.conf`

```
timeout: 3

/os
  protocol: limine
  path: boot():/boot/kernel.elf
```

| Line | Plain meaning |
|---|---|
| `timeout: 3` | show the menu for 3 seconds, then boot |
| `/os` | a menu entry called "os" (a line starting with `/`) |
| the indented lines | settings that belong to that entry |
| `protocol: limine` | "this kernel speaks the Limine notes language" |
| `path: boot():/boot/kernel.elf` | where the kernel is. `boot():` means "the same disk Limine came from" |

Limine looks for this file in a few fixed places on the disk. `boot/limine/` is one of them.

### 8. The screen is a mosaic

Think of the screen as a huge mosaic wall made of tiny tiles. The tiles are called **pixels**. In QEMU, the wall is 1280 × 800, about one million tiles.

Limine's answer to our screen note tells us **where in memory** that wall is. Each tile is **4 bytes** of memory. Write a number into those 4 bytes, and the tile changes color right away. The screen is like a window that always shows that piece of memory. That memory is the **framebuffer**.

**The color number works like a CSS color.** `#336699` in CSS is `0x00336699` here: `RR GG BB`, each from `00` to `FF`. The `00` in front isn't used. White is `0x00ffffff`, and black is `0x00000000`.

Limine's answer also tells us the size of the wall, `width` and `height`, and how many bits one tile has, `bpp` (bits per pixel). We only know how to paint 32-bit tiles, so if `bpp` isn't 32, we stop.

### 9. Rows and the margin: pitch

```
fb->address
   ▼
   row 0:  [dot][dot][dot] ... [dot] ░░
   row 1:  [dot][dot][dot] ... [dot] ░░
   ...
           └─ width dots × 4 bytes ─┘ ░░ = maybe some extra bytes
           └──────────── pitch bytes ──────┘
```

The rows sit one after another in memory, like lines on a notebook page. But the hardware may add a little margin at the end of each line. **`pitch`** is the full length of one line in bytes, margin included.

So to reach the next row, always jump `pitch` bytes, never `width × 4`. In QEMU there's often no margin, so that mistake would hide. On a real PC, it shows up as a slanted, broken picture.

Here's a tiny example: a screen 3 dots wide and 2 rows high, with `pitch = 16`. That's 12 bytes of dots and 4 bytes of margin per row:

```
byte:   0    4    8    12        16   20   24   28
        [d0] [d1] [d2] ░░░░      [d0] [d1] [d2] ░░░░
        └──── row 0 ──────┘      └──── row 1 ──────┘
        ▲                        ▲
        finger starts here       finger + 16 (pitch) = row 1
```

### 10. One address, two views: casts

In TypeScript you'd paint a grid with `grid[y][x] = color`. In memory there's no grid, only **one long strip of bytes**. So we keep a **finger** on the start of the current row, and look at the same address in two ways:

| View | What `+1` means | We use it for |
|---|---|---|
| `u8*` (bytes) | move 1 byte | jumping rows: `row += pitch` |
| `u32*` (dots) | move 4 bytes, one dot | painting: `dots[x] = color` |

`fb->address` is a `void*`, which means "an address, but I don't know what's there". You can't do math with it. So we switch views with a **cast**, like `as` in TypeScript:

- `static_cast<u8*>(fb->address)` turns the `void*` into bytes.
- `reinterpret_cast<u32*>(row)` turns bytes into dots.

C++ has two names because it wants you to say how risky the switch is. `reinterpret_cast` means "trust me, I know what's at this address".

### 11. Stopping for good: `halt_forever()`

`kmain` must never return (lesson 5), and now there are three places where it stops. So the sleeping loop becomes a small function in `kernel/arch/x86_64/cpu.hpp`. That folder is for code that only makes sense on this kind of CPU.

- **`cli; hlt`**: `cli` turns off interrupts, so nothing can wake the CPU. `hlt` is the sleep from lesson 5. The loop around them is just in case something wakes it anyway.
- **`volatile`** on the `__asm__`: "never remove or move this line."
- **`[[noreturn]]`**: a promise to the compiler and the reader that this function never comes back.
- **`inline`**: the function lives in a header, and many `.cpp` files will include it. Without `inline`, every one of them makes its own copy, and the linker complains about duplicates. `inline` tells it "they're all the same function, keep one".

## Build it

Seven files change or are new. The files in the repo have no comments. Here they have comments, to explain each line.

### `third_party/limine/`

Download `limine.h` and its license from the Limine project. The long number in the links pins this exact version:

```bash
mkdir -p third_party/limine
curl -fL -o third_party/limine/limine.h https://raw.githubusercontent.com/Limine-Bootloader/limine-protocol/877c2d4c50e170575f8b8e7fbf7b8fa89b1dc157/include/limine.h
curl -fL -o third_party/limine/LICENSE https://raw.githubusercontent.com/Limine-Bootloader/limine-protocol/877c2d4c50e170575f8b8e7fbf7b8fa89b1dc157/LICENSE
```

### `kernel/boot/limine.conf`

```
timeout: 3

/os
  protocol: limine
  path: boot():/boot/kernel.elf
```

### `kernel/boot/requests.hpp`

```cpp
#ifndef REQUESTS_HPP
#define REQUESTS_HPP

// <...> searches the folders given with -I, so this finds third_party/limine/limine.h.
#include <limine.h>

// The "reception desk": the only two things other files can use.
bool validate_base_revision();
struct limine_framebuffer* get_framebuffer();

#endif
```

### `kernel/boot/requests.cpp`

```cpp
#include "../../shared/types.hpp"
#include "./requests.hpp"

// Private to this file: nobody else can touch the notes.
namespace {
  // Bookmark: "notes start here".
  __attribute__((used, section(".limine_requests_start")))
  volatile u64 start_marker[] = LIMINE_REQUESTS_START_MARKER;

  // "I follow version 6 of Limine's rules." Limine sets the last number to 0 if it agrees.
  __attribute__((used, section(".limine_requests")))
  volatile u64 base_revision[] = LIMINE_BASE_REVISION(6);

  // "Please give me a screen." Limine writes its answer into .response.
  __attribute__((used, section(".limine_requests")))
  volatile limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0,
    .response = nullptr
  };

  // Bookmark: "notes end here".
  __attribute__((used, section(".limine_requests_end")))
  volatile u64 end_marker[] = LIMINE_REQUESTS_END_MARKER;
}

// True if Limine understood version 6.
bool validate_base_revision() {
  return LIMINE_BASE_REVISION_SUPPORTED(base_revision);
}

// The first screen, or nullptr if Limine didn't give us one.
struct limine_framebuffer* get_framebuffer() {
  if(framebuffer_request.response == nullptr) return nullptr;
  if(framebuffer_request.response->framebuffer_count == 0) return nullptr;
  return framebuffer_request.response->framebuffers[0];
}
```

In C++, the fields in `{ .id = ..., .revision = ..., .response = ... }` must come in the same order as in the struct.

### `kernel/arch/x86_64/cpu.hpp`

```cpp
#ifndef CPU_HPP
#define CPU_HPP

// Stop the CPU for good. It never returns.
[[noreturn]] inline void halt_forever() {
  while(1) {
    // cli: no interrupts can wake us. hlt: sleep.
    __asm__ volatile("cli; hlt");
  }
}

#endif
```

### `kernel/main.cpp`

```cpp
#include "../shared/types.hpp"
#include "./arch/x86_64/cpu.hpp"
#include "./boot/requests.hpp"

extern "C" void kmain() {
  // Did the crew understand our notes?
  if(!validate_base_revision()) halt_forever();

  // Did we get a screen with 4-byte (32-bit) dots?
  struct limine_framebuffer* fb = get_framebuffer();
  if(fb == nullptr || fb->bpp != 32) halt_forever();

  // The finger, at the start of row 0, counting in bytes.
  u8* row = static_cast<u8*>(fb->address);

  for(u64 y = 0; y < fb->height; y += 1) {
    // The same finger, counting in dots.
    u32* dots = reinterpret_cast<u32*>(row);
    for(u64 x = 0; x < fb->width; x += 1) {
      dots[x] = 0x00ffffff;   // white, like #ffffff in CSS
    }
    // Jump to the next row: the full line, margin included.
    row += fb->pitch;
  }

  halt_forever();
}
```

### `kernel/linker.ld`

```
ENTRY(kmain)

OUTPUT_FORMAT(elf64-x86-64)

PHDRS {
  limine PT_LOAD FLAGS(6);    /* new: the notes. Read + write, because Limine writes answers */
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
}

SECTIONS {
  . = 0xffffffff80000000;

  /* New: the notes come first. KEEP = never throw these away. */
  .limine_requests : {
    KEEP(*(.limine_requests_start))
    KEEP(*(.limine_requests))
    KEEP(*(.limine_requests_end))
  }: limine

  /* New: the code starts on the next page. */
  . = ALIGN(4096);
  .text : {
    *(.text*)
  }: text

  . = ALIGN(4096);
  .rodata : {
    *(.rodata*)
  }: rodata

  . = ALIGN(4096);
  .data : {
    *(.data*)
  }: data

  .bss : {
    *(COMMON)
    *(.bss*)
  }: data

  /DISCARD/ : {
    *(.note*)
    *(.eh_frame*)
  }
}
```

### `Makefile`

The recipe lines start with a TAB, as always.

```make
.PHONY: build run iso clean

CXX := clang++

# The flags from lesson 5, plus one new line at the end:
# -I third_party/limine means "also look in this folder for #include <...>".
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
-MP \
-I third_party/limine

BUILD := build/
TARGET := $(BUILD)kernel.elf
KERNEL := kernel/
SOURCE_FILES := $(shell find $(KERNEL) -name "*.cpp")
OBJECT_FILES = $(SOURCE_FILES:%.cpp=$(BUILD)%.o)
LINKER := $(KERNEL)linker.ld
LD := ld.lld
LDFLAGS = -T $(LINKER) -nostdlib -static

# New: where Limine gets downloaded (the crew).
LIMINECREW := $(BUILD)limine/
# New: the suitcase, and its two inner folders.
ISOROOT := $(BUILD)iso_root/
LIMINEBOOT := $(ISOROOT)boot/limine/
EFIBOOT := $(ISOROOT)EFI/BOOT/
ISO := $(BUILD)os.iso
LIMINECONF := $(KERNEL)boot/limine.conf

# The first rule is the default, so plain "make" still only builds the kernel.
build: $(TARGET)

$(TARGET): $(OBJECT_FILES) $(LINKER)
	$(LD) $(LDFLAGS) -o $@ $(OBJECT_FILES)

$(BUILD)%.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# New: pack the CD, then start a PC with it in the drive.
run: iso
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(ISO) -boot d

iso: $(ISO)

# New: pack the suitcase. Needs the kernel, Limine's tool and the instruction card.
$(ISO): $(TARGET) $(LIMINECREW)limine $(LIMINECONF)
	rm -rf $(ISOROOT)
	mkdir -p $(LIMINEBOOT) $(EFIBOOT)
	cp $< $(ISOROOT)boot
	cp $(LIMINECONF) $(LIMINEBOOT)
	cp $(LIMINECREW)limine-bios.sys $(LIMINECREW)limine-bios-cd.bin $(LIMINECREW)limine-uefi-cd.bin $(LIMINEBOOT)
	cp $(LIMINECREW)BOOTX64.EFI $(EFIBOOT)
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label $(ISOROOT) -o $@
	$(LIMINECREW)limine bios-install $@

# New: download Limine 11.2.1 and build its tool. The target is the tool itself,
# so if anything fails, make tries again from a clean folder next time.
$(LIMINECREW)limine:
	rm -rf $(LIMINECREW)
	git clone --depth=1 --branch=v11.2.1-binary https://github.com/limine-bootloader/limine.git $(LIMINECREW)
	$(MAKE) -C $(LIMINECREW)

clean:
	rm -rf $(BUILD)

-include $(OBJECT_FILES:.o=.d)
```

A few lines need a word:

- **`run: iso`**, and the recipe uses `$(ISO)`, not `$<`. `$<` would be the word `iso`, not the file.
- **`cp $< $(ISOROOT)boot`**: `$<` is the first prerequisite, `kernel.elf`. `cp` always goes `cp FROM TO`.
- **The `xorriso` line** is copied from Limine's own guide. Only two parts matter to us: `-b` names the BIOS door and `--efi-boot` names the UEFI door, both as paths inside the suitcase. The rest are standard CD settings.
- **`$(MAKE) -C $(LIMINECREW)`** runs make inside Limine's folder, where Limine's own small Makefile builds the `limine` tool.

## Run it

From the project folder:

```
make run
```

The first time, make does a lot:

```
clang++ ... -c kernel/boot/requests.cpp -o build/kernel/boot/requests.o
clang++ ... -c kernel/main.cpp -o build/kernel/main.o
ld.lld -T kernel/linker.ld -nostdlib -static -o build/kernel.elf build/kernel/boot/requests.o build/kernel/main.o
rm -rf build/limine/
git clone --depth=1 --branch=v11.2.1-binary https://github.com/limine-bootloader/limine.git build/limine/
Cloning into 'build/limine'...
Note: switching to 'deba356b4a70ee183ec3214864f0ba2ffe510b8c'.
You are in 'detached HEAD' state. ...
make -C build/limine/
cc -g -O2 -pipe -std=c99   limine.c  -o limine
rm -rf build/iso_root/
mkdir -p build/iso_root/boot/limine/ build/iso_root/EFI/BOOT/
cp ...
xorriso -as mkisofs ...
Writing to 'stdio:build/os.iso' completed successfully.
build/limine/limine bios-install build/os.iso
...
Limine BIOS stages installed successfully.
qemu-system-x86_64 -M q35 -m 2G -cdrom build/os.iso -boot d
```

The long "detached HEAD" note from git is normal. It means we asked for one fixed version (a tag), not a branch that keeps moving.

The next time, only the steps that are needed run again. Change the color in `main.cpp` and `make run` recompiles `main.cpp`, links, and packs a new CD, but doesn't download Limine again.

**Proof that the actor is on stage.** In the QEMU window, press **Ctrl+Alt+2** to open the monitor, as in lesson 2, and type:

```
(qemu) info registers
RIP=ffffffff80001152 RFL=00000002 [-------] CPL=0 II=0 A20=1 SMM=0 HLT=1
...
```

- `RIP=ffffffff8000...`: the CPU is inside our kernel, at its high address.
- `HLT=1`: it's asleep in `halt_forever()`.

**Ctrl+Alt+1** takes you back to the screen.

**The notes inside the file:**

```
$ readelf -l build/kernel.elf
...
  LOAD           0x0000000000001000 0xffffffff80000000 0xffffffff80000000
                 0x0000000000000080 0x0000000000000080  RW     0x1000
  LOAD           0x0000000000002000 0xffffffff80001000 0xffffffff80001000
                 0x0000000000000154 0x0000000000000154  R E    0x1000

 Section to Segment mapping:
  Segment Sections...
   00     .limine_requests
   01     .text
```

The notes' segment comes first, it's writable (`RW`), and it's `0x80` bytes long: 128 bytes for our four notes, plus a little padding.

```
$ nm -n build/kernel.elf
ffffffff80000000 d _ZN12_GLOBAL__N_112start_markerE
ffffffff80000020 d _ZN12_GLOBAL__N_113base_revisionE
ffffffff80000038 d _ZN12_GLOBAL__N_119framebuffer_requestE
ffffffff80000070 d _ZN12_GLOBAL__N_110end_markerE
ffffffff80001000 T _Z22validate_base_revisionv
ffffffff80001020 T _Z15get_framebufferv
ffffffff80001060 T kmain
```

The start bookmark is first and the end bookmark is last, with the two notes between them. The odd names are name mangling from lesson 5. `_GLOBAL__N_1` is the compiler's way of saying "inside the private namespace". `kmain` is no longer at the very start: it's on the next page, and `readelf -h` shows the same address as the entry point.

## What just happened

1. make compiled the two `.cpp` files and linked them. The notes went first, at `0xffffffff80000000`, and the code went on the next page.
2. make downloaded Limine 11.2.1 into `build/limine/` and built its `limine` tool.
3. make packed the suitcase: it copied the kernel, the instruction card and Limine's files into `build/iso_root/`, turned that into `build/os.iso` with `xorriso`, and added the BIOS boot sector with `limine bios-install`.
4. QEMU started a PC with `os.iso` in its CD drive. The BIOS found the BIOS door, and Limine started.
5. Limine read `limine.conf`, showed the menu, and after 3 seconds loaded `kernel.elf` into memory, following its segments.
6. Limine found our notes between the bookmarks. It changed the base revision's last number to 0, and wrote the address of its screen answer into `response`.
7. Limine set up 64-bit mode, the address map and a stack, then jumped to the entry point on the ELF label: `kmain`.
8. `kmain` checked both answers, painted 1280 × 800 dots, row by row, and went to sleep in `halt_forever()`.

## Common problems

- **`fatal error: 'limine.h' file not found`**: check that `third_party/limine/limine.h` exists, and that `-I third_party/limine` is in `CXXFLAGS`.
- **`a type specifier is required for all declarations`**, together with **`use of undeclared identifier 'used'`**: `__attribute__` is misspelled. It has two t's at the start: `__att...`. One typo like this can cause 20 errors. Always fix the first error first, because many of the others disappear with it.
- **`redefinition of 'name'`**: two notes have the same name. Give each one its own.
- **`expected unqualified-id`** on the screen note's line: the variable has a type but no name. Write the type, then the name: `volatile limine_framebuffer_request framebuffer_request = {`.
- **`use of undeclared identifier 'id'`**: a field in `{ ... }` is missing its dot. Write `.id =`, not `id =`.
- **`member reference base type 'volatile u64[3]' ... is not a structure or union`**: the base revision is a row of three numbers, not a struct, so it has no fields. Use `LIMINE_BASE_REVISION_SUPPORTED(base_revision)`.
- **`expected expression`** at a function: there's an `=` between `()` and `{`. In C++, the body comes right after the `()`.
- **`reference to 'framebuffer_request' is ambiguous`**: the header declares the note with `extern`, but the `.cpp` hides it in `namespace { }`. Now there are two different things with one name. Keep the note private, and remove the `extern` line from the header.
- **`unexpected header attribute: text`** from lld: a line in `PHDRS { }` is missing its `;`, so lld read the next line as part of it.
- **`; expected, but got .text`**: the line `. = ALIGN(4096)` needs a `;` at the end.
- **`ld.lld: error: duplicate symbol: halt_forever()`**: a function written in a header is missing `inline`, and two `.cpp` files include it.
- **`warning: comparison of integers of different signs`**: a loop counter is `int`, but `width` and `height` are `u64`. Make the counter `u64` too.
- **`No rule to make target 'build/limine//limine'`**: there's a double slash. If a variable already ends with `/`, don't add another one after it.
- **`cp: cannot stat '...': No such file or directory`**: `cp` couldn't find the file to copy. Check the order, which is always `cp FROM TO`, and read the path letter by letter. A missing `/` at the end of a variable glues two names together, like `build/boot/liminelimine.conf`.
- **`xorriso : FAILURE : Cannot find in ISO image: -boot_image ...`**: the paths after `-b` and `--efi-boot` must be paths inside the suitcase, like `boot/limine/limine-bios-cd.bin`, without `build/iso_root/` in front.
- **`qemu-system-x86_64: -cdrom iso: Could not open 'iso'`**: the recipe used `$<`, and the first prerequisite is the word `iso`, not the file. Use `$(ISO)`.
- **`fatal: destination path 'build/limine' already exists and is not an empty directory.`**: `git clone` won't clone into a folder that already exists. Delete `build/limine/`, or keep the `rm -rf $(LIMINECREW)` line before `git clone`.
- **`git clone` fails with a network error**: the first build needs the internet to download Limine. Later builds don't, until the next `make clean`.
- **Limine shows ``PANIC: limine: Failed to open executable with path `boot():/kernel.elf`. Is the path correct?``**: the `path:` in `limine.conf` doesn't match where the Makefile puts the kernel inside the suitcase. Ours is `boot():/boot/kernel.elf`.
- **The menu shows, then the screen stays black**: `kmain` stopped at one of its `halt_forever()` calls before painting. Check that the base revision is 6 and that the notes are in the right sections. To find out which stop it was, look at `RIP` in `info registers` and find that address in `objdump -d -M intel build/kernel.elf`.
- **The picture looks slanted or broken** (on a real PC, or with other screen sizes): the loop jumps `width * 4` bytes per row instead of `pitch`.
- **`Clock skew detected`**: harmless, the same as in lesson 4.

## Try this

- **Your own color.** Take any CSS color, like `#e63946`, and write it as `0x00e63946`. Red is `0x00ff0000`, green is `0x0000ff00` and blue is `0x000000ff`.
- **Paint only half.** Change the row loop to `y < fb->height / 2`. The top half gets your color and the bottom half stays black. Can you paint a vertical stripe instead, by changing the `x` loop?
- **Boot with UEFI.** Start QEMU with UEFI firmware instead of BIOS:
  ```
  qemu-system-x86_64 -M q35 -m 2G -cdrom build/os.iso -drive if=pflash,unit=0,format=raw,file=/usr/share/OVMF/OVMF_CODE_4M.fd,readonly=on
  ```
  You get the same Limine menu and the same color, through the other door. If the file isn't there, `sudo apt install ovmf` installs it.
- **Ask for a version Limine doesn't know.** Change `LIMINE_BASE_REVISION(6)` to `LIMINE_BASE_REVISION(99)`. The menu still shows, but the screen stays black: Limine left our 99 alone, so `validate_base_revision()` said no. `info registers` shows `RIP` inside `kmain`'s first stop. Change it back to 6.
- **Watch the compiler paint.** Run `objdump -d -M intel build/kernel.elf` and look inside `kmain` for `movabs r10,0xffffff00ffffff`. That's our color twice: clang paints two dots with one 8-byte write, because it's faster.

Next, in lesson 7, the kernel learns to talk: it sends text out through the serial port, and it shows up in the Ubuntu terminal.
