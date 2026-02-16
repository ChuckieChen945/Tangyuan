

# --- Network Diagnostic Tool v1.0 ---
$ErrorActionPreference = "SilentlyContinue"
$proxyUrl = "http://127.0.0.1:10808"

function Write-Header ([string]$Text) {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan -Bold
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

# 1. 网卡与 IP 地址信息
Write-Header "1. 正在获取活动网卡与 IPv4 地址..."
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object PrefixOrigin -ne "WellKnown" |
    Select-Object InterfaceAlias, IPAddress, PrefixLength |
    Format-Table -AutoSize

# 2. 默认网关 (按 Metric 自动筛选最优先的)
Write-Header "2. 当前生效的默认网关 (Lowest Metric)"
$defaultRoute = Get-NetRoute -DestinationPrefix 0.0.0.0/0 |
    Sort-Object RouteMetric, InterfaceMetric |
    Select-Object -First 1

if ($defaultRoute) {
    $defaultRoute | Select-Object DestinationPrefix, NextHop, RouteMetric, InterfaceAlias | Format-Table -AutoSize
} else {
    Write-Host "未找到有效的默认网关！" -ForegroundColor Red
}

# 3. DNS 服务器配置
Write-Header "3. 默认 DNS 服务器"
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object ServerAddresses -ne $null |
    Select-Object InterfaceAlias, ServerAddresses |
    Format-Table -AutoSize

# 4. 代理环境变量排查
Write-Header "4. 代理环境变量 (System & User)"
$proxyVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*proxy*" }
if ($proxyVars) {
    $proxyVars | Format-Table Name, Value -AutoSize
} else {
    Write-Host "未检测到代理相关的环境变量。" -ForegroundColor Gray
}

# 5. 真实连接测试 (直连 vs 代理)
Write-Header "5. 互联网连接测试 (真实请求)"

# --- 测试直连 (百度) ---
Write-Host "[直连测试] 正在尝试访问 www.baidu.com..." -NoNewline
try {
    $baidu = Invoke-WebRequest -Uri "https://www.baidu.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host " [成功] 状态码: $($baidu.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host " [失败] 无法连接到百度。" -ForegroundColor Red
}

# --- 测试代理端口存活 ---
Write-Host "[代理测试] 正在检查本地代理端口 $proxyUrl ..." -NoNewline
$portTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 10808
if ($portTest.TcpTestSucceeded) {
    Write-Host " [开放]" -ForegroundColor Green

    # --- 通过代理测试 Google ---
    Write-Host "[代理测试] 正在通过代理访问 www.google.com..." -NoNewline
    try {
        $google = Invoke-WebRequest -Uri "https://www.google.com" -Proxy $proxyUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Host " [成功] 状态码: $($google.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host " [失败] 代理握手成功但无法访问外网。" -ForegroundColor Yellow
    }
} else {
    Write-Host " [关闭] 本地 10808 端口未监听，跳过代理请求测试。" -ForegroundColor Red
}

Write-Host "`n检测完毕。" -ForegroundColor Cyan

# TODO: 测网速等
