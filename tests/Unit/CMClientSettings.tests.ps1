[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMClientSettings'

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

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettings\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $clientReturn = @{
                    Type              = 1
                    Description       = 'Test Settings'
                    SecuredScopeNames = @('Default','Scope1')
                }

                $defaultReturn = @{
                    Type              = 0
                    Description       = 'Default Agent'
                    SecuredScopeNames = @('Default','Scope1')
                }

                $getInput = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Type              = 'Device'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Client Policy Settings for Client Cache' {

                It 'Should return desired results when client settings exist' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $clientReturn }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'ClientTest'
                    $result.Description             | Should -Be -ExpectedValue 'Test Settings'
                    $result.Type                    | Should -Be -ExpectedValue 'Device'
                    $result.SecurityScopes          | Should -Be -ExpectedValue @('Default','Scope1')
                    $result.SecurityScopesToInclude | Should -Be -ExpectedValue $null
                    $result.SecurityScopesToExclude | Should -Be -ExpectedValue $null
                    $result.Ensure                  | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired results when specifying a default client policy' {
                    Mock -CommandName Get-CMClientSetting -MockWith { $defaultReturn }

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'ClientTest'
                    $result.Description             | Should -Be -ExpectedValue $null
                    $result.Type                    | Should -Be -ExpectedValue $null
                    $result.SecurityScopes          | Should -Be -ExpectedValue $null
                    $result.SecurityScopesToInclude | Should -Be -ExpectedValue $null
                    $result.SecurityScopesToExclude | Should -Be -ExpectedValue $null
                    $result.Ensure                  | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired results when client policy does not exist' {
                    Mock -CommandName Get-CMClientSetting

                    $result = Get-TargetResource @getInput
                    $result                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                | Should -Be -ExpectedValue 'Lab'
                    $result.ClientSettingName       | Should -Be -ExpectedValue 'ClientTest'
                    $result.Description             | Should -Be -ExpectedValue $null
                    $result.Type                    | Should -Be -ExpectedValue $null
                    $result.SecurityScopes          | Should -Be -ExpectedValue $null
                    $result.SecurityScopesToInclude | Should -Be -ExpectedValue $null
                    $result.SecurityScopesToExclude | Should -Be -ExpectedValue $null
                    $result.Ensure                  | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettings\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client'
                    Type                    = 'Device'
                    SecurityScopes          = @('Default','Scope1')
                    SecurityScopesToInclude = $null
                    SecurityScopesToExclude = $null
                    Ensure                  = 'Present'
                }

                $inputPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client'
                    Type                    = 'Device'
                    SecurityScopesToInclude = @('Default','Scope1')
                    SecurityScopesToExclude = @('Scope2')
                    Ensure                  = 'Present'
                }

                $getClientHash = @{
                    Name = 'ClientTest'
                    Type = 1
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMClientSetting
                Mock -CommandName Set-CMClientSetting
                Mock -CommandName Add-CMObjectSecurityScope
                Mock -CommandName Remove-CMObjectSecurityScope
                Mock -CommandName Remove-CMClientSetting
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $returnAbsentClient = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Description             = $null
                        Type                    = $null
                        SecurityScopes          = $null
                        SecurityScopesToInclude = $null
                        SecurityScopesToExclude = $null
                        Ensure                  = 'Absent'
                    }

                    $inputMisMatch = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Description             = 'Test Client Settings'
                        Type                    = 'Device'
                        SecurityScopes          = @('Scope1','Scope2')
                        SecurityScopesToInclude = @('Default','Scope1')
                        SecurityScopesToExclude = @('Scope2')
                        Ensure                  = 'Present'
                    }

                    $inputAbsent = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Type              = 'Device'
                        Ensure            = 'Absent'
                    }

                    $inputNewClient = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Type              = 'Device'
                        Ensure            = 'Present'
                    }
                }

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when creating a new client policy with no description and no scopes' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsentClient }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    Set-TargetResource @inputNewClient
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when creating a new client policy' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsentClient }
                    Mock -CommandName Get-CMClientSetting -MockWith { $getClientHash }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting -MockWith { $getClientHash }
                    Mock -CommandName Get-CMSecurityScope -MockWith { $true }

                    Set-TargetResource @inputMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when client policy is present and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $inputExcludeAll = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Description             = 'Test Client'
                        Type                    = 'Device'
                        SecurityScopesToExclude = @('Default','Scope1')
                        Ensure                  = 'Present'
                    }

                    $excludeAllMsg = 'Client Settings Policy must have at least 1 Security Scope assigned, SecurityScopesToExclude is currently set to remove all Security Scopes.'

                    $inputTypeMisMatch = @{
                        SiteCode          = 'Lab'
                        ClientSettingName = 'ClientTest'
                        Type              = 'User'
                        Ensure            = 'Present'
                    }

                    $typeMisMatchMsg = 'The ClientTest client setting already exists as a different type.'

                    $inputIncludeExcludeMatch = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Type                    = 'Device'
                        SecurityScopesToInclude = @('Scope1')
                        SecurityScopesToExclude = @('Scope1')
                        Ensure                  = 'Present'
                    }

                    $includeExcludeMsg = 'SecurityScopesToInclude and SecurityScopesToExclude contain to same entry Scope1, remove from one of the arrays.'

                    $inputSingleScope = @{
                        SiteCode                = 'Lab'
                        ClientSettingName       = 'ClientTest'
                        Type                    = 'Device'
                        SecurityScopesToInclude = @('Scope3')
                    }

                    $nullScopeMsg = 'The Security Scope specified does not exist: Scope3.'
                }

                It 'Should throw and call expected commands when client type mismatch' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    { Set-TargetResource @inputTypeMisMatch } | Should -Throw -ExpectedMessage $typeMisMatchMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when trying to exclude all security scopes' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    { Set-TargetResource @inputExcludeAll } | Should -Throw -ExpectedMessage $excludeAllMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when include and exclude contain the same entry' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting
                    Mock -CommandName Get-CMSecurityScope

                    { Set-TargetResource @inputIncludeExcludeMatch } | Should -Throw -ExpectedMessage $includeExcludeMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when trying to add a security scope that does not exist' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }
                    Mock -CommandName Get-CMClientSetting -MockWith { $getClientHash }
                    Mock -CommandName Get-CMSecurityScope

                    { Set-TargetResource @inputSingleScope } | Should -Throw -ExpectedMessage $nullScopeMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMClientSetting -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMObjectSecurityScope -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMClientSetting -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMClientSettings\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $returnPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client'
                    Type                    = 'Device'
                    SecurityScopes          = @('Default','Scope1')
                    SecurityScopesToInclude = $null
                    SecurityScopesToExclude = $null
                    Ensure                  = 'Present'
                }

                $returnAbsentClient = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = $null
                    Type                    = $null
                    SecurityScopes          = $null
                    SecurityScopesToInclude = $null
                    SecurityScopesToExclude = $null
                    Ensure                  = 'Absent'
                }

                $inputPresent = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client'
                    Type                    = 'Device'
                    SecurityScopesToInclude = @('Default','Scope1')
                    SecurityScopesToExclude = @('Scope2')
                    Ensure                  = 'Present'
                }

                $inputMisMatch = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client Settings'
                    Type                    = 'Device'
                    SecurityScopes          = @('Scope1','Scope2')
                    SecurityScopesToInclude = @('Default','Scope1')
                    SecurityScopesToExclude = @('Scope2')
                    Ensure                  = 'Present'
                }

                $inputAbsent = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'CilentTest'
                    Type              = 'Device'
                    Ensure            = 'Absent'
                }

                $inputExcludeAll = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Description             = 'Test Client'
                    Type                    = 'Device'
                    SecurityScopesToExclude = @('Default','Scope1')
                    Ensure                  = 'Present'
                }

                $inputTypeMisMatch = @{
                    SiteCode          = 'Lab'
                    ClientSettingName = 'ClientTest'
                    Type              = 'User'
                    Ensure            = 'Present'
                }

                $inputIncludeExcludeMatch = @{
                    SiteCode                = 'Lab'
                    ClientSettingName       = 'ClientTest'
                    Type                    = 'Device'
                    SecurityScopesToInclude = @('Scope1')
                    SecurityScopesToExclude = @('Scope1')
                    Ensure                  = 'Present'
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputPresent | Should -Be $true
                }

                It 'Should return desired result false when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputMisMatch | Should -Be $false
                }

                It 'Should return desired result false when client settings exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false when excluding all security scopes' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputExcludeAll | Should -Be $false
                }

                It 'Should return desired result false when client setting types does not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputTypeMisMatch | Should -Be $false
                }

                It 'Should return desired result false when include and exclude contain the same entry' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnPresent }

                    Test-TargetResource @inputIncludeExcludeMatch | Should -Be $false
                }

                It 'Should return desired result true when client policy is absent and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $returnAbsentClient }

                    Test-TargetResource @inputAbsent | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
