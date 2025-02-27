assume cs:code
data segment
	db "conversation",0
data ends

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
	
	mov ax,data
	mov ds,ax
	mov si,0
	mov ax,0b800h
	mov es,ax
	mov di,160*12+34*2
	
	mov bx,offset s - offset ok
s:
	cmp byte ptr [si],0
	je ok
	mov al,[si]
	mov es:[di],al
	mov dl,10001111b
	mov es:[di+1],dl
	inc si
	add di,2
	int 7ch
ok:
	mov ax,4c00h
	int 21h
lp:
	push bp
	mov bp,sp
	add [bp+2],bx
	pop bp
	iret
lpend:
	nop
code ends
end start