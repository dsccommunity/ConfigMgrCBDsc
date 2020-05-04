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

        $getBoundaryGroup = @{
            GroupID = 123456
            Name    = 'TestGroup'
        }

        $getBoundaryMembers = @(
            @{
                DisplayName = 'TB1'
            }
            @{
                DisplayName = 'TB2'
            }
        )

        $boundaryGroupGetInput = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
        }

        $boundaryGroupInputPresent = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = 'TB1','TB2'
            Ensure        = 'Present'
        }

        $boundaryGroupInputAbsent = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Absent'
        }

        $boundaryGroupInclude = @{
            SiteCode            = 'Lab'
            BoundaryGroup       = 'TestGroup'
            BoundariesToInclude = @('TB3','TB4')
            Ensure              = 'Present'
        }

        $boundaryGroupIncludeMatch = @{
            SiteCode            = 'Lab'
            BoundaryGroup       = 'TestGroup'
            BoundariesToInclude = @('TB1','TB2')
            Ensure              = 'Present'
        }

        $boundaryGroupExclude = @{
            SiteCode            = 'Lab'
            BoundaryGroup       = 'TestGroup'
            BoundariesToExclude = @('TB3','TB4')
            Ensure              = 'Present'
        }

        $boundaryGroupExcludeMatch = @{
            SiteCode            = 'Lab'
            BoundaryGroup       = 'TestGroup'
            BoundariesToExclude = @('TB1','TB2')
            Ensure              = 'Present'
        }

        $getTargetExpected = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = @('TB1','TB2')
            Ensure        = 'Present'
        }

        $getTargetAbsent = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Absent'
        }

        $getTargetBoundaries1 = @{
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = @('TB2','TB3')
            Ensure        = 'Present'
        }

        $compareObject = @(
            @{
                InputObject   = 'TB2'
                SideIndicator = '<='
            }
            @{
                InputObject   = 'TB3'
                SideIndicator = '=='
            }
        )

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving boundary group settings' {

                It 'Should return desired result for boundary group return' {
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroup }

                    $result = Get-TargetResource @boundaryGroupGetInput
                    $result               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries    | Should -Be -ExpectedValue @('TB1','TB2')
                    $result.Ensure        | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when boundaries is absent' {
                    Mock -CommandName Get-CMBoundary -MockWith { $null }
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroup }

                    $result = Get-TargetResource @boundaryGroupGetInput
                    $result               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries    | Should -Be -ExpectedValue $null
                    $result.Ensure        | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when boundary group is absent' {
                    Mock -CommandName Get-CMBoundary -MockWith { $null }
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $null }

                    $result = Get-TargetResource @boundaryGroupGetInput
                    $result               | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
                    $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
                    $result.Boundaries    | Should -Be -ExpectedValue $null
                    $result.Ensure        | Should -Be -ExpectedValue 'Absent'
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

                It 'Should call expected commands for adding a boundary group and boundaries' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetAbsent }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object

                    Set-TargetResource @boundaryGroupInputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 2 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for adding a new boundaries to the group' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetBoundaries1  }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object -MockWith { $compareObject }

                    Set-TargetResource @boundaryGroupInputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when boundaries match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object

                    Set-TargetResource @boundaryGroupInputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when include boundaries do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object

                    Set-TargetResource @boundaryGroupInclude
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 2 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when exclude boundaries match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object -MockWith { $compareObject }

                    Set-TargetResource @boundaryGroupExcludeMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when exclude boundaries match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName Compare-Object

                    Set-TargetResource @boundaryGroupInputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for removing a boundary group' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary

                    Set-TargetResource @boundaryGroupInputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 1 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when ensure = absent and boundary group is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetAbsent }
                    Mock -CommandName Get-CMBoundary

                    Set-TargetResource @boundaryGroupInputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMBoundaryGroup
                Mock -CommandName Add-CMBoundaryToGroup
                Mock -CommandName Remove-CMBoundaryGroup
                Mock -CommandName Compare-Object
                Mock -CommandName Remove-CMBoundaryFromGroup

                It 'Should call expected commands when Remove-CMBoundary throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }
                    Mock -CommandName Get-CMBoundary
                    Mock -CommandName Remove-CMBoundaryGroup -MockWith { throw }

                    { Set-TargetResource @boundaryGroupInputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when boundaries do not match and CMBoundary returns null' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetBoundaries1 }
                    Mock -CommandName Get-CMBoundary -MockWith { $null }

                    { Set-TargetResource @boundaryGroupInputPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for boundary group and boundaries when boundary group throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetAbsent }
                    Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryMembers }
                    Mock -CommandName New-CMBoundaryGroup -MockWith { throw }

                    { Set-TargetResource @boundaryGroupInputPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundaryGroup -Exactly  -Times 1 -Scope It
                    Assert-MockCalled Get-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMBoundaryToGroup -Exactly -Times 0 -Scope It
                    Assert-MockCalled Compare-Object -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryFromGroup -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundaryGroup -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true when ensure = present and boundary group matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupInputPresent | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and boundary group is missing' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetAbsent }

                    Test-TargetResource @boundaryGroupInputPresent | Should -Be $false
                }

                It 'Should return desired result false when ensure = present and boundaries are mismatched' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetBoundaries1 }

                    Test-TargetResource @boundaryGroupInputPresent | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and boundary group is missing' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetAbsent }

                    Test-TargetResource @boundaryGroupInputAbsent | Should -Be $true
                }

                It 'Should return desired result false when ensure = absent and boundary group is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupInputAbsent | Should -Be $false
                }

                It 'Should return desired results true when ensure = present and exclude membership has no matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupExclude | Should -Be $true
                }

                It 'Should return desired results false when ensure = present and exclude membership has matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupExcludeMatch | Should -Be $false
                }

                It 'Should return desired results false when ensure = present and membership has no matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupInclude | Should -Be $false
                }

                It 'Should return desired results true when ensure = present and exclude membership matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetExpected }

                    Test-TargetResource @boundaryGroupIncludeMatch | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
