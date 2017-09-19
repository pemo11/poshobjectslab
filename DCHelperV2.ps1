<#
 .Synopsis
 Contains serveral helper functions for using a Data center
#>

<#
 .Synopsis
 Adds a new server to the DC
#>
function Add-Server
{
    param([ServerSize]$Size="Small")
    $Global:DC.AddServer($Size)
}

<#
 .Synopsis
 Starts a server
#>
function Start-Server
{
    param([Parameter(Mandatory=$true)][Int]$ServerId)
    $Server = $Global:DC.ServerList.Where{$_.Id -eq $ServerId}
    if ($Server -ne $null)
    {
        $Server.Start()
        Write-Verbose ($MsgTable.ServerStartedMsg -f $ServerId)
    }
    else {
        Write-Verbose ($MsgTable.ServerNotFoundMsg -f $ServerId)
    }
}

<#
 .Synopsis
 Starts a server
#>
function Stop-Server
{
    param([Parameter(Mandatory=$true)][Int]$ServerId)
    $Server = $Global:DC.ServerList.Where{$_.Id -eq $ServerId}
    if ($Server -ne $null)
    {
        $Server.Stop()
        Write-Verbose ($MsgTable.ServerStoppedMsg -f $ServerId)
    }
    else {
        Write-Verbose ($MsgTable.ServerNotFoundMsg -f $ServerId)
    }
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
        Write-Verbose ($MsgTable.ServerRemovedMsg -f $ServerId)
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
        Write-Verbose ($MsgTable.ServerRemovedMsg -f $Server.Id)
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
.SYNOPSIS
Initialize a new Startup-Company
.DESCRIPTION
Each DataCenter is run by a Startup-Company
#>

function New-DCStartup
{
    param([Parameter(Mandatory=$true)][String]$ConfigPath, 
          [String]$ServerConfigPath)
    $Global:DC = [DataCenter]::new($ConfigPath, $ServerConfigPath)
}

<#
.SYNOPSIS
Gets the status of a Data Center
#>
function Get-DCStatus
{
    [PSCustomObject]@{
        CompanyName = $Global:DC.CompanyName
        ServerTotal = $Global:DC.ServerList.Count 
        ServerRunning = ($Global:DC.ServerList.Where{$_.State -eq "Running"}).Count
        ServerStopped = ($Global:DC.ServerList.Where{$_.State -eq "Stopped"}).Count
        TotalCost = Get-TotalCost
    }
}
