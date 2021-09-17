$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the software update point component.

    .Notes
        This component is only fully functional at the top level of the hierarchy. Downlevel Sites inherit most properties from top level.
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

    if ([string]::IsNullOrEmpty((Get-CMSite -SiteCode $SiteCode).ReportingSiteCode))
    {
        $child = $false
    }
    else
    {
        $child = $true
    }

    $supConfig = Get-CMSoftwareUpdatePointComponent -SiteCode $SiteCode

    if ($supConfig)
    {
        $supConfigProps = $supConfig.Props

        foreach ($supConfigProp in $supConfigProps)
        {
            switch ($supConfigProp.PropertyName)
            {
                'Call WSUS Cleanup'                     { $wsusCleanup = $supConfigProp.Value }
                'ClientReportingLevel'                  { $reportLevel = @('DoNotCreateWsusReportingEvents','CreateOnlyWsusStatusReportingEvents','CreateAllWsusReportingEvents')[($supConfigProp.Value)] }
                'DefaultWSUS'                           { $defaultWsus = $supConfigProp.Value2 }
                'DefaultUseParentWSUS'                  { $syncAction = @('SynchronizeFromMicrosoftUpdate','SynchronizeFromAnUpstreamDataSourceLocation','DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource')[($supConfigProp.Value)] }
                'ParentWSUS'                            { $parentWsus = 'http://' + $supConfigProp.Value2 }
                'SupportedTitleLanguages'               { $titleLanguages = $supConfigProp.Value2 }
                'SupportedUpdateLanguages'              { $updateLanguages = $supConfigProp.Value2 }
                'Sync Supersedence Age For Feature'     { $supAgeFeature = $supConfigProp.Value }
                'Sync Supersedence Age For NonFeature'  { $supAge = $supConfigProp.Value }
                'Sync Supersedence Mode For Feature'    { $supModeFeature = @($true,$false)[($supConfigProp.Value)] }
                'Sync Supersedence Mode For NonFeature' { $supMode = @($true,$false)[($supConfigProp.Value)] }
            }
        }
    }

    $languageTitles = @()
    $titleLangs = $titleLanguages.Split(',')

    foreach ($lang in $titleLangs)
    {
        $langName = [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Where-Object -FilterScript {$_.Name -eq $lang}
        $fullName = $langName.DisplayName
        $languageTitles += $fullName
    }

    $languageUpdates = @()
    $updateLangs = $updateLanguages.Split(',')

    foreach ($lang in $updateLangs)
    {
        $langName = [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Where-Object -FilterScript {$_.Name -eq $lang}
        $fullName = $langName.DisplayName
        $languageUpdates += $fullName
    }

    $wsusSyncProps = (Get-CMSiteComponent -SiteCode $SiteCode -ComponentName SMS_WSUS_Sync_Manager).Props

    foreach ($wsusSyncProp in $wsusSyncProps)
    {
        switch ($wsusSyncProp.PropertyName)
        {
            'Sync ExpressFiles'         {
                                            if ($wsusSyncProp.Value -eq '0')
                                            {
                                                $syncExpress = 'FullFilesOnly'
                                            }
                                            else
                                            {
                                                $syncExpress = 'ExpressForWindows10Only'
                                            }
                                        }
            'Sync Schedule'             {
                                            $syncSchedule = $wsusSyncProp.Value1
                                            if ([string]::IsNullOrEmpty($wsusSyncProp.Value1))
                                            {
                                                $enableSync = $false
                                            }
                                            else
                                            {
                                                $enableSync = $true
                                            }
                                        }
            'EnableThirdPartyUpdates'   {
                                            if ($wsusSyncProp.Value -eq '0')
                                            {
                                                $thirdParty = $false
                                            }
                                            elseif ($wsusSyncProp.Value -eq '1')
                                            {
                                                $thirdParty = $true
                                                $manualCert = $true
                                            }
                                            else
                                            {
                                                $thirdParty = $true
                                                $manualCert = $false
                                            }
                                         }
            'MaxInstallTime-ServicePack' { $fInstallTime = ($wsusSyncProp.Value)/60 }
            'MaxInstallTime-Windows'     { $uInstallTime = ($wsusSyncProp.Value)/60 }
        }
    }

    if (-not [string]::IsNullOrEmpty($syncSchedule))
    {
        $schedule = Get-CMSchedule -ScheduleString $syncSchedule
    }

    $syncFailureAlert = Get-CMAlert | Where-Object -FilterScript {$_.Name -match "Synchronization failure alert for software update point:"}

    if ($syncFailureAlert)
    {
        $enableFailureAlert = $true
    }
    else
    {
        $enableFailureAlert = $false
    }

    $available = (Get-CMSoftwareUpdateCategory -Fast)
    $updateCats = ($available | Where-Object -FilterScript {($_.SourceSite -eq $SiteCode) -and ($_.IsSubscribed -eq $true)})
    $products = @()
    $classifications = @()
    foreach ($cat in $updateCats)
    {
        switch ($cat.CategoryTypeName)
        {
            'Product'              { $products += $cat.LocalizedCategoryInstanceName }
            'UpdateClassification' { $classifications += $cat.LocalizedCategoryInstanceName }
        }
    }

    return @{
        SiteCode                                = $SiteCode
        ContentFileOption                       = $syncExpress
        DefaultWsusServer                       = $defaultWsus
        EnableCallWsusCleanupWizard             = $wsusCleanup
        EnableSyncFailureAlert                  = $enableFailureAlert
        EnableSynchronization                   = $enableSync
        ImmediatelyExpireSupersedence           = $supMode
        ImmediatelyExpireSupersedenceForFeature = $supModeFeature
        LanguageUpdateFiles                     = $languageUpdates
        LanguageSummaryDetails                  = $languageTitles
        ReportingEvent                          = $reportLevel
        Start                                   = $schedule.Start
        ScheduleType                            = $schedule.ScheduleType
        DayOfWeek                               = $schedule.DayofWeek
        MonthlyWeekOrder                        = $schedule.WeekOrder
        DayofMonth                              = $schedule.MonthDay
        RecurInterval                           = $schedule.RecurInterval
        Products                                = $products
        UpdateClassifications                   = $classifications
        SynchronizeAction                       = $syncAction
        UpstreamSourceLocation                  = $parentWsus
        WaitMonth                               = $supAge
        WaitMonthForFeature                     = $supAgeFeature
        EnableThirdPartyUpdates                 = $thirdParty
        EnableManualCertManagement              = $manualCert
        FeatureUpdateMaxRuntimeMins             = $fInstallTime
        NonFeatureUpdateMaxRuntimeMins          = $uInstallTime
        ChildSite                               = $child
        AvailableCats                           = $available.LocalizedCategoryInstanceName
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the software update point component.

    .PARAMETER LanguageSummaryDetails
        Specifies an array of languages desired for the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageSummaryDetailsToInclude
        Specifies an array of languages to include in the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageSummaryDetailsToExclude
        Specifies an array of languages to exclude from the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageUpdateFiles
        Specifies an array of languages desired for the languages supported for software updates at the specified site.

    .PARAMETER LanguageUpdateFilesToInclude
        Specifies an array of languages to include in the languages supported for software updates at the specified site.

    .PARAMETER LanguageUpdateFilesToExclude
        Specifies an array of languages to exclude from the languages supported for software updates at the specified site.

    .PARAMETER Products
        Specifies an array of products desired for software updates to synchronize.

    .PARAMETER ProductsToInclude
        Specifies an array of products to include in software updates to synchronize.

    .PARAMETER ProductsToExclude
        Specifies an array of products to exclude from software updates to synchronize.

    .PARAMETER UpdateClassifications
        Specifies an array of software update classifications desired for the classifications supported for software updates at this site.

    .PARAMETER UpdateClassificationsToInclude
        Specifies an array of software update classifications to include in the classifications supported for software updates at this site.

    .PARAMETER UpdateClassificationsToExclude
        Specifies an array of software update classifications to exclude from the classifications supported for software updates at this site.

    .PARAMETER ContentFileOption
        Specifies whether express updates will be downloaded for Windows 10. The acceptable values for this parameter are:

        FullFilesOnly
        ExpressForWindows10Only

    .PARAMETER DefaultWsusServer
        Specifies the default WSUS server that the software update point is pointed to.

    .PARAMETER EnableCallWsusCleanupWizard
        Specifies whether to decline expired updates in WSUS according to superscedence rules.

    .PARAMETER EnableSyncFailureAlert
        Specifies whether Configuration Manager creates an alert when synchronization fails on a site.

    .PARAMETER EnableSynchronization
        Indicates whether this site automatically synchronizes updates according to a schedule.

    .PARAMETER ImmediatelyExpireSupersedence
        Indicates whether a software update expires immediately after another update supersedes it or after a specified period of time.
        If you specify a value of $false for this parameter, specify the number of months to wait for expiration by using the WaitMonth parameter.
        If you specify a value of $true for this parameter, do not specify the WaitMonth parameter.

    .PARAMETER ImmediatelyExpireSupersedenceForFeature
        Indicates whether a feature update expires immediately after another update supersedes it or after a specified period of time.
        If you specify a value of $false for this parameter, specify the number of months to wait for expiration by using the WaitMonthForFeature parameter.
        If you specify a value of $true for this parameter, do not specify the WaitMonthForFeature parameter.

    .PARAMETER ReportingEvent
        Specifies whether to create event messages for WSUS reporting for status reporting events or for all reporting events. The acceptable values for this parameter are:

        CreateAllWsusReportingEvents
        CreateOnlyWsusStatusReportingEvents
        DoNotCreateWsusReportingEvents

    .PARAMETER SynchronizeAction
        Specifies a source for synchronization for this software update point. The acceptable values for this parameter are:

        SynchronizeFromMicrosoftUpdate
        SynchronizeFromAnUpstreamDataSourceLocation
        DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource

        If you select a value of SynchronizeFromAnUpstreamDataSourceLocation, specify the data source location by using the UpstreamSourceLocation parameter.

    .PARAMETER UpstreamSourceLocation
        Specifies an upstream data location as a URL.
        To use this location, specify a value of SynchronizeFromAnUpstreamDataSourceLocation for the SynchronizeAction parameter.

    .PARAMETER WaitMonth
        Specifies how long, in months, to wait before a software update expires after another update supersedes it.
        Specify a value of $True for the ImmediatelyExpireSupersedence parameter for software updates to expire immediately.
        If $True is specified for the ImmediatelyExpireSupersedence parameter, do not use this parameter.

    .PARAMETER WaitMonthForFeature
        Specifies how long, in months, to wait before a feature update expires after another update supersedes it.
        Specify a value of $True for the ImmediatelyExpireSupersedenceForFeature parameter for software updates to expire immediately.
        If $True is specified for the ImmediatelyExpireSupersedenceForFeature parameter, do not use this parameter.

    .PARAMETER Start
        Specifies the start date and start time for the synchronization schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the synchronization schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyWeekOrder
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER EnableManualCertManagement
        Specifies whether manual management of the WSUS signing certificate is enabled.

    .PARAMETER EnableThirdPartyUpdates
        Specifies whether third-party updates are enabled on the Software Update Point Component.

    .PARAMETER FeatureUpdateMaxRuntimeMins
        Specifies the maximum runtime, in minutes, for windows feature updates.

    .PARAMETER NonFeatureUpdateMaxRuntimeMins
        Specifies the maximum runtime, in minutes, for Office 365 updates and windows non-feature updates.

    .Notes
        After disabling or enabling synchronization, the GUI is slow to update, but the values are set correctly.
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
        [String[]]
        $LanguageSummaryDetails,

        [Parameter()]
        [String[]]
        $LanguageSummaryDetailsToInclude,

        [Parameter()]
        [String[]]
        $LanguageSummaryDetailsToExclude,

        [Parameter()]
        [String[]]
        $LanguageUpdateFiles,

        [Parameter()]
        [String[]]
        $LanguageUpdateFilesToInclude,

        [Parameter()]
        [String[]]
        $LanguageUpdateFilesToExclude,

        [Parameter()]
        [String[]]
        $Products,

        [Parameter()]
        [String[]]
        $ProductsToInclude,

        [Parameter()]
        [String[]]
        $ProductsToExclude,

        [Parameter()]
        [String[]]
        $UpdateClassifications,

        [Parameter()]
        [String[]]
        $UpdateClassificationsToInclude,

        [Parameter()]
        [String[]]
        $UpdateClassificationsToExclude,

        [Parameter()]
        [ValidateSet('FullFilesOnly', 'ExpressForWindows10Only')]
        [String]
        $ContentFileOption,

        [Parameter()]
        [String]
        $DefaultWsusServer,

        [Parameter()]
        [Boolean]
        $EnableCallWsusCleanupWizard,

        [Parameter()]
        [Boolean]
        $EnableSyncFailureAlert,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [Boolean]
        $ImmediatelyExpireSupersedence,

        [Parameter()]
        [Boolean]
        $ImmediatelyExpireSupersedenceForFeature,

        [Parameter()]
        [ValidateSet('CreateAllWsusReportingEvents', 'CreateOnlyWsusStatusReportingEvents', 'DoNotCreateWsusReportingEvents')]
        [String]
        $ReportingEvent,

        [Parameter()]
        [ValidateSet('SynchronizeFromMicrosoftUpdate', 'SynchronizeFromAnUpstreamDataSourceLocation', 'DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource')]
        [String]
        $SynchronizeAction,

        [Parameter()]
        [String]
        $UpstreamSourceLocation,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $WaitMonth,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $WaitMonthForFeature,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours')]
        [String]
        $ScheduleType,

        [Parameter()]
        [ValidateRange(1,31)]
        [UInt32]
        $RecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $MonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $DayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $DayOfMonth,

        [Parameter()]
        [Boolean]
        $EnableManualCertManagement,

        [Parameter()]
        [Boolean]
        $EnableThirdPartyUpdates,

        [Parameter()]
        [ValidateRange(5,9999)]
        [UInt32]
        $FeatureUpdateMaxRuntimeMins,

        [Parameter()]
        [ValidateRange(5,9999)]
        [UInt32]
        $NonFeatureUpdateMaxRuntimeMins
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode

    try
    {
        $nonChildParams = @('LanguageSummaryDetails','LanguageSummaryDetailsToInclude','LanguageSummaryDetailsToExclude','Products','ProductsToInclude','ProductsToExclude','UpdateClassifications',
        'UpdateClassificationsToInclude','UpdateClassificationsToExclude','ContentFileOption','DefaultWsusServer','EnableCallWsusCleanupWizard','EnableSyncFailureAlert','EnableSynchronization',
        'ImmediatelyExpireSupersedence','ImmediatelyExpireSupersedenceForFeature','SynchronizeAction','UpstreamSourceLocation','WaitMonth','WaitMonthForFeature','EnableThirdPartyUpdates',
        'EnableManualCertManagement','FeatureUpdateMaxRuntimeMins','NonFeatureUpdateMaxRuntimeMins','ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')

        $availableLangs = @('Arabic','Bulgarian','Chinese (Simplified, PRC)','Chinese (Traditional, Hong Kong S.A.R.)','Chinese (Traditional, Taiwan)','Croatian','Czech','Danish','Dutch','English',
        'Estonian','Finnish','French','German','Greek','Hebrew','Hindi','Hungarian','Italian','Japanese','Korean','Latvian','Lithuanian','Norwegian','Polish','Portuguese','Portuguese (Brazil)',
        'Romanian','Russian','Serbian','Slovak','Slovenian','Spanish','Swedish','Thai','Turkish','Ukrainian')

        $langs = $LanguageUpdateFiles + $LanguageUpdateFilesToInclude + $LanguageUpdateFilesToExclude + $LanguageSummaryDetails + $LanguageSummaryDetailsToInclude + $LanguageSummaryDetailsToExclude
        $cats = $Products + $ProductsToInclude + $ProductsToExclude + $UpdateClassifications + $UpdateClassificationsToInclude + $UpdateClassificationsToExclude

        foreach ($lang in $langs.Where({ $_ -ne $null }))
        {
            if ($availableLangs -notcontains $lang)
            {
                throw ($script:localizedData.InvalidLangs -f $lang)
            }
        }

        foreach ($cat in $cats.Where({ $_ -ne $null }))
        {
            if ($state.AvailableCats -notcontains $cat)
            {
                throw ($script:localizedData.InvalidCats -f $cat)
            }
        }

        if ($state.ChildSite -eq $true)
        {
            foreach ($child in $nonChildParams)
            {
                if ($PSBoundParameters.ContainsKey($child))
                {
                    Write-Warning -Message ($script:localizedData.ChildBadParams -f $child)
                }
            }

            if ($LanguageUpdateFiles -or $LanguageUpdateFilesToInclude -or $LanguageUpdateFilesToExclude)
            {
                if ($LanguageUpdateFilesToInclude -and $LanguageUpdateFilesToExclude)
                {
                    foreach ($item in $LanguageUpdateFilesToInclude)
                    {
                        if ($LanguageUpdateFilesToExclude -contains $item)
                        {
                            throw ($script:localizedData.LangFilesInEx -f $item)
                        }
                    }
                }

                $langFileArray = @{
                    Match        = $LanguageUpdateFiles
                    Include      = $LanguageUpdateFilesToInclude
                    Exclude      = $LanguageUpdateFilesToExclude
                    CurrentState = $state.LanguageUpdateFiles
                }

                $langFileCompare = Compare-MultipleCompares @langFileArray

                if ($langFileCompare.Missing)
                {
                    $buildingParams += @{
                        AddLanguageUpdateFile = $langFileCompare.Missing
                    }
                }

                if ($langFileCompare.Remove)
                {
                    $buildingParams += @{
                        RemoveLanguageUpdateFile = $langFileCompare.Remove
                    }
                }

                if ($state.LanguageUpdateFiles.Count + $langFileCompare.Missing.Count - $langFileCompare.Remove.Count -eq 0)
                {
                    throw $script:localizedData.AllUpdateRemoved
                }
            }

            if ($ReportingEvent -ne $state.ReportingEvent)
            {
                Write-Verbose -Message ($script:localizedData.SettingValue -f 'ReportingEvent', $ReportingEvent)
                $buildingParams += @{
                    ReportingEvent = $ReportingEvent
                }
            }
        }
        else {
            if (($PSBoundParameters.ImmediatelyExpireSupersedence -eq $false) -and
               (-not $PSBoundParameters.ContainsKey('WaitMonth')))
            {
                throw $script:localizedData.WaitMonthNull
            }

            if (($PSBoundParameters.ImmediatelyExpireSupersedence -eq $true) -and
               ($PSBoundParameters.ContainsKey('WaitMonth')))
            {
                throw $script:localizedData.WaitMonthNeeded
            }

            if (($PSBoundParameters.ImmediatelyExpireSupersedenceForFeature -eq $false) -and
               (-not $PSBoundParameters.ContainsKey('WaitMonthForFeature')))
            {
                throw $script:localizedData.WaitFeatureNull
            }

            if (($PSBoundParameters.ImmediatelyExpireSupersedenceForFeature -eq $true) -and
               ($PSBoundParameters.ContainsKey('WaitMonthForFeature')))
            {
                throw $script:localizedData.WaitFeatureNeeded
            }

            if (($PSBoundParameters.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation') -and
               (-not $PSBoundParameters.ContainsKey('UpstreamSourceLocation')))
            {
                throw $script:localizedData.UpstreamSourceNull
            }

            if (($PSBoundParameters.EnableThirdPartyUpdates -eq $false) -and
               ($PSBoundParameters.ContainsKey('EnableManualCertManagement')))
            {
                throw $script:localizedData.CertMgmtSpecified
            }

            if (($PSBoundParameters.EnableSynchronization -eq $false) -and
               ($PSBoundParameters.ContainsKey('ScheduleType')))
            {
                throw $script:localizedData.ScheduleNoSync
            }

            if (($PSBoundParameters.EnableSynchronization -eq $true) -and
               (-not $PSBoundParameters.ContainsKey('ScheduleType')))
            {
                throw $script:localizedData.SyncNoSchedule
            }

            if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
            {
                throw $script:localizedData.MissingScheduleType
            }

            if ($LanguageSummaryDetails -or $LanguageSummaryDetailsToInclude -or $LanguageSummaryDetailsToExclude)
            {
                if ($LanguageSummaryDetailsToInclude -and $LanguageSummaryDetailsToExclude)
                {
                    foreach ($item in $LanguageSummaryDetailsToInclude)
                    {
                        if ($LanguageSummaryDetailsToExclude -contains $item)
                        {
                            throw ($script:localizedData.LangSumInEx -f $item)
                        }
                    }
                }

                $langSumArray = @{
                    Match        = $LanguageSummaryDetails
                    Include      = $LanguageSummaryDetailsToInclude
                    Exclude      = $LanguageSummaryDetailsToExclude
                    CurrentState = $state.LanguageSummaryDetails
                }

                $langSumCompare = Compare-MultipleCompares @langSumArray

                if ($langSumCompare.Missing)
                {
                    $buildingParams += @{
                        AddLanguageSummaryDetail = $langSumCompare.Missing
                    }
                }

                if ($langSumCompare.Remove)
                {
                    $buildingParams += @{
                        RemoveLanguageSummaryDetail = $langSumCompare.Remove
                    }
                }

                if ($state.LanguageSummaryDetails.Count + $langSumCompare.Missing.Count - $langSumCompare.Remove.Count -eq 0)
                {
                    throw $script:localizedData.AllSummaryRemoved
                }
            }

            if ($LanguageUpdateFiles -or $LanguageUpdateFilesToInclude -or $LanguageUpdateFilesToExclude)
            {
                if ($LanguageUpdateFilesToInclude -and $LanguageUpdateFilesToExclude)
                {
                    foreach ($item in $LanguageUpdateFilesToInclude)
                    {
                        if ($LanguageUpdateFilesToExclude -contains $item)
                        {
                            throw ($script:localizedData.LangFilesInEx -f $item)
                        }
                    }
                }

                $langFileArray = @{
                    Match        = $LanguageUpdateFiles
                    Include      = $LanguageUpdateFilesToInclude
                    Exclude      = $LanguageUpdateFilesToExclude
                    CurrentState = $state.LanguageUpdateFiles
                }

                $langFileCompare = Compare-MultipleCompares @langFileArray

                if ($langFileCompare.Missing)
                {
                    $buildingParams += @{
                        AddLanguageUpdateFile = $langFileCompare.Missing
                    }
                }

                if ($langFileCompare.Remove)
                {
                    $buildingParams += @{
                        RemoveLanguageUpdateFile = $langFileCompare.Remove
                    }
                }

                if ($state.LanguageUpdateFiles.Count + $langFileCompare.Missing.Count - $langFileCompare.Remove.Count -eq 0)
                {
                    throw $script:localizedData.AllUpdateRemoved
                }
            }

            if ($Products -or $ProductsToInclude -or $ProductsToExclude)
            {
                if ($ProductsToInclude -and $ProductsToExclude)
                {
                    foreach ($item in $ProductsToInclude)
                    {
                        if ($ProductsToExclude -contains $item)
                        {
                            throw ($script:localizedData.ProductsInEx -f $item)
                        }
                    }
                }

                $productsArray = @{
                    Match        = $Products
                    Include      = $ProductsToInclude
                    Exclude      = $ProductsToExclude
                    CurrentState = $state.Products
                }

                $productsCompare = Compare-MultipleCompares @productsArray

                if ($productsCompare.Missing)
                {
                    $buildingParams += @{
                        AddProduct = $productsCompare.Missing
                    }
                }

                if ($productsCompare.Remove)
                {
                    $buildingParams += @{
                        RemoveProduct = $productsCompare.Remove
                    }
                }

            }

            if ($UpdateClassifications -or $UpdateClassificationsToInclude -or $UpdateClassificationsToExclude)
            {
                if ($UpdateClassificationsToInclude -and $UpdateClassificationsToExclude)
                {
                    foreach ($item in $UpdateClassificationsToInclude)
                    {
                        if ($UpdateClassificationsToExclude -contains $item)
                        {
                            throw ($script:localizedData.UpdateClassInEx -f $item)
                        }
                    }
                }

                $classArray = @{
                    Match        = $UpdateClassifications
                    Include      = $UpdateClassificationsToInclude
                    Exclude      = $UpdateClassificationsToExclude
                    CurrentState = $state.UpdateClassifications
                }

                $classCompare = Compare-MultipleCompares @classArray

                if ($classCompare.Missing)
                {
                    $buildingParams += @{
                        AddUpdateClassification = $classCompare.Missing
                    }
                }

                if ($classCompare.Remove)
                {
                    $buildingParams += @{
                        RemoveUpdateClassification = $classCompare.Remove
                    }
                }

            }

            if ($ScheduleType)
            {
                $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $scheduleCheck += @{
                            $item = $PSBoundParameters[$item]
                        }
                    }
                }

                $schedResult = Test-CMSchedule @scheduleCheck -State $state

                if ($schedResult -eq $false)
                {
                    $sched = Set-CMSchedule @scheduleCheck
                    $newSchedule = New-CMSchedule @sched

                    Write-Verbose -Message $script:localizedData.NewSchedule
                    $buildingParams += @{
                        Schedule = $newSchedule
                    }
                }
            }

            $evalList = @('ContentFileOption','DefaultWsusServer','EnableCallWsusCleanupWizard','EnableSyncFailureAlert','EnableSynchronization',
                'ImmediatelyExpireSupersedence','ImmediatelyExpireSupersedenceForFeature','ReportingEvent','SynchronizeAction','UpstreamSourceLocation',
                'WaitMonth','WaitMonthForFeature','EnableThirdPartyUpdates','EnableManualCertManagement','FeatureUpdateMaxRuntimeMins','NonFeatureUpdateMaxRuntimeMins')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($evalList -contains $param.Key)
                {
                    if ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }

                    if (($param.Value -ne $state[$param.Key]) -and ($param.Key -eq 'EnableSynchronization') -and ($param.Value -eq $false))
                    {
                        Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                        $buildingParams += @{
                            Schedule = $null
                        }
                    }
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMSoftwareUpdatePointComponent @buildingParams
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
        Specifies a site code for the Configuration Manager site that manages the system role for the software update point component.

    .PARAMETER LanguageSummaryDetails
        Specifies an array of languages desired for the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageSummaryDetailsToInclude
        Specifies an array of languages to include in the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageSummaryDetailsToExclude
        Specifies an array of languages to exclude from the languages supported for software updates summary details at the specified site.

    .PARAMETER LanguageUpdateFiles
        Specifies an array of languages desired for the languages supported for software updates at the specified site.

    .PARAMETER LanguageUpdateFilesToInclude
        Specifies an array of languages to include in the languages supported for software updates at the specified site.

    .PARAMETER LanguageUpdateFilesToExclude
        Specifies an array of languages to exclude from the languages supported for software updates at the specified site.

    .PARAMETER Products
        Specifies an array of products desired for software updates to synchronize.

    .PARAMETER ProductsToInclude
        Specifies an array of products to include in software updates to synchronize.

    .PARAMETER ProductsToExclude
        Specifies an array of products to exclude from software updates to synchronize.

    .PARAMETER UpdateClassifications
        Specifies an array of software update classifications desired for the classifications supported for software updates at this site.

    .PARAMETER UpdateClassificationsToInclude
        Specifies an array of software update classifications to include in the classifications supported for software updates at this site.

    .PARAMETER UpdateClassificationsToExclude
        Specifies an array of software update classifications to exclude from the classifications supported for software updates at this site.

    .PARAMETER ContentFileOption
        Specifies whether express updates will be downloaded for Windows 10. The acceptable values for this parameter are:

        FullFilesOnly
        ExpressForWindows10Only

    .PARAMETER DefaultWsusServer
        Specifies the default WSUS server that the software update point is pointed to.

    .PARAMETER EnableCallWsusCleanupWizard
        Specifies whether to decline expired updates in WSUS according to superscedence rules.

    .PARAMETER EnableSyncFailureAlert
        Specifies whether Configuration Manager creates an alert when synchronization fails on a site.

    .PARAMETER EnableSynchronization
        Indicates whether this site automatically synchronizes updates according to a schedule.

    .PARAMETER ImmediatelyExpireSupersedence
        Indicates whether a software update expires immediately after another update supersedes it or after a specified period of time.
        If you specify a value of $false for this parameter, specify the number of months to wait for expiration by using the WaitMonth parameter.
        If you specify a value of $true for this parameter, do not specify the WaitMonth parameter.

    .PARAMETER ImmediatelyExpireSupersedenceForFeature
        Indicates whether a feature update expires immediately after another update supersedes it or after a specified period of time.
        If you specify a value of $false for this parameter, specify the number of months to wait for expiration by using the WaitMonthForFeature parameter.
        If you specify a value of $true for this parameter, do not specify the WaitMonthForFeature parameter.

    .PARAMETER ReportingEvent
        Specifies whether to create event messages for WSUS reporting for status reporting events or for all reporting events. The acceptable values for this parameter are:

        CreateAllWsusReportingEvents
        CreateOnlyWsusStatusReportingEvents
        DoNotCreateWsusReportingEvents

    .PARAMETER SynchronizeAction
        Specifies a source for synchronization for this software update point. The acceptable values for this parameter are:

        SynchronizeFromMicrosoftUpdate
        SynchronizeFromAnUpstreamDataSourceLocation
        DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource

        If you select a value of SynchronizeFromAnUpstreamDataSourceLocation, specify the data source location by using the UpstreamSourceLocation parameter.

    .PARAMETER UpstreamSourceLocation
        Specifies an upstream data location as a URL.
        To use this location, specify a value of SynchronizeFromAnUpstreamDataSourceLocation for the SynchronizeAction parameter.

    .PARAMETER WaitMonth
        Specifies how long, in months, to wait before a software update expires after another update supersedes it.
        Specify a value of $True for the ImmediatelyExpireSupersedence parameter for software updates to expire immediately.
        If $True is specified for the ImmediatelyExpireSupersedence parameter, do not use this parameter.

    .PARAMETER WaitMonthForFeature
        Specifies how long, in months, to wait before a feature update expires after another update supersedes it.
        Specify a value of $True for the ImmediatelyExpireSupersedenceForFeature parameter for software updates to expire immediately.
        If $True is specified for the ImmediatelyExpireSupersedenceForFeature parameter, do not use this parameter.

    .PARAMETER Start
        Specifies the start date and start time for the synchronization schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the synchronization schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyWeekOrder
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER EnableManualCertManagement
        Specifies whether manual management of the WSUS signing certificate is enabled.

    .PARAMETER EnableThirdPartyUpdates
        Specifies whether third-party updates are enabled on the Software Update Point Component.

    .PARAMETER FeatureUpdateMaxRuntimeMins
        Specifies the maximum runtime, in minutes, for windows feature updates.

    .PARAMETER NonFeatureUpdateMaxRuntimeMins
        Specifies the maximum runtime, in minutes, for Office 365 updates and windows non-feature updates.
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
        [String[]]
        $LanguageSummaryDetails,

        [Parameter()]
        [String[]]
        $LanguageSummaryDetailsToInclude,

        [Parameter()]
        [String[]]
        $LanguageSummaryDetailsToExclude,

        [Parameter()]
        [String[]]
        $LanguageUpdateFiles,

        [Parameter()]
        [String[]]
        $LanguageUpdateFilesToInclude,

        [Parameter()]
        [String[]]
        $LanguageUpdateFilesToExclude,

        [Parameter()]
        [String[]]
        $Products,

        [Parameter()]
        [String[]]
        $ProductsToInclude,

        [Parameter()]
        [String[]]
        $ProductsToExclude,

        [Parameter()]
        [String[]]
        $UpdateClassifications,

        [Parameter()]
        [String[]]
        $UpdateClassificationsToInclude,

        [Parameter()]
        [String[]]
        $UpdateClassificationsToExclude,

        [Parameter()]
        [ValidateSet('FullFilesOnly', 'ExpressForWindows10Only')]
        [String]
        $ContentFileOption,

        [Parameter()]
        [String]
        $DefaultWsusServer,

        [Parameter()]
        [Boolean]
        $EnableCallWsusCleanupWizard,

        [Parameter()]
        [Boolean]
        $EnableSyncFailureAlert,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [Boolean]
        $ImmediatelyExpireSupersedence,

        [Parameter()]
        [Boolean]
        $ImmediatelyExpireSupersedenceForFeature,

        [Parameter()]
        [ValidateSet('CreateAllWsusReportingEvents', 'CreateOnlyWsusStatusReportingEvents', 'DoNotCreateWsusReportingEvents')]
        [String]
        $ReportingEvent,

        [Parameter()]
        [ValidateSet('SynchronizeFromMicrosoftUpdate', 'SynchronizeFromAnUpstreamDataSourceLocation', 'DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource')]
        [String]
        $SynchronizeAction,

        [Parameter()]
        [String]
        $UpstreamSourceLocation,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $WaitMonth,

        [Parameter()]
        [ValidateRange(1,99)]
        [UInt32]
        $WaitMonthForFeature,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours')]
        [String]
        $ScheduleType,

        [Parameter()]
        [ValidateRange(1,31)]
        [UInt32]
        $RecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $MonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $DayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $DayOfMonth,

        [Parameter()]
        [Boolean]
        $EnableManualCertManagement,

        [Parameter()]
        [Boolean]
        $EnableThirdPartyUpdates,

        [Parameter()]
        [ValidateRange(5,9999)]
        [UInt32]
        $FeatureUpdateMaxRuntimeMins,

        [Parameter()]
        [ValidateRange(5,9999)]
        [UInt32]
        $NonFeatureUpdateMaxRuntimeMins
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true

    $nonChildParams = @('LanguageSummaryDetails','LanguageSummaryDetailsToInclude','LanguageSummaryDetailsToExclude','Products','ProductsToInclude','ProductsToExclude','UpdateClassifications',
        'UpdateClassificationsToInclude','UpdateClassificationsToExclude','ContentFileOption','DefaultWsusServer','EnableCallWsusCleanupWizard','EnableSyncFailureAlert','EnableSynchronization',
        'ImmediatelyExpireSupersedence','ImmediatelyExpireSupersedenceForFeature','SynchronizeAction','UpstreamSourceLocation','WaitMonth','WaitMonthForFeature','EnableThirdPartyUpdates',
        'EnableManualCertManagement','FeatureUpdateMaxRuntimeMins','NonFeatureUpdateMaxRuntimeMins','ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')

    $availableLangs = @('Arabic','Bulgarian','Chinese (Simplified, PRC)','Chinese (Traditional, Hong Kong S.A.R.)','Chinese (Traditional, Taiwan)','Croatian','Czech','Danish','Dutch','English',
        'Estonian','Finnish','French','German','Greek','Hebrew','Hindi','Hungarian','Italian','Japanese','Korean','Latvian','Lithuanian','Norwegian','Polish','Portuguese','Portuguese (Brazil)',
        'Romanian','Russian','Serbian','Slovak','Slovenian','Spanish','Swedish','Thai','Turkish','Ukrainian')

    $langs = $LanguageUpdateFiles + $LanguageUpdateFilesToInclude + $LanguageUpdateFilesToExclude + $LanguageSummaryDetails + $LanguageSummaryDetailsToInclude + $LanguageSummaryDetailsToExclude
    $cats = $Products + $ProductsToInclude + $ProductsToExclude + $UpdateClassifications + $UpdateClassificationsToInclude + $UpdateClassificationsToExclude

    foreach ($lang in $langs.Where({ $_ -ne $null }))
    {
        if ($availableLangs -notcontains $lang)
        {
            Write-Warning -Message ($script:localizedData.InvalidLangs -f $lang)
            $result = $false
        }
    }

    foreach ($cat in $cats.Where({ $_ -ne $null }))
    {
        if ($state.AvailableCats -notcontains $cat)
        {
            Write-Warning -Message ($script:localizedData.InvalidCats -f $cat)
            $result = $false
        }
    }

    if ($state.ChildSite -eq $true)
    {
        foreach ($child in $nonChildParams)
        {
            if ($PSBoundParameters.ContainsKey($child))
            {
                Write-Warning -Message ($script:localizedData.ChildBadParams -f $child)
            }
        }

        if ($LanguageUpdateFiles -or $LanguageUpdateFilesToInclude -or $LanguageUpdateFilesToExclude)
        {
            if ($LanguageUpdateFilesToInclude -and $LanguageUpdateFilesToExclude)
            {
                foreach ($item in $LanguageUpdateFilesToInclude)
                {
                    if ($LanguageUpdateFilesToExclude -contains $item)
                    {
                        Write-Warning -Message ($script:localizedData.LangFilesInEx -f $item)
                        $result = $false
                    }
                }
            }

            $languageUpdateFilesArray = @{
                Match        = $LanguageUpdateFiles
                Include      = $LanguageUpdateFilesToInclude
                Exclude      = $LanguageUpdateFilesToExclude
                CurrentState = $state.LanguageUpdateFiles
            }

            $languageUpdateFilesCompare = Compare-MultipleCompares @languageUpdateFilesArray

            if ($PSBoundParameters.ContainsKey('LanguageUpdateFiles'))
            {
                if ($PSBoundParameters.ContainsKey('LanguageUpdateFilesToInclude') -or $PSBoundParameters.ContainsKey('LanguageUpdateFilesToExclude'))
                {
                    Write-Warning -Message $script:localizedData.LanguageUpdateIgnore
                }
            }

            if ($languageUpdateFilesCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.LanguageUpdateMissing -f ($languageUpdateFilesCompare.Missing | Out-String))
                $result = $false
            }

            if ($languageUpdateFilesCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.LanguageUpdateRemove -f ($languageUpdateFilesCompare.Remove | Out-String))
                $result = $false
            }

            if ($state.LanguageUpdateFiles.Count + $languageUpdateFilesCompare.Missing.Count - $languageUpdateFilesCompare.Remove.Count -eq 0)
            {
                Write-Warning -Message $script:localizedData.AllUpdateRemoved
                $result = $false
            }
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = @('ReportingEvent')
        }

        $mainState = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

        if (-not [string]::IsNullOrEmpty($mainState) -and $mainState -eq $false)
        {
            $result = $false
        }
    }
    else
    {
        if (($PSBoundParameters.ImmediatelyExpireSupersedence -eq $false) -and
           (-not $PSBoundParameters.ContainsKey('WaitMonth')))
        {
            Write-Warning -Message $script:localizedData.WaitMonthNull
            $result = $false
        }

        if (($PSBoundParameters.ImmediatelyExpireSupersedence -eq $true) -and
           ($PSBoundParameters.ContainsKey('WaitMonth')))
        {
            Write-Warning -Message $script:localizedData.WaitMonthNeeded
            $result = $false
        }

        if (($PSBoundParameters.ImmediatelyExpireSupersedenceForFeature -eq $false) -and
           (-not $PSBoundParameters.ContainsKey('WaitMonthForFeature')))
        {
            Write-Warning -Message $script:localizedData.WaitFeatureNull
            $result = $false
        }

        if (($PSBoundParameters.ImmediatelyExpireSupersedenceForFeature -eq $true) -and
           ($PSBoundParameters.ContainsKey('WaitMonthForFeature')))
        {
            Write-Warning -Message $script:localizedData.WaitFeatureNeeded
            $result = $false
        }

        if (($PSBoundParameters.SynchronizeAction -eq 'SynchronizeFromAnUpstreamDataSourceLocation') -and
           (-not $PSBoundParameters.ContainsKey('UpstreamSourceLocation')))
        {
            Write-Warning -Message $script:localizedData.UpstreamSourceNull
            $result = $false
        }

        if (($PSBoundParameters.EnableThirdPartyUpdates -eq $false) -and
           ($PSBoundParameters.ContainsKey('EnableManualCertManagement')))
        {
            Write-Warning -Message $script:localizedData.CertMgmtSpecified
            $result = $false
        }

        if (($PSBoundParameters.EnableSynchronization -eq $false) -and
           ($PSBoundParameters.ContainsKey('ScheduleType')))
        {
            Write-Warning -Message $script:localizedData.ScheduleNoSync
            $result = $false
        }

        if (($PSBoundParameters.EnableSynchronization -eq $true) -and
           (-not $PSBoundParameters.ContainsKey('ScheduleType')))
        {
            Write-Warning -Message $script:localizedData.SyncNoSchedule
            $result = $false
        }

        if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
        {
            Write-Warning -Message $script:localizedData.MissingScheduleType
            $result = $false
        }

        if ($LanguageSummaryDetails -or $LanguageSummaryDetailsToInclude -or $LanguageSummaryDetailsToExclude)
        {
            if ($LanguageSummaryDetailsToInclude -and $LanguageSummaryDetailsToExclude)
            {
                foreach ($item in $LanguageSummaryDetailsToInclude)
                {
                    if ($LanguageSummaryDetailsToExclude -contains $item)
                    {
                        Write-Warning -Message ($script:localizedData.LangSumInEx -f $item)
                        $result = $false
                    }
                }
            }

            $languageSummaryDetailsArray = @{
                Match        = $LanguageSummaryDetails
                Include      = $LanguageSummaryDetailsToInclude
                Exclude      = $LanguageSummaryDetailsToExclude
                CurrentState = $state.LanguageSummaryDetails
            }

            $languageSummaryDetailsCompare = Compare-MultipleCompares @languageSummaryDetailsArray

            if ($PSBoundParameters.ContainsKey('LanguageSummaryDetails'))
            {
                if ($PSBoundParameters.ContainsKey('LanguageSummaryDetailsToInclude') -or $PSBoundParameters.ContainsKey('LanguageSummaryDetailsToExclude'))
                {
                    Write-Warning -Message $script:localizedData.LanguageSummaryIgnore
                }
            }

            if ($languageSummaryDetailsCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.LanguageSummaryMissing -f ($languageSummaryDetailsCompare.Missing | Out-String))
                $result = $false
            }

            if ($languageSummaryDetailsCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.LanguageSummaryRemove -f ($languageSummaryDetailsCompare.Remove | Out-String))
                $result = $false
            }

            if ($state.LanguageSummaryDetails.Count + $languageSummaryDetailsCompare.Missing.Count - $languageSummaryDetailsCompare.Remove.Count -eq 0)
            {
                Write-Warning -Message $script:localizedData.AllSummaryRemoved
                $result = $false
            }
        }

        if ($LanguageUpdateFiles -or $LanguageUpdateFilesToInclude -or $LanguageUpdateFilesToExclude)
        {
            if ($LanguageUpdateFilesToInclude -and $LanguageUpdateFilesToExclude)
            {
                foreach ($item in $LanguageUpdateFilesToInclude)
                {
                    if ($LanguageUpdateFilesToExclude -contains $item)
                    {
                        Write-Warning -Message ($script:localizedData.LangFilesInEx -f $item)
                        $result = $false
                    }
                }
            }

            $languageUpdateFilesArray = @{
                Match        = $LanguageUpdateFiles
                Include      = $LanguageUpdateFilesToInclude
                Exclude      = $LanguageUpdateFilesToExclude
                CurrentState = $state.LanguageUpdateFiles
            }

            $languageUpdateFilesCompare = Compare-MultipleCompares @languageUpdateFilesArray

            if ($PSBoundParameters.ContainsKey('LanguageUpdateFiles'))
            {
                if ($PSBoundParameters.ContainsKey('LanguageUpdateFilesToInclude') -or $PSBoundParameters.ContainsKey('LanguageUpdateFilesToExclude'))
                {
                    Write-Warning -Message $script:localizedData.LanguageUpdateIgnore
                }
            }

            if ($languageUpdateFilesCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.LanguageUpdateMissing -f ($languageUpdateFilesCompare.Missing | Out-String))
                $result = $false
            }

            if ($languageUpdateFilesCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.LanguageUpdateRemove -f ($languageUpdateFilesCompare.Remove | Out-String))
                $result = $false
            }

            if ($state.LanguageUpdateFiles.Count + $languageUpdateFilesCompare.Missing.Count - $languageUpdateFilesCompare.Remove.Count -eq 0)
            {
                Write-Warning -Message $script:localizedData.AllUpdateRemoved
                $result = $false
            }
        }

        if ($Products -or $ProductsToInclude -or $ProductsToExclude)
        {
            if ($ProductsToInclude -and $ProductsToExclude)
            {
                foreach ($item in $ProductsToInclude)
                {
                    if ($ProductsToExclude -contains $item)
                    {
                        Write-Warning -Message ($script:localizedData.ProductsInEx -f $item)
                        $result = $false
                    }
                }
            }

            $productsArray = @{
                Match        = $Products
                Include      = $ProductsToInclude
                Exclude      = $ProductsToExclude
                CurrentState = $state.Products
            }

            $productsCompare = Compare-MultipleCompares @productsArray

            if ($PSBoundParameters.ContainsKey('Products'))
            {
                if ($PSBoundParameters.ContainsKey('ProductsToInclude') -or $PSBoundParameters.ContainsKey('ProductsToExclude'))
                {
                    Write-Warning -Message $script:localizedData.ProductsIgnore
                }
            }

            if ($productsCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.ProductsMissing -f ($productsCompare.Missing | Out-String))
                $result = $false
            }

            if ($productsCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.ProductsRemove -f ($productsCompare.Remove | Out-String))
                $result = $false
            }
        }

        if ($UpdateClassifications -or $UpdateClassificationsToInclude -or $UpdateClassificationsToExclude)
        {
            if ($UpdateClassificationsToInclude -and $UpdateClassificationsToExclude)
            {
                foreach ($item in $UpdateClassificationsToInclude)
                {
                    if ($UpdateClassificationsToExclude -contains $item)
                    {
                        Write-Warning -Message ($script:localizedData.UpdateClassInEx -f $item)
                        $result = $false
                    }
                }
            }

            $updateClassificationsArray = @{
                Match        = $UpdateClassifications
                Include      = $UpdateClassificationsToInclude
                Exclude      = $UpdateClassificationsToExclude
                CurrentState = $state.UpdateClassifications
            }

            $updateClassificationsCompare = Compare-MultipleCompares @updateClassificationsArray

            if ($PSBoundParameters.ContainsKey('UpdateClassifications'))
            {
                if ($PSBoundParameters.ContainsKey('UpdateClassificationsToInclude') -or $PSBoundParameters.ContainsKey('UpdateClassificationsToExclude'))
                {
                    Write-Warning -Message $script:localizedData.UpdateClassificationsIgnore
                }
            }

            if ($updateClassificationsCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.UpdateClassificationsMissing -f ($updateClassificationsCompare.Missing | Out-String))
                $result = $false
            }

            if ($updateClassificationsCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.UpdateClassificationsRemove -f ($updateClassificationsCompare.Remove | Out-String))
                $result = $false
            }
        }

        if ($ScheduleType)
        {
            $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')
            foreach ($item in $valuesToValidate)
            {
                if ($PSBoundParameters.ContainsKey($item))
                {
                    $scheduleCheck += @{
                        $item = $PSBoundParameters[$item]
                    }
                }
            }

            $schedResult = Test-CMSchedule @scheduleCheck -State $state

            if ($schedResult -ne $true)
            {
                $result = $false
            }
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = @('ContentFileOption','DefaultWsusServer','EnableCallWsusCleanupWizard','EnableSyncFailureAlert','EnableSynchronization',
                'ImmediatelyExpireSupersedence','ImmediatelyExpireSupersedenceForFeature','ReportingEvent','SynchronizeAction','UpstreamSourceLocation',
                'WaitMonth','WaitMonthForFeature','EnableThirdPartyUpdates','EnableManualCertManagement','FeatureUpdateMaxRuntimeMins','NonFeatureUpdateMaxRuntimeMins')
        }

        $mainState = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

        if (-not [string]::IsNullOrEmpty($mainState) -and $mainState -eq $false)
        {
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
