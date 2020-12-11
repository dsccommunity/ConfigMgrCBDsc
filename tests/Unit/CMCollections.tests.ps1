[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMCollections'

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
        <#$moduleResourceName = 'ConfigMgrCBDsc - DSC_CMCollections'

        $mockCimDeviceQuery = @(
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RuleName'        = 'QueryDevice1'
                    'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device1"'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RuleName'        = 'QueryDevice2'
                    'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device2"'
                } `
                -ClientOnly
            )
        )

        $mockCimUserQuery = @(
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RuleName'        = 'QueryUser1'
                    'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User01"'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RuleName'        = 'QueryUser2'
                    'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User02"'
                } `
                -ClientOnly
            )
        )

        $mockCimRefreshSchedule = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 7
                } `
                -ClientOnly
        )

        $mockCimRefreshScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 6
                } `
                -ClientOnly
        )

        $mockCimRefreshScheduleHours = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Hours'
                    'RecurCount'    = 7
                } `
                -ClientOnly
        )

        $mockCimRefreshScheduleMin = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Minutes'
                    'RecurCount'    = 50
                } `
                -ClientOnly
        )

        $newCMScheduleDaysMatch = @{
            DayDuration    = 0
            DaySpan        = 7
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 0
        }

        $newCMScheduleDaysNotMatch = @{
            DayDuration    = 0
            DaySpan        = 6
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 0
        }

        $newCMScheduleHours = @{
            DayDuration    = 0
            DaySpan        = 0
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 6
            MinuteDuration = 0
            MinuteSpan     = 0
        }

        $newCMScheduleMinutes = @{
            DayDuration    = 0
            DaySpan        = 0
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 59
        }

        $getDeviceInput = @{
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            CollectionType = 'Device'
        }

        $testDeviceInputAbsent = @{
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            CollectionType = 'Device'
            Ensure         = 'Absent'
        }

        $deviceCollectionResult = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 6
            Comment               = 'Test device collection'
            RefreshSchedule       = @{
                DayDuration    = 0
                DaySpan        = 7
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 0
            }
        }

        $deviceCollectionResultMin = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 6
            Comment               = 'Test device collection'
            RefreshSchedule       = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 50
            }
        }

        $deviceCollectionResultHour = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 6
            Comment               = 'Test device collection'
            RefreshSchedule       = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 10
                MinuteDuration = 0
                MinuteSpan     = 0
            }
        }

        $deviceCollectionResultRefreshNone = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 1
            Comment               = 'Test device collection'
        }

        $deviceCollectionResultRefreshPeriodic = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 2
            Comment               = 'Test device collection'
            RefreshSchedule       = @{
                DayDuration    = 0
                DaySpan        = 7
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 0
            }
        }

        $deviceCollectionResultRefreshContinuous = @{
            Name                  = 'Test'
            LimitToCollectionName = 'All Systems'
            CollectionType        = 2
            RefreshType           = 4
            Comment               = 'Test device collection'
        }

        $deviceExcludeResults = @(
            @{
                ExcludeCollectionID = 'Lab000016'
                RuleName            = 'Test1'
            }
            @{
                ExcludeCollectionId = 'Lab000017'
                RuleName            = 'Test2'
            }
        )

        $deviceDirectResult = @(
            @{
                ResourceID = '2097152000'
                RuleName   = 'Device1'
            }
            @{
                ResourceID = '2097152001'
                RuleName   = 'Device2'
            }
        )

        $deviceQueryResults = @(
            (New-Object -TypeName PSObject -Property  @{
                    'RuleName'        = 'QueryDevice1'
                    'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device1"'
                }
            ),
            (New-Object -TypeName PSObject -Property  @{
                    'RuleName'        = 'QueryDevice2'
                    'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device2"'
                }
            )
        )

        $getUserInput = @{
            SiteCode       = 'Lab'
            CollectionName = 'User1'
            CollectionType = 'User'
        }

        $userCollectionResult = @{
            Name                  = 'User1'
            LimitToCollectionName = 'All Users'
            CollectionType        = 1
            RefreshType           = 6
            Comment               = 'Test User collection'
            RefreshSchedule       = @{
                DayDuration    = 0
                DaySpan        = 7
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 0
            }
        }

        $userExcludeResults = @(
            @{
                ExcludeCollectionID = 'LAB0001A'
                RuleName            = 'TestUser1'
            }
            @{
                ExcludeCollectionId = 'LAB0001B'
                RuleName            = 'TestUser2'
            }
        )

        $userDirectResult = @(
            @{
                ResourceID = '2097152000'
                RuleName   = 'User1'
            }
            @{
                ResourceID = '2097152001'
                RuleName   = 'User2'
            }
        )

        $userQueryResults = @(
            (New-Object -TypeName PSObject -Property  @{
                    'RuleName'        = 'QueryUser1'
                    'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User01"'
                }
            ),
            (New-Object -TypeName PSObject -Property  @{
                    'RuleName'        = 'QueryUser2'
                    'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User02"'
                }
            )
        )

        $userDirectMismatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'User1'
            LimitingCollectionName = 'All Users'
            CollectionType         = 'User'
            RefreshType            = 'Both'
            Comment                = 'Test User collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('TestUser1','TestUser2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimUserQuery
            Ensure                 = 'Present'
        }

        $deviceGetCollectionResult = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $deviceQueryResults
            Ensure                 = 'Present'
        }

        $deviceGetCollectionNullSchedule = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $null
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $deviceQueryResults
            Ensure                 = 'Present'
        }

        $deviceGetCollectionResultSchedule = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = @{
                RecurInterval = 'Hours'
                RecurCount    = 5
            }
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $deviceQueryResults
            Ensure                 = 'Present'
        }

        $deviceGetCollectionEmpty = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = $null
            CollectionType         = $null
            RefreshType            = $null
            Comment                = $null
            RefreshSchedule        = $null
            ExcludeMembership      = $null
            DirectMembership       = $null
            QueryRules             = $null
            Ensure                 = 'Absent'
        }

        $deviceMatchCollectionParams = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimDeviceQuery
        }

        $deviceScheduleDay = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshSchedule        = $mockCimRefreshScheduleDayMismatch
        }

        $deviceScheduleHours = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshSchedule        = $mockCimRefreshScheduleHours
        }

        $deviceScheduleMin = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Systems'
            CollectionType         = 'Device'
            RefreshSchedule        = $mockCimRefreshScheduleMin
        }

        $deviceCommentItemsMisMatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Devices'
            CollectionType         = 'Device'
            RefreshType            = 'Manual'
            Comment                = 'collection mismatch'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimDeviceQuery
        }

        $deviceEvalItemsMisMatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Devices'
            CollectionType         = 'Device'
            RefreshType            = 'Manual'
            Comment                = 'Test device collections'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimDeviceQuery
        }

        $deviceExcludeMismatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Devices'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test3','Test4')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimDeviceQuery
        }

        $deviceDirectMismatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Devices'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152006','2097152007')
            QueryRules             = $mockCimDeviceQuery
        }

        $deviceQueryMismatch = @{
            SiteCode               = 'Lab'
            CollectionName         = 'Test'
            LimitingCollectionName = 'All Devices'
            CollectionType         = 'Device'
            RefreshType            = 'Both'
            Comment                = 'Test device collection'
            RefreshSchedule        = $mockCimRefreshSchedule
            ExcludeMembership      = @('Test1','Test2')
            DirectMembership       = @('2097152000','2097152001')
            QueryRules             = $mockCimUserQuery
            Ensure                 = 'Present'
        }#>

        Describe "ConfigMgrCBDsc - DSC_CMCollections\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $deviceCollectionResultRefreshNone = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 1
                    Comment               = 'Test device collection'
                }

                $deviceDirectResult = @(
                    @{
                        ResourceID = '2097152000'
                        RuleName   = 'Device1'
                    }
                    @{
                        ResourceID = '2097152001'
                        RuleName   = 'Device2'
                    }
                )

                $deviceIncludeResults = @(
                    @{
                        IncludeCollectionID = 'Lab000016'
                        RuleName            = 'Test3'
                    }
                    @{
                        IncludeCollectionId = 'Lab000017'
                        RuleName            = 'Test4'
                    }
                )

                $deviceExcludeResults = @(
                    @{
                        ExcludeCollectionID = 'Lab000016'
                        RuleName            = 'Test1'
                    }
                    @{
                        ExcludeCollectionId = 'Lab000017'
                        RuleName            = 'Test2'
                    }
                )

                $deviceQueryResults = @(
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryDevice1'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device1"'
                        }
                    ),
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryDevice2'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device2"'
                        }
                    )
                )

                $getDeviceInput = @{
                    SiteCode       = 'Lab'
                    CollectionName = 'Test'
                    CollectionType = 'Device'
                }

                $testDeviceInputAbsent = @{
                    SiteCode       = 'Lab'
                    CollectionName = 'Test'
                    CollectionType = 'Device'
                    Ensure         = 'Absent'
                }

                $deviceCollectionResult = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 6
                    Comment               = 'Test device collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        DaySpan        = 7
                        HourDuration   = 0
                        HourSpan       = 0
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }
                }

                $deviceCollectionResultMin = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 6
                    Comment               = 'Test device collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        DaySpan        = 0
                        HourDuration   = 0
                        HourSpan       = 0
                        MinuteDuration = 0
                        MinuteSpan     = 50
                    }
                }

                $deviceCollectionResultHour = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 6
                    Comment               = 'Test device collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        DaySpan        = 0
                        HourDuration   = 0
                        HourSpan       = 10
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }
                }

                $deviceCollectionResultRefreshNone = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 1
                    Comment               = 'Test device collection'
                }

                $deviceCollectionResultRefreshPeriodic = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 2
                    Comment               = 'Test device collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        DaySpan        = 7
                        HourDuration   = 0
                        HourSpan       = 0
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }
                }

                $deviceCollectionResultRefreshPeriodicNone = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 2
                    Comment               = 'Test device collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        HourDuration   = 0
                        MinuteDuration = 0
                    }
                }

                $deviceCollectionResultRefreshContinuous = @{
                    Name                  = 'Test'
                    LimitToCollectionName = 'All Systems'
                    CollectionType        = 2
                    RefreshType           = 4
                    Comment               = 'Test device collection'
                }

                $userCollectionResult = @{
                    Name                  = 'User1'
                    LimitToCollectionName = 'All Users'
                    CollectionType        = 1
                    RefreshType           = 6
                    Comment               = 'Test User collection'
                    RefreshSchedule       = @{
                        DayDuration    = 0
                        DaySpan        = 7
                        HourDuration   = 0
                        HourSpan       = 0
                        MinuteDuration = 0
                        MinuteSpan     = 0
                    }
                }

                $userExcludeResults = @(
                    @{
                        ExcludeCollectionID = 'LAB0001A'
                        RuleName            = 'TestUser1'
                    }
                    @{
                        ExcludeCollectionId = 'LAB0001B'
                        RuleName            = 'TestUser2'
                    }
                )

                $userDirectResult = @(
                    @{
                        ResourceID = '2097152000'
                        RuleName   = 'User1'
                    }
                    @{
                        ResourceID = '2097152001'
                        RuleName   = 'User2'
                    }
                )

                $userQueryResults = @(
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryUser1'
                            'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User01"'
                        }
                    ),
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryUser2'
                            'QueryExpression' = 'Select * from SMS_R_User where Name0 = "User02"'
                        }
                    )
                )

                $getUserInput = @{
                    SiteCode       = 'Lab'
                    CollectionName = 'User1'
                    CollectionType = 'User'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {

                It 'Should return desired result for device collections with no collection updates' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshNone  }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue $null
                    $result.ScheduleCount          | Should -be -ExpectedValue $null
                    $result.RefreshType            | Should -Be -ExpectedValue 'Manual'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for device collections' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResult }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue 'Days'
                    $result.ScheduleCount          | Should -be -ExpectedValue 7
                    $result.RefreshType            | Should -Be -ExpectedValue 'Both'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for device collections with periodic updates' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshPeriodicNone  }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue 'None'
                    $result.ScheduleCount          | Should -be -ExpectedValue $null
                    $result.RefreshType            | Should -Be -ExpectedValue 'Periodic'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for device collections with no collection updates' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshContinuous  }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue $null
                    $result.ScheduleCount          | Should -be -ExpectedValue $null
                    $result.RefreshType            | Should -Be -ExpectedValue 'Continuous'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for device collections with minutes schedule' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultMin  }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue 'Minutes'
                    $result.ScheduleCount          | Should -be -ExpectedValue 50
                    $result.RefreshType            | Should -Be -ExpectedValue 'Both'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for device collections with hours schedule' {
                    Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultHour  }
                    Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
                    Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
                    Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }
                    Mock -CommandName Get-CMDeviceCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getDeviceInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'Test'
                    $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'Device'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
                    $result.ScheduleInterval       | Should -be -ExpectedValue 'Hours'
                    $result.ScheduleCount          | Should -be -ExpectedValue 10
                    $result.RefreshType            | Should -Be -ExpectedValue 'Both'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('Device1','Device2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for user collections' {
                    Mock -CommandName Get-CMCollection -MockWith { $userCollectionResult }
                    Mock -CommandName Get-CMUserCollectionDirectMembershipRule -MockWith { $userDirectResult }
                    Mock -CommandName Get-CMUserCollectionExcludeMembershipRule -MockWith { $userExcludeResults }
                    Mock -CommandName Get-CMUserCollectionQueryMembershipRule -MockWith { $userQueryResults }
                    Mock -CommandName Get-CMUserCollectionIncludeMembershipRule -MockWith { $deviceIncludeResults }

                    $result = Get-TargetResource @getUserInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'User1'
                    $result.Comment                | Should -Be -ExpectedValue 'Test user collection'
                    $result.CollectionType         | Should -Be -ExpectedValue 'User'
                    $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Users'
                    $result.ScheduleInterval       | Should -be -ExpectedValue 'Days'
                    $result.ScheduleCount          | Should -be -ExpectedValue 7
                    $result.RefreshType            | Should -Be -ExpectedValue 'Both'
                    $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.QueryRules.Count       | Should -Be -ExpectedValue 2
                    $result.ExcludeMembership      | Should -Be -ExpectedValue @('TestUser1','TestUser2')
                    $result.DirectMembership       | Should -Be -ExpectedValue @('User1','User2')
                    $result.DirectMembershipId     | Should -Be -ExpectedValue @('2097152000','2097152001')
                    $result.IncludeMembership      | Should -Be -ExpectedValue @('Test3','Test4')
                    $result.Ensure                 | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for user collections does not exist' {
                    Mock -CommandName Get-CMCollection
                    Mock -CommandName Get-CMUserCollectionDirectMembershipRule
                    Mock -CommandName Get-CMUserCollectionExcludeMembershipRule
                    Mock -CommandName Get-CMUserCollectionQueryMembershipRule
                    Mock -CommandName Get-CMUserCollectionIncludeMembershipRule

                    $result = Get-TargetResource @getUserInput
                    $result                        | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
                    $result.CollectionName         | Should -Be -ExpectedValue 'User1'
                    $result.Comment                | Should -Be -ExpectedValue $null
                    $result.CollectionType         | Should -Be -ExpectedValue $null
                    $result.LimitingCollectionName | Should -Be -ExpectedValue $null
                    $result.RefreshSchedule        | Should -Be -ExpectedValue $null
                    $result.RefreshType            | Should -Be -ExpectedValue $null
                    $result.QueryRules             | Should -Be -ExpectedValue $null
                    $result.ExcludeMembership      | Should -Be -ExpectedValue $null
                    $result.DirectMembership       | Should -Be -ExpectedValue $null
                    $result.DirectMembershipId     | Should -Be -ExpectedValue $null
                    $result.IncludeMembership      | Should -Be -ExpectedValue $null
                    $result.Ensure                 | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        <#Describe "$moduleResourceName\Set-TargetResource" {
            BeforeAll {
                $deviceGetCollectionEmpty = @{
                    SiteCode               = 'Lab'
                    CollectionName         = 'Test'
                    LimitingCollectionName = $null
                    CollectionType         = $null
                    RefreshType            = $null
                    Comment                = $null
                    RefreshSchedule        = $null
                    ExcludeMembership      = $null
                    DirectMembership       = $null
                    DirectMembershipId     = $null
                    IncludeMembership      = $null
                    QueryRules             = $null
                    Ensure                 = 'Absent'
                }

                $deviceQueryResults = @(
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryDevice1'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device1"'
                        }
                    ),
                    (New-Object -TypeName PSObject -Property  @{
                            'RuleName'        = 'QueryDevice2'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device2"'
                        }
                    )
                )

                $mockCimDeviceQueryMismatch = @(
                    (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'RuleName'        = 'QueryDevice1'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device3"'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'RuleName'        = 'QueryDevice2'
                            'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device4"'
                        } `
                        -ClientOnly
                    )
                )

                $deviceGetCollectionResult = @{
                    SiteCode               = 'Lab'
                    CollectionName         = 'Test'
                    LimitingCollectionName = 'All Systems'
                    CollectionType         = 'Device'
                    RefreshType            = 'Both'
                    Comment                = 'Test device collection'
                    ScheduleInterval       = 'Days'
                    ScheduleCount          = 7
                    ExcludeMembership      = @('Test1','Test2')
                    DirectMembership       = @('Device1','Device2')
                    DirectMembershipId     = @('2097152000','2097152001')
                    IncludeMembership      = @('Test3','Test4')
                    QueryRules             = $deviceQueryResults
                    Ensure                 = 'Present'
                }

                $newCMScheduleDaysMatch = @{
                    DayDuration    = 0
                    DaySpan        = 7
                    IsGMT          = $false
                    HourDuration   = 0
                    HourSpan       = 0
                    MinuteDuration = 0
                    MinuteSpan     = 0
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    Mock -CommandName New-CMCollection
                    Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }
                    Mock -CommandName Set-CMCollection
                    Mock -CommandName Add-CMUserCollectionExcludeMembershipRule
                    Mock -CommandName Add-CMUserCollectionDirectMembershipRule
                    Mock -CommandName Add-CMUserCollectionQueryMembershipRule
                    Mock -CommandName Add-CMDeviceCollectionExcludeMembershipRule
                    Mock -CommandName Add-CMDeviceCollectionDirectMembershipRule
                    Mock -CommandName Add-CMUserCollectionIncludeMembershipRule
                    Mock -CommandName Add-CMDeviceCollectionIncludeMembershipRule
                    Mock -CommandName Add-CMDeviceCollectionQueryMembershipRule
                    Mock -CommandName Remove-CMCollection
                }

                It 'Should call expected commands for creating new device collection' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }

                    Set-TargetResource @deviceDirectMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMResouce -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDevice -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }
            }

            <#Context 'When running Set-TargetResource should throw' {

                It 'Should call expected commands and throw if query membership throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName Add-CMDeviceCollectionQueryMembershipRule -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if direct membership throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName Add-CMDeviceCollectionDirectMembershipRule -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if exclude membership throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName Add-CMDeviceCollectionExcludeMembershipRule -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if set collection throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName Set-CMCollection -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if new schedule throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName New-CMSchedule -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if new collection throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                    Mock -CommandName New-CMCollection -MockWith { throw }

                    { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if remove collection throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }
                    Mock -CommandName Remove-CMCollection -MockWith { throw }

                    { Set-TargetResource @testDeviceInputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionExcludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionDirectMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionIncludeMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMUserCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDeviceCollectionQueryMembershipRule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollection -Exactly -Times 1 -Scope It
                }
            }
        }#>

        Describe 'ConfigMgrCBDsc - DSC_CMCollections\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource device settings' {
                BeforeEach {
                    $deviceQueryResults = @(
                        (New-Object -TypeName PSObject -Property  @{
                                'RuleName'        = 'QueryDevice1'
                                'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device1"'
                            }
                        ),
                        (New-Object -TypeName PSObject -Property  @{
                                'RuleName'        = 'QueryDevice2'
                                'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device2"'
                            }
                        )
                    )

                    $mockCimDeviceQueryMismatch = @(
                        (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'RuleName'        = 'QueryDevice1'
                                'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device3"'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'RuleName'        = 'QueryDevice2'
                                'QueryExpression' = 'Select * from vSMS_R_System where Name0 = "Device4"'
                            } `
                            -ClientOnly
                        )
                    )

                    $deviceGetCollectionResult = @{
                        SiteCode               = 'Lab'
                        CollectionName         = 'Test'
                        LimitingCollectionName = 'All Systems'
                        CollectionType         = 'Device'
                        RefreshType            = 'Both'
                        Comment                = 'Test device collection'
                        ScheduleInterval       = 'Days'
                        ScheduleCount          = 7
                        ExcludeMembership      = @('Test1','Test2')
                        DirectMembership       = @('Device1','Device2')
                        DirectMembershipId     = @('2097152000','2097152001')
                        IncludeMembership      = @('Test3','Test4')
                        QueryRules             = $deviceQueryResults
                        Ensure                 = 'Present'
                    }

                    $deviceMatchCollectionParams = @{
                        SiteCode               = 'Lab'
                        CollectionName         = 'Test'
                        LimitingCollectionName = 'All Systems'
                        CollectionType         = 'Device'
                        RefreshType            = 'Both'
                        Comment                = 'Test device collection'
                        ScheduleInterval       = 'Days'
                        ScheduleCount          = 7
                        ExcludeMembership      = @('Test1','Test2')
                        DirectMembership       = @('2097152000','2097152001')
                        QueryRules             = $mockCimDeviceQuery
                    }

                    $collectionTypeMismatch = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        CollectionType = 'User'
                    }

                    $collectionIncludeExcludeMismatch = @{
                        SiteCode          = 'Lab'
                        CollectionName    = 'Test'
                        CollectionType    = 'Device'
                        ExcludeMembership = 'Test5'
                        IncludeMembership = 'Test5'
                    }

                    $scheduleDaysOver = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        ScheduleInterval = 'Days'
                        ScheduleCount    = 40
                    }

                    $scheduleHoursOver = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        ScheduleInterval = 'Hours'
                        ScheduleCount    = 25
                    }

                    $scheduleMinsOver = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        ScheduleInterval = 'Minutes'
                        ScheduleCount    = 80
                    }

                    $scheduleNoneOver = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        ScheduleInterval = 'None'
                    }

                    $scheduleInvalid = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        ScheduleInterval = 'Days'
                    }

                    $includeNameMatch = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        IncludeMembership = 'Device1'
                    }

                    $excludeNameMatch = @{
                        SiteCode          = 'Lab'
                        CollectionName    = 'Test'
                        CollectionType    = 'Device'
                        ExcludeMembership = 'Device1'
                    }

                    $directMembershipMisMatch = @{
                        SiteCode         = 'Lab'
                        CollectionName   = 'Test'
                        CollectionType   = 'Device'
                        DirectMembership = @('Test1','2097152005')
                    }

                    $directQueryMisMatch = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        CollectionType = 'Device'
                        QueryRules     = $mockCimDeviceQueryMismatch
                    }

                    $absentCollection = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        CollectionType = 'Device'
                        Ensure         = 'Absent'
                    }

                    $deviceManualSchedule = @{
                        SiteCode               = 'Lab'
                        CollectionName         = 'Test'
                        LimitingCollectionName = 'All Systems'
                        CollectionType         = 'Device'
                        RefreshType            = 'Manual'
                        ScheduleInterval       = 'Days'
                        ScheduleCount          = 7
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResult }
                }

                It 'Should return desired result true Ensure is present and collection is returned' {
                    Test-TargetResource @deviceMatchCollectionParams | Should -Be $true
                }

                It 'Should return desired result false when CollectionType mismatch' {
                    Test-TargetResource @collectionTypeMismatch | Should -Be $false
                }

                It 'Should return desired result false when Include and Exclude have matching settings' {
                    Test-TargetResource @collectionIncludeExcludeMismatch | Should -Be $false
                }

                It 'Should return desired result false when days mismatch' {
                    Test-TargetResource @scheduleDaysOver | Should -Be $false
                }

                It 'Should return desired result false when hours mismatch' {
                    Test-TargetResource @scheduleHoursOver | Should -Be $false
                }

                It 'Should return desired result false when minutes mismatch' {
                    Test-TargetResource @scheduleMinsOver | Should -Be $false
                }

                It 'Should return desired result false when setting none schedule' {
                    Test-TargetResource @scheduleNoneOver | Should -Be $false
                }

                It 'Should return desired result false when specifying invalid schedule' {
                    Test-TargetResource @scheduleInvalid | Should -Be $false
                }

                It 'Should return desired result false when include name already exists as a rulename' {
                    Test-TargetResource @includeNameMatch | Should -Be $false
                }

                It 'Should return desired result false when exclude name already exists as a rulename' {
                    Test-TargetResource @excludeNameMatch | Should -Be $false
                }

                It 'Should return desired result false when direct membership mismatch' {
                    Test-TargetResource @directMembershipMisMatch | Should -Be $false
                }

                It 'Should return desired result false when query membership rulename' {
                    Test-TargetResource @directQueryMisMatch | Should -Be $false
                }

                It 'Should return desired result false when collection is present and expected absent' {
                    Test-TargetResource @absentCollection | Should -Be $false
                }

                It 'Should return desired result false when manual schedule and collection schedule is specified' {
                    Test-TargetResource @deviceManualSchedule | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource collection is absent in Get-TargetResource' {
                BeforeEach {
                    $deviceGetCollectionEmpty = @{
                        SiteCode               = 'Lab'
                        CollectionName         = 'Test'
                        LimitingCollectionName = $null
                        CollectionType         = $null
                        RefreshType            = $null
                        Comment                = $null
                        RefreshSchedule        = $null
                        ExcludeMembership      = $null
                        DirectMembership       = $null
                        DirectMembershipId     = $null
                        IncludeMembership      = $null
                        QueryRules             = $null
                        Ensure                 = 'Absent'
                    }

                    $testDeviceInputAbsent = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        CollectionType = 'Device'
                        Ensure         = 'Absent'
                    }

                    $collectionAdd = @{
                        SiteCode       = 'Lab'
                        CollectionName = 'Test'
                        CollectionType = 'Device'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
                }

                It 'Should return desired result true Ensure is Absent and collection is null' {
                    Test-TargetResource @testDeviceInputAbsent | Should -Be $true
                }

                It 'Should return desired result false when Ensure is Present and the collection does not exist' {
                    Test-TargetResource @collectionAdd | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
