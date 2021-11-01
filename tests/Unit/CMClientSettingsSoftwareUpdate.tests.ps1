[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsSoftwareUpdate'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareUpdate\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    Type = 0
                }

                $clientReturnFalse = @{
                    Enabled                   = $false
                    ScanSchedule              = 1
                    EvaluationSchedule        = 2
                    AssignmentBatchingTimeout = 0
                    EnableExpressUpdates      = $true
                    ExpressUpdatesPort        = 8005
                    O365Management            = 2
                    EnableThirdPartyUpdates   = $true
                }

                $clientReturnEnforceFalse = @{
                    Enabled                   = $true
                    ScanSchedule              = 1
                    EvaluationSchedule        = 2
                    AssignmentBatchingTimeout = 0
                    EnableExpressUpdates      = $true
                    ExpressUpdatesPort        = 8005
                    O365Management            = 2
                    EnableThirdPartyUpdates   = $true
                }

                $clientReturnEnforceDays = @{
                    Enabled                   = $true
                    ScanSchedule              = 1
                    EvaluationSchedule        = 2
                    AssignmentBatchingTimeout = 345600
                    EnableExpressUpdates      = $true
                    ExpressUpdatesPort        = 8005
                    O365Management            = 1
                    EnableThirdPartyUpdates   = $true
                }

                $clientReturnEnforceHours = @{
                    Enabled                   = $true
                    ScanSchedule              = 1
                    EvaluationSchedule        = 2
                    AssignmentBatchingTimeout = 14400
                    EnableExpressUpdates      = $true
                    ExpressUpdatesPort        = 8005
                    O365Management            = 0
                    EnableThirdPartyUpdates   = $true
                }

                $cmScheduleReturnScan = @{
                    MinuteDuration = $null
                    RecurInterval  = 1
                    WeekOrder      = $null
                    HourDuration   = $null
                    Start          = '9/21/2021 16:54'
                    DayOfWeek      = $null
                    ScheduleType   = 'Hours'
                    MonthDay       = $null
                    DayDuration    = $null
                }

                $cmScheduleReturnEval = @{
                    MinuteDuration = $null
                    RecurInterval  = 2
                    WeekOrder      = $null
                    HourDuration   = $null
                    Start          = '9/21/2021 16:54'
                    DayOfWeek      = $null
                    ScheduleType   = 'Hours'
                    MonthDay       = $null
                    DayDuration    = $null
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'Default Client Agent Settings'
                    Enable            = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSchedule -MockWith { $cmScheduleReturnScan } -ParameterFilter { $ScheduleString -eq '1' }
                Mock -CommandName Get-CMSchedule -MockWith { $cmScheduleReturnEval } -ParameterFilter { $ScheduleString -eq '2' }
            }

            Context 'When retrieving Client Policy Settings for hardware settings' {

                It 'Should return desired results when enabled and EnforceManatory is false' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnEnforceFalse } -ParameterFilter { $Setting -eq 'SoftwareUpdates' }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $true
                    $result.ScanStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.ScanScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue 1
                    $result.EvalStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.EvalScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue 2
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $false
                    $result.TimeUnit                | Should -Be -ExpectedValue $null
                    $result.BatchingTimeout         | Should -Be -ExpectedValue $null
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $true
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue 8005
                    $result.Office365ManagementType | Should -Be -ExpectedValue 'No'
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Present'
                    $result.ClientType              | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired results when enabled and EnforceManatory is true and TimeUnit is days' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnEnforceDays } -ParameterFilter { $Setting -eq 'SoftwareUpdates' }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $true
                    $result.ScanStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.ScanScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue 1
                    $result.EvalStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.EvalScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue 2
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $true
                    $result.TimeUnit                | Should -Be -ExpectedValue 'Days'
                    $result.BatchingTimeout         | Should -Be -ExpectedValue 4
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $true
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue 8005
                    $result.Office365ManagementType | Should -Be -ExpectedValue 'Yes'
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Present'
                    $result.ClientType              | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired results when enabled and EnforceManatory is true and TimeUnit is hours' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnEnforceHours } -ParameterFilter { $Setting -eq 'SoftwareUpdates' }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $true
                    $result.ScanStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.ScanScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue 1
                    $result.EvalStart               | Should -Be -ExpectedValue '9/21/2021 16:54'
                    $result.EvalScheduleType        | Should -Be -ExpectedValue 'Hours'
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue 2
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $true
                    $result.TimeUnit                | Should -Be -ExpectedValue 'Hours'
                    $result.BatchingTimeout         | Should -Be -ExpectedValue 4
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $true
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue 8005
                    $result.Office365ManagementType | Should -Be -ExpectedValue 'NotConfigured'
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Present'
                    $result.ClientType              | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired result when software update is disabled' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnFalse } -ParameterFilter { $Setting -eq 'SoftwareUpdates' }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $false
                    $result.ScanStart               | Should -Be -ExpectedValue $null
                    $result.ScanScheduleType        | Should -Be -ExpectedValue $null
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EvalStart               | Should -Be -ExpectedValue $null
                    $result.EvalScheduleType        | Should -Be -ExpectedValue $null
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $null
                    $result.TimeUnit                | Should -Be -ExpectedValue $null
                    $result.BatchingTimeout         | Should -Be -ExpectedValue $null
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $null
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue $null
                    $result.Office365ManagementType | Should -Be -ExpectedValue $null
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Present'
                    $result.ClientType              | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $null
                    $result.ScanStart               | Should -Be -ExpectedValue $null
                    $result.ScanScheduleType        | Should -Be -ExpectedValue $null
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EvalStart               | Should -Be -ExpectedValue $null
                    $result.EvalScheduleType        | Should -Be -ExpectedValue $null
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $null
                    $result.TimeUnit                | Should -Be -ExpectedValue $null
                    $result.BatchingTimeout         | Should -Be -ExpectedValue $null
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $null
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue $null
                    $result.Office365ManagementType | Should -Be -ExpectedValue $null
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType              | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but software updates is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'SoftwareUpdates' }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'Default Client Agent Settings'
                    $result.Enable                  | Should -Be -ExpectedValue $null
                    $result.ScanStart               | Should -Be -ExpectedValue $null
                    $result.ScanScheduleType        | Should -Be -ExpectedValue $null
                    $result.ScanDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.ScanMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.ScanDayofMonth          | Should -Be -ExpectedValue $null
                    $result.ScanRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EvalStart               | Should -Be -ExpectedValue $null
                    $result.EvalScheduleType        | Should -Be -ExpectedValue $null
                    $result.EvalDayOfWeek           | Should -Be -ExpectedValue $null
                    $result.EvalMonthlyWeekOrder    | Should -Be -ExpectedValue $null
                    $result.EvalDayofMonth          | Should -Be -ExpectedValue $null
                    $result.EvalRecurInterval       | Should -Be -ExpectedValue $null
                    $result.EnforceMandatory        | Should -Be -ExpectedValue $null
                    $result.TimeUnit                | Should -Be -ExpectedValue $null
                    $result.BatchingTimeout         | Should -Be -ExpectedValue $null
                    $result.EnableDeltaDownload     | Should -Be -ExpectedValue $null
                    $result.DeltaDownloadPort       | Should -Be -ExpectedValue $null
                    $result.Office365ManagementType | Should -Be -ExpectedValue $null
                    $result.EnableThirdPartyUpdates | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus     | Should -Be -ExpectedValue 'Present'
                    $result.ClientType              | Should -Be -ExpectedValue 'Default'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareUpdate\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresentDevice = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $true
                    ScanStart               = '9/21/2021 16:54'
                    ScanScheduleType        = 'Hours'
                    ScanDayOfWeek           = $null
                    ScanMonthlyWeekOrder    = $null
                    ScanDayofMonth          = $null
                    ScanRecurInterval       = 1
                    EvalStart               = '9/21/2021 16:54'
                    EvalScheduleType        = 'Hours'
                    EvalDayOfWeek           = $null
                    EvalMonthlyWeekOrder    = $null
                    EvalDayofMonth          = $null
                    EvalRecurInterval       = 2
                    EnforceMandatory        = $true
                    TimeUnit                = 'Days'
                    BatchingTimeout         = 4
                    EnableDeltaDownload     = $true
                    DeltaDownloadPort       = 8005
                    Office365ManagementType = 'Yes'
                    EnableThirdPartyUpdates = $true
                    ClientSettingStatus     = 'Present'
                    ClientType              = 'Device'
                }

                $inputPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $true
                    ScanStart               = '9/21/2021 16:54'
                    ScanScheduleType        = 'Hours'
                    ScanRecurInterval       = 1
                    EvalStart               = '9/21/2021 16:54'
                    EvalScheduleType        = 'Hours'
                    EvalRecurInterval       = 2
                    EnforceMandatory        = $true
                    TimeUnit                = 'Days'
                    BatchingTimeout         = 4
                    EnableDeltaDownload     = $true
                    DeltaDownloadPort       = 8005
                    Office365ManagementType = 'Yes'
                    EnableThirdPartyUpdates = $true
                }

                Mock -CommandName Set-CMClientSettingSoftwareUpdate
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputPresentDefault = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'Default Client Agent Settings'
                        Enable                  = $true
                        ScanStart               = '9/21/2021 16:54'
                        ScanScheduleType        = 'Hours'
                        ScanRecurInterval       = 1
                        EvalStart               = '9/21/2021 16:54'
                        EvalScheduleType        = 'Hours'
                        EvalRecurInterval       = 2
                        EnforceMandatory        = $true
                        TimeUnit                = 'Days'
                        BatchingTimeout         = 4
                        EnableDeltaDownload     = $true
                        DeltaDownloadPort       = 8005
                        Office365ManagementType = 'No'
                        EnableThirdPartyUpdates = $true
                    }

                    $returnDisabled = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'Default Client Agent Settings'
                        Enable                  = $false
                        ScanStart               = $null
                        ScanScheduleType        = $null
                        ScanDayOfWeek           = $null
                        ScanMonthlyWeekOrder    = $null
                        ScanDayofMonth          = $null
                        ScanRecurInterval       = $null
                        EvalStart               = $null
                        EvalScheduleType        = $null
                        EvalDayOfWeek           = $null
                        EvalMonthlyWeekOrder    = $null
                        EvalDayofMonth          = $null
                        EvalRecurInterval       = $null
                        EnforceMandatory        = $null
                        TimeUnit                = $null
                        BatchingTimeout         = $null
                        EnableDeltaDownload     = $null
                        DeltaDownloadPort       = $null
                        Office365ManagementType = $null
                        EnableThirdPartyUpdates = $null
                        ClientSettingStatus     = 'Present'
                        ClientType              = 'Default'
                    }

                    $returnNotConfigured = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'Default Client Agent Settings'
                        Enable                  = $null
                        ScanStart               = $null
                        ScanScheduleType        = $null
                        ScanDayOfWeek           = $null
                        ScanMonthlyWeekOrder    = $null
                        ScanDayofMonth          = $null
                        ScanRecurInterval       = $null
                        EvalStart               = $null
                        EvalScheduleType        = $null
                        EvalDayOfWeek           = $null
                        EvalMonthlyWeekOrder    = $null
                        EvalDayofMonth          = $null
                        EvalRecurInterval       = $null
                        EnforceMandatory        = $null
                        TimeUnit                = $null
                        BatchingTimeout         = $null
                        EnableDeltaDownload     = $null
                        DeltaDownloadPort       = $null
                        Office365ManagementType = $null
                        EnableThirdPartyUpdates = $null
                        ClientSettingStatus     = 'Present'
                        ClientType              = 'Default'
                    }

                    $inputPersentMismatch = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Enable                  = $true
                        ScanStart               = '9/21/2021 16:54'
                        ScanScheduleType        = 'Hours'
                        ScanRecurInterval       = 2
                        EvalStart               = '9/21/2021 16:54'
                        EvalScheduleType        = 'Hours'
                        EvalRecurInterval       = 3
                        EnforceMandatory        = $true
                        TimeUnit                = 'Hours'
                        BatchingTimeout         = 5
                        EnableDeltaDownload     = $true
                        DeltaDownloadPort       = 8006
                        Office365ManagementType = 'NotConfigured'
                        EnableThirdPartyUpdates = $false
                    }

                    $inputDisableExtraParams = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Enable                  = $false
                        Office365ManagementType = 'NotConfigured'
                        EnableThirdPartyUpdates = $false
                    }

                    $inputDeltaHoursExtra = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Enable            = $true
                        EnforceMandatory  = $true
                        TimeUnit          = 'Hours'
                        BatchingTimeout   = 40
                    }

                    $inputDeltaHoursEnforceDisabled = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Enable            = $true
                        EnforceMandatory  = $false
                        TimeUnit          = 'Hours'
                        BatchingTimeout   = 5
                    }

                    $inputEnableDeltaFalse = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $true
                        EnableDeltaDownload = $false
                        DeltaDownloadPort   = 8005
                    }

                    $cmScheduleInput = @{
                        RecurCount    = 1
                        RecurInterval = 'Days'
                    }

                    Mock -CommandName Set-CMSchedule -MockWith { $cmScheduleInput }
                    Mock -CommandName New-CMSchedule -MockWith { $cmScheduleInput }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule -MockWith { $true }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Set-TargetResource @inputPersentMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when current state is not configured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfigured }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when current state is disabled and enabling' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnDisabled }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Set-TargetResource @inputPresentDefault
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when settings to disabled and currently enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule

                    Set-TargetResource @inputDisableExtraParams
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when setting EnabledDelta to false and specifying DeltaDownloadPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule

                    Set-TargetResource @inputEnableDeltaFalse
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when TimeUnit is hours and BatchingTimeout is above 23' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule

                    Set-TargetResource @inputDeltaHoursExtra
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when setting EnforceMandatory to false and specifying TimeUnit or BatchingTimeout' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }
                    Mock -CommandName Test-CMSchedule

                    Set-TargetResource @inputDeltaHoursEnforceDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Enable                  = $null
                        ScanStart               = $null
                        ScanScheduleType        = $null
                        ScanDayOfWeek           = $null
                        ScanMonthlyWeekOrder    = $null
                        ScanDayofMonth          = $null
                        ScanRecurInterval       = $null
                        EvalStart               = $null
                        EvalScheduleType        = $null
                        EvalDayOfWeek           = $null
                        EvalMonthlyWeekOrder    = $null
                        EvalDayofMonth          = $null
                        EvalRecurInterval       = $null
                        EnforceMandatory        = $null
                        TimeUnit                = $null
                        BatchingTimeout         = $null
                        EnableDeltaDownload     = $null
                        DeltaDownloadPort       = $null
                        Office365ManagementType = $null
                        EnableThirdPartyUpdates = $null
                        ClientSettingStatus     = 'Absent'
                        ClientType              = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'UserTest'
                        Enable                  = $null
                        ScanStart               = $null
                        ScanScheduleType        = $null
                        ScanDayOfWeek           = $null
                        ScanMonthlyWeekOrder    = $null
                        ScanDayofMonth          = $null
                        ScanRecurInterval       = $null
                        EvalStart               = $null
                        EvalScheduleType        = $null
                        EvalDayOfWeek           = $null
                        EvalMonthlyWeekOrder    = $null
                        EvalDayofMonth          = $null
                        EvalRecurInterval       = $null
                        EnforceMandatory        = $null
                        TimeUnit                = $null
                        BatchingTimeout         = $null
                        EnableDeltaDownload     = $null
                        DeltaDownloadPort       = $null
                        Office365ManagementType = $null
                        EnableThirdPartyUpdates = $null
                        ClientSettingStatus     = 'Present'
                        ClientType              = 'User'
                    }

                    $clientTypeError = 'Client Settings for software update only applies to Default and Device client settings.'

                    $inputInvalidScanSchedule = @{
                        SiteCode             = 'Lab'
                        ClientSettingName    = 'ClientTest'
                        Enable               = $true
                        ScanDayOfWeek        = 'Monday'
                        ScanMonthlyWeekOrder = 'Second'
                        ScanRecurInterval    = 1
                    }

                    $inputInvalidEvalSchedule = @{
                        SiteCode             = 'Lab'
                        ClientSettingName    = 'ClientTest'
                        Enable               = $true
                        EvalDayOfWeek        = 'Monday'
                        EvalMonthlyWeekOrder = 'Second'
                        EvalRecurInterval    = 1
                    }

                    $scheduleError = 'In order to create a schedule you must specify ScheduleType.'

                    $inputDeltaTrue = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Enable            = $true
                        EnforceMandatory  = $true
                        TimeUnit          = 'Hours'
                    }

                    $missingInPut = 'When settings EnforceMandatory to true you must specify both TimeUnit and BatchingTimeOut.'

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
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when not specifying a schedule type with scan schedule settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    { Set-TargetResource @inputInvalidScanSchedule } | Should -Throw -ExpectedMessage $scheduleError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when not specifying a schedule type with eval schedule settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    { Set-TargetResource @inputInvalidEvalSchedule } | Should -Throw -ExpectedMessage $scheduleError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when enforce is set to true and missing BatchTimeOut' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }

                    { Set-TargetResource @inputDeltaTrue } | Should -Throw -ExpectedMessage $missingInPut
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareUpdate -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareUpdate\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresentDevice = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $true
                    ScanStart               = '9/21/2021 16:54'
                    ScanScheduleType        = 'Hours'
                    ScanDayOfWeek           = $null
                    ScanMonthlyWeekOrder    = $null
                    ScanDayofMonth          = $null
                    ScanRecurInterval       = 1
                    EvalStart               = '9/21/2021 16:54'
                    EvalScheduleType        = 'Hours'
                    EvalDayOfWeek           = $null
                    EvalMonthlyWeekOrder    = $null
                    EvalDayofMonth          = $null
                    EvalRecurInterval       = 2
                    EnforceMandatory        = $true
                    TimeUnit                = 'Days'
                    BatchingTimeout         = 4
                    EnableDeltaDownload     = $true
                    DeltaDownloadPort       = 8005
                    Office365ManagementType = 'Yes'
                    EnableThirdPartyUpdates = $true
                    ClientSettingStatus     = 'Present'
                    ClientType              = 'Device'
                }

                $returnDisabled = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'Default Client Agent Settings'
                    Enable                  = $false
                    ScanStart               = $null
                    ScanScheduleType        = $null
                    ScanDayOfWeek           = $null
                    ScanMonthlyWeekOrder    = $null
                    ScanDayofMonth          = $null
                    ScanRecurInterval       = $null
                    EvalStart               = $null
                    EvalScheduleType        = $null
                    EvalDayOfWeek           = $null
                    EvalMonthlyWeekOrder    = $null
                    EvalDayofMonth          = $null
                    EvalRecurInterval       = $null
                    EnforceMandatory        = $null
                    TimeUnit                = $null
                    BatchingTimeout         = $null
                    EnableDeltaDownload     = $null
                    DeltaDownloadPort       = $null
                    Office365ManagementType = $null
                    EnableThirdPartyUpdates = $null
                    ClientSettingStatus     = 'Present'
                    ClientType              = 'Default'
                }

                $returnAbsent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $null
                    ScanStart               = $null
                    ScanScheduleType        = $null
                    ScanDayOfWeek           = $null
                    ScanMonthlyWeekOrder    = $null
                    ScanDayofMonth          = $null
                    ScanRecurInterval       = $null
                    EvalStart               = $null
                    EvalScheduleType        = $null
                    EvalDayOfWeek           = $null
                    EvalMonthlyWeekOrder    = $null
                    EvalDayofMonth          = $null
                    EvalRecurInterval       = $null
                    EnforceMandatory        = $null
                    TimeUnit                = $null
                    BatchingTimeout         = $null
                    EnableDeltaDownload     = $null
                    DeltaDownloadPort       = $null
                    Office365ManagementType = $null
                    EnableThirdPartyUpdates = $null
                    ClientSettingStatus     = 'Absent'
                    ClientType              = $null
                }

                $returnUser = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'UserTest'
                    Enable                  = $null
                    ScanStart               = $null
                    ScanScheduleType        = $null
                    ScanDayOfWeek           = $null
                    ScanMonthlyWeekOrder    = $null
                    ScanDayofMonth          = $null
                    ScanRecurInterval       = $null
                    EvalStart               = $null
                    EvalScheduleType        = $null
                    EvalDayOfWeek           = $null
                    EvalMonthlyWeekOrder    = $null
                    EvalDayofMonth          = $null
                    EvalRecurInterval       = $null
                    EnforceMandatory        = $null
                    TimeUnit                = $null
                    BatchingTimeout         = $null
                    EnableDeltaDownload     = $null
                    DeltaDownloadPort       = $null
                    Office365ManagementType = $null
                    EnableThirdPartyUpdates = $null
                    ClientSettingStatus     = 'Present'
                    ClientType              = 'User'
                }

                $inputPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $true
                    ScanStart               = '9/21/2021 16:54'
                    ScanScheduleType        = 'Hours'
                    ScanRecurInterval       = 1
                    EvalStart               = '9/21/2021 16:54'
                    EvalScheduleType        = 'Hours'
                    EvalRecurInterval       = 2
                    EnforceMandatory        = $true
                    TimeUnit                = 'Days'
                    BatchingTimeout         = 4
                    EnableDeltaDownload     = $true
                    DeltaDownloadPort       = 8005
                    Office365ManagementType = 'Yes'
                    EnableThirdPartyUpdates = $true
                }

                $inputPersentMismatch = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $true
                    ScanStart               = '9/21/2021 16:54'
                    ScanScheduleType        = 'Hours'
                    ScanRecurInterval       = 2
                    EvalStart               = '9/21/2021 16:54'
                    EvalScheduleType        = 'Hours'
                    EvalRecurInterval       = 3
                    EnforceMandatory        = $true
                    TimeUnit                = 'Hours'
                    BatchingTimeout         = 5
                    EnableDeltaDownload     = $true
                    DeltaDownloadPort       = 8006
                    Office365ManagementType = 'No'
                    EnableThirdPartyUpdates = $false
                }

                $inputInvalidScanSchedule = @{
                    SiteCode             = 'Lab'
                    ClientSettingName    = 'ClientTest'
                    Enable               = $true
                    ScanDayOfWeek        = 'Monday'
                    ScanMonthlyWeekOrder = 'Second'
                    ScanRecurInterval    = 1
                }

                $inputInvalidEvalSchedule = @{
                    SiteCode             = 'Lab'
                    ClientSettingName    = 'ClientTest'
                    Enable               = $true
                    EvalDayOfWeek        = 'Monday'
                    EvalMonthlyWeekOrder = 'Second'
                    EvalRecurInterval    = 1
                }

                $inputDisable = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $false
                }

                $inputDisableExtraParams = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Enable                  = $false
                    Office365ManagementType = 'No'
                    EnableThirdPartyUpdates = $false
                }

                $inputDeltaTrue = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                    EnforceMandatory  = $true
                    TimeUnit          = 'Hours'
                }

                $inputDeltaHoursExtra = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                    EnforceMandatory  = $true
                    TimeUnit          = 'Hours'
                    BatchingTimeout   = 40
                }

                $inputDeltaHoursMissingEnforce = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                    TimeUnit          = 'Hours'
                    BatchingTimeout   = 5
                }

                $inputEnableDeltaFalse = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $true
                    EnableDeltaDownload = $false
                    DeltaDownloadPort   = 8005
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputPersentMismatch | Should -Be $false
                }

                It 'Should return desired result false when specifying a scan schedule with no ScheduleType' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputInvalidScanSchedule | Should -Be $false
                }

                It 'Should return desired result false when specifying an eval schedule with no ScheduleType' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputInvalidEvalSchedule | Should -Be $false
                }

                It 'Should return desired result false when enabled and expected disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDisable | Should -Be $false
                }

                It 'Should return desired result false when enabled and expected disabled and adding unneeded params' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDisableExtraParams | Should -Be $false
                }

                It 'Should return desired result false when enforce is set to true and missing BatchTimeOut' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDeltaTrue | Should -Be $false
                }

                It 'Should return desired result false when enforce is set to true TimeUnit set to hours and BatchTimeOut is over 23' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDeltaHoursExtra | Should -Be $false
                }

                It 'Should return desired result true when enforce is set to false and TimeUnit and BatchTimeOut is specified and do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputDeltaHoursMissingEnforce | Should -Be $true
                }

                It 'Should return desired result false when EnableDelta is set to false and specifying DeltaDownloadPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDevice }

                    Test-TargetResource @inputEnableDeltaFalse | Should -Be $false
                }

                It 'Should return desired result false when client setting specified is for user settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client setting is absent' {
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
