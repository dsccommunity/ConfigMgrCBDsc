[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientPushSettings'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientPushSettings\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $siteComponent0 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 0
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent1 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent2 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 2
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent3 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 3
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent4 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 4
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent5 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 5
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent6 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 6
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Inactive'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 0
                            }
                        )
                    }
                )

                $siteComponent7 = @(
                    @{
                        ComponentName = 'SMS_Discovery_Data_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Filters'
                                Value        = 7
                            }
                            @{
                                PropertyName = 'Settings'
                                Value1       = 'Active'
                            }
                            @{
                                PropertyName = 'AutoInstallSiteSystem'
                                Value        = 1
                            }
                        )
                    }
                )

                $clientPushProps = @{
                    Props     = @(
                        @{
                            PropertyName = 'Advanced Client Command Line'
                            Value1       = 'SMSSiteCode=Lab CCMLogLevel=0'
                        }
                    )
                    PropLists = @{
                        PropertyListName = 'Reserved2'
                        Values = 'contoso\Push1','contoso\Push2'
                    }
                }

                $getInput = @{
                    SiteCode = 'Lab'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Push settings' {
                BeforeEach {
                    Mock -CommandName Get-CMClientPushInstallation -MockWith { $clientPushProps }
                }

                It 'Should return desired result with filter value 0' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent0 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $true
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $true
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 1' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent1 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $false
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $true
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 2' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent2 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $true
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $false
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 3' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent3 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $false
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $false
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 4' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent4 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $true
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $true
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 5' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent5 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $false
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $true
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 6' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent6 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $true
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $false
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }

                It 'Should return desired result with filter value 7' {
                    Mock -CommandName Get-CMSiteComponent -MockWith { $siteComponent7 }

                    $result = Get-TargetResource @getInput
                    $result                                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                              | Should -Be -ExpectedValue 'Lab'
                    $result.EnableAutomaticClientPushInstallation | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeConfigurationManager  | Should -Be -ExpectedValue $true
                    $result.EnableSystemTypeServer                | Should -Be -ExpectedValue $false
                    $result.EnableSystemTypeWorkstation           | Should -Be -ExpectedValue $false
                    $result.InstallClientToDomainController       | Should -Be -ExpectedValue $false
                    $result.Accounts                              | Should -Be -ExpectedValue @('contoso\Push1','contoso\Push2')
                    $result.InstallationProperty                  | Should -Be -ExpectedValue 'SMSSiteCode=Lab CCMLogLevel=0'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientPushSettings\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnDisabled = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $false
                    EnableSystemTypeConfigurationManager  = $false
                    EnableSystemTypeServer                = $true
                    EnableSystemTypeWorkstation           = $true
                    InstallClientToDomainController       = $false
                    InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                    Accounts                              = @('contoso\Push1')
                }

                $getReturnEnabled = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $true
                    EnableSystemTypeConfigurationManager  = $false
                    EnableSystemTypeServer                = $true
                    EnableSystemTypeWorkstation           = $true
                    InstallClientToDomainController       = $true
                    InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                    Accounts                              = @('contoso\Push1')
                }

                Mock -CommandName Set-CMClientPushInstallation
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMatch = @{
                        SiteCode                              = 'Lab'
                        EnableAutomaticClientPushInstallation = $true
                        EnableSystemTypeConfigurationManager  = $false
                        EnableSystemTypeServer                = $true
                        EnableSystemTypeWorkstation           = $true
                        InstallClientToDomainController       = $true
                        InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                        Accounts                              = @('contoso\Push1')
                    }

                    $accountsInputIncludeExclude = @{
                        SiteCode          = 'Lab'
                        AccountsToExclude = @('contoso\Push1')
                        AccountsToInclude = @('contoso\Push2')
                    }

                    Mock -CommandName Get-CMManagementPoint -MockWith { $true }
                    Mock -CommandName Get-CMAccount -MockWith { $true }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when setting accounts does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Set-TargetResource @accountsInputIncludeExclude
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $disableSettings = 'Client push is getting set to disabled or is disabled, unable to set the following settings: EnableSystemTypeConfigurationManager, EnableSystemTypeServer, EnableSystemTypeWorkstation.'
                    $includeExclude = 'AccountsToExclude and AccountsToInclude contain the same setting contoso\Push1.'
                    $mpError = 'Unable to enable client push settings, no Management Point could be found on Lab site.'

                    $inputDisableServerSetting = @{
                        SiteCode                              = 'Lab'
                        EnableAutomaticClientPushInstallation = $false
                        EnableSystemTypeWorkstation           = $false
                    }

                    $inputAccountsConflict = @{
                        SiteCode          = 'Lab'
                        AccountsToInclude = @('contoso\Push1')
                        AccountsToExclude = @('contoso\Push1')
                    }

                    $inputEnabledError = @{
                        SiteCode                              = 'Lab'
                        EnableAutomaticClientPushInstallation = $true
                    }

                    $accountsInputIncludeExclude = @{
                        SiteCode          = 'Lab'
                        AccountsToExclude = @('contoso\Push1')
                        AccountsToInclude = @('contoso\Push2')
                    }
                }

                It 'Should throw and call expected commands when setting command when disabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }
                    Mock -CommandName Get-CMManagementPoint -MockWith { $true }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @inputDisableServerSetting } | Should -Throw -ExpectedMessage $disableSettings
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when accounts include and exclude conflict' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }
                    Mock -CommandName Get-CMManagementPoint -MockWith { $true }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @inputAccountsConflict } | Should -Throw -ExpectedMessage $includeExclude
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when Management Point does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }
                    Mock -CommandName Get-CMManagementPoint -MockWith { $null }
                    Mock -CommandName Get-CMAccount -MockWith { $true }

                    { Set-TargetResource @inputEnabledError } | Should -Throw -ExpectedMessage $mpError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when account does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }
                    Mock -CommandName Get-CMManagementPoint -MockWith { $true }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @accountsInputIncludeExclude } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientPushInstallation -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientPushSettings\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnDisabled = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $false
                    EnableSystemTypeConfigurationManager  = $false
                    EnableSystemTypeServer                = $true
                    EnableSystemTypeWorkstation           = $true
                    InstallClientToDomainController       = $false
                    InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                    Accounts                              = @('contoso\Push1')
                }

                $getReturnEnabled = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $true
                    EnableSystemTypeConfigurationManager  = $false
                    EnableSystemTypeServer                = $true
                    EnableSystemTypeWorkstation           = $true
                    InstallClientToDomainController       = $true
                    InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                    Accounts                              = @('contoso\Push1')
                }

                $inputMatch = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $true
                    EnableSystemTypeConfigurationManager  = $false
                    EnableSystemTypeServer                = $true
                    EnableSystemTypeWorkstation           = $true
                    InstallClientToDomainController       = $true
                    InstallationProperty                  = 'SMSSiteCode=Lab CCMLogLevel=0'
                    Accounts                              = @('contoso\Push1')
                }

                $inputDisableServerSetting = @{
                    SiteCode                              = 'Lab'
                    EnableAutomaticClientPushInstallation = $false
                    EnableSystemTypeWorkstation           = $false
                }

                $inputAccountsConflict = @{
                    SiteCode          = 'Lab'
                    AccountsToInclude = @('contoso\Push1')
                    AccountsToExclude = @('contoso\Push1')
                }

                $accountsInputMisMatch = @{
                    SiteCode          = 'Lab'
                    Accounts          = @('contoso\Push1','contoso\Push2')
                    AccountsToInclude = @('contoso\Push1')
                }

                $accountsInputIncludeExclude = @{
                    SiteCode          = 'Lab'
                    AccountsToExclude = @('contoso\Push2')
                    AccountsToInclude = @('contoso\Push1')
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource and get returns present' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnDisabled }

                    Test-TargetResource @inputMatch | Should -Be $false
                }

                It 'Should return desired result false settings to disabled and settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @inputDisableServerSetting | Should -Be $false
                }

                It 'Should return desired result false account include and exclude' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @inputAccountsConflict | Should -Be $false
                }

                It 'Should return desired result false account include and exclude conflict' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @inputAccountsConflict | Should -Be $false
                }

                It 'Should return desired result false accounts and accounts to include specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnEnabled }

                    Test-TargetResource @accountsInputMisMatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
