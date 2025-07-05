. "$bucketsdir\$bucket\bin\utils.ps1"

Add-UserPath $(Join-Path "$(scoop which usdview)" '..')
Add-UserPath $(Join-Path "$(scoop which usdview)" '..\..\lib')
Add-UserPath $(Join-Path "$(scoop which usdview)" '..\..\plugin\usd')

. $(scoop which SFTA)

Register-FTA "$(scoop which usdview)" .usd
Register-FTA "$(scoop which usdview)" .usda
Register-FTA "$(scoop which usdview)" .usdc
Register-FTA "$(scoop which usdview)" .usdz
