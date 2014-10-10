		.386
		.model flat, stdcall
		option casemap :none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include �ļ�����
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
; Equ ��ֵ����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;ͼ��
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
; ���ݶ�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hDlg1		dd	?
hMain		dd	?
hMenu		dd	?
hInstance	dd	?
hWndTab		dd	?		; tab�ؼ����
hWinMain	dd	?		
Handles LABEL	DWORD			; �ӶԻ�����
hTabOpen	dd	?
hTabOption	dd	?
WhichTabChosen	dd	?		; ��ʾ�ĸ�tab�Ի���ѡ��
hPackButton	dd	?
szFileName	db	MAX_PATH dup (?)	;
szSaveFileName	db	MAX_PATH dup (?)
TabStruct  	TC_ITEM 	<?>
dwMapOfShell		dword	?		;�������ǵĴ�С
lpShellMap		dword	?		;
lpPackBuffer		dword	?
dwCurrentSize		dword	?		; ѹ���ļ�ʱʵ��д��Ĵ�С
dwImageSize		dword	?		; �����ļ���С
lpPEHeader		dword	?		; �����ڴ��Peͷ����ַ
lpMapFile		dword	?		; �����ڴ���ļ�����ַ
dwPEheadSize		dword	?		; PEͷ����С
lpImageBase		dword	?		; �����ļ�����ַ
lpSectionTableBase	dword	?		; ָ��ڵ�ַ
PackSection		db	0a0h dup (?)
FileAlignment		dword	?		; �ļ��нڶ���
SectionAlignment	dword	?		; �ڴ��нڵĶ���
ResDataAddr		dword	?		; ��Դ���ݵ�ַ
lpMapResDataAddr	dword	?
dwMovedRes		dword	?		; �Ѿ��ƶ�����Դ
		.data
CreateBak		dd	0h	; �Ƿ񴴽�����
PackResource		dd	0h	; ѹ����Դ
IsFileAlignment		dd	0h	; �����ļ�����
		.const
szFmtHex1		db	"%01x",0
TabOpen			DB	"Open",0
TabOption		DB	"Option",0
sziniFileName		db      'Option.ini',0		;������Ϣ��ini�ļ�
szIniSectionName	db	"OptionSet",0		;ini�ļ�����
IniCreatebak		db	'CreatBackup',0		;�Ӽ���
IniPackResource		db	'PackResource',0	;
IniFileAlgiment		db	'FileAlgiment',0
IsChecked		DB	"1",0			
szExtPe			db	'PE Files',0,'*.exe;*.dll;*.scr;*.fon;*.drv',0
			db	'All Files(*.*)',0,'*.*',0,0
szFilter		db	'PE Files(*.exe;*.dll)',0,'*.exe;*.dll',0,'All Files(*.*)',0,'*.*',0,0
szDefExt		db	'exe',0
szErr			db	'�ļ���ʽ����!',0
szErrFormat		db	'����ļ�����PE��ʽ���ļ�!',0
szOpenFileErrorMsg	db	'���ļ�����',0
szText			db	'���ڿ�����',0
szCaption		db	'by herx',0
szSaveCaption		db	'�����뱣����ļ���',0
szCreatSuccess		db	'�������ݳɹ�',0
szCreatNoSuccess	db	'��������ʧ��',0
szAllocSuccess		db	'�����ڴ�ɹ�',0
szAllocNoSuccess	db	'�����ڴ�ɹ�',0
szReadSuccess		db	'���ļ��ɹ�',0
szMoveResSuc		db	'�ƶ���Դ�ɹ�',0
szPackSuc		db	'ѹ�����',0
szbeginMoveRes		db	'��ʼ�ƶ���Դ',0
FileDataEnd		dd	?
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �����
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
;���Ի�����
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