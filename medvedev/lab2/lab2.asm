TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN

MEM  db 13, 10, "Memory address:     h$"
ENV_ADRESS  db 13, 10,  "Environment address:     h$"
TAIL db 13, 10, "Tail: $"
ENV db 13, 10, "Enviroment contains: ", 13, 10, "$"
ENDL db 13, 10, "$"
PATH db 13, 10, "Path: $"

TETR_TO_HEX		PROC	near
		and	al,0fh
		cmp	al,09
		jbe	NEXT
		add	al,07
NEXT:		add	al,30h
		ret
TETR_TO_HEX		ENDP
BYTE_TO_HEX		PROC near


		push	cx
		mov	al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov	cl,4
		shr	al,cl
		call	TETR_TO_HEX	 
		pop	cx 		
		ret
BYTE_TO_HEX		ENDP
WRD_TO_HEX		PROC	near


		push	bx
		mov	bh,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
WRD_TO_HEX		ENDP
BYTE_TO_DEC		PROC	near
		push	cx
		push	dx
		push	ax
		xor	ah,ah
		xor	dx,dx
		mov	cx,10
loop_bd:		div	cx
		or 	dl,30h
		mov 	[si],dl
		dec 	si
		xor	dx,dx
		cmp	ax,10
		jae	loop_bd
		cmp	ax,00h
		jbe	end_l
		or	al,30h
		mov	[si],al
end_l:		pop	ax
		pop	dx
		pop	cx
		ret
BYTE_TO_DEC		ENDP	


WRITE		PROC near
		mov 	ah,09h
		int	21h
		ret
WRITE		ENDP


GET_MEM PROC near
	mov	ax, ds:[02h]
	lea di, MEM
	add di, 21
	call WRD_TO_HEX
	lea dx, MEM
	call WRITE
	ret
GET_MEM ENDP

GET_ENV PROC near
	mov ax, ds:[2Ch]
	lea di, ENV_ADRESS
	add di, 26
	call WRD_TO_HEX
	lea dx, ENV_ADRESS
	call WRITE
	ret
GET_ENV ENDP

GET_TAIL PROC near
	mov ax, ds:[80h]
	cmp al, 0
	je end_proc_tail
	lea dx, TAIL
	call WRITE
	mov cl, al
	mov di, 00h
label:	mov al, ds:[81h + di]
	mov dl, al
	mov ah, 02h
	int 21h
	inc di
	loop label
	jmp end_proc_tail

end_proc_tail:
	ret
GET_TAIL ENDP

GET_ENV_CONTENT PROC near
	lea dx, ENV
	call WRITE
	mov di, 00h
	mov bx, 2Ch
	mov ds, [bx]
read:
	cmp byte ptr [di], 00h
	jz add_endl
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp end_cont
add_endl:
	push ds
	mov cx, cs
	mov ds, cx
	lea dx, ENDL
	call WRITE
	pop ds
end_cont:
	inc di
	cmp byte ptr [di], 0001h
	jz end_get_env
	jmp read
end_get_env:
	ret
GET_ENV_CONTENT ENDP

GET_PATH PROC near
	push ds
	mov ax, cs
	mov ds, ax
	lea dx, PATH
	call WRITE
	pop ds
	add di, 2
loop_:
	cmp byte ptr  [di], 00h
	jz end_get_path
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_
end_get_path:
	ret
GET_PATH ENDP




BEGIN:
	call GET_MEM
	call GET_ENV
	call GET_TAIL
	call GET_ENV_CONTENT
	call GET_PATH

	xor al,al
	mov ah,4ch
	int	21h

TESTPC 	ENDS
		END  	START
