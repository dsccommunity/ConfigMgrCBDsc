param ()

# Begin Testing
try
{
    $dscModuleName   = 'ConfigMgrCBDsc'
    $dscResourceName = 'DSC_CMAssetIntelligencePoint'

    $TestEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $dscModuleName `
        -DSCResourceName $dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    BeforeAll {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint'

        # Import Stub function
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

        try
        {
            Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
        }
        catch [System.IO.FileNotFoundException]
        {
            throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
        }

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
            SiteCode          = 'Lab'
            SiteServerName    = 'CA01.contoso.com'
            RemoveCertificate = $true
            CertificateFile   = '\\CA01.Contoso.com\c$\cert.pfx'
            IsSingleInstance  = 'Yes'
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

        $networkOSPath = @{
            NetworkOSPath = '\\CA01.Contoso.com'
        }
    }

    Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving asset intelligence point settings' {
                It 'Should return desired result when asset intelligence point is not currently installed' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $null }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $null }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -BeNullOrEmpty
                    $result.CertificateFile       | Should -BeNullOrEmpty
                    $result.Enable                | Should -BeNullOrEmpty
                    $result.EnableSynchronization | Should -BeNullOrEmpty
                    $result.Schedule              | Should -BeNullOrEmpty
                    $result.Ensure                | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when asset intelligence point is currently installed with no certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnNoCert }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $networkOSPath }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimSchedule }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -BeNullOrEmpty
                    $result.Enable                | Should -BeTrue
                    $result.EnableSynchronization | Should -BeTrue
                    $result.Schedule              | Should -Match $mockCimSchedule
                    $result.Schedule              | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when asset intelligence point is currently installed with a certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnWithCert }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $networkOSPath }
                    Mock -CommandName ConvertTo-CimCMScheduleString -MockWith { $mockCimSchedule }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue '\\CA01.Contoso.com\c$\cert.pfx'
                    $result.Enable                | Should -BeTrue
                    $result.EnableSynchronization | Should -BeTrue
                    $result.Schedule              | Should -Match $mockCimSchedule
                    $result.Schedule              | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }
            }
        }
    }

    Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set' {
        InModuleScope $dscResourceName {
            BeforeAll{
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName New-CMSchedule
                Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint
            }

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNoSync
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when asset intelligence synchronization point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $null }

                    Set-TargetResource @inputNoCert
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when a certificate is present and needs to be removed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNoCert
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnEnabledDaysMismatch }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }

                    Set-TargetResource @getReturnEnabledDays
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 2 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when asset intelligence point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                }

                It 'Should call expected commands when a schedule is present and a nonrecurring schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertZero }

                    Set-TargetResource @getReturnEnabledZero
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 1 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when no schedule is present and a schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoSchedule }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }

                    Set-TargetResource @getReturnEnabledDays
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 1 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands when a state is absent and a nonrecurring schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertZero }

                    Set-TargetResource @getReturnEnabledZero
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 1 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                It 'Should call throws when a schedule is specified and enable synchronization is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @syncScheduleThrow } | Should -Throw -ExpectedMessage $syncScheduleThrowMsg
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call throws when the role needs to be installed and the SiteServerName parameter is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    { Set-TargetResource @installThrow } | Should -Throw -ExpectedMessage $installThrowMsg
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call throws when a certificate is specified and RemoveCertificate is true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @certThrow } | Should -Throw -ExpectedMessage $certThrowMsg
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call throws when the role needs to be removed and the SiteServerName parameter is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @removeThrow } | Should -Throw -ExpectedMessage $removeThrowMsg
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputPresent } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputPresent } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if Add-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                    Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputNoCert } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSchedule throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnEnabledDaysMismatch }
                    Mock -CommandName New-CMSchedule -MockWith { throw }

                    { Set-TargetResource @getReturnEnabledDays } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 1 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputNoSync } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMAssetIntelligenceSynchronizationPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-TargetResource -Exactly 1 -Scope It
                    Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
                    Should -Invoke Add-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke New-CMSchedule -Exactly 0 -Scope It
                    Should -Invoke Set-CMAssetIntelligenceSynchronizationPoint -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAssetIntelligenceSynchronizationPoint -Exactly 1 -Scope It
                }
            }
        }
    }

    Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test'{
        InModuleScope $dscResourceName {
            BeforeAll{
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {
                It 'Should return desired result false when ensure = present and AP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputPresent  | Should -BeFalse
                }

                It 'Should return desired result true when ensure = absent and AP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputAbsent | Should -BeTrue
                }

                It 'Should return desired result false when ensure = absent and AP is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputAbsent | Should -BeFalse
                }

                It 'Should return desired result true when a certificate file is specified and a certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUseCert | Should -BeTrue
                }

                It 'Should return desired result false when a certificate file is not specified and a certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputNoCert | Should -BeFalse
                }

                It 'Should return desired result true when no certificate file is specified and no certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoCert }

                    Test-TargetResource @inputNoCert | Should -BeTrue
                }

                It 'Should return desired result false when a certificate file is specified and no certificate file is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoCert  }

                    Test-TargetResource @inputUseCert  | Should -BeFalse
                }

                It 'Should return desired result false schedule days mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays } -ParameterFilter { $RecurCount -eq 7 }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDaysMismatch } -ParameterFilter { $RecurCount -eq 6 }
                    Test-TargetResource @returnEnabledDaysMismatch | Should -BeFalse
                }

                It 'Should return desired result true schedule matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertDays }
                    Test-TargetResource @getReturnAll | Should -BeTrue
                }

                It 'Should return desired result false schedule present but nonrecurring specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Test-TargetResource @getReturnEnabledZero | Should -BeFalse
                }

                It 'Should return desired result false no schedule present but schedule specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoSchedule }
                    Test-TargetResource @getReturnEnabledDays | Should -BeFalse
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}
