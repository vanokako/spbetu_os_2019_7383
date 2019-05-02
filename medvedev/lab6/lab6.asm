CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

TETR_TO_HEX PROC NEAR
	and 	al,0Fh
	cmp 	al,09
	jbe 	NEXT
	add 	al,07
NEXT: 	
	add 	al,30h
	ret
TETR_TO_HEX ENDP



BYTE_TO_HEX PROC NEAR		
	push cx
	mov ah,al
	call TETR_TO_HEX
	xchg al,ah
	mov cl,4
	shr al,cl
	call TETR_TO_HEX 	
	pop cx 				
	ret	
BYTE_TO_HEX ENDP



Print PROC NEAR			
	push ax	
	mov ah, 09h
	int 21h
	pop ax
	ret
Print ENDP


Memory_err PROC NEAR
	cmp ax,7
	mov dx,offset destroy 
	je write

	cmp ax,8
	mov dx,offset overhead
	je write

	cmp ax,9
	mov dx,offset wrong_adress

write:
	call Print
	ret

Memory_err ENDP


Free_mem PROC NEAR
	mov ax,ASTACK 
	mov bx,es
	sub ax,bx 
	add ax,10h 
	mov bx,ax
	mov ah,4Ah
	int 21h
	jnc end_clear
	
	call Memory_err
	
end_clear:
	ret

Free_mem ENDP

Init_parameters PROC NEAR
	mov  ax, es:[2Ch]
	mov parameter_block, ax
	mov parameter_block+2, es 
	mov parameter_block+4, 80h 
	ret
Init_parameters ENDP

Err_proc PROC NEAR
	cmp ax,01h
	mov dx,offset func 
	je write_message

	cmp ax,02h
	mov dx,offset file 
	je write_message

	cmp ax,05h
	mov dx,offset disk 
	je write_message

	cmp ax,08h
	mov dx,offset memory
	je write_message

	cmp ax,0Ah
	mov dx,offset enviroment 
	je write_message

	mov dx,offset format
		
write_message:
	call Print
	ret
Err_proc ENDP

End_proc PROC NEAR
	mov dx, offset endl
	call Print

	cmp ah,0
	je normal_end
	cmp ah,01h
	mov dx,offset ctrl_c
	je output

	cmp ah,02h
	mov dx,offset device
	je output

	cmp ah,03h
	mov dx,offset resident
	je output
normal_end:
	mov dx,offset  normal
	call Print
	mov dx,offset exit_code
	call Print
	call BYTE_TO_HEX
	push ax
	mov ah,02h
	mov dl,al
	int 21h
	pop ax
	xchg ah,al
	mov ah,02h
	mov dl,al
	int 21h
	jmp exit
output:
	call 	Print
exit:
	ret
End_proc ENDP

Base_proc PROC NEAR
	mov es,es:[2ch]
	mov si,0

m1:
	mov dl,es:[si]
	cmp dl,0
	je m2
	inc si
	jmp m1
		
m2:
	inc si
	mov dl,es:[si]
	cmp dl,0
	jne m1
	add si,3
	lea di,path
		
m3:
	mov dl, es:[si]
	cmp dl,0
	je m4
	mov [di],dl
	inc di
	inc si
	jmp m3
		
m4:
	sub di,8
	mov [di], byte ptr 'l'	
	mov [di+1], byte ptr 'a'
	mov [di+2], byte ptr 'b'
	mov [di+3], byte ptr '2'
	mov [di+4], byte ptr '.'
	mov [di+5], byte ptr 'c'
	mov [di+6], byte ptr 'o'
	mov [di+7], byte ptr 'm'
	mov dx,offset path 
	push ds
	pop es
	mov bx,offset parameter_block
	mov keep_sp, SP
	mov keep_ss, SS
	
	mov ax,4B00h
	int 21h
	jnc success
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov ss,keep_ss
	mov sp,keep_sp
	
error:
	call Err_proc
	ret
		
success:
	mov ax,4d00h
	int 21h

	call End_proc
	ret
Base_proc ENDP

MAIN PROC far
	mov ax,data
	mov ds,ax

	call Free_mem
	call Init_parameters
	call Base_proc
	
	xor 	al,al
	mov 	ah,4Ch
	int 	21h

MAIN ENDP
CODE ENDS

DATA SEGMENT
	parameter_block 		dw ? ;сегментный адрес среды
					dd ? ;сегмент и смещение командной строки
					dd ? ;сегмент и смещение первого FCB
					dd ? ;сегмент и смещение второго FCB

	destroy 			db 'Block of main function is destroyed', 0Dh, 0Ah, '$'
	overhead 			db 'Not enough memory to process func', 0Dh, 0Ah, '$'
	wrong_adress 			db 'wrong adress', 0Dh, 0Ah, '$'


	func 	 			db 'Wrong code of function', 0Dh, 0Ah, '$'
	file 	 			db 'File not found', 0Dh, 0Ah, '$'
	disk 	 			db 'Disk error', 0Dh, 0Ah, '$'
	memory 	 			db 'Not enough memory', 0Dh, 0Ah, '$'
	enviroment 			db 'Wrong enviroment', 0Dh, 0Ah, '$'
	format 	 			db 'Wrong format', 0Dh, 0Ah, '$'

	normal 	 			db 'Normal termination', 0Dh, 0Ah, '$'
	ctrl_c 	 			db 'Termination by Control-Break', 0Dh, 0Ah, '$'
	device  			db 'Termination by device ', 0Dh, 0Ah, '$'
	resident 			db 'Termination by func 31h', 0Dh, 0Ah, '$'

	endl 				db ' ', 10, 13, '$'

	exit_code			db 'Exit code: $'
	
	path  				db 20h dup (0)

	keep_ss 			dw 0
	keep_sp 			dw 0
DATA ENDS

ASTACK SEGMENT STACK
	dw 100 dup (?) 
ASTACK ENDS
END MAIN