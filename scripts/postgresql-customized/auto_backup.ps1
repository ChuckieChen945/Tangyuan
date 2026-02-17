$backupScriptDir = Join-Path $persist_dir 'data\backup_db.ps1'
$pwshPath = (scoop which pwsh)

$argString = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command ""& `'$backupScriptDir`'"""

$Action = New-ScheduledTaskAction -Execute $pwshPath -Argument $argString
$Trigger1 = New-ScheduledTaskTrigger -Daily -At 2am
$Trigger2 = New-ScheduledTaskTrigger -Daily -At 2pm
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$currentUser = "$env:USERDOMAIN\$env:USERNAME"
$Principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType S4U -RunLevel Highest

Register-ScheduledTask `
    -Action $Action `
    -Trigger $Trigger1, $Trigger2 `
    -TaskName 'PostgreSQL_AutoBackup' `
    -Description '每日两次定时备份 PostgreSQL 数据库（静默后台运行）' `
    -Settings $Settings `
    -Principal $Principal `
    -Force

Write-Host "✅ 备份任务已成功注册，将在后台静默运行。" -ForegroundColor Green
