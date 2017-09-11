
# Some simple test for running directly
using Module .\2.0\PoshObjectsLab.psm1

Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force

$JSonPath = ".\StartupCompany.json"
# type $JSonPath | ConvertFrom-Json
$DC = [DataCenter]::new($JSonPath)

$S1 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Os/2" -CostPerHour 1000
Start-Sleep -Seconds 10
$S1.GetCost()
