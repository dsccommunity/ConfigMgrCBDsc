<#
    .SYNOPSIS
        A DSC configuration script to remove an account from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        SCCMIniFile ExampleSetting
        {
            IniFileName               = 'Azure-Lab-CAS-Test.ini'
            IniFilePath               = 'C:\temp\'
            Action                    = 'InstallCAS'
            CDLatest                  = ''
            ProductID                 = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY'
            SiteCode                  = 'LAB'
            SiteName                  = 'Contoso - Central Administration Site'
            SMSInstallDir             = 'E:\Apps\Microsoft Configuration Manager'
            SDKServer                 = 'CA01.contoso.com'
            PreRequisiteComp          = $true
            PreRequisitePath          = 'E:\SetupFiles\SCCMSetupFiles\Downloads'
            AdminConsole              = $true
            JoinCeip                  = $false
            MobileDeviceLanguage      = $false
            RoleCommunicationProtocol = ''
            ClientsUsePKICertificate  = ''
            ManagementPoint           = ''
            ManagementPointProtocol   = ''
            DistributionPoint         = ''
            DistributionPointProtocol = ''
            AddServerLanguages        = ''
            AddClientLanguages        = ''
            DeleteServerLanguages     = ''
            DeleteClientLanguages     = ''
            SQLServerName             = 'CA01.contoso.com'
            DatabaseName              = 'CA12INST01\CM_LAB'
            SQLSSBPort                = 4022
            SQLDataFilePath           = 'E:\MSSQL12.CA12INST01\MSSQL\Data\App\'
            SQLLogFilePath            = 'E:\MSSQL12.CA12INST01\MSSQL\Log\App\'
            CloudConnector            = $false
            CloudConnectorServer      = ''
            UseProxy                  = ''
            ProxyName                 = ''
            ProxyPort                 = ''
            SAActive                  = $true
            CurrentBranch             = $true
        }
    }
}
