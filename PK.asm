		.386
		.model flat, stdcall
		option casemap :none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include 文件定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
include		comdlg32.inc
includelib	comdlg32.lib
include		gdi32.inc 
includelib	gdi32.lib 
include		comctl32.inc
includelib	comctl32.lib
include		shell32.inc
includelib	shell32.lib
include		aplib.inc
includelib	aplib.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Equ 等值定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;图标
;******************************************************
IDI_ICON_PK     equ       131
IDI_ICON_SMALL		 equ	   13

IDD_DIALOG_MAIN         EQU        101
IDD_DIALOG_ABOUT        EQU        105
IDD_DIALOGBAR_OPEN      EQU        103
IDR_MENU                EQU        103
IDD_DIALOGBAR_OPTION    EQU        104
IDC_TAB2                EQU        1001
IDC_EDIT_PACKFILE       EQU        1002
IDC_BUTTON_OPEN1        EQU        1003
IDC_EDIT_SAVE           EQU        1004
IDC_BUTTON_SAVE         EQU        1005
IDC_BUTTON_PACK         EQU        1006
IDC_CHECK_PACKRESOURCE  EQU        1007
IDC_CHECK_CREATBACKUP   EQU        1008
IDC_BUTTON_OPTIONOK     EQU        1009
IDC_CHECK_FILEALIGMENT  EQU        1010
IDD_MENU_OPEN           EQU        40001
IDD_MENU_PACK           EQU        40002
IDD_MENU_EXIT           EQU        40003
IDD_MENU_ABOUT          EQU        65535
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 数据段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hDlg1		dd	?
hMain		dd	?
hMenu		dd	?
hInstance	dd	?
hWndTab		dd	?		; tab控件句柄
hWinMain	dd	?		
Handles LABEL	DWORD			; 子对话框句柄
hTabOpen	dd	?
hTabOption	dd	?
WhichTabChosen	dd	?		; 表示哪个tab对话框被选折
hPackButton	dd	?
szFileName	db	MAX_PATH dup (?)	;
szSaveFileName	db	MAX_PATH dup (?)
TabStruct  	TC_ITEM 	<?>
dwMapOfShell		dword	?		;对齐后外壳的大小
lpShellMap		dword	?		;
lpPackBuffer		dword	?
dwCurrentSize		dword	?		; 压缩文件时实际写入的大小
dwImageSize		dword	?		; 读入文件大小
lpPEHeader		dword	?		; 读入内存后Pe头部地址
lpMapFile		dword	?		; 读入内存后文件基地址
dwPEheadSize		dword	?		; PE头部大小
lpImageBase		dword	?		; 保存文件基地址
lpSectionTableBase	dword	?		; 指向节地址
PackSection		db	0a0h dup (?)
FileAlignment		dword	?		; 文件中节对齐
SectionAlignment	dword	?		; 内存中节的对齐
ResDataAddr		dword	?		; 资源数据地址
lpMapResDataAddr	dword	?
dwMovedRes		dword	?		; 已经移动的资源
		.data
CreateBak		dd	0h	; 是否创建备份
PackResource		dd	0h	; 压缩资源
IsFileAlignment		dd	0h	; 进行文件对齐
		.const
szFmtHex1		db	"%01x",0
TabOpen			DB	"Open",0
TabOption		DB	"Option",0
sziniFileName		db      'Option.ini',0		;保存信息的ini文件
szIniSectionName	db	"OptionSet",0		;ini文件节名
IniCreatebak		db	'CreatBackup',0		;子键名
IniPackResource		db	'PackResource',0	;
IniFileAlgiment		db	'FileAlgiment',0
IsChecked		DB	"1",0			
szExtPe			db	'PE Files',0,'*.exe;*.dll;*.scr;*.fon;*.drv',0
			db	'All Files(*.*)',0,'*.*',0,0
szFilter		db	'PE Files(*.exe;*.dll)',0,'*.exe;*.dll',0,'All Files(*.*)',0,'*.*',0,0
szDefExt		db	'exe',0
szErr			db	'文件格式错误!',0
szErrFormat		db	'这个文件不是PE格式的文件!',0
szOpenFileErrorMsg	db	'打开文件错误',0
szText			db	'正在开发中',0
szCaption		db	'by herx',0
szSaveCaption		db	'请输入保存的文件名',0
szCreatSuccess		db	'创建备份成功',0
szCreatNoSuccess	db	'创建备份失败',0
szAllocSuccess		db	'分配内存成功',0
szAllocNoSuccess	db	'分配内存成功',0
szReadSuccess		db	'读文件成功',0
szMoveResSuc		db	'移动资源成功',0
szPackSuc		db	'压缩完毕',0
szbeginMoveRes		db	'开始移动资源',0
FileDataEnd		dd	?
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.code
include		BeginPackFile.asm
include		DepackerCode.asm
include		WriteShell.asm
include		PackFunction.asm
include		TabDlg1.asm
include		TabDlg2.asm

_ProcDlgAbout PROC hDlg,wMsg,wParam,lParam

	mov eax,wMsg
	cmp eax,WM_CLOSE
	jz _closeabout

	cmp eax,WM_COMMAND
	jz _command

	xor eax,eax
	ret

	_command:
	mov eax,wParam
	cmp ax,IDOK
	jz  _closeabout

	_closeabout:
	invoke EndDialog,hDlg,0
	ret

_ProcDlgAbout	endp
;主对话框函数
_ProcDlgMain	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam

		mov	eax,wMsg
		.if	eax == WM_CLOSE
			invoke	_SaveSet
			invoke	EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			mov	eax,hWnd
			mov	hMain,eax
			invoke  GetMenu,hWnd
			mov	hMenu,eax
			invoke  EnableMenuItem,hMenu,IDD_MENU_PACK,MF_GRAYED
			invoke InitCommonControls
			invoke	LoadIcon,hInstance,IDI_ICON_PK
			invoke  SendMessage,hWnd,WM_SETICON,ICON_SMALL,eax
			invoke GetDlgItem,hWnd,IDC_TAB2
			mov	hWndTab,eax			
			mov	TabStruct.imask,TCIF_TEXT
			mov	TabStruct.lpReserved1,0
			mov	TabStruct.lpReserved2,0
  			mov	TabStruct.iImage,0
 			mov	TabStruct.lParam,0
			mov	TabStruct.pszText,OFFSET TabOpen
			mov	TabStruct.cchTextMax,sizeof TabOpen
			invoke	SendMessage,hWndTab,TCM_INSERTITEM,0,OFFSET TabStruct
			mov	TabStruct.pszText,OFFSET TabOption
			mov	TabStruct.cchTextMax,sizeof TabOption
			invoke	SendMessage,hWndTab,TCM_INSERTITEM,1,OFFSET TabStruct
	
			invoke	CreateDialogParam,hInstance,IDD_DIALOGBAR_OPEN,hWndTab,OFFSET _ProcDlgOpen,0
			mov	hTabOpen,eax
			invoke	CreateDialogParam,hInstance,IDD_DIALOGBAR_OPTION,hWndTab,OFFSET _ProcDlgOption,0
			mov	hTabOption,eax

			mov WhichTabChosen,0 				
			invoke ShowWindow,hTabOpen,SW_SHOWDEFAULT
			
		.elseif	eax == WM_COMMAND
			mov	eax,wParam
			.if	ax == IDD_MENU_OPEN
				invoke	_OpenFile,hDlg1
				invoke	GetDlgItem, hDlg1, IDC_BUTTON_SAVE
				invoke	EnableWindow, eax, TRUE
				invoke	GetDlgItem, hDlg1, IDC_EDIT_SAVE
				invoke	EnableWindow, eax, TRUE
			.elseif	ax == IDD_MENU_PACK
				invoke  PackFile,hDlg1
			.elseif	ax == IDD_MENU_ABOUT
				invoke  DialogBoxParam,hInstance,IDD_DIALOG_ABOUT,hWnd,offset _ProcDlgAbout,NULL
			.elseif	ax == IDD_MENU_EXIT
				invoke	EndDialog,hWnd,NULL
			.endif
		.elseif	eax == WM_NOTIFY
			mov eax,lParam	
			mov eax, (NMHDR PTR [eax]).code	
			.if eax == TCN_SELCHANGE
					mov eax,WhichTabChosen
					mov eax,[Handles+eax*4]
					invoke ShowWindow,eax,SW_HIDE
					invoke SendMessage,hWndTab,TCM_GETCURSEL,0,0												; Ok which one is BEING chosen right now?
					mov WhichTabChosen,eax
					mov eax,[Handles+eax*4]
 					invoke ShowWindow,eax,SW_SHOWDEFAULT
			.endif
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgMain	endp
start:
		
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	DialogBoxParam,hInstance,IDD_DIALOG_MAIN,NULL,offset _ProcDlgMain,NULL
		invoke	ExitProcess,NULL
		end	start