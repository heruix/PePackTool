;��γ���ο�mkfpack�е�������ƶ�
;;;;;��δѹ��������������ƶ��������ƶ�ԭ������������ܻᵼ�³����޷���������
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
	mov	pThunkData,eax        ;;;���NewImport��ƫ��
	mov	eax,NewImport-@DeCode
	add	eax,pShell0Buf
	add	pThunkData,eax	      ;;;;;;;NewImport��ʵ�ʵ�ַ
	;;;;;;;;����ԭ�������ƶ�
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
		.if	edx&80000000h      ;;;;���������
			
			;;;;;����IMAGE_THUNK_DATA
			mov	eax,pThunkData
			mov	DWORD PTR[eax],edx
			add	pThunkData,8      ;;;;������������dll��
		.else  ;;;����������
			;;;;;����IMAGE_THUNK_DATA
			mov	eax,pThunkData
			sub	eax,pShell0Buf
			add	eax,NotPackResDataSize
			add	eax,SizeOfImage
			add	eax,8
			mov	ebx,pThunkData
			mov	DWORD PTR[ebx],eax
			;;;;;�ƶ�API�����ַ���
			add	edx,2      ;;;��IMAGE_IMPORT_BY_NAME�ṹ�е�NAME
			add	edx,MapOfFile
			push	esi
			mov	esi,edx
			mov	edi,pThunkData
			add	edi,10       ;;;;ָ��IMAGE_IMPORT_BY_NAME�ṹ�е�NAME
			xor	ecx,ecx
			.while	byte ptr[esi]!=0
				movsb
				inc	ecx	
			.endw
			mov	BYTE PTR[edi],0
			inc	ecx  ;;;;���ַ����ĳ���
			add	ecx,10
			add	pThunkData,ecx      ;;;;;;;;;;;���汣��DLL��
			pop	esi
				
		.endif
		;;;;;;;;;�ƶ�DLL��
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