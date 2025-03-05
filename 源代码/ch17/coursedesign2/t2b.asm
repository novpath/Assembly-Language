assume cs:code
code segment
start:
	call clock
	
	mov ax,4c00h
	int 21h
	;-----------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax
clock_ini:
	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(十位|个位h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	call screen_clear		;清屏
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	call delay				;延迟执行指令，不能放在 je 指令前面，因为运算指令会影响 ZF 的值
	mov ah,1				;1 号功能：查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的 ZF
	int 16h					;ZF=0，表示有键盘操作，AL中存放的是当前输入的ASCII码，AH存放的是输入字符的扩展码
	je short clock_ini		;若 ZF=1，表示无键盘输入，则循环读取
	
	mov ah,0				;0 号功能：从键盘读数据并存于 al 中
	int 16h	
	cmp ah,1				;按下 ESC 键退出
	je clock_out
	cmp ah,3bH				;按下 F1 键改变颜色
	inc word ptr [bp+4]
	jne short clock_ini		;其他按键也是继续循环
clock_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
;------------------------------------------------------------------------
;名称：delay
;功能：延迟执行指令
;参数：无
;返回：无  
;------------------------------------------------------------------------
delay:
	push ax
	push dx
	mov dx,1h ; 循环 10000h 次，读者可以根据自己机器的速度调整循环次数
	mov ax,0
s1:
	sub ax,1
	sbb dx,0
	cmp ax,0
	jne s1
	cmp dx,0
	jne s1
	pop dx
	pop ax
	ret

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


	;-----------------------
code ends
end start