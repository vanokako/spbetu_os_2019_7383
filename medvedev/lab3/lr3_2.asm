.186
testpc segment
		assume cs:testpc, ds: testpc, es:nothing, ss:nothing
		org 100h
start: jmp main
	;data segnent
		available 		db	"Available memory:        ", 0dh, 0ah, '$'
		extended 		db	"Extended memory:       ", 0dh, 0ah, '$'
		header 			db 	"ADDRESS  OWNER    SIZE  NAME" ,0Dh,0Ah,'$'
		data 			db 	'                        $'
		endline 		db	 0dh, 0ah, '$'
		END_OF_PROGRAMM db 0
	;data ends

Print proc near
	push ax

	mov ax, 0900h
	int 21h

	pop ax
	ret
Print endp


	
TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX 
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  
	pop CX
	ret
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae _bd
	cmp AL,00h
	je end_
	or AL,30h
	mov [SI],AL
	end_:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP


WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
	_b: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae _b
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
	endl: pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

main proc near
;=======================================================================
;Available Mem

	sub ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset available
	add si, 017h
	call WRD_TO_DEC
	mov dx, offset available
	call PRINT

;==========================================================================
;EXTENDED Mem
	mov si, offset extended
	add si, 015h
	mov al, 30h
	out 70h, al
	in al, 71h
	mov dh, al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov ah, al
	mov al, dh
	xor dx, dx
	call WRD_TO_DEC
	mov dx, offset extended
	call Print
;============================================================================
;CLEARING

	mov ah, 4ah
	mov bx, offset END_OF_PROGRAMM
	int 21h
;==========================================================================
;MCB Data
	mov dx, offset header
	call Print
	mov ah, 52h
	int 21h
	sub bx, 02h
	mov es, es:[bx]


	@while_mcb:

		mov ax, es
		mov di, offset data
		add di, 6
		call WRD_TO_HEX
		
		mov ax, es:[0001h]
		mov di, offset data
		add di, 13
		call WRD_TO_HEX
		
		xor si, si

		mov ax, es:[03h]
		xor dx, dx
		mov bx, 16
		mul bx
		mov si, offset data
		add si, 21
		call WRD_TO_DEC

		mov dx, offset data
		call Print

		xor si, si

	@for_mcb:
		mov al, es:[si + 08h]
		inc si
		int 29h
		cmp si, 8h
		jne @for_mcb

		mov dx, offset endline
		call Print
		mov ax, es
		inc ax
		add ax,es:[03h]
		mov bl,es:[00h]
		mov es,ax
		cmp bl,4Dh
		je @while_mcb
		mov ah, 4ch
		int 21h
		
		ret
	main endp
testpc ends

end start