<#
    .SYNOPSIS
        A DSC  composite resource to configure/install the required PreReqs for SCCM.
        - .NET Framework 3.5 Windows Feature
        - .NET Framework 4.5 or later Windows Feature
        - Remote Differential Compression Windows Feature
        - Windows ADK install
        - Windows ADK WinPE install
        - Windows MDT install
        - Local Administrators
        - Add no_sms_on_drive files

    .PARAMETER AdkSetupExePath
        Specifies the path and filename to the ADK Setup.

    .PARAMETER AdkWinPeSetupPath
        Specifies the path and filename to the ADK WinPE Setup.

    .PARAMETER MdtMsiPath
        Specifies the path and filename to the MDT Setup.

    .PARAMETER LocalAdministrators
        Specifies the accounts and/or groups you want to add to the local adinistrators group.

    .PARAMETER NoSmsOnDrives
        Specifies the drive letters of the drive you don't want SCCM to install on.

    .PARAMETER DomainCredential
        Specifies credentials that have domain read permissions to add domain users or groups to the local
        administrators group.

    .PARAMETER AdkProductName
        Specifies the Product Name for ADK.
        Default: Windows Assessment and Deployment Kit - Windows 10

    .PARAMETER AdkProductID
        Specifies the Product ID for ADK.
        Default: fb450356-9879-4b2e-8dc9-282709286661

    .PARAMETER AdkWinPeProductName
        Specifies the Product Name for  ADK WinPE.
        Default: Windows Assessment and Deployment Kit Windows Preinstallation Environment Add-ons - Windows 10

    .PARAMETER AdkWinPeProductID
        Specifies the Product ID for ADK WinPE.
        Default: d8369a05-1f4a-4735-9558-6e131201b1a2

    .PARAMETER AdkInstallPath
        Specifies the path to install ADK and ADK WinPE
        Default: C:\Program Files (x86)\Windows Kits\10

    .PARAMETER MdtProductName
        Specifies the Product Name for MDT.
        Default: Microsoft Deployment Toolkit (6.3.8456.1000)

    .PARAMETER MdtProductID
        Specifies the Product ID for MDT.
        Default: 2E6CD7B9-9D00-4B04-882F-E6971BC9A763

    .PARAMETER MdtInstallPath
        Specifies the path to install MDT.
        Default: C:\Program Files\Microsoft Deployment Toolkit
#>
Configuration xSCCMPreReqs
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AdkSetupExePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AdkWinPeSetupPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MdtMsiPath,

        [Parameter()]
        [System.String[]]
        $LocalAdministrators,

        [Parameter()]
        [System.String[]]
        $NoSmsOnDrives,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DomainCredential,

        [Parameter()]
        [System.String]
        $AdkProductName = 'Windows Assessment and Deployment Kit - Windows 10',

        [Parameter()]
        [System.String]
        $AdkProductID = 'fb450356-9879-4b2e-8dc9-282709286661',

        [Parameter()]
        [System.String]
        $AdkWinPeProductName = 'Windows Assessment and Deployment Kit Windows Preinstallation Environment Add-ons - Windows 10',

        [Parameter()]
        [System.String]
        $AdkWinPeProductID = 'd8369a05-1f4a-4735-9558-6e131201b1a2',

        [Parameter()]
        [System.String]
        $AdkInstallPath ='C:\Program Files (x86)\Windows Kits\10',

        [Parameter()]
        [System.String]
        $MdtProductName = 'Microsoft Deployment Toolkit (6.3.8456.1000)',

        [Parameter()]
        [System.String]
        $MdtProductID = '2E6CD7B9-9D00-4B04-882F-E6971BC9A763',

        [Parameter()]
        [System.String]
        $MdtInstallPath = 'C:\Program Files\Microsoft Deployment Toolkit'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    WindowsFeature WindowsFeature-NET-Framework-Core
    {
        Name   = 'Net-Framework-Core'
        Ensure = 'Present'
    }

    WindowsFeature WindowsFeature-NET-Framework-45-Core
    {
        Name   = 'Net-Framework-45-Core'
        Ensure = 'Present'
    }

    WindowsFeature WindowsFeature-RDC
    {
        Name   = 'RDC'
        Ensure = 'Present'
    }

    $Localadministrators | Where-Object -FilterScript {$_ -like '*\*' -and $_ -notlike 'BUILTIN\*' -and $_ -notlike '.\*' -and $_ -notlike '*@*'}

    if ($LocalAdministrators -gt 0)
    {
        if ($null -eq $DomainCredential)
        {
            Write-Error -Message 'When adding domain users/groups to the Local Administrator group, domain credentials are needed.'
        }

        Group LocalAdministrators
        {
            GroupName        = 'Administrators'
            MembersToInclude = $LocalAdministrators
            Credential       = $DomainCredential
        }
    }
    elseif ($LocalAdministrators)
    {
        Group LocalAdministrators
        {
            GroupName        = 'Administrators'
            MembersToInclude = $LocalAdministrators
        }
    }

    # ADK install version 1903 (10.1.18362), 1909 ADK won't be released
    Package ADK
    {
        Ensure    = 'Present'
        Path      = $AdkSetupExePath
        Name      = $AdkProductName
        ProductId = $AdkProductID
        Arguments = "/installpath $($AdkInstallPath) /features OptionId.DeploymentTools OptionId.UserStateMigrationTool /quiet /norestart /ceip off"
    }

    # Windows Preinstallation Environment (PE) install. Starting with ADK 1809, this installation occurs separately
    Package WinPE
    {
        Ensure    = 'Present'
        Path      = $AdkWinPeSetupPath
        Name      = $AdkWinPeProductName
        ProductId = $AdkWinPeProductID
        Arguments = "/installpath $($AdkInstallPath) /quiet /norestart /ceip off"
    }

    Package MDT
    {
        Ensure    = 'Present'
        Path      = $MdtMsiPath
        Name      = $MdtProductName
        ProductId = $MdtProductID
        Arguments = "INSTALLDIR=$($MdtInstallPath) /qn /norestart"
    }

    foreach ($drive in $NoSmsOnDrives)
    {
        File "$drive-NoSmsOnDrive"
        {
            DestinationPath = "$($drive):\no_sms_on_drive.sms"
            Ensure          = 'Present'
            Contents        = ''
            Type            = 'File'
        }
    }
}
