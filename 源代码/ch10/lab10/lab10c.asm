assume cs:code

data segment
	db 10 dup (0)
data ends

code segment  
start:
    mov ax,12666
    mov bx,data		
    mov ds,bx		;bx定位data段
    mov si,0
    call dtoc
    
    mov dh,8   
    mov dl,3   
    mov cl,2   
    call show_str  
	mov ax,4c00h
	int 21h

dtoc:
	push ax
	push bx
	push si
	mov bx,10
	mov di,0
dtoc_core:
	mov cx,ax
	jcxz dtoc_out
	mov dx,0		;余数求出来后要归零，否则影响下一次div的高位
	div bx
	add dx,30H
	push dx
	inc di
	jmp short dtoc_core
dtoc_out:
	mov cx,di
	mov si,0
	s:
	pop [si]
	inc si
	loop s
	
	pop si
	pop bx
	pop ax
	ret
	
show_str:
	push si
	push ax
	push cx			;子程序要用到cl，所以要存cx
	push bx

show_addr:
	mov ax,0B800H	
	mov es,ax		;es关联显存区
	mov bx,0		;偏移地址bx初始化为0
	
	mov al,00A0H	;行偏移计算，只需要8位乘法
	mul dh
	add bx,ax		;不用特殊处理ah，因为8位乘法结果直接覆盖ax
	
	mov al,0002H	;列偏移计算，只需要8位乘法
	mul dl
	add bx,ax
	
	mov al,cl		;暂存颜色属性
show_core:			;打印字符核心代码
	mov cl,[si]		;先判断是否以0结束
	mov ch,0
	jcxz ok

	mov es:[bx],cl		;字符写入显存区偶数位
	mov es:[bx+1],al	;字符属性写入显存区奇数位
	
	inc si				;处理数据区下一个字符
	add bx,2			;一次循环写入显存区两个字节
	jmp short show_core
ok:
	pop bx
	pop cx
	pop ax
	pop si
	ret
	
code ends   
end start  