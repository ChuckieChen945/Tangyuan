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

# 模型路径
$diffusion_models = Join-Path $comfyui_path 'models\diffusion_models'
$vae = Join-Path $comfyui_path 'models\vae'

$ckptFiles = @(
    Join-Path $diffusion_models 'hunyuan3d-dit-v2-1.ckpt',
    Join-Path $vae              'hunyuan3d-vae-v2-1.ckpt'
)

# 删除 hardlink
foreach ($file in $ckptFiles) {
    if (Test-Path $file) {
        Write-Host "删除模型 hardlink: $file"
        Remove-Item $file -Force
    }
    else {
        Write-Host "模型文件不存在: $file"
    }
}

Write-Host "卸载完成。"
