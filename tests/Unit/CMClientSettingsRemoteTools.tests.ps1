[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsRemoteTools'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsRemoteTools\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturnNone = @{
                    FirewallExceptionProfiles           = 0
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPublic = @{
                    FirewallExceptionProfiles           = 9
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPrivate = @{
                    FirewallExceptionProfiles           = 10
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPubPriv = @{
                    FirewallExceptionProfiles           = 11
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnDomain = @{
                    FirewallExceptionProfiles           = 12
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPubDom = @{
                    FirewallExceptionProfiles           = 13
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPrivDom = @{
                    FirewallExceptionProfiles           = 14
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientReturnPubPrivDom = @{
                    FirewallExceptionProfiles           = 15
                    AllowClientChange                   = $true
                    AllowRemCtrlToUnattended            = $true
                    PermissionRequired                  = $true
                    ClipboardAccessPermissionRequired   = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 2
                    PermittedViewers                    = @('RemoteGroup1','RemoteGroup2')
                    RemCtrlTaskbarIcon                  = $true
                    RemCtrlConnectionBar                = $true
                    AudibleSignal                       = 1
                    ManageRA                            = $true
                    EnforceRAandTSSettings              = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageTS                            = $true
                    EnableTS                            = $true
                    TSUserAuthentication                = $true
                }

                $clientType = @{
                    Type = 1
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Remote Tools' {

                It 'Should return desired results when client settings exist firewall none' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnNone } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue $null
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $null
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $null
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $null
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $null
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $null
                    $result.AccessLevel                         | Should -Be -ExpectedValue $null
                    $result.PermittedViewer                     | Should -Be -ExpectedValue $null
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $null
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $null
                    $result.AudibleSignal                       | Should -Be -ExpectedValue $null
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $null
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $null
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue $null
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $null
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $null
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Disabled'
                }

                It 'Should return desired results when client settings exist firewall Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPublic } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Public'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Private' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPrivate } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Private'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Private and Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubPriv } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Private','Public'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnDomain } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Domain'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Public and Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubDom } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Public','Domain'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Private and Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPrivDom } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Domain','Private'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired results when client settings exist firewall Domain, Private and Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubPrivDom } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue 'Domain','Private','Public'
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $true
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $true
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $true
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $true
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $true
                    $result.AccessLevel                         | Should -Be -ExpectedValue 'FullControl'
                    $result.PermittedViewer                     | Should -Be -ExpectedValue @('RemoteGroup1','RemoteGroup2')
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $true
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $true
                    $result.AudibleSignal                       | Should -Be -ExpectedValue 'PlaySoundAtBeginAndEnd'
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $true
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $true
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue 'FullControl'
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $true
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $true
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $true
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue 'Enabled'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue $null
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $null
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $null
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $null
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $null
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $null
                    $result.AccessLevel                         | Should -Be -ExpectedValue $null
                    $result.PermittedViewer                     | Should -Be -ExpectedValue $null
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $null
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $null
                    $result.AudibleSignal                       | Should -Be -ExpectedValue $null
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $null
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $null
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue $null
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $null
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $null
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                          | Should -Be -ExpectedValue $null
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but remote tools is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'RemoteTools' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                            | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName                   | Should -Be -ExpectedValue 'ClientTest'
                    $result.FirewallExceptionProfile            | Should -Be -ExpectedValue $null
                    $result.AllowClientChange                   | Should -Be -ExpectedValue $null
                    $result.AllowUnattendedComputer             | Should -Be -ExpectedValue $null
                    $result.PromptUserForPermission             | Should -Be -ExpectedValue $null
                    $result.PromptUserForClipboardPermission    | Should -Be -ExpectedValue $null
                    $result.GrantPermissionToLocalAdministrator | Should -Be -ExpectedValue $null
                    $result.AccessLevel                         | Should -Be -ExpectedValue $null
                    $result.PermittedViewer                     | Should -Be -ExpectedValue $null
                    $result.ShowNotificationIconOnTaskbar       | Should -Be -ExpectedValue $null
                    $result.ShowSessionConnectionBar            | Should -Be -ExpectedValue $null
                    $result.AudibleSignal                       | Should -Be -ExpectedValue $null
                    $result.ManageUnsolicitedRemoteAssistance   | Should -Be -ExpectedValue $null
                    $result.ManageSolicitedRemoteAssistance     | Should -Be -ExpectedValue $null
                    $result.RemoteAssistanceAccessLevel         | Should -Be -ExpectedValue $null
                    $result.ManageRemoteDesktopSetting          | Should -Be -ExpectedValue $null
                    $result.AllowPermittedViewer                | Should -Be -ExpectedValue $null
                    $result.RequireAuthentication               | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus                 | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                          | Should -Be -ExpectedValue 'Device'
                    $result.RemoteToolsStatus                   | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsRemoteTools\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = @('Domain')
                    AllowClientChange                   = $true
                    AllowUnattendedComputer             = $true
                    PromptUserForPermission             = $true
                    PromptUserForClipboardPermission    = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 'FullControl'
                    PermittedViewer                     = @('RemoteGroup1','RemoteGroup2')
                    ShowNotificationIconOnTaskbar       = $true
                    ShowSessionConnectionBar            = $true
                    AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                    ManageUnsolicitedRemoteAssistance   = $true
                    ManageSolicitedRemoteAssistance     = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageRemoteDesktopSetting          = $true
                    AllowPermittedViewer                = $true
                    RequireAuthentication               = $true
                    ClientSettingStatus                 = 'Present'
                    ClientType                          = 'Device'
                    RemoteToolsStatus                   = 'Enabled'
                }

                $inputPresent = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = @('Domain')
                    AllowClientChange                   = $true
                    AllowUnattendedComputer             = $true
                    PromptUserForPermission             = $true
                    PromptUserForClipboardPermission    = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 'FullControl'
                    PermittedViewer                     = @('RemoteGroup1','RemoteGroup2')
                    ShowNotificationIconOnTaskbar       = $true
                    ShowSessionConnectionBar            = $true
                    AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                    ManageUnsolicitedRemoteAssistance   = $true
                    ManageSolicitedRemoteAssistance     = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageRemoteDesktopSetting          = $true
                    AllowPermittedViewer                = $true
                    RequireAuthentication               = $true
                }

                Mock -CommandName Set-CMClientSettingRemoteTool
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMisMatch = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = @('Domain','Public')
                        AllowClientChange                   = $false
                        AllowUnattendedComputer             = $false
                        PromptUserForPermission             = $false
                        PromptUserForClipboardPermission    = $true
                        GrantPermissionToLocalAdministrator = $true
                        AccessLevel                         = 'FullControl'
                        PermittedViewer                     = @('RemoteGroup3','RemoteGroup4')
                        ShowNotificationIconOnTaskbar       = $true
                        ShowSessionConnectionBar            = $true
                        AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                        ManageUnsolicitedRemoteAssistance   = $true
                        ManageSolicitedRemoteAssistance     = $true
                        RemoteAssistanceAccessLevel         = 'FullControl'
                        ManageRemoteDesktopSetting          = $false
                        AllowPermittedViewer                = $true
                    }

                    $inputFirewallMisMatch = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = @('Public')
                    }

                    $returnNotConfig = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = $null
                        AllowClientChange                   = $null
                        AllowUnattendedComputer             = $null
                        PromptUserForPermission             = $null
                        PromptUserForClipboardPermission    = $null
                        GrantPermissionToLocalAdministrator = $null
                        AccessLevel                         = $null
                        PermittedViewer                     = $null
                        ShowNotificationIconOnTaskbar       = $null
                        ShowSessionConnectionBar            = $null
                        AudibleSignal                       = $null
                        ManageUnsolicitedRemoteAssistance   = $null
                        ManageSolicitedRemoteAssistance     = $null
                        RemoteAssistanceAccessLevel         = $null
                        ManageRemoteDesktopSetting          = $null
                        AllowPermittedViewer                = $null
                        RequireAuthentication               = $null
                        ClientSettingStatus                 = 'Present'
                        ClientType                          = 'Default'
                        RemoteToolsStatus                   = $null
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when firewall settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputFirewallMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when return is not configured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = $null
                        AllowClientChange                   = $null
                        AllowUnattendedComputer             = $null
                        PromptUserForPermission             = $null
                        PromptUserForClipboardPermission    = $null
                        GrantPermissionToLocalAdministrator = $null
                        AccessLevel                         = $null
                        PermittedViewer                     = $null
                        ShowNotificationIconOnTaskbar       = $null
                        ShowSessionConnectionBar            = $null
                        AudibleSignal                       = $null
                        ManageUnsolicitedRemoteAssistance   = $null
                        ManageSolicitedRemoteAssistance     = $null
                        RemoteAssistanceAccessLevel         = $null
                        ManageRemoteDesktopSetting          = $null
                        AllowPermittedViewer                = $null
                        RequireAuthentication               = $null
                        ClientSettingStatus                 = 'Absent'
                        ClientType                          = $null
                        RemoteToolsStatus                   = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = $null
                        AllowClientChange                   = $null
                        AllowUnattendedComputer             = $null
                        PromptUserForPermission             = $null
                        PromptUserForClipboardPermission    = $null
                        GrantPermissionToLocalAdministrator = $null
                        AccessLevel                         = $null
                        PermittedViewer                     = $null
                        ShowNotificationIconOnTaskbar       = $null
                        ShowSessionConnectionBar            = $null
                        AudibleSignal                       = $null
                        ManageUnsolicitedRemoteAssistance   = $null
                        ManageSolicitedRemoteAssistance     = $null
                        RemoteAssistanceAccessLevel         = $null
                        ManageRemoteDesktopSetting          = $null
                        AllowPermittedViewer                = $null
                        RequireAuthentication               = $null
                        ClientSettingStatus                 = 'Present'
                        ClientType                          = 'User'
                        RemoteToolsStatus                   = $null
                    }

                    $wrongClientType  = 'Client Settings for remote tools only applies to Default and Device Client settings.'

                    $returnDisabled = @{
                        SiteCode                            = 'Lab'
                        ClientSettingName                   = 'ClientTest'
                        FirewallExceptionProfile            = $null
                        AllowClientChange                   = $null
                        AllowUnattendedComputer             = $null
                        PromptUserForPermission             = $null
                        PromptUserForClipboardPermission    = $null
                        GrantPermissionToLocalAdministrator = $null
                        AccessLevel                         = $null
                        PermittedViewer                     = $null
                        ShowNotificationIconOnTaskbar       = $null
                        ShowSessionConnectionBar            = $null
                        AudibleSignal                       = $null
                        ManageUnsolicitedRemoteAssistance   = $null
                        ManageSolicitedRemoteAssistance     = $null
                        RemoteAssistanceAccessLevel         = $null
                        ManageRemoteDesktopSetting          = $null
                        AllowPermittedViewer                = $null
                        RequireAuthentication               = $null
                        ClientSettingStatus                 = 'Present'
                        ClientType                          = 'Device'
                        RemoteToolsStatus                   = 'Disabled'
                    }

                    $remoteToolsDisabled = 'Remote tools is currenly disabled and must be enabled to set settings for Remote Tools.'

                }

                It 'Should throw and call expected commands when client policy is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Client Policy Settings are user targeted' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Remote tools policy is disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnDisabled }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $remoteToolsDisabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingRemoteTool -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsRemoteTools\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = @('Domain')
                    AllowClientChange                   = $true
                    AllowUnattendedComputer             = $true
                    PromptUserForPermission             = $true
                    PromptUserForClipboardPermission    = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 'FullControl'
                    PermittedViewer                     = @('RemoteGroup1','RemoteGroup2')
                    ShowNotificationIconOnTaskbar       = $true
                    ShowSessionConnectionBar            = $true
                    AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                    ManageUnsolicitedRemoteAssistance   = $true
                    ManageSolicitedRemoteAssistance     = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageRemoteDesktopSetting          = $true
                    AllowPermittedViewer                = $true
                    RequireAuthentication               = $true
                    ClientSettingStatus                 = 'Present'
                    ClientType                          = 'Device'
                    RemoteToolsStatus                   = 'Enabled'
                }

                $returnAbsent = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = $null
                    AllowClientChange                   = $null
                    AllowUnattendedComputer             = $null
                    PromptUserForPermission             = $null
                    PromptUserForClipboardPermission    = $null
                    GrantPermissionToLocalAdministrator = $null
                    AccessLevel                         = $null
                    PermittedViewer                     = $null
                    ShowNotificationIconOnTaskbar       = $null
                    ShowSessionConnectionBar            = $null
                    AudibleSignal                       = $null
                    ManageUnsolicitedRemoteAssistance   = $null
                    ManageSolicitedRemoteAssistance     = $null
                    RemoteAssistanceAccessLevel         = $null
                    ManageRemoteDesktopSetting          = $null
                    AllowPermittedViewer                = $null
                    RequireAuthentication               = $null
                    ClientSettingStatus                 = 'Absent'
                    ClientType                          = $null
                    RemoteToolsStatus                   = $null
                }

                $returnNotConfig = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = $null
                    AllowClientChange                   = $null
                    AllowUnattendedComputer             = $null
                    PromptUserForPermission             = $null
                    PromptUserForClipboardPermission    = $null
                    GrantPermissionToLocalAdministrator = $null
                    AccessLevel                         = $null
                    PermittedViewer                     = $null
                    ShowNotificationIconOnTaskbar       = $null
                    ShowSessionConnectionBar            = $null
                    AudibleSignal                       = $null
                    ManageUnsolicitedRemoteAssistance   = $null
                    ManageSolicitedRemoteAssistance     = $null
                    RemoteAssistanceAccessLevel         = $null
                    ManageRemoteDesktopSetting          = $null
                    AllowPermittedViewer                = $null
                    RequireAuthentication               = $null
                    ClientSettingStatus                 = 'Present'
                    ClientType                          = 'Default'
                    RemoteToolsStatus                   = $null
                }

                $returnUser = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = $null
                    AllowClientChange                   = $null
                    AllowUnattendedComputer             = $null
                    PromptUserForPermission             = $null
                    PromptUserForClipboardPermission    = $null
                    GrantPermissionToLocalAdministrator = $null
                    AccessLevel                         = $null
                    PermittedViewer                     = $null
                    ShowNotificationIconOnTaskbar       = $null
                    ShowSessionConnectionBar            = $null
                    AudibleSignal                       = $null
                    ManageUnsolicitedRemoteAssistance   = $null
                    ManageSolicitedRemoteAssistance     = $null
                    RemoteAssistanceAccessLevel         = $null
                    ManageRemoteDesktopSetting          = $null
                    AllowPermittedViewer                = $null
                    RequireAuthentication               = $null
                    ClientSettingStatus                 = 'Present'
                    ClientType                          = 'User'
                    RemoteToolsStatus                   = $null
                }

                $returnDisabled = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = $null
                    AllowClientChange                   = $null
                    AllowUnattendedComputer             = $null
                    PromptUserForPermission             = $null
                    PromptUserForClipboardPermission    = $null
                    GrantPermissionToLocalAdministrator = $null
                    AccessLevel                         = $null
                    PermittedViewer                     = $null
                    ShowNotificationIconOnTaskbar       = $null
                    ShowSessionConnectionBar            = $null
                    AudibleSignal                       = $null
                    ManageUnsolicitedRemoteAssistance   = $null
                    ManageSolicitedRemoteAssistance     = $null
                    RemoteAssistanceAccessLevel         = $null
                    ManageRemoteDesktopSetting          = $null
                    AllowPermittedViewer                = $null
                    RequireAuthentication               = $null
                    ClientSettingStatus                 = 'Present'
                    ClientType                          = 'Device'
                    RemoteToolsStatus                   = 'Disabled'
                }

                $inputPresent = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = 'Domain'
                    AllowClientChange                   = $true
                    AllowUnattendedComputer             = $true
                    PromptUserForPermission             = $true
                    PromptUserForClipboardPermission    = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 'FullControl'
                    PermittedViewer                     = @('RemoteGroup1','RemoteGroup2')
                    ShowNotificationIconOnTaskbar       = $true
                    ShowSessionConnectionBar            = $true
                    AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                    ManageUnsolicitedRemoteAssistance   = $true
                    ManageSolicitedRemoteAssistance     = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageRemoteDesktopSetting          = $true
                }

                $inputMisMatch = @{
                    SiteCode                            = 'Lab'
                    ClientSettingName                   = 'ClientTest'
                    FirewallExceptionProfile            = 'Domain','Public'
                    AllowClientChange                   = $false
                    AllowUnattendedComputer             = $false
                    PromptUserForPermission             = $false
                    PromptUserForClipboardPermission    = $true
                    GrantPermissionToLocalAdministrator = $true
                    AccessLevel                         = 'FullControl'
                    PermittedViewer                     = @('RemoteGroup3','RemoteGroup4')
                    ShowNotificationIconOnTaskbar       = $true
                    ShowSessionConnectionBar            = $true
                    AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
                    ManageUnsolicitedRemoteAssistance   = $true
                    ManageSolicitedRemoteAssistance     = $true
                    RemoteAssistanceAccessLevel         = 'FullControl'
                    ManageRemoteDesktopSetting          = $false
                    AllowPermittedViewer                = $true
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false return is notconfigured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when client policy settings does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false when client policy settings is user based' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false when remote tools is disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnDisabled }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
