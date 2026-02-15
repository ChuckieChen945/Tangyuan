
# 设置一个计划任务，每小时自动更新 Scoop

# 1. 获取 Scoop 和 PowerShell 的实际路径
$scoopPath = (scoop which scoop)
$pwshPath = (scoop which pwsh)

# 2. 设定日志文件路径
$logPath = "$env:TEMP\ScoopAutoTask.log"

# 3. 构建核心命令（更新 Scoop -> 更新所有 App -> 清理旧版本 -> 记录日志）
# 注意：这里加上了 scoop update *，如果你只想更新 scoop 本身，可以删掉中间那段
$cmdToRun = "Write-Output `"--- `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---`" >> `'$logPath`'; & `'$scoopPath`' update >> `'$logPath`' 2>&1; & `'$scoopPath`' update * >> `'$logPath`'; & `'$scoopPath`' cleanup * >> `'$logPath`' 2>&1"

# 4. 组装 pwsh.exe 的启动参数
$argString = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command ""$cmdToRun"""

# 5. 配置任务触发器和设置
$Action = New-ScheduledTaskAction -Execute $pwshPath -Argument $argString
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 6. 配置执行账号与后台静默模式
$currentUser = "$env:USERDOMAIN\$env:USERNAME"

$Principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType S4U -RunLevel Highest

Register-ScheduledTask -TaskName 'ScoopAutoUpdate' -Action $Action -Trigger $trigger -Description '每小时后台自动更新 Scoop 并清理旧版本' -Settings $Settings -Principal $Principal -Force
Write-Host "✅ 计划任务注册成功！" -ForegroundColor Green
Write-Host "日志查看路径: $logPath" -ForegroundColor Yellow
