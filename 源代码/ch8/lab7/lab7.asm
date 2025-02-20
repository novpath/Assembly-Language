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

stacksg segment stack
	dw 8 dup (0)
stacksg ends

codesg segment
start:
	mov ax,table
	mov es,ax		;es定位到table段
	mov ax,data
	mov ds,ax		;ds定位到data段
	mov ax,stacksg
	mov ss,ax		
	mov sp,16		;申请16个字节的栈空间暂存循环变量
	
	mov bp,sp				;设置栈帧，bp指向栈顶
	sub sp,4				;为变量A、B预留空间
	mov word ptr [bp-2],0 	;每行步进2字节变量A归零，注意bp寄存器按内存单元寻址时，如未声明则默认在ss段
	mov word ptr [bp-4],0 	;每行步进4字节变量B归零
	
	mov bx,0		;table行定位变量bx归零
	mov cx,21		;总共处理21个table行
s0:					;处理table行
	push cx			;暂存外层循环变量cx
	mov si,0		;定位每一项中具体元素的变量
	mov cx,4		;年份有4个字节字符
year:				;处理年份(4字节)
	mov di,[bp-4]		;读取步进变量B
	add di,si			;定位si+B，由于[di+si]是不合法的，所以这么写，如果合法的话直接合并成一句就好
	mov al,[di]			;外层循环每循环一次，就后移B个字节从data区取数，即读下一个年份
	mov es:[bx+si],al	;写回字符，写回时si从0开始，因为是新的table行了
	inc si				;后移一个字符
	loop year
	
blank1:					;处理空格(1字节)
	mov al,' '			;mov al,20h亦可，要al寄存器中转，否则会存在类型没声明的问题
	mov es:[bx+4],al	;写回table段要段前缀es强调，否则就写到data区去了
	
	mov si,0			;定位具体字
	mov cx,2			;收入为2个字4个字节，循环2次
rev:					;处理收入(2字)
	mov di,[bp-4]			;读取步进变量B
	add di,si				;定位si+B，由于[di+si]是不合法的，所以这么写。
	mov ax,[84+di]			;外层循环每循环一次，就后移B个字节从data:84区取数，即读下一个收入
	mov es:[bx+5+si],ax		;写回字，写回时si从0开始，因为是新的table行了
	add si,2				;后移一个字
	loop rev
	
blank2:
	mov al,' '
	mov es:[bx+9],al
	
ee:							;处理职工数(1字)
	mov di,[bp-2]			;读取步进变量A
	mov ax,[168+di]			;外层循环每循环一次，就后移A个字节从data:168取数，即读下一年雇员数
	mov es:[bx+10],ax		;写回雇员数（一个字）
	
blank3:
	mov al,' '
	mov es:[bx+12],al
	
av:							;处理人均收入(1字)
	mov di,[bp-4]			;读取步进变量B
	mov ax,[di+84]			;32位被除数，低位存在ax中，外层循环每循环一次，就后移B个字节从data:84取收入
	mov dx,[di+86]			;32位被除数，高位存在dx中，外层循环每循环一次，就后移B个字节从data:86取收入

	mov di,[bp-2]			;读取步进变量A
	div word ptr [168+di]	;除以员工数量
	mov es:[bx+13],ax

blank4:
	mov al,' '
	mov es:[bx+15],al
	
	add bx,16				;步进1行table，bx增加16字节
	add word ptr [bp-2],2	;A变量步进2个字节
	add word ptr [bp-4],4	;B变量步进4个字节
	pop cx					;恢复外层循环cx的值
	loop s0

	mov ax,4c00H
	int 21h
codesg ends

end start