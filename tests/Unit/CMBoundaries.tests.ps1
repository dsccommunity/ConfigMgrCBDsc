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
        DSCResourceName = 'DSC_CMBoundaries'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMBoundaries\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $boundarySubnetReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 0
                DisplayName  = 'Test Subnet'
                Value        = '10.1.1.0'
            }
        )

        $convert = @{
            Cidr           = 24
            SubnetMask     = '255.255.255.0'
            NetworkAddress = '10.1.1.0'
        }

        $inputSubnetPresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
        }

        $boundaryRangeReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 3
                DisplayName  = 'Test Range'
                Value        = '10.1.1.1-10.1.1.255'
            }
        )

        $inputRangePresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Range 1'
            Type        = 'IPRange'
            Value       = '10.1.1.1-10.1.1.255'
        }

        $boundaryAdSiteReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 1
                DisplayName  = 'Test Site'
                Value        = 'Default-First-Site'
            }
        )

        $inputAdSitePresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Site 1'
            Type        = 'ADSite'
            Value       = 'Default-First-Site'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries
        Mock -CommandName Set-Location -ModuleName DSC_CMBoundaries
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving client settings' {
        It 'Should return desired result for Subnet return' {
            Mock -CommandName Get-CMBoundary -MockWith { $boundarySubnetReturn } -ModuleName DSC_CMBoundaries
            Mock -CommandName Convert-CidrToIP -MockWith { $convert } -ModuleName DSC_CMBoundaries

            $result = Get-TargetResource @inputSubnetPresent
            $result             | Should -BeOfType System.Collections.HashTable
            $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
            $result.DisplayName | Should -Be -ExpectedValue 'Test Subnet'
            $result.Value       | Should -Be -ExpectedValue '10.1.1.0'
            $result.Type        | Should -Be -ExpectedValue 'IPSubnet'
            $result.Ensure      | Should -Be -ExpectedValue 'Present'
            $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
        }

        It 'Should return desired result for IPRange return' {
            Mock -CommandName Get-CMBoundary -MockWith { $boundaryRangeReturn } -ModuleName DSC_CMBoundaries

            $result = Get-TargetResource @inputRangePresent
            $result             | Should -BeOfType System.Collections.HashTable
            $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
            $result.DisplayName | Should -Be -ExpectedValue 'Test Range'
            $result.Value       | Should -Be -ExpectedValue '10.1.1.1-10.1.1.255'
            $result.Type        | Should -Be -ExpectedValue 'IPRange'
            $result.Ensure      | Should -Be -ExpectedValue 'Present'
            $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
        }

        It 'Should return desired result for AdSite return' {
            Mock -CommandName Get-CMBoundary -MockWith { $boundaryAdSiteReturn } -ModuleName DSC_CMBoundaries

            $result = Get-TargetResource @inputAdSitePresent
            $result             | Should -BeOfType System.Collections.HashTable
            $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
            $result.DisplayName | Should -Be -ExpectedValue 'Test Site'
            $result.Value       | Should -Be -ExpectedValue 'Default-First-Site'
            $result.Type        | Should -Be -ExpectedValue 'ADSite'
            $result.Ensure      | Should -Be -ExpectedValue 'Present'
            $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
        }

        It 'Should return desired result when boundary not found' {
            Mock -CommandName Get-CMBoundary -ModuleName DSC_CMBoundaries

            $result = Get-TargetResource @inputAdSitePresent
            $result             | Should -BeOfType System.Collections.HashTable
            $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
            $result.DisplayName | Should -BeNullOrEmpty
            $result.Value       | Should -Be -ExpectedValue 'Default-First-Site'
            $result.Type        | Should -Be -ExpectedValue 'AdSite'
            $result.Ensure      | Should -Be -ExpectedValue 'Absent'
            $result.BoundaryId  | Should -BeNullOrEmpty
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMBoundaries\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $inputSubnetPresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
        }

        $getSubnetReturnAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = $null
            Value       = $null
            Type        = $null
            Ensure      = 'Absent'
            BoundaryId  = $null
        }

        $getSubnetReturnName = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 2'
            Value       = '10.1.1.0'
            Type        = 'IPSubnet'
            Ensure      = 'Present'
            BoundaryId  = '1677726'
        }

        $getAdSiteReturnName = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 2'
            Value       = '10.1.1.0'
            Type        = 'IPSubnet'
            Ensure      = 'Present'
            BoundaryID  = '1677726'
        }

        $inputAdSiteAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Site 1'
            Type        = 'ADSite'
            Value       = 'Default-First-Site'
            Ensure      = 'Absent'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries
        Mock -CommandName Set-Location -ModuleName DSC_CMBoundaries
        Mock -CommandName New-CMBoundary -ModuleName DSC_CMBoundaries
        Mock -CommandName Set-CMBoundary -ModuleName DSC_CMBoundaries
        Mock -CommandName Remove-CMBoundary -ModuleName DSC_CMBoundaries
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }
    Context 'When Set-TargetResource runs successfully' {
        It 'Should call expected commands for adding a new boundary' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent } -ModuleName DSC_CMBoundaries

            Set-TargetResource @inputSubnetPresent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMBoundaries -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke New-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Set-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
        }

        It 'Should call expected commands for changing boundary name' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName } -ModuleName DSC_CMBoundaries

            Set-TargetResource @inputSubnetPresent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries -Exactly -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMBoundaries -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke New-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Set-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
        }

        It 'Should call expected commands for removing a boundary' {
            Mock -CommandName Get-TargetResource -MockWith { $getAdSiteReturnName } -ModuleName DSC_CMBoundaries

            Set-TargetResource @inputAdSiteAbsent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMBoundaries -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke New-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Set-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
        }
    }

    Context 'When Set-TargetResource throws' {
        It 'Should call expected commands when Remove-CMBoundary throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getAdSiteReturnName } -ModuleName DSC_CMBoundaries
            Mock -CommandName Remove-CMBoundary -MockWith { throw } -ModuleName DSC_CMBoundaries

            { Set-TargetResource @inputAdSiteAbsent } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMBoundaries -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke New-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Set-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Remove-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
        }

        It 'Should call expected commands when present and Set-CMBoundary throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName } -ModuleName DSC_CMBoundaries
            Mock -CommandName Set-CMBoundary -MockWith { throw } -ModuleName DSC_CMBoundaries

            { Set-TargetResource @inputSubnetPresent } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Set-Location -ModuleName DSC_CMBoundaries -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke New-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
            Should -Invoke Set-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 1 -Scope It
            Should -Invoke Remove-CMBoundary -ModuleName DSC_CMBoundaries -Exactly 0 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMBoundaries\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $inputSubnetAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
            Ensure      = 'Absent'
        }

        $getSubnetReturnMatch = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Value       = '10.1.1.0'
            Type        = 'IPSubnet'
            Ensure      = 'Present'
            BoundaryId  = '1677726'
        }

        $inputSubnetPresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
        }

        $getSubnetReturnName = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 2'
            Value       = '10.1.1.0'
            Type        = 'IPSubnet'
            Ensure      = 'Present'
            BoundaryId  = '1677726'
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMBoundaries
        Mock -CommandName Set-Location -ModuleName DSC_CMBoundaries
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource' {
        It 'Should return desired result true when ensure = present and boundary exists' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnMatch } -ModuleName DSC_CMBoundaries

            Test-TargetResource @inputSubnetPresent | Should -BeTrue
        }

        It 'Should return desired result false when ensure = present and boundary has differnt name' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName } -ModuleName DSC_CMBoundaries

            Test-TargetResource @inputSubnetPresent | Should -BeFalse
        }

        It 'Should return desired result false when ensure = present and boundary is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent } -ModuleName DSC_CMBoundaries

            Test-TargetResource @inputSubnetPresent | Should -BeFalse
        }

        It 'Should return desired result true when ensure = absent and boundary is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent } -ModuleName DSC_CMBoundaries

            Test-TargetResource @inputSubnetAbsent | Should -BeTrue
        }

        It 'Should return desired result false when ensure = absent and boundary is present' {
            Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnMatch } -ModuleName DSC_CMBoundaries

            Test-TargetResource @inputSubnetAbsent | Should -BeFalse
        }
    }
}
