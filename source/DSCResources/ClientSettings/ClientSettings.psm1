$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Name
        Specifies the display name of the client setting package.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.

    .PARAMETER SettingValue
        Specifies the value for the setting.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('BackgroundIntelligentTransfer','ClientCache','ClientPolicy','Cloud','ComplianceSettings','ComputerAgent',
        'ComputerRestart','DeliveryOptimization','EndpointProtection','HardwareInventory','MeteredNetwork','MobileDevice',
        'NetworkAccessProtection','PowerManagement','RemoteTools','SoftwareCenter','SoftwareDeployment','SoftwareInventory',
        'SoftwareMetering','SoftwareUpdates','StateMessaging','UserAndDeviceAffinity','WindowsAnalytics')]
        [String]
        $DeviceSettingName,

        [Parameter(Mandatory = $true)]
        [String]
        $Setting,

        [Parameter(Mandatory = $true)]
        [String]
        $SettingValue
    )

    Write-Verbose -Message ($script:localizedData.RetrieveSettingValue -f $Name, $DeviceSettingName, $Setting)
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    if ($DeviceSettingName -ne 'SoftwareCenter')
    {
        $settingVal = (Get-CMClientSetting -Name $Name -Setting $DeviceSettingName).$($Setting)
    }
    else
    {
        $settingVal = Get-ClientSettingsSoftwareCenter -Name $Name -Setting $Setting
    }

    Set-Location -Path $env:windir

    return @{
        SiteCode          = $SiteCode
        Name              = $Name
        DeviceSettingName = $DeviceSettingName
        Setting           = $Setting
        SettingValue      = $settingVal
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Name
        Specifies the display name of the client setting package.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.

    .PARAMETER SettingValue
        Specifies the value for the setting.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('BackgroundIntelligentTransfer','ClientCache','ClientPolicy','Cloud','ComplianceSettings','ComputerAgent',
        'ComputerRestart','DeliveryOptimization','EndpointProtection','HardwareInventory','MeteredNetwork','MobileDevice',
        'NetworkAccessProtection','PowerManagement','RemoteTools','SoftwareCenter','SoftwareDeployment','SoftwareInventory',
        'SoftwareMetering','SoftwareUpdates','StateMessaging','UserAndDeviceAffinity','WindowsAnalytics')]
        [String]
        $DeviceSettingName,

        [Parameter(Mandatory = $true)]
        [String]
        $Setting,

        [Parameter(Mandatory = $true)]
        [String]
        $SettingValue
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    Confirm-ClientSetting -DeviceSettingName $DeviceSettingName -Setting $Setting
    Write-Verbose -Message ($script:localizedData.RetrieveSettingValue -f $Name, $DeviceSettingName, $Setting)

    if ($DeviceSettingName -ne 'SoftwareCenter')
    {
        $settingVal = (Get-CMClientSetting -Name $Name -Setting $DeviceSettingName).$($Setting)
    }
    else
    {
        $settingVal = Get-ClientSettingsSoftwareCenter -Name $Name -Setting $Setting
    }

    Write-Verbose -Message ($script:localizedData.SettingValues -f $Setting, $SettingValue, $settingVal)

    if (($null -eq $settingVal) -or ($settingVal -ne $SettingValue))
    {
        $convertSetting = Convert-ClientSetting -DeviceSettingName $DeviceSettingName -Setting $Setting

        # Build command line
        $commandName = switch ($DeviceSettingName)
        {
            'Cloud'               { 'Set-CMClientSettingCloudService'              }
            'ComplianceSettings'  { 'Set-CMClientSettingComplianceSetting'         }
            'MeteredNetwork'      { 'Set-CMClientSettingMeteredInternetConnection' }
            'MobileDevice'        { 'Set-CMClientSettingEnrollment'                }
            'RemoteTools'         { 'Set-CMClientSettingRemoteTool'                }
            'SoftwareUpdates'     { 'Set-CMClientSettingSoftwareUpdate'            }
            default               { "Set-CMClientSetting$($DeviceSettingName)"     }
        }

        # Build the params
        if ($SettingValue -eq $true)
        {
            $params = @{
                Name            = $Name
                $convertSetting = $true
            }
        }
        elseif ($SettingValue -eq $false)
        {
            $params = @{
                Name            = $Name
                $convertSetting = $false
            }
        }
        else
        {
            $params = @{
                Name            = $Name
                $convertSetting = $SettingValue
            }
        }

        # Create the ScriptBlock
        $setSettings = [scriptblock]::Create(". $commandName @params")

        try
        {
            Write-Verbose -Message ($script:localizedData.Commandline -f $commandName, $params.Name, $convertSetting, $params.$($convertSetting))
            Invoke-Command -ScriptBlock $setSettings
        }
        catch
        {
            throw $_
        }
        finally
        {
            Set-Location -Path $env:windir
        }
    }
    else
    {
        Set-Location -Path $env:windir
    }
}

<#
    .SYNOPSIS
        This tests the desired state.
        If the state is not correct it returns $false.
        If the state is correct it returns $true.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Name
        Specifies the display name of the client setting package.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.

    .PARAMETER SettingValue
        Specifies the value for the setting.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('BackgroundIntelligentTransfer','ClientCache','ClientPolicy','Cloud','ComplianceSettings','ComputerAgent',
        'ComputerRestart','DeliveryOptimization','EndpointProtection','HardwareInventory','MeteredNetwork','MobileDevice',
        'NetworkAccessProtection','PowerManagement','RemoteTools','SoftwareCenter','SoftwareDeployment','SoftwareInventory',
        'SoftwareMetering','SoftwareUpdates','StateMessaging','UserAndDeviceAffinity','WindowsAnalytics')]
        [String]
        $DeviceSettingName,

        [Parameter(Mandatory = $true)]
        [String]
        $Setting,

        [Parameter(Mandatory = $true)]
        [String]
        $SettingValue
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    Confirm-ClientSetting -DeviceSettingName $DeviceSettingName -Setting $Setting
    Write-Verbose -Message ($script:localizedData.RetrieveSettingValue -f $Name, $DeviceSettingName, $Setting)

    if ($DeviceSettingName -ne 'SoftwareCenter')
    {
        $settingVal = (Get-CMClientSetting -Name $Name -Setting $DeviceSettingName).$($Setting)
    }
    else
    {
        $settingVal = Get-ClientSettingsSoftwareCenter -Name $Name -Setting $Setting
    }

    Write-Verbose -Message ($script:localizedData.SettingValues -f $Setting, $SettingValue, $settingVal)
    $result = $true

    if ($settingVal)
    {
        if ($settingVal -ne $SettingValue)
        {
            $result = $false
        }
    }
    else
    {
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
