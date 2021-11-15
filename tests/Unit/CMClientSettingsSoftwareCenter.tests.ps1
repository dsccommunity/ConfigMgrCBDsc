[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsSoftwareCenter'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareCenter\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $test = '<settings>
                <settings-version>1.0</settings-version>
                <tab-visibility>
                  <tab name="AvailableSoftware" visible="true" order="1" />
                  <tab name="Updates" visible="true" order="2" />
                  <tab name="OSD" visible="true" order="3" />
                  <tab name="InstallationStatus" visible="true" order="4" />
                  <tab name="Compliance" visible="true" order="5" />
                  <tab name="Options" visible="true" order="6" />
                </tab-visibility>
                <software-list>
                  <unapproved-applications-hidden>false</unapproved-applications-hidden>
                  <installed-applications-hidden>true</installed-applications-hidden>
                </software-list>
                <brand-logo />
                <brand-orgname>Test</brand-orgname>
                <brand-color>#CB4154</brand-color>
                <application-catalog-link-hidden>false</application-catalog-link-hidden>
                <defaults-list>
                  <required-filter-default>false</required-filter-default>
                  <list-view-default>false</list-view-default>
                </defaults-list>
              </settings>'

                $softwareCenterReturn = @{
                    SC_UserPortal   = 0
                    SC_Old_Branding = 1
                    SettingsXml     = $test
                }

                $softwareCenterCustomizeReturn = @{
                    SC_UserPortal   = 0
                    SC_Old_Branding = 0
                    SettingsXml     = $null
                }

                $companyPortalReturn = @{
                    SC_UserPortal   = 1
                    SC_Old_Branding = 0
                    SettingsXml     = $null
                }

                $clientType = @{
                    Type = 1
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    EnableCustomize   = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Client Cache' {

                It 'Should return desired results when client settings and software center customization exists' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $softwareCenterReturn } -ParameterFilter { $Setting -eq 'SoftwareCenter' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableCustomize            | Should -Be -ExpectedValue $true
                    $result.CompanyName                | Should -Be -ExpectedValue 'Test'
                    $result.ColorScheme                | Should -Be -ExpectedValue '#CB4154'
                    $result.HideApplicationCatalogLink | Should -Be -ExpectedValue $false
                    $result.HideInstalledApplication   | Should -Be -ExpectedValue $true
                    $result.HideUnapprovedApplication  | Should -Be -ExpectedValue $false
                    $result.EnableApplicationsTab      | Should -Be -ExpectedValue $true
                    $result.EnableUpdatesTab           | Should -Be -ExpectedValue $true
                    $result.EnableOperatingSystemsTab  | Should -Be -ExpectedValue $true
                    $result.EnableStatusTab            | Should -Be -ExpectedValue $true
                    $result.EnableComplianceTab        | Should -Be -ExpectedValue $true
                    $result.EnableOptionsTab           | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Device'
                    $result.PortalType                 | Should -Be -ExpectedValue 'Software Center'
                }

                It 'Should return desired results when client settings and software center customization is not set' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $softwareCenterCustomizeReturn } -ParameterFilter { $Setting -eq 'SoftwareCenter' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableCustomize            | Should -Be -ExpectedValue $false
                    $result.CompanyName                | Should -Be -ExpectedValue $null
                    $result.ColorScheme                | Should -Be -ExpectedValue $null
                    $result.HideApplicationCatalogLink | Should -Be -ExpectedValue $null
                    $result.HideInstalledApplication   | Should -Be -ExpectedValue $null
                    $result.HideUnapprovedApplication  | Should -Be -ExpectedValue $null
                    $result.EnableApplicationsTab      | Should -Be -ExpectedValue $null
                    $result.EnableUpdatesTab           | Should -Be -ExpectedValue $null
                    $result.EnableOperatingSystemsTab  | Should -Be -ExpectedValue $null
                    $result.EnableStatusTab            | Should -Be -ExpectedValue $null
                    $result.EnableComplianceTab        | Should -Be -ExpectedValue $null
                    $result.EnableOptionsTab           | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Device'
                    $result.PortalType                 | Should -Be -ExpectedValue 'Software Center'
                }

                It 'Should return desired results when client settings and company portal is set' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $companyPortalReturn } -ParameterFilter { $Setting -eq 'SoftwareCenter' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableCustomize            | Should -Be -ExpectedValue $null
                    $result.CompanyName                | Should -Be -ExpectedValue $null
                    $result.ColorScheme                | Should -Be -ExpectedValue $null
                    $result.HideApplicationCatalogLink | Should -Be -ExpectedValue $null
                    $result.HideInstalledApplication   | Should -Be -ExpectedValue $null
                    $result.HideUnapprovedApplication  | Should -Be -ExpectedValue $null
                    $result.EnableApplicationsTab      | Should -Be -ExpectedValue $null
                    $result.EnableUpdatesTab           | Should -Be -ExpectedValue $null
                    $result.EnableOperatingSystemsTab  | Should -Be -ExpectedValue $null
                    $result.EnableStatusTab            | Should -Be -ExpectedValue $null
                    $result.EnableComplianceTab        | Should -Be -ExpectedValue $null
                    $result.EnableOptionsTab           | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Device'
                    $result.PortalType                 | Should -Be -ExpectedValue 'Company Portal'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableCustomize            | Should -Be -ExpectedValue $null
                    $result.CompanyName                | Should -Be -ExpectedValue $null
                    $result.ColorScheme                | Should -Be -ExpectedValue $null
                    $result.HideApplicationCatalogLink | Should -Be -ExpectedValue $null
                    $result.HideInstalledApplication   | Should -Be -ExpectedValue $null
                    $result.HideUnapprovedApplication  | Should -Be -ExpectedValue $null
                    $result.EnableApplicationsTab      | Should -Be -ExpectedValue $null
                    $result.EnableUpdatesTab           | Should -Be -ExpectedValue $null
                    $result.EnableOperatingSystemsTab  | Should -Be -ExpectedValue $null
                    $result.EnableStatusTab            | Should -Be -ExpectedValue $null
                    $result.EnableComplianceTab        | Should -Be -ExpectedValue $null
                    $result.EnableOptionsTab           | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                 | Should -Be -ExpectedValue $null
                    $result.PortalType                 | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but software center is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'SoftwareCenter' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableCustomize            | Should -Be -ExpectedValue $null
                    $result.CompanyName                | Should -Be -ExpectedValue $null
                    $result.ColorScheme                | Should -Be -ExpectedValue $null
                    $result.HideApplicationCatalogLink | Should -Be -ExpectedValue $null
                    $result.HideInstalledApplication   | Should -Be -ExpectedValue $null
                    $result.HideUnapprovedApplication  | Should -Be -ExpectedValue $null
                    $result.EnableApplicationsTab      | Should -Be -ExpectedValue $null
                    $result.EnableUpdatesTab           | Should -Be -ExpectedValue $null
                    $result.EnableOperatingSystemsTab  | Should -Be -ExpectedValue $null
                    $result.EnableStatusTab            | Should -Be -ExpectedValue $null
                    $result.EnableComplianceTab        | Should -Be -ExpectedValue $null
                    $result.EnableOptionsTab           | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Device'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareCenter\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4154'
                    HideApplicationCatalogLink = $false
                    HideInstalledApplication   = $true
                    HideUnapprovedApplication  = $false
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $true
                    EnableOptionsTab           = $true
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                    PortalType                 = 'Software Center'
                }

                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4154'
                    HideApplicationCatalogLink = $false
                    HideInstalledApplication   = $true
                    HideUnapprovedApplication  = $false
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $true
                    EnableOptionsTab           = $true
                }

                $inputTabsDisabled = @{
                    SiteCode                  = 'Lab'
                    ClientSettingName         = 'ClientTest'
                    EnableCustomize           = $true
                    EnableApplicationsTab     = $false
                    EnableUpdatesTab          = $false
                    EnableOperatingSystemsTab = $false
                    EnableStatusTab           = $false
                    EnableOptionsTab          = $false
                }

                Mock -CommandName Set-CMClientSettingSoftwareCenter
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnNotConfig = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $null
                        CompanyName                = $null
                        ColorScheme                = $null
                        HideApplicationCatalogLink = $null
                        HideInstalledApplication   = $null
                        HideUnapprovedApplication  = $null
                        EnableApplicationsTab      = $null
                        EnableUpdatesTab           = $null
                        EnableOperatingSystemsTab  = $null
                        EnableStatusTab            = $null
                        EnableComplianceTab        = $null
                        EnableOptionsTab           = $null
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Default'
                        PortalType                 = 'Software Center'
                    }

                    $inputMisMatch = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $true
                        CompanyName                = 'Test'
                        ColorScheme                = '#CB4155'
                        HideApplicationCatalogLink = $true
                        HideInstalledApplication   = $false
                        HideUnapprovedApplication  = $true
                        EnableApplicationsTab      = $true
                        EnableUpdatesTab           = $true
                        EnableOperatingSystemsTab  = $true
                        EnableStatusTab            = $true
                        EnableComplianceTab        = $true
                        EnableOptionsTab           = $true
                    }

                    $inputCustomizeDisabled = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        EnableCustomize   = $false
                        EnableOptionsTab  = $true
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when settings tabs mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputTabsDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when return is not configured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when expected EnableCustomize to be disabled and currently enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputCustomizeDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $null
                        CompanyName                = $null
                        ColorScheme                = $null
                        HideApplicationCatalogLink = $null
                        HideInstalledApplication   = $null
                        HideUnapprovedApplication  = $null
                        EnableApplicationsTab      = $null
                        EnableUpdatesTab           = $null
                        EnableOperatingSystemsTab  = $null
                        EnableStatusTab            = $null
                        EnableComplianceTab        = $null
                        EnableOptionsTab           = $null
                        ClientSettingStatus        = 'Absent'
                        ClientType                 = $null
                        PortalType                 = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $null
                        CompanyName                = $null
                        ColorScheme                = $null
                        HideApplicationCatalogLink = $null
                        HideInstalledApplication   = $null
                        HideUnapprovedApplication  = $null
                        EnableApplicationsTab      = $null
                        EnableUpdatesTab           = $null
                        EnableOperatingSystemsTab  = $null
                        EnableStatusTab            = $null
                        EnableComplianceTab        = $null
                        EnableOptionsTab           = $null
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'User'
                        PortalType                 = $null
                    }

                    $wrongClientType  = 'Client Settings for Software Center only applies to default and device client settings.'

                    $returnCompanyPortal = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $null
                        CompanyName                = $null
                        ColorScheme                = $null
                        HideApplicationCatalogLink = $null
                        HideInstalledApplication   = $null
                        HideUnapprovedApplication  = $null
                        EnableApplicationsTab      = $null
                        EnableUpdatesTab           = $null
                        EnableOperatingSystemsTab  = $null
                        EnableStatusTab            = $null
                        EnableComplianceTab        = $null
                        EnableOptionsTab           = $null
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Device'
                        PortalType                 = 'Company Portal'
                    }

                    $portalErrorMsg = 'Software Center is currently set to use Company Portal in order to modify these settings, you must manually set client policy to Software Center.'

                    $inputBadColorScheme = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        EnableCustomize   = $true
                        ColorScheme       = '1#CB415Z'
                    }

                    $colorSchemeErrorMsg = 'ColorSchema is not formated correct: 1#CB415Z, example format would be #CB4154.'

                    $returnTabsMisconfigured = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableCustomize            = $true
                        CompanyName                = 'Test'
                        ColorScheme                = '#CB4154'
                        HideApplicationCatalogLink = $false
                        HideInstalledApplication   = $true
                        HideUnapprovedApplication  = $false
                        EnableApplicationsTab      = $true
                        EnableUpdatesTab           = $true
                        EnableOperatingSystemsTab  = $true
                        EnableStatusTab            = $true
                        EnableComplianceTab        = $false
                        EnableOptionsTab           = $true
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Device'
                        PortalType                 = 'Software Center'
                    }

                    $tabMsg = 'With the settings specified all Tabs will be put into a disabled state, you must have at least one tab enabled.'
                }

                It 'Should throw and call expected commands when client policy is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Client Policy Settings are user targeted' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when software center is set to use company portal' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnCompanyPortal }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $portalErrorMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when specified colorscheme is malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    { Set-TargetResource @inputBadColorScheme } | Should -Throw -ExpectedMessage $colorSchemeErrorMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when the combination of current state and specified state all tabs are disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnTabsMisconfigured }

                    { Set-TargetResource @inputTabsDisabled } | Should -Throw -ExpectedMessage $tabMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingSoftwareCenter -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsSoftwareCenter\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4154'
                    HideApplicationCatalogLink = $false
                    HideInstalledApplication   = $true
                    HideUnapprovedApplication  = $false
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $true
                    EnableOptionsTab           = $true
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                    PortalType                 = 'Software Center'
                }

                $returnTabsMisconfigured = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4154'
                    HideApplicationCatalogLink = $false
                    HideInstalledApplication   = $true
                    HideUnapprovedApplication  = $false
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $false
                    EnableOptionsTab           = $true
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                    PortalType                 = 'Software Center'
                }

                $returnAbsent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $null
                    CompanyName                = $null
                    ColorScheme                = $null
                    HideApplicationCatalogLink = $null
                    HideInstalledApplication   = $null
                    HideUnapprovedApplication  = $null
                    EnableApplicationsTab      = $null
                    EnableUpdatesTab           = $null
                    EnableOperatingSystemsTab  = $null
                    EnableStatusTab            = $null
                    EnableComplianceTab        = $null
                    EnableOptionsTab           = $null
                    ClientSettingStatus        = 'Absent'
                    ClientType                 = $null
                    PortalType                 = $null
                }

                $returnNotConfig = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $null
                    CompanyName                = $null
                    ColorScheme                = $null
                    HideApplicationCatalogLink = $null
                    HideInstalledApplication   = $null
                    HideUnapprovedApplication  = $null
                    EnableApplicationsTab      = $null
                    EnableUpdatesTab           = $null
                    EnableOperatingSystemsTab  = $null
                    EnableStatusTab            = $null
                    EnableComplianceTab        = $null
                    EnableOptionsTab           = $null
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                    PortalType                 = 'Software Center'
                }

                $returnUser = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $null
                    CompanyName                = $null
                    ColorScheme                = $null
                    HideApplicationCatalogLink = $null
                    HideInstalledApplication   = $null
                    HideUnapprovedApplication  = $null
                    EnableApplicationsTab      = $null
                    EnableUpdatesTab           = $null
                    EnableOperatingSystemsTab  = $null
                    EnableStatusTab            = $null
                    EnableComplianceTab        = $null
                    EnableOptionsTab           = $null
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'User'
                    PortalType                 = $null
                }

                $returnCompanyPortal = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $null
                    CompanyName                = $null
                    ColorScheme                = $null
                    HideApplicationCatalogLink = $null
                    HideInstalledApplication   = $null
                    HideUnapprovedApplication  = $null
                    EnableApplicationsTab      = $null
                    EnableUpdatesTab           = $null
                    EnableOperatingSystemsTab  = $null
                    EnableStatusTab            = $null
                    EnableComplianceTab        = $null
                    EnableOptionsTab           = $null
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                    PortalType                 = 'Company Portal'
                }

                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4154'
                    HideApplicationCatalogLink = $false
                    HideInstalledApplication   = $true
                    HideUnapprovedApplication  = $false
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $true
                    EnableOptionsTab           = $true
                }

                $inputTabsDisabled = @{
                    SiteCode                  = 'Lab'
                    ClientSettingName         = 'ClientTest'
                    EnableCustomize           = $true
                    EnableApplicationsTab     = $false
                    EnableUpdatesTab          = $false
                    EnableOperatingSystemsTab = $false
                    EnableStatusTab           = $false
                    EnableOptionsTab          = $false
                }

                $inputMisMatch = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableCustomize            = $true
                    CompanyName                = 'Test'
                    ColorScheme                = '#CB4155'
                    HideApplicationCatalogLink = $true
                    HideInstalledApplication   = $false
                    HideUnapprovedApplication  = $true
                    EnableApplicationsTab      = $true
                    EnableUpdatesTab           = $true
                    EnableOperatingSystemsTab  = $true
                    EnableStatusTab            = $true
                    EnableComplianceTab        = $true
                    EnableOptionsTab           = $true
                }

                $inputCustomizeDisabled = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    EnableCustomize   = $false
                    EnableOptionsTab  = $true
                }

                $inputBadColorScheme = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    EnableCustomize   = $true
                    ColorScheme       = '1#CB415Z'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false return is notconfigured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client policy settings does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false when client policy settings is user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false when expecting EnableCustomize set to disabled and is enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputCustomizeDisabled | Should -Be $false
                }

                It 'Should return desired result false when ColorScheme is malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputBadColorScheme | Should -Be $false
                }

                It 'Should return desired result false when software center setting is set to use company portal' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnCompanyPortal }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when Tabs are all set to disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnTabsMisconfigured }

                    Test-TargetResource @inputTabsDisabled | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
