[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

BeforeAll{
    # Import Stub function
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction 'SilentlyContinue'

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
}

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Import-ConfigMgrPowerShellModule' -Tag 'Import-ConfigMgrPowerShellModule' {
    BeforeAll {
        $moduleVersionGood = @{
            Name    = 'ConfgurationManager'
            Version = '5.1902'
        }

        $moduleVersionBad = @{
            Name    = 'ConfgurationManager'
            Version = '5.1802'
        }

        $siteCim = @{
            ServerName = 'Test.contoso.com'
            SiteCode   = 'Lab'
            SiteName   = 'Lab'
            Version    = '5.00.8790.1000'
        }

        $ENV:SMS_ADMIN_UI_PATH = 'test'

        Mock -CommandName Join-Path -MockWith { 'C:\' } -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Split-Path -MockWith { 'C:\' } -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Import-Module -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Get-CimInstance -MockWith { $siteCim } -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Set-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName New-Item -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Set-ConfigMgrCert -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Get-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper
        Mock -CommandName Test-Path -ModuleName ConfigMgrCBDsc.ResourceHelper
    }
    AfterAll {
        $ENV:SMS_ADMIN_UI_PATH = $null
    }

    Context 'When importing the module' {
        It 'Should call expected commands' {
            Mock -CommandName Get-Module -MockWith { $moduleVersionGood } -ModuleName ConfigMgrCBDsc.ResourceHelper
            Mock -CommandName Test-Path -MockWith { $false } -ModuleName ConfigMgrCBDsc.ResourceHelper
            Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  } -ModuleName ConfigMgrCBDsc.ResourceHelper

            Import-ConfigMgrPowerShellModule -SiteCode 'Lab'
            Assert-MockCalled Import-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Join-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Split-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-CimInstance -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled New-Item -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 4 -Scope It
            Assert-MockCalled Test-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 5 -Scope It
            Assert-MockCalled Set-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 4 -Scope It
            Assert-MockCalled Set-ConfigMgrCert -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
        }

        It 'Should throw when module version is lower than expected' {
            Mock -CommandName Get-Module -MockWith { $moduleVersionBad } -ModuleName ConfigMgrCBDsc.ResourceHelper
            Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'Lab:\' } -ModuleName ConfigMgrCBDsc.ResourceHelper

            { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
            Assert-MockCalled Import-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Join-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Split-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Get-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-CimInstance -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Get-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled New-Item -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Test-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Set-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Set-ConfigMgrCert -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
        }

        It 'Should throw on Module import' {
            Mock -CommandName Import-Module -MockWith { throw 'bad' } -ModuleName ConfigMgrCBDsc.ResourceHelper
            Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  } -ModuleName ConfigMgrCBDsc.ResourceHelper

            { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
            Assert-MockCalled Import-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Join-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Split-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-Module -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 0 -Scope It
            Assert-MockCalled Get-CimInstance -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled Get-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
            Assert-MockCalled New-Item -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 4 -Scope It
            Assert-MockCalled Test-Path -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 5 -Scope It
            Assert-MockCalled Set-ItemProperty -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 4 -Scope It
            Assert-MockCalled Set-ConfigMgrCert -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Convert-CidrToIP'  -Tag 'Convert-CidrToIP' {
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

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-CimCMScheduleString' -Tag 'ConvertTo-CimCMScheduleString' {
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
            Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertDays } -ModuleName ConfigMgrCBDsc.ResourceHelper

            $result = ConvertTo-CimCMScheduleString @cimInputParamDays
            $result.RecurInterval | Should -Be -ExpectedValue 'Days'
            $result.RecurCount    | Should -Be -ExpectedValue 6
            $result               | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            Should -Invoke Convert-CMSchedule -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly 1 -Scope It
        }
        It 'Should return desired result for hour schedule conversion.' {
            Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertHours } -ModuleName ConfigMgrCBDsc.ResourceHelper

            $result = ConvertTo-CimCMScheduleString @cimInputParamHours
            $result.RecurInterval | Should -Be -ExpectedValue 'Hours'
            $result.RecurCount    | Should -Be -ExpectedValue 7
            $result | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            Should -Invoke Convert-CMSchedule -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly 1 -Scope It
        }
        It 'Should return desired result for minute schedule conversion.' {
            Mock -CommandName Convert-CMSchedule -MockWith { $scheduleConvertMin } -ModuleName ConfigMgrCBDsc.ResourceHelper

            $result = ConvertTo-CimCMScheduleString @cimInputParamMinutes
            $result.RecurInterval | Should -Be -ExpectedValue 'Minutes'
            $result.RecurCount    | Should -Be -ExpectedValue 50
            $result | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            Should -Invoke Convert-CMSchedule -ModuleName ConfigMgrCBDsc.ResourceHelper -Exactly 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\ConvertTo-CimBoundaries' -Tag 'ConvertTo-CimBoundaries' {
    BeforeAll{
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
    }

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

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Convert-BoundariesIPSubnets' -Tag 'Convert-BoundariesIPSubnets' {
    BeforeAll {
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

Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Get-BoundaryInfo' -Tag 'Get-BoundaryInfo' {
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
        Mock -CommandName Get-CMBoundary -MockWith { $boundaryInfo }  -ModuleName ConfigMgrCBDsc.ResourceHelper
    }

    Context 'When results are as expected' {
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
