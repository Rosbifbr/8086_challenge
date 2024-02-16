; Name: Rodrigo Ourique
; UFRGS Card: 00581169
; Program: Tension File Parser
; Target Architecture: Intel 8086
; Target Assembler: MASM 6.11
; Target Operating System: MS-DOS 

; Description:
; Option [-i] (file in)
; Option [-o] (file out)
; Option [-v] (voltage - 127 or 220)
; File lines must be like: 
; 120,130,127
; 121, 119 , 125
; 123, 124, 128
; (Whitespace must be ignored)

; Model and stack config
.model small
.stack 2048

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Data
.data

;Strings
noparam_i db 'Opcao [-i] sem parametro$'
noparam_o db 'Opcao [-o] sem parametro$'
noparam_v db 'Opcao [-v] sem parametro$'
wrongparam_v db 'Parametro da opção [-v] deve ser 127 ou 220$'
;Linha <número da linha> inválido: <conteúdo da linha>
line_0 db 'Linha $'
line_1 db ' Valor inválido: $'

;Variables
cmd_size db 0 ;Size of command line
cmd db 128 dup(0) ;Buffer for command line
infile db 64 dup(0) ;Buffer for input file
outfiles db 64 dup(0) ;Buffer for output file
voltage db 64 dup(0) ;Buffer for voltage

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Code
.code
.startup

;PSP argument collection. Provided by the assignment
push ds ; Salva as informações de segmentos
push es

mov ax,ds; Troca DS com ES para poder usa o REP MOVSB
mov bx,es
mov ds,bx
mov es, ax
mov si,80h; Obtém o tamanho do string da linha de comando e coloca em CX
mov ch,0
mov cl,[si]
mov ax,cx ; Salva o tamanho do string em AX, para uso futuro
mov si,81h; Inicializa o ponteiro de origem
lea di,cmd ; Inicializa o ponteiro de destino
rep movsb

pop es ; retorna as informações dos registradores de segmentos
pop ds

mov cmd_size, al ; Store command size

;;Check argument size
cmp cmd_size, 0
je e_noparami

;Print commadn line
lea bx, cmd
call printf_s

.exit 0 ; Return to OS (err code 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Errors
e_noparami:
lea dx, noparam_i
call printf_dos
.exit 1

e_noparamo:
lea dx, noparam_o
call printf_dos
.exit 2

e_noparamv:
lea dx, noparam_v
call printf_dos
.exit 3

e_wrongparamv:
lea dx, wrongparam_v
call printf_dos
.exit 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Functions

;Print char (Native to MSDOS)
;Input: DL = character to print
;Output: None
putchar proc near
    mov ah,02h
    int 21h
    ret
putchar endp

;Print $ terminated string (Native to MSDOS)
;Input: DS:DX = pointer to string to print (terminated with $)
;Output: None
printf_dos proc near
    mov ah,09h
    int 21h
    ret
printf_dos endp

;Print \0 terminated string
;Input: BX = pointer to string to print (terminated with \0)
;Output: None
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1
	push	bx
    call    putchar
	pop		bx
	inc		bx
    jmp		printf_s		
    ps_1:
	ret
printf_s	endp

END