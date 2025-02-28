assume cs:code
code segment
start:
	mov ax,0
	mov es,ax
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0
	
	mov ax,cs
	mov ds,ax
	mov si,offset lp
	mov ax,0
	mov es,ax
	mov di,200h
	mov cx,offset lpend - offset lp
	cld
	rep movsb
	
	mov ax,4c00h
	int 21h
lp:
	push ax
	push es
	push di
	mov ax,0b800h
	
	mov es,ax
	mov di,0
	mov ah,0
	
	mov al,160
	mul dh
	add di,ax
	mov al,2
	mul dl
	add di,ax
show_str:
	cmp byte ptr [si],0
	je ok
	
	mov al,[si]
	mov es:[di],al
	mov es:[di+1],cl
	
	inc si
	add di,2
	
	jmp short show_str
ok:
	pop di
	pop es
	pop ax
	iret
lpend:
	nop
	
code ends
end start