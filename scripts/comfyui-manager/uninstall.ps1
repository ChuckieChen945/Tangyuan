
$comfyui_path = Join-Path $(appdir comfyui $global) 'current\ComfyUI'

# 自定义节点路径
$custom_nodes_path = Join-Path $comfyui_path 'custom_nodes'
$junctionPath = Join-Path $custom_nodes_path $app

# 删除自定义节点的 junction
if (Test-Path $junctionPath) {
    Write-Host "删除自定义节点目录链接: $junctionPath"
    Remove-Item $junctionPath -Recurse -Force
}
else {
    Write-Host "自定义节点目录链接不存在: $junctionPath"
}
