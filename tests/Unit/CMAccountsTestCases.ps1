#[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
#param ()

# Naming for Describe blocks
$moduleResourceName = 'ConfigMgrCBDsc - DSC_CMAccounts'

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

    #region Variables used for Testing
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
    #endregion
}

Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving client settings' {
        It 'Should return desired result' -TestCases @(
                @{MockWith = $cmAccounts}
                @{MockWith = $null}
            ){
            Mock -CommandName Get-CMAccount -MockWith { $MockWith }

            $result = Get-TargetResource @getCmAccounts
            $result                 | Should -BeOfType System.Collections.HashTable
            $result.SiteCode        | Should -Be -ExpectedValue $getCmAccounts.SiteCode
            $result.Account         | Should -Be -ExpectedValue $getCmAccounts.Account
            $result.CurrentAccounts | Should -Be -ExpectedValue $MockWith.UserName
            $result.Ensure          | Should -Be -ExpectedValue 'Present'
        }
    }
}
Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
        Mock -CommandName New-CMAccount
        Mock -CommandName Remove-CMAccount
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        BeforeEach {
            Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
        }
        It 'Should call expected commands for <Title>' -TestCases @(
            @{
                Title = 'adding a new account'
                Set = $cmAccountNull_Present
                Import = 1
                SetLocation = 2
                GetCMAccount = 1
                NewCMAccount =1
                RemoveCMAccount = 0
            }
            @{
                Title = 'removing an existing account'
                Set = $cmAccountExists_Absent
                Import = 1
                SetLocation = 2
                GetCMAccount = 1
                NewCMAccount =0
                RemoveCMAccount = 1
            }
            @{
                Title = 'removing an existing account no creds specified'
                Set = $cmAccountExists_AbsentNoCred
                Import = 1
                SetLocation = 2
                GetCMAccount = 1
                NewCMAccount =0
                RemoveCMAccount = 1
            }
            @{
                Title = 'when account is already in desired state'
                Set = $cmAccountExists_Present
                Import = 1
                SetLocation = 2
                GetCMAccount = 1
                NewCMAccount =0
                RemoveCMAccount = 0
            }
        ){

            Set-TargetResource @Set
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts -Exactly $Import -Scope It
            Should -Invoke Set-Location -Exactly $SetLocation -Scope It
            Should -Invoke Get-CMAccount -Exactly $GetCMAccount -Scope It
            Should -Invoke New-CMAccount -Exactly $NewCMAccount -Scope It
            Should -Invoke Remove-CMAccount -Exactly $RemoveCMAccount -Scope It
        }
    }

    Context 'When running Set-TargetResource should throw' {
        BeforeEach {
            Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
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
    }#>
}

Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMAccounts
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource where Get-CMAccounts has accounts' {
        BeforeEach {
            Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
        }

        It 'Should return desired result <Title>' -TestCases @(
            @{Title = 'true when ensure = present and account exists'; Test = $cmAccountExists_Present; Result = $true}
            @{Title = 'true when ensure = absent and account does not exist'; Test = $cmAccountNull_Absent; Result = $true}
            @{Title = 'false when ensure = present and account does not exist'; Test = $cmAccountNull_Present; Result = $false}
            @{Title = 'false when ensure = absent and account does not exist'; Test = $cmAccountExists_Absent; Result = $false}
        ){
            Test-TargetResource @Test | Should -Be $Result
        }
    }

    Context 'When running Test-TargetResource where Get-CMAccounts returned null' {
        BeforeAll {
            Mock -CommandName Get-CMAccount
        }

        It 'Should return desired result false when ensure = present' -TestCases @(
            @{Title = 'false when ensure = present'; Test = $cmAccountNull_Present; Result = $false}
            @{Title = 'true when ensure = absent'; Test = $cmAccountNull_Absent; Result = $true}
        ){
            Test-TargetResource @Test | Should -Be $Result
        }
    }
}