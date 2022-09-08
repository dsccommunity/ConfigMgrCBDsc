[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsComputerRestart'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerRestart\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    RebootNotificationsDialog                 = $true
                    RebootLogoffNotificationFinalWindow       = 10
                    RebootLogoffNotificationCountdownDuration = 30
                    EnforeReboot                              = $true
                }

                $clientType = @{
                    Type = '1'
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Computer Restart' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn } -ParameterFilter { $Setting -eq 'ComputerRestart' }

                    $result = Get-TargetResource @getInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                         | Should -Be -ExpectedValue 'ClientTest'
                    $result.NoRebootEnforcement                       | Should -Be -ExpectedValue $false
                    $result.CountdownMins                             | Should -Be -ExpectedValue 30
                    $result.FinalWindowMins                      | Should -Be -ExpectedValue 10
                    $result.ReplaceToastNotificationWithDialog                 | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                       | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                                | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                         | Should -Be -ExpectedValue 'ClientTest'
                    $result.NoRebootEnforcement                             | Should -Be -ExpectedValue $null
                    $result.CountdownMins | Should -Be -ExpectedValue $null
                    $result.FinalWindowMins       | Should -Be -ExpectedValue $null
                    $result.ReplaceToastNotificationWithDialog                 | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus                       | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                                | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but Computer Restart is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'ComputerRestart' }

                    $result = Get-TargetResource @getInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                         | Should -Be -ExpectedValue 'ClientTest'
                    $result.NoRebootEnforcement                             | Should -Be -ExpectedValue $null
                    $result.CountdownMins | Should -Be -ExpectedValue $null
                    $result.FinalWindowMins       | Should -Be -ExpectedValue $null
                    $result.ReplaceToastNotificationWithDialog                 | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus                       | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                                | Should -Be -ExpectedValue 'Device'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerRestart\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $true
                    CountdownMins                      = 30
                    FinalWindowMins                    = 10
                    ReplaceToastNotificationWithDialog = $true
                }

                $returnPresent = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $true
                    CountdownMins                      = 30
                    FinalWindowMins                    = 10
                    ReplaceToastNotificationWithDialog = $true
                    ClientSettingStatus                = 'Present'
                    ClientType                         = 'Device'
                }

                Mock -CommandName Set-CMClientSettingComputerRestart
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMismatch = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $false
                        CountdownMins                      = 90
                        FinalWindowMins                    = 20
                        ReplaceToastNotificationWithDialog = $true
                    }

                    $returnNotConfig = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $null
                        CountdownMins                      = $null
                        FinalWindowMins                    = $null
                        ReplaceToastNotificationWithDialog = $null
                        ClientSettingStatus                = 'Present'
                        ClientType                         = 'Default'
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when state returns present for the default policy' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $null
                        CountdownMins                      = $null
                        FinalWindowMins                    = $null
                        ReplaceToastNotificationWithDialog = $null
                        ClientSettingStatus                = 'Absent'
                        ClientType                         = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $null
                        CountdownMins                      = $null
                        FinalWindowMins                    = $null
                        ReplaceToastNotificationWithDialog = $null
                        ClientSettingStatus                = 'Present'
                        ClientType                         = 'User'
                    }

                    $wrongClientType = 'Client Settings for computer restart only applies to Default and Device Client settings.'

                    $returnNotConfig = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $null
                        CountdownMins                      = $null
                        FinalWindowMins                    = $null
                        ReplaceToastNotificationWithDialog = $null
                        ClientSettingStatus                = 'Present'
                        ClientType                         = 'Default'
                    }

                    $inputMismatchWrongSetting = @{
                        SiteCode                           = 'Lab'
                        ClientSettingName                  = 'ClientTest'
                        NoRebootEnforcement                = $false
                        CountdownMins                      = 10
                        FinalWindowMins                    = 20
                        ReplaceToastNotificationWithDialog = $true
                    }

                    $wrongMinutes = "Countdown $($inputMismatchWrongSetting['CountdownMins']) minutes is less or equal final window $($inputMismatchWrongSetting['FinalWindowMins']) minutes"
                }

                It 'Should throw and call expected commands when client settings does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when client type is incorrect' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when countdown is less or equal to final window' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    { Set-TargetResource @inputMismatchWrongSetting } | Should -Throw -ExpectedMessage $wrongMinutes
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerRestart -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerRestart\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $true
                    CountdownMins                      = 30
                    FinalWindowMins                    = 10
                    ReplaceToastNotificationWithDialog = $true
                    ClientSettingStatus                = 'Present'
                    ClientType                         = 'Device'
                }

                $returnUser = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $null
                    CountdownMins                      = $null
                    FinalWindowMins                    = $null
                    ReplaceToastNotificationWithDialog = $null
                    ClientSettingStatus                = 'Present'
                    ClientType                         = 'User'
                }

                $returnAbsent = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $null
                    CountdownMins                      = $null
                    FinalWindowMins                    = $null
                    ReplaceToastNotificationWithDialog = $null
                    ClientSettingStatus                = 'Absent'
                    ClientType                         = $null
                }

                $inputPresent = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $true
                    CountdownMins                      = 30
                    FinalWindowMins                    = 10
                    ReplaceToastNotificationWithDialog = $true
                }

                $inputMismatch = @{
                    SiteCode                           = 'Lab'
                    ClientSettingName                  = 'ClientTest'
                    NoRebootEnforcement                = $false
                    CountdownMins                      = 90
                    FinalWindowMins                    = 20
                    ReplaceToastNotificationWithDialog = $true
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputMismatch | Should -Be $false
                }

                It 'Should return desired result false when user policy is returned' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputMismatch | Should -Be $false
                }

                It 'Should return desired result false when client policy is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
