[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsSoftwareDeployment'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareDeployment\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    Type = 0
                }

                $settingsReturn = @{
                    EvaluationSchedule = 'DA159CC000280400'
                }

                $cmScheduleReturn = @{
                    MinuteDuration = $null
                    RecurInterval  = 1
                    WeekOrder      = $null
                    HourDuration   = $null
                    Start          = '9/21/2021 16:54'
                    DayOfWeek      = $null
                    ScheduleType   = 'MonthlyByDay'
                    MonthDay       = 0
                    DayDuration    = $null
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'Default Client Agent Settings'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSchedule -MockWith { $cmScheduleReturn }
            }

            Context 'When retrieving Client Policy Settings for software deployment' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $settingsReturn } -ParameterFilter { $Setting -eq 'SoftwareDeployment' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Start               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.ScheduleType        | Should -Be -ExpectedValue 'MonthlyByDay'
                    $result.DayOfWeek           | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.DayofMonth          | Should -Be -ExpectedValue 0
                    $result.RecurInterval       | Should -Be -ExpectedValue 1
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Start               | Should -Be -ExpectedValue $null
                    $result.ScheduleType        | Should -Be -ExpectedValue $null
                    $result.DayOfWeek           | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.DayofMonth          | Should -Be -ExpectedValue $null
                    $result.RecurInterval       | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType          | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but software deployment is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'SoftwareDeployment' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Start               | Should -Be -ExpectedValue $null
                    $result.ScheduleType        | Should -Be -ExpectedValue $null
                    $result.DayOfWeek           | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.DayofMonth          | Should -Be -ExpectedValue $null
                    $result.RecurInterval       | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Default'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareDeployment\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresentDevice = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Start               = '9/21/2021 16:54'
                    ScheduleType        = 'MonthlyByWeek'
                    DayOfWeek           = 'Monday'
                    MonthlyWeekOrder    = 'Second'
                    RecurInterval       = 1
                    DayofMonth          = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $returnPresentDefault = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'Default Client Agent Settings'
                    Start               = '9/21/2021 16:54'
                    ScheduleType        = 'MonthlyByDay'
                    DayOfWeek           = $null
                    MonthlyWeekOrder    = $null
                    DayofMonth          = 0
                    RecurInterval       = 1
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Default'
                }

                $inputPresent = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    ScheduleType      = 'MonthlyByWeek'
                    DayOfWeek         = 'Monday'
                    MonthlyWeekOrder  = 'Second'
                    RecurInterval     = 1
                }

                Mock -CommandName Set-CMClientSettingSoftwareDeployment
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnNotConfig = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Start               = $null
                        ScheduleType        = $null
                        DayOfWeek           = $null
                        MonthlyWeekOrder    = $null
                        DayofMonth          = $null
                        RecurInterval       = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Device'
                    }

                    $inputPresentMismatch = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        ScheduleType      = 'Days'
                        RecurInterval     = 10
                    }

                    $cmScheduleInput = @{
                        RecurCount    = 1
                        RecurInterval = 'Days'
                    }

                    Mock -CommandName Set-CMSchedule -MockWith { $cmScheduleInput }
                    Mock -CommandName New-CMSchedule
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule -MockWith { $true }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match for device' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule -MockWith  { $false }

                    Set-TargetResource @inputPresentMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when settings do not match for default' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }
                    Mock -CommandName Test-CMSchedule -MockWith  { $false }

                    Set-TargetResource @inputPresentMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Start               = $null
                        ScheduleType        = $null
                        DayOfWeek           = $null
                        MonthlyWeekOrder    = $null
                        DayofMonth          = $null
                        RecurInterval       = $null
                        ClientSettingStatus = 'Absent'
                        ClientType          = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'UserTest'
                        Start               = $null
                        ScheduleType        = $null
                        DayOfWeek           = $null
                        MonthlyWeekOrder    = $null
                        DayofMonth          = $null
                        RecurInterval       = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'User'
                    }

                    $clientTypeError = 'Client Settings for software deployment only applies to Default and Device client settings.'

                    $inputInvalidSchedule = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'Default Client Agent Settings'
                        DayOfWeek         = 'Monday'
                        MonthlyWeekOrder  = 'Second'
                        RecurInterval     = 1
                    }

                    $scheduleError = 'In order to create a schedule you must specify ScheduleType.'

                    Mock -CommandName Test-CMSchedule
                    Mock -CommandName Set-CMSchedule
                    Mock -CommandName New-CMSchedule
                }

                It 'Should throw and call expected commands when client policy does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when client policy is a user policy' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $clientTypeError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when not specifying a schedule type with schedule settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    { Set-TargetResource @inputInvalidSchedule } | Should -Throw -ExpectedMessage $scheduleError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareDeployment -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareDeployment\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresentDevice = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Start               = '9/21/2021 16:54'
                    ScheduleType        = 'MonthlyByWeek'
                    DayOfWeek           = 'Monday'
                    MonthlyWeekOrder    = 'Second'
                    RecurInterval       = 1
                    DayofMonth          = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $returnPresentDefault = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'Default Client Agent Settings'
                    Start               = '9/21/2021 16:54'
                    ScheduleType        = 'MonthlyByDay'
                    DayOfWeek           = $null
                    MonthlyWeekOrder    = $null
                    DayofMonth          = 0
                    RecurInterval       = 1
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Default'
                }

                $returnAbsent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Start               = $null
                    ScheduleType        = $null
                    DayOfWeek           = $null
                    MonthlyWeekOrder    = $null
                    DayofMonth          = $null
                    RecurInterval       = $null
                    ClientSettingStatus = 'Absent'
                    ClientType          = $null
                }

                $returnNotConfig = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Start               = $null
                    ScheduleType        = $null
                    DayOfWeek           = $null
                    MonthlyWeekOrder    = $null
                    DayofMonth          = $null
                    RecurInterval       = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $returnUser = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'UserTest'
                    Start               = $null
                    ScheduleType        = $null
                    DayOfWeek           = $null
                    MonthlyWeekOrder    = $null
                    DayofMonth          = $null
                    RecurInterval       = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'User'
                }

                $inputPresent = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    ScheduleType      = 'MonthlyByWeek'
                    DayOfWeek         = 'Monday'
                    MonthlyWeekOrder  = 'Second'
                    RecurInterval     = 1
                }

                $inputPresentMismatch = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    ScheduleType      = 'Days'
                    RecurInterval     = 10
                }

                $inputInvalidSchedule = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'Default Client Agent Settings'
                    DayOfWeek         = 'Monday'
                    MonthlyWeekOrder  = 'Second'
                    RecurInterval     = 1
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputPresentMismatch | Should -Be $false
                }

                It 'Should return desired result false when client policy does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client policy is user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when not specifying a schedule type' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    Test-TargetResource @inputInvalidSchedule | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
