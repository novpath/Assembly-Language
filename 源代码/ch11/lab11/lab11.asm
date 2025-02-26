assume cs:codesg
dataseg segment
	db "Beginner's All-purpose Symbolic Instruction Code.",0
dataseg ends
codesg segment
begin:
	mov ax, dataseg
	mov ds, ax
	mov si, 0
	call letterc
	mov ax, 4C00h
	int 21h
	
letterc:
	push si
	push cx
change:
	mov cl,[si]
	mov ch,0
	jcxz ok
	cmp byte ptr [si],97
	jb next
	cmp byte ptr [si],122
	ja next
	and byte ptr [si],11011111B
next:
	inc si
	jmp short change
ok:
	pop cx
	pop si
	ret
codesg ends
end begin