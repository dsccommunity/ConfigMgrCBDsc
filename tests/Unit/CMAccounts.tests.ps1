[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'CMAccounts'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'), '-q')
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {

        # Import Stub function
        $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

        $moduleResourceName = 'ConfigMgrCBDsc - ClientSettings'

        $testCredential = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'DummyUsername', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $getCmAccounts = @{
            SiteCode  = 'Lab'
            Account = 'TestUser1'
        }

        $cmAccountNull_Present = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser3'
            Ensure   = 'Present'
            AccountPassword = $testCredential
        }

        $cmAccountNull_Absent = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser3'
            Ensure   = 'Absent'
            AccountPassword = $testCredential
        }

        $cmAccountExists_Present = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser1'
            Ensure   = 'Present'
            AccountPassword = $testCredential
        }

        $cmAccountExists_Absent = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser1'
            Ensure   = 'Absent'
            AccountPassword = $testCredential
        }

        $cmAccountExists_AbsentNoCred = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser1'
            Ensure   = 'Absent'
        }

        $cmAccountPresentNoCred = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser3'
            Ensure   = 'Present'
        }

        $cmAccounts = @(
            @{
                UserName = 'DummyUser1'
                ItemType = 'User'
            }
            @{
                UserName = 'DummyUser2'
                ItemType = 'User'
            }
        )

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving client settings' {

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    $result = Get-TargetResource @getCmAccounts
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.CurrentAccounts | Should -Be -ExpectedValue @('DummyUser1','DummyUser2')
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    $result = Get-TargetResource @getCmAccounts
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.CurrentAccounts | Should -Be -ExpectedValue $null
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMAccount
                Mock -CommandName Remove-CMAccount

                It 'Should call expected commands for adding a new account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountNull_Present
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for removing an existing account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_Absent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for removing an existing account no creds specified' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_AbsentNoCred
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when account is already in desired state' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_Present
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMAccount
                Mock -CommandName Remove-CMAccount

                It 'Should Throw when Creds are not specified when adding an account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    { Set-TargetResource @cmAccountPresentNoCred } | Should -Throw -ExpectedMessage "When adding an account a password must be specified"

                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should throw when an error is returned from New-CMAccount' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                    Mock -CommandName New-CMAccount -MockWith { throw 'error' }

                    { Set-TargetResource @cmAccountNull_Present } | Should -Throw

                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should throw when an error is returned from Remove-CMAccount' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                    Mock -CommandName Remove-CMAccount -MockWith { throw 'error' }

                    { Set-TargetResource @cmAccountExists_Absent } | Should -Throw

                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource where Get-CMAccounts has accounts' {
                Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                It 'Should return desired result true when ensure = present and account exists' {
                    Test-TargetResource @cmAccountExists_Present | Should -Be $true
                }

                It 'Should return desired result true when ensure = absent and account does not exist' {
                    Test-TargetResource @cmAccountNull_Absent | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and account does not exist' {
                    Test-TargetResource @cmAccountNull_Present | Should -Be $false
                }

                It 'Should return desired result false when ensure = absent and account does not exist' {
                    Test-TargetResource @cmAccountExists_Absent | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource where Get-CMAccounts returned null' {
                Mock -CommandName Get-CMAccount -MockWith { $null }

                It 'Should return desired result false when ensure = present' {
                    Test-TargetResource @cmAccountNull_Present | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent' {
                    Test-TargetResource @cmAccountNull_Absent | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
