<#
 .Synopsis
 Contains serveral helper functions for using a Data center
#>

<#
 .Synopsis
 Adds a new server
#>
function Add-Server
{
    param([ServerSize]$Size="Small", [Int]$MemoryGB, [Int]$CpuCount, [String]$ServerOS, [Double]$CostPerHour)
    $Global:DC.AddServer($Size, $MemoryGB, $CpuCount, $ServerOS, $CostPerHour)
}

<#
 .Synopsis
 Removes a server by Server Id
#>
function Remove-ServerById
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Int]$ServerId)
    $RemoveServer = $Global:DC.ServerList | Where-Object Id -eq $ServerId
    if ($PSCmdlet.ShouldProcess(($MsgTable.RemoveServerMsg -f $ServerId), "From the loop"))
    {
        $Global:DC.RemoveServer($RemoveServer)
        Write-Verbose "Server ($MsgTable.ServerRemovedMsg -f $ServerId)."
    }
}

<#
 .Synopsis
 Removes a server by a server object
#>
function Remove-Server
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Server]$Server)
    if ($PSCmdlet.ShouldProcess(($MsgTable.RemoveServerMsg -f $Server.Id), "From the loop"))
    {
        $Global:DC.RemoveServer($Server)
        Write-Verbose "Server ($MsgTable.ServerRemovedMsg -f $Server.Id)."
    }
}

<#
 .Synopsis
 Gets all the existing servers
#>
function Get-Server
{
    return $Global:DC.ServerList
}

<#
 .Synopsis
 Gets the total cost of all servers
#>
function Get-TotalCost
{
    $ServerCost = 0
    $Global:DC.ServerList | ForEach-Object {
        $ServerCost += [ServerCost]::new($_).Cost
    }
    return $ServerCost
}

<#
.SYNOPSIS
Gets the cost of one server
#>
function Get-ServerCost
{
    param([Server]$Server)
    return [ServerCost]::new($Server).Cost
}
<#
 .Synopsis
 Get all orders for the DC
#>
function Get-Order
{
    $Global:DC.OrderList
}

<#
.SYNOPSIS
Initialize a new Startup-Company
.DESCRIPTION
Each DataCenter is run by a Startup-Company
#>

function New-DCStartup
{
    param([Parameter(Mandatory=$true)][String]$ConfigPath, 
          [String]$ServerConfigPath)
    if (Test-Path -Path $ServerConfigPath)
    {
        Type -Path $ServerConfigPath | ConvertFrom-Json | ForEach-Object {
        $Global:ServerConfig += { $_.Size = [PSCustomObject]{
                                              CPUCount = $_.Config.CPUCount
                                              RAMB = $_.Config.RAMGB
                                              OS = $_.Config.OS
                                            }
                                }
        }
    }
    return [DataCenter]::new($ConfigPath)
}

