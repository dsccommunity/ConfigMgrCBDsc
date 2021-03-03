[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMFileReplication'

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

        Describe 'DSC_CMFileReplication\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $getInput = @{
                    SiteCode            = 'Lab'
                    DestinationSiteCode = 'CAS'
                }

                $replRouteLimited = @{
                    UnlimitedRateForAll = $false
                    PropLists = @{
                        PropertyListName = 'Pulse Mode'
                        Values           = @(0,3,5)
                    }
                    Props = @(
                        @{
                            PropertyName = 'Connection Point'
                            Value        = 0
                            Value1       = 'CAS.Contoso.com'
                            Value2       = 'SMS_Site'
                        }
                        @{
                            PropertyName = 'Lan Login'
                            Value        = 0
                            Value1       = $null
                            Value2       = $null
                        }
                    )
                    RateLimitingSchedule = @(70,70,70,70,90,90,90,90,90,90,90,90,80,80,80,80,80,80,80,
                                            80,80,80,80,80)
                    UsageSchedule       = @(
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                        }
                        @{
                            HourUsage = @(2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2)
                        }
                        @{
                            HourUsage = @(3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3)
                        }
                        @{
                            HourUsage = @(4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
                        }
                        @{
                            HourUsage = @(2,2,2,2,2,2,1,1,1,1,1,3,3,3,3,3,3,3,4,4,4,4,4,4)
                        }
                        @{
                            HourUsage = @(1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2)
                        }
                        @{
                            HourUsage = @(4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2)
                        }
                    )
                }

                $replRoutePulse = @{
                    UnlimitedRateForAll = $false
                    PropLists =@{
                        PropertyListName = 'Pulse Mode'
                        Values           = @(1,3,5)
                    }
                    Props = @(
                        @{
                            PropertyName = 'Connection Point'
                            Value        = 0
                            Value1       = 'CAS.Contoso.com'
                            Value2       = 'SMS_Site'
                        }
                        @{
                            PropertyName = 'Lan Login'
                            Value        = 0
                            Value1       = $null
                            Value2       = $null
                        }
                    )
                    RateLimitingSchedule = @(100,100,100,100,100,100,100,100,100,100,100,100,100,
                                             100,100,100,100,100,100,100,100,100,100,100)
                    UsageSchedule       = @(
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                        }
                        @{
                            HourUsage = @(2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2)
                        }
                        @{
                            HourUsage = @(3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3)
                        }
                        @{
                            HourUsage = @(4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
                        }
                        @{
                            HourUsage = @(2,2,2,2,2,2,1,1,1,1,1,3,3,3,3,3,3,3,4,4,4,4,4,4)
                        }
                        @{
                            HourUsage = @(1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2)
                        }
                        @{
                            HourUsage = @(4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
                        }
                    )
                }

                $replRouteUnlimited = @{
                    UnlimitedRateForAll = $true
                    PropLists =@{
                        PropertyListName = 'Pulse Mode'
                        Values           = @(0,3,5)
                    }
                    Props = @(
                        @{
                            PropertyName = 'Connection Point'
                            Value        = 0
                            Value1       = 'CAS.Contoso.com'
                            Value2       = 'SMS_Site'
                        }
                        @{
                            PropertyName = 'LAN Login'
                            Value        = 0
                            Value1       = $null
                            Value2       = 'contoso\Repladmin'
                        }
                    )
                    RateLimitingSchedule = @(100,100,100,100,100,100,100,100,100,100,100,100,100,
                                             100,100,100,100,100,100,100,100,100,100,100)
                    UsageSchedule        = @(
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                            Update    = $false
                        }
                        @{
                            HourUsage = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
                            Update    = $false
                        }
                    )
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving file replication settings' {

                It 'Should return desired result for Limited' {
                    Mock -CommandName Get-CMFileReplicationRoute -MockWith { $replRouteLimited }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.DestinationSiteCode        | Should -Be -ExpectedValue 'CAS'
                    $result.DataBlockSizeKB            | Should -Be -ExpectedValue 3
                    $result.DelayBetweenDataBlockSec   | Should -Be -ExpectedValue 5
                    $result.FileReplicationAccountName | Should -Be -ExpectedValue $null
                    $result.UseSystemAccount           | Should -Be -ExpectedValue $true
                    $result.Limited                    | Should -Be -ExpectedValue $true
                    $result.PulseMode                  | Should -Be -ExpectedValue $false
                    $result.RateLimitingSchedule       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.RateLimitingSchedule.Count | Should -Be -ExpectedValue 3
                    $result.Unlimited                  | Should -Be -ExpectedValue $false
                    $result.NetworkLoadSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.NetworkLoadSchedule.Count  | Should -Be -ExpectedValue 13
                    $result.Ensure                     | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for Pulse mode' {
                    Mock -CommandName Get-CMFileReplicationRoute -MockWith { $replRoutePulse }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.DestinationSiteCode        | Should -Be -ExpectedValue 'CAS'
                    $result.DataBlockSizeKB            | Should -Be -ExpectedValue 3
                    $result.DelayBetweenDataBlockSec   | Should -Be -ExpectedValue 5
                    $result.FileReplicationAccountName | Should -Be -ExpectedValue $null
                    $result.UseSystemAccount           | Should -Be -ExpectedValue $true
                    $result.Limited                    | Should -Be -ExpectedValue $false
                    $result.PulseMode                  | Should -Be -ExpectedValue $true
                    $result.RateLimitingSchedule       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.RateLimitingSchedule.Count | Should -Be -ExpectedValue 1
                    $result.Unlimited                  | Should -Be -ExpectedValue $false
                    $result.NetworkLoadSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.NetworkLoadSchedule.Count  | Should -Be -ExpectedValue 11
                    $result.Ensure                     | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for Unlimited' {
                    Mock -CommandName Get-CMFileReplicationRoute -MockWith { $replRouteUnlimited }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.DestinationSiteCode        | Should -Be -ExpectedValue 'CAS'
                    $result.DataBlockSizeKB            | Should -Be -ExpectedValue 3
                    $result.DelayBetweenDataBlockSec   | Should -Be -ExpectedValue 5
                    $result.FileReplicationAccountName | Should -Be -ExpectedValue 'contoso\Repladmin'
                    $result.UseSystemAccount           | Should -Be -ExpectedValue $false
                    $result.Limited                    | Should -Be -ExpectedValue $false
                    $result.PulseMode                  | Should -Be -ExpectedValue $false
                    $result.RateLimitingSchedule       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.RateLimitingSchedule.Count | Should -Be -ExpectedValue 1
                    $result.Unlimited                  | Should -Be -ExpectedValue $true
                    $result.NetworkLoadSchedule        | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.NetworkLoadSchedule.Count  | Should -Be -ExpectedValue 7
                    $result.Ensure                     | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result for absent file replication' {
                    Mock -CommandName Get-CMFileReplicationRoute -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.DestinationSiteCode        | Should -Be -ExpectedValue 'CAS'
                    $result.DataBlockSizeKB            | Should -Be -ExpectedValue $null
                    $result.DelayBetweenDataBlockSec   | Should -Be -ExpectedValue $null
                    $result.FileReplicationAccountName | Should -Be -ExpectedValue $null
                    $result.UseSystemAccount           | Should -Be -ExpectedValue $null
                    $result.Limited                    | Should -Be -ExpectedValue $null
                    $result.PulseMode                  | Should -Be -ExpectedValue $null
                    $result.RateLimitingSchedule       | Should -Be -ExpectedValue $null
                    $result.Unlimited                  | Should -Be -ExpectedValue $null
                    $result.NetworkLoadSchedule        | Should -Be -ExpectedValue $null
                    $result.Ensure                     | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'DSC_CMFileReplication\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $networkLoadReturn = @(
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Sunday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'MediumHigh'
                            Day       = 'Monday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'High'
                            Day       = 'Tuesday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'Closed'
                            Day       = 'Wednesday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 13
                            Type      = 'All'
                            Day       = 'Thursday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 13
                            EndHour   = 0
                            Type      = 'Closed'
                            Day       = 'Thursday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Friday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Saturday'
                        } `
                        -ClientOnly
                    )
                )

                $rateLimitedReturn = @(
                    (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            LimitedBeginHour               = 0
                            LimitedEndHour                 = 10
                            LimitAvailableBandwidthPercent = 90
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            LimitedBeginHour               = 10
                            LimitedEndHour                 = 0
                            LimitAvailableBandwidthPercent = 70
                        } `
                        -ClientOnly
                    )
                )

                $getResult = @{
                    SiteCode                   = 'Lab'
                    DestinationSiteCode        = 'CAS'
                    DataBlockSizeKB            = 3
                    DelayBetweenDataBlockSec   = 5
                    FileReplicationAccountName = $null
                    UseSystemAccount           = $true
                    Limited                    = $true
                    PulseMode                  = $false
                    RateLimitingSchedule       = $rateLimitedReturn
                    Unlimited                  = $false
                    NetworkLoadSchedule        = $networkLoadReturn
                    Ensure                     = 'Present'
                }

                $getResultNull = @{
                    SiteCode                   = 'Lab'
                    DestinationSiteCode        = 'CAS'
                    DataBlockSizeKB            = $null
                    DelayBetweenDataBlockSec   = $null
                    FileReplicationAccountName = $null
                    UseSystemAccount           = $null
                    Limited                    = $null
                    PulseMode                  = $null
                    RateLimitingSchedule       = $null
                    Unlimited                  = $null
                    NetworkLoadSchedule        = $null
                    Ensure                     = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMFileReplicationRoute
                Mock -CommandName Set-CMFileReplicationRoute
                Mock -CommandName Remove-CMFileReplicationRoute
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $networkLoadInput = @(
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 0
                                EndHour   = 10
                                Type      = 'Closed'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 10
                                EndHour   = 0
                                Type      = 'All'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        )
                    )

                    $limitedInput = @(
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 0
                                LimitedEndHour                 = 10
                                LimitAvailableBandwidthPercent = 90
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 10
                                LimitedEndHour                 = 17
                                LimitAvailableBandwidthPercent = 100
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 17
                                LimitedEndHour                 = 0
                                LimitAvailableBandwidthPercent = 40
                            } `
                            -ClientOnly
                        )
                    )

                    $inputPulse = @{
                        SiteCode                   = 'Lab'
                        DestinationSiteCode        = 'CAS'
                        DataBlockSizeKB            = 255
                        DelayBetweenDataBlockSec   = 30
                        FileReplicationAccountName = 'contoso\ReplAccount'
                        PulseMode                  = $true
                    }

                    $inputUnlimited = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        UseSystemAccount    = $true
                        Unlimited           = $true
                        NetworkLoadSchedule = $networkLoadInput
                    }

                    $inputLimited = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        Limited              = $true
                        RateLimitingSchedule = $limitedInput
                        DataBlockSizeKB      = 40
                    }

                    $inputAbsent = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        Ensure              = 'Absent'
                    }

                    Mock -CommandName Get-CMAccount -MockWith { $true }
                }

                It 'Should call expected commands when removing a file replication route' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands changing replication route from limited to Pulse' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }

                    Set-TargetResource @inputPulse
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands changing replication route from limited to unlimited' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }

                    Set-TargetResource @inputUnlimited
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when creating a new replication route' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultNull }

                    Set-TargetResource @inputUnlimited
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 3 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when modifying limited schedule from null return' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultNull }

                    Set-TargetResource @inputlimited
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 4 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when modifying limited schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }

                    Set-TargetResource @inputlimited
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 3 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $badInput = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        PulseMode            = $true
                        Limited              = $true
                    }

                    $multiTrueError = 'Only one type PulseMode, Limited, or Unlimited can be set to True in the configuration.'

                    $badAccountInput = @{
                        SiteCode                   = 'Lab'
                        DestinationSiteCode        = 'CAS'
                        UseSystemAccount           = $true
                        FileReplicationAccountName = 'contoso\ReplAccount'
                        PulseMode                  = $true
                    }

                    $badAccountMsg = 'You are specifying UseSystemAccount $true and also sepcifying FileRepliacationAccountName, choose one.'

                    $pulseModeError = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        PulseMode           = $true
                    }

                    $pulseModeErrorMsg = 'When setting PulseMode to true you must specify DataBlocks and DelayBetweenDataBlockSec.'

                    $limitedError = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        Limited             = $true
                    }

                    $limitedErrorMsg = 'When specifying Limited you must also specify RateLimitingSchedule.'

                    $networkLoadInputOverlap = @(
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 0
                                EndHour   = 10
                                Type      = 'Closed'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 9
                                EndHour   = 0
                                Type      = 'All'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        )
                    )

                    $limitedInputOverlap = @(
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 0
                                LimitedEndHour                 = 10
                                LimitAvailableBandwidthPercent = 90
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 9
                                LimitedEndHour                 = 17
                                LimitAvailableBandwidthPercent = 100
                            } `
                            -ClientOnly
                        )
                    )

                    $inputOverlapRate = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        Limited              = $true
                        RateLimitingSchedule = $limitedInputOverlap
                    }

                    $inputOverlapRateMsg = 'RateLimitingSchedule has an input overlap for LimitedBeginHour: 9 LimitedEndHour: 17.'

                    $inputOverlapNetwork = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        UnLimited            = $true
                        NetworkLoadSchedule  = $networkLoadInputOverlap
                    }

                    $inputOverlapNetworkMsg = 'NetworkLoadSchedule has an input overlap for BeginHour: 9 EndHour: 0 Day: Sunday.'

                    $inputCMAccountAbsent = @{
                        SiteCode                   = 'Lab'
                        DestinationSiteCode        = 'CAS'
                        FileReplicationAccountName = 'contoso\notpresent'
                        UnLimited                  = $true
                    }

                    $inputCMAccountMsg = 'AccountName contoso\notpresent does not exist in Configuraion Manager.'
                }

                It 'Should throw when specifying UseSystemAccount and FileReplicationAccountName' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @badAccountInput } | Should -Throw -ExpectedMessage $badAccountMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when trying to set multiple types' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @badInput } | Should -Throw -ExpectedMessage $multiTrueError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when not all parameters required for PulseMode is provided' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @pulseModeError } | Should -Throw -ExpectedMessage $pulseModeErrorMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when not all parameters required for Limited is provided' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @limitedError } | Should -Throw -ExpectedMessage $limitedErrorMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when RateLimitingSchedule has time overlap' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @inputOverlapRate } | Should -Throw -ExpectedMessage $inputOverlapRateMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when NetworkLoadSchedule has time overlap' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @inputOverlapNetwork } | Should -Throw -ExpectedMessage $inputOverlapNetworkMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }

                It 'Should throw when account specified does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResult }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputCMAccountAbsent } | Should -Throw -ExpectedMessage $inputCMAccountMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFileReplicationRoute -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'DSC_CMFileReplication\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $networkLoadReturn = @(
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Sunday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'MediumHigh'
                            Day       = 'Monday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'High'
                            Day       = 'Tuesday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'Closed'
                            Day       = 'Wednesday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 13
                            Type      = 'All'
                            Day       = 'Thursday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 13
                            EndHour   = 0
                            Type      = 'Closed'
                            Day       = 'Thursday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Friday'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            BeginHour = 0
                            EndHour   = 0
                            Type      = 'All'
                            Day       = 'Saturday'
                        } `
                        -ClientOnly
                    )
                )

                $rateLimitedReturn = @(
                    (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            LimitedBeginHour               = 0
                            LimitedEndHour                 = 10
                            LimitAvailableBandwidthPercent = 90
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            LimitedBeginHour               = 10
                            LimitedEndHour                 = 0
                            LimitAvailableBandwidthPercent = 70
                        } `
                        -ClientOnly
                    )
                )

                $getResult = @{
                    SiteCode                   = 'Lab'
                    DestinationSiteCode        = 'CAS'
                    DataBlockSizeKB            = 3
                    DelayBetweenDataBlockSec   = 5
                    FileReplicationAccountName = $null
                    UseSystemAccount           = $true
                    Limited                    = $true
                    PulseMode                  = $false
                    RateLimitingSchedule       = $rateLimitedReturn
                    Unlimited                  = $false
                    NetworkLoadSchedule        = $networkLoadReturn
                    Ensure                     = 'Present'
                }

                $getResultNull = @{
                    SiteCode                   = 'Lab'
                    DestinationSiteCode        = 'CAS'
                    DataBlockSizeKB            = $null
                    DelayBetweenDataBlockSec   = $null
                    FileReplicationAccountName = $null
                    UseSystemAccount           = $null
                    Limited                    = $null
                    PulseMode                  = $null
                    RateLimitingSchedule       = $null
                    Unlimited                  = $null
                    NetworkLoadSchedule        = $null
                    Ensure                     = 'Absent'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    $networkLoadInput = @(
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 0
                                EndHour   = 10
                                Type      = 'Closed'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 10
                                EndHour   = 0
                                Type      = 'All'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        )
                    )

                    $limitedInput = @(
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 0
                                LimitedEndHour                 = 10
                                LimitAvailableBandwidthPercent = 90
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 10
                                LimitedEndHour                 = 17
                                LimitAvailableBandwidthPercent = 100
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 17
                                LimitedEndHour                 = 0
                                LimitAvailableBandwidthPercent = 40
                            } `
                            -ClientOnly
                        )
                    )

                    $networkLoadInputOverlap = @(
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 0
                                EndHour   = 10
                                Type      = 'Closed'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                BeginHour = 9
                                EndHour   = 0
                                Type      = 'All'
                                Day       = 'Sunday'
                            } `
                            -ClientOnly
                        )
                    )

                    $limitedInputOverlap = @(
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 0
                                LimitedEndHour                 = 10
                                LimitAvailableBandwidthPercent = 90
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMRateLimitingSchedule `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                LimitedBeginHour               = 9
                                LimitedEndHour                 = 17
                                LimitAvailableBandwidthPercent = 100
                            } `
                            -ClientOnly
                        )
                    )

                    $inputOverlap = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        Limited              = $true
                        NetworkLoadSchedule  = $networkLoadInputOverlap
                        RateLimitingSchedule = $limitedInputOverlap
                    }

                    $inputPulse = @{
                        SiteCode                   = 'Lab'
                        DestinationSiteCode        = 'CAS'
                        DataBlockSizeKB            = 255
                        DelayBetweenDataBlockSec   = 30
                        FileReplicationAccountName = 'contoso\ReplAccount'
                        PulseMode                  = $true
                    }

                    $inputUnlimited = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        UseSystemAccount    = $true
                        PulseMode           = $false
                        Unlimited           = $true
                        NetworkLoadSchedule = $networkLoadInput
                    }

                    $inputLimited = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        PulseMode            = $false
                        Limited              = $true
                        RateLimitingSchedule = $limitedInput
                    }

                    $inputAbsent = @{
                        SiteCode            = 'Lab'
                        DestinationSiteCode = 'CAS'
                        Ensure              = 'Absent'
                    }

                    $badInput = @{
                        SiteCode             = 'Lab'
                        DestinationSiteCode  = 'CAS'
                        UseSystemAccount     = $true
                        PulseMode            = $true
                        Limited              = $true
                    }

                    $badAccountInput = @{
                        SiteCode                   = 'Lab'
                        DestinationSiteCode        = 'CAS'
                        UseSystemAccount           = $true
                        FileReplicationAccountName = 'contoso\ReplAccount'
                        PulseMode                  = $true
                    }
                }

                It 'Should return desired result false when currently Limited and setting Pulse' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @inputPulse | Should -Be $false
                }

                It 'Should return desired result false when setting unlimited with Network Load restrictions' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @inputUnlimited | Should -Be $false
                }

                It 'Should return desired result false expected when limited schedule does not match' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @inputLimited | Should -Be $false
                }

                It 'Should return desired result false expected when file replication is absent' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResultNull }

                    Test-TargetResource @inputLimited | Should -Be $false
                }

                It 'Should return desired result true expected absent file replication is absent' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResultNull }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false expected absent file replication is present' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false expected when setting multiple file replication types' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @badInput | Should -Be $false
                }

                It 'Should return desired result false expected when specifying UseSystemAccount and replicationaccount' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @badAccountInput | Should -Be $false
                }

                It 'Should return desired result false network load schedule and Limiting schedule have overlapping settings' {
                    Mock -CommandName Get-TargetResource  -MockWith { $getResult }

                    Test-TargetResource @inputOverlap | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
