<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for computer agent settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsComputerAgent DefaultAgent
        {
            SiteCode                       = 'Lab'
            EnableThirdPartyOrchestration  = 'No'
            InterimReminderHr              = 4
            FinalReminderMins              = 15
            DisplayNewProgramNotification  = $true
            BrandingTitle                  = 'Default Company'
            InitialReminderHr              = 48
            PowerShellExecutionPolicy      = 'Bypass'
            UseOnPremisesHealthAttestation = $true
            ClientSettingName              = 'Default Client Agent Settings'
            SuspendBitLocker               = 'Never'
            InstallRestriction             = 'AllUsers'
            EnableHealthAttestation        = $true
            UseNewSoftwareCenter           = $true
        }

        CMClientSettingsComputerAgent DeviceAgent
        {
            SiteCode                       = 'Lab'
            EnableThirdPartyOrchestration  = 'Yes'
            InterimReminderHr              = 4
            FinalReminderMins              = 15
            DisplayNewProgramNotification  = $true
            InitialReminderHr              = 48
            PowerShellExecutionPolicy      = 'Restricted'
            UseOnPremisesHealthAttestation = $true
            ClientSettingName              = 'ClientTest'
            SuspendBitLocker               = 'Always'
            InstallRestriction             = 'NoUsers'
            EnableHealthAttestation        = $true
            UseNewSoftwareCenter           = $false
        }
    }
}
