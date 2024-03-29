[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsMetered'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsMetered\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturnAllow = @{
                    MeteredNetworkUsage = 1
                }

                $clientReturnLimit = @{
                    MeteredNetworkUsage = 2
                }

                $clientReturnBlock = @{
                    MeteredNetworkUsage = 4
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                $clientType = @{
                    Type = 1
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Metered settings' {

                It 'Should return desired results when client settings exist and allowed' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnAllow } -ParameterFilter { $Setting -eq 'MeteredNetwork' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.MeteredNetworkUsage | Should -Be -ExpectedValue 'Allow'
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist and limited' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnLimit } -ParameterFilter { $Setting -eq 'MeteredNetwork' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.MeteredNetworkUsage | Should -Be -ExpectedValue 'Limit'
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist and blocked' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnBlock } -ParameterFilter { $Setting -eq 'MeteredNetwork' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.MeteredNetworkUsage | Should -Be -ExpectedValue 'Block'
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.MeteredNetworkUsage | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType          | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but metered settings is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'MeteredNetwork' }

                    $result = Get-TargetResource @getInput
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName   | Should -Be -ExpectedValue 'ClientTest'
                    $result.MeteredNetworkUsage | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus | Should -Be -ExpectedValue 'Present'
                    $result.ClientType          | Should -Be -ExpectedValue 'Device'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsMetered\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = 'Allow'
                }

                Mock -CommandName Set-CMClientSettingMeteredInternetConnection
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnPresent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        MeteredNetworkUsage = 'Allow'
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Device'
                    }

                    $returnPresentDefaultClient = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        MeteredNetworkUsage = 'Block'
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Default'
                    }

                    $returnNotConfig = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        MeteredNetworkUsage = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'Device'
                    }

                    $inputMeteredLimited = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        MeteredNetworkUsage = 'Limit'
                    }

                    $inputMeteredDefaultClient = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'Default Client Agent Settings'
                        MeteredNetworkUsage = 'Limit'
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when limiting metered' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMeteredLimited
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when changing metered settings for default client settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresentDefaultClient }

                    Set-TargetResource @inputMeteredDefaultClient
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        MeteredNetworkUsage = $null
                        ClientSettingStatus = 'Absent'
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        MeteredNetworkUsage = $null
                        ClientSettingStatus = 'Present'
                        ClientType          = 'User'
                    }

                    $wrongClientType  = 'Client Settings for Metered Connections only applies to Default and Device Client settings.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Client Policy Settings are user targeted' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingMeteredInternetConnection -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsMetered\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = 'Allow'
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $returnAbsent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = $null
                    ClientSettingStatus = 'Absent'
                    ClientType          = $null
                }

                $returnNotConfig = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'Device'
                }

                $inputPresent = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = 'Allow'
                }

                $inputBlocked = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = 'Block'
                }

                $inputLimit = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = 'Limit'
                }

                $returnUser = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    MeteredNetworkUsage = $null
                    ClientSettingStatus = 'Present'
                    ClientType          = 'User'
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

                It 'Should return desired result false when client policy exists but does not set metered connection settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when setting metered connection to blocked' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputBlocked | Should -Be $false
                }

                It 'Should return desired result false when setting metered connection to limited' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputLimit | Should -Be $false
                }

                It 'Should return desired result false when Client Policy settings are user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputLimit | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
