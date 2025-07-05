. $(scoop which SFTA)

# 定义播放器路径和图标 DLL 基础路径
$exePath = Join-Path $(appdir potplayer $global) 'current\PotPlayer64.exe'
$iconBase = Join-Path $(appdir potplayer $global) 'current\PotIcons64.dll'

$associations = @{
    ".3g2" = 41; ".3gp" = 28; ".3gp2" = 42; ".3gpp" = 40
    ".aac" = 63; ".ac3" = 62; ".aif" = 0; ".aiff" = 0
    ".amr" = 46; ".amv" = 0; ".ape" = 64; ".asf" = 3
    ".ass" = 73; ".asx" = 4; ".avi" = 1; ".cda" = 0
    ".cue" = 0; ".divx" = 2; ".dmskm" = 31; ".dpg" = 0
    ".dpl" = 0; ".dsf" = 0; ".dts" = 67; ".dtshd" = 0
    ".dvr-ms" = 0; ".eac3" = 0; ".evo" = 0; ".f4v" = 0
    ".flac" = 68; ".flv" = 32; ".idx" = 75; ".ifo" = 17
    ".k3g" = 29; ".lmp4" = 27; ".m1a" = 49; ".m1v" = 10
    ".m2a" = 50; ".m2t" = 0; ".m2ts" = 77; ".m2v" = 11
    ".m3u" = 53; ".m3u8" = 0; ".m4a" = 51; ".m4b" = 39
    ".m4p" = 38; ".m4v" = 26; ".mka" = 69; ".mkv" = 20
    ".mod" = 65; ".mov" = 23; ".mp2" = 59; ".mp2v" = 37
    ".mp3" = 60; ".mp4" = 25; ".mpa" = 48; ".mpc" = 66
    ".mpd" = 0; ".mpe" = 12; ".mpeg" = 13; ".mpg" = 14
    ".mpl" = 0; ".mpls" = 0; ".mpv2" = 36; ".mqv" = 24
    ".mts" = 78; ".mxf" = 79; ".nsr" = 0; ".nsv" = 0
    ".ogg" = 61; ".ogm" = 19; ".ogv" = 80; ".opus" = 0
    ".pls" = 54; ".psb" = 0; ".qt" = 45; ".ra" = 52
    ".ram" = 43; ".rm" = 21; ".rmvb" = 22; ".rpm" = 44
    ".rt" = 0; ".sbv" = 0; ".skm" = 30; ".smi" = 71
    ".srt" = 72; ".ssa" = 74; ".ssf" = 0; ".sub" = 76
    ".sup" = 0; ".tak" = 0; ".tp" = 16; ".tpr" = 35
    ".trp" = 34; ".ts" = 33; ".tta" = 0; ".ttml" = 0
    ".usf" = 0; ".vob" = 18; ".vtt" = 0; ".wav" = 70
    ".wax" = 55; ".webm" = 0; ".wm" = 5; ".wma" = 47
    ".wmp" = 6; ".wmv" = 7; ".wmx" = 8; ".wtv" = 0
    ".wv" = 0; ".wvx" = 9; ".xspf" = 0; ".xss" = 0
}

# 遍历字典并调用 Register-FTA
foreach ($ext in $associations.Keys) {
    $index = $associations[$ext]
    $icon = "$iconBase,$index"
    Register-FTA $exePath $ext -Icon $icon
    Write-Host "added file association: $ext"
}
