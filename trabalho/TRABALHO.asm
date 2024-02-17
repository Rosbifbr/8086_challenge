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
;PROGRAM

;Get infile param
mov bh, 'i'
call get_param ;si = pointer to infile or 0
mov dx,si ;store pointer
lea bx, infile ;store destination

cmp dx, 0
jne i_present ;if si == 0
lea dx, noparam_i
call printf_dos
lea dx,def_in_file
i_present:
call strcpy_s ;copy to infile

;get outfile param
mov bh, 'o'
call get_param ;si = pointer to outfile or 0
mov dx,si ;store pointer
lea bx, outfile ;store destination

cmp dx, 0
jne o_present ;if si == 0
lea dx, noparam_o
call printf_dos
lea dx,def_out_file
o_present:
call strcpy_s ;copy to outfile

;get voltage param
mov bh, 'v'
call get_param ;si = pointer to voltage or 0
mov dx,si ;store pointer
lea bx, voltage ;store destination

cmp dx, 0
jne v_present ;if si == 0
lea dx, noparam_v
call printf_dos
lea dx,def_voltage
v_present:
call strcpy_s ;copy to voltage

;DEBUG print files to test
; lea bx, infile
; call printf_s

; lea bx, outfile
; call printf_s

; lea bx, voltage
; call printf_s

;Validate voltage
lea bx, voltage
call atoi
mov effective_voltage, ax
cmp effective_voltage, 127
je voltage_ok
cmp effective_voltage, 220
je voltage_ok

lea dx, wrongparam_v
call printf_dos
voltage_ok:

.exit 0 ; Return to OS (err code 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Errors, exits


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Functions (a very rich stdlib i would say)

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
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
printf_dos endp

;Print \0 terminated string
;Input: BX = pointer to string to print (terminated with \0)
;Output: None
printf_s proc near
	mov dl,[bx]
	cmp dl,0
	je ps_1
    call putchar
	inc bx
    jmp printf_s		
ps_1:
	ret
printf_s endp


; get_char_f: File* (bx) -> Char (dl) Inteiro (AX) Boolean (CF)
; Obj.: Dado um arquivo, devolve um caractere, a posicao do cursor e define CF como 0 se a leitura deu certo (diferente d getchar() do C, mais pra um getc(FILE*))
get_char_f proc	near
	mov ah,3fh
	mov cx,1
	lea dx,file_buffer
	int 21h
	mov dl,file_buffer
	ret
get_char_f endp

; set_char_f: File* (bx) Char (dl) -> Inteiro (ax) Boolean (CF)
; Obj.: Dado um arquivo e um caractere, escreve esse caractere no arquivo e devolve a posicao do cursor e define CF como 0 se a leitura deu certo
set_char_f proc	near
	mov ah,40h
	mov cx,1
	mov file_buffer,dl
	lea dx,file_buffer
	int 21h
	ret
set_char_f endp

; fopen: String (dx) -> File* (bx) Boolean (CF)		(Passa o File* para o ax tambem, mas por algum motivo ele move pro bx)
; Obj.: Dado o caminho para um arquivo, devolve o ponteiro desse arquivo e define CF como 0 se o processo deu certo
fopen proc near
    mov al,0
    mov ah,3dh
    int 21h
    mov bx,ax
    ret
fopen endp

; fcreate: String (dx) -> File* (bx) Boolean (CF)
; Obj.: Dado o caminho para um arquivo, cria um novo arquivo com dado nome em tal caminho e devolve seu ponteiro, define CF como 0 se o processo deu certo
fcreate proc near
    mov cx,0
    mov ah,3ch
    int 21h
    mov bx,ax
    ret
fcreate endp

; fclose: File* (bx) -> Boolean (CF)
; Obj.: evitar um memory leak fechando o arquivo
fclose proc	near
	mov ah,3eh
	int 21h
	ret
fclose endp

; atoi: String (bx) -> Inteiro (ax)
; Obj.: recebe uma string e transforma em um inteiro
; Ex:
; lea bx, String1 (Em que String1 é db "2024",0)
; call atoi
; -> devolve o numero 2024 em ax
atoi proc near
    mov ax,0 
atoi_2:
    ; while (*S!='\0') {
    cmp byte ptr[bx], 0
    jz  atoi_1
    ; A = 10 * A
    mov cx,10
    mul cx
    ; A = A + *S
    mov ch,0
    mov cl,[bx]
    add ax,cx
    ; A = A - '0'
    sub ax,'0'
    ; ++S
    inc bx
    ;}
    jmp atoi_2
atoi_1:
    ret
atoi endp

; get parameters in format of -i <inputfile> -o <outputfile> -v <voltage>
; Inputs: char bh - Cmdline option to check
; Outputs: si=0 if not found, si=pointer to string if found (ENDS WITH ' ' or '\0')
; todo support filenames with dashes
get_param proc near
    lea si, cmd; Get initial pointer
    mov bl, '-'
get_param_l:
    call find_s
    cmp si, 0
    je get_param_e ;eos reached
    inc si ;skip -
    cmp [si], bh ;check if its our option
    jne get_param_l
get_param_succ:
    add si, 2 ;skip option and space
    ret
get_param_e:
    ret
get_param endp

;Inputs - char bl - Char to find; char* si - String to search
;Outputs - si - Pointer to first ocurrence of bl in si OR 0 if not found
;Uses: si, bl, al
find_s proc near
    mov al,[si]
	cmp al,0
	je fail_find
    cmp al,bl
    je succ_find
	inc si
    jmp find_s
succ_find:
	ret
fail_find:
    mov si,0
    ret
find_s endp

; get_s_len: char* bx - pointer to string
; Outputs: si - Length of string
get_s_len proc near
    xor si, si                ; Clear si register to start from 0
get_s_len_l:
    cmp byte ptr [bx+si], 0  ; Compare current char to null terminator
    je get_s_len_e            ; If zero, we've reached the end of the string
    inc si                    ; Increase si to move to next char    
    jmp get_s_len_l           ; Repeat the loop
get_s_len_e:
    ret                       ; Return with si holding the length of the string
get_s_len endp

; get_s_len: char* bx - pointer to string ended with \0 or space
; Outputs: si - Length of string
get_s_len_s proc near
    xor si, si                ; Clear si register to start from 0
get_s_len_l_s:
    cmp byte ptr [bx+si], 0  ; Compare current char to null terminator
    je get_s_len_e_s            ; If zero, we've reached the end of the string
    cmp byte ptr [bx+si], ' ' ; Compare current char to space
    je get_s_len_e_s            ; If space, we've reached the end of the string
    inc si                    ; Increase si to move to next char    
    jmp get_s_len_l_s           ; Repeat the loop
get_s_len_e_s:
    ret                       ; Return with si holding the length of the string
get_s_len_s endp

;strcpy: char* dx - Source; char* bx - Destination
;Copies dx to bx
;Outputs: nothing
;Uses si, di, al
strcpy proc near
    push si
    push di

    mov si, dx ; Load source string address into SI
    mov di, bx ; Load destination string address into DI
strcpy_l:
    mov al, [si] ; Load character from source into AL
    mov [di], al ; Store character into destination
    inc si ; Increment source pointer
    inc di ; Increment destination pointer
    cmp al, 0 ; Check if character is null terminator
    jnz strcpy_l ; If not, loop

    pop di
    pop si
    ret
strcpy endp

;Same as strcpy, but with a space check
;strcpy_s: char* dx - Source; char* bx - Destination
;Copies dx to bx
;Outputs: nothing
strcpy_s proc near
    push si
    push di
    mov si, dx ; Load source string address into SI
    mov di, bx ; Load destination string address into DI
strcpy_s_l:
    mov al, [si] ; Load character from source into AL
    cmp al, 0 ; Check if character is null terminator
    jz strcpy_s_e ; quit if null
    cmp al, ' ' ; Check if character is space
    jz strcpy_s_e ; quit if space

    mov [di], al ; Store character into destination
    inc si ; Increment source pointer
    inc di ; Increment destination pointer
    jmp strcpy_s_l ; loop after successful save
strcpy_s_e:
    pop di
    pop si
    ret
strcpy_s endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Data
.data
;Defaults
def_in_file db 'a.in',0 ;default input file
def_out_file db 'b.out',0 ;default output file
def_voltage db '127',0 ;default voltage

;Strings
crlf db 13,10 ;Carriage return and line feed
noparam_i db 'Opcao [-i] sem parametro',13,10,'$'
noparam_o db 'Opcao [-o] sem parametro',13,10,'$'
noparam_v db 'Opcao [-v] sem parametro',13,10,'$'
wrongparam_v db 'Parametro da opcao [-v] deve ser 127 ou 220',13,10,'$'
;Linha <número da linha> inválido: <conteúdo da linha>
line_0 db 'Linha $'
line_1 db ' Valor inválido: $'

;Variables
cmd_size db 0 ;Size of command line
cmd db 128 dup(0) ;Buffer for command line
infile db 64 dup(0) ;Buffer for input file
outfile db 64 dup(0) ;Buffer for output file
voltage db 64 dup(0) ;Buffer for voltage
effective_voltage dw 0 ;Parsed voltage

file_buffer db 0 ;Buffer for file operations


END