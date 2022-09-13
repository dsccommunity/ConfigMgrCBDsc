[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMHierarchySetting'

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

        Describe 'ConfigMgrCBDsc - DSC_CMHierarchySetting\Get-TargetResource' -Tag 'GetHier' {
            BeforeAll {
                $hierarchyReturn = @(
                    [pscustomobject]@{
                        PropertyNames             = @('AdvertisementDuration')
                        AdvertisementDuration     = 10
                        AllowPrestage             = $true
                        ExcludedCollectionID      = 'ExclusionId'
                        ExcludeServers            = $false
                        IsProgramEnabled          = $true
                        IsUpgradeExclusionEnabled = $true
                    }
                    [pscustomobject]@{
                        PropertyNames      = @('TargetCollectionID')
                        IsAccepted         = $true
                        IsEnabled          = $true
                        TargetCollectionID = 'PreprodId'
                    }
                )

                $cimInstanceReturn = @(
                    [pscustomobject]@{
                        PropertyName = 'Auto Approval'
                        Value        = 1
                    }
                    [pscustomobject]@{
                        PropertyName = 'Registration HardwareID Conflict Resolution'
                        Value        = 0
                    }
                    [pscustomobject]@{
                        PropertyName = 'AcceptedBeta'
                        Value        = 0
                    }
                    [pscustomobject]@{
                        PropertyName = 'PreferMPInBoundaryWithFastNetwork'
                        Value        = 0
                    }
                    [pscustomobject]@{
                        PropertyName = 'SiteAssignmentSiteCode'
                        Value1       = 'SI2'
                    }
                    [pscustomobject]@{
                        PropertyName = 'TelemetryLevel'
                        Value        = 2
                    }
                )

                $preprodCollection = @{
                    Name = 'Preprod Collection'
                }

                $excludedCollection = @{
                    Name = 'Exclusion Collection'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CimInstance -MockWith { $cimInstanceReturn } -ParameterFilter { $ClassName -eq 'SMS_SCI_SCProperty' }
            }

            Context 'When retrieving Hierarchy Settings' {

                It 'Should return current hierarchy settings' {
                    Mock -CommandName Get-CMHierarchySetting -MockWith { $hierarchyReturn }
                    Mock -CommandName Get-CMCollection -MockWith { $preprodCollection } -ParameterFilter { $Id -eq 'PreprodId' }
                    Mock -CommandName Get-CMCollection -MockWith { $excludedCollection } -ParameterFilter { $Id -eq 'ExclusionId' }


                    $result = Get-TargetResource -SiteCode Lab
                    $result                                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                           | Should -Be -ExpectedValue 'Lab'
                    $result.AllowPrestage                      | Should -Be -ExpectedValue $true
                    $result.ApprovalMethod                     | Should -Be -ExpectedValue 'AutomaticallyApproveComputersInTrustedDomains'
                    $result.AutoResolveClientConflict          | Should -Be -ExpectedValue $true
                    $result.EnableAutoClientUpgrade            | Should -Be -ExpectedValue $true
                    $result.EnableExclusionCollection          | Should -Be -ExpectedValue $true
                    $result.EnablePreProduction                | Should -Be -ExpectedValue $true
                    $result.EnablePrereleaseFeature            | Should -Be -ExpectedValue $false
                    $result.ExcludeServer                      | Should -Be -ExpectedValue $false
                    $result.PreferBoundaryGroupManagementPoint | Should -Be -ExpectedValue $false
                    $result.UseFallbackSite                    | Should -Be -ExpectedValue $true
                    $result.AutoUpgradeDays                    | Should -Be -ExpectedValue 10
                    $result.ExclusionCollectionName            | Should -Be -ExpectedValue 'Exclusion Collection'
                    $result.FallbackSiteCode                   | Should -Be -ExpectedValue 'SI2'
                    $result.TargetCollectionName               | Should -Be -ExpectedValue 'Preprod Collection'
                    $result.TelemetryLevel                     | Should -Be -ExpectedValue 'Enhanced'
                }

                It 'Should call expected commands when reading the hierarchy setting' {

                    Get-TargetResource -SiteCode Lab
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMHierarchySetting -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMHierarchySetting\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $correctInput = @{
                    SiteCode                           = 'Lab'
                    AllowPrestage                      = $true
                    ApprovalMethod                     = 'AutomaticallyApproveComputersInTrustedDomains'
                    AutoResolveClientConflict          = $true
                    EnableAutoClientUpgrade            = $true
                    EnableExclusionCollection          = $true
                    EnablePreProduction                = $true
                    EnablePrereleaseFeature            = $true
                    ExcludeServer                      = $true
                    PreferBoundaryGroupManagementPoint = $true
                    UseFallbackSite                    = $true
                    AutoUpgradeDays                    = 10
                    ExclusionCollectionName            = 'Exclusions'
                    FallbackSiteCode                   = 'FB1'
                    TargetCollectionName               = 'Preprod'
                    TelemetryLevel                     = 'Enhanced'
                }

                $fallbackMismatch = $correctInput.Clone()
                $fallbackMismatch.UseFallbackSite = $false
                $exclusionMismatch = $correctInput.Clone()
                $exclusionMismatch.Remove('ExclusionCollectionName')
                $preprodMismatch = $correctInput.Clone()
                $preprodMismatch.Remove('TargetCollectionName')
                $ignoreAutoUpgrade = $correctInput.Clone()
                $ignoreAutoUpgrade.EnableAutoClientUpgrade = $false

                Mock -CommandName Set-CMHierarchySetting
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Write-Verbose -MockWith {} -ParameterFilter { $Message -eq 'ExcludeServer is configured, but client auto upgrade is not configured. Skipping setting.' }
                Mock -CommandName Write-Verbose -MockWith {} -ParameterFilter { $Message -eq 'AutoUpgradeDays is configured, but client auto upgrade is not configured. Skipping setting.' }
            }

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands during configuration' {
                    Set-TargetResource @correctInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMHierarchySetting -Exactly -Times 1 -Scope It
                }
                It 'Should call expected commands during configuration with mismatched auto upgrade settings' {
                    Set-TargetResource @ignoreAutoUpgrade
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Write-Verbose -Exactly -Times 1 -ParameterFilter { $Message -eq 'ExcludeServer is configured, but client auto upgrade is not configured. Skipping setting.' }
                    Assert-MockCalled Write-Verbose -Exactly -Times 1 -ParameterFilter { $Message -eq 'AutoUpgradeDays is configured, but client auto upgrade is not configured. Skipping setting.' }
                    Assert-MockCalled Set-CMHierarchySetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $fallbackMismatchMessage = 'If UseFallbackSite or FallbackSiteCode are used, both properties need to be specified.'
                    $preprodMismatchMessage = 'If EnablePreProduction or TargetCollectionName are used, both properties need to be specified.'
                    $exclusionMismatchMessage = 'If EnableExclusionCollection or ExclusionCollectionName are used, both properties need to be specified.'
                }

                It 'Should throw and call expected commands when setting with mismatched fallback settings' {
                    { Set-TargetResource @fallbackMismatch } | Should -Throw -ExpectedMessage $fallbackMismatchMessage
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMHierarchySetting -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when setting with mismatched exclusion settings' {
                    { Set-TargetResource @exclusionMismatch } | Should -Throw -ExpectedMessage $exclusionMismatchMessage
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMHierarchySetting -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when setting with mismatched preprod settings' {
                    { Set-TargetResource @preprodMismatch } | Should -Throw -ExpectedMessage $preprodMismatchMessage
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Set-CMHierarchySetting -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMHierarchySetting\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresentDefault = @{
                    SiteCode                           = 'Lab'
                    AllowPrestage                      = $true
                    ApprovalMethod                     = 'AutomaticallyApproveComputersInTrustedDomains'
                    AutoResolveClientConflict          = $true
                    EnableAutoClientUpgrade            = $true
                    EnableExclusionCollection          = $true
                    EnablePreProduction                = $true
                    EnablePrereleaseFeature            = $true
                    ExcludeServer                      = $true
                    PreferBoundaryGroupManagementPoint = $true
                    UseFallbackSite                    = $true
                    AutoUpgradeDays                    = 10
                    ExclusionCollectionName            = 'Exclusions'
                    FallbackSiteCode                   = 'FB1'
                    TargetCollectionName               = 'Preprod'
                    TelemetryLevel                     = 'Enhanced'
                }

                $inputPresent = $returnPresentDefault.Clone()
                $inputMismatch = @{
                    SiteCode                           = 'Lab'
                    AllowPrestage                      = $false
                    ApprovalMethod                     = 'AutomaticallyApproveAllComputers'
                    AutoResolveClientConflict          = $false
                    EnableAutoClientUpgrade            = $false
                    EnableExclusionCollection          = $false
                    EnablePreProduction                = $false
                    EnablePrereleaseFeature            = $false
                    ExcludeServer                      = $false
                    PreferBoundaryGroupManagementPoint = $false
                    UseFallbackSite                    = $false
                    AutoUpgradeDays                    = 42
                    ExclusionCollectionName            = 'NoExclusions'
                    TargetCollectionName               = 'NoPreprod'
                    TelemetryLevel                     = 'Full'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefault }
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when there is a settings mismatch' {
                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
