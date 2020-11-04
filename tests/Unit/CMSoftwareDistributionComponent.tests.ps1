[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSiteSystemServer'

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

        Describe 'DSC_CMSiteSystemServer\Get-TargetResource' -Tag 'Get' {
            BeforeAll {

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving site system settings' {

                It 'Should return desired result when a site system' {
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $siteServerReturn }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.MaximumPackageCount     | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.MaximumThreadCountPerPackage           | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.RetryCount         | Should -Be -ExpectedValue $true
                    $result.DelayBeforeRetryingMins | Should -Be -ExpectedValue $false
                    $result.MulticastRetryCount          | Should -Be -ExpectedValue 'contoso\Account'
                    $result.MulticastDelayBeforeRetryingMins | Should -Be -ExpectedValue $true
                    $result.ComputerAccount                  | Should -Be -ExpectedValue 'Proxy.contoso.com'
                    $result.AccessAccounts                   | Should -Be -ExpectedValue 443
                }
            }
        }

        Describe 'DSC_CMSiteSystemServer\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnPresent = @{
                    SiteCode             = 'Lab'
                    SiteSystemServer     = 'SS01.contoso.com'
                    PublicFqdn           = 'SS01.contoso.com'
                    FdmOperation         = $true
                    UseSiteServerAccount = $false
                    AccountName          = 'contoso\account'
                    EnableProxy          = $true
                    ProxyServerName      = 'Proxy.contoso.com'
                    ProxyServerPort      = 443
                    ProxyAccessAccount   = 'contoso\ProxyUser'
                    Ensure               = 'Present'
                    RoleCount            = 1
                }

                $getReturnAbsent = @{
                    SiteCode             = 'Lab'
                    SiteSystemServer     = 'SS01.contoso.com'
                    PublicFqdn           = 'SS01.contoso.com'
                    FdmOperation         = $null
                    UseSiteServerAccount = $null
                    AccountName          = $null
                    EnableProxy          = $null
                    ProxyServerName      = $null
                    ProxyServerPort      = $null
                    ProxyAccessAccount   = $null
                    Ensure               = 'Absent'
                    RoleCount            = $null
                }

                $inputAbsent = @{
                    SiteCode         = 'Lab'
                    SiteSystemServer = 'SS01.contoso.com'
                    Ensure           = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Set-CMSiteSystemServer
                Mock -CommandName Remove-CMSiteSystemServer
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $misMatchInput = @{
                        SiteCode             = 'Lab'
                        SiteSystemServer     = 'SS01.contoso.com'
                        PublicFqdn           = ''
                        FdmOperation         = $false
                        UseSiteServerAccount = $false
                        AccountName          = 'contoso\useraccount'
                        EnableProxy          = $true
                        ProxyServerName      = 'Proxy1.contoso.com'
                        Ensure               = 'Present'
                    }

                    Mock -CommandName Get-CMAccount -MockWith { $true }
                }

                It 'Should call expected command when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @misMatchInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $proxySettingsNoServerName = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUser'
                        EnableProxy        = $true
                        ProxyServerPort    = 80
                    }

                    $proxyNoServer = 'When EnableProxy equals $True you must at least specify ProxyServerName.'
                    $proxySettingNoEnable = 'When specifying a proxy setting you must specify EnableProxy = $True.'
                    $badAccountName = 'AccountName contoso\badaccount does not exist in Configuraion Manager.'
                    $badProxyAccess = 'ProxyAccessAccount contoso\ProxyUserBad does not exist in Configuraion Manager.'
                    $siteAndAccount = 'You have specified to use SiteSystemAccount and an Account for site server communications, you can only specify 1 or the other.'
                    $rolecount = 'Must uninstall all other roles prior to removing the site server component current rolecount: 3.'
                }

                It 'Should call expected command when not specifying ProxyServerName' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @proxySettingsNoServerName } | Should -Throw -ExpectedMessage $proxyNoServer
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'DSC_CMSiteSystemServer\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $testDSCValues = @{
                    SiteCode             = 'Lab'
                    SiteSystemServer     = 'SS01.contoso.com'
                    PublicFqdn           = 'SSO01.contoso.com'
                    FdmOperation         = $false
                    UseSiteServerAccount = $false
                    AccountName          = 'contoso\Accountbad'
                }

                $absentInput = @{
                    SiteCode         = 'Lab'
                    SiteSystemServer = 'SS01.contoso.com'
                    Ensure           = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Get-TargetResource turns present' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                }

                It 'Should return desired result false when non proxy settings do not match' {
                    Test-TargetResource @testDSCValues | Should -Be $false
                }

                It 'Should return desired result false when when specifying Account and UseSiteServerAccount' {
                    Test-TargetResource @siteServerAndAccount | Should -Be $false
                }

                It 'Should return desired result true when when proxy settings match' {
                    Test-TargetResource @proxySettingsMatch | Should -Be $true
                }

                It 'Should return desired result false with no ProxyServerName and settings do not match' {
                    Test-TargetResource @proxySettingsNoServerName | Should -Be $false
                }

                It 'Should return desired result false with no proxy port and settings do not match' {
                    Test-TargetResource @proxySettingsNoPort | Should -Be $false
                }

                It 'Should return desired result false with no proxy access account and settings do not match' {
                    Test-TargetResource @proxySettingsNoAccessAccount | Should -Be $false
                }

                It 'Should return desired result false with no EnableProxy and setting a proxy settings that does not match' {
                    Test-TargetResource @proxySettingNoEnableProxy | Should -Be $false
                }

                It 'Should return desired result false with resetting proxy access account to system account' {
                    Test-TargetResource @proxyAccessAccount | Should -Be $false
                }

                It 'Should return desired result false when expecting absent but is present' {
                    Test-TargetResource @absentInput | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
