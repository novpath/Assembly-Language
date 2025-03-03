assume cs:code
code segment
start:
	mov ax,30
	call showsin
showsin: 
	jmp short show
	
	table dw ag0,ag30,ag60,ag90,ag120,ag150,ag180 	;字符串偏移地址表
	ag0 db '0',0 									;sin(0)对应的字符串“0”
	ag30 db '0.5',0 								;sin(30)对应的字符串“0.5”
	ag60 db '0.866',0 								;sin(60)对应的字符串“0.866”
	ag90 db '1',0 									;sin(90)对应的字符串“1”
	ag120 db '0.866',0 								;sin(120)对应的字符串“0.866”
	ag150 db '0.5',0 								;sin(150)对应的字符串“0.5”
	ag180 db '0',0 									;sin(180)对应的字符串“0”
show: 
	push bx
	push es
	push si
	mov bx,0b800h
	mov es,bx
	
;以下用角度值/30 作为相对于 table 的偏移，取得对应的字符串的偏移地址，放在 bx 中
	mov ah,0				;ax 是主程序传递的角度
	mov bl,30
	div bl					;角度值/30 作为 table 偏移量
	mov bl,al				;取偏移量
	mov bh,0
	add bx,bx				;偏移一个字
	mov bx,table[bx]		;mov bx,cs:table[bx]
	
;以下显示 sin(x) 对应的字符串
	mov si,160*12+40*2
shows: 
	mov ah,cs:[bx]
	cmp ah,0
	je showret
	mov es:[si],ah
	inc bx
	add si,2
	jmp short shows
showret:
	pop si
	pop es
	pop bx
	ret

	mov ax,4c00h
	int 21h
code ends
end start