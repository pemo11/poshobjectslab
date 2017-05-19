
# A few simple Pester-Tests

describe "Dealing with Server objects" {
    BeforeAll {
        Import-Module -Name PoshObjectsLab
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

}