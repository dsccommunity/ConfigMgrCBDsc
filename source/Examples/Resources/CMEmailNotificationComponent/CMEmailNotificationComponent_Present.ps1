<#
    .SYNOPSIS
        A DSC configuration script to enable email notification component in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMEmailNotificationComponent ExampleSettings
        {
            SiteCode             = 'Lab'
            SendFrom             = 'emailsender@contoso.com'
            SmtpServerFqdn       = 'EmailServer.contoso.com'
            TypeOfAuthentication = 'Other'
            Port                 = 465
            UseSsl               = $true
            Enabled              = $true
            UserName             = 'contoso\EmailUser'
        }
    }
}
