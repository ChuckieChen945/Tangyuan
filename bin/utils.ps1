

$variables = @(
    @{ name = 'version'; value = $version },
    @{ name = 'architecture'; value = $architecture },
    @{ name = 'bucket'; value = $bucket },
    @{ name = 'bucketsdir'; value = $bucketsdir },
    @{ name = 'persist_dir'; value = $persist_dir },
    @{ name = 'global'; value = $global },
    @{ name = 'env:SCOOP'; value = $env:SCOOP },
    @{ name = 'dir'; value = $dir },
    @{ name = 'extract_dir'; value = $extract_dir },
    @{ name = 'manifest_path'; value = $manifest_path },
    @{ name = 'cache_dir'; value = $cache_dir },
    @{ name = 'config_dir'; value = $config_dir },
    @{ name = 'env:SCOOP_HOME'; value = $env:SCOOP_HOME },
    @{ name = 'app'; value = $app },
    @{ name = 'env:AppData'; value = $env:AppData },
    @{ name = 'env:LocalAppData'; value = $env:LocalAppData },
    @{ name = 'pwd'; value = $pwd },
    @{ name = 'PSScriptRoot'; value = $PSScriptRoot },
    @{ name = 'MyInvocation'; value = $MyInvocation },
    @{ name = 'manifest'; value = $manifest },
    @{ name = 'url'; value = $url }
)




function Show-VarInfo {
    param (
        [string]$name,
        $value
    )

    if ($null -ne $value) {
        $type = $value.GetType().Name
        Write-Host ("  • `$${name}".PadRight(24) + "$value".PadRight(40) + "($type)") -ForegroundColor DarkCyan
    }
    else {
        Write-Host ("  • `$${name}".PadRight(24) + "<null>".PadRight(40) + "(null)") -ForegroundColor DarkGray
    }
}


function Show-VarInfoList {

    foreach ($item in $variables) {
        Show-VarInfo -name $item.name -value $item.value
    }


}

function Show-uninstallString {
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $paths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, UninstallString
    }
}

function Copy-DirItems {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$dirTag,

        [Parameter(Mandatory = $true)]
        [string]$destinationDir,

        [bool]$clean = $true
    )

    if (-not (Get-Command 'gsudo' -ErrorAction SilentlyContinue)) {
        try {
            scoop install main/gsudo
        }
        catch {
            Write-Error "无法安装 gsudo，请确保 Scoop 可用。"
            return
        }
    }

    $sourceDir = Join-Path -Path $dir -ChildPath $dirTag

    if (-not (Test-Path $sourceDir)) {
        Write-Error "源目录不存在：$sourceDir"
        return
    }

    if (-not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }


    # 执行复制
    try {

        $copyCommand = "Copy-Item -Path `"$sourceDir`" -Destination `"$destinationDir`" -Recurse -Force"
        gsudo $copyCommand

        Write-Host "`n✅ 已复制文件: $sourceDir → $destinationDir"

        # 清理目录内容
        if ($clean) {
            Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "🧹 已清理安装目录内容: $dir"
        }
    }
    catch {
        Write-Error "❌ 操作失败: $_"
    }
}


function Add-UserPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PathToAdd
    )

    # TODO: 这个函数好像将$pathToAdd加入到了系统 环境变量中
    Add-Env -Variable 'Path' -Value $PathToAdd
}

function Uninstall-MsiApp {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppGuid

    )

    $args_ = @('/uninstall', $AppGuid, '/passive', '/norestart')

    try {
        Invoke-ExternalCommand 'msiexec' -ArgumentList $args_
        Write-Host "已启动卸载应用 GUID: $AppGuid" -ForegroundColor Green
    }
    catch {
        Write-Error "卸载失败：$_"
    }
}


function Add-Env {
    param (
        [Parameter(Mandatory)]
        [string]$VariableName,

        [Parameter(Mandatory)]
        [string]$Value

    )

    $currentValue = Get-EnvVar -Name $VariableName -Global $global
    $entries = if ($currentValue) { $currentValue -split ';' } else { @() }

    if ($entries -notcontains $Value) {
        $entries += $Value
        $newValue = ($entries | Where-Object { $_ -ne '' }) -join ';'
        Set-EnvVar -Name $VariableName -Value "$newValue" -Global $global
    }
}

function Remove-Env {
    param (
        [Parameter(Mandatory)]
        [string]$VariableName,

        [Parameter(Mandatory)]
        [string]$Value

    )

    $currentValue = Get-EnvVar -Name $VariableName -Global $global
    $entries = if ($currentValue) { $currentValue -split ';' } else { @() }

    if (-not [string]::IsNullOrEmpty($currentValue)) {
        $entries = $currentValue -split ';' | Where-Object { $_ -and $_ -ne $Value }

        # FIXME: 看一下scoop内置的 Set-EnvVar 与 Get-EnvVar 实现，优化这里的代码
        $newValue = $entries -join ';'
        Set-EnvVar -Name $VariableName -Value "$newValue" -Global $global
    }
}

function Stop-ProcessWithTimeout {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProcessName,

        [int]$MaxWaitSeconds = 60
    )

    $waited = 0
    while (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue

        if ($waited -ge $MaxWaitSeconds) {
            Write-Warning "进程 '$ProcessName' 未能在 $MaxWaitSeconds 秒内停止，继续执行脚本"
            break
        }

        Start-Sleep -Seconds 1
        $waited++
    }
}

