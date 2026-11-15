print:
  .loop:
    mov al, [ds:si]
    cmp al, 0x00
    je .done
    mov ah, 0x0E
    int 0x10
    inc si
    jmp .loop
  .done:
    ret