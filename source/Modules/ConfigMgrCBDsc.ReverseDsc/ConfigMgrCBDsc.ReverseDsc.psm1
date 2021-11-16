$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will populate the required values needed and will Invoke-DscResource.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER ModuleName
        Specifies the module that will be used for Invoke-DscResource.

    .PARAMETER StringValue
        Specifies a string, if required, for Invoke-DscResouce.

    .PARAMETER CollectionName
        Specifies the collection name, if required, for Invoke-DscResource.

    .PARAMETER Resource
        Specifies the properties for the individual resource for module.
#>
function Assert-CMModule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [String]
        $SiteCode,

        [Parameter()]
        [String]
        $ModuleName = 'ConfigMgrCBDsc',

        [Parameter()]
        [String]
        $StringValue,

        [Parameter()]
        [String]
        $CollectionName,

        [Parameter()]
        [System.Object]
        $Resource
    )

    $required = $Resource.Properties
    $properties = @{}

    foreach ($prop in $required)
    {
        if ($prop.IsMandatory -eq $true)
        {
            if ($prop.Name -eq 'SiteCode')
            {
                $properties.Add($prop.Name,$SiteCode)
            }
            elseif ($prop.Name -eq 'CollectionName')
            {
                $properties.Add($prop.Name,$CollectionName)
            }
            elseif ($prop.Name -eq 'Type')
            {
                $properties.Add($prop.Name,'Device')
            }
            elseif ($prop.PropertyType -eq '[string]')
            {
                $properties.Add($prop.Name,$StringValue)
            }
            elseif ($prop.PropertyType -eq '[Bool]')
            {
                $properties.Add($prop.Name,$true)
            }
            else
            {
                $properties.Add($prop.Name,1)
            }
        }
    }

    $result = Invoke-DscResource -ModuleName $ModuleName -Name $Resource.Name -Method Get -Property $properties

    $blanketExclude = @('ConfigurationName','DependsOn','ModuleName','ModuleVersion','PsDscRunAsCredential','ResourceId','SourceInfo')
    $return = @{}
    foreach ($item in $required)
    {
        if (($blanketExclude -notcontains $item.Name) -and ($item.Name -notmatch 'ToExclude') -and ($item.Name -notMatch 'ToInclude'))
        {
            $return.Add($item.Name,$result.$($item.Name))
        }
    }

    return $return
}

<#
    .SYNOPSIS
        This will populate the required values needed and will Invoke-DscResource.

    .PARAMETER ResourceName
        Specifies the individual resource name to evulate.

    .PARAMETER ExcludeList
        Specifies which items to exclude from Invoke-DscResource results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Indent
        Specifies the indent spacing for the output.

    .PARAMETER StringValue
        Specifies the value for required string for Invoke-DscResource.

    .PARAMETER CollectionName
        Specifies the value for required collection name for Invoke-DscResource.

    .PARAMETER Count
        Specifies the spacing count for the output.

    .PARAMETER MultiEntry
        Specifies the if return will have multiple entries, for indenting purposes.

    .PARAMETER Resources
        Specifies the Get-DscResource -Module 'ConfigMgrCBDsc' return.
#>
function Set-OutFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceName,

        [Parameter()]
        [String[]]
        $ExcludeList,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1,4)]
        [Int32]
        $Indent,

        [Parameter()]
        [String]
        $StringValue,

        [Parameter()]
        [String]
        $CollectionName,

        [Parameter()]
        [Int32]
        $Count,

        [Parameter()]
        [Boolean]
        $MultiEntry,

        [Parameter()]
        [System.Object[]]
        $Resources
    )

    $resource = $Resources | Where-Object -FilterScript {$_.Name -eq $ResourceName}

    if ($PSBoundParameters.ContainsKey('ExcludeList'))
    {
        $excluded = $ExcludeList
    }
    else
    {
        $excluded = @('SiteCode')
    }

    if ($StringValue)
    {
        if ($CollectionName)
        {
            $cPush = Assert-CMModule -SiteCode $SiteCode -Resource $resource -StringValue $StringValue -CollectionName $CollectionName
        }
        else
        {
            $cPush = Assert-CMModule -SiteCode $SiteCode -Resource $resource -StringValue $StringValue
        }
    }
    else
    {
        $cPush = Assert-CMModule -SiteCode $SiteCode -Resource $resource
    }

    if ($MultiEntry -eq $true)
    {
        $wPush += "`t@{`r`n"
    }

    if ($count)
    {
        $updatedCount = $Count
    }
    else
    {
        $updatedCount = ($cPush.Keys | Measure-Object -Maximum -Property Length).Maximum
    }

    # ScheduleInterval = None to remove ScheduleCount from the array
    if (($cPush.ScheduleInterval) -and ($cPush.ScheduleInterval -eq 'None'))
    {
        [array]$excluded += 'ScheduleCount'
    }

    if ($ResourceName -eq 'CMCollections' -or $ResourceName -eq 'CMAssetIntelligencePoint' -or
        $ResourceName -eq 'CMMaintenanceWindows' -or $ResourceName -eq 'CMGroupDiscovery' -or
        $ResourceName -eq 'CMSoftwareUpdatePointComponent' -or
        $ResourceName -eq 'CMClientSettingsCompliance' -or $ResourceName -eq 'CMClientSettingsHardware' -or
        $ResourceName -eq 'CMClientSettingsSoftwareDeployment' -or
        $ResourceName -eq 'CMClientSettingsSoftwareInventory' -or
        $ResourceName -eq 'CMClientSettingsSoftwareMetering')
    {
        if ($cPush.ScheduleType -eq 'None')
        {
            [array]$excluded += @('RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth')
        }
        elseif ($cPush.ScheduleType -eq 'MonthlyByWeek')
        {
            [array]$excluded += @('DayOfMonth')
        }
        elseif ($cPush.ScheduleType -eq 'MonthlyByDay')
        {
            [array]$excluded += @('MonthlyWeekOrder','DayOfWeek')
        }
        elseif ($cPush.ScheduleType -eq 'Weekly')
        {
            [array]$excluded += @('MonthlyWeekOrder','DayOfMonth')
        }
        else
        {
            [array]$excluded += @('MonthlyWeekOrder','DayOfWeek','DayOfMonth')
        }
    }

    # Maintence Tasks Updated Logic
    if ($ResourceName -eq 'CMSiteMaintenance')
    {
        if ($cPush.Enabled -eq $false)
        {
            [array]$excluded += 'DaysOfWeek','DeleteOlderThanDays','BeginTime','LatestBeginTime','DeleteOlderThanDays','RunInterval','BackupLocation'
        }
        elseif ($cPush.TaskName -eq 'Update Application Catalog Tables')
        {
            [array]$excluded += 'DaysOfWeek','DeleteOlderThanDays','BeginTime','LatestBeginTime','DeleteOlderThanDays','BackupLocation'
        }
        elseif ($cPush.TaskName -eq 'Backup SMS Site Server')
        {
            [array]$excluded += 'RunInterval','DeleteOlderThanDays'
        }
        elseif ($cPush.DeleteOlderThanDays -ne 0)
        {
            [array]$excluded += 'RunInterval','BackupLocation'
        }
        elseif ($cPush.BackupLocation -eq '')
        {
            [array]$excluded += 'DeleteOlderThanDays','RunInterval','BackupLocation'
        }
    }

    if ($ResourceName -eq 'CMPullDistributionPoint')
    {
        [array]$excluded += 'SourceDistributionPoint'
    }

    $params = @{
        Count       = $updatedCount
        ExcludeList = $excluded
        InputObject = $cPush
        Indent      = $Indent
    }

    $tester = Set-CMThing @params

    if ($ResourceName -eq 'CMPullDistributionPoint')
    {
        $sourceDP = 'SourceDistributionPoint'

        $tester += "`t`t$($sourceDP.PadRight($updatedCount)) = @(`r`n"
        foreach ($item in $cPush.SourceDistributionPoint)
        {
            $tester += "`t`t`t@{`r`n"
            $tester += "`t`t`t`tDPRank   = $($item.DPRank)`r`n"
            $tester += "`t`t`t`tSourceDP = '$($item.SourceDP)'`r`n"
            $tester += "`t`t`t}`r`n"
        }
        $tester += "`t`t)`r`n"
    }

    if (($ResourceName -eq 'CMCollections') -and ($cPush.QueryRules))
    {
        $col = 'QueryRules'

        $tester += "`t`t$($col.PadRight($updatedCount)) = @(`r`n"
        foreach ($item in $cPush.QueryRules)
        {
            $tester += "`t`t`t@{`r`n"
            $tester += "`t`t`t`tRuleName        = '$($item.RuleName)'`r`n"
            $tester += "`t`t`t`tQueryExpression = '$($item.QueryExpression)'`r`n"
            $tester += "`t`t`t}`r`n"
        }
        $tester += "`t`t)`r`n"
    }

    if (($ResourceName -eq 'CMGroupDiscovery') -and ($cPush.GroupDiscoveryScope))
    {
        $col = 'GroupDiscoveryScope'

        $tester += "`t`t$($col.PadRight($updatedCount)) = @(`r`n"
        foreach ($item in $cPush.GroupDiscoveryScope)
        {
            $tester += "`t`t`t@{`r`n"
            $tester += "`t`t`t`tName         = '$($item.Name)'`r`n"
            $tester += "`t`t`t`tLdapLocation = '$($item.LdapLocation)'`r`n"
            $tester += "`t`t`t`tRecurse      = `$$($item.Recurse)`r`n"
            $tester += "`t`t`t}`r`n"
        }
        $tester += "`t`t)`r`n"
    }

    if ($MultiEntry -eq $false)
    {
        $wPush += "$tester}"
    }
    else
    {
        $wPush += "$tester`t}`r`n"
    }

    return $wPush
}

<#
    .SYNOPSIS
        This will populate the required values needed and will Invoke-DscResource.

    .PARAMETER ExcludeList
        Specifies which items to exclude from Invoke-DscResource results.

    .PARAMETER InputObject
        Specifies the Get-DscResource return object.

    .PARAMETER Count
        Specifies the spacing count for the output.

    .PARAMETER Indent
        Specifies the indent spacing for the output.
#>
function Set-CMThing
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String[]]
        $ExcludeList,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [Int32]
        $Count,

        [Parameter(Mandatory = $true)]
        [Int32]
        $Indent
    )

    foreach ($item in $InputObject.GetEnumerator())
    {
        if ($ExcludeList -notcontains $item.Key)
        {
            $thing = $null
            $subThing = $null
            if ($null -ne $item.Value)
            {
                if ($item.Value.GetType().Name -eq 'Boolean')
                {
                    $thing = "$($item.Key.PadRight($Count)) = `$$($item.Value)"
                }
                elseif (($item.Value.GetTYpe().Name -eq 'String') -or ($item.Value.GetTYpe().Name -eq 'DateTime'))
                {
                    $thing = "$($item.Key.PadRight($Count)) = '$($item.Value)'"
                }
                elseif (($item.Value.GetType().Name -eq 'Object[]') -or ($item.Value.GetType().Name -eq 'String[]'))
                {
                    if ($item.Value)
                    {
                        foreach ($subItem in $item.Value)
                        {
                            $subThing += "'$subItem',"
                        }
                        $thing ="$($item.Key.PadRight($Count)) = $($subThing.TrimEnd(','))"
                    }
                }
                else
                {
                    $thing = "$($item.Key.PadRight($Count)) = $($item.Value)"
                }
            }
            if ($thing)
            {
                if ($Indent -eq 1)
                {
                    $output += "`t$($thing)`r`n"
                }
                elseif ($Indent -eq 2)
                {
                    $output += "`t`t$($thing)`r`n"
                }
            }
        }
    }

    return $output
}

<#
    .SYNOPSIS
        This will create the configuration file.

    .PARAMETER ConfigOutputPath
        Specifies where the configuration file will be saved.

    .PARAMETER DataFile
        Specifies where the data file will be saved.

    .PARAMETER MofOutPutPath
        Specifies where the mof file will be saved when running the configuration.
#>
function New-Configuration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ConfigOutputPath,

        [Parameter(Mandatory = $true)]
        [String]
        $DataFile,

        [Parameter(Mandatory = $true)]
        [String]
        $MofOutPutPath
    )

    if (Test-Path -Path $ConfigOutputPath)
    {
        Remove-Item -Path $ConfigOutputPath
    }

    Add-Content -Path $ConfigOutputPath -Value "
Configuration ConfigureSccm
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        `$SiteCode,

        [Parameter()]
        [System.String]
        `$Datafile,

        [Parameter()]
        [HashTable[]]
        `$CMAccounts,

        [Parameter()]
        [HashTable[]]
        `$CMAdministrativeUser,

        [Parameter()]
        [HashTable[]]
        `$CMBoundaryGroups,

        [Parameter()]
        [HashTable]
        `$CMClientPushSettings,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettings,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsBits,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsClientCache,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsClientPolicy,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsCloudService,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsCompliance,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsComputerAgent,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsDelivery,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsHardware,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsMetered,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsPower,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsRemoteTools,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsSoftwareCenter,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsSoftwareDeployment,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsSoftwareInventory,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsSoftwareMetering,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsSoftwareUpdate,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsStateMessaging,

        [Parameter()]
        [HashTable[]]
        `$CMClientSettingsUserDeviceAffinity,

        [Parameter()]
        [HashTable]
        `$CMClientStatusSettings,

        [Parameter()]
        [HashTable]
        `$CMCollectionMembershipEvaluationComponent,

        [Parameter()]
        [HashTable[]]
        `$CMDistributionGroup,

        [Parameter()]
        [HashTable[]]
        `$CMDistributionPoint,

        [Parameter()]
        [HashTable[]]
        `$CMDistributionPointGroupMembers,

        [Parameter()]
        [HashTable[]]
        `$CMEmailNotificationComponent,

        [Parameter()]
        [HashTable[]]
        `$CMFallbackStatusPoint,

        [Parameter()]
        [HashTable]
        `$CMForestDiscovery,

        [Parameter()]
        [HashTable]
        `$CMGroupDiscovery,

        [Parameter()]
        [HashTable]
        `$CMHeartbeatDiscovery,

        [Parameter()]
        [HashTable[]]
        `$CMMaintenanceWindows,

        [Parameter()]
        [HashTable[]]
        `$CMManagementPoint,

        [Parameter()]
        [HashTable]
        `$CMNetworkDiscovery,

        [Parameter()]
        [HashTable[]]
        `$CMPullDistributionPoint,

        [Parameter()]
        [HashTable[]]
        `$CMPxeDistributionPoint,

        [Parameter()]
        [HashTable[]]
        `$CMSecurityScopes,

        [Parameter()]
        [HashTable]
        `$CMServiceConnectionPoint,

        [Parameter()]
        [HashTable[]]
        `$CMSiteMaintenance,

        [Parameter()]
        [HashTable[]]
        `$CMSiteSystemServer,

        [Parameter()]
        [HashTable]
        `$CMSoftwareDistributionComponent,

        [Parameter()]
        [HashTable[]]
        `$CMSoftwareUpdatePoint,

        [Parameter()]
        [HashTable[]]
        `$CMSoftwareUpdatePointComponent,

        [Parameter()]
        [HashTable]
        `$CMStatusReportingComponent,

        [Parameter()]
        [HashTable]
        `$CMSystemDiscovery,

        [Parameter()]
        [HashTable]
        `$CMUserDiscovery
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        if (`$DataFile)
        {
            `$data = Import-PowerShellDataFile -Path `$DataFile

            foreach (`$item in `$data.GetEnumerator())
            {
                if ([string]::IsNullOrEmpty((Get-Variable -Name `$item.Name -ErrorAction SilentlyContinue).Value))
                {
                    Set-Variable -Name `$item.Name -Value `$item.Value
                }
            }
        }

        if (`$CMAccounts)
        {
            foreach (`$account in `$CMAccounts)
            {
                `$password = Get-Credential -UserName `$account.Account -Message `"Password for `$(`$account.Account)`"

                CMAccounts `"AddingAccount-`$(`$account.Account)`"
                {
                    SiteCode        = `$SiteCode
                    Account         = `$account.Account
                    AccountPassword = `$password
                    Ensure          = `$account.Ensure
                }

                [array]`$cmAccountsDependsOn += `"[CMAccounts]AddingAccount-`$(`$account.Account)`"
            }
        }

        if (`$CMAssetIntelligencePoint)
        {
            if (`$CMAssetIntelligencePoint.Enabled -eq `$false)
            {
                CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                {
                    SiteCode         = `$SiteCode
                    SiteServerName   = `$CMAssetIntelligencePoint.SiteServerName
                    IsSingleInstance = `$CMAssetIntelligencePoint.IsSingleInstance
                    Enable           = `$CMAssetIntelligencePoint.Enable
                    Ensure           = `$CMAssetIntelligencePoint.Ensure
                }
            }
            elseif (`$CMAssetIntelligencePoint.EnableSynchronization -eq `$false)
            {
                CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                {
                    SiteCode              = `$SiteCode
                    SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                    IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                    CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                    Enable                = `$CMAssetIntelligencePoint.Enable
                    EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                    Ensure                = `$CMAssetIntelligencePoint.Ensure
                }
            }
            else
            {
                if (`$CMAssetIntelligencePoint.ScheduleType -eq 'MonthlyByDay')
                {
                    CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                    {
                        SiteCode              = `$SiteCode
                        SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                        IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                        CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                        Enable                = `$CMAssetIntelligencePoint.Enable
                        EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                        Ensure                = `$CMAssetIntelligencePoint.Ensure
                        ScheduleType          = `$CMAssetIntelligencePoint.ScheduleType
                        RecurInterval         = `$CMAssetIntelligencePoint.RecurInterval
                        DayOfMonth            = `$CMAssetIntelligencePoint.DayOfMonth
                    }
                }
                elseif (`$CMAssetIntelligencePoint.ScheduleType -eq 'MonthlyByWeek')
                {
                    CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                    {
                        SiteCode              = `$SiteCode
                        SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                        IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                        CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                        Enable                = `$CMAssetIntelligencePoint.Enable
                        EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                        Ensure                = `$CMAssetIntelligencePoint.Ensure
                        ScheduleType          = `$CMAssetIntelligencePoint.ScheduleType
                        RecurInterval         = `$CMAssetIntelligencePoint.RecurInterval
                        MonthlyWeekOrder      = `$CMAssetIntelligencePoint.MonthlyWeekOrder
                        DayOfWeek             = `$CMAssetIntelligencePoint.DayOfWeek
                    }
                }
                elseif (`$CMAssetIntelligencePoint.ScheduleType -eq 'Weekly')
                {
                    CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                    {
                        SiteCode              = `$SiteCode
                        SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                        IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                        CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                        Enable                = `$CMAssetIntelligencePoint.Enable
                        EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                        Ensure                = `$CMAssetIntelligencePoint.Ensure
                        ScheduleType          = `$CMAssetIntelligencePoint.ScheduleType
                        RecurInterval         = `$CMAssetIntelligencePoint.RecurInterval
                        DayOfWeek             = `$CMAssetIntelligencePoint.DayOfWeek
                    }
                }
                elseif (`$CMAssetIntelligencePoint.ScheduleType -eq 'None')
                {
                    CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                    {
                        SiteCode              = `$SiteCode
                        SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                        IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                        CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                        Enable                = `$CMAssetIntelligencePoint.Enable
                        EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                        Ensure                = `$CMAssetIntelligencePoint.Ensure
                        ScheduleType          = `$CMAssetIntelligencePoint.ScheduleType
                    }
                }
                else
                {
                    CMAssetIntelligencePoint `$(`$CMAssetIntelligencePoint.SiteServerName)
                    {
                        SiteCode              = `$SiteCode
                        SiteServerName        = `$CMAssetIntelligencePoint.SiteServerName
                        IsSingleInstance      = `$CMAssetIntelligencePoint.IsSingleInstance
                        CertificateFile       = `$CMAssetIntelligencePoint.CertificateFile
                        Enable                = `$CMAssetIntelligencePoint.Enable
                        EnableSynchronization = `$CMAssetIntelligencePoint.EnableSynchronization
                        Ensure                = `$CMAssetIntelligencePoint.Ensure
                        ScheduleType          = `$CMAssetIntelligencePoint.ScheduleType
                        RecurInterval         = `$CMAssetIntelligencePoint.RecurInterval
                    }
                }
            }
        }

        if (`$CMReportingServicePoint)
        {
            CMReportingServicePoint CMReportingServicePoint
            {
                SiteCode             = `$SiteCode
                SiteServerName       = `$CMReportingServicePoint.SiteServerName
                Username             = `$CMReportingServicePoint.Username
                DatabaseName         = `$CMReportingServicePoint.DatabaseName
                DatabaseServerName   = `$CMReportingServicePoint.DatabaseServerName
                ReportServerInstance = `$CMReportingServicePoint.ReportServerInstance
                Ensure               = `$CMReportingServicePoint.Ensure
                DependsOn            = `$cmAccountsDependsOn
            }
        }

        if (`$CMEmailNotificationComponent)
        {
            if (`$CMEmailNotificationComponent.Enabled -eq `$false)
            {
                CMEmailNotificationComponent EmailNotificationComponent
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMEmailNotificationComponent.Enabled
                }
            }
            elseif (`$CMEmailNotificationComponent.TypeOfAuthentication -eq 'Other')
            {
                CMEmailNotificationComponent EmailNotificationComponent
                {
                    SiteCode             = `$SiteCode
                    Enabled              = `$CMEmailNotificationComponent.Enabled
                    TypeOfAuthentication = `$CMEmailNotificationComponent.TypeOfAuthentication
                    Port                 = `$CMEmailNotificationComponent.Port
                    SmtpServerFqdn       = `$CMEmailNotificationComponent.SmtpServerFqdn
                    SendFrom             = `$CMEmailNotificationComponent.SendFrom
                    UserName             = `$CMEmailNotificationComponent.UserName
                    UseSsl               = `$CMEmailNotificationComponent.UseSsl
                }
            }
            else
            {
                CMEmailNotificationComponent EmailNotificationComponent
                {
                    SiteCode             = `$SiteCode
                    Enabled              = `$CMEmailNotificationComponent.Enabled
                    TypeOfAuthentication = `$CMEmailNotificationComponent.TypeOfAuthentication
                    Port                 = `$CMEmailNotificationComponent.Port
                    SmtpServerFqdn       = `$CMEmailNotificationComponent.SmtpServerFqdn
                    SendFrom             = `$CMEmailNotificationComponent.SendFrom
                    UseSsl               = `$CMEmailNotificationComponent.UseSsl
                }
            }
        }

        if (`$CMSystemDiscovery)
        {
            if (`$CMSystemDiscovery.Enabled -eq `$true)
            {
                if (`$CMSystemDiscovery.ScheduleInterval -eq 'None')
                {
                    CMSystemDiscovery CreateSystemDiscovery
                    {
                        SiteCode                        = `$SiteCode
                        Enabled                         = `$CMSystemDiscovery.Enabled
                        ScheduleInterval                = `$CMSystemDiscovery.ScheduleInterval
                        EnableDeltaDiscovery            = `$CMSystemDiscovery.EnableDeltaDiscovery
                        DeltaDiscoveryMins              = `$CMSystemDiscovery.DeltaDiscoveryMins
                        EnableFilteringExpiredLogon     = `$CMSystemDiscovery.EnableFilteringExpiredLogon
                        TimeSinceLastLogonDays          = `$CMSystemDiscovery.TimeSinceLastLogonDays
                        EnableFilteringExpiredPassword  = `$CMSystemDiscovery.EnableFilteringExpiredPassword
                        TimeSinceLastPasswordUpdateDays = `$CMSystemDiscovery.TimeSinceLastPasswordUpdateDays
                        ADContainers                    = `$CMSystemDiscovery.ADContainers
                    }
                }
                else
                {
                    CMSystemDiscovery CreateSystemDiscovery
                    {
                        SiteCode                        = `$SiteCode
                        Enabled                         = `$CMSystemDiscovery.Enabled
                        ScheduleInterval                = `$CMSystemDiscovery.ScheduleInterval
                        ScheduleCount                   = `$CMSystemDiscovery.ScheduleCount
                        EnableDeltaDiscovery            = `$CMSystemDiscovery.EnableDeltaDiscovery
                        DeltaDiscoveryMins              = `$CMSystemDiscovery.DeltaDiscoveryMins
                        EnableFilteringExpiredLogon     = `$CMSystemDiscovery.EnableFilteringExpiredLogon
                        TimeSinceLastLogonDays          = `$CMSystemDiscovery.TimeSinceLastLogonDays
                        EnableFilteringExpiredPassword  = `$CMSystemDiscovery.EnableFilteringExpiredPassword
                        TimeSinceLastPasswordUpdateDays = `$CMSystemDiscovery.TimeSinceLastPasswordUpdateDays
                        ADContainers                    = `$CMSystemDiscovery.ADContainers
                    }
                }
            }
            else
            {
                CMSystemDiscovery CreateSystemDiscovery
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMSystemDiscovery.Enabled
                }
            }
        }

        if (`$CMNetworkDiscovery)
        {
            CMNetworkDiscovery NetworkDiscovery
            {
                SiteCode = `$SiteCode
                Enabled  = `$CMNetworkDiscovery.Enabled
            }
        }

        if (`$CMHeartbeatDiscovery)
        {
            if (`$CMHeartbeatDiscovery.Enabled -eq `$true)
            {
                if (`$CMHeartbeatDiscovery.ScheduleInterval -eq 'None')
                {
                    CMHeartbeatDiscovery HeartbeatDiscovery
                    {
                        SiteCode         = `$SiteCode
                        Enabled          = `$CMHeartbeatDiscovery.Enabled
                        ScheduleInterval = `$CMHeartbeatDiscovery.ScheduleInterval
                    }
                }
                else
                {
                    CMHeartbeatDiscovery HeartbeatDiscovery
                    {
                        SiteCode         = `$SiteCode
                        Enabled          = `$CMHeartbeatDiscovery.Enabled
                        ScheduleInterval = `$CMHeartbeatDiscovery.ScheduleInterval
                        ScheduleCount    = `$CMHeartbeatDiscovery.ScheduleCount
                    }
                }
            }
            else
            {
                CMHeartbeatDiscovery HeartbeatDiscovery
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMHeartbeatDiscovery.Enabled
                }
            }
        }

        if (`$CMForestDiscovery)
        {
            if (`$CMForestDiscovery.Enabled -eq `$true)
            {
                CMForestDiscovery ForestDiscovery
                {
                    SiteCode                                  = `$SiteCode
                    Enabled                                   = `$CMForestDiscovery.Enabled
                    EnableSubnetBoundaryCreation              = `$CMForestDiscovery.EnableSubnetBoundaryCreation
                    EnableActiveDirectorySiteBoundaryCreation = `$CMForestDiscovery.EnableActiveDirectorySiteBoundaryCreation
                }
            }
            else
            {
                CMForestDiscovery ForestDiscovery
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMForestDiscovery.Enabled
                }
            }
        }

        if (`$CMGroupDiscovery)
        {
            if (`$CMGroupDiscovery.Enabled -eq `$false)
            {
                CMGroupDiscovery GroupDiscoverySettings
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMGroupDiscovery.Enabled
                }
            }
            else
            {
                if (`$CMGroupDiscovery.GroupDiscoveryScope)
                {
                    `$groupScopes = @()
                    foreach (`$item in `$CMGroupDiscovery.GroupDiscoveryScope)
                    {
                        `$groupScopes += DSC_CMGroupDiscoveryScope
                        {
                            Name         = `$item.Name
                            LdapLocation = `$item.LdapLocation
                            Recurse      = `$item.Recurse
                        }
                    }
                }

                if (`$CMGroupDiscovery.DeltaDiscovery -eq `$false)
                {
                    if (`$CMGroupDiscovery.EnableFilteringExpiredLogon -eq `$true -and
                        `$CMGroupDiscovery.EnableFilteringExpiredPassword -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                    elseif (`$CMGroupDiscovery.EnableFilteringExpiredLogon -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                    elseif (`$CMGroupDiscovery.EnableFilteringExpiredPassword -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                }
                else
                {
                    if (`$CMGroupDiscovery.EnableFilteringExpiredLogon -eq `$true -and
                        `$CMGroupDiscovery.EnableFilteringExpiredPassword -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                    elseif (`$CMGroupDiscovery.EnableFilteringExpiredLogon -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                TimeSinceLastLogonDays              = `$CMGroupDiscovery.TimeSinceLastLogonDays
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                    elseif (`$CMGroupDiscovery.EnableFilteringExpiredPassword -eq `$true)
                    {
                        if (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfMonth                          = `$CMGroupDiscovery.DayOfMonth
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                MonthlyWeekOrder                    = `$CMGroupDiscovery.MonthlyWeekOrder
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'Weekly')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                                DayOfWeek                           = `$CMGroupDiscovery.DayOfWeek
                            }
                        }
                        elseif (`$CMGroupDiscovery.ScheduleType -eq 'None')
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                            }
                        }
                        else
                        {
                            CMGroupDiscovery GroupDiscoverySettings
                            {
                                SiteCode                            = `$SiteCode
                                Enabled                             = `$CMGroupDiscovery.Enabled
                                EnableDeltaDiscovery                = `$CMGroupDiscovery.EnableDeltaDiscovery
                                DeltaDiscoveryMins                  = `$CMGroupDiscovery.DeltaDiscoveryMins
                                EnableFilteringExpiredLogon         = `$CMGroupDiscovery.EnableFilteringExpiredLogon
                                EnableFilteringExpiredPassword      = `$CMGroupDiscovery.EnableFilteringExpiredPassword
                                TimeSinceLastPasswordUpdateDays     = `$CMGroupDiscovery.TimeSinceLastPasswordUpdateDays
                                GroupDiscoveryScope                 = `$groupScopes
                                DiscoverDistributionGroupMembership = `$CMGroupDiscovery.DiscoverDistributionGroupMembership
                                Start                               = `$CMGroupDiscovery.Start
                                ScheduleType                        = `$CMGroupDiscovery.ScheduleType
                                RecurInterval                       = `$CMGroupDiscovery.RecurInterval
                            }
                        }
                    }
                }
            }
        }

        if (`$CMSiteMaintenance)
        {
            foreach (`$task in `$CMSiteMaintenance)
            {
                if (`$task.Enabled -eq `$false)
                {
                    CMSiteMaintenance `$task.TaskName
                    {
                        SiteCode = `$SiteCode
                        TaskName = `$task.TaskName
                        Enabled  = `$task.Enabled
                    }
                }
                elseif (`$task.TaskName -eq 'Update Application Catalog Tables')
                {
                    CMSiteMaintenance `$task.TaskName
                    {
                        SiteCode    = `$SiteCode
                        TaskName    = `$task.TaskName
                        Enabled     = `$task.Enabled
                        RunInterval = `$task.RunInterval
                    }
                }
                elseif (`$task.DeleteOlderThanDays)
                {
                    CMSiteMaintenance `$task.TaskName
                    {
                        SiteCode            = `$SiteCode
                        TaskName            = `$task.TaskName
                        Enabled             = `$task.Enabled
                        DaysOfWeek          = `$task.DaysOfWeek
                        DeleteOlderThanDays = `$task.DeleteOlderThanDays
                        BeginTime           = `$task.BeginTime
                        LatestBeginTime     = `$task.LatestBeginTime
                    }
                }
                else
                {
                    CMSiteMaintenance `$task.TaskName
                    {
                        SiteCode        = `$SiteCode
                        TaskName        = `$task.TaskName
                        Enabled         = `$task.Enabled
                        DaysOfWeek      = `$task.DaysOfWeek
                        BeginTime       = `$task.BeginTime
                        LatestBeginTime = `$task.LatestBeginTime
                        BackupLocation  = `$task.BackupLocation
                    }
                }
                [array]`$cmSiteMaintenanceDependsOn += `"[CMSiteMaintenance]`$(`$task.TaskName)`"
            }
        }

        if (`$CMUserDiscovery)
        {
            if (`$CMUserDiscovery.Enabled -eq `$true)
            {
                if (`$CMUserDiscovery.ScheduleInterval -eq 'None')
                {
                    CMUserDiscovery CMUserDiscovery
                    {
                        SiteCode             = `$SiteCode
                        Enabled              = `$CMUserDiscovery.Enabled
                        ScheduleInterval     = `$CMUserDiscovery.ScheduleInterval
                        EnableDeltaDiscovery = `$CMUserDiscovery.EnableDeltaDiscovery
                        DeltaDiscoveryMins   = `$CMUserDiscovery.DeltaDiscoveryMins
                        ADContainers         = `$CMUserDiscovery.ADContainers
                    }
                }
                else
                {
                    CMUserDiscovery CMUserDiscovery
                    {
                        SiteCode             = `$SiteCode
                        Enabled              = `$CMUserDiscovery.Enabled
                        ScheduleInterval     = `$CMUserDiscovery.ScheduleInterval
                        ScheduleCount        = `$CMUserDiscovery.ScheduleCount
                        EnableDeltaDiscovery = `$CMUserDiscovery.EnableDeltaDiscovery
                        DeltaDiscoveryMins   = `$CMUserDiscovery.DeltaDiscoveryMins
                        ADContainers         = `$CMUserDiscovery.ADContainers
                    }
                }
            }
            else
            {
                CMUserDiscovery CMUserDiscovery
                {
                    SiteCode = `$SiteCode
                    Enabled  = `$CMUserDiscovery.Enabled
                }
            }
        }

        if (`$CMClientPushSettings)
        {
            CMClientPushSettings ClientPushSettings
            {
                SiteCode                              = `$SiteCode
                EnableAutomaticClientPushInstallation = `$CMClientPushSettings.EnableAutomaticClientPushInstallation
                InstallationProperty                  = `$CMClientPushSettings.InstallationProperty
                InstallClientToDomainController       = `$CMClientPushSettings.InstallClientToDomainController
                EnableSystemTypeConfigurationManager  = `$CMClientPushSettings.EnableSystemTypeConfigurationManager
                Accounts                              = `$CMClientPushSettings.Accounts
                EnableSystemTypeServer                = `$CMClientPushSettings.EnableSystemTypeServer
                EnableSystemTypeWorkstation           = `$CMClientPushSettings.EnableSystemTypeWorkstation
                DependsOn                             = `$cmAccountsDependsOn
            }
        }

        if (`$CMSoftwareDistributionComponent)
        {
            if (`$CMSoftwareDistributionComponent.MulticastRetryCount)
            {
                CMSoftwareDistributionComponent SoftwareDistributionSettings
                {
                    SiteCode                         = `$SiteCode
                    RetryCount                       = `$CMSoftwareDistributionComponent.RetryCount
                    MulticastDelayBeforeRetryingMins = `$CMSoftwareDistributionComponent.MulticastDelayBeforeRetryingMins
                    ClientComputerAccount            = `$CMSoftwareDistributionComponent.ClientComputerAccount
                    AccessAccounts                   = `$CMSoftwareDistributionComponent.AccessAccounts
                    DelayBeforeRetryingMins          = `$CMSoftwareDistributionComponent.DelayBeforeRetryingMins
                    MulticastRetryCount              = `$CMSoftwareDistributionComponent.MulticastRetryCount
                    MaximumThreadCountPerPackage     = `$CMSoftwareDistributionComponent.MaximumThreadCountPerPackage
                    MaximumPackageCount              = `$CMSoftwareDistributionComponent.MaximumPackageCount
                    DependsOn                        = `$cmAccountsDependsOn
                }
            }
            else
            {
                CMSoftwareDistributionComponent SoftwareDistributionSettings
                {
                    SiteCode                         = `$SiteCode
                    RetryCount                       = `$CMSoftwareDistributionComponent.RetryCount
                    ClientComputerAccount            = `$CMSoftwareDistributionComponent.ClientComputerAccount
                    DelayBeforeRetryingMins          = `$CMSoftwareDistributionComponent.DelayBeforeRetryingMins
                    MaximumThreadCountPerPackage     = `$CMSoftwareDistributionComponent.MaximumThreadCountPerPackage
                    MaximumPackageCount              = `$CMSoftwareDistributionComponent.MaximumPackageCount
                    DependsOn                        = `$cmAccountsDependsOn
                }
            }
        }

        if (`$CMClientStatusSettings)
        {
            CMClientStatusSettings ClientStatusSettings
            {
                SiteCode               = `$SiteCode
                IsSingleInstance       = `$CMClientStatusSettings.IsSingleInstance
                ClientPolicyDays       = `$CMClientStatusSettings.ClientPolicyDays
                HeartbeatDiscoveryDays = `$CMClientStatusSettings.HeartbeatDiscoveryDays
                SoftwareInventoryDays  = `$CMClientStatusSettings.SoftwareInventoryDays
                HardwareInventoryDays  = `$CMClientStatusSettings.HardwareInventoryDays
                StatusMessageDays      = `$CMClientStatusSettings.StatusMessageDays
                HistoryCleanupDays     = `$CMClientStatusSettings.HistoryCleanupDays
            }
        }

        if (`$CMCollectionMembershipEvaluationComponent)
        {
            CMCollectionMembershipEvaluationComponent CollectionSettings
            {
                SiteCode       = `$SiteCode
                EvaluationMins = `$CMCollectionMembershipEvaluationComponent.EvaluationMins
            }
        }

        if (`$CMCollections)
        {
            foreach (`$coll in `$CMCollections)
            {
                if (`$coll.QueryRules)
                {
                    `$queryRules = @()
                    foreach (`$item in `$coll.QueryRules)
                    {
                        `$queryRules += DSC_CMCollectionQueryRules
                        {
                            RuleName        = `$item.RuleName
                            QueryExpression = `$item.QueryExpression
                        }
                    }
                }

                if (`$coll.QueryRules -and `$coll.IncludeMembership -and `$coll.ExcludeMembership -and
                    `$coll.DirectMembership)
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            IncludeMembership      = `$coll.IncludeMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                            QueryRules             = `$queryRules
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                    }
                }
                elseif (`$coll.QueryRules -and `$coll.ExcludeMembership -and `$coll.DirectMembership -and
                        [string]::IsNullOrEmpty(`$coll.IncludeMembership))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                            QueryRules             = `$queryRules
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                    }
                }
                elseif (`$coll.QueryRules -and `$coll.IncludeMembership -and `$coll.DirectMembership -and
                        [string]::IsNullOrEmpty(`$coll.ExcludeMembership))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            IncludeMembership      = `$coll.IncludeMembership
                            QueryRules             = `$queryRules
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                    }
                }
                elseif (`$coll.QueryRules -and `$coll.IncludeMembership -and `$coll.ExcludeMembership -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            IncludeMembership      = `$coll.IncludeMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                            QueryRules             = `$queryRules
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                                QueryRules             = `$queryRules
                            }
                        }
                    }
                }
                elseif (`$coll.QueryRules -and [string]::IsNullOrEmpty(`$coll.IncludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.ExcludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            QueryRules             = `$queryRules
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                QueryRules             = `$queryRules
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                QueryRules             = `$queryRules
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                QueryRules             = `$queryRules
                            }
                        }
                    }
                }
                elseif (`$coll.DirectMembership -and `$coll.IncludeMembership -and `$coll.ExcludeMembership -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            IncludeMembership      = `$coll.IncludeMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                    }
                }
                elseif (`$coll.DirectMembership -and `$coll.IncludeMembership -and
                        [string]::IsNullOrEmpty(`$coll.ExcludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            IncludeMembership      = `$coll.IncludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                    }
                }
                elseif (`$coll.DirectMembership -and `$coll.ExcludeMembership -and
                        [string]::IsNullOrEmpty(`$coll.IncludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                    }
                }
                elseif (`$coll.DirectMembership -and [string]::IsNullOrEmpty(`$coll.ExcludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.IncludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            DirectMembership       = `$coll.DirectMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                DirectMembership       = `$coll.DirectMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                DirectMembership       = `$coll.DirectMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                DirectMembership       = `$coll.DirectMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DirectMembership       = `$coll.DirectMembership
                            }
                        }
                    }
                }
                elseif (`$coll.IncludeMembership -and `$coll.ExcludeMembership -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            IncludeMembership      = `$coll.IncludeMembership
                            ExcludeMembership      = `$coll.ExcludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                IncludeMembership      = `$coll.IncludeMembership
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                    }
                }
                elseif (`$coll.IncludeMembership -and [string]::IsNullOrEmpty(`$coll.ExcludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            IncludeMembership      = `$coll.IncludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                IncludeMembership      = `$coll.IncludeMembership
                            }
                        }
                    }
                }
                elseif (`$coll.ExcludeMembership -and [string]::IsNullOrEmpty(`$coll.IncludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                            ExcludeMembership      = `$coll.ExcludeMembership
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                ExcludeMembership      = `$coll.ExcludeMembership
                            }
                        }
                    }
                }
                elseif ([string]::IsNullOrEmpty(`$coll.ExcludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.IncludeMembership) -and
                        [string]::IsNullOrEmpty(`$coll.DirectMembership) -and
                        [string]::IsNullOrEmpty(`$coll.QueryRules))
                {
                    if (`$coll.RefreshType -eq 'Manual' -or `$coll.RefreshType -eq 'Continuous')
                    {
                        CMCollections `$(`$coll.CollectionName)
                        {
                            SiteCode               = `$SiteCode
                            CollectionType         = `$coll.CollectionType
                            Ensure                 = `$coll.Ensure
                            Comment                = `$coll.Comment
                            CollectionName         = `$coll.CollectionName
                            LimitingCollectionName = `$coll.LimitingCollectionName
                            RefreshType            = `$coll.RefreshType
                        }
                    }
                    elseif (`$coll.RefreshType -eq 'Periodic' -or `$coll.RefreshType -eq 'Both')
                    {
                        if (`$coll.ScheduleType -eq 'MonthlyByDay')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfMonth             = `$coll.DayOfMonth
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'MonthlyByWeek')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                MonthlyWeekOrder       = `$coll.MonthlyWeekOrder
                                DayOfWeek              = `$coll.DayOfWeek
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'Weekly')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                                DayOfWeek              = `$coll.DayOfWeek
                            }
                        }
                        elseif (`$coll.ScheduleType -eq 'None')
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                            }
                        }
                        else
                        {
                            CMCollections `$(`$coll.CollectionName)
                            {
                                SiteCode               = `$SiteCode
                                CollectionType         = `$coll.CollectionType
                                Ensure                 = `$coll.Ensure
                                Comment                = `$coll.Comment
                                CollectionName         = `$coll.CollectionName
                                LimitingCollectionName = `$coll.LimitingCollectionName
                                ScheduleType           = `$coll.ScheduleType
                                RefreshType            = `$coll.RefreshType
                                RecurInterval          = `$coll.RecurInterval
                            }
                        }
                    }
                }

                [array]`$cmCollectionsDependsOn += `"[CMCollections]`$(`$coll.CollectionName)`"
            }
        }

        if (`$CMMaintenanceWindows)
        {
            foreach (`$mw in `$CMMaintenanceWindows)
            {
                if (-not [string]::IsNullOrEmpty(`$mw.HourDuration))
                {
                    if (`$mw.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            HourDuration       = `$mw.HourDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DayOfMonth         = `$mw.DayOfMonth
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            HourDuration       = `$mw.HourDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            MonthlyWeekOrder   = `$mw.MonthlyWeekOrder
                            DayOfWeek          = `$mw.DayOfWeek
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'Weekly')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            HourDuration       = `$mw.HourDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DayOfWeek          = `$mw.DayOfWeek
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'None')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            HourDuration       = `$mw.HourDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    else
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            HourDuration       = `$mw.HourDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                }
                else
                {
                    if (`$mw.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            MinuteDuration     = `$mw.MinuteDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DayOfMonth         = `$mw.DayOfMonth
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            MinuteDuration     = `$mw.MinuteDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            MonthlyWeekOrder   = `$mw.MonthlyWeekOrder
                            DayOfWeek          = `$mw.DayOfWeek
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'Weekly')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            MinuteDuration     = `$mw.MinuteDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DayOfWeek          = `$mw.DayOfWeek
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    elseif (`$mw.ScheduleType -eq 'None')
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            MinuteDuration     = `$mw.MinuteDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                    else
                    {
                        CMMaintenanceWindows `"`$(`$mw.CollectionName)_`$(`$mw.Name)`"
                        {
                            SiteCode           = `$SiteCode
                            Name               = `$mw.Name
                            CollectionName     = `$mw.CollectionName
                            ServiceWindowsType = `$mw.ServiceWindowsType
                            IsEnabled          = `$mw.IsEnabled
                            Ensure             = `$mw.Ensure
                            MinuteDuration     = `$mw.MinuteDuration
                            Start              = `$mw.Start
                            ScheduleType       = `$mw.ScheduleType
                            RecurInterval      = `$mw.RecurInterval
                            DependsOn          = `$cmCollectionsDependsOn
                        }
                    }
                }
            }
        }

        if (`$CMStatusReportingComponent)
        {
            if (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$true -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportType           = `$CMStatusReportingComponent.ServerReportType
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$true -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportType           = `$CMStatusReportingComponent.ServerReportType
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$true -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportType           = `$CMStatusReportingComponent.ServerReportType
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$true -and `$CMStatusReportingComponent.ServerReportChecked -eq `$true -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportType           = `$CMStatusReportingComponent.ServerReportType
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ServerLogType              = `$CMStatusReportingComponent.ServerLogType
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$false -and `$CMStatusReportingComponent.ServerReportChecked -eq `$true -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportType           = `$CMStatusReportingComponent.ServerReportType
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$false -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$false -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$true)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ClientReportType           = `$CMStatusReportingComponent.ClientReportType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$false -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$true -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                    ClientLogType              = `$CMStatusReportingComponent.ClientLogType
                }
            }
            elseif (`$CMStatusReportingComponent.ServerLogChecked -eq `$false -and `$CMStatusReportingComponent.ServerReportChecked -eq `$false -and
                `$CMStatusReportingComponent.ClientLogChecked -eq `$false -and `$CMStatusReportingComponent.ClientReportChecked -eq `$false)
            {
                CMStatusReportingComponent  StatusReportingComponent
                {
                    SiteCode                   = `$SiteCode
                    ServerReportFailureChecked = `$CMStatusReportingComponent.ServerReportFailureChecked
                    ClientLogFailureChecked    = `$CMStatusReportingComponent.ClientLogFailureChecked
                    ServerReportChecked        = `$CMStatusReportingComponent.ServerReportChecked
                    ServerLogChecked           = `$CMStatusReportingComponent.ServerLogChecked
                    ServerLogFailureChecked    = `$CMStatusReportingComponent.ServerLogFailureChecked
                    ClientReportChecked        = `$CMStatusReportingComponent.ClientReportChecked
                    ClientLogChecked           = `$CMStatusReportingComponent.ClientLogChecked
                    ClientReportFailureChecked = `$CMStatusReportingComponent.ClientReportFailureChecked
                }
            }
        }

        if (`$CMSecurityScopes)
        {
            foreach (`$scope in `$CMSecuritySCopes)
            {
                CMSecurityScopes `$(`$scope.SecurityScopeName)
                {
                    SiteCode          = `$SiteCode
                    SecurityScopeName = `$scope.SecurityScopeName
                    Description       = `$scope.Description
                    Ensure            = `$scope.Ensure
                }

                [array]`$cmSecurityScopesDependsOn += `"[CMSecurityScopes]`$(`$scope.SecurityScopeName)`"
            }
        }

        if (`$CMDistributionGroup)
        {
            foreach (`$distributionGroup in `$CMDistributionGroup)
            {
                CMDistributionGroup `$(`$distributionGroup.DistributionGroup)
                {
                    SiteCode          = `$SiteCode
                    DistributionGroup = `$distributionGroup.DistributionGroup
                    SecurityScopes    = `$distributionGroup.SecurityScopes
                    Ensure            = `$distributionGroup.Ensure
                    DependsOn         = `$cmSecurityScopesDependsOn
                }

                [array]`$cmDistroGroupsDependsOn += `"[CMDistributionGroup]`$(`$distributionGroup.DistributionGroup)`"
            }
        }

        if (`$CMSiteSystemServer)
        {
            foreach (`$item in `$CMSiteSystemServer)
            {
                if ([string]::IsNullOrEmpty(`$item.EnableProxy))
                {
                    if (`$item.UseSiteServerAccount -eq `$true)
                    {
                        CMSiteSystemServer `$item.SiteSystemServer
                        {
                            SiteCode             = `$SiteCode
                            Ensure               = `$item.Ensure
                            SiteSystemServer     = `$item.SiteSystemServer
                            UseSiteServerAccount = `$item.UseSiteServerAccount
                            DependsOn            = `$cmAccountsDependsOn
                        }
                    }
                    else
                    {
                        CMSiteSystemServer `$item.SiteSystemServer
                        {
                            SiteCode             = `$SiteCode
                            Ensure               = `$item.Ensure
                            SiteSystemServer     = `$item.SiteSystemServer
                            UseSiteServerAccount = `$item.UseSiteServerAccount
                            AccountName          = `$item.AccountName
                            DependsOn            = `$cmAccountsDependsOn
                        }
                    }
                }
                elseif (`$item.EnableProxy -eq `$false)
                {
                    if (`$item.UseSiteServerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                AccountName          = `$item.AccountName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                AccountName          = `$item.AccountName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                }
                elseif (`$item.ProxyAccessAccount)
                {
                    if (`$item.UseSiteServerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                ProxyAccessAccount   = `$item.ProxyAccessAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                ProxyAccessAccount   = `$item.ProxyAccessAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                AccountName          = `$item.AccountName
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                ProxyAccessAccount   = `$item.ProxyAccessAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                AccountName          = `$item.AccountName
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                ProxyAccessAccount   = `$item.ProxyAccessAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                }
                else
                {
                    if (`$item.UseSiteServerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$item.FdmOperation))
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                AccountName          = `$item.AccountName
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                        else
                        {
                            CMSiteSystemServer `$item.SiteSystemServer
                            {
                                SiteCode             = `$SiteCode
                                ProxyServerPort      = `$item.ProxyServerPort
                                AccountName          = `$item.AccountName
                                EnableProxy          = `$item.EnableProxy
                                Ensure               = `$item.Ensure
                                SiteSystemServer     = `$item.SiteSystemServer
                                FdmOperation         = `$item.FdmOperation
                                PublicFqdn           = `$item.PublicFqdn
                                ProxyServerName      = `$item.ProxyServerName
                                UseSiteServerAccount = `$item.UseSiteServerAccount
                                DependsOn            = `$cmAccountsDependsOn
                            }
                        }
                    }
                }

                [array]`$cmSiteSystemsDependsOn += `"[CMSiteSystemServer]`$(`$item.SiteSystemServer)`"
            }
        }

        if (`$CMManagementPoint)
        {
            foreach (`$mp in `$CMManagementPoint)
            {
                if (`$mp.UseSiteDatabase -eq `$true)
                {
                    if (`$mp.UseComputerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UseComputerAccount   = `$mp.UseComputerAccount
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UseComputerAccount   = `$mp.UseComputerAccount
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                EnableCloudGateway   = `$mp.EnableCloudGateway
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UserName             = `$mp.UserName
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UserName             = `$mp.UserName
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                EnableCloudGateway   = `$mp.EnableCloudGateway
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                }
                elseif (`$mp.SqlServerInstanceName)
                {
                    if (`$mp.UseComputerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode              = `$SiteCode
                                EnableSsl             = `$mp.EnableSsl
                                GenerateAlert         = `$mp.GenerateAlert
                                SiteServerName        = `$mp.SiteServerName
                                Ensure                = `$mp.Ensure
                                UseComputerAccount    = `$mp.UseComputerAccount
                                UseSiteDatabase       = `$mp.UseSiteDatabase
                                ClientConnectionType  = `$mp.ClientConnectionType
                                SQLServerFqdn         = `$mp.SQLServerFqdn
                                DatabaseName          = `$mp.DatabaseName
                                SqlServerInstanceName = `$mp.SqlServerInstanceName
                                DependsOn             = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode              = `$SiteCode
                                EnableSsl             = `$mp.EnableSsl
                                GenerateAlert         = `$mp.GenerateAlert
                                SiteServerName        = `$mp.SiteServerName
                                Ensure                = `$mp.Ensure
                                UseComputerAccount    = `$mp.UseComputerAccount
                                UseSiteDatabase       = `$mp.UseSiteDatabase
                                ClientConnectionType  = `$mp.ClientConnectionType
                                EnableCloudGateway    = `$mp.EnableCloudGateway
                                SQLServerFqdn         = `$mp.SQLServerFqdn
                                DatabaseName          = `$mp.DatabaseName
                                SqlServerInstanceName = `$mp.SqlServerInstanceName
                                DependsOn             = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode              = `$SiteCode
                                EnableSsl             = `$mp.EnableSsl
                                GenerateAlert         = `$mp.GenerateAlert
                                SiteServerName        = `$mp.SiteServerName
                                Ensure                = `$mp.Ensure
                                UserName              = `$mp.UserName
                                UseSiteDatabase       = `$mp.UseSiteDatabase
                                ClientConnectionType  = `$mp.ClientConnectionType
                                SQLServerFqdn         = `$mp.SQLServerFqdn
                                DatabaseName          = `$mp.DatabaseName
                                SqlServerInstanceName = `$mp.SqlServerInstanceName
                                DependsOn             = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode              = `$SiteCode
                                EnableSsl             = `$mp.EnableSsl
                                GenerateAlert         = `$mp.GenerateAlert
                                SiteServerName        = `$mp.SiteServerName
                                Ensure                = `$mp.Ensure
                                UserName              = `$mp.UserName
                                UseSiteDatabase       = `$mp.UseSiteDatabase
                                ClientConnectionType  = `$mp.ClientConnectionType
                                EnableCloudGateway    = `$mp.EnableCloudGateway
                                SQLServerFqdn         = `$mp.SQLServerFqdn
                                DatabaseName          = `$mp.DatabaseName
                                SqlServerInstanceName = `$mp.SqlServerInstanceName
                                DependsOn             = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                }
                else
                {
                    if (`$mp.UseComputerAccount -eq `$true)
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UseComputerAccount   = `$mp.UseComputerAccount
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                SQLServerFqdn        = `$mp.SQLServerFqdn
                                DatabaseName         = `$mp.DatabaseName
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UseComputerAccount   = `$mp.UseComputerAccount
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                EnableCloudGateway   = `$mp.EnableCloudGateway
                                SQLServerFqdn        = `$mp.SQLServerFqdn
                                DatabaseName         = `$mp.DatabaseName
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if ([string]::IsNullOrEmpty(`$mp.EnableCloudGateway))
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UserName             = `$mp.UserName
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                SQLServerFqdn        = `$mp.SQLServerFqdn
                                DatabaseName         = `$mp.DatabaseName
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                        else
                        {
                            CMManagementPoint `$(`$mp.SiteServerName)
                            {
                                SiteCode             = `$SiteCode
                                EnableSsl            = `$mp.EnableSsl
                                GenerateAlert        = `$mp.GenerateAlert
                                SiteServerName       = `$mp.SiteServerName
                                Ensure               = `$mp.Ensure
                                UserName             = `$mp.UserName
                                UseSiteDatabase      = `$mp.UseSiteDatabase
                                ClientConnectionType = `$mp.ClientConnectionType
                                EnableCloudGateway   = `$mp.EnableCloudGateway
                                SQLServerFqdn        = `$mp.SQLServerFqdn
                                DatabaseName         = `$mp.DatabaseName
                                DependsOn            = `$cmSiteSystemsDependsOn
                            }
                        }
                    }
                }

                [array]`$cmMPDependsOn += `"[CMManagementPoint]`$(`$mp.SiteServerName)`"
            }
        }

        if (`$CMFallbackStatusPoint)
        {
            foreach (`$fallback in `$CMFallbackStatusPoint)
            {
                CMFallbackStatusPoint `$(`$fallback.SiteServerName)
                {
                    SiteCode          = `$SiteCode
                    ThrottleSec       = `$fallback.ThrottleSec
                    StateMessageCount = `$fallback.StateMessageCount
                    SiteServerName    = `$fallback.SiteServerName
                    Ensure            = `$fallback.Ensure
                    DependsOn         = `$cmSiteSystemsDependsOn
                }

                [array]`$cmFallbackDependsOn += `"[CMFallbackStatusPoint]`$(`$fallback.SiteServerName)`"
            }
        }

        if (`$CMBoundaryGroups)
        {
            foreach (`$item in `$CMBoundaryGroups)
            {
                CMBoundaryGroups `$(`$item.BoundaryGroup)
                {
                    SiteCode       = `$SiteCode
                    SecurityScopes = `$item.SecurityScopes
                    Ensure         = `$item.Ensure
                    BoundaryGroup  = `$item.BoundaryGroup
                    DependsOn      = `$cmSecurityScopesDependsOn
                }

                [array]`$cmBoundaryGroupDependsOn += `"[CMBoundaryGroups]`$(`$item.BoundaryGroup)`"
            }
        }

        if (`$CMBoundaryGroups -and `$CMSiteSystemServer)
        {
            `$dpDependsOn = `$cmSiteSystemsDependsOn,`$cmBoundaryGroupDependsOn
        }
        elseif (`$CMBoundaryGroups)
        {
            `$dpDependsOn = `$cmBoundaryGroupDependsOn
        }
        else
        {
            `$dpDependsOn = `$cmSiteSystemsDependsOn
        }

        if (`$CMDistributionPoint)
        {
            foreach (`$dp in `$CMDistributionPoint)
            {
                CMDistributionPoint `$(`$dp.SiteServerName)
                {
                    SiteCode                        = `$SiteCode
                    EnableAnonymous                 = `$dp.EnableAnonymous
                    ClientCommunicationType         = `$dp.ClientCommunicationType
                    Description                     = `$dp.Description
                    SecondaryContentLibraryLocation = `$dp.SecondaryContentLibraryLocation
                    SiteServerName                  = `$dp.SiteServerName
                    PrimaryContentLibraryLocation   = `$dp.PrimaryContentLibraryLocation
                    Ensure                          = `$dp.Ensure
                    MinimumFreeSpaceMB              = `$dp.MinimumFreeSpaceMB
                    EnableLedbat                    = `$dp.EnableLedbat
                    PrimaryPackageShareLocation     = `$dp.PrimaryPackageShareLocation
                    BoundaryGroups                  = `$dp.BoundaryGroups
                    CertificateExpirationTimeUtc    = `$dp.CertificateExpirationTimeUtc
                    SecondaryPackageShareLocation   = `$dp.SecondaryPackageShareLocation
                    EnableBranchCache               = `$dp.EnableBranchCache
                    AllowPreStaging                 = `$dp.AllowPreStaging
                    DependsOn                       = `$dpDependsOn
                }

                [array]`$cmDistroPointDependsOn += `"[CMDistributionPoint]`$(`$dp.SiteServerName)`"
            }
        }

        if (`$cmDistroPointDependsOn -and `$cmDistroGroupsDependsOn)
        {
            `$dpGroupDependsOn = `$cmDistroPointDependsOn,`$cmDistroGroupsDependsOn
        }
        elseif (`$cmDistroPointDependsOn)
        {
            `$dpGroupDependsOn = `$cmDistroPointDependsOn
        }
        else
        {
            `$dpGroupDependsOn = `$cmDistroGroupsDependsOn
        }

        if (`$CMDistributionPointGroupMembers)
        {
            foreach (`$dpGroup in `$CMDistributionPointGroupMembers)
            {
                CMDistributionPointGroupMembers `$(`$dpGroup.DistributionPoint)
                {
                    SiteCode           = `$SiteCode
                    DistributionPoint  = `$dpGroup.DistributionPoint
                    DistributionGroups = `$dpGroup.DistributionGroups
                    DependsOn          = `$dpGroupDependsOn
                }
            }
        }

        if (`$CMPullDistributionPoint)
        {
            foreach (`$pull in `$CMPullDistributionPoint)
            {
                `$pullRankings = @()
                foreach (`$value in `$pull.SourceDistributionPoint)
                {
                    `$pullRankings += DSC_CMPullDistributionPointSourceDP
                    {
                        SourceDP = `$value.SourceDP
                        DPRank   = `$value.DPRank
                    }
                }

                CMPullDistributionPoint `$(`$pull.SiteServerName)
                {
                    SiteCode                = `$SiteCode
                    SiteServerName          = `$pull.SiteServerName
                    EnablePullDP            = `$pull.EnablePullDP
                    SourceDistributionPoint = `$pullRankings
                    DependsOn               = `$cmDistroPointDependsOn
                }

                [array]`$cmPullDPDependsOn += `"[CMPxeDistributionPoint]`$(`$pull.SiteServerName)`"
            }
        }

        if (`$CMPxeDistributionPoint)
        {
            foreach (`$pxe in `$CMPxeDistributionPoint)
            {
                if (`$pxe.PxePassword -eq `$true)
                {
                    `$password = Get-Credential -UserName `'PxePassword`' -Message `"Enter the PXE boot Password you wish to use for `$(`$pxe.SiteServerName). The username does not matter.`"

                    CMPxeDistributionPoint `$(`$pxe.SiteServerName)
                    {
                        SiteCode                     = `$SiteCode
                        PxeServerResponseDelaySec    = `$pxe.PxeServerResponseDelaySec
                        EnableNonWdsPxe              = `$pxe.EnableNonWdsPxe
                        PxePassword                  = `$password
                        SiteServerName               = `$pxe.SiteServerName
                        EnableUnknownComputerSupport = `$pxe.EnableUnknownComputerSupport
                        EnablePxe                    = `$pxe.EnablePxe
                        AllowPxeResponse             = `$pxe.AllowPxeResponse
                        UserDeviceAffinity           = `$pxe.UserDeviceAffinity
                        DependsOn                    = `$cmDistroPointDependsOn
                    }
                }
                else
                {
                    CMPxeDistributionPoint `$(`$pxe.SiteServerName)
                    {
                        SiteCode                     = `$SiteCode
                        PxeServerResponseDelaySec    = `$pxe.PxeServerResponseDelaySec
                        EnableNonWdsPxe              = `$pxe.EnableNonWdsPxe
                        SiteServerName               = `$pxe.SiteServerName
                        EnableUnknownComputerSupport = `$pxe.EnableUnknownComputerSupport
                        EnablePxe                    = `$pxe.EnablePxe
                        AllowPxeResponse             = `$pxe.AllowPxeResponse
                        UserDeviceAffinity           = `$pxe.UserDeviceAffinity
                        DependsOn                    = `$cmDistroPointDependsOn
                    }
                }

                [array]`$cmPXEPointDependsOn += `"[CMPxeDistributionPoint]`$(`$pxe.SiteServerName)`"
            }
        }

        if (`$CMServiceConnectionPoint)
        {
            CMServiceConnectionPoint `$(`$CMServiceConnectionPoint.SiteServerName)
            {
                SiteCode       = `$SiteCode
                SiteServerName = `$CMServiceConnectionPoint.SiteServerName
                Ensure         = `$CMServiceConnectionPoint.Ensure
                Mode           = `$CMServiceConnectionPoint.Mode
            }
        }

        if (`$CMSoftwareUpdatePoint)
        {
            foreach (`$updatePoint in `$CMSoftwareUpdatePoint)
            {
                if (`$updatePoint.AnonymousWsusAccess -eq `$true)
                {
                    CMSoftwareUpdatePoint `$(`$updatePoint.SiteServerName)
                    {
                        SiteCode                      = `$SiteCode
                        AnonymousWsusAccess           = `$updatePoint.AnonymousWsusAccess
                        ClientConnectionType          = `$updatePoint.ClientConnectionType
                        SiteServerName                = `$updatePoint.SiteServerName
                        WsusIisSslPort                = `$updatePoint.WsusIisSslPort
                        EnableCloudGateway            = `$updatePoint.EnableCloudGateway
                        WsusSsl                       = `$updatePoint.WsusSsl
                        UseProxyForAutoDeploymentRule = `$updatePoint.UseProxyForAutoDeploymentRule
                        UseProxy                      = `$updatePoint.UseProxy
                        WsusIisPort                   = `$updatePoint.WsusIisPort
                        Ensure                        = `$updatePoint.Ensure
                        DependsOn                     = `$cmSiteSystemsDependsOn
                    }
                }
                else
                {
                    CMSoftwareUpdatePoint `$(`$updatePoint.SiteServerName)
                    {
                        SiteCode                      = `$SiteCode
                        AnonymousWsusAccess           = `$updatePoint.AnonymousWsusAccess
                        ClientConnectionType          = `$updatePoint.ClientConnectionType
                        SiteServerName                = `$updatePoint.SiteServerName
                        WsusIisSslPort                = `$updatePoint.WsusIisSslPort
                        EnableCloudGateway            = `$updatePoint.EnableCloudGateway
                        WsusSsl                       = `$updatePoint.WsusSsl
                        UseProxyForAutoDeploymentRule = `$updatePoint.UseProxyForAutoDeploymentRule
                        UseProxy                      = `$updatePoint.UseProxy
                        WsusIisPort                   = `$updatePoint.WsusIisPort
                        WsusAccessAccount             = `$updatePoint.WsusAccessAccount
                        Ensure                        = `$updatePoint.Ensure
                        DependsOn                     = `$cmSiteSystemsDependsOn
                    }
                }

                [array]`$cmUpdatePointDependsOn += `"[CMSoftwareUpdatePoint]`$(`$updatePoint.SiteServerName)`"
            }
        }
        if (`$CMSoftwareUpdatePointComponent)
        {
            if (-not `$CMSoftwareUpdatePointComponent.ContainsKey('EnableSynchronization'))
            {
                CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                {
                    SiteCode            = `$SiteCode
                    LanguageUpdateFiles = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                    ReportingEvent      = `$CMSoftwareUpdatePointComponent.ReportingEvent
                }
            }
            elseif (`$CMSoftwareUpdatePointComponent.EnableSynchronization -eq `$true)
            {
                if (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    if (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfMonth                              = `$CMSoftwareUpdatePointComponent.DayOfMonth
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            MonthlyWeekOrder                        = `$CMSoftwareUpdatePointComponent.MonthlyWeekOrder
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    elseif (`$CMSoftwareUpdatePointComponent.ScheduleType -eq 'Weekly')
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DayOfWeek                               = `$CMSoftwareUpdatePointComponent.DayOfWeek
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                    else
                    {
                        CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                        {
                            SiteCode                                = `$SiteCode
                            LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                            LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                            Products                                = `$CMSoftwareUpdatePointComponent.Products
                            UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                            ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                            DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                            EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                            EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                            EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                            ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                            ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                            ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                            SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                            WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                            EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                            FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                            NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                            ScheduleType                            = `$CMSoftwareUpdatePointComponent.ScheduleType
                            Start                                   = `$CMSoftwareUpdatePointComponent.Start
                            RecurInterval                           = `$CMSoftwareUpdatePointComponent.RecurInterval
                            DependsOn                               = `$cmUpdatePointDependsOn
                        }
                    }
                }
            }
            else
            {
                if (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        UpstreamSourceLocation                  = `$CMSoftwareUpdatePointComponent.UpstreamSourceLocation
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$true)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        EnableManualCertManagement              = `$CMSoftwareUpdatePointComponent.EnableManualCertManagement
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonthForFeature                     = `$CMSoftwareUpdatePointComponent.WaitMonthForFeature
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
                elseif (`$CMSoftwareUpdatePointComponent.SynchronizeAction -ne 'SynchronizeFromAnUpstreamDataSourceLocation' -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence -eq `$false -and
                    `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature -eq `$true -and
                    `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates -eq `$false)
                {
                    CMSoftwareUpdatePointComponent SoftwareUpdatePointComponent
                    {
                        SiteCode                                = `$SiteCode
                        LanguageSummaryDetails                  = `$CMSoftwareUpdatePointComponent.LanguageSummaryDetails
                        LanguageUpdateFiles                     = `$CMSoftwareUpdatePointComponent.LanguageUpdateFiles
                        Products                                = `$CMSoftwareUpdatePointComponent.Products
                        UpdateClassifications                   = `$CMSoftwareUpdatePointComponent.UpdateClassifications
                        ContentFileOption                       = `$CMSoftwareUpdatePointComponent.ContentFileOption
                        DefaultWsusServer                       = `$CMSoftwareUpdatePointComponent.DefaultWsusServer
                        EnableCallWsusCleanupWizard             = `$CMSoftwareUpdatePointComponent.EnableCallWsusCleanupWizard
                        EnableSyncFailureAlert                  = `$CMSoftwareUpdatePointComponent.EnableSyncFailureAlert
                        EnableSynchronization                   = `$CMSoftwareUpdatePointComponent.EnableSynchronization
                        ImmediatelyExpireSupersedence           = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedence
                        ImmediatelyExpireSupersedenceForFeature = `$CMSoftwareUpdatePointComponent.ImmediatelyExpireSupersedenceForFeature
                        ReportingEvent                          = `$CMSoftwareUpdatePointComponent.ReportingEvent
                        SynchronizeAction                       = `$CMSoftwareUpdatePointComponent.SynchronizeAction
                        WaitMonth                               = `$CMSoftwareUpdatePointComponent.WaitMonth
                        EnableThirdPartyUpdates                 = `$CMSoftwareUpdatePointComponent.EnableThirdPartyUpdates
                        FeatureUpdateMaxRuntimeMins             = `$CMSoftwareUpdatePointComponent.FeatureUpdateMaxRuntimeMins
                        NonFeatureUpdateMaxRuntimeMins          = `$CMSoftwareUpdatePointComponent.NonFeatureUpdateMaxRuntimeMins
                        DependsOn                               = `$cmUpdatePointDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettings)
        {
            foreach (`$client in `$CMClientSettings)
            {
                if (`$client.Description)
                {
                    CMClientSettings `$client.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$client.ClientSettingName
                        Type              = `$client.Type
                        Description       = `$client.Description
                        SecurityScopes    = `$client.SecurityScopes
                        Ensure            = `$client.Ensure
                        DependsOn         = `$cmSecurityScopesDependsOn
                    }
                }
                else
                {
                    CMClientSettings `$client.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$client.ClientSettingName
                        Type              = `$client.Type
                        SecurityScopes    = `$client.SecurityScopes
                        Ensure            = `$client.Ensure
                        DependsOn         = `$cmSecurityScopesDependsOn
                    }
                }

                [array]`$cmClientSettingsDependsOn += `"[CMClientSettings]`$(`$client.ClientSettingName)`"
            }
        }

        if (`$CMClientSettingsBits)
        {
            foreach (`$bitsSetting in `$CMClientSettingsBits)
            {
                if (`$bitsSetting.EnableBitsMaxBandwidth -eq `$false)
                {
                    CMClientSettingsBits `$bitsSetting.ClientSettingName
                    {
                        SiteCode               = `$SiteCode
                        ClientSettingName      = `$bitsSetting.ClientSettingName
                        EnableBitsMaxBandwidth = `$bitsSetting.EnableBitsMaxBandwidth
                        DependsOn              = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$bitsSetting.EnableDownloadOffSchedule -eq `$false)
                {
                    CMClientSettingsBits `$bitsSetting.ClientSettingName
                    {
                        SiteCode                  = `$SiteCode
                        ClientSettingName         = `$bitsSetting.ClientSettingName
                        EnableBitsMaxBandwidth    = `$bitsSetting.EnableBitsMaxBandwidth
                        MaxBandwidthBeginHr       = `$bitsSetting.MaxBandwidthBeginHr
                        MaxBandwidthEndHr         = `$bitsSetting.MaxBandwidthEndHr
                        MaxTransferRateOnSchedule = `$bitsSetting.MaxTransferRateOnSchedule
                        EnableDownloadOffSchedule = `$bitsSetting.EnableDownloadOffSchedule
                        DependsOn                 = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsBits `$bitsSetting.ClientSettingName
                    {
                        SiteCode                   = `$SiteCode
                        ClientSettingName          = `$bitsSetting.ClientSettingName
                        EnableBitsMaxBandwidth     = `$bitsSetting.EnableBitsMaxBandwidth
                        MaxBandwidthBeginHr        = `$bitsSetting.MaxBandwidthBeginHr
                        MaxBandwidthEndHr          = `$bitsSetting.MaxBandwidthEndHr
                        MaxTransferRateOnSchedule  = `$bitsSetting.MaxTransferRateOnSchedule
                        EnableDownloadOffSchedule  = `$bitsSetting.EnableDownloadOffSchedule
                        MaxTransferRateOffSchedule = `$bitsSetting.MaxTransferRateOffSchedule
                        DependsOn                  = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsClientCache)
        {
            foreach (`$clientCache in `$CMClientSettingsClientCache)
            {
                if (`$clientCache.ConfigureBranchCache -eq `$true -and
                    `$clientCache.ConfigureCacheSize -eq `$true -and
                    `$clientCache.EnableSuperPeer -eq `$true)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode                  = `$SiteCode
                        ClientSettingName         = `$clientCache.ClientSettingName
                        ConfigureBranchCache      = `$clientCache.ConfigureBranchCache
                        EnableBranchCache         = `$clientCache.EnableBranchCache
                        MaxBranchCacheSizePercent = `$clientCache.MaxBranchCacheSizePercent
                        ConfigureCacheSize        = `$clientCache.ConfigureCacheSize
                        MaxCacheSize              = `$clientCache.MaxCacheSize
                        MaxCacheSizePercent       = `$clientCache.MaxCacheSizePercent
                        EnableSuperPeer           = `$clientCache.EnableSuperPeer
                        BroadcastPort             = `$clientCache.BroadcastPort
                        DownloadPort              = `$clientCache.DownloadPort
                        DependsOn                 = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$true -and
                       `$clientCache.ConfigureCacheSize -eq `$true -and
                       `$clientCache.EnableSuperPeer -eq `$false)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode                  = `$SiteCode
                        ClientSettingName         = `$clientCache.ClientSettingName
                        ConfigureBranchCache      = `$clientCache.ConfigureBranchCache
                        EnableBranchCache         = `$clientCache.EnableBranchCache
                        MaxBranchCacheSizePercent = `$clientCache.MaxBranchCacheSizePercent
                        ConfigureCacheSize        = `$clientCache.ConfigureCacheSize
                        MaxCacheSize              = `$clientCache.MaxCacheSize
                        MaxCacheSizePercent       = `$clientCache.MaxCacheSizePercent
                        EnableSuperPeer           = `$clientCache.EnableSuperPeer
                        DependsOn                 = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$true -and
                        `$clientCache.ConfigureCacheSize -eq `$false -and
                        `$clientCache.EnableSuperPeer -eq `$true)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode                  = `$SiteCode
                        ClientSettingName         = `$clientCache.ClientSettingName
                        ConfigureBranchCache      = `$clientCache.ConfigureBranchCache
                        EnableBranchCache         = `$clientCache.EnableBranchCache
                        MaxBranchCacheSizePercent = `$clientCache.MaxBranchCacheSizePercent
                        ConfigureCacheSize        = `$clientCache.ConfigureCacheSize
                        EnableSuperPeer           = `$clientCache.EnableSuperPeer
                        BroadcastPort             = `$clientCache.BroadcastPort
                        DownloadPort              = `$clientCache.DownloadPort
                        DependsOn                 = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$true -and
                        `$clientCache.ConfigureCacheSize -eq `$false -and
                        `$clientCache.EnableSuperPeer -eq `$false)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode                  = `$SiteCode
                        ClientSettingName         = `$clientCache.ClientSettingName
                        ConfigureBranchCache      = `$clientCache.ConfigureBranchCache
                        EnableBranchCache         = `$clientCache.EnableBranchCache
                        MaxBranchCacheSizePercent = `$clientCache.MaxBranchCacheSizePercent
                        ConfigureCacheSize        = `$clientCache.ConfigureCacheSize
                        EnableSuperPeer           = `$clientCache.EnableSuperPeer
                        DependsOn                 = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$false -and
                        `$clientCache.ConfigureCacheSize -eq `$true -and
                        `$clientCache.EnableSuperPeer -eq `$true)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode             = `$SiteCode
                        ClientSettingName    = `$clientCache.ClientSettingName
                        ConfigureBranchCache = `$clientCache.ConfigureBranchCache
                        ConfigureCacheSize   = `$clientCache.ConfigureCacheSize
                        MaxCacheSize         = `$clientCache.MaxCacheSize
                        EnableSuperPeer      = `$clientCache.EnableSuperPeer
                        BroadcastPort        = `$clientCache.BroadcastPort
                        DownloadPort         = `$clientCache.DownloadPort
                        DependsOn            = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$false -and
                        `$clientCache.ConfigureCacheSize -eq `$true -and
                        `$clientCache.EnableSuperPeer -eq `$false)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode             = `$SiteCode
                        ClientSettingName    = `$clientCache.ClientSettingName
                        ConfigureBranchCache = `$clientCache.ConfigureBranchCache
                        ConfigureCacheSize   = `$clientCache.ConfigureCacheSize
                        MaxCacheSize         = `$clientCache.MaxCacheSize
                        EnableSuperPeer      = `$clientCache.EnableSuperPeer
                        DependsOn            = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$false -and
                        `$clientCache.ConfigureCacheSize -eq `$false -and
                        `$clientCache.EnableSuperPeer -eq `$true)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode             = `$SiteCode
                        ClientSettingName    = `$clientCache.ClientSettingName
                        ConfigureBranchCache = `$clientCache.ConfigureBranchCache
                        ConfigureCacheSize   = `$clientCache.ConfigureCacheSize
                        EnableSuperPeer      = `$clientCache.EnableSuperPeer
                        BroadcastPort        = `$clientCache.BroadcastPort
                        DownloadPort         = `$clientCache.DownloadPort
                        DependsOn            = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$clientCache.ConfigureBranchCache -eq `$false -and
                        `$clientCache.ConfigureCacheSize -eq `$false -and
                        `$clientCache.EnableSuperPeer -eq `$false)
                {
                    CMClientSettingsClientCache `$clientCache.ClientSettingName
                    {
                        SiteCode             = `$SiteCode
                        ClientSettingName    = `$clientCache.ClientSettingName
                        ConfigureBranchCache = `$clientCache.ConfigureBranchCache
                        ConfigureCacheSize   = `$clientCache.ConfigureCacheSize
                        EnableSuperPeer      = `$clientCache.EnableSuperPeer
                        DependsOn            = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsClientPolicy)
        {
            foreach (`$clientPolicy in `$CMClientSettingsClientPolicy)
            {
                CMClientSettingsClientPolicy `$clientPolicy.ClientSettingName
                {
                    SiteCode                   = `$SiteCode
                    ClientSettingName          = `$clientPolicy.ClientSettingName
                    PolicyPollingMins          = `$clientPolicy.PolicyPollingMins
                    EnableUserPolicy           = `$clientPolicy.EnableUserPolicy
                    EnableUserPolicyOnInternet = `$clientPolicy.EnableUserPolicyOnInternet
                    EnableUserPolicyOnTS       = `$clientPolicy.EnableUserPolicyOnTS
                    DependsOn                  = `$cmClientSettingsDependsOn
                }
            }
        }

        if (`$CMClientSettingsCloudService)
        {
            foreach (`$cloudService in `$CMClientSettingsCloudService)
            {
                if ([string]::IsNullOrEmpty(`$cloudService.AutoAzureADJoin))
                {
                    CMClientSettingsCloudService `$cloudService.ClientSettingName
                    {
                        SiteCode                    = `$SiteCode
                        ClientSettingName           = `$cloudService.ClientSettingName
                        AllowCloudDistributionPoint = `$cloudService.AllowCloudDistributionPoint
                        DependsOn                   = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsCloudService `$cloudService.ClientSettingName
                    {
                        SiteCode                    = `$SiteCode
                        ClientSettingName           = `$cloudService.ClientSettingName
                        AllowCloudDistributionPoint = `$cloudService.AllowCloudDistributionPoint
                        AutoAzureADJoin             = `$cloudService.AutoAzureADJoin
                        AllowCloudManagementGateway = `$cloudService.AllowCloudManagementGateway
                        DependsOn                   = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsCompliance)
        {
            foreach (`$complianceSetting in `$CMClientSettingsCompliance)
            {
                if (`$complianceSetting.Enable -eq `$false)
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$complianceSetting.ClientSettingName
                        Enable            = `$complianceSetting.Enable
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif ([string]::IsNullOrEmpty(`$complianceSetting.ScheduleType))
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$complianceSetting.ScheduleType -eq 'MonthlyByDay')
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        Start                    = `$complianceSetting.Start
                        ScheduleType             = `$complianceSetting.ScheduleType
                        RecurInterval            = `$complianceSetting.RecurInterval
                        DayOfMonth               = `$complianceSetting.DayOfMonth
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$complianceSetting.ScheduleType -eq 'MonthlyByWeek')
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        Start                    = `$complianceSetting.Start
                        ScheduleType             = `$complianceSetting.ScheduleType
                        RecurInterval            = `$complianceSetting.RecurInterval
                        DayOfWeek                = `$complianceSetting.DayOfWeek
                        MonthlyWeekOrder         = `$complianceSetting.MonthlyWeekOrder
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$complianceSetting.ScheduleType -eq 'Weekly')
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        Start                    = `$complianceSetting.Start
                        ScheduleType             = `$complianceSetting.ScheduleType
                        RecurInterval            = `$complianceSetting.RecurInterval
                        DayOfWeek                = `$complianceSetting.DayOfWeek
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$complianceSetting.ScheduleType -eq 'None')
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        Start                    = `$complianceSetting.Start
                        ScheduleType             = `$complianceSetting.ScheduleType
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsCompliance `$complianceSetting.ClientSettingName
                    {
                        SiteCode                 = `$SiteCode
                        ClientSettingName        = `$complianceSetting.ClientSettingName
                        Enable                   = `$complianceSetting.Enable
                        EnableUserDataAndProfile = `$complianceSetting.EnableUserDataAndProfile
                        Start                    = `$complianceSetting.Start
                        ScheduleType             = `$complianceSetting.ScheduleType
                        RecurInterval            = `$complianceSetting.RecurInterval
                        DependsOn                = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsComputerAgent)
        {
            foreach (`$agent in `$CMClientSettingsComputerAgent)
            {
                if (`$agent.EnableHealthAttestation -eq `$true)
                {
                    CMClientSettingsComputerAgent `$agent.ClientSettingName
                    {
                        SiteCode                       = `$SiteCode
                        ClientSettingName              = `$agent.ClientSettingName
                        InitialReminderHr              = `$agent.InitialReminderHr
                        InterimReminderHr              = `$agent.InterimReminderHr
                        FinalReminderMins              = `$agent.FinalReminderMins
                        BrandingTitle                  = `$agent.BrandingTitle
                        UseNewSoftwareCenter           = `$agent.UseNewSoftwareCenter
                        EnableHealthAttestation        = `$agent.EnableHealthAttestation
                        UseOnPremisesHealthAttestation = `$agent.UseOnPremisesHealthAttestation
                        InstallRestriction             = `$agent.InstallRestriction
                        SuspendBitLocker               = `$agent.SuspendBitLocker
                        EnableThirdPartyOrchestration  = `$agent.EnableThirdPartyOrchestration
                        PowerShellExecutionPolicy      = `$agent.PowerShellExecutionPolicy
                        DisplayNewProgramNotification  = `$agent.DisplayNewProgramNotification
                        DependsOn                      = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsComputerAgent `$agent.ClientSettingName
                    {
                        SiteCode                       = `$SiteCode
                        ClientSettingName              = `$agent.ClientSettingName
                        InitialReminderHr              = `$agent.InitialReminderHr
                        InterimReminderHr              = `$agent.InterimReminderHr
                        FinalReminderMins              = `$agent.FinalReminderMins
                        BrandingTitle                  = `$agent.BrandingTitle
                        UseNewSoftwareCenter           = `$agent.UseNewSoftwareCenter
                        EnableHealthAttestation        = `$agent.EnableHealthAttestation
                        InstallRestriction             = `$agent.InstallRestriction
                        SuspendBitLocker               = `$agent.SuspendBitLocker
                        EnableThirdPartyOrchestration  = `$agent.EnableThirdPartyOrchestration
                        PowerShellExecutionPolicy      = `$agent.PowerShellExecutionPolicy
                        DisplayNewProgramNotification  = `$agent.DisplayNewProgramNotification
                        DependsOn                      = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsDelivery)
        {
            foreach (`$settingsDelivery in `$CMClientSettingsDelivery)
            {
                CMClientSettingsDelivery `$settingsDelivery.ClientSettingName
                {
                    SiteCode          = `$SiteCode
                    ClientSettingName = `$settingsDelivery.ClientSettingName
                    Enable            = `$settingsDelivery.Enable
                    DependsOn         = `$cmClientSettingsDependsOn
                }
            }
        }

        if (`$CMClientSettingsHardware)
        {
            foreach (`$hardwareSetting in `$CMClientSettingsHardware)
            {
                if (`$hardwareSetting.Enable -eq `$false)
                {
                    CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$hardwareSetting.ClientSettingName
                        Enable            = `$hardwareSetting.Enable
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$hardwareSetting.CollectMifFile)
                {
                    if (`$hardwareSetting.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode             = `$SiteCode
                            ClientSettingName    = `$hardwareSetting.ClientSettingName
                            Enable               = `$hardwareSetting.Enable
                            MaxRandomDelayMins   = `$hardwareSetting.MaxRandomDelayMins
                            Start                = `$hardwareSetting.Start
                            ScheduleType         = `$hardwareSetting.ScheduleType
                            RecurInterval        = `$hardwareSetting.RecurInterval
                            DayOfMonth           = `$hardwareSetting.DayOfMonth
                            CollectMifFile       = `$hardwareSetting.CollectMifFile
                            MaxThirdPartyMifSize = `$hardwareSetting.MaxThirdPartyMifSize
                            DependsOn            = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode             = `$SiteCode
                            ClientSettingName    = `$hardwareSetting.ClientSettingName
                            Enable               = `$hardwareSetting.Enable
                            MaxRandomDelayMins   = `$hardwareSetting.MaxRandomDelayMins
                            Start                = `$hardwareSetting.Start
                            ScheduleType         = `$hardwareSetting.ScheduleType
                            RecurInterval        = `$hardwareSetting.RecurInterval
                            DayOfWeek            = `$hardwareSetting.DayOfWeek
                            MonthlyWeekOrder     = `$hardwareSetting.MonthlyWeekOrder
                            CollectMifFile       = `$hardwareSetting.CollectMifFile
                            MaxThirdPartyMifSize = `$hardwareSetting.MaxThirdPartyMifSize
                            DependsOn            = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'Weekly')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode             = `$SiteCode
                            ClientSettingName    = `$hardwareSetting.ClientSettingName
                            Enable               = `$hardwareSetting.Enable
                            MaxRandomDelayMins   = `$hardwareSetting.MaxRandomDelayMins
                            Start                = `$hardwareSetting.Start
                            ScheduleType         = `$hardwareSetting.ScheduleType
                            RecurInterval        = `$hardwareSetting.RecurInterval
                            DayOfWeek            = `$hardwareSetting.DayOfWeek
                            CollectMifFile       = `$hardwareSetting.CollectMifFile
                            MaxThirdPartyMifSize = `$hardwareSetting.MaxThirdPartyMifSize
                            DependsOn            = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'None')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode             = `$SiteCode
                            ClientSettingName    = `$hardwareSetting.ClientSettingName
                            Enable               = `$hardwareSetting.Enable
                            MaxRandomDelayMins   = `$hardwareSetting.MaxRandomDelayMins
                            Start                = `$hardwareSetting.Start
                            ScheduleType         = `$hardwareSetting.ScheduleType
                            CollectMifFile       = `$hardwareSetting.CollectMifFile
                            MaxThirdPartyMifSize = `$hardwareSetting.MaxThirdPartyMifSize
                            DependsOn            = `$cmClientSettingsDependsOn
                        }
                    }
                    else
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode             = `$SiteCode
                            ClientSettingName    = `$hardwareSetting.ClientSettingName
                            Enable               = `$hardwareSetting.Enable
                            MaxRandomDelayMins   = `$hardwareSetting.MaxRandomDelayMins
                            Start                = `$hardwareSetting.Start
                            ScheduleType         = `$hardwareSetting.ScheduleType
                            RecurInterval        = `$hardwareSetting.RecurInterval
                            CollectMifFile       = `$hardwareSetting.CollectMifFile
                            MaxThirdPartyMifSize = `$hardwareSetting.MaxThirdPartyMifSize
                            DependsOn            = `$cmClientSettingsDependsOn
                        }
                    }
                }
                else
                {
                    if (`$hardwareSetting.ScheduleType -eq 'MonthlyByDay')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode           = `$SiteCode
                            ClientSettingName  = `$hardwareSetting.ClientSettingName
                            Enable             = `$hardwareSetting.Enable
                            MaxRandomDelayMins = `$hardwareSetting.MaxRandomDelayMins
                            Start              = `$hardwareSetting.Start
                            ScheduleType       = `$hardwareSetting.ScheduleType
                            RecurInterval      = `$hardwareSetting.RecurInterval
                            DayOfMonth         = `$hardwareSetting.DayOfMonth
                            DependsOn          = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'MonthlyByWeek')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode           = `$SiteCode
                            ClientSettingName  = `$hardwareSetting.ClientSettingName
                            Enable             = `$hardwareSetting.Enable
                            MaxRandomDelayMins = `$hardwareSetting.MaxRandomDelayMins
                            Start              = `$hardwareSetting.Start
                            ScheduleType       = `$hardwareSetting.ScheduleType
                            RecurInterval      = `$hardwareSetting.RecurInterval
                            DayOfWeek          = `$hardwareSetting.DayOfWeek
                            MonthlyWeekOrder   = `$hardwareSetting.MonthlyWeekOrder
                            DependsOn          = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'Weekly')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode           = `$SiteCode
                            ClientSettingName  = `$hardwareSetting.ClientSettingName
                            Enable             = `$hardwareSetting.Enable
                            MaxRandomDelayMins = `$hardwareSetting.MaxRandomDelayMins
                            Start              = `$hardwareSetting.Start
                            ScheduleType       = `$hardwareSetting.ScheduleType
                            RecurInterval      = `$hardwareSetting.RecurInterval
                            DayOfWeek          = `$hardwareSetting.DayOfWeek
                            DependsOn          = `$cmClientSettingsDependsOn
                        }
                    }
                    elseif (`$hardwareSetting.ScheduleType -eq 'None')
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode           = `$SiteCode
                            ClientSettingName  = `$hardwareSetting.ClientSettingName
                            Enable             = `$hardwareSetting.Enable
                            MaxRandomDelayMins = `$hardwareSetting.MaxRandomDelayMins
                            Start              = `$hardwareSetting.Start
                            ScheduleType       = `$hardwareSetting.ScheduleType
                            DependsOn          = `$cmClientSettingsDependsOn
                        }
                    }
                    else
                    {
                        CMClientSettingsHardware `$hardwareSetting.ClientSettingName
                        {
                            SiteCode           = `$SiteCode
                            ClientSettingName  = `$hardwareSetting.ClientSettingName
                            Enable             = `$hardwareSetting.Enable
                            MaxRandomDelayMins = `$hardwareSetting.MaxRandomDelayMins
                            Start              = `$hardwareSetting.Start
                            ScheduleType       = `$hardwareSetting.ScheduleType
                            RecurInterval      = `$hardwareSetting.RecurInterval
                            DependsOn          = `$cmClientSettingsDependsOn
                        }
                    }
                }
            }
        }

        if (`$CMClientSettingsMetered)
        {
            foreach (`$settingsMetered in `$CMClientSettingsMetered)
            {
                CMClientSettingsMetered `$settingsMetered.ClientSettingName
                {
                    SiteCode            = `$SiteCode
                    ClientSettingName   = `$settingsMetered.ClientSettingName
                    MeteredNetworkUsage = `$settingsMetered.MeteredNetworkUsage
                    DependsOn           = `$cmClientSettingsDependsOn
                }
            }
        }

        if (`$CMClientSettingsSoftwareDeployment)
        {
            foreach (`$softwareDeploy in `$CMClientSettingsSoftwareDeployment)
            {
                if (`$softwareDeploy.ScheduleType -eq 'MonthlyByDay')
                {
                    CMClientSettingsSoftwareDeployment `$softwareDeploy.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareDeploy.ClientSettingName
                        Start             = `$softwareDeploy.Start
                        ScheduleType      = `$softwareDeploy.ScheduleType
                        RecurInterval     = `$softwareDeploy.RecurInterval
                        DayOfMonth        = `$softwareDeploy.DayOfMonth
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softwareDeploy.ScheduleType -eq 'MonthlyByWeek')
                {
                    CMClientSettingsSoftwareDeployment `$softwareDeploy.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareDeploy.ClientSettingName
                        Start             = `$softwareDeploy.Start
                        ScheduleType      = `$softwareDeploy.ScheduleType
                        RecurInterval     = `$softwareDeploy.RecurInterval
                        DayOfWeek         = `$softwareDeploy.DayOfWeek
                        MonthlyWeekOrder  = `$softwareDeploy.MonthlyWeekOrder
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softwareDeploy.ScheduleType -eq 'Weekly')
                {
                    CMClientSettingsSoftwareDeployment `$softwareDeploy.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareDeploy.ClientSettingName
                        Start             = `$softwareDeploy.Start
                        ScheduleType      = `$softwareDeploy.ScheduleType
                        RecurInterval     = `$softwareDeploy.RecurInterval
                        DayOfWeek         = `$softwareDeploy.DayOfWeek
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softwareDeploy.ScheduleType -eq 'None')
                {
                    CMClientSettingsSoftwareDeployment `$softwareDeploy.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareDeploy.ClientSettingName
                        Start             = `$softwareDeploy.Start
                        ScheduleType      = `$softwareDeploy.ScheduleType
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsSoftwareDeployment `$softwareDeploy.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareDeploy.ClientSettingName
                        Start             = `$softwareDeploy.Start
                        ScheduleType      = `$softwareDeploy.ScheduleType
                        RecurInterval     = `$softwareDeploy.RecurInterval
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsSoftwareInventory)
        {
            foreach (`$softInvenSetting in `$CMClientSettingsSoftwareInventory)
            {
                if (`$softInvenSetting.Enable -eq `$false)
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softInvenSetting.ScheduleType -eq 'MonthlyByDay')
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        ReportOption      = `$softInvenSetting.ReportOption
                        Start             = `$softInvenSetting.Start
                        ScheduleType      = `$softInvenSetting.ScheduleType
                        RecurInterval     = `$softInvenSetting.RecurInterval
                        DayOfMonth        = `$softInvenSetting.DayOfMonth
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softInvenSetting.ScheduleType -eq 'MonthlyByWeek')
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        ReportOption      = `$softInvenSetting.ReportOption
                        Start             = `$softInvenSetting.Start
                        ScheduleType      = `$softInvenSetting.ScheduleType
                        RecurInterval     = `$softInvenSetting.RecurInterval
                        DayOfWeek         = `$softInvenSetting.DayOfWeek
                        MonthlyWeekOrder  = `$softInvenSetting.MonthlyWeekOrder
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softInvenSetting.ScheduleType -eq 'Weekly')
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        ReportOption      = `$softInvenSetting.ReportOption
                        Start             = `$softInvenSetting.Start
                        ScheduleType      = `$softInvenSetting.ScheduleType
                        RecurInterval     = `$softInvenSetting.RecurInterval
                        DayOfWeek         = `$softInvenSetting.DayOfWeek
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softInvenSetting.ScheduleType -eq 'None')
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        ReportOption      = `$softInvenSetting.ReportOption
                        Start             = `$softInvenSetting.Start
                        ScheduleType      = `$softInvenSetting.ScheduleType
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsSoftwareInventory `$softInvenSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softInvenSetting.ClientSettingName
                        Enable            = `$softInvenSetting.Enable
                        ReportOption      = `$softInvenSetting.ReportOption
                        Start             = `$softInvenSetting.Start
                        ScheduleType      = `$softInvenSetting.ScheduleType
                        RecurInterval     = `$softInvenSetting.RecurInterval
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsSoftwareMetering)
        {
            foreach (`$softMetSetting in `$CMClientSettingsSoftwareMetering)
            {
                if (`$softMetSetting.Enable -eq `$false)
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softMetSetting.ScheduleType -eq 'MonthlyByDay')
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        Start             = `$softMetSetting.Start
                        ScheduleType      = `$softMetSetting.ScheduleType
                        RecurInterval     = `$softMetSetting.RecurInterval
                        DayOfMonth        = `$softMetSetting.DayOfMonth
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softMetSetting.ScheduleType -eq 'MonthlyByWeek')
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        Start             = `$softMetSetting.Start
                        ScheduleType      = `$softMetSetting.ScheduleType
                        RecurInterval     = `$softMetSetting.RecurInterval
                        DayOfWeek         = `$softMetSetting.DayOfWeek
                        MonthlyWeekOrder  = `$softMetSetting.MonthlyWeekOrder
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softMetSetting.ScheduleType -eq 'Weekly')
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        Start             = `$softMetSetting.Start
                        ScheduleType      = `$softMetSetting.ScheduleType
                        RecurInterval     = `$softMetSetting.RecurInterval
                        DayOfWeek         = `$softMetSetting.DayOfWeek
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$softMetSetting.ScheduleType -eq 'None')
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        Start             = `$softMetSetting.Start
                        ScheduleType      = `$softMetSetting.ScheduleType
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsSoftwareMetering `$softMetSetting.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softMetSetting.ClientSettingName
                        Enable            = `$softMetSetting.Enable
                        Start             = `$softMetSetting.Start
                        ScheduleType      = `$softMetSetting.ScheduleType
                        RecurInterval     = `$softMetSetting.RecurInterval
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsSoftwareUpdate)
        {
            foreach (`$update in `$CMClientSettingsSoftwareUpdate)
            {
                if (`$update.Enable -eq `$false)
                {
                    CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$update.ClientSettingName
                        Enable            = `$update.Enable
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$update.EnforceMandatory -eq `$true -and `$update.EnableDeltaDownload -eq `$true)
                {
                    if (`$update.ScanScheduleType -eq 'MonthlyByDay')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'MonthlyByWeek')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'Weekly')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'None')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
                elseif (`$update.EnforceMandatory -eq `$true -and `$update.EnableDeltaDownload -eq `$false)
                {
                    if (`$update.ScanScheduleType -eq 'MonthlyByDay')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'MonthlyByWeek')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'Weekly')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'None')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                TimeUnit                = `$update.TimeUnit
                                BatchingTimeOut         = `$update.BatchingTimeOut
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
                elseif (`$update.EnforceMandatory -eq `$false -and `$update.EnableDeltaDownload -eq `$true)
                {
                    if (`$update.ScanScheduleType -eq 'MonthlyByDay')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'MonthlyByWeek')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'Weekly')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'None')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                DeltaDownloadPort       = `$update.DeltaDownloadPort
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
                elseif (`$update.EnforceMandatory -eq `$false -and `$update.EnableDeltaDownload -eq `$false)
                {
                    if (`$update.ScanScheduleType -eq 'MonthlyByDay')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfMonth          = `$update.ScanDayOfMonth
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'MonthlyByWeek')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                ScanMonthlyWeekOrder    = `$update.ScanMonthlyWeekOrder
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'Weekly')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                ScanDayOfWeek           = `$update.ScanDayOfWeek
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    elseif (`$update.ScanScheduleType -eq 'None')
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$update.EvalScheduleType -eq 'MonthlyByDay')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfMonth          = `$update.EvalDayOfMonth
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'MonthlyByWeek')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EvalMonthlyWeekOrder    = `$update.MonthlyWeekOrder
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'Weekly')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EvalDayOfWeek           = `$update.EvalDayOfWeek
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        elseif (`$update.EvalScheduleType -eq 'None')
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsSoftwareUpdate `$update.ClientSettingName
                            {
                                SiteCode                = `$SiteCode
                                ClientSettingName       = `$update.ClientSettingName
                                Enable                  = `$update.Enable
                                ScanStart               = `$update.ScanStart
                                ScanScheduleType        = `$update.ScanScheduleType
                                ScanRecurInterval       = `$update.ScanRecurInterval
                                EvalStart               = `$update.EvalStart
                                EvalScheduleType        = `$update.EvalScheduleType
                                EvalRecurInterval       = `$update.EvalRecurInterval
                                EnforceMandatory        = `$update.EnforceMandatory
                                EnableDeltaDownload     = `$update.EnableDeltaDownload
                                Office365ManagementType = `$update.Office365ManagementType
                                EnableThirdPartyUpdates = `$update.EnableThirdPartyUpdates
                                DependsOn               = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
            }
        }

        if (`$CMClientSettingsPower)
        {
            foreach (`$powerSetting in `$CMClientSettingsPower)
            {
                if (`$powerSetting.NetworkWakeupOption -ne 'Enabled' -and `$powerSetting.EnableWakeupProxy -eq `$false)
                {
                    CMClientSettingsPower `$powerSetting.ClientSettingName
                    {
                        SiteCode                       = `$SiteCode
                        ClientSettingName              = `$powerSetting.ClientSettingName
                        Enable                         = `$powerSetting.Enable
                        AllowUserToOptOutFromPowerPlan = `$powerSetting.AllowUserToOptOutFromPowerPlan
                        NetworkWakeupOption            = `$powerSetting.NetworkWakeupOption
                        EnableWakeupProxy              = `$powerSetting.EnableWakeupProxy
                        DependsOn                      = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$powerSetting.WakeupProxyDirectAccessPrefix)
                {
                    CMClientSettingsPower `$powerSetting.ClientSettingName
                    {
                        SiteCode                        = `$SiteCode
                        ClientSettingName               = `$powerSetting.ClientSettingName
                        Enable                          = `$powerSetting.Enable
                        AllowUserToOptOutFromPowerPlan  = `$powerSetting.AllowUserToOptOutFromPowerPlan
                        NetworkWakeupOption             = `$powerSetting.NetworkWakeupOption
                        EnableWakeupProxy               = `$powerSetting.EnableWakeupProxy
                        FirewallExceptionForWakeupProxy = `$powerSetting.FirewallExceptionForWakeupProxy
                        WakeupProxyDirectAccessPrefix   = `$powerSetting.WakeupProxyDirectAccessPrefix
                        WakeupProxyPort                 = `$powerSetting.WakeupProxyPort
                        WakeOnLanPort                   = `$powerSetting.WakeOnLanPort
                        DependsOn                       = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsPower `$powerSetting.ClientSettingName
                    {
                        SiteCode                        = `$SiteCode
                        ClientSettingName               = `$powerSetting.ClientSettingName
                        Enable                          = `$powerSetting.Enable
                        AllowUserToOptOutFromPowerPlan  = `$powerSetting.AllowUserToOptOutFromPowerPlan
                        NetworkWakeupOption             = `$powerSetting.NetworkWakeupOption
                        EnableWakeupProxy               = `$powerSetting.EnableWakeupProxy
                        FirewallExceptionForWakeupProxy = `$powerSetting.FirewallExceptionForWakeupProxy
                        WakeupProxyPort                 = `$powerSetting.WakeupProxyPort
                        WakeOnLanPort                   = `$powerSetting.WakeOnLanPort
                        DependsOn                       = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsRemoteTools)
        {
            foreach (`$remoteTool in `$CMClientSettingsRemoteTools)
            {
                if (`$remoteTool.ManageRemoteDesktopSetting -eq `$true)
                {
                    if (`$remoteTool.PermittedViewer)
                    {
                        if (`$remoteTool.FirewallExceptionProfile)
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                FirewallExceptionProfile            = `$remoteTool.FirewallExceptionProfile
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                PermittedViewer                     = `$remoteTool.PermittedViewer
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                AllowPermittedViewer                = `$remoteTool.AllowPermittedViewer
                                RequireAuthentication               = `$remoteTool.RequireAuthentication
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                PermittedViewer                     = `$remoteTool.PermittedViewer
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                AllowPermittedViewer                = `$remoteTool.AllowPermittedViewer
                                RequireAuthentication               = `$remoteTool.RequireAuthentication
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$remoteTool.FirewallExceptionProfile)
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                FirewallExceptionProfile            = `$remoteTool.FirewallExceptionProfile
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                PermittedViewer                     = `$remoteTool.PermittedViewer
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                AllowPermittedViewer                = `$remoteTool.AllowPermittedViewer
                                RequireAuthentication               = `$remoteTool.RequireAuthentication
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                PermittedViewer                     = `$remoteTool.PermittedViewer
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                AllowPermittedViewer                = `$remoteTool.AllowPermittedViewer
                                RequireAuthentication               = `$remoteTool.RequireAuthentication
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
                else
                {
                    if (`$remoteTool.PermittedViewer)
                    {
                        if (`$remoteTool.FirewallExceptionProfile)
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                FirewallExceptionProfile            = `$remoteTool.FirewallExceptionProfile
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                    else
                    {
                        if (`$remoteTool.FirewallExceptionProfile)
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                FirewallExceptionProfile            = `$remoteTool.FirewallExceptionProfile
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                        else
                        {
                            CMClientSettingsRemoteTools `$remoteTool.ClientSettingName
                            {
                                SiteCode                            = `$SiteCode
                                ClientSettingName                   = `$remoteTool.ClientSettingName
                                AllowClientChange                   = `$remoteTool.AllowClientChange
                                AllowUnattendedComputer             = `$remoteTool.AllowUnattendedComputer
                                PromptUserForPermission             = `$remoteTool.PromptUserForPermission
                                PromptUserForClipboardPermission    = `$remoteTool.PromptUserForClipboardPermission
                                GrantPermissionToLocalAdministrator = `$remoteTool.GrantPermissionToLocalAdministrator
                                AccessLevel                         = `$remoteTool.AccessLevel
                                ShowNotificationIconOnTaskbar       = `$remoteTool.ShowNotificationIconOnTaskbar
                                ShowSessionConnectionBar            = `$remoteTool.ShowSessionConnectionBar
                                AudibleSignal                       = `$remoteTool.AudibleSignal
                                ManageUnsolicitedRemoteAssistance   = `$remoteTool.ManageUnsolicitedRemoteAssistance
                                ManageSolicitedRemoteAssistance     = `$remoteTool.ManageSolicitedRemoteAssistance
                                RemoteAssistanceAccessLevel         = `$remoteTool.RemoteAssistanceAccessLevel
                                ManageRemoteDesktopSetting          = `$remoteTool.ManageRemoteDesktopSetting
                                DependsOn                           = `$cmClientSettingsDependsOn
                            }
                        }
                    }
                }
            }
        }

        if (`$CMClientSettingsSoftwareCenter)
        {
            foreach (`$softwareCenter in `$CMClientSettingsSoftwareCenter)
            {
                if (`$softwareCenter.EnableCustomize -eq `$false)
                {
                    CMClientSettingsSoftwareCenter `$softwareCenter.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$softwareCenter.ClientSettingName
                        EnableCustomize   = `$softwareCenter.EnableCustomize
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
                elseif ([string]::IsNullOrEmpty(`$softwareCenter.CompanyName) -and
                        [string]::IsNullOrEmpty(`$softwareCenter.ColorScheme))
                {
                    CMClientSettingsSoftwareCenter `$softwareCenter.ClientSettingName
                    {
                        SiteCode                   = `$SiteCode
                        ClientSettingName          = `$softwareCenter.ClientSettingName
                        EnableCustomize            = `$softwareCenter.EnableCustomize
                        HideApplicationCatalogLink = `$softwareCenter.HideApplicationCatalogLink
                        HideInstalledApplication   = `$softwareCenter.HideInstalledApplication
                        HideUnapprovedApplication  = `$softwareCenter.HideUnapprovedApplication
                        EnableApplicationsTab      = `$softwareCenter.EnableApplicationsTab
                        EnableUpdatesTab           = `$softwareCenter.EnableUpdatesTab
                        EnableOperatingSystemsTab  = `$softwareCenter.EnableOperatingSystemsTab
                        EnableStatusTab            = `$softwareCenter.EnableStatusTab
                        EnableComplianceTab        = `$softwareCenter.EnableComplianceTab
                        EnableOptionsTab           = `$softwareCenter.EnableOptionsTab
                        DependsOn                  = `$cmClientSettingsDependsOn
                    }
                }
                elseif ([string]::IsNullOrEmpty(`$softwareCenter.CompanyName))
                {
                    CMClientSettingsSoftwareCenter `$softwareCenter.ClientSettingName
                    {
                        SiteCode                   = `$SiteCode
                        ClientSettingName          = `$softwareCenter.ClientSettingName
                        EnableCustomize            = `$softwareCenter.EnableCustomize
                        ColorScheme                = `$softwareCenter.ColorScheme
                        HideApplicationCatalogLink = `$softwareCenter.HideApplicationCatalogLink
                        HideInstalledApplication   = `$softwareCenter.HideInstalledApplication
                        HideUnapprovedApplication  = `$softwareCenter.HideUnapprovedApplication
                        EnableApplicationsTab      = `$softwareCenter.EnableApplicationsTab
                        EnableUpdatesTab           = `$softwareCenter.EnableUpdatesTab
                        EnableOperatingSystemsTab  = `$softwareCenter.EnableOperatingSystemsTab
                        EnableStatusTab            = `$softwareCenter.EnableStatusTab
                        EnableComplianceTab        = `$softwareCenter.EnableComplianceTab
                        EnableOptionsTab           = `$softwareCenter.EnableOptionsTab
                        DependsOn                  = `$cmClientSettingsDependsOn
                    }
                }
                elseif ([string]::IsNullOrEmpty(`$softwareCenter.ColorScheme))
                {
                    CMClientSettingsSoftwareCenter `$softwareCenter.ClientSettingName
                    {
                        SiteCode                   = `$SiteCode
                        ClientSettingName          = `$softwareCenter.ClientSettingName
                        EnableCustomize            = `$softwareCenter.EnableCustomize
                        CompanyName                = `$softwareCenter.CompanyName
                        HideApplicationCatalogLink = `$softwareCenter.HideApplicationCatalogLink
                        HideInstalledApplication   = `$softwareCenter.HideInstalledApplication
                        HideUnapprovedApplication  = `$softwareCenter.HideUnapprovedApplication
                        EnableApplicationsTab      = `$softwareCenter.EnableApplicationsTab
                        EnableUpdatesTab           = `$softwareCenter.EnableUpdatesTab
                        EnableOperatingSystemsTab  = `$softwareCenter.EnableOperatingSystemsTab
                        EnableStatusTab            = `$softwareCenter.EnableStatusTab
                        EnableComplianceTab        = `$softwareCenter.EnableComplianceTab
                        EnableOptionsTab           = `$softwareCenter.EnableOptionsTab
                        DependsOn                  = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsSoftwareCenter `$softwareCenter.ClientSettingName
                    {
                        SiteCode                   = `$SiteCode
                        ClientSettingName          = `$softwareCenter.ClientSettingName
                        EnableCustomize            = `$softwareCenter.EnableCustomize
                        CompanyName                = `$softwareCenter.CompanyName
                        ColorScheme                = `$softwareCenter.ColorScheme
                        HideApplicationCatalogLink = `$softwareCenter.HideApplicationCatalogLink
                        HideInstalledApplication   = `$softwareCenter.HideInstalledApplication
                        HideUnapprovedApplication  = `$softwareCenter.HideUnapprovedApplication
                        EnableApplicationsTab      = `$softwareCenter.EnableApplicationsTab
                        EnableUpdatesTab           = `$softwareCenter.EnableUpdatesTab
                        EnableOperatingSystemsTab  = `$softwareCenter.EnableOperatingSystemsTab
                        EnableStatusTab            = `$softwareCenter.EnableStatusTab
                        EnableComplianceTab        = `$softwareCenter.EnableComplianceTab
                        EnableOptionsTab           = `$softwareCenter.EnableOptionsTab
                        DependsOn                  = `$cmClientSettingsDependsOn
                    }
                }
            }
        }

        if (`$CMClientSettingsStateMessaging)
        {
            foreach (`$stateMessage in `$CMClientSettingsStateMessaging)
            {
                CMClientSettingsStateMessaging `$stateMessage.ClientSettingName
                {
                    SiteCode           = `$SiteCode
                    ClientSettingName  = `$stateMessage.ClientSettingName
                    ReportingCycleMins = `$stateMessage.ReportingCycleMins
                    DependsOn          = `$cmClientSettingsDependsOn
                }
            }
        }

        if (`$CMClientSettingsUserDeviceAffinity)
        {
            foreach (`$udAffinity in `$CMClientSettingsUserDeviceAffinity)
            {
                if (`$udAffinity.LogOnThresholdMins -and `$udAffinity.AllowUserAffinity)
                {
                    CMClientSettingsUserDeviceAffinity `$udAffinity.ClientSettingName
                    {
                        SiteCode            = `$SiteCode
                        ClientSettingName   = `$udAffinity.ClientSettingName
                        LogOnThresholdMins  = `$udAffinity.LogOnThresholdMins
                        UsageThresholdDays  = `$udAffinity.UsageThresholdDays
                        AutoApproveAffinity = `$udAffinity.AutoApproveAffinity
                        AllowUserAffinity   = `$udAffinity.AllowUserAffinity
                        DependsOn           = `$cmClientSettingsDependsOn
                    }
                }
                elseif (`$udAffinity.LogOnThresholdMins)
                {
                    CMClientSettingsUserDeviceAffinity `$udAffinity.ClientSettingName
                    {
                        SiteCode            = `$SiteCode
                        ClientSettingName   = `$udAffinity.ClientSettingName
                        LogOnThresholdMins  = `$udAffinity.LogOnThresholdMins
                        UsageThresholdDays  = `$udAffinity.UsageThresholdDays
                        AutoApproveAffinity = `$udAffinity.AutoApproveAffinity
                        DependsOn           = `$cmClientSettingsDependsOn
                    }
                }
                else
                {
                    CMClientSettingsUserDeviceAffinity `$udAffinity.ClientSettingName
                    {
                        SiteCode          = `$SiteCode
                        ClientSettingName = `$udAffinity.ClientSettingName
                        AllowUserAffinity = `$udAffinity.AllowUserAffinity
                        DependsOn         = `$cmClientSettingsDependsOn
                    }
                }
            }
        }
    }
}

`$cd = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = `$true
            PSDscAllowDomainUser        = `$true
        }
    )
}

ConfigureSccm -OutputPath $MofOutPutPath -ConfigurationData `$cd -DataFile $DataFile
"
}

<#
    .SYNOPSIS
        This will create the data file and\or configuration.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Include
        Specifies which resources will be invoked, default setting: All.

    .PARAMETER Exclude
        Specifies which resources will be excluded from being evaluated.

    .PARAMETER DataFile
        Specifies where the data file will be saved.

    .PARAMETER ConfigOutputPath
        Specifies where the configuration file will be saved.

    .PARAMETER MofOutPutPath
        Specifies where the mof file will be saved when running the configuration.
#>
function Set-ConfigMgrCBDscReverse
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [ValidateSet('All','Accounts','AdministrativeUser','AssetIntelligencePoint','BoundaryGroups',
            'ClientPush','ClientStatusSettings','CollectionEvaluationComponent','Collections',
            'DistributionGroups','DistributionPoint','DistributionPointGroupMembers',
            'EmailNotificationComponent','FallbackPoints','ForestDiscovery','HeartbeatDiscovery',
            'MaintenanceWindow','ManagementPoint','NetworkDiscovery','PullDistributionPoint',
            'PxeDistributionPoint','ReportingServicesPoint','SecurityScopes','ServiceConnection',
            'SiteMaintenance','SiteSystemServer','SoftwareDistributionComponent','SoftwareupdatePoint',
            'StatusReportingComponent','SystemDiscovery','UserDiscovery','ConfigFileOnly','GroupDiscovery',
            'SoftwareUpdatePointComponent','ClientSettings','ClientSettingsBits',
            'ClientSettingsClientCache','ClientSettingsClientPolicy','ClientSettingsCloudService',
            'ClientSettingsCompliance','ClientSettingsComputerAgent','ClientSettingsDelivery',
            'ClientSettingsHardware','ClientSettingsMetered','ClientSettingsPower',
            'ClientSettingsRemoteTools','ClientSettingsSoftwareCenter','ClientSettingsSoftwareDeployment',
            'ClientSettingsSoftwareInventory','ClientSettingsSoftwareMetering','ClientSettingsSoftwareUpdate',
            'ClientSettingsStateMessaging','ClientSettingsUserDeviceAffinity','SiteConfiguration')]
        [String[]]
        $Include = 'All',

        [Parameter()]
        [ValidateSet('Accounts','AdministrativeUser','AssetIntelligencePoint','BoundaryGroups',
            'ClientPush','ClientStatusSettings','CollectionEvaluationComponent','Collections',
            'DistributionGroups','DistributionPoint','DistributionPointGroupMembers',
            'EmailNotificationComponent','FallbackPoints','ForestDiscovery','HeartbeatDiscovery',
            'MaintenanceWindow','ManagementPoint','NetworkDiscovery','PullDistributionPoint',
            'PxeDistributionPoint','ReportingServicesPoint','SecurityScopes','ServiceConnection',
            'SiteMaintenance','SiteSystemServer','SoftwareDistributionComponent','SoftwareupdatePoint',
            'StatusReportingComponent','SystemDiscovery','UserDiscovery','GroupDiscovery',
            'SoftwareUpdatePointComponent','ClientSettings','ClientSettingsBits',
            'ClientSettingsClientCache','ClientSettingsClientPolicy','ClientSettingsCloudService',
            'ClientSettingsCompliance','ClientSettingsComputerAgent','ClientSettingsDelivery',
            'ClientSettingsHardware','ClientSettingsMetered','ClientSettingsPower',
            'ClientSettingsRemoteTools','ClientSettingsSoftwareCenter','ClientSettingsSoftwareDeployment',
            'ClientSettingsSoftwareInventory','ClientSettingsSoftwareMetering','ClientSettingsSoftwareUpdate',
            'ClientSettingsStateMessaging','ClientSettingsUserDeviceAffinity','SiteConfiguration')]
        [String[]]
        $Exclude,

        [Parameter()]
        [ValidateScript(
            {
                if ($_.Substring($_.Length -5,5) -eq '.psd1')
                {
                    $true
                }
                else
                {
                    throw $script:localizedData.DataFileEr
                }
            }
        )]
        [String]
        $DataFile,

        [Parameter()]
        [ValidateScript(
            {
                if ($_.Substring($_.Length -4,4) -eq '.ps1')
                {
                    $true
                }
                else
                {
                    throw $script:localizedData.ConfigOutputPathEr
                }
            }
        )]
        [String]
        $ConfigOutputPath,

        [Parameter()]
        [String]
        $MofOutPutPath
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    if (($ConfigOutputPath -or $MofOutPutPath) -and ([string]::IsNullOrEmpty($ConfigOutputPath) -or
        [string]::IsNullOrEmpty($MofOutPutPath) -or [string]::IsNullOrEmpty($DataFile)))
    {
        throw $script:localizedData.MissingParams
    }

    Import-Module -Name 'ConfigMgrCBDsc'
    $resources = Get-DscResource -Module 'ConfigMgrCBDsc'

    if ($Include -ne 'All' -and -not [string]::IsNullOrEmpty($Exclude))
    {
        Write-Warning -Message $script:localizedData.ExcludeMsg
    }

    $fileOut = "@{`r`nSiteCode = '$SiteCode'`r`n"

    if (($Include -contains 'All' -and $Exclude -notcontains 'Accounts') -or ($Include -contains 'Accounts'))
    {
        $resourceName = 'CMAccounts'
        $accounts = Get-CMAccount -SiteCode $SiteCode

        if ($accounts)
        {
            $wCMAccounts = "$ResourceName = @(`r`n"
        }

        foreach ($account in $accounts)
        {
            Write-Verbose -Message ($script:localizedData.CMAccounts -f $account.UserName) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                ExcludeList  = @('SiteCode','AccountPassword')
                Count        = 7
                Indent       = 2
                StringValue  = $account.UserName
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wCMAccounts += "$testThing"
        }

        if ($wCMAccounts)
        {
            $wCMAccounts += ")"
            $fileOut += "$wCMAccounts`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'AdministrativeUser') -or ($Include -eq 'AdministrativeUser'))
    {
        $resourceName = 'CMAdministrativeUser'
        $susers = (Get-CMAdministrativeUser).LogonName
        if ($susers)
        {
            $wAdministrativeUser = "$resourceName = @(`r`n"
        }

        foreach ($user in $susers)
        {
            Write-Verbose -Message ($script:localizedData.AdminUser -f $user) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $user
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wAdministrativeUser += "$testThing"
        }

        if ($wAdministrativeUser)
        {
            $wAdministrativeUser += ")"
            $fileOut += "$wAdministrativeUser`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'AssetIntelligencePoint') -or ($Include -contains 'AssetIntelligencePoint'))
    {
        $resourceName = 'CMAssetIntelligencePoint'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose

        $assetIntel = Get-CMAssetIntelligenceSynchronizationPoint -SiteCode $SiteCode

        if ($assetIntel)
        {
            $wAsset = "$resourceName = @{`r`n"
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                StringValue  = 'Yes'
                Indent       = 1
                MultiEntry   = $false
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wAsset += "$testThing"
            $fileOut += "$wAsset`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'BoundaryGroups') -or ($Include -contains 'BoundaryGroups'))
    {
        $resourceName = 'CMBoundaryGroups'
        $boundaryGroups = Get-CMBoundaryGroup

        foreach ($boundaryGroup in $boundaryGroups)
        {
            if ([string]::IsNullOrEmpty($wBG))
            {
                $wBG = "$resourceName = @(`r`n"
            }

            Write-Verbose -Message ($script:localizedData.BoundaryGroup -f $boundaryGroup.Name) -Verbose
            $params = @{
                ResourceName   = $resourceName
                SiteCode       = $SiteCode
                ExcludeList    = @('SiteCode','Boundaries','BoundaryAction','SiteSystems')
                Indent         = 2
                StringValue    = $boundaryGroup.Name
                MultiEntry     = $true
                Resources      = $resources
            }

            $testThing = Set-OutFile @params
            $wBG += "$testThing"
        }

        if ($wBG)
        {
            $wBG += ")"
            $fileOut += "$wBG`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ClientPush') -or ($Include -contains 'ClientPush'))
    {
        $resourceName = 'CMClientPushSettings'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wPush = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wPush += "$testThing"
        $fileOut += "$wPush`r`n"
    }

    if (($Include -eq 'All') -or (@($Include) -like 'ClientSettings*').Count -gt 0)
    {
        $clientSettings = Get-CMClientSetting

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettings') -or
            ($Include -contains 'ClientSettings'))
        {
            foreach ($item in $clientSettings)
            {
                if ($item.Type -ne 0)
                {
                    if ([string]::IsNullOrEmpty($wCSClient))
                    {
                        $resourceName = 'CMClientSettings'
                        $wCSClient = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSettings -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSClient += "$testThing"
                }
            }

            if ($wCSClient)
            {
                $wCSClient += ")"
                $fileOut += "$wCSClient`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsBits') -or
            ($Include -contains 'ClientSettingsBits'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting BackgroundIntelligentTransfer -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSBits))
                    {
                        $resourceName = 'CMClientSettingsBits'
                        $wCSBits = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientBits -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSBits += "$testThing"
                }
            }

            if ($wCSBits)
            {
                $wCSBits += ")"
                $fileOut += "$wCSBits`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsClientCache') -or
            ($Include -contains 'ClientSettingsClientCache'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting ClientCache -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSClientCache))
                    {
                        $resourceName = 'CMClientSettingsClientCache'
                        $wCSClientCache = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientClientCache -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSClientCache += "$testThing"
                }
            }

            if ($wCSClientCache)
            {
                $wCSClientCache += ")"
                $fileOut += "$wCSClientCache`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsClientPolicy') -or
            ($Include -contains 'ClientSettingsClientPolicy'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting ClientPolicy -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSClientPolicy))
                    {
                        $resourceName = 'CMClientSettingsClientPolicy'
                        $wCSClientPolicy = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientClientPolicy -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSClientPolicy += "$testThing"
                }
            }

            if ($wCSClientPolicy)
            {
                $wCSClientPolicy += ")"
                $fileOut += "$wCSClientPolicy`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsCloudService') -or
            ($Include -contains 'ClientSettingsCloudService'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting Cloud -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSClientCloud))
                    {
                        $resourceName = 'CMClientSettingsCloudService'
                        $wCSClientCloud = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientCloud -f $item.Name) -Verbose

                    if ($item.Type -eq 2)
                    {
                        $eList = @('SiteCode','AutoAzureADJoin','AllowCloudManagementGateway')
                    }
                    else
                    {
                        $eList = @('SiteCode')
                    }

                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        ExcludeList  = $eList
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSClientCloud += "$testThing"
                }
            }

            if ($wCSClientCloud)
            {
                $wCSClientCloud += ")"
                $fileOut += "$wCSClientCloud`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsCompliance') -or
            ($Include -contains 'ClientSettingsCompliance'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting ComplianceSettings -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSCompliance))
                    {
                        $resourceName = 'CMClientSettingsCompliance'
                        $wCSCompliance = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientCompliance -f $item.Name) -Verbose

                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSCompliance += "$testThing"
                }
            }

            if ($wCSCompliance)
            {
                $wCSCompliance += ")"
                $fileOut += "$wCSCompliance`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsComputerAgent') -or
            ($Include -contains 'ClientSettingsComputerAgent'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting ComputerAgent -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSCompAgent))
                    {
                        $resourceName = 'CMClientSettingsComputerAgent'
                        $wCSCompAgent = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientCompAgent -f $item.Name) -Verbose

                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSCompAgent += "$testThing"
                }
            }

            if ($wCSCompAgent)
            {
                $wCSCompAgent += ")"
                $fileOut += "$wCSCompAgent`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsDelivery') -or
            ($Include -contains 'ClientSettingsDelivery'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting DeliveryOptimization -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSDelivery))
                    {
                        $resourceName = 'CMClientSettingsDelivery'
                        $wCSDelivery = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientDelivery -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSDelivery += "$testThing"
                }
            }

            if ($wCSDelivery)
            {
                $wCSDelivery += ")"
                $fileOut += "$wCSDelivery`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsHardware') -or
            ($Include -contains 'ClientSettingsHardware'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting HardwareInventory -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSHardware))
                    {
                        $resourceName = 'CMClientSettingsHardware'
                        $wCSHardware = "$resourceName = @(`r`n"
                    }

                    if ($item.Type -eq 0)
                    {
                        $exList = @('SiteCode')
                    }
                    else
                    {
                        $exList = @('SiteCode','MaxThirdPartyMifSize','CollectMifFile')
                    }

                    Write-Verbose -Message ($script:localizedData.ClientHardware -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        ExcludeList  = $exList
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSHardware += "$testThing"
                }
            }

            if ($wCSHardware)
            {
                $wCSHardware += ")"
                $fileOut += "$wCSHardware`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsMetered') -or
            ($Include -contains 'ClientSettingsMetered'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting MeteredNetwork -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSMetered))
                    {
                        $resourceName = 'CMClientSettingsMetered'
                        $wCSMetered = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientMetered -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSMetered += "$testThing"
                }
            }

            if ($wCSMetered)
            {
                $wCSMetered += ")"
                $fileOut += "$wCSMetered`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsPower') -or
            ($Include -contains 'ClientSettingsPower'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting PowerManagement -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSPower))
                    {
                        $resourceName = 'CMClientSettingsPower'
                        $wCSPower = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientPower -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSPower += "$testThing"
                }
            }

            if ($wCSPower)
            {
                $wCSPower += ")"
                $fileOut += "$wCSPower`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsRemoteTools') -or
            ($Include -contains 'ClientSettingsRemoteTools'))
        {
            foreach ($item in $clientSettings)
            {
                $clientRemoteTools = Get-CMClientSetting -Setting RemoteTools -Name $item.Name
                if ($clientRemoteTools -and $clientRemoteTools.FirewallExceptionProfiles -ge 1)
                {
                    if ([string]::IsNullOrEmpty($wCSRemoteTools))
                    {
                        $resourceName = 'CMClientSettingsRemoteTools'
                        $wCSRemoteTools = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientRemoteTools -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSRemoteTools += "$testThing"
                }
            }

            if ($wCSRemoteTools)
            {
                $wCSRemoteTools += ")"
                $fileOut += "$wCSRemoteTools`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsSoftwareCenter') -or
            ($Include -contains 'ClientSettingsSoftwareCenter'))
        {
            foreach ($item in $clientSettings)
            {
                $softwareCenter = Get-CMClientSetting -Setting SoftwareCenter -Name $item.Name
                if (($softwareCenter) -and ($softwareCenter.SC_UserPortal -eq 0))
                {
                    if ([string]::IsNullOrEmpty($wCSSoftCenter))
                    {
                        $resourceName = 'CMClientSettingsSoftwareCenter'
                        $wCSSoftCenter = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSoftCenter -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSSoftCenter += "$testThing"
                }
            }

            if ($wCSSoftCenter)
            {
                $wCSSoftCenter += ")"
                $fileOut += "$wCSSoftCenter`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsSoftwareDeployment') -or
            ($Include -contains 'ClientSettingsSoftwareDeployment'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting SoftwareDeployment -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSSoftDeploy))
                    {
                        $resourceName = 'CMClientSettingsSoftwareDeployment'
                        $wCSSoftDeploy = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSoftDeploy -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSSoftDeploy += "$testThing"
                }
            }

            if ($wCSSoftDeploy)
            {
                $wCSSoftDeploy += ")"
                $fileOut += "$wCSSoftDeploy`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsSoftwareInventory') -or
            ($Include -contains 'ClientSettingsSoftwareInventory'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting SoftwareInventory -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSSoftInven))
                    {
                        $resourceName = 'CMClientSettingsSoftwareInventory'
                        $wCSSoftInven = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSoftInven -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSSoftInven += "$testThing"
                }
            }

            if ($wCSSoftInven)
            {
                $wCSSoftInven += ")"
                $fileOut += "$wCSSoftInven`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsSoftwareMetering') -or
            ($Include -contains 'ClientSettingsSoftwareMetering'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting SoftwareMetering -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSSoftMet))
                    {
                        $resourceName = 'CMClientSettingsSoftwareMetering'
                        $wCSSoftMet = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSoftMet -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSSoftMet += "$testThing"
                }
            }

            if ($wCSSoftMet)
            {
                $wCSSoftMet += ")"
                $fileOut += "$wCSSoftMet`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsSoftwareUpdate') -or
            ($Include -contains 'ClientSettingsSoftwareUpdate'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting SoftwareUpdates -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSSoftUp))
                    {
                        $resourceName = 'CMClientSettingsSoftwareUpdate'
                        $wCSSoftUp = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientSoftUp -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSSoftUp += "$testThing"
                }
            }

            if ($wCSSoftUp)
            {
                $wCSSoftUp += ")"
                $fileOut += "$wCSSoftUp`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsStateMessaging') -or
        ($Include -contains 'ClientSettingsStateMessaging'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting StateMessaging -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSStateMsg))
                    {
                        $resourceName = 'CMClientSettingsStateMessaging'
                        $wCSStateMsg = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientStateMessage -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSStateMsg += "$testThing"
                }
            }

            if ($wCSStateMsg)
            {
                $wCSStateMsg += ")"
                $fileOut += "$wCSStateMsg`r`n"
            }
        }

        if (($Include -eq 'All' -and $Exclude -notcontains 'ClientSettingsUserDeviceAffinity') -or
        ($Include -contains 'ClientSettingsUserDeviceAffinity'))
        {
            foreach ($item in $clientSettings)
            {
                if (Get-CMClientSetting -Setting UserAndDeviceAffinity -Name $item.Name)
                {
                    if ([string]::IsNullOrEmpty($wCSUDAffinity))
                    {
                        $resourceName = 'CMClientSettingsUserDeviceAffinity'
                        $wCSUDAffinity = "$resourceName = @(`r`n"
                    }

                    Write-Verbose -Message ($script:localizedData.ClientAffinity -f $item.Name) -Verbose
                    $params = @{
                        ResourceName = $resourceName
                        SiteCode     = $SiteCode
                        Indent       = 2
                        MultiEntry   = $true
                        Resources    = $resources
                        StringValue  = $item.Name
                    }

                    $testThing = Set-OutFile @params
                    $wCSUDAffinity += "$testThing"
                }
            }

            if ($wCSUDAffinity)
            {
                $wCSUDAffinity += ")"
                $fileOut += "$wCSUDAffinity`r`n"
            }
        }
        # new client setting here
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ClientStatusSettings') -or ($Include -contains 'ClientStatusSettings'))
    {
        $resourceName = 'CMClientStatusSettings'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wClientStatus = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            StringValue  = 'Yes'
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wClientStatus += "$testThing"
        $fileOut += "$wClientStatus`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'CollectionEvaluationComponent') -or ($Include -contains 'CollectionEvaluationComponent'))
    {
        $resourceName = 'CMCollectionMembershipEvaluationComponent'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wcollectionEval = "$resourceName = @{`r`n"

        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        if ($testThing.Length -gt 1)
        {
            $wcollectionEval += "$testThing"
            $fileOut += "$wcollectionEval`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'Collections') -or ($Include -contains 'Collections'))
    {
        $resourceName = 'CMCollections'
        $deviceCollections = Get-CMCollection -CollectionType Device
        $userCollections = Get-CMCollection -CollectionType User

        if ($deviceCollections -or $userCollections)
        {
            $wcollections = "$resourceName = @(`r`n"
        }

        foreach ($item in $deviceCollections)
        {
            Write-Verbose -Message ($script:localizedData.DeviceColl -f $item.Name) -Verbose
            $params = @{
                ResourceName   = $resourceName
                SiteCode       = $SiteCode
                ExcludeList    = @('SiteCode','DirectMembershipId','QueryRules')
                Indent         = 2
                StringValue    = 'Device'
                CollectionName = $item.Name
                MultiEntry     = $true
                Resources      = $resources
            }

            $testThing = Set-OutFile @params
            $wcollections += "$testThing"
        }

        foreach ($item in $userCollections)
        {
            Write-Verbose -Message ($script:localizedData.UserColl -f $item.Name) -Verbose
            $params = @{
                ResourceName   = $resourceName
                SiteCode       = $SiteCode
                ExcludeList    = @('SiteCode','DirectMembershipId','QueryRules')
                Indent         = 2
                StringValue    = 'User'
                CollectionName = $item.Name
                MultiEntry     = $true
                Resources      = $resources
            }

            $testThing = Set-OutFile @params
            $wcollections += "$testThing"
        }

        if ($wcollections)
        {
            $wcollections += ")"
            $fileOut += "$wcollections`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'DistributionGroups') -or ($Include -contains 'DistributionGroups'))
    {
        $resourceName = 'CMDistributionGroup'
        $allGroups = Get-CMDistributionPointGroup

        if ($allGroups)
        {
            $distroGroups = "$resourceName = @(`r`n"
        }

        foreach ($item in $allGroups)
        {
            Write-Verbose -Message ($script:localizedData.DistroGroup -f $item.Name) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $item.Name
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $distroGroups += "$testThing"
        }

        if ($distroGroups)
        {
            $distroGroups += ")"
            $fileOut += "$distroGroups`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'DistributionPoint') -or ($Include -contains 'DistributionPoint'))
    {
        $resourceName = 'CMDistributionPoint'
        $dps = Get-CMDistributionPoint -SiteCode $SiteCode

        if ($dps)
        {
            $wDPs = "$resourceName = @(`r`n"
        }

        foreach ($dp in $dps)
        {
            Write-Verbose -Message ($script:localizedData.DistroPoint -f $dp.NetworkOSPath.TrimStart('\\')) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                ExcludeList  = @('SiteCode','BoundaryGroupStatus')
                Indent       = 2
                StringValue  = $dp.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wDPs += "$testThing"
        }

        if ($wDPs)
        {
            $wDPs += ")"
            $fileOut += "$wDPs`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'DistributionPointGroupMembers') -or ($Include -contains 'DistributionPointGroupMembers'))
    {
        $resourceName = 'CMDistributionPointGroupMembers'
        $getDPGroupMembers = Get-CMDistributionPoint -SiteCode $SiteCode

        if ($getDPGroupMembers)
        {
            $wDPGroupMembers = "$resourceName = @(`r`n"
        }

        foreach ($getDPGroupMember in $getDPGroupMembers)
        {
            Write-Verbose -Message ($script:localizedData.DistroGroupMembers -f $getDPGroupMember.NetworkOSPath.TrimStart('\\')) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                ExcludeList  = @('SiteCode','DPStatus')
                Indent       = 2
                StringValue  = $getDPGroupMember.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wDPGroupMembers += "$testThing"
        }

        if ($wDPGroupMembers)
        {
            $wDPGroupMembers += ")"
            $fileOut += "$wDPGroupMembers`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'EmailNotificationComponent') -or ($Include -contains 'EmailNotificationComponent'))
    {
        $resourceName = 'CMEmailNotificationComponent'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose

        $wEmailNotify = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wEmailNotify += "$testThing"
        $fileOut += "$wEmailNotify`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'FallbackPoints') -or ($Include -contains 'FallbackPoints'))
    {
        $resourceName = 'CMFallbackStatusPoint'
        $fallbacks = Get-CMFallbackStatusPoint -SiteCode $SiteCode

        if ($fallbacks)
        {
            $wFallback = "$resourceName = @(`r`n"
        }

        foreach ($fallback in $fallbacks)
        {
            Write-Verbose -Message ($script:localizedData.Fallback -f $fallback.NetworkOSPath.TrimStart('\\')) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $fallback.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wFallback += "$testThing"
        }

        if ($wFallback)
        {
            $wFallback += ")"
            $fileOut += "$wFallback`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ForestDiscovery') -or ($Include -contains 'ForestDiscovery'))
    {
        $resourceName = 'CMForestDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $forest = ((Get-CMDiscoveryMethod -Name ActiveDirectoryForestDiscovery -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1
        $wforest = "$resourceName = @{`r`n"

        if ($forest -eq 'INACTIVE')
        {
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 1
                Count        = 7
                ExcludeList  = @('SiteCode','ScheduleInterval','EnableActiveDirectorySiteBoundaryCreation','EnableSubnetBoundaryCreation','ScheduleCount')
                Resources    = $resources
            }
        }
        else
        {
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 1
                Resources    = $resources
            }
        }

        $testThing = Set-OutFile @params
        $wforest += "$testThing"
        $fileOut += "$wforest`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'GroupDiscovery') -or ($Include -contains 'GroupDiscovery'))
    {
        $resourceName = 'CMGroupDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $groupDisc = ((Get-CMDiscoveryMethod -Name ActiveDirectoryGroupDiscovery -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1

        if ($groupDisc)
        {
            $wGrpDiscovery = "$resourceName = @{`r`n"

            if ($groupDisc -eq 'INACTIVE')
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    ExcludeList  = @('SiteCode','EnableDeltaDiscovery','DeltaDiscoveryMins','EnableFilteringExpiredLogon',
                    'TimeSinceLastLogonDays','EnableFilteringExpiredPassword','TimeSinceLastPasswordUpdateDays','DiscoverDistributionGroupMembership',
                    'GroupDiscoveryScope','Start','ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth')
                    Indent       = 1
                    Count        = 7
                    Resources    = $resources
                }
            }
            else
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    ExcludeList  = @('SiteCode','GroupDiscoveryScope')
                    Indent       = 1
                    Resources    = $resources
                }
            }

            $testThing = Set-OutFile @params
            $wGrpDiscovery += "$testThing"
            $fileOut += "$wGrpDiscovery`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'HeartbeatDiscovery') -or ($Include -contains 'HeartbeatDiscovery'))
    {
        $resourceName = 'CMHeartbeatDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $heartbeat = ((Get-CMDiscoveryMethod -Name HeartbeatDiscovery -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1

        if ($heartbeat)
        {
            $wHeartbeat = "$resourceName = @{`r`n"

            if ($heartbeat -eq 'INACTIVE')
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    Count        = 7
                    ExcludeList  = @('SiteCode','ScheduleInterval','ScheduleCount')
                    Resources    = $resources
                }
            }
            else
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    Resources    = $resources
                }
            }

            $testThing = Set-OutFile @params
            $wHeartbeat += "$testThing"
            $fileOut += "$wHeartbeat`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'MaintenanceWindow') -or ($Include -contains 'MaintenanceWindow'))
    {
        $resourceName = 'CMMaintenanceWindows'
        $deviceCollections = Get-CMCollection -CollectionType Device

        foreach ($deviceCollection in $deviceCollections)
        {
            if ($deviceCollection.ServiceWindowsCount -gt 0)
            {
                if ([string]::IsNullOrEmpty($wWindow))
                {
                    $wWindow = "$resourceName = @(`r`n"
                }

                $mw = Get-CMMaintenanceWindow -CollectionId $deviceCollection.CollectionID
                foreach ($item in $mw)
                {
                    Write-Verbose -Message ($script:localizedData.MWindows -f $item.Name, $deviceCollection.Name) -Verbose
                    $params = @{
                        ResourceName   = $resourceName
                        SiteCode       = $SiteCode
                        Indent         = 2
                        StringValue    = $item.Name
                        CollectionName = $deviceCollection.Name
                        MultiEntry     = $true
                        Resources      = $resources
                    }

                    $testThing = Set-OutFile @params
                    $wWindow += "$testThing"
                }
            }
        }

        if ($wWindow)
        {
            $wWindow += ")"
            $fileOut += "$wWindow`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ManagementPoint') -or ($Include -contains 'ManagementPoint'))
    {
        $resourceName = 'CMManagementPoint'
        $mps = Get-CMManagementPoint -SiteCode $SiteCode

        if ($mps)
        {
            $wMPs = "$resourceName = @(`r`n"
        }

        foreach ($mp in $mps)
        {
            Write-Verbose -Message ($script:localizedData.ManagementPoint -f $mp.NetworkOSPath.TrimStart('\\')) -Verbose
            $useSiteDB = ($mp.Props | Where-Object -FilterScript {$_.PropertyName -eq 'UseSiteDatabase'}).Value
            if ($useSiteDB -eq $true)
            {
                $excludeList = ('SiteCode','SQLServerFqdn','SqlServerInstanceName','DatabaseName')
            }
            else
            {
                $excludeList = @('SiteCode','UseSiteDatabase')
            }

            $useComputerAccount = ($mp.Props | Where-Object -FilterScript {$_.PropertyName -eq 'UserName'}).Value2
            if ([string]::IsNullOrEmpty($useComputerAccount))
            {
                $excludeList += 'Username'
            }
            else
            {
                $excludeList += 'UseComputerAccount'
            }

            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $mp.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                ExcludeList  = $excludeList
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wMPs += "$testThing"
        }

        if ($wMPs)
        {
            $wMPs += ")"
            $fileOut += "$wMPs`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'NetworkDiscovery') -or ($Include -contains 'NetworkDiscovery'))
    {
        $resourceName = 'CMNetworkDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $network = Get-CMDiscoveryMethod -Name NetworkDiscovery -SiteCode $SiteCode

        if ($network)
        {
            $wNetDiscovery = "$resourceName = @{`r`n"
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 1
                MultiEntry   = $false
                Count        = 7
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wNetDiscovery += "$testThing"
            $fileOut += "$wNetDiscovery`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'PullDistributionPoint') -or ($Include -contains 'PullDistributionPoint'))
    {
        $resourceName = 'CMPullDistributionPoint'
        $getPullDPs = Get-CMDistributionPointInfo -SiteCode $SiteCode | Where-Object -FilterScript {$_.IsPullDP -eq $true}

        if ($getPullDPs)
        {
            $wPullDP = "$resourceName = @(`r`n"
        }

        foreach ($getPullDP in $getPullDPs)
        {
            Write-Verbose -Message ($script:localizedData.PullDP -f $getPullDP.ServerName) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $getPullDP.ServerName
                MultiEntry   = $true
                ExcludeList  = @('SiteCode','DPStatus')
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wPullDP += "$testThing"
        }

        if ($wPullDP)
        {
            $wPullDP += ")"
            $fileOut += "$wPullDP`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'PxeDistributionPoint') -or ($Include -contains 'PxeDistributionPoint'))
    {
        $resourceName = 'CMPxeDistributionPoint'
        $getPxeDPs = Get-CMDistributionPointInfo -SiteCode $SiteCode | Where-Object -FilterScript {$_.IsPXE -eq $true}

        if ($getPxeDPs)
        {
            $wPxeDP = "$resourceName = @(`r`n"
        }

        foreach ($getPxeDP in $getPxeDPs)
        {
            Write-Verbose -Message ($script:localizedData.PxeDP -f $getPxeDP.ServerName) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $getPxeDP.ServerName
                MultiEntry   = $true
                ExcludeList  = @('SiteCode','DPStatus','IsMulticast')
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wPxeDP += "$testThing"

            if ($getPxeDP.PxePassword)
            {
                $wPxeDP = $wPxeDP.Replace('MSFT_Credential','$true')
            }
            else
            {
                $wPxeDP = $wPxeDP.Replace('MSFT_Credential','$false')
            }
        }

        if ($wPxeDP)
        {
            $wPxeDP += ")"
            $fileOut += "$wPxeDP`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ReportingServicesPoint') -or ($Include -contains 'ReportingServicesPoint'))
    {
        $resourceName = 'CMReportingServicePoint'
        $rsps = Get-CMReportingServicePoint -SiteCode $SiteCode

        if ($rsps)
        {
            $wRptServer = "$resourceName = @(`r`n"
        }

        foreach ($rsp in $rsps)
        {
            Write-Verbose -Message ($script:localizedData.ReportingPoint -f $rsp.NetworkOSPath.TrimStart('\\')) -Verbose
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $rsp.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wRptServer += "$testThing"
        }

        if ($wRptServer)
        {
            $wRptServer += ")"
            $fileOut += "$wRptServer`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SecurityScopes') -or ($Include -contains 'SecurityScopes'))
    {
        $resourceName = 'CMSecurityScopes'
        $getscopes = Get-CMSecurityScope

        if ($getscopes)
        {
            $wScopes = "$resourceName = @(`r`n"
        }

        foreach ($scope in $getscopes)
        {
            Write-Verbose -Message ($script:localizedData.SecurityScopes -f $scope.CategoryName) -Verbose
            $params = @{
                ResourceName = $resourceName
                ExcludeList  = @('SiteCode','InUse')
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $scope.CategoryName
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wScopes += "$testThing"
        }

        if ($wScopes)
        {
            $wScopes += ")"
            $fileOut += "$wScopes`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'ServiceConnection') -or ($Include -contains 'ServiceConnection'))
    {
        $resourceName = 'CMServiceConnectionPoint'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $serviceConnections = Get-CMServiceConnectionPoint -SiteCode $SiteCode

        if ($serviceConnections)
        {
            $wsvcConnection = "$resourceName = @{`r`n"
            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                Indent       = 1
                MultiEntry   = $false
                StringValue  = $serviceConnections.NetworkOSPath.TrimStart('\\')
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wsvcConnection += "$testThing"
            $fileOut += "$wsvcConnection`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SiteConfiguration') -or ($Include -contains 'SiteConfiguration'))
    {
        $resourceName = 'CMSiteConfiguration'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wSiteConfiguration = "$resourceName = @(`r`n"
        $siteType = Get-CMSiteDefinition -SiteCode $SiteCode

        if ($siteType.SiteType -eq 2)
        {
            $excluded = @('SiteCode','SiteType')
        }
        else
        {
            $excluded = @('SiteCode','ClientCheckCertificateRevocationListForSiteSystem',
            'UsePkiClientCertificate', 'RequireSigning','UseEncryption','EnableLowFreeSpaceAlert',
            'FreeSpaceThresholdCriticalGB','FreeSpaceThresholdWarningGB','SiteType')
        }

        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
            ExcludeList  = $excluded
        }

        $testThing = Set-OutFile @params
        $wSiteConfiguration += "$testThing"
        $fileOut += $wSiteConfiguration
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SiteMaintenance') -or ($Include -contains 'SiteMaintenance'))
    {
        $resourceName = 'CMSiteMaintenance'
        $wSiteMaintenance = "$resourceName = @(`r`n"
        $siteType = Get-CMSiteDefinition -SiteCode $SiteCode
        $allTasks = @('Delete Obsolete Alerts','Delete Aged Replication Data','Delete Expired MDM Bulk Enroll Package Records',
            'Backup SMS Site Server','Delete Aged Status Messages','Delete Aged Application Revisions',
            'Delete Aged Replication Summary Data','Delete Obsolete Forest Discovery Sites And Subnets',
            'Delete Aged Delete Detection Data','Delete Aged Distribution Point Usage Stats',
            'Rebuild Indexes','Delete Aged Log Data','Delete Aged Passcode Records','Delete Aged Console Connection Data',
            'Monitor Keys','Delete Aged Client Operations','Delete Aged Notification Server History'
        )
        $casOnly = @('Check Application Title with Inventory Information','Delete Duplicate System Discovery Data')
        $primaryOnly = @('Clear Undiscovered Clients','Delete Aged Application Request Data','Delete Aged Client Download History',
            'Delete Aged Collected Files','Delete Aged Computer Association Data','Delete Aged Device Wipe Record',
            'Delete Aged Discovery Data','Delete Aged Enrolled Devices','Delete Aged EP Health Status History Data',
            'Delete Aged Exchange Partnership','Delete Aged Inventory History','Delete Aged Metering Data',
            'Delete Aged Metering Summary Data','Delete Aged Notification Task History','Delete Aged Threat Data'
            'Delete Aged Unknown Computers','Delete Aged User Device Affinity Data','Delete Inactive Client Discovery Data'
            'Delete Obsolete Client Discovery Data','Delete Orphaned Client Deployment State Records',
            'Summarize File Usage Metering Data','Summarize Installed Software Data','Summarize Monthly Usage Metering Data',
            'Update Application Available Targeting','Update Application Catalog Tables','Delete Aged Cloud Management Gateway Traffic Data'
        )

        if ($siteType.SiteType -eq 2)
        {
            $rollupTasks = $allTasks + $primaryOnly
        }
        else
        {
            $rollupTasks = $allTasks + $casOnly
        }

        foreach ($task in $rollupTasks)
        {
            Write-Verbose -Message ($script:localizedData.SiteMaintenance -f $task) -Verbose
            $params = @{
                ResourceName = $resourceName
                ExcludeList  = @('SiteCode','SiteType')
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $task
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wSiteMaintenance += "$testThing"
        }

        if ($wSiteMaintenance)
        {
            $wSiteMaintenance += ")"
            $fileOut += "$wSiteMaintenance`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SiteSystemServer') -or ($Include -contains 'SiteSystemServer'))
    {
        $resourceName = 'CMSiteSystemServer'
        $siteServers = Get-CMSiteSystemServer -SiteCode $SiteCode

        if ($siteServers)
        {
            $wSiteServers = "$resourceName = @(`r`n"
        }

        foreach ($siteServer in $siteServers)
        {
            Write-Verbose -Message ($script:localizedData.SiteServer -f $siteServer.NetworkOSPath.TrimStart('\\')) -Verbose
            $useSiteServer = ($siteServer.Props | Where-Object -FilterScript {$_.PropertyName -eq 'UseMachineAccount'}).Value
            if ($useSiteServer -eq 1)
            {
                $excludeList = @('SiteCode','AccountName','RoleCount')
            }
            else
            {
                $excludeList = @('SiteCode','UseSiteServiceAccount','RoleCount')
            }

            $proxy = ($siteServer.Props | Where-Object -FilterScript {$_.PropertyName -eq 'UseProxy'}).Value
            if ($proxy -eq 0)
            {
                $excludeList += @('ProxyServerPort','ProxyAccessAccount','ProxyServerName')
            }

            $proxyUser = ($siteServer.Props | Where-Object -FilterScript {$_.PropertyName -eq 'AnonymousProxyAccess'}).Value
            if ($proxyUser -eq 1)
            {
                $excludeList += @('ProxyAccessAccount')
            }

            $params = @{
                ResourceName = $resourceName
                ExcludeList  = $excludeList
                SiteCode     = $SiteCode
                Indent       = 2
                StringValue  = $siteServer.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wSiteServers += "$testThing"
        }

        if ($wSiteServers)
        {
            $wSiteServers += ")"
            $fileOut += "$wSiteServers`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SoftwareDistributionComponent') -or ($Include -contains 'SoftwareDistributionComponent'))
    {
        $resourceName = 'CMSoftwareDistributionComponent'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wdistroComSetting = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wdistroComSetting += "$testThing"
        $fileOut += "$wdistroComSetting`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SoftwareUpdatePoint') -or ($Include -contains 'SoftwareUpdatePoint'))
    {
        $resourceName = 'CMSoftwareUpdatePoint'
        $getSoftwareUpdatePoints = Get-CMSoftwareUpdatePoint -SiteCode $SiteCode

        if ($getSoftwareUpdatePoints)
        {
            $wSup = "$resourceName = @(`r`n"
        }

        foreach ($sup in $getSoftwareUpdatePoints)
        {
            Write-Verbose -Message ($script:localizedData.UpdatePoint -f $sup.NetworkOSPath.TrimStart('\\')) -Verbose
            $supAccess = ($sup.Props | Where-Object -FilterScript {$_.PropertyName -eq 'WSUSAccessAccount'}).Value2
            $excludeList = @('SiteCode')
            if ([string]::IsNullOrEmpty($supAccess))
            {
                $excludeList += @('WsusAccessAccount')
            }

            $params = @{
                ResourceName = $resourceName
                SiteCode     = $SiteCode
                ExcludeList  = $excludeList
                Indent       = 2
                StringValue  = $sup.NetworkOSPath.TrimStart('\\')
                MultiEntry   = $true
                Resources    = $resources
            }

            $testThing = Set-OutFile @params
            $wSup += "$testThing"
        }

        if ($wSup)
        {
            $wSup += ")"
            $fileOut += "$wSup`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SoftwareUpdatePointComponent') -or ($Include -contains 'SoftwareUpdatePointComponent'))
    {
        if ([string]::IsNullOrEmpty((Get-CMSite -SiteCode $SiteCode).ReportingSiteCode))
        {
            $excludeList = @('SiteCode')
        }
        else
        {
            $excludeList = @('SiteCode','LanguageSummaryDetails','LanguageSummaryDetailsToInclude','LanguageSummaryDetailsToExclude','Products','ProductsToInclude','ProductsToExclude','UpdateClassifications',
            'UpdateClassificationsToInclude','UpdateClassificationsToExclude','ContentFileOption','DefaultWsusServer','EnableCallWsusCleanupWizard','EnableSyncFailureAlert','EnableSynchronization',
            'ImmediatelyExpireSupersedence','ImmediatelyExpireSupersedenceForFeature','SynchronizeAction','UpstreamSourceLocation','WaitMonth','WaitMonthForFeature','EnableThirdPartyUpdates',
            'EnableManualCertManagement','FeatureUpdateMaxRuntimeMins','NonFeatureUpdateMaxRuntimeMins','ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')
        }

        $resourceName = 'CMSoftwareUpdatePointComponent'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wSupComponent = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            ExcludeList  = $excludeList
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wSupComponent += "$testThing"
        $fileOut += "$wSupComponent`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'StatusReportingComponent') -or ($Include -contains 'StatusReportingComponent'))
    {
        $resourceName = 'CMStatusReportingComponent'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $wStatusReportingCom = "$resourceName = @{`r`n"
        $params = @{
            ResourceName = $resourceName
            SiteCode     = $SiteCode
            Indent       = 1
            MultiEntry   = $false
            Resources    = $resources
        }

        $testThing = Set-OutFile @params
        $wStatusReportingCom += "$testThing"
        $fileOut += "$wStatusReportingCom`r`n"
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'SystemDiscovery') -or ($Include -contains 'SystemDiscovery'))
    {
        $resourceName = 'CMSystemDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $systemDisc = ((Get-CMDiscoveryMethod -Name ActiveDirectorySystemDiscovery -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1

        if ($systemDisc)
        {
            $wsysDiscovery = "$resourceName = @{`r`n"

            if ($systemDisc -eq 'INACTIVE')
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    ExcludeList  = @('SiteCode','ScheduleInterval','ScheduleCount')
                    Resources    = $resources
                }
            }
            else
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    Resources    = $resources
                }
            }

            $testThing = Set-OutFile @params
            $wsysDiscovery += "$testThing"
            $fileOut += "$wsysDiscovery`r`n"
        }
    }

    if (($Include -eq 'All' -and $Exclude -notcontains 'UserDiscovery') -or ($Include -contains 'UserDiscovery'))
    {
        $resourceName = 'CMUserDiscovery'
        Write-Verbose -Message ($script:localizedData.SingleOutput -f $resourceName) -Verbose
        $userDisc = ((Get-CMDiscoveryMethod -Name ActiveDirectoryUserDiscovery -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1

        if ($userDisc)
        {
            $wusrDiscovery = "$resourceName = @{`r`n"

            if ($userDisc -eq 'INACTIVE')
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    ExcludeList  = @('SiteCode','ScheduleInterval','ScheduleCount')
                    Resources    = $resources
                }
            }
            else
            {
                $params = @{
                    ResourceName = $resourceName
                    SiteCode     = $SiteCode
                    Indent       = 1
                    Resources    = $resources
                }
            }

            $testThing = Set-OutFile @params
            $wusrDiscovery += "$testThing"
            $fileOut += "$wusrDiscovery`r`n"
        }
    }

    $fileOut += "}`r`n"

    if ($DataFile -and $Include -ne 'ConfigFileOnly')
    {
        if (Test-Path -Path $DataFile)
        {
            Remove-Item -Path $DataFile
        }

        Write-Verbose -Message ($script:localizedData.NewDataFile -f $DataFile) -Verbose
        Add-Content -Path $DataFile -Value "$fileOut"
    }

    if (($ConfigOutputPath) -and ($MofOutPutPath) -and ($DataFile))
    {
        Write-Verbose -Message ($script:localizedData.NewConfigFile -f $ConfigOutputPath) -Verbose
        New-Configuration -ConfigOutputPath $ConfigOutputPath -DataFile $DataFile -MofOutPutPath $MofOutPutPath
    }

    if ($Include -eq 'ConfigFileOnly')
    {
        return $script:localizedData.ConfigFileComplete
    }
    else
    {
        return $fileOut
    }
}
