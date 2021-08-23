Pure Storage PowerShell Toolkit

# Revision 2.0.2.0
8-23-2021
* Added cmdlets:
    Get-WindowsDiagnosticInfo, Get-FlashArrayRASession, Get-FlashArrayQuickCapacityStats, New-FlashArrayPGroupVolumes, Get-FlashArrayVolumeGrowth
    Changed cmdlets: Show-FlashArrayPGroupsConfig to proper verb of Get-FlashArrayPGroupsConfig
    Changed cmdlets: 'Pfa' prefixed cmdlets to 'FlashArray' for clarity with SDK v1 cmdlet naming as well as future FlashBlade cmdlets:
        Get-PfaSerialNumbers to Get-FlashArraySerialNumbers
        New-PfaDbSnapshot to New-FlashArrayDbSnapshot
        Invoke-PfaDbRefresh to Invoke-FlashArrayDbRefresh

# Revision 2.0.1.0
7-28-2021
* Merged Pure Storage DBAToolkit functions
* Cleaned up typos in Help

# Revision 2.0.0.0
Release version: 2.0.0.0
Release date: 7.13.2021
* Refactoring and cleanup of version 1911.0 coding.
* Additional helper functions added for SDK module check/load, admin-level check, Hyper-V checks, and FlashArray login.
* Adding of the global $Creds variable to make single array authentication easier.
** Create the $Creds variable by issuing a $Creds = Get-Credential command.
* 13 new cmdlets added (see list below).
* 2 cmdlets removed.
* Help fully updated.

## Known Issues

Cmdlet Get-FlashArraySpace - Code is returning a "ParseExact" error message for each object returned, but it does return valid data. Under investigation.

Cmdlet Get-FlashArrayDisconnectedVolumes - Code returning error for 'hash.Add' function. These can be ignored. Under investigation.

## Cmdlets included

* Get-AllHostVolumeInfo
* Set-WindowsPowerScheme
* Get-HostBusAdapter
* Register-HostVolumes
* Unregister-HostVolumes
* Get-QuickFixEngineering
* Test-WindowsBestPractices
* New-VolumeShadowCopy
* Get-VolumeShadowCopy
* New-FlashArrayCapacityReport
* Update-DriveInformation
* Sync-FlashArrayHosts
* Get-FlashArraySerialNumbers
* New-HypervClusterVolumeReport
* Set-TlsVersions
* Get-MPIODiskLBPolicy
* Set-MPIODiskLBPolicy
* Get-FlashArrayStaleSnapshots
* Get-FlashArrayDisconnectedVolumes
* Get-FlashArrayArraySpace
* Get-FlashArrayPgroupsConfig
* Remove-FlashArrayPendingDeletes
* Get-FlashArrayConfig
* Get-FlashArraySerialNumbers
* Get-FlashArrayHierarchy
* New-FlashArrayDbSnapshot
* Invoke-DynamicDataMasking
* Invoke-StaticDataMasking
* Invoke-FlashArrayDbRefresh
* Get-WindowsDiagnosticInfo
* Get-FlashArrayRASession
* Get-FlashArrayQuickCapacityStats
* New-FlashArrayPGroupVolumes
* Get-FlashArrayVolumeGrowth
