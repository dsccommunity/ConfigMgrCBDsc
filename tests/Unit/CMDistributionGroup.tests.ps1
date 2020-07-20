[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMDistributionGroup'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction 'SilentlyContinue'

    # Import DscResource.Test Module
try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

# Variables used for each Initialize-TestEnvironment
$testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'ConfigMgrCBDsc - DSC_CMDistributionGroup\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $distributionPointGroup = @{
                    MemberCount = 0
                    Name        = 'Group1'
                    SourceSite  = 'LAB'
                }

                $distributionPoint = @(
                    @{
                        NetworkOSPath = '\\DP01.contoso.com'
                        SiteCode      = 'LAB'
                    }
                    @{
                        NetworkOSPath = '\\DP02.contoso.com'
                        SiteCode      = 'LAB'
                    }
                )

                $cmObjectsReturn = @(
                    @{
                        CategoryName    = 'Scope1'
                        NumberOfAdmins  = 1
                        NumberOfObjects = 1
                    }
                    @{
                        CategoryName    = 'Scope2'
                        NumberOfAdmins  = 1
                        NumberOfObjects = 1
                    }
                )

                $getInput = @{
                    SiteCode          = 'Lab'
                    DistributionGroup = 'Group1'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Distribution Group settings' {

                It 'Should return desired result when group exists and contains Distribution Points and Scopes' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $distributionPoint }
                    Mock -CommandName Get-CMObjectSecurityScope -MockWith { $cmObjectsReturn }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionGroup  | Should -Be -ExpectedValue 'Group1'
                    $result.DistributionPoints | Should -Be -ExpectedValue 'DP01.contoso.com','DP02.contoso.com'
                    $result.SecurityScopes     | Should -Be -ExpectedValue 'Scope1','Scope2'
                    $result.Ensure             | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when group exists and does not contain Distribution Points or Scopes' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null }
                    Mock -CommandName Get-CMObjectSecurityScope -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionGroup  | Should -Be -ExpectedValue 'Group1'
                    $result.DistributionPoints | Should -Be -ExpectedValue $null
                    $result.SecurityScopes     | Should -Be -ExpectedValue $null
                    $result.Ensure             | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when group is absent' {
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $null }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null }
                    Mock -CommandName Get-CMObjectSecurityScope -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                    | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode           | Should -Be -ExpectedValue 'Lab'
                    $result.DistributionGroup  | Should -Be -ExpectedValue 'Group1'
                    $result.DistributionPoints | Should -Be -ExpectedValue $null
                    $result.SecurityScopes     | Should -Be -ExpectedValue $null
                    $result.Ensure             | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionGroup\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnPresent = @{
                    SiteCode           = 'Lab'
                    DistributionGroup  = 'Group1'
                    DistributionPoints = @('DP01.contoso.com','DP02.contoso.com')
                    SecurityScopes     = @('Scope1','Scope2')
                    Ensure             = 'Present'
                }

                $groupPresentMatch = @{
                    SiteCode           = 'Lab'
                    DistributionGroup  = 'Group1'
                    DistributionPoints = 'DP03.contoso.com'
                    SecurityScopes     = 'Scope3'
                }

                $groupPresent = @{
                    SiteCode          = 'Lab'
                    DistributionGroup = 'Group1'
                    Ensure            = 'Present'
                }

                $groupPresentAddMultiple = @{
                    SiteCode                    = 'Lab'
                    DistributionGroup           = 'Group1'
                    DistributionPointsToInclude = 'DP03.contoso.com','DP04.contoso.com'
                    SecurityScopesToInclude     = 'Scope3','Scope4'
                }

                $scopesAddMultiple = @{
                    SiteCode                = 'Lab'
                    DistributionGroup       = 'Group1'
                    SecurityScopesToInclude = 'Scope3','Scope4'
                }

                $distributionPointGroup = @{
                    MemberCount = 0
                    Name        = 'Group1'
                    SourceSite  = 'LAB'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMDistributionPointGroup
                Mock -CommandName Add-CMDistributionPointToGroup
                Mock -CommandName Remove-CMDistributionPointFromGroup
                Mock -CommandName Remove-CMDistributionPointGroup
                Mock -CommandName Add-CMObjectSecurityScope
                Mock -CommandName Remove-CMObjectSecurityScope
            }

            Context 'When Set-TargetResource runs successfully when get returns absent' {
                BeforeEach {
                    $getReturnAbsent = @{
                        SiteCode           = 'Lab'
                        DistributionGroup  = 'Group1'
                        DistributionPoints = $null
                        Ensure             = 'Absent'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should call expected commands when adding a Distribution Point Group' {
                    Mock -CommandName Get-CMDistributionPoint
                    Mock -CommandName Get-CMDistributionPointGroup
                    Mock -CommandName Get-CMSecurityScope

                    Set-TargetResource @groupPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when adding a Distribution Point Group and Distribution Points' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $true }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    Set-TargetResource @groupPresentMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource runs successfully when get returns present' {
                BeforeEach {
                    $groupAbsent = @{
                        SiteCode          = 'Lab'
                        DistributionGroup = 'Group1'
                        Ensure            = 'Absent'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                }

                It 'Should call expected commands when adding and removing Distribution Points and Scopes to groups' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $true }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    Set-TargetResource @groupPresentMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when removing Distribution Point Group' {
                    Mock -CommandName Get-CMDistributionPoint
                    Mock -CommandName Get-CMDistributionPointGroup
                    Mock -CommandName Get-CMSecurityScope

                    Set-TargetResource @groupAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when adding multiple Distribution Points and Scopes to the group' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $true }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    Set-TargetResource @groupPresentAddMultiple
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $includeExclude = @{
                        SiteCode                    = 'Lab'
                        DistributionGroup           = 'Group1'
                        DistributionPointsToExclude = 'DP02.contoso.com'
                        DistributionPointsToInclude = 'DP02.contoso.com'
                        Ensure                      = 'Present'
                    }

                    $scopesIncludeExclude = @{
                        SiteCode                = 'Lab'
                        DistributionGroup       = 'Group1'
                        SecurityScopesToInclude = 'Scope3'
                        SecurityScopesToExclude = 'Scope3'
                    }

                    $distroInEx = 'DistributionPointsToInclude and DistributionPointsToExclude contain to same entry DP02.contoso.com, remove from one of the arrays.'
                    $scopeInEx = 'SecurityScopesToInclude and SecurityScopesToExclude contain to same entry Scope3, remove from one of the arrays'
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                }

                It 'Should call expected commands when Set-CMDistributionPoint throws' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $true } -ParameterFilter { $Name -eq 'DP03.Contoso.com' }
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $null } -ParameterFilter { $Name -eq 'DP04.Contoso.com' }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    { Set-TargetResource @groupPresentAddMultiple } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when DistributionPointInclude and Exclude have the same Distribution Point' {
                    Mock -CommandName Get-CMDistributionPoint

                    { Set-TargetResource @includeExclude } | Should -Throw -ExpectedMessage $distroInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when Set-CMDistributionPoint throws with an invalid Scope' {
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $true }
                    Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionPointGroup }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }  -ParameterFilter { $Name -eq 'Scope3' }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $null } -ParameterFilter { $Name -eq 'Scope4' }

                    { Set-TargetResource @groupPresentAddMultiple } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when SecurityScopesToInclude and SecurityScopesTo have the same entry' {
                    Mock -CommandName Get-CMDistributionPoint
                    Mock -CommandName Get-CMDistributionPointGroup
                    Mock -CommandName Get-CMSecurityScope

                    { Set-TargetResource @scopesIncludeExclude } | Should -Throw -ExpectedMessage $scopeInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPointToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointFromGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionGroup\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $groupAbsent = @{
                    SiteCode          = 'Lab'
                    DistributionGroup = 'Group1'
                    Ensure            = 'Absent'
                }

                $groupPresent = @{
                    SiteCode          = 'Lab'
                    DistributionGroup = 'Group1'
                    Ensure            = 'Present'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource and get returns present' {
                BeforeEach {
                    $getReturnPresent = @{
                        SiteCode           = 'Lab'
                        DistributionGroup  = 'Group1'
                        DistributionPoints = @('DP01.contoso.com','DP02.contoso.com')
                        SecurityScopes     = @('Scope1','Scope2')
                        Ensure             = 'Present'
                    }

                    $groupPresentMatch = @{
                        SiteCode           = 'Lab'
                        DistributionGroup  = 'Group1'
                        DistributionPoints = 'DP03.contoso.com'
                        SecurityScopes     = 'Scope1'
                    }

                    $groupPresentInclude = @{
                        SiteCode                    = 'Lab'
                        DistributionGroup           = 'Group1'
                        DistributionPointsToInclude = 'DP03.contoso.com'
                    }

                    $groupPresentExclude = @{
                        SiteCode                    = 'Lab'
                        DistributionGroup           = 'Group1'
                        DistributionPointsToExclude = 'DP02.contoso.com'
                    }

                    $groupPresentWarningMatch = @{
                        SiteCode                    = 'Lab'
                        DistributionGroup           = 'Group1'
                        DistributionPoints          = 'DP02.contoso.com'
                        DistributionPointsToInclude = 'DP03.contoso.com'
                    }

                    $groupPresentScopeInclude = @{
                        SiteCode                = 'Lab'
                        DistributionGroup       = 'Group1'
                        SecurityScopesToInclude = 'Scope3'
                    }

                    $groupPresentScopeExclude = @{
                        SiteCode                = 'Lab'
                        DistributionGroup       = 'Group1'
                        SecurityScopesToExclude = 'Scope1'
                    }

                    $groupPresentScopeWarningMatch = @{
                        SiteCode                = 'Lab'
                        DistributionGroup        = 'Group1'
                        SecurityScopes          = 'Scope3'
                        SecurityScopesToInclude = 'Scope2'
                    }

                    $groupPresent = @{
                        SiteCode          = 'Lab'
                        DistributionGroup = 'Group1'
                        Ensure            = 'Present'
                    }

                    $includeExclude = @{
                        SiteCode                    = 'Lab'
                        DistributionGroup           = 'Group1'
                        DistributionPointsToExclude = 'DP02.contoso.com'
                        DistributionPointsToInclude = 'DP02.contoso.com'
                        SecurityScopesToInclude     = 'Scope1'
                        SecurityScopesToExclude     = 'Scope1'
                        Ensure                      = 'Present'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                }

                It 'Should return desired result true when setting present' {
                    Test-TargetResource @groupPresent | Should -Be $true
                }

                It 'Should return desired result false when DistributionPoints and Security Scopes do not match get' {
                    Test-TargetResource @groupPresentMatch | Should -Be $false
                }

                It 'Should return desired result false when DistributionPointsToInclude does not match get' {
                    Test-TargetResource @groupPresentInclude | Should -Be $false
                }

                It 'Should return desired result false when DistributionPointsToExclude has a match with get' {
                    Test-TargetResource @groupPresentExclude | Should -Be $false
                }

                It 'Should return desired result false when DistributionPointsToInclude and DistributionPoints does not match get' {
                    Test-TargetResource @groupPresentWarningMatch | Should -Be $false
                }

                It 'Should return desired result false when SecurityScopesToInclude does not match get' {
                    Test-TargetResource @groupPresentScopeInclude | Should -Be $false
                }

                It 'Should return desired result false when SecurityScopesToExclude has a match with get' {
                    Test-TargetResource @groupPresentScopeExclude | Should -Be $false
                }

                It 'Should return desired result false when SecurityScopesToInclude and SecurityScopes does not match get' {
                    Test-TargetResource @groupPresentScopeWarningMatch | Should -Be $false
                }

                It 'Should return desired result false when get returns present and expected absent' {
                    Test-TargetResource @groupAbsent | Should -Be $false
                }

                It 'Shoud return desired result false when DistributionPoint and Scope ToInclude and ToExclude contain the same members' {
                    Test-TargetResource @includeExclude | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and get returns absent' {
                BeforeEach {
                    $getReturnAbsent = @{
                        SiteCode           = 'Lab'
                        DistributionGroup  = 'Group1'
                        DistributionPoints = $null
                        SecurityScopes     = $null
                        Ensure             = 'Absent'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result true when get returns absent and expected absent' {
                    Test-TargetResource @groupAbsent | Should -Be $true
                }

                It 'Should return desired result false when get returns absent and expected present' {
                    Test-TargetResource @groupPresent | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
