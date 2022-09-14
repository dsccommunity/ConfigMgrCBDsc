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

    .PARAMETER SiteSystemServer
        Specifies the name of the site system server.
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
        $SiteSystemServer
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $servercheck = (Get-CMSiteSystemServer -SiteSystemServerName $SiteSystemServer -SiteCode $SiteCode)

    if ($servercheck)
    {
        foreach ($check in $servercheck.Props)
        {
            switch ($check.PropertyName)
            {
                'Server Remote Public Name' { $publicName = $check.Value1 }
                'FDMOperation'              { [boolean]$fdm =  $check.Value }
                'UseMachineAccount'         { [boolean]$useMachine = $check.Value }
                'UserName'                  { $username = $check.Value2 }
                'UseProxy'                  { [boolean]$proxy = $check.Value }
                'ProxyName'                 { $proxyServer = $check.Value2 }
                'ProxyServerPort'           { [UInt32]$proxyPort = $check.Value }
                'ProxyUserName'             { $proxyUser = $check.Value2 }
                'AnonymousProxyAccess'      { $anon = $check.Value }
            }
        }

        if ($anon -eq 1)
        {
            $proxyUser = $null
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode             = $SiteCode
        SiteSystemServer     = $SiteSystemServer
        PublicFqdn           = $publicName
        FdmOperation         = $fdm
        UseSiteServerAccount = $useMachine
        AccountName          = $username
        EnableProxy          = $proxy
        ProxyServerName      = $proxyServer
        ProxyServerPort      = $proxyPort
        ProxyAccessAccount   = $proxyUser
        Ensure               = $status
        RoleCount            = $servercheck.RoleCount
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteSystemServer
        Specifies the name of the site system server.

    .PARAMETER PublicFqdn
        Specifies the public FQDN of the site server.  Setting PublicFqdn = '' will disable
        the PublicFqdn setting.

    .PARAMETER FdmOperation
        Indicates whether the site system server is required to initiate connections to this site system.

    .PARAMETER UseSiteServerAccount
        Indicates that the cmdlet uses the site server's computer account to install the site system.

    .PARAMETER AccountName
        Specifies the account name for installing the site system. The account must already exist in Configuration Manager.

    .PARAMETER EnableProxy
        Indicates whether to enable a proxy server to use when the server synchronizes information from the Internet.

    .PARAMETER ProxyServerName
        Specifies the name of a proxy server. Use a fully qualified domain name FQDN, short name, or IPv4/IPv6 address.
        When specifying EnableProxy, ProxyServerName must be specified.

    .PARAMETER ProxyServerPort
        Specifies the proxy server port number to use when connecting to the Internet.

    .PARAMETER ProxyAccessAccount
        Specifies the credentials to use to authenticate with the proxy server.
        Do not use user principal name (UPN) format. Setting $ProxyAccessAccount = '' will remove the account.

    .PARAMETER Ensure
        Specifies whether the site system server is to be present or absent.  When removing the role, all other site system roles
        must first be removed.
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
        $SiteSystemServer,

        [Parameter()]
        [String]
        $PublicFqdn,

        [Parameter()]
        [Boolean]
        $FdmOperation,

        [Parameter()]
        [Boolean]
        $UseSiteServerAccount,

        [Parameter()]
        [String]
        $AccountName,

        [Parameter()]
        [Boolean]
        $EnableProxy,

        [Parameter()]
        [String]
        $ProxyServerName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [UInt32]
        $ProxyServerPort,

        [Parameter()]
        [String]
        $ProxyAccessAccount,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteSystemServer $SiteSystemServer

    try
    {
        if ($Ensure -eq 'Present')
        {
            if (($PSBoundParameters.ContainsKey('UseSiteServerAccount') -and $PSBoundParameters.UseSiteServerAccount -eq $true) -and
                $PSBoundParameters.ContainsKey('AccountName'))
            {
                throw $script:localizedData.SiteSvrAccountandAccount
            }

            if ($EnableProxy -eq $true -and -not $PSBoundParameters.ContainsKey('ProxyServerName'))
            {
                throw $script:localizedData.EnableProxyNoServer
            }

            if (($PSBoundParameters.ContainsKey('ProxyServerPort') -or $PSBoundParameters.ContainsKey('ProxyAccessAccount') -or
                    $PSBoundParameters.ContainsKey('ProxyServerName')) -and ($EnableProxy -ne $true))
            {
                throw $script:localizedData.ProxySettingNoEnable
            }

            if ($state.Ensure -eq 'Absent')
            {
                $newServer = $true
            }

            $valuesToCheck = @('PublicFqdn','FdmOperation','UseSiteServerAccount','AccountName')
            $proxyCheck = @('EnableProxy','ProxyServerName','ProxyServerPort','ProxyAccessAccount')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($valuesToCheck -contains $param.Key)
                {
                    if ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.SetSetting -f $param.Key, $param.Value)

                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
                elseif ($proxyCheck -contains $param.Key)
                {
                    if ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.SetSetting -f $param.Key, $param.Value)
                        $proxyBad = $true
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($buildingParams) -and $buildingParams.ContainsKey('AccountName'))
            {
                if ($null -eq (Get-CMAccount -UserName $AccountName))
                {
                    throw ($script:localizedData.BadAccountName -f $AccountName)
                }
            }

            if ($proxyBad)
            {
                if ($EnableProxy -eq $true)
                {
                    $buildingParams += @{
                        EnableProxy     = $true
                        ProxyServerName = $ProxyServerName
                    }

                    if ($PSBoundParameters.ContainsKey('ProxyServerPort'))
                    {
                        $buildingParams += @{
                            ProxyServerPort = $ProxyServerPort
                        }
                    }

                    if ($PSBoundParameters.ContainsKey('ProxyAccessAccount'))
                    {
                        if (-not [string]::IsNullOrEmpty($ProxyAccessAccount))
                        {
                            $account = Get-CMAccount -UserName $ProxyAccessAccount

                            if ([string]::IsNullOrEmpty($account))
                            {
                                throw ($script:localizedData.BadProxyAccess -f $ProxyAccessAccount)
                            }

                            $buildingParams += @{
                                ProxyAccessAccount = $account
                            }
                        }
                    }

                    if ((-not $PSBoundParameters.ContainsKey('ProxyServerPort')) -and
                        (-not [string]::IsNullOrEmpty($state.ProxyServerPort) -and $state.ProxyServerPort -ne 80))
                    {
                        Write-Warning -Message ($script:localizedData.NoProxyPort -f $state.ProxyServerPort)
                    }

                    if (-not $PSBoundParameters.ContainsKey('ProxyAccessAccount') -and
                        -not [string]::IsNullOrEmpty($state.ProxyAccessAccount))
                    {
                        Write-Warning -Message ($script:localizedData.NoProxyAccessAccount -f $state.ProxyAccessAccount)
                    }
                }
                else
                {
                    $buildingParams += @{
                        EnableProxy = $false
                    }
                }
            }

            if ($newServer)
            {
                New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteSystemServer
            }

            if ($buildingParams)
            {
                Set-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteSystemServer @buildingParams
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            if ($state.RoleCount -ge 2)
            {
                throw ($script:localizedData.CurrentRoleCount -f $state.RoleCount)
            }

            Remove-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteSystemServer
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

    .PARAMETER SiteSystemServer
        Specifies the name of the site system server.

    .PARAMETER PublicFqdn
        Specifies the public FQDN of the site server.  Setting PublicFqdn = '' will disable
        the PublicFqdn setting.

    .PARAMETER FdmOperation
        Indicates whether the site system server is required to initiate connections to this site system.

    .PARAMETER UseSiteServerAccount
        Indicates that the cmdlet uses the site server's computer account to install the site system.

    .PARAMETER AccountName
        Specifies the account name for installing the site system. The account must already exist in Configuration Manager.

    .PARAMETER EnableProxy
        Indicates whether to enable a proxy server to use when the server synchronizes information from the Internet.

    .PARAMETER ProxyServerName
        Specifies the name of a proxy server. Use a fully qualified domain name FQDN, short name, or IPv4/IPv6 address.
        When specifying EnableProxy, ProxyServerName must be specified.

    .PARAMETER ProxyServerPort
        Specifies the proxy server port number to use when connecting to the Internet.

    .PARAMETER ProxyAccessAccount
        Specifies the credentials to use to authenticate with the proxy server.
        Do not use user principal name (UPN) format. Setting $ProxyAccessAccount = '' will remove the account.

    .PARAMETER Ensure
        Specifies whether the site system server is to be present or absent.  When removing the role, all other site system roles
        must first be removed.
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
        $SiteSystemServer,

        [Parameter()]
        [String]
        $PublicFqdn,

        [Parameter()]
        [Boolean]
        $FdmOperation,

        [Parameter()]
        [Boolean]
        $UseSiteServerAccount,

        [Parameter()]
        [String]
        $AccountName,

        [Parameter()]
        [Boolean]
        $EnableProxy,

        [Parameter()]
        [String]
        $ProxyServerName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [UInt32]
        $ProxyServerPort,

        [Parameter()]
        [String]
        $ProxyAccessAccount,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteSystemServer $SiteSystemServer
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.NonSiteServer -f $SiteSystemServer)
            $result = $false
        }
        else
        {
            if (($PSBoundParameters.ContainsKey('UseSiteServerAccount') -and $PSBoundParameters.UseSiteServerAccount -eq $true) -and
                $PSBoundParameters.ContainsKey('AccountName'))
            {
                Write-Warning -Message $script:localizedData.SiteSvrAccountandAccount
            }

            if ($EnableProxy -eq $true -and -not $PSBoundParameters.ContainsKey('ProxyServerName'))
            {
                Write-Warning -Message $script:localizedData.EnableProxyNoServer
            }

            if (($PSBoundParameters.ContainsKey('ProxyServerPort') -or $PSBoundParameters.ContainsKey('ProxyAccessAccount') -or
                   $PSBoundParameters.ContainsKey('ProxyServerName')) -and ($EnableProxy -ne $true))
            {
                Write-Warning -Message $script:localizedData.ProxySettingNoEnable
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('PublicFqdn','FdmOperation','UseSiteServerAccount','AccountName')
            }

            $result = Test-DscParameterState @testParams -Verbose -TurnOffTypeChecking

            $proxyCheck = @('EnableProxy','ProxyServerName','ProxyServerPort','ProxyAccessAccount')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($proxyCheck -contains $param.Key)
                {
                    if ($param.Key -eq 'ProxyAccessAccount' -and $param.Value -eq '')
                    {
                        if (-not [string]::IsNullOrEmpty($state.ProxyAccessAccount))
                        {
                            Write-Verbose -Message ($script:localizedData.ProxyCheck -f $param.Key, $param.Value, $state[$param.Key])
                            $proxyBad = $true
                        }
                    }
                    elseif ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.ProxyCheck -f $param.Key, $param.Value, $state[$param.Key])
                        $proxybad = $true
                    }
                }
            }

            if ($proxyBad)
            {
                if ((-not $PSBoundParameters.ContainsKey('ProxyServerPort')) -and
                    (-not [string]::IsNullOrEmpty($state.ProxyServerPort) -and $state.ProxyServerPort -ne 80))
                {
                    Write-Warning -Message ($script:localizedData.NoProxyPort -f $state.ProxyServerPort)
                }

                if (-not $PSBoundParameters.ContainsKey('ProxyAccessAccount') -and -not [string]::IsNullOrEmpty($state.ProxyAccessAccount))
                {
                    Write-Warning -Message ($script:localizedData.NoProxyAccessAccount -f $state.ProxyAccessAccount)
                }

                $result = $false
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        if ($state.RoleCount -ge 2)
        {
            Write-Warning -Message ($script:localizedData.CurrentRoleCount -f $state.RoleCount)
        }

        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}
