;这段程序参考mkfpack中的输入表移动
;;;;;对未压缩程序的输入表的移动，若不移动原程序的输入表可能会导致程序无法正常运行
MoveImport	proc pOldImport:DWORD,pNewImport:DWORD,pShell0Buf:DWORD
	LOCAL	pThunkData:DWORD
	pushad
	mov	esi,pOldImport
	assume	esi: ptr IMAGE_IMPORT_DESCRIPTOR
	xor	ecx,ecx
	push	esi
	.while [esi].Name1!=0
		inc	ecx
		add	esi,20
	.endw
	pop	esi
	inc	ecx
	mov	eax,20
	mul	ecx
	mov	pThunkData,eax        ;;;相对NewImport的偏移
	mov	eax,NewImport-@DeCode
	add	eax,pShell0Buf
	add	pThunkData,eax	      ;;;;;;;NewImport的实际地址
	;;;;;;;;进行原导入表的移动
	.while	[esi].Name1!=0
		invoke	RtlMoveMemory,pNewImport,esi,20
		mov	ebx,pNewImport
		mov	[ebx+IMAGE_IMPORT_DESCRIPTOR.OriginalFirstThunk],0
		mov	eax,pThunkData
		sub	eax,pShell0Buf
		add	eax,NotPackResDataSize
		add	eax,SizeOfImage
		mov	[ebx+IMAGE_IMPORT_DESCRIPTOR.FirstThunk],eax
		
		.if 	[esi].OriginalFirstThunk==0
			push	[esi].FirstThunk
			pop	[esi].OriginalFirstThunk
		.endif

		mov	ebx,[esi].OriginalFirstThunk
		add	ebx,MapOfFile
		mov	edx,DWORD PTR[ebx]
		.if	edx&80000000h      ;;;;以序号输入
			
			;;;;;设置IMAGE_THUNK_DATA
			mov	eax,pThunkData
			mov	DWORD PTR[eax],edx
			add	pThunkData,8      ;;;;后面用来保存dll名
		.else  ;;;以名字输入
			;;;;;设置IMAGE_THUNK_DATA
			mov	eax,pThunkData
			sub	eax,pShell0Buf
			add	eax,NotPackResDataSize
			add	eax,SizeOfImage
			add	eax,8
			mov	ebx,pThunkData
			mov	DWORD PTR[ebx],eax
			;;;;;移动API函数字符串
			add	edx,2      ;;;向IMAGE_IMPORT_BY_NAME结构中的NAME
			add	edx,MapOfFile
			push	esi
			mov	esi,edx
			mov	edi,pThunkData
			add	edi,10       ;;;;指向IMAGE_IMPORT_BY_NAME结构中的NAME
			xor	ecx,ecx
			.while	byte ptr[esi]!=0
				movsb
				inc	ecx	
			.endw
			mov	BYTE PTR[edi],0
			inc	ecx  ;;;;得字符串的长度
			add	ecx,10
			add	pThunkData,ecx      ;;;;;;;;;;;后面保存DLL名
			pop	esi
				
		.endif
		;;;;;;;;;移动DLL名
		mov	ebx,pNewImport
		mov	eax,pThunkData
		sub	eax,pShell0Buf
		add	eax,NotPackResDataSize
		add	eax,SizeOfImage
		mov	[ebx+IMAGE_IMPORT_DESCRIPTOR.Name1],eax		
		push	esi
		mov	esi,[esi].Name1
		add	esi,MapOfFile
		mov	edi,pThunkData
		xor	ecx,ecx
		.while	BYTE PTR[esi]!=0
			movsb
			inc	ecx
		.endw
		mov	BYTE PTR[edi],0
		inc	ecx
		add	pThunkData,ecx
		pop	esi
		add	esi,20
		add	pNewImport,20
		
	.endw
	
	
	
	popad
	ret

MoveImport endp