<#
 .Synopsis
 Posh Objects Lab 
 .Description
 A very tiny data center simulation with class based objects - Version 2
 The current version supports server configuration with Json files
 .Notes
 Last Update: 18/09/2017
#>

Set-StrictMode -Version Latest

Import-LocalizedData -BindingVariable MsgTable -FileName PoshObjectsLabText.psd1

# Write-Verbose $MsgTable.InitializedMsg -Verbose

# Load ps1 file with helper functions that should be exported
$HelperPath = Join-Path -Path $PSScriptRoot -ChildPath ..
$HelperPath = Join-Path -Path $HelperPath -ChildPath .\DCHelperV2.ps1
.$HelperPath

# Stores the server size configuration from a Json config file
$Script:ServerConfig = $null

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

# Represents the different server status states
Enum ServerStatus
{
    Green
    Yellow
    Orange
    Red
}

# Represents the general size of the server
Enum ServerSize
{
    Small
    Medium
    Big
}

# Represents a single server
class Server
{
  [Int]$Id
  [String]$Name
  [DateTime]$StartTime
  [ServerState]$State
  [ServerStatus]$Status
  [ServerSize]$Size 
  [Long]$MemoryGB
  [Byte]$CPUCount
  [String]$ServerOS
  [Double]$CostPerHour
  [Double]$TotalCost
  [Int]$RunningTimeSeconds
  [System.Timers.Timer]$Timer
  [System.Collections.Generic.List[LogEvent]]$Eventlog

  # Constructor with Size and Id argument - Id is important for timer event registration
  Server([ServerSize]$Size, [Int]$Id)
  {
      $this.Size = $Size
      $this.Id = $Id
      $this.MemoryGB = $Script:ServerConfig.$Size.RAMGB
      $this.CPUCount = $Script:ServerConfig.$Size.CPUCount
      $this.ServerOS = $Script:ServerConfig.$Size.OS
      $this.CostPerHour = $Script:ServerConfig.$Size.CostPerHour
      $this.State = [ServerState]::Stopped # Alternative "Stopped"
      $this.Status = [ServerStatus]::Green # Alternative "Green"
  }

  # Starts this server
  [void]Start()
  {
    $this.StartTime = Get-Date
    $this.State = [ServerState]::Running
    $this.Timer = New-Object -TypeName System.Timers.Timer
    $this.Timer.Interval = 5000
    $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
    # Event vorsichtshalber entfernen
    Unregister-Event -SourceIdentifier "ServerEvent$($this.Id)" -Force -ErrorAction Ignore
    Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -SourceIdentifier "ServerEvent$($this.Id)" `
     -Action {
        $EventLog = $Event.MessageData.Eventlog
        $Eventlog.Add([LogEvent]::new($Eventlog.Count+1, [EventCategory]::Information, "Server-State: " + $Event.MessageData.State +
         " Server-Status: " + $Event.MessageData.Status))
        # Calculate current costs  -  only if the server is running
        if ($Event.MessageData.State -eq [ServerState]::Running)
        {
            $Event.MessageData.RunningTimeSeconds += 5
            $Event.MessageData.TotalCost += $Event.MessageData.CostPerHour / 3600 * 5
        }        
    } -MessageData $this
    $this.Timer.Start()
  }

  # Stops this server
  [void]Stop()
  {
    $this.State = [ServerState]::Stopped
    $this.Timer.Stop()
  }

  # Get the running time of a server as a TimeSpan
  [TimeSpan]GetRunningTime()
  {
    return [TimeSpan]::new(0, 0, $this.RunningTimeSeconds)
  }

  # Gets the current cost of this server
  [Double]GetCost()
  {
      $RunningHours = $this.RunningTimeSeconds / 3600
      # 0.1 damit nicht immer 0 herauskommt
      return ($this:CostPerCPUHour * $RunningHours + 0.1)
  }
}

# Represents the whole Data Center
class DataCenter
{
    # A unique Id for the DC
    [Guid]$Id

    # The name of the fictious company
    [String]$CompanyName
    
    # The Starttime of the DC
    [DateTime]$StartTime 

    # Contains all the servers of the DC
    [System.Collections.Generic.List[Server]]$ServerList

    # A timer that generates events in the DC
    [System.Timers.Timer]$Timer

    # Container for all log messages
    [System.Collections.Generic.List[LogEvent]]$Eventlog
    
    # Initializes the Data Center
    [void]DCInit([String]$ServerConfigPath)
    {
        # Initialize the server sizes with configuration date
        $Script:ServerConfig = Get-Content -Path $ServerConfigPath | ConvertFrom-Json 
        # the DC-Id is a GUID
        $this.Id = (New-Guid).Guid
        # Set the start time of the DC
        $this.StartTime = Get-Date
        # Timer should tick every 5 seconds
        $this.Timer = [System.Timers.Timer]::new()
        $this.Timer.Interval = 5000
        # Initialize eventlog property with a new generic list for LogEvent objects
        $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
        # Event vorsichtshalber entfernen
        Unregister-Event -SourceIdentifier "DCTimer$($this.Id)" -Force -ErrorAction Ignore
        Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -SourceIdentifier "DCTimer$($this.Id)" `
         -Action {
            $EventLog = $Event.MessageData.EventLog
            $DCStatus = ($Event.MessageData.ServerList | Group-Object -Property Status | ForEach-Object {
                "Status: $($_.Name) - Count: $($_.Count)" 
            })
            $Eventlog.Add([LogEvent]::new($Eventlog.Count+1, [EventCategory]::Information, $DCStatus))        
        } -MessageData $this
        $this.Timer.Start()
    }

    # Constructor of the class
    DataCenter([String]$CompanyConfigPath, [String]$ServerConfigPath)
    {
        $this.DCInit($ServerConfigPath)
        # Initialize the server list
        $this.Serverlist = New-Object -TypeName System.Collections.Generic.List[Server]
        # Read company configuration and server data from json file
        Get-Content -Path $CompanyConfigPath | ConvertFrom-Json | ForEach-Object {
            $this.CompanyName = $_.CompanyName
            # Initialize the servers for the company
            foreach($HardwareData in $_.Hardware)
            {
                $Server = [Server]::new($HardwareData.ServerSize, $this.ServerList.Count + 1)
                $Server.Name = $HardwareData.Name
                $this.Serverlist.Add($Server)
            }
        }
    }

    # AddServer method - returns the new server object
    [Server]AddServer([ServerSize]$Size)
    {
        $NewServer = [Server]::new($Size, $this.ServerList.Count + 1)
        $this.ServerList.Add($NewServer)
        Write-Verbose ($Script:MsgTable.ServerAdded -f $Size)
        return $NewServer
    }

    # Remove Server method
    [void]RemoveServer([Server]$Server)
    {
        $this.ServerList.Remove($Server)
        Write-Verbose ($Script:MsgTable.ServerRemoved -f $Server)
    }

    # Remove Server method
    [void]RemoveServer([Int]$ServerId)
    {
        $Server = $this.ServerList.Where{$_.Id -eq $ServerId}
        if ($Server -ne $null)
        {
            $this.ServerList.Remove($Server)
            Write-Verbose ($Script:MsgTable.ServerRemoved -f $Server)
        }
        else {
            throw ($Script:MsgTable.ServerNotFound -f $ServerId)
        }
    }
} # End DC class definition

# Represents the cost for one Server
class ServerCost
{
    [Int]$ServerId
    [DateTime]$StartTime
    [Double]$Cost

    # class constructor expects a server object
    ServerCost([Server]$Server)
    {
        # Initialize variables
        $this.ServerId = $Server.Id
        $this.StartTime = $Server.StartTime
        $this.Cost = $Server.GetCost()
    }   
} # End ServerCost class definition

Export-ModuleMember -Function  New-DCStartup,
Add-Server, 
Start-Server,
Stop-Server,
Remove-Server, 
Remove-ServerById, 
Get-Server,
Get-ServerCost,
Get-TotalCost
 