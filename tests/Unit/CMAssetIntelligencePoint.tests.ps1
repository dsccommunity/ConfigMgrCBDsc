[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
        <#$moduleResourceName = 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint'

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
        }#>

        Describe 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint\Get-TargetResource' -Tag 'Get' {
            BeforeAll{
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

                $networkOSPath = @{
                    NetworkOSPath = '\\CA01.Contoso.com'
                }

                $getDayScheduleReturn = @{
                    MinuteDuration = $null
                    RecurInterval  = 5
                    WeekOrder      = $null
                    HourDuration   = $null
                    Start          = '2/1/1970 00:00'
                    DayOfWeek      = $null
                    ScheduleType   = 'Days'
                    MonthDay       = $null
                    DayDuration    = $null
                }

                $getMonthlyByWeek = @{
                    MinuteDuration = $null
                    RecurInterval  = 1
                    WeekOrder      = 'First'
                    HourDuration   = $null
                    Start          = '2/1/1970 00:00'
                    DayOfWeek      = 'Friday'
                    ScheduleType   = 'MonthlyByWeek'
                    MonthDay       = $null
                    DayDuration    = $null
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving asset intelligence point settings' {

                It 'Should return desired result when asset intelligence point is not currently installed' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $null }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $null }
                    Mock -CommandName Get-CMSchedule -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.IsSingleInstance      | Should -Be -ExpectedValue 'Yes'
                    $result.SiteServerName        | Should -Be -ExpectedValue $null
                    $result.CertificateFile       | Should -Be -ExpectedValue $null
                    $result.Enable                | Should -Be -ExpectedValue $null
                    $result.EnableSynchronization | Should -Be -ExpectedValue $null
                    $result.Start                 | Should -Be -ExpectedValue $null
                    $result.ScheduleType          | Should -Be -ExpectedValue $null
                    $result.DayOfWeek             | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder      | Should -Be -ExpectedValue $null
                    $result.DayOfMonth            | Should -Be -ExpectedValue $null
                    $result.RecurInterval         | Should -Be -ExpectedValue $null
                    $result.Ensure                | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when asset intelligence point is currently installed with no certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnNoCert }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $networkOSPath }
                    Mock -CommandName Get-CMSchedule -MockWith { $getDayScheduleReturn }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.IsSingleInstance      | Should -Be -ExpectedValue 'Yes'
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue $null
                    $result.Enable                | Should -Be -ExpectedValue $true
                    $result.EnableSynchronization | Should -Be -ExpectedValue $true
                    $result.Start                 | Should -Be -ExpectedValue '2/1/1970 00:00'
                    $result.ScheduleType          | Should -Be -ExpectedValue 'Days'
                    $result.DayOfWeek             | Should -Be -ExpectedValue $null
                    $result.MonthlyWeekOrder      | Should -Be -ExpectedValue $null
                    $result.DayOfMonth            | Should -Be -ExpectedValue $null
                    $result.RecurInterval         | Should -Be -ExpectedValue 5
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when asset intelligence point is currently installed with a certificate file' {
                    Mock -CommandName Get-CMAssetIntelligenceProxy -MockWith { $getAPReturnWithCert }
                    Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $networkOSPath }
                    Mock -CommandName Get-CMSchedule -MockWith { $getMonthlyByWeek }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.IsSingleInstance      | Should -Be -ExpectedValue 'Yes'
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.CertificateFile       | Should -Be -ExpectedValue '\\CA01.Contoso.com\c$\cert.pfx'
                    $result.Enable                | Should -Be -ExpectedValue $true
                    $result.EnableSynchronization | Should -Be -ExpectedValue $true
                    $result.Start                 | Should -Be -ExpectedValue '2/1/1970 00:00'
                    $result.ScheduleType          | Should -Be -ExpectedValue 'MonthlyByWeek'
                    $result.DayOfWeek             | Should -Be -ExpectedValue 'Friday'
                    $result.MonthlyWeekOrder      | Should -Be -ExpectedValue 'First'
                    $result.DayOfMonth            | Should -Be -ExpectedValue $null
                    $result.RecurInterval         | Should -Be -ExpectedValue 1
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnAll = @{
                    SiteCode              = 'Lab'
                    SiteServerName        = 'CA01.contoso.com'
                    CertificateFile       = '\\CA01.Contoso.com\c$\cert.pfx'
                    Enable                = $true
                    EnableSynchronization = $true
                    Start                 = '2/1/1970 00:00'
                    ScheduleType          = 'Days'
                    DayOfWeek             = $null
                    MonthlyWeekOrder      = $null
                    DayOfMonth            = $null
                    RecurInterval         = '5'
                    Ensure                = 'Present'
                    IsSingleInstance      = 'Yes'
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

                $inputAbsent = @{
                    SiteCode         = 'Lab'
                    SiteServerName   = 'CA01.contoso.com'
                    Ensure           = 'Absent'
                    IsSingleInstance = 'Yes'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Set-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Remove-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName New-CMSChedule
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputNoSync = @{
                        SiteCode              = 'Lab'
                        SiteServerName        = 'CA01.contoso.com'
                        Enable                = $true
                        EnableSynchronization = $false
                        Ensure                = 'Present'
                        IsSingleInstance      = 'Yes'
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

                    $inputPresentSchedule = @{
                        SiteCode              = 'Lab'
                        SiteServerName        = 'CA01.contoso.com'
                        EnableSynchronization = $true
                        Ensure                = 'Present'
                        IsSingleInstance      = 'Yes'
                        ScheduleType          = 'Weekly'
                        RecurInterval         = 1
                        DayOfWeek             = 'Monday'
                        Start                 = '1/1/2021 01:00'
                    }

                    $scheduleReturn = @{
                        DurationInterval = 'Minutes'
                        DurationCount    = 59
                        RecurCount       = 1
                        DayOfWeek        = 'Monday'
                    }

                    Mock -CommandName Test-CMSchedule -MockWith { $false }

                    Mock -CommandName Set-CMSchedule -MockWith { $scheduleReturn }
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
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when changing the schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputPresentSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                <#It 'Should call expected commands when a schedule is present and a nonrecurring schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabledDays }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertZero }

                    Set-TargetResource @getReturnEnabledZero
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -ScopeIt
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -ScopeIt
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
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -ScopeIt
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -ScopeIt
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when a state is absent and a nonrecurring schedule is specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName New-CMSchedule -MockWith { $scheduleConvertZero }

                    Set-TargetResource @getReturnEnabledZero
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -ScopeIt
                    Assert-MockCalled Set-CMSchedule -Exactly -Times 0 -ScopeIt
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                }#>
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $syncScheduleThrow = @{
                        SiteCode              = 'Lab'
                        SiteServerName        = 'CA01.contoso.com'
                        EnableSynchronization = $false
                        ScheduleType          = 'Days'
                        RecurInterval         = 1
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

                    Mock -CommandName Test-CMSchedule
                    Mock -CommandName New-CMSchedule
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

                <#It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
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
                }#>
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMAssetIntelligencePoint\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
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

                $inputPresentSchedule = @{
                    SiteCode         = 'Lab'
                    SiteServerName   = 'CA01.contoso.com'
                    Ensure           = 'Present'
                    IsSingleInstance = 'Yes'
                    ScheduleType     = 'Weekly'
                    RecurInterval    = 1
                    DayOfWeek        = 'Monday'
                    Start            = '1/1/2021 01:00'
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

                $getReturnAll = @{
                    SiteCode              = 'Lab'
                    SiteServerName        = 'CA01.contoso.com'
                    CertificateFile       = '\\CA01.Contoso.com\c$\cert.pfx'
                    Enable                = $true
                    EnableSynchronization = $true
                    Start                 = '2/1/1970 00:00'
                    ScheduleType          = 'Days'
                    DayOfWeek             = $null
                    MonthlyWeekOrder      = $null
                    DayOfMonth            = $null
                    RecurInterval         = '5'
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

                It 'Should return desired result false when a schedule does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoCert }

                    Test-TargetResource @inputPresentSchedule  | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
