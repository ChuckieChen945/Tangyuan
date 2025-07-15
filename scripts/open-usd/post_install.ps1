. "$bucketsdir\$bucket\bin\utils.ps1"

. $(scoop which SFTA)

Register-FTA "$(scoop which usdview)" .usd
Register-FTA "$(scoop which usdview)" .usda
Register-FTA "$(scoop which usdview)" .usdc
Register-FTA "$(scoop which usdview)" .usdz
