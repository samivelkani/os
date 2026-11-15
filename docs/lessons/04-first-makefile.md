# Lesson 4: The first Makefile

## Goal

Stop typing the same long commands by hand. After this lesson, one command builds the boot sector when it needs building, then starts QEMU: `make run`.

## What you'll see

```
$ make run
mkdir -p ../build/warmup/ && \
nasm -f bin boot.asm -o ../build/warmup/boot.bin
qemu-system-x86_64 -drive format=raw,file=../build/warmup/boot.bin
```

QEMU opens and shows "Hello There", the same screen as in lesson 3. The screen didn't change. What changed is how we get there.

Run `make run` a second time and the `nasm` line is gone. Nothing changed since the last build, so make skips it and goes straight to QEMU.

## New words

- **Make**: a program that runs build commands for you, and only the ones that are needed.
- **Makefile**: the file that tells make what to build and how.
- **Rule**: one entry in a Makefile: a target, its prerequisites, and a recipe.
- **Target**: the file a rule makes, or the name of a job like `run`.
- **Prerequisite**: a file the target is built from.
- **Recipe**: the shell commands that make the target. Each line starts with a TAB.
- **Phony target**: a target that's a job, not a file, like `run` or `clean`.
- **Automatic variable**: a short name make fills in for each rule, like `$@` for the target.
- **Environment variable**: a named value that every program gets from the shell that started it, like `PATH`.

They're all in the [glossary](../glossary.md) too.

## The idea

### Why a build tool

Until now we built and ran the boot sector with three commands, typed by hand every time. In TypeScript you'd put commands like these in the `"scripts"` part of `package.json` and type `npm run build`. Make does that job too, with one big extra: it knows which files each output is built from. If none of them changed since the last build, it skips the work. That's like `tsc --incremental`, but for any command.

For one boot sector that builds in a blink, this hardly matters. For the kernel, which will have about a hundred files, it matters a lot. Change one file, and make rebuilds that one, not all of them.

### A rule

A Makefile is a list of rules. Every rule has three parts:

```makefile
target: prerequisites
	recipe
```

- The **target** is the file you want.
- The **prerequisites** are the files it's built from. There can be zero or more, separated by spaces.
- The **recipe** is the shell commands that build it. There can be zero or more lines, and **every line must start with a TAB**, not spaces. That rule goes back to the first version of make, from 1976, and it never changed.

A toy example:

```makefile
hello.txt: name.txt
	cp name.txt hello.txt
```

This reads as: "to make `hello.txt`, you need `name.txt`, and then you run `cp`."

### How make decides what to run

Make looks at the time each file was last changed. It runs a target's recipe when:

- the target file doesn't exist yet, or
- any prerequisite was changed **after** the target was made.

Otherwise the target is up to date, and make says `Nothing to be done`. That's why the `nasm` line disappeared on the second `make run`.

`touch print.asm` sets the file's "last changed" time to now, without changing what's inside. It's a quick way to make make think a file changed.

### Rules form a tree

When you ask for a target, make looks at its prerequisites. If a prerequisite is the target of another rule, make deals with that rule first, then with that rule's prerequisites, and so on. Our Makefile makes this tree:

```
run
└── ../build/warmup/boot.bin
    ├── boot.asm
    └── print.asm
```

Make works from the bottom up. `boot.asm` and `print.asm` have no rules, but they exist, so they're fine as they are. Then make decides whether `boot.bin` needs building. Then it runs `run`.

Because make follows the tree, **the order of the rules in the file doesn't matter**, with one exception: plain `make`, with no target, runs the **first** rule. Many projects call that first rule `all`. We call ours `build`.

### Variables

A variable is a name for some text:

```makefile
ASM = nasm
```

You use it as `$(ASM)`, and make swaps it for `nasm` before it runs anything. Always use the brackets: make reads `$ASM` as the one-letter variable `$A` followed by the text `SM`.

There are two ways to set a variable:

- `NAME := value` works out the value once, right there. It's like `const` in TypeScript.
- `NAME = value` works it out again every time it's used, like a getter.

For plain text like ours, both give the same result.

Two rules for variables:

- **Define them at the top.** Make fills in the variables in a rule's first line as soon as it reads that line. A variable defined further down is still empty at that point. There's no error: the prerequisite quietly disappears, and make says `Nothing to be done`.
- **Don't reuse a name that's already taken.** Every program gets a set of *environment variables* from the shell that started it, and make sees them as variables too. The most important one is `PATH`, the list of folders where the shell looks for programs like `mkdir` and `nasm`. A Makefile variable called `PATH` replaces it for every command make runs, and suddenly no program can be found. Pick names like `BUILD` or `OUT` instead. To see your own `PATH`, type `echo $PATH` in the terminal.

### Automatic variables

Inside a recipe, make fills in a few short names for you:

| Name | Means |
|---|---|
| `$@` | the target of this rule |
| `$<` | the first prerequisite |
| `$^` | all the prerequisites |

They save typing, and they keep each name in one place. If the target's path changes, the recipe follows on its own.

### Jobs that aren't files: `.PHONY`

`run` and `clean` don't make files called `run` or `clean`. They're names for jobs. We tell make that with:

```makefile
.PHONY: build run clean
```

Without it, make treats `clean` like any other target: as a file name. If a file called `clean` ever shows up in the folder, make finds it, sees no prerequisites that are newer, and says `'clean' is up to date`. And it doesn't clean.

`.PHONY` is a special target, so it needs a colon. `.PHONY = ...` with an equals sign makes an ordinary variable with a strange name, and does nothing.

### Where make runs

We run make **inside `warmup/`**, and every path in this Makefile is written from there:

- The output goes to `../build/warmup/boot.bin`. That's still the `build/` folder at the top of the project, the one git ignores.
- nasm finds `print.asm` on its own now, so we don't need `-i` anymore. nasm looks for included files in the folder it runs in, and that's now `warmup/`.

Paths are always relative, never full paths like `/mnt/c/Users/...`. Make splits words at spaces, so a full path with a space in it, like a Windows user name with two words, falls apart.

Each line of a recipe runs in **its own new shell**, so a `cd` on one line is forgotten by the next. And `cd` only moves the shell, never make: make still checks files from the folder it started in. Writing every path from that one folder keeps things simple.

## Build it

Create `warmup/Makefile`, with exactly that name and a capital M. Here it is with comments:

```makefile
# Jobs that aren't files.
.PHONY: build run clean

# Every path is written from warmup/, the folder make runs in.

# The build folder. It ends with "/", so a file name can follow it directly.
BUILD := ../build/warmup/

# The file we make: ../build/warmup/boot.bin
TARGET = $(BUILD)boot.bin

# The assembler, and the options we always give it.
ASM = nasm
ASMFLAGS = -f bin

# Every file boot.bin is built from.
ASMFILES = boot.asm print.asm

# The first rule, so plain "make" runs this one.
# It's a short name for the real file, with no recipe of its own.
build: $(TARGET)

# Turn the .asm files into boot.bin.
# $< is boot.asm, the first prerequisite. $@ is the target, boot.bin.
$(TARGET): $(ASMFILES)
	mkdir -p $(BUILD) && \
	$(ASM) $(ASMFLAGS) $< -o $@

# Build boot.bin if needed, then start QEMU with it.
# Here $< is boot.bin, the first (and only) prerequisite.
run: $(TARGET)
	qemu-system-x86_64 -drive format=raw,file=$<

# Delete only what this Makefile built.
clean:
	rm -rf $(BUILD)
```

A few things to notice:

- **`print.asm` is a prerequisite**, even though the nasm command never names it. If it weren't in the list, changing `print.asm` wouldn't rebuild anything.
- **nasm gets `$<`, not `$^`.** nasm takes only one input file. `$^` would hand it both files, and it would stop with `more than one input file specified`. `print.asm` gets in through the `%include` in `boot.asm`.
- **`mkdir -p`** creates the folder, plus any missing folders above it, and stays quiet if it already exists.
- **`&& \`.** The `\` at the end of a line joins the next line to it, so both commands run in one shell, as one command. The `&&` runs nasm only if `mkdir` worked. These two lines don't depend on each other, so two plain lines would work too.
- **`clean` deletes `../build/warmup/` and nothing else.** The kernel will build into `build/` too, later. An `rm -rf` line is worth reading twice, and `make -n clean` shows exactly what it would delete, without deleting it.
- **Comments go on their own line.** A comment at the end of a variable line keeps the spaces before the `#` as part of the value. `BUILD := ../build/warmup/ # folder` gives `../build/warmup/ ` with a space on the end, and `$(BUILD)boot.bin` turns into two words. Inside a recipe, a comment line that starts with a TAB is handed to the shell, so make prints it.

In the repo, the file has no comments, because this page explains it.

## Run it

In the Ubuntu terminal, from the project folder:

```bash
cd warmup
make
```

It prints the two commands it runs. Then try each of these:

1. `make` again: `make: Nothing to be done for 'build'.`
2. `make run`: QEMU opens with "Hello There". Close the window when you're done.
3. `touch print.asm`, then `make`: it builds again, because `print.asm` now looks newer than `boot.bin`.
4. `make clean`: `build/warmup/` is gone.

You can also stay in the project folder and run `make -C warmup run`. `-C` means "go into this folder first". Make then prints `Entering directory` and `Leaving directory` around its work.

VS Code uses TABs on its own in a file named `Makefile`. When the file is open, the bottom-right corner says "Tab Size", not "Spaces". To check the file itself, run `cat -A Makefile`: every TAB shows up as `^I`.

## What just happened

Here's `make run` when `build/warmup/` doesn't exist yet:

1. Make read the whole Makefile first and filled in the variables in the rule lines. `$(TARGET)` became `../build/warmup/boot.bin`.
2. We asked for `run`. It's phony, so make didn't look for a file called `run`. It went to its prerequisite, `../build/warmup/boot.bin`.
3. There's a rule for that file. Its prerequisites, `boot.asm` and `print.asm`, have no rules of their own, but they exist, so they're fine.
4. `boot.bin` didn't exist, so make ran its recipe. It printed each command, then ran it in a shell.
5. With `boot.bin` ready, make went back to `run` and started QEMU.

The second time, `boot.bin` existed and was newer than both `.asm` files, so make skipped step 4.

### Ask make why

`make -n` (a *dry run*) prints the commands make would run, without running any of them. `make --trace` runs them and says why:

```
$ make --trace
Makefile:11: update target '../build/warmup/boot.bin' due to: boot.asm print.asm
mkdir -p ../build/warmup/ && \
nasm -f bin boot.asm -o ../build/warmup/boot.bin
```

`Makefile:11` is the line in the repo's file where the recipe starts. The list after `due to:` is the prerequisites that made the difference. When the target doesn't exist yet, that's all of them. After `touch print.asm`, it says `due to: print.asm` only.

## Common problems

- **make says `Makefile:2: *** missing separator.  Stop.`** A recipe line starts with spaces instead of a TAB. The number is the line. Check with `cat -A Makefile`: a TAB shows up as `^I`.
- **make says `No targets` or `no makefile found`.** You're probably in a different folder from the Makefile you meant. Run `cd warmup` first, or use `make -C warmup`.
- **The shell says `mkdir: not found`, and make says `Error 127`.** 127 means "command not found". A variable in the Makefile is probably called `PATH`, which replaces the list of folders where the shell looks for programs. Rename it, for example to `BUILD`.
- **make says `No rule to make target 'X', needed by 'Y'.`** Make needs a file called `X`, it doesn't exist, and no rule makes it. Check that:
  - the path is written from the folder make runs in, not from wherever a `cd` moved to
  - every variable has its `$( )` around it, because plain `ASMFILES` is just the word "ASMFILES"
  - the rule that builds the file uses the file's full path as its target, and the same path is used everywhere it's needed
- **make says `target pattern contains no '%'`.** A target got a `:` in it, so make read it as a special kind of rule. This usually means a variable holds something unexpected. `$(PATH)`, for example, is a list of folders joined with colons.
- **The build runs every time, even when nothing changed.** The rule's target isn't the file its recipe makes. If the rule is called `boot.bin` but nasm writes to `../build/warmup/boot.bin`, make never finds `boot.bin`, so it always runs the recipe.
- **Changing `print.asm` doesn't rebuild anything.** `print.asm` is missing from the prerequisites. Every file the output is built from belongs in that list.
- **nasm says `fatal: no input file specified`.** The input file name came out empty. Look for a variable that doesn't exist: `$>`, for example, isn't one of make's automatic variables, so make swaps it for nothing.
- **nasm says `fatal: more than one input file specified`.** The command uses `$^`, which is every prerequisite. Use `$<` for nasm.
- **QEMU says it can't open a file called `run`.** In the `run` rule, `$@` is `run`, the target. The disk file is the prerequisite, `$<`.
- **`make clean` says `'clean' is up to date` and doesn't clean.** A file named `clean` exists in the folder, and `clean` isn't marked as phony. Add it to the `.PHONY:` line, which needs a colon.
- **make says `Nothing to be done`, but `boot.bin` was never built.** A variable used in a rule line is defined below that rule, so it was still empty when make read the rule. Move the variables to the top.
- **A `cd` on one recipe line has no effect on the next line.** Each line runs in a new shell. Join the lines with `&& \`, or better, write the paths so that no `cd` is needed.
- **make warns about `Clock skew` or a file time "in the future".** Windows and WSL keep slightly different clocks, and the project lives on the Windows side. It's harmless. If a build ever looks out of date, run `make clean`, then `make`.

## Try this

- **Ask make why.** Run `touch print.asm`, then `make --trace`, and read the `due to:` part.
- **Quiet a line.** Put `@` at the start of the qemu line: `@qemu-system-x86_64 ...`. Make still runs it, but doesn't print it first. On lines joined with `\`, one `@` at the start hides all of them.
- **Add a job.** Add a `disasm` rule that depends on `$(TARGET)` and runs `ndisasm -b 16 -o 0x7C00 $< | head -20`, and add `disasm` to the `.PHONY` line. Now `make disasm` builds if needed, then shows the first instructions, like in lesson 3.
- **See the separate shells.** Make a test rule with `cd /` on one recipe line and `pwd` on the next. `pwd` still prints the path of `warmup/`. Then join the two lines with `&& \` and run it again: now it prints `/`.
- **Break it on purpose.** Replace one TAB with spaces, or move the `TARGET = ...` line below the rules, and read what make says. Once you know the messages, they're quick to fix.

In lesson 5, we leave the boot sector behind and start the real kernel: C++ with no operating system underneath. The Makefile at the top of the project gets its first rules, and with many source files, it'll need rules that build many files at once.
