;对要压缩的文件创建备份文件
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
	mov	dword ptr [edi],'kab.'				;于原文件名加后缀.bak
	invoke	CopyFile, lpSourceFileName , @lpBakFileName ,0		;复制源文件进行备份
	push	eax
	invoke	VirtualFree, @lpBakFileName, 0, MEM_RELEASE
	pop	eax
	pop	esi
	pop	edi
	ret
CreateBakFile	endp





; 找到资源数据地址
; 参考看雪出版的软件加密技术内幕对资源的处理
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
		mov	edi,eax		;资源段地址
		xor	ecx,ecx
		mov	cx,word ptr [edi+0ch]
		add	cx,word ptr [edi+0eh]
		add	edi,sizeof IMAGE_RESOURCE_DIRECTORY
			.while ecx > 0
			push	edi
			push	ecx
			mov	edi,dword ptr [edi+4h]		;edi指向OffsetToData
			and	edi,7fffffffh			;相对于资源起点的偏移
			add	edi,esi
			add	edi,lpMapFile
			xor	ecx,ecx
			mov	cx,word ptr [edi+0ch]
			add	cx,word ptr [edi+0eh]
			add	edi,10h			;sizeof IMAGE_RESOURCE_DIRECTORY
				.while	ecx > 0
				push	edi
				push	ecx
				mov	edi,dword ptr [edi+4h]		;edi指向OffsetToData
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

; 移动特定类型的资源，这些资源不能压缩
; 参考看雪出版的软件加密技术内幕对资源的处理
MoveResource		PROC	ResType:DWORD,lpMoveRes:DWORD,dwMoveResSize:DWORD
  local	@lpResourceBase:DWORD
	pushad
	mov	edx,lpPEHeader
	assume	edx : ptr IMAGE_NT_HEADERS
	mov	edx,dword ptr [edx].OptionalHeader.DataDirectory[2*SIZEOF IMAGE_DATA_DIRECTORY].VirtualAddress
	add	edx,lpMapFile		;资源地址
	mov	@lpResourceBase,edx
	xor	ecx,ecx
	mov	cx,word ptr [edx+0ch]		
	add	cx,word ptr [edx+0eh]
	add	edx,sizeof IMAGE_RESOURCE_DIRECTORY
		.while ecx > 0
			mov	eax,dword ptr [edx]		; 指向name
			.if	eax==ResType			; 找到相应类型的资源
				jmp	FoundResDir		; ID为3表示是ICON资源，14表示GROUP ICON，16表示VERSION INFORMATION
			.elseif
			add	edx,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
			.endif
			dec	ecx
		.endw
	jmp	NotFoundResDir
    FoundResDir:
	mov	edx,dword ptr [edx+4h]			;
	and	edx,7fffffffh				; 资源项偏移指向OffsetToData
	add	edx,@lpResourceBase			; 资源的第二层目录
	xor	ecx,ecx 
	mov	cx,word ptr [edx+0ch]
	add	cx,word ptr [edx+0eh]
	add	edx,sizeof IMAGE_RESOURCE_DIRECTORY
		.while ecx > 0
			mov	ebx,dword ptr [edx+4h]			; 指向OffsetToData
			and	ebx,7fffffffh				; 资源项的的偏移
			add	ebx,@lpResourceBase			; 该相的地址，第三层目录
			add	ebx,sizeof IMAGE_RESOURCE_DIRECTORY
			mov	ebx,dword ptr [ebx+4h]			; 指向OffsetToData
			add	ebx,@lpResourceBase			; 指向节点，资源数据指针
			push	ecx
			mov	ecx,dword ptr [ebx+4h]			; 移动资源的大小
			mov	esi,dword ptr [ebx]			; 资源数据指针==esi,指向资源数据偏移；rva
			add	esi,lpMapFile				; 资源数据的地址
			mov	eax,dwImageSize				;
			add	eax,@DeCodeEnd-@DeCode       
			add	eax,dwMoveResSize			; eax==映像文件大小+外壳+移动资源大小
			mov	dword ptr [ebx],eax			; ebx指向资源要移动到的地址,修改资源数据指针
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


; 压缩文件函数
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
			mov	esi,eax			; esi=PEheader偏移地址
			
			add	eax,50h			; eax指向sizeofimage，映像文件大小
			invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
			invoke	ReadFile,@hFile,addr dwImageSize,4,addr @dwBytesRead,NULL
			invoke	VirtualAlloc, NULL, dwImageSize, MEM_COMMIT, PAGE_READWRITE   ; 分配内存
			.if eax
				mov	lpMapFile,eax
				invoke	MessageBox,hWnd,addr szAllocSuccess,NULL,MB_OK
				mov	eax,esi
				add	eax,54h			; 指向SizeOfHeaders ，所有头+节表大小
				invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
				mov	@szbuffer,0
				invoke	ReadFile,@hFile,addr @szbuffer,4,addr @dwBytesRead,NULL
				invoke	SetFilePointer, @hFile, 0, NULL,  FILE_BEGIN
				; PE文件头读入分配的内存
				invoke	ReadFile,@hFile,lpMapFile,@szbuffer,addr @dwBytesRead,NULL
				mov	eax,lpMapFile
				add	eax,esi
				mov	lpPEHeader,eax
				mov	edi,lpPEHeader
				assume	edi:ptr IMAGE_NT_HEADERS
				mov	eax,dword ptr [edi].OptionalHeader.ImageBase
				mov	lpImageBase,eax			; 取得文件装入基地址
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
				mov	lpSectionTableBase,esi		; esi指向节表基地址
	LoadSections:							; 循环读入每个节
				push	ecx
				mov	eax,dword ptr [esi+14h]		; 指向PointerToRawData，节在磁盘文件中的偏移
				invoke	SetFilePointer, @hFile, eax, NULL,  FILE_BEGIN
				mov	ecx,dword ptr [esi+0ch]		; 指出节被装载到内存中后的偏移地址（rva）
				add	ecx,lpMapFile
				mov	ebx,dword ptr [esi+10h]		; 节表文件大小
				invoke	ReadFile, @hFile, ecx, ebx, addr @dwBytesRead, NULL
				mov	ebx,dword ptr [esi+08h]		; 节没有进行对齐处理前的实际大小
				invoke	_FileAlignment,ebx,SectionAlignment
				mov	dword ptr [esi+08h],eax
				add	esi,28h
				pop	ecx
				loop	LoadSections
							; 节读入完毕
				invoke	MessageBox,hWnd,addr szReadSuccess,NULL,MB_OK
				invoke	_FileAlignment,dwImageSize,SectionAlignment
				mov	dwImageSize,eax
				mov	dword ptr [edi].OptionalHeader.SizeOfImage,eax     ; 对齐后文件大小
				invoke	CloseHandle,@hFile
				.if PackResource == 1
					invoke	FindResData
					mov	ResDataAddr,eax
					;===================测试======================
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
					;===================测试======================
					;invoke	wsprintf,addr @tempbuf,addr szFmtHex1,eax
					;invoke	MessageBox,NULL,addr @tempbuf,NULL,MB_OK

					invoke	MessageBox,0,OFFSET szMoveResSuc,0,MB_OK
				.endif
				; +++++++++++++++开始压缩文件++++++++++++++++++
				invoke	VirtualAlloc, NULL, 100000h, MEM_COMMIT, PAGE_READWRITE
				.if eax == 0
					jmp	AllocNo
				.endif
				mov	lpPackBuffer,eax
				invoke	CreateFile,offset szSaveFileName, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE,0,OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL,NULL
				mov	@hFile,eax
				invoke	BegainPackFile,@hFile

				;处理外壳代码
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
				;写入pe头部
				mov	esi,lpPEHeader
				assume esi  : ptr IMAGE_NT_HEADERS
				invoke  SetFilePointer, @hFile, 0h, NULL,  FILE_BEGIN
				mov	ebx,dwPEheadSize
				invoke	WriteFile, @hFile,lpMapFile ,ebx,ADDR @dwBytesRead, NULL
				;压缩完成释放句柄

				invoke	CloseHandle,@hFile
				invoke	VirtualFree, lpPackBuffer, 0, MEM_RELEASE	;释放压缩缓冲
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

