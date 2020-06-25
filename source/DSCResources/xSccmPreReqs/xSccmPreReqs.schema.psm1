<#
    .SYNOPSIS
        A DSC composite resource to configure/install the required PreReqs for SCCM.
        - .NET Framework 3.5 Windows Feature
        - .NET Framework 4.5 or later Windows Feature
        - Remote Differential Compression Windows Feature
        - Windows ADK install
        - Windows ADK WinPE install
        - Windows MDT install
        - Local Administrators
        - Add no_sms_on_drive files

    .PARAMETER InstallAdk
        Specify whether to install ADK.

    .PARAMETER InstallMDT
        Specify wheter to install MDT.

    .PARAMETER AdkSetupExePath
        Specifies the path and filename to the ADK Setup.

    .PARAMETER AdkWinPeSetupPath
        Specifies the path and filename to the ADK WinPE Setup.

    .PARAMETER MdtMsiPath
        Specifies the path and filename to the MDT Setup.

    .PARAMETER InstallWindowsFeatures
        Specifiy to install Windows Features needed for the SCCM install.

    .PARAMETER WindowsFeatureSource
        Specifies the source that will be used to install windows features if the files are not present in the local
        side-by-side store.

    .PARAMETER SccmRole
        Specify the SCCM Roles that will be on the server.

    .PARAMETER AddWindowsFirewallRule
        Specify whether to add the Windows Firewall Rules needed for the install.

    .PARAMETER FirewallProfile
        Specify the Windows Firewall profile for the rules to be added.

    .PARAMETER FirewallTcpLocalPort
        Specify the TCP ports to be added to the windows firewall as allowed.

    .PARAMETER FirewallUdpLocalPort
        Specify the UDP ports to be added to the windows firewall as allowed.

    .PARAMETER LocalAdministrators
        Specifies the accounts and/or groups you want to add to the local administrators group.

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
        Specifies the path to install ADK and ADK WinPE.
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

    .NOTES
        SCCM Roles based one the following documentation:
        https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/configs/site-and-site-system-prerequisites
#>
Configuration xSCCMPreReqs
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Boolean]
        $InstallAdk = $true,

        [Parameter()]
        [Boolean]
        $InstallMdt,

        [Parameter()]
        [System.String]
        $AdkSetupExePath,

        [Parameter()]
        [System.String]
        $AdkWinPeSetupPath,

        [Parameter()]
        [System.String]
        $MdtMsiPath,

        [Parameter()]
        [Boolean]
        $InstallWindowsFeatures = $true,

        [Parameter()]
        [System.String]
        $WindowsFeatureSource = 'C:\Windows\WinSxS',

        [Parameter()]
        [ValidateSet('CASorSiteServer','AssetIntelligenceSynchronizationPoint','CertificateRegistrationPoint','DistributionPoint','EndpointProtectionPoint','EnrollmentPoint','EnrollmentProxyPoint','FallbackServicePoint','ManagementPoint','ReportingServicesPoint','ServiceConnectionPoint','StateMigrationPoint','SoftwareUpdatePoint')]
        [System.String[]]
        $SccmRole = 'CASorSiteServer',

        [Parameter()]
        [Boolean]
        $AddWindowsFirewallRule = $false,

        [Parameter()]
        [System.String[]]
        $FirewallProfile,

        [Parameter()]
        [System.String[]]
        $FirewallTcpLocalPort = @('1433','1434','4022','445','135','139','49154-49157'),

        [Parameter()]
        [System.String[]]
        $FirewallUdpLocalPort = @('137-138','1434','5355'),

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
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 7.4.0.0

    $features = @()
    foreach ($role in $SccmRole)
    {
        switch ($role)
        {
            'CASorSiteServer' {$features += 'Net-Framework-Core','Net-Framework-45-Core','RDC'}
            'AssetIntelligenceSynchronizationPoint' {$features += 'Net-Framework-45-Core'}
            'CertificateRegistrationPoint' {$features += 'Net-Framework-Core','NET-HTTP-Activation',
                'Net-Framework-45-Core','NET-WCF-HTTP-Activation45','Web-Default-Doc','Web-Asp-Net','Web-Asp-Net45',
                'Web-ISAPI-Ext','Web-ISAPI-Filter','Web-Net-Ext','Web-Net-Ext45','Web-Mgmt-Console','Web-Metabase',
                'Web-WMI','Web-Filtering','WAS-Process-Model','WAS-NET-Environment','WAS-Config-APIs'
            }
            'DistributionPoint' {$features += 'RDC','Web-ISAPI-Ext','Web-Windows-Auth','Web-Mgmt-Console',
                'Web-Metabase','Web-WMI','Web-Filtering'
            }
            'EndpointProtectionPoint' {'Net-Framework-Core'}
            'EnrollmentPoint' {$features += 'Net-Framework-Core','NET-HTTP-Activation',
                'Net-Framework-45-Core','NET-WCF-HTTP-Activation45','Web-Default-Doc','Web-Asp-Net','Web-Asp-Net45',
                'Web-Net-Ext','Web-Net-Ext45','Web-Mgmt-Console','Web-Metabase'
            }
            'EnrollmentProxyPoint' {$features += 'Net-Framework-Core','Net-Framework-45-Core','Web-Default-Doc',
                'Web-Static-Content','Web-Asp-Net','Web-Asp-Net45','Web-ISAPI-Ext','Web-ISAPI-Filter',
                'Web-Net-Ext','Web-Net-Ext45','Web-Filtering','Web-Windows-Auth','Web-Mgmt-Console','Web-Metabase'
            }
            'FallbackServicePoint' {$features += 'BITS','BITS-IIS-Ext','RSAT-Bits-Server','Web-ISAPI-Ext',
                'Web-Http-Redirect','Web-Default-Doc','Web-Dir-Browsing','Web-Http-Errors','Web-Static-Content',
                'Web-Http-Logging','Web-Stat-Compression','Web-Filtering','Web-Metabase','Web-Mgmt-Console',
                'Web-Http-Tracing','Web-Log-Libraries','Web-Request-Monitor'
            }
            'ManagementPoint' {$features += 'Net-Framework-45-Core','BITS','BITS-IIS-Ext','RSAT-Bits-Server',
                'Web-ISAPI-Ext','Web-Http-Redirect','Web-Default-Doc','Web-Dir-Browsing','Web-Http-Errors',
                'Web-Static-Content','Web-Windows-Auth','Web-Mgmt-Console','Web-Metabase','Web-WMI',
                'Web-Http-Logging','Web-Http-Tracing','Web-Log-Libraries','Web-Request-Monitor','Web-Stat-Compression'
            }
            'ReportingServicesPoint' {$features += 'Net-Framework-45-Core'}
            'ServiceConnectionPoint' {$features += 'Net-Framework-45-Core','Net-Framework-Core'}
            'SoftwareUpdatePoint' {$features += 'Net-Framework-45-Core','Net-Framework-Core','UpdateServices',
                'NET-Framework-45-ASPNET','UpdateServices-RSAT','UpdateServices-API','UpdateServices-UI',
                'Web-Asp-Net45','Web-ISAPI-Ext','Web-ISAPI-Filter','Web-Net-Ext45','Web-Default-Doc',
                'Web-Static-Content','Web-Dyn-Compression','Web-Filtering','Web-Windows-Auth','Web-Mgmt-Console',
                'Web-Metabase','UpdateServices-Services','UpdateServices-DB','WAS-Config-APIs'
            }
            'StateMigrationPoint' {$features += 'Net-Framework-45-Core','Net-Framework-Core','NET-HTTP-Activation',
                'NET-WCF-HTTP-Activation45','NET-Framework-45-ASPNET','Web-Default-Doc','Web-Asp-Net','Web-Asp-Net45',
                'Web-ISAPI-Ext','Web-ISAPI-Filter','Web-Net-Ext','Web-Net-Ext45','Web-Filtering','Web-Metabase',
                'Web-Mgmt-Console','WAS-NET-Environment','WAS-Config-APIs','WAS-Process-Model'
            }
        }
    }

    if ($InstallWindowsFeatures)
    {
        $uniqueFeatures = $features | Select-Object -Unique

        WindowsFeatureSet $([string]$SccmRole)
        {
            Name   = $uniqueFeatures
            Ensure = 'Present'
            Source = $WindowsFeatureSource
        }
    }

    if ($AddWindowsFirewallRule)
    {
        if ($null -eq $FirewallProfile)
        {
            throw 'When specifying AddWindowsFirewallRule you need to provide FirewallProfile, FirewallTcpLocalPort, and FirewallUdpLocalPort.'
        }

        Firewall AddSccmTCPFirewallRule
        {
            Name        = 'SCCMServerTCP'
            DisplayName = 'SCCM to SCCM communication - TCP'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = $FirewallProfile
            Direction   = 'Inbound'
            LocalPort   = $FirewallTcpLocalPort
            Protocol    = 'TCP'
            Description = 'Firewall Rule SCCM to SCCM communication - TCP'
        }

        Firewall AddSccmUdpFirewallRule
        {
            Name        = 'SCCMServerUDP'
            DisplayName = 'SCCM to SCCM communication - UDP'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = $FirewallProfile
            Direction   = 'Inbound'
            LocalPort   = $FirewallUdpLocalPort
            Protocol    = 'UDP'
            Description = 'Firewall Rule SCCM to SCCM communication - UDP'
        }
    }

    $domainAccounts = $Localadministrators | Where-Object -FilterScript {$_ -like '*\*' -and $_ -notlike 'BUILTIN\*' -and $_ -notlike '.\*' -and $_ -notlike '*@*'}

    if ($domainAccounts -gt 0)
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

    if ($InstallAdk)
    {
        if ([string]::IsNullOrEmpty($AdkSetupExePath) -or [string]::IsNullOrEmpty($AdkWinPeSetupPath))
        {
            throw 'To install ADK you must specify ADKSetupExePath and $AdkWinPeSetupPath'
        }

        Package ADK
        {
            Ensure    = 'Present'
            Path      = $AdkSetupExePath
            Name      = $AdkProductName
            ProductId = $AdkProductID
            Arguments = "/installpath `"$($AdkInstallPath)`" /features OptionId.DeploymentTools OptionId.UserStateMigrationTool /quiet /norestart /ceip off"
        }

        Package WinPE
        {
            Ensure    = 'Present'
            Path      = $AdkWinPeSetupPath
            Name      = $AdkWinPeProductName
            ProductId = $AdkWinPeProductID
            Arguments = "/installpath `"$($AdkInstallPath)`" /quiet /norestart /ceip off"
        }
    }

    if ($InstallMdt)
    {
        if ([string]::IsNullOrEmpty($MdtMsiPath))
        {
            throw 'To install MDT you must specify MdtMsiPath.'
        }

        Package MDT
        {
            Ensure    = 'Present'
            Path      = $MdtMsiPath
            Name      = $MdtProductName
            ProductId = $MdtProductID
            Arguments = "INSTALLDIR=`"$($MdtInstallPath)`" /qn /norestart"
        }
    }

    foreach ($drive in $NoSmsOnDrives)
    {
        if ($drive -gt 1)
        {
            $driveLetter = $drive[0]
        }
        File "$driveLetter-NoSmsOnDrive"
        {
            DestinationPath = "$($driveLetter):\no_sms_on_drive.sms"
            Ensure          = 'Present'
            Contents        = ''
            Type            = 'File'
        }
    }
}
