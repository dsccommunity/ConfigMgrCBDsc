[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMAdministrativeUser'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import Stub function
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'ConfigMgrCBDsc - DSC_CMAdministrativeUser\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {
                BeforeEach {
                    $getAdminUser = @{
                        SourceSite = 'Lab'
                        LogonName = 'contoso\User'
                        RoleNames = 'Security Administrator'
                        Permissions = @(
                            @{
                                CategoryName   = 'Default'
                                CategoryTypeId = 29
                            }
                            @{
                                CategoryName   = 'Test'
                                CategoryTypeId = 29
                            }
                            @{
                                CategoryName   = 'All Systems'
                                CategoryTypeId = 1
                            }
                            @{
                                CategoryName   = 'All Users and User Groups'
                                CategoryTypeId = 1
                            }
                        )
                    }

                    $getInput = @{
                        SiteCode = 'Lab'
                        AdminName = 'contoso\User'
                    }
                }

                It 'Should return desired result admin user present' {
                    Mock -CommandName Get-CMAdministrativeUser -MockWith { $getAdminUser }

                    $result = Get-TargetResource @getInput
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.AdminName   | Should -Be -ExpectedValue 'contoso\User'
                    $result.Roles       | Should -Be -ExpectedValue 'Security Administrator'
                    $result.Scopes      | Should -Be -ExpectedValue 'Default','Test'
                    $result.Collections | Should -Be -ExpectedValue 'All Systems','All Users and User Groups'
                    $result.Ensure      | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result admin user absent' {
                    Mock -CommandName Get-CMAdministrativeUser

                    $result = Get-TargetResource @getInput
                    $result             | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode    | Should -Be -ExpectedValue 'Lab'
                    $result.AdminName   | Should -Be -ExpectedValue 'contoso\User'
                    $result.Roles       | Should -Be -ExpectedValue $null
                    $result.Scopes      | Should -Be -ExpectedValue $null
                    $result.Collections | Should -Be -ExpectedValue $null
                    $result.Ensure      | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMAdministrativeUser\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $inputRolesDif = @{
                    SiteCode  = 'Lab'
                    AdminName = 'contoso\User'
                    Roles     = 'Full Administrator'
                }

                $inputScopeDif = @{
                    SiteCode  = 'Lab'
                    AdminName = 'contoso\User'
                    Scopes    = 'Test'
                }

                $inputCollectionDif = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Collections = 'All Systems','All Servers'
                }

                $getReturnPresent = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Roles       = 'Security Administrator'
                    Scopes      = 'Default'
                    Collections = 'All Systems','All Users and User Groups'
                    Ensure      = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Roles       = $null
                    Scopes      = $null
                    Collections = $null
                    Ensure      = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMAdministrativeUser
                Mock -CommandName Add-CMSecurityRoleToAdministrativeUser
                Mock -CommandName Remove-CMSecurityRoleFromAdministrativeUser
                Mock -CommandName Add-CMSecurityScopeToAdministrativeUser
                Mock -CommandName Remove-CMSecurityScopeFromAdministrativeUser
                Mock -CommandName Add-CMCollectionToAdministrativeUser
                Mock -CommandName Remove-CMCollectionFromAdministrativeUser
                Mock -CommandName Remove-CMAdministrativeUser
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputMatch = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Roles       = 'Security Administrator'
                        Scopes      = 'Default'
                        Collections = 'All Systems','All Users and User Groups'
                        Ensure      = 'Present'
                    }

                    $inputAbsent = @{
                        SiteCode  = 'Lab'
                        AdminName = 'contoso\User'
                        Ensure    = 'Absent'
                    }

                    Mock -CommandName Get-CMSecurityRole -MockWith { $true }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true}
                    Mock -CommandName Get-CMCollection -MockWith { $true }
                }

                It 'Should return desired result when deleting an administrator' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 1 -Scope It
                }

                It 'Should return desired result when creating a new administrator' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 2 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing roles for the administrator' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputRolesDif
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing scopes for the administrator' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputScopeDif
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should return desired result when changing collections for the administrator' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    Set-TargetResource @inputCollectionDif
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $getReturnPresentAll = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Roles       = 'Security Administrator'
                        Scopes      = 'All'
                        Collections = 'All Systems','All Users and User Groups'
                        Ensure      = 'Present'
                    }

                    $newUserNoRole = @{
                        SiteCode  = 'Lab'
                        AdminName = 'contoso\test'
                        Ensure    = 'Present'
                    }

                    $inputChangeAllScope = @{
                        SiteCode        = 'Lab'
                        AdminName       = 'contoso\User'
                        ScopesToInclude = 'All'
                    }

                    $inputRemoveAllScope = @{
                        SiteCode        = 'Lab'
                        AdminName       = 'contoso\User'
                        ScopesToExclude = 'All'
                    }

                    $dupRoles = @{
                        SiteCode       = 'Lab'
                        AdminName      = 'contoso\User'
                        RolesToInclude = 'Full Administrator'
                        RolesToExclude = 'Full Administrator'
                    }

                    $dupScopes = @{
                        SiteCode        = 'Lab'
                        AdminName       = 'contoso\User'
                        ScopesToInclude = 'Default'
                        ScopesToExclude = 'Default'
                    }

                    $dupCollections = @{
                        SiteCode             = 'Lab'
                        AdminName            = 'contoso\User'
                        CollectionsToInclude = 'Test1'
                        CollectionsToExclude = 'Test1'
                    }

                    $modifyAllScope = 'Unable to modify scope with Desired State Configuration as it is currently set to All'
                    $newUserNoRoleMsg = 'When administrative user does not exist, at least 1 valid role must be specified.'
                    $addAllScopes = 'Unable to add the All scopes setting via Desired State Configuration, All can be used for new account only.'
                    $removeAllScopes = 'Unable to remove the All scope via Desired State Configuration.'
                    $rolesInEx = 'RolesToExclude and RolesToInclude contain to same entry Full Administrator, remove from one of the arrays.'
                    $scopesInEx = 'ScopesToExclude and ScopesToInclude contain to same entry Default, remove from one of the arrays.'
                    $collInEx = 'CollectionsToExclude and CollectionsToInclude contain to same Test1, remove from one of the arrays.'

                    Mock -CommandName Get-CMSecurityRole
                    Mock -CommandName Get-CMSecurityScope
                    Mock -CommandName Get-CMCollection
                }

                It 'Should return throw when no valid security role is specified with a new user' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    { Set-TargetResource @newUserNoRole } | Should -Throw -ExpectedMessage $newUserNoRoleMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when the security role does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @inputRolesDif } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when scope does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @inputScopeDif } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when collection does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @inputCollectionDif } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when trying to change the All Scope' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentAll }

                    { Set-TargetResource @inputScopeDif } | Should -Throw -ExpectedMessage $modifyAllScope
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when trying to remove the All Scope' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentAll }

                    { Set-TargetResource @inputRemoveAllScope } | Should -Throw -ExpectedMessage $removeAllScopes
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when trying to add the All Scope' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @inputChangeAllScope } | Should -Throw -ExpectedMessage $addAllScopes
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when RolesToInclude and RolesToExclude have duplicate settings' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @dupRoles } | Should -Throw -ExpectedMessage $rolesInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when ScopesToInclude and ScopesToExclude have duplicate settings' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @dupScopes } | Should -Throw -ExpectedMessage $scopesInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }

                It 'Should throw when CollectionsToInclude and CollectionsToExclude have duplicate settings' {
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }

                    { Set-TargetResource @dupCollections } | Should -Throw -ExpectedMessage $collInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityRoleToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRoleFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMSecurityScopeToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityScopeFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMCollectionToAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMCollectionFromAdministrativeUser -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMAdministrativeUser -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMPullDistributionPoint\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnPresent = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Roles       = 'Security Administrator'
                    Scopes      = 'Default'
                    Collections = 'All Systems','All Users and User Groups'
                    Ensure      = 'Present'
                }

                $getReturnPresentAll = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Roles       = 'Security Administrator'
                    Scopes      = 'All'
                    Collections = 'All Systems','All Users and User Groups'
                    Ensure      = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode    = 'Lab'
                    AdminName   = 'contoso\User'
                    Roles       = $null
                    Scopes      = $null
                    Collections = $null
                    Ensure      = 'Absent'
                }

                $inputAbsent = @{
                    SiteCode  = 'Lab'
                    AdminName = 'contoso\User'
                    Ensure    = 'Absent'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource when get returns present' {
                BeforeEach {
                    $inputMatch = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Roles       = 'Security Administrator'
                        Scopes      = 'Default'
                        Collections = 'All Systems','All Users and User Groups'
                        Ensure      = 'Present'
                    }

                    $inputAllOptions = @{
                        SiteCode             = 'Lab'
                        AdminName            = 'contoso\User'
                        Roles                = 'Security Administrator'
                        RolesToInclude       = 'Full Administrator'
                        RolesToExclude       = 'Default Administrator'
                        Scopes               = 'Default'
                        ScopesToInclude      = 'Test'
                        ScopesToExclude      = 'Scope1'
                        Collections          = 'All Systems','All Users and User Groups'
                        CollectionsToInclude = 'All Servers'
                        CollectionsToExclude = 'All Workstations'
                        Ensure               = 'Present'
                    }

                    $inputRolesDif = @{
                        SiteCode  = 'Lab'
                        AdminName = 'contoso\User'
                        Roles     = 'Full Administrator'
                    }

                    $inputScopeDif = @{
                        SiteCode  = 'Lab'
                        AdminName = 'contoso\User'
                        Scopes    = 'Test'
                    }

                    $inputCollectionDif = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Collections = 'All Systems','All Servers'
                    }

                    $inputChangeAllScope = @{
                        SiteCode        = 'Lab'
                        AdminName       = 'contoso\User'
                        ScopesToInclude = 'All'
                    }

                    $inputDupIncludeExclude = @{
                        SiteCode             = 'Lab'
                        AdminName            = 'contoso\User'
                        RolesToInclude       = 'Full Administrator'
                        RolesToExclude       = 'Full Administrator'
                        ScopesToInclude      = 'Default'
                        ScopesToExclude      = 'Default'
                        CollectionsToInclude = 'Test1'
                        CollectionsToExclude = 'Test1'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                }

                It 'Should return desired result true settings match' {
                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false when roles do not match' {
                    Test-TargetResource @inputRolesDif | Should -Be $false
                }

                It 'Should return desired result false when scopes do not match' {
                    Test-TargetResource @inputScopeDif | Should -Be $false
                }

                It 'Should return desired result false when collections do not match' {
                    Test-TargetResource @inputCollectionDif | Should -Be $false
                }

                It 'Should return desired result tue when specifying the match parameter but the include and exclude do not match' {
                    Test-TargetResource @inputAllOptions | Should -Be $true
                }

                It 'Should return desired result false when present and expected absent' {
                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false when trying to add All Scope with warning' {
                    Test-TargetResource @inputChangeAllScope | Should -Be $false
                }

                It 'Should return desired result false when include and exclude contain duplicate settings' {
                    Test-TargetResource @inputDupIncludeExclude | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource when get returns absent' {
                BeforeEach {
                    $inputNewUser = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Roles       = 'Security Administrator'
                        Scopes      = 'All'
                        Collections = 'All Systems','All Users and User Groups'
                        Ensure      = 'Present'
                    }

                    $inputNewUserNoRolesInvalid = @{
                        SiteCode    = 'Lab'
                        AdminName   = 'contoso\User'
                        Ensure      = 'Present'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result true when absent and expected absent' {
                    Test-TargetResource @inputAbsent | Should -Be $true
                }

                It 'Should return desired result false when absent and expected present' {
                    Test-TargetResource @inputNewUser | Should -Be $false
                }

                It 'Should return desired result false when absent and not specifying a role' {
                    Test-TargetResource @inputNewUserNoRolesInvalid | Should -Be $false
                }
            }

            Context 'All Setting results' {
                BeforeEach {
                    $inputRemoveAll = @{
                        SiteCode        = 'Lab'
                        AdminName       = 'contoso\User'
                        ScopesToInclude = 'Default'
                        ScopesToExclude = 'All'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresentAll }
                }

                It 'Should return desired result false when all scope present and removing the scope' {
                    Test-TargetResource @inputRemoveAll | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
