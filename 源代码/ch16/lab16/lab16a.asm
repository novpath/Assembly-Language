assume cs:code

code segment
start:
	mov ah,1			;测试程序
	mov al,2
	int 7ch
	
	mov ax,4c00h
	int 21h
	
code ends
end start