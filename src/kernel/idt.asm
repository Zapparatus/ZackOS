global loadIDT
loadIDT:
    push ebp
    mov ebp, esp
    pusha

    cli
    lidt [IDTPointer]

    popa
    mov esp, ebp
    pop ebp
    ret

global initIDT
initIDT:
    push ebp
    mov ebp, esp
    pusha

    mov al, 0x11
    mov dx, 0x20
    out dx, al
    mov dx, 0xA0
    out dx, al
    mov al, 0x20
    mov dx, 0x21
    out dx, al
    mov al, 0x28
    mov dx, 0xA1
    out dx, al
    mov al, 0x04
    mov dx, 0x21
    out dx, al
    mov al, 0x02
    mov dx, 0xA1
    out dx, al
    mov al, 0x01
    mov dx, 0x21
    out dx, al
    mov dx, 0xA1
    out dx, al
    mov al, 0x00
    mov dx, 0x21
    out dx, al
    mov dx, 0xA1
    out dx, al

    mov eax, IDTStart
    xor ecx, ecx
    initIDTLoop:
        push dword eax
        push dword DefaultISRs
        call installIRQHandler
        add esp, 0x08
        add eax, 8
        inc ecx
        cmp eax, IDTEnd
        jl initIDTLoop

    push dword 0x21
    push dword KeyboardISR
    call installIRQHandler
    add esp, 0x08

    push dword 0x20
    push dword processTimerIRQ
    call installIRQHandler
    add esp, 0x08

    popa
    mov esp, ebp
    pop ebp
    ret

extern ProcessTimer

processTimerIRQ:
    pushad
    push es

    call ProcessTimer

    mov al, 0x20
    mov dx, 0x20
    out dx, al

    pop es
    popad
    iret

installIRQHandler:
    push ebp
    mov ebp, esp
    pusha

    mov eax, 0x08
    xor ecx, ecx
    mov ecx, dword [ebp + 0x0C]
    mul cl
    add eax, IDTStart

    mov ebx, dword [ebp + 0x08]
    mov word [eax], bx
    mov word [eax + 2], 0x0008
    mov byte [eax + 4], 0x00
    mov byte [eax + 5], 0x8E
    rol ebx, 0x10
    mov word [eax + 6], bx

    popa
    mov esp, ebp
    pop ebp
    ret

DefaultISRs:
    pushad
    cld

    mov eax, 0xB8000
    mov byte [eax], 'A'

    mov al, 0x20
    out 0x20, al

    ;hlt

    popad
    iret

extern HandleKeyboard

KeyboardISR:
    pushad
    cld

    xor eax, eax
    in al, 0x60

    mov bx, 0x00
    cmp ax, 0x59
    jl .Pressed
    inc bx
    sub ax, 0x80
.Pressed:
    push bx

    mov ebx, dword keyboardCodes
    add ebx, eax
    push dword [ebx]
    call HandleKeyboard
    pop ebx
    pop bx

.Finish:
    mov al, 0x20
    out 0x20, al

    popad
    iret

keyboardCodes:
    db 0x00,0x00,'1','2','3','4','5','6','7','8','9','0','-','=',0x08,0x09      ;0x00-0x0F
    db 'q','w','e','r','t','y','u','i','o','p','[',']',0x00,0x00,'a','s'        ;0x10-0x1F
    db 'd','f','g','h','j','k','l',';',0x27,'`',0x00,'\','z','x','c','v'        ;0x20-0x2F
    db 'b','n','m',',','.','/',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00  ;0x30-0x3F
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,'7','8','9','-','4','5','6','+','1'   ;0x40-0x4F
    db '2','3','0','.',0x00,0x00,0x00,0x00,0x00                                 ;0x50-0x58
shiftKeyboardCodes:
    db 0x00,0x00,'!','@','#','$','%','^','&','*','(',')','_','+',0x00,0x00      ;0x00-0x0F
    db 'Q','W','E','R','T','Y','U','I','O','P','{','}',0x00,0x00,'A','S'        ;0x10-0x1F
    db 'D','F','G','H','J','K','L',':',0x22,'~',0x00,'|','Z','X','C','V'        ;0x20-0x2F
    db 'B','N','M','<','>','?',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00  ;0x30-0x3F
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,'7','8','9','-','4','5','6','+','1'   ;0x40-0x4F
    db '2','3','0','.',0x00,0x00,0x00,0x00,0x00                                 ;0x50-0x58

IDTStart:
    times 0x100 dq 0
IDTEnd:

IDTPointer:
    dw IDTEnd - IDTStart - 1
    dd IDTStart
