[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMHeartbeatDiscovery'

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

        Describe 'ConfigMgrCBDsc - DSC_CMHeartbeatDiscovery\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $standardGetDiscoveryOutput = @{
                    Props = @(
                        @{
                            PropertyName = 'Enable Heartbeat DDR'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'DDR Refresh Interval'
                            Value2       = '0001200000100038'
                        }
                    )
                }

                $standardGetInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                $convertScheduleDays = @{
                    Interval = 'Days'
                    Count    = 7
                }

                $convertScheduleHours = @{
                    Interval = 'Hours'
                    Count    = 8
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {

                It 'Should return desired result for hearbeat discovery days' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryOutput }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $convertScheduleDays }

                    $result = Get-TargetResource @standardGetInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled          | Should -Be -ExpectedValue $true
                    $result.ScheduleInterval | Should -Be -ExpectedValue 'Days'
                    $result.ScheduleCount    | Should -Be -ExpectedValue 7
                }

                It 'Should return desired result for hearbeat discovery hours' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryOutput }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $convertScheduleHours }

                    $result = Get-TargetResource @standardGetInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled          | Should -Be -ExpectedValue $true
                    $result.ScheduleInterval | Should -Be -ExpectedValue 'Hours'
                    $result.ScheduleCount    | Should -Be -ExpectedValue 8
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMHeartbeatDiscovery\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnEnabledDaysMismatch = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                    ScheduleCount    = 6
                }

                $getReturnEnabledDays = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                    ScheduleCount    = 7
                }

                $getReturnEnabledHours = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Hours'
                    ScheduleCount    = 7
                }

                $getReturnDisabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $inputScheduleNoCount = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                }

                $standardGetInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                $scheduleConvertDaysMismatch = @{
                    DayDuration    = 0
                    DaySpan        = 6
                    HourDuration   = 0
                    HourSpan       = 0
                    MinuteDuration = 0
                    MinuteSpan     = 0
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDiscoveryMethod
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands enabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @standardGetInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands enabling discovery and changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch }

                    Set-TargetResource @returnEnabledDaysMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands disabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @getReturnDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {

                It 'Should call expected commands and throw when setting schedule interval without count' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule
                    MOck -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputScheduleNoCount } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if query membership throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule
                    MOck -CommandName Set-CMDiscoveryMethod -MockWith { throw }

                    { Set-TargetResource @getReturnDisabled } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands enabling discovery and changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule -MockWith { throw }

                    { Set-TargetResource @returnEnabledDaysMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMHeartbeatDiscovery\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnEnabledDaysMismatch = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                    ScheduleCount    = 6
                }

                $getReturnEnabledDays = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                    ScheduleCount    = 7
                }

                $getReturnEnabledHours = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Hours'
                    ScheduleCount    = 7
                }

                $getReturnDisabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $inputScheduleNoCount = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource device settings and Heartbeat Discovery is enabled' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                }

                It 'Should return desired result true schedule matches' {
                    Test-TargetResource @getReturnEnabledDays | Should -Be $true
                }

                It 'Should return desired result false schedule days mismatch' {
                    Test-TargetResource @returnEnabledDaysMismatch | Should -Be $false
                }

                It 'Should return desired result false schedule hours mismatch' {
                    Test-TargetResource @getReturnEnabledHours | Should -Be $false
                }

                It 'Should return desired result false when setting is enabled and disabled expected disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $false
                }

                It 'Should return desired result false when setting schedule interval without count' {
                    Test-TargetResource @inputScheduleNoCount | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource device settings and Heartbeat Discovery is disabled' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                }

                It 'Should return desired result true when discovery is disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
