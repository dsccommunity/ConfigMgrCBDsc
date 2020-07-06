<#
    .SYNOPSIS
        A DSC configuration script to remove an administrative users in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAdministrativeUser User1
        {
            SiteCode  = 'Lab'
            AdminName = 'contoso\User1'
            Ensure    = 'Absent'
        }
    }
}
