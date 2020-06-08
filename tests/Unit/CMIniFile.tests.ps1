param ()

# Begin Testing
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
        DSCResourceName = 'DSC_CMIniFile'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }

    $mockCasIniFile = @(
        '[Identification]
        Action=InstallCAS

        [Options]
        ProductID=Eval
        SiteCode=CAS
        SiteName=Contoso - Central Administration Site
        SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
        SDKServer=CAS.contoso.com
        PrerequisiteComp=1
        PrerequisitePath=C:\Windows\Temp\SCCMInstall\Downloads
        MobileDeviceLanguage=0
        AdminConsole=1
        JoinCEIP=0

        [SQLConfigOptions]
        SQLServerName=CAS.contoso.com
        DatabaseName=CASINST01\CM_LAB
        SQLSSBPort=4022
        SQLDataFilePath=C:\MSSQL12.CASINST01\MSSQL\Data\App\
        SQLLogFilePath=C:\MSSQL12.CASINST01\MSSQL\Log\App\

        [CloudConnectorOptions]
        CloudConnector=0
        CloudConnectorServer=CAS.contoso.com
        UseProxy=0

        [SABranchOptions]
        CurrentBranch=1'
    )

    $mockPrimaryIniFile = @(
        '[Identification]`
        Action=InstallPrimarySite
        CDLatest=1

        [Options]
        ProductID=EVAL
        SiteCode=PRI
        SiteName=Contoso - Primary Site
        SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
        SDKServer=PRI.contoso.com
        RoleCommunicationProtocol=HTTPorHTTPS
        ClientsUsePKICertificate=1
        PrerequisiteComp=1
        PrerequisitePath=C:\Windows\Temp\SCCMInstall\Downloads
        MobileDeviceLanguage=0
        AdminConsole=1
        JoinCEIP=0

        [SQLConfigOptions]
        SQLServerName=PRI.contoso.com
        DatabaseName=PRIINST01\CM_PRI
        SQLSSBPort=4022
        SQLDataFilePath=E:\MSSQL12.PRIINST01\MSSQL\Data\App\
        SQLLogFilePath=E:\MSSQL12.PRIINST01\MSSQL\Log\App\

        [CloudConnectorOptions]
        CloudConnector=0
        CloudConnectorServer=
        UseProxy=0

        [HierarchyExpansionOption]
        CCARSiteServer=CAS.contoso.com'
    )
}

Describe 'ConfigMgrCBDsc - CMIniFile\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving ini file settings' {
        BeforeEach {
            $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
            $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini
        }
        It 'Should return the settings in ini file, <FileName>, when it exists' -TestCases @(
            @{
                Test = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename          = 'InstallCas.ini'
            }
            @{
                Test = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename               = 'InstallPrimary.ini'
            }
        ){

            $result = Get-TargetResource @Test
            $result | Should -BeOfType System.Collections.HashTable
            Write-Host -Object $result.Value
            $result.GetEnumerator().Where({$_.Value -ne $null}).Count | Should -Be $(`
                if ($Test.IniFilename -eq 'InstallCas.ini')
                {
                    20 # This is from the parameters that are in mock ini files line:38
                }
                if ($Test.IniFilename -eq 'InstallPrimary.ini')
                {
                    22 # This is from the parameters that are in mock ini files line:70
                }
            )
        }

        It 'Should return parametes when no ini file exists for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Mock -CommandName Get-Content -ModuleName DSC_CMIniFile

            $result = Get-TargetResource @Test
            $result | Should -BeOfType System.Collections.HashTable
            foreach ($item in $results)
            {
                $item.Value | Should -Be -ExpectedValue $Test."$($item.Key)"
            }
        }
    }
}

Describe 'ConfigMgrCBDsc - CMIniFile\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize

        $primaryInstallOptionalSettings = @{
            ManagementPoint           = 'PRI.contoso.com'
            ManagementPointProtocol   = 'HTTP'
            DistributionPoint         = 'PRI.contoso.com'
            DistributionPointProtocol = 'HTTP'
            CCARSiteServer            = 'CAS.contoso.com'
            CasRetryInterval          = '30'
            WaitForCasTimeout         = '30'
        }

        $optionalParamatersAll = @{
            CDLatest              = $true
            AddServerLanguages    = 'DEU'
            AddClientLanguages    = 'DEU'
            DeleteServerLanguages = 'FRA'
            DeleteClientLanguages = 'FRA'
            SQLSSBPort            = 4022
            SQLDataFilePath       = 'C:\MSSQL12.CASINST01\MSSQL\Data\App\'
            SQLLogFilePath        = 'C:\MSSQL12.CASINST01\MSSQL\Log\App\'
            CloudConnectorServer  = 'CAS.contoso.com'
            UseProxy              = $true
            ProxyName             = 'Proxy.contoso.com'
            ProxyPort             = '8080'
            SAActive              = $true
            CurrentBranch         = $true
        }

    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {
        It 'Should not throw with minimal parameters for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Set-TargetResource @Test
            Get-Item -LiteralPath "$($Test.IniFilePath)/$($Test.IniFilename)" | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw with optional parameters for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            $combined = $Test + $optionalParamatersAll
            Set-TargetResource @combined
            Get-Item -LiteralPath "$($Test.IniFilePath)/$($Test.IniFilename)" | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw with all optional parameters for the primary config ini' -TestCases @(
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            $combined = $Test + $optionalParamatersAll + $primaryInstallOptionalSettings
            Set-TargetResource @combined
            Get-Item -LiteralPath "$($Test.IniFilePath)/$($Test.IniFilename)" | Should -Not -BeNullOrEmpty
        }
    }

    Context "When Set-TargetResource for $($Test.IniFilename) has incorrect parameters" {
        BeforeEach {
            if ($Test.IniFilename -eq 'InstallCas.ini')
            {
                $wrongParameters = $Test.clone()
                $wrongParameters.Add('ManagementPoint','PRI.contoso.com')
                $message = 'The parameters ManagementPoint, ManagementPointProtocol, DistributionPoint, ' +
                    'DistributionPointProtocol, RoleCommunicationProtocol, ClientsUsePKICertificate, ' +
                'CCARSiteServer, CASRetryInterval, WaitForCASTimeout are used only with InstallPrimarySite.'
            }

            if ($Test.IniFilename -eq 'InstallPrimary.ini')
            {
                $wrongParameters = $Test.Clone()
                $wrongParameters.CloudConnector = $true
                $wrongParameters.Add('CloudConnectorServer','CAS.contoso.com')
                $message = 'If CloudConnector is True you must provide CloudConnectorServer and UseProxy.'
            }
        }
        It 'Should throw because Wrong parameter for CAS' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
        ){
            { Set-TargetResource @wrongParameters } | Should -Throw -ExpectedMessage $message
        }

        It 'Should throw because Missing Cloud Connector parameter' -TestCases @(
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            { Set-TargetResource @wrongParameters } | Should -Throw -ExpectedMessage $message
        }

        It 'Should throw because missing proxy parameters in <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            $proxyTest = $Test.Clone()
            $proxyTest.Add('UseProxy', $true)
            { Set-TargetResource @proxyTest } | Should -Throw -ExpectedMessage 'If Proxy is True, you must provide ProxyName and ProxyPort.'
        }
    }
}

Describe 'ConfigMgrCBDsc - CMIniFile\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $testEnvironment = Initialize-TestEnvironment @initalize
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

        # Order of the Context blocks matter since some attributes are being changed in different Context.
    Context "When ini file does not exist for" {
        It 'Should return false for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Test-TargetResource @Test | Should -BeFalse
        }
    }

    Context "When ini file exists and is not missing any parameters" {
        BeforeEach {
            $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
            $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini
        }

        It 'Should return true for <Filename>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Test-TargetResource @Test | Should -BeTrue
        }
    }

    Context "When ini file exists and parameters don't match" {
        BeforeEach {
            $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
            $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

            # Change parameters so that they don't match.
            $Test.SiteCode = 'LAB'
            $Test.SMSInstallDir ='C:\Apps\Microsoft Configuration Manager'
        }

        It 'Should return false for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Test-TargetResource @Test | Should -BeFalse
        }
    }

    Context "When ini file exists and is missing parameters" {
        BeforeEach {
            $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
            $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

            # Adding a value that is missing against the file being tested.
            $Test.Add('SAActive',$true)
        }

        It 'Should return false for <FileName>' -TestCases @(
            @{
                Test     = @{
                    IniFilename          = 'InstallCas.ini'
                    IniFilePath          = 'TestDrive:\'
                    Action               = 'InstallCAS'
                    ProductID            = 'Eval'
                    SiteCode             = 'CAS'
                    SiteName             = 'Contoso - Central Administration Site'
                    SMSInstallDir        = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer            = 'CAS.contoso.com'
                    PreRequisiteComp     = $true
                    PreRequisitePath     = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole         = $true
                    JoinCeip             = $false
                    MobileDeviceLanguage = $false
                    SQLServerName        = 'CAS.contoso.com'
                    DatabaseName         = 'CASINST01\CM_LAB'
                    CloudConnector       = $false
                }
                Filename = 'InstallCas.ini'
            }
            @{
                Test     = @{
                    IniFilename               = 'InstallPrimary.ini'
                    IniFilePath               = 'TestDrive:\'
                    Action                    = 'InstallPrimarySite'
                    ProductID                 = 'Eval'
                    SiteCode                  = 'PRI'
                    SiteName                  = 'Contoso - Primary Site'
                    SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
                    SDKServer                 = 'PRI.contoso.com'
                    PreRequisiteComp          = $true
                    PreRequisitePath          = 'C:\Windows\Temp\SCCMInstall\Downloads'
                    AdminConsole              = $true
                    JoinCeip                  = $false
                    RoleCommunicationProtocol = 'HTTPorHTTPS'
                    ClientsUsePKICertificate  = $true
                    MobileDeviceLanguage      = $false
                    SQLServerName             = 'PRI.contoso.com'
                    DatabaseName              = 'PRIINST01\CM_PRI'
                    CloudConnector            = $false
                }
                Filename = 'InstallPrimary.ini'
            }
        ){
            Test-TargetResource @Test | Should -BeFalse
        }
    }
}
