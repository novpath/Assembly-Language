## 第 13 章 int 指令

​	中断信息可以来自 CPU 的内部和外部，当 CPU 的内部有需要处理的事情发生的时候，将产生需要马上处理的中间信息，引发中断过程。在第 12 章中，我们讲解了中断过程和两种内中断的处理。

​	这一章中，我们讲解另一种重要的内中断，由 int 指令引发的中断。

### 13.1 int 指令

​	int 指令的格式为：`int n`，n 为中断类型码，它的功能是引发中断过程。

​	CPU 执行 int n 指令，相当于引发一个 n 号中断的中断过程，执行过程如下：

* (1) 取中断类型码 n；
* (2) 标志寄存器入栈，IF=0，TF=0；
* (3) CS、IP 入栈；
* (4) (IP)=(n×4)，(CS)=(n×4+2)。

​	从此处转去执行 n 号中断的中断处理程序。

​	可以在程序中使用 int 指令调用任何一个中断的中断处理程序。例如，下面的程序：

```assembly
assume cs:code
code segment
start:
	mov ax,0b800h
	mov es,ax
	mov byte ptr es:[12*160+40*2], '!' 
	int 0
code ends
end start
```

​	这个程序在 Windows 2000 中的 DOS 方式下执行时，将在屏幕中间显示一个“!”，然后显示“Divide overflow”后返回到系统中。“!”是我们编程显示的，而“Divide overflow”是哪里来的呢？我们的程序中又没有做除法，不可能产生除法溢出。

​	程序是没有做除法，但是在结尾使用了 int 0 指令。CPU 执行 int 0 指令时，将引发中断过程，执行 0 号中断处理程序，而系统设置的 0 号中断处理程序的功能是显示“Divide overflow”，然后返回到系统。

​	可见，int指令的最终功能和call指令相似，都是调用一段程序。

​	一般情况下，系统将一些具有一定功能的子程序，以中断处理程序的方式提供给应用程序调用。我们在编程的时候，可以用 int 指令调用这些子程序。当然，也可以自己编写一些中断处理程序供别人使用。以后，我们可以将中断处理程序简称为**中断例程**。

### 13.2 编写供应用程序调用的中断例程

​	前面，我们已经编写过中断 0 的中断例程了，现在在我们讨论可以供应用程序调用的中断例程的编写方法。下面通过两个问题来讨论。

【问题一】编写、安装中断 7ch 的中断例程。

> 功能：求一个 word 型数据的平方。
> 参数：(ax)=要计算的数据。
> 返回值：dx、ax 中存放结果的高16位和低16位。

应用举例：求2*3456^2。

```assembly
assume cs:code
code segment
start: 
	mov ax,3456 	;(ax)=3456
	int 7ch    		;调用中断7ch的中断例程，计算ax中的数据的平方
	add ax,ax
	adc dx,dx  		;dx:ax 存放结果，将结果乘以2
	mov ax,4c00h
	int 21h
code ends
end start
```

分析一下，我们要做以下3部分工作：

​	(1) 编写实现求平方功能的程序；

​	(2) 安装程序，将其安装在0:200处；

​	(3) 设置中断向量表，将程序的入口地址保存在7ch 表项中，使其成为中断7ch的中断例程。

​	安装程序如下：

```assembly
assume cs:code
code segment
start: 
	mov ax,cs
	mov ds,ax
	mov si, offset sqr	; 设置 ds:si 指向源地址
	mov ax, 0
	mov es, ax
	mov di, 200h 		; 设置 es:di 指向目的地址
	mov cx, offset sarend - offset sqr ; 设置 cx 为传输长度
	cld ; 设置传输方向为正
	rep movsb

	mov ax, 0
	mov es, ax
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0

	mov ax, 400h
	int 21h
sqr:
	mul ax
	iret
sarend:
	nop

code ends
end start
```

​	注意，在中断例程 sqr 的最后，要使用 iret 指令。用汇编语法描述，iret 指令的功能为：

```assembly
pop IP
pop CS
popf
```

​	CPU 执行 int 7ch 指令进入中断例程之前，标志寄存器、当前的 CS 和 IP 被压入栈中，在执行完中断例程后，应该用 iret 指令恢复 int 7ch 执行前的标志寄存器和 CS、IP 的值，从而接着执行应用程序。

​	**int 指令和 iret 指令的配合使用**与 call 指令和 ret 指令的配合使用具有相似的思路。

【问题二】编写、安装中断 7ch 的中断例程。

> 功能：将一个全是字母，以 0 结尾的字符串，转化为大写。
>
> 参数：ds:si 指向字符串的首地址。

应用举例：将 data 段中的字符串转化为大写。

```assembly
assume cs:code

data segment
	db 'conversation', 0
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0
	int 7ch

	mov ax, 4c00h
	int 21h
code ends
end start
```

安装程序如下。

```assembly
assume cs: code
code segment
start:
	mov ax, cs
	mov ds, ax
	mov si, offset capital
	mov ax, 0
	mov es, ax
	mov di, 200h
	mov cx, offset capitalend - offset capital
	cld
	rep movsb
	
	mov ax, 0
	mov es, ax
	mov word ptr es:[7ch*4], 200h
	mov word ptr es:[7ch*4+2], 0
	mov ax, 4c00h
	int 21h
capital:
	push cx
	push si
change:
	mov cl, [si]
	mov ch, 0
	jcxz ok
	and byte ptr [si], 11011111b
	inc si
	jmp short change
ok:
	pop si
	pop cx
	iret
capitalend:
	nop
code ends
end start
```

在中断例程 capital 中用到了寄存器 si 和 cx，编写中断例程和编写子程序的时候具有同样的问题，就是要**避免寄存器的冲突**。应该注意例程中用到的寄存器的值的保存和恢复。

### 13.3 对 int、iret 和栈的深入理解

【问题】用 7ch 中断例程完成 loop 指令的功能。

​	loop s 的执行需要两个信息，循环次数和到 s 的位移，所以，7ch 中断例程要完成 loop 指令的功能，也需要这两个信息作为参数。我们用 cx 存放循环次数，用 bx 存放位移。

​	应用举例：在屏幕中间显示 80 个“!”。

```assembly
assume cs:code

code segment
start:
	mov ax,0b800h
	mov es,ax
	mov di,160*12
	
	mov bx,offset s-offset se 	;设置从标号se到标号s的转移位移(负数)
	mov cx,80
s: 
	mov byte ptr es:[di],'!'
	add di,2
	int 7ch 					;如果(cx)≠0，转移到标号s处
se:
	nop

	mov ax,4c00h
	int 21h
code ends
end start
```

在上面的程序中，用 int 7ch 调用 7ch 中断例程进行转移，用 bx 传递转移的位移。

分析：为了模拟 loop 指令，7ch 中断例程应具备下面的功能。

* dec cx
* 如果(cx)≠0，转到标号 s 处执行，否则向下执行

​	下面我们分析 7ch 中断例程如何实现到目的地址的转移。

1. 转到标号 s 显然应设(CS)=标号 s 的段地址，(IP)=标号 s 的偏移地址。

2. 那么，中断例程如何得到标号 s 的段地址和偏移地址呢？

​	int 7ch 引发中断过程后，进入 7ch 中断例程，在中断过程中，当前的标志寄存器、CS 和 IP 都要压栈，此时压入的 CS 和 IP 中的内容，分别是调用程序的段地址(可以认为是标号 s 的段地址)和 int 7ch 后一条指令的偏移地址(即标号 se 的偏移地址)。

​	可见，在中断例程中，可以**从栈里取得标号 s 的段地址和标号 se 的偏移地址**，而用标号 se 的偏移地址加上 bx 中存放的转移位移就可以得到标号 s 的偏移地址。

3. 现在知道，可以从栈中直接和间接地得到标号 s 的段地址和偏移地址，那么如何用它们设置 CS:IP 呢？

​	可以利用 iret 指令，我们将栈中的 se 的偏移地址加上 bx 中的转移位移，则栈中的 se 的偏移地址就变为了 s 的偏移地址。我们再使用 iret 指令，用栈中的内容设置 CS、IP，从而实现转移到标号 s 处。

​	7ch 中断例程如下：

```assembly
lp:
	push bp
	mov bp, sp
	dec cx
	jcxz lpret
	add [bp+2],bx
lpret:
	pop bp
	iret
```

​	因为要访问栈，使用了 bp，在程序开始处将 bp 入栈保存，结束时出栈恢复。当要修改栈中 se 的偏移地址的时候，栈中的情况为：栈顶处是 bp 原来的数值，下面是 se 的偏移地址，再下面是 s 的段地址，再下面是标志寄存器的值。而此时，bp 中为栈顶的偏移地址，所以((ss)*16+(bp)+2)处为 se 的偏移地址，将它加上 bx 中的转移位移就变为 s 的偏移地址。最后用 iret 出栈返回，CS:IP 即从标号 s 处开始执行指令。

​	如果(cx)=0，则不需要修改栈中 se 的偏移地址，直接返回即可。CPU 从标号 se 处向下执行指令。

### 13.a 检测点

​	(1) 在上面的内容中，我们用 7ch 中断例程实现 loop 的功能，则上面的 7ch 中断例程所能进行的最大转移位移是多少？

---

解析：

​	单纯的 loop 指令的转移位移是 -128\~127，而使用中断例程实现的 loop 功能，最大转移位移取决于 bx，以及最大段长，最大段长是 64 KB = 65536，而 bx 的取值范围是 -32768\~32767，所以最大转移位移应该是 32768。

​	(2) 用 7ch 中断例程完成 jmp near ptr s 指令的功能，用 bx 向中断例程传送转移位移。

应用举例：在屏幕的第 12 行，显示 data 段中以 0 结尾的字符串。

```assembly
assume cs:code
data segment
	db 'conversation',0
data ends
code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0
	mov ax,0b800h
	mov es,ax
	mov di,12*160
s: 
	cmp byte ptr [si],0
	je ok 						;如果是0跳出循环
	mov al,[si]
	mov es:[di],al
	inc si
	add di,2
	mov bx,offset s-offset ok 	;设置从标号ok到标号s的转移位移
	int 7ch 					;转移到标号s处
ok: 
	mov ax,4c00h
	int 21h
code ends
end start
```

---

解析：

```assembly
