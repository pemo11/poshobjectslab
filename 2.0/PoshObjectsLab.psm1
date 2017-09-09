<#
 .Synopsis
 Posh Objects Lab 
 .Description
 A very tiny data center simulation with class based objects - Version 1
 .Notes
 Last Update: 21/05/2017
#>

Set-StrictMode -Version Latest

Import-LocalizedData -BindingVariable MsgTable -FileName PoshObjectsLabText.psd1

$Script:CostPerCPUHour = 0.2
$Script:CostPerGBHour = 0.1

# Different event categories
enum EventCategory
{
    Information
    Warning
    Error
}

# Represents a single log entry
class LogEvent
{
    [Int]$EventId
    [EventCategory]$Category
    [DateTime]$TimeCreated
    [String]$Message

    LogEvent([Int]$Id, [String]$LogCategory, [String]$LogMessage)
    {
        $this.Category = $LogCategory
        $this.Message = $LogMessage
        $this.EventId = $Id
        $this.TimeCreated = (Get-Date)
    }
}

# Represents the different server states
Enum ServerState
{
    Running
    Stopped
}

# Represents a single server
class Server
{
  [Int]$Id
  [String]$Name
  [DateTime]$StartTime
  [ServerState]$Status
  [Long]$MemoryGB
  [Byte]$CPUCount
  [String]$ServerOS
  [System.Timers.Timer]$Timer
  [System.Collections.Generic.List[LogEvent]]$Eventlog

  # Starts this server
  [void]Start()
  {
    $this.StartTime = Get-Date
    $this.Status = [ServerState]::Running
    $this.Timer = New-Object -TypeName System.Timers.Timer
    $this.Timer.Interval = 1000
    $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
    # Event vorsichtshalber entfernen
    Unregister-Event -SourceIdentifier "ServerEvent$($this.Id)" -Force -ErrorAction Ignore
    Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -SourceIdentifier "ServerEvent$($this.Id)" `
     -Action {
        $EventLog = $Event.MessageData
        $Eventlog.Add([LogEvent]::new($Eventlog.Count+1, [EventCategory]::Information, "Just a silly remark"))        
    } -MessageData $this.Eventlog
    $this.Timer.Start()
  }

  # Stops this server
  [void]Stop()
  {
    $this.Status = [ServerState]::Stopped
    $this.Timer.Stop()
  }

  # Get the running time of a server
  [TimeSpan]GetRunningTime()
  {
    return ((Get-Date) - $this.StartTime)
  }

  # Gets the current cost of this server
  [Double]GetCost()
  {
      $RunningHours = ((Get-Date) - $this.StartTime).TotalHours
      return $Script:CostPerCPUHour * $RunningHours + $Script:CostPerGBHour * $RunningHours
  }

}

# Represents a customer order
class CustomerOrder
{
    [Int]$Id
    [DateTime]$OrderDate
    [String]$CustomerName
    [Double]$RessourceAmount
    [bool]$Completed

    CustomerId([Int]$Id)
    {
        $this.Order = $Id
    }
}

# Represents account details
class Accounting
{
    [Double]$Capital

    Accounting([Double]$Capital)
    {
        $this.Capital = $Capital
    }
    
}

# Represents the whole Data Center
class DataCenter
{
    # A unique Id for the DC
    [int]$Id

    # The name of the fictious company
    [String]$CompanyName

    # Contains the Starttime of the DC
    [DateTime]$StartTime 

    # Contains all the servers
    [System.Collections.Generic.List[Server]]$ServerList

    # Contains all the orders
    [System.Collections.Generic.List[Server]]$OrderList
        
    # A time generates events in the DC
    [System.Timers.Timer]$Timer

    # Container for all log messages
    [System.Collections.Generic.List[LogEvent]]$Eventlog
    
    # Initializes the Data Center
    DCInit()
    {
        $this.Id = 1
        $this.StartTime = Get-Date
        $this.Timer = [System.Timers.Timer]::new()
        $this.Timer.Interval = 5000
        $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
        # Event vorsichtshalber entfernen
        Unregister-Event -SourceIdentifier "DCTimer$($this.Id)" -Force -ErrorAction Ignore
        Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -SourceIdentifier "DCTimer$($this.Id)" `
         -Action {
            # Generate new customer order
            if ((Get-Random -Maximum 10) -gt 5)
            {
                $Order = [CustomerOrder]::new($this.OrderList + 1)
                $Order.OrderDate = Get-Date
                $Order.CustomerName = "ALFKI", "ANATR", "ANTON" | Get-Random
                $Order.RessourceAmount = 1..100 | Get-Random
                $this.OrderList.Add($Order)
                $EventLog = $Event.MessageData
                $Eventlog.Add([LogEvent]::new($Eventlog.Count+1, [EventCategory]::Information, "New Order placed"))        
                }
        } -MessageData $this.Eventlog
        $this.Timer.Start()
    }

    # Constructor of the class
    DataCenter([String]$InitialConfig)
    {
        $this.Serverlist = New-Object -TypeName System.Collections.Generic.List[Server]
        $InitialConfig | ConvertFrom-Json | ForEach-Object {
            $this.CompanyName = $_.CompanyName
            $this.Accounting = [Accounting]::new($_.InitialCapital)
            foreach($Server in $_.Hardware)
            {
                $Server = [Server]::new()
                $Server.Name = $_.Name
                $Server.ServerOS = $_.OS
                $Server.TCO = $_.TCO
                $Server.Size = $_.ServerService
                $Server.MemoryGB = $_.GB
                $Server.CpuCount = $_.CPUCount
                # Take Server price into account
                $this.Accounting.Capital -= $_.InitialCost  
                $this.Serverlist.Add($Server)
            }
        }
    }

    [Server]AddServer([Int]$MemoryGB, [Int]$CpuCount, [String]$ServerOS)
    {
        $NewServer = [Server]::new()
        $NewServer.Id = $this.ServerList.Count + 1
        $NewServer.MemoryGB = $MemoryGB
        $NewServer.CPUCount = $CpuCount
        $NewServer.ServerOS = $ServerOS
        $this.ServerList.Add($NewServer)
        return $NewServer
    }

    [void]RemoveServer([Server]$Server)
    {
        $this.ServerList.Remove($Server)
    }

    [void]RemoveServer([Int]$ServerId)
    {
        $Server = $this.ServerList.Where{$_.Id -eq $ServerId}
        $this.ServerList.Remove($Server)
    }

}

# Represents the cost for one Server
class ServerCost
{
    [Int]$ServerId
    [DateTime]$StartTime
    [double]$Cost

    ServerCost([Server]$Server)
    {
        $this.ServerId = $Server.Id
        $this.StartTime = $Server.StartTime
        $this.Cost = $Server.GetCost()
    }   
}

<#
 .Synopsis
 Adds a new server
#>
function Add-Server
{
    param([Int]$MemoryGB, [Int]$CpuCount, [String]$ServerOS)
    $Global:DC.AddServer($MemoryGB, $CpuCount, $ServerOS)
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
 Removes a server
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
 Gets all the existing server
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
    $Global:DC.ServerList | ForEach-Object {
        [ServerCost]::new($_)
    }
}

<#
 .Synopsis
 Get all orders
#>
function Get-Order
{
    $Global:DC.OrderList
}

$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath .\StartupCompany.json
$Global:DC = [DataCenter]::new($ConfigPath)
Write-Verbose $MsgTable.InitializedMsg -Verbose


# Ab hier neue Funktionalitäten der Version 2.0

<#
.SYNOPSIS
Initialize a new Startup-Company
.DESCRIPTION
Each DataCenter is run by a Startup-Company
#>
Function New-Startup
{
    path([String]$ConfigPath)
    $Global:DC = [DataCenter]::new($ConfigPath)
}
Function New-Server
{

}

Export-ModuleMember -Function  Add-Server, Remove-Server, Remove-ServerbyId, Get-Server, Get-TotalCost 
