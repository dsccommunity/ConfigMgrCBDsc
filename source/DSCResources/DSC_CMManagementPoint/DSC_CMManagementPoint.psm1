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
        This must be ran on the Primary servers to install the ManagementPoint role.
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

    $mp = Get-CMManagementPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode

    if ($mp)
    {
        foreach ($mpProp in $mp.Props)
        {
            switch ($mpProp.PropertyName)
            {
                'AllowProxyTraffic' { $proxyTraffic = $mpProp.Value }
                'UseSiteDatabase'   { $usingSiteDatabase =  $mpProp.Value }
                'SQLServerName'     { $sqlServer = $mpProp.Value2 }
                'MPInternetFacing'  {
                                        if ($mpProp.Value -eq '1')
                                        {
                                            $internet = 'Internet'
                                        }
                                    }
                'MPIntranetFacing'  {
                                        if ($mpProp.Value -eq '1')
                                        {
                                            $intranet = 'Intranet'
                                        }
                                    }
                'Username'          {
                                        $userConnection = $mpProp.Value2
                                        if (($mpProp.Value2 -eq '') -or ($null -eq $mpProp.Value2))
                                        {
                                            $computerAccount = $true
                                        }
                                        else
                                        {
                                            $computerAccount = $false
                                        }
                                    }
                'DatabaseName'      {
                                        if ($mpProp.Value2.Contains('\'))
                                        {
                                            $instanceName = $mpProp.Value2.Split('\')[0]
                                            $dbName = $mpProp.Value2.Split('\')[-1]
                                        }
                                        else
                                        {
                                            $dbName = $mpProp.Value2
                                        }
                                    }
            }
        }

        if (($internet) -and ($intranet))
        {
            $connectionType = 'InternetAndIntranet'
        }
        else
        {
            $connectionType = $internet + $intranet
        }

        $searchText = "Not healthy alert for site role: Management point on `'$SiteServerName`'"
        $mpAlert = Get-CMAlert | Where-Object -FilterScript { $_.Name -eq $searchText }
        $mpHealthAlert = Get-CMAlert | Where-Object -FilterScript { $_.Name -eq '$MPRoleHealthAlertName' }

        if ($mpHealthAlert)
        {
            foreach ($item in $mpHealthAlert)
            {
                if ($item.TypeInstanceID -match $SiteServerName)
                {
                    $secondaryAlertCheck = $true
                }
            }
        }

        if (($mpAlert) -or ($secondaryAlertCheck))
        {
            $alert = $true
        }
        else
        {
            $alert = $false
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode              = $SiteCode
        SiteServerName        = $SiteServerName
        EnableSsl             = $mp.SslState
        ClientConnectionType  = $connectionType
        UseSiteDatabase       = $usingSiteDatabase
        GenerateAlert         = $alert
        EnableCloudGateway    = $proxyTraffic
        UseComputerAccount    = $computerAccount
        SQLServerFqdn         = $sqlServer
        SqlServerInstanceName = $instanceName
        DatabaseName          = $dbName
        Username              = $userConnection
        Ensure                = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER SqlServerFqdn
        Specifies the SQL server fqdn if using a SQL replica.

    .PARAMETER DatabaseName
        Specifies the name of the site database or site database replica that the management point uses
        to query for site database information.

    .PARAMETER ClientConnectionType
        Specifies the type of the client connection. The acceptable value are Internet,
        Intranet, and InterneAndIntranet.

    .PARAMETER EnableCloudGateway
        Specifies if a cloudgateway is to be used for the management point.

    .PARAMETER EnableSsl
        Specifies whether to enable SSL (HTTPS) traffic to the management point.

    .PARAMETER GenerateAlert
        Indicates whether the management point generates health alerts.

    .PARAMETER UseComputerAccount
        Indicates that the management point uses its own computer account
        instead of a domain user account to access site database information.

    .PARAMETER UseSiteDatabase
        Indicates whether the management point queries a site database instead of a
        site database replica for information.

    .PARAMETER SqlServerInstanceName
        Specifies the name of the SQL Server instance that clients use to communicate with the site system.

    .PARAMETER Username
        Specifies a domain user account that the management point uses to access site information.
        If specifying an account the account must already exist in
        Configuration Manager.  This can be achieved by:

        $secure = ConvertTo-SecureString -String "Password" -AsPlainText -Force
        New-CMAccount -Name 'contoso\test1' -Password $secure -SiteCode '<siteCode>'

    .Notes
        This must be ran on the Primary servers to install the ManagementPoint role.
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
        [String]
        $SqlServerFqdn,

        [Parameter()]
        [String]
        $DatabaseName,

        [Parameter()]
        [ValidateSet('Internet', 'Intranet', 'InternetAndIntranet')]
        [String]
        $ClientConnectionType,

        [Parameter()]
        [Boolean]
        $EnableCloudGateway,

        [Parameter()]
        [Boolean]
        $EnableSsl,

        [Parameter()]
        [Boolean]
        $GenerateAlert,

        [Parameter()]
        [Boolean]
        $UseSiteDatabase,

        [Parameter()]
        [Boolean]
        $UseComputerAccount,

        [Parameter()]
        [String]
        $SqlServerInstanceName,

        [Parameter()]
        [String]
        $Username,

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
        if (($EnableCloudGateway -eq $true) -or ($state.EnableCloudGateway -eq $true))
        {
            if (($ClientConnectionType -eq 'Intranet') -or ([string]::IsNullOrEmpty($ClientConnectionType) -and
                ([string]::IsNullOrEmpty($state.ClientConnectionType) -or $state.ClientConnectionType -eq 'Intranet')))
            {
                throw 'When CloudGateway is enabled, ClientConnectionType must not equal Intranet'
            }

            if (($PSBoundParameters.EnableSsl -eq $false) -or
                ([string]::IsNullOrEmpty($PSBoundParameters.EnableSsl) -and
                ([string]::IsNullOrEmpty($state.EnableSSL) -or $state.EnableSSL -eq $false)))
            {
                throw 'When CloudGateway is enabled SSL must also be enabled'
            }
        }

        if ((($SqlServerFqdn) -and [string]::IsNullOrEmpty($DatabaseName)) -or
            (($DatabaseName) -and [string]::IsNullOrEmpty($SqlServerFqdn)))
        {
            throw 'SQLServerFqdn and database name must be specified together'
        }

        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                Write-Verbose -Message ($script:localizedData.AddMPRole -f $SiteServerName)
                Add-CMManagementPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
            }

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if (($param.Key -ne 'Verbose') -and ($param.Key -ne 'Ensure'))
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

            if ($buildingParams)
            {
                Set-CMManagementPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
            }
        }
        else
        {
            if ($state.Ensure -eq 'Present')
            {
                Write-Verbose -Message ($script:localizedData.RemoveMPRole -f $SiteServerName)
                Remove-CMManagementPoint -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
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

    .PARAMETER SqlServerFqdn
        Specifies the SQL server fqdn if using a SQL replica.

    .PARAMETER DatabaseName
        Specifies the name of the site database or site database replica that the management point uses
        to query for site database information.

    .PARAMETER ClientConnectionType
        Specifies the type of the client connection. The acceptable value are Internet,
        Intranet, and InterneAndIntranet.

    .PARAMETER EnableCloudGateway
        Specifies if a cloudgateway is to be used for the management point.

    .PARAMETER EnableSsl
        Specifies whether to enable SSL (HTTPS) traffic to the management point.

    .PARAMETER GenerateAlert
        Indicates whether the management point generates health alerts.

    .PARAMETER UseComputerAccount
        Indicates that the management point uses its own computer account
        instead of a domain user account to access site database information.

    .PARAMETER UseSiteDatabase
        Indicates whether the management point queries a site database instead of a
        site database replica for information.

    .PARAMETER SqlServerInstanceName
        Specifies the name of the SQL Server instance that clients use to communicate with the site system.

    .PARAMETER Username
        Specifies a domain user account that the management point uses to access site information.
        If specifying an account the account must already exist in
        Configuration Manager.  This can be achieved by:

        $secure = ConvertTo-SecureString -String "Password" -AsPlainText -Force
        New-CMAccount -Name 'contoso\test1' -Password $secure -SiteCode '<siteCode>'

    .Notes
        This must be ran on the Primary servers to install the ManagementPoint role.
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
        [String]
        $SqlServerFqdn,

        [Parameter()]
        [String]
        $DatabaseName,

        [Parameter()]
        [ValidateSet('Internet', 'Intranet', 'InternetAndIntranet')]
        [String]
        $ClientConnectionType,

        [Parameter()]
        [Boolean]
        $EnableCloudGateway,

        [Parameter()]
        [Boolean]
        $EnableSsl,

        [Parameter()]
        [Boolean]
        $GenerateAlert,

        [Parameter()]
        [Boolean]
        $UseSiteDatabase,

        [Parameter()]
        [Boolean]
        $UseComputerAccount,

        [Parameter()]
        [String]
        $SqlServerInstanceName,

        [Parameter()]
        [String]
        $Username,

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
            Write-Verbose -Message ($script:localizedData.MPNotInstalled -f $SiteServerName)
            $result = $false
        }
        else
        {
            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if (($param.Key -ne 'Verbose') -and ($param.Key -ne 'Ensure'))
                {
                    if ($param.Value -ne $state[$param.key])
                    {
                        Write-Verbose -Message ($script:localizedData.TestSetting -f $param.Key, $param.Value, $state[$param.key])
                        $result = $false
                    }
                }
            }
        }
    }
    else
    {
        if ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.MPAbsent -f $SiteServerName)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path $env:windir
    return $result
}

Export-ModuleMember -Function *-TargetResource
