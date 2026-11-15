bits 16
org 0x7C00
xor ax, ax
mov ss, ax
mov sp, 0x7C00
mov ds, ax
mov si, msg
call print
cli
hang:
  hlt
  jmp hang
; Helpers
%include "print.asm"
msg:
  db 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x54, 0x68, 0x65, 0x72, 0x65, 0x00
; -----------------------------------------
times 510-($-$$) db 0
dw 0xAA55