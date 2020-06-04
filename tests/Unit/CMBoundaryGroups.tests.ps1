param ()

# Begin Testing
BeforeAll {
    # Import Stub function
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
    $initalize = @{
        DSCModuleName   = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMBoundaryGroups'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMBoundaryGroups\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving boundary group settings' {
        It 'Should return desired result when boundary group does not exist' {
            Mock -CommandName Get-CMBoundaryGroup

            $result = Get-TargetResource @getInput
            $result               | Should -BeOfType System.Collections.HashTable
            $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
            $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
            $result.Boundaries    | Should -BeNullOrEmpty
            $result.Ensure        | Should -Be -ExpectedValue 'Absent'
        }

        It 'Should return desired result when boundaries is exists and has no boundaries assoicated' {
            Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroupOutput }
            Mock -CommandName Get-CMBoundary

            $result = Get-TargetResource @getInput
            $result               | Should -BeOfType System.Collections.HashTable
            $result.SiteCode      | Should -Be -ExpectedValue 'Lab'
            $result.BoundaryGroup | Should -Be -ExpectedValue 'TestGroup'
            $result.Boundaries    | Should -BeNullOrEmpty
            $result.Ensure        | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result when boundary group exists and contains boundaries' {
            Mock -CommandName Get-CMBoundaryGroup -MockWith { $getBoundaryGroupOutput }
            Mock -CommandName Get-CMBoundary -MockWith { $getBoundaryOutput }
            Mock -CommandName ConvertTo-CimBoundaries -MockWith { $mockBoundaryMembers } -ModuleName DSC_CMBoundaryGroups

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

Describe 'ConfigMgrCBDsc - DSC_CMBoundaryGroups\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        $getReturnAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Absent'
        }

        $setTestInputAdd = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundarySubnet
            BoundaryAction = 'Add'
        }

        $getReturn = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $mockBoundaryMembers
            Ensure        = 'Present'
        }

        $setTestInputAddValue = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundaryADSiteAdd
            BoundaryAction = 'Add'
        }

        $setTestInputMatch = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundaryRange
            BoundaryAction = 'Match'
        }

        $setTestInputRemove = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundarySubnet
            BoundaryAction = 'Remove'
        }

        $setTestInputGroupOnlyAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Absent'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups
        Mock -CommandName Set-Location
        Mock -CommandName New-CMBoundaryGroup
        Mock -CommandName Add-CMBoundaryToGroup
        Mock -CommandName Remove-CMBoundaryGroup
        Mock -CommandName Remove-CMBoundaryFromGroup
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        It 'Should call expected commands for new boundary group and adding boundary' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet } -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -MockWith { return 164111 } -ModuleName DSC_CMBoundaryGroups

            Set-TargetResource @setTestInputAdd
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly 1 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 1 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 0 -Scope It
        }

        It 'Should call expected commands for adding a new boundary to the group' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd } -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 } -ModuleName DSC_CMBoundaryGroups

            Set-TargetResource @setTestInputAddValue
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly  0 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 1 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 0 -Scope It
        }

        It 'Should call expected commands for boundary set to match removing two additional boundaries' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryRange } -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 } -ModuleName DSC_CMBoundaryGroups

            Set-TargetResource @setTestInputMatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly  0 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 0 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 2 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 2 -Scope It
        }

        It 'Should call expected commands when removing a boundary' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSite } -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -MockWith { return 16411 } -ModuleName DSC_CMBoundaryGroups

            Set-TargetResource @setTestInputRemove
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 0 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 1 -Scope It
        }

        It 'Should call expected commands when removing a boundary group' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups

            Set-TargetResource @setTestInputGroupOnlyAbsent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 0 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 0 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 0 -Scope It
        }

        It 'Should throw and call expected commands for adding a new boundary that does not exist' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd } -ModuleName DSC_CMBoundaryGroups
            Mock -CommandName Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups

            { Set-TargetResource @setTestInputAddValue } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke New-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Add-CMBoundaryToGroup -Exactly 0 -Scope It
            Should -Invoke Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Get-BoundaryInfo -ModuleName DSC_CMBoundaryGroups -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundaryGroup -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundaryFromGroup -Exactly 0 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMBoundaryGroups\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize


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

        $getReturnAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Absent'
        }

        $getReturn = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $mockBoundaryMembers
            Ensure        = 'Present'
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

        $setTestInputMatch = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundaryRange
            BoundaryAction = 'Match'
        }

        $setTestInputRemove = @{
            SiteCode       = 'Lab'
            BoundaryGroup  = 'TestGroup'
            Boundaries     = $mockInputBoundarySubnet
            BoundaryAction = 'Remove'
        }

        $setTestInputGroupOnlyAbsent = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Absent'
        }

        $setTestInputGroupOnly = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Present'
        }

        $getReturnNoBoundaries = @{
            Site          = 'Lab'
            BoundaryGroup = 'TestGroup'
            Boundaries    = $null
            Ensure        = 'Present'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaryGroups
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource' {
        It 'Should return desired result false when boundaries do not match with Match specified' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryRange  } -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputMatch | Should -BeFalse
        }

        It 'Should return desired result true when boundaries contains boundary with Add specified' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet } -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputAdd | Should -BeTrue
        }

        It 'Should return desired result false when boundaries not contains boundary with Add specified' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSiteAdd } -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputAddValue | Should -BeFalse
        }

        It 'Should return desired result false when boundaries contains boundary with Remove Specified' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturn }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockInputBoundaryADSite } -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputRemove | Should -BeFalse
        }

        It 'Should return desired result false when boundaries return null from get with boundary specified to be added' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
            Mock -CommandName Convert-BoundariesIPSubnets -MockWith { $mockOutputBoundarySubnet } -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputAdd | Should -BeFalse
        }

        It 'Should return desired result true when boundaries return null from get with boundary specified to be removed' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputRemove | Should -BeTrue
        }

        It 'Should return desired result true when boundary group is present and no boundaries are specified' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputGroupOnly | Should -BeTrue
        }

        It 'Should return desired result fase when boundary group is absent and expected to be present' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnAbsent }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputGroupOnly | Should -BeFalse
        }

        It 'Should return desired result false when boundary group is present and expected absent' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnNoBoundaries }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputGroupOnlyAbsent | Should -BeFalse
        }

        It 'Should return desired result true when boundary group is absent and expected absent' {
            Mock -CommandName Get-TargetResource -Mockwith { $getReturnAbsent }
            Mock -CommandName Convert-BoundariesIPSubnets -ModuleName DSC_CMBoundaryGroups

            Test-TargetResource @setTestInputGroupOnlyAbsent | Should -BeTrue
        }
    }
}
