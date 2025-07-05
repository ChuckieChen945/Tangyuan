
. .\utils.ps1

$script_path = Convert-WindowsPathToWslPath "$bucketsdir\ChuckieChen945_Chuckie_s\scripts\archlinux-customized\init_archlinux.sh"
wsl --distribution Arch bash -c $script_path
$script_path = Convert-WindowsPathToWslPath "$bucketsdir\ChuckieChen945_Chuckie_s\scripts\archlinux-customized\restore_pkgs.sh"
wsl --distribution Arch bash --username -command $script_path

$source_etc = Join-Path (chezmoi data | ConvertFrom-Json).CHEZMOI 'etc'
$source_etc = Convert-WindowsPathToWslPath $source_etc
$destination_etc = '/etc'
$chezmoi_command = "sudo chezmoi apply --source '$source_etc' --destination '$destination_etc' --verbose --force --init"
wsl --distribution Arch --username Chuckie -- bash --command $chezmoi_command
