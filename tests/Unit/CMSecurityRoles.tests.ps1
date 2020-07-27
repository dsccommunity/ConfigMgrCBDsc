[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSecurityRoles'

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
        Describe 'DSC_CMSecurityRoles\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $roleReturn = @{
                    CopiedFromID    = 'SMS0001R'
                    NumberOfAdmins  = 1
                    Operations      = @(
                        @{
                            SmsProviderObjectPath = 'SMS_ARoleOperation'
                            GrantedOperations     = 2241187
                            ObjectTypeID          = 1
                        }
                        @{
                            SmsProviderObjectPath = 'SMS_ARoleOperation'
                            GrantedOperations     = 268435457
                            ObjectTypeID          = 2
                        }
                        @{
                            SmsProviderObjectPath = 'SMS_ARoleOperation'
                            GrantedOperations     = 268435457
                            ObjectTypeID          = 4
                        }
                    )
                    RoleDescription = 'Test description'
                    RoleName        = 'Test Role'
                    SourceSite      = 'Lab'
                }

                $getAdminUsers = @(
                    @{
                        LogonName = 'contoso\TestUser1'
                        RoleNames = @('Full Administrator', 'Asset Manager')
                    }
                    @{
                        LogonName = 'contoso\TestUser2'
                        RoleNames = @('Test Role', 'Asset Manager')
                    }
                    @{
                        LogonName = 'contoso\TestUser3'
                        RoleNames = @('Test Role')
                    }
                )

                $getInput = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                }

                $opReturn ='1=2241187;2=268435457;4=268435457;'

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Security Roles' {

                It 'Should return desired result when role is present and has users assigned to role' {
                    Mock -CommandName Get-CMSecurityRole -MockWith { $roleReturn }
                    Mock -CommandName Get-CMAdministrativeUser -MockWith { $getAdminUsers }

                    $result = Get-TargetResource @getInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityRoleName | Should -Be -ExpectedValue 'Test Role'
                    $result.Description      | Should -Be -ExpectedValue 'Test description'
                    $result.Operation        | Should -Be -ExpectedValue $opReturn
                    $result.UsersAssigned    | Should -Be -ExpectedValue 'contoso\TestUser2','contoso\TestUser3'
                    $result.Ensure           | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when role is present and no users assigned to role' {
                    Mock -CommandName Get-CMSecurityRole -MockWith { $roleReturn }
                    Mock -CommandName Get-CMAdministrativeUser -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityRoleName | Should -Be -ExpectedValue 'Test Role'
                    $result.Description      | Should -Be -ExpectedValue 'Test description'
                    $result.Operation        | Should -Be -ExpectedValue $opReturn
                    $result.UsersAssigned    | Should -Be -ExpectedValue $null
                    $result.Ensure           | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when role is absent' {
                    Mock -CommandName Get-CMSecurityRole -MockWith { $null }
                    Mock -CommandName Get-CMAdministrativeUser -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode         | Should -Be -ExpectedValue 'Lab'
                    $result.SecurityRoleName | Should -Be -ExpectedValue 'Test Role'
                    $result.Description      | Should -Be -ExpectedValue $null
                    $result.Operation        | Should -Be -ExpectedValue $null
                    $result.UsersAssigned    | Should -Be -ExpectedValue $null
                    $result.Ensure           | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'DSC_CMSecurityRoles\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnAbsent = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                    Description      = $null
                    Operation        = $null
                    UsersAssigned    = $null
                    Ensure           = 'Absent'
                }

                $getReturnPresent = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                    Description      = 'Test description'
                    Operation        = '1=2241187;2=268435457;4=268435457;'
                    UsersAssigned    = 'contoso\TestUser2','contoso\TestUser3'
                    Ensure           = 'Present'
                }

                $inputPresentAppend = @{
                    SiteCode         = 'Lab'
                    XmlPath          = "$TestDrive\test.xml"
                    SecurityRoleName = 'Test Role'
                    Description      = 'Test description'
                    Overwrite        = $true
                    Append           = $true
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Rename-Item
                Mock -CommandName Import-CMSecurityRole
                Mock -CommandName Set-CMSecurityRole
                Mock -CommandName Remove-CMSecurityRole
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputPresentOverwrite = @{
                        SiteCode         = 'Lab'
                        XmlPath          = "$TestDrive\test.xml"
                        SecurityRoleName = 'Test Role'
                        Description      = ''
                        Overwrite        = $true
                    }

                    $inputPresent = @{
                        SiteCode         = 'Lab'
                        XmlPath          = "$TestDrive\test.xml"
                        SecurityRoleName = 'Test Role'
                    }

                    $inputAbsent = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        Ensure           = 'Absent'
                    }

                    [xml]$roleXmlDif = '
                        <SMS_Roles>
                            <SMS_Role RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                                <Operations>
                                    <Operation ObjectTypeID="1" GrantedOperations="3"/>
                                    <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                    <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                                </Operations>
                            </SMS_Role>
                        </SMS_Roles>
                    '

                    $getCmRole = @{
                        RoleDescription = 'Test description'
                        RoleName        = 'Test Role'
                        SourceSite      = 'Lab'
                    }

                    $childItemReturn = @{
                        BaseName = 'Test Role'
                        Fullname = 'TestDrive:\test.xml'
                    }

                    $getReturnNoOperations = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        Description      = 'Test Description'
                        Operation        = $null
                        UsersAssigned    = 'contoso\TestUSer2','contoso\TestUser3'
                        Ensure           = 'Present'
                    }

                    $dateMock = '2020-07-20-19-23-44'

                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName Get-CMSecurityRole -MockWith { $getCMRole }
                    Mock -CommandName Get-ChildItem -MockWith { $childItemReturn }
                    Mock -CommandName Get-Date -MockWith { $dateMock }
                }

                It 'Should call expected commands when state absent and expected present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Set-TargetResource @inputPresentOverwrite
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when overwrite is true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Set-TargetResource @inputPresentOverwrite
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when append is true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Set-TargetResource @inputPresentAppend
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 1 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when removing Security Role' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when state Operations returns null' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoOperations }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Set-TargetResource @inputPresentAppend
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when overwrite and append are false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoOperations }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Set-TargetResource @inputPresent
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $inputPresentNoXml = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        Description      = 'Test description'
                        Overwrite        = $true
                    }

                    $missingXml = 'Role does not exist and will not be able to create role without specifying a valid XML.'

                    [xml]$roleXmlMalformed = '
                        <SMS_Role>
                            <SMS_Roles RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                                <Operation>
                                    <Operations ObjectTypeID="1" GrantedOperations="3"/>
                                    <Operations ObjectTypeID="4" GrantedOperations="268435457"/>
                                    <Operations ObjectTypeID="6" GrantedOperations="805306369"/>
                                </Operation>
                            </SMS_Roles>
                        </SMS_Role>
                    '

                    $invalidXml = 'Xml appears to be invalid check xml and try again.'

                    [xml]$roleXmlNameMismatch = '
                        <SMS_Roles>
                            <SMS_Role RoleDescription="Test Description" RoleName="Role Test" CopiedFromID="SMS0001R">
                                <Operations>
                                    <Operation ObjectTypeID="1" GrantedOperations="3"/>
                                    <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                    <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                                </Operations>
                            </SMS_Role>
                        </SMS_Roles>
                    '

                    $nonXml = 'a'

                    $nameMismatch = 'The name specified in the xml does not match the name specified in the parameters.'

                    Mock -CommandName Get-ChildItem
                    Mock -CommandName Get-Date
                    Mock -CommandName Rename-Item
                    Mock -CommandName Get-CMSecurityRole
                }

                It 'Should call expected commands and throw when Absent and expected present with no XML file specified' {
                    Mock -CommandName Test-Path
                    Mock -CommandName Get-Content
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    { Set-TargetResource @inputPresentNoXml } | Should -Throw -ExpectedMessage $missingXml
                    Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when malformed xml file is specified' {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlMalformed }

                    { Set-TargetResource @inputPresentAppend } | Should -Throw -ExpectedMessage $invalidXml
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when non xml file is specified' {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $nonXml }

                    { Set-TargetResource @inputPresentAppend } | Should -Throw -ExpectedMessage $invalidXml
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when xml is a null file' {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $null }

                    { Set-TargetResource @inputPresentAppend } | Should -Throw -ExpectedMessage $invalidXml
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw xml file name does not match parameter' {
                    Mock -CommandName Test-Path -MockWith { $true }
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlNameMismatch }

                    { Set-TargetResource @inputPresentAppend } | Should -Throw -ExpectedMessage $nameMismatch
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and Test-Path throws in parameter validation' {
                    Mock -CommandName Test-Path -MockWith { $false }
                    Mock -CommandName Get-TargetResource
                    Mock -CommandName Get-Content

                    { Set-TargetResource @inputPresentAppend } | Should -Throw
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Content -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-Date -Exactly -Times 0 -Scope It
                    Assert-MockCalled Rename-Item -Exactly -Times 0 -Scope It
                    Assert-MockCalled Import-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSecurityRole -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMSecurityRole -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'DSC_CMSecurityRoles\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnPresent = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                    Description      = 'Test description'
                    Operation        = '1=2241187;2=268435457;4=268435457;'
                    UsersAssigned    = 'contoso\TestUser2','contoso\TestUser3'
                    Ensure           = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                    Description      = $null
                    Operation        = $null
                    UsersAssigned    = $null
                    Ensure           = 'Absent'
                }

                $getReturnNoOperations = @{
                    SiteCode         = 'Lab'
                    SecurityRoleName = 'Test Role'
                    Description      = 'Test Description'
                    Operation        = $null
                    UsersAssigned    = 'contoso\TestUSer2','contoso\TestUser3'
                    Ensure           = 'Present'
                }

                [xml]$roleXmlAdd = '
                    <SMS_Roles>
                        <SMS_Role RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                            <Operations>
                                <Operation ObjectTypeID="1" GrantedOperations="2241187"/>
                                <Operation ObjectTypeID="2" GrantedOperations="268435457"/>
                                <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                            </Operations>
                        </SMS_Role>
                    </SMS_Roles>
                '

                [xml]$roleXmlDif = '
                    <SMS_Roles>
                        <SMS_Role RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                            <Operations>
                                <Operation ObjectTypeID="1" GrantedOperations="3"/>
                                <Operation ObjectTypeID="2" GrantedOperations="26843545"/>
                                <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                            </Operations>
                        </SMS_Role>
                    </SMS_Roles>
                '

                [xml]$roleXmlMissing = '
                    <SMS_Roles>
                        <SMS_Role RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                            <Operations>
                                <Operation ObjectTypeID="1" GrantedOperations="3"/>
                                <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                            </Operations>
                        </SMS_Role>
                    </SMS_Roles>
                '

                [xml]$roleXmlNameMismatch = '
                    <SMS_Roles>
                        <SMS_Role RoleDescription="Test Description" RoleName="Role Test" CopiedFromID="SMS0001R">
                            <Operations>
                                <Operation ObjectTypeID="1" GrantedOperations="3"/>
                                <Operation ObjectTypeID="4" GrantedOperations="268435457"/>
                                <Operation ObjectTypeID="6" GrantedOperations="805306369"/>
                            </Operations>
                        </SMS_Role>
                    </SMS_Roles>
                '

                [xml]$roleXmlMalformed = '
                    <SMS_Role>
                        <SMS_Roles RoleDescription="Test Description" RoleName="Test Role" CopiedFromID="SMS0001R">
                            <Operation>
                                <Operations ObjectTypeID="1" GrantedOperations="3"/>
                                <Operations ObjectTypeID="4" GrantedOperations="268435457"/>
                                <Operations ObjectTypeID="6" GrantedOperations="805306369"/>
                            </Operation>
                        </SMS_Roles>
                    </SMS_Role>
                '
                $nonXml = 'a'

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Test-Path -Mockwith { $true }
            }

            Context 'When running Test-TargetResource' {
                BeforeEach {
                    $inputPresentNoXml = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        Description      = 'Test description'
                        Overwrite        = $true
                    }

                    $inputPresentOverwrite = @{
                        SiteCode         = 'Lab'
                        XmlPath          = "$TestDrive\test.xml"
                        SecurityRoleName = 'Test Role'
                        Description      = 'Test description'
                        Overwrite        = $true
                    }

                    $inputPresentAppend = @{
                        SiteCode         = 'Lab'
                        XmlPath          = "$TestDrive\test.xml"
                        SecurityRoleName = 'Test Role'
                        Description      = 'Test description'
                        Overwrite        = $true
                        Append           = $true
                    }

                    $inputAbsent = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        Ensure           = 'Absent'
                    }

                    $inputDescription = @{
                        SiteCode         = 'Lab'
                        SecurityRoleName = 'Test Role'
                        XmlPath          = "$TestDrive\test.xml"
                        Description      = ''
                        Ensure           = 'Present'
                    }
                }

                It 'Should return desired result false when absent returned expected Present' {
                    Mock -CommandName Get-TargetResource { $getReturnAbsent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlAdd }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false when absent returned expected Present and no Xml specified' {
                    Mock -CommandName Get-TargetResource { $getReturnAbsent }
                    Mock -CommandName Get-Content

                    Test-TargetResource @inputPresentNoXml | Should -Be $false
                }

                It 'Should return desired result false when security Role settings do not match' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlAdd }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false expected description is incorrect' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content

                    Test-TargetResource @inputDescription | Should -Be $false
                }

                It 'Should return desired result false when append is true and settings do not match' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlMissing }

                    Test-TargetResource @inputPresentAppend | Should -Be $false
                }

                It 'Should return desired result false when Xml specified is invalid format' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlMalformed }

                    Test-TargetResource @inputPresentAppend | Should -Be $false
                }

                It 'Should return desired result false when overwrite is true and settings do not match' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlDif }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false when RoleName specified and xml name do not match' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $roleXmlNameMismatch }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false when Role is present but operations is null' {
                    Mock -CommandName Get-TargetResource { $getReturnNoOperations }
                    Mock -CommandName Get-Content -MockWith { $roleXmlNameMismatch }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false when Role is present and expected absent' {
                    Mock -CommandName Get-TargetResource { $getReturnNoOperations }
                    Mock -CommandName Get-Content

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result false when xml file is null' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }

                It 'Should return desired result false when none xml formatted file' {
                    Mock -CommandName Get-TargetResource { $getReturnPresent }
                    Mock -CommandName Get-Content -MockWith { $nonXml }

                    Test-TargetResource @inputPresentOverwrite | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
