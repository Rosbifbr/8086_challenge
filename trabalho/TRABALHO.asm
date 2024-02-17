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

;TODO
; Parse lines correctly
; Convert second integers to mm:ss format
; Write output to file

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
lea dx,def_voltage
v_present:
call strcpy_s ;copy to voltage

;After copy, check for bad pointers
cmp infile, 0
je e_noparam_i
cmp outfile, 0
je e_noparam_o
cmp voltage, 0
je e_noparam_v

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

;Define upper and lower limits
mov effective_voltage, ax
mov voltage_upper, al
add voltage_upper, 10
mov voltage_lower, al
sub voltage_lower, 10

;After parameter validation, we can finally start the file parsing

;try to open input file 
lea dx, infile
call fopen
jc e_invalid_file

;If input file is ok, start main loop
main_loop:
call get_line

cmp [line_buffer], 0 ;check if we reached EOF
je main_loop_end
cmp [line_buffer], 'e' ;check if we reached EOF (some files end in "end" string) "end" is the ONLY valid line that starts with e
je main_loop_end

call parse_line ;parse line to number_1, number_2, number_3

;check if line has valid entries
cmp number_1, 0
je e_invalid_line
cmp number_1, 499
jae e_invalid_line

cmp number_2, 0
je e_invalid_line
cmp number_2, 499
jae e_invalid_line

cmp number_3, 0
je e_invalid_line
cmp number_3, 499
jae e_invalid_line

inc time_total ;increment total time (or line number)

;classify if all 3 voltages are below 10
cmp number_1, 10
jae tension_not_null ;dont count time if voltage is too low
cmp number_2, 10
jae tension_not_null ;dont count time if voltage is too low
cmp number_3, 10
jae tension_not_null ;dont count time if voltage is too low
call add_no_tension ;increment time_no_tension
jmp main_loop ;loop
tension_not_null:

;classify time-reading
mov ah, 0
mov al, voltage_upper
cmp number_3, ax
jae main_loop ;dont count time if voltage is too high
cmp number_2, ax
jae main_loop ;dont count time if voltage is too high
cmp number_1, ax
jae main_loop ;dont count time if voltage is too high

mov al, voltage_lower
cmp number_3, ax
jbe main_loop ;dont count time if voltage is too low
cmp number_2, ax
jbe main_loop ;dont count time if voltage is too low
cmp number_1, ax
jbe main_loop ;dont count time if voltage is too low

inc time_adequate ;increment time_adequate

jmp main_loop ;loop
main_loop_end:

cmp error_detected, 1
je dont_calculate ;if we had an error, dont calculate

;Perform time calculations
;TODO

;Write output to screen
lea dx, infile_label
call printf_dos
lea bx, infile
call printf_s

lea dx, outfile_label
call printf_dos
lea bx, outfile
call printf_s

lea dx, voltage_label
call printf_dos
lea bx, voltage
call printf_s

;DEBUG
lea dx, time_total_label
call printf_dos
mov ax, time_total
lea bx, time_total_string
call format_time
lea bx, time_total_string
call printf_s

lea dx, time_adequate_label
call printf_dos
mov ax, time_adequate
lea bx, time_adequate_string
call format_time
lea bx, time_adequate_string
call printf_s

lea dx, time_no_tension_label
call printf_dos
mov ax, time_no_tension
lea bx, time_no_tension_string
call format_time
lea bx, time_no_tension_string
call printf_s

;Write output to our file
;infile
;outfile
;voltage
;total time
;time correct voltage
;time no voltage 
;TODO

.exit 0 ; Return to OS (err code 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Errors, exits
dont_calculate:
.exit 2 ; Return to OS (err code 2 - error detected)

e_noparam_i:
lea dx, noparam_i
call printf_dos
.exit 1 ; Return to OS (err code 1 - no param)

e_noparam_o:
lea dx, noparam_o
call printf_dos
.exit 1 ; Return to OS (err code 1 - no param)

e_noparam_v:
lea dx, noparam_v
call printf_dos
.exit 1 ; Return to OS (err code 1 - no param)

e_invalid_line proc near
    mov error_detected,1
    lea dx, line_0
    call printf_dos
    lea bx, number_conversion_buffer
    mov ax, time_total
    call sprintf_w ;convert to ascii
    call printf_s ;print number
    
    lea dx, line_1
    call printf_dos
    ;print rest of line
    lea bx, line_buffer
    call printf_s
    ret
e_invalid_line endp

;input: dx - filename
e_invalid_file:
lea dx, invalid_file
call printf_dos
lea bx, infile
call printf_s
.exit 3 ; Return to OS (err code 3 - bad file load)

;input: dx - filename
e_get_line:
lea dx, file_read_error
call printf_dos
.exit 4 ; Return to OS (err code 4 - IO error)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Functions (a very rich stdlib i would say. Some functions extracted from moodle content)

;Input - Ax - time in seconds, Bx - pointer to buffer
;Output - Bx - buffer with time in mm:ss format
format_time proc near
    mov cx, 60 ;minutes
    div cx ;ax = minutes(res), dx = seconds(remainder)

    mov [bx+5], 0 ;null terminator
    mov [bx+4], '0' ;Zero
    mov [bx+3], '0' ;Zero
    mov [bx+2], ':' ;Sep
    mov [bx+1], '0' ;Zero
    mov [bx], '0' ;Zero

    ;Store our results for later use
    ;push ax ;mins
    push dx ;secs

    mov dx, ax ;minutes
    add dx, 3 ;pointer to second string

    cmp ax, 10 ;Check if we need to consider a leading zero
    jge ft_1
    inc bx ;move to next char
    ft_1:
    call sprintf_w ;convert and write to bx

    mov bx, dx ;move to second string pointer
    pop ax ;get seconds
    call sprintf_w ;convert and write to original bx + 3
    ret
format_time endp

add_no_tension proc near
    inc time_no_tension
    ret
add_no_tension endp

;Input - bx - file handle
;Output - None
;Copy curr line to line_buffer, IGNORIING SPACES AND TABS
get_line proc near
mov cx, 0 ;clear cx "line cursor"
get_line_start:
    call get_char_f ;dl = char, ax = 0 if eof, cf = 0 if ok
    
    jc e_get_line ;check file read error
    cmp ax, 0 ;check if eof
    je get_line_end
    cmp dl, 13 ;check if cr
    je get_line_end ;stop on cr
    cmp dl, 10 ;check if lf
    je get_line_end ;stop on lf
    
    cmp dl, 32 ;check if space
    je get_line_start ;ignore spaces
    cmp dl, 9 ;check if tab
    je get_line_start ;ignore tabs

    mov [line_buffer+cx], dl ;copy char to line_buffer
    inc cx ;move to next char
    jmp get_line_start ;loop
get_line_end:
    cmp cx, 0 ;check if line is empty
    je get_line_empty_case
    inc cx ;add one char
    mov [line_buffer+cx], 0 ;append null terminator to end of buffer
    ret
get_line_empty_case:
    mov [line_buffer], 0 ;write null terminator to buffer
    ret
get_line endp

;Parses line_buffer 3 numbers
;Input: bx = pointer to line
;Output: number_1, number_2, number_3
parse_line proc near
    lea si, line_buffer ; Get initial pointer
    call find_s ; Find first comma
    cmp si, 0 ; Check if we reached end of line
    je parse_line_error ; If we did, error
    mov di, si ; Store pointer to first comma
    mov [di], 0 ; Null terminate first number
    call atoi ; Parse first number
    mov number_1, ax ; Store first number

    mov si, di ; Move pointer to first comma
    inc si ; Move pointer to next char
    call find_s ; Find second comma
    cmp si, 0 ; Check if we reached end of line
    je parse_line_error ; If we did, error
    mov di, si ; Store pointer to second comma
    mov [di], 0 ; Null terminate second number
    call atoi ; Parse second number
    mov number_2, ax ; Store second number

    mov si, di ; Move pointer to second comma
    inc si ; Move pointer to next char
    cmp [si], 0 ; Check if we reached end of line
    je parse_line_error ; If we did, error
    ;call find_s ; Find third comma
    ;mov di, si ; Store pointer to third comma
    ;mov [di], 0 ; Null terminate third number
    call atoi ; Parse third number
    mov number_3, ax ; Store third number
    ret
parse_line_error:
    call e_invalid_line
    ret
parse_line endp

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
    mov dl,13;New line
    call putchar
    mov dl,10;Carriage return
    call putchar
	ret
printf_s endp

; get_char_f: File* (bx) -> Char (dl) Inteiro (AX) Boolean (CF)
get_char_f proc	near
	mov ah,3fh
	mov cx,1
	lea dx,file_pointer
	int 21h
	mov dl,file_pointer
	ret
get_char_f endp

; set_char_f: File* (bx) Char (dl) -> Inteiro (ax) Boolean (CF)
set_char_f proc	near
	mov ah,40h
	mov cx,1
	mov file_pointer,dl
	lea dx,file_pointer
	int 21h
	ret
set_char_f endp

; fopen: String (dx) -> File* (bx) Boolean (CF)		(Passa o File* para o ax tambem, mas por algum motivo ele move pro bx)
fopen proc near
    mov al,0
    mov ah,3dh
    int 21h
    mov bx,ax
    ret
fopen endp

; fcreate: String (dx) -> File* (bx) Boolean (CF)
fcreate proc near
    mov cx,0
    mov ah,3ch
    int 21h
    mov bx,ax
    ret
fcreate endp

; fclose: File* (bx) -> Boolean (CF)
fclose proc	near
	mov ah,3eh
	int 21h
	ret
fclose endp

; atoi: String (bx) -> Inteiro (ax)
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

; sprintf_w: Inteiro (ax) String (bx) -> void
sprintf_w	proc	near
;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax
;	k=5;
	mov		cx,5
;	m=10000;
	mov		sw_m,10000
;	f=0;
	mov		sw_f,0
;	do {
sw_do:
;		quociente = n / m : resto = n % m;	// Usar instru��o DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	mov		sw_f,1
sw_continue:
;		n = resto;
	mov		sw_n,dx
;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
;		--k;
	dec		cx
;	} while(k);
	cmp		cx,0
	jnz		sw_do
;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:
;	*string = '\0';
	mov		byte ptr[bx],0
;}
	ret
sprintf_w	endp

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
invalid_file db 'Impossivel abrir arquivo',13,10,'$'
file_read_error db 'Erro ao ler arquivo',13,10,'$'
noparam_i db 'Opcao [-i] sem parametro',13,10,'$'
noparam_o db 'Opcao [-o] sem parametro',13,10,'$'
noparam_v db 'Opcao [-v] sem parametro',13,10,'$'
wrongparam_v db 'Parametro da opcao [-v] deve ser 127 ou 220',13,10,'$'
;Linha <número da linha> inválido: <conteúdo da linha>
line_0 db 'Linha $'
line_1 db ' Valor inválido: $'

;CMD and FILE labels
infile_label db 'Arquivo de entrada: $'
outfile_label db 'Arquivo de saida: $'
voltage_label db 'Tensao selecionada: $'
time_total_label db 'Tempo total medido: $'

;File only labels
time_adequate_label db 'Tempo com tensao adequada: $'
time_no_tension_label db 'Tempo sem tensao: $'

;Variables
cmd_size db 0 ;Size of command line
cmd db 128 dup(0) ;Buffer for command line
infile db 64 dup(0) ;Buffer for input file
outfile db 64 dup(0) ;Buffer for output file
voltage db 64 dup(0) ;Buffer for voltage
effective_voltage dw 0 ;Parsed voltage
voltage_upper db 0 ;Flag for voltage upper limit
voltage_lower db 0 ;Flag for voltage lower limit


time_total dw 0 ;Total entries in file
time_total_string db 9 dup(0) ;Buffer for total time
time_adequate dw 0 ;Time of adequate voltage
time_adequate_string db 9 dup(0) ;Buffer for time of adequate voltage
time_no_tension dw 0 ;Time of no voltage
time_no_tension_string db 9 dup(0) ;Buffer for time of no voltage

file_pointer db 0 ;Buffer for file operations
line_buffer db 64 dup(0) ;Buffer for currline
number_1 dw 0 ;Buffer for number 1 of line
number_2 dw 0 ;Buffer for number 2 of line
number_3 dw 0 ;Buffer for number 3 of line

error_detected db 0 ;Flag for error detection

number_conversion_buffer db 6 dup(0) ;Buffer for number conversion

;Function specific
sw_n dw 0
sw_m dw 0
sw_f dw 0

END