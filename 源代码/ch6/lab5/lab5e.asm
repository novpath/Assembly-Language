assume cs:code

a segment
	db 1,2,3,4,5,6,7,8		;定义了8个字节的变量
a ends

b segment
	db 1,2,3,4,5,6,7,8
b ends

c segment
	db 0,0,0,0,0,0,0,0
c ends

code segment 
start:
    mov ax,c
    mov ds,ax		;ds指向c段
    mov ax,a
    mov es,ax		;es指向a段

    mov bx,0
    mov cx,8		;循环8次

    s:
    mov dl,es:[bx]
    add [bx],dl
    mov dl,es:[bx+16]
    add [bx],dl
    inc bx
    loop s
    
    mov ax,4c00h
    int 21h
code ends
end start