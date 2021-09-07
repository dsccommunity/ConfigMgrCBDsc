[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsDelivery'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsDelivery\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    EnableWindowsDO = 1
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Delivery Optimization' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when client setting policy exist but delivery optimization is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $true }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'DeliveryOptimization' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsDelivery\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                }

                Mock -CommandName Set-CMClientSettingDeliveryOptimization
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnPresent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $true
                        ClientSettingStatus = 'Present'
                    }

                    $returnPresentDefaultClient = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        Enable              = $false
                        ClientSettingStatus = 'Present'
                    }

                    $returnNotConfig = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $null
                        ClientSettingStatus = 'Present'
                    }

                    $inputDeliveryDisabled = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Enable            = $false
                    }

                    $inputDeliveryDefaultClient = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'Default Client Agent Settings'
                        Enable            = $true
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when disabling delivery optimization' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputDeliveryDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when disabling delivery optimization for default client settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefaultClient }

                    Set-TargetResource @inputDeliveryDefaultClient
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $null
                        ClientSettingStatus = 'Absent'
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsDelivery\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $true
                    ClientSettingStatus = 'Present'
                }

                $returnAbsent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $null
                    ClientSettingStatus = 'Absent'
                }

                $returnNotConfig = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $null
                    ClientSettingStatus = 'Present'
                }

                $inputPresent = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                }

                $inputDisabled = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $false
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

                It 'Should return desired result false when client policy exists but does not set Delivery optimization settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when setting delivery optimization to disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputDisabled | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
