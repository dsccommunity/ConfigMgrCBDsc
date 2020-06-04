param ()

# Begin Testing
BeforeAll {
    # Import Stub function
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
    $initalize = @{
        DSCModuleName   = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMCollections'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMCollections\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving Collection settings' {
        It 'Should return desired result for device collections with no collection updates' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshNone  }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeNullOrEmpty
            $result.RefreshType            | Should -Be -ExpectedValue 'Manual'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for device collections' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResult }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.RefreshType            | Should -Be -ExpectedValue 'Both'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for device collections with periodic updates' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshPeriodic  }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.RefreshType            | Should -Be -ExpectedValue 'Periodic'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for device collections with no collection updates' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultRefreshContinuous  }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeNullOrEmpty
            $result.RefreshType            | Should -Be -ExpectedValue 'Continuous'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for device collections with minutes schedule' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultMin  }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.RefreshType            | Should -Be -ExpectedValue 'Both'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for device collections with hours schedule' {
            Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionResultHour  }
            Mock -CommandName Get-CMDeviceCollectionDirectMembershipRule -MockWith { $deviceDirectResult }
            Mock -CommandName Get-CMDeviceCollectionExcludeMembershipRule -MockWith { $deviceExcludeResults }
            Mock -CommandName Get-CMDeviceCollectionQueryMembershipRule -MockWith { $deviceQueryResults }

            $result = Get-TargetResource @getDeviceInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'Test'
            $result.Comment                | Should -Be -ExpectedValue 'Test device collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'Device'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Systems'
            $result.RefreshSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.RefreshType            | Should -Be -ExpectedValue 'Both'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('Test1','Test2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for user collections' {
            Mock -CommandName Get-CMCollection -MockWith { $userCollectionResult }
            Mock -CommandName Get-CMUserCollectionDirectMembershipRule -MockWith { $userDirectResult }
            Mock -CommandName Get-CMUserCollectionExcludeMembershipRule -MockWith { $userExcludeResults }
            Mock -CommandName Get-CMUserCollectionQueryMembershipRule -MockWith { $userQueryResults }

            $result = Get-TargetResource @getUserInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'User1'
            $result.Comment                | Should -Be -ExpectedValue 'Test user collection'
            $result.CollectionType         | Should -Be -ExpectedValue 'User'
            $result.LimitingCollectionName | Should -Be -ExpectedValue 'All Users'
            $result.RefreshSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.RefreshType            | Should -Be -ExpectedValue 'Both'
            $result.QueryRules             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.QueryRules.Count       | Should -Be -ExpectedValue 2
            $result.ExcludeMembership      | Should -Be -ExpectedValue @('TestUser1','TestUser2')
            $result.DirectMembership       | Should -Be -ExpectedValue @('2097152000','2097152001')
            $result.Ensure                 | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result for user collections does not exist' {
            Mock -CommandName Get-CMCollection
            Mock -CommandName Get-CMUserCollectionDirectMembershipRule
            Mock -CommandName Get-CMUserCollectionExcludeMembershipRule
            Mock -CommandName Get-CMUserCollectionQueryMembershipRule

            $result = Get-TargetResource @getUserInput
            $result                        | Should -BeOfType System.Collections.HashTable
            $result.SiteCode               | Should -Be -ExpectedValue 'Lab'
            $result.CollectionName         | Should -Be -ExpectedValue 'User1'
            $result.Comment                | Should -BeNullOrEmpty
            $result.CollectionType         | Should -BeNullOrEmpty
            $result.LimitingCollectionName | Should -BeNullOrEmpty
            $result.RefreshSchedule        | Should -BeNullOrEmpty
            $result.RefreshType            | Should -BeNullOrEmpty
            $result.QueryRules             | Should -BeNullOrEmpty
            $result.ExcludeMembership      | Should -BeNullOrEmpty
            $result.DirectMembership       | Should -BeNullOrEmpty
            $result.Ensure                 | Should -Be -ExpectedValue 'Absent'
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMCollections\Set-TargetResource' -Tag 'Set' {
        BeforeAll{
        $testEnvironment = Initialize-TestEnvironment @initalize

        $mockCimRefreshSchedule = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 7
                } `
                -ClientOnly
        )

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

        $newCMScheduleDaysMatch = @{
            DayDuration    = 0
            DaySpan        = 7
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 0
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

        $testDeviceInputAbsent = @{
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            CollectionType = 'Device'
            Ensure         = 'Absent'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections
        Mock -CommandName Set-Location
        Mock -CommandName New-CMCollection
        Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }
        Mock -CommandName Set-CMCollection
        Mock -CommandName Add-CMUserCollectionExcludeMembershipRule
        Mock -CommandName Add-CMUserCollectionDirectMembershipRule
        Mock -CommandName Add-CMUserCollectionQueryMembershipRule
        Mock -CommandName Add-CMDeviceCollectionExcludeMembershipRule
        Mock -CommandName Add-CMDeviceCollectionDirectMembershipRule
        Mock -CommandName Add-CMDeviceCollectionQueryMembershipRule
        Mock -CommandName Remove-CMCollection
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        BeforeEach {
            $mockCimRefreshScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 6
                } `
                -ClientOnly
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

            $newCMScheduleHours = @{
                DayDuration    = 0
                DaySpan        = 0
                IsGMT          = $false
                HourDuration   = 0
                HourSpan       = 6
                MinuteDuration = 0
                MinuteSpan     = 0
            }

            $deviceScheduleDay = @{
                SiteCode               = 'Lab'
                CollectionName         = 'Test'
                LimitingCollectionName = 'All Systems'
                CollectionType         = 'Device'
                RefreshSchedule        = $mockCimRefreshScheduleDayMismatch
            }
        }

        It 'Should call expected commands for creating new device collection' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }

            Set-TargetResource @deviceDirectMismatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 2 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands for creating new user collection' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }

            Set-TargetResource @userDirectMismatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands for setting schedule and direct membership rule' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }

            Set-TargetResource @deviceDirectMismatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 0 -Scope It
            Should -Invoke New-CMSchedule -Exactly 2 -Scope It
            Should -Invoke Set-CMCollection -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands for setting eval schedule mismatch' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }

            Set-TargetResource @deviceEvalItemsMisMatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 0 -Scope It
            Should -Invoke New-CMSchedule -Exactly 2 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands for removing collection' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }

            Set-TargetResource @testDeviceInputAbsent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 0 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMCollection -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 1 -Scope It
        }

        It 'Should call expected commands when changing the schedule' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleHours } -ParameterFilter { $RecurInterval -eq 'Hours' }
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch } -ParameterFilter { $RecurInterval -eq 'Days' }

            Set-TargetResource @deviceScheduleDay
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 0 -Scope It
            Should -Invoke New-CMSchedule -Exactly 2 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }
    }

    Context 'When running Set-TargetResource should throw' {

        It 'Should call expected commands and throw if query membership throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName Add-CMDeviceCollectionQueryMembershipRule -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 1 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if direct membership throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName Add-CMDeviceCollectionDirectMembershipRule -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 2 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if exclude membership throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName Add-CMDeviceCollectionExcludeMembershipRule -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if set collection throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName Set-CMCollection -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 1 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if new schedule throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName New-CMSchedule -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMCollection -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if new collection throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
            Mock -CommandName New-CMCollection -MockWith { throw }

            { Set-TargetResource @deviceEvalItemsMisMatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMCollection -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if remove collection throws' {
            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResultSchedule }
            Mock -CommandName Remove-CMCollection -MockWith { throw }

            { Set-TargetResource @testDeviceInputAbsent } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMCollection -Exactly 0 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMCollection -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionExcludeMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionDirectMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMUserCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Add-CMDeviceCollectionQueryMembershipRule -Exactly 0 -Scope It
            Should -Invoke Remove-CMCollection -Exactly 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMCollections\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $mockCimRefreshSchedule = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 7
                } `
                -ClientOnly
        )

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

        $newCMScheduleDaysMatch = @{
            DayDuration    = 0
            DaySpan        = 7
            IsGMT          = $false
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 0
        }

        $testDeviceInputAbsent = @{
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            CollectionType = 'Device'
            Ensure         = 'Absent'
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

        Mock -CommandName Set-Location
        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMCollections
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource device settings' {
        BeforeEach {
            $mockCimRefreshScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 6
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

            $mockCimRefreshScheduleHours = (New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Hours'
                    'RecurCount'    = 7
                } `
                -ClientOnly
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

            $deviceScheduleDay = @{
                SiteCode               = 'Lab'
                CollectionName         = 'Test'
                LimitingCollectionName = 'All Systems'
                CollectionType         = 'Device'
                RefreshSchedule        = $mockCimRefreshScheduleDayMismatch
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

            $deviceScheduleHours = @{
                SiteCode               = 'Lab'
                CollectionName         = 'Test'
                LimitingCollectionName = 'All Systems'
                CollectionType         = 'Device'
                RefreshSchedule        = $mockCimRefreshScheduleHours
            }

            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionResult }
        }

        It 'Should return desired result true Ensure is present and collection is returned' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceMatchCollectionParams | Should -BeTrue
        }

        It 'Should return desired result false Ensure is present and schedule days does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysNotMatch } -ParameterFilter { $RecurCount -eq 6 }
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch } -ParameterFilter { $RecurCount -eq 7 }

            Test-TargetResource @deviceScheduleDay | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and schedule hours does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleHours } -ParameterFilter { $RecurInterval -eq 'Hours' }
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch } -ParameterFilter { $RecurInterval -eq 'Days' }

            Test-TargetResource @deviceScheduleHours | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and schedule minutes does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleMinutes } -ParameterFilter { $RecurInterval -eq 'Minutes' }
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch } -ParameterFilter { $RecurInterval -eq 'Days' }

            Test-TargetResource @deviceScheduleMin | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and comment does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceCommentItemsMisMatch | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and refreshtype does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceEvalItemsMisMatch | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and excluded collections does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceExcludeMismatch | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and direct membership does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceDirectMismatch | Should -BeFalse
        }

        It 'Should return desired result false Ensure is present and collection query does not match' {
            Mock -CommandName New-CMSchedule -MockWith { $newCMScheduleDaysMatch }

            Test-TargetResource @deviceQueryMismatch | Should -BeFalse
        }

        It 'Should return desired result false Ensure is Absent and collection is returned' {
            Test-TargetResource @testDeviceInputAbsent | Should -BeFalse
        }
    }

    Context 'When running Test-TargetResource collection and Get-TargetResource returns Null schedule' {
        BeforeEach {
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

            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionNullSchedule }
        }

        It 'Should return desired result true Ensure is Absent and collection is null' {
            Test-TargetResource @deviceMatchCollectionParams | Should -BeFalse
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
                QueryRules             = $null
                Ensure                 = 'Absent'
            }

            Mock -CommandName Get-TargetResource -MockWith { $deviceGetCollectionEmpty }
        }

        It 'Should return desired result true Ensure is Absent and collection is null' {
            Test-TargetResource @testDeviceInputAbsent | Should -BeTrue
        }

        It 'Should return desired result false when Ensure is Present and the collection does not exist' {
            Test-TargetResource @deviceQueryMismatch | Should -BeFalse
        }
    }
}
