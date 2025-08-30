
# 公共参数
$commonArgs = "--verbose --force --init"

# 执行列表
$tasks = @(
    @{
        Source      = "D:\chezmoi";
        Destination = "C:\"
    },
    @{
        Source      = "D:\chezmoi\scoop";
        Destination = "D:\scoop"
    },
    ########################## wsl相关配置 ##########################
    @{
        Source      = "D:\chezmoi\Windows\System32\drivers\";
        Destination = "\\wsl.localhost\Arch\\";
        ExtraArgs   = "--config D:\chezmoi\others\copy_mode.chezmoi.jsonc"
    },
    @{
        Source      = "D:\chezmoi\Users\Chuckie\";
        Destination = "\\wsl.localhost\Arch\home\Chuckie";
        ExtraArgs   = "--config D:\chezmoi\others\copy_mode.chezmoi.jsonc"
    },
    ########################## Eagle相关配置 ##########################
    @{
        Source      = "F:\eagle_librarys\Illusion.library\images\MCY6317GW5VTU.info";
        Destination = (Join-Path (Split-Path (scoop which zbrush)) "ZBrushes")
    },
    @{
        Source      = "F:\eagle_librarys\Illusion.library\images\MD79GOXXJ69II.info";
        Destination = "$env:USERPROFILE\Documents\houdini20.5\otls"
    },
    @{
        Source      = "F:\eagle_librarys\Illusion.library\images\MDR4DVA51K586.info";
        Destination = "$env:USERPROFILE\Documents\Adobe\Adobe Substance 3D Painter\assets"
    },
    @{
        Source      = "F:\eagle_librarys\Illusion.library\images\MDWFI8KD2ZCRM.info";
        Destination = "$env:USERPROFILE\Documents\MarvelousDesigner\Assets\Materials\Fabric"
    }
)

# 执行循环
foreach ($task in $tasks) {
    $src = $task.Source
    $dst = $task.Destination
    $extraArgs = if ($task.ContainsKey('ExtraArgs')) { $task.ExtraArgs } else { "" }

    if (-not (Test-Path -Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    Write-Host "===Applying chezmoi for source: $src to destination: $dst"
    if ($extraArgs) {
        gsudo chezmoi apply --source "$src" --destination "`"$dst`"" $commonArgs $extraArgs
    }
    else {
        gsudo chezmoi apply --source "$src" --destination "`"$dst`"" $commonArgs
    }
}
