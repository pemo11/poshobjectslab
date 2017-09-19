
# Setups a Data Center
using Module .\2.0\PoshObjectsLab.psm1

Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force

$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath .\StartupCompany.json
# $ConfigPath = ".\StartupCompany.json"
# type $JSonPath | ConvertFrom-Json
$ServerConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "ServerConfig.json"
New-DCStartup -ConfigPath $ConfigPath -ServerConfigPath $ServerConfigPath 

$DC

$DC.ServerList

# Start first server
Start-Server -ServerId 1
Start-Sleep -Seconds 6

$DC.ServerList.GetCost()

# Start second server
Start-Server -ServerId 2
Start-Sleep -Seconds 6

$DC.ServerList.GetCost()

Get-TotalCost

Get-DCStatus