[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSoftwareDistributionComponent'

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

        Describe 'DSC_CMSoftwareDistributionComponent\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $cmDistroReturn = @(
                    @{
                        ComponentName = 'SMS_Distribution_Manager'
                        Props         = @(
                            @{
                                PropertyName = 'Thread Limit'
                                Value        = 3
                            }
                            @{
                                PropertyName = 'Retry Delay'
                                Value        = 30
                            }
                            @{
                                PropertyName = 'Package Thread Limit'
                                Value        = 5
                            }
                            @{
                                PropertyName = 'Number of Retries'
                                Value        = 100
                            }
                        )
                    }
                    @{
                        ComponentName = 'SMS_MULTICAST_SERVICE_POINT'
                        Props         = @(
                            @{
                                PropertyName = 'Retry Delay'
                                Value        = 60
                            }
                            @{
                                PropertyName = 'Number of Retries'
                                Value        = 3
                            }
                        )
                    }
                )

                $cmAccounts = @(
                    @{
                        AccountUsage = 'Software Distribution'
                        UserName     = 'contoso\Network1'
                    }
                )

                $getInput = @{
                    SiteCode = 'Lab'
                }

                Mock -CommandName Get-CMSoftwareDistributionComponent -MockWith { $cmDistroReturn }
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving site system settings' {

                It 'Should return desired result when a Network access account is assigned' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    $result = Get-TargetResource @getInput
                    $result                                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                         | Should -Be -ExpectedValue 'Lab'
                    $result.MaximumPackageCount              | Should -Be -ExpectedValue 3
                    $result.MaximumThreadCountPerPackage     | Should -Be -ExpectedValue 5
                    $result.RetryCount                       | Should -Be -ExpectedValue 100
                    $result.DelayBeforeRetryingMins          | Should -Be -ExpectedValue 30
                    $result.MulticastRetryCount              | Should -Be -ExpectedValue 3
                    $result.MulticastDelayBeforeRetryingMins | Should -Be -ExpectedValue 1
                    $result.ClientComputerAccount            | Should -Be -ExpectedValue $false
                    $result.AccessAccounts                   | Should -Be -ExpectedValue @('contoso\Network1')
                }

                It 'Should return desired result when a Network access account is not assigned' {
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                         | Should -Be -ExpectedValue 'Lab'
                    $result.MaximumPackageCount              | Should -Be -ExpectedValue 3
                    $result.MaximumThreadCountPerPackage     | Should -Be -ExpectedValue 5
                    $result.RetryCount                       | Should -Be -ExpectedValue 100
                    $result.DelayBeforeRetryingMins          | Should -Be -ExpectedValue 30
                    $result.MulticastRetryCount              | Should -Be -ExpectedValue 3
                    $result.MulticastDelayBeforeRetryingMins | Should -Be -ExpectedValue 1
                    $result.ClientComputerAccount            | Should -Be -ExpectedValue $true
                    $result.AccessAccounts                   | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'DSC_CMSoftwareDistributionComponent\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnAccounts = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = @('contoso\Network1')
                    MaximumPackageCount              = 3
                    MaximumThreadCountPerPackage     = 5
                    RetryCount                       = 100
                    DelayBeforeRetryingMins          = 30
                    MulticastRetryCount              = 3
                    MulticastDelayBeforeRetryingMins = 1
                    ClientComputerAccount            = $false
                }

                $getReturnComputerAccount = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = $null
                    MaximumPackageCount              = 4
                    MaximumThreadCountPerPackage     = 4
                    RetryCount                       = 99
                    DelayBeforeRetryingMins          = 20
                    MulticastRetryCount              = 2
                    MulticastDelayBeforeRetryingMins = 2
                    ClientComputerAccount            = $true
                }

                $inputAccessAccounts = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = @('contoso\Network1')
                    MaximumPackageCount              = 3
                    MaximumThreadCountPerPackage     = 5
                    RetryCount                       = 100
                    DelayBeforeRetryingMins          = 30
                    MulticastRetryCount              = 3
                    MulticastDelayBeforeRetryingMins = 1
                    ClientComputerAccount            = $false
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMSoftwareDistributionComponent
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $computerAccount = @{
                        SiteCode              = 'Lab'
                        ClientComputerAccount = $true
                    }

                    $accountAccessInEx = @{
                        SiteCode = 'Lab'
                        AccessAccountsToInclude = @('contoso\Network2')
                        AccessAccountsToExclude = @('contoso\Network1')
                    }

                    $inputSpecifyingAllAccountOptions = @{
                        SiteCode                = 'Lab'
                        AccessAccounts          = @('contoso\Network1')
                        AccessAccountsToInclude = @('contoso\Network2')
                        AccessAccountsToExclude = @('contoso\Network3')
                    }

                    Mock -CommandName Get-CMAccount -MockWith { $true }
                }

                It 'Should call expected command when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnComputerAccount }

                    Set-TargetResource @inputAccessAccounts
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 1 -Scope It
                }

                It 'Should call expected command when changing user computer account settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Set-TargetResource @computerAccount
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 1 -Scope It
                }

                It 'Should call expected command when changing accountaccess settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Set-TargetResource @accountAccessInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 1 -Scope It
                }

                It 'Should call expected command all three options for AccessAccounts is specified.' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Set-TargetResource @inputSpecifyingAllAccountOptions
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $excludeAccessAccount = @{
                        SiteCode                = 'Lab'
                        AccessAccountsToExclude = @('contoso\Network1')
                    }

                    $includeAccessAccount = @{
                        SiteCode                = 'Lab'
                        AccessAccountsToInclude = @('contoso\Network2')
                    }

                    $inputAccountOptionsInExMatch = @{
                        SiteCode                = 'Lab'
                        AccessAccountsToInclude = @('contoso\Network2')
                        AccessAccountsToExclude = @('contoso\Network2')
                    }

                    $computerAccountAndInclude = @{
                        SiteCode              = 'Lab'
                        ClientComputerAccount = $true
                        AccessAccounts        = @('contoso\Network1')
                    }

                    $computerAccountFalse = @{
                        SiteCode              = 'Lab'
                        ClientComputerAccount = $false
                    }

                    $allAccounts = 'All AccessAccounts would be removed causing the ClientComputerAccount to be set to true causing invalid configuration.'
                    $accountMissing = 'Account contoso\Network2 is missing from configuration manager unable to add account.'
                    $includeExcludeMatch = 'AccessAccountsToInclude and AccessAccountsToExclude contain the same member contoso\Network2.'
                    $paramsInvalid = 'AccessAccounts and AccessAccountsToInclude or AccessAccountToExclude is specified remove AccessAccounts or the include or exclude setting.'
                    $computerAndAccessAccounts = 'Specifying both ComputerAccount and AccessAccount, these settings can not be specified together.'
                    $computerAccountNoAccess = 'Setting ClientComputerAccount to false and no access account is currently set or specified.'

                    Mock -CommandName Get-CMAccount
                }

                It 'Should call expected command excluding the all accessaccount' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    { Set-TargetResource @excludeAccessAccount } | Should -Throw -ExpectedMessage $allAccounts
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when CMAccounts returns null' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    { Set-TargetResource @includeAccessAccount } | Should -Throw -ExpectedMessage $accountMissing
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when AccessAccountsToInclude and AccessAccountsToExclude contain the same account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    { Set-TargetResource @inputAccountOptionsInExMatch } | Should -Throw -ExpectedMessage $includeExcludeMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when specifying AccessAccounts and setting ClientComputerAccount to true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    { Set-TargetResource @computerAccountAndInclude } | Should -Throw -ExpectedMessage $computerAndAccessAccounts
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected command when specifying ClientComputerAccount to false and no access accounts are specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnComputerAccount }

                    { Set-TargetResource @computerAccountFalse } | Should -Throw -ExpectedMessage $computerAccountNoAccess
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareDistributionComponent -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'DSC_CMSoftwareDistributionComponent\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnAccounts = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = @('contoso\Network1')
                    MaximumPackageCount              = 3
                    MaximumThreadCountPerPackage     = 5
                    RetryCount                       = 100
                    DelayBeforeRetryingMins          = 30
                    MulticastRetryCount              = 3
                    MulticastDelayBeforeRetryingMins = 1
                    ClientComputerAccount            = $false
                }

                $getReturnComputerAccount = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = $null
                    MaximumPackageCount              = 4
                    MaximumThreadCountPerPackage     = 4
                    RetryCount                       = 99
                    DelayBeforeRetryingMins          = 20
                    MulticastRetryCount              = 2
                    MulticastDelayBeforeRetryingMins = 2
                    ClientComputerAccount            = $true
                }

                $inputAccessAccounts = @{
                    SiteCode                         = 'Lab'
                    AccessAccounts                   = @('contoso\Network1')
                    MaximumPackageCount              = 3
                    MaximumThreadCountPerPackage     = 5
                    RetryCount                       = 100
                    DelayBeforeRetryingMins          = 30
                    MulticastRetryCount              = 3
                    MulticastDelayBeforeRetryingMins = 1
                    ClientComputerAccount            = $false
                }

                $inputClientComputer = @{
                    SiteCode              = 'Lab'
                    AccessAccounts        = @('contoso\Network1')
                    ClientComputerAccount = $true
                }

                $inputSpecifyingAllAccountOptions = @{
                    SiteCode                = 'Lab'
                    AccessAccounts          = @('contoso\Network1')
                    AccessAccountsToInclude = @('contoso\Network2')
                    AccessAccountsToExclude = @('contoso\Network3')
                }

                $inputAccountOptionsInEx = @{
                    SiteCode                = 'Lab'
                    AccessAccountsToInclude = @('contoso\Network2')
                    AccessAccountsToExclude = @('contoso\Network3')
                }

                $inputAccountOptionsInExMatch = @{
                    SiteCode                = 'Lab'
                    AccessAccountsToInclude = @('contoso\Network2')
                    AccessAccountsToExclude = @('contoso\Network2')
                }

                $inputAccountExclude = @{
                    SiteCode                = 'Lab'
                    AccessAccountsToExclude = @('contoso\Network1')
                }

                $inputComputerAccessFalse = @{
                    SiteCode              = 'Lab'
                    ClientComputerAccount = $false
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When Get-TargetResource turns present' {

                It 'Should return desired result true when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputAccessAccounts | Should -Be $true
                }

                It 'Should return desired result false when ClientComputerAccount does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnComputerAccount }

                    Test-TargetResource @inputAccessAccounts | Should -Be $false
                }

                It 'Should return desired result false when ClientComputerAccount does not match and specifying accounts' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputClientComputer | Should -Be $false
                }

                It 'Should return desired result true when specifying multiple AccessAccount options' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputSpecifyingAllAccountOptions | Should -Be $true
                }

                It 'Should return desired result false when AccessAccount do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputAccountOptionsInEx | Should -Be $false
                }

                It 'Should return desired result false when AccessAccount include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputAccountOptionsInExMatch | Should -Be $false
                }

                It 'Should return desired result false when AccessAccountExclude removing account' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAccounts }

                    Test-TargetResource @inputAccountExclude | Should -Be $false
                }

                It 'Should return desired result false when specifying ComputerAccess to false and not specifying accessaccount' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnComputerAccount }

                    Test-TargetResource @inputComputerAccessFalse | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
