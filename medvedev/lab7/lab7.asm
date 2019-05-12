AStack SEGMENT  STACK
        dw 64 dup(?)			
AStack ENDS


CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack


DATA SEGMENT
		error1_7     	db 'Memory control block destroyed',0DH,0AH,'$'
		error1_8     	db 'Not enough memory to perform the function',0DH,0AH,'$'
		error1_9     	db 'Wrong memory address',0DH,0AH,'$'
		error3_1	db 'Non-existent function', 0DH,0AH,'$'  
		error3_2  	db 'File not found', 0DH,0AH,'$'
		error3_3  	db 'Path not found', 0DH,0AH,'$'
		error3_4  	db 'Too many opened files', 0DH,0AH,'$'
		error3_5  	db 'No access', 0DH,0AH,'$'					
		error3_8  	db 'Not enough memory', 0DH,0AH,'$'					
		error3_10 	db 'Incorrect environment', 0DH,0AH,'$'

	
		str_overlay1	db 'OVL1.ovl', 0
		str_overlay2 	db 'OVL2.ovl', 0
		DTA 		db 43 dup (0), '$'
		OVERLAY_PATH 	db 100h	dup (0), '$'
		OVERLAY_ADDR 	dd 0
		KEEP_PSP 	dw 0
		OVERLAY_ADDRESS dw 0
DATA 	ENDS


Print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
Print endp

Memory_err proc near
	cmp ax,7
	mov dx,offset error1_7
	je write_message1
	cmp ax,8
	mov dx,offset error1_8
	je write_message1
	cmp ax,9
	mov dx,offset error1_9
	je write_message1	
write_message1:

	call Print
	ret
Memory_err endp

Free_mem proc near
	mov bx,offset LAST_BYTE 
	mov ax,es 
	sub bx,ax 
	mov cl,4h
	shr bx,cl 
	mov ah,4Ah 
	int 21h
	jnc end_clear 
	
	call Memory_err
	xor al,al
	mov ah,4Ch
	int 21h
end_clear:
	ret
Free_mem endp

Variables proc near
get_variables:
	inc cx
	mov al, es:[bx]
	inc bx
	cmp al, 0
	jz check_end
	loop get_variables
	
check_end:
	cmp byte PTR es:[bx], 0
	jnz get_variables
	add bx, 3
	mov si, offset OVERLAY_PATH
	ret
Variables endp

Func_path proc near
m1:
	mov al, es:[bx]
	mov	[si], al
	inc si
	inc bx
	cmp al, 0
	jz m2
	jmp m1
	
m2:	
	sub si, 9
	mov di, bp
	ret
Func_path endp

get_path_ovl proc near
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es	
	mov es, KEEP_PSP
	mov ax, es:[2Ch]
	mov es, ax
	mov bx, 0
	mov cx, 2
	
	call Variables
	call Func_path 
		
get_way:
	mov ah, [di]
	mov [si], ah
	cmp ah, 0
	jz check_way
	inc di
	inc si
	jmp get_way
		
check_way:
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
get_path_ovl endp

Size_of_ovl proc near
	push bx
	push es
	push si
	push ds
	push dx
	mov dx, SEG DTA
	mov ds, dx
	mov dx, offset DTA	
	mov ax, 1A00h		
	int 21h
	pop dx
	pop ds
		
	push ds
	push dx
	xor cx, cx			
	mov dx, SEG OVERLAY_PATH	
	mov ds, dx
	mov dx, offset OVERLAY_PATH	
	mov ax, 4E00h
	int 21h
	pop dx
	pop ds

	jnc no_err_size 		
	cmp ax, 2
	je err1	
		
	cmp ax, 3
	je err2
	jmp no_err_size
				
err1:
	mov dx, offset error3_2
	call Print
	jmp exit
		
err2:
	mov dx, offset error3_3
	call Print
	jmp exit
			
no_err_size:
	push es
	push bx
	push si
	mov si, offset DTA
	add si, 1Ch		
	mov bx, [si]
		
	sub si, 2	
	mov bx, [si]	
	push cx
	mov cl, 4
	shr bx, cl 
	pop cx
	mov ax, [si+2] 
	push cx
	mov cl, 12
	sal ax, cl	
	pop cx
	add bx, ax	
	add bx, 2
	mov ax, 4800h	
	int 21h			
	mov OVERLAY_ADDRESS, ax	
	pop si
	pop bx
	pop es

exit:
	pop si
	pop es
	pop bx
	ret
Size_of_ovl endp

Err_processing proc near
	cmp ax, 01h
	mov dx, offset error3_1
	je write_message3
	
	cmp ax, 02h
	mov dx, offset error3_2
	je write_message3
	
	cmp ax, 03h
	mov dx, offset error3_3
	je write_message3
	
	cmp ax, 04h
	mov dx, offset error3_4
	je write_message3
	
	cmp ax, 05h
	mov dx, offset error3_5
	je write_message3
	
	cmp ax, 08h
	mov dx, offset error3_8
	je write_message3
	
	cmp ax, 0Ah
	mov dx, offset error3_10
	je write_message3
		
write_message3:
	call Print	
	ret
Err_processing endp



Run_proc proc near
	push bp
	push ax
	push bx
	push cx
	push dx
			
	mov bx, SEG OVERLAY_ADDRESS
	mov es, bx
	mov bx, offset OVERLAY_ADDRESS	
			
	mov dx, SEG OVERLAY_PATH
	mov ds, dx	
	mov dx, offset OVERLAY_PATH
			
	push ss
	push sp
			
	mov ax, 4B03h	
	int 21h
	jnc no_error_way
		
	call Err_processing 
	jmp exit_way
no_error_way:
	mov ax, SEG DATA
	mov ds, ax	
	mov ax, OVERLAY_ADDRESS
	mov WORD PTR OVERLAY_ADDR+2, ax
	call OVERLAY_ADDR
	mov ax, OVERLAY_ADDRESS
	mov es, ax
	mov ax, 4900h
	int 21h
	mov ax, SEG DATA
	mov ds, ax
exit_way:
	pop sp
	pop 	ss
	mov es, KEEP_PSP
	pop dx
	pop cx
	pop bx
	pop ax	
	pop bp
	ret
Run_proc endp

Main proc far
	mov ax, seg DATA
	mov ds, ax
	mov KEEP_PSP, es
	call Free_mem
	
	mov bp, offset str_overlay1
	call get_path_ovl
	call Size_of_ovl
	call Run_proc
		
	mov bp, offset str_overlay2
	call get_path_ovl
	call Size_of_ovl
	call Run_proc
	
	xor al, al
	mov ah, 4Ch
	int 21h
	ret
Main endp
CODE ENDS

LAST_BYTE SEGMENT	
LAST_BYTE ENDS	

END MAIN