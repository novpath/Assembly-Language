assume cs:code  
code segment  
start: 
	mov ax,4240H
	mov dx,000FH
	mov cx,0AH
	call divdw
	
	mov ax,4c00h
	int 21h
divdw:					;保存寄存器状态
	push ax
	push dx
	push cx
divdw_core:				;防溢出除法程序的核心代码
	mov bp,sp			;bp置于栈顶
	mov ax,[bp+2]		;读取高16位dx
	mov dx,0			;高16位要置零，因为在求的是H/N，而非X/N
	div word ptr [bp]	;H/N,ax存商，dx存余数
	mov [bp+2],ax		;商写回高16位dx
	
	mov ax,[bp+4]		;取低16位L，之前rem(H/N)恰好存储在dx里，作为高16位，不用额外处理了
	div word ptr [bp]	;ax存商，dx存余数
	mov [bp+4],ax		;商写回低16位ax
	mov [bp],dx			;余数写回cx
divdw_out:				;还原寄存器状态
	pop cx				
	pop dx
	pop ax
	ret

code ends  
end start