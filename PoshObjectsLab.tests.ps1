
# A few simple Pester-Tests
using module .\2.0\PoshObjectsLab.psm1

$JSonPath = ".\StartupCompany.json"
$ServerConfigPath = ".\ServerConfig.json"

describe "Initialize the Data Center" {

    BeforeAll {
        Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force
    }

    AfterAll {
        Remove-Module -Name PoshObjectsLab
    }
    
    it "Should initialize a DC" {
        $DC = [DataCenter]::new($JSonPath, $ServerConfigPath)
        $DC | Should not be $null
    }

    it "Should results to 3 server" {
        $DC = [DataCenter]::new($JSonPath, $ServerConfigPath)
        $DC.ServerList.Count -eq 3 | Should be $true
    }

}
describe "Dealing with Server objects" {
    
    BeforeAll {
        Import-Module -Name ..\PoshObjectsLab -RequiredVersion 2.0 -Force
        $DC = [DataCenter]::new($JSonPath, $ServerConfigPath)
    }

    AfterAll {
        Remove-Module -Name PoshObjectsLab
    }

    it "should return a server object" {
        $S1 = Add-Server -Size Small
        $S1 | Should not be $null
    }

    it "should create three server objects" {
        $Server = @()
        $Server += Add-Server -Size Small
        $Server += Add-Server -Size Medium
        $Server += Add-Server -Size Large
        $Server.Count | Should  be 3
    }

    it "should leave one object" {
        $DC.ServerList.Clear()
        Add-Server -Size Small
        $S2 = Add-Server -Size Medium
        Remove-ServerById -ServerId $S2.Id  
        $DC.ServerList.Count | Should  be 1
    }

    it "should leave zero objects" {
        $DC.ServerList.Clear()
        $S1 = Add-Server -Size Small
        Remove-Server -Server $S1  
        $DC.ServerList.Count | Should  be 0
    }

    it "should cost be greater than 0" {
        $DC.ServerList.Clear()
        $S1 = Add-Server -Size Small
        Start-Sleep -Seconds 1
        (Get-ServerCost -Server $S1 -gt 0) | Should be $true 
    }

}