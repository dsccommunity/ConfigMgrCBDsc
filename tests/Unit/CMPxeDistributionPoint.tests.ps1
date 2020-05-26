[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMPxeDistributionPoint'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMPxeDistributionPoint'

        # Get input and output
        $getDPInfo = @{
            IsPxe                  = $true
            SCCMPxe                = $true
            SupportUnknownMachines = $true
            UdaSetting             = 0
            PxePassword            = 'password'
            IsActive               = $true
            ResponseDelay          = 2
            IsMulticast            = $false
        }

        $getInput = @{
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
        }

        # Test and Set
        $getStatusAbsent = @{
            SiteCode                     = 'Lab'
            SiteServerName               = 'DP01.contoso.com'
            EnablePxe                    = $null
            EnableNonWdsPxe              = $null
            EnableUnknownComputerSupport = $null
            PxePassword                  = $null
            AllowPxeResponse             = $null
            PxeServerResponseDelaySec    = 0
            UserDeviceAffinity           = $null
            IsMulticast                  = $null
            DPStatus                     = 'Absent'
        }

        $getStatusPresentNoPassword = @{
            SiteCode                     = 'Lab'
            SiteServerName               = 'DP01.contoso.com'
            EnablePxe                    = $true
            EnableNonWdsPxe              = $true
            EnableUnknownComputerSupport = $true
            PxePassword                  = $null
            AllowPxeResponse             = $true
            PxeServerResponseDelaySec    = [UInt16]2
            UserDeviceAffinity           = 'AllowWithManualApproval'
            IsMulticast                  = $false
            DPStatus                     = 'Present'
        }

        $inputParamsMatch = @{
            SiteCode                  = 'Lab'
            SiteServerName            = 'DP01.contoso.com'
            EnablePxe                 = $true
            AllowPxeResponse          = $true
            PxeServerResponseDelaySec = 2
            UserDeviceAffinity        = 'AllowWithManualApproval'
        }

        $inputParamsMismatch = @{
            SiteCode                  = 'Lab'
            SiteServerName            = 'DP01.contoso.com'
            EnablePxe                 = $true
            AllowPxeResponse          = $false
            PxeServerResponseDelaySec = 1
            UserDeviceAffinity        = 'DoNotUse'
        }

        $testCredential = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'DummyUsername', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $inputParamsPxePassword = @{
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
            PxePassword    = $testCredential
        }

        $distroPointError = 'The Distribution Point role on DP01.contoso.com is not installed, run DSC_CMDistibutionPoint to install the role.'
        $pxeFalseThrow = 'Can not specify PXE settings when PXE is currently or setting to $false, please set EnablePxe to $true.'

        $badInputPxeFalse = @{
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
            EnablePxe      = $false
            PxePassword    = $testCredential
        }

        $nonWdsThrow = 'You can not enable nonWDSPxe while multicast is set to enabled.'

        $getReturnMulticastEnabled = @{
            SiteCode                     = 'Lab'
            SiteServerName               = 'DP01.contoso.com'
            EnablePxe                    = $true
            EnableNonWdsPxe              = $true
            EnableUnknownComputerSupport = $true
            PxePassword                  = $null
            AllowPxeResponse             = $true
            PxeServerResponseDelaySec    = [UInt16]2
            UserDeviceAffinity           = 'AllowWithManualApproval'
            IsMulticast                  = $true
            DPStatus                     = 'Present'
        }

        $setNonWdsEnabled = @{
            SiteCode        = 'Lab'
            SiteServerName  = 'DP01.contoso.com'
            EnableNonWdsPxe = $true
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving Collection settings' {

                It 'Should return desired result when all info is returned' {
                    Mock -CommandName Get-CMDistributionPointInfo -MockWith { $getDPInfo }

                    $result = Get-TargetResource @getInput
                    $result                              | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                     | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName               | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.EnablePxe                    | Should -Be -ExpectedValue $true
                    $result.EnableNonWdsPxe              | Should -Be -ExpectedValue $true
                    $result.EnableUnknownComputerSupport | Should -Be -ExpectedValue $true
                    $result.PxePassword                  | Should -Be -ExpectedValue 'password'
                    $result.AllowPxeResponse             | Should -Be -ExpectedValue $true
                    $result.PxeServerResponseDelaySec    | Should -Be -ExpectedValue 2
                    $result.UserDeviceAffinity           | Should -Be -ExpectedValue 'DoNotUse'
                    $result.IsMulticast                  | Should -Be -ExpectedValue $false
                    $result.DPStatus                     | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when server is not a Distribution Point' {
                    Mock -CommandName Get-CMDistributionPointInfo -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                              | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                     | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName               | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.EnablePxe                    | Should -Be -ExpectedValue $null
                    $result.EnableNonWdsPxe              | Should -Be -ExpectedValue $null
                    $result.EnableUnknownComputerSupport | Should -Be -ExpectedValue $null
                    $result.PxePassword                  | Should -Be -ExpectedValue $null
                    $result.AllowPxeResponse             | Should -Be -ExpectedValue $null
                    $result.PxeServerResponseDelaySec    | Should -Be -ExpectedValue 0
                    $result.UserDeviceAffinity           | Should -Be -ExpectedValue $null
                    $result.IsMulticast                  | Should -Be -ExpectedValue $null
                    $result.DPStatus                     | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location
            Mock -CommandName Set-CMDistributionPoint

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands when settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Set-TargetResource @inputParamsMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Set-TargetResource @inputParamsMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when setting a Pxe password' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Set-TargetResource @inputParamsPxePassword
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {

                It 'Should throw and call expected commands when distribution point rule is not installed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusAbsent }

                    { Set-TargetResource @inputParamsMatch } | Should -Throw -ExpectedMessage $distroPointError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when specifying additional settings and setting EnablePxe to false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    { Set-TargetResource @badInputPxeFalse } | Should -Throw -ExpectedMessage $pxeFalseThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should throw and call expected commands when trying to enable NonWdsPxe and Multicast is currently enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnMulticastEnabled }

                    { Set-TargetResource @setNonWdsEnabled } | Should -Throw -ExpectedMessage $nonWdsThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule

            Context 'When running Test-TargetResource and get returns present' {

                It 'Should return desired result true settings match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Test-TargetResource @inputParamsMatch | Should -Be $true
                }

                It 'Should return desired result false settings do not match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Test-TargetResource @inputParamsMismatch | Should -Be $false
                }

                It 'Should return desired result false settings when pxe password not present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusPresentNoPassword }

                    Test-TargetResource @inputParamsPxePassword | Should -Be $false
                }

                It 'Should return desired result false settings when server is not a distribution point' {
                    Mock -CommandName Get-TargetResource -MockWith { $getStatusAbsent }

                    Test-TargetResource @inputParamsMatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
