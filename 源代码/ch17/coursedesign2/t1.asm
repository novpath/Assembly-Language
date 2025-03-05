assume cs:code

code segment
start:
	mov dl,32
	mov dh,8				
	mov cl,7				;8 行 32 列开始，黑底白字
	call menu
	
	mov ax,4c00h
	int 21h
	;-----------------------
show_str:
	push si
	push dx
	push cx			
	push bx
	push ax
	
	mov ax,0B800H	
	mov es,ax		;es 关联显存区
	mov bx,0		;偏移地址 bx 初始化为 0
	
	mov al,00A0H	;行偏移计算，只需要 8 位乘法
	mul dh
	add bx,ax		;不用特殊处理 ah，因为 8 位乘法结果直接覆盖 ax
	
	mov al,0002H	;列偏移计算，只需要 8 位乘法
	mul dl
	add bx,ax
	
	mov al,cl		;暂存颜色属性
show_core:			;打印字符核心代码
	mov cl,[si]		;先判断是否以 0 结束
	mov ch,0
	jcxz show_out

	mov es:[bx],cl		;字符写入显存区偶数位
	mov es:[bx+1],al	;字符属性写入显存区奇数位
	
	inc si				;处理数据区下一个字符
	add bx,2			;一次循环写入显存区两个字节
	jmp short show_core
show_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop si
	ret


screen_clear:
	push bx
	push cx
	push es			;保护现场
	mov bx,0b800h
	mov es,bx		;es 设置为显存地址
	mov bx,0
	mov cx,2000		;全屏幕 25 行 × 80 列
screen_clears:
	mov byte ptr es:[bx],' '	;当前字符置为空格
	add bx,2					;下一个字符地址
	loop screen_clears
	pop es						;恢复现场
	pop cx
	pop bx
	ret


menu:
	jmp short menu_show
	
	linelabel dw line1,line2,line3,line4
	line1 db '1)reset pc',0
	line2 db '2)start system',0
	line3 db '3)clock',0
	line4 db '4)set clock',0
menu_show: 
	push es
	push ds
	push si
	push dx
	push bx
	mov bx,cs
	mov ds,bx				;★用到了数据标号，数据段和代码段对齐，方便调用 show_str 子程序★
	mov bx,0				;偏移量初始化
	
	call screen_clear		;清屏
menus:
	;以下用 0,2,4,6 作为相对于 line 的偏移，取得对应的字符串的偏移地址，放在 bx 中
	mov si,linelabel[bx]	;mov si,cs:[linelabel+bx]
	call show_str
	add bx,2				;移动到下一 line
	add dh,2				;下移 2 行开始打印
	cmp bx,6
	jna menus				;重复此过程，直至打印完四行
menuout:
	pop bx
	pop dx
	pop si
	pop ds
	pop es
	ret
	;-----------------------
code ends
end start