[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientStatusSettings'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import Stub function
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMClientStatusSettings'

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

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

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
                    $result.ClientPolicyDays       | Should -Be -ExpectedValue $null
                    $result.HeartbeatDiscoveryDays | Should -Be -ExpectedValue $null
                    $result.SoftwareInventoryDays  | Should -Be -ExpectedValue $null
                    $result.HardwareInventoryDays  | Should -Be -ExpectedValue $null
                    $result.StatusMessageDays      | Should -Be -ExpectedValue $null
                    $result.HistoryCleanupDays     | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMClientStatusSetting

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @cmClientSettingsInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientStatusSetting -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for changing single settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @cmClientInputHeartbeat
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientStatusSetting -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for changing multiple settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @cmClientInputmultiple
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientStatusSetting -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when Set client status setting throws' {
                    Mock -CommandName Set-CMClientStatusSetting -MockWith { throw }
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    { Set-TargetResource @cmClientInputmultiple } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientStatusSetting -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should returned desired result true when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Test-TargetResource @cmClientSettingsInput | Should -Be $true
                }

                It 'Should returned desired result false when get returns mismatch on single setting' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Test-TargetResource @cmClientInputHeartbeat | Should -Be $false
                }

                It 'Should returned desired result false when get returns mismatch on multiple settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Test-TargetResource @cmClientInputmultiple | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
