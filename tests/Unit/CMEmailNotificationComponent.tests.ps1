[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMEmailNotificationComponent'

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
        Describe 'ConfigMgrCBDsc - DSC_CMEmailNotificationComponent\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving email notification component' {
                BeforeEach {
                    $getCMReturn = @{
                        ItemName = 'SMS_ALERT_NOTIFICATION|SMS Site Server'
                        ItemType = 'Component'
                        Name     = 'SMS Site Server'
                        SiteCode = 'LAB'
                        Props    = @(
                            @{
                                PropertyName = 'EnableSmtpSetting'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Port'
                                Value        = 25
                            }
                            @{
                                PropertyName = 'SendFrom'
                                Value1       = 'emailsender@contoso.com'
                            }
                            @{
                                PropertyName = 'ServerFqdn'
                                Value1       = 'EmailServer.contoso.com'
                            }
                            @{
                                PropertyName = 'AuthenticationMethod'
                                Value        = 0
                            }
                            @{
                                PropertyName = 'UseSsl'
                                Value        = $false
                            }
                            @{
                                PropertyName = 'UserName'
                                Value1       = 'contoso\EmailUser'
                            }
                        )
                    }

                    $getCMReturnDisabled = @{
                        ItemName = 'SMS_ALERT_NOTIFICATION|SMS Site Server'
                        ItemType = 'Component'
                        Name     = 'SMS Site Server'
                        SiteCode = 'LAB'
                        Props    = @(
                            @{
                                PropertyName = 'EnableSmtpSetting'
                                Value        = 0
                            }
                        )
                    }

                    $getCMReturnOther = @{
                        ItemName = 'SMS_ALERT_NOTIFICATION|SMS Site Server'
                        ItemType = 'Component'
                        Name     = 'SMS Site Server'
                        SiteCode = 'LAB'
                        Props    = @(
                            @{
                                PropertyName = 'EnableSmtpSetting'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Port'
                                Value        = 446
                            }
                            @{
                                PropertyName = 'SendFrom'
                                Value1       = 'emailsender@contoso.com'
                            }
                            @{
                                PropertyName = 'ServerFqdn'
                                Value1       = 'EmailServer.contoso.com'
                            }
                            @{
                                PropertyName = 'AuthenticationMethod'
                                Value        = 2
                            }
                            @{
                                PropertyName = 'UseSsl'
                                Value        = $true
                            }
                            @{
                                PropertyName = 'UserName'
                                Value1       = 'contoso\EmailUser'
                            }
                        )
                    }

                    $getInput = @{
                        SiteCode = 'Lab'
                        Enabled  = $true
                    }
                }

                It 'Should return desired result when enabled and Type of Authentication equals Anonymous' {
                    Mock -CommandName Get-CMEmailNotificationComponent -MockWith { $getCMReturn }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $true
                    $result.TypeOfAuthentication | Should -Be -ExpectedValue 'Anonymous'
                    $result.SmtpServerFqdn       | Should -Be -ExpectedValue 'EmailServer.contoso.com'
                    $result.SendFrom             | Should -Be -ExpectedValue 'emailsender@contoso.com'
                    $result.UserName             | Should -Be -ExpectedValue $null
                    $result.Port                 | Should -Be -ExpectedValue 25
                    $result.UseSsl               | Should -Be -ExpectedValue $false
                }

                It 'Should return desired result when enabled and Type of Authentication equals other' {
                    Mock -CommandName Get-CMEmailNotificationComponent -MockWith { $getCMReturnOther }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $true
                    $result.TypeOfAuthentication | Should -Be -ExpectedValue 'Other'
                    $result.SmtpServerFqdn       | Should -Be -ExpectedValue 'EmailServer.contoso.com'
                    $result.SendFrom             | Should -Be -ExpectedValue 'emailsender@contoso.com'
                    $result.UserName             | Should -Be -ExpectedValue 'contoso\EmailUser'
                    $result.Port                 | Should -Be -ExpectedValue 446
                    $result.UseSsl               | Should -Be -ExpectedValue $true
                }

                It 'Should return desired result when disabled' {
                    Mock -CommandName Get-CMEmailNotificationComponent -MockWith { $getCMReturnDisabled }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.Enabled              | Should -Be -ExpectedValue $false
                    $result.TypeOfAuthentication | Should -Be -ExpectedValue $null
                    $result.SmtpServerFqdn       | Should -Be -ExpectedValue $null
                    $result.SendFrom             | Should -Be -ExpectedValue $null
                    $result.UserName             | Should -Be -ExpectedValue $null
                    $result.Port                 | Should -Be -ExpectedValue $null
                    $result.UseSsl               | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMEmailNotificationComponent\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnPresentSsl = @{
                    SiteCode             = 'Lab'
                    UserName             = 'contoso\EmailUser'
                    Port                 = 446
                    SendFrom             = 'emailsender@contoso.com'
                    SmtpServerFqdn       = 'EmailServer.contoso.com'
                    TypeOfAuthentication = 'Other'
                    UseSsl               = $true
                    Enabled              = $true
                }

                $getReturnPresentNonSsl = @{
                    SiteCode             = 'Lab'
                    UserName             = $null
                    Port                 = 25
                    SendFrom             = 'emailsender@contoso.com'
                    SmtpServerFqdn       = 'EmailServer.contoso.com'
                    TypeOfAuthentication = 'Anonymous'
                    UseSsl               = $false
                    Enabled              = $true
                }

                $getReturnedAbsent = @{
                    SiteCode             = 'Lab'
                    UserName             = $null
                    Port                 = $null
                    SendFrom             = $null
                    SmtpServerFqdn       = $null
                    TypeOfAuthentication = $null
                    UseSsl               = $null
                    Enabled              = $false
                }

                $inputChangingAuth = @{
                    SiteCode             = 'Lab'
                    SendFrom             = 'emailsender@contoso.com'
                    SmtpServerFqdn       = 'EmailServer.contoso.com'
                    TypeOfAuthentication = 'Other'
                    UserName             = 'contoso\EmailUser'
                    Enabled              = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMEmailNotificationComponent
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputAbsent = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }

                    $inputPresent = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        Enabled              = $true
                    }

                    $inputSwitchSslToFalse = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        UseSsl               = $false
                        Enabled              = $true
                    }

                    $inputSwitchSslToTrue = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    Mock -CommandName Get-CMAccount -MockWith { $true }
                }

                It 'Should return desired result when disabling email notifcations settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when enabling email notifications' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing email notification settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing ssl settings to false and not specifying a port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Set-TargetResource @inputSwitchSslToFalse
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing ssl settings to true and not specifying a port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }

                    Set-TargetResource @inputSwitchSslToTrue
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when adding a UserName with correct TypeOfAuthentication' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }

                    Set-TargetResource @inputChangingAuth
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    Mock -CommandName Get-CMAccount
                    $absentUsername = 'UserAccount specifed contoso\EmailUser does not exist in the specified Configuration Manager site and will need to be created prior to adding as the connection account.'

                    $inputMissingCore = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        Enabled              = $true
                    }

                    $missingParams = 'When specifying Enabled equals true you must specify SmtpServerFqdn, Sendfrom, and TypeOfAuthentication.'

                    $inputAuthenticationMisMatch = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        UserName             = 'contoso\EmailUser'
                        Enabled              = $true
                    }

                    $userAuthNotOther = 'When specifying UserName you must set TypeOfAuthentication to Other.'

                    $inputMissingUserName = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Other'
                        Enabled              = $true
                    }

                    $authOtherNoUser = 'When setting TypeOfAuthentication to Other, you must specify UserName.'

                    $inputSslPortforSslFalse = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 465
                        UseSsl               = $false
                        Enabled              = $true
                    }

                    $nonSslBadPort = 'When not using SSL, you must specify a port other than the default SSL port 465.'

                    $inputNoneSslPortforSslTrue = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 25
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $sslBadPort = 'When using SSL, you must specify a port other than the default non-SSL port 25.'

                    $inputBadSendFrom = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender.contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 446
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $sendFromError = 'SendFrom emailsender.contoso.com should use @ format, example sendfrom@contoso.com.'

                    $inputBadSmtpServerFqdn = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer@contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 446
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $smtpError = 'SmtpServerFqdn EmailServer@contoso.com should use . vs @ format, example test.contoso.com.'
                }

                It 'Should return throw Username specifed does not exist in Confiuration Manager' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    { Set-TargetResource @inputChangingAuth } | Should -Throw -ExpectedMessage $absentUsername
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                }

                It 'Should return throw when enabling and core components are not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    { Set-TargetResource @inputMissingCore } | Should -Throw -ExpectedMessage $missingParams
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when Username is specified and TypeOfAuthentication is not set to other' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputAuthenticationMisMatch } | Should -Throw -ExpectedMessage $userAuthNotOther
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when TypeOfAuthentication is set to other and Username is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputMissingUserName } | Should -Throw -ExpectedMessage $authOtherNoUser
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when setting SSL to true and specifying the default non SSL port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputNoneSslPortforSslTrue } | Should -Throw -ExpectedMessage $sslBadPort
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when setting SSL to disabled and specifying the default SSL port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputSslPortforSslFalse } | Should -Throw -ExpectedMessage $nonSslBadPort
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when specifying a bad misformatted SendFrom' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputBadSendFrom } | Should -Throw -ExpectedMessage $sendFromError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when specifying a bad misformatted SmtpServerFqdn' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    { Set-TargetResource @inputBadSmtpServerFqdn } | Should -Throw -ExpectedMessage $smtpError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMEmailNotificationComponent -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMEmailNotificationComponent\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnPresentSsl = @{
                    SiteCode             = 'Lab'
                    UserName             = 'contoso\EmailUser'
                    Port                 = 446
                    SendFrom             = 'emailsender@contoso.com'
                    SmtpServerFqdn       = 'EmailServer.contoso.com'
                    TypeOfAuthentication = 'Other'
                    UseSsl               = $true
                    Enabled              = $true
                }

                $getReturnPresentNonSsl = @{
                    SiteCode             = 'Lab'
                    UserName             = $null
                    Port                 = 25
                    SendFrom             = 'emailsender@contoso.com'
                    SmtpServerFqdn       = 'EmailServer.contoso.com'
                    TypeOfAuthentication = 'Anonymous'
                    UseSsl               = $false
                    Enabled              = $true
                }

                $getReturnedAbsent = @{
                    SiteCode             = 'Lab'
                    UserName             = $null
                    Port                 = $null
                    SendFrom             = $null
                    SmtpServerFqdn       = $null
                    TypeOfAuthentication = $null
                    UseSsl               = $null
                    Enabled              = $false
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    $inputAbsent = @{
                        SiteCode = 'Lab'
                        Enabled  = $false
                    }

                    $inputPresent = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        Enabled              = $true
                    }
                }

                It 'Should return desired result true when Enabled = false and desired is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false when enabled = false and desired is true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Test-TargetResource @inputPresent | Should -Be $false
                }

                It 'Should return desired result false when enabled = true and desired is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputPresent | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource for Write-Warning validations' {
                BeforeEach {
                    $inputMissingCore = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        Enabled              = $true
                    }

                    $inputAuthenticationMisMatch = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Anonymous'
                        UserName             = 'contoso\EmailUser'
                        Enabled              = $true
                    }

                    $inputMissingUserName = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'Other'
                        Enabled              = $true
                    }

                    $inputSwitchSslToFalse = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        UseSsl               = $false
                        Enabled              = $true
                    }

                    $inputSwitchSslToTrue = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $inputSslPortforSslFalse = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 465
                        UseSsl               = $false
                        Enabled              = $true
                    }

                    $inputNoneSslPortforSslTrue = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 25
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $inputBadSendFrom = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender.contoso.com'
                        SmtpServerFqdn       = 'EmailServer.contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 446
                        UseSsl               = $true
                        Enabled              = $true
                    }

                    $inputBadSmtpServerFqdn = @{
                        SiteCode             = 'Lab'
                        SendFrom             = 'emailsender@contoso.com'
                        SmtpServerFqdn       = 'EmailServer@contoso.com'
                        TypeOfAuthentication = 'DefaultServiceAccount'
                        Port                 = 446
                        UseSsl               = $true
                        Enabled              = $true
                    }
                }

                It 'Should return desired result false when Enabled and missing core components for enabled equals True' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Test-TargetResource @inputMissingCore | Should -Be $false
                }

                It 'Should return desired result false when specifying Username and TypeOfAuthentication does not equal Other' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Test-TargetResource @inputAuthenticationMisMatch | Should -Be $false
                }

                It 'Should return desired result false when specifying TypeOfAuthentication as other and not specifying a UserName' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnedAbsent }

                    Test-TargetResource @inputMissingUserName | Should -Be $false
                }

                It 'Should return desired result false when switching SSL to false and not specifying a port ' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputSwitchSslToFalse | Should -Be $false
                }

                It 'Should return desired result false when switching SSL to true and not specifying a port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentNonSsl }

                    Test-TargetResource @inputSwitchSslToTrue | Should -Be $false
                }

                It 'Should return desired result false when setting SSL to false and specifying the default SSL port ' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputSslPortforSslFalse | Should -Be $false
                }

                It 'Should return desired result false when setting SSL to true and specifying the default non SSL port' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputNoneSslPortforSslTrue | Should -Be $false
                }

                It 'Should return desired result false when specifying a malformed SendFrom' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputBadSendFrom | Should -Be $false
                }

                It 'Should return desired result false when specifying a malformed SmtpServerFqdn' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentSsl }

                    Test-TargetResource @inputBadSmtpServerFqdn | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
