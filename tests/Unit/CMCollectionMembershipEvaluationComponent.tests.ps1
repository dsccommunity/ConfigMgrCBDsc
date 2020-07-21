param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMCollectionMembershipEvaluationComponent'

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

        Describe 'ConfigMgrCBDsc - DSC_CMCollectionMembershipEvaluationComponent\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $getDiscovery = @{
                    Props = @(
                        @{
                            PropertyName = 'Incremental Interval'
                            Value        = 5
                        }
                    )
                }

                $getInput = @{
                    SiteCode = 'Lab'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving settings' {
                It 'Should return desired result when retrieving Collection Membership Evaluation Component settings' {
                    Mock -CommandName Get-CMCollectionMembershipEvaluationComponent -MockWith { $getDiscovery }

                    $result = Get-TargetResource @getInput
                    $result                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode       | Should -Be -ExpectedValue 'Lab'
                    $result.EvaluationMins | Should -Be -ExpectedValue '5'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMCollectionMembershipEvaluationComponent\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturn = @{
                    SiteCode       = 'Lab'
                    EvaluationMins = 5
                }

                $getReturnMismatch = @{
                    SiteCode       = 'Lab'
                    EvaluationMins = 10
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                Mock -CommandName Set-CMCollectionMembershipEvaluationComponent
            }

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands when changing settings' {

                    Set-TargetResource @getReturnMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollectionMembershipEvaluationComponent -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                It 'Should call expected commands and throw when Set-CMCollectionMembershipEvaluationComponent throws' {
                    Mock -CommandName Set-CMCollectionMembershipEvaluationComponent -MockWith { throw }

                    { Set-TargetResource @getReturnMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMCollectionMembershipEvaluationComponent -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMCollectionMembershipEvaluationComponent\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturn = @{
                    SiteCode       = 'Lab'
                    EvaluationMins = 5
                }

                $getReturnMismatch = @{
                    SiteCode       = 'Lab'
                    EvaluationMins = 10
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                }

                It 'Should return desired result true when all returned values match inputs' {
                    Test-TargetResource @getReturn| Should -Be $true
                }

                It 'Should return desired result false when there is a mismatch between returned values and inputs' {
                    Test-TargetResource @getReturnMismatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
