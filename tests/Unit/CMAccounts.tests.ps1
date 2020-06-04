[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

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
        DSCModuleName  = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMAccounts'
        ResourceType = 'Mof'
        TestType  = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getCmAccounts = @{
            SiteCode  = 'Lab'
            Account = 'TestUser1'
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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
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
Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getCmAccounts = @{
            SiteCode  = 'Lab'
            Account = 'TestUser1'
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

        $testCredential = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'DummyUsername', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $cmAccountNull_Present = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser3'
            Ensure   = 'Present'
            AccountPassword = $testCredential
        }

        $cmAccountExists_Absent = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser1'
            Ensure   = 'Absent'
            AccountPassword = $testCredential
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
        Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
        Mock -CommandName New-CMAccount
        Mock -CommandName Remove-CMAccount
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        BeforeEach {
            $cmAccountExists_Present = @{
                SiteCode = 'Lab'
                Account  = 'DummyUser1'
                Ensure   = 'Present'
                AccountPassword = $testCredential
            }

            $cmAccountExists_AbsentNoCred = @{
                SiteCode = 'Lab'
                Account  = 'DummyUser1'
                Ensure   = 'Absent'
            }
        }
        It 'Should call expected commands for adding a new account' {
            Set-TargetResource @cmAccountNull_Present

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 1 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
        }

        It 'Should call expected commands for removing an existing account' {
            Set-TargetResource @cmAccountExists_Absent

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 0 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
        }

        It 'Should call expected commands for removing an existing account no creds specified' {
            Set-TargetResource @cmAccountExists_AbsentNoCred

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 0 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
        }

        It 'Should call expected commands for when account is already in desired state' {
            Set-TargetResource @cmAccountExists_Present

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 0 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
        }
    }

    Context 'When running Set-TargetResource should throw' {
        BeforeEach {
            $cmAccountPresentNoCred = @{
                SiteCode = 'Lab'
                Account  = 'DummyUser3'
                Ensure   = 'Present'
            }
        }
        It 'Should Throw when Creds are not specified when adding an account' {
            { Set-TargetResource @cmAccountPresentNoCred } | Should -Throw -ExpectedMessage "When adding an account a password must be specified"

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 0 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
        }

        It 'Should throw when an error is returned from New-CMAccount' {
            Mock -CommandName New-CMAccount -MockWith { throw 'error' }

            { Set-TargetResource @cmAccountNull_Present } | Should -Throw

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 1 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 0 -Scope It
        }

        It 'Should throw when an error is returned from Remove-CMAccount' {
            Mock -CommandName Remove-CMAccount -MockWith { throw 'error' }

            { Set-TargetResource @cmAccountExists_Absent } | Should -Throw

            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-CMAccount -Exactly 1 -Scope It
            Should -Invoke New-CMAccount -Exactly 0 -Scope It
            Should -Invoke Remove-CMAccount -Exactly 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getCmAccounts = @{
            SiteCode  = 'Lab'
            Account = 'TestUser1'
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

        $testCredential = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'DummyUsername', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $cmAccountNull_Present = @{
            SiteCode = 'Lab'
            Account  = 'DummyUser3'
            Ensure   = 'Present'
            AccountPassword = $testCredential
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource where Get-CMAccounts has accounts' {
        BeforeEach {
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
        BeforeEach {
            $cmAccountNull_Absent = @{
                SiteCode = 'Lab'
                Account  = 'DummyUser3'
                Ensure   = 'Absent'
                AccountPassword = $testCredential
            }

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