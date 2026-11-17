.PHONY: build clean

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
-MP

BUILD := build/

TARGET := $(BUILD)kernel.elf

KERNEL := kernel/

SOURCE_FILES := $(shell find $(KERNEL) -name "*.cpp")

OBJECT_FILES = $(SOURCE_FILES:%.cpp=$(BUILD)%.o)

LINKER := $(KERNEL)linker.ld

LD := ld.lld

LDFLAGS = -T $(LINKER) -nostdlib -static

build: $(TARGET)

$(TARGET): $(OBJECT_FILES) $(LINKER)
	$(LD) $(LDFLAGS) -o $@ $(OBJECT_FILES)

$(BUILD)%.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD)

-include $(OBJECT_FILES:.o=.d)