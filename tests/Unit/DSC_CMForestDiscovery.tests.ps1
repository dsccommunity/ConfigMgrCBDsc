[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()
$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMForestDiscovery'
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'), '-q')
}
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit
# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Import Stub function
        $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMForestDiscovery'
        $mockCimPollingSchedule = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 7
                } -ClientOnly
        )
        $mockCimPollingScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 6
                } -ClientOnly
        )
        $mockCimPollingScheduleHours = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Hours'
                    'RecurCount'    = 7
                } -ClientOnly
        )
        $scheduleConvertDays = @{
            DayDuration    = 0
            DaySpan        = 7
            HourDuration   = 0
            HourSpan       = 0
            MinuteDuration = 0
            MinuteSpan     = 0
        }
        $scheduleConvertDaysMismatch = @{
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
        $standardGetDiscoveryOutput = @{
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
        $standardGetInput = @{
            SiteCode = 'Lab'
            Enabled  = $true
        }
        $returnEnabledDaysMismatch = @{
            SiteCode        = 'Lab'
            Enabled         = $true
            PollingSchedule = $mockCimPollingScheduleDayMismatch
        }
        $getReturnEnabledDays = @{
            SiteCode                                  = 'Lab'
            Enabled                                   = $true
            PollingSchedule                           = $mockCimPollingSchedule
            EnableActiveDirectorySiteBoundaryCreation = $true
            EnableSubnetBoundaryCreation              = $true
        }
        $getReturnEnabledHours = @{
            SiteCode        = 'Lab'
            Enabled         = $true
            PollingSchedule = $mockCimPollingScheduleHours
        }
        $getReturnDisabledOutput = @{
            SiteCode                                  = 'Lab'
            Enabled                                   = $false
            PollingSchedule                           = $mockCimPollingSchedule
            EnableActiveDirectorySiteBoundaryCreation = $false
            EnableSubnetBoundaryCreation              = $false
        }
        $getInputDisableSubnet = @{
            SiteCode                     = 'Lab'
            Enabled                      = $true
            EnableSubnetBoundaryCreation = $false
        }
        $getReturnDisabled = @{
            SiteCode = 'Lab'
            Enabled  = $false
        }
        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location
            Context 'When retrieving Collection settings' {
                It 'Should return desired result for forest discovery.' {
                    mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryOutput }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimPollingSchedule }
                    $result = Get-TargetResource @standardGetInput
                    $result                                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled                                   | Should -Be -ExpectedValue $true
                    $result.PollingSchedule                           | Should -Match $mockCimPollingSchedule
                    $result.PollingSchedule                           | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.EnableActiveDirectorySiteBoundaryCreation | Should -Be -ExpectedValue $false
                    $result.EnableSubnetBoundaryCreation              | Should -Be -ExpectedValue $false
                }
            }
        }
        Describe "$moduleResourceName\Set-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location
            Mock -CommandName Set-CMDiscoveryMethod
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
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabledOutput }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }
                    Set-TargetResource @returnEnabledDaysMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 2 -Scope It
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
        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Context 'When running Test-TargetResource device settings' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                It 'Should return desired result true schedule matches' {
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }
                    Test-TargetResource @getReturnEnabledDays | Should -Be $true
                }
                It 'Should return desired result false schedule days mismatch' {
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }
                    Test-TargetResource @returnEnabledDaysMismatch | Should -Be $false
                }
                It 'Should return desired result false schedule hours mismatch' {
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurInterval -eq 'Days' }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertHours } -ParameterFilter { $RecurInterval -eq 'Hours' }
                    Test-TargetResource @getReturnEnabledHours | Should -Be $false
                }
                It 'Should return desired state false EnableSubnetBoundaryCreation mismatch' {
                    Test-TargetResource @getInputDisableSubnet | Should -Be $false
                }
                It 'Should return desired result false when setting is enabled and disabled expected disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $false
                }
                It 'Should return desired result true when discovery is disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabledOutput }
                    Test-TargetResource @getReturnDisabled | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
