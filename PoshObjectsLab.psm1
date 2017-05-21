<#
 .Synopsis
 Posh Objects Lab 
 .Description
 A very tiny data center simulation with class based objects - Version 1
 .Notes
 Last Update: 19/05/2017
#>

Set-StrictMode -Version Latest

Import-LocalizedData -BindingVariable MsgTable -FileName PoshObjectsLabText.psd1

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
  [Double]$CostPerSecond = 0.05
  [System.Timers.Timer]$Timer
  [System.Collections.Generic.List[LogEvent]]$Eventlog

  # Starts this server
  [void]Start()
  {
    $this.StartTime = Get-Date
    $this.Status = [ServerState]::Running
    $this.Timer = New-Object -TypeName System.Timers.Timer
    $this.Timer.Interval = 5000
    $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
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
    return $this.GetRunningTime().TotalSeconds * $this.CostPerSecond
  }

}

# Represents the whole Data Center
class DataCenter
{
    # Contains all the servers
    [System.Collections.Generic.List[Server]]$ServerList
 
    # Constructor of the class
    DataCenter([Int]$InitialCount)
    {
        $this.Serverlist = New-Object -TypeName System.Collections.Generic.List[Server]
        for($i = 1; $i -le $InitialCount; $i++)
        {
            $NewServer = [Server]::new()
            $NewServer.Id = $i
            $NewServer.MemoryGB = 1
            $NewServer.ServerOS = "Windows Server 2012 R2"
            $NewServer.CPUCount = 2
            $NewServer.Status = [ServerState]::Stopped
            $this.Serverlist.Add($NewServer)
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

$Global:DC = [DataCenter]::new(0)
Write-Verbose $MsgTable.InitializedMsg -Verbose

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

Export-ModuleMember -Function  Add-Server, Remove-Server, Remove-ServerbyId, Get-Server
