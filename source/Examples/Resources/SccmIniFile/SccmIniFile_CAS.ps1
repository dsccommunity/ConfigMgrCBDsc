<#
    .SYNOPSIS
        A DSC configuration script to create a CAS ini file for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        SCCMIniFile ExampleSetting
        {
            IniFileName               = 'Lab-CAS-Test.ini'
            IniFilePath               = 'C:\windows\temp\'
            Action                    = 'InstallCAS'
            CDLatest                  = $true
            ProductID                 = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY'
            SiteCode                  = 'LAB'
            SiteName                  = 'Contoso - Central Administration Site'
            SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
            SDKServer                 = 'CAS.contoso.com'
            PreRequisiteComp          = $true
            PreRequisitePath          = 'C:\Windows\Temp\SCCMSetupFiles\Downloads'
            AdminConsole              = $true
            JoinCeip                  = $false
            MobileDeviceLanguage      = $false
            SQLServerName             = 'CAS.contoso.com'
            DatabaseName              = 'CASINST01\CM_LAB'
            SQLSSBPort                = 4022
            SQLDataFilePath           = 'E:\MSSQL12.CASINST01\MSSQL\Data\App\'
            SQLLogFilePath            = 'E:\MSSQL12.CASINST01\MSSQL\Log\App\'
            CloudConnector            = $false
            SAActive                  = $true
            CurrentBranch             = $true
        }
    }
}
