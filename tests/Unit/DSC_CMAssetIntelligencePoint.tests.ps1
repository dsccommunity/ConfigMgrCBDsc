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

        $mockCimScheduleZero = (New-CimInstance -ClassName DSC_CMAssetIntelligenceSynchronizationSchedule `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'RecurInterval' = 'Days'
                    'RecurCount'    = 0
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

        $scheduleConvertZero = @{
            DayDuration    = 0
            HourDuration   = 0
            IsGMT          = $false
            MinuteDuration = 0
        }

        $returnEnabledDaysMismatch = @{
            SiteCode         = 'Lab'
            SiteServerName   = 'CA01.contoso.com'
            Schedule         = $mockCimScheduleDayMismatch
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
        }

        $getReturnEnabledZero = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Schedule              = $mockCimScheduleZero
            EnableSynchronization = $true
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $getInput = @{
            SiteCode         = 'Lab'
            IsSingleInstance = 'Yes'
        }

        $getAPReturnNoCert = @{
            SiteCode                      = 'Lab'
            ProxyName                     = 'CA01.contoso.com'
            ProxyCertPath                 = $null
            ProxyEnabled                  = $true
            PeriodicCatalogUpdateEnabled  = $true
            PeriodicCatalogUpdateSchedule = '0001200000100038'
            IsSingleInstance              = 'Yes'
        }

        $getAPReturnWithCert = @{
            SiteCode                      = 'Lab'
            ProxyName                     = 'CA01.contoso.com'
            ProxyCertPath                 = '\\CA01.Contoso.com\c$\cert.pfx'
            ProxyEnabled                  = $true
            PeriodicCatalogUpdateEnabled  = $true
            PeriodicCatalogUpdateSchedule = '0001200000100038'
            IsSingleInstance              = 'Yes'
        }

        $getReturnAbsent = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $null
            EnableSynchronization = $null
            Schedule              = $null
            Ensure                = 'Absent'
            IsSingleInstance      = 'Yes'
        }

        $getReturnAll = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = '\\CA01.Contoso.com\c$\cert.pfx'
            Enable                = $true
            EnableSynchronization = $true
            Schedule              = $mockCimSchedule
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $getReturnEnabledDays = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $true
            EnableSynchronization = $true
            Schedule              = $mockCimSchedule
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $getReturnNoSchedule = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $true
            EnableSynchronization = $true
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $getReturnNoCert = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            CertificateFile       = $null
            Enable                = $true
            EnableSynchronization = $true
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $inputAbsent = @{
            SiteCode         = 'Lab'
            SiteServerName   = 'CA01.contoso.com'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
        }

        $inputPresent = @{
            SiteCode         = 'Lab'
            SiteServerName   = 'CA01.contoso.com'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
        }

        $inputUseCert = @{
            SiteCode         = 'Lab'
            SiteServerName   = 'CA01.contoso.com'
            CertificateFile  = '\\CA01.Contoso.com\c$\cert.pfx'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
        }

        $inputNoCert = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Enable                = $true
            EnableSynchronization = $true
            RemoveCertificate     = $true
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $inputNoSync = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Enable                = $true
            EnableSynchronization = $false
            Ensure                = 'Present'
            IsSingleInstance      = 'Yes'
        }

        $syncScheduleThrow = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            EnableSynchronization = $false
            Schedule              = $mockCimSchedule
            IsSingleInstance      = 'Yes'
        }

        $syncScheduleThrowMsg = 'When specifying a schedule, the EnableSynchronization paramater must be true.'

        $certThrow = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            RemoveCertificate     = $true
            CertificateFile       = '\\CA01.Contoso.com\c$\cert.pfx'
            IsSingleInstance      = 'Yes'
        }

        $certThrowMsg = "When specifying a certificate, you can't specify RemoveCertificate as true."

        $installThrow = @{
            SiteCode         = 'Lab'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
        }

        $installThrowMsg = 'Role is not installed, need to specify SiteServerName to add.'

        $removeThrow = @{
            SiteCode         = 'Lab'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
        }

        $removeThrowMsg = 'Role is installed, need to specify SiteServerName to remove.'

        Describe "$moduleResourceName\Get-TargetResource" {
            BeforeAll{
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving asset intelligence point settings' {

                It 'Should return desired result when asset intelligence point is not currently installed' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $null }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue $null
                    $result.CertificateFile       | Should -Be -ExpectedValue $null
                    $result.Enable                | Should -Be -ExpectedValue $null
                    $result.EnableSynchronization | Should -Be -ExpectedValue $null
                    $result.Schedule              | Should -Be -ExpectedValue $null
                    $result.Ensure                | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when asset intelligence point is currently installed with no certificate file' {
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
                BeforeEach{
                    Mock -CommandName Import-ConfigMgrPowerShellModule
                    Mock -CommandName Set-Location
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer
                    Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                    Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint
                }

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNoSync
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when asset intelligence synchronization point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $null }

                    Set-TargetResource @inputNoCert
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when a schedule is present and a nonrecurring schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertZero }

                    Set-TargetResource @getReturnEnabledZero
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when no schedule is present and a schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoSchedule }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }

                    Set-TargetResource @getReturnEnabledDays
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach{
                    Mock -CommandName Import-ConfigMgrPowerShellModule
                    Mock -CommandName Set-Location
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer
                    Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                    Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint
                }

                It 'Should call throws when a schedule is specified and enable synchronization is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @syncScheduleThrow } | Should -Throw -ExpectedMessage $syncScheduleThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when the role needs to be installed and the SiteServerName parameter is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    { Set-TargetResource @installThrow } | Should -Throw -ExpectedMessage $installThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when a certificate is specified and RemoveCertificate is true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @certThrow } | Should -Throw -ExpectedMessage $certThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when the role needs to be removed and the SiteServerName parameter is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @removeThrow } | Should -Throw -ExpectedMessage $removeThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Add-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                    Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputNoCert } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            BeforeAll{
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

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

                    Test-TargetResource @inputNoCert | Should -Be $false
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

                It 'Should return desired result true schedule matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }
                    Test-TargetResource @getReturnAll | Should -Be $true
                }

                It 'Should return desired result false schedule present but nonrecurring specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Test-TargetResource @getReturnEnabledZero | Should -Be $false
                }

                It 'Should return desired result false no schedule present but schedule specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoSchedule }
                    Test-TargetResource @getReturnEnabledDays | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
