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
                $siteServerReturn = @{
                    SiteCode      = 'Lab'
                    RoleName      = 'SMS Site Server'
                    NetworkOSPath = '\\SS01.contoso.com'
                    RoleCount     = 1
                    Props         = @(
                        @{
                            PropertyName = 'AnonymousProxyAccess'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'FDMOperation'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'ProxyName'
                            Value2       = 'Proxy.contoso.com'
                        }
                        @{
                            PropertyName = 'ProxyServerPort'
                            Value        = 443
                        }
                        @{
                            PropertyName = 'ProxyUserName'
                            Value2       = 'contoso\ProxyUser'
                        }
                        @{
                            PropertyName = 'Server Remote Public Name'
                            Value1       = 'SS01.contoso.com'
                        }
                        @{
                            PropertyName = 'UseMachineAccount'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxy'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'UserName'
                            Value2       = 'contoso\Account'
                        }
                    )
                }

                $siteServerReturnAnon = @{
                    SiteCode      = 'Lab'
                    RoleName      = 'SMS Site Server'
                    NetworkOSPath = '\\SS01.contoso.com'
                    RoleCount     = 1
                    Props         = @(
                        @{
                            PropertyName = 'AnonymousProxyAccess'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'FDMOperation'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'ProxyName'
                            Value2       = 'Proxy.contoso.com'
                        }
                        @{
                            PropertyName = 'ProxyServerPort'
                            Value        = 443
                        }
                        @{
                            PropertyName = 'ProxyUserName'
                            Value2       = 'contoso\ProxyUser'
                        }
                        @{
                            PropertyName = 'Server Remote Public Name'
                            Value1       = 'SS01.contoso.com'
                        }
                        @{
                            PropertyName = 'UseMachineAccount'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxy'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'UserName'
                            Value2       = 'contoso\Account'
                        }
                    )
                }

                $getInput = @{
                    SiteCode = 'Lab'
                    SiteSystemServer = 'SS01.contoso.com'
                }


                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving site system settings' {

                It 'Should return desired result when a site system' {
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $siteServerReturn }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.SiteSystemServer     | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.PublicFqdn           | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.FdmOperation         | Should -Be -ExpectedValue $true
                    $result.UseSiteServerAccount | Should -Be -ExpectedValue $false
                    $result.AccountName          | Should -Be -ExpectedValue 'contoso\Account'
                    $result.EnableProxy          | Should -Be -ExpectedValue $true
                    $result.ProxyServerName      | Should -Be -ExpectedValue 'Proxy.contoso.com'
                    $result.ProxyServerPort      | Should -Be -ExpectedValue 443
                    $result.ProxyAccessAccount   | Should -Be -ExpectedValue 'contoso\ProxyUser'
                    $result.Ensure               | Should -Be -ExpectedValue 'Present'
                    $result.RoleCount            | Should -Be -ExpectedValue 1
                }

                It 'Should return desired result when a site system and no proxy account' {
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $siteServerReturnAnon }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.SiteSystemServer     | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.PublicFqdn           | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.FdmOperation         | Should -Be -ExpectedValue $true
                    $result.UseSiteServerAccount | Should -Be -ExpectedValue $false
                    $result.AccountName          | Should -Be -ExpectedValue 'contoso\Account'
                    $result.EnableProxy          | Should -Be -ExpectedValue $true
                    $result.ProxyServerName      | Should -Be -ExpectedValue 'Proxy.contoso.com'
                    $result.ProxyServerPort      | Should -Be -ExpectedValue 443
                    $result.ProxyAccessAccount   | Should -Be -ExpectedValue $null
                    $result.Ensure               | Should -Be -ExpectedValue 'Present'
                    $result.RoleCount            | Should -Be -ExpectedValue 1
                }

                It 'Should return desired result when not a site system' {
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.SiteSystemServer     | Should -Be -ExpectedValue 'SS01.contoso.com'
                    $result.PublicFqdn           | Should -Be -ExpectedValue $null
                    $result.FdmOperation         | Should -Be -ExpectedValue $null
                    $result.UseSiteServerAccount | Should -Be -ExpectedValue $null
                    $result.AccountName          | Should -Be -ExpectedValue $null
                    $result.EnableProxy          | Should -Be -ExpectedValue $null
                    $result.ProxyServerName      | Should -Be -ExpectedValue $null
                    $result.ProxyServerPort      | Should -Be -ExpectedValue $null
                    $result.ProxyAccessAccount   | Should -Be -ExpectedValue $null
                    $result.Ensure               | Should -Be -ExpectedValue 'Absent'
                    $result.RoleCount            | Should -Be -ExpectedValue $null
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

                    $proxyAccessAccount = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        AccountName        = 'contoso\useraccount'
                        EnableProxy        = $true
                        ProxyServerName    = 'Proxy.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUserBad'
                        Ensure             = 'Present'
                    }

                    $disableProxy = @{
                        SiteCode         = 'Lab'
                        SiteSystemServer = 'SS01.contoso.com'
                        EnableProxy      = $false
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

                It 'Should call expected command when adding a site system server' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @misMatchInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when changing the proxy access account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @proxyAccessAccount
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when removing a site system server' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 1 -Scope It
                }

                It 'Should call expected command when disabling proxy' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @disableProxy
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
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

                    $proxySettingBadProxyAccount = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyServerName    = 'CA01.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUserBad'
                        EnableProxy        = $true
                        ProxyServerPort    = 80
                    }

                    $proxySettingNoEnableProxy = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyServerPort    = 80
                    }

                    $userAccountBad = @{
                        SiteCode         = 'Lab'
                        SiteSystemServer = 'SS01.contoso.com'
                        AccountName      = 'contoso\badaccount'
                    }

                    $accountAndUseSiteSystem = @{
                        SiteCode             = 'Lab'
                        SiteSystemServer     = 'SS01.contoso.com'
                        AccountName          = 'contoso\account'
                        UseSiteServerAccount = $true
                    }

                    $getReturnPresentMultipleRoles = @{
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
                        RoleCount            = 3
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

                It 'Should call expected command when not specifying a bad proxy access account' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @proxySettingBadProxyAccount } | Should -Throw -ExpectedMessage $badProxyAccess
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when AccountName account does not exist' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @userAccountBad } | Should -Throw -ExpectedMessage $badAccountName
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when specifying proxy settings and not specifying EnableProxy' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @proxySettingNoEnableProxy } | Should -Throw -ExpectedMessage $proxySettingNoEnable
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when specifying UserAccount and UseSiteSystemAccount' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @accountAndUseSiteSystem } | Should -Throw -ExpectedMessage $siteAndAccount
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSiteSystemServer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command removing the site system server role and has multiple roles installed' {
                    Mock -CommandName Get-CMAccount
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentMultipleRoles }

                    { Set-TargetResource @inputAbsent } | Should -Throw -ExpectedMessage $rolecount
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
                        RoleCount            = 3
                    }

                    $siteServerAndAccount = @{
                        SiteCode             = 'Lab'
                        SiteSystemServer     = 'SS01.contoso.com'
                        UseSiteServerAccount = $true
                        AccountName          = 'contoso\Account'
                    }

                    $proxySettingsMatch = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUser'
                        EnableProxy        = $true
                        ProxyServerPort    = 443
                        ProxyServerName    = 'Proxy.contoso.com'
                    }

                    $proxySettingsNoServerName = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUser'
                        EnableProxy        = $true
                        ProxyServerPort    = 80
                    }

                    $proxyAccessAccount = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyAccessAccount = ''
                        EnableProxy        = $true
                        ProxyServerPort    = 80
                    }

                    $proxySettingsNoPort = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyAccessAccount = 'contoso\ProxyUser1'
                        EnableProxy        = $true
                        ProxyServerName    = 'Proxy.contoso.com'
                    }

                    $proxySettingsNoAccessAccount = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        EnableProxy        = $true
                        ProxyServerPort    = 80
                        ProxyServerName    = 'Proxy.contoso.com'
                    }

                    $proxySettingNoEnableProxy = @{
                        SiteCode           = 'Lab'
                        SiteSystemServer   = 'SS01.contoso.com'
                        ProxyServerPort    = 80
                    }

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

            Context 'When Get-TargetResource turns absent' {
                BeforeEach {
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

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result true when expecting absent and is absent' {
                    Test-TargetResource @absentInput | Should -Be $true
                }

                It 'Should return desired result false when expecting present and is absent' {
                    Test-TargetResource @testDSCValues | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
