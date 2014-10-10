@DeCode:
	call	@impcode
;构建外壳输入表


@impcode:
	pop	ebp				;地址重定位ebp指向ImportTable地址
	sub	ebp,(@impcode-@DeCode)	;ebp就是@DeCode的地址
	lea	esi,[ebp+(DLLName-@DeCode)]
	push	esi
	call	dword ptr [ebp+(THUNK_DATA2-@DeCode)]
	push	PAGE_READWRITE
	push	MEM_COMMIT
	push	dword ptr [ebp+(ShellPackSize-@DeCode)]
	push	0
	call	dword ptr [ebp+(THUNK_DATA4-@DeCode)]		;call VirtualAlloc函数
	mov	esi,eax						;分配的内存地址
	mov	ebx,dword ptr [ebp+(ShellBase-@DeCode)]
	add	ebx,ebp
	push	eax
	push	ebx
	call	_aP_depack_asm				;进行解压缩
	push	ebp
	jmp	esi					;跳到解压出来的代码处执行

ImportTable:	
	OriginalFirstThunk	dd	THUNK_DATA1 - ImportTable
	TimeDateStamp		dd	0
	ForwarderChain		dd	0
	libname			dd	DLLName - ImportTable	;模块名的RVA

	FirstThunk		dd	THUNK_DATA1 - ImportTable
	NewImport		db	100*20 DUP(0)

	THUNK_DATA1		dd	FirstFun  - ImportTable
	THUNK_DATA2		dd	SecondFun - ImportTable
	THUNK_DATA3		dd	ThirdFun  - ImportTable
	THUNK_DATA4		dd	FourthFun - ImportTable
				dd	0

	DLLName			db	'Kernel32.dll',0
	FirstFun		dw	0	
				db	'GetProcAddress',0
	SecondFun		dw	0
				db	'GetModuleHandleA',0
	ThirdFun		dw	0
				db	'LoadLibraryA',0
	FourthFun		dw	0
				db	'VirtualAlloc',0

	ShellPackSize		dd	0
	ShellBase		dd	0
	TlsTable		DB	18h dup (?)


_aP_depack_asm:
    pushad
    mov    esi, [esp + 36]    ; C calling convention
    mov    edi, [esp + 40]
    cld
    mov    dl, 80h
    xor    ebx, ebx
literal:
    movsb
    mov    bl, 2
nexttag:
    call   getbit
    jnc    literal

    xor    ecx, ecx
    call   getbit
    jnc    codepair
    xor    eax, eax
    call   getbit
    jnc    shortmatch
    mov    bl, 2
    inc    ecx
    mov    al, 10h
getmorebits:
    call   getbit
    adc    al, al
    jnc    getmorebits
    jnz    domatch
    stosb
    jmp    short nexttag
codepair:
    call   getgamma_no_ecx
    sub    ecx, ebx
    jnz    normalcodepair
    call   getgamma
    jmp    short domatch_lastpos
shortmatch:
    lodsb
    shr    eax, 1
    jz     donedepacking
    adc    ecx, ecx
    jmp    short domatch_with_2inc
normalcodepair:
    xchg   eax, ecx
    dec    eax
    shl    eax, 8
    lodsb
    call   getgamma
    cmp    eax, 32000
    jae    domatch_with_2inc
    cmp    ah, 5
    jae    domatch_with_inc
    cmp    eax, 7fh
    ja     domatch_new_lastpos
domatch_with_2inc:
    inc    ecx
domatch_with_inc:
    inc    ecx
domatch_new_lastpos:
    xchg   eax, ebp
domatch_lastpos:
    mov    eax, ebp
    mov    bl, 1
domatch:
    push   esi
    mov    esi, edi
    sub    esi, eax
    rep    movsb
    pop    esi
    jmp    short nexttag
getbit:
    add     dl, dl
    jnz     stillbitsleft
    mov     dl, [esi]
    inc     esi
    adc     dl, dl
stillbitsleft:
    ret
getgamma:
    xor    ecx, ecx
getgamma_no_ecx:
    inc    ecx
getgammaloop:
    call   getbit
    adc    ecx, ecx
    call   getbit
    jc     getgammaloop
    ret
donedepacking:
    sub    edi, [esp + 40]
    mov    [esp + 28], edi    ; return unpacked length in eax
    popad
    ret	8h

@DeCodeEnd:


;解压PE文件代码
@UnPack:
	call	@lable
	@lable:	
		pop	edx
		sub	edx,(@lable-@UnPack)		;取得@UnPack的地址
		pop	ebp
	;保存外壳输入表函数地址
		xor	ecx,ecx
		mov	ecx,4	
		lea	esi,[ebp+(THUNK_DATA1-@DeCode)]
		lea	edi,[edx+(GetProcAddr-@UnPack)]
	@save:
		push	dword ptr [esi]
		pop	dword ptr [edi]
		add	edi,04h
		add	esi,04h
		loop	@save
		lea	eax,[ebp+(_aP_depack_asm-@DeCode)]
		mov	dword ptr [edx+(aP_depackAddr-@UnPack)],eax
		mov	ebp,edx
		push	0
		call	dword ptr [ebp+(GetModuleAddr-@UnPack)]		;取得当前模块句柄
		mov	dword ptr [ebp+(hFileHandle-@UnPack)],eax
		lea	esi,dword ptr [ebp+(Ker32DllName-@UnPack)]
		push	esi
		call	dword ptr [ebp+(GetModuleAddr-@UnPack)]
		cmp	eax,0
		jnz	@Loaded
		push	esi
		call	dword ptr [ebp+(LoadlibraryAddr-@UnPack)]
	@Loaded:
		mov	esi,eax
		lea	ebx,[ebp+(Virtualfree-@UnPack)]
		push	ebx
		push	esi
		call	dword ptr [ebp+(GetProcAddr-@UnPack)]
		mov	dword ptr [ebp+(VirtualfreeAddr-@UnPack)],eax

		mov	ebx,S_PackSection-@UnPack
	@depackSection:
		cmp	dword ptr [ebp+ebx],0h		;比较节是否解压完毕
		jz	@allPacked
		push	ebx
		push	PAGE_READWRITE
		push	MEM_COMMIT
		push	dword ptr [ebp+ebx]
		push	0
		call	dword ptr [ebp+(VirtualAllocAddr-@UnPack)]
		mov	esi,eax
		pop	ebx
		mov	eax,ebx
		add	eax,ebp
		mov	edi,dword ptr [eax+04h]			;解压节区的RVA
		add	edi,dword ptr [ebp+(hFileHandle-@UnPack)]
		push	esi
		push	edi
		call	dword ptr [ebp+(aP_depackAddr-@UnPack)]
		mov	ecx,dword ptr [ebp+ebx]
		push	esi
		rep	movsb
		pop	esi
		push	ebx
		push	MEM_RELEASE
		push	0
		push	esi
		call	dword ptr [ebp+(VirtualfreeAddr-@UnPack)]
		pop	ebx
		add	ebx,0ch
		jmp	@depackSection

	@allPacked:
		;初始化源程序输入表
		mov	eax,dword ptr [ebp+(ImpTableAddr-@UnPack)]
		add	eax,dword ptr [ebp+(hFileHandle-@UnPack)]
		.while	dword ptr [eax+0ch]!=0
			push	eax
			mov	ebx,eax
			mov	esi,dword ptr [ebx+0ch]
			add	esi,dword ptr [ebp+(hFileHandle-@UnPack)];取得DLL名
			push	esi		
			call	dword ptr [ebp+(GetModuleAddr-@UnPack)]
			.if	eax==0
				push	esi
				call	dword ptr [ebp+(LoadlibraryAddr-@UnPack)]	;获得DLL句柄
			.endif
			mov	esi,eax
			mov	edx,dword ptr [ebx]
			.if	edx == 0
				mov	edx,dword ptr [ebx+10h]	
			.endif
			add	edx,dword ptr [ebp+(hFileHandle-@UnPack)]
			mov	edi,dword ptr [ebx+10h]
			add	edi,dword ptr [ebp+(hFileHandle-@UnPack)]	;edi指向IMAGE_THUNK_DATA
			.while	dword ptr [edx]!=0
				push	edx
				push	edi
				mov	eax,dword ptr [edx]
				cdq
				.if	edx == 0		;按序号导入	
					add	eax,2h
					add	eax,dword ptr [ebp+(hFileHandle-@UnPack)]
				.else
					and	eax,7fffffffh
				.endif
				push	eax
				push	esi
				call	dword ptr [ebp+(GetProcAddr-@UnPack)]
				mov	dword ptr [edi],eax
				pop	edi
				pop	edx
				add	edx,04h
				add	edi,04h
			.endw

			pop	eax
			add	eax,14h
		.endw
		mov	eax,dword ptr [ebp+(OEP-@UnPack)]
		add	eax,dword ptr [ebp+(hFileHandle-@UnPack)]
		jmp	eax


GetProcAddr		dd	0
GetModuleAddr		dd	0
LoadlibraryAddr		dd	0
VirtualAllocAddr	dd	0
hFileHandle		DD	0
ImpTableAddr		dd	0

OEP			DD	0
aP_depackAddr		DD	0
Ker32DllName		DB	'KERNEL32.dll',0
Virtualfree		DB	'VirtualFree',0
VirtualfreeAddr		DD	0
S_PackSection	DB	0a0h dup (?)
@UnPackEnd:	
