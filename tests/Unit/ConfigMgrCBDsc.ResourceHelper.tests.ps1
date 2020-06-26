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

InModuleScope $script:subModuleName {

    $moduleResourceName = 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper'

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

    Describe "$moduleResourceName\Import-ConfigMgrPowerShellModule" {

        Context 'When importing the module' {
            Mock -CommandName Join-Path -MockWith { 'C:\' }
            Mock -CommandName Split-Path -MockWith { 'C:\' }
            Mock -CommandName Import-Module
            Mock -CommandName Get-CimInstance -MockWith { $siteCim }
            Mock -CommandName Set-ItemProperty
            Mock -CommandName New-Item
            Mock -CommandName Set-ConfigMgrCert
            Mock -CommandName Get-ItemProperty
            Mock -CommandName Test-Path

            It 'Should call expected commands' {
                Mock -CommandName Get-Module -MockWith { $moduleVersionGood }
                Mock -CommandName Test-Path -MockWith { $false }
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  }

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
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  }

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

    Describe "$moduleResourceName\Convert-CidrToIP" {

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

    Describe "$moduleResourceName\ConvertTo-CimCMScheduleString" {
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

    Describe "$moduleResourceName\Convert-BoundariesIPSubnets" {

        $inputObject = @(
            @{
                BoundaryID = 16777231
                BoundaryType = 3
                Value        = '10.1.1.1-10.1.1.255'
            }
            @{
                BoundaryID = 16777232
                BoundaryType = 0
                Value        = '10.1.2.0'
            }
            @{
                BoundaryID = 16777233
                BoundaryType = 1
                Value        = 'First-Site'
            }

        )

        Context 'When results are as expected' {

            It 'Should return desired output' {

                $result = ConvertTo-CimBoundaries -InputObject $inputObject
                $result          | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.Count    | Should -Be -ExpectedValue 3
                $result[0].Value | Should -Be -ExpectedValue '10.1.1.1-10.1.1.255'
                $result[0].Type  | Should -Be -ExpectedValue 'IPRange'
                $result[1].Value | Should -Be -ExpectedValue '10.1.2.0'
                $result[1].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[2].Value | Should -Be -ExpectedValue 'First-Site'
                $result[2].Type  | Should -Be -ExpectedValue 'ADSite'
            }
        }
    }

    Describe "$moduleResourceName\ConvertTo-CimBoundaries" {

        $mockBoundaryMembers = @(
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
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
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Type'  = 'IPSubnet'
                    'Value' = '10.3.3.1/8'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = 'First-Site'
                    'Type'  = 'ADSite'
                } `
                -ClientOnly
            )
        )

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

    Describe "$moduleResourceName\Get-BoundaryInfo" {

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

        Context 'When results are as expected' {
            Mock -CommandName Get-CMBoundary -MockWith { $boundaryInfo }

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

    Describe "$moduleResourceName\ConvertTo-ScheduleInterval" {
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

    Describe "$moduleResourceName\ConvertTo-AnyCimInstance" {
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

    Describe "$moduleResourceName\Compare-MultipleCompares" {
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
}
