assume cs:code

data segment
	a db 4000 dup (0)
data ends

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
	
	mov ax,data
	mov es,ax
	mov bx,offset a	;es:bx 指向用于读写的缓冲区
	mov ah,0		;ah=0 读
	mov dx,0		;逻辑扇区号
	int 7ch
	
	mov ax,4c00h
	int 21h
	org 200H
lp:
	push bp
	push ax
	
	cmp ah,1
	ja ok					;功能号超出范围则退出
	mov bp,sp
	add ah,2
	mov al,1				;读写扇区数 1
	mov word ptr [bp],ax	;int 13h 功能号 2 读，3 写，而 ah 为 0 读 1 写，二者差 2
	
	call disknum
	
	int 13h					;调用 int 13h 中断例程
ok:
	pop ax
	pop bp
	iret
;------------------------------------
;名称：disknum
;输入：逻辑扇区号 dx
;返回：dh(面号)、dl(驱动器号)、ch(磁道号)、cl(扇区号)
;------------------------------------
disknum:
	jmp short disknum_core
	cst dw 1440,18
disknum_core:
	push bp
	push dx
	push cx
	push bx
	push ax

	mov bp,sp
	mov ax,dx
	mov dx,0
	div word ptr cst[0]
	mov ah,al
	mov al,0
	mov word ptr [bp+6],ax		;高 8 位存面号 dh
	and word ptr [bp+6],0FFF0H	;驱动器号 0,A 盘
	
	mov ax,dx					;取余数
	mov dx,0
	div word ptr cst[1]			;商 ax 为磁道号
	mov ah,al
	mov al,0
	mov word ptr [bp+4],ax		;高 8 位存磁道号 ch
	
	add dx,1					;余数 dx, +1 为扇区号
	add word ptr [bp+4],dx		;低 8 位存扇区号 cl
	
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	ret
lpend:
	nop
	
code ends
end start