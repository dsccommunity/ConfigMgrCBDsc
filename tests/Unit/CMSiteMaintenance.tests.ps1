[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSiteMaintenance'

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

        Describe 'DSC_CMSiteMaintenance\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $getInputType1Enabled = @{
                    SiteCode        = 'Lab'
                    TaskName        = 'Backup SMS Site Server'
                    Enabled         = $true
                }

                $inputType2Disabled = @{
                    SiteCode = 'Lab'
                    TaskName = 'Summarize File Usage Metering Data'
                    Enabled  = $false
                }

                $inputType3Disabled = @{
                    SiteCode = 'Lab'
                    TaskName = 'Delete Aged Client Operations'
                    Enabled  = $false
                }

                $inputSummaryTaskDisabled = @{
                    SiteCode = 'Lab'
                    TaskName = 'Update Application Catalog Tables'
                    Enabled  = $false
                }

                $resultBackup = @{
                    TaskName      = 'Backup SMS Site Server'
                    ManagedObject = @{
                        BeginTime       = '00000000010000'
                        LatestBeginTime = '00000000060000'
                        DaysOfWeek      = 65
                        TaskName        = 'Backup SMS Site Server'
                        TaskType        = 1
                        Enabled         = $true
                        DeviceName      = 'C:\Temp123'
                        DeleteOlderThan = 0
                    }
                    TaskType      = 1
                    Enabled       = $true
                }

                $resultMeteringData = @{
                    TaskName      = 'Summarize File Usage Metering Data'
                    ManagedObject = @{
                        BeginTime       = '00000000030000'
                        LatestBeginTime = '00000000070000'
                        DaysOfWeek      = 127
                        TaskName        = 'Summarize File Usage Metering Data'
                        TaskType        = 2
                        Enabled         = $true
                        DeleteOlderThan = 0
                    }
                    TaskType      = 2
                    Enabled       = $true
                }

                $resultAgedClient = @{
                    TaskName      = 'Delete Aged Client Operations'
                    ManagedObject = @{
                        BeginTime       = '00000000000000'
                        LatestBeginTime = '00000000050000'
                        DaysOfWeek      = 64
                        TaskName        = 'Delete Aged Client Operations'
                        TaskType        = 3
                        Enabled         = $true
                        DeleteOlderThan = 20
                    }
                    TaskType      = 3
                    Enabled       = $true
                }

                $resultSummaryTaskEnabled = @{
                    TaskName      = 'Update Application Catalog Tables'
                    RunInterval   = 82800
                    Enabled       = $true
                    TaskParameter = $null
                }

                $resultSummaryTaskDisabled = @{
                    TaskName      = 'Update Application Catalog Tables'
                    RunInterval   = 82800
                    Enabled       = $true
                    TaskParameter = 'AutoTune'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving client settings' {

                It 'Should return desired result for tasktype 1' {
                    Mock -CommandName Get-CMSiteMaintenanceTask -MockWith { $resultBackup }

                    $result = Get-TargetResource @getInputType1Enabled
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.TaskName            | Should -Be -ExpectedValue 'Backup SMS Site Server'
                    $result.Enabled             | Should -Be -ExpectedValue $true
                    $result.DaysOfWeek          | Should -Be -ExpectedValue @('Saturday','Sunday')
                    $result.BeginTime           | Should -Be -ExpectedValue '0100'
                    $result.LatestBeginTime     | Should -Be -ExpectedValue '0600'
                    $result.DeleteOlderThanDays | Should -Be -ExpectedValue '0'
                    $result.BackupLocation      | Should -Be -ExpectedValue 'C:\Temp123'
                    $result.RunInterval         | Should -Be -ExpectedValue $null
                    $result.TaskType            | Should -Be -ExpectedValue 1
                }

                It 'Should return desired result for tasktype 2' {
                    Mock -CommandName Get-CMSiteMaintenanceTask -MockWith { $resultMeteringData }

                    $result = Get-TargetResource @inputType2Disabled
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.TaskName            | Should -Be -ExpectedValue 'Summarize File Usage Metering Data'
                    $result.Enabled             | Should -Be -ExpectedValue $true
                    $result.DaysOfWeek          | Should -Be -ExpectedValue @('Saturday','Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                    $result.BeginTime           | Should -Be -ExpectedValue '0300'
                    $result.LatestBeginTime     | Should -Be -ExpectedValue '0700'
                    $result.DeleteOlderThanDays | Should -Be -ExpectedValue '0'
                    $result.BackupLocation      | Should -Be -ExpectedValue $null
                    $result.RunInterval         | Should -Be -ExpectedValue $null
                    $result.TaskType            | Should -Be -ExpectedValue 2
                }

                It 'Should return desired result for tasktype 3' {
                    Mock -CommandName Get-CMSiteMaintenanceTask -MockWith { $resultAgedClient }

                    $result = Get-TargetResource @inputType3Disabled
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.TaskName            | Should -Be -ExpectedValue 'Delete Aged Client Operations'
                    $result.Enabled             | Should -Be -ExpectedValue $true
                    $result.DaysOfWeek          | Should -Be -ExpectedValue 'Saturday'
                    $result.BeginTime           | Should -Be -ExpectedValue '0000'
                    $result.LatestBeginTime     | Should -Be -ExpectedValue '0500'
                    $result.DeleteOlderThanDays | Should -Be -ExpectedValue '20'
                    $result.BackupLocation      | Should -Be -ExpectedValue $null
                    $result.RunInterval         | Should -Be -ExpectedValue $null
                    $result.TaskType            | Should -Be -ExpectedValue 3
                }

                It 'Should return desired result for Update Application Catalog Tables enabled' {
                    Mock -CommandName Get-CMSiteSummaryTask -MockWith { $resultSummaryTaskEnabled }

                    $result = Get-TargetResource @inputSummaryTaskDisabled
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.TaskName            | Should -Be -ExpectedValue 'Update Application Catalog Tables'
                    $result.Enabled             | Should -Be -ExpectedValue $true
                    $result.DaysOfWeek          | Should -Be -ExpectedValue $null
                    $result.BeginTime           | Should -Be -ExpectedValue $null
                    $result.LatestBeginTime     | Should -Be -ExpectedValue $null
                    $result.DeleteOlderThanDays | Should -Be -ExpectedValue $null
                    $result.BackupLocation      | Should -Be -ExpectedValue $null
                    $result.RunInterval         | Should -Be -ExpectedValue 1380
                    $result.TaskType            | Should -Be -ExpectedValue $null
                }

                It 'Should return desired result for Update Application Catalog Tables disabled' {
                    Mock -CommandName Get-CMSiteSummaryTask -MockWith { $resultSummaryTaskDisabled }

                    $result = Get-TargetResource @inputSummaryTaskDisabled
                    $result                     | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode            | Should -Be -ExpectedValue 'Lab'
                    $result.TaskName            | Should -Be -ExpectedValue 'Update Application Catalog Tables'
                    $result.Enabled             | Should -Be -ExpectedValue $false
                    $result.DaysOfWeek          | Should -Be -ExpectedValue $null
                    $result.BeginTime           | Should -Be -ExpectedValue $null
                    $result.LatestBeginTime     | Should -Be -ExpectedValue $null
                    $result.DeleteOlderThanDays | Should -Be -ExpectedValue $null
                    $result.BackupLocation      | Should -Be -ExpectedValue $null
                    $result.RunInterval         | Should -Be -ExpectedValue 1380
                    $result.TaskType            | Should -Be -ExpectedValue $null
                }
            }
        }

        Describe 'DSC_CMSiteMaintenance\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMSiteMaintenanceTask
                Mock -CommandName Set-CMSiteSummaryTask
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $getReturnTaskType1 = @{
                        SiteCode            = 'Lab'
                        BeginTime           = '0100'
                        LatestBeginTime     = '0600'
                        DaysOfWeek          = 'Saturday','Sunday'
                        TaskName            = 'Backup SMS Site Server'
                        TaskType            = 1
                        Enabled             = $true
                        RunInterval         = $null
                        BackupLocation      = 'C:\Temp123'
                        DeleteOlderThanDays = 0
                    }

                    $inputType1EnabledBad = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Backup SMS Site Server'
                        Enabled         = $true
                        DaysofWeek      = 'Saturday','Monday'
                        BeginTime       = '0200'
                        LatestBeginTime = '0700'
                        BackupLocation  = 'C:\Temp1234'
                        RunInterval     = 5
                    }

                    $inputType1EnabledBadDay = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Backup SMS Site Server'
                        Enabled         = $true
                        DaysOfWeek      = 'Saturday','Friday'
                        BeginTime       = '0200'
                        LatestBeginTime = '0700'
                        BackupLocation  = 'C:\Temp1234'
                        RunInterval     = 5
                    }

                    $getReturnTaskType2 = @{
                        SiteCode            = 'Lab'
                        BeginTime           = '0300'
                        LatestBeginTime     = '0700'
                        DaysOfWeek          = @('Saturday','Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                        TaskName            = 'Summarize File Usage Metering Data'
                        TaskType            = 2
                        Enabled             = $true
                        DeleteOlderThanDays = 0
                        BackupLocation      = $null
                        RunInterval         = $null
                    }

                    $inputType2EnabledBad = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Summarize File Usage Metering Data'
                        Enabled         = $true
                        DaysofWeek      = @('Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                        BeginTime       = '0400'
                        LatestBeginTime = '0800'
                        RunInterval     = 5
                    }

                    $getReturnTaskType3 = @{
                        BeginTime           = '0000'
                        LatestBeginTime     = '0500'
                        DaysOfWeek          = 'Saturday'
                        TaskName            = 'Delete Aged Client Operations'
                        TaskType            = 3
                        Enabled             = $true
                        DeleteOlderThanDays = 20
                        SiteCode            = 'Lab'
                        BackupLocation      = $null
                        RunInterval         = $null
                    }

                    $getReturnTaskType3Disabled = @{
                        BeginTime           = '0000'
                        LatestBeginTime     = '0500'
                        DaysOfWeek          = 'Saturday'
                        TaskName            = 'Delete Aged Client Operations'
                        TaskType            = 3
                        Enabled             = $false
                        DeleteOlderThanDays = 20
                        SiteCode            = 'Lab'
                        BackupLocation      = $null
                        RunInterval         = $null
                    }

                    $inputType3EnabledDay = @{
                        SiteCode            = 'Lab'
                        TaskName            = 'Delete Aged Client Operations'
                        Enabled             = $true
                        DaysofWeek          = 'Sunday'
                        BeginTime           = '0100'
                        LatestBeginTime     = '0600'
                        DeleteOlderThanDays = 19
                        RunInterval         = 5
                    }

                    $inputType3Disabled = @{
                        SiteCode = 'Lab'
                        TaskName = 'Delete Aged Client Operations'
                        Enabled  = $false
                    }

                    $getResultSummaryTaskEnabled = @{
                        SiteCode            = 'Lab'
                        BeginTime           = $null
                        LatestBeginTime     = $null
                        DaysOfWeek          = $null
                        TaskName            = 'Update Application Catalog Tables'
                        TaskType            = $null
                        RunInterval         = 1380
                        Enabled             = $true
                        BackupLocation      = $null
                        DeleteOlderThanDays = 0
                    }

                    $inputSummaryTaskEnabledBad = @{
                        SiteCode    = 'Lab'
                        TaskName    = 'Update Application Catalog Tables'
                        Enabled     = $true
                        RunInterval = 40
                        BeginTime   = '0100'
                    }

                    $inputSummaryTaskDisable = @{
                        SiteCode    = 'Lab'
                        TaskName    = 'Update Application Catalog Tables'
                        Enabled     = $false
                    }
                }

                It 'Should call expected commands for setting Type 1 task' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType1 }

                    Set-TargetResource @inputType1EnabledBad
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for setting Type 1 task with different days' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType1 }

                    Set-TargetResource @inputType1EnabledBadDay
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for setting Type 2 task' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType2 }

                    Set-TargetResource @inputType2EnabledBad
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for setting Type 3 task' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType3 }

                    Set-TargetResource @inputType3EnabledDay
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected for disabling maintenance task for type 3' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType3 }

                    Set-TargetResource @inputType3Disabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected for enabling maintenance task for type 3' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType3Disabled }

                    Set-TargetResource @inputType3EnabledDay
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected for disabling maintenance task for type 3' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType3 }

                    Set-TargetResource @inputType3Disabled
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should call expected for enabling Summary Tasks' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultSummaryTaskEnabled }

                    Set-TargetResource @inputSummaryTaskEnabledBad
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 1 -Scope It
                }

                It 'Should call expected for disabling Summary Tasks' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultSummaryTaskEnabled }

                    Set-TargetResource @inputSummaryTaskDisable
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $badParamTaskName = @{
                        TaskName        = 'Whatever'
                        BeginTime       = '0000'
                        LatestBeginTime = '0500'
                        Enabled         = $true
                    }

                    $badParamBeginTime = @{
                        TaskName        = 'Delete Aged Client Operations'
                        BeginTime       = '2600'
                        LatestBeginTime = '0500'
                        Enabled         = $true
                    }

                    $badParamLatestBeginTime = @{
                        TaskName        = 'Delete Aged Client Operations'
                        BeginTime       = '0100'
                        LatestBeginTime = 'T100'
                        Enabled         = $true
                    }

                    $getReturnTaskType1Null = @{
                        SiteCode            = 'Lab'
                        BeginTime           = '0100'
                        LatestBeginTime     = '0600'
                        DaysOfWeek          = 'Saturday','Sunday'
                        TaskName            = 'Backup SMS Site Server'
                        TaskType            = 1
                        Enabled             = $true
                        RunInterval         = $null
                        BackupLocation      = $null
                        DeleteOlderThanDays = 0
                    }

                    $inputType1EnabledBad = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Backup SMS Site Server'
                        Enabled         = $true
                        DaysofWeek      = 'Saturday','Monday'
                        BeginTime       = '0200'
                        LatestBeginTime = '0700'
                        RunInterval     = 5
                    }
                }

                It 'Should throw when taskname is invalid' {
                    Mock -CommandName Get-TargetResource

                    { Set-TargetResource @badParamTaskName } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should throw when begin time is invalid' {
                    Mock -CommandName Get-TargetResource

                    { Set-TargetResource @badParamBeginTime } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should throw when an latest begin time is invalid' {
                    Mock -CommandName Get-TargetResource

                    { Set-TargetResource @badParamLatestBeginTime } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }

                It 'Should throw when an Backup location is Null' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType1Null }
                    Mock -CommandName Set-CMSiteMaintenanceTask -MockWith { throw }

                    { Set-TargetResource @inputType1EnabledBad } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSiteMaintenanceTask -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSiteSummaryTask -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'DSC_CMSiteMaintenance\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource Task Type 1' {
                BeforeEach {
                    $getReturnTaskType1 = @{
                        SiteCode            = 'Lab'
                        BeginTime           = '0100'
                        LatestBeginTime     = '0600'
                        DaysOfWeek          = 'Saturday','Sunday'
                        TaskName            = 'Backup SMS Site Server'
                        TaskType            = 1
                        Enabled             = $true
                        RunInterval         = $null
                        BackupLocation      = 'C:\Temp123'
                        DeleteOlderThanDays = 0
                    }

                    $inputType1Enabled = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Backup SMS Site Server'
                        Enabled         = $true
                        DaysofWeek      = 'Saturday','Sunday'
                        BeginTime       = '0100'
                        LatestBeginTime = '0600'
                        BackupLocation  = 'C:\Temp123'
                    }

                    $inputType1Disabled = @{
                        SiteCode = 'Lab'
                        TaskName = 'Backup SMS Site Server'
                        Enabled  = $false
                    }

                    $inputType1EnabledBad = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Backup SMS Site Server'
                        Enabled         = $true
                        DaysofWeek      = 'Saturday','Monday'
                        BeginTime       = '0200'
                        LatestBeginTime = '0700'
                        BackupLocation  = 'C:\Temp1234'
                        RunInterval     = 5
                    }

                    Mock -CommandName Get-TargetResource  -MockWith { $getReturnTaskType1 }
                }

                It 'Should return desired result true when TaskType 1 is correct' {
                    Test-TargetResource @inputType1Enabled | Should -Be $true
                }

                It 'Should return desired result false when TaskType 1 is incorrect' {
                    Test-TargetResource @inputType1EnabledBad | Should -Be $false
                }

                It 'Should return desired result false expected disabled and setting is enabled' {
                    Test-TargetResource @inputType1Disabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource Task Type 2' {
                BeforeEach {
                    $getReturnTaskType2 = @{
                        SiteCode            = 'Lab'
                        BeginTime           = '0300'
                        LatestBeginTime     = '0700'
                        DaysOfWeek          = @('Saturday','Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                        TaskName            = 'Summarize File Usage Metering Data'
                        TaskType            = 2
                        Enabled             = $true
                        DeleteOlderThanDays = 0
                        BackupLocation      = $null
                        RunInterval         = $null
                    }

                    $inputType2Disabled = @{
                        SiteCode = 'Lab'
                        TaskName = 'Summarize File Usage Metering Data'
                        Enabled  = $false
                    }

                    $inputType2Enabled = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Summarize File Usage Metering Data'
                        Enabled         = $true
                        DaysofWeek      = @('Saturday','Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                        BeginTime       = '0300'
                        LatestBeginTime = '0700'
                    }

                    $inputType2EnabledBad = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Summarize File Usage Metering Data'
                        Enabled         = $true
                        DaysofWeek      = @('Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
                        BeginTime       = '0400'
                        LatestBeginTime = '0800'
                        RunInterval     = 5
                    }

                    Mock -CommandName Get-TargetResource  -MockWith { $getReturnTaskType2 }
                }

                It 'Should return desired result true when TaskType 2 is correct' {
                    Test-TargetResource @inputType2Enabled | Should -Be $true
                }

                It 'Should return desired result false when TaskType 2 is incorrect' {
                    Test-TargetResource @inputType2EnabledBad | Should -Be $false
                }

                It 'Should return desired result false expected disabled and setting is enabled' {
                    Test-TargetResource @inputType2Disabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource Task Type 3' {
                BeforeEach {
                    $getReturnTaskType3 = @{
                        BeginTime           = '0000'
                        LatestBeginTime     = '0500'
                        DaysOfWeek          = 'Saturday'
                        TaskName            = 'Delete Aged Client Operations'
                        TaskType            = 3
                        Enabled             = $true
                        DeleteOlderThanDays = 20
                        SiteCode            = 'Lab'
                        BackupLocation      = $null
                        RunInterval         = $null
                    }

                    $inputType3Disabled = @{
                        SiteCode = 'Lab'
                        TaskName = 'Delete Aged Client Operations'
                        Enabled  = $false
                    }

                    $inputType3Enabled = @{
                        SiteCode            = 'Lab'
                        TaskName            = 'Delete Aged Client Operations'
                        Enabled             = $true
                        DaysofWeek          = 'Saturday'
                        BeginTime           = '0000'
                        LatestBeginTime     = '0500'
                        DeleteOlderThanDays = 20
                    }

                    $inputType3EnabledBad = @{
                        SiteCode            = 'Lab'
                        TaskName            = 'Delete Aged Client Operations'
                        Enabled             = $true
                        DaysofWeek          = 'Saturday','Sunday'
                        BeginTime           = '0100'
                        LatestBeginTime     = '0600'
                        DeleteOlderThanDays = 19
                        RunInterval         = 5
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnTaskType3 }
                }

                It 'Should return desired result true when TaskType 3 is correct' {
                    Test-TargetResource @inputType3Enabled | Should -Be $true
                }

                It 'Should return desired result false when TaskType 3 is incorrect' {
                    Test-TargetResource @inputType3EnabledBad | Should -Be $false
                }

                It 'Should return desired result false expected disabled and setting is enabled' {
                    Test-TargetResource @inputType3Disabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource Summary Tasks' {
                BeforeEach {
                    $getResultSummaryTaskEnabled = @{
                        SiteCode            = 'Lab'
                        BeginTime           = $null
                        LatestBeginTime     = $null
                        DaysOfWeek          = $null
                        TaskName            = 'Update Application Catalog Tables'
                        TaskType            = $null
                        RunInterval         = 1380
                        Enabled             = $true
                        BackupLocation      = $null
                        DeleteOlderThanDays = 0
                    }

                    $getResultSummaryTaskDisabled = @{
                        SiteCode            = 'Lab'
                        BeginTime           = $null
                        LatestBeginTime     = $null
                        DaysOfWeek          = $null
                        TaskName            = 'Update Application Catalog Tables'
                        TaskType            = $null
                        RunInterval         = 82800
                        Enabled             = $false
                        BackupLocation      = $null
                        DeleteOlderThanDays = 0
                    }

                    $inputSummaryTaskEnabled = @{
                        SiteCode    = 'Lab'
                        TaskName    = 'Update Application Catalog Tables'
                        Enabled     = $true
                        RunInterval = 1380
                    }

                    $inputSummaryTaskEnabledBad = @{
                        SiteCode    = 'Lab'
                        TaskName    = 'Update Application Catalog Tables'
                        Enabled     = $true
                        RunInterval = 40
                        BeginTime   = '0100'
                    }

                    $resultSummaryTaskDisabled = @{
                        TaskName      = 'Update Application Catalog Tables'
                        RunInterval   = 82800
                        Enabled       = $true
                        TaskParameter = 'AutoTune'
                    }
                }

                It 'Should return desired result true when Update Application Catalog Tables is correct' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultSummaryTaskEnabled }

                    Test-TargetResource @inputSummaryTaskEnabled | Should -Be $true
                }

                It 'Should return desired result false when Update Application Catalog Tables is incorrect' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultSummaryTaskDisabled }

                    Test-TargetResource @inputSummaryTaskEnabledBad | Should -Be $false
                }

                It 'Should return desired result false expected disabled and setting is enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getResultSummaryTaskEnabled }

                    Test-TargetResource @inputSummaryTaskDisabled | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource Parameter Validation' {
                BeforeEach {
                    $inputBadBegin = @{
                        SiteCode    = 'Lab'
                        TaskName    = 'Update Application Catalog Tables'
                        Enabled     = $true
                        BeginTime   = '01000'
                    }

                    $inputBadLatestBegin = @{
                        SiteCode        = 'Lab'
                        TaskName        = 'Update Application Catalog Tables'
                        Enabled         = $true
                        LatestBeginTime = 'e340'
                    }
                }

                It 'Should thow when BeginTime is wrong format' {
                    { Test-TargetResource @inputBadBegin } | Should -Throw
                }

                It 'Should throw when LatestBeginTime is in wrong format' {
                    { Test-TargetResource @inputBadLatestBegin } | Should -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
