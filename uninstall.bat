@echo off
chcp 65001 >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $desk=[Environment]::GetFolderPath('Desktop'); $sm=[Environment]::GetFolderPath('StartMenu'); $p1=Join-Path $desk 'DeepSeek Harness.lnk'; $p2=Join-Path $sm 'Programs\DeepSeek Harness.lnk'; $ok=$false; if(Test-Path $p1){Remove-Item $p1 -Force; Write-Host ('已删除桌面快捷方式') -ForegroundColor Green; $ok=$true}; if(Test-Path $p2){Remove-Item $p2 -Force; Write-Host ('已删除开始菜单快捷方式') -ForegroundColor Green; $ok=$true}; if(-not $ok){Write-Host '未发现 DeepSeek Harness 快捷方式'}; Write-Host '如需彻底卸载，请直接删除整个 DeepSeekHarness 文件夹。'"
pause
