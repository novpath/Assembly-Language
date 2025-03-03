assume cs:code

code segment
start:
	mov ah,2			
	mov al,3
	int 7ch
	
	mov ax,4c00h
	int 21h
	
code ends
end start