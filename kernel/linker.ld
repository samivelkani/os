ENTRY(kmain)

OUTPUT_FORMAT(elf64-x86-64)

PHDRS {
  limine PT_LOAD FLAGS(6);
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
}

SECTIONS {
  . = 0xffffffff80000000;

  .limine_requests : {
    KEEP(*(.limine_requests_start))
    KEEP(*(.limine_requests))
    KEEP(*(.limine_requests_end))
  }: limine

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