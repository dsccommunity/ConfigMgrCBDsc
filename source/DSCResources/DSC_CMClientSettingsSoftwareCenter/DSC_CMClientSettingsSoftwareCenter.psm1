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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter EnableCustomize
        Specifies if custom software center is to be used.
        Not Used in Get.
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
        $ClientSettingName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableCustomize
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting SoftwareCenter

        if ($settings)
        {
            $portal = @('Software Center','Company Portal')[$settings.SC_UserPortal]

            if ($portal -eq 'Software Center')
            {
                if ($settings.SC_Old_Branding -eq 0)
                {
                    $customize = $false
                }
                else
                {
                    $customize = $true
                }

                if ($customize -eq $true)
                {
                    $xml = [xml]$settings.SettingsXml

                    if ($xml)
                    {
                        $orgName = $xml.settings.'brand-orgname'
                        $color = $xml.settings.'brand-color'
                        $hideApp = [System.Convert]::ToBoolean($xml.settings.'application-catalog-link-hidden')
                        $hideInstalled = [System.Convert]::ToBoolean($xml.settings.'software-list'.'installed-applications-hidden')
                        $hideUnapproved = [System.Convert]::ToBoolean($xml.settings.'software-list'.'unapproved-applications-hidden')
                        $validateTab = $xml.settings.'tab-visibility'.tab

                        foreach ($item in $validateTab)
                        {
                            switch ($item.Name)
                            {
                                'AvailableSoftware'  { $softwareTab = [System.Convert]::ToBoolean($item.visible) }
                                'Updates'            { $updateTab = [System.Convert]::ToBoolean($item.visible) }
                                'OSD'                { $osTab = [System.Convert]::ToBoolean($item.visible) }
                                'InstallationStatus' { $statusTab = [System.Convert]::ToBoolean($item.visible) }
                                'Compliance'         { $comTab = [System.Convert]::ToBoolean($item.visible) }
                                'Options'            { $opsTab = [System.Convert]::ToBoolean($item.visible) }
                            }
                        }
                    }
                }
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                   = $SiteCode
        ClientSettingName          = $ClientSettingName
        EnableCustomize            = $customize
        CompanyName                = $orgName
        ColorScheme                = $color
        HideApplicationCatalogLink = $hideApp
        HideInstalledApplication   = $hideInstalled
        HideUnapprovedApplication  = $hideUnapproved
        EnableApplicationsTab      = $softwareTab
        EnableUpdatesTab           = $updateTab
        EnableOperatingSystemsTab  = $osTab
        EnableStatusTab            = $statusTab
        EnableComplianceTab        = $comTab
        EnableOptionsTab           = $opsTab
        ClientSettingStatus        = $status
        ClientType                 = $type
        PortalType                 = $portal
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter EnableCustomize
        Specifies if custom software center is to be used.

    .Parameter CompanyName
        Specifies the company name to be used in software center.

    .PARAMETER ColorScheme
        Specifies in hex format the color to be used in software center.

    .PARAMETER HideApplicationCatalogLink
        Specifies if application catalog link is hidden.

    .PARAMETER HideInstalledApplication
        Specifies if installed applications are hidden.

    .PARAMETER HideUnapprovedApplication
        Specifies if unapproved applications are hidden.

    .PARAMETER EnableApplicationsTab
        Specifies if application tab is visible.

    .PARAMETER EnableUpdatesTab
        Specifies if updates tab is visible.

    .PARAMETER EnableOperatingSystemsTab
        Specifies if operating system tab is visible.

    .PARAMETER EnableStatusTab
        Specifies if status tab is visible.

    .PARAMETER EnableComplianceTab
        Specifies if compliance tab is visible.

    .PARAMETER EnableOptionsTab
        Specifies if options tab is visible.
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
        $ClientSettingName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableCustomize,

        [Parameter()]
        [String]
        $CompanyName,

        [Parameter()]
        [String]
        $ColorScheme,

        [Parameter()]
        [Boolean]
        $HideApplicationCatalogLink,

        [Parameter()]
        [Boolean]
        $HideInstalledApplication,

        [Parameter()]
        [Boolean]
        $HideUnapprovedApplication,

        [Parameter()]
        [Boolean]
        $EnableApplicationsTab,

        [Parameter()]
        [Boolean]
        $EnableUpdatesTab,

        [Parameter()]
        [Boolean]
        $EnableOperatingSystemsTab,

        [Parameter()]
        [Boolean]
        $EnableStatusTab,

        [Parameter()]
        [Boolean]
        $EnableComplianceTab,

        [Parameter()]
        [Boolean]
        $EnableOptionsTab
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -EnableCustomize $EnableCustomize
    $schedResult = $true

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($state.ClientType -eq 'User')
        {
            throw $script:localizedData.WrongClientType
        }

        if ($state.PortalType -eq 'Company Portal')
        {
            throw $script:localizedData.CompanyPortalMsg
        }

        if ($EnableCustomize -eq $true)
        {
            if ($PSBoundParameters.ContainsKey('ColorScheme'))
            {
                $regexPrefix = '^(#|0x)?[0-9,a-f]*$'

                if ($ColorScheme.Length -ne 7 -or $ColorScheme.SubString(0,1) -ne '#' -or
                    $ColorScheme -notmatch $regexPrefix)
                {
                    throw ($script:localizedData.ColorSchemeErrorMsg -f $ColorScheme)
                }
            }

            $tabsCheck = @('EnableApplicationsTab','EnableUpdatesTab','EnableOperatingSystemsTab','EnableStatusTab',
                'EnableComplianceTab','EnableOptionsTab')

            foreach ($item in $tabsCheck)
            {
                if ($PSBoundParameters.ContainsKey($item))
                {
                    $itemValue = Get-Variable -Name $item
                    $arrayOfTabs += @{
                        $item = $itemValue.Value
                    }
                }
                else
                {
                    if ([string]::IsNullOrEmpty($state.$item) -or $state.$item -eq $true)
                    {
                        $arrayOfTabs += @{
                            $item = $true
                        }
                    }
                    else
                    {
                        $arrayOfTabs += @{
                            $item = $false
                        }
                    }
                }
            }

            if ($arrayOfTabs.Values -notcontains $true)
            {
                throw $script:localizedData.TabsDisabled
            }

            $defaultValues = @('EnableCustomize','CompanyName','ColorScheme','HideApplicationCatalogLink',
                'HideInstalledApplication','HideUnapprovedApplication','EnableApplicationsTab',
                'EnableUpdatesTab','EnableOperatingSystemsTab','EnableStatusTab',
                'EnableComplianceTab','EnableOptionsTab')

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
        }
        elseif ($state.EnableCustomize -eq $true)
        {
            if ($PSBoundParameters.Keys.Count -ge 4)
            {
                Write-Warning -Message $script:localizedData.DisableIgnore
            }

            Write-Verbose -Message $script:localizedData.TestDisabled

            $buildingParams += @{
                EnableCustomize = $EnableCustomize
            }
        }

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingSoftwareCenter -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingSoftwareCenter -Name $ClientSettingName @buildingParams
            }
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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter EnableCustomize
        Specifies if custom software center is to be used.

    .Parameter CompanyName
        Specifies the company name to be used in software center.

    .PARAMETER ColorScheme
        Specifies in hex format the color to be used in software center.

    .PARAMETER HideApplicationCatalogLink
        Specifies if application catalog link is hidden.

    .PARAMETER HideInstalledApplication
        Specifies if installed applications are hidden.

    .PARAMETER HideUnapprovedApplication
        Specifies if unapproved applications are hidden.

    .PARAMETER EnableApplicationsTab
        Specifies if application tab is visible.

    .PARAMETER EnableUpdatesTab
        Specifies if updates tab is visible.

    .PARAMETER EnableOperatingSystemsTab
        Specifies if operating system tab is visible.

    .PARAMETER EnableStatusTab
        Specifies if status tab is visible.

    .PARAMETER EnableComplianceTab
        Specifies if compliance tab is visible.

    .PARAMETER EnableOptionsTab
        Specifies if options tab is visible.
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
        $ClientSettingName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableCustomize,

        [Parameter()]
        [String]
        $CompanyName,

        [Parameter()]
        [String]
        $ColorScheme,

        [Parameter()]
        [Boolean]
        $HideApplicationCatalogLink,

        [Parameter()]
        [Boolean]
        $HideInstalledApplication,

        [Parameter()]
        [Boolean]
        $HideUnapprovedApplication,

        [Parameter()]
        [Boolean]
        $EnableApplicationsTab,

        [Parameter()]
        [Boolean]
        $EnableUpdatesTab,

        [Parameter()]
        [Boolean]
        $EnableOperatingSystemsTab,

        [Parameter()]
        [Boolean]
        $EnableStatusTab,

        [Parameter()]
        [Boolean]
        $EnableComplianceTab,

        [Parameter()]
        [Boolean]
        $EnableOptionsTab
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -EnableCustomize $EnableCustomize
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    elseif ($state.PortalType -eq 'Company Portal')
    {
        Write-Warning -Message $script:localizedData.CompanyPortalMsg
        $result = $false
    }
    elseif ($state.ClientType -eq 'User')
    {
        Write-Warning -Message $script:localizedData.WrongClientType
        $result = $false
    }
    elseif ($EnableCustomize -eq $true)
    {
        if ($PSBoundParameters.ContainsKey('ColorScheme'))
        {
            $regexPrefix = '^(#|0x)?[0-9,a-f]*$'

            if ($ColorScheme.Length -ne 7 -or $ColorScheme.SubString(0,1) -ne '#' -or
                $ColorScheme -notmatch $regexPrefix)
            {
                Write-Warning -Message ($script:localizedData.ColorSchemeErrorMsg -f $ColorScheme)
                $badInput = $true
            }
        }

        $tabsCheck = @('EnableApplicationsTab','EnableUpdatesTab','EnableOperatingSystemsTab','EnableStatusTab',
            'EnableComplianceTab','EnableOptionsTab')

        foreach ($item in $tabsCheck)
        {
            if ($PSBoundParameters.ContainsKey($item))
            {
                $itemValue = Get-Variable -Name $item
                $arrayOfTabs += @{
                    $item = $itemValue.Value
                }
            }
            else
            {
                if ([string]::IsNullOrEmpty($state.$item) -or $state.$item -eq $true)
                {
                    $arrayOfTabs += @{
                        $item = $true
                    }
                }
                else
                {
                    $arrayOfTabs += @{
                        $item = $false
                    }
                }
            }
        }

        if ($arrayOfTabs.Values -notcontains $true)
        {
            Write-Warning -Message $script:localizedData.TabsDisabled
        }

        $defaultValues = @('EnableCustomize','CompanyName','ColorScheme','HideApplicationCatalogLink',
            'HideInstalledApplication','HideUnapprovedApplication','EnableApplicationsTab',
            'EnableUpdatesTab','EnableOperatingSystemsTab','EnableStatusTab',
            'EnableComplianceTab','EnableOptionsTab')

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }
    elseif ($state.EnableCustomize -eq $true)
    {
        if ($PSBoundParameters.Keys.Count -ge 4)
        {
            Write-Warning -Message $script:localizedData.DisableIgnore
        }

        Write-Verbose -Message $script:localizedData.TestDisabled
        $result = $false
    }

    if ($result -eq $false -or $badInput -eq $true)
    {
        $return = $false
    }
    else
    {
        $return = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $return)
    Set-Location -Path "$env:temp"
    return $return
}

Export-ModuleMember -Function *-TargetResource
