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

    $siteDef = Get-CMSiteDefinition -SiteCode $SiteCode
    $comments = ($siteDef.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Comments'}).Value1
    $defaultSize = ($siteDef.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value1
    $maxSize = ($siteDef.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value2

    if (($siteDef.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Device Collection Threshold'}).Value -eq 0)
    {
        $siteServerDeployment = 'Block'
    }
    else
    {
        $siteServerDeployment = 'Warn'
    }

    # Communication Security
    $comSec = Get-CMSiteComponent -ComponentName 'SMS_Site_Component_Manager' -SiteCode $SiteCode
    $clientComms = ($comSec.Props | Where-Object -FilterScript {$_.PropertyName -eq 'IISSSLState'}).Value

    if ($clientComms -eq 0)
    {
        $clientCommunication = 'HttpsOrHttp'
        $useCrl = $true
        $pkiClient = $true
        $sccmCert = $false
    }
    elseif ($clientComms -eq 31)
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

    foreach ($item in $comSec.Props)
    {
        switch ($item.PropertyName)
        {
            'Certificate Store'              { $customStore = $item.Value1 }
            'Select First Certificate'       { $certSel = @('FailSelectionAndSendErrorMessage','SelectCertificateWithLongestValidityPeriod')[($item.Value)] }
            'Certificate Selection Criteria' {
                                                $criteria = $item.Value1
                                                if ([string]::IsNullOrEmpty($criteria))
                                                {
                                                    $criteriaType = 'ClientAuthentication'
                                                    $criteriaValue = ''
                                                }
                                                else
                                                {
                                                    $criteriaValue = $criteria.Split(':')[1]

                                                    if ($criteria.Split(':')[0] -eq 'SubjectStr')
                                                    {
                                                        $criteriaType = 'CertificateSubjectContainsString'
                                                    }
                                                    else
                                                    {
                                                        $criteriaType = 'CertificateSubjectOrSanIncludesAtrributes'
                                                    }
                                                }
                                              }
        }
    }

    if ($siteDef.SiteType -eq 2)
    {
        $sType = 'Primary'

        # Alerts
        $dbAlert = (Get-CMAlert | Where-Object -FilterScript {$_.Name -eq '$DatabaseFreeSpaceWarningName'}).PropertyList.ParameterValues
        if ($dbAlert)
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

        [boolean]$hash = ($comSec.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Enforce Enhanced Hash Algorithm'}).Value
        [boolean]$signing = ($comSec.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Enforce Message Signing'}).Value

        $siteSecurity = (Get-CMSiteComponent -ComponentName SMS_POLICY_PROVIDER).Props

        [boolean]$threeDes = ($siteSecurity | Where-Object -FilterScript {$_.PropertyName -eq 'Use Encryption'}).Value

        # Wake On LAN
        $wol = Get-CMSiteComponent -ComponentName 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' -sitecode $SiteCode

        if ($wol.Flag -eq 6)
        {
            $wolEnabled = $true
        }
        else
        {
            $wolEnabled = $false
        }

        foreach ($item in $wol.Props)
        {
            switch ($item.PropertyName)
            {
                'SendRetryMax'         { $sendRetryMax = $item.Value }
                'SendRetryInterval'    { $sendRetryInterval = $item.Value / 60 }
                'SendThrottleMax'      { $sendThrottleMax = $item.Value }
                'SendThrottleInterval' { $sendThrottleInterval = $item.Value }
                'MaxThreads'           { $maxThreads = $item.Value }
                'SendMode'             {
                                            if ($item.Value -eq 1)
                                            {
                                                $sendMode = 'Unicast'
                                            }
                                            else
                                            {
                                                $sendMode = 'SubnetDirectedBroadcasts'
                                            }
                                        }
            }
        }

        $wolComponent = (Get-CMSiteComponent -ComponentName 'SMS_WAKEONLAN_MANAGER' -sitecode $SiteCode).Props
        $scheduleOffset = ($wolComponent | Where-Object -FilterScript {$_.PropertyName -eq 'ScheduleOffset'}).Value / 60
    }
    elseif ($siteDef.SiteType -eq 4)
    {
        $sType = 'Cas'
        $useCrl = $null
        $pkiClient = $null
    }

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
        SiteType                                          = $sType
        EnableWakeOnLan                                   = $wolEnabled
        WakeOnLanTransmissionMethodType                   = $sendMode
        RetryNumberOfSendingWakeupPacketTransmission      = $sendRetryMax
        SendingWakeupPacketTransmissionDelayMins          = $sendRetryInterval
        MaximumNumberOfSendingWakeupPacketBeforePausing   = $sendThrottleMax
        SendingWakeupPacketBeforePausingWaitSec           = $sendThrottleInterval
        ThreadNumberOfSendingWakeupPacket                 = $maxThreads
        SendingWakeupPacketTransmissionOffsetMins         = $scheduleOffset
        ClientCertificateCustomStoreName                  = $customStore
        TakeActionForMultipleCertificateMatchCriteria     = $certSel
        ClientCertificateSelectionCriteriaType            = $criteriaType
        ClientCertificateSelectionCriteriaValue           = $criteriaValue
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

    .PARAMETER EnableWakeOnLan
        Indicates whether to send Wake On LAN packets for scheduled activities such as deployments
        of software updates.

    .PARAMETER WakeOnLanTransmissionMethodType
        Specifies the type of transmission method to use for Wake On LAN transmissions.

    .PARAMETER RetryNumberOfSendingWakeupPacketTransmission
        Specifies the number of times a wake up packet is sent to a target computer.

    .PARAMETER SendingWakeupPacketTransmissionDelayMins
        Specifies the number of minutes to delay between wake up retries.

    .PARAMETER MaximumNumberOfSendingWakeupPacketBeforePausing
        Specifies the maximum number of wake up packets transmitted by this site server before pausing.

    .PARAMETER SendingWakeupPacketBeforePausingWaitSec
        Specifies the number of seconds to wait between sending wake up packets to a target computer.

    .PARAMETER ThreadNumberOfSendingWakeupPacket
        Specifies the number of threads to use when sending wake up packets.

    .PARAMETER SendingWakeupPacketTransmissionOffsetMins
        Specifies when wake up packets should be sent prior to a scheduled activity.

    .PARAMETER ClientCertificateCustomStoreName
        Specifies the store name where the client certificate is located in the Computer store when
        you don't use the default store of Personal.

    .PARAMETER TakeActionForMultipleCertificateMatchCriteria
        Specifies the action to take if multiple certificates match criteria.

    .PARAMETER ClientCertificateSelectionCriteriaType
        Specifies the criteria type to match in a client certificate when more than one
        certificate is available.

    .PARAMETER ClientCertificateSelectionCriteriaValue
        Specifies a value for the ClientCertificateSelectionCriteriaType parameter.
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
        $SiteSystemCollectionBehavior,

        [Parameter()]
        [Boolean]
        $EnableWakeOnLan,

        [Parameter()]
        [ValidateSet('Unicast','SubnetDirectedBroadcasts')]
        [String]
        $WakeOnLanTransmissionMethodType,

        [Parameter()]
        [ValidateRange(1,5)]
        [UInt32]
        $RetryNumberOfSendingWakeupPacketTransmission,

        [Parameter()]
        [ValidateRange(1,5)]
        [UInt32]
        $SendingWakeupPacketTransmissionDelayMins,

        [Parameter()]
        [ValidateRange(1000,300000)]
        [UInt32]
        $MaximumNumberOfSendingWakeupPacketBeforePausing,

        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $SendingWakeupPacketBeforePausingWaitSec,

        [Parameter()]
        [ValidateRange(1,9)]
        [UInt32]
        $ThreadNumberOfSendingWakeupPacket,

        [Parameter()]
        [ValidateRange(0,60)]
        [UInt32]
        $SendingWakeupPacketTransmissionOffsetMins,

        [Parameter()]
        [String]
        $ClientCertificateCustomStoreName,

        [Parameter()]
        [ValidateSet('FailSelectionAndSendErrorMessage','SelectCertificateWithLongestValidityPeriod')]
        [String]
        $TakeActionForMultipleCertificateMatchCriteria,

        [Parameter()]
        [ValidateSet('ClientAuthentication','CertificateSubjectContainsString','CertificateSubjectOrSanIncludesAttributes')]
        [String]
        $ClientCertificateSelectionCriteriaType,

        [Parameter()]
        [String]
        $ClientCertificateSelectionCriteriaValue
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode

    try
    {
        $defaultValues = @(
            'SiteCode','Comment','ClientComputerCommunicationType','MaximumConcurrentSendingForAllSite',
            'MaximumConcurrentSendingForPerSite','RetryNumberForConcurrentSending',
            'ConcurrentSendingDelayBeforeRetryingMins','ThresholdOfSelectCollectionByDefault',
            'ThresholdOfSelectCollectionMax','SiteSystemCollectionBehavior'
        )

        if (($PSBoundParameters.ContainsKey('UseSmsGeneratedCert')) -and
            (-not [string]::IsNullOrEmpty($ClientComputerCommunicationType) -and $ClientComputerCommunicationType -eq 'HttpsOnly') -or
            ([string]::IsNullOrEmpty($ClientComputerCommunicationType) -and $state.ClientComputerCommunicationType -eq 'HttpsOnly'))
        {
            Write-Warning -Message $script:localizedData.IgnoreSMSCert
        }
        else
        {
            $defaultValues += @('UseSmsGeneratedCert')
        }

        if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionByDefault') -or $PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionMax'))
        {
            if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionByDefault'))
            {
                $collectionDefault = $ThresholdOfSelectCollectionByDefault
            }
            elseif ($state.ThresholdOfSelectCollectionByDefault)
            {
                $collectionDefault = $state.ThresholdOfSelectCollectionByDefault
            }

            if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionMax'))
            {
                $collectionMax = $ThresholdOfSelectCollectionMax
            }
            elseif ($state.ThresholdOfSelectCollectionMax)
            {
                $collectionMax = $state.ThresholdOfSelectCollectionMax
            }

            if (($collectionMax -ne 0) -and ($collectionMax -le $collectionDefault))
            {
                throw ($script:localizedData.CollectionError -f $collectionDefault, $collectionMax)
            }
        }

        if ($state.SiteType -eq 'Primary')
        {
            $defaultValues += @('ClientCheckCertificateRevocationListForSiteSystem','UsePkiClientCertificate',
            'RequireSigning','UseEncryption','EnableLowFreeSpaceAlert','EnableWakeOnLan','ClientCertificateCustomStoreName',
            'TakeActionForMultipleCertificateMatchCriteria','ClientCertificateSelectionCriteriaType')

            if ($PSBoundParameters.ContainsKey('EnableLowFreeSpaceAlert') -or $PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
                $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
            {
                if ($EnableLowFreeSpaceAlert -eq $true)
                {
                    if (-not $PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
                        -not $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
                    {
                        throw $script:localizedData.AlertMissing
                    }
                    else
                    {
                        if ($FreeSpaceThresholdCriticalGB -ge $FreeSpaceThresholdWarningGB)
                        {
                            throw $script:localizedData.AlertErrorMsg
                        }
                        else
                        {
                            $defaultValues += @('FreeSpaceThresholdWarningGB','FreeSpaceThresholdCriticalGB')
                        }
                    }
                }
                else
                {
                    if ($PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
                        $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
                    {
                        Write-Warning -Message $script:localizedData.IgnoreAlertsSettings
                    }
                }
            }

            $wolParams = @('WakeOnLanTransmissionMethodType','RetryNumberOfSendingWakeupPacketTransmission','SendingWakeupPacketTransmissionDelayMins',
            'MaximumNumberOfSendingWakeupPacketBeforePausing','SendingWakeupPacketBeforePausingWaitSec','ThreadNumberOfSendingWakeupPacket',
            'SendingWakeupPacketTransmissionOffsetMins')

            foreach ($param in $wolParams)
            {
                if (($EnableWakeOnLan -eq $false) -or ($State.EnableWakeOnLan -eq $false -and (-not $PSBoundParameters.ContainsKey('EnableWakeOnLan'))) -and
                    ($PSBoundParameters.ContainsKey($prarm)))
                {
                    Write-Warning -Message ($script:localizedData.WakeFalse -f $param)
                }
                else
                {
                    $defaultValues += $param
                }
            }

            if ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaType'))
            {
                if ($ClientCertificateSelectionCriteriaType -eq 'ClientAuthentication')
                {
                    if ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
                    {
                        Write-Warning -Message $script:localizedData.IgnoreCertValue
                    }
                }
                else
                {
                    if (-not $PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
                    {
                        throw ($script:localizedData.MissingCertValue -f $ClientCertificateSelectionCriteriaType)
                        $badInput = $true
                    }
                    else
                    {
                        $defaultValues += @('ClientCertificateSelectionCriteriaValue')
                    }
                }
            }
            elseif ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
            {
                throw $script:localizedData.MissingCertType
                $badInput = $true
            }
            if ($PSBoundParameters.ContainsKey('ClientCertificateCustomStoreName') -and [string]::IsNullOrEmpty($ClientCertificateCustomStoreName))
            {
                $PSBoundParameters.ClientCertificateCustomStoreName = 'Personal'
                Write-Warning -Message $script:localizedData.NullCertStore
            }
        }
        elseif ($state.SiteType -eq 'Cas')
        {
            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($defaultValues -notcontains $param.Key)
                {
                    Write-Warning -Message ($script:localizedData.IgnorePrimarySetting -f $param.Key)
                }
            }
        }

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -contains $param.Key)
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
            Set-CMSite -SiteCode $SiteCode @buildingParams
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

    .PARAMETER EnableWakeOnLan
        Indicates whether to send Wake On LAN packets for scheduled activities such as deployments
        of software updates.

    .PARAMETER WakeOnLanTransmissionMethodType
        Specifies the type of transmission method to use for Wake On LAN transmissions.

    .PARAMETER RetryNumberOfSendingWakeupPacketTransmission
        Specifies the number of times a wake up packet is sent to a target computer.

    .PARAMETER SendingWakeupPacketTransmissionDelayMins
        Specifies the number of minutes to delay between wake up retries.

    .PARAMETER MaximumNumberOfSendingWakeupPacketBeforePausing
        Specifies the maximum number of wake up packets transmitted by this site server before pausing.

    .PARAMETER SendingWakeupPacketBeforePausingWaitSec
        Specifies the number of seconds to wait between sending wake up packets to a target computer.

    .PARAMETER ThreadNumberOfSendingWakeupPacket
        Specifies the number of threads to use when sending wake up packets.

    .PARAMETER SendingWakeupPacketTransmissionOffsetMins
        Specifies when wake up packets should be sent prior to a scheduled activity.

    .PARAMETER ClientCertificateCustomStoreName
        Specifies the store name where the client certificate is located in the Computer store when
        you don't use the default store of Personal.

    .PARAMETER TakeActionForMultipleCertificateMatchCriteria
        Specifies the action to take if multiple certificates match criteria.

    .PARAMETER ClientCertificateSelectionCriteriaType
        Specifies the criteria type to match in a client certificate when more than one
        certificate is available.

    .PARAMETER ClientCertificateSelectionCriteriaValue
        Specifies a value for the ClientCertificateSelectionCriteriaType parameter.
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
        $SiteSystemCollectionBehavior,

        [Parameter()]
        [Boolean]
        $EnableWakeOnLan,

        [Parameter()]
        [ValidateSet('Unicast','SubnetDirectedBroadcasts')]
        [String]
        $WakeOnLanTransmissionMethodType,

        [Parameter()]
        [ValidateRange(1,5)]
        [UInt32]
        $RetryNumberOfSendingWakeupPacketTransmission,

        [Parameter()]
        [ValidateRange(1,5)]
        [UInt32]
        $SendingWakeupPacketTransmissionDelayMins,

        [Parameter()]
        [ValidateRange(1000,300000)]
        [UInt32]
        $MaximumNumberOfSendingWakeupPacketBeforePausing,

        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $SendingWakeupPacketBeforePausingWaitSec,

        [Parameter()]
        [ValidateRange(1,9)]
        [UInt32]
        $ThreadNumberOfSendingWakeupPacket,

        [Parameter()]
        [ValidateRange(0,60)]
        [UInt32]
        $SendingWakeupPacketTransmissionOffsetMins,

        [Parameter()]
        [String]
        $ClientCertificateCustomStoreName,

        [Parameter()]
        [ValidateSet('FailSelectionAndSendErrorMessage','SelectCertificateWithLongestValidityPeriod')]
        [String]
        $TakeActionForMultipleCertificateMatchCriteria,

        [Parameter()]
        [ValidateSet('ClientAuthentication','CertificateSubjectContainsString','CertificateSubjectOrSanIncludesAttributes')]
        [String]
        $ClientCertificateSelectionCriteriaType,

        [Parameter()]
        [String]
        $ClientCertificateSelectionCriteriaValue
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true
    $badInput = $false

    $defaultValues = @(
        'SiteCode','Comment','ClientComputerCommunicationType','MaximumConcurrentSendingForAllSite',
        'MaximumConcurrentSendingForPerSite','RetryNumberForConcurrentSending',
        'ConcurrentSendingDelayBeforeRetryingMins','ThresholdOfSelectCollectionByDefault',
        'ThresholdOfSelectCollectionMax','SiteSystemCollectionBehavior'
    )

    if (($PSBoundParameters.ContainsKey('UseSmsGeneratedCert')) -and
        (-not [string]::IsNullOrEmpty($ClientComputerCommunicationType) -and $ClientComputerCommunicationType -eq 'HttpsOnly') -or
        ([string]::IsNullOrEmpty($ClientComputerCommunicationType) -and $state.ClientComputerCommunicationType -eq 'HttpsOnly'))
    {
        Write-Warning -Message $script:localizedData.IgnoreSMSCert
    }
    else
    {
        $defaultValues += @('UseSmsGeneratedCert')
    }

    if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionByDefault') -or $PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionMax'))
    {
        if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionByDefault'))
        {
            $collectionDefault = $ThresholdOfSelectCollectionByDefault
        }
        elseif ($state.ThresholdOfSelectCollectionByDefault)
        {
            $collectionDefault = $state.ThresholdOfSelectCollectionByDefault
        }

        if ($PSBoundParameters.ContainsKey('ThresholdOfSelectCollectionMax'))
        {
            $collectionMax = $ThresholdOfSelectCollectionMax
        }
        elseif ($state.ThresholdOfSelectCollectionMax)
        {
            $collectionMax = $state.ThresholdOfSelectCollectionMax
        }

        if (($collectionMax -ne 0) -and ($collectionMax -le $collectionDefault))
        {
            Write-Warning -Message ($script:localizedData.CollectionError -f $collectionDefault, $collectionMax)
        }
    }

    if ($state.SiteType -eq 'Primary')
    {
        $defaultValues += @('ClientCheckCertificateRevocationListForSiteSystem','UsePkiClientCertificate',
            'RequireSigning','UseEncryption','EnableLowFreeSpaceAlert','EnableWakeOnLan','ClientCertificateCustomStoreName',
            'TakeActionForMultipleCertificateMatchCriteria','ClientCertificateSelectionCriteriaType')

        if ($PSBoundParameters.ContainsKey('EnableLowFreeSpaceAlert') -or $PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
            $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
        {
            if ($EnableLowFreeSpaceAlert -eq $true)
            {
                if (-not $PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
                    -not $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
                {
                    Write-Warning -Message $script:localizedData.AlertErrorMsg
                    $badInput = $true
                }
                else
                {
                    if ($FreeSpaceThresholdCriticalGB -ge $FreeSpaceThresholdWarningGB)
                    {
                        Write-Warning -Message $script:localizedData.AlertErrorMsg
                        $badInput = $true
                    }
                    else
                    {
                        $defaultValues += @('FreeSpaceThresholdWarningGB','FreeSpaceThresholdCriticalGB')
                    }
                }
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('FreeSpaceThresholdWarningGB') -or
                    $PSBoundParameters.ContainsKey('FreeSpaceThresholdCriticalGB'))
                {
                    Write-Warning -Message $script:localizedData.IgnoreAlertsSettings
                }
            }
        }

        $wolParams = @('WakeOnLanTransmissionMethodType','RetryNumberOfSendingWakeupPacketTransmission','SendingWakeupPacketTransmissionDelayMins',
        'MaximumNumberOfSendingWakeupPacketBeforePausing','SendingWakeupPacketBeforePausingWaitSec','ThreadNumberOfSendingWakeupPacket',
        'SendingWakeupPacketTransmissionOffsetMins')

        foreach ($param in $wolParams)
        {
            if (($EnableWakeOnLan -eq $false) -or ($State.EnableWakeOnLan -eq $false -and (-not $PSBoundParameters.ContainsKey('EnableWakeOnLan'))) -and
                ($PSBoundParameters.ContainsKey($prarm)))
            {
                Write-Warning -Message ($script:localizedData.WakeFalse -f $param)
            }
            else
            {
                $defaultValues += $param
            }
        }

        if ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaType'))
        {
            if ($ClientCertificateSelectionCriteriaType -eq 'ClientAuthentication')
            {
                if ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
                {
                    Write-Warning -Message $script:localizedData.IgnoreCertValue
                }
            }
            else
            {
                if (-not $PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
                {
                    Write-Warning -Message ($script:localizedData.MissingCertValue -f $ClientCertificateSelectionCriteriaType)
                    $badInput = $true
                }
                else
                {
                    $defaultValues += @('ClientCertificateSelectionCriteriaValue')
                }
            }
        }
        elseif ($PSBoundParameters.ContainsKey('ClientCertificateSelectionCriteriaValue'))
        {
            Write-Warning -Message $script:localizedData.MissingCertType
            $badInput = $true
        }
        if ($PSBoundParameters.ContainsKey('ClientCertificateCustomStoreName') -and [string]::IsNullOrEmpty($ClientCertificateCustomStoreName))
        {
            $PSBoundParameters.ClientCertificateCustomStoreName = 'Personal'
            Write-Warning -Message $script:localizedData.NullCertStore
        }
    }
    elseif ($state.SiteType -eq 'Cas')
    {
        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -notcontains $param.Key)
            {
                Write-Warning -Message ($script:localizedData.IgnorePrimarySetting -f $param.Key)
            }
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
