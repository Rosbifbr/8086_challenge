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

.data ;Data segment

;Sample
message DB 'Hello World!$'
msg_size EQU $-MENSAGEM
counter DB ? ;dont care



.code ;Code segment
.startup
;Configure 21h to print string
mov ah, 09h ;Function 09h - Print string
lea dx, message ;Load message address
int 21h ;Call DOS

.exit 0 ; Return to DOS

;Functions here. Move to other segment if needed

END