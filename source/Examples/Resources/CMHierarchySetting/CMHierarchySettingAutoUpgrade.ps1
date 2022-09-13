<#
    .SYNOPSIS
        A DSC configuration script to enable automatic client upgrade while
        excluding servers and all machines in the collection called 'NoAutoUpgrade'.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMHierarchySetting ExampleSettings
        {
            SiteCode                  = 'Lab'
            EnableAutoClientUpgrade   = $true
            EnableExclusionCollection = $true
            ExcludeServer             = $true
            ExclusionCollectionName   = 'NoAutoUpgrade'
            AutoUpgradeDays           = 7
        }
    }
}
