assume cs:code
data segment
	db 32 dup (0)		;日期/时间数据存放区，输入格式：YYMMDDHHMMSS
data ends
code segment
start:
	mov dh,12
	mov dl,31
	mov ax,data
	mov ds,ax
	call set_clock
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
	
	add ax,3030h				;(十位|个位 h)转换为字符
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
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
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




set_clock:
	push di
	push bx
	push ax
	
	call getstr
	mov di,5
	mov ah,1		;0 出栈
	call charstack
setclock_in:
	mov ah,1		;出栈功能号 1
	call charstack 	;字符出栈，输出内容到 al
	sub al,30h		;个位 ASCII 码转换为 BCD 码
	mov bl,al		;暂存 al
	
	mov ah,1
	call charstack
	sub al,30h
	shl al,1
	shl al,1
	shl al,1
	shl al,1
	or bl,al		;再存十位
	
	mov al,unit_num[di]
	out 70h,al
	mov al,bl
	out 71h,al
	
	cmp di,0
	je setclock_ret
	dec di
	jmp setclock_in
setclock_ret:
	pop ax
	pop bx
	pop di
	ret



getstr:
	push ax
getstrs:
	mov ah,0
	int 16h			;读取缓冲区的字符
	cmp al,20h
	jb nochar 		;ASCII 码小于 20h，说明不是字符
	mov ah,0
	call charstack 	;字符入栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
nochar:
	cmp ah,0eh		;退格键的扫描码
	je backspace 	
	cmp ah,1ch		;Enter 键的扫描码
	je enter 		
	jmp getstrs
backspace:
	mov ah,1
	call charstack 	;字符出栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
enter:
	mov al,0
	mov ah,0
	call charstack 	;0 入栈，作为字符串结尾
	mov ah,2
	call charstack 	;显示栈中的字符
	pop ax
	ret




charstack:
	jmp short charstart
	subfun dw charpush,charpop,charshow
	top dw 0							;栈顶
charstart: 
	push bx
	push dx
	push di
	push es

	cmp ah,2				;功能号超出范围则跳出程序
	ja sret
	mov bl,ah				;bx 读取数据标号偏移量 = 功能号*2
	mov bh,0
	add bx,bx				
	jmp word ptr subfun[bx]	;跳转执行子程序
charpush:
	mov bx,top				;从 top 位置开始入栈
	mov [si][bx],al			;等价于 mov [si+bx],al
	inc top					;先入栈，再 top++ 说明 top 指向的是栈顶元素后一个位置
	jmp sret
charpop:
	cmp top,0				;检测是否为空，空则退出
	je sret
	dec top					;top 指针先减少，指向栈顶元素后再出栈
	mov bx,top
	mov al,[si][bx]			;al 存放字符栈弹出的元素
	jmp sret
charshow:
	mov bx,0b800h
	mov es,bx
	mov al,160
	mov ah,0
	mul dh
	mov di,ax
	add dl,dl
	mov dh,0
	add di,dx					;计算显示字符偏移量 行×160+列×2

	mov bx,0
charshows: 
	cmp bx,top					;检查栈是否为空
	jne noempty
	mov byte ptr es:[di],' '
	jmp sret					;若为空，则打印空格符(下一个字符位置清屏)后退出
noempty:
	mov al,[si][bx]				
	mov es:[di],al				;不为空则取出栈顶元素并显示
	mov byte ptr es:[di+2],' '	;下一个字符置为空格(下一个字符位置清屏)
	inc bx						;移动到下一个元素
	add di,2					;移动到下一个字符位置
	jmp charshows
sret:
	pop es
	pop di
	pop dx
	pop bx
	ret

	;-----------------------
code ends
end start