$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

 <#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
        This role can only be installed on CAS or PRI.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteServerName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $scpProp = (Get-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName).Props

    if ($scpProp)
    {
        if ($scpProp.Value -eq '0')
        {
            $offlineMode = 'Online'
        }
        else
        {
            $offlineMode = 'Offline'
        }
        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteServerName = $SiteServerName
        SiteCode       = $siteCode
        Mode           = $offlineMode
        Ensure         = $status
    }
}

 <#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER Mode
        Specifies a mode for the service connection point. The acceptable values are Online and Offline.

    .PARAMETER Ensure
        Specifies whether the fallback status point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
        This role can only be installed on CAS or PRI.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteServerName,

        [Parameter()]
        [ValidateSet('Online', 'Offline')]
        [String]
        $Mode = 'Online',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.AddScpRole -f $SiteServerName)
                Add-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode -Mode $Mode
            }
            elseif ($state.Mode -ne $Mode)
            {
                Write-Verbose -Message ($script:localizedData.SettingValue -f $Mode)
                Set-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode -Mode $Mode
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveScpRole -f $SiteServerName)
            Remove-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Set-Location -Path "$env:temp"
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER Mode
        Specifies a mode for the service connection point. The acceptable values are Online and Offline.

    .PARAMETER Ensure
        Specifies whether the fallback status point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
        This role can only be installed on CAS or PRI.
#>

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteServerName,

        [Parameter()]
        [ValidateSet('Online', 'Offline')]
        [String]
        $Mode = 'Online',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.ScpNotInstalled -f $SiteServerName)
            $result = $false
        }

        if (([string]::IsNullOrEmpty($state.mode)) -or ($state.Mode -ne $Mode))
        {
            Write-Verbose -Message ($script:localizedData.TestSetting -f $Mode, $state.mode)
            $result = $false
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.ScpAbsent -f $SiteServerName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
