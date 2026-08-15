# 重新编译 DeepSeekHarness.exe

环境：Windows 自带 .NET Framework 4.8 编译器 + WebView2 .NET 程序集（已放在 desktop\lib）。

```powershell
$dsh = "C:\Users\11766\Documents\Codex\2026-08-15\an-zh\deepseek-harness"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $csc /nologo /target:winexe /platform:x64 /optimize+ `
  "/win32icon:$dsh\DeepSeekHarness.ico" `
  "/out:$dsh\DeepSeekHarness.exe" `
  /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Management.dll `
  "/r:$dsh\desktop\lib\Microsoft.Web.WebView2.Core.dll" `
  "/r:$dsh\desktop\lib\Microsoft.Web.WebView2.WinForms.dll" `
  "$dsh\desktop\src\App.cs"
```

运行要求（应用目录内需有）：
- DeepSeekHarness.exe
- node.exe
- node_modules\@deepseek-ai\dsh\lib\bin.js
- Microsoft.Web.WebView2.Core.dll / .WinForms.dll / WebView2Loader.dll
- 系统装有 WebView2 运行时（Win10/11 默认已带）
