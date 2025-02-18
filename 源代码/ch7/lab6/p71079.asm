assume cs:codesg, ss:stacksg, ds:datasg

stacksg segment
	dw 0,0,0,0,0,0,0,0 
stacksg ends

datasg segment
    db '1. display      '
    db '2. brows        '
    db '3. replace      '
    db '4. modify       '
datasg ends

codesg segment
start:
	mov ax,stacksg
	mov ss,ax
	mov sp,16
	mov ax,datasg
	mov ds,ax
	mov bx,0
	
	mov cx,4
s0:
	push cx			;外层循环的cx值压栈
	mov si,0
	mov cx,4		;cx设置为内层循环的次数
s:
	mov al,[bx+3+si]	;定位bx行3+si列
	and al,11011111b	;大小写转换
	mov [bx+3+si],al	;修改后的数据写回内存
	inc si
	loop s
	
	add bx,16
	pop cx			;从栈顶弹出原cx的值，恢复cx
	loop s0			;外层循环的loop指令将cx中的计数值减1
	
	mov ax,4c00h
	int 21h
codesg ends

end start 