

. .\utils.ps1

$script_path = Convert-WindowsPathToWslPath "$bucketsdir\ChuckieChen945_Chuckie_s\scripts\archlinux-customized\init_archlinux.sh"
wsl --distribution Arch bash -c $script_path
$script_path = Convert-WindowsPathToWslPath "$bucketsdir\ChuckieChen945_Chuckie_s\scripts\archlinux-customized\install_pkgs.sh"
TODO:chezmoi
