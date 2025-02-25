assume cs:codesg
data segment
	db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
	db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
	db '1993','1994','1995'
	;以上是表示 21 年的 21 个字符串
	dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
	dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000
	;以上是表示 21 年公司总收入的 21 个 dword 型数据
	dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226
	dw 11542,14430,15257,17800
	;以上是表示 21 年公司雇员人数的 21 个 word 型数据
data ends

table segment
	db 21 dup ('year Rev. nu av ')
table ends
codesg segment
start:
	mov ax,table
	mov es,ax		;es定位到table段
	mov ax,data
	mov ds,ax		;ds定位到data段
	
	mov cx,21		;总共处理21个table行
	mov bx,0		;table行定位变量bx归零,利用[bx+idata]定位最终写回的table区地址
	mov si,0		;定位两个字节的数据区数组项,利用[si+idata]定位读取的数据区地址
	mov di,0		;定位四个字节的数据区数组项,利用[di+idata]定位读取的数据区地址
s0:					;处理table行
year:				;处理年份(4字节)
	mov ax,[di]
	mov es:[bx+0],ax	;写回字
	mov ax,[di+2]
	mov es:[bx+2],ax
blank1:							;处理空格(1字节)
	mov byte ptr es:[bx+4],00h	;写回table段要段前缀es强调，否则就写到data区去了，0作为字符串结尾方便打印
rev:						;处理收入(4字节)
	mov ax,[84+di]			;从data:84区取数，即读下一个收入
	mov es:[bx+5],ax		;写回字
	mov ax,[86+di]			
	mov es:[bx+7],ax		
blank2:
	mov byte ptr es:[bx+9],00h
ee:							;处理职工数(2字节)
	mov ax,[168+si]			;从data:168取数，即读下一年雇员数
	mov es:[bx+10],ax		;写回雇员数（2字节）
blank3:
	mov byte ptr es:[bx+12],00h
av:							;处理人均收入(2字节)
	mov ax,[di+84]			;32位被除数，低位存在ax中，外层循环每循环一次，就后移4个字节从data:84取收入
	mov dx,[di+86]			;32位被除数，高位存在dx中，外层循环每循环一次，就后移4个字节从data:86取收入
	div word ptr [168+si]	;除以员工数量
	mov es:[bx+13],ax
blank4:
	mov byte ptr es:[bx+15],00h

	add bx,16				;步进1行table，bx增加16字节
	add si,2				;步进2字节
	add di,4				;步进4字节
	loop s0
	
print_table:
	mov ax,table		;明显处理过的table区结构更清晰，所以DS移到table段将其作为数据区
	mov ds,ax
	
	mov cx,21
	mov ax,0
	mov si,0
s_print:
	push cx				;内层要修改cx的值，不能影响循环变量cx计数

	mov dh,al			;打印年份
	mov dl,20
	mov cl,00000111B	;设置黑底白字
	call show_str
	add si,5
	
	add dl,12			;打印公司收入
	call show_string2	;打印四个字节数据区表示的字符串
	add si,5
	
	add dl,12			;打印公司雇员
	call show_string1	;打印两个字节数据区表示的字符串
	add si,3
	
	add dl,12			;打印人均收入
	call show_string1	;打印两个字节数据区表示的字符串
	add si,3
	
	inc al				;年份从下一行开始打印
	pop cx
	loop s_print
	
	mov ax,4c00H
	int 21h
;---------
;名称：dtoc(改进型)
;功能：将 dword 型数转变为表示十进制数的字符串，字符串以0为结尾符。  
;参数：(ax)=dword型数据的低16位,(dx)=dword型数据的高16位,ds:si指向字符串的首地址 
;返回：无  
;---------
dtoc:			;存储寄存器状态，相关寄存器初始化
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov bx,10
	mov di,0
dtoc_core:			;显示数值核心代码
	mov cx,ax		;遇到字符串0证明结尾了
	jcxz dtoc_out
	mov cx,10
	call divdw
	add cx,30H		;数字转字符串ASCII码
	push cx			;ASCII码压栈
	inc di			;统计字符个数
	jmp short dtoc_core
dtoc_out:
	mov cx,di		;循环字符个数次
	mov si,0		
	s:				;弹出字符到数据区
	pop [si]
	inc si
	loop s
	mov word ptr [si],0		;结尾赋0
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;--------
;名称：show_str  
;功能：在指定的位置，用指定的颜色，显示一个用 0 结束的字符串。  
;参数：(dh)=行号(取值范围 0-24)，(dl)=列号(取值范围 0-79)，(cl)=颜色，ds:si 指向字符串的首地址  
;返回：无  
;--------	
show_str:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es
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
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;-------
;名称：divdw
;功能：进行不会产生溢出的除法运算，被除数为 dword 型，除数为 word 型，结果为 dword 型。
;参数：(ax)=dword 型数据的低 16 位,(dx)=dword 型数据的高 16 位,(cx)=除数
;返回：(dx)=结果的高 16 位,(ax)=结果的低 16 位,(cx)=余数
;-------
divdw:					;保存寄存器状态
	push ax
	push cx
	push dx
	push bp
divdw_core:				;防溢出除法程序的核心代码
	mov bp,sp			;bp置于栈顶
	mov ax,[bp+2]		;读取高16位dx
	mov dx,0			;高16位要置零，因为在求的是H/N，而非X/N
	div word ptr [bp+4]	;H/N,ax存商，dx存余数
	mov [bp+2],ax		;商写回原来的高16位dx
	
	mov ax,[bp+6]		;取低16位L，之前rem(H/N)恰好存储在dx里，作为高16位，不用额外处理了
	div word ptr [bp+4]	;ax存商，dx存余数
	mov [bp+6],ax		;商写回原来的低16位ax
	mov [bp+4],dx		;余数写回原来的cx
divdw_out:				;还原寄存器状态
	pop bp				
	pop dx
	pop cx
	pop ax
	ret
;---------------------
;名称：show_string2、show_string1
;功能：将四个字节或两个字节的table数据区里的数据转换为字符串并打印出来。  
;参数：ds:si 指向需要处理的数据区的首地址  
;返回：无  
;---------------------
show_string2:			;处理4字节字符串
	push ds				
	push es				;这里es和ds区要调换一下，ds作为数据区暂存转换后的数据，尽量保障table区结构完整
	push ax
	push dx
	mov ax,data
	mov ds,ax
	mov ax,table
	mov es,ax
	mov ax,es:[si]
	mov dx,es:[si+2]
	call dtoc			;因为dtoc是从数据区取数的，所以之前我们要将ds设为data
	pop dx
	pop ax
	push si
	mov si,0
	call show_str
	pop si
	pop es
	pop ds
	ret
show_string1:			;处理2字节字符串
	push ds				
	push es
	push ax
	push dx
	mov ax,data
	mov ds,ax
	mov ax,table
	mov es,ax
	mov ax,es:[si]
	mov dx,0			;数据只占2个字节时，默认高位为0。
	call dtoc
	pop dx
	pop ax
	push si
	mov si,0
	call show_str
	pop si
	pop es
	pop ds
	ret
codesg ends
end start