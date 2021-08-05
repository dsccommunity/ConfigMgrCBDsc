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

    $senderProps = (Get-CMSiteComponent -ComponentName 'SMS_LAN_Sender' -SiteCode $SiteCode).Props
    foreach ($item in $senderProps)
    {
        switch ($item.PropertyName)
        {
            'Concurrent Sending Limit' {
                                         $allSites = $item.Value1
                                         $perSite  = $item.Value2
                                       }
            'Number of Retries'        { $retry = $item.Value }
            'Retry Delay'              { $retryDelay = $item.Value }
        }
    }

    $hiercySettings = (Get-CMSiteDefinition -SiteCode $SiteCode).Props

    $comments = ($hiercySettings | Where-Object -FilterScript {$_.PropertyName -eq 'Comments'}).Value1

    $defaultSize = ($hiercySettings | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value1
    $maxSize = ($hiercySettings | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value2

    if (($hiercySettings | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value -eq 0)
    {
        $siteServerDeployment = 'Block'
    }
    else
    {
        $siteServerDeployment = 'Warn'
    }

    #[boolean]$nonCrit = ($hiercySettings | Where-Object -FilterScript {$_.PropertyName -eq 'Enable Console Notifications'}).Value

    # Alerts
    $dbAlert = (Get-CMAlert | Where-Object -FilterScript {$_.Name -eq '$DatabaseFreeSpaceWarningName'}).PropertyList.ParameterValues[-1]
    if ($dbAlert -ne '>')
    {
        $dbAlertXml = [xml]$dbAlert
        $freeSpaceAlert = $true
        $warningGB = $dbAlertXml.Parameters.Parameter[2].'#text'
        $critGB = $dbAlertXml.Parameters.Parameter[3].'#text'
    }
    else
    {
        $freeSpaceAlert = $false
    }

    # Communication Security
    $props = (Get-CMSiteComponent -ComponentName 'SMS_Site_Component_Manager' -SiteCode $SiteCode).Props
    $clientComms = ($props | Where-Object -FilterScript {$_.PropertyName -eq 'IISSSLState'}).Value

    if ($clientComms -eq 31)
    {
        $clientCommunication = 'HttpsOnly'
        $useCrl = $false
        $pkiClient = $true
        $sccmCert = $false
    }
    elseif ($clientComms -eq 63)
    {
        $clientCommunication = 'HttpsOnly'
        $useCrl = $true
        $pkiClient = $true
        $sccmCert = $false
    }
    elseif ($clientComms -eq 192)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $false
        $pkiClient = $false
        $sccmCert = $false
    }
    elseif ($clientComms -eq 224)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $true
        $pkiClient = $false
        $sccmCert = $false
    }
    elseif ($clientComms -eq 448)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $false
        $pkiClient = $true
        $sccmCert = $false
    }
    elseif ($clientComms -eq 480)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $true
        $pkiClient = $true
        $sccmCert = $false
    }
    elseif ($clientComms -eq 1216)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $false
        $pkiClient = $false
        $sccmCert = $true
    }
    elseif ($clientComms -eq 1248)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $true
        $pkiClient = $false
        $sccmCert = $true
    }
    elseif ($clientComms -eq 1504)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $true
        $pkiClient = $true
        $sccmCert = $true
    }

    [boolean]$hash = ($props | Where-Object -FilterScript {$_.PropertyName -eq 'Enforce Enhanced Hash Algorithm'}).Value
    [boolean]$signing = ($props | Where-Object -FilterScript {$_.PropertyName -eq 'Enforce Message Signing'}).Value

    $siteSecurity = (Get-CMSiteComponent -ComponentName SMS_POLICY_PROVIDER).Props

    [boolean]$threeDes = ($siteSecurity | Where-Object -FilterScript {$_.PropertyName -eq 'Use Encryption'}).Value

    return @{
        SiteCode                                          = $SiteCode
        Comment                                           = $comments
        MaximumConcurrentSendingForAllSite                = $allSites
        MaximumConcurrentSendingForPerSite                = $perSite
        RetryNumberForConcurrentSending                   = $retry
        ConcurrentSendingDelayBeforeRetryingMins          = $retryDelay
        ThresholdOfSelectCollectionByDefault              = $defaultSize
        ThresholdOfSelectCollectionMax                    = $maxSize
        SiteSystemCollectionBehavior                      = $siteServerDeployment
        EnableLowFreeSpaceAlert                           = $freeSpaceAlert
        FreeSpaceThresholdWarningGB                       = $warningGB
        FreeSpaceThresholdCriticalGB                      = $critGB
        ClientComputerCommunicationType                   = $clientCommunication
        ClientCheckCertificateRevocationListForSiteSystem = $useCrl
        UsePkiClientCertificate                           = $pkiClient
        UseSmsGeneratedCert                               = $sccmCert
        RequireSha256                                     = $hash
        RequireSigning                                    = $signing
        UseEncryption                                     = $threeDes
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter Comment
        Specifies the site comments.

    .PARAMETER ClientComputerCommunicationType
        Specifies the communication method for the site systems that use IIS. To use HTTPS,
        the servers need a valid PKI web server certificate for server authentication.

    .PARAMETER ClientCheckCertificateRevocationListForSiteSystem
        Indicates whether clients check the Certificate Revocation List (CRL) for site systems.

    .PARAMETER UsePkiClientCertificate
        Indicates whether to use a PKI client certificate for client authentication when available.

    .PARAMETER UseSmsGeneratedCert
        Use this parameter to enable or disable the site property to Use Configuration Manager-generated
        certificates for HTTP site systems.

    .PARAMETER RequireSigning
        This option requires that clients sign data when they send to management points.

    .PARAMETER RequireSha256
        Specifies if the clients sign data and communicate with site systems by using HTTP, this option requires the
        clients to use SHA-256 to sign the data. This option applies to clients that don't use PKI certificates.

    .PARAMETER UseEncryption
        Specifies to use 3DES to encrypt the client inventory data and state messages that are sent to the
        management point.

    .PARAMETER MaximumConcurrentSendingForAllSite
        Specifies the maximum number of simultaneous communications to all sites.

    .PARAMETER MaximumConcurrentSendingForPerSite
        Specifies the maximum number of simultaneous communications to any single site.

    .PARAMETER RetryNumberForConcurrentSending
        Specifies the number of times to retry a failed communication.

    .PARAMETER ConcurrentSendingDelayBeforeRetryingMins
        Specifies the number of minutes to delay before it retries.

    .PARAMETER EnableLowFreeSpaceAlert
        Specifies if an alert is created when the free disk space on the site database server is low.

    .PARAMETER FreeSpaceThresholdWarningGB
        Specifies disk space warning alert when the free disk space on the
        site database server falls below the specified threshold.

    .PARAMETER FreeSpaceThresholdCriticalGB
        Specifies disk space critical alert when the free disk space on the
        site database server falls below the specified threshold.

    .PARAMETER ThresholdOfSelectCollectionByDefault
        Specifies select collection window hides collections with membership that
        exceeds this value.

    .PARAMETER ThresholdOfSelectCollectionMax
        Specifies select collection window always hides collections that have more members
        than this maximum value.

    .PARAMETER SiteSystemCollectionBehavior
        Specify the behavior to take when the selected collection includes computers that
        host site systems roles.
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
        [String]
        $Comment,

        [Parameter()]
        [ValidateSet('HttpsOnly','HttpsOrHttp')]
        [String]
        $ClientComputerCommunicationType,

        [Parameter()]
        [Boolean]
        $ClientCheckCertificateRevocationListForSiteSystem,

        [Parameter()]
        [Boolean]
        $UsePkiClientCertificate,

        [Parameter()]
        [Boolean]
        $UseSmsGeneratedCert,

        [Parameter()]
        [Boolean]
        $RequireSigning,

        [Parameter()]
        [Boolean]
        $RequireSha256,

        [Parameter()]
        [Boolean]
        $UseEncryption,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumConcurrentSendingForAllSite,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumConcurrentSendingForPerSite,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $RetryNumberForConcurrentSending,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $ConcurrentSendingDelayBeforeRetryingMins,

        [Parameter()]
        [Boolean]
        $EnableLowFreeSpaceAlert,

        [Parameter()]
        [ValidateRange(1,32767)]
        [UInt32]
        $FreeSpaceThresholdWarningGB,

        [Parameter()]
        [ValidateRange(1,32767)]
        [UInt32]
        $FreeSpaceThresholdCriticalGB,

        [Parameter()]
        [ValidateRange(0,1000000)]
        [UInt32]
        $ThresholdOfSelectCollectionByDefault,

        [Parameter()]
        [ValidateRange(0,1000000)]
        [UInt32]
        $ThresholdOfSelectCollectionMax,

        [Parameter()]
        [ValidateSet('Warn','Block')]
        [String]
        $SiteSystemCollectionBehavior
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
                Write-Verbose -Message ($script:localizedData.AddScpRole -f $SiteServerName)
                Add-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode -Mode $Mode
            }
            elseif ($state.Mode -ne $Mode)
            {
                Write-Verbose -Message ($script:localizedData.SettingValue -f $Mode)
                Set-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode -Mode $Mode
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveScpRole -f $SiteServerName)
            Remove-CMServiceConnectionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
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

    .Parameter Comment
        Specifies the site comments.

    .PARAMETER ClientComputerCommunicationType
        Specifies the communication method for the site systems that use IIS. To use HTTPS,
        the servers need a valid PKI web server certificate for server authentication.

    .PARAMETER ClientCheckCertificateRevocationListForSiteSystem
        Indicates whether clients check the Certificate Revocation List (CRL) for site systems.

    .PARAMETER UsePkiClientCertificate
        Indicates whether to use a PKI client certificate for client authentication when available.

    .PARAMETER UseSmsGeneratedCert
        Use this parameter to enable or disable the site property to Use Configuration Manager-generated
        certificates for HTTP site systems.

    .PARAMETER RequireSigning
        This option requires that clients sign data when they send to management points.

    .PARAMETER RequireSha256
        Specifies if the clients sign data and communicate with site systems by using HTTP, this option requires the
        clients to use SHA-256 to sign the data. This option applies to clients that don't use PKI certificates.

    .PARAMETER UseEncryption
        Specifies to use 3DES to encrypt the client inventory data and state messages that are sent to the
        management point.

    .PARAMETER MaximumConcurrentSendingForAllSite
        Specifies the maximum number of simultaneous communications to all sites.

    .PARAMETER MaximumConcurrentSendingForPerSite
        Specifies the maximum number of simultaneous communications to any single site.

    .PARAMETER RetryNumberForConcurrentSending
        Specifies the number of times to retry a failed communication.

    .PARAMETER ConcurrentSendingDelayBeforeRetryingMins
        Specifies the number of minutes to delay before it retries.

    .PARAMETER EnableLowFreeSpaceAlert
        Specifies if an alert is created when the free disk space on the site database server is low.

    .PARAMETER FreeSpaceThresholdWarningGB
        Specifies disk space warning alert when the free disk space on the
        site database server falls below the specified threshold.

    .PARAMETER FreeSpaceThresholdCriticalGB
        Specifies disk space critical alert when the free disk space on the
        site database server falls below the specified threshold.

    .PARAMETER ThresholdOfSelectCollectionByDefault
        Specifies select collection window hides collections with membership that
        exceeds this value.

    .PARAMETER ThresholdOfSelectCollectionMax
        Specifies select collection window always hides collections that have more members
        than this maximum value.

    .PARAMETER SiteSystemCollectionBehavior
        Specify the behavior to take when the selected collection includes computers that
        host site systems roles.
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

        [Parameter()]
        [String]
        $Comment,

        [Parameter()]
        [ValidateSet('HttpsOnly','HttpsOrHttp')]
        [String]
        $ClientComputerCommunicationType,

        [Parameter()]
        [Boolean]
        $ClientCheckCertificateRevocationListForSiteSystem,

        [Parameter()]
        [Boolean]
        $UsePkiClientCertificate,

        [Parameter()]
        [Boolean]
        $UseSmsGeneratedCert,

        [Parameter()]
        [Boolean]
        $RequireSigning,

        [Parameter()]
        [Boolean]
        $RequireSha256,

        [Parameter()]
        [Boolean]
        $UseEncryption,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumConcurrentSendingForAllSite,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumConcurrentSendingForPerSite,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $RetryNumberForConcurrentSending,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $ConcurrentSendingDelayBeforeRetryingMins,

        [Parameter()]
        [Boolean]
        $EnableLowFreeSpaceAlert,

        [Parameter()]
        [ValidateRange(1,32767)]
        [UInt32]
        $FreeSpaceThresholdWarningGB,

        [Parameter()]
        [ValidateRange(1,32767)]
        [UInt32]
        $FreeSpaceThresholdCriticalGB,

        [Parameter()]
        [ValidateRange(0,1000000)]
        [UInt32]
        $ThresholdOfSelectCollectionByDefault,

        [Parameter()]
        [ValidateRange(0,1000000)]
        [UInt32]
        $ThresholdOfSelectCollectionMax,

        [Parameter()]
        [ValidateSet('Warn','Block')]
        [String]
        $SiteSystemCollectionBehavior
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true
    $badInput = $false

    $defaultValues = @(
        'Comment','ClientComputerCommunicationType','ClientCheckCertificateRevocationListForSiteSystem',
        'UsePkiClientCertificate','RequireSigning','UseEncryption','MaximumConcurrentSendingForAllSite',
        'MaximumConcurrentSendingForPerSite','RetryNumberForConcurrentSending',
        'ConcurrentSendingDelayBeforeRetryingMins','EnableLowFreeSpaceAlert',
        'ThresholdOfSelectCollectionByDefault','ThresholdOfSelectCollectionMax','SiteSystemCollectionBehavior'
    )

    if ($ClientComputerCommunicationType -eq 'HttpsOnly' -and $PSBoundParameters.ContainsKey('UseSmsGeneratedCert'))
    {
        Write-Warning -Message 'When specifying HttpsOnly, UseSMSGeneratedCert can not be specified, ignoring setting.'
    }
    else
    {
        $defaultValues += @('UseSmsGeneratedCert')
    }

    if ($PSBoundParameters.ContainsKey('EnableLowFreeSpaceAlert') -and $EnableLowFreeSpaceAlert -eq $false)
    {
        if ($PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
        {
            Write-Warning 'EnableLowFreeSpaceAlert is disabled and FreeSpaceThreshold Warning\Critical GB was specified, ignoring setting'
        }
        else
        {
            if ($FreeSpaceThresholdCriticalGB -ge $FreeSpaceThresholdWarningGB)
            {
                Write-Warning 'FreeSpaceThresholdCritical is greater than or equal to FreeSpaceThresholdWarning.  Warning should be greater than Critical'
                $badInput = $true
            }

            $defaultValues += @('FreeSpaceThresholdCriticalGB','FreeSpaceThresholdWarningGB')
        }
    }

    $testParams = @{
        CurrentValues = $state
        DesiredValues = $PSBoundParameters
        ValuesToCheck = $defaultValues
    }

    $testResult = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

    if ($testResult -eq $true -and $badInput -eq $false)
    {
        $result = $true
    }
    else
    {
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
