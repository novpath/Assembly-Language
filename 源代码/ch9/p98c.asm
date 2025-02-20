assume cs:code
code segment
start: 
    mov ax,2000H
    mov ds,ax
    mov bx,0
s: 
    mov cl,[bx]
    mov ch,0
    add cl,1
    inc bx
	loop s
ok:
	dec bx 			; dec指令的功能和 inc 相反，dec bx进行的操作为：(bx)=(bx)-1
	mov dx,bx
	mov ax,4c00h
	int 21h
code ends
end start