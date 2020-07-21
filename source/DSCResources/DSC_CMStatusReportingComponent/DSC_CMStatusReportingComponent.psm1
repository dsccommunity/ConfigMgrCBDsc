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

    $clientComponentStatus = Get-CMStatusReportingComponent -SiteCode $SiteCode | Where-Object -FilterScript {$_.ItemName -eq 'Client Component Status Reporting'}
    $serverComponentStatus = Get-CMStatusReportingComponent -SiteCode $SiteCode | Where-Object -FilterScript {$_.ItemName -eq 'Server Component Status Reporting'}

    foreach ($prop in $clientComponentStatus.Props)
    {
        switch ($prop.PropertyName)
        {
            'Default Status Message Reporting Level'   {
                                                           $clientReporting = ($prop.Value2 -split ",")
                                                           $cReportType = $clientReporting[0]
                                                           $cReportChecked = $true
                                                           switch ($cReportType)
                                                           {
                                                               'NONE' { $cReportChecked = $false }
                                                               'EWI'  { $cReportType = 'AllMilestones' }
                                                               'All'  { $cReportType = 'AllMilestonesAndAllDetails' }
                                                               'EW'   { $cReportType = 'ErrorAndWarningMilestones' }
                                                               'E'    { $cReportType = 'ErrorMilestones' }
                                                           }
                                                           $cReportFailure = [System.Convert]::ToBoolean($clientReporting[1])
                                                       }
            'Default Windows NT Event Reporting Level' {
                                                           $clientLogging = ($prop.Value2 -split ",")
                                                           $cLogType = $clientLogging[0]
                                                           $cLogChecked = $true
                                                           switch ($cLogType)
                                                           {
                                                               'NONE' { $cLogChecked = $false }
                                                               'EWI'  { $cLogType = 'AllMilestones' }
                                                               'All'  { $cLogType = 'AllMilestonesAndAllDetails' }
                                                               'EW'   { $cLogType = 'ErrorAndWarningMilestones' }
                                                               'E'    { $cLogType = 'ErrorMilestones' }
                                                           }
                                                           $cLogFailure = [System.Convert]::ToBoolean($clientLogging[1])
                                                       }
        }
    }

    foreach ($prop in $serverComponentStatus.Props)
    {
        switch ($prop.PropertyName)
        {
            'Default Status Message Reporting Level'   {
                                                           $serverReporting = ($prop.Value1 -split ",")
                                                           $sReportType = $serverReporting[0]
                                                           $sReportChecked = $true
                                                           switch ($sReportType)
                                                           {
                                                               'NONE' { $sReportChecked = $false }
                                                               'EWI'  { $sReportType = 'AllMilestones' }
                                                               'All'  { $sReportType = 'AllMilestonesAndAllDetails' }
                                                               'EW'   { $sReportType = 'ErrorAndWarningMilestones' }
                                                               'E'    { $sReportType = 'ErrorMilestones' }
                                                           }
                                                           $sReportFailure = [System.Convert]::ToBoolean($serverReporting[1])
                                                       }
            'Default Windows NT Event Reporting Level' {
                                                           $serverLogging = ($prop.Value1 -split ",")
                                                           $sLogType = $serverLogging[0]
                                                           $sLogChecked = $true
                                                           switch ($sLogType)
                                                           {
                                                               'NONE' { $sLogChecked = $false }
                                                               'EWI'  { $sLogType = 'AllMilestones' }
                                                               'All'  { $sLogType = 'AllMilestonesAndAllDetails' }
                                                               'EW'   { $sLogType = 'ErrorAndWarningMilestones' }
                                                               'E'    { $sLogType = 'ErrorMilestones' }
                                                           }
                                                           $sLogFailure = [System.Convert]::ToBoolean($serverLogging[1])
                                                       }
        }
    }

    return @{
        SiteCode                   = $SiteCode
        ClientLogChecked           = $cLogChecked
        ClientLogFailureChecked    = $cLogFailure
        ClientLogType              = $cLogType
        ClientReportChecked        = $cReportChecked
        ClientReportFailureChecked = $cReportFailure
        ClientReportType           = $cReportType
        ServerLogChecked           = $sLogChecked
        ServerLogFailureChecked    = $sLogFailure
        ServerLogType              = $sLogType
        ServerReportChecked        = $sReportChecked
        ServerReportFailureChecked = $sReportFailure
        ServerReportType           = $sReportType
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER ClientLogChecked
        Indicates whether a client log is checked.

    .PARAMETER ClientLogFailureChecked
        Indicates whether a client log failure is checked.

    .PARAMETER ClientLogType
        Specifies a client log type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ClientReportChecked
        Indicates whether a client report is checked.

    .PARAMETER ClientReportFailureChecked
        Indicates whether a client failure is checked.

    .PARAMETER ClientReportType
        Specifies a client report type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ServerLogChecked
        Indicates whether a server log is checked.

    .PARAMETER ServerLogFailureChecked
        Indicates whether a server log failure is checked.

    .PARAMETER ServerLogType
        Specifies a server log type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ServerReportChecked
        Indicates whether a server report is checked.

    .PARAMETER ServerReportFailureChecked
        Indicates whether a server report failure is checked.

    .PARAMETER ServerReportType
        Specifies a server report type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones
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
        [Boolean]
        $ClientLogChecked,

        [Parameter()]
        [Boolean]
        $ClientLogFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ClientLogType,

        [Parameter()]
        [Boolean]
        $ClientReportChecked,

        [Parameter()]
        [Boolean]
        $ClientReportFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ClientReportType,

        [Parameter()]
        [Boolean]
        $ServerLogChecked,

        [Parameter()]
        [Boolean]
        $ServerLogFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ServerLogType,

        [Parameter()]
        [Boolean]
        $ServerReportChecked,

        [Parameter()]
        [Boolean]
        $ServerReportFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ServerReportType
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode

    try
    {
        if (($ClientLogChecked -eq $false) -and ($clientLogType -or $ClientLogFailureChecked))
        {
            throw $script:localizedData.CLogThrow
        }

        if (($ClientReportChecked -eq $false) -and ($ClientReportType -or $ClientReportFailureChecked))
        {
            throw $script:localizedData.CReportThrow
        }

        if (($ServerLogChecked -eq $false) -and ($ServerLogType -or $ServerLogFailureChecked))
        {
            throw $script:localizedData.SLogThrow
        }

        if (($ServerReportChecked -eq $false) -and ($ServerReportType -or $ServerReportFailureChecked))
        {
            throw $script:localizedData.SReportThrow
        }

        $evalList = @('ClientLogChecked','ClientLogFailureChecked','ClientLogType','ClientReportChecked','ClientReportFailureChecked','ClientReportType'
            'ServerLogChecked','ServerLogFailureChecked','ServerLogType','ServerReportChecked','ServerReportFailureChecked','ServerReportType')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
        if ($evalList -contains $param.Key)
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
            Set-CMStatusReportingComponent -SiteCode $SiteCode @buildingParams
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

    .PARAMETER ClientLogChecked
        Indicates whether a client log is checked.

    .PARAMETER ClientLogFailureChecked
        Indicates whether a client log failure is checked.

    .PARAMETER ClientLogType
        Specifies a client log type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ClientReportChecked
        Indicates whether a client report is checked.

    .PARAMETER ClientReportFailureChecked
        Indicates whether a client failure is checked.

    .PARAMETER ClientReportType
        Specifies a client report type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ServerLogChecked
        Indicates whether a server log is checked.

    .PARAMETER ServerLogFailureChecked
        Indicates whether a server log failure is checked.

    .PARAMETER ServerLogType
        Specifies a server log type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones

    .PARAMETER ServerReportChecked
        Indicates whether a server report is checked.

    .PARAMETER ServerReportFailureChecked
        Indicates whether a server report failure is checked.

    .PARAMETER ServerReportType
        Specifies a server report type. The acceptable values are:

        AllMilestones, AllMilestonesAndAllDetails, ErrorAndWarningMilestones, ErrorMilestones
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
        [Boolean]
        $ClientLogChecked,

        [Parameter()]
        [Boolean]
        $ClientLogFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ClientLogType,

        [Parameter()]
        [Boolean]
        $ClientReportChecked,

        [Parameter()]
        [Boolean]
        $ClientReportFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ClientReportType,

        [Parameter()]
        [Boolean]
        $ServerLogChecked,

        [Parameter()]
        [Boolean]
        $ServerLogFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ServerLogType,

        [Parameter()]
        [Boolean]
        $ServerReportChecked,

        [Parameter()]
        [Boolean]
        $ServerReportFailureChecked,

        [Parameter()]
        [ValidateSet('AllMilestones','AllMilestonesAndAllDetails','ErrorAndWarningMilestones','ErrorMilestones')]
        [String]
        $ServerReportType
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true

    $testParams = @{
        CurrentValues = $state
        DesiredValues = $PSBoundParameters
        ValuesToCheck = @('ClientLogChecked','ClientLogFailureChecked','ClientLogType','ClientReportChecked','ClientReportFailureChecked','ClientReportType'
            'ServerLogChecked','ServerLogFailureChecked','ServerLogType','ServerReportChecked','ServerReportFailureChecked','ServerReportType')
    }

    $result = Test-DscParameterState @testParams -Verbose -TurnOffTypeChecking

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
