;��Ҫѹ�����ļ����������ļ�
CreateBakFile	PROC	lpSourceFileName:DWORD

  local	@lpBakFileName:DWORD
	push	edi
	push	esi
	invoke	VirtualAlloc, NULL, 1000h, MEM_COMMIT, PAGE_READWRITE
	mov	@lpBakFileName,eax
	mov	edi,eax
	mov	esi,lpSourceFileName
	xor	eax,eax
MoveNextByte:
	lodsb
	.if	eax!=0
		stosb
	.else
		jmp	AllByteMoved
	.endif
	xor	eax,eax
	jmp	MoveNextByte
AllByteMoved:
	mov	dword ptr [edi],'kab.'				;��ԭ�ļ����Ӻ�׺.bak
	invoke	CopyFile, lpSourceFileName , @lpBakFileName ,0		;����Դ�ļ����б���
	push	eax
	invoke	VirtualFree, @lpBakFileName, 0, MEM_RELEASE
	pop	eax
	pop	esi
	pop	edi
	ret
CreateBakFile	endp





; �ҵ���Դ���ݵ�ַ
; �ο���ѩ�����������ܼ�����Ļ����Դ�Ĵ���
FindResData	proc
		local	@ResDataAddr:dword,@buf[5]:byte
		push	edi
		push	esi
		push	ecx
		mov	@ResDataAddr,7fffffffh
		mov	esi,lpPEHeader
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	eax,dword ptr [esi].OptionalHeader.DataDirectory[2*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
		mov	esi,eax
		add	eax,lpMapFile
		mov	edi,eax		;��Դ�ε�ַ
		xor	ecx,ecx
		mov	cx,word ptr [edi+0ch]
		add	cx,word ptr [edi+0eh]
		add	edi,sizeof IMAGE_RESOURCE_DIRECTORY
			.while ecx > 0
			push	edi
			push	ecx
			mov	edi,dword ptr [edi+4h]		;ediָ��OffsetToData
			and	edi,7fffffffh			;�������Դ����ƫ��
			add	edi,esi
			add	edi,lpMapFile
			xor	ecx,ecx
			mov	cx,word ptr [edi+0ch]
			add	cx,word ptr [edi+0eh]
			add	edi,10h			;sizeof IMAGE_RESOURCE_DIRECTORY
				.while	ecx > 0
				push	edi
				push	ecx
				mov	edi,dword ptr [edi+4h]		;ediָ��OffsetToData
				and	edi,7fffffffh
				add	edi,esi
				add	edi,lpMapFile
				add	edi,10h	
				mov	edi,dword ptr [edi+4h]
				add	edi,esi
				add	edi,lpMapFile
				mov	eax,dword ptr [edi]

					.if eax > esi
						.if eax < @ResDataAddr
							mov	@ResDataAddr,eax

						.endif
					.endif
				pop	ecx
				pop	edi
				dec	ecx
				add	edi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
				.endw
			pop	ecx
			pop	edi
			dec	ecx
			add	edi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
			.endw
		pop	ecx
		pop	esi
		pop	edi
		mov	eax,@ResDataAddr
		;;;invoke	wsprintf,addr @buf,offset szFmtHex1,eax
		;;;invoke	MessageBox,NULL,addr @buf,NULL,MB_OK
		ret
FindResData	endp

; �ƶ��ض����͵���Դ����Щ��Դ����ѹ��
; �ο���ѩ�����������ܼ�����Ļ����Դ�Ĵ���
MoveResource		PROC	ResType:DWORD,lpMoveRes:DWORD,dwMoveResSize:DWORD
  local	@lpResourceBase:DWORD
	pushad
	mov	edx,lpPEHeader
	assume	edx : ptr IMAGE_NT_HEADERS
	mov	edx,dword ptr [edx].OptionalHeader.DataDirectory[2*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
	add	edx,lpMapFile		;��Դ��ַ
	mov	@lpResourceBase,edx
	xor	ecx,ecx
	mov	cx,word ptr [edx+0ch]		
	add	cx,word ptr [edx+0eh]
	add	edx,sizeof IMAGE_RESOURCE_DIRECTORY
		.while ecx > 0
			mov	eax,dword ptr [edx]		; ָ��name
			.if	eax==ResType			; �ҵ���Ӧ���͵���Դ
				jmp	FoundResDir		; IDΪ3��ʾ��ICON��Դ��14��ʾGROUP ICON��16��ʾVERSION INFORMATION
			.elseif
			add	edx,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
			.endif
			dec	ecx
		.endw
	jmp	NotFoundResDir
    FoundResDir:
	mov	edx,dword ptr [edx+4h]			;
	and	edx,7fffffffh				; ��Դ��ƫ��ָ��OffsetToData
	add	edx,@lpResourceBase			; ��Դ�ĵڶ���Ŀ¼
	xor	ecx,ecx 
	mov	cx,word ptr [edx+0ch]
	add	cx,word ptr [edx+0eh]
	add	edx,sizeof IMAGE_RESOURCE_DIRECTORY
		.while ecx > 0
			mov	ebx,dword ptr [edx+4h]			; ָ��OffsetToData
			and	ebx,7fffffffh				; ��Դ��ĵ�ƫ��
			add	ebx,@lpResourceBase			; ����ĵ�ַ��������Ŀ¼
			add	ebx,sizeof IMAGE_RESOURCE_DIRECTORY
			mov	ebx,dword ptr [ebx+4h]			; ָ��OffsetToData
			add	ebx,@lpResourceBase			; ָ��ڵ㣬��Դ����ָ��
			push	ecx
			mov	ecx,dword ptr [ebx+4h]			; �ƶ���Դ�Ĵ�С
			mov	esi,dword ptr [ebx]			; ��Դ����ָ��==esi,ָ����Դ����ƫ�ƣ�rva
			add	esi,lpMapFile				; ��Դ���ݵĵ�ַ
			mov	eax,dwImageSize				;
			add	eax,@DeCodeEnd-@DeCode       
			add	eax,dwMoveResSize			; eax==ӳ���ļ���С+���+�ƶ���Դ��С
			mov	dword ptr [ebx],eax			; ebxָ����ԴҪ�ƶ����ĵ�ַ,�޸���Դ����ָ��
			mov	edi,lpMoveRes 
			add	edi,dwMoveResSize
			add	dwMoveResSize,ecx
			push	esi
			push	ecx
			rep	movsb
			pop	ecx
			pop	edi
			xor	eax,eax
			rep	stosb
			pop	ecx
			add	edx,IMAGE_RESOURCE_DIRECTORY_ENTRY
			dec	ecx
		.endw
    NotFoundResDir:
	popad
	mov	eax,dwMoveResSize
	ret
MoveResource		endp


; ѹ���ļ�����
PackFile	proc	hWnd
		local @hFile
		local @szbuffer:dword
		local @dwBytesRead:dword
		local @PEHeaherRVA
		local @tempbuf[64]:byte
		pushad
		.if CreateBak == 1
			invoke	CreateBakFile,ADDR szFileName
				.if	eax!=0
				invoke	MessageBox,hWnd,addr szCreatSuccess,NULL,MB_OK
				.else
				invoke	MessageBox,hWnd,addr szCreatNoSuccess,NULL,MB_OK
				.endif
		.endif
		invoke CreateFile,offset szFileName,GENERIC_READ+GENERIC_WRITE,FILE_SHARE_READ+FILE_SHARE_WRITE,NULL,OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,NULL
		.if eax != INVALID_HANDLE_VALUE
			mov	@hFile,eax
			mov	@szbuffer,0
			invoke  SetFilePointer, @hFile, 3ch, NULL,  FILE_BEGIN
			invoke	ReadFile,@hFile,addr @szbuffer,4,addr @dwBytesRead,NULL
			mov	eax,@szbuffer
			mov	esi,eax			; esi=PEheaderƫ�Ƶ�ַ
			
			add	eax,50h			; eaxָ��sizeofimage��ӳ���ļ���С
			invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
			invoke	ReadFile,@hFile,addr dwImageSize,4,addr @dwBytesRead,NULL
			invoke	VirtualAlloc, NULL, dwImageSize, MEM_COMMIT, PAGE_READWRITE   ; �����ڴ�
			.if eax
				mov	lpMapFile,eax
				invoke	MessageBox,hWnd,addr szAllocSuccess,NULL,MB_OK
				mov	eax,esi
				add	eax,54h			; ָ��SizeOfHeaders ������ͷ+�ڱ��С
				invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
				mov	@szbuffer,0
				invoke	ReadFile,@hFile,addr @szbuffer,4,addr @dwBytesRead,NULL
				invoke	SetFilePointer, @hFile, 0, NULL,  FILE_BEGIN
				; PE�ļ�ͷ���������ڴ�
				invoke	ReadFile,@hFile,lpMapFile,@szbuffer,addr @dwBytesRead,NULL
				mov	eax,lpMapFile
				add	eax,esi
				mov	lpPEHeader,eax
				mov	edi,lpPEHeader
				assume	edi:ptr IMAGE_NT_HEADERS
				mov	eax,dword ptr [edi].OptionalHeader.ImageBase
				mov	lpImageBase,eax			; ȡ���ļ�װ�����ַ
				mov	eax,dword ptr [edi].OptionalHeader.FileAlignment
				mov	FileAlignment,eax
					.if	IsFileAlignment == 1
						mov	FileAlignment,200h
						mov	dword ptr [edi].OptionalHeader.FileAlignment,200h
					.endif
				mov	eax,dword ptr [edi].OptionalHeader.SectionAlignment
				mov	SectionAlignment,eax	
				movzx	ecx,word ptr [edi].FileHeader.NumberOfSections
				movzx	esi,word ptr [edi].FileHeader.SizeOfOptionalHeader  ; 
				add	esi,edi
				add	esi,18h
				mov	lpSectionTableBase,esi		; esiָ��ڱ����ַ
	LoadSections:							; ѭ������ÿ����
				push	ecx
				mov	eax,dword ptr [esi+14h]		; ָ��PointerToRawData�����ڴ����ļ��е�ƫ��
				invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
				mov	ecx,dword ptr [esi+0ch]		; ָ���ڱ�װ�ص��ڴ��к��ƫ�Ƶ�ַ��rva��
				add	ecx,lpMapFile
				mov	ebx,dword ptr [esi+10h]		; �ڱ��ļ���С
				invoke	ReadFile, @hFile, ecx, ebx, addr @dwBytesRead, NULL
				mov	ebx,dword ptr [esi+08h]		; ��û�н��ж��봦��ǰ��ʵ�ʴ�С
				invoke	_FileAlignment,ebx,SectionAlignment
				mov	dword ptr [esi+08h],eax
				add	esi,28h
				pop	ecx
				loop	LoadSections
							; �ڶ������
				invoke	MessageBox,hWnd,addr szReadSuccess,NULL,MB_OK
				invoke	_FileAlignment,dwImageSize,SectionAlignment
				mov	dwImageSize,eax
				mov	dword ptr [edi].OptionalHeader.SizeOfImage,eax     ; ������ļ���С
				invoke	CloseHandle,@hFile
				.if PackResource == 1
					invoke	FindResData
					mov	ResDataAddr,eax
					;===================����======================
					;invoke	wsprintf,addr @tempbuf,addr szFmtHex1,eax
					;invoke	MessageBox,NULL,addr @tempbuf,NULL,MB_OK
	
					invoke	VirtualAlloc, NULL, 50000h, MEM_COMMIT, PAGE_READWRITE
					.if eax == 0
						jmp	AllocNo
					.endif
					;invoke	MessageBox,hWnd,addr szbeginMoveRes,NULL,MB_OK
					mov	lpMapResDataAddr,eax
					mov	dwMovedRes,0
					invoke	MoveResource,03h,lpMapResDataAddr,dwMovedRes
					mov	dwMovedRes,eax

					invoke	MoveResource,0eh,lpMapResDataAddr,dwMovedRes
					mov	dwMovedRes,eax

					invoke	MoveResource,10h,lpMapResDataAddr,dwMovedRes
					mov	dwMovedRes,eax

					invoke	MoveResource,18h,lpMapResDataAddr,dwMovedRes
					mov	dwMovedRes,eax
					;===================����======================
					;invoke	wsprintf,addr @tempbuf,addr szFmtHex1,eax
					;invoke	MessageBox,NULL,addr @tempbuf,NULL,MB_OK

					invoke	MessageBox,0,OFFSET szMoveResSuc,0,MB_OK
				.endif
				; +++++++++++++++��ʼѹ���ļ�++++++++++++++++++
				invoke	VirtualAlloc, NULL, 100000h, MEM_COMMIT, PAGE_READWRITE
				.if eax == 0
					jmp	AllocNo
				.endif
				mov	lpPackBuffer,eax
				invoke	CreateFile,offset szSaveFileName, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE,0,OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL,NULL
				mov	@hFile,eax
				invoke	BegainPackFile,@hFile

				;������Ǵ���
				invoke	VirtualAlloc, NULL, 100000h, MEM_COMMIT, PAGE_READWRITE
					.if eax == 0
						jmp	AllocNo
					.endif
				mov	lpShellMap,eax
				invoke	WriteShell
				mov	dwMapOfShell,eax
				push	eax
				mov	ebx,esp
				invoke	WriteFile,@hFile,lpShellMap,dwMapOfShell,ebx,NULL
				invoke	SetEndOfFile,@hFile
				;invoke	GetLastError
				;invoke	wsprintf,addr @tempbuf,addr szFmtHex1,eax
				;invoke	MessageBox,NULL,addr @tempbuf,NULL,MB_OK
				pop	eax
				;д��peͷ��
				mov	esi,lpPEHeader
				assume esi  : ptr IMAGE_NT_HEADERS
				invoke  SetFilePointer, @hFile, 0h, NULL,  FILE_BEGIN
				mov	ebx,dwPEheadSize
				invoke	WriteFile, @hFile,lpMapFile ,ebx,ADDR @dwBytesRead, NULL
				;ѹ������ͷž��

				invoke	CloseHandle,@hFile
				invoke	VirtualFree, lpPackBuffer, 0, MEM_RELEASE	;�ͷ�ѹ������
				invoke	VirtualFree, lpMapFile, 0, MEM_RELEASE

			.else
	AllocNo:			
			invoke	MessageBox,hWnd,addr szAllocNoSuccess,NULL,MB_OK 
			.endif
		.else
			invoke MessageBox,0,OFFSET szOpenFileErrorMsg,0,MB_OK
		.endif
;invoke	MessageBox,0,OFFSET szPackSuc,0,MB_OK
		popad
		
		ret
PackFile	endp

