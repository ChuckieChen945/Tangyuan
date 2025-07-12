
# 公共参数
$commonArgs = "--verbose --force --init"

# 执行列表
$tasks = @(
    @{ Source = "D:\chezmoi"; Destination = "C:\" },
    @{ Source = "D:\chezmoi\scoop"; Destination = "D:\scoop" },
    @{ Source = "F:\eagle_librarys\Illusion.library\images\MCY6317GW5VTU.info"; Destination = (Join-Path (Split-Path (scoop which zbrush)) "ZBrushes") }
)

# 执行循环
foreach ($task in $tasks) {
    $src = $task.Source
    $dst = $task.Destination

    Write-Host "===Applying chezmoi for source: $src to destination: $dst"
    gsudo chezmoi apply --source "$src" --destination "`"$dst`"" $commonArgs

}
