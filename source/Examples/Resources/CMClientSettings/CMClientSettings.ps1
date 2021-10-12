<#
    .SYNOPSIS
        A DSC configuration script to create\modify\remove client settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettings DevicePresent
        {
            SiteCode                = 'Lab'
            ClientSettingName       = 'TestClient'
            Type                    = 'Device'
            Description             = 'Device Policy'
            SecurityScopesToInclude = @('Scope1','Scope1')
            SecurityScopesToExclude = @('Default')
            Ensure                  = 'Present'
        }

        CMClientSettings User
        {
            SiteCode          = 'Lab'
            ClientSettingName = 'TestUser'
            Type              = 'User'
            Description       = 'User Policy'
            SecurityScopes    = @('Default','Scope1')
            Ensure            = 'Present'
        }

        CMClientSettings DeviceAbsent
        {
            SiteCode          = 'Lab'
            ClientSettingName = 'TestClient2'
            Type              = 'Device'
            Ensure            = 'Absent'
        }
    }
}
