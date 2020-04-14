$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'MSFT_SccmIniFile'

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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $moduleResourceName = 'ConfigMgrCBDsc - SccmIniFile'

        $tests = @(
            @{
                IniFileName          = 'InstallCas.ini'
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
            @{
                IniFileName               = 'InstallPrimary.ini'
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
        )

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

        Describe "$moduleResourceName\Get-TargetResource" {
            foreach ($test in $tests)
            {
                Context "When retrieving ini file settings for $($test.IniFileName)" {
                    $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
                    $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

                    It 'Should return the settings in an ini file when it exists' {
                        $result = Get-TargetResource @test
                        $result | Should -BeOfType System.Collections.HashTable
                        Write-Host -Object $result.Value
                        $result.GetEnumerator().Where({$_.Value -ne $null}).Count | Should -Be $(`
                            if ($test.iniFileName -eq 'InstallCas.ini')
                            {
                                20
                            }
                            if ($test.iniFileName -eq 'InstallPrimary.ini')
                            {
                                22
                            }
                        )
                    }

                    It 'Should return parametes when no ini file exists' {
                        Mock -CommandName Get-Content -MockWith { $null }

                        $result = Get-TargetResource @test
                        $result | Should -BeOfType System.Collections.HashTable
                        foreach ($item in $results)
                        {
                            $item.Value | Should -Be -ExpectedValue $test."$($item.Key)"
                        }
                    }
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            foreach ($test in $tests)
            {
                Context "When Set-TargetResource runs successfully with $($test.IniFileName)" {
                    It 'Should not throw with minmual parameters' {
                        Set-TargetResource @test
                        Get-Item -LiteralPath "$IniFilePath/$IniFileName" | Should -Not -Be $null
                    }

                    It 'Should not throw with optional parameters' {
                        $combined = $test + $optionalParamatersAll
                        Set-TargetResource @combined
                        Get-Item -LiteralPath "$IniFilePath/$IniFileName" | Should -Not -Be $null
                    }
                }

                Context "When Set-TargetResource for $($test.IniFileName) has incorrect parameters" {
                    if ($test.iniFileName -eq 'InstallCas.ini')
                    {
                        $wrongParameters = $test.clone()
                        $wrongParameters.Add('ManagementPoint','PRI.contoso.com')
                        $message = 'The parameters ManagementPoint, ManagementPointProtocol, DistributionPoint,',
                            'DistributionPointProtocol, RoleCommunicationProtocol, ClientsUsePKICertificate,',
                        'CCARSiteServer, CASRetryInterval, WaitForCASTimeout are used only with InstallPrimarySite.'
                        $throwreason = 'Wrong parameter for CAS'

                        It "Should throw because $throwReason" {
                            { Set-TargetResource @wrongParameters } | Should -Throw -ExpectedMessage $message
                        }
                    }
                    if ($test.iniFileName -eq 'InstallPrimary.ini')
                    {
                        $wrongParameters = $test.Clone()
                        $wrongParameters.CloudConnector = $true
                        $wrongParameters.Add('CloudConnectorServer','CAS.contoso.com')
                        $message = 'If CloudConnector is True you must provide CloudConnectorServer and UseProxy.'
                        $throwReason = 'Missing Cloud Connector parameter'

                        It "Should throw because $throwReason" {
                            { Set-TargetResource @wrongParameters } | Should -Throw -ExpectedMessage $message
                        }
                    }

                    It '"Should throw because missing proxy parameters' {
                        $proxyTest = $test.Clone()
                        $proxyTest.Add('UseProxy', $true)
                        { Set-TargetResource @proxyTest } | Should -Throw -ExpectedMessage 'If Proxy is True, you must provide ProxyName and ProxyPort.'
                    }
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            foreach ($test in $tests)
            {
                # Order of the Context blocks matter since some attributes are being changed in different Context.
                Context "When ini file does not exist for $($test.IniFileName)" {
                    It 'Should return false' {
                        $result = Test-TargetResource @test
                        $result | Should -Be $false
                    }
                }

                Context "When ini file exists and is not missing any parameters for $($test.IniFileName)" {
                    $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
                    $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

                    It 'Should return true' {
                        $result = Test-TargetResource @test
                        $result | Should -Be $true
                    }
                }

                Context "When ini file exists and parameters don't match for $($test.IniFileName)" {
                    $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
                    $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

                    $test.SiteCode = 'LAB'
                    $test.SMSInstallDir ='C:\Apps\Microsoft Configuration Manager'

                    It 'Should return false' {
                        $result = Test-TargetResource @test
                        $result | Should -Be $false
                    }
                }

                Context "When ini file exists and is missing parameters for $($test.IniFileName)" {
                    $mockCasIniFile | Out-File -LiteralPath $TestDrive\InstallCAS.ini
                    $mockPrimaryIniFile | Out-File -LiteralPath $TestDrive\InstallPrimary.ini

                    # Adding a value that is missing against the file being tested.
                    $test.Add('SAActive',$true)

                    It 'Should return false' {
                        $result = Test-TargetResource @test
                        $result | Should -Be $false
                    }
                }
            }

        }
    }
}
finally
{
    Invoke-TestCleanup
}
