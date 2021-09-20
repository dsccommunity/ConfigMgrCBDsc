[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMGroupDiscovery'

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

        Describe "ConfigMgrCBDsc - DSC_CMGroupDiscovery\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $getInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                $getCMDiscoveryEnabled = @{
                    Props     = @(
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
                        @{
                            PropertyName = 'Enable Filtering Expired Logon'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Days Since Last Logon'
                            Value        = 20
                        }
                        @{
                            PropertyName = 'Enable Filtering Expired Password'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Days Since Last Password Set'
                            Value        = 40
                        }
                        @{
                            PropertyName = 'Discover DG Membership'
                            Value        = 1
                        }
                    )
                    PropLists = @(
                        @{
                            PropertyListName = 'AD Containers'
                            Values           = @(
                                'Test1'
                                '0'
                                '0'
                                'Test2'
                                '0'
                                '1'
                            )
                        }
                        @{
                            PropertyListName = 'Search Bases:Test1'
                            Values           = @('LDAP://OU=Test1,DC=contoso,DC=com')
                        }
                        @{
                            PropertyListName = 'Search Bases:Test2'
                            Values           = @('LDAP://OU=Test2,DC=contoso,DC=com')
                        }
                    )
                }

                $getCMDiscoveryDisabledDelta = @{
                    Props     = @(
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
                        @{
                            PropertyName = 'Enable Filtering Expired Logon'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Days Since Last Logon'
                            Value        = 20
                        }
                        @{
                            PropertyName = 'Enable Filtering Expired Password'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Days Since Last Password Set'
                            Value        = 40
                        }
                        @{
                            PropertyName = 'Discover DG Membership'
                            Value        = 1
                        }
                    )
                    PropLists = @(
                        @{
                            PropertyListName = 'AD Containers'
                            Values           = @(
                                'Test1'
                                '0'
                                '0'
                                'Test2'
                                '0'
                                '1'
                            )
                        }
                        @{
                            PropertyListName = 'Search Bases:Test1'
                            Values           = @('LDAP://OU=Test1,DC=contoso,DC=com')
                        }
                        @{
                            PropertyListName = 'Search Bases:Test2'
                            Values           = @('LDAP://OU=Test2,DC=contoso,DC=com')
                        }
                    )
                }

                $getCMDiscoveryDisabled = @{
                    Props = @(
                        @{
                            PropertyName = 'Settings'
                            Value1       = 'InActive'
                        }
                    )
                }

                $getMonthlyByWeek = @{
                    MinuteDuration = $null
                    RecurInterval  = 1
                    WeekOrder      = 'First'
                    HourDuration   = $null
                    Start          = '2/1/1970 00:00'
                    DayOfWeek      = 'Friday'
                    ScheduleType   = 'MonthlyByWeek'
                    MonthDay       = $null
                    DayDuration    = $null
                }

                $getWeeklyScheduleReturn = @{
                    MinuteDuration = $null
                    RecurInterval  = 1
                    WeekOrder      = $null
                    HourDuration   = $null
                    Start          = '2/1/1970 00:00'
                    DayOfWeek      = 'Friday'
                    ScheduleType   = 'Weekly'
                    MonthDay       = $null
                    DayDuration    = $null
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

            Context 'When retrieving Group Discovery settings' {

                It 'Should return desired result when delta schedule returns hour' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryEnabled  }
                    Mock -CommandName Get-CMSchedule -MockWith { $getMonthlyByWeek }
                    Mock -CommandName Convert-CMSchedule -MockWith { $cmScheduleHours }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                             | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery                | Should -Be -ExpectedValue $true
                    $result.DeltaDiscoveryMins                  | Should -Be -ExpectedValue 60
                    $result.EnableFilteringExpiredLogon         | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastLogonDays              | Should -Be -ExpectedValue 20
                    $result.EnableFilteringExpiredPassword      | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastPasswordUpdateDays     | Should -Be -ExpectedValue 40
                    $result.DiscoverDistributionGroupMembership | Should -Be -ExpectedValue $true
                    $result.Start                               | Should -Be -ExpectedValue '2/1/1970 00:00'
                    $result.ScheduleType                        | Should -Be -ExpectedValue 'MonthlyByWeek'
                    $result.RecurInterval                       | Should -Be -ExpectedValue 1
                    $result.DayOfMonth                          | Should -Be -ExpectedValue $null
                    $result.DayOfWeek                           | Should -Be -ExpectedValue 'Friday'
                    $result.MonthlyWeekOrder                    | Should -Be -ExpectedValue 'First'
                    $result.GroupDiscoveryScope                 | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.GroupDiscoveryScope[0].Name         | Should -Be -ExpectedValue 'Test1'
                    $result.GroupDiscoveryScope[0].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test1,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[0].Recurse      | Should -Be -ExpectedValue $true
                    $result.GroupDiscoveryScope[1].Name         | Should -Be -ExpectedValue 'Test2'
                    $result.GroupDiscoveryScope[1].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test2,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[1].Recurse      | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when delta schedule returns minutes' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryEnabled  }
                    Mock -CommandName Get-CMSchedule -MockWith { $getMonthlyByWeek }
                    Mock -CommandName Convert-CMSchedule -MockWith { $cmScheduleMins }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                             | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery                | Should -Be -ExpectedValue $true
                    $result.DeltaDiscoveryMins                  | Should -Be -ExpectedValue 45
                    $result.EnableFilteringExpiredLogon         | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastLogonDays              | Should -Be -ExpectedValue 20
                    $result.EnableFilteringExpiredPassword      | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastPasswordUpdateDays     | Should -Be -ExpectedValue 40
                    $result.DiscoverDistributionGroupMembership | Should -Be -ExpectedValue $true
                    $result.Start                               | Should -Be -ExpectedValue '2/1/1970 00:00'
                    $result.ScheduleType                        | Should -Be -ExpectedValue 'MonthlyByWeek'
                    $result.RecurInterval                       | Should -Be -ExpectedValue 1
                    $result.DayOfMonth                          | Should -Be -ExpectedValue $null
                    $result.DayOfWeek                           | Should -Be -ExpectedValue 'Friday'
                    $result.MonthlyWeekOrder                    | Should -Be -ExpectedValue 'First'
                    $result.GroupDiscoveryScope                 | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.GroupDiscoveryScope[0].Name         | Should -Be -ExpectedValue 'Test1'
                    $result.GroupDiscoveryScope[0].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test1,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[0].Recurse      | Should -Be -ExpectedValue $true
                    $result.GroupDiscoveryScope[1].Name         | Should -Be -ExpectedValue 'Test2'
                    $result.GroupDiscoveryScope[1].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test2,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[1].Recurse      | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when delta discovery is disabled' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryDisabledDelta }
                    Mock -CommandName Get-CMSchedule -MockWith { $getWeeklyScheduleReturn }
                    Mock -CommandName Convert-CMSchedule -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                             | Should -Be -ExpectedValue $true
                    $result.EnableDeltaDiscovery                | Should -Be -ExpectedValue $false
                    $result.DeltaDiscoveryMins                  | Should -Be -ExpectedValue $null
                    $result.EnableFilteringExpiredLogon         | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastLogonDays              | Should -Be -ExpectedValue 20
                    $result.EnableFilteringExpiredPassword      | Should -Be -ExpectedValue $true
                    $result.TimeSinceLastPasswordUpdateDays     | Should -Be -ExpectedValue 40
                    $result.DiscoverDistributionGroupMembership | Should -Be -ExpectedValue $true
                    $result.Start                               | Should -Be -ExpectedValue '2/1/1970 00:00'
                    $result.ScheduleType                        | Should -Be -ExpectedValue 'Weekly'
                    $result.RecurInterval                       | Should -Be -ExpectedValue 1
                    $result.DayOfMonth                          | Should -Be -ExpectedValue $null
                    $result.DayOfWeek                           | Should -Be -ExpectedValue 'Friday'
                    $result.MonthlyWeekOrder                    | Should -Be -ExpectedValue $null
                    $result.GroupDiscoveryScope                 | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.GroupDiscoveryScope[0].Name         | Should -Be -ExpectedValue 'Test1'
                    $result.GroupDiscoveryScope[0].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test1,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[0].Recurse      | Should -Be -ExpectedValue $true
                    $result.GroupDiscoveryScope[1].Name         | Should -Be -ExpectedValue 'Test2'
                    $result.GroupDiscoveryScope[1].LdapLocation | Should -Be -ExpectedValue 'LDAP://OU=Test2,DC=contoso,DC=com'
                    $result.GroupDiscoveryScope[1].Recurse      | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when group discovery is disabled' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getCMDiscoveryDisabled }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                             | Should -Be -ExpectedValue $false
                    $result.EnableDeltaDiscovery                | Should -Be -ExpectedValue $null
                    $result.DeltaDiscoveryMins                  | Should -Be -ExpectedValue $null
                    $result.EnableFilteringExpiredLogon         | Should -Be -ExpectedValue $null
                    $result.TimeSinceLastLogonDays              | Should -Be -ExpectedValue $null
                    $result.EnableFilteringExpiredPassword      | Should -Be -ExpectedValue $null
                    $result.TimeSinceLastPasswordUpdateDays     | Should -Be -ExpectedValue $null
                    $result.DiscoverDistributionGroupMembership | Should -Be -ExpectedValue $null
                    $result.Start                               | Should -Be -ExpectedValue $null
                    $result.ScheduleType                        | Should -Be -ExpectedValue $null
                    $result.RecurInterval                       | Should -Be -ExpectedValue $null
                    $result.DayOfMonth                          | Should -Be -ExpectedValue $null
                    $result.DayOfWeek                           | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder                    | Should -Be -ExpectedValue $null
                    $result.GroupDiscoveryScope                 | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMGroupDiscovery\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $groupDiscoveryMisMatchInstance = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test3'
                            'LdapLocation' = 'LDAP://OU=Test3,DC=Contoso,DC=Com'
                            'Recurse'      = $false
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test2'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    )
                )

                $groupDiscoverySingleInstance = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test2'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $false
                        } `
                        -ClientOnly
                    )
                )

                $groupdiscoveryInstanceReturn = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test1'
                            'LdapLocation' = 'LDAP://OU=Test1,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test2'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    )
                )

                $getReturnEnabled = @{
                    SiteCode                            = 'Lab'
                    Enabled                             = $true
                    EnableDeltaDiscovery                = $true
                    DeltaDiscoveryMins                  = 40
                    EnableFilteringExpiredLogon         = $true
                    TimeSinceLastLogonDays              = 90
                    EnableFilteringExpiredPassword      = $true
                    TimeSinceLastPasswordUpdateDays     = 90
                    DiscoverDistributionGroupMembership = $true
                    GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                    Start                               = '2/1/1970 00:00'
                    ScheduleType                        = 'MonthlyByWeek'
                    DayOfWeek                           = 'Friday'
                    MonthlyWeekOrder                    = 'first'
                    DayofMonth                          = $null
                    RecurInterval                       = 1
                }

                $getReturnedDisabled = @{
                    SiteCode                            = 'Lab'
                    Enabled                             = $false
                    EnableDeltaDiscovery                = $null
                    DeltaDiscoveryMins                  = $null
                    EnableFilteringExpiredLogon         = $null
                    TimeSinceLastLogonDays              = $null
                    EnableFilteringExpiredPassword      = $null
                    TimeSinceLastPasswordUpdateDays     = $null
                    DiscoverDistributionGroupMembership = $null
                    GroupDiscoveryScope                 = $null
                    Start                               = $null
                    ScheduleType                        = $null
                    DayOfWeek                           = $null
                    MonthlyWeekOrder                    = $null
                    DayofMonth                          = $null
                    RecurInterval                       = $null
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDiscoveryMethod
                Mock -CommandName New-CMSchedule -MockWith { $true }
                Mock -CommandName New-CMADGroupDiscoveryScope -MockWith { $true }
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $scheduleMisMatch = @{
                        SiteCode                            = 'Lab'
                        Enabled                             = $true
                        EnableDeltaDiscovery                = $true
                        DeltaDiscoveryMins                  = 60
                        EnableFilteringExpiredLogon         = $true
                        TimeSinceLastLogonDays              = 50
                        EnableFilteringExpiredPassword      = $true
                        TimeSinceLastPasswordUpdateDays     = 50
                        DiscoverDistributionGroupMembership = $true
                        GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                        Start                               = '2/1/1970 00:00'
                        ScheduleType                        = 'MonthlyByDay'
                        DayofMonth                          = 10
                        RecurInterval                       = 1
                    }

                    $groupDiscoveryDisabled = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }

                    $scopesMatchParam = @{
                        SiteCode            = 'Lab'
                        Enabled             = $true
                        GroupDiscoveryScope = $groupDiscoveryMisMatchInstance
                    }

                    $scopesIncludeParam = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                    }

                    $scopesExcludeParam = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }

                    $allGroupDiscoveryOptions = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScope          = $groupDiscoveryMisMatchInstance
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }
                }

                It 'Should call expected commands for disenabling the group discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @scheduleMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for enabling and changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @groupDiscoveryDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for adding and removing group discovery scopes' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @scopesMatchParam
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 2 -Scope It
                }

                It 'Should call expected commands for include' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @scopesIncludeParam
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for exclude' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @scopesExcludeParam
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when match and include and exclude are all specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @allGroupDiscoveryOptions
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 2 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $includeExclude = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }

                    $includeExcludeMsg = 'GroupDiscoveryScopeToExclude and GroupDiscoveryScopeToInclude contain to same entry Test2, remove from one of the arrays.'

                    $getDeltaDisabled = @{
                        SiteCode                            = 'Lab'
                        Enabled                             = $true
                        EnableDeltaDiscovery                = $false
                        DeltaDiscoveryMins                  = $null
                        EnableFilteringExpiredLogon         = $true
                        TimeSinceLastLogonDays              = 90
                        EnableFilteringExpiredPassword      = $true
                        TimeSinceLastPasswordUpdateDays     = 90
                        DiscoverDistributionGroupMembership = $true
                        GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                        Start                               = '2/1/1970 00:00'
                        ScheduleType                        = 'MonthlyByWeek'
                        DayOfWeek                           = 'Friday'
                        MonthlyWeekOrder                    = 'first'
                        DayofMonth                          = $null
                        RecurInterval                       = 1
                    }

                    $deltaDiscovery = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                    }

                    $deltaDiscoveryMsg = 'DeltaDiscoveryMins is not specified, specify DeltaDiscoveryMins when enabling Delta Discovery.'

                    $deltaMinutes = @{
                        SiteCode           = 'Lab'
                        Enabled            = $true
                        DeltaDiscoveryMins = 10
                    }

                    $deltaMinutesMsg = 'When changing delta schedule, delta schedule must be enabled.'

                    $missingScheduleType = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        Start            = '2/1/1970 00:00'
                        DayOfWeek        = 'Friday'
                        MonthlyWeekOrder = 'first'
                    }

                    $missingScheduleTypeMsg = 'In order to create a schedule you must specify ScheduleType.'

                    $timeSinceLastLogon = @{
                        SiteCode               = 'Lab'
                        Enabled                = $true
                        TimeSinceLastLogonDays = 15
                    }

                    $timeSinceLastLogonMsg = 'When setting TimeSinceLastLogonDays, EnableFilteringExpiredLogon must be set to true.'

                    $timePasswordUpdate = @{
                        SiteCode                        = 'Lab'
                        Enabled                         = $true
                        TimeSinceLastPasswordUpdateDays = 49
                    }

                    $passwordExpiredFilterMsg = 'When setting TimeSinceLastPasswordUpdateDays, EnableFilteringExpiredPassword must be set to true.'
                }

                It 'Should call expected commands when include and exclude contain the same entry' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }

                    { Set-TargetResource @includeExclude } | Should -Throw -ExpectedMessage $includeExcludeMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when enabling delta discovery and not specifying minutes' {
                    Mock -CommandName Get-TargetResource -MockWith { $getDeltaDisabled }

                    { Set-TargetResource @deltaDiscovery } | Should -Throw -ExpectedMessage $deltaDiscoveryMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when specifying delta discovery minutes without enabling delta discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getDeltaDisabled }

                    { Set-TargetResource @deltaMinutes } | Should -Throw -ExpectedMessage $deltaMinutesMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when specifying schedule and not specifying ScheduleType' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }

                    { Set-TargetResource @missingScheduleType } | Should -Throw -ExpectedMessage $missingScheduleTypeMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when specifying TimeSinceLastLogonDays and not EnableFilteringExpiredLogon' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }

                    { Set-TargetResource @timeSinceLastLogon } | Should -Throw -ExpectedMessage $timeSinceLastLogonMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when specifying TimeSinceLastPasswordUpdateDays and not EnableFilteringExpiredPassword' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }

                    { Set-TargetResource @timePasswordUpdate } | Should -Throw -ExpectedMessage $passwordExpiredFilterMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMADGroupDiscoveryScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "ConfigMgrCBDsc - DSC_CMGroupDiscovery\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $groupDiscoveryMisMatchInstance = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test3'
                            'LdapLocation' = 'LDAP://OU=Test3,DC=Contoso,DC=Com'
                            'Recurse'      = $false
                        } `
                        -ClientOnly
                    )
                )

                $groupDiscoverySingleInstance = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test2'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    )
                )

                $groupdiscoveryInstanceReturn = @(
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test1'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'Name'         = 'Test2'
                            'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                            'Recurse'      = $true
                        } `
                        -ClientOnly
                    )
                )

                $getReturnEnabled = @{
                    SiteCode                            = 'Lab'
                    Enabled                             = $true
                    EnableDeltaDiscovery                = $true
                    DeltaDiscoveryMins                  = 40
                    EnableFilteringExpiredLogon         = $true
                    TimeSinceLastLogonDays              = 90
                    EnableFilteringExpiredPassword      = $true
                    TimeSinceLastPasswordUpdateDays     = 90
                    DiscoverDistributionGroupMembership = $true
                    GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                    Start                               = '2/1/1970 00:00'
                    ScheduleType                        = 'MonthlyByWeek'
                    DayOfWeek                           = 'Friday'
                    MonthlyWeekOrder                    = 'first'
                    DayofMonth                          = $null
                    RecurInterval                       = 1
                }

                $getReturnedDisabled = @{
                    SiteCode                            = 'Lab'
                    Enabled                             = $false
                    EnableDeltaDiscovery                = $null
                    DeltaDiscoveryMins                  = $null
                    EnableFilteringExpiredLogon         = $null
                    TimeSinceLastLogonDays              = $null
                    EnableFilteringExpiredPassword      = $null
                    TimeSinceLastPasswordUpdateDays     = $null
                    DiscoverDistributionGroupMembership = $null
                    GroupDiscoveryScope                 = $null
                    Start                               = $null
                    ScheduleType                        = $null
                    DayOfWeek                           = $null
                    MonthlyWeekOrder                    = $null
                    DayofMonth                          = $null
                    RecurInterval                       = $null
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource with returned schedule settings' {
                BeforeEach {
                    $groupDiscoverySingleInstanceRecurse = @(
                        (New-CimInstance -ClassName DSC_CMGroupDiscoveryScope `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'Name'         = 'Test2'
                                'LdapLocation' = 'LDAP://OU=Test2,DC=Contoso,DC=Com'
                                'Recurse'      = $false
                            } `
                            -ClientOnly
                        )
                    )

                    $scheduleMisMatch = @{
                        SiteCode                            = 'Lab'
                        Enabled                             = $true
                        EnableDeltaDiscovery                = $true
                        DeltaDiscoveryMins                  = 60
                        EnableFilteringExpiredLogon         = $true
                        TimeSinceLastLogonDays              = 50
                        EnableFilteringExpiredPassword      = $true
                        TimeSinceLastPasswordUpdateDays     = 50
                        DiscoverDistributionGroupMembership = $true
                        GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                        Start                               = '2/1/1970 00:00'
                        ScheduleType                        = 'MonthlyByDay'
                        DayofMonth                          = 10
                        RecurInterval                       = 1
                    }

                    $groupDiscoveryMismatch = @{
                        SiteCode            = 'Lab'
                        Enabled             = $true
                        GroupDiscoveryScope = $groupDiscoveryMisMatchInstance
                    }

                    $groupDiscoveryIncludeMatches = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                    }

                    $groupDiscoveryIncludeMismatch = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstanceRecurse
                    }

                    $groupDiscoveryMatches = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }

                    $groupDiscoveryDisabled = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetResourceStandardReturn }
                }

                It 'Should return desired result false when group discovery settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @scheduleMisMatch | Should -Be $false
                }

                It 'Should return desired result false when GroupDiscoveryScopes match, mismatches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @groupDiscoveryMismatch | Should -Be $false
                }

                It 'Should return desired result true when GroupDiscoveryScopes include, matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @groupDiscoveryIncludeMatches | Should -Be $true
                }

                It 'Should return desired result true when GroupDiscoveryScopes include, property mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @groupDiscoveryIncludeMismatch | Should -Be $false
                }

                It 'Should return desired result false when GroupDiscoveryScopes exclude, matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @groupDiscoveryMatches | Should -Be $false
                }

                It 'Should return desired result true when Group Discovery is disabled and expected disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedDisabled }

                    Test-TargetResource @groupDiscoveryDisabled | Should -Be $true
                }

                It 'Should return desired result false when Group Discovery is enabled and expected disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @groupDiscoveryDisabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource write warnings' {
                BeforeEach {
                    $includeExclude = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }

                    $getDeltaDisabled = @{
                        SiteCode                            = 'Lab'
                        Enabled                             = $true
                        EnableDeltaDiscovery                = $false
                        DeltaDiscoveryMins                  = $null
                        EnableFilteringExpiredLogon         = $true
                        TimeSinceLastLogonDays              = 90
                        EnableFilteringExpiredPassword      = $true
                        TimeSinceLastPasswordUpdateDays     = 90
                        DiscoverDistributionGroupMembership = $true
                        GroupDiscoveryScope                 = $groupdiscoveryInstanceReturn
                        Start                               = '2/1/1970 00:00'
                        ScheduleType                        = 'MonthlyByWeek'
                        DayOfWeek                           = 'Friday'
                        MonthlyWeekOrder                    = 'first'
                        DayofMonth                          = $null
                        RecurInterval                       = 1
                    }

                    $deltaDiscovery = @{
                        SiteCode             = 'Lab'
                        Enabled              = $true
                        EnableDeltaDiscovery = $true
                    }

                    $deltaSchedule = @{
                        SiteCode           = 'Lab'
                        Enabled            = $true
                        DeltaDiscoveryMins = 5
                    }

                    $allGroupDiscoveryOptions = @{
                        SiteCode                     = 'Lab'
                        Enabled                      = $true
                        GroupDiscoveryScope          = $groupDiscoveryMisMatchInstance
                        GroupDiscoveryScopeToInclude = $groupDiscoverySingleInstance
                        GroupDiscoveryScopeToExclude = 'Test2'
                    }

                    $missingScheduleType = @{
                        SiteCode         = 'Lab'
                        Enabled          = $true
                        Start            = '2/1/1970 00:00'
                        DayOfWeek        = 'Friday'
                        MonthlyWeekOrder = 'first'
                    }

                    $timeSinceLastLogon = @{
                        SiteCode               = 'Lab'
                        Enabled                = $true
                        TimeSinceLastLogonDays = 15
                    }

                    $timePasswordUpdate = @{
                        SiteCode                        = 'Lab'
                        Enabled                         = $true
                        TimeSinceLastPasswordUpdateDays = 49
                    }
                }

                It 'Should return desired result false when enabling delta discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getDeltaDisabled }

                    Test-TargetResource @deltaDiscovery | Should -Be $false
                }

                It 'Should return desired result false when Include and Exclude contain the same name' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @includeExclude | Should -Be $false
                }

                It 'Should return desired result false when using all three GroupDiscoveryScope types' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @allGroupDiscoveryOptions | Should -Be $false
                }

                It 'Should return desired result false when specifying delta discovery and not enabling delta discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getDeltaDisabled }

                    Test-TargetResource @deltaSchedule | Should -Be $false
                }

                It 'Should return desired result false when specifying schedule and not specifying ScheduleType' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @missingScheduleType | Should -Be $false
                }

                It 'Should return desired result false when specifying TimeSinceLastLogonDays and not EnableFilteringExpiredLogon' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @timeSinceLastLogon | Should -Be $false
                }

                It 'Should return desired result false when specifying TimeSinceLastPasswordUpdateDays and not EnableFilteringExpiredPassword' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @timePasswordUpdate | Should -Be $false
                }
            }
        }
    }
}
catch
{
    Invoke-TestCleanup
}
