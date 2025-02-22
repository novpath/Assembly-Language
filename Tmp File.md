## 第 10 章 CALL 和 RET 指令

​	call 和 ret 指令都是转移指令，它们都修改 IP，或同时修改 CS 和 IP。它们经常被共同用来实现子程序的设计。这一章，我们讲解 call 和 ret 指令的原理。

### 10.1 ret 和 retf

​	ret 指令**用栈中的数据，修改 IP 的内容**，从而实现**近转移**；

​	retf 指令**用栈中的数据，修改 CS 和 IP 的内容**，从而实现**远转移**。

CPU 执行 ret 指令时，进行下面两步操作：

​	(1) (IP)=((ss)*16+(sp))
​	(2) (sp)=(sp)+2

CPU 执行 retf 指令时，进行下面 4 步操作：
	(1) (IP)=((ss)*16+(sp))

​	(2) (sp)=(sp)+2

​	(3) (CS)=((ss)*16+(sp))

​	(4) (sp)=(sp)+2

可以看出，如果我们用汇编语法来解释 ret 和 retf 指令，则:

CPU 执行 ret 指令时，相当于进行:

```assembly
pop IP
```

CPU 执行 retf 指令时，相当于进行:

```assembly
pop IP
pop CS
```

例:
	下面的程序中，ret 指令执行后，(IP)=0，CS:IP 指向代码段的第一条指令。

```assembly
assume cs:code

stack segment
	db 16 dup (0)
stack ends

code segment
	mov ax,4c00h
	int 21h  
	
start:
	mov ax,stack  
	mov ss,ax  
	mov sp,16  
	mov ax,0  
	push ax  
	mov bx,0  
	ret  
code ends  

end start  
```

下面的程序中，retf 指令执行后，CS:IP 指向代码段的第一条指令。  

```assembly
assume cs:code 

stack segment  
	db 16 dup (0)  
stack ends  

code segment  
	mov ax,4c00h  
	int 21h  
start:
	mov ax,stack  
	mov ss,ax  
	mov sp,16  
	mov ax,0  
	push cs  
	push ax  
	mov bx,0  
	retf  
code ends  

end start
```

### 10.a 检测点 

​	补全程序，实现从内存 1000:0000 处开始执行指令。

```assembly
assume cs:code

stack segment
	db 16 dup (0)
stack ends

code segment
start:
	mov ax, stack
	mov ss, ax
	mov sp, 16
	mov ax, ___________
	push ax
	mov ax, ___________
	push ax
	retf
code ends

end start
```

解析：

​	栈是 FILO 结构，因为 retf 是先 pop ip，后 pop cs，所以入栈时要先压入 cs 后压入 ip

​	那答案就很明显了：

```assembly
 mov ax,1000H
 ...
 mov ax,0H
```

### 10.2 call 指令  

CPU 执行 call 指令时，进行两步操作：

1. 将当前的 IP 或 CS 和 IP 压入栈中；
2. 转移。  

​	call指令不能实现短转移，除此之外，call指令实现转移的方法和jmp指令的原理相同，下面的几个小节中，我们以给出转移目的地址的不同方法为主线，讲解call指令的主要应用格式。

### 10.3 依据位移进行转移的 call 指令  

call 标号(将当前的 IP 压栈后，转到标号处执行指令)

CPU 执行此种格式的 call 指令时，进行如下的操作:
	(1)(sp)=(sp)-2

 		((ss)*16+(sp))=(IP)

​	(2)(IP)=(IP)+16位位移。

* 16 位位移=标号处的地址-call 指令后的第一个字节的地址；
* 16 位位移的范围为-32768~32767，用补码表示；
* 16 位位移由编译程序在编译时算出。

从上面的描述中，可以看出，如果我们用汇编语法来解释此种格式的 call 指令，则：

CPU 执行“call 标号”时，相当于进行：

```assembly
push IP
jmp near ptr 标号
```

### 10.b 检测点

下面的程序执行后，ax 中的数值为多少？

| 内存地址 | 机器码   | 汇编指令 |
| -------- | -------- | -------- |
| 1000:0   | b8 00 00 | mov ax,0 |
| 1000:3   | e8 01 00 | call s   |
| 1000:6   | 40       | inc ax   |
| 1000:7   | 58       | s:pop ax |

解析：

| 内存地址 | 机器码   | 汇编指令 | 作用                    |
| -------- | -------- | -------- | ----------------------- |
| 1000:0   | b8 00 00 | mov ax,0 | ax=0                    |
| 1000:3   | e8 01 00 | call s   | ip=6,push ip,jmp near s |
| 1000:6   | 40       | inc ax   | 不执行                  |
| 1000:7   | 58       | s:pop ax | ax = 6                  |

### 10.4 转移的目的地址在指令中的call指令

​	前面讲的 call 指令，其对应的机器指令中并没有转移的目的地址，而是相对于当前 IP 的转移位移。

​	“call far ptr 标号”实现的是**段间转移**。  

CPU 执行此种格式的 call 指令时，进行如下的操作。

​	(1)(sp)=(sp)-2  

​	     ((ss)*16+(sp))=(CS)

​	     (sp)=(sp)-2  

​	     ((ss)*16+(sp))=(IP)  

​	(2)(CS)=标号所在段的段地址
​	     (IP)=标号在段中的偏移地址

从上面的描述中可以看出，如果我们用汇编语法来解释此格式的 call 指令，则：

CPU 执行 “call far ptr 标号” 时，相当于进行：

```assembly
push CS  
push IP  
jmp far ptr 标号
```

### 10.c 检测点

下面的程序执行后，ax中的数值为多少？

| 内存地址 | 机器码         | 汇编指令       |
| -------- | -------------- | -------------- |
| 1000:0   | b8 00 00       | mov ax, 0      |
| 1000:3   | 9A 09 00 00 10 | call far ptr s |
| 1000:8   | 40             | inc ax         |
| 1000:9   | 58             | s:pop ax       |
|          |                | add ax, ax     |
|          |                | pop bx         |
|          |                | add ax, bx     |

解析：

| 内存地址 | 机器码         | 汇编指令       | 作用                            |
| -------- | -------------- | -------------- | ------------------------------- |
| 1000:0   | b8 00 00       | mov ax, 0      | ax = 0                          |
| 1000:3   | 9A 09 00 00 10 | call far ptr s | push cs(1000)、push ip(8),jmp s |
| 1000:8   | 40             | inc ax         | 不执行                          |
| 1000:9   | 58             | s:pop ax       | ax = ip = 8 = 0008H             |
|          |                | add ax, ax     | ax = 16 =  0010H                |
|          |                | pop bx         | bx =1000H                       |
|          |                | add ax, bx     | ax = 1010H                      |

### 10.5 转移地址在寄存器中的 call 指令

**指令格式:** `call 16位reg` 
**功能:**  

​	(sp)=(sp)-2

​	((ss)*16+(sp))=(IP)

​	(IP)=(16 位 reg)

用汇编语法来解释此种格式的 call 指令，CPU 执行“call 16 位 reg”时，相当于进行：

```assembly
push IP
jmp 16位reg
```

### 10.d 检测点 

下面的程序执行后，ax 中的数值为多少？

| 内存地址 | 机器码   | 汇编指令    |
| -------- | -------- | ----------- |
| 1000:0   | b8 06 00 | mov ax,6    |
| 1000:3   | ff d0    | call ax     |
| 1000:5   | 40       | inc ax      |
| 1000:6   |          | mov bp,sp   |
|          |          | add ax,[bp] |

解析：

| 内存地址 | 机器码   | 汇编指令    | 作用                                 |
| -------- | -------- | ----------- | ------------------------------------ |
| 1000:0   | b8 06 00 | mov ax,6    | ax = 6                               |
| 1000:3   | ff d0    | call ax     | ip = 5, push ip, jmp 6               |
| 1000:5   | 40       | inc ax      | 不执行                               |
| 1000:6   |          | mov bp,sp   | bp = sp                              |
|          |          | add ax,[bp] | ax = ax + ss:[bp] = 6 + 5 = 11 = 0BH |

### 10.6 转移地址在内存中的 call 指令

转移地址在内存中的 call 指令有两种格式。

(1) call word ptr 内存单元地址

用汇编语法来解释此种格式的 call 指令，则：

CPU 执行 “call word ptr 内存单元地址” 时，相当于进行：

```assembly
push IP
jmp word ptr 内存单元地址
```

比如，下面的指令：

```assembly
mov sp,10h
mov ax,0123h
mov ds:[0],ax
call word ptr ds:[0]
```

执行后，(IP)=0123H，(sp)=0EH。

(2) call dword ptr 内存单元地址

用汇编语法来解释此种格式的 call 指令，则：

CPU 执行“call dword ptr 内存单元地址”时，相当于进行：

```assembly
push CS
push IP
jmp dword ptr 内存单元地址
```

比如，下面的指令：

```assembly
mov sp,10h
mov ax,0123h
mov ds:[0],ax
mov word ptr ds:[2],0
call dword ptr ds:[0]
```

执行后，（CS)=0，（IP)=0123H，（sp)=0CH。

### 10.e 检测点

(1) 下面的程序执行后，ax 中的数值为多少？(注意：用 call 指令的原理来分析，不要在 Debug 中单步跟踪来验证你的结论。对于此程序，在 Debug 中单步跟踪的结果，不能代表 CPU 的实际执行结果。)

```assembly
assume cs:code
stack segment
	dw 8 dup (0)
stack ends
code segment
start:
	mov ax, stack
	mov ss, ax
	mov sp, 16
	mov ds, ax
	mov ax, 0
	call word ptr ds:[0EH]
	inc ax
	inc ax
	inc ax
	mov ax, 4C00H
	int 21h
code ends
end start
```

解析：

* 栈段和数据段都设置成同一段
* 执行`call word ptr ds:[0EH]`后 IP 入栈，入栈存在ds:[0E]和ds:[0F]中
* ax 的最终值为 3，分析如下：

| 指令                   | 作用                                     |
| ---------------------- | ---------------------------------------- |
| mov ax, stack          | ax = stack                               |
| mov ss, ax             | ss = stack                               |
| mov sp, 16             | sp = 16 = 10H                            |
| mov ds, ax             | ds = ax = stack                          |
| mov ax, 0              | ax = 0                                   |
| call word ptr ds:[0EH] | Push IP，SP = 0EH，jmp ds:[0EH] = jmp IP |
| inc ax                 | ax = 1                                   |
| inc ax                 | ax = 2                                   |
| inc ax                 | ax = 3                                   |
| mov ax, 4C00H          | 程序终止                                 |

(2) 下面的程序执行后，ax 和 bx 中的数值为多少？

```assembly
assume cs:code
data segment
	dw 8 dup (0)
data ends
code segment
start:
	mov ax, data
	mov ss, ax
	mov sp, 16
	mov word ptr ss:[0], offset s
	mov ss:[2], cs
	call dword ptr ss:[0]
	nop
s: 
	mov ax,offset s
	sub ax,ss:[0CH]
	mov bx,cs
	sub bx,ss:[0EH]
	mov ax,4C00h
	int 21h
code ends
end start
```

分析：

* 同样数据段和栈段设置在同一段

| 指令                          | 作用                                            |
| ----------------------------- | ----------------------------------------------- |
| mov ax, data                  | ax = data                                       |
| mov ss, ax                    | ss = data                                       |
| mov sp, 16                    | sp = 10H                                        |
| mov word ptr ss:[0], offset s | ss:[0] = s(s 偏移地址存放在ss:[0]和ss:[1]中)    |
| mov ss:[2], cs                | ss:[2] = cs(cs 存放在ss:[2]和ss:[3]中)          |
| call dword ptr ss:[0]         | push CS, push IP(IP 指向 nop), sp=0CH,jmp cs:s  |
| nop                           | 不执行                                          |
| s:mov ax,offset s             | ax = s                                          |
| sub ax,ss:[0CH]               | ax = s - ss:[0CH] = s - IP = 1(nop 占 1 个字节) |
| mov bx,cs                     | bx = cs                                         |
| sub bx,ss:[0EH]               | bx = cs - ss:[0EH] = cs - cs = 0                |
| mov ax,4C00h                  | 程序终止                                        |
| int 21h                       | 程序终止                                        |

### 10.7 call 和 ret 的配合使用

​	前面分别学习了 ret 和 call 指令的原理。现在来看一下，如何将它们配合使用来实现子程序的机制。

**问题 10.1**

下面程序返回前，bx 中的值是多少？

```assembly
assume cs:code
code segment
start: 
	mov ax,1
	mov cx,3
	call s
	mov bx,ax 		;(bx)=?
	mov ax,4c00h
	int 21h
s:	 
	add ax,ax
	loop s
	ret
code ends
end start
```
**分析**：

我们来看一下CPU执行这个程序的主要过程。

​	(1) CPU 将 call s 指令的机器码读入，IP 指向了 call s 后的指令 mov bx,ax，然后 CPU 执行 call s 指令，将当前的 IP 值(指令 mov bx,ax 的偏移地址)压栈，并将 IP 的值改变为标号 s 处的偏移地址;

​	(2) CPU 从标号 s 处开始执行指令，loop 循环完毕后，(ax)=8;

​	(3) CPU 将 ret 指令的机器码读入，IP 指向了 ret 指令的内存单元，然后 CPU 执行 ret 指令，从栈中弹出一个值(即 call s 先前压入的 mov bx,ax 指令的偏移地址)送入 IP 中。则 CS:IP 指向指令 mov bx,ax;

​	(4) CPU 从 mov bx,ax 开始执行指令，直至完成。

​	程序返回前，(bx)=8。可以看出，从标号 s 到 ret 的程序段的作用是计算 2 的 N 次方，计算前，N 的值由 cx 提供。

​	我们再来看看下面的程序：

源程序

```assembly
;源程序						;内存中的情况(假设程序从内存1000:0处装入)
assume cs:code
stack segment
	db 8 dup (0)			  ;1000:0000 00 00 00 00 00 00 00
	db 8 dup (0)			  ;1000:0008 00 00 00 00 00 00 00
stack ends

code segment
start: 
	mov ax, stack			  ;1001:0000 B8 00 10
	mov ss, ax				  ;1001:0003 8E D0
	mov sp,16				  ;1001:0005 BC 10 00
	mov ax,1000				  ;1001:0008 B8 E8 03
	call s					  ;1001:000B E8 05 00
	mov ax,4c00h			  ;1001:000E B8 00 4C
	int 21h					  ;1001:0011 CD 21
s:
	add ax,ax				  ;1001:0013 03 C0
	ret						  ;1001:0015 C3
code ends
end start
```

看一下程序的主要执行过程。
(1) 前3条指令执行后，栈的情况如下:

1000:0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
													    ↑ss:sp
(2) call 指令读入后，(IP)=000EH，CPU 指令缓冲器中的代码为:E8 05 00;

CPU 执行 E8 05 00，首先，栈中的情况变为：
1000:0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0E 00
													↑ ss:sp

然后，（IP)=(IP)+0005=0013H。

(3) CPU 从 cs:0013H 处（即标号 s 处）开始执行。

(4) ret 指令读入后：

(IP)=0016H，CPU指令缓冲器中的代码为：C3

CPU 执行 C3，相当于进行 pop IP，执行后，栈中的情况为：

1000:0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0E 00
														   ↑ ss:sp

(IP)=000EH

(5) CPU 回到 cs:000EH 处（即 call 指令后面的指令处）继续执行。

​	从上面的讨论中我们发现，可以写一个具有一定功能的程序段，我们称其为**子程序**，在需要的时候，用 call 指令转去执行。可是执行完子程序后，如何让 CPU 接着 call 指令向下执行？call 指令转去执行子程序之前，call 指令后面的指令地址将存储在栈中，所以可在子程序的后面使用 ret 指令，用栈中的数据设置 IP 的值，从而转到 call 指令后面的代码处继续执行。
​	这样，我们可以利用 call 和 ret 来实现子程序的机制。子程序的框架如下。

```assembly
标号:
	指令
	ret
```

具有子程序的源程序的框架如下。

```assembly
assume cs:code
code segment
main:
	... ...
	call sub1 		;调用子程序sub1
	... ...
	... ...
	mov ax,4c00h
	int 21h
sub1:				;子程序sub1开始
	... ...
	call sub2 		;调用子程序sub2
	... ...
	... ...
	ret 			;子程序返回  
sub2:				;子程序 sub2 开始  
	...  
	ret 			;子程序返回  
code ends  
end main  
```

现在，可以从子程序的角度，回过头来再看一下本节中的两个程序。

### 10.8 mul 指令

​	因下面要用到，这里介绍一下 mul 指令，mul 是乘法指令，使用 mul 做乘法的时候，注意以下两点。

​	(1) 两个相乘的数：两个相乘的数，要么都是 8 位，要么都是 16 位。如果是 8 位，一个默认放在 AL 中，另一个放在 8 位 reg 或内存字节单元中；如果是 16 位，一个默认在 AX 中，另一个放在 16 位 reg 或内存字单元中。

​	(2) 结果：如果是 8 位乘法，结果默认放在 AX 中；如果是 16 位乘法，结果高位默认在 DX 中存放，低位在 AX 中放。

格式如下：

```assembly
mul reg  
mul 内存单元
```

内存单元可以用不同的寻址方式给出，比如：

```assembly
mul byte ptr ds:[0]  
```

含义：`(ax)=(al)*((ds)*16+0))`  

```assembly
mul word ptr [bx+si+8]  
```

含义：`(ax)=(ax)*((ds)*16+(bx)+(si)+8)`结果的低 16 位

​	    `(dx)=(ax)*((ds)*16+(bx)+(si)+8)`结果的高 16 位。

例：  

(1) 计算 100*10。
100 和 10 小于 255，可以做 8 位乘法，程序如下。  

```assembly
mov al,100  
mov bl,10  
mul bl  
```

结果：(ax)=1000(03E8H)

(2) 计算 100 * 10000

100 小于255，可10000大于255，所以必须做 16 位乘法，程序如下。

```assembly
mov ax,100
mov bx,10000
mul bx
```

结果：(ax)=4240H，(dx)=000FH		(F4240H=1000000)

### 10.9 模块化程序设计

​	从上面我们看到，call 与 ret 指令共同支持了汇编语言编程中的模块化设计。在实际编程中，**程序的模块化**是必不可少的。因为现实的问题比较复杂，对现实问题进行分析时，把它**转化成为相互联系、不同层次的子问题**，是必须的解决方法。而 call 与 ret 指令对这种分析方法提供了程序实现上的支持。利用 call 和 ret 指令，我们可以用简捷的方法，实现多个相互联系、功能独立的子程序来解决一个复杂的问题。
​	下面的内容中，我们来看一下子程序设计中的相关问题和解决方法。

### 10.10 参数和结果传递的问题

​	子程序一般都要根据提供的参数处理一定的事务，处理后，将结果(返回值)提供给调用者。其实，我们讨论参数和返回值传递的问题，实际上就是在探讨，应该**如何存储子程序需要的参数和产生的返回值**。

​	比如，设计一个子程序，可以根据提供的 N，来计算 N 的 3 次方。

这里面就有两个问题：

1. 将参数N存储在什么地方？

2. 计算得到的数值，存储在什么地方？

​	很显然，可以用寄存器来存储，可以将参数放到 bx 中；因为子程序中要计算`N*N*N`，可以使用多个 mul 指令，为了方便，可将结果放到 dx 和 ax 中。子程序如下。

```assembly
; 说明: 计算 N 的 3 次方
; 参数: (bx) = N
; 结果: (dx:ax) = N^3

cube:
	mov ax,bx
	mul bx
	mul bx
	ret
```

​	注意，我们在编程的时候要注意形成良好的风格，对于**程序应有详细的注释**。**子程序注释信息**应该包含对**子程序的功能、参数和结果**的说明。因为今天写的子程序，以后可能还会用到；自己写的子程序，也很可能要给别人使用，所以一定要有全面的说明。

​	用寄存器来存储参数和结果是常用方法。对于存放参数的寄存器和存放结果的寄存器，调用者和子程序的读写操作恰恰相反：调用者将参数送入参数寄存器，从结果寄存器中取到返回值；子程序从参数寄存器中取到参数，将返回值送入结果寄存器。

【编程】计算 data 段中第一组数据的 3 次方，结果保存在后面一组 dword 单元中。

```assembly
assume cs:code
data segment
	dw 1,2,3,4,5,6,7,8
	dd 0,0,0,0,0,0,0,0
data ends

;我们可以用到已经写好的子程序，程序如下：

code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0		;ds:si指向第一组word单元
	mov di,16		;ds:di指向第二组dword单元
	mov cx,8
s:
	mov bx,[si]
	call cube
	mov [di],ax
	mov [di+2],dx
	add si,2		;ds:si指向下一个word单元
	add di,4		;ds:di指向下一个dword单元
	loop s

	mov ax,4c00h
	int 21h

cube:
	mov ax,bx
	mul bx
	mul bx
	ret
	
code ends
end start
```

### 10.11 批量数据的传递

​	前面的例程中，子程序 cube 只有一个参数，放在 bx 中。可是如果需要传递的数据有3个、4个或更多直至N个，该怎样存放呢？寄存器的数量终究有限，我们不可能简单地用寄存器来存放多个需要传递的数据。对于返回值，也有同样的问题。

​	在这种情况下，我们将批量数据放到内存中，然后将它们所在内存空间的首地址放在寄存器中，传递给需要的子程序。对于具有批量数据的返回结果，也可用同样的方法。

【典例】设计一个子程序，功能：将一个全是字母的字符串转化为大写。

​	这个子程序需要知道两件事，字符串的内容和字符串的长度。因为字符串中的字母可能很多，所以不便将整个字符串中的所有字母都直接传递给子程序。但是，可以将**字符串在内存中的首地址**放在寄存器中传递给子程序。因为子程序要用到循环，我们可以用 loop 指令，而循环的次数恰恰就是字符串的长度。出于方便的考虑，可以将字符串的长度放到 cx 中。

子程序：

```assembly
capital: 
	and byte ptr [si],11011111b 	;将ds:si所指单元中的字母转化为大写 
	inc si							;ds:si指向下一个单元
	loop capital
	ret
```

将 data 段中的字符串转化为大写：

```assembly
assume cs:code

data segment
	db 'conversation'
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0 		;ds:si指向字符串(批量数据)所在空间的首地址
	mov cx,12 		;cx存放字符串的长度
	call capital
	mov ax,4c00h
	int 21h
capital:
	and byte ptr [si],11011111b
	inc si
	loop capital
	ret
code ends
end start
```

​	注意，除了用了寄存器传递参数外，还有一种通用的方法是**用栈来传递参数**。关于这种技术请参看附注 4。

### 10.12 寄存器冲突的问题

【编程】设计一个子程序，功能：将一个全是字母，以 0 结尾的字符串，转化为大写。

​	程序要处理的字符串以 0 作为结尾符，这个字符串可以如下定义：

```assembly
db 'conversation',0
```

​	应用这个子程序，字符串的内容后面一定要有一个 0，标记字符串的结束。子程序可以依次读取每个字符进行检测，如果不是 0，就进行大写的转化；如果是 0，就结束处理。由于可通过检测 0 知道是否已经处理完整个字符串，所以子程序可以不需要字符串的长度作为参数。可以用 jcxz 来检测 0。

```assembly
;说明：将一个全是字母，以 0 结尾的字符串，转化为大写
;参数：ds:si 指向字符串的首地址
;结果：没有返回值

capital:
	mov cl,[si]
	jcxz ok
	and byte ptr [si],11011111b ;将 ds:si 所指单元中的字母转化为大写
	inc si
	jmp short capital
ok: 
	ret
```

来看一下这个子程序的应用。

(1) 将 data 段中字符串转化为大写。

```assembly
assume cs:code
data segment
	db 'conversation', 0
data ends
```

代码段中的相关程序段如下。

```assembly
mov ax,data
mov ds,ax
mov si,0
call capital
```

(2) 将 data 段中的字符串全部转化为大写。

```assembly
assume cs:code
data segment
	db 'word', 0
	db 'unix', 0
	db 'wind', 0
	db 'good', 0
data ends
```

​	可以看到，所有字符串的长度都是 5(算上结尾符 0)，使用循环，重复调用子程序 capital，完成对 4 个字符串的处理。完整的程序如下。

```assembly
code segment
start: 
	mov ax,data
	mov ds,ax
	mov bx,0

	mov cx,4
s: 
	mov si,bx
	call capital
	add bx,5
	loop s

	mov ax,4c00h
	int 21h

capital: 
	mov cl,[si]
	mov ch,0
	jcxz ok
	and byte ptr [si],11011111b
	inc si
	jmp short capital
ok: 
	ret

code ends

end start
```

**问题 10.2** 

这个程序在思想上完全正确，但在细节上却有些错误。

**分析：**

​	问题在于 cx 的使用，主程序要使用 cx 记录循环次数，可是子程序中也使用了 cx，在执行子程序的时候，cx 中保存的循环计数值被改变，使得主程序的循环出错。

​	从上面的问题中，实际上引出了一个一般化的问题：**子程序中使用的寄存器，很可能在主程序中也要使用，造成了寄存器使用上的冲突**。

粗略地看，可以有以下两个方案来避免这种冲突。

1. 在编写调用子程序的程序时，注意看看子程序中有没有用到会产生冲突的寄存器，如果有，调用者使用别的寄存器；
2.  在编写子程序的时候，不要使用会产生冲突的寄存器。

上面两种方案可行性：

1. 会给调用子程序的程序编写造成很大麻烦，要小心检查可能产生冲突的寄存器，比如主程序的 bx 和 cx 里，cx 寄存器在子程序中用到，主程序循环就不能用。
2.  第二种方案则完全无法实现，因为编写子程序时不知道未来那个(使用子程序的)主程序的调用情况。

可见，我们上面所设想的两个方案都不可行。我们希望：

1. 编写调用子程序的程序的时候不必关心子程序到底使用了哪些寄存器；
2. 编写子程序的时候不必关心调用者使用了哪些寄存器；
3. 不会发生寄存器冲突。

​	解决这个问题的简捷方法是，在**子程序的开始将子程序中所有用到的寄存器中的内容都保存起来，在子程序返回前再恢复**。可以用栈来保存寄存器中的内容。

以后，我们编写子程序的标准框架如下：

```assembly
子程序开始：
	子程序中使用的寄存器入栈
	子程序内容
	子程序中使用的寄存器出栈
	返回(ret, retf)
```

我们改进一下子程序 capital 的设计：

```assembly
capital:
	push cx
	push si
change:
	mov cl, [si]
	mov ch, 0
	jcxz ok
	and byte ptr [si],11011111b
	inc si
	jmp short change

ok:
	pop si
	pop cx
	ret
```

要注意寄存器入栈和出栈的顺序(LIFO)。



### 附注 4 用栈传递参数

​	这种技术和高级语言编译器的工作原理密切相关。我们下面结合 C 语言的函数调用，看一下用栈传递参数的思想。

​	用栈传递参数的原理十分简单，就是由调用者将**需要传递给子程序的参数压入栈中，子程序从栈中取得参数**。我们看下面的例子。

<center style="color:#C0C0C0">表 栈中存储单元示意表</center>

| stack:0000 | ...  | 08         | 09   | 0A     | 0B   | 0C   | 0D   | 0E   | 0F   |
| ---------- | ---- | ---------- | ---- | ------ | ---- | ---- | ---- | ---- | ---- |
|            | ...  |            |      | IP     | IP   | a    | a    | b    | b    |
|            |      |            |      | ↑ss:sp |      |      |      |      |      |
| push bp    | ...  | bp         | bp   | IP     | IP   | a    | a    | b    | b    |
| mov bp,sp  | ...  | ↑ss:sp(bp) |      |        |      |      |      |      |      |

​	（注意：栈是由高地址向低地址增长的）

```assembly
;说明：计算(a-b)^3，a、b 为字型数据
;参数：进入子程序时，栈顶存放 IP，后面依次存放 a、b
;结果：(dx:ax) = (a-b)^3

difcube:
	push bp
	mov bp,sp
	mov ax,[bp+4]     ;将栈中 a 的值送入 ax 中
	sub ax,[bp+6]     ;减栈中 b 的值
	mov bp,ax
	mul bp
	mul bp
	pop bp
	ret 4
```

指令 ret n 的含义用汇编语法描述为：

```assembly
pop ip
add sp,n
```

​	因为用栈传递参数，所以调用者在调用程序的时候要向栈中压入参数，子程序在返回的时候可以用 ret n 指令将栈顶指针修改为调用前的值。调用上面的子程序之前，需要压入两个参数，所以用 ret 4 返回。

​	我们看一下如何调用上面的程序，设 a=3，b=1，下面的程序段计算 (a-b)^3：

```assembly
	mov ax,1
	push ax
	mov ax,3
	push ax			;注意参数压栈顺序	
	call diffcube
```

程序的执行过程中的变化如下。

(1) 假设栈的初始情况如下：

```assembly
1000:0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
													   ↑ss:sp
```

(2) 执行以下指令：
```assembly
mov ax, 1
push ax
mov ax, 3
push ax
```
栈的情况变为：

```assembly
                                         a     b
1000:0000 00 00 00 00 00 00 00 00 00 00 03 00 01 00 
                                         ↑ss:sp
```

(3) 执行指令 call diffcube，栈的情况变为：

```assembly
                                      IP     a     b
1000:0000 00 00 00 00 00 00 00 00 00 XX XX 03 00 01 00 
                                      ↑ss:sp
```

(4) 执行指令 push bp，栈的情况变为：

```assembly
                                      bp    IP     a     b
1000:0000 00 00 00 00 00 00 00 00 00 XX XX XX XX 03 00 01 00
                                      ↑ss:sp
```

(5) 执行指令 mov bp, sp；ss:bp 指向 1000:8

(6) 执行以下指令：
```assembly
mov ax,[bp+4]		;将栈中 a 的值送入 ax 中。
sub ax,[bp+6] 		;减栈中 b 的值
mov bp,ax
mul bp
mul bp
```
(7) 执行指令 pop bp，栈的情况变为：

```assembly
                                          IP    a     b
1000:0000 00 00 00 00 00 00 00 00 XX XX XX XX 03 00 01 00
                                        ↑ss:sp
```

(8) 执行指令 ret 4，栈的情况变为：

```assembly
1000:0000 00 00 00 00 00 00 00 00 XX XX XX XX 03 00 01 00
                                                          ↑ss:sp
```

​	下面，我们通过一个 C 语言程序编译后的汇编语言程序，看一下栈在参数传递中的应用。要注意的是，在 C 语言中，局部变量也在栈中存储。
**C 程序**

```c
void add(int,int,int);

main()
{
	int a=1;
	int b=2;
	int c=0;
	add(a,b,c);
	c++;
}

}
void add(int a,int b,int c)
{
	c=a+b;
}
```

编译后的汇编程序

```assembly
	mov bp,sp
	sub sp,6
	mov word ptr [bp-6],0001 ;int a
	mov word ptr [bp-4],0002 ;int b
	mov word ptr [bp-2],0000 ;int c
	push [bp-2]
	push [bp-4]
	push [bp-6]
	call ADDR  
	add sp,6  
	inc word ptr [bp-2]  

ADDR:  
	push bp  
	mov bp,sp  
	mov ax,[bp+4]  
	add ax,[bp+6]  
	mov [bp+8],ax  
	mov sp,bp  
	pop bp  
	ret
```

<center style="color:#C0C0C0">表 栈中存储单元示意表</center>

| ss:0               | ...    | ...    | 09     | 0A     | 0B     | 0C     | 0D     | 0E     | 0F     | 10     | ...     |
| ------------------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------- |
| 单元内容→          |        |        | ?      | ?      | ?      | ?      | ?      | ?      | ?      | ?      |         |
|                    |        |        |        |        |        |        |        |        |        | ↑sp/bp |         |
| sub sp,6           | ...    | ...    | ?      | 01     | 00     | 02     | 00     | 00     | 00     | ...    | ...     |
| mov wor ...],0000  | ...    | ...    |        | ↑sp    |        |        |        |        |        | ↑bp    |         |
| **ss:0**           | **00** | **01** | **02** | **03** | **04** | **05** | **06** | **07** | **08** | **09** | ...     |
|                    | ?      | ?      | ?      | ?      | 01     | 00     | 02     | 00     | 00     | 00     | ...     |
| push [bp-2]... -6] |        |        |        |        | ↑sp    |        |        |        |        |        | ...     |
| call ADDR          | ?      | ?      | IP     | IP     | 01     | 00     | 02     | 00     | 00     | 00     | ...     |
|                    |        |        | ↑sp    |        |        |        |        |        |        |        |         |
| push bp            | 10     | 00     | IP     | IP     | 01     | 00     | 02     | 00     | 00     | 00     | ...     |
| mov bp,sp          | ↑sp/bp |        |        |        |        |        |        |        |        |        |         |
| mov ax,[bp+4]      | ax=1   |        |        |        |        |        |        |        |        |        |         |
| add ax,[bp+6]      | ax=3   |        |        |        |        |        |        |        |        |        |         |
| mov [bp+8],ax      | 10     | 00     | IP     | IP     | 01     | 00     | 02     | 00     | 03     | 00     | ...     |
| mov sp,bp          | ↑sp/bp |        |        |        |        |        |        |        |        |        |         |
| pop bp             |        |        | ↑sp    |        |        |        |        |        |        |        | ↑bp=10H |
| ret                | 10     | 00     | IP     | IP     | 01     | 00     | 02     | 00     | 03     | 00     |         |
|                    |        |        |        |        | ↑sp    |        |        |        |        |        |         |
| **ss:0**           | ...    | ...    | **09** | **0A** | **0B** | **0C** | **0D** | **0E** | **0F** | **10** | ...     |
| add sp,6           |        |        |        | ↑sp    |        |        |        |        |        | ↑bp    |         |
| inc word...-2]     | ...    | 03     | 00     | 01     | 00     | 02     | 00     | 01     | 00     | ...    | ...     |

* 注意，先是用栈初始化了 A、B、C 三个变量，然后又按 C、B、A 顺序压栈了一次，也就是说变量存了两遍，而后面子程序调用都是在用后面压栈的三个变量，这样不会对最初初始化的三个变量造成影响，这也能解释 C 程序为什么在子函数内修改变量的值不会影响主调函数内的变量的值。
* 第二点注意，弹出栈实际上是栈内的值被“逻辑”上删除了，但是“物理”上，内存单元仍然保留着之前存过的变量的值，但如果又有变量重新入栈，这些值将会被改变。
