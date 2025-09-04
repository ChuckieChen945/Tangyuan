
$comfyui_path = Join-Path $(appdir comfyui $global) 'current\ComfyUI'

# 安装自定义节点
$custom_nodes_path = Join-Path $comfyui_path 'custom_nodes'

# 如果文件夹链接已存在，则删除后重新创建
$junctionPath = Join-Path $custom_nodes_path $app
if (Test-Path $junctionPath) {
    Remove-Item $junctionPath -Recurse -Force
}
New-Item -ItemType Junction -Path $junctionPath -Target $dir
