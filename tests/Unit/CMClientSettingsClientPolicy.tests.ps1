[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsClientPolicy'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsClientPolicy\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    PolicyRequestAssignmentTimeout   = 60
                    PolicyEnableUserPolicyPolling    = 1
                    PolicyEnableUserPolicyOnInternet = 0
                    PolicyEnableUserPolicyOnTS       = $true
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Client Policy' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.PolicyPollingMins          | Should -Be -ExpectedValue 60
                    $result.EnableUserPolicy           | Should -Be -ExpectedValue $true
                    $result.EnableUserPolicyOnInternet | Should -Be -ExpectedValue $false
                    $result.EnableUserPolicyOnTS       | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.PolicyPollingMins          | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicy           | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicyOnInternet | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicyOnTS       | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when client setting policy exist but client policy is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $true }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'ClientPolicy' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.PolicyPollingMins          | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicy           | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicyOnInternet | Should -Be -ExpectedValue $null
                    $result.EnableUserPolicyOnTS       | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsClientPolicy\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = 60
                    EnableUserPolicy           = $true
                    EnableUserPolicyOnInternet = $false
                    EnableUserPolicyOnTS       = $true
                }

                Mock -CommandName Set-CMClientSettingClientPolicy
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnPresent = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        PolicyPollingMins          = 60
                        EnableUserPolicy           = $true
                        EnableUserPolicyOnInternet = $false
                        EnableUserPolicyOnTS       = $true
                        ClientSettingStatus        = 'Present'
                    }

                    $returnNotConfig = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        PolicyPollingMins          = $null
                        EnableUserPolicy           = $null
                        EnableUserPolicyOnInternet = $null
                        EnableUserPolicyOnTS       = $null
                        ClientSettingStatus        = 'Present'
                    }

                    $returnDefaultClient = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'Default Client Agent Settings'
                        PolicyPollingMins          = 60
                        EnableUserPolicy           = $true
                        EnableUserPolicyOnInternet = $false
                        EnableUserPolicyOnTS       = $true
                        ClientSettingStatus        = 'Present'
                    }

                    $inputDefaultClient = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'Default Client Agent Settings'
                        PolicyPollingMins          = 50
                        EnableUserPolicy           = $true
                        EnableUserPolicyOnInternet = $true
                        EnableUserPolicyOnTS       = $true
                    }

                    $inputMismatch = @{
                        SiteCode                    = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        PolicyPollingMins          = 50
                        EnableUserPolicy           = $false
                        EnableUserPolicyOnInternet = $true
                        EnableUserPolicyOnTS       = $false
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingClientPolicy -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match and nothing is currently set' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingClientPolicy -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when settings mis match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingClientPolicy -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when modifying default client settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnDefaultClient }

                    Set-TargetResource @inputDefaultClient
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingClientPolicy -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        PolicyPollingMins          = $null
                        EnableUserPolicy           = $null
                        EnableUserPolicyOnInternet = $null
                        EnableUserPolicyOnTS       = $null
                        ClientSettingStatus        = 'Absent'
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingClientPolicy -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsClientPolicy\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = 60
                    EnableUserPolicy           = $true
                    EnableUserPolicyOnInternet = $false
                    EnableUserPolicyOnTS       = $true
                    ClientSettingStatus        = 'Present'
                }

                $returnAbsent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = $null
                    EnableUserPolicy           = $null
                    EnableUserPolicyOnInternet = $null
                    EnableUserPolicyOnTS       = $null
                    ClientSettingStatus        = 'Absent'
                }

                $returnNotConfig = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = $null
                    EnableUserPolicy           = $null
                    EnableUserPolicyOnInternet = $null
                    EnableUserPolicyOnTS       = $null
                    ClientSettingStatus        = 'Present'
                }

                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = 60
                    EnableUserPolicy           = $true
                    EnableUserPolicyOnInternet = $false
                    EnableUserPolicyOnTS       = $true
                }

                $inputMismatch = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    PolicyPollingMins          = 50
                    EnableUserPolicy           = $false
                    EnableUserPolicyOnInternet = $true
                    EnableUserPolicyOnTS       = $false
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client policy exists but does not set settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
