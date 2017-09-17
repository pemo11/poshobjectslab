
# Setups a Data Center
using Module .\2.0\PoshObjectsLab.psm1

Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force

$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath .\StartupCompany.json
$ConfigPath = ".\StartupCompany.json"
# type $JSonPath | ConvertFrom-Json
$ServerConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "ServerConfig.json"
$DC = New-DCStartup -ConfigPath $ConfigPath -ServerConfigPath $ServerConfigPath 
$DC

# $DC = [DataCenter]::new($ConfigPath)

# $S1 = Add-Server -Size Medium # -MemoryGB 1 -CpuCount 1 -ServerOS "Os/2" -CostPerHour 1000
Start-Sleep -Seconds 6
$DC.ServerList[0].GetCost()

Get-TotalCost

