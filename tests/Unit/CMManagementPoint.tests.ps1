[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

BeforeAll {
    # Import Stub function
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction 'SilentlyContinue'

    # Import DscResource.Test Module
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    # Variables used for each Initialize-TestEnvironment
    $initalize = @{
        DSCModuleName   = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMManagementPoint'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMManagementPoint\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint
        Mock -CommandName Set-Location

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

        $cmAlert = @(
            @{
                Name           = '$MPRoleHealthAlertName'
                TypeInstanceId = '["Display=\\MP.contoso.com\"]MSWNET:["SMS_SITE=Lab"]'
            }
        )

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
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving boundary group settings' {

        It 'Should return desired result when management is not currently installed' {
            Mock -CommandName Get-CMManagementPoint
            Mock -CommandName Get-CMAlert

            $result = Get-TargetResource @getInput
            $result                       | Should -BeOfType System.Collections.HashTable
            $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
            $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
            $result.EnableSsl             | Should -BeNullOrEmpty
            $result.ClientConnectionType  | Should -BeNullOrEmpty
            $result.UseSiteDatabase       | Should -BeNullOrEmpty
            $result.GenerateAlert         | Should -BeNullOrEmpty
            $result.EnableCloudGateway    | Should -BeNullOrEmpty
            $result.UseComputerAccount    | Should -BeNullOrEmpty
            $result.SQLServerFqdn         | Should -BeNullOrEmpty
            $result.SqlServerInstanceName | Should -BeNullOrEmpty
            $result.DatabaseName          | Should -BeNullOrEmpty
            $result.Username              | Should -BeNullOrEmpty
            $result.Ensure                | Should -Be -ExpectedValue 'Absent'
        }

        It 'Should return desired result when management is currently installed' {
            Mock -CommandName Get-CMManagementPoint -MockWith { $getMpReturnNoSQL }
            Mock -CommandName Get-CMAlert -MockWith { $cmAlert }

            $result = Get-TargetResource @getInput
            $result                       | Should -BeOfType System.Collections.HashTable
            $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
            $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
            $result.EnableSsl             | Should -Be -ExpectedValue 1
            $result.ClientConnectionType  | Should -Be -ExpectedValue 'InternetAndIntranet'
            $result.UseSiteDatabase       | Should -Be -ExpectedValue 1
            $result.GenerateAlert         | Should -BeTrue
            $result.EnableCloudGateway    | Should -Be -ExpectedValue 0
            $result.UseComputerAccount    | Should -BeTrue
            $result.SQLServerFqdn         | Should -Be -ExpectedValue ''
            $result.SqlServerInstanceName | Should -BeNullOrEmpty
            $result.DatabaseName          | Should -Be -ExpectedValue ''
            $result.Username              | Should -Be -ExpectedValue ''
            $result.Ensure                | Should -Be -ExpectedValue 'Present'
        }

        It 'Should return desired result when management is currently installed with local SQL' {
            Mock -CommandName Get-CMManagementPoint -MockWith { $getMpReturnLocalSQL }
            Mock -CommandName Get-CMAlert

            $result = Get-TargetResource @getInput
            $result                       | Should -BeOfType System.Collections.HashTable
            $result.SiteCode              | Should -Be -ExpectedValue 'Lab'
            $result.SiteServerName        | Should -Be -ExpectedValue 'MP.contoso.com'
            $result.EnableSsl             | Should -Be -ExpectedValue 1
            $result.ClientConnectionType  | Should -Be -ExpectedValue 'Internet'
            $result.UseSiteDatabase       | Should -Be -ExpectedValue 0
            $result.GenerateAlert         | Should -BeFalse
            $result.EnableCloudGateway    | Should -Be -ExpectedValue 1
            $result.UseComputerAccount    | Should -BeFalse
            $result.SQLServerFqdn         | Should -Be -ExpectedValue 'MP.contoso.com'
            $result.SqlServerInstanceName | Should -Be -ExpectedValue 'MP01'
            $result.DatabaseName          | Should -Be -ExpectedValue 'CM_Lab'
            $result.Username              | Should -Be -ExpectedValue 'contoso\TestUser'
            $result.Ensure                | Should -Be -ExpectedValue 'Present'
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMManagementPoint\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        $inputUseSiteDatabaseMisMatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $true
        }

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint
        Mock -CommandName Set-Location
        Mock -CommandName Get-CMSiteSystemServer
        Mock -CommandName New-CMSiteSystemServer
        Mock -CommandName Add-CMManagementPoint
        Mock -CommandName Set-CMManagementPoint
        Mock -CommandName Remove-CMManagementPoint
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        BeforeEach {
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

            $inputGatewayAndSsl = @{
                SiteCode             = 'Lab'
                SiteServerName       = 'MP.contoso.com'
                EnableCloudGateway   = $false
                ClientConnectionType = 'Intranet'
                EnableSsl            = $false
                Ensure               = 'Present'
            }

            $inputAbsent = @{
                SiteCode       = 'Lab'
                SiteServerName = 'MP.contoso.com'
                Ensure         = 'Absent'
            }
        }
        It 'Should call expected commands for when changing settings' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Set-TargetResource @inputUseSiteDatabaseMisMatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when management point is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

            Set-TargetResource @inputGatewayAndSsl
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when management point is present and setting gateway and SSL are false' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Set-TargetResource @inputGatewayAndSsl
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 2 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when management point is absent and gateway and SSL are false' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

            Set-TargetResource @inputGatewayAndSsl
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when management point exists and expected absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Set-TargetResource @inputAbsent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 1 -Scope It
        }
    }

    Context 'When Set-TargetResource throws' {
        BeforeEach {

        }
        It 'Should call throws when Gateway is enabled and connection type is intranet' {
            $gatewayThrow = @{
                SiteCode             = 'Lab'
                SiteServerName       = 'MP.contoso.com'
                EnableCloudGateway   = $true
                ClientConnectionType = 'Intranet'
            }

            $gatewayThrowMsg = 'When CloudGateway is enabled, ClientConnectionType must not equal Intranet.'

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @gatewayThrow } | Should -Throw -ExpectedMessage $gatewayThrowMsg
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call throws when Gateway is enabled and SSL is false' {
            $sslThrow = @{
                SiteCode             = 'Lab'
                SiteServerName       = 'MP.contoso.com'
                EnableCloudGateway   = $true
                ClientConnectionType = 'Internet'
                EnableSsl            = $false
            }

            $sslThrowMsg = 'When CloudGateway is enabled SSL must also be enabled.'

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @sslThrow } | Should -Throw -ExpectedMessage $sslThrowMsg
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call throws when sql server specified and no database name' {
            $sqlServerNoDatabaseParam = @{
                SiteCode       = 'Lab'
                SiteServerName = 'MP.contoso.com'
                SqlServerFqdn  = 'MP.contoso.com'
            }

            $sqlDbError = 'SQLServerFqdn and database name must be specified together.'

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @sqlServerNoDatabaseParam } | Should -Throw -ExpectedMessage $sqlDbError
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call throws when gateway disabled and connection type is not Intranet' {
            $gatewayFalseClientInternetThrow = @{
                SiteCode             = 'Lab'
                SiteServerName       = 'MP.contoso.com'
                EnableCloudGateway   = $false
                ClientConnectionType = 'Internet'
            }

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @gatewayFalseClientInternetThrow } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call throws when usesitedatabase and Sqlserver are specified together' {
            $sqlSiteDatabaseThrow = @{
                SiteCode        = 'Lab'
                SiteServerName  = 'MP.contoso.com'
                SqlServerFqdn   = 'MP.contoso.com'
                DatabaseName    = 'Lab'
                UseSiteDatabase = $true
            }

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @sqlSiteDatabaseThrow } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }

        It 'Should call throws when usecomputeraccount and username are specified together' {
            $computerAccountUserAccount = @{
                SiteCode           = 'Lab'
                SiteServerName     = 'MP.contoso.com'
                Username           = 'contoso\test'
                UseComputerAccount = $true
            }

            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            { Set-TargetResource @computerAccountUserAccount } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMManagementPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMManagementPoint -Exactly 0 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMManagementPoint\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        $inputUseSiteDatabaseMisMatch = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'MP.contoso.com'
            Ensure          = 'Present'
            UseSiteDatabase = $true
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

        Mock -CommandName Set-Location
        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMManagementPoint
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource' {

        It 'Should return desired result false when ensure = present and MP is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

            Test-TargetResource @inputPresent  | Should -BeFalse
        }

        It 'Should return desired result true when ensure = absent and MP is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

            Test-TargetResource @inputAbsent | Should -BeTrue
        }

        It 'Should return desired result false when ensure = absent and MP is present' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputAbsent | Should -BeFalse
        }

        It 'Should return desired result true when ensure = present and use site database matches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputUseSiteDatabaseMatch | Should -BeTrue
        }

        It 'Should return desired result false when ensure = present and use site database not matches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputUseSiteDatabaseMisMatch | Should -BeFalse
        }

        It 'Should return desired result true when ensure = present and username matches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputUsernameMatch | Should -BeTrue
        }

        It 'Should return desired result false when ensure = present and username not matches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputUsernameMisMatch | Should -BeFalse
        }

        It 'Should return desired result false when ensure = present and multiple mismatches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputMultipleMismatch | Should -BeFalse
        }

        It 'Should return desired result true when ensure = present and multiple matches' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Test-TargetResource @inputMultipleMatch | Should -BeTrue
        }
    }
}
