$comfyui_path = Join-Path $(appdir comfyui $global) 'current\ComfyUI'
$python_embeded = Join-Path $(appdir comfyui $global) 'current\python_embeded\python.exe'

# 安装自定义节点
$custom_nodes_path = Join-Path $comfyui_path 'custom_nodes'

# 如果文件夹链接已存在，则删除后重新创建
$junctionPath = Join-Path $custom_nodes_path $app
if (Test-Path $junctionPath) {
    Remove-Item $junctionPath -Recurse -Force
}
New-Item -ItemType Junction -Path $junctionPath -Target $dir

# 安装自定义节点依赖
& $python_embeded -m pip install -r "$junctionPath\requirements.txt"
& $python_embeded -m pip install "$junctionPath\hy3dpaint\custom_rasterizer\dist\custom_rasterizer-0.1-cp312-cp312-win_amd64.whl"
& $python_embeded -m pip install "$junctionPath\hy3dpaint\DifferentiableRenderer\dist\mesh_inpaint_processor-0.0.0-cp312-cp312-win_amd64.whl"
& $python_embeded -m pip install rembg onnxruntime # 这两个包requirements.txt中漏掉了

# 安装模型
$diffusion_models = Join-Path $comfyui_path 'models\diffusion_models'
$vae = Join-Path $comfyui_path 'models\vae'

# hunyuan3d-dit-v2-1.ckpt
$ckptPath = Join-Path $diffusion_models 'hunyuan3d-dit-v2-1.ckpt'
if (Test-Path $ckptPath) {
    Remove-Item $ckptPath -Force
}
New-Item -ItemType HardLink -Path $ckptPath -Target (Join-Path $dir 'hunyuan3d-dit-v2-1.ckpt')

# hunyuan3d-vae-v2-1.ckpt
$vaePath = Join-Path $vae 'hunyuan3d-vae-v2-1.ckpt'
if (Test-Path $vaePath) {
    Remove-Item $vaePath -Force
}
New-Item -ItemType HardLink -Path $vaePath -Target (Join-Path $dir 'hunyuan3d-vae-v2-1.ckpt')
