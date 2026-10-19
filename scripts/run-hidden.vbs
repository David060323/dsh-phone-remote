' Launch one PowerShell script hidden, so a scheduled task never flashes a console window.
' Usage: wscript.exe run-hidden.vbs <script-name-relative-to-this-folder> [extra args...]
Dim fso, shell, here, target, extra, i
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)
If WScript.Arguments.Count = 0 Then
  WScript.Quit 1
End If
target = WScript.Arguments(0)
extra = ""
For i = 1 To WScript.Arguments.Count - 1
  extra = extra & " " & WScript.Arguments(i)
Next
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & fso.BuildPath(here, target) & """" & extra, 0, False
