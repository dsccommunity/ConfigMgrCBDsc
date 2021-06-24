[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMAccounts'

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
        Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $getInput = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                }

                $cmAccounts = @{
                    UserName = 'TestUser1'
                    ItemType = 'User'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving client settings' {

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    $result = Get-TargetResource @getInput
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.Ensure          | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Get-TargetResource' -Tag 'Set' {
            BeforeAll {
                $testCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList 'TestUser1', (ConvertTo-SecureString 'RandomPassword' -AsPlainText -Force)

                $getReturnPresent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Absent'
                }

                $inputPresent = @{
                    SiteCode        = 'Lab'
                    Account         = 'TestUser1'
                    AccountPassword = $testCredential
                    Ensure          = 'Present'
                }

                $inputAbsent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Absent'
                }

                $inputAbsentCreds = @{
                    SiteCode        = 'Lab'
                    Account         = 'TestUser1'
                    AccountPassword = $testCredential
                    Ensure          = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMAccount
                Mock -CommandName Remove-CMAccount
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands for adding a new account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for removing an existing account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputAbsentCreds
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for removing an existing account no creds specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when account is already in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $cmAccountPresentNoCred = @{
                        SiteCode = 'Lab'
                        Account  = 'TestUser3'
                        Ensure   = 'Present'
                    }

                    $getAbsentReturn = @{
                        SiteCode = 'Lab'
                        Account  = 'TestUser3'
                        Ensure   = 'Absent'
                    }

                    $errorMsg = 'When adding an account a password must be specified.'
                }

                It 'Should Throw when Creds are not specified when adding an account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAbsentReturn }

                    { Set-TargetResource @cmAccountPresentNoCred } | Should -Throw -ExpectedMessage $errorMsg

                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAccount -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMAccounts\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $testCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList 'TestUser1', (ConvertTo-SecureString 'RandomPassword' -AsPlainText -Force)

                $getReturnPresent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Absent'
                }

                $inputPresent = @{
                    SiteCode        = 'Lab'
                    Account         = 'TestUser1'
                    AccountPassword = $testCredential
                    Ensure          = 'Present'
                }

                $inputAbsent = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Absent'
                }

                $cmAccountPresentNoCred = @{
                    SiteCode = 'Lab'
                    Account  = 'TestUser1'
                    Ensure   = 'Present'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource where Get-CMAccounts has accounts' {

                It 'Should return desired result true when ensure = present and account exists' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result true when ensure = absent and account does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and account does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when ensure = absent and account does exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false when ensure = present and account does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @cmAccountPresentNoCred | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
