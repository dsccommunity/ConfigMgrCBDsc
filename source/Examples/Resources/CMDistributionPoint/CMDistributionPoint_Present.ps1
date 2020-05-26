<#
    .SYNOPSIS
        A DSC configuration script to add a distribution point from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionPoint ExampleSettings
        {
            SiteCode                        = 'Lab'
            SiteServerName                  = 'DP01.contoso.com'
            Description                     = 'Primary distribution point'
            MinimumFreeSpaceMB              = 100
            PrimaryContentLibraryLocation   = 'F'
            SecondaryContentLibraryLocation = 'C'
            PrimaryPackageShareLocation     = 'F'
            SecondaryPackageShareLocation   = 'C'
            CertificateExpirationTimeUtc    = '5/26/2025'
            ClientCommunicationType         = 'Https'
            BoundaryGroups                  = @('TestBoundary1','TestBoundary2')
            BoundaryGroupStatus             = 'Add'
            AllowPreStaging                 = $true
            EnableAnonymous                 = $true
            EnableBranchCache               = $false
            EnableLedbat                    = $true
            Ensure                          = 'Present'
        }
    }
}
