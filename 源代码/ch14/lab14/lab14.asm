assume cs:code
code segment
start: 
	mov ax,0b800h				
	mov es,ax					;es定位显存区

	mov al,9					;指定第 9 单元
	mov di,160*12+31*2			;偏移量
	call printime				;打印日期/时间的十位和个位
	mov byte ptr es:[di],'/'	;打印分隔符
	add di,2					;指向下一个位置
	
	mov al,8
	call printime
	mov byte ptr es:[di],'/'
	add di,2
	
	mov al,7
	call printime
	add di,2
	
	mov al,4
	call printime
	mov byte ptr es:[di],':'
	add di,2
	
	mov al,2
	call printime
	mov byte ptr es:[di],':'
	add di,2
	
	mov al,0
	call printime
	
	mov ax,4c00h
	int 21h
;---
;名称：打印日期子程序printime
;参数：端口号、偏移量di
;返回：无
;---
printime:
	push ax
	push cx
	push bx
	push di
	push es
print:
	out 70h,al
	in al,71h
	
	mov ah,al
	mov cl,4
	shr ah,cl
	and al,00001111b
	
	add ah,30h
	add al,30h
	
	mov bx,0b800h
	mov es,bx
	
	mov byte ptr es:[di],ah 	;显示日期十位数
	mov byte ptr es:[di+2],al 	;接着显示日期的个位数
	mov bp,sp
	add word ptr [bp+2],4
	pop es
	pop di
	pop bx
	pop cx
	pop ax
	ret
	
	mov ax,4c00h
	int 21h
	
code ends
end start
