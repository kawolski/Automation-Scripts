<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (${%~f0} | Out-String)"
pause
exit /b
#>

# --- EVERYTHING BELOW IS PURE POWERSHELL ---
$Host.UI.RawUI.ForegroundColor = 'DarkYellow'
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

Write-Host ">> ENCRYPTION AT HOST <<" -ForegroundColor Yellow

# Your logic

# Azure VM EncryptionAtHost Utility (PowerShell Version)
# Dummy Mode for Enable Option (only echo commands)
# Azure VM EncryptionAtHost Utility (PowerShell Version) - Version 3 Final
# Requires Az CLI logged in
function Show-Menu {
    Clear-Host
    Write-Host "============================================="
    Write-Host " Azure VM EncryptionAtHost Utility"
    Write-Host "============================================="
    Write-Host "1. Check EncryptionAtHost status for all VMs"
    Write-Host "2. Enable EncryptionAtHost on specific VMs"
    Write-Host "3. Exit"
    Write-Host "============================================="
}

# function Check-EncryptionStatus {
#     Write-Host "`nFetching VM EncryptionAtHost status...`n"
#     az vm list --query "[].{VM:name, RG:resourceGroup, EncryptionAtHost:securityProfile.encryptionAtHost}" -o table
#     Pause
# }

function Check-EncryptionStatus {
    Write-Host "`nFetching VM EncryptionAtHost status...`n"

    # Get VMs from Azure
    $vms = az vm list --query "[].{VM:name, EncryptionAtHost:securityProfile.encryptionAtHost}" -o json | ConvertFrom-Json

    if (-not $vms) {
        Write-Host "No VMs found!"
        Pause
        return
    }

    # Calculate max VM name length
    $maxVMLength = ($vms | ForEach-Object { $_.VM.Length } | Measure-Object -Maximum).Maximum
    if ($maxVMLength -lt 13) { $maxVMLength = 13 }  # Minimum width for header

    # Print header
    "{0,-$maxVMLength}   {1,-18}" -f "VM", "EncryptionAtHost"
    "{0,-$maxVMLength}   {1,-18}" -f ("".PadRight($maxVMLength, "-")), ("".PadRight(18, "-"))

    # Print VM rows
    foreach ($vm in $vms) {
        $status = if ($vm.EncryptionAtHost) { "True" } else { "------" }
        "{0,-$maxVMLength}   {1,-18}" -f $vm.VM, $status
    }

    Pause
}

function Enable-Encryption {
    Write-Host "`nFetching VM list...`n"
    $vms = az vm list --query "[].{VM:name, RG:resourceGroup, EncryptionAtHost:securityProfile.encryptionAtHost}" -o json | ConvertFrom-Json

    if (-not $vms) {
        Write-Host "No VMs found!"
        Pause
        return
    }

    # Show numbered VM list without RG
    $maxVMLength = ($vms | ForEach-Object { $_.VM.Length } | Measure-Object -Maximum).Maximum
    if ($maxVMLength -lt 13) { $maxVMLength = 13 }  # minimum width

    Write-Host ("No.   {0,-$maxVMLength}   {1,-18}" -f "VM", "EncryptionAtHost")
    Write-Host ("---   {0,-$maxVMLength}   {1,-18}" -f ("-"*$maxVMLength), ("-"*18))

    for ($i = 0; $i -lt $vms.Count; $i++) {
        $status = if ($vms[$i].EncryptionAtHost) { "True" } else { "------" }
        Write-Host ("{0,-3}   {1,-$maxVMLength}   {2,-18}" -f ($i+1), $vms[$i].VM, $status)
    }

    $selection = Read-Host "`nEnter VM numbers separated by comma (e.g., 1,3,5)"
    $indexes = $selection -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    foreach ($index in $indexes) {
        $vm = $vms[$index - 1]
        if ($vm) {
            if ($vm.EncryptionAtHost -eq $true) {
                Write-Host "`nVM $($vm.VM) is already enabled. Skipping..."
                continue
            }

            Write-Host "`nDeallocating VM: $($vm.VM)..."
            az vm deallocate --resource-group $vm.RG --name $vm.VM

            Write-Host "Enabling EncryptionAtHost for VM: $($vm.VM)..."
            az vm update --resource-group $vm.RG --name $vm.VM --set securityProfile.encryptionAtHost=true

            Write-Host "Starting VM: $($vm.VM)..."
            az vm start --resource-group $vm.RG --name $vm.VM

            Write-Host "VM $($vm.VM) EncryptionAtHost enabled successfully!"
        }
    }
    Pause
}


# Main Loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1/2/3)"

    switch ($choice) {
        "1" { Check-EncryptionStatus }
        "2" { Enable-Encryption }
        "3" { Write-Host "Exiting..."; exit }
        default { Write-Host "Invalid choice. Please try again."; Pause }
    }
}
