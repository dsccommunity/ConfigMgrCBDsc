param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMAssetIntelligencePoint'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint'

        $mockCimSchedule = (New-CimInstance -ClassName DSC_CMAssetIntelligenceSynchronizationSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 7
                } -ClientOnly
        )

        $mockCimScheduleDayMismatch = (New-CimInstance -ClassName DSC_CMAssetIntelligenceSynchronizationSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 6
                } -ClientOnly
        )

        $mockCimScheduleHours = (New-CimInstance -ClassName DSC_CMAssetIntelligenceSynchronizationSchedule `
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

        $returnEnabledDaysMismatch = @{
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Schedule       = $mockCimScheduleDayMismatch
            Ensure         = 'Present'
        }

        $getReturnEnabledHours = @{
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Schedule       = $mockCimScheduleHours
            Ensure         = 'Present'
        }

        $getInput = @{
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
        }

        $getAPReturnNoCert = @{
            SiteCode                      = 'Lab'
            ProxyName                     = 'CA01.contoso.com'
            ProxyCertPath                 = $null
            ProxyEnabled                  = $true
            PeriodicCatalogUpdateEnabled  = $true
            PeriodicCatalogUpdateSchedule = '0001200000100038'
        }

        $getAPReturnWithCert = @{
            SiteCode                      = 'Lab'
            ProxyName                     = 'CA01.contoso.com'
            ProxyCertPath                 = '\\CA01.Contoso.com\c$\cert.pfx'
            ProxyEnabled                  = $true
            PeriodicCatalogUpdateEnabled  = $true
            PeriodicCatalogUpdateSchedule = '0001200000100038'
        }

        $getReturnAbsent = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $null
            EnableSynchronization = $null
            Schedule              = $null
            Ensure                = 'Absent'
        }

        $getReturnAll = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = '\\CA01.Contoso.com\c$\cert.pfx'
            Enable                = $true
            EnableSynchronization = $true
            Schedule              = $mockCimSchedule
            Ensure                = 'Present'
        }

        $getReturnEnabledDays = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $true
            EnableSynchronization = $true
            Schedule              = $mockCimSchedule
            Ensure                = 'Present'
        }

        $getReturnNoCert = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $true
            EnableSynchronization = $true
            Ensure                = 'Present'
        }

        $inputAbsent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Ensure         = 'Absent'
        }

        $inputPresent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Ensure         = 'Present'
        }

        $inputUseCert = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'CA01.contoso.com'
            CertificateFile = '\\CA01.Contoso.com\c$\cert.pfx'
            Ensure          = 'Present'
        }

        $inputNoCert = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Enable                = $true
            EnableSynchronization = $true
            Ensure                = 'Present'
        }

        $inputNoSync = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Enable                = $true
            EnableSynchronization = $false
            Ensure                = 'Present'
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving asset intelligence point settings' {

                It 'Should return desired result when asset intelligence point is not currently installed' {
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $null }
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $null }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue $null
                    $result.Enable                | Should -Be -ExpectedValue $null
                    $result.EnableSynchronization | Should -Be -ExpectedValue $null
                    $result.Schedule              | Should -Be -ExpectedValue $null
                    $result.Ensure                | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when asset intelligence point is currently installed with no certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $true }
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnNoCert }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimSchedule }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue $null
                    $result.Enable                | Should -Be -ExpectedValue $true
                    $result.EnableSynchronization | Should -Be -ExpectedValue $true
                    $result.Schedule              | Should -Match $mockCimSchedule
                    $result.Schedule              | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when asset intelligence point is currently installed with a certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $true }
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnWithCert }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimSchedule }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue '\\CA01.Contoso.com\c$\cert.pfx'
                    $result.Enable                | Should -Be -ExpectedValue $true
                    $result.EnableSynchronization | Should -Be -ExpectedValue $true
                    $result.Schedule              | Should -Match $mockCimSchedule
                    $result.Schedule              | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName New-CMSchedule
                Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNoSync
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when asset intelligence synchronization point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputNoCert
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when a certificate is present and needs to be removed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNoCert
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnEnabledDaysMismatch }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }

                    Set-TargetResource @getReturnEnabledDays
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when asset intelligence point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName New-CMSchedule
                Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint

                It 'Should call expected commands and throw if Add-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputNoCert } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSchedule throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnEnabledDaysMismatch }
                    Mock -CommandName New-CMSchedule -MockWith { throw }

                    { Set-TargetResource @getReturnEnabledDays } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputNoSync } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should return desired result false when ensure = present and AP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and AP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false when ensure = absent and AP is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result true when a certificate file is specified and a certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUseCert | Should -Be $true
                }

                It 'Should return desired result false when a certificate file is not specified and a certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result true when no certificate file is specified and no certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoCert }

                    Test-TargetResource @inputNoCert | Should -Be $true
                }

                It 'Should return desired result false when a certificate file is specified and no certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoCert  }

                    Test-TargetResource @inputUseCert  | Should -Be $false
                }

                It 'Should return desired result false schedule days mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }
                    Test-TargetResource @returnEnabledDaysMismatch | Should -Be $false
                }

                It 'Should return desired result false schedule hours mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurInterval -eq 'Days' }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertHours } -ParameterFilter { $RecurInterval -eq 'Hours' }
                    Test-TargetResource @getReturnEnabledHours | Should -Be $false
                }

                It 'Should return desired result true schedule matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }
                    Test-TargetResource @getReturnAll | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}