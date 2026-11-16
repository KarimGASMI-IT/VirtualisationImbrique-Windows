#Requires -RunAsAdministrator

Write-Host "=== Preparation Windows pour virtualisation ===" -ForegroundColor Cyan

# Fonctionnalites Windows a activer
$features = @(
    "Microsoft-Hyper-V-All",              # Hyper-V
    "VirtualMachinePlatform",             # Plateforme de machine virtuelle
    "HypervisorPlatform",                 # Plateforme hyperviseur Windows
    "Containers-DisposableClientVM",      # Sandbox Windows
    "Microsoft-Windows-Subsystem-Linux"   # WSL
)

Write-Host "`n[1/5] Activation des fonctionnalites Windows..." -ForegroundColor Yellow

foreach ($feature in $features) {
    Write-Host " -> $feature"
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction SilentlyContinue
}

# Activation de l'integrite de la memoire / HVCI
Write-Host "`n[2/5] Activation de l'integrite de la memoire (HVCI)..." -ForegroundColor Yellow

$HVCIPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
New-Item -Path $HVCIPath -Force | Out-Null
New-ItemProperty -Path $HVCIPath -Name "Enabled" -Value 1 -PropertyType DWord -Force | Out-Null

# Activation de VBS / Device Guard
Write-Host "`n[3/5] Activation de VBS / Device Guard..." -ForegroundColor Yellow

$DeviceGuardPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
New-Item -Path $DeviceGuardPath -Force | Out-Null
New-ItemProperty -Path $DeviceGuardPath -Name "EnableVirtualizationBasedSecurity" -Value 1 -PropertyType DWord -Force | Out-Null

# Activation de Credential Guard
Write-Host "`n[4/5] Activation de Credential Guard..." -ForegroundColor Yellow

$LsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
New-ItemProperty -Path $LsaPath -Name "LsaCfgFlags" -Value 1 -PropertyType DWord -Force | Out-Null

$CredentialGuardPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard"
New-Item -Path $CredentialGuardPath -Force | Out-Null
New-ItemProperty -Path $CredentialGuardPath -Name "Enabled" -Value 1 -PropertyType DWord -Force | Out-Null

# Activation du lancement de l'hyperviseur Windows
Write-Host "`n[5/5] Activation du lancement de l'hyperviseur Windows..." -ForegroundColor Yellow

bcdedit /set "{current}" hypervisorlaunchtype auto

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Configuration terminee." -ForegroundColor Green
Write-Host "Hyper-V, VBS, HVCI et Credential Guard ont ete configures pour etre actives." -ForegroundColor Green
Write-Host "Un REDEMARRAGE est necessaire." -ForegroundColor Green
Write-Host "========================================"

$restart = Read-Host "Redemarrer maintenant ? (O/N)"

if ($restart -match '^[OoYy]$') {
    Restart-Computer -Force
}