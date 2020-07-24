[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMUserDiscovery'

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
        Describe "ConfigMgrCBDsc - DSC_CMUserDiscovery\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $getInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                $getCMDiscoveryEnabled = @{
                    Props = @(
                        @{
                            PropertyName = 'Enable Incremental Sync'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Startup Schedule'
                            Value1       = '000120000015A000'
                        }
                        @{
                            PropertyName = 'Full Sync Schedule'
                            Value1       = '000120000015A000'
                        }
                        @{
                            PropertyName = 'Settings'
                            Value1       = 'Active'
                        }
                    )
                    PropLists = @(
                        @{
                            PropertyListName = 'AD Containers'
                            Values           = @(
                                'LDAP://OU=Test,DC=contoso,DC=com'
                                '0'
                                '1'
                                'LDAP://OU=Test1,DC=contoso,DC=com'
                                '0'
                                '1'
                            )
                        }
                    )
                }

                $getCMDiscoveryDisabled = @{
                    Props = @(
                        @{
                            PropertyName = 'Enable Incremental Sync'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Startup Schedule'
                            Value1       = '000120000015A000'
                        }
                        @{
                            PropertyName = 'Full Sync Schedule'
                            Value1       = '000120000015A000'
                        }
                        @{
                            PropertyName = 'Settings'
                            Value1       = 'Active'
                        }
                    )
                    PropLists = @(
                        @{
                            PropertyListName = 'AD Containers'
                            Values           = @(
                                'LDAP://OU=Test,DC=contoso,DC=com'
                                '0'
                                '1'
                                'LDAP://OU=Test1,DC=contoso,DC=com'
                                '0'
                                '1'
                            )
                        }
                    )
                }

                $adContainersReturn = @(
                    'LDAP://OU=Test,DC=contoso,DC=com'
                    'LDAP://OU=Test1,DC=contoso,DC=com'
                )

                $intervalDays = @{
                    Interval = 'Days'
                    Count    = '7'
                }

                $intervalHours = @{
                    Interval = 'Hours'
                    Count    = 5
                }

                $intervalNone = @{
                    Interval = 'None'
                    Count    = $null
                }

                $cmScheduleHours = @{
                    DayDuration    = 0
                    DaySpan        = 0
                    HourDuration   = 0
                    HourSpan       = 1
                    IsGMT          = $false
                    MinuteDuration = 0
                    MinuteSpan     = 0
                }

                $cmScheduleMins = @{
                    DayDuration    = 0
                    DaySpan        = 0
                    HourDuration   = 0
                    HourSpan       = 0
                    IsGMT          = $false
                    MinuteDuration = 0
                    MinuteSpan     = 45
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving User Discovery settings' {

                It 'Should return desired result when delta schedule returns hour' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryEnabled }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $intervalDays }
                    Mock -CommandName Convert-CMSchedule -MockWith { $cmScheduleHours }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery | Should -Be -ExpectedValue $true
                    $result.DeltaDiscoveryMins   | Should -Be -ExpectedValue 60
                    $result.ADContainers         | Should -Be -ExpectedValue $adContainersReturn
                    $result.ScheduleInterval     | Should -Be -ExpectedValue 'Days'
                    $result.ScheduleCount        | Should -Be -ExpectedValue 7
                }

                It 'Should return desired result when delta schedule returns minutes' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryEnabled }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $intervalHours }
                    Mock -CommandName Convert-CMSchedule -MockWith { $cmScheduleMins }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery | Should -Be -ExpectedValue $true
                    $result.DeltaDiscoveryMins   | Should -Be -ExpectedValue 45
                    $result.ADContainers         | Should -Be -ExpectedValue $adContainersReturn
                    $result.ScheduleInterval     | Should -Be -ExpectedValue 'Hours'
                    $result.ScheduleCount        | Should -Be -ExpectedValue 5
                }

                It 'Should return desired result when delta discovery is disabled' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryDisabled }
                    Mock -CommandName ConvertTo-ScheduleInterval -MockWith { $intervalNone }
                    Mock -CommandName Convert-CMSchedule

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery | Should -Be -ExpectedValue $false
                    $result.DeltaDiscoveryMins   | Should -Be -ExpectedValue $null
                    $result.ADContainers         | Should -Be -ExpectedValue $adContainersReturn
                    $result.ScheduleInterval     | Should -Be -ExpectedValue 'None'
                    $result.ScheduleCount        | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMUserDiscovery\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $adContainersReturn = @(
                    'LDAP://OU=Test,DC=contoso,DC=com'
                    'LDAP://OU=Test1,DC=contoso,DC=com'
                )

                $getTargetResourceStandardReturn = @{
                    SiteCode             = 'Lab'
                    Enabled              = $true
                    EnableDeltaDiscovery = $true
                    DeltaDiscoveryMins   = [UInt32]60
                    ADContainers         = $adContainersReturn
                    ScheduleInterval     = 'Days'
                    ScheduleCount        = 7
                }

                $getTargetResourceStandardNoSchedule = @{
                    SiteCode             = 'Lab'
                    Enabled              = $true
                    EnableDeltaDiscovery = $true
                    DeltaDiscoveryMins   = 60
                    ADContainers         = $adContainersReturn
                    ScheduleInterval     = 'None'
                    ScheduleCount        = $null
                }

                $inputParamsHours = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Hours'
                    ScheduleCount    = 8
                }

                $adContainersMismatch = 'LDAP://OU=Test2,DC=contoso,DC=com'

                $inputParamsADContainersMismatch = @{
                    SiteCode     = 'Lab'
                    Enabled      = $true
                    ADContainers = $adContainersMismatch
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDiscoveryMethod
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputParamsDisable = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }

                    $cmScheduleNull = @{
                        DayDuration    = 0
                        HourDuration   = 0
                        IsGMT          = $false
                        MinuteDuration = 0
                    }

                    $inputParamsDeltaMismatch = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                        DeltaDiscoveryMins   = 45
                    }

                    $inputParamsNoSchedule = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'None'
                    }

                    $cmScheduleHours = @{
                        DayDuration    = 0
                        DaySpan        = 0
                        HourDuration   = 0
                        HourSpan       = 1
                        IsGMT          = $false
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }

                    $adContainersMismatch = 'LDAP://OU=Test2,DC=contoso,DC=com'

                    $inputParamsADContainersInclude = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToInclude = $adContainersMismatch
                    }

                    $adContainersExclude = 'LDAP://OU=Test1,DC=contoso,DC=com'

                    $inputParamsADContainersExclude = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToExclude = $adContainersExclude
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                }

                It 'Should call expected commands for disabling User Discovery' {
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @inputParamsDisable
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for delta schedule mismatch' {
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @inputParamsDeltaMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when setting schedule to none' {
                    Mock -CommandName New-CMSchedule -MockWith { $cmScheduleNull }

                    Set-TargetResource @inputParamsNoSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands schedule mismatch' {
                    Mock -CommandName New-CMSchedule -MockWith { $cmScheduleHours } -ParameterFilter { $RecurInterval -eq 'Hours' }

                    Set-TargetResource @inputParamsHours
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for mismatch AD container' {
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @inputParamsADContainersMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for include AD container' {
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @inputParamsADContainersInclude
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for exclude AD container' {
                    Mock -CommandName New-CMSchedule

                    Set-TargetResource @inputParamsADContainersExclude
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource with no schedule return' {
                BeforeEach {
                    $cmScheduleDays = @{
                        DayDuration    = 0
                        DaySpan        = 1
                        HourDuration   = 0
                        HourSpan       = 0
                        IsGMT          = $false
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardNoSchedule }
                }

                It 'Should call expected commands when current schedule set to none' {
                    Mock -CommandName New-CMSchedule -MockWith { $cmScheduleDays }

                    Set-TargetResource @inputParamsHours
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $inputParamsBadSchedule = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'Days'
                    }

                    $inputDeltaThrow = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $false
                        DeltaDiscoveryMins   = 60
                    }

                    $adContainersExclude = 'LDAP://OU=Test1,DC=contoso,DC=com'

                    $enableDeltaThrow = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                    }

                    $inputParamsIncludeExcludeThrow = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToInclude = $adContainersExclude
                        ADContainersToExclude = $adContainersExclude
                    }

                    $deltaThrow = 'When changing delta schedule, delta schedule must be enabled.'
                    $scheduleThrow = "Invalid parameter usage specifying an Interval and didn't specify count."
                    $excludeThrow = "ADContainersToToExclude and ADContainersToToInclude contain to same entry LDAP://OU=Test1,DC=contoso,DC=com, remove from one of the arrays."
                    $enableDeltaThrowMsg = "DeltaDiscoveryMins is not specified, specify DeltaDiscoveryMins when enabling Delta Discovery."

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                }

                It 'Should call expected when specifying ScheduleInterval and not including ScheduleCount' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputParamsBadSchedule } | Should -Throw -ExpectedMessage $scheduleThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when specifying the same container in include and exclude' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputParamsIncludeExcludeThrow } | Should -Throw -ExpectedMessage $excludeThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when enabling delta discovery without specifying an interval' {
                    Mock -CommandName Get-TargetResource -MockWith { $inputDeltaThrow }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @enableDeltaThrow } | Should -Throw -ExpectedMessage $enableDeltaThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when Set-CMDiscovery throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod -MockWith { throw }

                    { Set-TargetResource @inputParamsADContainersMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected when new-CMSchedule throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                    Mock -CommandName New-CMSchedule -MockWith { throw }
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputParamsHours } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when delta discover is disabled and specifying delta schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputDeltaThrow } | Should -Throw -ExpectedMessage $deltaThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected when Get-TargetResource throws' {
                    Mock -CommandName Get-TargetResource -MockWith { throw }
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMDiscoveryMethod

                    { Set-TargetResource @inputParamsHours } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMUserDiscovery\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $adContainersReturn = @(
                    'LDAP://OU=Test,DC=contoso,DC=com'
                    'LDAP://OU=Test1,DC=contoso,DC=com'
                )

                $getTargetResourceStandardReturn = @{
                    SiteCode             = 'Lab'
                    Enabled              = $true
                    EnableDeltaDiscovery = $true
                    DeltaDiscoveryMins   = [UInt32]60
                    ADContainers         = $adContainersReturn
                    ScheduleInterval     = 'Days'
                    ScheduleCount        = 7
                }

                $getTargetResourceStandardNoSchedule = @{
                    SiteCode             = 'Lab'
                    Enabled              = $true
                    EnableDeltaDiscovery = $true
                    DeltaDiscoveryMins   = 60
                    ADContainers         = $adContainersReturn
                    ScheduleInterval     = 'None'
                    ScheduleCount        = $null
                }

                $inputParamsHours = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'Hours'
                    ScheduleCount    = 8
                }

                $inputParamsDisable = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $inputParamsNoSchedule = @{
                    SiteCode         = 'Lab'
                    Enabled          = $true
                    ScheduleInterval = 'None'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource with returned schedule settings' {
                BeforeEach {
                    $adContainersMismatch = 'LDAP://OU=Test2,DC=contoso,DC=com'
                    $adContainersExclude = 'LDAP://OU=Test1,DC=contoso,DC=com'

                    $iputAllParamsMatch = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                        DeltaDiscoveryMins   = 60
                        ADContainers         = $adContainersReturn
                        ScheduleInterval     = 'Days'
                        ScheduleCount        = 7
                    }

                    $inputParamsDeltaMismatch = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                        DeltaDiscoveryMins   = 45
                    }

                    $inputParamsADContainersMismatch = @{
                        SiteCode     = 'Lab'
                        Enabled      = $true
                        ADContainers = $adContainersMismatch
                    }

                    $inputParamsADContainersMultiple = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainers          = $adContainersMismatch
                        ADContainersToExclude = $adContainersExclude
                    }

                    $inputParamsADContainersInclude = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToInclude = $adContainersMismatch
                    }

                    $inputParamsADContainersExclude = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToExclude = $adContainersExclude
                    }

                    $inputParamsIncludeExclude = @{
                        SiteCode              = 'Lab'
                        Enabled               = $true
                        ADContainersToInclude = $adContainersExclude
                        ADContainersToExclude = $adContainersExclude
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                }

                It 'Should return desired result true when User Discovery settings match' {
                    Test-TargetResource @iputAllParamsMatch | Should -Be $true
                }

                It 'Should return desired result false when ad containers mismatch' {
                    Test-TargetResource @inputParamsIncludeExclude | Should -Be $false
                }

                It 'Should return desired result false when delta schedule mismatch' {
                    Test-TargetResource @inputParamsDeltaMismatch | Should -Be $false
                }

                It 'Should return desired result false when User Discovery schedules do not match' {
                    Test-TargetResource @inputParamsHours | Should -Be $false
                }

                It 'Should return desired result false when User Discovery desires none schedule to be set' {
                    Test-TargetResource @inputParamsNoSchedule | Should -Be $false
                }

                It 'Should return desired result false when User Discovery ADContainers are not correct add and remove' {
                    Test-TargetResource @inputParamsADContainersMismatch | Should -Be $false
                }

                It 'Should return desired result false when User Discovery ADContainers and ADContainersExclude are specified' {
                    Test-TargetResource @inputParamsADContainersMultiple | Should -Be $false
                }

                It 'Should return desired result false when User Discovery ADContainersInclude are not correct' {
                    Test-TargetResource @inputParamsADContainersInclude | Should -Be $false
                }

                It 'Should return desired result false when User Discovery ADContainersExclude is not correct' {
                    Test-TargetResource @inputParamsADContainersExclude | Should -Be $false
                }

                It 'Should return desired result false when User Discovery set to Enabled and expected value disabled' {
                    Test-TargetResource @inputParamsDisable | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource with returned schedule settings of none' {
                BeforeEach {
                    $inputParamsBadSchedule = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        ScheduleInterval = 'Days'
                    }

                    $disableDelta = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $false
                    }

                    $enableDelta = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardNoSchedule }
                }

                It 'Should return desired result false when current state returns null schedule' {
                    Test-TargetResource @inputParamsDisable | Should -Be $false
                }

                It 'Should return desired result true when current schedule and desired schedule are none' {
                    Test-TargetResource @inputParamsNoSchedule | Should -Be $true
                }

                It 'Should return desired result false when current schedule is none and desired schedule is set' {
                    Test-TargetResource @inputParamsHours | Should -Be $false
                }

                It 'Should return desired result false when input param is setting schedule is count is missing' {
                    Test-TargetResource @inputParamsBadSchedule | Should -Be $false
                }

                It 'Should return desired result false when enabling delta discovery without interval' {
                    Mock -CommandName Get-TargetResource -MockWith { $disableDelta }

                    Test-TargetResource @enableDelta | Should -Be $false
                }
            }
        }
    }
}
catch
{
    Invoke-TestCleanup
}
