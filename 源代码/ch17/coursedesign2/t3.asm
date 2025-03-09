assume cs:code
data segment
	db 32 dup (0)
data ends
code segment
start:
	mov dh,12
	mov dl,31
	mov ax,data
	mov ds,ax
	call getstr
	
	mov ax,4c00h
	int 21h
	;-----------------------
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


	;-----------------------
code ends
end start