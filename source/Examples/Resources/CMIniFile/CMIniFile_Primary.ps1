<#
    .SYNOPSIS
        A DSC configuration script to create a Primary ini file for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMIniFile ExampleSetting
        {
            IniFileName                 = 'Lab-PRI-Test.ini'
            IniFilePath                 = 'C:\windows\temp\'
            Action                      = 'InstallPrimarySite'
            CDLatest                    = $true
            ProductID                   = 'Eval'
            SiteCode                    = 'PRI'
            SiteName                    = 'Contoso - Primary Site'
            SMSInstallDir               = 'C:\Program Files\Microsoft Configuration Manager'
            SDKServer                   = 'PRI.contoso.com'
            PreRequisiteComp            = $true
            PreRequisitePath            = 'C:\Windows\Temp\SCCMSetupFiles\Downloads'
            AdminConsole                = $true
            JoinCeip                    = $false
            MobileDeviceLanguage        = $false
            RoleCommunicationProtocol   = 'HTTPorHTTPS'
            ClientsUsePKICertificate    = $true
            ManagementPoint             = 'PRI.contoso.com'
            ManagementPointProtocol     = 'HTTP'
            DistributionPoint           = 'PRI.contoso.com'
            DistributionPointInstallIis = $true
            DistributionPointProtocol   = 'HTTP'
            SQLServerName               = 'PRI.contoso.com'
            DatabaseName                = 'PRIINST01\CM_PRI'
            SQLSSBPort                  = 4022
            SQLDataFilePath             = 'C:\MSSQL12.CASINST01\MSSQL\Data\App\'
            SQLLogFilePath              = 'C:\MSSQL12.CASINST01\MSSQL\Log\App\'
            CloudConnector              = $true
            SAActive                    = $true
            CurrentBranch               = $true
        }
    }
}
