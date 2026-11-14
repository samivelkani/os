; Creating our first character display
; We assume that this file is what disk gives us from its first sector (512 bytes). Note that it is in memory, not storage like disk
; We make it success by adding two last bytes exactly 55 AA

bits 16                   ; tells the nasm to produce a 16 bit code as output
org 0x7C00                ; tells the nasm what is the first address (in hexa) that code starts
mov al, 0x41              ; move 0x41 value ('A' value in ASCII) to al register (the second half, which is the low byte of ax register)
mov ah, 0x0E              ; move 0x0E value to ah register (the first half, which is the high byte of ax register). It tells to print the character in al register
int 0x10                  ; calls the BIOS video service and executes the command ah register has choosen (to print a character)
cli                       ; ignore hardware interrupts
hang:                     ; it is just a bookmark (stored in an address) and can be used whenever something jumps to it
  hlt                     ; puts the CPU in sleep until any interrupts arrive
  jmp hang                ; jump back to hang
times 510-($-$$) db 0     ; fills in the remaining bytes with 0. the calculation is 510 - the amount of bytes that are covered so far
dw 0xAA55                 ; last two bytes to make it 512 and success at the end