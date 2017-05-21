<#
 .Synopsis
 Testet die allgemeine Funktionsfähigkeit des Moduls
#>

Import-Module -Name PoshObjectsLab -Force

$DC.ServerList.Clear()
$S1 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
$S1.Start()
$DC.ServerList

Start-Sleep -Seconds 3

$S1.GetCost()

Get-TotalCost | Format-Table -View Currency