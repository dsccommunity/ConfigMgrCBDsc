<#
    .SYNOPSIS
        A DSC configuration script to add a boundary group and remove boundaries from
        the boundary group in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMBoundaryGroups ExampleSettings
        {
            SiteCode                = 'Lab'
            BoundaryGroup           = 'TestGroup'
            SiteSystemsToExclude    = @('DP01.contoso.com','DP02.contoso.com')
            SecurityScopesToExclude = @('Scope1','Scope2')
            Boundaries              = @(
                DSC_CMBoundaryGroupsBoundaries
                {
                    Value = '10.1.1.1/24'
                    Type  = 'IPSubnet'
                }
                DSC_CMBoundaryGroupsBoundaries
                {
                    Value = '10.1.1.1-10.1.1.255'
                    Type  = 'IPRange'
                }
                DSC_CMBoundaryGroupsBoundaries
                {
                    Value = 'First-Site'
                    Type  = 'AdSite'
                }
            )
            BoundaryAction          = 'Remove'
        }
    }
}
