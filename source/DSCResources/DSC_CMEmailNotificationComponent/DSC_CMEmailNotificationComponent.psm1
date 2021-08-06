$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Enabled
        Specifies if email notifications are enabled or disabled.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $emailProps = (Get-CMEmailNotificationComponent -SiteCode $SiteCode).Props

    if (($emailProps.Where({$_.PropertyName -eq 'EnableSmtpSetting'})).Value -eq 1)
    {
        foreach ($emailProp in $emailProps)
        {
            switch ($emailProp.PropertyName)
            {
                'Port'                 { $portValue = $emailProp.Value }
                'SendFrom'             { $sendFromValue = $emailProp.Value1 }
                'ServerFqdn'           { $smtpServerFqdnValue = $emailProp.Value1 }
                'AuthenticationMethod' { $authValue = @('Anonymous','DefaultServiceAccount','Other')[($emailProp.Value)] }
                'UseSsl'               { [boolean]$useSslValue = $emailProp.Value }
            }
        }

        if ($authValue -eq 'Other')
        {
            $userNameValue = ($emailProps.Where({$_.PropertyName -eq 'UserName'})).Value1
        }

        $enabledValue = $true
    }
    else
    {
        $enabledValue = $false
    }

    return @{
        SiteCode             = $SiteCode
        UserName             = $userNameValue
        Port                 = $portValue
        SendFrom             = $sendFromValue
        SmtpServerFqdn       = $smtpServerFqdnValue
        TypeOfAuthentication = $authValue
        UseSsl               = $useSslValue
        Enabled              = $enabledValue
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Enabled
        Specifies if email notifications are enabled or disabled.

    .PARAMETER ServerFqdn
        Specifies the FQDN of the site server that will send e-mail.

    .PARAMETER SendFrom
        Specifies the address used to send mail.

    .PARAMETER Port
        Specifies the port used to send mail.

    .PARAMETER UserName
        Specifies the username for authenticating against an SMTP server.

    .PARAMETER UseSsl
        Specifies whether to use SSL for email alerts. If omitted, the assumed intent is that SSL is not to be used.

    .PARAMETER TypeOfAuthentication
        Specifies the method by which Configuration Manager authenticates the site server to the SMTP Server.
        The acceptable values for this parameter are: Anonymous, DefaultServiceAccount, Other
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [String]
        $SmtpServerFqdn,

        [Parameter()]
        [String]
        $SendFrom,

        [Parameter()]
        [UInt32]
        $Port,

        [Parameter()]
        [String]
        $Username,

        [Parameter()]
        [Boolean]
        $UseSsl,

        [Parameter()]
        [ValidateSet('Anonymous','DefaultServiceAccount','Other')]
        [String]
        $TypeOfAuthentication
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled

    try
    {
        if ($Enabled -eq $true)
        {
            if ([string]::IsNullOrEmpty($SmtpServerFqdn) -or [string]::IsNullOrEmpty($TypeOfAuthentication) -or
                [string]::IsNullOrEmpty($SendFrom))
            {
                throw $script:localizedData.MissingParams
            }

            if ($Username -and $TypeOfAuthentication -ne 'Other')
            {
                throw $script:localizedData.UserAuthNotOther
            }

            if ($TypeOfAuthentication -eq 'Other' -and [string]::IsNullOrEmpty($Username))
            {
                throw $script:localizedData.AuthOtherNoUser
            }

            if ($SmtpServerFqdn)
            {
                if ($SmtpServerFqdn.Contains('@') -or -not $SmtpServerFqdn.Contains('.'))
                {
                    throw ($script:localizedData.SmtpError -f $SmtpServerFqdn)
                }
            }

            if ($SendFrom)
            {
                if (-not $SendFrom.Contains('@') -or -not $SendFrom.Contains('.'))
                {
                    throw ($script:localizedData.SendFromError -f $SendFrom)
                }
            }

            if ($PSBoundParameters.ContainsKey('UseSsl'))
            {
                if (($state.UseSsl -eq $false -and $useSsl -eq $true) -and -not $PSBoundParameters.ContainsKey('Port'))
                {
                    Write-Warning -Message $script:localizedData.SSLTrueNoPort
                }

                if (($state.UseSsl -eq $true -and $UseSsl -eq $false) -and -not $PSBoundParameters.ContainsKey('Port'))
                {
                    Write-Warning -Message $script:localizedData.SSLFalseNoPort
                }

                if ($UseSsl -eq $true -and $Port -eq 25)
                {
                    throw $script:localizedData.SslBadPort
                }

                if (($UseSsl -eq $false) -and ($Port -eq '465'))
                {
                    throw $script:localizedData.NonSslBadPort
                }
            }

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($param.Key -ne 'SiteCode')
                {
                    if ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                    }

                    if ($param.Key -ne 'Enabled')
                    {
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
            }

            if ($buildingParams)
            {
                if ($buildingParams.ContainsKey('UserName'))
                {
                    $validateAccount = Get-CMAccount -UserName $Username -SiteCode $SiteCode

                    if ([string]::IsNullOrEmpty($validateAccount))
                    {
                        throw ($script:localizedData.AbsentUsername -f $Username)
                    }
                }

                Set-CMEmailNotificationComponent -EnableEmailNotification @buildingParams
            }
        }
        elseif ($state.Enabled -eq $true)
        {
            Write-Verbose -Message $script:localizedData.Disabled
            Set-CMEmailNotificationComponent -DisableEmailNotification
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Enabled
        Specifies if email notifications are enabled or disabled.

    .PARAMETER ServerFqdn
        Specifies the FQDN of the site server that will send e-mail.

    .PARAMETER SendFrom
        Specifies the address used to send mail.

    .PARAMETER Port
        Specifies the port used to send mail.

    .PARAMETER UserName
        Specifies the username for authenticating against an SMTP server. Only used when TypeOfAuthentication
        equals Other.

    .PARAMETER UseSsl
        Specifies whether to use SSL for email alerts. If omitted, the assumed intent is that SSL is not to be used.

    .PARAMETER TypeOfAuthentication
        Specifies the method by which Configuration Manager authenticates the site server to the SMTP Server.
        The acceptable values for this parameter are: Anonymous, DefaultServiceAccount, Other
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [String]
        $SmtpServerFqdn,

        [Parameter()]
        [String]
        $SendFrom,

        [Parameter()]
        [UInt32]
        $Port,

        [Parameter()]
        [String]
        $Username,

        [Parameter()]
        [Boolean]
        $UseSsl,

        [Parameter()]
        [ValidateSet('Anonymous','DefaultServiceAccount','Other')]
        [String]
        $TypeOfAuthentication
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled
    $result = $true
    $testResult = $true

    if ($Enabled -eq $true)
    {
        if ([string]::IsNullOrEmpty($SmtpServerFqdn) -or [string]::IsNullOrEmpty($TypeOfAuthentication) -or
            [string]::IsNullOrEmpty($SendFrom))
        {
            Write-Warning -Message $script:localizedData.MissingParams
            $result = $false
        }

        if ($TypeOfAuthentication -ne 'Other' -and $Username)
        {
            Write-Warning -Message $script:localizedData.UserAuthNotOther
            $result = $false
        }

        if ($TypeOfAuthentication -eq 'Other' -and [string]::IsNullOrEmpty($Username))
        {
            Write-Warning -Message $script:localizedData.AuthOtherNoUser
            $result = $false
        }

        if ($SmtpServerFqdn)
        {
            if ($SmtpServerFqdn.Contains('@') -or -not $SmtpServerFqdn.Contains('.'))
            {
                Write-Warning -Message ($script:localizedData.SmtpError -f $SmtpServerFqdn)
                $result = $false
            }
        }

        if ($SendFrom)
        {
            if (-not $SendFrom.Contains('@') -or -not $SendFrom.Contains('.'))
            {
                Write-Warning -Message ($script:localizedData.SendFromError -f $SendFrom)
                $result = $false
            }
        }

        if ($PSBoundParameters.ContainsKey('UseSsl'))
        {
            if (($state.UseSsl -eq $false -and $useSsl -eq $true) -and -not $PSBoundParameters.ContainsKey('Port'))
            {
                Write-Warning -Message $script:localizedData.SSLTrueNoPort
            }

            if (($state.UseSsl -eq $true -and $UseSsl -eq $false) -and -not $PSBoundParameters.ContainsKey('Port'))
            {
                Write-Warning -Message $script:localizedData.SSLFalseNoPort
            }

            if ($UseSsl -eq $true -and $Port -eq 25)
            {
                Write-Warning -Message $script:localizedData.SslBadPort
                $result = $false
            }

            if (($UseSsl -eq $false) -and ($Port -eq 465))
            {
                Write-Warning -Message $script:localizedData.NonSslBadPort
                $result = $false
            }
        }

        if ($state.Enabled -eq $false)
        {
            Write-Verbose -Message $script:localizedData.Enabled
            $result = $false
        }
        else
        {
            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Enabled','SmtpServerFqdn','SendFrom','Port',
                    'Username','UseSsl','TypeOfAuthentication')
            }

            $testResult = Test-DscParameterState @testParams -Verbose -TurnOffTypeChecking
        }
    }
    elseif ($state.Enabled -eq $true)
    {
        Write-Verbose -Message $script:localizedData.Disabled
        $result = $false
    }

    if ($result -eq $false -or $testResult -eq $false)
    {
        $finalResult = $false
    }
    else
    {
        $finalResult = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $finalResult)
    return $finalResult
}

Export-ModuleMember -Function *-TargetResource
