[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsComputerAgent'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerAgent\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    ReminderInterval              = 2
                    DayReminderInterval           = 1
                    HourReminderInterval          = 20
                    BrandingTitle                 = 'Test Site'
                    UseNewSoftwareCenter          = $true
                    EnableHealthAttestation       = $true
                    UseOnPremHAService            = $true
                    InstallRestriction            = 1
                    SuspendBitLocker              = 0
                    EnableThirdPartyOrchestration = 1
                    PowerShellExecutionPolicy     = 1
                    DisplayNewProgramNotification = $true
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

            Context 'When retrieving Client Policy Settings for Computer Agent' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn } -ParameterFilter { $Setting -eq 'ComputerAgent' }

                    $result = Get-TargetResource @getInput
                    $result                                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                       | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName              | Should -Be -ExpectedValue 'ClientTest'
                    $result.InitialReminderHr              | Should -Be -ExpectedValue 2
                    $result.InterimReminderHr              | Should -Be -ExpectedValue 1
                    $result.FinalReminderMins              | Should -Be -ExpectedValue 20
                    $result.BrandingTitle                  | Should -Be -ExpectedValue 'Test Site'
                    $result.UseNewSoftwareCenter           | Should -Be -ExpectedValue $true
                    $result.EnableHealthAttestation        | Should -Be -ExpectedValue $true
                    $result.UseOnPremisesHealthAttestation | Should -Be -ExpectedValue $true
                    $result.InstallRestriction             | Should -Be -ExpectedValue 'OnlyAdministrators'
                    $result.SuspendBitLocker               | Should -Be -ExpectedValue 'Never'
                    $result.EnableThirdPartyOrchestration  | Should -Be -ExpectedValue 'Yes'
                    $result.PowerShellExecutionPolicy      | Should -Be -ExpectedValue 'Bypass'
                    $result.DisplayNewProgramNotification  | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus            | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                     | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                       | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName              | Should -Be -ExpectedValue 'ClientTest'
                    $result.InitialReminderHr              | Should -Be -ExpectedValue $null
                    $result.InterimReminderHr              | Should -Be -ExpectedValue $null
                    $result.FinalReminderMins              | Should -Be -ExpectedValue $null
                    $result.BrandingTitle                  | Should -Be -ExpectedValue $null
                    $result.UseNewSoftwareCenter           | Should -Be -ExpectedValue $null
                    $result.EnableHealthAttestation        | Should -Be -ExpectedValue $null
                    $result.UseOnPremisesHealthAttestation | Should -Be -ExpectedValue $null
                    $result.InstallRestriction             | Should -Be -ExpectedValue $null
                    $result.SuspendBitLocker               | Should -Be -ExpectedValue $null
                    $result.EnableThirdPartyOrchestration  | Should -Be -ExpectedValue $null
                    $result.PowerShellExecutionPolicy      | Should -Be -ExpectedValue $null
                    $result.DisplayNewProgramNotification  | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus            | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                     | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but computer agent is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'ComputerAgent' }

                    $result = Get-TargetResource @getInput
                    $result                                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                       | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName              | Should -Be -ExpectedValue 'ClientTest'
                    $result.InitialReminderHr              | Should -Be -ExpectedValue $null
                    $result.InterimReminderHr              | Should -Be -ExpectedValue $null
                    $result.FinalReminderMins              | Should -Be -ExpectedValue $null
                    $result.BrandingTitle                  | Should -Be -ExpectedValue $null
                    $result.UseNewSoftwareCenter           | Should -Be -ExpectedValue $null
                    $result.EnableHealthAttestation        | Should -Be -ExpectedValue $null
                    $result.UseOnPremisesHealthAttestation | Should -Be -ExpectedValue $null
                    $result.InstallRestriction             | Should -Be -ExpectedValue $null
                    $result.SuspendBitLocker               | Should -Be -ExpectedValue $null
                    $result.EnableThirdPartyOrchestration  | Should -Be -ExpectedValue $null
                    $result.PowerShellExecutionPolicy      | Should -Be -ExpectedValue $null
                    $result.DisplayNewProgramNotification  | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus            | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                     | Should -Be -ExpectedValue 'Device'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerAgent\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = 2
                    InterimReminderHr              = 1
                    FinalReminderMins              = 20
                    BrandingTitle                  = 'Test Site'
                    UseNewSoftwareCenter           = $true
                    EnableHealthAttestation        = $true
                    UseOnPremisesHealthAttestation = $true
                    InstallRestriction             = 'OnlyAdministrators'
                    SuspendBitLocker               = 'Never'
                    EnableThirdPartyOrchestration  = 'Yes'
                }

                $returnPresent = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = 2
                    InterimReminderHr              = 1
                    FinalReminderMins              = 20
                    BrandingTitle                  = 'Test Site'
                    UseNewSoftwareCenter           = $true
                    EnableHealthAttestation        = $true
                    UseOnPremisesHealthAttestation = $true
                    InstallRestriction             = 'OnlyAdministrators'
                    SuspendBitLocker               = 'Never'
                    EnableThirdPartyOrchestration  = 'Yes'
                    PowerShellExecutionPolicy      = 'Bypass'
                    DisplayNewProgramNotification  = $true
                    ClientSettingStatus            = 'Present'
                    ClientType                     = 'Device'
                }

                Mock -CommandName Set-CMClientSettingComputerAgent
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMismatch = @{
                        SiteCode                       = 'Lab'
                        ClientSettingName              = 'ClientTest'
                        InitialReminderHr              = 3
                        InterimReminderHr              = 2
                        FinalReminderMins              = 25
                        BrandingTitle                  = 'Test Site'
                        UseNewSoftwareCenter           = $true
                        EnableHealthAttestation        = $false
                        UseOnPremisesHealthAttestation = $true
                        InstallRestriction             = 'OnlyAdministrators'
                        SuspendBitLocker               = 'Always'
                        EnableThirdPartyOrchestration  = 'No'
                    }

                    $returnNotConfig = @{
                        SiteCode                       = 'Lab'
                        ClientSettingName              = 'ClientTest'
                        InitialReminderHr              = $null
                        InterimReminderHr              = $null
                        FinalReminderMins              = $null
                        BrandingTitle                  = $null
                        UseNewSoftwareCenter           = $null
                        EnableHealthAttestation        = $null
                        UseOnPremisesHealthAttestation = $null
                        InstallRestriction             = $null
                        SuspendBitLocker               = $null
                        EnableThirdPartyOrchestration  = $null
                        PowerShellExecutionPolicy      = $null
                        DisplayNewProgramNotification  = $null
                        ClientSettingStatus            = 'Present'
                        ClientType                     = 'Default'
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerAgent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerAgent -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when state returns present for the default policy' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerAgent -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                       = 'Lab'
                        ClientSettingName              = 'ClientTest'
                        InitialReminderHr              = $null
                        InterimReminderHr              = $null
                        FinalReminderMins              = $null
                        BrandingTitle                  = $null
                        UseNewSoftwareCenter           = $null
                        EnableHealthAttestation        = $null
                        UseOnPremisesHealthAttestation = $null
                        InstallRestriction             = $null
                        SuspendBitLocker               = $null
                        EnableThirdPartyOrchestration  = $null
                        PowerShellExecutionPolicy      = $null
                        DisplayNewProgramNotification  = $null
                        ClientSettingStatus            = 'Absent'
                        ClientType                     = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                       = 'Lab'
                        ClientSettingName              = 'ClientTest'
                        InitialReminderHr              = $null
                        InterimReminderHr              = $null
                        FinalReminderMins              = $null
                        BrandingTitle                  = $null
                        UseNewSoftwareCenter           = $null
                        EnableHealthAttestation        = $null
                        UseOnPremisesHealthAttestation = $null
                        InstallRestriction             = $null
                        SuspendBitLocker               = $null
                        EnableThirdPartyOrchestration  = $null
                        PowerShellExecutionPolicy      = $null
                        DisplayNewProgramNotification  = $null
                        ClientSettingStatus            = 'Present'
                        ClientType                     = 'User'
                    }

                    $wrongClientType  = 'Client Settings for software update only applies to Default and Device Client settings.'
                }

                It 'Should throw and call expected commands when client settings does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerAgent -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when client type is incorrect' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingComputerAgent -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsComputerAgent\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = 2
                    InterimReminderHr              = 1
                    FinalReminderMins              = 20
                    BrandingTitle                  = 'Test Site'
                    UseNewSoftwareCenter           = $true
                    EnableHealthAttestation        = $true
                    UseOnPremisesHealthAttestation = $true
                    InstallRestriction             = 'OnlyAdministrators'
                    SuspendBitLocker               = 'Never'
                    EnableThirdPartyOrchestration  = 'Yes'
                    PowerShellExecutionPolicy      = 'Bypass'
                    DisplayNewProgramNotification  = $true
                    ClientSettingStatus            = 'Present'
                    ClientType                     = 'Device'
                }

                $returnUser = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = $null
                    InterimReminderHr              = $null
                    FinalReminderMins              = $null
                    BrandingTitle                  = $null
                    UseNewSoftwareCenter           = $null
                    EnableHealthAttestation        = $null
                    UseOnPremisesHealthAttestation = $null
                    InstallRestriction             = $null
                    SuspendBitLocker               = $null
                    EnableThirdPartyOrchestration  = $null
                    PowerShellExecutionPolicy      = $null
                    DisplayNewProgramNotification  = $null
                    ClientSettingStatus            = 'Present'
                    ClientType                     = 'User'
                }

                $returnAbsent = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = $null
                    InterimReminderHr              = $null
                    FinalReminderMins              = $null
                    BrandingTitle                  = $null
                    UseNewSoftwareCenter           = $null
                    EnableHealthAttestation        = $null
                    UseOnPremisesHealthAttestation = $null
                    InstallRestriction             = $null
                    SuspendBitLocker               = $null
                    EnableThirdPartyOrchestration  = $null
                    PowerShellExecutionPolicy      = $null
                    DisplayNewProgramNotification  = $null
                    ClientSettingStatus            = 'Absent'
                    ClientType                     = $null
                }

                $inputPresent = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = 2
                    InterimReminderHr              = 1
                    FinalReminderMins              = 20
                    BrandingTitle                  = 'Test Site'
                    UseNewSoftwareCenter           = $true
                    EnableHealthAttestation        = $true
                    UseOnPremisesHealthAttestation = $true
                    InstallRestriction             = 'OnlyAdministrators'
                    SuspendBitLocker               = 'Never'
                    EnableThirdPartyOrchestration  = 'Yes'
                }

                $inputMismatch = @{
                    SiteCode                       = 'Lab'
                    ClientSettingName              = 'ClientTest'
                    InitialReminderHr              = 3
                    InterimReminderHr              = 2
                    FinalReminderMins              = 25
                    BrandingTitle                  = 'Test Site'
                    UseNewSoftwareCenter           = $true
                    EnableHealthAttestation        = $false
                    UseOnPremisesHealthAttestation = $true
                    InstallRestriction             = 'OnlyAdministrators'
                    SuspendBitLocker               = 'Always'
                    EnableThirdPartyOrchestration  = 'No'
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
