[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMManagementPoint'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMManagementPoint'

        $getInput = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
        }

        $getMpReturnNoSQL = @{
            SiteCode = 'Lab'
            SslState = 1
            Props    = @(
                @{
                    PropertyName = 'AllowProxyTraffic'
                    Value        = 0
                }
                @{
                    PropertyName = 'UseSiteDatabase'
                    Value        = 1
                }
                @{
                    PropertyName = 'SqlServerName'
                    Value2       = ''
                }
                @{
                    PropertyName = 'MPInternetFacing'
                    Value        = '1'
                }
                @{
                    PropertyName = 'MPIntranetFacing'
                    Value        = '1'
                }
                @{
                    PropertyName = 'UserName'
                    Value2       = ''
                }
                @{
                    PropertyName = 'DatabaseName'
                    Value2       = ''
                }
            )
        }

        $getMpReturnLocalSQL = @{
            SiteCode = 'Lab'
            SslState = 1
            Props    = @(
                @{
                    PropertyName = 'AllowProxyTraffic'
                    Value        = 1
                }
                @{
                    PropertyName = 'UseSiteDatabase'
                    Value        = 0
                }
                @{
                    PropertyName = 'SqlServerName'
                    Value2       = 'MP.contoso.com'
                }
                @{
                    PropertyName = 'MPInternetFacing'
                    Value        = '1'
                }
                @{
                    PropertyName = 'MPIntranetFacing'
                    Value        = '0'
                }
                @{
                    PropertyName = 'UserName'
                    Value2       = 'contoso\TestUser'
                }
                @{
                    PropertyName = 'DatabaseName'
                    Value2       = 'mp01\CM_Lab'
                }
            )
        }

        $cmAlert = @(
            @{
                Name           = '$MPRoleHealthAlertName'
                TypeInstanceId = '["Display=\\MP.contoso.com\"]MSWNET:["SMS_SITE=Lab"]'
            }
        )

        $getReturnAll = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'MP.contoso.com'
            EnableSSL             = 1
            ClientConnectionType  = 'Internet'
            UseSiteDatabase       = 0
            GenerateAlert         = $true
            EnableCloudGateway    = 1
            UseComputerAccount    = $false
            SqlServerFqdn         = 'MP.contoso.com'
            SQLServerInstanceName = 'MP01'
            DatabaseName          = 'CM_Lab'
            Username              = 'contoso\TestUser'
            Ensure                = 'Present'
        }

        $getReturnAbsent = @{
            SiteCode              = 'Lab'
            SiteServerName        = 'MP.contoso.com'
            EnableSSL             = $null
            ClientConnectionType  = $null
            UseSiteDatabase       = $null
            GenerateAlert         = $null
            EnableCloudGateway    = $null
            UseComputerAccount    = $null
            SqlServerFqdn         = $null
            SQLServerInstanceName = $null
            DatabaseName          = $null
            Username              = $null
            Ensure                = 'Absent'
        }

        $inputAbsent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
            Ensure         = 'Absent'
        }

        $inputPresent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
            Ensure         = 'Present'
        }

        $inputUseSiteDatabaseMatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $false
        }

        $inputUseSiteDatabaseMisMatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $true
        }

        $inputUsernameMatch = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
            Ensure         = 'Present'
            UserName       = 'contoso\TestUser'
        }

        $inputUsernameMisMatch = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
            Ensure         = 'Present'
            UserName       = ''
        }

        $inputMultipleMatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $false
            UserName        = 'contoso\TestUser'
        }

        $inputMultipleMismatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $true
            UserName        = ''
        }

        $gatewayThrow = @{
            SiteCode             = 'Lab'
            SiteServerName       = 'MP.contoso.com'
            EnableCloudGateway   = $true
            ClientConnectionType = 'Intranet'
        }

        $gatewayThrowMsg = 'When CloudGateway is enabled, ClientConnectionType must not equal Intranet'

        $sslThrow = @{
            SiteCode             = 'Lab'
            SiteServerName       = 'MP.contoso.com'
            EnableCloudGateway   = $true
            ClientConnectionType = 'Internet'
            EnableSsl            = $false
        }

        $sslThrowMsg = 'When CloudGateway is enabled SSL must also be enabled'

        $sqlServerNoDatabaseParam = @{
            SiteCode       = 'Lab'
            SiteServerName = 'MP.contoso.com'
            SqlServerFqdn  = 'MP.contoso.com'
        }

        $sqlDbError = 'SQLServerFqdn and database name must be specified together'

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving boundary group settings' {

                It 'Should return desired result when management is not currently installed' {
                    Mock -CommandName Get-CMManagementPoint -MockWith { $null  }
                    Mock -CommandName Get-CMAlert -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
                    $result.EnableSsl             | Should -Be -ExpectedValue $null
                    $result.ClientConnectionType  | Should -Be -ExpectedValue $null
                    $result.UseSiteDatabase       | Should -Be -ExpectedValue $null
                    $result.GenerateAlert         | Should -Be -ExpectedValue $null
                    $result.EnableCloudGateway    | Should -Be -ExpectedValue $null
                    $result.UseComputerAccount    | Should -Be -ExpectedValue $null
                    $result.SQLServerFqdn         | Should -Be -ExpectedValue $null
                    $result.SqlServerInstanceName | Should -Be -ExpectedValue $null
                    $result.DatabaseName          | Should -Be -ExpectedValue $null
                    $result.Username              | Should -Be -ExpectedValue $null
                    $result.Ensure                | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when management is currently installed' {
                    Mock -CommandName Get-CMManagementPoint -MockWith { $getMpReturnNoSQL  }
                    Mock -CommandName Get-CMAlert -MockWith { $cmAlert }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
                    $result.EnableSsl             | Should -Be -ExpectedValue 1
                    $result.ClientConnectionType  | Should -Be -ExpectedValue 'InternetAndIntranet'
                    $result.UseSiteDatabase       | Should -Be -ExpectedValue 1
                    $result.GenerateAlert         | Should -Be -ExpectedValue $true
                    $result.EnableCloudGateway    | Should -Be -ExpectedValue 0
                    $result.UseComputerAccount    | Should -Be -ExpectedValue $true
                    $result.SQLServerFqdn         | Should -Be -ExpectedValue ''
                    $result.SqlServerInstanceName | Should -Be -ExpectedValue $null
                    $result.DatabaseName          | Should -Be -ExpectedValue ''
                    $result.Username              | Should -Be -ExpectedValue ''
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when management is currently installed with local SQL' {
                    Mock -CommandName Get-CMManagementPoint -MockWith { $getMpReturnLocalSQL  }
                    Mock -CommandName Get-CMAlert -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                       | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
                    $result.EnableSsl             | Should -Be -ExpectedValue 1
                    $result.ClientConnectionType  | Should -Be -ExpectedValue 'Internet'
                    $result.UseSiteDatabase       | Should -Be -ExpectedValue 0
                    $result.GenerateAlert         | Should -Be -ExpectedValue $false
                    $result.EnableCloudGateway    | Should -Be -ExpectedValue 1
                    $result.UseComputerAccount    | Should -Be -ExpectedValue $false
                    $result.SQLServerFqdn         | Should -Be -ExpectedValue 'MP.contoso.com'
                    $result.SqlServerInstanceName | Should -Be -ExpectedValue 'MP01'
                    $result.DatabaseName          | Should -Be -ExpectedValue 'CM_Lab'
                    $result.Username              | Should -Be -ExpectedValue 'contoso\TestUser'
                    $result.Ensure                | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMManagementPoint
                Mock -CommandName Set-CMManagementPoint
                Mock -CommandName Remove-CMManagementPoint

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputUseSiteDatabaseMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when collection is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputUseSiteDatabaseMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when collection collection exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMManagementPoint
                Mock -CommandName Set-CMManagementPoint
                Mock -CommandName Remove-CMManagementPoint

                It 'Should call throws when Gateway is enabled and connection type is intranet' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @gatewayThrow } | Should -Throw -ExpectedMessage $gatewayThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when Gateway is enabled and SSL is false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @sslThrow } | Should -Throw -ExpectedMessage $sslThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when sql server specified and no database name' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @sqlServerNoDatabaseParam } | Should -Throw -ExpectedMessage $sqlDbError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMManagementPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMManagementPoint -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource' {

                It 'Should return desired result false when ensure = present and MP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and MP is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false when ensure = absent and MP is present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result true when ensure = present and use site database matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUseSiteDatabaseMatch | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and use site database not matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUseSiteDatabaseMisMatch | Should -Be $false
                }

                It 'Should return desired result true when ensure = present and username matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUsernameMatch | Should -Be $true
                }

                It 'Should return desired result false when ensure = present and username not matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputUsernameMisMatch | Should -Be $false
                }

                It 'Should return desired result false when ensure = present and multiple mismatches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputMultipleMismatch | Should -Be $false
                }

                It 'Should return desired result true when ensure = present and multiple matches' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Test-TargetResource @inputMultipleMatch | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
