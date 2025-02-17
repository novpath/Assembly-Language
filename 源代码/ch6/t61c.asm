assume cs:codesg, ss:stack, ds:datasg
datasg segment
	dw 1122h,3344h,5566h,7788h,99aah,0bbcch,0ddeeh,0ff00h
datasg ends

stack segment
	dw 0,0,0,0,0,0
stack ends

codesg segment
	dw 0123h, 0456h,0789h,0abch,0defh,0fedh, 0cbah, 0987h

start:
	mov ax,stack
	mov ss,ax
	mov sp,02h
	
	mov ax,datasg
	mov ds,ax
	mov bx,0
	mov cx,8
s:
	push ds:[bx]
	pop cs:[bx]
	add bx,2
	loop s
	
	mov ax,4c00h
	int 21h
	
codesg ends

end start