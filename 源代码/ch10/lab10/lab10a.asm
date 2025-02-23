assume cs:code  
data segment  
	db 'Welcome to masm!',0  
data ends

stack segment stack
	db 16 dup (0)
stack ends

code segment  
start: 
	mov dh,8
	mov dl,3 
	mov cl,2  
	mov ax,data  
	mov ds,ax  
	mov si,0  
	call show_str  
	
	mov ax,4c00h  
	int 21h
show_str:
	push si
	push ax
	push cx
addr:
	mov ax,0B800H
	mov es,ax
	mov bx,0
	
	mov cl,dh
	mov ch,0
sdh:
	add bx,00A0H
	loop sdh
	
	mov cl,dl
	mov ch,0
sdl:
	add bx,0002H
	loop sdl
show:
	mov cl,[si]
	mov ch,0
	jcxz ok

	mov al,[si]
	mov es:[bx],al
	pop ax
	mov es:[bx+1],al
	push ax
	
	inc si
	add bx,2
	jmp short show
ok:
	pop cx
	pop ax
	pop si
	ret

code ends  
end start