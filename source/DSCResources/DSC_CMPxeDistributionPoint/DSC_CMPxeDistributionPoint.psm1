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
        Specifies the SiteServer to install the role on.

    .Notes
        This must be ran on the Primary servers to install the Distribution Point role.
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

    $dpInfo = Get-CMDistributionPointInfo -SiteSystemServerName $SiteServerName -SiteCode $SiteCode

    if ($dpInfo)
    {
        $uda = $dpInfo.UdaSetting
        $udaSetting = @('DoNotUse', 'AllowWithManualApproval','AllowWithAutomaticApproval')[$uda]

        $dpInstall = 'Present'
    }
    else
    {
        $dpInstall = 'Absent'
    }

    return @{
        SiteCode                     = $SiteCode
        SiteServerName               = $SiteServerName
        EnablePxe                    = $dpInfo.IsPxe
        EnableNonWdsPxe              = $dpInfo.SccmPxe
        EnableUnknownComputerSupport = $dpInfo.SupportUnknownMachines
        PxePassword                  = $dpInfo.PxePassword
        AllowPxeResponse             = $dpInfo.IsActive
        PxeServerResponseDelaySec    = [UInt16]$dpInfo.ResponseDelay
        UserDeviceAffinity           = $udaSetting
        IsMulticast                  = $dpInfo.IsMulticast
        DPStatus                     = $dpInstall
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER EnablePxe
        Indicates whether Pxe is enabled on the distribution point.
        When you enable Pxe, Configuration Manager installs Windows Deployment Services on the server, if required.
        Windows Deployment Services is the service that performs the Pxe boot to install operating systems.
        After you create the distribution point, Configuration Manager installs a provider in
        Windows Deployment Services that uses the Pxe boot functions.

    .PARAMETER EnableNonWdsPxe
        Specifies whether to enable Pxe responder without Windows Deployment services.

    .PARAMETER EnableUnknownComputerSupport
        Indicates whether support for unknown computers is enabled.
        Unknown computers are computers that are not managed by Configuration Manager.

    .PARAMETER AllowPxeResponse
        Indicates whether the distribution point can respond to Pxe requests.

    .PARAMETER PxeServerResponseDelaySec
        Specifies, in seconds, how long the distribution point delays before it responds to computer requests when
        you are using multiple Pxe-enabled distribution points. By default, the Configuration Manager
        Pxe service point responds first to network Pxe requests.

    .PARAMETER UserDeviceAffinity
        Specifies how you want the distribution point to associate users with their devices for Pxe deployments.

    .PARAMETER PxePassword
        Specifies, as a secure string, the Pxe password.
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
        [Boolean]
        $EnablePxe,

        [Parameter()]
        [Boolean]
        $EnableNonWdsPxe,

        [Parameter()]
        [Boolean]
        $EnableUnknownComputerSupport,

        [Parameter()]
        [Boolean]
        $AllowPxeResponse,

        [Parameter()]
        [ValidateRange(0,32)]
        [UInt16]
        $PxeServerResponseDelaySec,

        [Parameter()]
        [ValidateSet('DoNotUse','AllowWithManualApproval','AllowWithAutomaticApproval')]
        [String]
        $UserDeviceAffinity,

        [Parameter()]
        [PSCredential]
        $PxePassword
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    try
    {
        if ($state.DPStatus -eq 'Absent')
        {
            throw ($script:localizedData.DistroPointInstall -f $SiteServerName)
        }

        if ((($PSBoundParameters.EnablePxe -eq $false) -or ([string]::IsNullOrEmpty($PSBoundParameters.EnablePxe) -and
            $state.EnablePxe -eq $false)) -and (($PSBoundParameters.EnableNonWdsPxe) -or
            ($PSBoundParameters.EnableUnknownComputerSupport) -or ($PSBoundParameters.AllowPxeResponse) -or
            ($PSBoundParameters.PxeServerResponseDelaySec) -or ($PSBoundParameters.UserDeviceAffinity) -or
            ($PSBoundParameters.PxePassword)))
        {
            throw $script:localizedData.PxeThrow
        }

        if ($EnableNonWdsPxe -eq $true -and $state.IsMulticast -eq $true)
        {
            throw $script:localizedData.NonWdsThrow
        }

        $eval = @('EnablePxe','EnableNonWdsPxe','EnableUnknownComputerSupport','AllowPxeResponse',
                    'PxeServerResponseDelaySec','UserDeviceAffinity')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($eval -contains $param.key)
            {
                if ($param.Value -ne $state[$param.key])
                {
                    Write-Verbose -Message ($script:localizedData.SettingValue -f $param.key, $param.Value)

                    $buildingParams += @{
                        $param.key = $param.Value
                    }
                }
            }
        }

        if ((-not [string]::IsNullOrEmpty($PxePassword)) -and ([string]::IsNullOrEmpty($state.PxePassword)))
        {
            Write-Verbose -Message $script:localizedData.SetPxePassword
            $buildingParams += @{
                PxePassword = $PxePassword.Password
            }
        }

        if ($buildingParams)
        {
            Set-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
        }
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

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER EnablePxe
        Indicates whether Pxe is enabled on the distribution point.
        When you enable Pxe, Configuration Manager installs Windows Deployment Services on the server, if required.
        Windows Deployment Services is the service that performs the Pxe boot to install operating systems.
        After you create the distribution point, Configuration Manager installs a provider in
        Windows Deployment Services that uses the Pxe boot functions.

    .PARAMETER EnableNonWdsPxe
        Specifies whether to enable Pxe responder without Windows Deployment services.

    .PARAMETER EnableUnknownComputerSupport
        Indicates whether support for unknown computers is enabled.
        Unknown computers are computers that are not managed by Configuration Manager.

    .PARAMETER AllowPxeResponse
        Indicates whether the distribution point can respond to Pxe requests.

    .PARAMETER PxeServerResponseDelaySec
        Specifies, in seconds, how long the distribution point delays before it responds to computer requests when
        you are using multiple Pxe-enabled distribution points. By default, the Configuration Manager
        Pxe service point responds first to network Pxe requests.

    .PARAMETER UserDeviceAffinity
        Specifies how you want the distribution point to associate users with their devices for Pxe deployments.

    .PARAMETER PxePassword
        Specifies, as a secure string, the Pxe password.
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
        [Boolean]
        $EnablePxe,

        [Parameter()]
        [Boolean]
        $EnableNonWdsPxe,

        [Parameter()]
        [Boolean]
        $EnableUnknownComputerSupport,

        [Parameter()]
        [Boolean]
        $AllowPxeResponse,

        [Parameter()]
        [ValidateRange(0,32)]
        [UInt16]
        $PxeServerResponseDelaySec,

        [Parameter()]
        [ValidateSet('DoNotUse','AllowWithManualApproval','AllowWithAutomaticApproval')]
        [String]
        $UserDeviceAffinity,

        [Parameter()]
        [PSCredential]
        $PxePassword
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $returnValue = $true
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    if ($state.DPStatus -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.DistroPointInstall -f $SiteServerName)
        $returnValue = $false
    }
    else
    {
        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = @('EnablePxe','EnableNonWdsPxe','EnableUnknownComputerSupport','AllowPxeResponse',
                'PxeServerResponseDelaySec','UserDeviceAffinity')
        }

        $returnValue = Test-DscParameterState @testParams -Verbose

        if ((-not [string]::IsNullOrEmpty($PxePassword)) -and ([string]::IsNullOrEmpty($state.PxePassword)))
        {
            Write-Verbose -Message $script:localizedData.PXEPassword
            $returnValue = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path $env:windir
    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
