[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMPullDistributionPoint'

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
        Describe 'ConfigMgrCBDsc - DSC_CMPullDistributionPoint\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {
                BeforeEach {
                    $getCMdistroOutputMultiple = @{
                        Props     = @(
                            @{
                                PropertyName = 'IsPullDP'
                                Value        = 1
                            }
                        )
                        PropLists = @(
                            @{
                                PropertyListName = 'SourceDistributionPoints'
                                Values           = @(
                                    'DISPLAY=\\DP02.contoso.com\"]MSWNET:["SMS_SITE=LAB"]\\DP02.contoso.com\',
                                    'DISPLAY=\\DP03.contoso.com\"]MSWNET:["SMS_SITE=LAB"]\\DP03.contoso.com\'
                                )
                            }
                            @{
                                PropertyListName = 'SourceDPRanks'
                                Values           = @('1','2')
                            }
                        )
                    }

                    $getCMdistroOutputSingle = @{
                        Props     = @(
                            @{
                                PropertyName = 'IsPullDP'
                                Value        = 1
                            }
                        )
                        PropLists = @(
                            @{
                                PropertyListName = 'SourceDistributionPoints'
                                Values           = 'DISPLAY=\\DP02.contoso.com\"]MSWNET:["SMS_SITE=LAB"]\\DP02.contoso.com\'
                            }
                            @{
                                PropertyListName = 'SourceDPRanks'
                                Values           = '1'
                            }
                        )
                    }

                    $getInput = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'DP01.contoso.com'
                    }
                }

                It 'Should return desired result when all info is returned with multiple SourceDPs' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $getCMdistroOutputMultiple }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                      | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.EnablePullDP                        | Should -Be -ExpectedValue $true
                    $result.SourceDistributionPoint             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.SourceDistributionPoint[0].SourceDP | Should -Be -ExpectedValue 'DP02.contoso.com'
                    $result.SourceDistributionPoint[0].DPRank   | Should -Be -ExpectedValue '1'
                    $result.SourceDistributionPoint[1].SourceDP | Should -Be -ExpectedValue 'DP03.contoso.com'
                    $result.SourceDistributionPoint[1].DPRank   | Should -Be -ExpectedValue '2'
                    $result.DPStatus                            | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when all info is returned with single SourceDP' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $getCMdistroOutputSingle }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                      | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.EnablePullDP                        | Should -Be -ExpectedValue $true
                    $result.SourceDistributionPoint             | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.SourceDistributionPoint[0].SourceDP | Should -Be -ExpectedValue 'DP02.contoso.com'
                    $result.SourceDistributionPoint[0].DPRank   | Should -Be -ExpectedValue '1'
                    $result.DPStatus                            | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when role is not installed' {
                    Mock -CommandName Get-CMDistributionPoint

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                      | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.EnablePullDP                        | Should -Be -ExpectedValue $null
                    $result.SourceDistributionPoint             | Should -Be -ExpectedValue $null
                    $result.DPStatus                            | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMPullDistributionPoint\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'DP01.contoso.com'
                    EnablePullDP   = $false
                }

                $getSourceDPReturn = @(
                    (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'SourceDP' = 'DP02.contoso.com'
                            'DPRank'   = '1'
                        } `
                        -ClientOnly
                    ),
                    (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            'SourceDP' = 'DP03.contoso.com'
                            'DPRank'   = '2'
                        } `
                        -ClientOnly
                    )
                )

                $getTargetReturn = @{
                    SiteCode                = 'Lab'
                    SiteServerName          = 'DP01.contoso.com'
                    EnablePullDP            = $true
                    SourceDistributionPoint = $getSourceDPReturn
                    DPStatus                = 'Present'
                }

                $inputMatch = @{
                    SiteCode                = 'Lab'
                    SiteServerName          = 'DP01.contoso.com'
                    EnablePullDP            = $true
                    SourceDistributionPoint = $getSourceDPReturn
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDistributionPoint
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $sourceDPInput = @(
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP02.contoso.com'
                                'DPRank'   = '1'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP04.contoso.com'
                                'DPRank'   = '2'
                            } `
                            -ClientOnly
                        )
                    )

                    $inputSourceDPMisMatch = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $true
                        SourceDistributionPoint = $sourceDPInput
                    }

                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when Source DPs do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @inputSourceDPMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when currently EnablePullDP is disabled and expected enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $pullDPDisabled }

                    Set-TargetResource @inputSourceDPMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when expected EnablePullDP to be set to disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $dpRoleNotInstalledReturn = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $null
                        SourceDistributionPoint = $null
                        DPStatus                = 'Absent'
                    }

                    $inputAbsentValue = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $false
                        SourceDistributionPoint = $getSourceDPReturn
                    }

                    $invalidConfig = 'EnablePullDP is being set to false or is currently false and can not specify a sourcedistribution point, set to enable of remove SourceDistributionPoint from the configuration.'

                    $dpRoleAbsent = 'The Distribution Point role on DP01.contoso.com is not installed, run DSC_CMDistibutionPoint to install the role.'

                    $inputInvalid = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'DP01.contoso.com'
                        EnablePullDP   = $true
                    }

                    $pullDPEnableNoSource = 'When enabling a Pull DP sourceDistribution Point must be specified.'
                }

                It 'Should throw and call expected commands when distribution point role is not installed' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpRoleNotInstalledReturn }

                    { Set-TargetResource @inputAbsent } | Should -Throw -ExpectedMessage $dpRoleAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when specifying disabled and SourceDistributionPoint' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    { Set-TargetResource @inputAbsentValue } | Should -Throw -ExpectedMessage $invalidConfig
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when specifying enabled and not specifing Source Distribution Points' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn }

                    { Set-TargetResource @inputInvalid } | Should -Throw -ExpectedMessage $pullDPEnableNoSource
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMPullDistributionPoint\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    $getSourceDPReturn = @(
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP02.contoso.com'
                                'DPRank'   = '1'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP03.contoso.com'
                                'DPRank'   = '2'
                            } `
                            -ClientOnly
                        )
                    )

                    $sourceDPInput = @(
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP02.contoso.com'
                                'DPRank'   = '1'
                            } `
                            -ClientOnly
                        ),
                        (New-CimInstance -ClassName DSC_CMPullDistributionPointSourceDP `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -Property @{
                                'SourceDP' = 'DP04.contoso.com'
                                'DPRank'   = '2'
                            } `
                            -ClientOnly
                        )
                    )

                    $getTargetReturn = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $true
                        SourceDistributionPoint = $getSourceDPReturn
                        DPStatus                = 'Present'
                    }

                    $inputMatch = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $true
                        SourceDistributionPoint = $getSourceDPReturn
                    }

                    $inputSourceDPMisMatch = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $true
                        SourceDistributionPoint = $sourceDPInput
                    }

                    $dpRoleNotInstalledReturn = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $null
                        SourceDistributionPoint = $null
                        DPStatus                = 'Absent'
                    }

                    $pullDPDisabled = @{
                        SiteCode                = 'Lab'
                        SiteServerName          = 'DP01.contoso.com'
                        EnablePullDP            = $false
                        SourceDistributionPoint = $null
                        DPStatus                = 'Present'
                    }

                    $inputAbsent = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'DP01.contoso.com'
                        EnablePullDP   = $false
                    }
                }

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn  }

                    Test-TargetResource @inputMatch  | Should -Be $true
                }

                It 'Should return desired result false when Source DP settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn  }

                    Test-TargetResource @inputSourceDPMisMatch  | Should -Be $false
                }

                It 'Should return desired result false when Pull DP is disabled and expected enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $pullDPDisabled  }

                    Test-TargetResource @inputSourceDPMisMatch  | Should -Be $false
                }

                It 'Should return desired result false when Pull DP is enabled and expected disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturn  }

                    Test-TargetResource @inputAbsent  | Should -Be $false
                }

                It 'Should return desired result false when Distribution Point role is not installed' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpRoleNotInstalledReturn  }

                    Test-TargetResource @inputMatch  | Should -Be $false
                }

                It 'Should return desired result true when Pull DP is disabled and expected disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $pullDPDisabled  }

                    Test-TargetResource @inputAbsent  | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
