#
# Module manifest for module 'ConfigMgrCBDsc.ResourceHelper'
#
# Generated by: Microsoft Corporation
#
# Generated on: 05/21/2019
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ConfigMgrCBDsc.ResourceHelper.psm1'

    # Version number of this module.
    ModuleVersion = '1.0'

    # ID used to uniquely identify this module
    GUID = 'e73b2d11-812d-4373-99da-95769f055c14'

    # Author of this module
    Author = 'DSC Community'

    # Company or vendor of this module
    CompanyName = 'DSC Community'

    # Copyright statement for this module
    Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module includes functions used in the ConfigMgrCBDsc module.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Functions to export from this module
    FunctionsToExport = @(
        'Import-ConfigMgrPowerShellModule'
        'Convert-CidrToIP'
        'ConvertTo-CimCMScheduleString'
        'ConvertTo-CimBoundaries'
        'Convert-BoundariesIPSubnets'
        'Get-BoundaryInfo'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # DSC resources to export from this module
    DscResourcesToExport = @()

    <#
      Private data to pass to the module specified in RootModule/ModuleToProcess.
      This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    #>
    PrivateData = @{
        PSData = @{
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
