[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

try
{
    $dscModuleName   = 'ConfigMgrCBDsc'
    $dscResourceName = 'DSC_CMAccounts'

    $testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $dscModuleName `
        -DSCResourceName $dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    BeforeAll {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMClientAccounts'

        # Import Stub function
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

        try
        {
            Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
        }
        catch [System.IO.FileNotFoundException]
        {
            throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
        }

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
    }

    Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

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
                    Mock -CommandName Get-CMAccount

                    $result = Get-TargetResource @getCmAccounts
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.CurrentAccounts | Should -BeNullOrEmpty
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }
            }
        }
    }

    Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMAccount
                Mock -CommandName Remove-CMAccount
            }
            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands for adding a new account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountNull_Present
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
                }

                It 'Should call expected commands for removing an existing account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_Absent
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
                }

                It 'Should call expected commands for removing an existing account no creds specified' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_AbsentNoCred
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
                }

                It 'Should call expected commands for when account is already in desired state' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    Set-TargetResource @cmAccountExists_Present
                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {

                It 'Should Throw when Creds are not specified when adding an account' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    { Set-TargetResource @cmAccountPresentNoCred } | Should -Throw -ExpectedMessage "When adding an account a password must be specified"

                    Should -Invoke Import-ConfigMgrPowerShellModule 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
                }

                It 'Should throw when an error is returned from New-CMAccount' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                    Mock -CommandName New-CMAccount -MockWith { throw 'error' }

                    { Set-TargetResource @cmAccountNull_Present } | Should -Throw

                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 1 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
                }

                It 'Should throw when an error is returned from Remove-CMAccount' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                    Mock -CommandName Remove-CMAccount -MockWith { throw 'error' }

                    { Set-TargetResource @cmAccountExists_Absent } | Should -Throw

                    Should -Invoke Import-ConfigMgrPowerShellModule -Exactly 1 -Scope It
                    Should -Invoke Set-Location -Exactly 2 -Scope It
                    Should -Invoke Get-CMAccount -Exactly 1 -Scope It
                    Should -Invoke New-CMAccount -Exactly 0 -Scope It
                    Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
                }
            }
        }
    }

    Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test' {
        InModuleScope $dscResourceName {
            BeforeAll {
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource where Get-CMAccounts has accounts' {
                BeforeAll {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                }

                It 'Should return desired result true when ensure = present and account exists' {
                    Test-TargetResource @cmAccountExists_Present | Should -BeTrue
                }

                It 'Should return desired result true when ensure = absent and account does not exist' {
                    Test-TargetResource @cmAccountNull_Absent | Should -BeTrue
                }

                It 'Should return desired result false when ensure = present and account does not exist' {
                    Test-TargetResource @cmAccountNull_Present | Should -BeFalse
                }

                It 'Should return desired result false when ensure = absent and account does not exist' {
                    Test-TargetResource @cmAccountExists_Absent | Should -BeFalse
                }
            }

            Context 'When running Test-TargetResource where Get-CMAccounts returned null' {
                BeforeAll {
                    Mock -CommandName Get-CMAccount
                }

                It 'Should return desired result false when ensure = present' {
                    Test-TargetResource @cmAccountNull_Present | Should -BeFalse
                }

                It 'Should return desired result true when ensure = absent' {
                    Test-TargetResource @cmAccountNull_Absent | Should -BeTrue
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}
