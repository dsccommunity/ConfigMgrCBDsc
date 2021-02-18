[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMMaintenanceWindows'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

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
$testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe "ConfigMgrCBDsc - DSC_CMMaintenanceWindows\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mwReturnMonthlyByWeek = @{
                    Description            = 'Occurs the Second Tuesday of every 1 months effective 2/1/2021 12:00 AM'
                    Duration               = 60
                    IsEnabled              = $true
                    IsGMT                  = $false
                    Name                   = 'MW1'
                    RecurrenceType         = 2
                    ServiceWindowID        = '{29BC0579-6608-463B-BD09-939AC1507A38}'
                    ServiceWindowSchedules = '00012CC008231400'
                    ServiceWindowType      = 5
                    StartTime              = '2/1/2021 12:00:00 AM'
                }

                $monthlyByWeekReturn = @{
                    MonthDay       = $null
                    ScheduleType   = 'MonthlyByWeek'
                    RecurInterval  = 1
                    DayOfWeek      = 'Tuesday'
                    Start          = '2/1/2021 00:00'
                    WeekOrder      = 'Second'
                    DayDuration    = $null
                    HourDuration   = 1
                    MinuteDuration = $null
                }

                $mwReturnMonthlyByDay = @{
                    Description            = 'Occurs day 9 of every 1 months effective 2/1/2021 12:00 AM'
                    Duration               = 60
                    IsEnabled              = $true
                    IsGMT                  = $false
                    Name                   = 'MW1'
                    RecurrenceType         = 5
                    ServiceWindowID        = '{29BC0579-6608-463B-BD09-939AC1507A38}'
                    ServiceWindowSchedules = '00012CC008231400'
                    ServiceWindowType      = 4
                    StartTime              = '2/1/2021 12:00:00 AM'
                }

                $monthlyByDayReturn = @{
                    MonthDay       = 9
                    ScheduleType   = 'MonthlyByDay'
                    RecurInterval  = 1
                    DayOfWeek      = $null
                    Start          = '2/1/2021 00:00'
                    WeekOrder      = $null
                    DayDuration    = $null
                    HourDuration   = 1
                    MinuteDuration = $null
                }

                $mwReturnWeekly = @{
                    Description            = 'Occurs every 2 weeks on Monday effective 2/1/2021 12:00 AM'
                    Duration               = 60
                    IsEnabled              = $true
                    IsGMT                  = $false
                    Name                   = 'MW1'
                    RecurrenceType         = 5
                    ServiceWindowID        = '{29BC0579-6608-463B-BD09-939AC1507A38}'
                    ServiceWindowSchedules = '00012CC008231400'
                    ServiceWindowType      = 1
                    StartTime              = '2/1/2021 12:00:00 AM'
                }

                $weeklyReturn = @{
                    MonthDay       = $null
                    ScheduleType   = 'Weekly'
                    RecurInterval  = 2
                    DayOfWeek      = 'Monday'
                    Start          = '2/1/2021 00:00'
                    WeekOrder      = $null
                    DayDuration    = $null
                    HourDuration   = 1
                    MinuteDuration = $null
                }

                $getInput = @{
                    SiteCode       = 'Lab'
                    CollectionName = 'Test'
                    Name           = 'MW1'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMCollection -MockWith { $true }
            }

            Context 'When retrieving User Discovery settings' {

                It 'Should return desired result when MonthlyByWeekly Schedule returned' {
                    Mock -CommandName Get-CMMaintenanceWindow -MockWith { $mwReturnMonthlyByWeek }
                    Mock -CommandName Get-CMSchedule -MockWith { $monthlyByWeekReturn }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName     | Should -Be -ExpectedValue 'Test'
                    $result.Name               | Should -Be -ExpectedValue 'MW1'
                    $result.ServiceWindowsType | Should -Be -ExpectedValue 'TaskSequencesOnly'
                    $result.IsEnabled          | Should -Be -ExpectedValue $true
                    $result.Ensure             | Should -Be -ExpectedValue 'Present'
                    $result.HourDuration       | Should -Be -ExpectedValue 1
                    $result.MinuteDuration     | Should -Be -ExpectedValue $null
                    $result.Start              | Should -Be -ExpectedValue '2/1/2021 00:00'
                    $result.ScheduleType       | Should -Be -ExpectedValue 'MonthlyByWeek'
                    $result.DayOfWeek          | Should -Be -ExpectedValue 'Tuesday'
                    $result.MonthlyWeekOrder   | Should -Be -ExpectedValue 'Second'
                    $result.DayOfMonth         | Should -Be -ExpectedValue $null
                    $result.RecurInterval      | Should -Be -ExpectedValue 1
                    $result.Description        | Should -Be -ExpectedValue 'Occurs the Second Tuesday of every 1 months effective 2/1/2021 12:00 AM'
                    $result.CollectionStatus   | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when MonthlyByDay Schedule returned' {
                    Mock -CommandName Get-CMMaintenanceWindow -MockWith { $mwReturnMonthlyByDay }
                    Mock -CommandName Get-CMSchedule -MockWith { $monthlyByDayReturn }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName     | Should -Be -ExpectedValue 'Test'
                    $result.Name               | Should -Be -ExpectedValue 'MW1'
                    $result.ServiceWindowsType | Should -Be -ExpectedValue 'SoftwareUpdatesOnly'
                    $result.IsEnabled          | Should -Be -ExpectedValue $true
                    $result.Ensure             | Should -Be -ExpectedValue 'Present'
                    $result.HourDuration       | Should -Be -ExpectedValue 1
                    $result.MinuteDuration     | Should -Be -ExpectedValue $null
                    $result.Start              | Should -Be -ExpectedValue '2/1/2021 00:00'
                    $result.ScheduleType       | Should -Be -ExpectedValue 'MonthlyByDay'
                    $result.DayOfWeek          | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder   | Should -Be -ExpectedValue $null
                    $result.DayOfMonth         | Should -Be -ExpectedValue 9
                    $result.RecurInterval      | Should -Be -ExpectedValue 1
                    $result.Description        | Should -Be -ExpectedValue 'Occurs day 9 of every 1 months effective 2/1/2021 12:00 AM'
                    $result.CollectionStatus   | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when Weekly Schedule returned' {
                    Mock -CommandName Get-CMMaintenanceWindow -MockWith { $mwReturnWeekly }
                    Mock -CommandName Get-CMSchedule -MockWith { $weeklyReturn }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName     | Should -Be -ExpectedValue 'Test'
                    $result.Name               | Should -Be -ExpectedValue 'MW1'
                    $result.ServiceWindowsType | Should -Be -ExpectedValue 'Any'
                    $result.IsEnabled          | Should -Be -ExpectedValue $true
                    $result.Ensure             | Should -Be -ExpectedValue 'Present'
                    $result.HourDuration       | Should -Be -ExpectedValue 1
                    $result.MinuteDuration     | Should -Be -ExpectedValue $null
                    $result.Start              | Should -Be -ExpectedValue '2/1/2021 00:00'
                    $result.ScheduleType       | Should -Be -ExpectedValue 'Weekly'
                    $result.DayOfWeek          | Should -Be -ExpectedValue 'Monday'
                    $result.MonthlyWeekOrder   | Should -Be -ExpectedValue $null
                    $result.DayOfMonth         | Should -Be -ExpectedValue $null
                    $result.RecurInterval      | Should -Be -ExpectedValue 2
                    $result.Description        | Should -Be -ExpectedValue 'Occurs every 2 weeks on Monday effective 2/1/2021 12:00 AM'
                    $result.CollectionStatus   | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when collection and maintenance window does not exist' {
                    Mock -CommandName Get-CMMaintenanceWindow -MockWith { $null }
                    Mock -CommandName Get-CMSchedule
                    Mock -CommandName Get-CMCollection -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName     | Should -Be -ExpectedValue 'Test'
                    $result.Name               | Should -Be -ExpectedValue 'MW1'
                    $result.ServiceWindowsType | Should -Be -ExpectedValue $null
                    $result.IsEnabled          | Should -Be -ExpectedValue $null
                    $result.Ensure             | Should -Be -ExpectedValue 'Absent'
                    $result.HourDuration       | Should -Be -ExpectedValue $null
                    $result.MinuteDuration     | Should -Be -ExpectedValue $null
                    $result.Start              | Should -Be -ExpectedValue $null
                    $result.ScheduleType       | Should -Be -ExpectedValue $null
                    $result.DayOfWeek          | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder   | Should -Be -ExpectedValue $null
                    $result.DayOfMonth         | Should -Be -ExpectedValue $null
                    $result.RecurInterval      | Should -Be -ExpectedValue $null
                    $result.Description        | Should -Be -ExpectedValue $null
                    $result.CollectionStatus   | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMMaintenanceWindows\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $nullGetReturn = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = $null
                    IsEnabled          = $null
                    Ensure             = 'Absent'
                    HourDuration       = $null
                    MinuteDuration     = $null
                    Start              = $null
                    ScheduleType       = $null
                    DayOfWeek          = $null
                    MonthlyWeekOrder   = $null
                    DayOfMonth         = $null
                    RecurInterval      = $null
                    CollectionStatus   = 'Present'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMSchedule -MockWith { $true }
                Mock -CommandName New-CMMaintenanceWindow
                Mock -CommandName Set-CMMaintenanceWindow
                Mock -CommandName Remove-CMMaintenanceWindow
                Mock -CommandName Set-CMSchedule -MockWith { $cmScheduleInput }
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $monthlyByWeekReturn = @{
                        SiteCode           = 'Lab'
                        CollectionName     = 'Test'
                        Name               = 'MW1'
                        ServiceWindowsType = 'Any'
                        IsEnabled          = $true
                        Ensure             = 'Present'
                        HourDuration       = 1
                        MinuteDuration     = $null
                        Start              = '2/2/2021 00:00'
                        ScheduleType       = 'MonthlyByWeek'
                        DayOfWeek          = 'Sunday'
                        MonthlyWeekOrder   = 'Second'
                        DayOfMonth         = $null
                        RecurInterval      = 1
                        CollectionStatus   = 'Present'
                    }

                    $inputMisMatch = @{
                        SiteCode           = 'Lab'
                        CollectionName     = 'Test'
                        Name               = 'MW1'
                        ServiceWindowsType = 'Any'
                        IsEnabled          = $false
                        Ensure             = 'Present'
                        MinuteDuration     = 10
                        Start              = '2/2/2021 00:00'
                        ScheduleType       = 'Weekly'
                        DayOfWeek          = 'Friday'
                        MonthlyWeekOrder   = 'Second'
                        RecurInterval      = 2
                    }

                    $inputAbsent = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        Name           = 'MW1'
                        Ensure         = 'Absent'
                    }

                    $cmScheduleInput = @{
                        RecurCount    = 1
                        RecurInterval = 'Days'
                    }
                }

                It 'Should call expected commands for disabling User Discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $monthlyByWeekReturn }
                    Mock -CommandName Test-CMSchedule

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 0 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for modifying a maintenance window' {
                    Mock -CommandName Get-TargetResource -MockWith { $monthlyByWeekReturn }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 0 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for creating a new maintenance window' {
                    Mock -CommandName Get-TargetResource -MockWith { $nullGetReturn }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 1 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $nullCollectionReturn = @{
                        SiteCode           = 'Lab'
                        CollectionName     = 'Test'
                        Name               = 'MW1'
                        ServiceWindowsType = $null
                        IsEnabled          = $null
                        Ensure             = 'Absent'
                        HourDuration       = $null
                        MinuteDuration     = $null
                        Start              = $null
                        ScheduleType       = $null
                        DayOfWeek          = $null
                        MonthlyWeekOrder   = $null
                        DayOfMonth         = $null
                        RecurInterval      = $null
                        CollectionStatus   = 'Absent'
                    }

                    $inputParamsForTesting = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        Name           = 'MW1'
                        ScheduleType   = 'MonthlyByDay'
                        DayOfMonth     = 1
                    }

                    $inputParamsDuration = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        Name           = 'MW1'
                        ScheduleType   = 'MonthlyByDay'
                        DayOfMonth     = 1
                        HourDuration   = 12
                        MinuteDuration = 59
                    }

                    $missingCollectionError = 'Collection Test does not exist and will not be able to create Maintenance Windows.'
                    $missingParams = 'Maintenance Window MW1 does not exist, need to specify a ScheduleType and a duration to create a new maintence window.'
                    $durationError = 'Currently, you can only specify Hour or Minute you can not specify both settings.'
                }

                It 'Should call expected when creating a maintenance window and collection does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $nullCollectionReturn }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    { Set-TargetResource @inputParamsForTesting } | Should -Throw -ExpectedMessage $missingCollectionError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 0 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when creating a maintenance window and not specifying duration' {
                    Mock -CommandName Get-TargetResource -MockWith { $nullGetReturn }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    { Set-TargetResource @inputParamsForTesting } | Should -Throw -ExpectedMessage $missingParams
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 0 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when creating a maintenance window specifying minutes and hour duration' {
                    Mock -CommandName Get-TargetResource -MockWith { $nullGetReturn }
                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    { Set-TargetResource @inputParamsDuration } | Should -Throw -ExpectedMessage $durationError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMMaintenanceWindow -Times 0 -Scope It
                    Assert-MockCalled Set-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMMaintenanceWindows\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $monthlyByWeekReturn = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = 'Any'
                    IsEnabled          = $true
                    Ensure             = 'Present'
                    HourDuration       = $null
                    MinuteDuration     = 30
                    Start              = '2/2/2021 00:00'
                    ScheduleType       = 'MonthlyByWeek'
                    DayOfWeek          = 'Sunday'
                    MonthlyWeekOrder   = 'Second'
                    DayOfMonth         = $null
                    RecurInterval      = 1
                    CollectionStatus   = 'Present'
                }

                $inputMonthlyByWeekReturn = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = 'Any'
                    Ensure             = 'Present'
                    MinuteDuration     = 30
                    Start              = '2/2/2021 00:00'
                    ScheduleType       = 'MonthlyByWeek'
                    MonthlyWeekOrder   = 'Second'
                    DayOfWeek          = 'Sunday'
                    RecurInterval      = 1
                }

                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    CollectionName = 'Test'
                    Name           = 'MW1'
                    Ensure         = 'Absent'
                }

                $getReturnAbsent = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = $null
                    IsEnabled          = $null
                    Ensure             = 'Absent'
                    HourDuration       = $null
                    MinuteDuration     = $null
                    Start              = $null
                    ScheduleType       = $null
                    DayOfWeek          = $null
                    MonthlyWeekOrder   = $null
                    DayOfMonth         = $null
                    RecurInterval      = $null
                    CollectionStatus   = 'Absent'
                }

                $getMWReturnAbsent = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = $null
                    IsEnabled          = $null
                    Ensure             = 'Absent'
                    HourDuration       = $null
                    MinuteDuration     = $null
                    Start              = $null
                    ScheduleType       = $null
                    DayOfWeek          = $null
                    MonthlyWeekOrder   = $null
                    DayOfMonth         = $null
                    RecurInterval      = $null
                    CollectionStatus   = 'Present'
                }

                $inputMissingParams = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = 'Any'
                    Ensure             = 'Present'
                    Start              = '2/2/2021 00:00'
                    ScheduleType       = 'MonthlyByWeek'
                    MonthlyWeekOrder   = 'Second'
                    DayOfWeek          = 'Sunday'
                    RecurInterval      = 1
                }

                $inputScheduleTypeParam = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = 'Any'
                    Ensure             = 'Present'
                    Start              = '2/2/2021 00:00'
                    MonthlyWeekOrder   = 'Second'
                    DayOfWeek          = 'Sunday'
                    RecurInterval      = 1
                }

                $inputMixedDuration = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ScheduleType       = 'None'
                    HourDuration       = 1
                    MinuteDuration     = 10
                }

                $inputNotMatch = @{
                    SiteCode           = 'Lab'
                    CollectionName     = 'Test'
                    Name               = 'MW1'
                    ServiceWindowsType = 'TaskSequencesOnly'
                    Ensure             = 'Present'
                    HourDuration       = 10
                    Start              = '2/2/2021 02:00'
                    ScheduleType       = 'Weekly'
                    DayOfWeek          = 'Sunday'
                    RecurInterval      = 3
                    IsEnabled          = $false
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource with returned schedule settings' {

                It 'Should return desired result true when settings match for monthly schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $monthlyByWeekReturn }

                    Test-TargetResource @inputMonthlyByWeekReturn | Should -Be $true
                }

                It 'Should return desired result false Present and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $monthlyByWeekReturn }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false Collection Absent and expected collection present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputMonthlyByWeekReturn | Should -Be $false
                }

                It 'Should return desired result false Maintenance Absent and expected present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getMWReturnAbsent }

                    Test-TargetResource @inputMonthlyByWeekReturn | Should -Be $false
                }

                It 'Should return desired result false Maintenance Absent and missing required params to create new Maintence Window' {
                    Mock -CommandName Get-TargetResource -MockWith { $getMWReturnAbsent }

                    Test-TargetResource @inputMissingParams | Should -Be $false
                }

                It 'Should return desired result false Maintenance Absent and missing ScheduleType to create new Maintence Window' {
                    Mock -CommandName Get-TargetResource -MockWith { $getMWReturnAbsent }

                    Test-TargetResource @inputScheduleTypeParam | Should -Be $false
                }

                It 'Should return desired result false when duration contains Hour and minutes' {
                    Mock -CommandName Get-TargetResource -MockWith { $getMWReturnAbsent }

                    Test-TargetResource @inputMixedDuration | Should -Be $false
                }

                It 'Should return desired result false when information does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $monthlyByWeekReturn }

                    Test-TargetResource @inputNotMatch | Should -Be $false
                }
            }
        }
    }
}
catch
{
    Invoke-TestCleanup
}
