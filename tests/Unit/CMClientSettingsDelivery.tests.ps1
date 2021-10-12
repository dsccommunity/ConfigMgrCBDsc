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

                $clientType = @{
                    Type = '0'
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
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn } -ParameterFilter { $Setting -eq 'DeliveryOptimization' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType          | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but delivery optimization is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'DeliveryOptimization' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Default'
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
                        ClientType          = 'Device'
                    }

                    $returnPresentDefaultClient = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        Enable              = $false
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Device'
                    }

                    $returnNotConfig = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Default'
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
                        ClientType          = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnWrongClientType = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'User'
                    }

                    $wrongClientType  = 'Client Settings for Delivery Optimization only applies to Default and Device Client settings.'
                }

                It 'Should throw and call expected commands when client settings does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingDeliveryOptimization -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when client type is incorrect' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnWrongClientType }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
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
                    ClientType          = 'Default'
                }

                $returnAbsent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $null
                    ClientSettingStatus = 'Absent'
                    ClientType          = $null
                }

                $returnNotConfig = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $returnWrongClientType = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'User'
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

                It 'Should return desired result false when client policy exists but currently does not set Delivery optimization settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client policy exists but is currently a User based client policy' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnWrongClientType }

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
