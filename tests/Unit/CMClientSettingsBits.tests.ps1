[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsBits'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsBits\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientDefault = @{
                    Type = 0
                }

                $clientReturn = @{
                    EnableBitsMaxBandwidth     = $true
                    MaxBandwidthValidFrom      = 0
                    MaxBandwidthValidTo        = 23
                    MaxTransferRateOnSchedule  = 900
                    EnableDownloadOffSchedule  = $true
                    MaxTransferRateOffSchedule = 400
                }

                $getInput = @{
                    SiteCode               = 'Lab'
                    ClientSettingName      = 'ClientTest'
                    EnableBitsMaxBandwidth = $true

                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for BITS' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientDefault }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn } -ParameterFilter { $Setting -eq 'BackgroundIntelligentTransfer' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableBitsMaxBandwidth     | Should -Be -ExpectedValue $true
                    $result.MaxBandwidthBeginHr        | Should -Be -ExpectedValue 0
                    $result.MaxBandwidthEndHr          | Should -Be -ExpectedValue 23
                    $result.MaxTransferRateOnSchedule  | Should -Be -ExpectedValue 900
                    $result.EnableDownloadOffSchedule  | Should -Be -ExpectedValue $true
                    $result.MaxTransferRateOffSchedule | Should -Be -ExpectedValue 400
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Default'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableBitsMaxBandwidth     | Should -Be -ExpectedValue $null
                    $result.MaxBandwidthBeginHr        | Should -Be -ExpectedValue $null
                    $result.MaxBandwidthEndHr          | Should -Be -ExpectedValue $null
                    $result.MaxTransferRateOnSchedule  | Should -Be -ExpectedValue $null
                    $result.EnableDownloadOffSchedule  | Should -Be -ExpectedValue $null
                    $result.MaxTransferRateOffSchedule | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                 | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but bits is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientDefault }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'BackgroundIntelligentTransfer' }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName          | Should -Be -ExpectedValue 'ClientTest'
                    $result.EnableBitsMaxBandwidth     | Should -Be -ExpectedValue $null
                    $result.MaxBandwidthBeginHr        | Should -Be -ExpectedValue $null
                    $result.MaxBandwidthEndHr          | Should -Be -ExpectedValue $null
                    $result.MaxTransferRateOnSchedule  | Should -Be -ExpectedValue $null
                    $result.EnableDownloadOffSchedule  | Should -Be -ExpectedValue $null
                    $result.MaxTransferRateOffSchedule | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus        | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                 | Should -Be -ExpectedValue 'Default'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsBits\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $true
                    MaxBandwidthBeginHr        = 0
                    MaxBandwidthEndHr          = 23
                    MaxTransferRateOnSchedule  = 900
                    EnableDownloadOffSchedule  = $true
                    MaxTransferRateOffSchedule = 1000
                }

                Mock -CommandName Set-CMClientSettingBackgroundIntelligentTransfer
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnPresent = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableBitsMaxBandwidth     = $true
                        MaxBandwidthBeginHr        = 0
                        MaxBandwidthEndHr          = 23
                        MaxTransferRateOnSchedule  = 900
                        EnableDownloadOffSchedule  = $true
                        MaxTransferRateOffSchedule = 1000
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Device'
                    }

                    $returnNotConfig = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableBitsMaxBandwidth     = $null
                        MaxBandwidthBeginHr        = $null
                        MaxBandwidthEndHr          = $null
                        MaxTransferRateOnSchedule  = $null
                        EnableDownloadOffSchedule  = $null
                        MaxTransferRateOffSchedule = $null
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Device'
                    }

                    $returnDefaultClient = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'Default Client Agent Settings'
                        EnableBitsMaxBandwidth     = $true
                        MaxBandwidthBeginHr        = 0
                        MaxBandwidthEndHr          = 23
                        MaxTransferRateOnSchedule  = 900
                        EnableDownloadOffSchedule  = $true
                        MaxTransferRateOffSchedule = 1000
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'Default'
                    }

                    $inputDefaultClient = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'Default Client Agent Settings'
                        EnableBitsMaxBandwidth     = $true
                        MaxBandwidthBeginHr        = 5
                        MaxBandwidthEndHr          = 11
                    }

                    $inputBitsDisabled = @{
                        SiteCode                  = 'Lab'
                        ClientSettingName         = 'ClientTest'
                        EnableBitsMaxBandwidth    = $false
                        EnableDownloadOffSchedule = $true
                    }

                    $inputOffSchedule = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableBitsMaxBandwidth     = $true
                        EnableDownloadOffSchedule  = $false
                        MaxTransferRateOffSchedule = 1000
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when disabling BITs' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputBitsDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when modifying default client settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnDefaultClient }

                    Set-TargetResource @inputDefaultClient
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when settings do not match and specifying EnableDownloadOffSchedule disabled and specifying MaxTransferRateOffSchedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputOffSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'ClientTest'
                        EnableBitsMaxBandwidth     = $null
                        MaxBandwidthBeginHr        = $null
                        MaxBandwidthEndHr          = $null
                        MaxTransferRateOnSchedule  = $null
                        EnableDownloadOffSchedule  = $null
                        MaxTransferRateOffSchedule = $null
                        ClientSettingStatus        = 'Absent'
                        ClientType                 = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'UserTest'
                        EnableBitsMaxBandwidth     = $null
                        MaxBandwidthBeginHr        = $null
                        MaxBandwidthEndHr          = $null
                        MaxTransferRateOnSchedule  = $null
                        EnableDownloadOffSchedule  = $null
                        MaxTransferRateOffSchedule = $null
                        ClientSettingStatus        = 'Present'
                        ClientType                 = 'User'
                    }

                    $userMsg = 'Client Settings for Bits only applies to Default and Device Client settings.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when client policy is user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $userMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsBits\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $true
                    MaxBandwidthBeginHr        = 0
                    MaxBandwidthEndHr          = 23
                    MaxTransferRateOnSchedule  = 900
                    EnableDownloadOffSchedule  = $true
                    MaxTransferRateOffSchedule = 1000
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                }

                $returnAbsent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $null
                    MaxBandwidthBeginHr        = $null
                    MaxBandwidthEndHr          = $null
                    MaxTransferRateOnSchedule  = $null
                    EnableDownloadOffSchedule  = $null
                    MaxTransferRateOffSchedule = $null
                    ClientSettingStatus        = 'Absent'
                    ClientType                 = $null
                }

                $returnNotConfig = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $null
                    MaxBandwidthBeginHr        = $null
                    MaxBandwidthEndHr          = $null
                    MaxTransferRateOnSchedule  = $null
                    EnableDownloadOffSchedule  = $null
                    MaxTransferRateOffSchedule = $null
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'Device'
                }

                $returnUser = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'UserTest'
                    EnableBitsMaxBandwidth     = $null
                    MaxBandwidthBeginHr        = $null
                    MaxBandwidthEndHr          = $null
                    MaxTransferRateOnSchedule  = $null
                    EnableDownloadOffSchedule  = $null
                    MaxTransferRateOffSchedule = $null
                    ClientSettingStatus        = 'Present'
                    ClientType                 = 'User'
                }

                $inputPresent = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $true
                    MaxBandwidthBeginHr        = 0
                    MaxBandwidthEndHr          = 23
                    MaxTransferRateOnSchedule  = 900
                    EnableDownloadOffSchedule  = $true
                    MaxTransferRateOffSchedule = 1000
                }

                $inputBitsDisabled = @{
                    SiteCode                  = 'Lab'
                    ClientSettingName         = 'ClientTest'
                    EnableBitsMaxBandwidth    = $false
                    EnableDownloadOffSchedule = $true
                }

                $inputOffSchedule = @{
                    SiteCode                   = 'Lab'
                    ClientSettingName          = 'ClientTest'
                    EnableBitsMaxBandwidth     = $true
                    EnableDownloadOffSchedule  = $false
                    MaxTransferRateOffSchedule = 1000
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

                It 'Should return desired result false when client policy exists but does not set BITs settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when setting bits to disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputBitsDisabled | Should -Be $false
                }

                It 'Should return desired result false when client policy is user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputBitsDisabled | Should -Be $false
                }

                It 'Should return desired result false when settings do not match and specifying EnableDownloadOffSchedule disabled and specifying MaxTransferRateOffSchedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputOffSchedule | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
