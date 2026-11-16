if ($PROFILE) {
    $profilePath = $PROFILE
    # Backup the existing profile if it exists
    if (Test-Path $profilePath) {
        $backupPath = "$profilePath.bak"
        Copy-Item -Path $profilePath -Destination $backupPath -Force
        Write-Host "Backup of existing profile created at: $backupPath"
    }
} else {
    $profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
}

# Ensure the destination folder exists
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    Write-Host "Creating directory: $profileDir"
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Copy the new profile to the profile path
Write-Host "Copying PowerShell profile to: $profilePath"
Copy-Item -Path "Microsoft.PowerShell_profile.ps1" -Destination $profilePath -Force

Write-Host "Profile deployed. Run '. `$PROFILE' to load the new profile in the current session."
