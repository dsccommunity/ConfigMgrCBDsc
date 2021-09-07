[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsCompliance'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsCompliance\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    ConfigureBranchCache      = $true
                    BranchCacheEnabled        = 1
                    MaxBranchCacheSizePercent = 20
                    ConfigureCacheSize        = 1
                    MaxCacheSizeMB            = 1048576
                    MaxCacheSizePercent       = 80
                    CanBeSuperPeer            = $true
                    BroadcastPort             = 8006
                    HttpPort                  = 8003
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Client Cache' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }

                    $result = Get-TargetResource @getInput
                    $result                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName         | Should -Be -ExpectedValue 'ClientTest'
                    $result.ConfigureBranchCache      | Should -Be -ExpectedValue $true
                    $result.EnableBranchCache         | Should -Be -ExpectedValue $true
                    $result.MaxBranchCacheSizePercent | Should -Be -ExpectedValue 20
                    $result.ConfigureCacheSize        | Should -Be -ExpectedValue $true
                    $result.MaxCacheSize              | Should -Be -ExpectedValue 1048576
                    $result.MaxCacheSizePercent       | Should -Be -ExpectedValue 80
                    $result.EnableSuperPeer           | Should -Be -ExpectedValue $true
                    $result.BroadcastPort             | Should -Be -ExpectedValue 8006
                    $result.DownloadPort              | Should -Be -ExpectedValue 8003
                    $result.ClientSettingStatus       | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName         | Should -Be -ExpectedValue 'ClientTest'
                    $result.ConfigureBranchCache      | Should -Be -ExpectedValue $null
                    $result.EnableBranchCache         | Should -Be -ExpectedValue $null
                    $result.MaxBranchCacheSizePercent | Should -Be -ExpectedValue $null
                    $result.ConfigureCacheSize        | Should -Be -ExpectedValue $null
                    $result.MaxCacheSize              | Should -Be -ExpectedValue $null
                    $result.MaxCacheSizePercent       | Should -Be -ExpectedValue $null
                    $result.EnableSuperPeer           | Should -Be -ExpectedValue $null
                    $result.BroadcastPort             | Should -Be -ExpectedValue $null
                    $result.DownloadPort              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus       | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when client setting policy exist but client cache is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $true }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'ClientCache' }

                    $result = Get-TargetResource @getInput
                    $result                           | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                  | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName         | Should -Be -ExpectedValue 'ClientTest'
                    $result.ConfigureBranchCache      | Should -Be -ExpectedValue $null
                    $result.EnableBranchCache         | Should -Be -ExpectedValue $null
                    $result.MaxBranchCacheSizePercent | Should -Be -ExpectedValue $null
                    $result.ConfigureCacheSize        | Should -Be -ExpectedValue $null
                    $result.MaxCacheSize              | Should -Be -ExpectedValue $null
                    $result.MaxCacheSizePercent       | Should -Be -ExpectedValue $null
                    $result.EnableSuperPeer           | Should -Be -ExpectedValue $null
                    $result.BroadcastPort             | Should -Be -ExpectedValue $null
                    $result.DownloadPort              | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus       | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsCompliance\Set-TargetResource' -Tag 'Set' {
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
                    }

                    $inputDefaultClient = @{
                        SiteCode                   = 'Lab'
                        ClientSettingName          = 'Default Client Agent Settings'
                        EnableBitsMaxBandwidth     = $true
                        MaxBandwidthBeginHr        = 5
                        MaxBandwidthEndHr          = 11
                    }

                    $inputBitsDisabled = @{
                        SiteCode               = 'Lab'
                        ClientSettingName      = 'ClientTest'
                        EnableBitsMaxBandwidth = $false
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
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingBackgroundIntelligentTransfer -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsCompliance\Test-TargetResource' -Tag 'Test' {
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
                    SiteCode               = 'Lab'
                    ClientSettingName      = 'ClientTest'
                    EnableBitsMaxBandwidth = $false
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
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
