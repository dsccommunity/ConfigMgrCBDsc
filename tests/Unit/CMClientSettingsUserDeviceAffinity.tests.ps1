[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsUserDeviceAffinity'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsUserDeviceAffinity\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $returnTypeDefault = @{
                    Type = 0
                }

                $returnTypeDevice = @{
                    Type = 1
                }

                $returnTypeUser = @{
                    Type = 2
                }

                $returnClient = @{
                    ConsoleMinutes      = 200
                    IntervalDays        = 100
                    AllowUserAffinity   = $true
                    AutoApproveAffinity = $true
                }

                $getDefaultInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'Default Client Agent Settings'
                }

                $getDeviceInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                $getUserInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'UserTest'
                }

                $clientSettingReturn = @{
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for User Device Affinity' {

                It 'Should return desired results when client settings exist for default client policy' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnTypeDefault }
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnClient } -ParameterFilter { $Setting -eq 'UserAndDeviceAffinity' }

                    $result = Get-TargetResource @getDefaultInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.LogOnThresholdMins  | Should -Be -ExpectedValue 200
                    $result.UsageThresholdDays  | Should -Be -ExpectedValue 100
                    $result.AutoApproveAffinity | Should -Be -ExpectedValue $true
                    $result.AllowUserAffinity   | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired results when client settings exist for device client policy' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnTypeDevice }
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnClient } -ParameterFilter { $Setting -eq 'UserAndDeviceAffinity' }

                    $result = Get-TargetResource @getDeviceInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.LogOnThresholdMins  | Should -Be -ExpectedValue 200
                    $result.UsageThresholdDays  | Should -Be -ExpectedValue 100
                    $result.AutoApproveAffinity | Should -Be -ExpectedValue $true
                    $result.AllowUserAffinity   | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist for User client policy' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnTypeUser }
                    Mock -CommandName Get-CMClientSetting -MockWith { $returnClient } -ParameterFilter { $Setting -eq 'UserAndDeviceAffinity' }

                    $result = Get-TargetResource @getUserInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'UserTest'
                    $result.LogOnThresholdMins  | Should -Be -ExpectedValue $null
                    $result.UsageThresholdDays  | Should -Be -ExpectedValue $null
                    $result.AutoApproveAffinity | Should -Be -ExpectedValue $null
                    $result.AllowUserAffinity   | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'User'
                }

                It 'Should return desired results when client policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getUserInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'UserTest'
                    $result.LogOnThresholdMins  | Should -Be -ExpectedValue $null
                    $result.UsageThresholdDays  | Should -Be -ExpectedValue $null
                    $result.AutoApproveAffinity | Should -Be -ExpectedValue $null
                    $result.AllowUserAffinity   | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType          | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsUserDeviceAffinity\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputDeviceMisMatch = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'TestClient'
                    LogOnThresholdMins  = 100
                    UsageThresholdDays  = 50
                    AutoApproveAffinity = $false
                    AllowUserAffinity   = $true
                }

                Mock -CommandName Set-CMClientSettingUserAndDeviceAffinity
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnPresentDefault = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        LogOnThresholdMins  = 200
                        UsageThresholdDays  = 100
                        AutoApproveAffinity = $true
                        AllowUserAffinity   = $true
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Default'
                    }

                    $inputPresent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        LogOnThresholdMins  = 200
                        UsageThresholdDays  = 100
                        AutoApproveAffinity = $true
                        AllowUserAffinity   = $true
                    }

                    $inputDefaultMisMatch = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        LogOnThresholdMins  = 100
                        UsageThresholdDays  = 50
                        AutoApproveAffinity = $false
                        AllowUserAffinity   = $false
                    }

                    $returnPresentDevice = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'TestClient'
                        LogOnThresholdMins  = 200
                        UsageThresholdDays  = 100
                        AutoApproveAffinity = $true
                        AllowUserAffinity   = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Device'
                    }

                    $returnPresentUser = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'UserClient'
                        LogOnThresholdMins  = $null
                        UsageThresholdDays  = $null
                        AutoApproveAffinity = $null
                        AllowUserAffinity   = $true
                        ClientSettingStatus = 'Present'
                        ClientType          = 'User'
                    }

                    $inputUserMisMatch = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'TestClient'
                        LogOnThresholdMins  = 100
                        UsageThresholdDays  = 50
                        AutoApproveAffinity = $false
                        AllowUserAffinity   = $false
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingUserAndDeviceAffinity -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when making changes to device policy settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Set-TargetResource @inputDeviceMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingUserAndDeviceAffinity -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when making changes to user policy settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentUser }

                    Set-TargetResource @inputUserMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingUserAndDeviceAffinity -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when making changes to default policy settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    Set-TargetResource @inputDefaultMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingUserAndDeviceAffinity -Exactly -Times 1 -Scope It
                }

            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'TestClient'
                        LogOnThresholdMins  = $null
                        UsageThresholdDays  = $null
                        AutoApproveAffinity = $null
                        AllowUserAffinity   = $null
                        ClientSettingStatus = 'Absent'
                        ClientType          = $null
                    }

                    $absentMsg = 'Client Policy setting TestClient does not exist, and will need to be created prior to making client setting changes.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputDeviceMisMatch } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingUserAndDeviceAffinity -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsUserDeviceAffinity\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresentDefault = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'Default Client Agent Settings'
                    LogOnThresholdMins  = 200
                    UsageThresholdDays  = 100
                    AutoApproveAffinity = $true
                    AllowUserAffinity   = $true
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Default'
                }

                $inputPresent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'Default Client Agent Settings'
                    LogOnThresholdMins  = 200
                    UsageThresholdDays  = 100
                    AutoApproveAffinity = $true
                    AllowUserAffinity   = $true
                }

                $returnPresentDevice = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'TestClient'
                    LogOnThresholdMins  = 200
                    UsageThresholdDays  = 100
                    AutoApproveAffinity = $true
                    AllowUserAffinity   = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $inputDeviceMisMatch = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'TestClient'
                    LogOnThresholdMins  = 100
                    UsageThresholdDays  = 50
                    AutoApproveAffinity = $false
                    AllowUserAffinity   = $true
                }

                $returnPresentUser = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'UserClient'
                    LogOnThresholdMins  = $null
                    UsageThresholdDays  = $null
                    AutoApproveAffinity = $null
                    AllowUserAffinity   = $true
                    ClientSettingStatus = 'Present'
                    ClientType          = 'User'
                }

                $inputUserMisMatch = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'TestClient'
                    LogOnThresholdMins  = 100
                    UsageThresholdDays  = 50
                    AutoApproveAffinity = $false
                    AllowUserAffinity   = $false
                }

                $returnAbsent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'TestClient'
                    LogOnThresholdMins  = $null
                    UsageThresholdDays  = $null
                    AutoApproveAffinity = $null
                    AllowUserAffinity   = $null
                    ClientSettingStatus = 'Absent'
                    ClientType          = $null
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when modifying device settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDeviceMisMatch | Should -Be $false
                }

                It 'Should return desired result false when modifying user settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentUser }

                    Test-TargetResource @inputUserMisMatch | Should -Be $false
                }

                It 'Should return desired result false when client policy is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputPresent | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
