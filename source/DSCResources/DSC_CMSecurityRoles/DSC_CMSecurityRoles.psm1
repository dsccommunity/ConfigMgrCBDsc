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

    .PARAMETER SecurityRoleName
        Specifies the Security Role Name.
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
        $SecurityRoleName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $role = Get-CMSecurityRole -Name $SecurityRoleName

    if ($role)
    {
        foreach ($item in $role.Operations)
        {
            $ops = $ops + "$($item.ObjectTypeId)=$($item.GrantedOperations);"
        }

        if ($role.NumberOfAdmins -ge 1)
        {
            $users = Get-CMAdministrativeUser

            foreach ($user in $users)
            {
                if ($user.RoleNames -Contains $SecurityRoleName)
                {
                    [array]$adminUsers += $user.logonName
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
        SiteCode         = $SiteCode
        SecurityRoleName = $SecurityRoleName
        Description      = $role.RoleDescription
        Operation        = $ops
        UsersAssigned    = $adminUsers
        Ensure           = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER SecurityRoleName
        Specifies the Security Role Name.

    .PARAMETER Description
        Specifies the description of the Security Role.

    .PARAMETER XmlPath
        Specifies the path the Security Role xml file to evalute and import.

    .PARAMETER OverWrite
        Specifies if the Security Roles does not match the xml this will overwrite the policy.
        If Overwrite and Append is set to false the settings in the Role are not evaluated.

    .PARAMETER Append
        Specifies additional settings in the xml will be appended to the current Security Role.
        If Overwrite and Append are set to true, Append will be used.

    .PARAMETER Ensure
        Specifies if the Security Role is present or absent.
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
        $SecurityRoleName,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [ValidateScript({((Test-Path -Path $_) -and ($_.EndsWith('.xml')))})]
        [String]
        $XmlPath,

        [Parameter()]
        [Boolean]
        $OverWrite = $false,

        [Parameter()]
        [Boolean]
        $Append = $false,

        [Parameter()]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SecurityRoleName $SecurityRoleName

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($PSBoundParameters.ContainsKey('XmlPath') -and ($OverWrite -eq $true -or $Append -eq $true))
            {
                [xml]$xmlFile = Get-Content -Path $XmlPath
                $xmlContent = $xmlFile.SelectNodes("/SMS_Roles/SMS_Role/Operations/Operation")
                $xmlName = $xmlFile.SelectNodes("/SMS_Roles/SMS_Role").RoleName

                if ([string]::IsNullOrEmpty($xmlContent) -or [string]::IsNullOrEmpty($xmlName))
                {
                    throw $script:localizedData.InvalidXmlThow
                }

                if ($xmlName -ne $SecurityRoleName)
                {
                    throw $script:localizedData.XmlNameMismatch
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                if ([string]::IsNullOrEmpty($XMLPath))
                {
                    throw $script:localizedData.AbsentRoleXmlMissing
                }

                $applyXml = $true
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('XmlPath') -and $OverWrite -eq $false -and $Append -eq $false)
                {
                    Write-Warning -Message $script:localizedData.XmlFileNoOverwrite
                }
                elseif ($PSBoundParameters.ContainsKey('XmlPath') -and ($OverWrite -eq $true -or $Append -eq $true))
                {
                    if ($state.Operation)
                    {
                        $convert = $state.Operation.TrimEnd(';').Split(';')
                        $object = @{}
                        foreach ($item in $convert)
                        {
                            $sitem = $item.Split('=')

                            $object += @{
                                $sitem[0] = $sitem[1]
                            }
                        }

                        foreach ($item in $xmlContent)
                        {
                            if ($object.ContainsKey($item.ObjectTypeID))
                            {
                                if ($object[$item.ObjectTypeID] -ne $item.GrantedOperations)
                                {
                                    Write-Verbose -Message ($script:localizedData.SettingsMismatchSet -f $item.ObjectTypeID,$item.GrantedOperations)
                                    $applyXml = $true
                                }
                            }
                            else
                            {
                                Write-Verbose -Message ($script:localizedData.SettingsMismatchSet -f $item.ObjectTypeID,$item.GrantedOperations)
                                $applyXml = $true
                            }
                        }

                        foreach ($item in $object.GetEnumerator())
                        {
                            if ($xmlContent.ObjectTypeId -notcontains $item.Name)
                            {
                                if ($Append -eq $false)
                                {
                                    $action = 'over written'
                                    Write-Warning -Message ($script:localizedData.AdditionalSettings -f $SecurityRoleName,$action,$item.Name,$item.Value)
                                    $applyXml = $true
                                }
                                else
                                {
                                    $action = 'appended'
                                    Write-Warning -Message ($script:localizedData.AdditionalSettings -f $SecurityRoleName,$action,$item.Name,$item.Value)
                                    $primaryValue = $xmlFile.SMS_Roles.SMS_Role.Operations
                                    $orgValue = $xmlFile.SMS_Roles.SMS_Role.Operations.Operation
                                    $element = $orgValue[0].Clone()
                                    $element.ObjectTypeID = $item.Name
                                    $element.GrantedOperations = $item.Value
                                    $primaryValue.AppendChild($element)
                                    $saveXML = $true
                                }
                            }
                        }

                        if ($saveXML)
                        {
                            $renameFile = Get-ChildItem -Path $XmlPath
                            $dateStamp = Get-Date -UFormat "%Y-%m-%d-%H-%M-%S"
                            $newName = "$($renameFile.BaseName).$dateStamp.old"
                            Rename-Item -Path $renameFile.FullName -NewName $newName
                            $xmlFile.Save($XmlPath)
                            $applyXml = $true
                        }
                    }
                    else
                    {
                        Write-Warning -Message $script:localizedData.MissingGetConfig
                        $applyXml = $true
                    }
                }
            }

            if ($applyXml)
            {
                Import-CMSecurityRole -XmlFileName $XmlPath -Overwrite $true
            }

            if ($PSBoundParameters.ContainsKey('Description'))
            {
                $xmlDescription = (Get-CMSecurityRole -Name $SecurityRoleName).RoleDescription

                if ($Description -ne $xmlDescription)
                {
                    Write-Verbose -Message ($script:localizedData.DescriptionSet -f $Description)
                    Set-CMSecurityRole -Name $SecurityRoleName -Description $Description
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            if ($state.UsersAssigned)
            {
                Write-Warning -Message ($script:localizedData.RoleDeleteAdmin -f ($state.UsersAssigned | Out-String))
            }

            Write-Verbose -Message ($script:localizedData.DeleteRole -f $SecurityRoleName)
            Remove-CMSecurityRole -Name $SecurityRoleName -Force
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER SecurityRoleName
        Specifies the Security Role Name.

    .PARAMETER Description
        Specifies the description of the Security Role.

    .PARAMETER XmlPath
        Specifies the path the Security Role xml file to evalute and import.

    .PARAMETER OverWrite
        Specifies if the Security Roles does not match the xml this will overwrite the policy.
        If Overwrite and Append is set to false the settings in the Security Role are not evaluated.

    .PARAMETER Append
        Specifies additional settings in the xml will be appended to the current Security Role.
        If Overwrite and Append are set to true, Append will be used.

    .PARAMETER Ensure
        Specifies if the Security Role is present or absent.
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
        $SecurityRoleName,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [ValidateScript({((Test-Path -Path $_) -and ($_.EndsWith('.xml')))})]
        [String]
        $XmlPath,

        [Parameter()]
        [Boolean]
        $OverWrite = $false,

        [Parameter()]
        [Boolean]
        $Append = $false,

        [Parameter()]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SecurityRoleName $SecurityRoleName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            if ([string]::IsNullOrEmpty($XMLPath))
            {
                Write-Warning -Message $script:localizedData.AbsentRoleXmlMissing
            }

            $result = $false
        }
        else
        {
            if ($PSBoundParameters.ContainsKey('XmlPath') -and $OverWrite -eq $false -and $Append -eq $false)
            {
                Write-Warning -Message $script:localizedData.XmlFileNoOverwrite
                $result = $false
            }

            if ($PSBoundParameters.ContainsKey('XmlPath') -and ($OverWrite -eq $true -or $Append -eq $true))
            {
                if ($OverWrite -eq $true -and $Append -eq $true)
                {
                    Write-Warning -Message $script:localizedData.OverwriteAppend
                }

                [xml]$xmlFile = Get-Content -Path $XmlPath
                $xmlContent = $xmlFile.SelectNodes("/SMS_Roles/SMS_Role/Operations/Operation")
                $xmlName = $xmlFile.SelectNodes("/SMS_Roles/SMS_Role").RoleName

                if ([string]::IsNullOrEmpty($xmlContent) -or [string]::IsNullOrEmpty($xmlName))
                {
                    Write-Warning -Message ($script:localizedData.InvalidXml -f $XmlPath)
                    $result = $false
                }
                else
                {
                    if ($xmlName -ne $SecurityRoleName)
                    {
                        Write-Warning -Message $script:localizedData.XmlNameMismatch
                    }

                    if ($state.Operation)
                    {
                        $convert = $state.Operation.TrimEnd(';').Split(';')
                        $object = @{}
                        foreach ($item in $convert)
                        {
                            $sitem = $item.Split('=')

                            $object += @{
                                $sitem[0] = $sitem[1]
                            }
                        }

                        foreach ($item in $xmlContent)
                        {
                            if ($object.ContainsKey($item.ObjectTypeID))
                            {
                                if ($object[$item.ObjectTypeID] -ne $item.GrantedOperations)
                                {
                                    Write-Verbose -Message ($script:localizedData.SettingsMismatch -f $item.ObjectTypeId,$item.GrantedOperations,$object[$item.ObjectTypeID])
                                    $result = $false
                                }
                            }
                            else
                            {
                                Write-Verbose -Message ($script:localizedData.MissingSettings -f $item.ObjectTypeId,$item.GrantedOperations)
                                $result = $false
                            }
                        }

                        foreach ($item in $object.GetEnumerator())
                        {
                            if ($xmlContent.ObjectTypeId -notcontains $item.Name)
                            {
                                if ($Append -eq $true)
                                {
                                    $action = 'appended'
                                }
                                else
                                {
                                    $action = 'over written'
                                    $result = $false
                                }

                                Write-Warning -Message ($script:localizedData.AdditionalSettings -f $SecurityRoleName,$action,$item.Name,$item.Value)
                            }
                        }
                    }
                    else
                    {
                        Write-Verbose -Message $script:localizedData.MissingGetConfig
                        $result = $false
                    }
                }
            }

            if ($PSBoundParameters.ContainsKey('Description'))
            {
                if ($Description -ne $state.Description)
                {
                    Write-Verbose -Message ($script:localizedData.DescriptionMismatch -f $Description, $state.Description)
                    $result = $false
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        if ($state.UsersAssigned)
        {
            Write-Warning -Message ($script:localizedData.RoleDeleteAdmin -f ($state.UsersAssigned | Out-String))
        }

        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}
