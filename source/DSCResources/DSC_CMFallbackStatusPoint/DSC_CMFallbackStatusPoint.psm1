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
        This must be ran on the Primary servers to install the fallback status point role.
        The Primary server computer account must be in the local
        administrators group to perform the install.
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

    $fspProps = (Get-CMFallbackStatusPoint -SiteCode $SiteCode -SiteSystemServerName $SiteServerName).Props

    if ($fspProps)
    {
        foreach ($fspProp in $fspProps)
        {
            switch ($fspProp.PropertyName)
            {
                'Throttle Count'    { $throttleCount = $fspProp.Value }
                'Throttle Interval' { $throttleInterval = $fspProp.Value/1000 }
            }
        }
        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteServerName    = $SiteServerName
        SiteCode          = $SiteCode
        StateMessageCount = $throttleCount
        ThrottleSec       = $throttleInterval
        Ensure            = $status
    }
}

 <#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER StateMessageCount
        Specifies the number of state messages that a fallback status point can send to Configuration Manager within a throttle interval.

    .PARAMETER ThrottleSec
        Specifies the throttle interval in seconds.

    .PARAMETER Ensure
        Specifies whether the fallback status point is present or absent.

    .Notes
        This must be ran on the Primary servers to install the fallback status point role.
        The Primary server computer account must be in the local
        administrators group to perform the install.
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
        [ValidateRange(100,100000)]
        [UInt32]
        $StateMessageCount,

        [Parameter()]
        [ValidateRange(60,86400)]
        [UInt32]
        $ThrottleSec,

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
                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                Write-Verbose -Message ($script:localizedData.AddFSPRole -f $SiteServerName)
                Add-CMFallbackStatusPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
            }

            $evalList = @('StateMessageCount','ThrottleSec')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
            if ($evalList -contains $param.key)
                {
                    if ($param.Value -ne $state[$param.key])
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
                Set-CMFallbackStatusPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveFSPRole -f $SiteServerName)
            Remove-CMFallbackStatusPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
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

    .PARAMETER StateMessageCount
        Specifies the number of state messages that a fallback status point can send to Configuration Manager within a throttle interval.

    .PARAMETER ThrottleSec
        Specifies the throttle interval in seconds.

    .PARAMETER Ensure
        Specifies whether the fallback status point is present or absent.

    .Notes
        This must be ran on the Primary servers to install the fallback status point role.
        The Primary server computer account must be in the local
        administrators group to perform the install.
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
        [ValidateRange(100,100000)]
        [UInt32]
        $StateMessageCount,

        [Parameter()]
        [ValidateRange(60,86400)]
        [UInt32]
        $ThrottleSec,

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
            Write-Verbose -Message ($script:localizedData.FSPNotInstalled -f $SiteServerName)
            $result = $false
        }
        else
        {
            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('StateMessageCount','ThrottleSec')
            }

            $result = Test-DscParameterState @testParams -Verbose -TurnOffTypeChecking
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.FSPAbsent -f $SiteServerName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
