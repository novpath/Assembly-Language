assume cs:code
code segment
begin: 
    jmp s
    jmp near ptr s
    jmp far ptr s
    db 100 dup (0b8h,0,0)
s:  
	mov ax,2
code ends
end begin