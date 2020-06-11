param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSoftwareUpdatePoint'

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

#Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePoint\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                }

                $getSUPReturn = @{
                    SiteCode = 'Lab'
                    Props    = @(
                        @{
                            PropertyName = 'AllowProxyTraffic'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'IsINF'
                            Value        = '0'
                        }
                        @{
                            PropertyName = 'IsIntranet'
                            Value        = '1'
                        }
                        @{
                            PropertyName = 'SSLWSUS'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxy'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxyForADR'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'WSUSAccessAccount'
                            Value2       = $null
                        }
                        @{
                            PropertyName = 'WSUSIISPort'
                            Value        = '8530'
                        }
                        @{
                            PropertyName = 'WSUSIISSSLPort'
                            Value        = '8531'
                        }
                    )
                }

                $getSUPReturn2 = @{
                    SiteCode = 'Lab'
                    Props    = @(
                        @{
                            PropertyName = 'AllowProxyTraffic'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'IsINF'
                            Value        = '1'
                        }
                        @{
                            PropertyName = 'IsIntranet'
                            Value        = '1'
                        }
                        @{
                            PropertyName = 'SSLWSUS'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxy'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'UseProxyForADR'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'WSUSAccessAccount'
                            Value2       = 'contoso\admin'
                        }
                        @{
                            PropertyName = 'WSUSIISPort'
                            Value        = '8530'
                        }
                        @{
                            PropertyName = 'WSUSIISSSLPort'
                            Value        = '8531'
                        }
                    )
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving software update point settings' {

                It 'Should return desired result when software update point is not currently installed' {
                    Mock -CommandName Get-CMSoftwareUpdatePoint

                    $result = Get-TargetResource @getInput
                    $result                               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                      | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.AnonymousWsusAccess           | Should -Be -ExpectedValue $null
                    $result.ClientConnectionType          | Should -Be -ExpectedValue $null
                    $result.EnableCloudGateway            | Should -Be -ExpectedValue $null
                    $result.UseProxy                      | Should -Be -ExpectedValue $null
                    $result.UseProxyForAutoDeploymentRule | Should -Be -ExpectedValue $null
                    $result.WsusAccessAccount             | Should -Be -ExpectedValue $null
                    $result.WsusIisPort                   | Should -Be -ExpectedValue $null
                    $result.WsusIisSslPort                | Should -Be -ExpectedValue $null
                    $result.WsusSsl                       | Should -Be -ExpectedValue $null
                    $result.Ensure                        | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when software update point is currently installed' {
                    Mock -CommandName Get-CMSoftwareUpdatePoint -MockWith { $getSUPReturn }

                    $result = Get-TargetResource @getInput
                    $result                               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                      | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.AnonymousWsusAccess           | Should -Be -ExpectedValue $true
                    $result.ClientConnectionType          | Should -Be -ExpectedValue 'Intranet'
                    $result.EnableCloudGateway            | Should -Be -ExpectedValue $false
                    $result.UseProxy                      | Should -Be -ExpectedValue $false
                    $result.UseProxyForAutoDeploymentRule | Should -Be -ExpectedValue $false
                    $result.WsusAccessAccount             | Should -Be -ExpectedValue $null
                    $result.WsusIisPort                   | Should -Be -ExpectedValue 8530
                    $result.WsusIisSslPort                | Should -Be -ExpectedValue 8531
                    $result.WsusSsl                       | Should -Be -ExpectedValue $false
                    $result.Ensure                        | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when software update point is currently installed' {
                    Mock -CommandName Get-CMSoftwareUpdatePoint -MockWith { $getSUPReturn2 }

                    $result = Get-TargetResource @getInput
                    $result                               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                      | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.AnonymousWSUSAccess           | Should -Be -ExpectedValue $false
                    $result.ClientConnectionType          | Should -Be -ExpectedValue 'InternetAndIntranet'
                    $result.EnableCloudGateway            | Should -Be -ExpectedValue $false
                    $result.UseProxy                      | Should -Be -ExpectedValue $false
                    $result.UseProxyForAutoDeploymentRule | Should -Be -ExpectedValue $false
                    $result.WSUSAccessAccount             | Should -Be -ExpectedValue 'contoso\admin'
                    $result.WSUSIISPort                   | Should -Be -ExpectedValue 8530
                    $result.WSUSIISSSLPort                | Should -Be -ExpectedValue 8531
                    $result.WSUSSSL                       | Should -Be -ExpectedValue $false
                    $result.Ensure                        | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePoint\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMismatch = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    ClientConnectionType          = 'InternetAndIntranet'
                    EnableCloudGateway            = $true
                    UseProxy                      = $true
                    UseProxyForAutoDeploymentRule = $true
                    WSUSAccessAccount             = 'contoso\admin'
                    WsusIisPort                   = 8530
                    WsusIisSslPort                = 8531
                    WsusSsl                       = $true
                    Ensure                        = 'Present'
                }

                $getReturnAll = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    AnonymousWSUSAccess           = $true
                    ClientConnectionType          = 'Intranet'
                    EnableCloudGateway            = $false
                    UseProxy                      = $false
                    UseProxyForAutoDeploymentRule = $false
                    WSUSAccessAccount             = $null
                    WsusIisPort                   = 8530
                    WsusIisSslPort                = 8531
                    WsusSsl                       = $null
                    Ensure                        = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    AnonymousWSUSAccess           = $null
                    ClientConnectionType          = $null
                    EnableCloudGateway            = $null
                    UseProxy                      = $null
                    UseProxyForAutoDeploymentRule = $null
                    WSUSAccessAccount             = $null
                    WsusIisPort                   = $null
                    WsusIisSslPort                = $null
                    WsusSsl                       = $null
                    Ensure                        = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMSoftwareUpdatePoint
                Mock -CommandName Set-CMSoftwareUpdatePoint
                Mock -CommandName Remove-CMSoftwareUpdatePoint
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach{
                    $inputMatch = @{
                        SiteCode                      = 'Lab'
                        SiteServerName                = 'CA01.contoso.com'
                        AnonymousWSUSAccess           = $true
                        ClientConnectionType          = 'Intranet'
                        EnableCloudGateway            = $false
                        UseProxy                      = $false
                        UseProxyForAutoDeploymentRule = $false
                        WsusIisPort                   = 8530
                        WsusIisSslPort                = 8531
                        Ensure                        = 'Present'
                    }
                }

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when software update point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when software update point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach{
                    $inputPresent = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'CA01.contoso.com'
                        Ensure         = 'Present'
                    }

                    $gatewayThrow = @{
                        SiteCode             = 'Lab'
                        SiteServerName       = 'CA01.contoso.com'
                        EnableCloudGateway   = $true
                        ClientConnectionType = 'Intranet'
                    }

                    $gatewayThrowMsg = 'When CloudGateway is enabled, ClientConnectionType must not equal Intranet.'

                    $sslThrow = @{
                        SiteCode             = 'Lab'
                        SiteServerName       = 'CA01.contoso.com'
                        EnableCloudGateway   = $true
                        ClientConnectionType = 'Internet'
                        WsusSsl              = $false
                    }

                    $sslThrowMsg = 'When CloudGateway is enabled SSL must also be enabled.'

                    $computerAccountUserAccount = @{
                        SiteCode            = 'Lab'
                        SiteServerName      = 'CA01.contoso.com'
                        WSUSAccessAccount   = 'contoso\test'
                        AnonymousWsusAccess = $true
                    }

                    $acountThrowMsg = 'You can not specify a WSUSAccessAccount and set AnonymousWsusAccess to $true.'

                    $proxyThrow = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'CA01.contoso.com'
                        UseProxy       = $true
                    }

                    $proxyThrowMsg = 'No proxy is configured on the server. Please configure a proxy before specifying UseProxy or UseProxyForAutoDeploymentRule as true.'

                    $filterReturn = @{
                        Props = @(
                            @{
                                PropertyName = 'UseProxy'
                                Value        = '0'
                            }
                        )
                    }
                }

                It 'Should call throws when Gateway is enabled and connection type is intranet' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @gatewayThrow } | Should -Throw -ExpectedMessage $gatewayThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when Gateway is enabled and SSL is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @sslThrow } | Should -Throw -ExpectedMessage $sslThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when usecomputeraccount and username are specified together' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @computerAccountUserAccount } | Should -Throw -ExpectedMessage $acountThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when useProxy is specified and no proxy is configured on the server' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { $filterReturn }

                    { Set-TargetResource @proxyThrow } | Should -Throw -ExpectedMessage $proxyThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
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
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Add-CMSoftwareUpdatePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                    Mock -CommandName Add-CMSoftwareUpdatePoint -MockWith { throw }

                    { Set-TargetResource @inputPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMSoftwareUpdatePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMSoftwareUpdatePoint -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMSoftwareUpdatePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMSoftwareUpdatePoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePoint\Test-TargetResource' -Tag 'Test'{
            BeforeAll{
                $inputPresent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Present'
                }

                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMatch = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    AnonymousWSUSAccess           = $true
                    ClientConnectionType          = 'Intranet'
                    EnableCloudGateway            = $false
                    UseProxy                      = $false
                    UseProxyForAutoDeploymentRule = $false
                    WsusIisPort                   = 8530
                    WsusIisSslPort                = 8531
                    Ensure                        = 'Present'
                }

                $inputMismatch = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    ClientConnectionType          = 'InternetAndIntranet'
                    EnableCloudGateway            = $true
                    UseProxy                      = $true
                    UseProxyForAutoDeploymentRule = $true
                    WSUSAccessAccount             = 'contoso\admin'
                    WsusIisPort                   = 8530
                    WsusIisSslPort                = 8531
                    WsusSsl                       = $true
                    Ensure                        = 'Present'
                }

                $getReturnAll = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    AnonymousWSUSAccess           = $true
                    ClientConnectionType          = 'Intranet'
                    EnableCloudGateway            = $false
                    UseProxy                      = $false
                    UseProxyForAutoDeploymentRule = $false
                    WSUSAccessAccount             = $null
                    WsusIisPort                   = 8530
                    WsusIisSslPort                = 8531
                    WsusSsl                       = $null
                    Ensure                        = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode                      = 'Lab'
                    SiteServerName                = 'CA01.contoso.com'
                    AnonymousWSUSAccess           = $null
                    ClientConnectionType          = $null
                    EnableCloudGateway            = $null
                    UseProxy                      = $null
                    UseProxyForAutoDeploymentRule = $null
                    WSUSAccessAccount             = $null
                    WsusIisPort                   = $null
                    WsusIisSslPort                = $null
                    WsusSsl                       = $null
                    Ensure                        = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns ' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result false when ensure = absent and SUP is present' {

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result true when all returned values match inputs' {

                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false when there is a mismatch between returned values and inputs' {

                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns absent' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result false when ensure = present and SUP is absent' {

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and SUP is absent' {

                    Test-TargetResource @inputAbsent | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
