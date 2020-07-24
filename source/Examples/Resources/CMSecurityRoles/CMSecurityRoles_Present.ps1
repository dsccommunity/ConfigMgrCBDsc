<#
    .SYNOPSIS
        A DSC configuration script to add Security Roles to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSecurityRoles ExampleSettingsOverwrite
        {
            SiteCode          = 'Lab'
            SecurityRoleName  = 'Field Services'
            Description       = ''
            XmlPath           = 'C:\Temp\Field Services.xml'
            OverWrite         = $true
            Ensure            = 'Present'
        }

        CMSecurityRoles ExampleSettingsAppend
        {
            SiteCode          = 'Lab'
            SecurityRoleName  = 'Site Admins'
            Description       = ''
            XmlPath           = 'C:\Temp\Site Admins.xml'
            Append            = $true
            Ensure            = 'Present'
        }
    }
}
