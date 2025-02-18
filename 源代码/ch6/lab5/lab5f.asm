assume cs:code

a segment
	dw 1,2,3,4,5,6,7,8,9,0ah,0bh,0ch,0dh,0eh,0fh,0ffh
a ends

b segment
	dw 0,0,0,0,0,0,0,0 
b ends

code segment
start: 
	mov ax,a
	mov ds,ax		;ds指向a段
	mov ax,b
	mov ss,ax		;ss指向b段
	mov sp,16		;栈中有8个字，栈空间16字节
	
	mov bx,0
	mov cx,8
s:
	push [bx]
	add bx,2		;偏移地址移动一个字
	loop s
	
	mov ax,4c00h
	int 21h

code ends 

end start 