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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.
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
        $ClientSettingName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting Cloud

        if ($settings)
        {
            $cdp = [System.Convert]::ToBoolean($settings.AllowCloudDP)
            $autoAZJoin = [System.Convert]::ToBoolean($settings.AutoAADJoin)
            $cmg = [System.Convert]::ToBoolean($settings.AllowCMG)
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                    = $SiteCode
        ClientSettingName           = $ClientSettingName
        AllowCloudDistributionPoint = $cdp
        AutoAzureADJoin             = $autoAZJoin
        AllowCloudManagementGateway = $cmg
        ClientSettingStatus         = $status
        ClientType                  = $type
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER AllowCloudDistributionPoint
        Specifies if allow access to cloud distribution point is enabled or disabled.

    .PARAMETER AutoAzureADJoin
        Specifies whether to automatically register new Windows 10 domain joined devices with
        Azure Active Directory.

    .PARAMETER AllowCloudManagementGateway
        Specifies if allow access to cloud management gateway is enabled or disabled.
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
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $AllowCloudDistributionPoint,

        [Parameter()]
        [Boolean]
        $AutoAzureADJoin,

        [Parameter()]
        [Boolean]
        $AllowCloudManagementGateway
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($state.ClientType -eq 'User')
        {
            $defaultValues = @('AllowCloudDistributionPoint')
            if ($PSBoundParameters.ContainsKey('AutoAzureADJoin') -or
                $PSBoundParameters.ContainsKey('AllowCloudManagementGateway'))
            {
                Write-Warning -Message $script:localizedData.DeviceSettings
            }
        }
        else
        {
            $defaultValues = @('AllowCloudDistributionPoint','AutoAzureADJoin','AllowCloudManagementGateway')
        }

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -contains $param.Key)
            {
                if ($param.Value -ne $state[$param.Key])
                {
                    Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                    $buildingParams += @{
                        $param.Key = $param.Value
                    }
                }
            }
        }

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingCloudService -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingCloudService -Name $ClientSettingName @buildingParams
            }
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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER AllowCloudDistributionPoint
        Specifies if allow access to cloud distribution point is enabled or disabled.

    .PARAMETER AutoAzureADJoin
        Specifies whether to automatically register new Windows 10 domain joined devices with
        Azure Active Directory.

    .PARAMETER AllowCloudManagementGateway
        Specifies if allow access to cloud management gateway is enabled or disabled.
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
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $AllowCloudDistributionPoint,

        [Parameter()]
        [Boolean]
        $AutoAzureADJoin,

        [Parameter()]
        [Boolean]
        $AllowCloudManagementGateway
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    else
    {
        if ($state.ClientType -eq 'User')
        {
            $defaultValues = @('AllowCloudDistributionPoint')
            if ($PSBoundParameters.ContainsKey('AutoAzureADJoin') -or
                $PSBoundParameters.ContainsKey('AllowCloudManagementGateway'))
            {
                Write-Warning -Message $script:localizedData.DeviceSettings
            }
        }
        else
        {
            $defaultValues = @('AllowCloudDistributionPoint','AutoAzureADJoin','AllowCloudManagementGateway')
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
