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
        This must be ran on the Primary servers to install the distribution point role.
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
        $status = 'Present'
        $clientCommType = @('HTTP','HTTPS')[$dpInfo.Communication]

        $groups = (Get-CMBoundaryGroupSiteSystem | Where-Object -FilterScript {$_.ServerNalPath -eq $DPinfo.NALPath}).GroupID

        foreach ($group in $groups)
        {
            [array]$bGroups += (Get-CMBoundaryGroup -Id $group).Name
        }

        $dpProps = Get-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode

        foreach ($dpProp in $dpProps.Props)
        {
            switch ($dpProp.PropertyName)
            {
                'AvailableContentLibDrivesList' {
                                                    if ($dpProp.Value1.Length -eq 1)
                                                    {
                                                        $availContentDrivePrimary = ($dpProp.Value1).SubString(0,1)
                                                    }
                                                    else
                                                    {
                                                        $availContentDrivePrimary = ($dpProp.Value1).SubString(0,1)
                                                        $availContentDriveSecondary = ($dpProp.Value1).SubString(1,1)
                                                    }
                                                }
                'AvailablePkgShareDrivesList'   {
                                                    if ($dpProp.Value1.Length -eq 1)
                                                    {
                                                        $availPkgSharePrimary = ($dpProp.Value1).SubString(0,1)
                                                    }
                                                    else
                                                    {
                                                        $availPkgSharePrimary = ($dpProp.Value1).SubString(0,1)
                                                        $availPkgShareSecondary = ($dpProp.Value1).SubString(1,1)
                                                    }
                                                }
                'CertificateContextData'        { $certInfo = $dpProp.Value1 }
                'MinFreeSpace'                  { $freespace = $dpProp.Value }
                'IsAnonymousEnabled'            { [boolean]$anonymous = $dpProp.Value }
                'UpdateBranchCacheKey'          { [boolean]$branchCache = $dpProp.Value }
            }
        }

        if ($certInfo)
        {
            $validData = (Get-CMCertificate | Where-Object -FilterScript {$_.Certificate -match $certInfo}).ValidUntil
        }
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                        = $SiteCode
        SiteServerName                  = $SiteServerName
        Description                     = $dpInfo.Description
        MinimumFreeSpaceMB              = $freespace
        PrimaryContentLibraryLocation   = $availcontentDrivePrimary
        SecondaryContentLibraryLocation = $availContentDriveSecondary
        PrimaryPackageShareLocation     = $availPkgSharePrimary
        SecondaryPackageShareLocation   = $availPkgShareSecondary
        ClientCommunicationType         = $clientCommType
        BoundaryGroups                  = $bGroups
        AllowPreStaging                 = $dpInfo.PreStagingAllowed
        CertificateExpirationTimeUtc    = $validData
        EnableAnonymous                 = $anonymous
        EnableBranchCache               = $branchCache
        EnableLedbat                    = $dpInfo.EnableLEDBAT
        Ensure                          = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER Description
        Specifies a description for the distribution point.

    .PARAMETER MinimumFreeSpaceMB
        Specifies the amount of free space to reserve on each drive used by this distribution point.
        Only used when distribution point is not currently installed.

    .PARAMETER PrimaryContentLibraryLocation
        Specifies the primary content location. Configuration Manager copies content to the primary content location
        until the amount of free space reaches the value that you specified.
        Only used when distribution point is not currently installed.

    .PARAMETER SecondaryContentLibraryLocation
        Specifies the secondary content location.
        Only used when distribution point is not currently installed.

    .PARAMETER PrimaryPackageShareLocation
        Specifies the primary package share location. Configuration Manager copies content to the primary package
        share location until the amount of free space reaches the value that you specified.
        Only used when distribution point is not currently installed.

    .PARAMETER SecondaryPackageShareLocation
        Specifies the secondary package share location.
        Only used when distribution point is not currently installed.

    .PARAMETER CertificateExpirationTimeUtc
        Specifies, in UTC format, the date and time when the certificate expires.
        If not specified and a Distribution Point is added, by a certificate will be
        generated with an expiration date of 2 years from date installed.

    .PARAMETER ClientCommunicationType
        Specifies protocol clients or devices communicate with the distribution point.

    .PARAMETER BoundaryGroups
        Specifies an array of boundary groups by name.

    .PARAMETER BoundaryGroupStatus
        Specifies if the boundary group is to be added, removed, or match BoundaryGroups.

    .PARAMETER AllowPreStaging
        Indicates whether the distribution point is enabled for prestaged content.

    .PARAMETER EnableAnonymous
        Indicates that the distribution point permits anonymous connections from Configuration Manager clients
        to the content library.

    .PARAMETER EnableBranchCache
        Indicates that clients that use Windows BranchCache are allowed to download content from an on-premises
        distribution point.

    .PARAMETER EnableLedbat
        Indicates whether to adjust the download speed to use the unused network Bandwidth or Windows LEDBAT.

    .PARAMETER Ensure
        Specifies if the DP is to be present or absent.
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
        [String]
        $Description,

        [Parameter()]
        [UInt32]
        $MinimumFreeSpaceMB,

        [Parameter()]
        [String]
        $PrimaryContentLibraryLocation,

        [Parameter()]
        [String]
        $SecondaryContentLibraryLocation,

        [Parameter()]
        [String]
        $PrimaryPackageShareLocation,

        [Parameter()]
        [String]
        $SecondaryPackageShareLocation,

        [Parameter()]
        [DateTime]
        $CertificateExpirationTimeUtc,

        [Parameter()]
        [ValidateSet('Http','Https')]
        [String]
        $ClientCommunicationType = 'Http',

        [Parameter()]
        [String[]]
        $BoundaryGroups,

        [Parameter()]
        [ValidateSet('Add','Remove','Match')]
        [String]
        $BoundaryGroupStatus = 'Add',

        [Parameter()]
        [Boolean]
        $AllowPreStaging,

        [Parameter()]
        [Boolean]
        $EnableAnonymous,

        [Parameter()]
        [Boolean]
        $EnableBranchCache,

        [Parameter()]
        [Boolean]
        $EnableLedbat,

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
                if (($PrimaryContentLibraryLocation.Length -gt 1 -or $PrimaryContentLibraryLocation -match '[0-9]') -or
                   ($SecondaryContentLibraryLocation.Length -gt 1 -or $SecondaryContentLibraryLocation -match '[0-9]') -or
                   ($PrimaryPackageShareLocation.Length -gt 1 -or $PrimaryPackageShareLocation -match '[0-9]') -or
                   ($SecondaryPackageShareLocation.Lenth -gt 1 -or $SecondaryPackageShareLocation -match '[0-9]'))
                {
                    throw $script:localizedData.InvalidPriOrSecLetter
                }

                if (($SecondaryContentLibraryLocation -and [string]::IsNullOrEmpty($PrimaryContentLibraryLocation)) -or
                   ($SecondaryPackageShareLocation -and [string]::IsNullOrEmpty($PrimaryPackageShareLocation)))
                {
                    throw $script:localizedData.SecAndNoPrimary
                }

                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                $initialValues = @('MinimumFreeSpaceMB','PrimaryContentLibraryLocation','SecondaryContentLibraryLocation',
                                    'PrimaryPackageShareLocation','SecondaryPackageShareLocation','CertificateExpirationTimeUtc')

                foreach ($item in $initialValues)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $dpSetupParams += @{
                            $item = $PSBoundParameters.$item
                        }
                    }
                }

                if (-not $PSBoundParameters.ContainsKey('CertificateExpirationTimeUtc'))
                {
                    $dateValueDefault = [DateTime]::Now.AddYears(2)

                    $dpSetupParams += @{
                        CertificateExpirationTimeUtc = $dateValueDefault
                    }
                }

                Write-Verbose -Message ($script:localizedData.AddDPRole -f $SiteServerName)
                Add-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode  @dpSetupParams
            }

            $additionalParams = @('Description','ClientCommunicationType','AllowPreStaging','EnableAnonymous',
                                'EnableBranchCache','EnableLedbat')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($additionalParams -contains $param.key)
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

            if ($BoundaryGroups)
            {
                if ($BoundaryGroupStatus -ne 'Remove')
                {
                    foreach ($boundaryGroup in $BoundaryGroups)
                    {
                        if ($state.BoundaryGroups -notcontains $boundaryGroup)
                        {
                            if (Get-CMBoundaryGroup -Name $boundaryGroup)
                            {
                                Write-Verbose -Message ($script:localizedData.BoundaryGroupAdd -f $boundaryGroup)
                                [array]$boundaryAddArray += $boundaryGroup
                            }
                            else
                            {
                                $errorMsg += ($script:localizedData.BoundaryGroupAbsent -f $boundaryGroup)
                            }
                        }
                    }
                }

                if ($BoundaryGroupStatus -eq 'Remove')
                {
                    foreach ($boundaryGroup in $BoundaryGroups)
                    {
                        if ($state.BoundaryGroups -contains $boundaryGroup)
                        {
                            Write-Verbose -Message ($script:localizedData.BoundaryGroupRemove -f $boundaryGroup)
                            [array]$boundaryRemoveArray += $boundaryGroup
                        }
                    }
                }

                if ($BoundaryGroupStatus -eq 'Match')
                {
                    foreach ($stateGroup in $state.BoundaryGroups)
                    {
                        if ($BoundaryGroups -notcontains $stateGroup)
                        {
                            Write-Verbose -Message ($script:localizedData.BoundaryGroupRemove -f $stateGroup)
                            [array]$boundaryRemoveArray += $stateGroup
                        }
                    }
                }

                if ($boundaryAddArray)
                {
                    $buildingParams += @{
                        AddBoundaryGroupName = $boundaryAddArray
                    }
                }

                if ($boundaryRemoveArray)
                {
                    $buildingParams += @{
                        RemoveBoundaryGroupName = $boundaryRemoveArray
                    }
                }
            }

            if ($buildingParams)
            {
                Set-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
            }

            if ($errorMsg)
            {
                throw $errorMsg
            }
        }
        else
        {
            if ($state.Ensure -eq 'Present')
            {
                Write-Verbose -Message ($script:localizedData.RemoveDPRole -f $SiteServerName)
                Remove-CMDistributionPoint -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
            }
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

    .PARAMETER Description
        Specifies a description for the distribution point.

    .PARAMETER MinimumFreeSpaceMB
        Specifies the amount of free space to reserve on each drive used by this distribution point.
        Only used when distribution point is not currently installed.

    .PARAMETER PrimaryContentLibraryLocation
        Specifies the primary content location. Configuration Manager copies content to the primary content location
        until the amount of free space reaches the value that you specified.
        Only used when distribution point is not currently installed.

    .PARAMETER SecondaryContentLibraryLocation
        Specifies the secondary content location.
        Only used when distribution point is not currently installed.

    .PARAMETER PrimaryPackageShareLocation
        Specifies the primary package share location. Configuration Manager copies content to the primary package
        share location until the amount of free space reaches the value that you specified.
        Only used when distribution point is not currently installed.

    .PARAMETER SecondaryPackageShareLocation
        Specifies the secondary package share location.
        Only used when distribution point is not currently installed.

    .PARAMETER CertificateExpirationTimeUtc
        Specifies, in UTC format, the date and time when the certificate expires.
        If not specified and a Distribution Point is added, by a certificate will be
        generated with an expiration date of 2 years from date installed.

    .PARAMETER ClientCommunicationType
        Specifies protocol clients or devices communicate with the distribution point.

    .PARAMETER BoundaryGroups
        Specifies an array of boundary groups by name.

    .PARAMETER BoundaryGroupStatus
        Specifies if the boundary group is to be added, removed, or match BoundaryGroups.

    .PARAMETER AllowPreStaging
        Indicates whether the distribution point is enabled for prestaged content.

    .PARAMETER EnableAnonymous
        Indicates that the distribution point permits anonymous connections from Configuration Manager clients
        to the content library.

    .PARAMETER EnableBranchCache
        Indicates that clients that use Windows BranchCache are allowed to download content from an on-premises
        distribution point.

    .PARAMETER EnableLedbat
        Indicates whether to adjust the download speed to use the unused network Bandwidth or Windows LEDBAT.

    .PARAMETER Ensure
        Specifies if the DP is to be present or absent.
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
        [String]
        $Description,

        [Parameter()]
        [UInt32]
        $MinimumFreeSpaceMB,

        [Parameter()]
        [String]
        $PrimaryContentLibraryLocation,

        [Parameter()]
        [String]
        $SecondaryContentLibraryLocation,

        [Parameter()]
        [String]
        $PrimaryPackageShareLocation,

        [Parameter()]
        [String]
        $SecondaryPackageShareLocation,

        [Parameter()]
        [DateTime]
        $CertificateExpirationTimeUtc,

        [Parameter()]
        [ValidateSet('Http','Https')]
        [String]
        $ClientCommunicationType = 'Http',

        [Parameter()]
        [String[]]
        $BoundaryGroups,

        [Parameter()]
        [ValidateSet('Add','Remove','Match')]
        [String]
        $BoundaryGroupStatus = 'Add',

        [Parameter()]
        [Boolean]
        $AllowPreStaging,

        [Parameter()]
        [Boolean]
        $EnableAnonymous,

        [Parameter()]
        [Boolean]
        $EnableBranchCache,

        [Parameter()]
        [Boolean]
        $EnableLedbat,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $result = $true
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.DPNotInstalled -f $SiteServerName)
            $result = $false
        }
        else
        {
            Write-Warning -Message $script:localizedData.SettingsNotEval

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Description','ClientCommunicationType','AllowPreStaging','EnableAnonymous',
                                'EnableBranchCache','EnableLedbat')
            }

            $result = Test-DscParameterState @testParams -Verbose

            if ($BoundaryGroups)
            {
                if ($BoundaryGroupStatus -ne 'Remove')
                {
                    foreach ($boundaryGroup in $BoundaryGroups)
                    {
                        if ($state.BoundaryGroups -notcontains $boundaryGroup)
                        {
                            Write-Verbose -Message ($script:localizedData.BoundaryGroupMissing -f $boundaryGroup)
                            $result = $false
                        }
                    }
                }

                if ($BoundaryGroupStatus -eq 'Remove')
                {
                    foreach ($boundaryGroup in $BoundaryGroups)
                    {
                        if ($state.BoundaryGroups -contains $boundaryGroup)
                        {
                            Write-Verbose -Message ($script:localizedData.BoundaryGroupExtra -f $boundaryGroup)
                            $result = $false
                        }
                    }
                }

                if ($BoundaryGroupStatus -eq 'Match')
                {
                    foreach ($stateGroup in $state.BoundaryGroups)
                    {
                        if ($BoundaryGroups -notcontains $stateGroup)
                        {
                            Write-Verbose -Message ($script:localizedData.BoundaryGroupExtra -f $stateGroup)
                            $result = $false
                        }
                    }
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
            Write-Verbose -Message ($script:localizedData.DPAbsent -f $SiteServerName)
            $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path $env:windir
    return $result
}

Export-ModuleMember -Function *-TargetResource
