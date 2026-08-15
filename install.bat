@echo off
chcp 65001 >nul 2>&1
setlocal
set "APP_DIR=%~dp0"
if not exist "%APP_DIR%DeepSeekHarness.exe" (
    echo [错误] 未在当前文件夹找到 DeepSeekHarness.exe。
    echo 请确认本文件与 DeepSeekHarness.exe 位于同一文件夹内。
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=$env:APP_DIR; $exe=Join-Path $d 'DeepSeekHarness.exe'; $ws=New-Object -ComObject WScript.Shell; $desk=[Environment]::GetFolderPath('Desktop'); $lnk=$ws.CreateShortcut((Join-Path $desk 'DeepSeek Harness.lnk')); $lnk.TargetPath=$exe; $lnk.WorkingDirectory=$d; $lnk.IconLocation=($exe+',0'); $lnk.Description='DeepSeek Harness 桌面版'; $lnk.Save(); $sm=[Environment]::GetFolderPath('StartMenu'); $sl=$ws.CreateShortcut((Join-Path $sm 'Programs\DeepSeek Harness.lnk')); $sl.TargetPath=$exe; $sl.WorkingDirectory=$d; $sl.IconLocation=($exe+',0'); $sl.Save(); Write-Host ('已创建桌面与开始菜单快捷方式') -ForegroundColor Green; Write-Host ('快捷方式指向: '+$exe)"
echo.
echo 安装完成！现在可以直接从桌面或开始菜单启动 DeepSeek Harness。
echo 注意：请保留整个 DeepSeekHarness 文件夹，不要单独移动 exe。
pause
