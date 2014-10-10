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
		mov	ecx,@UnPackEnd-@UnPack			;shell�ĳ���
		mov	@UnPackShellSize,ecx
		lea	esi,@UnPack				;shell����ʼ��ַ
		mov	edi,@lpMapShell
		rep	movsb
 		;����OEP
		mov	ebx,@lpMapShell	
		add	ebx,OEP-@UnPack
		mov	esi,lpPEHeader
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	eax,dword ptr [esi].OptionalHeader.AddressOfEntryPoint
		mov	dword ptr [ebx],eax
		;����������ַ
		mov	eax,dword ptr [esi].OptionalHeader.DataDirectory[SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
		mov	ebx,@lpMapShell
		add	ebx,ImpTableAddr-@UnPack
		mov	dword ptr [ebx],eax

		;����ѹ���ڱ���Ϣ
		lea	esi,PackSection
		mov	ecx,0a0h
		mov	edi,@lpMapShell
		add	edi,S_PackSection-@UnPack
		rep	movsb

		;����Ǵ������ѹ��
		mov	eax,@UnPackShellSize
		mov	edx, 9
		mul	edx
		shr	eax,3
		add	eax,16
		mov	@Memsize,eax
		invoke	VirtualAlloc, NULL, eax, MEM_COMMIT, PAGE_READWRITE
		mov	@lpMEM,eax
		invoke	aP_pack,@lpMapShell,@lpMEM,@UnPackShellSize,lpPackBuffer,0
		mov	@ShellPackedBuffer,eax			;ѹ����Ĵ�С
		;д�������������
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
		;д��ѹ��������
		mov	ecx,@ShellPackedBuffer
		add	@ShellSize,ecx
		mov	esi,@lpMEM
		rep	movsb
		;������������
		mov	eax,dwImageSize	
		add	eax,ImportTable-@DeCode
		mov	ebx,lpShellMap			;�����ƫ��(RVA)	
		add	ebx,ImportTable-@DeCode
		add	dword ptr [ebx],eax
		mov	ebx,lpShellMap
		add	ebx,libname-@DeCode			;dll��RVA
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

		;�ļ�ͷ����һ���ڱ�����
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
		mov	eax,dword ptr [esi-14h]		;ǰһ�����ļ��е�ƫ��
		add	eax,dword ptr [esi-18h]		;ǰһ�����ļ��еĴ�С
		invoke	_FileAlignment,eax,FileAlignment
		mov	dword ptr [esi+14h],eax
		mov	dword ptr [esi+24h],0c0000040h
		inc	word ptr [edi].FileHeader.NumberOfSections	;��������һ
		;�޸��ļ�ͷ
		mov	eax,dwImageSize
		mov	dword ptr [edi].OptionalHeader.AddressOfEntryPoint,eax	;�޸�EntryPoint
		invoke	_FileAlignment,@ShellSize,SectionAlignment
		add	eax,dwImageSize 
		mov	dword ptr [edi].OptionalHeader.SizeOfImage,eax	;�޸�ӳ���С
		;�޸������
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
				;�ֲ߳̾��洢
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
		ret		;������Ǵ����С
WriteShell	endp