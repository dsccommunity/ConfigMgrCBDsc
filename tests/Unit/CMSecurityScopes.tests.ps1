[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSecurityScopes'

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
        Describe 'ConfigMgrCBDsc - DSC_CMSecurityScopes\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {
                BeforeEach {
                    $scopeReturn = @{
                        CategoryName        = 'TestScope'
                        CategoryDescription = $null
                        NumberOfObjects     = 1
                        NumberOfAdmins      = 0
                    }

                    $scopeReturnInUseObjects = @{
                        CategoryName        = 'TestScope'
                        CategoryDescription = 'Test description'
                        NumberOfObjects     = 2
                        NumberOfAdmins      = 0
                    }

                    $scopeReturnInUseAdmin = @{
                        CategoryName        = 'TestScope'
                        CategoryDescription = 'Test description'
                        NumberOfObjects     = 1
                        NumberOfAdmins      = 1
                    }

                    $getInput = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                    }
                }

                It 'Should return desired result when Security Scope return not in use' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $scopeReturn }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityScopeName | Should -Be -ExpectedValue 'TestScope'
                    $result.Description       | Should -Be -ExpectedValue $null
                    $result.Ensure            | Should -Be -ExpectedValue 'Present'
                    $result.InUse             | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when Security Scope return in use Objects' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $scopeReturnInUseObjects }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityScopeName | Should -Be -ExpectedValue 'TestScope'
                    $result.Description       | Should -Be -ExpectedValue 'Test description'
                    $result.Ensure            | Should -Be -ExpectedValue 'Present'
                    $result.InUse             | Should -Be -ExpectedValue $true
                }

                It 'Should return desired result when Security Scope return in use Admin' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $scopeReturnInUseAdmin }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityScopeName | Should -Be -ExpectedValue 'TestScope'
                    $result.Description       | Should -Be -ExpectedValue 'Test description'
                    $result.Ensure            | Should -Be -ExpectedValue 'Present'
                    $result.InUse             | Should -Be -ExpectedValue $true
                }

                It 'Should return desired result when Security Scope is abent' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityScopeName | Should -Be -ExpectedValue 'TestScope'
                    $result.Description       | Should -Be -ExpectedValue $null
                    $result.Ensure            | Should -Be -ExpectedValue 'Absent'
                    $result.InUse             | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSecurityScopes\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputAbsent = @{
                    SiteCode          = 'Lab'
                    SecurityScopeName = 'TestScope'
                    Ensure            = 'Absent'
                }

                $getReturnPresentDescription = @{
                    SiteCode          = 'Lab'
                    SecurityScopeName = 'TestScope'
                    Description       = ''
                    Ensure            = 'Present'
                    InUse             = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMSecurityScope
                Mock -CommandName Set-CMSecurityScope
                Mock -CommandName Remove-CMSecurityScope
            }

            Context 'When running Set-TargetResource successfully' {
                BeforeEach {
                    $inputPresent = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = 'Test description'
                        Ensure            = 'Present'
                    }

                    $getReturnPresentMatch = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = 'Test description'
                        Ensure            = 'Present'
                        InUse             = $false
                    }

                    $getReturnAbsent = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = $null
                        Ensure            = 'Absent'
                        InUse             = $null
                    }
                }

                It 'Should throw and call expected commands creating a Security Scope' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityScope -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands modifying the description' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentDescription }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityScope -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands removing the Security Scope' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentMatch }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScope -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource throws' {
                BeforeEach {
                    $scopeError = 'The Security Scope is in use and will not be deleted.'
                }

                It 'Should throw and call expected commands creating a Security Scope' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentDescription }

                    { Set-TargetResource @inputAbsent } | Should -Throw -ExpectedMessage $scopeError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScope -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSecurityScopes\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    $inputPresent = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = 'Test description'
                        Ensure            = 'Present'
                    }

                    $inputAbsent = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Ensure            = 'Absent'
                    }

                    $getReturnPresentMatch = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = 'Test description'
                        Ensure            = 'Present'
                        InUse             = $false
                    }

                    $getReturnPresentDescription = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = ''
                        Ensure            = 'Present'
                        InUse             = $true
                    }

                    $getReturnAbsent = @{
                        SiteCode          = 'Lab'
                        SecurityScopeName = 'TestScope'
                        Description       = $null
                        Ensure            = 'Absent'
                        InUse             = $null
                    }
                }

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentMatch }

                    Test-TargetResource @inputPresent  | Should -Be $true
                }

                It 'Should return desired result false when description does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentDescription }

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result false when absent and expected present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result false when present and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentDescription }

                    Test-TargetResource @inputAbsent  | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
