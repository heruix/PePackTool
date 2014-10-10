; 打开文件对话框
_OpenFile	proc	hWnd
		local	@stOF:OPENFILENAME		

		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWnd
		pop	@stOF.hwndOwner
		mov	@stOF.lpstrFilter,offset szFilter
		mov	@stOF.lpstrFile,offset szFileName
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
		invoke	GetOpenFileName,addr @stOF
		.if	! eax
			jmp	@F
		.endif
			invoke SetDlgItemText,hWnd,IDC_EDIT_PACKFILE,OFFSET szFileName

@@:
		ret
_OpenFile	endp

; 判断是否是PE文件
_LoadIsPEFile	proc	hWnd
		local	@hFile,@hMapFile,@ImageBase,@dwFileSize,@lpMemory

; 打开文件并建立文件 Mapping,判断是不是PE格式文件
	invoke CreateFile,offset szFileName,GENERIC_READ+GENERIC_WRITE,FILE_SHARE_READ+FILE_SHARE_WRITE,NULL,OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,NULL
	.if eax != INVALID_HANDLE_VALUE
		mov	@hFile,eax
			invoke	GetFileSize,eax,NULL
			mov	@dwFileSize,eax
			.if	eax
				invoke	CreateFileMapping,@hFile,NULL,PAGE_READONLY,0,0,NULL
				.if	eax
					mov	@hMapFile,eax
					invoke	MapViewOfFile,eax,FILE_MAP_READ,0,0,0
					.if	eax
						mov	@lpMemory,eax
; 检测 PE 文件是否有效

						mov	esi,@lpMemory
						assume	esi:ptr IMAGE_DOS_HEADER
						.if	[esi].e_magic != IMAGE_DOS_SIGNATURE
							jmp	_ErrFormat
						.endif
						add	esi,[esi].e_lfanew
						assume	esi:ptr IMAGE_NT_HEADERS
						.if	[esi].Signature != IMAGE_NT_SIGNATURE
							jmp	_ErrFormat
						.endif
						xor	eax,eax
						inc	eax
						jmp	_ErrorExit
_ErrFormat:
						invoke	MessageBox,hWnd,addr szErrFormat,NULL,MB_OK
						xor	eax,eax
						
_ErrorExit:
						
					.endif
					invoke	UnmapViewOfFile,@lpMemory
				.endif
				invoke	CloseHandle,@hMapFile				
			.endif
			invoke	CloseHandle,@hFile
		.else		
		invoke MessageBox,0,OFFSET szOpenFileErrorMsg,0,MB_OK
		.endif

@@:
			ret
_LoadIsPEFile	endp
;保存文件对话框
_SavePackFile		proc	hWnd
		local	@stOF:OPENFILENAME

		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWinMain
		pop	@stOF.hwndOwner
		mov	@stOF.lpstrFilter,offset szFilter
		mov	@stOF.lpstrFile,offset szSaveFileName
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_PATHMUSTEXIST
		mov	@stOF.lpstrDefExt,offset szDefExt
		mov	@stOF.lpstrTitle,offset szSaveCaption
		invoke	GetSaveFileName,addr @stOF
		.if	eax
			invoke SetDlgItemText,hWnd,IDC_EDIT_SAVE,OFFSET szSaveFileName
		.endif
		ret

_SavePackFile		endp

;选折打开文件对话框函数
_ProcDlgOpen	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam

		mov	eax,wMsg
		.if	eax == WM_CLOSE
			invoke	EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			mov	eax,hWnd
			mov	hDlg1,eax
			invoke	GetDlgItem, hWnd, IDC_BUTTON_PACK
			mov	hPackButton,eax
			invoke	EnableWindow, hPackButton, FALSE
			invoke	GetDlgItem, hWnd, IDC_BUTTON_SAVE
			invoke	EnableWindow, eax, FALSE
			invoke	GetDlgItem, hWnd, IDC_EDIT_SAVE
			invoke	EnableWindow, eax, FALSE
		.elseif	eax == WM_COMMAND
			mov	eax,wParam
			.if	ax == IDC_BUTTON_OPEN1
			invoke	_OpenFile,hWnd
			invoke	GetDlgItem, hWnd, IDC_BUTTON_SAVE
			invoke	EnableWindow, eax, TRUE
			invoke	GetDlgItem, hWnd, IDC_EDIT_SAVE
			invoke	EnableWindow, eax, TRUE
			invoke SetDlgItemText,hWnd,IDC_EDIT_SAVE,OFFSET szFileName
			.elseif	ax == IDC_BUTTON_SAVE
				invoke	_SavePackFile,hWnd
				invoke	_LoadIsPEFile,hWnd
				.if eax ==1
					.if szFileName
				invoke	EnableWindow, hPackButton, TRUE
				invoke  EnableMenuItem,hMenu,IDD_MENU_PACK,MF_ENABLED
					.endif
				.elseif eax == 0
				invoke	EnableWindow, hPackButton, FALSE
				.endif
			.elseif	ax == IDC_BUTTON_PACK
				invoke  PackFile,hWnd		;开始压缩文件
			.endif
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgOpen	endp