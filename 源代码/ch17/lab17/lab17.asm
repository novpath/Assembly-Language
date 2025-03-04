assume cs:code

code segment
start:
	mov ax,0
	mov es,ax
	cli
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0
	sti
	
	mov ax,cs
	mov ds,ax
	mov si,offset lp
	mov ax,0
	mov es,ax
	mov di,200h
	mov cx,offset lpend - offset lp
	cld
	rep movsb
	
	mov ax,079ah
	mov es,ax
	mov al,0
	mov ah,0
	mov dx,1579
	mov bx,200
	int 7ch
	nop			;调试看寄存器参数
	mov dl,80h
	int 13h
	
	mov ax,4c00h
	int 21h
lp:
	push bp
	push dx
	push cx
	push bx
	push ax
	
	cmp ah,1
	ja ok					;功能号超出范围则退出
	mov bp,sp
	add ah,2
	mov word ptr [bp],ax	;int 13h 功能号 2 读，3 写，而 ah 为 0 读 1 写，二者差 2
	
	mov ax,dx
	mov bx,1440
	mov dx,0
	div bx
	mov ah,al
	mov al,0
	mov word ptr [bp+6],ax	;高 8 位存面号 dh
	
	mov ax,dx
	mov bx,18
	mov dx,0
	div bx					;商 ax 为磁道号
    mov ah,al
    mov al,0
    mov word ptr [bp+4],ax	;高 8 位存磁道号 ch
	
	add dx,1				;余数 dx 为扇区号
	add word ptr [bp+4],dx	;低 8 位存扇区号 cl
ok:
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	iret
lpend:
	nop
	
code ends
end start