assume cs:codesg
codesg segment
start:
	mov ax,0
	mov bx,0
	jmp short s
	add ax,1
s:
	inc ax
codesg ends
end start