<#
 .Synopsis
 Posh Objects Lab 
 .Description
 A very tiny data center simulation with class based objects - Version 3
 The current version also supports billing and running a profitable data center
 .Notes
 Last Update: 18/09/2017
#>

Set-StrictMode -Version Latest

Import-LocalizedData -BindingVariable MsgTable -FileName PoshObjectsLabText.psd1

# Write-Verbose $MsgTable.InitializedMsg -Verbose

# Load ps1 file with helper functions that should be exported
$HelperPath = Join-Path -Path $PSScriptRoot -ChildPath ..
$HelperPath = Join-Path -Path $HelperPath -ChildPath .\DCHelper.ps1
.$HelperPath

# Stores the server size configuration from a Json config file
$Global:ServerConfigList = @{}

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
  [Double]$CostPerHour = 1
  [Int]$RunningTimeSecond
  [System.Timers.Timer]$Timer
  [System.Collections.Generic.List[LogEvent]]$Eventlog

  # Constructor with Size argument
  Server([ServerSize]$Size)
  {
  # TODO: Server config
  }

  # Starts this server
  [void]Start()
  {
    $this.StartTime = Get-Date
    $this.Status = [ServerState]::Running
    $this.Timer = New-Object -TypeName System.Timers.Timer
    $this.Timer.Interval = 5000
    $this.Eventlog = New-Object -TypeName System.Collections.Generic.List[LogEvent]
    # Event vorsichtshalber entfernen
    Unregister-Event -SourceIdentifier "ServerEvent$($this.Id)" -Force -ErrorAction Ignore
    Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -SourceIdentifier "ServerEvent$($this.Id)" `
     -Action {
        $EventLog = $Event.MessageData
        $Eventlog.Add([LogEvent]::new($Eventlog.Count+1, [EventCategory]::Information, "Server-State: " + $this.ServerState +
         " Server-Status: " + $this.ServerStatus))
        # Calculate current costs  - the server is running anyway
        if ($this.State -eq "Running")
        {
            $this.RunningTimeSecond += 5
            $this.TotalCost += $this.CostPerHour / 3600 * 5
        }        
    } -MessageData $this.Eventlog
    $this.Timer.Start()
  }

  # Stops this server
  [void]Stop()
  {
    $this.Status = [ServerState]::Stopped
    $this.Timer.Stop()
  }

  # Get the running time of a server as a TimeSpan
  [TimeSpan]GetRunningTime()
  {
    return [TimeSpan]::new(0,0, $this.RunningTimeSecond)
  }

  # Gets the current cost of this server
  [Double]GetCost()
  {
      $RunningHours = $this.RunningTimeSecond / 3600
      # 0.1 damit nicht immer 0 herauskommt
      return ($this:CostPerCPUHour * $RunningHours + 0.1)
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

    # Constructor expects an Id
    CustomerId([Int]$Id)
    {
        $this.Order = $Id
    }

}

# Represents account details
class Accounting
{
    [Double]$Capital

    # Constructor expects the initial capital
    Accounting([Double]$Capital)
    {
        $this.Capital = $Capital
    }
    
}

# Represents the whole Data Center
class DataCenter
{
    # A unique Id for the DC
    [Guid]$Id

    # The name of the fictious company
    [String]$CompanyName
    
    # The Account Data for billing
    [Accounting]$Account
    
    # The Starttime of the DC
    [DateTime]$StartTime 

    # Contains all the servers of the DC
    [System.Collections.Generic.List[Server]]$ServerList

    # Contains all the orders
    [System.Collections.Generic.List[Server]]$OrderList
        
    # A timer that generates events in the DC
    [System.Timers.Timer]$Timer

    # Container for all log messages
    [System.Collections.Generic.List[LogEvent]]$Eventlog
    
    # Initializes the Data Center
    [void]DCInit()
    {
        $this.Id = (New-Guid).Guid
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
            # Generate new customer order eventually
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
    DataCenter([String]$CompanyConfigPath, [String]$ServerConfigPath)
    {
        $this.DCInit($ServerConfigPath)
        # Store reference of this instance in global variable
        $this.Serverlist = New-Object -TypeName System.Collections.Generic.List[Server]
        # Read configuration and server data from json file
        Get-Content -Path $CompanyConfigPath | ConvertFrom-Json | ForEach-Object {
            $this.CompanyName = $_.CompanyName
            $this.Account = [Accounting]::new($_.InitialCapital)
            foreach($HwData in $_.Hardware)
            {
                $Server = [Server]::new($HwData.ServerSize)
                $Server.Name = $HwData.Name
                # Take Server price into account
                $this.Account.Capital -= $HwData.InitialCost  
                $this.Serverlist.Add($Server)
            }
        }
    }

    # AddServer method - returns the new server object
    [Server]AddServer([ServerSize]$Size)
    {
        $ServerConfig = $ServerConfigList.$Size
        $NewServer = [Server]::new()
        $NewServer.Id = $this.ServerList.Count + 1
        $NewServer.Size = $Size
        $NewServer.MemoryGB = $ServerConfig.MemoryGB
        $NewServer.CPUCount = $ServerConfig.CpuCount
        $NewServer.ServerOS = $ServerConfig.OS
        $NewServer.CostPerHour = $ServerConfig.CostPerHour
        $this.ServerList.Add($NewServer)
        return $NewServer
    }

    # Remove Server method
    [void]RemoveServer([Server]$Server)
    {
        $this.ServerList.Remove($Server)
    }

    # Remove Server method
    [void]RemoveServer([Int]$ServerId)
    {
        $Server = $this.ServerList.Where{$_.Id -eq $ServerId}
        if ($Server -ne $null)
        {
            $this.ServerList.Remove($Server)
        }
        else {
            throw "Server mit Id=$ServerId gibt es nicht."
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
Remove-Server, 
Remove-ServerbyId, 
Get-Server,
Get-ServerCost,
Get-TotalCost,
Get-Order
 