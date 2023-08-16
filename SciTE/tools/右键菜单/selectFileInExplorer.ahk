﻿#NoEnv
#NoTrayIcon
#SingleInstance Force

selectFileInExplorer(A_Args[1])

; 与命令 explorer.exe /select,１.txt 不同的是，不会重复打开已经存在的文件夹
selectFileInExplorer(path)
{
  ; 转换斜杠 / -> \ ，否则 SplitPath 解析时会出错
  path := StrReplace(path, "/", "\")
  
  ; 确保目标文件或至少目标文件夹存在
  SplitPath, path, OutFileName, OutDir
  if (!FileExist(path))
  {
    if (InStr(FileExist(OutDir), "D"))
      onlyFolderExist := true
    else
    {
      MsgBox 0x40010, , 无法打开文件所在目录。
      return
    }
  }
  
  oWin := isFolderOpened(OutDir)
  if (IsObject(oWin))
  {
    WinActivate, % "ahk_id " oWin.hwnd
    
    oItems := oWin.Document.Folder.Items
    ; SVSI_DESELECT := 0x0, SVSI_SELECT := 0x1, SVSI_DESELECTOTHERS := 0x4, SVSI_ENSUREVISIBLE := 0x8, SVSI_FOCUSED := 0x10
    flags := onlyFolderExist ? 0x0|0x4 : 0x1|0x4|0x8|0x10
    oWin.Document.SelectItem(oItems.Item("" OutFileName), flags)
  }
  else
  {
    if (onlyFolderExist)
      Run, %OutDir%
    else
      Run, explorer.exe /select`,"%path%"
  }
}

isFolderOpened(path)
{
  ; 移除末尾 “\” 方便之后比较路径
  path := RTrim(path, "\")
  
  ; 遍历所有打开的资源管理器的路径
  WinGet, OutputVar, List, ahk_exe explorer.exe
  loop, % OutputVar
  {
    hwnd := OutputVar%A_Index%
    for window in ComObjCreate("Shell.Application").Windows
    {
      if (window.hwnd = hwnd)
      {
        _path := RegExReplace(window.LocationURL, "^\Qfile:///\E")  ; file:///c:/ -> c:/
        _path := StrReplace(_path, "/", "\")                        ; c:/ -> c:\
        _path := RTrim(_path, "\")                                  ; c:\ -> c:
        
        ; 有些时候 window.LocationURL 返回的路径是 uri 编码过的
        if (path = _path or path = uriDecode(_path))
          return window
      }
    }
  }
}

uriDecode(str) {
  Loop
    If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
      StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
    Else Break
  Return, str
}