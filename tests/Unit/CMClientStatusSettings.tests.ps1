param ()

# Begin Testing
BeforeAll {
    # Import Stub function
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction 'SilentlyContinue'

    # Import DscResource.Test Module
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    # Variables used for each Initialize-TestEnvironment
    $initalize = @{
        DSCModuleName   = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMClientStatusSettings'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMClientStatusSettings\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $cmClientSettingsReturn = @{
            PolicyInactiveInterval = 8
            DDRInactiveInterval    = 7
            SWInactiveInterval     = 7
            HWInactiveInterval     = 7
            StatusInactiveInterval = 7
            CleanUpInterval        = 31
        }

        $cmClientSettingsGet = @{
            SiteCode         = 'Lab'
            IsSingleInstance = 'Yes'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Set-Location -ModuleName DSC_CMClientStatusSettings
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving client status settings' {
        It 'Should return desired result' {
            Mock -CommandName Get-CMClientStatusSetting -MockWith { $cmClientSettingsReturn } -ModuleName DSC_CMClientStatusSettings

            $result = Get-TargetResource @cmClientSettingsGet
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.IsSingleInstance       | Should -Be -ExpectedValue 'Yes'
            $result.ClientPolicyDays       | Should -Be -ExpectedValue 8
            $result.HeartbeatDiscoveryDays | Should -Be -ExpectedValue 7
            $result.SoftwareInventoryDays  | Should -Be -ExpectedValue 7
            $result.HardwareInventoryDays  | Should -Be -ExpectedValue 7
            $result.StatusMessageDays      | Should -Be -ExpectedValue 7
            $result.HistoryCleanupDays     | Should -Be -ExpectedValue 31
        }

        It 'Should return desired result when Client status settings are null' {
            Mock -CommandName Get-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings

            $result = Get-TargetResource @cmClientSettingsGet
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.IsSingleInstance       | Should -Be -ExpectedValue 'Yes'
            $result.ClientPolicyDays       | Should -BeNullOrEmpty
            $result.HeartbeatDiscoveryDays | Should -BeNullOrEmpty
            $result.SoftwareInventoryDays  | Should -BeNullOrEmpty
            $result.HardwareInventoryDays  | Should -BeNullOrEmpty
            $result.StatusMessageDays      | Should -BeNullOrEmpty
            $result.HistoryCleanupDays     | Should -BeNullOrEmpty
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMClientStatusSettings\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getTargetReturn = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
        }

        $cmClientSettingsInput = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
        }

        $cmClientInputHeartbeat = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            HeartBeatDiscoveryDays = 8
        }

        $cmClientInputmultiple = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            HeartBeatDiscoveryDays = 8
            HardwareInventoryDays  = 19
            StatusMessageDays      = 7
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Set-Location -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Set-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn } -ModuleName DSC_CMClientStatusSettings
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        It 'Should call expected commands when settings match' {

            Set-TargetResource @cmClientSettingsInput
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMClientStatusSettings -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings -Exactly 0 -Scope It
        }

        It 'Should call expected commands for changing single settings' {

            Set-TargetResource @cmClientInputHeartbeat
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMClientStatusSettings -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
        }

        It 'Should call expected commands for changing multiple settings' {

            Set-TargetResource @cmClientInputmultiple
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMClientStatusSettings -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
        }

        It 'Should call expected commands when Set client status setting throws' {
            Mock -CommandName Set-CMClientStatusSetting -MockWith { throw } -ModuleName DSC_CMClientStatusSettings

            { Set-TargetResource @cmClientInputmultiple } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings 1 -Exactly -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMClientStatusSettings -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
            Should -Invoke Set-CMClientStatusSetting -ModuleName DSC_CMClientStatusSettings -Exactly 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMClientStatusSettings\Test-TargetResource' -Tag 'Test' {
    BeforeAll{
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getTargetReturn = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
        }

        $cmClientSettingsInput = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
        }

        $cmClientInputHeartbeat = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            HeartBeatDiscoveryDays = 8
        }

        $cmClientInputmultiple = @{
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            HeartBeatDiscoveryDays = 8
            HardwareInventoryDays  = 19
            StatusMessageDays      = 7
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Set-Location -ModuleName DSC_CMClientStatusSettings
        Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn } -ModuleName DSC_CMClientStatusSettings
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource' {
        It 'Should returned desired result true when settings match' {
            Test-TargetResource @cmClientSettingsInput | Should -BeTrue
        }

        It 'Should returned desired result false when get returns mismatch on single setting' {
            Test-TargetResource @cmClientInputHeartbeat | Should -BeFalse
        }

        It 'Should returned desired result false when get returns mismatch on multiple settings' {
            Test-TargetResource @cmClientInputmultiple | Should -BeFalse
        }
    }
}
