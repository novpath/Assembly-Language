assume cs:code
code segment
    mov ax,0ffffh
    mov ds,ax
    mov bx,6	;以上，设置ds:bx指向ffff:6
    
    mov al,[bx]
    mov ah,0	;以上，设置(al)=((ds*16)+(bx),(ah)=0
    
    mov dx,0	;累加寄存器清0
    
    mov cx,123	;循环 123 次 
 s: add dx,ax
    loop s		;以上累加计算（ax）*3
	
	mov ax,4c00h
	int 21h		;程序返回

code ends
end