
_SaveSet	proc		
		.if PackResource == 1
			invoke	WritePrivateProfileString,addr szIniSectionName,addr IniPackResource,addr IsChecked,addr sziniFileName
		.endif
		.if CreateBak == 1
			invoke	WritePrivateProfileString,addr szIniSectionName,addr IniCreatebak,addr IsChecked,addr sziniFileName
		.endif
		.if IsFileAlignment == 1
			invoke	WritePrivateProfileString,addr szIniSectionName,addr IniFileAlgiment,addr IsChecked,addr sziniFileName
		.endif
		ret
_SaveSet	endp
;压缩选项对话框函数
_ProcDlgOption	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam

		mov	eax,wMsg
		.if	eax == WM_CLOSE
			invoke	EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			invoke	GetPrivateProfileInt,addr szIniSectionName,addr IniPackResource,0h,addr sziniFileName
			.if	eax == 1
				mov	PackResource,1
				invoke	CheckDlgButton,hWnd,IDC_CHECK_PACKRESOURCE,BST_CHECKED
			.endif
			invoke	GetPrivateProfileInt,addr szIniSectionName,addr IniCreatebak,0h,addr sziniFileName
			.if	eax == 1
				mov	CreateBak,1
				invoke	CheckDlgButton,hWnd,IDC_CHECK_CREATBACKUP,BST_CHECKED
			.endif
			invoke	GetPrivateProfileInt,addr szIniSectionName,addr IniFileAlgiment,0h,addr sziniFileName
			.if	eax == 1
				mov	IsFileAlignment,1
				invoke	CheckDlgButton,hWnd,IDC_CHECK_CREATBACKUP,BST_CHECKED
			.endif
			
		.elseif	eax == WM_COMMAND
			mov	eax,wParam
			.if	ax == IDC_BUTTON_OPTIONOK
				invoke	SendDlgItemMessage, hWnd, IDC_CHECK_PACKRESOURCE, BM_GETCHECK, 0, 0
				.if	eax == BST_CHECKED
				mov	PackResource,1
				.else
				mov	PackResource,0
				.endif
				invoke	SendDlgItemMessage, hWnd, IDC_CHECK_PACKRESOURCE, BM_GETCHECK, 0, 0
				.if	eax == BST_CHECKED
				mov	CreateBak,1
				.else
				mov	CreateBak,0
				.endif
				invoke	SendDlgItemMessage, hWnd, IDC_CHECK_FILEALIGMENT, BM_GETCHECK, 0, 0
				.if	eax == BST_CHECKED
				mov	IsFileAlignment,1
				.else
				mov	IsFileAlignment,0
				.endif
			.endif
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgOption	endp