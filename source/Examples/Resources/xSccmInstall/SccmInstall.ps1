#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration Install Microsoft System Center Configuration Manager.
#>
Configuration Example
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
        }
    }
}
