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
        $AdkInstallPath ='',

        [Parameter()]
        [System.String]
        $MdtProductName = 'Microsoft Deployment Toolkit (6.3.8456.1000)',

        [Parameter()]
        [System.String]
        $MdtProductID = '2E6CD7B9-9D00-4B04-882F-E6971BC9A763',

        [Parameter()]
        [System.String]
        $MdtInstallPath = ''
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    WindowsFeature NET-Framework-Core
    {
        Name   = 'Net-Framework-Core'
        Ensure = 'Present'
    }

    WindowsFeature NET-Framework-45-Core
    {
        Name   = 'Net-Framework-45-Core'
        Ensure = 'Present'
    }

    WindowsFeature RDC
    {
        Name   = 'RDC'
        Ensure = 'Present'
    }

    $Localadministrators | Where-Object -FilterScript {$_ -like '*\*' -and $_ -notlike 'BUILTIN\*' -and $_ -notlike '.\*'}

    if ($LocalAdministrators -gt 0)
    {
        Group LocalAdministrators
        {
            GroupName        = 'Administrators'
            MembersToInclude = $LocalAdministrators
            Credential       = $DomainCredential
        }
    }
    else
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
        Name      = $MdtName
        ProductId = $MdtProductID
        Arguments = "INSTALLDIR=$($MdtInstallPath) /qn /norestart"
    }

    foreach ($drive in $NoSmsOnDrives)
    {
        File $drive
        {
            DestinationPath = "$($drive):\no_sms_on_drive.sms"
            Ensure          = 'Present'
            Contents        = ''
            Type            = 'File'
        }
    }
}
