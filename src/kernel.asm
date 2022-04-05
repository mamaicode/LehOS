[BITS 32] ;so that all code after this is seen as 32bits
global _start ;exports the symbol otherwise it wont be publically known

CODE_SEG equ 0x08 ;kernel code segment
DATA_SEG equ 0x10 ;data segment

_start:
    mov ax, DATA_SEG  ;setting up data registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000;setting base pointer to point to 0x00200000
    mov esp, ebp;setting stack pointer to base pointer as well

    ;enabling A20 line, which is the physical representation of the 21st bit 
    in al, 0x92
    or al, 2
    out 0x92, al

    jmp $

