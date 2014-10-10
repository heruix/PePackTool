WriteShell	proc
		local	@lpMapShell:dword
		local	@UnPackShellSize:dword
		local	@PackedShellSize:dword
		local	@Memsize:dword,@lpMEM:dword
		local	@ShellPackedBuffer:dword
		local	@ShellSize:dword
		pushad
		invoke	VirtualAlloc,NULL,20000h,MEM_COMMIT,PAGE_READWRITE
		mov	@lpMapShell,eax
		mov	ecx,@UnPackEnd-@UnPack			;shell的长度
		mov	@UnPackShellSize,ecx
		lea	esi,@UnPack				;shell的起始地址
		mov	edi,@lpMapShell
		rep	movsb
 		;保存OEP
		mov	ebx,@lpMapShell	
		add	ebx,OEP-@UnPack
		mov	esi,lpPEHeader
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	eax,dword ptr [esi].OptionalHeader.AddressOfEntryPoint
		mov	dword ptr [ebx],eax
		;保存输入表地址
		mov	eax,dword ptr [esi].OptionalHeader.DataDirectory[SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
		mov	ebx,@lpMapShell
		add	ebx,ImpTableAddr-@UnPack
		mov	dword ptr [ebx],eax

		;保存压缩节表信息
		lea	esi,PackSection
		mov	ecx,0a0h
		mov	edi,@lpMapShell
		add	edi,S_PackSection-@UnPack
		rep	movsb

		;对外壳代码进行压缩
		mov	eax,@UnPackShellSize
		mov	edx, 9
		mul	edx
		shr	eax,3
		add	eax,16
		mov	@Memsize,eax
		invoke	VirtualAlloc, NULL, eax, MEM_COMMIT, PAGE_READWRITE
		mov	@lpMEM,eax
		invoke	aP_pack,@lpMapShell,@lpMEM,@UnPackShellSize,lpPackBuffer,0
		mov	@ShellPackedBuffer,eax			;压缩后的大小
		;写入外壳引导部分
		mov	ecx,@DeCodeEnd-@DeCode
		mov	@ShellSize,ecx
		mov	edi,lpShellMap
		lea	esi,@DeCode
		rep	movsb
		.if	PackResource == 1
			mov	ecx,dwMovedRes
			add	@ShellSize,ecx
			mov	esi,lpMapResDataAddr
			rep	movsb
		.endif
		;写入压缩后的外壳
		mov	ecx,@ShellPackedBuffer
		add	@ShellSize,ecx
		mov	esi,@lpMEM
		rep	movsb
		;处理外壳输入表
		mov	eax,dwImageSize	
		add	eax,ImportTable-@DeCode
		mov	ebx,lpShellMap			;输入表偏移(RVA)	
		add	ebx,ImportTable-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,libname-@DeCode			;dll名RVA
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,FirstThunk-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,THUNK_DATA1-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,THUNK_DATA2-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,THUNK_DATA3-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,THUNK_DATA4-@DeCode
		add	dword ptr [ebx],eax

		mov	ebx,lpShellMap
		add	ebx,ShellBase-@DeCode
		mov	eax,@DeCodeEnd-@DeCode
			.if PackResource == 1
				add	eax,dwMovedRes
			.endif
		mov	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,ShellPackSize-@DeCode
		mov	eax,@UnPackShellSize
		mov	dword ptr [ebx],eax

		;文件头增加一个节表资料
		mov	edi,lpPEHeader
		assume	edi : ptr IMAGE_NT_HEADERS
		mov	eax,lpSectionTableBase
		movzx	ecx,word ptr [edi].FileHeader.NumberOfSections
@ModSecCharact:
		or	dword ptr [eax+24h],0c0000000h
		add	eax,28h
		loop	@ModSecCharact
		mov	esi,eax
		push	edi
		mov	edi,esi
		xor	eax,eax
		mov	ecx,28h
		rep	stosb
		pop	edi
		mov	dword ptr [esi],'ekp.'
		invoke	_FileAlignment,@ShellSize,SectionAlignment
		mov	dword ptr [esi+08h],eax
		mov	eax,dwImageSize
		mov	dword ptr [esi+0ch],eax
		invoke	_FileAlignment,@ShellSize,FileAlignment
		mov	dword ptr [esi+10h],eax
		mov	eax,dword ptr [esi-14h]		;前一节在文件中的偏移
		add	eax,dword ptr [esi-18h]		;前一节在文件中的大小
		invoke	_FileAlignment,eax,FileAlignment
		mov	dword ptr [esi+14h],eax
		mov	dword ptr [esi+24h],0c0000040h
		inc	word ptr [edi].FileHeader.NumberOfSections	;节数增加一
		;修改文件头
		mov	eax,dwImageSize
		mov	dword ptr [edi].OptionalHeader.AddressOfEntryPoint,eax	;修改EntryPoint
		invoke	_FileAlignment,@ShellSize,SectionAlignment
		add	eax,dwImageSize 
		mov	dword ptr [edi].OptionalHeader.SizeOfImage,eax	;修改映象大小
		;修改输入表
		mov	eax,dwImageSize
		add	eax,ImportTable-@DeCode
		mov	dword ptr [edi].OptionalHeader.DataDirectory[SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress,eax
		mov	dword ptr [edi].OptionalHeader.DataDirectory[5*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress,0h
		mov	dword ptr [edi].OptionalHeader.DataDirectory[5*SIZEOF IMAGE_DATA_DIRECTORY].isize,0h
		mov	dword ptr [edi].OptionalHeader.DataDirectory[11*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress,0h
		mov	dword ptr [edi].OptionalHeader.DataDirectory[11*SIZEOF IMAGE_DATA_DIRECTORY].isize,0h
		mov	dword ptr [edi].OptionalHeader.DataDirectory[12*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress,0h
		mov	dword ptr [edi].OptionalHeader.DataDirectory[12*SIZEOF IMAGE_DATA_DIRECTORY].isize,0h
		mov	esi,dword ptr [edi].OptionalHeader.DataDirectory[9*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
				;线程局部存储
			.if esi !=0
				add	esi,lpMapFile
				mov	eax,dwImageSize
				add	eax,TlsTable-@DeCode
				mov	dword ptr [edi].OptionalHeader.DataDirectory[9*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress,eax
				mov	edi,lpMapFile
				add	edi,TlsTable-@DeCode
				mov	ecx,18h
				rep	movsb
			.endif
		invoke	VirtualFree, @lpMapShell, 0, MEM_RELEASE
		popad
		invoke	_FileAlignment,@ShellSize,SectionAlignment
		ret		;返回外壳代码大小
WriteShell	endp