
; 对齐数据
_FileAlignment	proc	AligSize:dword,AligValue:dword
				; AligSize要对齐的地址，按AligValue值进行对齐
		push	ecx
		push	edx
		mov	eax,AligSize
		xor	edx,edx
		div	AligValue
		.if edx != 0
			xor	edx,edx
			inc	eax
		.endif
		mul	AligValue	
		pop	edx
		pop	ecx
		ret
_FileAlignment	endp

;对文件进行压缩
BegainPackFile	proc	hFile
		local	@lpResourceBase:dword
		local	@dwBytesRead:dword
		local	@MEMSize:dword,@lpMEM:dword
		pushad
		mov	dwCurrentSize,0
		mov	esi,lpPEHeader
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	eax,dword ptr [esi].OptionalHeader.DataDirectory[2*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
		mov	@lpResourceBase,eax	; 资源基地址
		mov	edi,lpSectionTableBase	; 节表基地址
		mov	ebx,dword ptr [edi+14h]	; 第一个节在文件中的偏移，
		mov	dwPEheadSize,ebx
		add	dwCurrentSize,ebx
		invoke	WriteFile,hFile,lpMapFile,dwPEheadSize,addr @dwBytesRead,NULL
		movzx	ecx,word ptr [esi].FileHeader.NumberOfSections
		mov	esi,offset PackSection		; 保存各节压缩前的属性

WriteSection:			
		test	ecx,ecx
		jz	Allpacked

		cmp	dword ptr [edi], 'adr.'
		jz	NotPack
		cmp	dword ptr [edi], 'ade.'
		jz	NotPack
		cmp	dword ptr [edi], 'rsr.'
		jz	PackResSection
		cmp	dword ptr [edi], 'oci.'
		jz	NotPack
		cmp	dword ptr [edi+10h], 0
		jz	NotPack
; *****************对节进行压缩*******************************
		mov	eax,[edi+08h]		; 该节装入内存后的大小
		xor	edx,edx
		mov	edx,9
		mul	edx
		shr	eax,3
		add	eax,16
		mov	@MEMSize,eax
		push	ecx
		invoke	VirtualAlloc, NULL, eax, MEM_COMMIT, PAGE_READWRITE
		mov	@lpMEM,eax
		mov	ebx,[edi+0ch]
		add	ebx,lpMapFile
		;ebx=压缩数据的地址，[edi+08h]=未压缩数据的大小
		invoke	aP_pack,ebx,@lpMEM,dword ptr[edi+08h],lpPackBuffer,0
		invoke	_FileAlignment,eax,FileAlignment
		push	eax
		mov	eax,dword ptr [edi+08h]
		mov	dword ptr [esi],eax		; 保存节的原始大小
		mov	eax,dword ptr [edi+0ch]
		mov	dword ptr [esi+4h],eax		; 保存节区的RVA
		pop	ebx
		mov	dword ptr [esi+08h],ebx		; 保存压缩后的大小
		add	esi,0ch
		mov	dword ptr [edi+10h],ebx		;;在文件中对齐后的尺寸
		mov	eax,dwCurrentSize
		mov	dword ptr[edi+14h],eax		;在文件中的偏移
		add	dwCurrentSize,ebx
		invoke	WriteFile,hFile,@lpMEM,ebx,addr @dwBytesRead,NULL
		invoke	VirtualFree, @lpMEM, 0, MEM_RELEASE
		pop	ecx
		jmp	next
		
;压缩资源		
PackResSection:	
		mov	eax,PackResource	
		cmp	eax,0
		jz	NotPack
		push	ecx
		mov	eax,ResDataAddr
		sub	eax,[edi+0ch]		;减去节基地址得到不压缩资源的大小
		mov	ecx,eax
		mov	ebx,[edi+0ch]
		add	ebx,lpMapFile			;写入资源段不被压缩的部分
		invoke	WriteFile,hFile,ebx,ecx,addr @dwBytesRead,NULL
		
		;对资源压缩
		;invoke	_FileAlignment,eax,FileAlignment
		mov	eax,[edi+08h]		; 资源段的大小
		xor	edx,edx
		mov	edx,9
		mul	edx
		shr	eax,3
		add	eax,16
		mov	@MEMSize,eax
		invoke	VirtualAlloc, NULL, eax, MEM_COMMIT, PAGE_READWRITE
		.if !eax		
			invoke	MessageBox,NULL,addr szAllocNoSuccess,NULL,MB_OK
		.endif
		mov	@lpMEM,eax
		mov	eax,ResDataAddr
		sub	eax,dword ptr [edi+0ch]		
		mov	ebx,dword ptr [edi+08h]		
		sub	ebx,eax				;要压缩的资源的数据的大小
		push	ebx
		mov	eax,ResDataAddr			
		add	eax,lpMapFile
		invoke	aP_pack,eax,@lpMEM,ebx,lpPackBuffer,0
		pop	ebx
		;保存数据以备解压缩
		mov	dword ptr [esi],ebx		;原始大小
		mov	ebx,ResDataAddr
		mov	dword ptr [esi+4],ebx		;还原的起始地址	
		mov	dword ptr [esi+8],eax		;压缩后的大小
		add	esi,0ch
		
		mov	ecx,dwCurrentSize
		mov	dword ptr [edi+14h],ecx
		sub	eax,dword ptr [edi+0ch]		;没被压缩资源的大小
		add	eax,ebx				;压缩后资源的总大小
		invoke	_FileAlignment,eax,FileAlignment
		mov	dword ptr [edi+10h],eax		;压缩后资源节对齐后的长度
		add	dwCurrentSize,eax
		mov	ebx,ResDataAddr
		sub	ebx,dword ptr [edi+0ch]
		sub	eax,ebx
		mov	ebx,eax
		invoke	WriteFile,hFile,@lpMEM,ebx,addr @dwBytesRead,NULL
		invoke	VirtualFree, @lpMEM, 0, MEM_RELEASE
		pop	ecx
		jmp	next
		
NotPack:
		push	ecx
		mov	ebx,dword ptr [edi+0ch]		; 节区的RVA
		add	ebx,lpMapFile
		mov	edx,dwCurrentSize
		mov	dword ptr [edi+14h],edx		;;在文件中的偏移
		mov	eax,dword ptr [edi+10h]
		invoke	_FileAlignment,eax,FileAlignment
		add	dwCurrentSize,eax
		mov	ecx,eax
		invoke	WriteFile,hFile,ebx,ecx,addr @dwBytesRead,NULL
		pop	ecx
next:
		add	edi,28h
		dec	ecx
		jmp	WriteSection
Allpacked:
		invoke MessageBox,0,OFFSET szPackSuc,0,MB_OK
		popad
		ret
BegainPackFile	endp