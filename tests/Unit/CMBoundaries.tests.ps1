[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMBoundaries'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMBoundaries'

        $inputSubnetPresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
        }

        $inputSubnetAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.0/24'
            Ensure      = 'Absent'
        }

        $inputRangePresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Range 1'
            Type        = 'IPRange'
            Value       = '10.1.1.1-10.1.1.255'
        }

        $inputAdSitePresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Site 1'
            Type        = 'ADSite'
            Value       = 'Default-First-Site'
        }

        $inputAdSiteAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = 'Site 1'
            Type        = 'ADSite'
            Value       = 'Default-First-Site'
            Ensure      = 'Absent'
        }

        $inputVPNPresent = @{
            SiteCode    = 'Lab'
            DisplayName = 'VPN 1'
            Type        = 'VPN'
            Value       = 'Auto:On'
        }

        $inputIPv6Present = @{
            SiteCode    = 'Lab'
            DisplayName = 'IPv6 1'
            Type        = 'IPv6Prefix'
            Value       = '2001:0DB8:0000:000b'
        }

        $boundaryVPNReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 4
                DisplayName  = 'VPN 1'
                Value        = 'Auto:On'
            }
        )

        $boundaryIPv6Return = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 2
                DisplayName  = 'IPv6 1'
                Value        = '2001:0DB8:0000:000b'
            }
        )

        $boundarySubnetReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 0
                DisplayName  = 'Test Subnet'
                Value        = '10.1.1.0'
            }
        )

        $boundaryAdSiteReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 1
                DisplayName  = 'Test Site'
                Value        = 'Default-First-Site'
            }
        )

        $boundaryRangeReturn = @(
            @{
                BoundaryId   = 1677726
                BoundaryType = 3
                DisplayName  = 'Test Range'
                Value        = '10.1.1.1-10.1.1.255'
            }
        )

        $getSubnetReturnMatch = @{
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Value       = '10.1.1.0'
            Type        = 'IPSubnet'
            Ensure      = 'Present'
            BoundaryId  = '1677726'
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

        $getSubnetReturnAbsent = @{
            SiteCode    = 'Lab'
            DisplayName = $null
            Value       = $null
            Type        = $null
            Ensure      = 'Absent'
            BoundaryId  = $null
        }

        $convert = @{
            Cidr           = 24
            SubnetMask     = '255.255.255.0'
            NetworkAddress = '10.1.1.0'
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving client settings' {

                It 'Should return desired result for Subnet return' {
                    Mock -CommandName Get-CMBoundary -MockWith { $boundarySubnetReturn }
                    Mock -CommandName Convert-CidrToIP -MockWith { $convert }

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
                    Mock -CommandName Get-CMBoundary -MockWith { $boundaryRangeReturn }

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
                    Mock -CommandName Get-CMBoundary -MockWith { $boundaryAdSiteReturn }

                    $result = Get-TargetResource @inputAdSitePresent
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.DisplayName | Should -Be -ExpectedValue 'Test Site'
                    $result.Value       | Should -Be -ExpectedValue 'Default-First-Site'
                    $result.Type        | Should -Be -ExpectedValue 'ADSite'
                    $result.Ensure      | Should -Be -ExpectedValue 'Present'
                    $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
                }

                It 'Should return desired result for VPN return' {
                    Mock -CommandName Get-CMBoundary -MockWith { $boundaryVPNReturn }

                    $result = Get-TargetResource @inputVPNPresent
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.DisplayName | Should -Be -ExpectedValue 'VPN 1'
                    $result.Value       | Should -Be -ExpectedValue 'Auto:On'
                    $result.Type        | Should -Be -ExpectedValue 'VPN'
                    $result.Ensure      | Should -Be -ExpectedValue 'Present'
                    $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
                }

                It 'Should return desired result for IPv6 return' {
                    Mock -CommandName Get-CMBoundary -MockWith { $boundaryIPv6Return }

                    $result = Get-TargetResource @inputIPv6Present
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.DisplayName | Should -Be -ExpectedValue 'IPv6 1'
                    $result.Value       | Should -Be -ExpectedValue '2001:0DB8:0000:000b'
                    $result.Type        | Should -Be -ExpectedValue 'IPv6Prefix'
                    $result.Ensure      | Should -Be -ExpectedValue 'Present'
                    $result.BoundaryId  | Should -Be -ExpectedValue '1677726'
                }

                It 'Should return desired result when boundary not found' {
                    Mock -CommandName Get-CMBoundary -MockWith { $null }

                    $result = Get-TargetResource @inputAdSitePresent
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.DisplayName | Should -Be -ExpectedValue $null
                    $result.Value       | Should -Be -ExpectedValue 'Default-First-Site'
                    $result.Type        | Should -Be -ExpectedValue 'AdSite'
                    $result.Ensure      | Should -Be -ExpectedValue 'Absent'
                    $result.BoundaryId  | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMBoundary
                Mock -CommandName Set-CMBoundary
                Mock -CommandName Remove-CMBoundary

                It 'Should call expected commands for adding a new boundary' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent }

                    Set-TargetResource @inputSubnetPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundary -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundary -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for changing boundary name' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName }

                    Set-TargetResource @inputSubnetPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMBoundary -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundary -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for removing a boundary' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAdSiteReturnName }

                    Set-TargetResource @inputAdSiteAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundary -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMBoundary
                Mock -CommandName Set-CMBoundary
                Mock -CommandName Remove-CMBoundary

                It 'Should call expected commands when Remove-CMBoundary throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAdSiteReturnName }
                    Mock -CommandName Remove-CMBoundary -MockWith { throw }

                    { Set-TargetResource @inputAdSiteAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMBoundary -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when present and Set-CMBoundary throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName }
                    Mock -CommandName Set-CMBoundary -MockWith { throw }

                    { Set-TargetResource @inputSubnetPresent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMBoundary -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMBoundary -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMBoundary -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true when ensure = present and boundary exists' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnMatch }

                    Test-TargetResource @inputSubnetPresent | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and boundary has differnt name' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnName }

                    Test-TargetResource @inputSubnetPresent | Should -Be $false
                }

                It 'Should return desired result false when ensure = present and boundary is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent }

                    Test-TargetResource @inputSubnetPresent | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and boundary is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnAbsent }

                    Test-TargetResource @inputSubnetAbsent | Should -Be $true
                }

                It 'Should return desired result false when ensure = absent and boundary is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getSubnetReturnMatch }

                    Test-TargetResource @inputSubnetAbsent | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
