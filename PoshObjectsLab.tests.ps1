
# A few simple Pester-Tests
using module .\2.0\PoshObjectsLab.psm1

$JSonPath = ".\StartupCompany.json"

describe "Initialize the Data Center" {

    BeforeAll {
        Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force
    }

    AfterAll {
        Remove-Module -Name PoshObjectsLab
    }
    
    it "Should initialize a DC" {
        $DC = [DataCenter]::new($JSonPath)
        $DC | Should not be $null
    }

}
describe "Dealing with Server objects" {
    
    BeforeAll {
        Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force
        $DC = [DataCenter]::new($JSonPath)
    }

    AfterAll {
        Remove-Module -Name PoshObjectsLab
    }

    it "should return a server object" {
        $S = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
        $S | Should not be $null
    }

    it "should create two server objects" {
        $Server = @()
        $Server += Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
        $Server += Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
        $Server.Count | Should  be 2
    }

    it "should return two server objects from the DataCenter" {
        $DC.ServerList.Clear()
        Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
        Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS"
        $DC.ServerList.Count | Should  be 2
    }

    it "should leave one object" {
        $DC.ServerList.Clear()
        $S1 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS1"
        $S2 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS2"
        Remove-ServerById -ServerId $S2.Id  
        $DC.ServerList.Count | Should  be 1
    }

    it "should leave zero objects" {
        $DC.ServerList.Clear()
        $S1 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS1"
        Remove-Server -Server $S1  
        $DC.ServerList.Count | Should  be 0
    }

    it "should cost be greater than 0" {
        $DC.ServerList.Clear()
        $S1 = Add-Server -MemoryGB 1 -CpuCount 1 -ServerOS "Test-OS1"
        Start-Sleep -Seconds 1
        (Get-ServerCost -Server $S1 -gt 0) | Should be $true 
    }

}