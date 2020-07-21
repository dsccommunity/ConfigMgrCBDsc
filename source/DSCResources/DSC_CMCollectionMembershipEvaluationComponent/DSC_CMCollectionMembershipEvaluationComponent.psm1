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

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $component = (Get-CMCollectionMembershipEvaluationComponent -SiteCode $SiteCode).Props
    $evalMins = ($component | Where-Object -FilterScript {$_.PropertyName -eq 'Incremental Interval'}).Value

    return @{
        SiteCode       = $SiteCode
        EvaluationMins = $evalMins
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER EvaluationMins
        Indicates the CM Collection Membership Evaluation Component interval in minutes.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $EvaluationMins

    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode

    try
    {
        if ($EvaluationMins -ne $state.EvaluationMins)
        {
            Write-Verbose -Message ($script:localizedData.EvaluationSetting -f $state.EvaluationMins, $EvaluationMins)
            Set-CMCollectionMembershipEvaluationComponent -SiteCode $SiteCode -EvaluationMins $EvaluationMins
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
        Specifies the site code for Configuration Manager site.

    .PARAMETER EvaluationMins
        Indicates the CM Collection Membership Evaluation Component interval in minutes.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $EvaluationMins
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true

    if ($EvaluationMins -ne $state.EvaluationMins)
    {
        Write-Verbose -Message ($script:localizedData.EvaluationMins -f $EvaluationMins, $state.EvaluationMins)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
