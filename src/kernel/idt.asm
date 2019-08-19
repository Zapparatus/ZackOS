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

    mov ebx, 18
    call init_PIT

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

IRQ0_fractions:          resd 1          ; Fractions of 1 ms between IRQs
IRQ0_ms:                 resd 1          ; Number of whole ms between IRQs
IRQ0_frequency:          resd 1          ; Actual frequency of PIT
PIT_reload_value:        resw 1          ; Current PIT reload value
global init_PIT
init_PIT:
    pushad
 
    ; Do some checking
 
    mov eax,0x10000                   ;eax = reload value for slowest possible frequency (65536)
    cmp ebx,18                        ;Is the requested frequency too low?
    jbe .gotReloadValue               ; yes, use slowest possible frequency
 
    mov eax,1                         ;ax = reload value for fastest possible frequency (1)
    cmp ebx,1193181                   ;Is the requested frequency too high?
    jae .gotReloadValue               ; yes, use fastest possible frequency
 
    ; Calculate the reload value
 
    mov eax,3579545
    mov edx,0                         ;edx:eax = 3579545
    div ebx                           ;eax = 3579545 / frequency, edx = remainder
    cmp edx,3579545 / 2               ;Is the remainder more than half?
    jb .l1                            ; no, round down
    inc eax                           ; yes, round up
 .l1:
    mov ebx,3
    mov edx,0                         ;edx:eax = 3579545 * 256 / frequency
    div ebx                           ;eax = (3579545 * 256 / 3 * 256) / frequency
    cmp edx,3 / 2                     ;Is the remainder more than half?
    jb .l2                            ; no, round down
    inc eax                           ; yes, round up
 .l2:
 
 
 ; Store the reload value and calculate the actual frequency
 
 .gotReloadValue:
    push eax                          ;Store reload_value for later
    mov [PIT_reload_value],ax         ;Store the reload value for later
    mov ebx,eax                       ;ebx = reload value
 
    mov eax,3579545
    mov edx,0                         ;edx:eax = 3579545
    div ebx                           ;eax = 3579545 / reload_value, edx = remainder
    cmp edx,3579545 / 2               ;Is the remainder more than half?
    jb .l3                            ; no, round down
    inc eax                           ; yes, round up
 .l3:
    mov ebx,3
    mov edx,0                         ;edx:eax = 3579545 / reload_value
    div ebx                           ;eax = (3579545 / 3) / frequency
    cmp edx,3 / 2                     ;Is the remainder more than half?
    jb .l4                            ; no, round down
    inc eax                           ; yes, round up
 .l4:
    mov [IRQ0_frequency],eax          ;Store the actual frequency for displaying later
 
 
 ; Calculate the amount of time between IRQs in 32.32 fixed point
 ;
 ; Note: The basic formula is:
 ;           time in ms = reload_value / (3579545 / 3) * 1000
 ;       This can be rearranged in the follow way:
 ;           time in ms = reload_value * 3000 / 3579545
 ;           time in ms = reload_value * 3000 / 3579545 * (2^42)/(2^42)
 ;           time in ms = reload_value * 3000 * (2^42) / 3579545 / (2^42)
 ;           time in ms * 2^32 = reload_value * 3000 * (2^42) / 3579545 / (2^42) * (2^32)
 ;           time in ms * 2^32 = reload_value * 3000 * (2^42) / 3579545 / (2^10)
 
    pop ebx                           ;ebx = reload_value
    mov eax,0xDBB3A062                ;eax = 3000 * (2^42) / 3579545
    mul ebx                           ;edx:eax = reload_value * 3000 * (2^42) / 3579545
    shrd eax,edx,10
    shr edx,10                        ;edx:eax = reload_value * 3000 * (2^42) / 3579545 / (2^10)
 
    mov [IRQ0_ms],edx                 ;Set whole ms between IRQs
    mov [IRQ0_fractions],eax          ;Set fractions of 1 ms between IRQs
 
 
 ; Program the PIT channel
 
    pushfd
    cli                               ;Disabled interrupts (just in case)
 
    mov al,00110100b                  ;channel 0, lobyte/hibyte, rate generator
    out 0x43, al
 
    mov ax,[PIT_reload_value]         ;ax = 16 bit reload value
    out 0x40,al                       ;Set low byte of PIT reload value
    mov al,ah                         ;ax = high 8 bits of reload value
    out 0x40,al                       ;Set high byte of PIT reload value
 
    popfd
 
    popad
    ret

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
