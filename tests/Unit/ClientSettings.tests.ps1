[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'ClientSettings'

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
        $moduleResourceName = 'ConfigMgrCBDsc - ClientSettings'

        $getClientSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'BackgroundIntelligentTransfer'
            Setting           = 'MaxBandwidthValidTo'
            SettingValue      = '23'
        }

        $getCloudSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'Cloud'
            Setting           = 'AutoAADJoin'
            SettingValue      = $true
        }

        $getComplianceSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'ComplianceSettings'
            Setting           = 'EnableUserStateManagement'
            SettingValue      = $false
        }

        $getMeteredNetworkSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'MeteredNetwork'
            Setting           = 'Test'
            SettingValue      = 1
        }

        $getMobileDeviceSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'MobileDevice'
            Setting           = 'EnableDeviceEnrollment'
            SettingValue      = 'True'
        }

        $getRemoteToolsSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'RemoteTools'
            Setting           = 'ManageRA'
            SettingValue      = '1'
        }

        $getSoftwareUpdatesSettings = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'SoftwareUpdates'
            Setting           = 'Enabled'
            SettingValue      = '1'
        }

        $getClientSettingsSC = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'SoftwareCenter'
            Setting           = 'SC_Old_Branding'
            SettingValue      = '0'
        }

        $getClientSettingsSCThrow = @{
            SiteCode          = 'Tes'
            Name              = 'Test'
            DeviceSettingName = 'SoftwareCenter'
            Setting           = 'Test'
            SettingValue      = '0'
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving client settings' {

                It 'Should return desired result for ClientSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '22' } }

                    $result = Get-TargetResource @getClientSettings
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Tes'
                    $result.Name              | Should -Be -ExpectedValue 'Test'
                    $result.DeviceSettingName | Should -Be -ExpectedValue 'BackgroundIntelligentTransfer'
                    $result.Setting           | Should -Be -ExpectedValue 'MaxBandwidthValidTo'
                    $result.SettingValue      | Should -Be -ExpectedValue '22'
                }

                It 'Should return desired result for SoftwareCenter' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '0' }

                    $result = Get-TargetResource @getClientSettingsSC 
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Tes'
                    $result.Name              | Should -Be -ExpectedValue 'Test'
                    $result.DeviceSettingName | Should -Be -ExpectedValue 'SoftwareCenter'
                    $result.Setting           | Should -Be -ExpectedValue 'SC_Old_Branding'
                    $result.SettingValue      | Should -Be -ExpectedValue '0'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {

            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Confirm-ClientSetting

                It 'Should call expected commands for Bits setting is compliant' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '23' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'MaxBandwidthEndHr' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getClientSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for Bits' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '22' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'MaxBandwidthEndHr' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getClientSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for SoftwareCenter' {
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '1' }
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'EnableCustomize' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getClientSettingsSC
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 1 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for SoftwareCenter when null return' {
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'EnableCustomize' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getClientSettingsSC
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 1 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for CloudSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ AutoAADJoin = 'false' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'AutoAzureADJoin' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getCloudSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for ComplianceSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ EnableUserStateManagement = 'true' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'EnableUserDataAndProfile' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getComplianceSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for MeteredNetworkSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ Test = '0' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'Test' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getMeteredNetworkSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for MobileDeviceSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ EnableDeviceEnrollment = 'False' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'EnableDevice' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getMobileDeviceSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for RemoteToolsSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ ManageRA = '0' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'ManageUnsolicitedRemoteAssistance' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getRemoteToolsSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for SoftwareUpdatesSettings' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ Enabled = '0' } }
                    Mock -CommandName Get-ClientSettingsSoftwareCenter
                    Mock -CommandName Convert-ClientSetting -MockWith { return 'Enable' }
                    Mock -CommandName Invoke-Command 

                    Set-TargetResource @getSoftwareUpdatesSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                Mock -CommandName Set-Location
                Mock -CommandName Confirm-ClientSetting
                Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '22' } }
                Mock -CommandName Get-ClientSettingsSoftwareCenter
                Mock -CommandName Convert-ClientSetting -MockWith { return 'MaxBandwidthEndHr' }

                It 'Should call expected commads on module import throw' {
                    Mock -CommandName Import-ConfigMgrPowerShellModule -MockWith { throw }
                    Mock -CommandName Invoke-Command

                    { Set-TargetResource @getClientSettings } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands on invoke throw' {
                    Mock -CommandName Import-ConfigMgrPowerShellModule
                    Mock -CommandName Invoke-Command -MockWith { throw }

                    { Set-TargetResource @getClientSettings } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands on settings mismatch throw' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '1' }
                    Mock -CommandName Import-ConfigMgrPowerShellModule
                    Mock -CommandName Confirm-ClientSetting -MockWith { throw }
                    Mock -CommandName Invoke-Command

                    { Set-TargetResource @getClientSettingsSCThrow } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 1 -Scope It
                    Assert-MockCalled Confirm-ClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ClientSettingsSoftwareCenter -Exactly -Times 0 -Scope It
                    Assert-MockCalled Convert-ClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Invoke-Command -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {            
            Mock -CommandName Set-Location

            Context 'When running Test-TargetResource' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Confirm-ClientSetting

                It 'Should return desired result True with CMClientSetting' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '23' } }

                    Test-TargetResource @getClientSettings | Should -Be $true
                }

                It 'Should return desired result True with SoftwareCenter' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '0' }

                    Test-TargetResource @getClientSettingsSC | Should -Be $true
                }

                It 'Should return desired result false with CMClientSetting' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = '22' } }

                    Test-TargetResource @getClientSettings | Should -Be $false
                }

                It 'Should return desired result false with SoftwareCenter' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '1' }

                    Test-TargetResource @getClientSettingsSC | Should -Be $false
                }

                It 'Should return desired result false with CMClientSetting returning Null' {
                    Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ MaxBandwidthValidTo = $null } }

                    Test-TargetResource @getClientSettings | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource should throw' {

                It 'Should throw when configmgr module does not import' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '1' }
                    Mock -CommandName Import-Module -MockWith { throw }

                    { Test-TargetResource @getClientSettingsSC } | Should -Throw -ExpectedMessage "Failure to import SCCM Cmdlets."
                }

                It 'Should throw when SoftwareCenter setting does not exist' {
                    Mock -CommandName Get-ClientSettingsSoftwareCenter -MockWith { return '1' }
                    Mock -CommandName Import-ConfigMgrPowerShellModule

                    { Test-TargetResource @getClientSettingsSCThrow } | Should -Throw -ExpectedMessage "The setting: $($getClientSettingsSCThrow.Setting) does not exist under $($getClientSettingsSCThrow.DeviceSettingName)"
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
