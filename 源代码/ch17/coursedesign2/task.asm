assume cs:code
data segment
	db 32 dup (0)		;日期/时间数据存放区，输入格式：YYMMDDHHMMSS
data ends
stack segment stack
	db 32 dup (0)
stack ends
code segment
start:
	mov dh,8
    mov dl,32
	mov ax,data
	mov ds,ax
	mov cx,7
	call menu

	mov ah,0
	int 16h
	call setscreen
	
	jmp short start
	mov ax,4c00h
	int 21h
;------------------------------------------------------------------------
;名称：show_str  
;功能：在指定的位置，用指定的颜色，显示一个用 0 结束的字符串。  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色，ds:si 指向字符串的首地址  
;返回：无  
;------------------------------------------------------------------------
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
;------------------------------------------------------------------------
;名称：screen_clear
;功能：全屏幕字符用空格填充，而字符颜色属性保持不变。  
;参数：无
;返回：无  
;------------------------------------------------------------------------
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
;------------------------------------------------------------------------
;名称：menu
;功能：显示菜单栏目  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色
;返回：无  
;------------------------------------------------------------------------
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
	mov si,linelabel[bx]	;等价于 mov si,cs:[linelabel+bx]
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
;------------------------------------------------------------------------
;名称：setscreen
;功能：调用菜单栏目对应功能  
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
setscreen: 
	jmp short set
	table dw 0,reset_pc,start_system,clock,set_clock	;预留 0 号位，方便和按键对应
set:
	push bx
	push ax
	sub al,30h				;将 int 16h 传递的 al 中的 ASCII 码转化为数值
	cmp al,4 				;判断按键是否大于 4
	ja setret
	mov bl,al
	mov bh,0
	add bx,bx 				;根据 ah 中的功能号计算对应子程序在 table 表中的偏移，偏移量为 1 个字
	call word ptr table[bx] ;调用对应的功能子程序
setret:
	pop ax
	pop bx
	ret
;------------------------------------------------------------------------
;名称：reset_pc
;功能：重启 pc 机
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
reset_pc:
	mov ax,0ffffH
	push ax
	mov ax,0H
	push ax
	retf
;------------------------------------------------------------------------
;名称：start_system
;功能：引导现有操作系统
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
start_system:
	mov ax,0
	mov es,ax
	mov bx,7c00h	;es:bx 指向将写入磁盘的数据

	mov al,1		;(al)写入扇区数
	mov ch,0		;(ch)磁道号
	mov cl,1		;(cl)扇区号
	mov dl,80h		;(dl)驱动器号，80h 为 C 盘
	mov dh,0		;(dh)面号

	mov ah,2		;int 13h 的功能号(2 表示读扇区)
	int 13h
	
	mov ax,0
	push ax
	mov ax,7c00h
	push ax
	retf				;将 CS:IP 指向 0:7c00
;------------------------------------------------------------------------
;名称：clock(动态显示 + 热键控制)
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)，ESC 退出，F1 改变颜色
;返回：无  
;------------------------------------------------------------------------
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
	call screen_clear		;清屏
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
	
	add ax,3030h				;(个位|十位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	mov ah,1				;1 号功能：查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的 ZF
	int 16h					;ZF=0，表示有键盘操作，AL 中存放当前输入的 ASCII 码，AH 存放输入字符的扩展码
	je short clock_ini		;若 ZF=1，表示无键盘输入，则循环读取(可以省去 cmp 步骤，因为本质上 je 就是查 ZF)
	
	mov ah,0				;0 号功能：从键盘读数据并存于 al 中
	int 16h	
	cmp ah,1				;按下 ESC 键退出
	je clock_out
	cmp ah,3bH				;按下 F1 键改变颜色
	jne short clock_ini		;其他按键也是继续循环
	inc word ptr [bp+4]		;改变字符颜色属性
	and word ptr [bp+4],07H	;改变前景色
	jmp short clock_ini
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
;名称：set_clock
;功能：修改当前日期、时间，显示格式:YYMMDDHHMMSS
;参数：扫描码-功能号(ah)，键盘输入日期、时间
;返回：无
;------------------------------------------------------------------------
set_clock:
	push di
	push bx
	push ax
	call screen_clear		;清屏
	call getstr
	mov di,5
	mov ah,1		;0 出栈
	call charstack
setclock_in:
	mov ah,1		;出栈功能号 1
	call charstack 	;字符出栈，输出内容到 al
	sub al,30h		;个位 ASCII 码转换为 BCD 码
	mov bl,al		;低 4 位暂存个位 al
	
	mov ah,1
	call charstack
	sub al,30h
	shl al,1
	shl al,1
	shl al,1
	shl al,1
	or bl,al		;高 4 位再存十位
	
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
;------------------------------------------------------------------------
;子程序：接收字符串输入的子程序 getstr
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;返回：无；
;ds:si 指向字符栈空间；
;------------------------------------------------------------------------
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
;------------------------------------------------------------------------
;子程序：字符栈 charstack 的入栈、出栈和显示 
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;ds:si 指向字符栈空间；
;对于 0 号功能：(al)=入栈字符；
;对于 1 号功能：(al)=返回的字节；
;对于 2 号功能：(dh)、(dl)=字符串在屏幕上显示的行、列位置。
;------------------------------------------------------------------------
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
	
code ends
end start