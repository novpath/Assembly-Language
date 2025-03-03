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
	org 200h
lp:
setscreen: 
	jmp short set
	table dw sub1,sub2,sub3,sub4
set:
	push bx
	
	cmp ah,3 					;判断功能号是否大于 3
	ja sret
	mov bl,ah
	mov bh,0
	add bx,bx 					;根据 ah 中的功能号计算对应子程序在 table 表中的偏移，偏移量为 1 个字
	
	call word ptr table[bx] 	;调用对应的功能子程序
sret:
	pop bx
	iret
sub1:
	push bx
	push cx
	push es			;保护现场
	mov bx,0b800h
	mov es,bx		;es 设置为显存地址
	mov bx,0
	mov cx,2000		;全屏幕 25 行 × 80 列
sub1s:
	mov byte ptr es:[bx],' '	;当前字符置为空格
	add bx,2					;下一个字符地址
	loop sub1s
	pop es						;恢复现场
	pop cx
	pop bx
	ret
sub2:
	push bx
	push cx
	push es

	mov bx,0b800h
	mov es,bx
	mov bx,1		;奇数位用来设置字符颜色
	mov cx,2000
sub2s:
	and byte ptr es:[bx],11111000b	;前景色清空
	or es:[bx],al					;设置前景色
	add bx,2						;移到下一个字符颜色属性设置位
	loop sub2s

	pop es
	pop cx
	pop bx
	ret
sub3: 
	push bx
	push cx
	push es
	mov cl,4
	shl al,cl				;将 al 移动到高四位
	mov bx,0b800h
	mov es,bx
	mov bx,1
	mov cx,2000
sub3s: 
	and byte ptr es:[bx],10001111b	;清空背景色
	or es:[bx],al					;设置背景色
	add bx,2
	loop sub3s
	pop es
	pop cx
	pop bx
	ret
sub4: 
	push cx
	push si
	push di
	push es
	push ds
	mov si,0b800h
	mov es,si
	mov ds,si
	mov si,160				;ds:si 指向第 n+1 行
	mov di,0				;es:di 指向第 n 行
	cld						;清空方向标志位，使其置为 0，正向传送
	mov cx,24				;共复制 24 行
sub4s:
	push cx					;保护循环变量 cx，因为下面传送要重新设置 cx
	mov cx,160				;一行 160 字节(80 字节字符 + 80 字节字符颜色属性)
	rep movsb				;从源地址 ds:si 复制到目标地址 es:di
	pop cx
	loop sub4s
	
	mov cx,80							;清空偶数位字符位即可
	mov si,0
sub4s1: 
	mov byte ptr [160*24+si],' '		;最后一行清空
	add si,2							;移动到下一个字符
	loop sub4s1
	
	pop ds
	pop es
	pop di
	pop si
	pop cx
	ret
lpend:
	nop
	
code ends
end start