.PHONY: build run iso clean

CXX := clang++

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

LIMINECREW := $(BUILD)limine/

ISOROOT := $(BUILD)iso_root/

LIMINEBOOT := $(ISOROOT)boot/limine/

EFIBOOT := $(ISOROOT)EFI/BOOT/

ISO := $(BUILD)os.iso

LIMINECONF := $(KERNEL)boot/limine.conf

build: $(TARGET)

$(TARGET): $(OBJECT_FILES) $(LINKER)
	$(LD) $(LDFLAGS) -o $@ $(OBJECT_FILES)

$(BUILD)%.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: iso
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(ISO) -boot d

iso: $(ISO)

$(ISO): $(TARGET) $(LIMINECREW)limine $(LIMINECONF)
	rm -rf $(ISOROOT)
	mkdir -p $(LIMINEBOOT) $(EFIBOOT)
	cp $< $(ISOROOT)boot
	cp $(LIMINECONF) $(LIMINEBOOT)
	cp $(LIMINECREW)limine-bios.sys $(LIMINECREW)limine-bios-cd.bin $(LIMINECREW)limine-uefi-cd.bin $(LIMINEBOOT)
	cp $(LIMINECREW)BOOTX64.EFI $(EFIBOOT)
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label $(ISOROOT) -o $@
	$(LIMINECREW)limine bios-install $@

$(LIMINECREW)limine:
	rm -rf $(LIMINECREW)
	git clone --depth=1 --branch=v11.2.1-binary https://github.com/limine-bootloader/limine.git $(LIMINECREW)
	$(MAKE) -C $(LIMINECREW)

clean:
	rm -rf $(BUILD)

-include $(OBJECT_FILES:.o=.d)