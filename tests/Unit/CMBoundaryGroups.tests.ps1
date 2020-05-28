[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMBoundaryGroups'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMBoundaryGroups'

        # Get-TargetResource input and output
        $getInput = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
        }

        $getBoundaryGroupOutput = @{
            Name    = 'TestGroup'
            GroupID = 16777229
        }

        $getBoundaryOutput = @(
            @{
                BoundaryId   = 16777231
                BoundaryType = 3
                Value        = '10.1.1.1-10.1.1.255'
            }
            @{
                BoundaryId   = 16777232
                BoundaryType = 0
                Value        = '10.1.3.0'
            }
            @{
                BoundaryId   = 16777233
                BoundaryType = 2
                Value        = 'First-Site'
            }
        )

        $mockBoundaryMembers = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = '10.1.1.1-10.1.1.255'
                    'Type'  = 'IPRange'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = '10.1.3.0'
                    'Type'  = 'IPSubnet'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = 'First-Site'
                    'Type'  = 'ADSite'
                } `
                -ClientOnly
            )
        )

        $mockInputBoundaryRange = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = '10.1.1.1-10.1.1.255'
                    'Type'  = 'IPRange'
                } `
                -ClientOnly
            )
        )

        $mockInputBoundarySubnet = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = '10.1.3.1/24'
                    'Type'  = 'IPSubnet'
                } `
                -ClientOnly
            )
        )

        $mockOutputBoundarySubnet = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = '10.1.3.0'
                    'Type'  = 'IPSubnet'
                } `
                -ClientOnly
            )
        )

        $mockInputBoundaryADSite = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = 'First-Site'
                    'Type'  = 'ADSite'
                } `
                -ClientOnly
            )
        )

        $mockInputBoundaryADSiteAdd = @(
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = 'Second-Site'
                    'Type'  = 'ADSite'
                } `
                -ClientOnly
            )
        )

        $setTestInputMatch = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundaryRange
            BoundaryAction = 'Match'
        }

        $setTestInputAdd = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundarySubnet
            BoundaryAction = 'Add'
        }

        $setTestInputAddValue = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundaryADSiteAdd
            BoundaryAction = 'Add'
        }

        $setTestInputRemove = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundarySubnet
            BoundaryAction = 'Remove'
        }

        $getReturn = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $mockBoundaryMembers
            Ensure        = 'Present'
        }

        $setTestInputGroupOnly = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Present'
        }

        $setTestInputGroupOnlyAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Absent'
        }

        $getReturnNoBoundaries = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Present'
        }

        $getReturnAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Absent'
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving boundary group settings' {

                It 'Should return desired result when boundary group does not exist' {
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $null }
                    Mock -CommandName Get-CMBoundary -MockWith { $null }
                    Mock -CommandName ConvertTo-CimBoundaries -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries    | Should -Be -ExpectedValue $null
                    $result.Ensure        | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when boundaries is exists and has no boundaries assoicated' {
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroupOutput }
                    Mock -CommandName Get-CMBoundary -MockWith { $null }
                    Mock -CommandName ConvertTo-CimBoundaries -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries    | Should -Be -ExpectedValue $null
                    $result.Ensure        | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when boundary group exists and contains boundaries' {
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroupOutput }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryOutput }
                    Mock -CommandName ConvertTo-CimBoundaries -MockWith { $mockBoundaryMembers }

                    $result = Get-TargetResource @getInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup    | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries       | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                    $result.Boundaries.Count | Should -Be -ExpectedValue 3
                    $result.Ensure           | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMBoundaryGroup
                Mock -CommandName Add-CMBoundaryToGroup
                Mock -CommandName Remove-CMBoundaryGroup
                Mock -CommandName Remove-CMBoundaryFromGroup

                It 'Should call expected commands for new boundary group and adding boundary' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet }
                    Mock -CommandName Get-BoundaryInfo -MockWith { return 164111 }

                    Set-TargetResource @setTestInputAdd
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 1 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for adding a new boundary to the group' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd }
                    Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 }

                    Set-TargetResource @setTestInputAddValue
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for boundary set to match removing two additional boundaries' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryRange }
                    Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 }

                    Set-TargetResource @setTestInputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 2 -Scope It
                }

                It 'Should call expected commands when removing a boundary' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSite }
                    Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 }

                    Set-TargetResource @setTestInputRemove
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when removing a boundary group' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets
                    Mock -CommandName Get-BoundaryInfo

                    Set-TargetResource @setTestInputGroupOnlyAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands for adding a new boundary that does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd }
                    Mock -CommandName Get-BoundaryInfo -MockWith { $null }

                    { Set-TargetResource @setTestInputAddValue } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-BoundariesIPSubnets -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-BoundaryInfo -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should return desired result false when boundaries do not match with Match specified' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryRange  }

                    Test-TargetResource @setTestInputMatch | Should -Be $false
                }

                It 'Should return desired result true when boundaries contains boundary with Add specified' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet }

                    Test-TargetResource @setTestInputAdd | Should -Be $true
                }

                It 'Should return desired result false when boundaries not contains boundary with Add specified' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd }

                    Test-TargetResource @setTestInputAddValue | Should -Be $false
                }

                It 'Should return desired result false when boundaries contains boundary with Remove Specified' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSite }

                    Test-TargetResource @setTestInputRemove | Should -Be $false
                }

                It 'Should return desired result false when boundaries return null from get with boundary specified to be added' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
                    Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet }

                    Test-TargetResource @setTestInputAdd | Should -Be $false
                }

                It 'Should return desired result true when boundaries return null from get with boundary specified to be removed' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
                    Mock -CommandName Convert-BoundariesIPSubnets

                    Test-TargetResource @setTestInputRemove | Should -Be $true
                }

                It 'Should return desired result true when boundary group is present and no boundaries are specified' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
                    Mock -CommandName Convert-BoundariesIPSubnets

                    Test-TargetResource @setTestInputGroupOnly | Should -Be $true
                }

                It 'Should return desired result fase when boundary group is absent and expected to be present' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnAbsent }
                    Mock -CommandName Convert-BoundariesIPSubnets

                    Test-TargetResource @setTestInputGroupOnly | Should -Be $false
                }

                It 'Should return desired result false when boundary group is present and expected absent' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
                    Mock -CommandName Convert-BoundariesIPSubnets

                    Test-TargetResource @setTestInputGroupOnlyAbsent | Should -Be $false
                }

                It 'Should return desired result true when boundary group is absent and expected absent' {
                    Mock -CommandName Get-TargetResource -Mockwith { $getReturnAbsent }
                    Mock -CommandName Convert-BoundariesIPSubnets

                    Test-TargetResource @setTestInputGroupOnlyAbsent | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
