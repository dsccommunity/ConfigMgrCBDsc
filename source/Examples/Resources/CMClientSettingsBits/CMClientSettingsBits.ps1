<#
    .SYNOPSIS
        A DSC configuration script to modify client policy Bits settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsBits DefaultClientSettings
        {
            SiteCode                   = 'Lab'
            ClientSettingName          = 'Default Client Agent Settings'
            EnableBitsMaxBandwidth     = $true
            MaxBandwidthBeginHr        = 0
            MaxBandwidthEndHr          = 23
            MaxTransferRateOnSchedule  = 900
            EnableDownloadOffSchedule  = $true
            MaxTransferRateOffSchedule = 9000
        }

        CMClientSettingsBits TestClient
        {
            SiteCode                  = 'Lab'
            ClientSettingName         = 'TestClient'
            EnableBitsMaxBandwidth    = $true
            MaxBandwidthBeginHr       = 1
            MaxBandwidthEndHr         = 11
            MaxTransferRateOnSchedule = 900
            EnableDownloadOffSchedule = $false
        }

        CMClientSettingsBits TestClientDisable
        {
            SiteCode               = 'Lab'
            ClientSettingName      = 'TestClientDisable'
            EnableBitsMaxBandwidth = $false
        }
    }
}
