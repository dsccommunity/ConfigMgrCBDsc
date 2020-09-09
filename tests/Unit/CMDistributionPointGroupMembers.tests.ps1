[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMDistributionPointGroupMembers'

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
        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPointGroupMembers\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $distroPoint = @{
                    NetworkOSPath = '\\DP01.contoso.com'
                    RoleName      = 'SMS Distribution Point'
                    SiteCode      = 'LAB'
                }

                $distroGroups = @(
                    @{
                        Description = 'TestGroup'
                        Name        = 'TestGroup'
                    }
                    @{
                        Description = 'TestGroup1'
                        Name        = 'TestGroup1'
                    }
                    @{
                        Description = 'TestGroup2'
                        Name        = 'TestGroup2'
                    }
                )

                $distroReturn = @(
                    @{
                        NetworkOSPath = '\\DP01.contoso.com'
                        RoleName      = 'SMS Distribution Point'
                        SiteCode      = 'LAB'
                    }
                    @{
                        NetworkOSPath = '\\DP02.contoso.com'
                        RoleName      = 'SMS Distribution Point'
                        SiteCode      = 'LAB'
                    }
                )

                $getInput = @{
                    SiteCode          = 'Lab'
                    DistributionPoint = 'DP01.contoso.com'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Distribution Point Group Members' {

                It 'Should return desired result when Distribution Point has group members' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $distroPoint } -ParameterFilter { $SiteSystemServerName -eq 'DP01.contoso.com' }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distroGroups }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $distroReturn } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup' }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $distroReturn } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup1' }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup2' }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionPoint  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.DistributionGroups | Should -Be -ExpectedValue 'TestGroup','TestGroup1'
                    $result.DPStatus           | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when Distribution Point has no group members' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $distroPoint } -ParameterFilter { $SiteSystemServerName -eq 'DP01.contoso.com' }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distroGroups }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup' }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup1' }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $DistributionPointGroupName -eq 'TestGroup2' }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionPoint  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.DistributionGroups | Should -Be -ExpectedValue $null
                    $result.DPStatus           | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when currently not a Distribution Point' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $SiteSystemServerName -eq 'DP01.contoso.com' }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionPoint  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.DistributionGroups | Should -Be -ExpectedValue $null
                    $result.DPStatus           | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPointGroupMembers\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $dpAbsent = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = $null
                    DPStatus           = 'Absent'
                }

                $dpReturnPresent = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = 'TestGroup1','TestGroup3'
                    DPStatus           = 'Present'
                }

                $groupInput = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = 'TestGroup1','TestGroup2'
                }

                $groupInputMatch = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = 'TestGroup1','TestGroup3'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Remove-CMDistributionPointFromGroup
            }

            Context 'When Set-TargetResource runs successfully when get returns absent' {
                BeforeEach {
                    $includeOnly = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToInclude = 'TestGroup2'
                    }

                    $excludeOnly = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToExclude = 'TestGroup1'
                    }

                    Mock -CommandName Add-DPToDPGroup -MockWith { $true }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $true }
                }

                It 'Should call expected commands when groups match' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Set-TargetResource @groupInputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when groups do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Set-TargetResource @groupInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when using Include groups do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Set-TargetResource @includeOnly
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when using exclude groups and have a match' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Set-TargetResource @excludeOnly
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $includeExclude = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToInclude = 'TestGroup1'
                        DistributionGroupsToExclude = 'TestGroup1'
                    }

                    $dpGroupAddError = "Unable to add the Distribution Point: DP01.contoso.com to Group: TestGroup2."
                    Mock -CommandName Add-DPToDPGroup
                }

                It 'Should call expected commands when DP is absent and throws' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $null }
                    Mock -CommandName Get-TargetResource -MockWith { $dpAbsent }

                    { Set-TargetResource @groupInputMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when Include and Exclude contain same group and throws' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $null }
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    { Set-TargetResource @includeExclude } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when mismatch and group does not exist' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $null }
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    { Set-TargetResource @groupInput } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when DP errors while adding to group' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $true }
                    Mock -CommandName Add-DPToDPGroup -MockWith { $false }

                    { Set-TargetResource @groupInput } | Should -Throw -ExpectedMessage $dpGroupAddError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-DPToDPGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPointGroupMembers\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $dpAbsent = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = $null
                    DPStatus           = 'Absent'
                }

                $dpReturnPresent = @{
                    SiteCode           = 'Lab'
                    DistributionPoint  = 'DP01.contoso.com'
                    DistributionGroups = 'TestGroup1','TestGroup3'
                    DPStatus           = 'Present'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource and get returns present' {
                BeforeEach {
                    $groupInputMatch = @{
                        SiteCode           = 'Lab'
                        DistributionPoint  = 'DP01.contoso.com'
                        DistributionGroups = 'TestGroup1','TestGroup3'
                    }

                    $groupInput = @{
                        SiteCode           = 'Lab'
                        DistributionPoint  = 'DP01.contoso.com'
                        DistributionGroups = 'TestGroup1','TestGroup2'
                    }

                    $allOptions = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroups          = 'TestGroup1','TestGroup2'
                        DistributionGroupsToInclude = 'Test1'
                        DistributionGroupsToExclude = 'Test2'
                    }

                    $includeExclude = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToInclude = 'TestGroup1'
                        DistributionGroupsToExclude = 'TestGroup1'
                    }

                    $noGroupsSpecified = @{
                        SiteCode          = 'Lab'
                        DistributionPoint = 'DP01.contoso.com'
                    }

                    $includeOnly = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToInclude = 'TestGroup2'
                    }

                    $excludeOnly = @{
                        SiteCode                    = 'Lab'
                        DistributionPoint           = 'DP01.contoso.com'
                        DistributionGroupsToExclude = 'TestGroup1'
                    }
                }

                It 'Should return desired result false when Distribution Point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpAbsent }

                    Test-TargetResource @groupInput | Should -Be $false
                }

                It 'Should return desired result true when group input matches return' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @groupInputMatch | Should -Be $true
                }

                It 'Should return desired result false when match, include, and exclude are specified and settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @allOptions | Should -Be $false
                }

                It 'Should return desired result false when include and exclude are specified with the same value' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @includeExclude | Should -Be $false
                }

                It 'Should return desired result false when include does not match Distribution Groups' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @includeOnly | Should -Be $false
                }

                It 'Should return desired result false when Distribution Groups contains excluded group' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @excludeOnly | Should -Be $false
                }

                It 'Should return desired result true when Distribution Point is present and no groups specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $dpReturnPresent }

                    Test-TargetResource @noGroupsSpecified | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
