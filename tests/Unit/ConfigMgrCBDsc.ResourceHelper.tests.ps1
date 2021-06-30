[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)"

Import-Module $script:subModuleFile -Force -ErrorAction 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

InModuleScope $script:subModuleName {
    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Import-ConfigMgrPowerShellModule' -Tag 'Import' {
        BeforeAll {
            $moduleVersionGood = @{
                Name    = 'ConfgurationManager'
                Version = '5.1902'
            }

            $moduleVersionBad = @{
                Name    = 'ConfgurationManager'
                Version = '5.1802'
            }

            $ENV:SMS_ADMIN_UI_PATH = 'test'

            $siteCim = @{
                ServerName = 'Test.contoso.com'
                SiteCode   = 'Lab'
                SiteName   = 'Lab'
                Version    = '5.00.8790.1000'
            }
        }

        Context 'When importing the module' {
            BeforeEach {
                Mock -CommandName Join-Path -MockWith { 'C:\' }
                Mock -CommandName Split-Path -MockWith { 'C:\' }
                Mock -CommandName Import-Module
                Mock -CommandName Get-CimInstance -MockWith { $siteCim }
                Mock -CommandName Set-ItemProperty
                Mock -CommandName New-Item
                Mock -CommandName Set-ConfigMgrCert
                Mock -CommandName Get-ItemProperty
                Mock -CommandName Test-Path
            }

            It 'Should call expected commands' {
                Mock -CommandName Get-Module -MockWith { $moduleVersionGood }
                Mock -CommandName Test-Path -MockWith { $false }
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\' }

                Import-ConfigMgrPowerShellModule -SiteCode 'Lab'
                Assert-MockCalled Import-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 4 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 5 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 4 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 1 -Scope It
            }

            It 'Should throw when module version is lower than expected' {
                Mock -CommandName Get-Module -MockWith { $moduleVersionBad }
                Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'Lab:\' }

                { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
                Assert-MockCalled Import-Module -Exactly -Times 0 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 0 -Scope It
            }

            It 'Should throw on Module import' {
                Mock -CommandName Import-Module -MockWith { throw 'bad' }
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\' }

                { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
                Assert-MockCalled Import-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 4 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 5 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 4 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Convert-CidrToIP' -Tag 'CidrToIp' {

        Context 'When results are as expected' {

            It 'Should return expected results Cidr 24' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 24
                $result.NetworkAddress | Should -Be -ExpectedValue '10.1.1.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.255.255.0'
                $result.Cidr           | Should -Be -ExpectedValue '24'
            }

            It 'Should return expected results Cidr 16' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 16
                $result.NetworkAddress | Should -Be -ExpectedValue '10.1.0.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.255.0.0'
                $result.Cidr           | Should -Be -ExpectedValue '16'
            }

            It 'Should return expected results Cidr 8' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 8
                $result.NetworkAddress | Should -Be -ExpectedValue '10.0.0.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.0.0.0'
                $result.Cidr           | Should -Be -ExpectedValue '8'
            }

            It 'Should thow with invalid IP Address' {
                { Convert-CidrToIP -IPAddress 10.1.1.1.1 -Cidr 8 } | Should -Throw
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-CimCMScheduleString' -Tag 'CMScheduleString' {
        BeforeAll {
            $scheduleConvertDays = @{
                DayDuration    = 0
                DaySpan        = 6
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 0
            }
            $scheduleConvertHours = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 7
                MinuteDuration = 0
                MinuteSpan     = 0
            }
            $scheduleConvertMin = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 0
                MinuteDuration = 0
                MinuteSpan     = 50
            }
            $cimInputParamDays = @{
                CimClassName   = 'DSC_TestCimInstance'
                ScheduleString = '0001200000100030'
            }
            $cimInputParamHours = @{
                CimClassName   = 'DSC_TestCimInstance'
                ScheduleString = '0001200000100700'
            }
            $cimInputParamMinutes = @{
                CimClassName   = 'DSC_TestCimInstance'
                ScheduleString = '0001200000164000'
            }
        }

        Context 'When return is as expected' {
            It 'Should return desired result for day schedule conversion.' {
                Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertDays }
                $result = ConvertTo-CimCMScheduleString @cimInputParamDays
                $result.RecurInterval | Should -Be -ExpectedValue 'Days'
                $result.RecurCount    | Should -Be -ExpectedValue 6
                $result               | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }
            It 'Should return desired result for hour schedule conversion.' {
                Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertHours }
                $result = ConvertTo-CimCMScheduleString @cimInputParamHours
                $result.RecurInterval | Should -Be -ExpectedValue 'Hours'
                $result.RecurCount    | Should -Be -ExpectedValue 7
                $result | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }
            It 'Should return desired result for minute schedule conversion.' {
                Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertMin }
                $result = ConvertTo-CimCMScheduleString @cimInputParamMinutes
                $result.RecurInterval | Should -Be -ExpectedValue 'Minutes'
                $result.RecurCount    | Should -Be -ExpectedValue 50
                $result | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-CimBoundaries' -Tag 'CimBoundaries' {
        BeforeAll {
            $inputObject = @(
                @{
                    BoundaryID   = 16777231
                    BoundaryType = 3
                    Value        = '10.1.1.1-10.1.1.255'
                }
                @{
                    BoundaryID   = 16777232
                    BoundaryType = 0
                    Value        = '10.1.2.0'
                }
                @{
                    BoundaryID   = 16777233
                    BoundaryType = 1
                    Value        = 'First-Site'
                }
                @{
                    BoundaryID   = 16777234
                    BoundaryType = 4
                    Value        = 'Description:Virtual Adapter'
                }
            )
        }

        Context 'When results are as expected' {

            It 'Should return desired output' {

                $result = ConvertTo-CimBoundaries -InputObject $inputObject
                $result          | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.Count    | Should -Be -ExpectedValue 4
                $result[0].Value | Should -Be -ExpectedValue '10.1.1.1-10.1.1.255'
                $result[0].Type  | Should -Be -ExpectedValue 'IPRange'
                $result[1].Value | Should -Be -ExpectedValue '10.1.2.0'
                $result[1].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[2].Value | Should -Be -ExpectedValue 'First-Site'
                $result[2].Type  | Should -Be -ExpectedValue 'ADSite'
                $result[3].Value | Should -Be -ExpectedValue 'Description:Virtual Adapter'
                $result[3].Type  | Should -Be -ExpectedValue 'VPN'
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Convert-BoundariesIPSubnets' -Tag 'BoundariesIPSubnet' {
        BeforeAll {
            $mockBoundaryMembers = @(
                (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        'Type'  = 'IPSubnet'
                        'Value' = '10.1.1.1/24'
                    } `
                    -ClientOnly
                ),
                (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        'Type'  = 'IPSubnet'
                        'Value' = '10.2.2.1/16'
                    } `
                    -ClientOnly
                ),
                (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        'Type'  = 'IPSubnet'
                        'Value' = '10.3.3.1/8'
                    } `
                    -ClientOnly
                ),
                (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        'Value' = 'First-Site'
                        'Type'  = 'ADSite'
                    } `
                    -ClientOnly
                )
            )
        }

        Context 'When results are as expected' {

            It 'Should return desired output' {

                $result = Convert-BoundariesIPSubnets -InputObject $mockBoundaryMembers
                $result          | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.Count    | Should -Be -ExpectedValue 4
                $result[0].Value | Should -Be -ExpectedValue '10.1.1.0'
                $result[0].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[1].Value | Should -Be -ExpectedValue '10.2.0.0'
                $result[1].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[2].Value | Should -Be -ExpectedValue '10.0.0.0'
                $result[2].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[3].Value | Should -Be -ExpectedValue 'First-Site'
                $result[3].Type  | Should -Be -ExpectedValue 'ADSite'
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Get-BoundaryInfo' -Tag 'BoundaryInfo' {
        BeforeAll {
            $ipSubnet = @{
                Value = '10.1.1.0'
                Type  = 'IPSubnet'
            }

            $adSite = @{
                Value = 'First-Site'
                Type  = 'ADSite'
            }

            $ipRange = @{
                Value = '10.1.2.1-10.1.2.255'
                Type  = 'IPRange'
            }

            $boundaryInfo = @(
                @{
                    BoundaryID   = 16211
                    BoundaryType = 0
                    Value        = '10.1.1.0'
                }
                @{
                    BoundaryID   = 16212
                    BoundaryType = 1
                    Value        = 'First-Site'
                }
                @{
                    BoundaryID   = 16213
                    BoundaryType = 3
                    Value        = '10.1.2.1-10.1.2.255'
                }
            )
        }

        Context 'When results are as expected' {
            BeforeEach {
                Mock -CommandName Get-CMBoundary -MockWith { $boundaryInfo }
            }

            It 'Should return desired output for IPSubnet' {
                Get-BoundaryInfo @ipSubnet | Should -Be -ExpectedValue 16211
            }

            It 'Should return desired output for ADSite' {
                Get-BoundaryInfo @adSite | Should -Be -ExpectedValue 16212
            }

            It 'Should return desired output for IPRange' {
                Get-BoundaryInfo @ipRange | Should -Be -ExpectedValue 16213
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-ScheduleInterval' -Tag 'ScheduleInterval' {
        BeforeAll {
            $inputdays = @{
                ScheduleString = '0001200000100020'
            }

            $daysReturn = @{
                DayDuration    = 0
                DaySpan        = 4
                HourDuration   = 0
                HourSpan       = 0
                IsGMT          = $False
                MinuteDuration = 0
                MinuteSpan     = 0
                StartTime      = '2/1/1970 12:00:00 AM'
            }

            $inputHours = @{
                ScheduleString = '0001200000100400'
            }

            $hoursReturn = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 4
                IsGMT          = $False
                MinuteDuration = 0
                MinuteSpan     = 0
                StartTime      = '2/1/1970 12:00:00 AM'
            }

            $inputMins = @{
                ScheduleString = '0001200000164000'
            }

            $minsReturn = @{
                DayDuration    = 0
                DaySpan        = 0
                HourDuration   = 0
                HourSpan       = 0
                IsGMT          = $False
                MinuteDuration = 0
                MinuteSpan     = 50
                StartTime      = '2/1/1970 12:00:00 AM'
            }

            $inputNonrecurring = @{
                ScheduleString = '0001200000080000'
            }

            $nonrecurringReturn = @{
                DayDuration    = 0
                HourDuration   = 0
                IsGMT          = $False
                MinuteDuration = 0
                StartTime      = '2/1/1970 12:00:00 AM'
            }
        }

        Context 'When results are as expected' {

            It 'Should return desired output for days' {
                Mock -CommandName Convert-CMSchedule -MockWith { $daysReturn }

                $result = ConvertTo-ScheduleInterval @inputdays
                $result.Interval | Should -Be -ExpectedValue 'Days'
                $result.Count    | Should -Be -ExpectedValue 4
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }

            It 'Should return desired output for hours' {
                Mock -CommandName Convert-CMSchedule -MockWith { $hoursReturn }

                $result = ConvertTo-ScheduleInterval @inputHours
                $result.Interval | Should -Be -ExpectedValue 'Hours'
                $result.Count    | Should -Be -ExpectedValue 4
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }

            It 'Should return desired output for minutes' {
                Mock -CommandName Convert-CMSchedule -MockWith { $minsReturn }

                $result = ConvertTo-ScheduleInterval @inputMins
                $result.Interval | Should -Be -ExpectedValue 'Minutes'
                $result.Count    | Should -Be -ExpectedValue 50
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }

            It 'Should return desired output for schedule set to none' {
                Mock -CommandName Convert-CMSchedule -MockWith { $nonrecurringReturn }

                $result = ConvertTo-ScheduleInterval @inputNonrecurring
                $result.Interval | Should -Be -ExpectedValue 'None'
                $result.Count    | Should -Be -ExpectedValue $null
                Assert-MockCalled Convert-CMSchedule -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-AnyCimInstance' -Tag 'AnyCimInstance' {
        BeforeAll {
            $inputSingleParams = @{
                ClassName = 'MSFT_KeyPairs'
                HashTable = @{
                    Value1 = 'Value'
                }
            }

            $inputMultipleParams = @{
                ClassName = 'MSFT_KeyPairs'
                HashTable = @{
                    Value1 = 'Value'
                    Value2 = 1
                }
            }
        }

        Context 'When return is as expected' {
            It 'Should return desired result for single entry hashtable' {
                $result = ConvertTo-AnyCimInstance @inputSingleParams
                $result                       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.CimClass.CimClassName | Should -Be -ExpectedValue 'MSFT_KeyPairs'
                $result.Value1                | Should -Be -ExpectedValue 'Value'
            }

            It 'Should return desired result for multiple entry hashtable' {
                $result = ConvertTo-AnyCimInstance @inputMultipleParams
                $result                       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.CimClass.CimClassName | Should -Be -ExpectedValue 'MSFT_KeyPairs'
                $result.Value1                | Should -Be -ExpectedValue 'Value'
                $result.Value2                | Should -Be -ExpectedValue 1
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Compare-MultipleCompares' -Tag 'MultiCompare' {
        BeforeAll {
            $inputParamMatch = @{
                CurrentState = 'Device1','Device2'
                Match        = 'Device2','Device3'
                Include      = $null
                Exclude      = $null
            }

            $inputParamCurrentNull = @{
                CurrentState = $null
                Match        = 'Device2','Device3'
                Include      = $null
                Exclude      = $null
            }

            $inputParamInclude = @{
                CurrentState = 'Device1','Device2'
                Match        = $null
                Include      = 'Device2','Device3'
                Exclude      = $null
            }

            $inputParamExclude = @{
                CurrentState = 'Device1','Device2'
                Match        = $null
                Include      = $null
                Exclude      = 'Device2','Device3'
            }

            $inputParamExcludeInclude = @{
                CurrentState = 'Device1','Device2'
                Match        = $null
                Include      = 'Device4'
                Exclude      = 'Device2','Device3'
            }
        }

        Context 'When return is as expected' {
            It 'Should return desired result for desired results with match' {
                $result = Compare-MultipleCompares @inputParamMatch
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Type         | Should -Be -ExpectedValue 'Match'
                $result.Missing      | Should -Be -ExpectedValue 'Device3'
                $result.Remove       | Should -Be -ExpectedValue 'Device1'
                $result.CurrentState | Should -Be -ExpectedValue 'Device1','Device2'
            }

            It 'Should return desired result for desired missing settings with match when current state is null' {
                $result = Compare-MultipleCompares @inputParamCurrentNull
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Type         | Should -Be -ExpectedValue 'Match'
                $result.Missing      | Should -Be -ExpectedValue 'Device2','Device3'
                $result.Remove       | Should -Be -ExpectedValue $null
                $result.CurrentState | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for desired missing settings with include' {
                $result = Compare-MultipleCompares @inputParamInclude
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Type         | Should -Be -ExpectedValue 'Include'
                $result.Missing      | Should -Be -ExpectedValue 'Device3'
                $result.Remove       | Should -Be -ExpectedValue $null
                $result.CurrentState | Should -Be -ExpectedValue 'Device1','Device2'
            }

            It 'Should return desired result for desired exclude settings with exclude' {
                $result = Compare-MultipleCompares @inputParamExclude
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Type         | Should -Be -ExpectedValue 'Exclude'
                $result.Missing      | Should -Be -ExpectedValue $null
                $result.Remove       | Should -Be -ExpectedValue 'Device2'
                $result.CurrentState | Should -Be -ExpectedValue 'Device1','Device2'
            }

            It 'Should return desired result for desired exclude settings with include and exclude' {
                $result = Compare-MultipleCompares @inputParamExcludeInclude
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Type         | Should -Be -ExpectedValue 'Include, Exclude'
                $result.Missing      | Should -Be -ExpectedValue 'Device4'
                $result.Remove       | Should -Be -ExpectedValue 'Device2'
                $result.CurrentState | Should -Be -ExpectedValue 'Device1','Device2'
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Add-DPToDPGroup' -Tag 'DPToDPGroup' {
        BeforeAll {
            $inputParam = @{
                DistributionPointName      = 'DP01.contoso.com'
                DistributionPointGroupName = 'TestGroup1'
            }

            Mock -CommandName Start-Sleep
        }

        Context 'When return is as expected' {
            It 'Should return desired result for when DP is added to the group' {
                Mock -CommandName Add-CMDistributionPointToGroup

                Add-DPToDPGroup @inputParam | Should -Be $true
                Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 1 -Scope It
                Assert-MockCalled Start-Sleep -Exactly -Times 0 -Scope It
            }

            It 'Should return desired result for when DP is added to the group' {
                Mock -CommandName Add-CMDistributionPointToGroup -MockWith { throw }

                Add-DPToDPGroup @inputParam | Should -Be $false
                Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 12 -Scope It
                Assert-MockCalled Start-Sleep -Exactly -Times 12 -Scope It
            }
        }
    }

    Describe "ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Get-CMSchedule" -Tag 'GetCMSchedules' {
        BeforeAll {
            $weeklyString = @{
                ScheduleString = '00012CC008194000'
            }

            $weeklySchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurWeekly'
                Day                   = 1
                DayDuration           = 0
                ForNumberOfWeeks      = 2
                HourDuration          = 1
                IsGMT                 = $false
                MinuteDuration        = 0
                StartTime             = [datetime]'2/1/2021 12:00:00 AM'
            }

            $monthlyByDayString = @{
                ScheduleString = '00012CC008294400'
            }

            $monthlyByDaySchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurMonthlyByDate'
                DayDuration           = 0
                ForNumberOfMonths     = 1
                HourDuration          = 1
                IsGMT                 = $false
                MinuteDuration        = 5
                MonthDay              = 5
                StartTime             = [datetime]'2/1/2021 12:00:00 AM'
            }

            $monthlyByWeekString = @{
                ScheduleString = '00012CC008232400'
            }

            $monthlyByWeekSchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurMonthlyByWeekday'
                Day                   = 3
                DayDuration           = 0
                ForNumberOfMonths     = 2
                HourDuration          = 1
                IsGMT                 = $false
                MinuteDuration        = 0
                StartTime             = [datetime]'2/1/2021 12:00:00 AM'
                WeekOrder             = 2
            }

            $dayString = @{
                ScheduleString = '00012CC008100028'
            }

            $daySchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurInterval'
                DayDuration           = 0
                DaySpan               = 5
                HourDuration          = 1
                HourSpan              = 0
                IsGMT                 = $false
                MinuteDuration        = 0
                MinuteSpan            = 0
                StartTime             = [datetime]'2/1/2021 12:00:00 AM'
            }

            $hourString = @{
                ScheduleString = '0001200000100500'
            }

            $hourSchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurInterval'
                DayDuration           = 0
                DaySpan               = 0
                HourDuration          = 0
                HourSpan              = 5
                IsGMT                 = $false
                MinuteDuration        = 0
                MinuteSpan            = 0
                StartTime             = [datetime]'2/1/1970 12:00:00 AM'
            }

            $minString = @{
                ScheduleString = '0001200000176000'
            }

            $minSchedule = @{
                SmsProviderObjectPath = 'SMS_ST_RecurInterval'
                DayDuration           = 0
                DaySpan               = 0
                HourDuration          = 0
                HourSpan              = 0
                IsGMT                 = $false
                MinuteDuration        = 0
                MinuteSpan            = 59
                StartTime             = [datetime]'2/1/1970 12:00:00 AM'
            }

            $nonRecurringString = @{
                ScheduleString = '2D62200000080000'
            }

            $nonRecurring = @{
                SmsProviderObjectPath = 'SMS_ST_NonRecurring'
                DayDuration           = 0
                HourDuration          = 11
                IsGMT                 = $false
                MinuteDuration        = 0
                StartTime             = [datetime]'2/2/1970 11:11:00 AM'
            }

            $dayDurationString = @{
                ScheduleString = '0001200000880000'
            }

            $dayDuration = @{
                SmsProviderObjectPath = 'SMS_ST_NonRecurring'
                DayDuration           = 2
                HourDuration          = 0
                IsGMT                 = $false
                MinuteDuration        = 0
                StartTime             = [datetime]'2/1/1970 12:00:00 AM'
            }
        }

        Context 'When return is as expected' {
            It 'Should return desired result for ScheduleType Weekly' {
                Mock -CommandName Convert-CMSchedule -MockWith { $weeklySchedule }

                $result = Get-CMSChedule @weeklyString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'Weekly'
                $result.RecurInterval  | Should -Be -ExpectedValue 2
                $result.DayOfWeek      | Should -Be -ExpectedValue 'Sunday'
                $result.Start          | Should -Be -ExpectedValue '2/1/2021 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue 1
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType MonthlyByDay' {
                Mock -CommandName Convert-CMSchedule -MockWith { $monthlyByDaySchedule }

                $result = Get-CMSChedule @monthlyByDayString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue 5
                $result.ScheduleType   | Should -Be -ExpectedValue 'MonthlyByDay'
                $result.RecurInterval  | Should -Be -ExpectedValue 1
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/1/2021 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue 1
                $result.MinuteDuration | Should -Be -ExpectedValue 5
            }

            It 'Should return desired result for ScheduleType MonthlyByWeek' {
                Mock -CommandName Convert-CMSchedule -MockWith { $monthlyByWeekSchedule }

                $result = Get-CMSChedule @monthlyByWeekString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'MonthlyByWeek'
                $result.RecurInterval  | Should -Be -ExpectedValue 2
                $result.DayOfWeek      | Should -Be -ExpectedValue 'Tuesday'
                $result.Start          | Should -Be -ExpectedValue '2/1/2021 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue 'Second'
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue 1
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType Days' {
                Mock -CommandName Convert-CMSchedule -MockWith { $daySchedule }

                $result = Get-CMSChedule @dayString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'Days'
                $result.RecurInterval  | Should -Be -ExpectedValue 5
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/1/2021 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue 1
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType Hours' {
                Mock -CommandName Convert-CMSchedule -MockWith { $hourSchedule }

                $result = Get-CMSChedule @hourString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'Hours'
                $result.RecurInterval  | Should -Be -ExpectedValue 5
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/1/1970 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue $null
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType Minutes' {
                Mock -CommandName Convert-CMSchedule -MockWith { $minSchedule }

                $result = Get-CMSChedule @minString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'Minutes'
                $result.RecurInterval  | Should -Be -ExpectedValue 59
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/1/1970 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue $null
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType Nonrecurring' {
                Mock -CommandName Convert-CMSchedule -MockWith { $nonRecurring }

                $result = Get-CMSChedule @nonRecurringString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'None'
                $result.RecurInterval  | Should -Be -ExpectedValue $null
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/2/1970 11:11'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue $null
                $result.HourDuration   | Should -Be -ExpectedValue 11
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }

            It 'Should return desired result for ScheduleType Nonrecurring day duration' {
                Mock -CommandName Convert-CMSchedule -MockWith { $dayDuration }

                $result = Get-CMSChedule @dayDurationString
                $result                | Should -BeOfType System.Collections.HashTable
                $result.MonthDay       | Should -Be -ExpectedValue $null
                $result.ScheduleType   | Should -Be -ExpectedValue 'None'
                $result.RecurInterval  | Should -Be -ExpectedValue $null
                $result.DayOfWeek      | Should -Be -ExpectedValue $null
                $result.Start          | Should -Be -ExpectedValue '2/1/1970 00:00'
                $result.WeekOrder      | Should -Be -ExpectedValue $null
                $result.DayDuration    | Should -Be -ExpectedValue 2
                $result.HourDuration   | Should -Be -ExpectedValue $null
                $result.MinuteDuration | Should -Be -ExpectedValue $null
            }
        }
    }

    Describe "ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Test-CMSchedule" -Tag 'TestCMSchedules' {
        BeforeAll {
            $state = @{
                DayofMonth       = $null
                DayOfWeek        = $null
                Start            = '02/01/2021 00:00'
                RecurInterval    = 5
                MinuteDuration   = $null
                IsEnabled        = $true
                HourDuration     = 1
                MonthlyWeekOrder = $null
                ScheduleType     = 'Days'
            }

            $monthlyByWeek = @{
                ScheduleType     = 'MonthlyByWeek'
                HourDuration     = 1
                Start            = '02/01/2021 00:00'
                RecurInterval    = 5
                DayOfWeek        = 'Sunday'
                MonthlyWeekOrder = 'Second'
                State            = $state
            }

            $monthlyByWeekMissingParams = @{
                ScheduleType  = 'MonthlyByWeek'
                HourDuration  = 1
                Start         = '02/01/2021 00:00'
                RecurInterval = 5
                DayOfWeek     = 'Sunday'
                State         = $state
            }

            $monthlyByDay = @{
                ScheduleType   = 'MonthlyByDay'
                MinuteDuration = 10
                Start          = '14/01/2021 00:00'
                RecurInterval  = 40
                DayOfMonth     = 3
                State          = $state
            }

            $monthlyByDayMissingParams = @{
                ScheduleType   = 'MonthlyByDay'
                MinuteDuration = 10
                Start          = '01/01/2021 00:00'
                RecurInterval  = 40
                State          = $state
            }

            $weekly = @{
                ScheduleType   = 'Weekly'
                MinuteDuration = 59
                Start          = '02/01/2021 00:00'
                RecurInterval  = 4
                DayOfWeek      = 'Sunday'
                State          = $state
            }

            $weeklyMissingParams = @{
                ScheduleType  = 'Weekly'
                HourDuration  = 1
                Start         = '02/01/2021 00:00'
                RecurInterval = 5
                State         = $state
            }

            $days = @{
                ScheduleType  = 'Days'
                Start         = '02/01/2021 00:00'
                RecurInterval = 40
                State         = $state
            }

            $daysMatch = @{
                ScheduleType  = 'Days'
                RecurInterval = 5
                HourDuration  = 1
                Start         = '02/01/2021 00:00'
                State         = $state
            }

            $hours = @{
                ScheduleType  = 'Hours'
                Start         = '02/01/2021 00:00'
                RecurInterval = 40
                State         = $state
            }

            $minutes = @{
                ScheduleType  = 'Minutes'
                Start         = '02/01/2021 00:00'
                RecurInterval = 70
                State         = $state
            }

            $minutesMin = @{
                ScheduleType  = 'Minutes'
                Start         = '02/01/2021 00:00'
                RecurInterval = 1
                State         = $state
            }

            $missingRecur = @{
                ScheduleType = 'Minutes'
                Start        = '02/01/2021 00:00'
                State        = $state
            }
        }

        Context 'When running Test-CMSchedules should returned desired results' {
            It 'Should return desired result false when returned ScheduleType Day and desire MonthlyByWeek' {
                Test-CMSchedule @monthlyByWeek | Should -Be $false
            }

            It 'Should return desired result false when returned ScheduleType Day and desire MonthlyByWeek missing params' {
                Test-CMSchedule @monthlyByWeekMissingParams | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire MonthlyByDay' {
                Test-CMSchedule @monthlyByDay | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire MonthlyByDay missing params' {
                Test-CMSchedule @monthlyByDayMissingParams | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire Weekly' {
                Test-CMSchedule @weekly | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire Weekly missing params' {
                Test-CMSchedule @weeklyMissingParams | Should -Be $false
            }

            It 'Should return desired result true when return ScheduleType Day and desire Days settings match' {
                Test-CMSchedule @daysMatch | Should -Be $true
            }

            It 'Should return desired result false when return ScheduleType Day and desire Days settings do not match' {
                Test-CMSchedule @days | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire Hours settings do not match' {
                Test-CMSchedule @hours | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire minutes settings do not match' {
                Test-CMSchedule @minutes | Should -Be $false
            }

            It 'Should return desired result false when return ScheduleType Day and desire minutes settings do not match and below minute limit' {
                Test-CMSchedule @minutesMin | Should -Be $false
            }

            It 'Should return desired result false when input is missing RecurInterval' {
                Test-CMSchedule @missingRecur | Should -Be $false
            }
        }
    }

    Describe "ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Set-CMSchedule" -Tag 'SetCMSchedules' {
        BeforeAll {
            $inputMonthlyByWeek = @{
                ScheduleType     = 'MonthlyByWeek'
                DayOfWeek        = 'Friday'
                MonthlyWeekOrder = 'First'
                HourDuration     = 5
                RecurInterval    = 1
            }

            $inputMonthlyByDay = @{
                ScheduleType   = 'MonthlyByDay'
                DayOfMonth     = 4
                MinuteDuration = 59
                RecurInterval  = 13
            }

            $inputWeekly = @{
                ScheduleType   = 'Weekly'
                DayOfWeek      = 'Friday'
                MinuteDuration = 59
                RecurInterval  = 7
            }

            $inputDay = @{
                ScheduleType  = 'Days'
                RecurInterval = 30
                Start         = '01/23/1970 00:00'
            }

            $inputDayOver = @{
                ScheduleType  = 'Days'
                RecurInterval = 40
            }

            $inputHour = @{
                ScheduleType  = 'Hours'
                RecurInterval = 12
            }

            $inputHourOver = @{
                ScheduleType  = 'Hours'
                RecurInterval = 24
            }

            $inputMinutes = @{
                ScheduleType  = 'Minutes'
                RecurInterval = 30
            }

            $inputMinutesOver = @{
                ScheduleType  = 'Minutes'
                RecurInterval = 60
            }

            $inputMinutesUnder = @{
                ScheduleType  = 'Minutes'
                RecurInterval = 1
            }

            $inputNonrecurring = @{
                ScheduleType = 'None'
            }
        }

        Context 'When return is as expected' {
            It 'Should return desired result for ScheduleType MonthlyByWeek' {
                $result = Set-CMSChedule @inputMonthlyByWeek
                $result                  | Should -BeOfType System.Collections.HashTable
                $result.DurationCount    | Should -Be -ExpectedValue 5
                $result.RecurCount       | Should -Be -ExpectedValue 1
                $result.DurationInterval | Should -Be -ExpectedValue 'Hours'
                $result.DayOfWeek        | Should -Be -ExpectedValue 'Friday'
                $result.WeekOrder        | Should -Be -ExpectedValue 'First'
            }

            It 'Should return desired result for ScheduleType MonthlyByDay' {
                $result = Set-CMSChedule @inputMonthlyByDay
                $result                  | Should -BeOfType System.Collections.HashTable
                $result.DurationInterval | Should -Be -ExpectedValue 'Minutes'
                $result.DurationCount    | Should -Be -ExpectedValue 59
                $result.RecurCount       | Should -Be -ExpectedValue 12
                $result.DayOfMonth       | Should -Be -ExpectedValue 4
            }

            It 'Should return desired result for ScheduleType Weekly' {
                $result = Set-CMSChedule @inputWeekly
                $result                  | Should -BeOfType System.Collections.HashTable
                $result.DurationInterval | Should -Be -ExpectedValue 'Minutes'
                $result.DurationCount    | Should -Be -ExpectedValue 59
                $result.RecurCount       | Should -Be -ExpectedValue 4
                $result.DayOfWeek        | Should -Be -ExpectedValue 'Friday'
            }

            It 'Should return desired result for ScheduleType Days' {
                $result = Set-CMSChedule @inputDay
                $result                  | Should -BeOfType System.Collections.HashTable
                $result.RecurCount       | Should -Be -ExpectedValue 30
                $result.RecurInterval    | Should -Be -ExpectedValue 'Days'
                $result.Start            | Should -BeOfType datetime
                $result.Start.ToString() | Should -Be -ExpectedValue '1/23/1970 12:00:00 AM'
            }

            It 'Should return desired result for ScheduleType Days over interval limit' {
                $result = Set-CMSChedule @inputDayOver
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 31
                $result.RecurInterval | Should -Be -ExpectedValue 'Days'
            }

            It 'Should return desired result for ScheduleType Hours' {
                $result = Set-CMSChedule @inputHour
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 12
                $result.RecurInterval | Should -Be -ExpectedValue 'Hours'
            }

            It 'Should return desired result for ScheduleType Hours over interval limit' {
                $result = Set-CMSChedule @inputHourOver
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 23
                $result.RecurInterval | Should -Be -ExpectedValue 'Hours'
            }

            It 'Should return desired result for ScheduleType Minutes' {
                $result = Set-CMSChedule @inputMinutes
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 30
                $result.RecurInterval | Should -Be -ExpectedValue 'Minutes'
            }

            It 'Should return desired result for ScheduleType Minutes over interval limit' {
                $result = Set-CMSChedule @inputMinutesOver
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 59
                $result.RecurInterval | Should -Be -ExpectedValue 'Minutes'
            }

            It 'Should return desired result for ScheduleType Minutes under interval limit' {
                $result = Set-CMSChedule @inputMinutesUnder
                $result               | Should -BeOfType System.Collections.HashTable
                $result.RecurCount    | Should -Be -ExpectedValue 5
                $result.RecurInterval | Should -Be -ExpectedValue 'Minutes'
            }

            It 'Should return desired result for ScheduleType None' {
                $result = Set-CMSChedule @inputNonrecurring
                $result              | Should -BeOfType System.Collections.HashTable
                $result.Nonrecurring | Should -Be -ExpectedValue $null
            }
        }

        Context 'Should throw when params missing or incorrect' {
            BeforeEach {
                $invalidStartTime = @{
                    ScheduleType  = 'Days'
                    RecurInterval = 1
                    Start         = '13/1/21 00:44'
                }

                $startError = 'Start: 13/1/21 00:44 is not formatted correctly, example: 01/01/2021 01:00.'
                $missingRecurInterval = @{
                    ScheduleType = 'Days'
                }

                $recurIntervalError = 'Missing RecurInverval setting for the schedule, setting a schedule will fail.'

                $inputMonthlyByWeekParams = @{
                    ScheduleType  = 'MonthlyByWeek'
                    DayOfWeek     = 'Friday'
                    HourDuration  = 5
                    RecurInterval = 1
                }

                $monthlyByWeekError = 'ScheduleType of MonthWeekly is missing MonthlyWeekOrder or DayofWeek.'

                $inputMonthlyByDayParams = @{
                    ScheduleType   = 'MonthlyByDay'
                    MinuteDuration = 29
                    RecurInterval  = 12
                }

                $monthlyByDayError = 'ScheduleType of MonthlyByDay is missing DayOfMonth.'

                $inputWeeklyParams = @{
                    ScheduleType   = 'Weekly'
                    MinuteDuration = 59
                    RecurInterval  = 3
                }

                $weeklyError = 'ScheduleType of Weekly is missing DayOfWeek.'
            }

            It 'Should throw when specifying an invalid start time' {
                { Set-CMSChedule @invalidStartTime } | Should -Throw -ExpectedMessage $startError
            }

            It 'Should throw when specifying a schedule and not specifying RecurInterval' {
                { Set-CMSChedule @missingRecurInterval } | Should -Throw -ExpectedMessage $recurIntervalError
            }

            It 'Should throw when ScheduleType MonthlyByWeek and missing params' {
                { Set-CMSChedule @inputMonthlyByWeekParams } | Should -Throw -ExpectedMessage $monthlyByWeekError
            }

            It 'Should throw when ScheduleType MonthlyByWeek and missing params' {
                { Set-CMSChedule @inputMonthlyByDayParams } | Should -Throw -ExpectedMessage $monthlyByDayError
            }

            It 'Should throw when ScheduleType Weekly and missing params' {
                { Set-CMSChedule @inputWeeklyParams } | Should -Throw -ExpectedMessage $weeklyError
            }
        }
    }
}
