MBALIGN equ 1 << 0
MEMINFO equ 1 << 1
FLAGS equ MBALIGN | MEMINFO
MAGIC equ 0x1BADB002
CHECKSUM equ -(MAGIC + FLAGS)

section .multiboot
align 4
  dd MAGIC
  dd FLAGS
  dd CHECKSUM

section .bss
align 16
stack_bottom:
resb 16384
stack_top:

section .text
global _start:function (_start.end - _start)
_start:
  mov esp, stack_top

  lgdt [GDTPointer]
  mov ax, 0x10
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  jmp 0x08:.flush
.flush:

  extern kernel_main
  call kernel_main
  cli
.hang:
  hlt
  jmp .hang
.end:

GDTStart:
NullDescriptor:
    dd 0x00
    dd 0x00
KernelCodeDescriptor:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10011010
    db 0b11001111
    db 0x00
KernelDataDescriptor:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10010010
    db 0b11001111
    db 0x00
GDTEnd:
GDTPointer:
    dw (GDTEnd-GDTStart - 1)
    dd GDTStart
