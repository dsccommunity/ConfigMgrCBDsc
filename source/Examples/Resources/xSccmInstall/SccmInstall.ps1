#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration Install Microsoft System Center Configuration Manager.
#>
Configuration SCCMInstall
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SccmInstallAccount
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {

        xSccmInstall SccmInstall
        {
            SetupExePath       = 'C:\Temp\SCCMInstall\SMSSETUP\BIN\X64'
            IniFile            = 'C:\temp\Lab-CAS-Test.ini'
            SccmServerType     = 'CAS'
            SccmInstallAccount = $SccmInstallAccount
            DependsOn          = '[xSccmPreReqs]SCCMPreReqs','[xSccmSqlSetup]SccmSqlSetup','[SccmIniFile]CreateSCCMIniFile'
        }
    }
}
