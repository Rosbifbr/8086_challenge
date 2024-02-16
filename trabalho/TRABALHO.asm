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
cmd db 128 dup(0) ;Buffer for command line
cmd_size dw 0 ;Size of command line
infile db 64 dup(0) ;Buffer for input file
outfiles db 64 dup(0) ;Buffer for output file
voltage db 64 dup(0) ;Buffer for voltage

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Code
.code
.startup


.exit 0 ; Return to OS (err code 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Errors
e_noparami:
lea dx, noparam_i
call printstring
.exit 1

e_noparamo:
lea dx, noparam_o
call printstring
.exit 2

e_noparamv:
lea dx, noparam_v
call printstring
.exit 3

e_wrongparamv:
lea dx, wrongparam_v
call printstring
.exit 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Functions

;Input: AL = character to print
;Output: None
printchar proc near
    mov ah,02h
    int 21h
    ret
printchar endp

;Input: DS:DX = pointer to string to print (terminated with $)
;Output: None
printstring proc near
    mov ah,09h
    int 21h
    ret
printstring endp

END