OVERLAY_CODE SEGMENT
ASSUME CS:OVERLAY_CODE, DS:NOTHING, ES:NOTHING, SS:NOTHING

OVERLAY proc far
	push ax
	push dx
	push di
	push ds
	mov ax, cs
	mov ds, ax
	mov bx, offset message
	add bx, 46
	mov di, bx
	mov ax, cs
	call WRD_TO_HEX
	mov dx, offset message
	call Print
	pop ds
	pop di
	pop dx
	pop ax
	retf
OVERLAY endp

TETR_TO_HEX PROC NEAR
	and al,0Fh
	cmp al,09
	jbe NEXT
	add al,07
NEXT: 	add al,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR		
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al,ah
	mov cl,4
	shr al,cl
	call TETR_TO_HEX 	
	pop cx 				
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR 
	push bx
	mov bh,ah
	call BYTE_TO_HEX
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	xor ah,ah
	call BYTE_TO_HEX
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
WRD_TO_HEX ENDP

Print proc near		
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
Print endp

message db 	'Segment address of first overlay segment                  ', 13, 10, '$'

OVERLAY_CODE ENDS
END