assume cs:code
code segment
	mov ax,0020h
	mov ds,ax		;通过ax中介修改段地址寄存器ds
	mov bx,0		;偏移地址记录
	mov cx,64		;循环次数计数
	
s:  mov ds:[bx],bx	;传送数据
	inc bx
	loop s
	
	mov ax,4c00h
	int 21h
code ends
end