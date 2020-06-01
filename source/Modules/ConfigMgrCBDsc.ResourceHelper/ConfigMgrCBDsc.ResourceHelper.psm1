# Localized messages
data LocalizedData
{
    # Culture="en-US"
    ConvertFrom-StringData -StringData @'
    ModuleNotFound = Please ensure that the PowerShell module for role {0} is installed.
'@
}

<#
    .SYNOPSIS
        Import Configuration Manager module commands.

    .PARAMTER SiteCode
        Specifies the site code for configuration manager.
#>
function Import-ConfigMgrPowerShellModule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    if ((Test-Path -Path "$($SiteCode):\") -eq $false)
    {
        $getCim = @{
            ClassName = 'SMS_Site'
            Namespace = "root\sms\site_$SiteCode"
        }

        $siteInfo = Get-CimInstance @getCim | Where-Object -FilterScript {$_.SiteCode -eq $SiteCode}
        $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $baseRegKeyPath = "Registry::HKEY_Users\$sid\Software\Microsoft"
        $createKeys = @('ConfigMgr10','AdminUI','MRU','1')

        foreach ($key in $createKeys)
        {
            if (-not (Test-Path -Path "$baseRegKeyPath\$key"))
            {
                New-Item -Path $baseRegKeyPath -Name $key |Out-Null
            }

            $baseRegKeyPath += "\$key"
        }

        $regProperties = (Get-ItemProperty -Path $baseRegKeyPath -ErrorAction SilentlyContinue)

        $values = @{
            ServerName = $siteInfo.ServerName
            SiteName   = $siteInfo.SiteName
            SiteCode   = $siteInfo.SiteCode
            DomainName = ($siteinfo.ServerName.SubString($siteinfo.ServerName.Indexof('.') + 1))
        }

        foreach ($value in $values.GetEnumerator())
        {
            if ($($regProperties.$($value.Name)) -ne $value.Value)
            {
                Set-ItemProperty -Path $baseRegKeyPath -Name $value.Name -Value $value.Value | Out-Null
            }
        }

        Set-ConfigmgrCert

        try
        {
            Import-Module -Name (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Global
        }
        catch
        {
            throw "Failure to import SCCM Cmdlets."
        }
    }

    if ((Get-Module -Name ConfigurationManager).Version -lt '5.1902')
    {
        throw "Incorrect version of Configuration Manager Powershell to use this module"
    }
}

<#
    .SYNOPSIS
        Imports the configuration manager powershell certificate to Trusted Publisher.
#>
function Set-ConfigMgrCert
{
    param ()

    $configCert = Get-AuthenticodeSignature -FilePath (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

    $store = Get-Item -Path Cert:\LocalMachine\TrustedPublisher
    $store.Open('ReadWrite')

    if ($store.Certificates -notcontains $configCert.SignerCertificate)
    {
        $store.Add($configCert.SignerCertificate)
    }

    $store.Close()
}

<#
    .SYNOPSIS
        Converts the CIDR and IPAddress.

    .PARAMETER IPAddress
        Specifies the network address.

    .PARAMETER Cidr
        Specifies the network mask value.
#>
function Convert-CidrToIP
{
    [CmdLetBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0,32)]
        [Int16]
        $Cidr
    )

    $CidrBits = ('1' * $Cidr).PadRight(32, '0')
    $octets = $CidrBits -Split '(.{8})' -ne ''
    $mask = ($octets | ForEach-Object -Process {[Convert]::ToInt32($_, 2) }) -Join '.'

    $ip = [IPAddress](($IPAddress).Address -Band ([IPAddress]$mask).Address)

    return  @{
        NetworkAddress = $ip.IPAddressToString
        Subnetmask     = $mask
        Cidr           = $Cidr
    }
}

<#
    .SYNOPSIS
        Converts CMSchedule objects to a readable and workable format.

    .PARAMETER ScheduleString
        Specifies the schedule string to convert.

    .PARAMETER CimClassName
        Specifies the name of the EmbeddedInstance for the schedule object.
#>
function ConvertTo-CimCMScheduleString
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScheduleString,

        [Parameter(Mandatory = $true)]
        [String]
        $CimClassName
    )

    $schedule = Convert-CMSchedule -ScheduleString $ScheduleString

    if (-not [string]::IsNullOrEmpty($schedule.DaySpan))
    {
        if ($schedule.DaySpan -gt 0)
        {
            $rInterval = 'Days'
            $rCount = $schedule.DaySpan
        }
        elseif ($schedule.HourSpan -gt 0)
        {
            $rInterval = 'Hours'
            $rCount = $schedule.HourSpan
        }
        elseif ($schedule.MinuteSpan -gt 0)
        {
            $rInterval = 'Minutes'
            $rCount = $schedule.MinuteSpan
        }

        $scheduleCim = New-CimInstance -ClassName $CimClassName -Property @{
            RecurInterval = $rInterval
            RecurCount    = $rCount
        } -ClientOnly -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

        return $scheduleCim
    }
}

<#
    .SYNOPSIS
        Converts the boundaries to a CIM Instance.

    .PARAMETER InputObject
        Specifies the array of hashtables of boundary returns.
#>
function ConvertTo-CimBoundaries
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )

    $cimClassName = 'DSC_CMBoundaryGroupsBoundaries'
    $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    $cimCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

    foreach ($customField in $InputObject)
    {
        $convertBoundary = switch ($customField.BoundaryType)
        {
            '0' { 'IPSubnet' }
            '1' { 'AdSite' }
            '3' { 'IPRange' }
        }

        $cimProperties = @{
            Value      = $customField.Value
            Type       = $convertBoundary
        }

        $cimCollection += (New-CimInstance -ClassName $cimClassName `
                        -Namespace $cimNamespace `
                        -Property $cimProperties `
                        -ClientOnly)
    }

    return $cimCollection
}

<#
    .SYNOPSIS
        Converts the boundaries input to a CIM Instance transforming
        the IPSubnet input to a network address.

    .PARAMETER InputObject
        Specifies the array of CIM Instances for the boundary input.
#>
function Convert-BoundariesIPSubnets
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $InputObject
    )

    $cimClassName = 'MSFT_KeyPairs'
    $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    $bounds = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

    foreach ($item in $InputObject)
    {
        if ($item.Type -eq 'IPSubnet')
        {
            $splitValue = $item.Value.Split('/')
            $address = Convert-CidrToIP -IPAddress $splitValue[0] -Cidr $splitValue[1]

            $cimProperties = @{
                Value     = $address.NetworkAddress
                Type      = "IPSubnet"
            }

            $bounds += (New-CimInstance -ClassName $cimClassName `
                        -Namespace $cimNamespace `
                        -Property $cimProperties `
                        -ClientOnly)
        }
        else
        {
            $cimProperties = @{
                Value     = $item.Value
                Type      = $item.Type
            }

            $bounds += (New-CimInstance -ClassName $cimClassName `
                        -Namespace $cimNamespace `
                        -Property $cimProperties `
                        -ClientOnly)
        }
    }

    return $bounds
}

<#
    .SYNOPSIS
        Returns the boundary ID based on Value and Type of boundary specified.

    .PARAMETER Value
        Specifies the value of the boundary.

    .PARAMETER Type
        Specifies the type of boundary options are ADSite, IPSubnet, and IPRange.
#>
function Get-BoundaryInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADSite','IPSubnet','IPRange')]
        [String]
        $Type
    )

    $convertBoundaryBack = switch ($Type)
    {
        'IPSubnet' { '0' }
        'AdSite'   { '1' }
        'IPRange'  { '3' }
    }

    return (Get-CMBoundary | Where-Object -FilterScript { ($_.BoundaryType -eq $convertBoundaryBack) -and
            ($_.Value -eq $Value) }).BoundaryID
}

Export-ModuleMember -Function @(
    'Get-LocalizedData'
    'New-InvalidArgumentException'
    'Import-ConfigMgrPowerShellModule'
    'Confirm-ClientSetting'
    'Convert-ClientSetting'
    'Get-ClientSettingsSoftwareCenter'
    'Convert-CidrToIP'
    'ConvertTo-CimCMScheduleString'
    'ConvertTo-CimBoundaries'
    'Convert-BoundariesIPSubnets'
    'Get-BoundaryInfo'
)
