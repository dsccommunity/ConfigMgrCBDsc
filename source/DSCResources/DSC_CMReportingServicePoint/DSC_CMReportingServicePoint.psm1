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
        In order to use this resource, SQL Server Reporting Services must be installed and configured.
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

    $rspProps = (Get-CMReportingServicePoint -SiteCode $SiteCode -SiteSystemServerName $SiteServerName).Props

    if ($rspProps)
    {
        foreach ($rspProp in $rspProps)
        {
            switch ($rspProp.PropertyName)
            {
                'DatabaseName'         { $dbName = $rspProp.Value2 }
                'DatabaseServerName'   { $dbServerName = $rspProp.Value2 }
                'UserName'             { $account = $rspProp.Value2 }
                'ReportServerInstance' { $rptInstance = $rspProp.Value2 }
                'RootFolder'           { $folder = $rspProp.Value2 }
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteServerName       = $SiteServerName
        SiteCode             = $SiteCode
        DatabaseName         = $dbName
        DatabaseServerName   = $dbServerName
        UserName             = $account
        FolderName           = $folder
        ReportServerInstance = $rptInstance
        Ensure               = $status
    }
}

 <#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER DatabaseName
        Specifies the name of the Configuration Manager database that you want to use as the data source for reports
        from Microsoft SQL Server Reporting Services.

    .PARAMETER DatabaseServerName
        Specifies the name of the Configuration Manager database server that you want to use as the data source for
        reports from Microsoft SQL Server Reporting Services.

        To specify a database instance, use the format <Server Name>\<Instance Name>.

    .PARAMETER FolderName
        Specifies the name of the report folder on the report server.
        This parameter can only be used when installing the role.
        Once the role is installed, this parameter cannot be changed without uninstalling the role.

    .PARAMETER ReportServerInstance
        Specifies the name of an instance of Microsoft SQL Server Reporting Services.
        This parameter can only be used when installing the role.
        Once the role is installed, this parameter cannot be changed without uninstalling the role.

    .PARAMETER UserName
        Specifies a user name for an account that Configuration Manager uses to connect with Microsoft SQL Server
        Reporting Services and that gives this user access to the site database.

        If specifying an account the account must already exist in
        Configuration Manager. This can be achieved by using the CMAccounts Resource.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.
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
        $DatabaseName,

        [Parameter()]
        [String]
        $DatabaseServerName,

        [Parameter()]
        [String]
        $FolderName,

        [Parameter()]
        [String]
        $ReportServerInstance,

        [Parameter()]
        [String]
        $UserName,

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
            $evalList = @('DatabaseName','DatabaseServerName','UserName','FolderName','ReportServerInstance')

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

            if ($state.Ensure -eq 'Absent')
            {
                if ([string]::IsNullOrEmpty($buildingParams.UserName))
                {
                    throw $script:localizedData.SpecifyUser
                }

                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                Write-Verbose -Message ($script:localizedData.AddRSPRole -f $SiteServerName)
                Add-CMReportingServicePoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
            }
            else
            {
                if ((-not [string]::IsNullOrEmpty($buildingParams.FolderName)) -or (-not [string]::IsNullOrEmpty($buildingParams.ReportServerInstance)))
                {
                    throw $script:localizedData.ThrowParams
                }
                elseif ($buildingParams)
                {
                    Set-CMReportingServicePoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveRSPRole -f $SiteServerName)
            Remove-CMReportingServicePoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
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

    .PARAMETER DatabaseName
        Specifies the name of the Configuration Manager database that you want to use as the data source for reports
        from Microsoft SQL Server Reporting Services.

    .PARAMETER DatabaseServerName
        Specifies the name of the Configuration Manager database server that you want to use as the data source for
        reports from Microsoft SQL Server Reporting Services.

        To specify a database instance, use the format <Server Name>\<Instance Name>.

    .PARAMETER FolderName
        Specifies the name of the report folder on the report server.
        This parameter can only be used when installing the role.
        Once the role is installed, this parameter cannot be changed without uninstalling the role.

    .PARAMETER ReportServerInstance
        Specifies the name of an instance of Microsoft SQL Server Reporting Services.
        This parameter can only be used when installing the role.
        Once the role is installed, this parameter cannot be changed without uninstalling the role.

    .PARAMETER UserName
        Specifies a user name for an account that Configuration Manager uses to connect with Microsoft SQL Server
        Reporting Services and that gives this user access to the site database.

        If specifying an account the account must already exist in
        Configuration Manager. This can be achieved by using the CMAccounts Resource.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.
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
        $DatabaseName,

        [Parameter()]
        [String]
        $DatabaseServerName,

        [Parameter()]
        [String]
        $FolderName,

        [Parameter()]
        [String]
        $ReportServerInstance,

        [Parameter()]
        [String]
        $UserName,

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
            Write-Verbose -Message ($script:localizedData.RSPNotInstalled -f $SiteServerName)
            $result = $false
        }
        else
        {
            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = ('DatabaseName','DatabaseServerName','UserName','FolderName','ReportServerInstance')
            }

            $result = Test-DscParameterState @testParams -Verbose

	        if ($FolderName -or $ReportServerInstance)
            {
                Write-Warning -Message $script:localizedData.ThrowParams
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.RSPAbsent -f $SiteServerName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
