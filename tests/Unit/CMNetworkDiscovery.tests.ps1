param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMNetworkDiscovery'

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

        Describe 'ConfigMgrCBDsc - DSC_CMNetworkDiscovery\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $standardGetDiscoveryDisabled = @{
                    Props = @(
                        @{
                            PropertyName = 'Discovery Enabled'
                            Value1       = 'FALSE'
                        }
                    )
                }

                $standardGetDiscoveryEnabled = @{
                    Props = @(
                        @{
                            PropertyName = 'Discovery Enabled'
                            Value1       = 'TRUE'
                        }
                    )
                }

                $standardGetInput = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving settings' {
                It 'Should return desired result when network discovery is disabled' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryDisabled }

                    $result = Get-TargetResource @standardGetInput
                    $result          | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled  | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when network discovery is enabled' {
                    Mock -CommandName Get-CMDiscoveryMethod -MockWith { $standardGetDiscoveryEnabled }

                    $result = Get-TargetResource @standardGetInput
                    $result          | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled  | Should -Be -ExpectedValue $true
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMNetworkDiscovery\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnDisabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $getReturnEnabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMDiscoveryMethod
            }

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands enabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }

                    Set-TargetResource @getReturnEnabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands disabling discovery' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @getReturnDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                It 'Should call expected commands and throw when Set-CMDiscoveryMethod throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }
                    Mock -CommandName Set-CMDiscoveryMethod -MockWith { throw }

                    { Set-TargetResource @getReturnDisabled } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMNetworkDiscovery\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnDisabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $false
                }

                $getReturnEnabled = @{
                    SiteCode = 'Lab'
                    Enabled  = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource and Network Discovery is enabled' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }
                }

                It 'Should return desired result true Network Discovery enabled' {
                    Test-TargetResource @getReturnEnabled | Should -Be $true
                }

                It 'Should return desired result false Network Discovery disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and Network Discovery is disabled' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                }

                It 'Should return desired result false Network Discovery enabled' {
                    Test-TargetResource @getReturnEnabled | Should -Be $false
                }

                It 'Should return desired result true Network Discovery disabled' {
                    Test-TargetResource @getReturnDisabled | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
