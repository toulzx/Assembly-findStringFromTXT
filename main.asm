; main.asm
;
; author tou
; time 2022-05



;;; header section
include Irvine32.inc



FILENAME_BUFFER_SIZE = 30
CONTENT_BUFFER_SIZE = 500


;;; data section
.data
hint_filename byte "Enter the filename:", 0DH, 0AH, 0
hint_search byte "To find string:", 0DH, 0AH, 0
hint_replace byte "Replace with:", 0DH, 0AH, 0
hint_error_open  byte "Could not open the file:(", 0DH, 0AH, 0
hint_error_read  byte "Could not read the file:(", 0DH, 0AH, 0
hint_error_write  byte "Could not write the file:(", 0DH, 0AH, 0
hint_error_length  byte "string length exceeds", 0DH, 0AH, 0
hint_not_find  byte "Could not find the substring:(", 0DH, 0AH, 0
hint_original  byte "Original:", 0DH, 0AH, 0
hint_result  byte "Now:", 0DH, 0AH, 0
hint_count  byte "Counts:", 0DH, 0AH, 0
handle_file HANDLE ?
str_filename_original byte FILENAME_BUFFER_SIZE DUP(0)
str_filename_result byte "result.txt", 0
original byte CONTENT_BUFFER_SIZE DUP(0)
str_find byte CONTENT_BUFFER_SIZE DUP(0)
str_replace byte CONTENT_BUFFER_SIZE DUP(0)
result byte CONTENT_BUFFER_SIZE DUP(0)
set_pos_ori dword CONTENT_BUFFER_SIZE DUP(0)
set_pos_res dword CONTENT_BUFFER_SIZE DUP(0)
pos1 dword	0		; "POS1" = "POS_ORI[K]" + "COUNT_FIND" (K=1,2,3...)
pos2 dword	0		; "POS2" = "POS_RES[K]" - 1 (K BEGINS FROM 1)
count_filename dword ?
count_original dword ?
count_find dword ?
count_replace dword ?
count_result dword ?
count     dword   0			  ; COUNT FOR "FIND"
i         dword   ?             ; INDEX FOR "ORIGINAL".
j         dword   ?             ; INDEX FOR "RESULT".

;;; code section
.code
main PROC	

; HINT FOR FILENAME INPUT
	mov edx, offset hint_filename		; FOR: WriteString
	call WriteString

; RECORD THE FILENAME
	mov ecx, SIZEOF str_filename_original	; FOR: ReadString
	mov edx, offset str_filename_original	; FOR: ReadString
	call ReadString
	mov count_filename, eax

; OPEN THE FILE 
	invoke CreateFile,
		addr str_filename_original,
		GENERIC_READ,
		DO_NOT_SHARE,
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_READONLY,
		NULL
	mov handle_file, eax
	;; CHECK FOR ERROR
	CMP	eax, INVALID_HANDLE_VALUE
	JE	_error_open_file	; IF ERROR

; READ FILE
	invoke ReadFile, 
		handle_file, 
		addr original, 
		CONTENT_BUFFER_SIZE,
		addr count_original,
		NULL
	;; CHECK FOR ERROR
	JC _error_read_file		; IF ERROR

	
_1_close_file:
	invoke CloseHandle, handle_file
	
; TEST
	call	Crlf
	mov edx, offset original		; FOR: WriteString
	call WriteString
	call	Crlf

_input_find_str:
; HINT TO INPUT STRING "FIND"
	call	Crlf
	call	Crlf
	mov edx, offset hint_search		; FOR: WriteString
	call WriteString

; RECORD STRING "FIND"
	mov ecx, SIZEOF str_find			; FOR: ReadString
	mov edx, offset str_find			; FOR: ReadString
	call ReadString
	mov count_find, eax				; FOR: ReadString

; CHECK IF ERROR ("FIND" < "ORIGINAL" IS NEEDED)
	mov ebx, count_original
	cmp ebx, count_find
	Jnc _input_new_str
	;; IF ERROR
	call	Crlf
	mov edx, offset hint_error_length	; FOR: WriteString
	call WriteString
	jmp	_input_find_str

_input_new_str:
; HINT TO INPUT STRING "REPLACE"
	call	Crlf
	call	Crlf
	mov edx, offset hint_replace			; FOR: WriteString
	call WriteString

; RECORD THE NEW STRING "REPLACE"
	mov ecx, SIZEOF str_replace			; FOR: ReadString
	mov edx, offset str_replace			; FOR: ReadString
	call ReadString
	mov count_replace, eax				; FOR: ReadString

; CHECK IF ERROR ("REPLACE" < "ORIGINAL" IS NEEDED)
	mov ebx, count_original
	CMP ebx, count_replace
	JNC _initial
	;; IF ERROR
	call	Crlf
	mov edx, offset hint_error_length		; FOR: WriteString
	call WriteString
	jmp	_input_new_str

_initial:
	   ; INITIALIZE "I" AND "J"
     mov  i, offset original            ; "I" POINTS TO "ORIGINAL".
     mov  j, offset result              ; "J" POINTS TO "RESULT".
     ; SEARCH VARIABLE "FIND" AT CURRENT POSITION ("I").
     mov  esi, i
     lea  edi, str_find
     jmp _search
_search:
	   ;; RECORD POSTION NUM OF "ORIGINAL"
	   inc	pos1		; POS1 UPDATE WITH "ORIGINAL" POINTER
     ;; CHECK IF END OF "FIND".
	   mov  al, [edi]          ; CURRENT CHAR OF VARIABLE "FIND".
     cmp  al, 0		
     je   _match
     ; CHECK IF END OF "ORIGINAL".
     mov  al, [esi]        ; CURRENT CHAR OF VARIABLE "ORIGINAL".
     cmp  al, 0
     je   _check_count
     ; CONTINUE.   
     cmp  al, [edi]       ; CMP ORIGINAL[SI],FIND[DI].
     jne  mismatch        ; JUMP IF CHAR NOT EQUAL.
     inc  esi              ; NEXT CHAR OF "ORIGINAL".
     inc  edi              ; NEXT CHAR OF "FIND".
     jmp  _search          ; REPEAT (COMPARE NEXT CHAR).
_match:
    ; RECORD THE FIRST CHAR POSITION OF "FIND" 
    mov edx, pos1
    sub edx, count_find		; NOW, EDX == FIRST CHAR OF "FIND"
    dec edx				; FIRST INDEX OF ARRAY IS 0
    mov eax, count	; FOR: WriteDec
    mov set_pos_ori[eax * type set_pos_ori], edx		; SEND EDX TO ARRAY"SET_POS_ORI"
    ; SKIP "FIND" IN "ORIGINAL" AND SKIPPED ONE CHAR FORWARD (SO DECREASE).
    mov  i, esi          
    dec  i               
    dec	pos1			; POS1 UPDATED WITH "ORIGINAL" POINTER
    ; RECORD THE FIRST CHAR POSITION OF "REPLACE" 
    mov edx, pos2				; NOW, EDX == FIRST CHAR OF "REPLACE" (FIRST INDEX OF ARRAY IS 0)
    mov eax, count
    mov set_pos_res[eax * type set_pos_res], edx		; SEND EDX TO ARRAY"SET_POS_RES"
    ; RECORD THE NUM OF "FIND"
    inc  count
    ; REPLACE "FIND".
    lea  edi, str_replace      
    jmp  _replace          
_replace:
	   ; "REPLACE" REPLACE IT IN "RESULT".
     mov  al, [edi]       ; CURRENT CHAR OF VARIABLE "REPLACE".
     ; CHECK IF END OF "REPLACE".
     cmp  al, 0
     je   _next
     ; ELSE: COPY CHAR INTO "RESULT[ J ]".
     mov  esi, j          ; CURRENT POSITION IN "RESULT".
     mov  [esi], al
     inc  j               ; NEXT POSITION IN "RESULT".
	inc  pos2			; RECORD POSTION NUM OF "RESULT"(UPDATE WITH "RESULT" POINTER)
     inc  edi             ; NEXT POSITION IN "REPLACE".
     jmp  _replace
mismatch:
     ; APPEND CURRENT CHAR INTO "RESULT".
     mov  esi, i          ; CURRENT POSITION IN "ORIGINAL".
     mov  edi, j          ; CURRENT POSITION IN "RESULT".
     mov  al, [esi]
     mov  [edi], al
     inc  j               ; "I" IS ALSO INC IN ROUTINE NEXT.
	   inc  pos2			; RECORD POSITION NUM OF "RESULT"
     jmp  _next
_next:
     ; NEXT CHAR IN "ORIGINAL".
     inc  i               ; NEXT CHAR IN "ORIGINAL".
     lea  edi, str_find       ; SEARCH AGAIN IN VARIABLE "FIND".
     ; CHECK IF END OF "ORIGINAL".
     mov  esi, i
     mov  al, [esi]
     cmp  al, 0
     jne  _search          ; REPEAT (SEARCH "FIND" AGAIN).

; SPECIFIC THE LENGTH OF "RESULT"
	mov eax, count_find
	sub eax, count_replace
	cmp eax, 0
	jnc _no_resub
	mov eax, count_replace
	sub eax, count_find 
_no_resub:
	mov ebx, count
	mul ebx
	add eax, count_original
	mov count_result, eax

; PRINT "ORIGINAL" CHAR BY CHAR
	call Crlf
	call Crlf
	mov edx, offset hint_original		; FOR: WriteString
	call WriteString
	mov esi, 0		; RECORD INDEX OF "SET_POS_ORI", INDEX OF ARRAY BEGINS FROM 0
	mov edi, count_original		; RECORD INDEX OF "ORIGINAL" (REVERSE)
_print_ori:
	mov ebx, count_original
	sub ebx, edi		; RECORD INDEX OF "ORIGINAL", INDEX OF ARRAY BEGINS FROM 0
	; CHECK IF IS FIRST CHAR OF "FIND"
	cmp ebx, set_pos_ori[esi * type set_pos_ori]
	jz  _on_color_print_ori
	; CHECK IF IS LAST CHAR OF "FIND"
	cmp ecx, ebx
	jz  _off_color_print_ori
	mov ah, 0							; FOR:WriteChar
	mov al, original[ebx * type original]	; FOR:WriteChar
	call WriteChar
	jmp _check_print_ori
_on_color_print_ori:
	mov eax, red +(white * 16)		; FOR: SetTextColor
	call SetTextColor
	mov ah, 0							; FOR:WriteChar
	mov al, original[ebx * type original]	; FOR:WriteChar
	call WriteChar
	; SET THE END POSITION OF THIS "FIND"
	mov ecx, ebx
	add ecx, count_find
	; SET NEXT POSITION OF "FIND"
	inc esi
	jmp _check_print_ori
_off_color_print_ori:
	mov eax, white +(black * 16)		; FOR: SetTextColor
	call SetTextColor
	mov ah, 0							; FOR:WriteChar
	mov al, original[ebx * type original]	; FOR:WriteChar
	call WriteChar
_check_print_ori:
	; NEXT CHAR OF "ORIGINAL"
	dec edi
	; CHECK IF IS END OF "ORIGINAL"
	cmp edi, 0
	JNZ _print_ori

; PRINT COUNT OF "FIND"
  call Crlf	
	call Crlf
	mov edx, offset hint_count		; FOR: WriteString
	call WriteString
  mov eax, count		; FOR: WriteDec
	call WriteDec

; PRINT "RESULT" CHAR BY CHAR		; SAME STRUCTURE
	call Crlf
	call Crlf
	mov edx, offset hint_result		; FOR: WriteString
	call WriteString
	mov esi, 0		; RECORD INDEX OF "SET_POS_RES", INDEX OF ARRAY BEGINS FROM 0
	mov edi, count_result		; RECORD INDEX OF "RESULT" (REVERSE)
_print_res:
	mov ebx, count_result
	sub ebx, edi		; RECORD INDEX OF "RESULT", INDEX OF ARRAY BEGINS FROM 0
	; CHECK IF IS FIRST CHAR OF "REPLACE"
	cmp ebx, set_pos_res[esi * type set_pos_res]
	jz  _on_color_print_res
	; CHECK IF IS LAST CHAR OF "REPLACE"
	cmp ecx, ebx
	jz  _off_color_print_res
	mov ah, 0							; FOR:WriteChar
	mov al, result[ebx * type result]	; FOR:WriteChar
	call WriteChar
	jmp _check_print_res
_on_color_print_res:
	mov eax, red +(white * 16)		; FOR: SetTextColor
	call SetTextColor
	mov ah, 0							; FOR:WriteChar
	mov al, result[ebx * type result]	; FOR:WriteChar
	call WriteChar
	; SET THE END POSITION OF THIS "FIND"
	mov ecx, ebx
	add ecx, count_replace
	; SET NEXT POSITION OF "REPLACE"
	inc esi
	jmp _check_print_res
_off_color_print_res:
	mov eax, white +(black * 16)		; FOR: SetTextColor
	call SetTextColor
	mov ah, 0							; FOR:WriteChar
	mov al, result[ebx * type result]	; FOR:WriteChar
	call WriteChar
_check_print_res:
	; NEXT CHAR OF "RESULT"
	dec edi
	; CHECK IF IS END OF "RESULT"
	cmp edi, 0
	JNZ _print_res

_check_count:
; CHECK IF ERROR
	cmp count, 0
	jnz _write_file
	;; IF NOT FIND
	call	Crlf
	mov edx, offset hint_not_find
	call WriteString
	jmp	_input_find_str

_write_file:
; OPEN THE FILE (FOR WRITING)
	invoke CreateFile,
		addr str_filename_result,
		GENERIC_WRITE,
		DO_NOT_SHARE,
		NULL,
		CREATE_ALWAYS,
		FILE_ATTRIBUTE_NORMAL,
		NULL
	mov handle_file, eax
	;; CHECK FOR ERROR
	cmp	eax, INVALID_HANDLE_VALUE
	JE	_error_open_file				; IF ERROR, JUMP

; WRITE TO FILE
	invoke WriteFile,
	handle_file,
	addr result,
	count_result,		; BE CAREFUL, IT WILL WRITE THE WHOLE SPACE YOU HAVE PREDEFINED
	addr count_result,
	NULL
	;; CHECK FOR ERROR
	JC _error_write_file			; IF CF=1, SYSTEM ERROR, JUMP

; CLOSE FILE AND QUIT
	invoke CloseHandle, handle_file
	jmp _quit


;--------------------------------------;

_error_open_file:
	invoke CloseHandle, handle_file	; CLOSE FILE
	call	Crlf
	mov edx, offset hint_error_open	; FOR: WriteString
	call WriteString
	jmp	_quit

_error_read_file:
	invoke CloseHandle, handle_file	; CLOSE FILE
	call	Crlf
	mov edx, offset hint_error_read	; FOR: WriteString
	call WriteString
	jmp	_quit
	
_error_write_file:
	invoke CloseHandle, handle_file	; CLOSE FILE
	call	Crlf
	mov edx, offset hint_error_write	; FOR: WriteString
	call WriteString
	jmp	_quit

_quit:
	call	Crlf
	invoke ExitProcess, 0


main ENDP
END main