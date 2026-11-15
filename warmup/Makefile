.PHONY: build run clean
BUILD := ../build/warmup/
TARGET = $(BUILD)boot.bin
ASM = nasm
ASMFLAGS = -f bin
ASMFILES = boot.asm print.asm

build: $(TARGET)

$(TARGET): $(ASMFILES)
	mkdir -p $(BUILD) && \
	$(ASM) $(ASMFLAGS) $< -o $@

run: $(TARGET)
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD)