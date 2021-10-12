<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for software center settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsSoftwareCenter 'Default Client Agent Settings'
	    {
            SiteCode                   = 'Lab'
            HideUnapprovedApplication  = $false
            CompanyName                = 'Test'
            HideApplicationCatalogLink = $false
            EnableCustomize            = $true
            EnableOptionsTab           = $true
            ClientSettingName          = 'Default Client Agent Settings'
            EnableStatusTab            = $true
            EnableComplianceTab        = $true
            HideInstalledApplication   = $true
            EnableApplicationsTab      = $true
            ColorScheme                = '#CB4154'
            EnableUpdatesTab           = $true
            EnableOperatingSystemsTab  = $true
	    }

        CMClientSettingsSoftwareCenter 'TestClient'
        {
		    SiteCode          = 'Lab'
            EnableCustomize   = $false
		    ClientSettingName = 'TestClient'
	    }
    }
}
