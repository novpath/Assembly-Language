### 课程设计 2

#### 0.任务要求

​	阅读下面的材料：

​	开机后，CPU 自动进入到 FFFF:0 单元处执行，此处有一条跳转指令。CPU 执行该指令后，转去执行 BIOS 中的硬件系统检测和初始化程序。

​	初始化程序将建立 BIOS 所支持的中断向量，即将 BIOS 提供的中断例程的入口地址登记在中断向量表中。

​	硬件系统检测和初始化完成后，调用 int 19h 进行操作系统的引导。

​	如果设为从软盘启动操作系统，则 int 19h 将主要完成以下工作：

* (1) 控制号 0 号软驱，读取软盘 0 道 0 面 1 扇区的内容到 0:7c00；

* (2) 将 CS:IP 指向 0:7c00。

​	软盘的 0 道 0 面 1 扇区中装有操作系统引导程序。int 19h 将其装载到 0:7c00 处后，设置 CPU 从 0:7c00 开始执行此处的引导程序，操作系统被激活，控制计算机。

​	如果在 0 号软驱中没有软盘，或发生软盘 I/O 错误，则 int 19h 将主要完成以下工作：

* (1) 读取硬盘 C 的 0 道 0 面 1 扇区的内容到 0:7c00；
* (2) 将 CS:IP 指向 0:7c00。

​	这次课程设计的任务是编写一个可以自行启动计算机，不需要在现有操作系统环境中运行的程序。

该程序的功能如下。

​	(1) 列出功能选项，让用户通过键盘进行选择，界面如下。

```assembly
1)reset pc 			;重新启动计算机
2)start system 		;引导现有的操作系统
3)clock 			;进入时钟程序
4)set clock 		;设置时间
```

​	(2) 用户输入“1”后重新启动计算机(提示：考虑 ffff:0 单元)。

​	(3) 用户输入“2”后引导现有的操作系统(提示：考虑硬盘 C 的 0 道 0 面 1 扇区)。

​	(4) 用户输入“3”后，执行动态显示当前日期、时间的程序。

​	显示格式如下:`年/月/日 时:分:秒`

​	进入此项功能后，一直动态显示当前的时间，在屏幕上将出现时间按秒变化的效果(提示：循环读取 CMOS)。

当按下 F1 键后，改变显示颜色；按下 Esc 键后，返回到主选单(提示：利用键盘中断)。  

​	(5) 用户输入“4”后可更改当前的日期、时间，更改后返回到主选单(提示：输入字符串)。  

​	下面给出几点建议：  

* (1) 在 DOS 下编写安装程序，在安装程序中包含任务程序；  
* (2) 运行安装程序，将任务程序写到软盘上；  
* (3) 若要任务程序可以在开机后自行执行，要将它写到软盘的 0 道 0 面 1 扇区上。如果程序长度大于 512 个字节，则需要用多个扇区存放，这种情况下，处于软盘 0 道 0 面 1 扇区中的程序就必须负责将其他扇区中的内容读入内存。 

​	这个程序较为复杂，它用到了我们所学到的所有技术，需要进行仔细分析和耐心地调试。这个程序对于我们的整个学习过程是具有总结性的，希望读者能够尽力完成。

---

解析：

* 本课程设计内容特别庞大，涉及到了几乎全部课程内容，如果从整体入手会发现可能无从下手，但是这个程序的子程序很多都是之前或多或少见过、写过的程序，因此从实现功能的子程序入手**自底向上**实现整个程序，顺便复习一下之前学过的子程序。

#### 1.显示字符串

* 菜单键、显示日期/时间等界面都有字符串，所以需要一个字符串显示函数将这些字符串显示出来，并设置字符颜色。

```assembly
;------------------------------------------------------------------------
;名称：show_str  
;功能：在指定的位置，用指定的颜色，显示一个用 0 结束的字符串。  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色，ds:si 指向字符串的首地址  
;返回：无  
;------------------------------------------------------------------------
show_str:
	push si
	push dx
	push cx			
	push bx
	push ax
	
	mov ax,0B800H	
	mov es,ax		;es 关联显存区
	mov bx,0		;偏移地址 bx 初始化为 0
	
	mov al,00A0H	;行偏移计算，只需要 8 位乘法
	mul dh
	add bx,ax		;不用特殊处理 ah，因为 8 位乘法结果直接覆盖 ax
	
	mov al,0002H	;列偏移计算，只需要 8 位乘法
	mul dl
	add bx,ax
	
	mov al,cl		;暂存颜色属性
show_core:			;打印字符核心代码
	mov cl,[si]		;先判断是否以 0 结束
	mov ch,0
	jcxz show_out

	mov es:[bx],cl		;字符写入显存区偶数位
	mov es:[bx+1],al	;字符属性写入显存区奇数位
	
	inc si				;处理数据区下一个字符
	add bx,2			;一次循环写入显存区两个字节
	jmp short show_core
show_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop si
	ret
```

#### 2.清屏程序

* 用户切换一个界面，最基本的流程就是要把屏幕上所有字符清空，然后再重新显示新的字符

```assembly
;------------------------------------------------------------------------
;名称：screen_clear
;功能：全屏幕字符用空格填充，而字符颜色属性保持不变。  
;参数：无
;返回：无  
;------------------------------------------------------------------------
screen_clear:
	push bx
	push cx
	push es			;保护现场
	mov bx,0b800h
	mov es,bx		;es 设置为显存地址
	mov bx,0
	mov cx,2000		;全屏幕 25 行 × 80 列
screen_clears:
	mov byte ptr es:[bx],' '	;当前字符置为空格
	add bx,2					;下一个字符地址
	loop screen_clears
	pop es						;恢复现场
	pop cx
	pop bx
	ret
```

#### 3.菜单界面

* 菜单界面有四个字符串，想到用**直接定址表**方法存储各字符串的首地址，然后用显示字符串函数打印再屏幕上。

```assembly
;------------------------------------------------------------------------
;名称：menu
;功能：显示菜单栏目  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色
;返回：无  
;------------------------------------------------------------------------
menu:
	jmp short menu_show
	
	linelabel dw line1,line2,line3,line4
	line1 db '1)reset pc',0
	line2 db '2)start system',0
	line3 db '3)clock',0
	line4 db '4)set clock',0
menu_show: 
	push es
	push ds
	push si
	push dx
	push bx
	mov bx,cs
	mov ds,bx				;★用到了数据标号，数据段和代码段对齐，方便调用 show_str 子程序★
	mov bx,0				;偏移量初始化
	
	call screen_clear		;清屏
menus:
	;以下用 0,2,4,6 作为相对于 line 的偏移，取得对应的字符串的偏移地址，放在 bx 中
	mov si,linelabel[bx]	;等价于 mov si,cs:[linelabel+bx]
	call show_str
	add bx,2				;移动到下一 line
	add dh,2				;下移 2 行开始打印
	cmp bx,6
	jna menus				;重复此过程，直至打印完四行
menuout:
	pop bx
	pop dx
	pop si
	pop ds
	pop es
	ret
```

测试程序`t1.asm`：

```assembly
assume cs:code

code segment
start:
	mov dl,32
	mov dh,8				
	mov cl,7				;8 行 32 列开始，黑底白字
	call menu
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 menu、screen_clear、show_str 粘贴至此处
	;-----------------------
code ends
end start
```

![17.4.2 菜单函数测试样例](文档插图/17.4.2 菜单函数测试样例.png)

<center style="color:#C0C0C0">图 17.4.2 菜单函数测试样例</center>

#### 4.菜单功能

* 上面我们只是在屏幕上打印了可视化的界面，并无实际作用，任务要求按键产生对应功能，所以需要读取键盘按键，然后调用对应功能的子函数。
* 我们可以将这些功能子程序的入口地址存储在一个**直接定址表**中，它们在表中的位置和功能号相对应。对应关系为：功能号*2=对应的功能子程序在地址表中的偏移

```assembly
;------------------------------------------------------------------------
;名称：setscreen
;功能：调用菜单栏目对应功能  
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
setscreen: 
	jmp short set
	table dw reset_pc,start_system,clock,set_clock
set:
	push bx
	
	cmp ah,3 				;判断功能号是否大于 3
	ja sret
	mov bl,ah
	mov bh,0
	add bx,bx 				;根据 ah 中的功能号计算对应子程序在 table 表中的偏移，偏移量为 1 个字
	
	call word ptr table[bx] ;调用对应的功能子程序
sret:
	pop bx
	ret
```

#### 4.1 重启 pc

* 注意任务所给材料：

> 开机后，CPU 自动进入到 FFFF:0 单元处执行，此处有一条跳转指令。CPU 执行该指令后，转去执行 BIOS 中的硬件系统检测和初始化程序。

* 所以这个 reset_pc 子程序只需要跳转到 ffff:0 单元即可，即设置 CS:IP 为 ffff:0 
* 搞不清楚 retf 是先 pop ip 还是先 pop cs 可以这么记，cs 存于高地址，ip 存于低地址，而栈是由高地址向低地址生长，所以入栈时(call far ptr 标号)是 push cs、push ip，出栈时(retf)是 pop ip、pop cs，这样就不会弄错。
* X86汇编语言，立即数不可以直接压栈，所以需要寄存器中转（而且重启的话寄存器就不用再保存了）。

```assembly
;------------------------------------------------------------------------
;名称：reset_pc
;功能：重启 pc 机
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
reset_pc:
	mov ax,0ffffH
	push ax
	mov ax,0H
	push ax
	retf
```

#### 4.2 引导现有操作系统

* 引导**现有操作系统**，同样是材料题。即模拟 0 号软驱中没有软盘，或发生软盘 I/O 错误，int 19h 需要完成的工作，需要考虑下面两点：
  * (1) 读取硬盘 C 的 0 道 0 面 1 扇区的内容到 0:7c00；
  * (2) 将 CS:IP 指向 0:7c00。

* 因为“ CPU 执行 ffff:0 处指令后，转去执行 BIOS 中的硬件系统检测和初始化程序。初始化程序将建立 BIOS 所支持的中断向量，即将 BIOS 提供的中断例程的入口地址登记在中断向量表中”。所以此时 BIOS 已经启动，可以利用第 17 章提到的(BIOS 提供的)int 13h 中断例程来完成

```assembly
;------------------------------------------------------------------------
;名称：start_system
;功能：引导现有操作系统
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
start_system:
	mov ax,0
	mov es,ax
	mov bx,7c00h	;es:bx 指向将写入磁盘的数据

	mov al,1		;(al)写入扇区数
	mov ch,0		;(ch)磁道号
	mov cl,1		;(cl)扇区号
	mov dl,80h		;(dl)驱动器号，80h 为 C 盘
	mov dh,0		;(dh)面号

	mov ah,2		;int 13h 的功能号(2 表示读扇区)
	int 13h
	
	mov ax,0
	push ax
	mov ax,7c00h
	push ax
	retf				;将 CS:IP 指向 0:7c00
```

#### 4.3 显示当前日期、时间

* 同样可以借助**数据标号**实现**日期、时间格式控制**以及**单元号选择**。
* 注意，这里是先写入字符串，然后打印，所以和之前 14 章有点不一样，要稍作修改：十位在 al，个位在 ah，这样写显示出来才是正确的顺序。 因为写入内存后的顺序是：低位在前，高位在后，打印字符串也是从低位到高位。

```assembly
;------------------------------------------------------------------------
;名称：clock
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax

	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(十位|个位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	call screen_clear		;清屏
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
```

* 测试程序`t2.asm`

```assembly
assume cs:code
code segment
start:
	call clock
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 clock、screen_clear、show_str 粘贴至此处
	;-----------------------
code ends
end start
```

* 运行结果如下，发现字体颜色是闪烁的灰底白字，这是因为初始 cx 寄存器的值的影响，使用 r 命令修改 cx = 7 后重新运行，即可看到字符颜色变为黑底白字。

![17.4.3 显示日期时间程序测试样例](文档插图/17.4.3 显示日期时间程序测试样例.png)

<center style="color:#C0C0C0">图 17.4.3 显示日期时间程序测试样例</center>

##### 4.3.1 动态显示

* 上面只是实现了静态显示当前日期、时间，接下来要实现动态显示日期、时间以及热键控制，就需要循环读取 CMOS 以及键盘中断实现。
  * 循环读取的速度太快会导致看不清屏幕输出内容，所以要使用 delay 子程序。

```assembly
;------------------------------------------------------------------------
;名称：clock(动态显示)
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax
clock_ini:
	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(十位|个位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	call screen_clear		;清屏
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	call delay				;延迟执行指令
	jmp short clock_ini		;循环读取
	
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
;------------------------------------------------------------------------
;名称：delay
;功能：延迟执行指令
;参数：无
;返回：无  
;------------------------------------------------------------------------
delay:
	push ax
	push dx
	mov dx,1h 				;循环 10000h 次，可以根据自己机器的速度调整循环次数
	mov ax,0
s1:
	sub ax,1
	sbb dx,0
	cmp ax,0
	jne s1
	cmp dx,0
	jne s1
	pop dx
	pop ax
	ret
```

* 测试程序`t2a.asm`

```assembly
assume cs:code
code segment
start:
	call clock
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 clock、delay、screen_clear、show_str 粘贴至此处
	;-----------------------
code ends
end start
```

![17.4.4 动态显示日期时间程序测试样例](文档插图/17.4.4 动态显示日期时间程序测试样例.gif)

<center style="color:#C0C0C0">图 17.4.4 动态显示日期时间程序测试样例</center>

##### 4.3.2 热键控制

* 当我们需要用热键实现特别的功能时，有两种方法，一种是通过 int 9h 中断例程在处理键盘输入时来实现；另一种是通过调用 int 16h 从键盘缓冲区中读取键盘输入来实现。后者的优点在于不需要重写编写 int 9h 中断例程。所以本题利用 int 16h 中断例程实现热键控制功能。
  * 不过使用 int 16h 的 0 号功能号来实现有一个其他问题，就是缓冲区无数据时会循环等待，这会影响我们动态刷新的时钟程序，会造成不按键时间就不会动态刷新的问题。
  * 我们需要使用 int 16h 中 ah=1 的功能号，查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的  ZF，如果 ZF=1 说明键盘没输入，循环读取，如果 ZF=0 说明键盘有输入，接着执行 int 16h  中 ah=0 的功能号，从键盘读数据并存于 al 中。

```assembly
;------------------------------------------------------------------------
;名称：clock(动态显示 + 热键控制)
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)，ESC 退出，F1 改变颜色
;返回：无  
;------------------------------------------------------------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax
clock_ini:
	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(个位|十位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	call screen_clear		;清屏
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	call delay				;延迟执行指令，不能放在 je 指令前面，因为运算指令会影响 ZF 的值
	mov ah,1				;1 号功能：查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的 ZF
	int 16h					;ZF=0，表示有键盘操作，AL 中存放当前输入的 ASCII 码，AH 存放输入字符的扩展码
	je short clock_ini		;若 ZF=1，表示无键盘输入，则循环读取(可以省去 cmp 步骤，因为本质上 je 就是查 ZF)
	
	mov ah,0				;0 号功能：从键盘读数据并存于 al 中
	int 16h	
	cmp ah,1				;按下 ESC 键退出
	je clock_out
	cmp ah,3bH				;按下 F1 键改变颜色
	jne short clock_ini		;其他按键继续循环
	inc word ptr [bp+4]		;改变字符颜色属性
	jmp short clock_ini		;按下 F1 键改变颜色后，继续循环
clock_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
```

* 测试程序`t2b.asm`

```assembly
assume cs:code
code segment
start:
	call clock
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 clock、delay、screen_clear、show_str 粘贴至此处
	;-----------------------
code ends
end start
```

![17.4.5 热键控制日期时间程序测试样例](文档插图/17.4.5 热键控制日期时间程序测试样例.gif)

<center style="color:#C0C0C0">图 17.4.5 热键控制日期时间程序测试样例</center>

#### 4.4 更改当前日期、时间

* CMOS 内部实时钟占用 0~0dh 单元来保存时间信息，所以实验目标是修改其中记录时间信息的数据达到更改当前日期、时间的目的。
* 用户输入功能的实现可以使用 17 章“输入字符串”相关内容。

* 需要复习字符栈有关内容，为什么需要搞一个字符栈？因为一般的栈都是以一个字来进行的，按字节处理的字符栈最终输入、输出更方便而且字符顺序更符合直觉。

* 程序 t3.asm：

```assembly
;------------------------------------------------------------------------
;子程序：接收字符串输入的子程序 getstr
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;返回：无；
;ds:si 指向字符栈空间；
;------------------------------------------------------------------------
getstr:
	push ax
getstrs:
	mov ah,0
	int 16h			;读取缓冲区的字符
	cmp al,20h
	jb nochar 		;ASCII 码小于 20h，说明不是字符
	mov ah,0
	call charstack 	;字符入栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
nochar:
	cmp ah,0eh		;退格键的扫描码
	je backspace 	
	cmp ah,1ch		;Enter 键的扫描码
	je enter 		
	jmp getstrs
backspace:
	mov ah,1
	call charstack 	;字符出栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
enter:
	mov al,0
	mov ah,0
	call charstack 	;0 入栈，作为字符串结尾
	mov ah,2
	call charstack 	;显示栈中的字符
	pop ax
	ret
;------------------------------------------------------------------------
;子程序：字符栈 charstack 的入栈、出栈和显示 
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;ds:si 指向字符栈空间；
;对于 0 号功能：(al)=入栈字符；
;对于 1 号功能：(al)=返回的字节；
;对于 2 号功能：(dh)、(dl)=字符串在屏幕上显示的行、列位置。
;------------------------------------------------------------------------
charstack:
	jmp short charstart
	subfun dw charpush,charpop,charshow
	top dw 0							;栈顶
charstart: 
	push bx
	push dx
	push di
	push es

	cmp ah,2				;功能号超出范围则跳出程序
	ja sret
	mov bl,ah				;bx 读取数据标号偏移量 = 功能号*2
	mov bh,0
	add bx,bx				
	jmp word ptr subfun[bx]	;跳转执行子程序
charpush:
	mov bx,top				;从 top 位置开始入栈
	mov [si][bx],al			;等价于 mov [si+bx],al
	inc top					;先入栈，再 top++ 说明 top 指向的是栈顶元素后一个位置
	jmp sret
charpop:
	cmp top,0				;检测是否为空，空则退出
	je sret
	dec top					;top 指针先减少，指向栈顶元素后再出栈
	mov bx,top
	mov al,[si][bx]			;al 存放字符栈弹出的元素
	jmp sret
charshow:
	mov bx,0b800h
	mov es,bx
	mov al,160
	mov ah,0
	mul dh
	mov di,ax
	add dl,dl
	mov dh,0
	add di,dx					;计算显示字符偏移量 行×160+列×2

	mov bx,0
charshows: 
	cmp bx,top					;检查栈是否为空
	jne noempty
	mov byte ptr es:[di],' '
	jmp sret					;若为空，则打印空格符(下一个字符位置清屏)后退出
noempty:
	mov al,[si][bx]				
	mov es:[di],al				;不为空则取出栈顶元素并显示
	mov byte ptr es:[di+2],' '	;下一个字符置为空格(下一个字符位置清屏)
	inc bx						;移动到下一个元素
	add di,2					;移动到下一个字符位置
	jmp charshows
sret:
	pop es
	pop di
	pop dx
	pop bx
	ret
```

测试程序`t3.asm`

```assembly
assume cs:code
data segment
	db 32 dup (0)		;日期/时间数据存放区
data ends
code segment
start:
	mov dh,12
	mov dl,31
	mov ax,data
	mov ds,ax
	call getstr
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 getstr、charstack 粘贴至此处
	;-----------------------
code ends
end start
```

* 现在需要写一个子程序从字符栈中读取数据，写回 CMOS 中存放日期、时间的单元。
  * 务必要记得，从栈中取数时要先将结束符 0 出栈，否则后面所有位都偏移一位，而且第一位结果计算就是错误的，调试时很容易以为是个位十位搞反了，实际上反过来调试一下也是不对的，于是就发现了这个问题，浪费了不少时间。
  * 注意一个字节是含两个 BCD 码的，一般来说取高、低 4 位是用 and 和 or 相关运算，虽然 add 和 sub 也能实现类似效果，不过不符合习惯。

```assembly
;------------------------------------------------------------------------
;名称：set_clock
;功能：修改当前日期、时间，显示格式:YYMMDDHHMMSS
;参数：扫描码-功能号(ah)，键盘输入日期、时间
;返回：无
;------------------------------------------------------------------------
set_clock:
	push di
	push bx
	push ax
	
	call getstr
	mov di,5
	mov ah,1		;0 出栈
	call charstack
setclock_in:
	mov ah,1		;出栈功能号 1
	call charstack 	;字符出栈，输出内容到 al
	sub al,30h		;个位 ASCII 码转换为 BCD 码
	mov bl,al		;暂存 al
	
	mov ah,1
	call charstack
	sub al,30h
	shl al,1
	shl al,1
	shl al,1
	shl al,1
	or bl,al		;再存十位
	
	mov al,unit_num[di]
	out 70h,al
	mov al,bl
	out 71h,al
	
	cmp di,0
	je setclock_ret
	dec di
	jmp setclock_in
setclock_ret:
	pop ax
	pop bx
	pop di
	ret
```

* 测试样例`t3a.asm`

* 由于 DOSBox 是一款 DOS 模拟器，其实前面所谓的从 CMOS 读日期、时间的指令都是在从系统中获取时间，所以修改 CMOS 中的日期和时间数据是无效的，需要在真实的机器或者其他模拟器上实现。

```assembly
assume cs:code
data segment
	db 32 dup (0)		;日期/时间数据存放区，输入格式：YYMMDDHHMMSS
data ends
code segment
start:
	mov dh,12
	mov dl,31
	mov ax,data
	mov ds,ax
	call set_clock
	call clock
	
	mov ax,4c00h
	int 21h
	;-----------------------
	;需要用到的子程序 clock(静态显示版本)、set_clock、getstr、charstack 粘贴至此处
	;-----------------------
code ends
end start
```

#### 5.任务程序

* 上面我们已经将所有任务程序功能都实现了，接下来只需要把它们组合成一个主程序即可。

* 注意的问题：
  * 精简代码，修改了时钟子程序的逻辑，不使用 delay 循环清屏而改成进入子程序前清屏一次。
  
  * 完善了 int 16h 传输参数进入 setscreen 中时与对应子程序入口地址的映射关系
  
  * (可选)热键控制改成只修改前景色
  
  * DOSBox 关闭计算器表现的是关闭 DOSBox，无法模拟引导现在的系统以及更改 CMOS 日期、时间的任务，会在之后模拟
  
  * 下面这个程序仅仅是能实现最基本的功能，至于界面布局及美观度、修改时钟信息的引导以及边界控制还需完善，但这些设置就是因人而异的了，可以根据喜好调整。不写也是避免太多无关代码引入导致无法突出代码重点。
  
    （注：正常来说，这种和用户交互的软件的引导是一定要清晰规范的，否则会给使用者造成很大麻烦，本人曾经深受其害 TAT）
  
  * 自底向上编写好大程序之后可以自顶向下完善各个子程序的细节。

```assembly
assume cs:code
data segment
	db 32 dup (0)		;日期/时间数据存放区，输入格式：YYMMDDHHMMSS
data ends
stack segment stack
	db 32 dup (0)
stack ends
code segment
start:
	mov dh,8
	mov dl,32
	mov ax,data
	mov ds,ax
	mov cx,7
	call menu

	mov ah,0
	int 16h
	call setscreen
	
	jmp short start
	mov ax,4c00h
	int 21h
;------------------------------------------------------------------------
;名称：show_str  
;功能：在指定的位置，用指定的颜色，显示一个用 0 结束的字符串。  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色，ds:si 指向字符串的首地址  
;返回：无  
;------------------------------------------------------------------------
show_str:
	push si
	push dx
	push cx			
	push bx
	push ax
	
	mov ax,0B800H	
	mov es,ax		;es 关联显存区
	mov bx,0		;偏移地址 bx 初始化为 0
	
	mov al,00A0H	;行偏移计算，只需要 8 位乘法
	mul dh
	add bx,ax		;不用特殊处理 ah，因为 8 位乘法结果直接覆盖 ax
	
	mov al,0002H	;列偏移计算，只需要 8 位乘法
	mul dl
	add bx,ax
	
	mov al,cl		;暂存颜色属性
show_core:			;打印字符核心代码
	mov cl,[si]		;先判断是否以 0 结束
	mov ch,0
	jcxz show_out

	mov es:[bx],cl		;字符写入显存区偶数位
	mov es:[bx+1],al	;字符属性写入显存区奇数位
	
	inc si				;处理数据区下一个字符
	add bx,2			;一次循环写入显存区两个字节
	jmp short show_core
show_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop si
	ret
;------------------------------------------------------------------------
;名称：screen_clear
;功能：全屏幕字符用空格填充，而字符颜色属性保持不变。  
;参数：无
;返回：无  
;------------------------------------------------------------------------
screen_clear:
	push bx
	push cx
	push es			;保护现场
	mov bx,0b800h
	mov es,bx		;es 设置为显存地址
	mov bx,0
	mov cx,2000		;全屏幕 25 行 × 80 列
screen_clears:
	mov byte ptr es:[bx],' '	;当前字符置为空格
	add bx,2					;下一个字符地址
	loop screen_clears
	pop es						;恢复现场
	pop cx
	pop bx
	ret
;------------------------------------------------------------------------
;名称：menu
;功能：显示菜单栏目  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色
;返回：无  
;------------------------------------------------------------------------
menu:
	jmp short menu_show
	
	linelabel dw line1,line2,line3,line4
	line1 db '1)reset pc',0
	line2 db '2)start system',0
	line3 db '3)clock',0
	line4 db '4)set clock',0
menu_show: 
	push es
	push ds
	push si
	push dx
	push bx
	mov bx,cs
	mov ds,bx				;★用到了数据标号，数据段和代码段对齐，方便调用 show_str 子程序★
	mov bx,0				;偏移量初始化
	
	call screen_clear		;清屏
menus:
	;以下用 0,2,4,6 作为相对于 line 的偏移，取得对应的字符串的偏移地址，放在 bx 中
	mov si,linelabel[bx]	;等价于 mov si,cs:[linelabel+bx]
	call show_str
	add bx,2				;移动到下一 line
	add dh,2				;下移 2 行开始打印
	cmp bx,6
	jna menus				;重复此过程，直至打印完四行
menuout:
	pop bx
	pop dx
	pop si
	pop ds
	pop es
	ret
;------------------------------------------------------------------------
;名称：setscreen
;功能：调用菜单栏目对应功能  
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
setscreen: 
	jmp short set
	table dw 0,reset_pc,start_system,clock,set_clock	;预留 0 号位，方便和按键对应
set:
	push bx
	push ax
	sub al,30h				;将 int 16h 传递的 al 中的 ASCII 码转化为数值
	cmp al,4 				;判断按键是否大于 4
	ja setret
	mov bl,al
	mov bh,0
	add bx,bx 				;根据 ah 中的功能号计算对应子程序在 table 表中的偏移，偏移量为 1 个字
	call word ptr table[bx] ;调用对应的功能子程序
setret:
	pop ax
	pop bx
	ret
;------------------------------------------------------------------------
;名称：reset_pc
;功能：重启 pc 机
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
reset_pc:
	mov ax,0ffffH
	push ax
	mov ax,0H
	push ax
	retf
;------------------------------------------------------------------------
;名称：start_system
;功能：引导现有操作系统
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
start_system:
	mov ax,0
	mov es,ax
	mov bx,7c00h	;es:bx 指向将写入磁盘的数据

	mov al,1		;(al)写入扇区数
	mov ch,0		;(ch)磁道号
	mov cl,1		;(cl)扇区号
	mov dl,80h		;(dl)驱动器号，80h 为 C 盘
	mov dh,0		;(dh)面号

	mov ah,2		;int 13h 的功能号(2 表示读扇区)
	int 13h
	
	mov ax,0
	push ax
	mov ax,7c00h
	push ax
	retf				;将 CS:IP 指向 0:7c00
;------------------------------------------------------------------------
;名称：clock(动态显示 + 热键控制)
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)，ESC 退出，F1 改变颜色
;返回：无  
;------------------------------------------------------------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax
	call screen_clear		;清屏
clock_ini:
	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(个位|十位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	mov ah,1				;1 号功能：查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的 ZF
	int 16h					;ZF=0，表示有键盘操作，AL 中存放当前输入的 ASCII 码，AH 存放输入字符的扩展码
	je short clock_ini		;若 ZF=1，表示无键盘输入，则循环读取(可以省去 cmp 步骤，因为本质上 je 就是查 ZF)
	
	mov ah,0				;0 号功能：从键盘读数据并存于 al 中
	int 16h	
	cmp ah,1				;按下 ESC 键退出
	je clock_out
	cmp ah,3bH				;按下 F1 键改变颜色
	jne short clock_ini		;其他按键也是继续循环
	inc word ptr [bp+4]		;改变字符颜色属性
	and word ptr [bp+4],07H	;改变前景色
	jmp short clock_ini
clock_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
;------------------------------------------------------------------------
;名称：set_clock
;功能：修改当前日期、时间，显示格式:YYMMDDHHMMSS
;参数：扫描码-功能号(ah)，键盘输入日期、时间
;返回：无
;------------------------------------------------------------------------
set_clock:
	push di
	push bx
	push ax
	call screen_clear		;清屏
	call getstr
	mov di,5
	mov ah,1		;结束符 0 出栈
	call charstack
setclock_in:
	mov ah,1		;出栈功能号 1
	call charstack 	;字符出栈，输出内容到 al
	sub al,30h		;个位 ASCII 码转换为 BCD 码
	mov bl,al		;低 4 位暂存个位 al
	
	mov ah,1
	call charstack
	sub al,30h
	shl al,1
	shl al,1
	shl al,1
	shl al,1
	or bl,al		;高 4 位再存十位
	
	mov al,unit_num[di]
	out 70h,al
	mov al,bl
	out 71h,al
	
	cmp di,0
	je setclock_ret
	dec di
	jmp setclock_in
setclock_ret:
	pop ax
	pop bx
	pop di
	ret
;------------------------------------------------------------------------
;子程序：接收字符串输入的子程序 getstr
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;返回：无；
;ds:si 指向字符栈空间；
;------------------------------------------------------------------------
getstr:
	push ax
getstrs:
	mov ah,0
	int 16h			;读取缓冲区的字符
	cmp al,20h
	jb nochar 		;ASCII 码小于 20h，说明不是字符
	mov ah,0
	call charstack 	;字符入栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
nochar:
	cmp ah,0eh		;退格键的扫描码
	je backspace 	
	cmp ah,1ch		;Enter 键的扫描码
	je enter 		
	jmp getstrs
backspace:
	mov ah,1
	call charstack 	;字符出栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
enter:
	mov al,0
	mov ah,0
	call charstack 	;0 入栈，作为字符串结尾
	mov ah,2
	call charstack 	;显示栈中的字符
	pop ax
	ret
;------------------------------------------------------------------------
;子程序：字符栈 charstack 的入栈、出栈和显示 
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;ds:si 指向字符栈空间；
;对于 0 号功能：(al)=入栈字符；
;对于 1 号功能：(al)=返回的字节；
;对于 2 号功能：(dh)、(dl)=字符串在屏幕上显示的行、列位置。
;------------------------------------------------------------------------
charstack:
	jmp short charstart
	subfun dw charpush,charpop,charshow
	top dw 0							;栈顶
charstart: 
	push bx
	push dx
	push di
	push es

	cmp ah,2				;功能号超出范围则跳出程序
	ja sret
	mov bl,ah				;bx 读取数据标号偏移量 = 功能号*2
	mov bh,0
	add bx,bx				
	jmp word ptr subfun[bx]	;跳转执行子程序
charpush:
	mov bx,top				;从 top 位置开始入栈
	mov [si][bx],al			;等价于 mov [si+bx],al
	inc top					;先入栈，再 top++ 说明 top 指向的是栈顶元素后一个位置
	jmp sret
charpop:
	cmp top,0				;检测是否为空，空则退出
	je sret
	dec top					;top 指针先减少，指向栈顶元素后再出栈
	mov bx,top
	mov al,[si][bx]			;al 存放字符栈弹出的元素
	jmp sret
charshow:
	mov bx,0b800h
	mov es,bx
	mov al,160
	mov ah,0
	mul dh
	mov di,ax
	add dl,dl
	mov dh,0
	add di,dx					;计算显示字符偏移量 行×160+列×2

	mov bx,0
charshows: 
	cmp bx,top					;检查栈是否为空
	jne noempty
	mov byte ptr es:[di],' '
	jmp sret					;若为空，则打印空格符(下一个字符位置清屏)后退出
noempty:
	mov al,[si][bx]				
	mov es:[di],al				;不为空则取出栈顶元素并显示
	mov byte ptr es:[di+2],' '	;下一个字符置为空格(下一个字符位置清屏)
	inc bx						;移动到下一个元素
	add di,2					;移动到下一个字符位置
	jmp charshows
sret:
	pop es
	pop di
	pop dx
	pop bx
	ret
	
code ends
end start
```

#### 6.DOS 实模式模拟

* 接下来使用 VMware 17 虚拟机中的 FreeDOS 1.3 Floppy Edition 系统来模拟真实的硬件环境。
* 由于后续有可能会对软盘数据进行修改，以及对系统日期、时间进行修改，所以要对数据进行备份以及设置还原点（可选用 VMware 的拍摄快照功能）

* 使用 WINImage 将任务文件的`.exe`可执行文件制作成虚拟软盘文件，后缀为`.flp`或者`.img`。

* 成功运行！至此，我们实现了第一步，可以在 MS-DOS 系统里面运行任务文件`task.exe`
  * 此时第二个功能——引导操作系统，还不能正常使用，这是因为虚拟机系统的安全保护机制，我们需要安装程序到软盘扇区之后就可以正常运行了（见之后的演示）。

* 接下来我们要实现第二步，将程序安装至软盘并任务程序实现开机自启动

#### 7.程序安装与开机自启动

* 阅读材料可知，要想实现程序开机自启动，需要将任务程序写到软盘的 0 道 0 面 1 扇区，但是我们的任务程序大小为 1200Byte 大于 1 个扇区 512 字节，所以要用 3 个扇区存放，而 1 扇区的程序负责引导 CPU 将其他扇区内容读入内存。
* 开机自动转向 0:7c00H 处加载软盘 0 道 0 面 1 扇区的内容，长度为 512(200H) 字节，计算出末地址为 0:7dffH，额外预留 256(100H) 字节给系统栈空间（防止产生冲突），因此任务程序可以被加载到 0:7f00H 处

| **程序类型** | **安装位置**              | **执行功能**                       |
| ------------ | ------------------------- | ---------------------------------- |
| 安装程序     | 无                        | 将引导程序和任务程序安装到软盘     |
| 引导程序     | 软盘 0 道 0 面 1 扇区     | 将任务程序载入内存，跳转到任务程序 |
| 任务程序     | 软盘 0 道 0 面 2 扇区开始 | 执行任务                           |

* 目前确定任务程序要被安装到 0:7f00H 处，所以使用 org 标号防止编译后标号地址错乱。

```assembly
assume cs:code

code segment
start:
	mov ax,cs
	mov es,ax
 
	mov bx,offset lead 	;将引导程序写入软盘 0 道 0 面 1 扇区
	mov al,1 			;操作扇区数量
	mov ah,3 			;写入操作
	mov dl,0 			;驱动器号：软驱 A
	mov dh,0 			;面号
	mov ch,0 			;磁道号
	mov cl,1 			;扇区号
	int 13H
 
	mov bx,offset main_ini 	;将主程序写入软盘 0 道 0 面 2 扇区开始的 3 个扇区
	mov al,3 				;操作扇区数量
	mov ah,3 				;写入操作
	mov dl,0 				;驱动器号 软驱A
	mov dh,0 				;面号
	mov ch,0 				;磁道号
	mov cl,2 				;扇区号
	int 13H
 
	mov ax,4c00H
	int 21H
lead: 					;引导程序，被保存在软盘 0 道 0 面 1 扇区，由操作系统加载到 0:7c00H 处，
						;负责被加载后从 0 道 0 面 2 扇区开始的 3 个扇区加载主程序
	mov ax,0
	mov ss,ax
	mov sp,7f00H 		;0:7e00H 到 0:7f00H 是安全的栈空间
	
	mov ax,cs
	mov es,ax
	mov bx,7f00H 		;es:bx 指向接收从扇区读入数据的内存区，将主程序加载到 0:7f00H 处
 
	mov al,3 			;操作扇区数量
	mov ah,2 			;读取操作
	mov dl,0 			;驱动器号 软驱 A
	mov dh,0 			;面号
	mov ch,0 			;磁道号
	mov cl,2 			;扇区号
	int 13H
 
	mov ax,0
	push ax
	mov ax,7f00h
	push ax
	retf				;将 CS:IP 指向 0:7f00
 
	org 7f00H 			;防止数据标号错乱
main_ini:
	jmp short main
	data segment
    	db 32 dup (0)		;日期/时间数据存放区，输入格式：YYMMDDHHMMSS
	data ends
	stack segment stack
		db 32 dup (0)
	stack ends
main:
	mov dh,8
	mov dl,32
	mov ax,data
	mov ds,ax
	mov cx,7
	call menu

	mov ah,0
	int 16h
	call setscreen
	
	jmp short main
	mov ax,4c00h
	int 21h
;------------------------------------------------------------------------
;名称：show_str  
;功能：在指定的位置，用指定的颜色，显示一个用 0 结束的字符串。  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色，ds:si 指向字符串的首地址  
;返回：无  
;------------------------------------------------------------------------
show_str:
	push si
	push dx
	push cx			
	push bx
	push ax
	
	mov ax,0B800H	
	mov es,ax		;es 关联显存区
	mov bx,0		;偏移地址 bx 初始化为 0
	
	mov al,00A0H	;行偏移计算，只需要 8 位乘法
	mul dh
	add bx,ax		;不用特殊处理 ah，因为 8 位乘法结果直接覆盖 ax
	
	mov al,0002H	;列偏移计算，只需要 8 位乘法
	mul dl
	add bx,ax
	
	mov al,cl		;暂存颜色属性
show_core:			;打印字符核心代码
	mov cl,[si]		;先判断是否以 0 结束
	mov ch,0
	jcxz show_out

	mov es:[bx],cl		;字符写入显存区偶数位
	mov es:[bx+1],al	;字符属性写入显存区奇数位
	
	inc si				;处理数据区下一个字符
	add bx,2			;一次循环写入显存区两个字节
	jmp short show_core
show_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop si
	ret
;------------------------------------------------------------------------
;名称：screen_clear
;功能：全屏幕字符用空格填充，而字符颜色属性保持不变。  
;参数：无
;返回：无  
;------------------------------------------------------------------------
screen_clear:
	push bx
	push cx
	push es			;保护现场
	mov bx,0b800h
	mov es,bx		;es 设置为显存地址
	mov bx,0
	mov cx,2000		;全屏幕 25 行 × 80 列
screen_clears:
	mov byte ptr es:[bx],' '	;当前字符置为空格
	add bx,2					;下一个字符地址
	loop screen_clears
	pop es						;恢复现场
	pop cx
	pop bx
	ret
;------------------------------------------------------------------------
;名称：menu
;功能：显示菜单栏目  
;参数：(dh)=行号(取值范围 0~24)，(dl)=列号(取值范围 0~79)，(cl)=颜色
;返回：无  
;------------------------------------------------------------------------
menu:
	jmp short menu_show
	
	linelabel dw line1,line2,line3,line4
	line1 db '1)reset pc',0
	line2 db '2)start system',0
	line3 db '3)clock',0
	line4 db '4)set clock',0
menu_show: 
	push es
	push ds
	push si
	push dx
	push bx
	mov bx,cs
	mov ds,bx				;★用到了数据标号，数据段和代码段对齐，方便调用 show_str 子程序★
	mov bx,0				;偏移量初始化
	
	call screen_clear		;清屏
menus:
	;以下用 0,2,4,6 作为相对于 line 的偏移，取得对应的字符串的偏移地址，放在 bx 中
	mov si,linelabel[bx]	;等价于 mov si,cs:[linelabel+bx]
	call show_str
	add bx,2				;移动到下一 line
	add dh,2				;下移 2 行开始打印
	cmp bx,6
	jna menus				;重复此过程，直至打印完四行
menuout:
	pop bx
	pop dx
	pop si
	pop ds
	pop es
	ret
;------------------------------------------------------------------------
;名称：setscreen
;功能：调用菜单栏目对应功能  
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
setscreen: 
	jmp short set
	table dw 0,reset_pc,start_system,clock,set_clock	;预留 0 号位，方便和按键对应
set:
	push bx
	push ax
	sub al,30h				;将 int 16h 传递的 al 中的 ASCII 码转化为数值
	cmp al,4 				;判断按键是否大于 4
	ja setret
	mov bl,al
	mov bh,0
	add bx,bx 				;根据 ah 中的功能号计算对应子程序在 table 表中的偏移，偏移量为 1 个字
	call word ptr table[bx] ;调用对应的功能子程序
setret:
	pop ax
	pop bx
	ret
;------------------------------------------------------------------------
;名称：reset_pc
;功能：重启 pc 机
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
reset_pc:
	mov ax,0ffffH
	push ax
	mov ax,0H
	push ax
	retf
;------------------------------------------------------------------------
;名称：start_system
;功能：引导现有操作系统
;参数：扫描码-功能号(ah)
;返回：无  
;------------------------------------------------------------------------
start_system:
	mov ax,0
	mov es,ax
	mov bx,7c00h	;es:bx 指向将写入磁盘的数据

	mov al,1		;(al)写入扇区数
	mov ch,0		;(ch)磁道号
	mov cl,1		;(cl)扇区号
	mov dl,80h		;(dl)驱动器号，80h 为 C 盘
	mov dh,0		;(dh)面号

	mov ah,2		;int 13h 的功能号(2 表示读扇区)
	int 13h
	
	mov ax,0
	push ax
	mov ax,7c00h
	push ax
	retf				;将 CS:IP 指向 0:7c00
;------------------------------------------------------------------------
;名称：clock(动态显示 + 热键控制)
;功能：显示当前日期、时间，显示格式:年/月/日 时:分:秒
;参数：扫描码-功能号(ah)，ESC 退出，F1 改变颜色
;返回：无  
;------------------------------------------------------------------------
clock:
	jmp short clock_in
	format db 'YY/MM/DD HH:MM:SS',0 ;日期、时间字符串模板
	unit_num db 9,8,7,4,2,0			;要读取的单元号
clock_in:
	push bp
	push si
	push ds
	push dx
	push cx
	push bx
	push ax
	call screen_clear		;清屏
clock_ini:
	mov ax,cs
	mov ds,ax				;★用到了数据标号，将数据段和代码段对齐★
	mov si,0				;单元号数据标号步进变量 si
	mov bx,0				;字符串数据标号步进变量 bx
clock_show:
	mov al,unit_num[si]		;从数据标号处取得单元号
	out 70h,al				;地址端口写入单元号
	in al,71h				;数据端口读取单元号
	
	mov ah,al				;ah 存放单元号中的内容
	mov cl,4
	shr al,cl				;al 取得十位
	and ah,00001111b		;ah 取得个位
	
	add ax,3030h				;(个位|十位 h)转换为字符
	mov word ptr format[bx],ax	;写回字符串
	inc si						;指向下一个单元
	add bx,3					;指向字符串下一个写入位置
	
	cmp si,6
	jnb clock_ret
	jmp clock_show
clock_ret:
	mov si,offset format	;指向日期/时间字符串位置
	mov dh,12	
	mov dl,31				;12 行 31 列居中显示
	mov bp,sp
	mov cx,[bp+4]			;取得字符颜色
	call show_str			;显示字符串
	
	mov ah,1				;1 号功能：查询键盘缓冲区，对键盘进行扫描但不等待，并设置标志寄存器中的 ZF
	int 16h					;ZF=0，表示有键盘操作，AL 中存放当前输入的 ASCII 码，AH 存放输入字符的扩展码
	je short clock_ini		;若 ZF=1，表示无键盘输入，则循环读取(可以省去 cmp 步骤，因为本质上 je 就是查 ZF)
	
	mov ah,0				;0 号功能：从键盘读数据并存于 al 中
	int 16h	
	cmp ah,1				;按下 ESC 键退出
	je clock_out
	cmp ah,3bH				;按下 F1 键改变颜色
	jne short clock_ini		;其他按键也是继续循环
	inc word ptr [bp+4]		;改变字符颜色属性
	and word ptr [bp+4],07H	;改变前景色
	jmp short clock_ini
clock_out:
	pop ax
	pop bx
	pop cx
	pop dx
	pop ds
	pop si
	pop bp
	ret
;------------------------------------------------------------------------
;名称：set_clock
;功能：修改当前日期、时间，显示格式:YYMMDDHHMMSS
;参数：扫描码-功能号(ah)，键盘输入日期、时间
;返回：无
;------------------------------------------------------------------------
set_clock:
	push di
	push bx
	push ax
	call screen_clear		;清屏
	call getstr
	mov di,5
	mov ah,1		;结束符 0 出栈
	call charstack
setclock_in:
	mov ah,1		;出栈功能号 1
	call charstack 	;字符出栈，输出内容到 al
	sub al,30h		;个位 ASCII 码转换为 BCD 码
	mov bl,al		;低 4 位暂存个位 al
	
	mov ah,1
	call charstack
	sub al,30h
	shl al,1
	shl al,1
	shl al,1
	shl al,1
	or bl,al		;高 4 位再存十位
	
	mov al,unit_num[di]
	out 70h,al
	mov al,bl
	out 71h,al
	
	cmp di,0
	je setclock_ret
	dec di
	jmp setclock_in
setclock_ret:
	pop ax
	pop bx
	pop di
	ret
;------------------------------------------------------------------------
;子程序：接收字符串输入的子程序 getstr
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;返回：无；
;ds:si 指向字符栈空间；
;------------------------------------------------------------------------
getstr:
	push ax
getstrs:
	mov ah,0
	int 16h			;读取缓冲区的字符
	cmp al,20h
	jb nochar 		;ASCII 码小于 20h，说明不是字符
	mov ah,0
	call charstack 	;字符入栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
nochar:
	cmp ah,0eh		;退格键的扫描码
	je backspace 	
	cmp ah,1ch		;Enter 键的扫描码
	je enter 		
	jmp getstrs
backspace:
	mov ah,1
	call charstack 	;字符出栈
	mov ah,2
	call charstack 	;显示栈中的字符
	jmp getstrs
enter:
	mov al,0
	mov ah,0
	call charstack 	;0 入栈，作为字符串结尾
	mov ah,2
	call charstack 	;显示栈中的字符
	pop ax
	ret
;------------------------------------------------------------------------
;子程序：字符栈 charstack 的入栈、出栈和显示 
;参数说明：(ah)=功能号，0 表示入栈，1 表示出栈，2 表示显示；
;ds:si 指向字符栈空间；
;对于 0 号功能：(al)=入栈字符；
;对于 1 号功能：(al)=返回的字节；
;对于 2 号功能：(dh)、(dl)=字符串在屏幕上显示的行、列位置。
;------------------------------------------------------------------------
charstack:
	jmp short charstart
	subfun dw charpush,charpop,charshow
	top dw 0							;栈顶
charstart: 
	push bx
	push dx
	push di
	push es

	cmp ah,2				;功能号超出范围则跳出程序
	ja sret
	mov bl,ah				;bx 读取数据标号偏移量 = 功能号*2
	mov bh,0
	add bx,bx				
	jmp word ptr subfun[bx]	;跳转执行子程序
charpush:
	mov bx,top				;从 top 位置开始入栈
	mov [si][bx],al			;等价于 mov [si+bx],al
	inc top					;先入栈，再 top++ 说明 top 指向的是栈顶元素后一个位置
	jmp sret
charpop:
	cmp top,0				;检测是否为空，空则退出
	je sret
	dec top					;top 指针先减少，指向栈顶元素后再出栈
	mov bx,top
	mov al,[si][bx]			;al 存放字符栈弹出的元素
	jmp sret
charshow:
	mov bx,0b800h
	mov es,bx
	mov al,160
	mov ah,0
	mul dh
	mov di,ax
	add dl,dl
	mov dh,0
	add di,dx					;计算显示字符偏移量 行×160+列×2

	mov bx,0
charshows: 
	cmp bx,top					;检查栈是否为空
	jne noempty
	mov byte ptr es:[di],' '
	jmp sret					;若为空，则打印空格符(下一个字符位置清屏)后退出
noempty:
	mov al,[si][bx]				
	mov es:[di],al				;不为空则取出栈顶元素并显示
	mov byte ptr es:[di+2],' '	;下一个字符置为空格(下一个字符位置清屏)
	inc bx						;移动到下一个元素
	add di,2					;移动到下一个字符位置
	jmp charshows
sret:
	pop es
	pop di
	pop dx
	pop bx
	ret
	
code ends
end start
```

* 编译、连接上述程序，此时可执行文件`tasksr.exe`会比之前任务程序`task.exe`大很多，这是正常现象。
* 用 WinImage 将`tasksr.exe`制作成软盘 .flp 文件，然后插入虚拟机的软盘 B，切换到 b: 盘执行安装程序。
* 重新开机发现开机自动执行了我们的任务程序（而且此时软盘 A 已经被修改！注意之前提过的备份）
* 功能一：重启 PC，实现成功！（蓝色的圆形色块是录屏软件产生的，请忽略。）

![17.4.6 重启 pc 示意图](文档插图/17.4.6 重启 pc 示意图.gif)

<center style="color:#C0C0C0">图 17.4.6 重启 pc 示意图</center>

* 功能二：引导现有操作系统功能正常执行，如下

![17.4.7 引导现有操作系统示意图](文档插图/17.4.7 引导现有操作系统示意图.gif)

<center style="color:#C0C0C0">图 17.4.7 引导现有操作系统示意图</center>

* 功能三：查看时钟及热键控制功能正常执行，F1 换色、ESC 键退回主菜单，如下：

![17.4.8 查看时钟以及热键控制示意图](文档插图/17.4.8 查看时钟以及热键控制示意图.gif)

<center style="color:#C0C0C0">图 17.4.8 查看时钟以及热键控制示意图</center>

* 功能四：更改当前日期、时间功能正常运行，修改完重新进入时钟页面，发现仍是修改后的值，证明是真正修改了 CMOS 里的数据单元。

![17.4.9 更改当前日期、时间示意图](文档插图/17.4.9 更改当前日期、时间示意图.gif)

<center style="color:#C0C0C0">图 17.4.9 更改当前日期、时间示意图</center>

#### 8.总结

* 至此，完成了课程设计 2 中的所有内容，完结撒花～(∠・ω< )⌒🏵
* 本课程设计的完结，也标志着该门课程接近尾声，后续还有一点收尾内容会另起一章说明。该课程设计属于本课程门槛最高的内容，需要对之前学过的相关内容熟悉，并且举一反三，才能够编写出符合要求的程序，通过本课程设计的研究反过来也可以促进知识的融会贯通，而且加深理解，明白知易行难的道理。
* 学习了利用 VMware + MS-DOS 模拟真实实模式 DOS 汇编环境，由于汇编语言年代久远了，所以搭建这个仿真的 DOS 环境也是有不小的门槛的，可以参见网络上有关教程。相应的 Free-DOS 系统、虚拟软盘文件、可执行文件等内容，我也会放在第 17 章课程设计 2 相关文件夹下。
* 本课程设计 2 贯彻落实了本书提到的“**知识屏蔽**”学习方法，而且出于规范考虑，本课程设计中绝大多数程序都是基于之前学习过的程序改写而成的，所以没有多余的个性化内容，有兴趣可以自行完善。
* 提醒：由于课程设计程序进行了多次修改，可能出现本文程序内容和对应编译文本 .asm 文件出现细微差别的问题，出于保留思考痕迹的考虑以及有可能没有将对应部分完全修改，最终以笔记内的程序为准，可以方便的使用 MASM 重新编译、连接成可执行文件。
