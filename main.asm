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
handle_file HANDLE ?
str_filename_original byte FILENAME_BUFFER_SIZE DUP(0)
str_filename_result byte "result.txt", 0
original byte CONTENT_BUFFER_SIZE DUP(0)
str_find byte CONTENT_BUFFER_SIZE DUP(0)
str_replace byte CONTENT_BUFFER_SIZE DUP(0)
result byte CONTENT_BUFFER_SIZE DUP(0)
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

; TEST
	call	Crlf
	mov edx, offset str_filename_original	; FOR: WriteString
	call WriteString
	call	Crlf
	mov eax, count_filename		; FOR: WriteDec
	call WriteDec

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
	mov eax, count_original		; FOR: WriteDec
	call WriteDec


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
	
; TEST
	call	Crlf
	mov edx, offset str_find		; FOR: WriteString
	call WriteString
	call	Crlf
	mov eax, count_find			; FOR: WriteDec
	call WriteDec

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

; TEST
	call	Crlf
	mov edx, offset str_replace		; FOR: WriteString
	call WriteString
	call	Crlf
	mov eax, count_replace			; FOR: WriteDec
	call WriteDec

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
     mov  al, [edi]          ; CURRENT CHAR OF VARIABLE "FIND".
     ; CHECK IF END OF "FIND".
     cmp  al, 0
     je   _match
     ; CHECK IF END OF "ORIGINAL".
     mov  al, [esi]
     cmp  al, 0
     je   _check_count
     ; CONTINUE.   
     cmp  al, [edi]       ; CMP ORIGINAL[SI],FIND[DI].
     jne  mismatch        ; JUMP IF CHAR NOT EQUAL.
     inc  esi              ; NEXT CHAR OF "ORIGINAL".
     inc  edi              ; NEXT CHAR OF "FIND".
     jmp  _search          ; REPEAT (COMPARE NEXT CHAR).
_match:
     mov  i, esi          ; SKIP "FIND" IN "ORIGINAL", BUT...
     dec  i               ; ...SKIPPED ON CHAR FORWARD (SO DECREASE).
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
     inc  edi             ; NEXT POSITION IN "REPLACE".
     jmp  _replace
mismatch:
     ; APPEND CURRENT CHAR INTO "RESULT".
     mov  esi, i          ; CURRENT POSITION IN "ORIGINAL".
     mov  edi, j          ; CURRENT POSITION IN "RESULT".
     mov  al, [esi]
     mov  [edi], al
     inc  j               ; "I" IS ALSO INC IN ROUTINE NEXT.
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

; TEST  
	call Crlf
     call Crlf
     mov edx, offset original		; FOR: WriteString
	call WriteString
     call Crlf
     mov edx, offset str_find		; FOR: WriteString
	call WriteString
     call Crlf
     mov edx, offset str_replace		; FOR: WriteString
	call WriteString
     call Crlf
     mov edx, offset result		; FOR: WriteString
	call WriteString
     call Crlf
     mov eax, count		; FOR: WriteDec
	call WriteDec

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
	CMP	eax, INVALID_HANDLE_VALUE
	JE	_error_open_file				; IF ERROR, JUMP

; WRITE TO FILE
	invoke WriteFile,
	handle_file,
	addr result,
	CONTENT_BUFFER_SIZE,
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