param ()

# Begin Testing
try
{
    $dscModuleName   = 'ConfigMgrCBDsc'
    $dscResourceName = 'DSC_CMClientStatusSettings'

    $testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $dscModuleName `
        -DSCResourceName $dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    BeforeAll {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMClientStatusSettings'

        # Import Stub function
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

        try
        {
            Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
        }
        catch [System.IO.FileNotFoundException]
        {
            throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
        }

        $cmClientSettingsGet = @{
            SiteCode         = 'Lab'
            IsSingleInstance = 'Yes'
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

        $cmClientSettingsReturn = @{
            PolicyInactiveInterval = 8
            DDRInactiveInterval    = 7
            SWInactiveInterval     = 7
            HWInactiveInterval     = 7
            StatusInactiveInterval = 7
            CleanUpInterval        = 31
        }

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
    }

    Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving client status settings' {
                It 'Should return desired result' {
                    Mock -CommandName Get-CMClientStatusSetting -MockWith { $cmClientSettingsReturn }

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
                    Mock -CommandName Get-CMClientStatusSetting

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
    }

    Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMClientStatusSetting
                Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }
            }

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands when settings match' {

                    Set-TargetResource @cmClientSettingsInput
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Set-CMClientStatusSetting -Exactly 0 -Scope It
                }

                It 'Should call expected commands for changing single settings' {

                    Set-TargetResource @cmClientInputHeartbeat
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Set-CMClientStatusSetting -Exactly 1 -Scope It
                }

                It 'Should call expected commands for changing multiple settings' {

                    Set-TargetResource @cmClientInputmultiple
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Set-CMClientStatusSetting -Exactly 1 -Scope It
                }

                It 'Should call expected commands when Set client status setting throws' {
                    Mock -CommandName Set-CMClientStatusSetting -MockWith { throw }

                    { Set-TargetResource @cmClientInputmultiple } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule 1 -Exactly -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Set-CMClientStatusSetting -Exactly 1 -Scope It
                }
            }
        }
    }

    Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test' {
        InModuleScope $dscResourceName {
            BeforeAll{
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }
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
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}
