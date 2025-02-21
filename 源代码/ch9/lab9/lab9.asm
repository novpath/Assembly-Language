assume cs:codesg
data segment
	db "welcome to masm!"
	db 3 dup (02H,24H,71H)
data ends

codesg segment
start:
	mov ax,data
	mov ds,ax				;ds定位数据区
	mov bx,0B800H			
	mov es,bx				;es定位显存区
	
	mov bx,067EH			;0640H+003EH=067EH
	mov si,0
	mov cx,16				;"welcome to masm!"共16个字符
s:
	mov al,[si]				;偶数位存数，一次读取一个字节的字符
	mov es:[bx],al			;由于每一行同一个相对位置的字母都是一样的，所以一次处理三个字母
	mov es:[bx+00A0H],al
	mov es:[bx+0140H],al
	
	mov ah,02h				;奇数位存字符属性，一次读取一个字节的字符属性
	mov es:[bx+1],ah		;由于每一行同一个相对位置的字符属性都是不一样的，所以要分开处理
	mov ah,24h
	mov es:[bx+00A1H],ah
	mov ah,71h
	mov es:[bx+0141H],ah
	
	inc si					;从数据区"welcome to masm!"一次取1字节
	add bx,2				;写回显存区一次循环处理2字节
	loop s
	
	mov ax,4c00h
	int 21h
codesg ends
end start