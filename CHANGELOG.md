# Revision 2.0.1.0
7-28-2021
* Merged Pure Storage DBAToolkit functions
* Cleaned up typos in Help

# Revision 2.0.0.0

Pure Storage PowerShell SDK Toolkit

Release version: 2.0.0.0
Release date: 7.13.2021

## Release Information

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

* Get-AllHostVolumeInfo  [New]
* Get-FlashArrayConfig  [New]
* Get-FlashArrayDisconnectedVolumes  [New] [Issue]
* Get-FlashArrayHierarchy  [New]
* Get-FlashArraySerialNumbers
* Get-FlashArraySpace  [New] [Issue]
* Get-FlashArrayStaleSnapshots [New]
* Get-HostBusAdapter
* Get-MPIODiskLBPolicy [New]
* Get-PfaSerialNumbers
* Get-QuickFixEngineering
* Get-VolumeShadowCopy
* New-FlashArrayCapacityReport
* New-HypervClusterVolumeReport  [New]
* New-VolumeShadowCopy
* Register-HostVolumes
* Remove-FlashArrayPendingDeletes  [New]
* Set-MPIODiskLBPolicy  [New]
* Set-TlsVersions  [New]
* Set-WindowsPowerScheme [New]
* Show-FlashArrayPgroupsConfig  [New]
* Sync-FlashArrayHosts
* Test-WindowsBestPractices
* Unregister-HostVolumes
* Update-DriveInformation
