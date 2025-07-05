function Convert-WindowsPathToWslPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )
    # Ensure the path is absolute and resolved
    try {
        $resolvedPath = Resolve-Path -Path $WindowsPath -ErrorAction Stop | Select-Object -ExpandProperty Path
    }
    catch {
        Write-Error "Could not resolve Windows path: $WindowsPath. $($_.Exception.Message)"
        throw # Re-throw to halt execution if path is critical
    }

    $cleanPath = $resolvedPath -replace '\\', '/'

    if ($cleanPath -match '^([A-Za-z]):/(.*)') {
        $drive = $matches[1].ToLower()
        $rest = $matches[2]
        return "/mnt/$drive/$rest"
    }
    elseif ($cleanPath -match '^//') {
        # Handle UNC paths (basic example, might need more robust handling)
        $uncPath = $cleanPath -replace '^//', ''
        return "/mnt/unc/$uncPath" # Example, WSL UNC mapping might vary or require setup
    }
    else {
        Write-Error "Illegal or unhandled Windows file path format: $cleanPath"
        throw # Re-throw
    }
}
