
; ��������
_FileAlignment	proc	AligSize:dword,AligValue:dword
				; AligSizeҪ����ĵ�ַ����AligValueֵ���ж���
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

;���ļ�����ѹ��
BegainPackFile	proc	hFile
		local	@lpResourceBase:dword
		local	@dwBytesRead:dword
		local	@MEMSize:dword,@lpMEM:dword
		pushad
		mov	dwCurrentSize,0
		mov	esi,lpPEHeader
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	eax,dword ptr [esi].OptionalHeader.DataDirectory[2*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
		mov	@lpResourceBase,eax	; ��Դ����ַ
		mov	edi,lpSectionTableBase	; �ڱ����ַ
		mov	ebx,dword ptr [edi+14h]	; ��һ�������ļ��е�ƫ�ƣ�
		mov	dwPEheadSize,ebx
		add	dwCurrentSize,ebx
		invoke	WriteFile,hFile,lpMapFile,dwPEheadSize,addr @dwBytesRead,NULL
		movzx	ecx,word ptr [esi].FileHeader.NumberOfSections
		mov	esi,offset PackSection		; �������ѹ��ǰ������

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
; *****************�Խڽ���ѹ��*******************************
		mov	eax,[edi+08h]		; �ý�װ���ڴ��Ĵ�С
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
		;ebx=ѹ�����ݵĵ�ַ��[edi+08h]=δѹ�����ݵĴ�С
		invoke	aP_pack,ebx,@lpMEM,dword ptr[edi+08h],lpPackBuffer,0
		invoke	_FileAlignment,eax,FileAlignment
		push	eax
		mov	eax,dword ptr [edi+08h]
		mov	dword ptr [esi],eax		; ����ڵ�ԭʼ��С
		mov	eax,dword ptr [edi+0ch]
		mov	dword ptr [esi+4h],eax		; ���������RVA
		pop	ebx
		mov	dword ptr [esi+08h],ebx		; ����ѹ����Ĵ�С
		add	esi,0ch
		mov	dword ptr [edi+10h],ebx		;;���ļ��ж����ĳߴ�
		mov	eax,dwCurrentSize
		mov	dword ptr[edi+14h],eax		;���ļ��е�ƫ��
		add	dwCurrentSize,ebx
		invoke	WriteFile,hFile,@lpMEM,ebx,addr @dwBytesRead,NULL
		invoke	VirtualFree, @lpMEM, 0, MEM_RELEASE
		pop	ecx
		jmp	next
		
;ѹ����Դ		
PackResSection:	
		mov	eax,PackResource	
		cmp	eax,0
		jz	NotPack
		push	ecx
		mov	eax,ResDataAddr
		sub	eax,[edi+0ch]		;��ȥ�ڻ���ַ�õ���ѹ����Դ�Ĵ�С
		mov	ecx,eax
		mov	ebx,[edi+0ch]
		add	ebx,lpMapFile			;д����Դ�β���ѹ���Ĳ���
		invoke	WriteFile,hFile,ebx,ecx,addr @dwBytesRead,NULL
		
		;����Դѹ��
		;invoke	_FileAlignment,eax,FileAlignment
		mov	eax,[edi+08h]		; ��Դ�εĴ�С
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
		sub	ebx,eax				;Ҫѹ������Դ�����ݵĴ�С
		push	ebx
		mov	eax,ResDataAddr			
		add	eax,lpMapFile
		invoke	aP_pack,eax,@lpMEM,ebx,lpPackBuffer,0
		pop	ebx
		;���������Ա���ѹ��
		mov	dword ptr [esi],ebx		;ԭʼ��С
		mov	ebx,ResDataAddr
		mov	dword ptr [esi+4],ebx		;��ԭ����ʼ��ַ	
		mov	dword ptr [esi+8],eax		;ѹ����Ĵ�С
		add	esi,0ch
		
		mov	ecx,dwCurrentSize
		mov	dword ptr [edi+14h],ecx
		sub	eax,dword ptr [edi+0ch]		;û��ѹ����Դ�Ĵ�С
		add	eax,ebx				;ѹ������Դ���ܴ�С
		invoke	_FileAlignment,eax,FileAlignment
		mov	dword ptr [edi+10h],eax		;ѹ������Դ�ڶ����ĳ���
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
		mov	ebx,dword ptr [edi+0ch]		; ������RVA
		add	ebx,lpMapFile
		mov	edx,dwCurrentSize
		mov	dword ptr [edi+14h],edx		;;���ļ��е�ƫ��
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