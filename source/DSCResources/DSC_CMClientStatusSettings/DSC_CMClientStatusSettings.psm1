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

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $statusSettings = Get-CMClientStatusSetting

    return @{
        SiteCode               = $SiteCode
        IsSingleInstance       = $IsSingleInstance
        ClientPolicyDays       = $statusSettings.PolicyInactiveInterval
        HeartbeatDiscoveryDays = $statusSettings.DDRInactiveInterval
        SoftwareInventoryDays  = $statusSettings.SWInactiveInterval
        HardwareInventoryDays  = $statusSettings.HWInactiveInterval
        StatusMessageDays      = $statusSettings.StatusInactiveInterval
        HistoryCleanupDays     = $statusSettings.CleanUpInterval
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER ClientPolicyDays
        Specifies the data collection intervals for client policy client monitoring activities.

    .PARAMETER HeartbeatDiscoveryDays
        Specifies the data collection intervals for heartbeat discovery client monitoring activities.

    .PARAMETER SoftwareInventoryDays
        Specifies the data collection intervals for software inventory client monitoring activities.

    .PARAMETER HardwareInventoryDays
        Specifies the data collection intervals for hardware inventory client monitoring activities.

    .PARAMETER StatusMessageDays
        Specifies the data collection intervals for status message client monitoring activities.

    .PARAMETER HistoryCleanupDays
        Specifies the data collection intervals for status history cleanup client monitoring activities.
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $ClientPolicyDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $HeartbeatDiscoveryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $SoftwareInventoryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $HardwareInventoryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $StatusMessageDays,

        [Parameter()]
        [ValidateRange(0,90)]
        [Nullable[UInt32]]
        $HistoryCleanupDays
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $currentState = Get-TargetResource -SiteCode $SiteCode -IsSingleInstance Yes

    try
    {
        foreach ($property in $PSBoundParameters.GetEnumerator())
        {
            if ((-not [string]::IsNullOrEmpty($property.Value)) -and ($property.key -ne 'Verbose'))
            {
                $currentValue = $currentState.("$($property.Key)")

                if ($property.Value -ne $currentValue)
                {
                    Write-Verbose -Message ($script:localizedData.ModifySetting -f $property.Key, $property.Value, $currentValue)

                    $buildingParmas += @{
                        $($property.Key) = $($property.Value)
                    }
                }
            }
        }

        if($buildingParmas)
        {
            Set-CMClientStatusSetting @buildingParmas
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
        This tests the desired state.
        If the state is not correct it returns $false.
        If the state is correct it returns $true.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER ClientPolicyDays
        Specifies the data collection intervals for client policy client monitoring activities.

    .PARAMETER HeartbeatDiscoveryDays
        Specifies the data collection intervals for heartbeat discovery client monitoring activities.

    .PARAMETER SoftwareInventoryDays
        Specifies the data collection intervals for software inventory client monitoring activities.

    .PARAMETER HardwareInventoryDays
        Specifies the data collection intervals for hardware inventory client monitoring activities.

    .PARAMETER StatusMessageDays
        Specifies the data collection intervals for status message client monitoring activities.

    .PARAMETER HistoryCleanupDays
        Specifies the data collection intervals for status history cleanup client monitoring activities.
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $ClientPolicyDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $HeartbeatDiscoveryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $SoftwareInventoryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $HardwareInventoryDays,

        [Parameter()]
        [ValidateRange(1,30)]
        [Nullable[UInt32]]
        $StatusMessageDays,

        [Parameter()]
        [ValidateRange(0,90)]
        [Nullable[UInt32]]
        $HistoryCleanupDays
    )

    $currentState = Get-TargetResource -SiteCode $SiteCode -IsSingleInstance Yes
    $result = $true

    foreach ($property in $PSBoundParameters.GetEnumerator())
    {
        if ((-not [string]::IsNullOrEmpty($property.Value)) -and ($property.Key -ne 'Verbose'))
        {
            $currentValue = $currentState.("$($property.Key)")

            if ($property.Value -ne $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.TestSetting -f $property.Key, $property.Value, $currentValue)
                $result = $false
            }
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
