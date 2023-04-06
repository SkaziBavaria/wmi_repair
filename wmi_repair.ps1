# Enable error reporting and set failure flag to false
$ErrorActionPreference = "Stop"
$failed = $false

# Check for administrative privileges
Write-Host "Checking for administrative privileges..."
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Failure: Administrative privileges required. Please run this script as an administrator."
    $failed = $true
    exit 1
}
Write-Host "Success: Administrative privileges confirmed."

# Stop WMI service
Write-Host "Stopping WMI service..."
Stop-Service -Name winmgmt -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "WMI service stopped."
} else {
    Write-Host "Failure: Could not stop WMI service."
    $failed = $true
    Write-Host "Trying to force stop WMI service..."
    try {
        Stop-Process -Name wmiprvse -Force
        Write-Host "WMI service force stopped."
    } catch {
        Write-Host "Failure: Could not force stop WMI service."
        $failed = $true
    }
}

# Re-register WMI components
if (-NOT $failed) {
    Write-Host "Repairing WMI components..."
    $components = Get-ChildItem -Path "$env:SystemRoot\system32\wbem" -Filter "*.mof" -Recurse
    foreach ($component in $components) {
        Write-Host "Re-registering $($component.Name)..."
        try {
            mofcomp $component.FullName
        } catch {
            Write-Host "Failure: Could not re-register $($component.Name)."
            $failed = $true
        }
    }
    if (-NOT $failed) {
        Write-Host "Success: WMI components re-registered."
    }
}

# Start WMI service
Write-Host "Starting WMI service..."
Start-Service -Name winmgmt -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "WMI service started."
} else {
    Write-Host "Failure: Could not start WMI service."
    $failed = $true
}

# Check if anything failed
if ($failed) {
    Write-Host "One or more failures occurred during the repair process."
    exit 1
} else {
    Write-Host "WMI repair completed successfully."
    exit 0
}
