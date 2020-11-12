param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMForestDiscovery'

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
        Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $standardGetInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                $standardGetFalse = @{
                    Props = @(
                        @{
                            PropertyName = 'Startup Schedule'
                            Value1       = '0001200000100038'
                        }
                        @{
                            PropertyName = 'SETTINGS'
                            Value1       = 'Active'
                        }
                        @{
                            PropertyName = 'Enable AD Site Boundary Creation'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Enable Subnet Boundary Creation'
                            Value        = 0
                        }
                    )
                }

                $standardGetTrue = @{
                    Props = @(
                        @{
                            PropertyName = 'Startup Schedule'
                            Value1       = '0001200000100037'
                        }
                        @{
                            PropertyName = 'SETTINGS'
                            Value1       = 'Active'
                        }
                        @{
                            PropertyName = 'Enable AD Site Boundary Creation'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enable Subnet Boundary Creation'
                            Value        = 1
                        }
                    )
                }

                $intervalDays = @{
                    Interval = 'Days'
                    Count    = 7
                }

                $intervalHours = @{
                    Interval = 'Hours'
                    Count    = 5
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {

                It 'Should return desired result for forest discovery for days' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetFalse }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $intervalDays }

                    $result = Get-TargetResource @standardGetInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                                   | Should -Be -ExpectedValue $true
                    $result.EnableActiveDirectorySiteBoundaryCreation | Should -Be -ExpectedValue $false
                    $result.EnableSubnetBoundaryCreation              | Should -Be -ExpectedValue $false
                    $result.ScheduleInterval                          | Should -Be -ExpectedValue 'Days'
                    $result.ScheduleCount                             | Should -Be -ExpectedValue 7
                }

                It 'Should return desired result for forest discovery for hours' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetTrue }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $intervalHours }

                    $result = Get-TargetResource @standardGetInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                                   | Should -Be -ExpectedValue $true
                    $result.EnableActiveDirectorySiteBoundaryCreation | Should -Be -ExpectedValue $true
                    $result.EnableSubnetBoundaryCreation              | Should -Be -ExpectedValue $true
                    $result.ScheduleInterval                          | Should -Be -ExpectedValue 'Hours'
                    $result.ScheduleCount                             | Should -Be -ExpectedValue 5
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnEnabledDays = @{
                    SiteCode                                  = 'Lab'
                    Enabled                                   = $true
                    EnableActiveDirectorySiteBoundaryCreation = $true
                    EnableSubnetBoundaryCreation              = $true
                    ScheduleInterval                          = 'Days'
                    ScheduleCount                             = 7
                }

                $getReturnDisabled = @{
                    SiteCode                                  = 'Lab'
                    Enabled                                   = $false
                    EnableActiveDirectorySiteBoundaryCreation = $true
                    EnableSubnetBoundaryCreation              = $true
                    ScheduleInterval                          = 'Days'
                    ScheduleCount                             = 7
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDiscoveryMethod
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $standardGetInput = @{
                        SiteCode                                  = 'Lab'
                        Enabled                                   = $true
                        EnableActiveDirectorySiteBoundaryCreation = $false
                        EnableSubnetBoundaryCreation              = $false
                        ScheduleInterval                          = 'Days'
                        ScheduleCount                             = 5
                    }

                    $scheduleConvertDays = @{
                        DayDuration    = 0
                        DaySpan        = 31
                        HourDuration   = 0
                        HourSpan       = 0
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }

                    $standardGetHourInput = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'Hours'
                        ScheduleCount    = 24
                    }

                    $standardGetDayInput = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'Days'
                        ScheduleCount    = 40
                    }

                    $scheduleConvertHours = @{
                        DayDuration    = 0
                        DaySpan        = 0
                        HourDuration   = 0
                        HourSpan       = 23
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }

                    $setSettingDisable = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }
                }

                It 'Should call expected commands enabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }

                    Set-TargetResource @standardGetInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands enabling discovery and changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertHours }

                    Set-TargetResource @standardGetHourInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when changing the days schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }

                    Set-TargetResource @standardGetDayInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands disabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @setSettingDisable
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $missingScheduleParam = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'Days'
                    }

                    $invalidParamError = 'Invalid parameter usage must specify ScheduleInterval and ScheduleCount.'
                }

                It 'Should call expected commands when schedule parameters are not correct' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName New-CMSchedule

                    { Set-TargetResource @missingScheduleParam } | Should -Throw -ExpectedMessage $invalidParamError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMDiscoveryMethod throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod -MockWith { throw }

                    { Set-TargetResource @getReturnDisabled } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnEnabledDays = @{
                    SiteCode                                  = 'Lab'
                    Enabled                                   = $true
                    EnableActiveDirectorySiteBoundaryCreation = $true
                    EnableSubnetBoundaryCreation              = $true
                    ScheduleInterval                          = 'Days'
                    ScheduleCount                             = 7
                }

                $getReturnDisabled = @{
                    SiteCode                                  = 'Lab'
                    Enabled                                   = $false
                    EnableActiveDirectorySiteBoundaryCreation = $true
                    EnableSubnetBoundaryCreation              = $true
                    ScheduleInterval                          = 'Days'
                    ScheduleCount                             = 7
                }

                $daysMismatch = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                    ScheduleCount    = 6
                }

                $hoursMismatch = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Hours'
                    ScheduleCount    = 24
                }

                $disabledMismatch = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $settingsMismatch = @{
                    SiteCode                                  = 'Lab'
                    Enabled                                   = $true
                    EnableActiveDirectorySiteBoundaryCreation = $false
                    EnableSubnetBoundaryCreation              = $false
                    ScheduleInterval                          = 'Days'
                    ScheduleCount                             = 50
                }

                $missingScheduleParam = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Days'
                }

                Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource device settings' {

                It 'Should return desired result true schedule matches' {
                    Test-TargetResource @getReturnEnabledDays | Should -Be $true
                }

                It 'Should return desired result false schedule days mismatch' {
                    Test-TargetResource @daysMismatch | Should -Be $false
                }

                It 'Should return desired result false schedule hours mismatch' {
                    Test-TargetResource @hoursMismatch | Should -Be $false
                }

                It 'Should return desired state false when settings mismatch' {
                    Test-TargetResource @settingsMismatch | Should -Be $false
                }

                It 'Should return desired result false when setting is enabled and disabled expected disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $false
                }

                It 'Should return desired state false when all schedule params are not specified' {
                    Test-TargetResource @missingScheduleParam | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
