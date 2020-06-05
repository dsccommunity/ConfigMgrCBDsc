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
        DSCResourceName = 'DSC_CMForestDiscovery'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        $mockCimPollingSchedule = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
            -Property @{
                'RecurInterval' = 'Days'
                'RecurCount'    = 7
            } -ClientOnly
        )

        $standardGetInput = @{
            SiteCode = 'Lab'
            Enabled  = $true
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery
        Mock -CommandName Set-Location
        Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryOutput }
        Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimPollingSchedule } -ModuleName DSC_CMForestDiscovery
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving Collection settings' {
        It 'Should return desired result for forest discovery.' {
            $result = Get-TargetResource @standardGetInput

            $result                                           | Should -BeOfType System.Collections.HashTable
            $result.SiteCode                                  | Should -Be -ExpectedValue 'Lab'
            $result.Enabled                                   | Should -BeTrue
            $result.PollingSchedule                           | Should -Match $mockCimPollingSchedule
            $result.PollingSchedule                           | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
            $result.EnableActiveDirectorySiteBoundaryCreation | Should -BeFalse
            $result.EnableSubnetBoundaryCreation              | Should -BeFalse
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $mockCimPollingScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
            -Property @{
                'RecurInterval' = 'Days'
                'RecurCount'    = 6
            } -ClientOnly
        )

        $mockCimPollingSchedule = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
            -Property @{
                'RecurInterval' = 'Days'
                'RecurCount'    = 7
            } -ClientOnly
        )

        $standardGetInput = @{
            SiteCode = 'Lab'
            Enabled  = $true
        }

        $getReturnDisabled = @{
            SiteCode = 'Lab'
            Enabled  = $false
        }

        $getReturnEnabledDays = @{
            SiteCode                                  = 'Lab'
            Enabled                                   = $true
            PollingSchedule                           = $mockCimPollingSchedule
            EnableActiveDirectorySiteBoundaryCreation = $true
            EnableSubnetBoundaryCreation              = $true
        }

        $returnEnabledDaysMismatch = @{
            SiteCode        = 'Lab'
            Enabled         = $true
            PollingSchedule = $mockCimPollingScheduleDayMismatch
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery
        Mock -CommandName Set-Location
        Mock -CommandName Set-CMDiscoveryMethod
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        BeforeEach {
            $getReturnDisabledOutput = @{
                SiteCode                                  = 'Lab'
                Enabled                                   = $false
                PollingSchedule                           = $mockCimPollingSchedule
                EnableActiveDirectorySiteBoundaryCreation = $false
                EnableSubnetBoundaryCreation              = $false
            }

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
        }
        It 'Should call expected commands enabling discovery' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
            Mock -CommandName New-CMSchedule

            Set-TargetResource @standardGetInput
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMDiscoveryMethod -Exactly 1 -Scope It
        }

        It 'Should call expected commands enabling discovery and changing the schedule' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabledOutput }
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }

            Set-TargetResource @returnEnabledDaysMismatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 2 -Scope It
            Should -Invoke Set-CMDiscoveryMethod -Exactly 1 -Scope It
        }

        It 'Should call expected commands disabling discovery' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
            Mock -CommandName New-CMSchedule

            Set-TargetResource @getReturnDisabled
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMDiscoveryMethod -Exactly 1 -Scope It
        }
    }

    Context 'When running Set-TargetResource should throw' {
        It 'Should call expected commands and throw if Set-CMDiscoveryMethod throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
            Mock -CommandName New-CMSchedule
            Mock -CommandName Set-CMDiscoveryMethod -MockWith { throw }

            { Set-TargetResource @getReturnDisabled } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 0 -Scope It
            Should -Invoke Set-CMDiscoveryMethod -Exactly 1 -Scope It
        }

        It 'Should call expected commands enabling discovery and changing the schedule' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
            Mock -CommandName New-CMSchedule -MockWith { throw }

            { Set-TargetResource @returnEnabledDaysMismatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMSchedule -Exactly 1 -Scope It
            Should -Invoke Set-CMDiscoveryMethod -Exactly 0 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMForestDiscovery\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        $mockCimPollingSchedule = (New-CimInstance -ClassName DSC_CMForestDiscoveryPollingSchedule `
            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
            -Property @{
                'RecurInterval' = 'Days'
                'RecurCount'    = 7
            } -ClientOnly
        )

        $getReturnDisabled = @{
            SiteCode = 'Lab'
            Enabled  = $false
        }

        $getReturnDisabledOutput = @{
            SiteCode                                  = 'Lab'
            Enabled                                   = $false
            PollingSchedule                           = $mockCimPollingSchedule
            EnableActiveDirectorySiteBoundaryCreation = $false
            EnableSubnetBoundaryCreation              = $false
        }

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

        $getReturnEnabledDays = @{
            SiteCode                                  = 'Lab'
            Enabled                                   = $true
            PollingSchedule                           = $mockCimPollingSchedule
            EnableActiveDirectorySiteBoundaryCreation = $true
            EnableSubnetBoundaryCreation              = $true
        }

        $returnEnabledDaysMismatch = @{
            SiteCode        = 'Lab'
            Enabled         = $true
            PollingSchedule = $mockCimPollingScheduleDayMismatch
        }

        $scheduleConvertHours = @{
            DayDuration    = 0
            DaySpan        = 0
            HourDuration   = 0
            HourSpan       = 7
            MinuteDuration = 0
            MinuteSpan     = 0
        }

        $getReturnEnabledHours = @{
            SiteCode        = 'Lab'
            Enabled         = $true
            PollingSchedule = $mockCimPollingScheduleHours
        }

        $getInputDisableSubnet = @{
            SiteCode                     = 'Lab'
            Enabled                      = $true
            EnableSubnetBoundaryCreation = $false
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMForestDiscovery
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource device settings' {
        BeforeEach {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
        }

        It 'Should return desired result true schedule matches' {
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }

            Test-TargetResource @getReturnEnabledDays | Should -BeTrue
        }
        It 'Should return desired result false schedule days mismatch' {
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }

            Test-TargetResource @returnEnabledDaysMismatch | Should -BeFalse
        }
        It 'Should return desired result false schedule hours mismatch' {
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurInterval -eq 'Days' }
            Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertHours } -ParameterFilter { $RecurInterval -eq 'Hours' }

            Test-TargetResource @getReturnEnabledHours | Should -BeFalse
        }
        It 'Should return desired state false EnableSubnetBoundaryCreation mismatch' {

            Test-TargetResource @getInputDisableSubnet | Should -BeFalse
        }
        It 'Should return desired result false when setting is enabled and disabled expected disabled' {

            Test-TargetResource @getReturnDisabled | Should -BeFalse
        }
        It 'Should return desired result true when discovery is disabled' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabledOutput }

            Test-TargetResource @getReturnDisabled | Should -BeTrue
        }
    }
}
