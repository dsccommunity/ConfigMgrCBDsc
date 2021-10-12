[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettingsPower'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsPower\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturnNone = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 0
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPublic = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 0
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 9
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPrivate = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 10
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPubPriv = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 11
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnDomain = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 12
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPubDom = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 13
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPrivDom = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 14
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
                }

                $clientReturnPubPrivDom = @{
                    Enabled                           = $true
                    AllowUserToOptOutFromPowerPlan    = $true
                    AllowWakeup                       = 1
                    EnableWakeupProxy                 = $true
                    Port                              = 40
                    WolPort                           = 41
                    WakeupProxyFirewallFlags          = 15
                    WakeupProxyDirectAccessPrefixList = 'fe80::6013:b219:6a1b:4767'
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

            Context 'When retrieving Client Policy Settings for Power settings' {

                It 'Should return desired results when client settings exist firewall none' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnNone } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue 'None'
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPublic } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue 'Public'
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'NotConfigured'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Private' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPrivate } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue 'Private'
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Private and Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubPriv } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue @('Private','Public')
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnDomain } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue 'Domain'
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Public and Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubDom } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue @('Public','Domain')
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Private and Domain' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPrivDom } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue @('Domain','Private')
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired results when client settings exist firewall Domain, Private and Public' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturnPubPrivDom } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $true
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $true
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $true
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue 40
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue 41
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue @('Domain','Private','Public')
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue @('fe80::6013:b219:6a1b:4767')
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue 'Enabled'
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }

                It 'Should return desired result when client setting policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $null
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $null
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $null
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue $null
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue $null
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue $null
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue $null
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Absent'
                    $result.ClientType                      | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result when client setting policy exist but power management is not configured' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientType }
                    Mock -CommandName Get-CMClientSetting -MockWith { $null } -ParameterFilter { $Setting -eq 'PowerManagement' }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName               | Should -Be -ExpectedValue 'ClientTest'
                    $result.Enable                          | Should -Be -ExpectedValue $null
                    $result.AllowUserToOptOutFromPowerPlan  | Should -Be -ExpectedValue $null
                    $result.EnableWakeupProxy               | Should -Be -ExpectedValue $null
                    $result.WakeupProxyPort                 | Should -Be -ExpectedValue $null
                    $result.WakeOnLanPort                   | Should -Be -ExpectedValue $null
                    $result.FirewallExceptionForWakeupProxy | Should -Be -ExpectedValue $null
                    $result.WakeupProxyDirectAccessPrefix   | Should -Be -ExpectedValue $null
                    $result.NetworkWakeupOption             | Should -Be -ExpectedValue $null
                    $result.ClientSettingStatus             | Should -Be -ExpectedValue 'Present'
                    $result.ClientType                      | Should -Be -ExpectedValue 'Device'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsPower\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    AllowUserToOptOutFromPowerPlan  = $true
                    EnableWakeupProxy               = $true
                    WakeupProxyPort                 = 41
                    WakeOnLanPort                   = 42
                    FirewallExceptionForWakeupProxy = @('Domain','Private')
                    WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4768','fe80::6013:b219:6a1b:4767')
                    NetworkWakeupOption             = 'Enabled'
                    ClientSettingStatus             = 'Present'
                    ClientType                      = 'Device'
                }

                $inputPresent = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    AllowUserToOptOutFromPowerPlan  = $true
                    EnableWakeupProxy               = $true
                    WakeupProxyPort                 = 41
                    WakeOnLanPort                   = 42
                    FirewallExceptionForWakeupProxy = @('Private','Domain')
                    WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4767','fe80::6013:b219:6a1b:4768')
                    NetworkWakeupOption             = 'Enabled'
                }

                Mock -CommandName Set-CMClientSettingPowerManagement
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMisMatch = @{
                        SiteCode                        = 'Lab'
                        ClientSettingName               = 'ClientTest'
                        Enable                          = $true
                        AllowUserToOptOutFromPowerPlan  = $true
                        EnableWakeupProxy               = $true
                        WakeupProxyPort                 = 42
                        WakeOnLanPort                   = 43
                        FirewallExceptionForWakeupProxy = @('Private','Public')
                        WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4767','fe80::6013:b219:6a1b:4769')
                        NetworkWakeupOption             = 'Enabled'
                    }

                    $returnNotConfig = @{
                        SiteCode                        = 'Lab'
                        ClientSettingName               = 'ClientTest'
                        Enable                          = $null
                        AllowUserToOptOutFromPowerPlan  = $null
                        EnableWakeupProxy               = $null
                        WakeupProxyPort                 = $null
                        WakeOnLanPort                   = $null
                        FirewallExceptionForWakeupProxy = $null
                        WakeupProxyDirectAccessPrefix   = $null
                        NetworkWakeupOption             = $null
                        ClientSettingStatus             = 'Present'
                        ClientType                      = 'Default'
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when return is not configured' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnNotConfig }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $returnAbsent = @{
                        SiteCode                  = 'Lab'
                        ClientSettingName         = 'ClientTest'
                        ConfigureBranchCache      = $null
                        EnableBranchCache         = $null
                        MaxBranchCacheSizePercent = $null
                        ConfigureCacheSize        = $null
                        MaxCacheSize              = $null
                        MaxCacheSizePercent       = $null
                        EnableSuperPeer           = $null
                        BroadcastPort             = $null
                        DownloadPort              = $null
                        ClientSettingStatus       = 'Absent'
                        ClientType                = $null
                    }

                    $absentMsg = 'Client Policy setting ClientTest does not exist, and will need to be created prior to making client setting changes.'

                    $returnUser = @{
                        SiteCode                        = 'Lab'
                        ClientSettingName               = 'ClientTest'
                        Enable                          = $null
                        AllowUserToOptOutFromPowerPlan  = $null
                        EnableWakeupProxy               = $null
                        WakeupProxyPort                 = $null
                        WakeOnLanPort                   = $null
                        FirewallExceptionForWakeupProxy = $null
                        WakeupProxyDirectAccessPrefix   = $null
                        NetworkWakeupOption             = $null
                        ClientSettingStatus             = 'Present'
                        ClientType                      = 'User'
                    }

                    $wrongClientType  = 'Client Settings for power management only applies to Default and Device Client settings.'

                    $inputNetworkWakeUp = @{
                        SiteCode            = 'Lab'
                        ClientSettingName   = 'ClientTest'
                        Enable              = $true
                        NetworkWakeUpOption = 'Disabled'
                        WakeOnLanPort       = 40
                    }

                    $networkWakeUpMsg = 'In order to set WakeOnLanPort you must specify NetworkWakeUpOption Enabled and also set EnableWakeUpProxy true.'

                    $inputEnableWakeUpProxy = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Enable            = $true
                        EnableWakeUpProxy = $false
                        WakeupProxyPort   = 41
                    }

                    $disableWakeUpProxyMsg = 'In order to set WakeUpProxyPort, FirewallExceptionForWakeupProxy, or WakeupProxyDirectAccessPrefix, EnableWakeUpProxy must be set to $true.'

                    $inputBadFirewall = @{
                        SiteCode                        = 'Lab'
                        ClientSettingName               = 'ClientTest'
                        Enable                          = $true
                        EnableWakeUpProxy               = $true
                        NetworkWakeUpOption             = 'Enabled'
                        FirewallExceptionForWakeupProxy = @('None','Domain')
                    }

                    $firewallMsg = 'When specifying FirewallExceptionForWakeupProxy and specifying None, you can not specify any other firewall exceptions.'
                }

                It 'Should throw and call expected commands when client policy is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $absentMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Client Policy Settings are user targeted' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnUser }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $wrongClientType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when when network wake up options is disabled and specifying WakeOnLanPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    { Set-TargetResource @inputNetworkWakeUp } | Should -Throw -ExpectedMessage $networkWakeUpMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when EnableWakeUpProxy is false and specifying WakeupProxyPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    { Set-TargetResource @inputEnableWakeUpProxy } | Should -Throw -ExpectedMessage $disableWakeUpProxyMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when FirewallExceptionForWakeupProxy contains None and another firewall setting' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    { Set-TargetResource @inputBadFirewall } | Should -Throw -ExpectedMessage $firewallMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSettingPowerManagement -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettingsPower\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    AllowUserToOptOutFromPowerPlan  = $true
                    EnableWakeupProxy               = $true
                    WakeupProxyPort                 = 41
                    WakeOnLanPort                   = 42
                    FirewallExceptionForWakeupProxy = @('Domain','Private')
                    WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4768','fe80::6013:b219:6a1b:4767')
                    NetworkWakeupOption             = 'Enabled'
                    ClientSettingStatus             = 'Present'
                    ClientType                      = 'Device'
                }

                $returnAbsent = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $null
                    AllowUserToOptOutFromPowerPlan  = $null
                    EnableWakeupProxy               = $null
                    WakeupProxyPort                 = $null
                    WakeOnLanPort                   = $null
                    FirewallExceptionForWakeupProxy = $null
                    WakeupProxyDirectAccessPrefix   = $null
                    NetworkWakeupOption             = $null
                    ClientSettingStatus             = 'Absent'
                    ClientType                      = $null
                }

                $returnNotConfig = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $null
                    AllowUserToOptOutFromPowerPlan  = $null
                    EnableWakeupProxy               = $null
                    WakeupProxyPort                 = $null
                    WakeOnLanPort                   = $null
                    FirewallExceptionForWakeupProxy = $null
                    WakeupProxyDirectAccessPrefix   = $null
                    NetworkWakeupOption             = $null
                    ClientSettingStatus             = 'Present'
                    ClientType                      = 'Device'
                }

                $returnUser = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $null
                    AllowUserToOptOutFromPowerPlan  = $null
                    EnableWakeupProxy               = $null
                    WakeupProxyPort                 = $null
                    WakeOnLanPort                   = $null
                    FirewallExceptionForWakeupProxy = $null
                    WakeupProxyDirectAccessPrefix   = $null
                    NetworkWakeupOption             = $null
                    ClientSettingStatus             = 'Present'
                    ClientType                      = 'User'
                }

                $inputPresent = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    AllowUserToOptOutFromPowerPlan  = $true
                    EnableWakeupProxy               = $true
                    WakeupProxyPort                 = 41
                    WakeOnLanPort                   = 42
                    FirewallExceptionForWakeupProxy = @('Private','Domain')
                    WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4767','fe80::6013:b219:6a1b:4768')
                    NetworkWakeupOption             = 'Enabled'
                }

                $inputMisMatch = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    AllowUserToOptOutFromPowerPlan  = $true
                    EnableWakeupProxy               = $true
                    WakeupProxyPort                 = 42
                    WakeOnLanPort                   = 43
                    FirewallExceptionForWakeupProxy = @('Private','Domain','Public')
                    WakeupProxyDirectAccessPrefix   = @('fe80::6013:b219:6a1b:4767','fe80::6013:b219:6a1b:4769')
                    NetworkWakeupOption             = 'Enabled'
                }

                $inputNetworkWakeUp = @{
                    SiteCode            = 'Lab'
                    ClientSettingName   = 'ClientTest'
                    Enable              = $true
                    NetworkWakeUpOption = 'Disabled'
                    WakeOnLanPort       = 40
                }

                $inputEnableWakeUpProxy = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Enable            = $true
                    EnableWakeUpProxy = $false
                    WakeupProxyPort   = 41
                }

                $inputBadFirewall = @{
                    SiteCode                        = 'Lab'
                    ClientSettingName               = 'ClientTest'
                    Enable                          = $true
                    EnableWakeUpProxy               = $true
                    NetworkWakeUpOption             = 'Enabled'
                    FirewallExceptionForWakeupProxy = @('None','Domain')
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

                It 'Should return desired result false when network wake up options is disabled and specifying WakeOnLanPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputNetworkWakeUp | Should -Be $false
                }

                It 'Should return desired result false when EnableWakeUpProxy is false and specifying WakeupProxyPort' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputEnableWakeUpProxy | Should -Be $false
                }

                It 'Should return desired result false when FirewallExceptionForWakeupProxy contains None and another firewall setting' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputBadFirewall | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
