<#
	===========================================================================
	Maintained by: 	fa-solutions@purestorage.com
	Organization: 	Pure Storage, Inc.
	Filename:     	PureStoragePowerShellToolkit.psm1
	Copyright:		(c) 2021 Pure Storage, Inc.
	Module Name: 	PureStoragePowerShellToolkit
	Description: 	PowerShell Script Module (.psm1)
	-------------------------------------------------------------------------
	Disclaimer
    The sample module and documentation are provided AS IS and are not supported by
	the author or the author’s employer, unless otherwise agreed in writing. You bear
	all risk relating to the use or performance of the sample script and documentation.
	The author and the author’s employer disclaim all express or implied warranties
	(including, without limitation, any warranties of merchantability, title, infringement
	or fitness for a particular purpose). In no event shall the author, the author’s employer
	or anyone else involved in the creation, production, or delivery of the scripts be liable
	for any damages whatsoever arising out of the use or performance of the sample script and
	documentation (including, without limitation, damages for loss of business profits,
	business interruption, loss of business information, or other pecuniary loss), even if
	such person has been advised of the possibility of such damages.
	===========================================================================

	Revision information:
	: version 2.0.1.0   Added SQL DBATooolkit functions New-PfaDbSnapshot, Invoke-DynamicDataMasking,
                        Invoke-StaticDataMasking, Invoke-PfaDbRefresh
                        Cleaned up Array login logic, misc typos.
    : version 2.0.0.0	GA release


	Contributors and many thanks go out to:
	Rob "Barkz" Barker @purestorage
	Robert "Q" Quimbey @purestorage
	Mike "Chief" Nelson @purestorage
	Julian "Doctor" Cates @purestorage
	Marcel Dussil @purestorage - https://en.pureflash.blog/
	Craig Dayton - https://github.com/cadayton
	Jake Daniels - https://github.com/JakeDennis
	Richard Raymond - https://github.com/data-sciences-corporation/PureStorage
	.. and all of the Pure Code community who provide excellent advice, feedback, & scripts, and for those that will in the future.
	#>

#Requires -Version 3

## BEGIN HELPER FUNCTIONS

#region ConvertTo-Base64
function ConvertTo-Base64() {
<#
    .SYNOPSIS
	Converts source file to Base64.
    .DESCRIPTION
	Helper function
	Supporting function to handle conversions.
    .INPUTS
	Source (Mandatory)
    .OUTPUTS
	Converted source.
#>
    Param (
        [Parameter(Mandatory = $true)][String] $Source
    )
    return [Convert]::ToBase64String((Get-Content $Source -Encoding byte))
}
#endregion

#region Convert-Size
function Convert-Size() {
<#
    .SYNOPSIS
	Converts volume sizes from B to MB, MB, GB, TB.
    .DESCRIPTION
	Helper function
	Supporting function to handle conversions.
    .INPUTS
	ConvertFrom (Mandatory)
	ConvertTo (Mandatory)
	Value (Mandatory)
	Precision (Optional)
    .OUTPUTS
	Converted size of volume.
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][ValidateSet("Bytes", "KB", "MB", "GB", "TB")][String]$ConvertFrom,
        [Parameter(Mandatory = $true)][ValidateSet("Bytes", "KB", "MB", "GB", "TB")][String]$ConvertTo,
        [Parameter(Mandatory = $true)][Double]$Value,
        [Parameter(Mandatory = $false)][Int]$Precision = 4
    )
    switch ($ConvertFrom) {
        "Bytes" { $value = $Value }
        "KB" { $value = $Value * 1024 }
        "MB" { $value = $Value * 1024 * 1024 }
        "GB" { $value = $Value * 1024 * 1024 * 1024 }
        "TB" { $value = $Value * 1024 * 1024 * 1024 * 1024 }
    }

    switch ($ConvertTo) {
        "Bytes" { return $value }
        "KB" { $Value = $Value / 1KB }
        "MB" { $Value = $Value / 1MB }
        "GB" { $Value = $Value / 1GB }
        "TB" { $Value = $Value / 1TB }
    }

    return [Math]::Round($Value, $Precision, [MidPointRounding]::AwayFromZero)
}
#endregion

#region New-FlashArrayReportPieChart
function New-FlashArrayReportPieChart() {
<#
    .SYNOPSIS
	Creates graphic pie chart .png image file for use in report.
    .DESCRIPTION
	Helper function
	Supporting function to create a pie chart.
    .OUTPUTS
	piechart.png.
#>
    Param (
        [string]$FileName,
        [float]$SnapshotSpace,
        [float]$VolumeSpace,
        [float]$CapacitySpace
    )

    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

    $chart = New-Object System.Windows.Forms.DataVisualization.charting.chart
    $chart.Width = 700
    $chart.Height = 500
    $chart.Left = 10
    $chart.Top = 10

    $chartArea = New-Object System.Windows.Forms.DataVisualization.charting.chartArea
    $chart.chartAreas.Add($chartArea)
    [void]$chart.Series.Add("Data")

    $legend = New-Object system.Windows.Forms.DataVisualization.charting.Legend
    $legend.Name = "Legend"
    $legend.Font = "Verdana"
    $legend.Alignment = "Center"
    $legend.Docking = "top"
    $legend.Bordercolor = "#FE5000"
    $legend.Legendstyle = "row"
    $chart.Legends.Add($legend)

    $datapoint = New-Object System.Windows.Forms.DataVisualization.charting.DataPoint(0, $SnapshotSpace)
    $datapoint.AxisLabel = "SnapShots " + "(" + $SnapshotSpace + " MB)"
    $chart.Series["Data"].Points.Add($datapoint)

    $datapoint = New-Object System.Windows.Forms.DataVisualization.charting.DataPoint(0, $VolumeSpace)
    $datapoint.AxisLabel = "Volumes " + "(" + $VolumeSpace + " GB)"
    $chart.Series["Data"].Points.Add($datapoint)

    $chart.Series["Data"].chartType = [System.Windows.Forms.DataVisualization.charting.SerieschartType]::Doughnut
    $chart.Series["Data"]["DoughnutLabelStyle"] = "Outside"
    $chart.Series["Data"]["DoughnutLineColor"] = "#FE5000"

    $Title = New-Object System.Windows.Forms.DataVisualization.charting.Title
    $chart.Titles.Add($Title)
    $chart.SaveImage($FileName + ".png", "png")
}
#endregion

#region Get-Sdk1Module
function Get-Sdk1Module() {
<#
    .SYNOPSIS
	Confirms that PureStoragePowerShellSDK version 1 module is loaded, present, or missing. If missing, it will download it and import. If internet access is not available, the function will error.
    .DESCRIPTION
	Helper function
	Supporting function to load required module.
    .OUTPUTS
	PureStoragePowerShellSDK version 1 module.
#>
    $m = "PureStoragePowerShellSDK"
    # If module is imported, continue
    if (Get-Module | Where-Object { $_.Name -eq $m }) {
    }
    else {
        # If module is not imported, but available on disk, then import
        if (Get-InstalledModule | Where-Object { $_.Name -eq $m }) {
            Import-Module $m -ErrorAction SilentlyContinue
        }
        else {
            # If module is not imported, not available on disk, then install and import
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }) {
                Write-Warning "The $m module does not exist."
                Write-Host "We will attempt to install the module from the PowerShell Gallery. Please wait..."
                Install-Module -Name $m -Force -ErrorAction SilentlyContinue -Scope CurrentUser
                Import-Module $m -ErrorAction SilentlyContinue
            }
            else {
                # If module is not imported, not available on disk, and we cannot access it online, then abort
                Write-Host "Module $m not imported, not available on disk, and we are not able to download it from the online gallery... Exiting."
                EXIT 1
            }
        }
    }
}
#endregion

#region Get-DbaToolsModule
function Get-DbaToolsModule() {
    <#
    .SYNOPSIS
	Confirms that dbatools PowerShell module is loaded, present, or missing. If missing, it will download it and import. If internet access is not available, the function will error.
    .DESCRIPTION
	Helper function
	Supporting function to load required module.
    .OUTPUTS
	dbatools module - https://dbatools.io.
#>
    $m = "dbatools"
    # If module is imported, continue
    if (Get-Module | Where-Object { $_.Name -eq $m }) {
    }
    else {
        # If module is not imported, but available on disk, then import
        if (Get-InstalledModule | Where-Object { $_.Name -eq $m }) {
            Import-Module $m -ErrorAction SilentlyContinue
        }
        else {
            # If module is not imported, not available on disk, then install and import
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }) {
                Write-Warning "$m module does not exist."
                Write-Host "We will attempt to install the module from the PowerShell Gallery. Please wait..."
                Install-Module -Name $m -Force -ErrorAction SilentlyContinue -Scope CurrentUser
                Import-Module $m -ErrorAction SilentlyContinue
            }
            else {
                # If module is not imported, not available on disk, and we cannot access it online, then abort
                Write-Host "Module $m not imported, not available on disk, and we are not able to download it from the online gallery... Exiting."
                EXIT 1
            }
        }
    }
}
#endregion

#region Get-ElevatedStatus
function Get-ElevatedStatus() {
<#
    .SYNOPSIS
	Confirms elevated permissions to run cmdlets.
    .DESCRIPTION
	Helper function
	Supporting function to confirm administrator permissions.
    .OUTPUTS
	Error on non-administrative permissions.
#>
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
                [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this cmdlet. Open the PowerShell console as an administrator and run this cmdlet again."
        Break
    }
}
#endregion

#region Get-HypervStatus
function Get-HypervStatus() {
    <#
    .SYNOPSIS
	Confirms that the HyperV role is installed ont he server.
    .DESCRIPTION
	Helper function
	Supporting function to ensure proper role is installed.
    .OUTPUTS
	Error on missing HyperV role.
    #>
    $hypervStatus = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State
    if ($hypervStatus -ne "Enabled") {
        Write-Host "Hyper-V is not running. This cmdlet must be run on a Hyper-V host."
        break
    }
}
#endregion
## END HELPER FUNCTIONS

#### FLASHARRAY FUNCTIONS

#region Get-HostVolumeInfo
function Get-AllHostVolumeInfo() {
    <#
    .SYNOPSIS
    Retrieves Host Volume information from FlashArray.
    .DESCRIPTION
    Retrieves Host Volume information including volumes attributes from a FlashArray.
    .INPUTS
    EndPoint IP or FQDN required
    .OUTPUTS
    Outputs Host volume information
    .EXAMPLE
    Get-HostVolumeinfo -EndPoint myarray.mydomain.com

    Retrieves Host Volume information from the FlashArray myarray.mydomain.com.
    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Position=0,Mandatory=$True)][ValidateNotNullOrEmpty()][string] $EndPoint
	)
	Get-Sdk1Module
    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

	$hostNames = Get-PfaHosts -array $FlashArray | Select-Object -Property name
	foreach ($hostName in $hostnames) {
		$hostvols = Get-PfaHostVolumeConnections -Array $FlashArray -Name $hostName.name
		$hostvols | Format-Table -AutoSize;
		ForEach-Object -InputObject $hostvols {
			$vols = $_.vol;
			$volattribs = @();
			if ($_.vol.count -gt 1) {
				for ($i = 0; $i -lt $_.vol.count; $i++) {
					$volattrib = Get-PfaVolume -Array $FlashArray -Name $vols[$i];
					$volattribs += $volattrib;
				}
				$volattribs |
				Select-Object name, created, source, serial, @{Name = "Size(GB)"; Expression = { $_.size / 1GB } } |
				Format-Table -AutoSize;
			}
			else {
				Get-PfaVolume -Array $FlashArray -Name $_.vol |
				Select-Object name, created, source, serial, @{Name = "Size(GB)"; Expression = { $_.size / 1GB } } |
				Format-Table -AutoSize;
			}
		}
	}
}
#endregion

#region Get-PfaSerialNumbers
function Get-PfaSerialNumbers() {
    <#
    .SYNOPSIS
    Retrieves FlashArray volume serial numbers connected to the host.
    .DESCRIPTION
    Cmdlet queries WMI on the localhost to retrieve the disks that are associated to Pure FlashArrays.
    .INPUTS
    EndPoint IP or FQDN required.
    .OUTPUTS
    Outputs serial numbers of FlashArrays devices.
    .EXAMPLE
    Get-PfaSerialNumbers

    Returns serial number information on Pure FlashArray disk devices connected to the host.
    #>
    $AllDevices = Get-WmiObject -Class Win32_DiskDrive -Namespace 'root\CIMV2'
    ForEach ($Device in $AllDevices) {
        if ($Device.Model -like 'PURE FlashArray*') {
            @{
                Name     = $Device.Name;
                Caption  = $Device.Caption;
                Index    = $Device.Index;
                SerialNo = $Device.SerialNumber;
            }
        }
    }
}
#endregion

#region New-HypervClusterVolumeReport
function New-HypervClusterVolumeReport() {
    <#
    .SYNOPSIS
    Creates a Excel report on volumes connected to a Hyper-V cluster.
    .DESCRIPTION
    This creates separate CSV files for VM, Windows Hosts, and FlashArray information that is part of a HyperV cluster. It then takes that output and places it into a an Excel workbook that contains sheets for each CSV file.
    .PARAMETER VmCsvFileName
    Optional. Defaults to VMs.csv.
    .PARAMETER WinCsvFileName
    Optional. defaults to WindowsHosts.csv.
    .PARAMETER PfaCsvFileName
    Optional. defaults to FlashArrays.csv.
    .PARAMETER ExcelFile
    Optional. defaults to HypervClusterReport.xlsx.
    .INPUTS
    Endpoint is mandatory. VM, Win, and PFA csv file names are optional.
    .OUTPUTS
    Outputs individual CSV files and creates an Excel workbook that is built using the required PowerShell module ImportExcel, created by Douglas Finke.
    .EXAMPLE
    New-HypervClusterVolumeReport -EndPoint myarray -VmCsvName myVMs.csv -WinCsvName myWinHosts.csv -PfaCsvName myFlashArray.csv -ExcelFile myExcelFile

    This will create three separate CSV files with HyperV cluster information and incorporate them into a single Excel workbook.
    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint,
        [Parameter(Mandatory=$False)][string]$VmCsvFileName = "VMs.csv",
        [Parameter(Mandatory=$False)][string]$WinCsvFileName = "WindowsHosts.csv",
        [Parameter(Mandatory=$False)][string]$PfaCsvFileName = "FlashArrays.csv",
        [Parameter(Mandatory=$False)][string]$ExcelFile = "HypervClusterReport.xlxs"
    )
    try {
        Get-ElevatedStatus

        Get-HypervStatus

        ## Check for modules & features
        Write-Host "Checking, installing, and importing prerequisite modules."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $modulesArray = @(
            "PureStoragePowerShellSDK",
            "ImportExcel"
        )
        ForEach ($mod in $modulesArray) {
            If (Get-Module -ListAvailable $mod) {
                Continue
            }
            Else {
                Install-Module $mod -Force -ErrorAction 'SilentlyContinue'
                Import-Module $mod -ErrorAction 'SilentlyContinue'
            }
        }

        Write-Host "Checking and installing prerequisite Windows Features."
        $osVer = (Get-ComputerInfo).WindowsProductName
        $featuresArray = @(
            "hyper-v-powershell",
            "rsat-clustering-powershell"
        )
        ForEach ($fea in $featuresArray) {
            If (Get-WindowsFeature $fea | Select-Object -ExpandProperty installed) {
                Continue
            }
            Else {
                If ($osVer -le "2008") {
                    Add-WindowsFeature -Name $fea -Force -ErrorAction 'SilentlyContinue'
                }
                Else {
                    Install-WindowsFeature -Name $fea -Force -ErrorAction 'SilentlyContinue'
                }
            }
        }

        # Connect to FlashArray
        if (!($Creds)) {
            try {
                $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
            }
            catch {
                $ExceptionMessage = $_.Exception.Message
                Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
                Return
            }
        }
        else {
            try {
                $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
            }
            catch {
                $ExceptionMessage = $_.Exception.Message
                Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
                Return
            }
        }

        ## Get a list of VMs - VM Sheet
        $vmList = Get-VM -ComputerName (Get-ClusterNode)
        $vmList | ForEach-Object { $vmState = $_.state; $vmName = $_.name; Write-Output $_; } | ForEach-Object { Get-VHD -ComputerName $_.ComputerName -VMId $_.VMId
        } | Select-Object -Property path, @{n = 'VMName'; e = { $vmName } }, @{n = 'VMState'; e = { $vmState } }, computername, vhdtype, @{Label = 'Size(GB)'; expression = { [Math]::Round($_.size / 1gb, 2) -as [int] } }, @{label = 'SizeOnDisk(GB)'; expression = { [Math]::Round($_.filesize / 1gb, 2) -as [int] } } | Export-Csv $VmCsvFileName
        Import-Csv $VmCsvFileName | Export-Excel -Path $ExcelFile -AutoSize -WorkSheetname 'VMs'

        ## Get windows physical disks - Windows Host Sheet
        Get-ClusterNode | ForEach-Object { Get-WmiObject Win32_Volume -Filter "DriveType='3'" -ComputerName $_ | ForEach-Object {
                [pscustomobject][ordered]@{
                    Server        = $_.__Server
                    Label         = $_.Label
                    Name          = $_.Name
                    TotalSize_GB  = ([Math]::Round($_.Capacity / 1GB, 2))
                    FreeSpace_GB  = ([Math]::Round($_.FreeSpace / 1GB, 2))
                    SizeOnDisk_GB = ([Math]::Round(($_.Capacity - $_.FreeSpace) / 1GB, 2))
                }
            } } | Export-Csv $WinCsvFileName -NoTypeInformation
        Import-Csv $WinCsvFileName | Export-Excel -Path $ExcelFile -AutoSize -WorkSheetname 'Windows Hosts'
        ## Get Pure FlashArray volumes and space - FlashArray Sheet
        Function GetSerial {
            [Cmdletbinding()]
            Param(   [Parameter(ValueFromPipeline)]
                $findserial)
            $GetVol = Get-Volume -FilePath $findserial | Select-Object -ExpandProperty path
            $GetDiskNum = Get-Partition | Where-Object -Property accesspaths -CContains $getvol | Select-Object disknumber
            Get-Disk -Number $getdisknum.disknumber | Select-Object serialnumber
        }
        $pathQ = $VmList | ForEach-Object { Get-VHD -ComputerName $_.ComputerName -VMId $_.VMId } | Select-Object -ExpandProperty path
        $serials = GetSerial { $pathQ } -ErrorAction SilentlyContinue

        ## FlashArray volumes
        $pureVols = Get-PfaVolumes -Array $FlashArray | Where-Object { $serials.serialnumber -contains $_.serial } | ForEach-Object { Get-PfaVolumeSpaceMetrics -Array $FlashArray -VolumeName $_.name } | Select-Object name, size, total, data_reduction

        $pureVols | Select-Object Name, @{Name = "Size(GB)"; Expression = { [math]::round($_.size / 1gb, 2) } }, @{Name = "SizeOnDisk(GB)"; Expression = { [math]::round($_.total / 1gb, 2) } }, @{Name = "DataReduction"; Expression = { [math]::round($_.data_reduction, 2) } } | Export-Csv $PfaCsvFileName -NoTypeInformation
        Import-Csv $PfaCsvFileName | Export-Excel -Path $ExcelFile -AutoSize -WorkSheetname 'FlashArrays'

    }
    catch {
        Write-Host "There was a problem running this cmdlet. Please try again or submit an Issue in the GitHub Repository."
    }
}
#endregion

#region Sync-FlashArrayHosts
function Sync-FlashArrayHosts() {
    <#
    .SYNOPSIS
    Synchronizes the hosts amd host protocols between two FlashArrays.
    .DESCRIPTION
    This cmdlet will retrieve the current hosts from the Source array and create them on the target array. It will also add the FC (WWN) or iSCSI (iqn) settings for each host on the Target array.
    .PARAMETER SourceArray
    Required. FQDN or IP address of the source FlashArray.
    .PARAMETER TargetArray
    Required. FQDN or IP address of the source FlashArray.
    .PARAMETER Protocol
    Required. 'FC' for Fibre Channel WWNs or 'iSCSI' for iSCSI IQNs.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Sync-FlashArraysHosts -SourceArray mySourceArray -TargetArray myTargetArray -Protocol FC

    Synchronizes the hosts and hosts FC WWNs from the mySourceArray to the myTargetArray.
    .NOTES
    This cmdlet cannot utilize the global $Creds variable as it requires two logins to two separate arrays.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0,Mandatory=$True)][ValidateNotNullOrEmpty()][string] $SourceArray,
        [Parameter(Position=1,Mandatory=$True)][ValidateNotNullOrEmpty()][string]$TargetArray,
        [Parameter(Mandatory = $True)][ValidateSet("iSCSI", "FC")][string]$Protocol
    )

    $FlashArray1 = New-PfaArray -EndPoint $SourceArray -Credentials (Get-Credential) -IgnoreCertificateError
    $FlashArray2 = New-PfaArray -EndPoint $TargetArray -Credentials (Get-Credential) -IgnoreCertificateError

    Get-PfaHosts -Array $FlashArray1 | New-PfaHost -Array $FlashArray2
    Get-PfaHostGroups -Array $FlashArray1 | New-PfaHostGroup -Array $FlashArray2

    $fa1Hosts = Get-PfaHosts -Array $FlashArray1

    switch ($Procotol) {
        'iSCSI' {
            foreach ($fa1Host in $fa1Hosts) {
                Add-PfaHostIqns -Array $FlashArray2 -AddIqnList $fa1Host.iqn -Name $fa1Host.name
            }
        }
        'FC' {
            foreach ($fa1Host in $fa1Hosts) {
                Add-PfaHostWwns -Array $FlashArray2 -AddWwnList $fa1Host.wwn -Name $fa1Host.name
            }
        }
    }
}
#endregion

#region Get-FlashArrayStaleSnapshots
function Get-FlashArrayStaleSnapshots() {
    <#
    .SYNOPSIS
    Retrieves aged snapshots and allows for Deletion and Eradication of such snapshots.
    .DESCRIPTION
    This cmdlet will retrieve all snapshots that are beyond the specified SnapAgeThreshold. It allows for the parameters of Delete and Eradicate, and if set to $true, it will delete and eradicate the snapshots returned. It allows for the parameter of Confirm, and if set to $true, it will prompt before deletion and/or eradication of the snapshots.
    Snapshots must be deleted before they can be eradicated.
    .PARAMETER EndPoint
    Required. Endpoint is the FlashArray IP or FQDN.
    .PARAMETER SnapAgeThreshold
    Required. SnapAgeThreshold is the number of days from the current date. Delete. Confirm, and Eradicate are optional.
    .PARAMETER Delete
    Optional. If set to $true, delete the snapshots.
    .PARAMETER Eradicate
    Optional. If set to $true, eradicate the deleted snapshots (snapshot must be flagged as deleted).
    .PARAMETER Confirm
    Optional. If set to $true, provide user confirmation for Deletion or Eradication of the snapshots.
    .OUTPUTS
    Returns a listing of snapshots that are beyond the specified threshold and displays final results.
    .EXAMPLE
    Get-FlashArrayStaleSnapshots -EndPoint myArray -SnapAgeThreshold 30

    Returns all snapshots that are older than 30 days from the current date.

    .EXAMPLE
    Get-FlashArrayStaleSnapshots -EndPoint myArray -SnapAgeThreshold 30 -Delete:$true -Eradicate:$true -Confirm:$false

    Returns all snapshots that are older than 30 days from the current date, deletes and eradicates them without confirmation.
    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint,
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $SnapAgeThreshold,
        [switch]$Delete,
        [switch]$Eradicate,
        [switch]$Confirm
    )
    # Establish variables, Pure time format, and gather current time.
    $1GB = 1024 * 1024 * 1024
    $CurrentTime = Get-Date
    $DateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ'

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    # Establish and reset counter variables.
    [int]$SpaceConsumedTotal = 0
    [int]$SnapNumberTotal = 0
    $Timespan = $null
    [int]$SpaceConsumed = 0
    [int]$SnapNumber = 0
    try {
        $Snapshots = Get-PfaAllVolumeSnapshots -Array $FlashArray

        Write-Output ""
        Write-Output "========================================================================="
        Write-Output "      $EndPoint                               "
        Write-Output "========================================================================="
    }
    catch {
        Write-Host "Error processing $($EndPoint)."
    }
    #Get all snapshots and compute the age of them. $DateTimeFormat variable taken from above; this is needed in order to parse Pure time format.
    foreach ($Snapshot in $Snapshots) {
        $SnapshotDateTime = $Snapshot.created
        $SnapshotDateTime = [datetime]::ParseExact($SnapshotDateTime, $DateTimeFormat, $null)
        $Timespan = New-TimeSpan -Start $SnapshotDateTime -End $CurrentTime
        $SnapAge = $($Timespan.Days + $($Timespan.Hours / 24) + $($Timespan.Minutes / 1440))
        $SnapAge = [math]::Round($SnapAge, 2)

        #Find snaps older than given threshold and output with formatted data.
        if ($SnapAge -gt $SnapAgeThreshold) {
            $SnapStats = Get-PfaSnapshotSpaceMetrics -Array $FlashArray -Name $Snapshot.name
            $SnapSize = [math]::round($($SnapStats.total / $1GB), 2)
            $SpaceConsumed = $SpaceConsumed + $SnapSize
            $SnapNumber = $SnapNumber + 1

            #Delete snapshots
            if ($Delete -eq $true -and $Eradicate -eq $true) {
                Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $Snapshot.name -Eradicate -Confirm $Confirm
                Write-Output "Eradicating $($Snapshot.name) - $($SnapSize) GB."
            }
            elseif ($Delete -eq $true) {
                Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $Snapshot.name -Confirm $Confirm
                Write-Output "Deleting $($Snapshot.name) - $($SnapSize) GB."
            }
            else {
                Write-Output $Snapshot.name
                Write-Output "          $SnapSize GB"
                Write-Output "          $SnapAge days"
            }
        }

    }
    #Display final message for array results.
    Write-Output "There are $($SnapNumber) snapshot(s) older than $($SnapAgeThreshold) days consuming a total of $($SpaceConsumed) GB on the array."

    $SnapNumberTotal = $SnapNumberTotal + $SnapNumber
    $SpaceConsumedTotal = $SpaceConsumedTotal + $SpaceConsumed
}
Write-Output "There are $($SnapNumberTotal) snapshot(s) older than $($SnapAgeThreshold) days consuming a total of $($SpaceConsumedTotal) GB."
#endregion

#region Get-FlashArrayDisconnectedVolumes
Function Get-FlashArrayDisconnectedVolumes() {
    <#
    .SYNOPSIS
    Retrieves disconnected volume information for a FlashArray.
    .DESCRIPTION
    This cmdlet will retrieve information for volumes that are ina disconnected state for a FlashArray.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .INPUTS
    None
    .OUTPUTS
    Disconnected volume information is displayed.
    .EXAMPLE
    Get-FlashArrayDisconnectedVolumes -EndPoint myArray
    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint
    )
    #Math values
    $1GB = 1024 * 1024 * 1024
    $1TB = 1024 * 1024 * 1024 * 1024
    Get-Sdk1Module

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    $faSpace = Get-PfaArraySpaceMetrics -Array $FlashArray

    $Hosts = Get-PfaHosts -Array $FlashArray
    ForEach ($HostVol in $Hosts) {
        $ConnectedVolumes += @(Get-PfaHostVolumeConnections -Array $FlashArray -Name $HostVol.name | Select-Object vol)
    }

    #Get all volumes
    $AllVolumes = @(Get-PfaVolumes -Array $FlashArray | Select-Object name)
    $hash = @{}
    foreach ($i in $ConnectedVolumes) {
        $Vol = $i.vol
        $hash.Add($z, $Vol)
        $z++
    }
    foreach ($j in $AllVolumes) {
        if (!$hash.ContainsValue($j.name)) {
            $DisconnectedVolumes += $j.name
        }
        else {
            $hash.Remove($j.name)
        }
    }
    Write-Output ""
    Write-Output "`t$($FlashArray) - $([math]::Round((($faSpace.total)/$1TB),2)) TB/$([math]::Round($(($faSpace.capacity)/$1TB),2)) TB ($([math]::Round((($faSpace.total)*100)/$($faSpace.capacity),2))% Full)`n"
    Write-Output "==================================================="
    Write-Output "`t`t Disconnected Volumes ($($DisconnectedVolumes.Count-1) of $($hash.Count))"
    Write-Output "==================================================="

    #If the array has a disconnected volume, gather volume space metrics
    if (($DisconnectedVolumes.Count) -gt 1 ) {
        foreach ($DisconnectedVolume in $DisconnectedVolumes) {
            if ($null -ne $DisconnectedVolume) {
                $VolDetails = Get-PfaVolumeSpaceMetrics -array $FlashArray -VolumeName $DisconnectedVolume
                $GetVol = Get-PfaVolume -Array $FlashArray -Name $DisconnectedVolume
                $VolSerial = $GetVol.serial
                $Space = ($($VolDetails.volumes / $1GB))
                $Space = [math]::Round($Space, 3)
                $Total = [math]::Round(($($VolDetails.size / $1TB)), 3)
                $Reduction = $VolDetails.data_reduction
                $Reduction = [math]::Round($Reduction, 0)
                Write-Output "$($DisconnectedVolume) `n`t $($VolSerial) `n`t $($Space) GB Consumed `n`t $($Total) TB Provisioned `n`t $($Reduction):1 Reduction `n" | Format-List
                $PotentialSpaceSavings = $PotentialSpaceSavings + $($VolDetails.volumes / $1GB)
            }
        }
        Write-Output "Potential space savings for $($faEndPoint) is $([math]::Round($PotentialSpaceSavings,3)) GB."
    }
    else {
        Write-Output "No Disconnected Volumes found."
    }
}
#endregion

#region Get-FlashArraySpace
Function Get-FlashArraySpace() {
    <#
    .SYNOPSIS
    Retrieves the space used and available for a FlashArray.
    .DESCRIPTION
    This cmdlet will return various array space metrics for the given FlashArray.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .INPUTS
    None
    .OUTPUTS
    Various FlashArray space used and available information.
    .EXAMPLE
    Get-FlashArraySpace -EndPoint myArray

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint
    )
    Get-Sdk1Module
    #Math values
    #	[double]$1GB = 1024 * 1024 * 1024
    [double]$1TB = 1024 * 1024 * 1024 * 1024

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    $ArraySpace = @()
    $faSpace = Get-PfaArraySpaceMetrics -Array $FlashArray
    $faSpace | Select-Object @{name = 'Hostname'; expr = { $_.Hostname } },
    @{name = 'Percent Used'; expr = { ($faSpace.total / $faSpace.capacity).ToString("P") } },
    @{name = 'Capacity Used (TB)'; expr = { ([math]::Round([double]($_.Total / $1TB), 2)) } },
    @{name = 'Capacity Free (TB)'; expr = { ([math]::Round((($faSpace.capacity - $faSpace.total) / $1TB), 2)) } },
    @{name = 'Volume Space (TB)'; expr = { ([math]::Round([double]($_.Volumes / $1TB), 2)) } },
    @{name = 'Shared Space (TB)'; expr = { ([math]::Round([double]($_.Shared_Space / $1TB), 2)) } },
    @{name = 'Snapshot Space (TB)'; expr = { ([math]::Round([double]($_.Snapshots / $1TB), 2)) } },
    @{name = 'System Space (TB)'; expr = { ([math]::Round([double]($_.System / $1TB), 2)) } },
    @{name = 'Total Storage (TB)'; expr = { ([math]::Round([double]($_.Capacity / $1TB), 2)) } },
    @{name = 'Data Reduction'; expr = { [math]::Round($_.Data_Reduction, 2) } },
    @{name = 'Thin Provisioning'; expr = { [math]::Round($_.Thin_Provisioning * 10, 2) } }
    $ArraySpace | Format-Table -AutoSize
}
#endregion

#region Show-FlashArrayPgroupsConfig
Function Show-FlashArrayPgroupsConfig() {
    <#
    .SYNOPSIS
    Retrieves Protection Group (PGroup) information for the FlashArray.
    .DESCRIPTION
    Retrieves Protection Group (PGroup) information for the FlashArray.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .INPUTS
    None
    .OUTPUTS
    Protection Group information is displayed.
    .EXAMPLE
    Show-FlashArrayPgroupsConfig -EndPoint myArrayg

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint
    )
    Get-Sdk1Module

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    $ProtectionGroups = Get-PfaProtectionGroups -Array $FlashArray
    $ErrorActionPreference = "Continue"

    foreach ($ProtectionGroup in $ProtectionGroups) {
        $RetentionDetails = Get-PfaProtectionGroupRetention -Array $FlashArray -ProtectionGroupName $ProtectionGroup.name
        $ScheduleDetails = Get-PfaProtectionGroupSchedule -Array $FlashArray -ProtectionGroupName $ProtectionGroup.name

        if ($ScheduleDetails.replicate_enabled -eq "True") {
            Write-Host "========================================================================================"
            Write-Host "                 $($ProtectionGroup.name)                               " -ForegroundColor Green
            Write-Host "========================================================================================"
            Write-Host "Host Groups: $($ProtectionGroup.hgroups)"
            Write-Host "Hosts: $($ProtectionGroup.hosts)"
            Write-Host "Volumes: $($ProtectionGroup.volumes)"
            Write-Host ""
            Write-Host "A snapshot is taken and replicated every $($ScheduleDetails.replicate_frequency/60) minutes."
            Write-Host "$(($RetentionDetails.target_all_for/60)/($ScheduleDetails.replicate_frequency/60)) snapshot(s) are kept on the target for $($RetentionDetails.target_all_for/60) minutes."
            Write-Host "$($RetentionDetails.target_per_day) additional snapshot(s) are kept for $($RetentionDetails.target_days) more days."
        }
        else {
            Write-Host "=========================================================================================="
            Write-Host "                $($ProtectionGroup.name)                               " -ForegroundColor Yellow
            Write-Host "=========================================================================================="
            Write-Host "Host Groups: $($ProtectionGroup.hgroups)"
            Write-Host "Hosts: $($ProtectionGroup.hosts)"
            Write-Host "Volumes: $($ProtectionGroup.volumes)"
            Write-Host ""
            Write-Host "$($ProtectionGroup.name) is disabled." -ForegroundColor Yellow
            Write-Host ""
        }
    }
}
#endregion

#region Remove-FlashArrayPendingDeletes
Function Remove-FlashArrayPendingDeletes() {
    <#
    .SYNOPSIS
    Reports on pending FlashArray Volume and Snapshots deletions and optionally Eradicates them.
    .DESCRIPTION
    This cmdlet will return information on any volumes or volume snapshots that are pending eradication after deletion and optionally prompt for eradication of those objects. The user will be prompted for confirmation.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .INPUTS
    None
    .OUTPUTS
    Volume and volume snapshots awaiting eradication.
    .EXAMPLE
    Remove-FlashArrayPendingDelete -EndPoint myArray

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint
    )

    Get-Sdk1Module

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    $pendingvolumelist = Get-PfaPendingDeleteVolumes -Array $FlashArray
    $pendingsnaplist = Get-PfaPendingDeleteVolumeSnapshots -Array $FlashArray
    if (!pendingvolumelist) {
        Write-Host "No volumes are pending delete."
    }
    else {
    Write-Host "Listing PENDING volumes and snapshots that exist on the array."
    Write-Host "======================================================================================================================`n"
    Write-Host "Volumes in PENDING state"
    foreach ($volume in $pendingvolumelist) {
        Write-Host " -" $volume.name
    }
    }
    if (!pendingsnaplist) {
        Write-Host "No snapshots are pending delete."
        break
    }
    else {
    Write-Host "Snapshots in PENDING state"
    foreach ($volumesnap in $pendingsnaplist) {
        Write-Host " -" $volumesnap.name
    }
    }
    $confirmstring = "proceed"
    Write-Host "Please confirm that you wish to perform an unrecoverable operation."
    Write-Host "======================================================================================================================`n"
    Write-Host "Please type the word $confirmstring to eradicate the pending deleted volumes and snapshots."
    Write-Host "The action will initiate immediately upon inputting $confirmstring . This operation CANNOT be undone." -fore yellow
    $user_response = Read-Host "`t"
    if (($user_response.ToLower() -ne $confirmstring.ToLower())) {
        Write-Host "Your input was [$user_response]. It was not the word $confirmstring. Exiting."
        exit
    }
    Write-Host "Eradicating PENDING volumes and snapshots."
    Write-Host "======================================================================================================================`n"

    foreach ($volume in $pendingvolumelist) {
        Write-Host " -" $volume.name " eradicated."
        Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $volume.name -Eradicate
    }

    foreach ($volumesnap in $pendingsnaplist) {
        Write-Host " -" $volumesnap.name " eradicated"
        Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $volumesnap.name -Eradicate
    }
    Write-Host "Volume and Snapshot pending deletes have been eradicated."
}
#endregion

#region Get-FlashArrayConfig
Function Get-FlashArrayConfig() {
    <#
    .SYNOPSIS
    Retrieves and outputs to a file the configuration of the FlashArray.
    .DESCRIPTION
    This cmdlet will run Purity CLI commands to retrieve the base configuration of a FlashArray and output it to a file. This file is formatted for the CLI, not necessarily human-readable.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .PARAMETER OutFile
    Optional. The file path and filename that will contain the output. if not specified, the default is the current folder\Array_Config.txt.
    .PARAMETER ArrayName
    Optional. The FlashArray name to use in the output. Defaults to $EndPoint.
    .INPUTS
    None
    .OUTPUTS
    Configuration file.
    .EXAMPLE
    Get-FlashArray -EndPoint myArray -ArrayName Array100

    Retrieves the configuration for a FlashArray and stores it in the current path as Array100_config.txt.

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint,
        [Parameter(Mandatory = $False)][string] $OutFile = "Array_Config.txt",
        [Parameter(Mandatory = $False)][string] $ArrayName
    )
    Get-Sdk1Module
    $GetDate = Get-Date
    # Connect to FlashArray
    if (!($Creds)) {
        $Creds = Get-Credential
    }

    If (!$ArrayName) {
        $ArrayName = $EndPoint
    }

    "==================================================================================" | Out-File -FilePath $OutFile -Append
    "FlashArray Configuration Export for: $($ArrayName)" | Out-File -FilePath $OutFile -Append
    "Date: $($GetDate)" | Out-File -FilePath $OutFile -Append
    "==================================================================================`n" | Out-File -FilePath $OutFile -Append
    $InvokeCommand_pureconfig_list_object = "pureconfig list --object"
    $InvokeCommand_pureconfig_list_system = "pureconfig list --system"
    Write-Host "Retrieving FlashArray OBJECT configuration export (host-pod-volume-hgroup-connection)..."
    "FlashArray OBJECT configuration export (host-pod-volume-hgroup-connection)..." | Out-File -FilePath $OutFile -Append
    " " | Out-File -FilePath $OutFile -Append
    New-PfaCLICommand -EndPoint $EndPoint -Credentials $Creds -CommandText $InvokeCommand_pureconfig_list_object | Out-File -FilePath $OutFile -Append
    Write-Host "Retrieving FlashArray SYSTEM configuration export (array-network-alert-support)..."
    "FlashArray SYSTEM configuration export (array-network-alert-support):" | Out-File -FilePath $OutFile -Append
    " " | Out-File -FilePath $OutFile -Append
    New-PfaCLICommand -EndPoint $EndPoint -Credentials $Creds -CommandText $InvokeCommand_pureconfig_list_system | Out-File -FilePath $OutFile -Append
    Write-Host "FlashArray configuration file located in $Outfile." -ForegroundColor Green
}
#endregion

#region Get-FlashArrayHierarchy
Function Get-FlashArrayHierarchy() {
    <#
    .SYNOPSIS
    Displays array hierarchy in relation to hosts and/or volumes.
    .DESCRIPTION
    This cmdlet will display the hierarchy from a FlashArray of hosts and volumes. The output is to the console in text.
    .PARAMETER EndPoint
    Required. FQDN or IP address of the FlashArray.
    .INPUTS
    None
    .OUTPUTS
    FlashArray host and/or volume hierarchy.
    .EXAMPLE
    Get-FlashArrayHierarchy -EndPoint myArray

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint
    )

    Get-Sdk1Module

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    $Initiators = Get-PfaHosts -Array $FlashArray
    $Volumes = Get-PfaVolumes -Array $FlashArray
    $1GB = 1024 * 1024 * 1024
    Write-Host ""
    Write-Host "Please indicate if you would like to see the hierarchy by host." -ForegroundColor Cyan
    Write-Host "This process will take a couple minutes, but is useful to find disconnected hosts or hosts with no replication group." -ForegroundColor Cyan
    Write-Host "Otherwise, the hierarchy will be shown at the volume level." -ForegroundColor Cyan
    Write-Host ""
    $ByHost = Read-Host -Prompt "Do you want to view hierarchy by individual hosts? (Y/N)"

    Write-Host ""
    Write-Host "================================================================"
    Write-Host "                    $EndPoint Hierarchy"
    Write-Host "================================================================"
    #If else statement to control hierarchy displayed by host or by volume
    If ($ByHost -eq "Y" -or $ByHost -eq "y") {

        #Start at host level
        ForEach ($Initiator in $Initiators) {
            Write-Host "  [H] $($Initiator.name)"
            $Volumes = Get-PfaHostVolumeConnections -Array $FlashArray -Name $Initiator.name
            If (!$Volumes) {
                Write-Host ' [No volumes connected]' -ForegroundColor Yellow
            }
            Else {

                #Start at volume level
                ForEach ($Volume in $Volumes) {

                    #Reset variables
                    $Snapshots = Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $Volume.vol
                    $SnapshotDetails = Get-PfaSnapshotSpaceMetrics -Array $FlashArray -name $Volume.vol
                    $SpaceConsumed = 0

                    #Change value for snapshot count threshold
                    If ($Snapshots.Count -eq 0) {
                        Write-Host " [V]$($Volume.vol)" -ForegroundColor Yellow
                        Write-Host " There are no associated snapshots with this volume." -ForegroundColor Red
                    }
                    Else {
                        Write-Host " [V]$($Volume.vol)" -ForegroundColor Green
                    }

                    #Space consumed computation for each volume
                    ForEach ($SnapshotDetail in $SnapshotDetails) {
                        $SpaceConsumed = $SpaceConsumed + $SnapshotDetail.total
                    }

                    #Change value for snapshot count threshold
                    ForEach ($Snapshot in $Snapshots) {
                        If ($Snapshots.Count -gt 1) {
                            Write-Host " [S] $($Snapshot.name)" -ForegroundColor Yellow
                        }
                        Else {
                            Write-Host " [S] $($Snapshot.name)" -ForegroundColor Green
                        }
                    }

                    #Display space consumed if snapshot count exceeds threshold
                    If ($Snapshots.Count -gt 1) {
                        Write-Host  " There are $($Snapshots.Count) snapshots associated with this volume consuming a total of $([math]::Round($SpaceConsumed/$1GB,2)) GB on the array."
                    }
                }
            }
        }
    }
    #If user does not want hierarchy at host level
    Else {

        #Start volume level
        ForEach ($Volume in $Volumes) {

            #Reset variables
            $Snapshots = Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $Volume.name
            $SnapshotDetails = Get-PfaSnapshotSpaceMetrics -Array $FlashArray -name $Volume.name
            $SpaceConsumed = 0

            #Change value for snapshot count threshold
            If ($Snapshots.Count -eq 0) {
                Write-Host " [V]$($Volume.name)" -ForegroundColor Yellow
                Write-Host " There are no associated snapshots with this volume." -ForegroundColor Red
            }
            Else {
                Write-Host " [V]$($Volume.name)" -ForegroundColor Green
            }

            #Space Consumed computation for each volume
            ForEach ($SnapshotDetail in $SnapshotDetails) {
                $SpaceConsumed = $SpaceConsumed + $SnapshotDetail.total
            }

            #Change value for snapshot count threshold
            ForEach ($Snapshot in $Snapshots) {
                If ($Snapshots.Count -gt 1) {
                    Write-Host " [S] $($Snapshot.name)" -ForegroundColor Yellow
                }
                Else {
                    Write-Host " [S] $($Snapshot.name)" -ForegroundColor Green
                }
            }

            #Display space consumed if snapshot count threshold is exceeded
            If ($Snapshots.Count -gt 1) {
                Write-Host  "There are $($Snapshots.Count) snapshots associated with this volume consuming a total of $([math]::Round($SpaceConsumed/$1GB,2)) GB on the array."
            }
        }
    }
}
#endregion

#region New-FlashArrayCapacityReport
function New-FlashArrayCapacityReport() {
    <#
    .SYNOPSIS
    Create a formatted report that contains FlashArray Capacity Information
    .DESCRIPTION
    This cmdlet will retrieve volume and snapshot capacity information from the FlashArray and output it to a formatted report.
    .PARAMETER EndPoint
    Required. FQDN or IP address of FlashArray.
    .PARAMETER OutFile
    Optional. Full folder path for output report. Default is the current %TEMP% folder.
    .PARAMETER HTMLFileName
    Optional. File name of output report. Default is Array_Capacity_Report.html.
    .PARAMETER VolumeFilter
    Optional. Specific volumes to filter output on. Wildcards are accepted. By default, this is "*" (all).
    .INPUTS
    None
    .OUTPUTS
    Formatted HTML report containing retrieved data and specified options.
    .EXAMPLE
    New-FlashArrayCapacityReport -EndPoint myArray

    Creates a capacity report named myArray_Capacity_Report.html in the current folder.

    .EXAMPLE
    New-FlashArrayCapacityReport -EndPoint myArray -OutFile C:\temp -HTMLFileName MyArrayReport.html -VolumeFilter 'Volume1*'.

    Creates a capacity report c:\temp\myArrayReport.html that includes volumes that contain the name 'Volume1*'.

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)][ValidateNotNullOrEmpty()][string] $EndPoint,
        [Parameter(Mandatory = $False)][string] $OutFile = "$env:Temp",
        [Parameter(Mandatory = $False)][string] $HTMLFileName = "Array_Capacity_Report.html",
        [Parameter(Mandatory = $False)][string] $VolumeFilter = "*"
    )

    # define variables
    $ReportDateTime = Get-Date -Format d
    $metadata = [PSCustomObject]@{
        ReportDate = Get-Date -Format g
        Source = $env:COMPUTERNAME
        ScriptPath = $($myInvocation.mycommand).path
        ScriptVersion = "2.0.0.0"
        CreatedBy = "$env:USERNAME"
    }

    Get-Sdk1Module

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    # populate variables
    $FlashArraySpaceMetrics = Get-PfaArraySpaceMetrics -Array $FlashArray
    $FlashArrayConfig = Get-PfaArrayAttributes -Array $FlashArray
    $FlashArraySnapshots = Get-PfaAllVolumeSnapshots -Array $FlashArray

    $sysCapacity = Convert-Size -ConvertFrom Bytes -ConvertTo TB $FlashArraySpaceMetrics.capacity -Precision 2
    $sysSnapshotSpace = Convert-Size -ConvertFrom Bytes -ConvertTo MB $FlashArraySpaceMetrics.snapshots -Precision 4
    $sysVolumeSpace = Convert-Size -ConvertFrom Bytes -ConvertTo GB $FlashArraySpaceMetrics.volumes -Precision 2
    $sysDRR = [system.Math]::Round($FlashArraySpaceMetrics.data_reduction, 1)
    $sysSpace = Convert-Size -ConvertFrom Bytes -ConvertTo GB $FlashArraySpaceMetrics.total -Precision 2
    $sysSharedSpace = Convert-Size -ConvertFrom Bytes -ConvertTo GB $FlashArraySpaceMetrics.shared_space -Precision 0
    $sysTP = Convert-Size -ConvertFrom Bytes -ConvertTo GB $FlashArraySpaceMetrics.thin_provisioning -Precision 2
    if ([system.Math]::Round($FlashArraySpaceMetrics.total_reduction, 1) -gt 100) {
        $sysTotalDRR = ">100:1"
    }
    else {
        $sysTotalDRR = ([system.Math]::Round($FlashArraySpaceMetrics.total_reduction, 1)).toString() + ":1"
    }

    # zero out varables
    $volumeInfo = $null
    $provisioned = 0

    $volumes = Get-PfaVolumes -Array $FlashArray | Where-Object { $_.name -like $VolumeFilter }
    $volumeInfo += "<th>Volume Name</th><th>Volume Size (GB)</th><th>Connection</th><th><center>Protected</center></th><th>DR</th><th>SS</th><th>TP</th><th>WS (GB)</th>"

    ForEach ($volume in $volumes) {
        $printVol = $volume.name
        $volSize = ($volume.size) / 1GB
        $provisioned = (Convert-Size -ConvertFrom GB -ConvertTo TB $volSize -Precision 4) + $provisioned
        $dr = Get-PfaVolumeSpaceMetrics -Array $FlashArray -VolumeName $volume.name
        $datardx = "{0:N2}" -f $dr.data_reduction
        $dataTP = "{0:N3}" -f $dr.thin_provisioning
        $WrittenSpace = "{0:N2}" -f (((1 - $dr.thin_provisioning) * $dr.total) / 1024 / 1024 / 1024)
        if ($dr.shared_space) {
            $dataSS = "{0:N2}" -f $dr.shared_space
        }
        else {
            $dataSS = "None"
        }

        # Does the volume have any snapshots?
        if (!(Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $volume.name)) {
            $protected = "No"
        }
        else {
            $protected = "Yes"
        }

        if (!(Get-PfaVolumeHostConnections -Array $FlashArray -VolumeName $volume.name).host) {
            if (!(Get-PfaVolumeHostGroupConnections -Array $FlashArray -VolumeName $volume.name).hgroup) {
                $hostconnname = "Not Connected"
            }
            else {
                if (((Get-PfaVolumeHostGroupConnections -Array $FlashArray -VolumeName $volume.name).hgroup).Count -gt 1) {
                    $hostconnname = (Get-PfaVolumeHostGroupConnections -Array $FlashArray -VolumeName $volume.name).hgroup[0]
                }
                else {
                    $hostconnname = (Get-PfaVolumeHostGroupConnections -Array $FlashArray -VolumeName $volume.name).hgroup
                }
            }
        }
        else {
            $hostconnname = (Get-PfaVolumeHostConnections -Array $FlashArray -VolumeName $volume.name).host
        }
        $volumeInfo += "<tr><td>$("{0:N0}" -f $printVol)</td> <td>$("{0:N0}" -f $volSize)</td><td>$($hostconnname)</td><td><center>$protected</center></td><td>$($datardx)</td><td>$($dataSS)</td><td>$($dataTP)</td><td>$($WrittenSpace)</td></tr>"
    }

    $snapshotInfo = $null
    $snapshots = Get-PfaVolumes -Array $FlashArray | Where-Object { $_.name -like $VolumeFilter }
    $snapshotInfo += "<th>Snapshot Name</th><th>Snapshot Size (GB)</th>"
    ForEach ($snapshot in $snapshots) {
        $printSnapshot = $snapshot.name
        $snapshotSize = ($snapshot.size) / 1GB
        $snapshotInfo += "<tr><td>$("{0:N0}" -f $printSnapshot)</td> <td>$("{0:N0}" -f $snapshotSize)</td></tr>"
    }

    # Create HTML/CSS report format
    #region HTML
    $HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
<!--
$(($metadata | Out-String).Trim())
-->
<title>Pure Storage FlashArray Capacity Report</title>
<style type="text/css">
<!--
body {
    font-family: Proxima Nova, Verdana, Geneva, Arial, Helvetica, Sans-Serif;
}
table {
	border-collapse: collapse;
	border: none;
	border-right: 1px grey solid;
    border-top: 1px grey solid;
    border-bottom: 1px grey solid;
    border-left: 1px grey solid;
	text-align: left;
	font: 12pt Proxima Nova, Verdana, Geneva, Arial, Helvetica, Sans-Serif;
	color: black;
	margin-bottom: 10px;
    margin-left: 20px;
}

table td {
    vertical-align: top;
	font-size: 12px;
	padding-left: 2px;
	padding-right: 2px;
	text-align: left;
	border-right: 1px grey solid;
    border-top: 1px grey solid;
    border-bottom: 1px grey solid;
    border-left: 1px grey solid;
}

table th {
	font-size: 14px;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
	text-align: left;
	border-right: 1px grey solid;
    border-top: 1px grey solid;
    border-bottom: 1px grey solid;
    border-left: 1px grey solid;
}

h2 {
    clear: both;
    font-size: 130%;
}

h3 {
	clear: both;
	font-size: 115%;
	margin-left: 20px;
	margin-top: 30px;
}

protected {
    font-weight: bold;
	text-align: left;
}

p {
    margin-left: 20px;
    font-size: 12px;
}

hr {
    background-color: #FE5000
}

table.list {
	font-size: 12px;
	font-weight: normal;
	padding-left: 2px;
	padding-right: 2px;
	text-align: right;
    border-style: solid;
    width: 700px;
}

table.list td:nth-child(1) {
	font-weight: bold;
	border-right: 1px grey solid;
	text-align: left;
}

table.list td:nth-child(2) {
    padding-left: 2px;
	border-right: 1px grey solid;
	text-align: left;
}

table tr:nth-child(even) td:nth-child(even) {
    background: #F8D2CD;
}

table tr:nth-child(odd) td:nth-child(odd) {
    background: #FCEAE8;
}

table tr:nth-child(even) td:nth-child(odd) {
    background: #F8D2CD;
}

table tr:nth-child(odd) td:nth-child(even) {
    background: #FCEAE8;
}

div.column {
    width: 400px;
    float: left;
}

div.first {
    padding-right: 2px;
    border-right: 1px grey solid;
}

div.second {
    margin-left: 30px;
}

div.relative {
    position: relative;
}

div.absolute {
    position: absolute;
    top: 80px;
    left: 350px;
    width: 200px;
    height: 75px;
	font-size: 14px;
	font-weight: bold;
}

div.time {
    position: absolute;
    top: 25px;
    left: 0px;
    width: 600px;
    height: 75px;
	font-size: 12px;
	font-weight: normal;
}

img {
    max-width: 500px;
    max-height: 88px;
}
-->
</style>
</head>
<body>
"@

$CurrentSystemHTML = @"
<img class="relative" src="data:image/png;base64,
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
AElFTkSuQmCC">

<div id="report">
<p><div class='absolute'>FlashArray Capacity Report<br><div class='time'>$(Get-Date -Format U)</div></div>
<h3>FlashArray Information</h3>
<table class="list">
<tr>
<td>FlashArray Name</td>
<td>$($FlashArrayConfig.array_name)</td>
</tr>
<tr>
<td>Purity Version</td>
<td>$($FlashArrayConfig.version)</td>
</tr>
<tr>
<td>Revision</td>
<td>$($FlashArrayConfig.revision)</td>
</tr>
<tr>
<td>ID</td>
<td>$($FlashArrayConfig.id)</td>
</tr>
<tr>
<td>Total Volumes Space</td>
<td>$sysVolumeSpace G</td>
</tr>
<tr>
<td>Total Snapshots Space</td>
<td>$("{0:N2}" -f $sysSnapshotSpace) M</td>
</tr>
<tr>
<td>Shared Space</td>
<td>$("{0:N2}" -f $sysSharedSpace) G</td>
</tr>
<tr>
<td>Used Space</td>
<td>$("{0:N2}" -f $sysSpace) G</td>
</tr>
<tr>
<td>System Capacity</td>
<td>$("{0:N2}" -f $sysCapacity) T</td>
</tr>
<tr>
<td>System Data Reduction</td>
<td>$("{0:N2}" -f $sysDRR):1</td>
</tr>
<tr>
<td>Total Data Reduction</td>
<td>$($sysTotalDRR)</td>
</tr>
<tr>
<td>Provisioned Space</td>
<td> $("{0:N2}" -f $provisioned) T</td>
</tr>
</table>
<h3>Volume Information</h3>
<p>Volumes(s), Sizes (GB) and Data Reduction columes include DR (Data Reduction), SS (Shared Space)<br>and TP (Thin Provisioning) and WS (Written Space) for $($FlashArrayConfig.array_name) listed below.</p>
<table class="list">$volumeInfo</table>
<h3>FlashRecover SnapShot Information</h3>
<p>Snapshot(s) and Sizes (GB) for $($FlashArrayConfig.array_name) listed below.</p>
<table class="list">$snapshotInfo</table>
<br></br>
"@
    # Add the current System HTML Report into the final HTML Report body
    $HTMLMiddle += $CurrentSystemHTML

    # Assemble the closing HTML for our report.
    $HTMLEnd = @"
</div>
<hr noshade size=3 width="100%">
$ReportDateTime
</body>
</html>
"@
    # Assemble the final report from all our HTML sections
    $HTMLmessage = $HTMLHeader + $HTMLMiddle + $HTMLEnd
    # Save the report out to a file in the current path$
    $HTMLmessage | Out-File ($OutFile + "\" + $HTMLFileName)

    Write-Host " "
    Write-Host "The report file is located in the $OutFile folder." -ForegroundColor Green
}
#endregion

#### END FLASHARRAY FUNCTIONS

#### WINDOWS FUNCTIONS

#region Test-WindowsBestPractices
function Test-WindowsBestPractices() {
    <#
    .SYNOPSIS
    Cmdlet used to retrieve hosts information, test and optionally configure MPIO (FC) and/or iSCSI settings in a Windows OS against FlashArray Best Practices.
    .DESCRIPTION
    This cmdlet will retrieve the curretn host infromation, and iterate through several tests around MPIO (FC) and iSCSI OS settings and hardware, indicate whether they are adhearing to Pure Storage FlashArray Best Practices, and offer to alter the settings if applicable.
    All tests can be bypassed with a negative user response when prompted, or simply by using Ctrl-C to break the process.
    .PARAMETER EnableIscsiTests
    Optional. If this parameter is present, the cmdlet will run tests for iSCSI settings.
    .PARAMETER OutFile
    Optional. Specify the full filepath (ex. c:\mylog.log) for logging. If not specified, the default file of %TMP%\Test-WindowsBestPractices.log will be used.
    .INPUTS
    Optional parameter for iSCSI testing.
    .OUTPUTS
    Output status and best practice options for every test.
    .EXAMPLE
    Test-WindowsBestPractices

    Run the cmdlet against the local machine running the MPIO tests and the log is located in the %TMP%\Test-WindowsBestPractices.log file.

    .EXAMPLE
    Test-WindowsZBestPractices -EnableIscsiTests -OutFile "c:\temp\mylog.log"

    Run the cmdlet against the local machine, run the additional iSCSI tests, and create the log file at c:\temp\mylog.log.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)] [string] $OutFile = "$env:Temp\Test-WindowsBestPractices.log",
        [Switch]$EnableIscsiTests
    )
    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter()][ValidateNotNullOrEmpty()][string]$Message,
            [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("Information", "Passed", "Warning", "Failed")][string]$Severity = "Information"
        )
        [pscustomobject]@{
            Time     = (Get-Date -f g)
            Message  = $Message
            Severity = $Severity
        } | Out-File -FilePath $OutFile -Append
    }
    Write-Log -Message 'Pure Storage FlashArray Windows Server Best Practices Analyzer v2.0.0.0' -Severity Information
    Clear-Host
    Write-Host '             __________________________'
    Write-Host '            /++++++++++++++++++++++++++\'
    Write-Host '           /++++++++++++++++++++++++++++\'
    Write-Host '          /++++++++++++++++++++++++++++++\'
    Write-Host '         /++++++++++++++++++++++++++++++++\'
    Write-Host '        /++++++++++++++++++++++++++++++++++\'
    Write-Host '       /++++++++++++/----------\++++++++++++\'
    Write-Host '      /++++++++++++/            \++++++++++++\'
    Write-Host '     /++++++++++++/              \++++++++++++\'
    Write-Host '    /++++++++++++/                \++++++++++++\'
    Write-Host '   /++++++++++++/                  \++++++++++++\'
    Write-Host '   \++++++++++++\                  /++++++++++++/'
    Write-Host '    \++++++++++++\                /++++++++++++/'
    Write-Host '     \++++++++++++\              /++++++++++++/'
    Write-Host '      \++++++++++++\            /++++++++++++/'
    Write-Host '       \++++++++++++\          /++++++++++++/'
    Write-Host '        \++++++++++++\'
    Write-Host '         \++++++++++++\'
    Write-Host '          \++++++++++++\'
    Write-Host '           \++++++++++++\'
    Write-Host '            \------------\'
    Write-Host 'Pure Storage FlashArray Windows Server Best Practices Analyzer v2.0.0.0'
    Write-Host '------------------------------------------------------------------------'
    Write-Host ''
    Write-Host ''
    Write-Host '========================================='
    Write-Host 'Host Information'
    Write-Host '========================================='
    $compinfo = Get-SilComputer | Out-String -Stream
    $compinfo | Out-File -FilePath $OutFile -Append
    $compinfo
    Write-Log -Message "Successfully retrieved computer properties. Continuing..." -Severity Information
    Write-Host ''
    Write-Host '========================================='
    Write-Host 'Multipath-IO Verificaton'
    Write-Host '========================================='
    # Multipath-IO
    if ((Get-WindowsFeature -Name 'Multipath-IO').InstallState -eq 'Available') {
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
        Write-Host ": Multipath-IO Windows feature is not installed. This feature can be installed by this cmdlet, but a reboot of the server will be required, and the you must re-run the cmdlet again."
        Write-Log -Message 'Multipath-IO Windows feature is not installed.' -Severity Failed
        $resp = Read-Host "Would you like to install this feature? (***Reboot Required) Y/N"
        if ($resp.ToUpper() -eq 'Y') {
            Add-WindowsFeature -Name Multipath-IO
            Write-Log -Message 'Multipath-IO Windows feature was installed per user request. Continuing...' -Severity Passed
        }
        else {
            Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
            Write-Host ": You have chosen not to install the Multipath-IO feature via this cmdlet. Please add this feature manually and re-run this cmdlet."
            Write-Log -Message 'Multipath-IO Windows feature not installed per user request. Exiting.' -Severity Warning
            exit
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": The Multipath-IO feature is installed."
        Write-Log -Message 'Multipath-IO Windows feature is installed. Continuing...' -Severity Passed
    }

    Write-Host ''
    Write-Host '========================================='
    Write-Host 'Multipath-IO Hardware Verification'
    Write-Host '========================================='
    $MPIOHardware = Get-MPIOAvailableHW
    $MPIOHardware | Out-File -FilePath $OutFile -Append
    Write-Log -Message "Successfully retrieved MPIO Hardware. Continuing..." -Severity Information
    $MPIOHardware
    $DSMs = Get-MPIOAvailableHW
    ForEach ($DSM in $DSMs) {
        if ((($DSM).VendorId.Trim()) -eq 'PURE' -and (($DSM).ProductId.Trim()) -eq 'FlashArray') {
            Write-Host "PASSED" -ForegroundColor Green -NoNewline
            Write-Host ": Microsoft Device Specific Module (MSDSM) is configured for $($DSM.ProductID).`n`r"
            Write-Log -Message "Microsoft Device Specific Module (MSDSM) is configured for $($DSM.ProductID).`n`r. Continuing..." -Severity Passed
        }
        else {
            Write-Host "FAILED" -ForegroundColor Red -NoNewline
            Write-Host ": Microsoft Device Specific Module (MSDSM) is not configured for $($DSM.ProductID).`n`r"
            Write-Log -Message "Microsoft Device Specific Module (MSDSM) is not configured for $($DSM.ProductID).`n`r. Continuing anyway..." -Severity Failed
        }
    }

    Write-Host ''
    Write-Host '-----------------------------------------'
    Write-Host 'Current MPIO Settings'
    Write-Host '-----------------------------------------'

    $MPIOSettings = $null
    $MPIOSetting = $null
    Write-Log -Message "Retrieving MPIO settings. Continuing..." -Severity Information
    $MPIOSettings = Get-MPIOSetting | Out-String -Stream
    $MPIOSettings = $MPIOSettings.Replace(" ", "")
    $MPIOSettings | Out-Null
    $MPIOSettings | Out-File -FilePath $OutFile -Append
    Write-Log -Message "Successfully retrieved MPIO Settings. Continuing..." -Severity Information

    ForEach ($MPIOSetting in $MPIOSettings) {
        $MPIOSetting.Split(':')[0]
        $MPIOSetting.Split(':')[1]
        switch ( $($MPIOSetting.Split(':')[0])) {
            'PathVerificationState' { $PathVerificationState = $($MPIOSetting.Split(':')[1]) }
            'PDORemovePeriod' { $PDORemovePeriod = $($MPIOSetting.Split(':')[1]) }
            'UseCustomPathRecoveryTime' { $UseCustomPathRecoveryTime = $($MPIOSetting.Split(':')[1]) }
            'CustomPathRecoveryTime' { $CustomPathRecoveryTime = $($MPIOSetting.Split(':')[1]) }
            'DiskTimeoutValue' { $DiskTimeOutValue = $($MPIOSetting.Split(':')[1]) }
        }
    }

    Write-Host ''
    Write-Host '========================================='
    Write-Host 'MPIO Settings Verification'
    Write-Host '========================================='

    # PathVerificationState
    if ($PathVerificationState -eq 'Disabled') {
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
        Write-Host ": PathVerificationState is $($PathVerificationState)."
        Write-Log -Message "PathVerificationState is $($PathVerificationState)." -Severity Failed
        $resp = Read-Host "REQUIRED ACTION: Set the PathVerificationState to Enabled? Y/N"
        if ($resp.ToUpper() -eq 'Y') {
            Set-MPIOSetting -NewPathVerificationState Enabled
            Write-Log -Message "PathVerificationState is now $($PathVerificationState) per to user request." -Severity Information
        }
        else {
            Write-Host "WARNING" -ForegroundColor Yellow
            Write-Host ": Not changing the PathVerificationState to Enabled could cause unexpected path recovery issues."
            Write-Log -Message "PathVerificationState $($PathVerificationState) was not altered due to user request." -Severity Warning
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": PathVerificationState has a value of Enabled. No action required."
        Write-Log -Message "PathVerificationState has a value of Enabled. No action required." -Severity Passed
    }

    # PDORemovalPeriod
    # Need to test for Azure VM. If Azure VM, use PDORemovalPeriod=120. If not Azure VM, use PDORemovePeriod=30.
    try {
        $StatusCode = wget -TimeoutSec 3 -Headers @{"Metadata" = "true" } -Uri "http://169.254.169.254/metadata/instance/compute?api-version=2021-01-01" | ForEach-Object { $_.StatusCode }
    }
    catch {}
    if ($StatusCode -eq '200') {
        $b = Invoke-RestMethod -Headers @{"Metadata" = "true" } -Method GET -Proxy $Null -Uri "http://169.254.169.254/metadata/instance/compute?api-version=2021-01-01&format=json" | Select-Object azEnvironment
        if ($b.azEnvironment -like "Azure*") {
            Write-Log -Message "This is an Azure Vitual Machine. The PDORemovalPeriod is set differently than others." -Severity Information
            if ($PDORemovePeriod -ne '120') {
                Write-Host "FAILED" -ForegroundColor Red -NoNewline
                Write-Host ": PDORemovePeriod for this Azure VM is set to $($PDORemovePeriod)."
                Write-Log -Message "PDORemovePeriod for this Azure VM is set to $($PDORemovePeriod)." -Severity Failed
                $resp = Read-Host "REQUIRED ACTION: Set the PDORemovePeriod to a value of 120? Y/N"
                if ($resp.ToUpper() -eq 'Y') {
                    Set-MPIOSetting -NewPDORemovePeriod 120
                    Write-Log -Message ": PDORemovePeriod for this Azure VM is set to $($PDORemovePeriod) per user request." -Severity Information
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": Not changing the PDORemovePeriod to 120 for an Azure VM could cause unexpected path recovery issues."
                    Write-Log -Message "Not changing the PDORemovePeriod to 120 for an Azure VM could cause unexpected path recovery issues." -Severity Warning
                }
                else {
                    Write-Host "PASSED" -ForegroundColor Green -NoNewline
                    Write-Host ": PDORemovePeriod is set to a value of 120 for this Azure VM. No action required."
                    Write-Log -Message "PDORemovePeriod is set to a value of 120 for this Azure VM. No action required." -Severity Passed
                }
            }
        }
        else {
            if ($PDORemovePeriod -ne '30') {
                Write-Host "FAILED" -ForegroundColor Red -NoNewline
                Write-Host ": PDORemovePeriod is set to $($PDORemovePeriod)."
                Write-Log -Message "PDORemovePeriod is set to $($PDORemovePeriod)." -Severity Failed
                $resp = Read-Host "REQUIRED ACTION: Set the PDORemovePeriod to a value of 30? Y/N"
                if ($resp.ToUpper() -eq 'Y') {
                    Set-MPIOSetting -NewPDORemovePeriod 30
                    Write-Log -Message "PDORemovePeriod is set to $($PDORemovePeriod) per user request." -Severity Information
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": Not changing the PDORemovePeriod to 30 could cause unexpected path recovery issues."
                    Write-Log -Message "Not changing the PDORemovePeriod to 30 could cause unexpected path recovery issues." -Severity Warning
                }
                else {
                    Write-Host "PASSED" -ForegroundColor Green -NoNewline
                    Write-Host ": PDORemovePeriod is set to a value of 30. No action required."
                    Write-Log -Message "PDORemovePeriod is set to a value of 30. No action required." -Severity Passed
                }
            }
        }
    }
    # PathRecoveryTime
    if ($UseCustomPathRecoveryTime -eq 'Disabled') {
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
        Write-Host ": UseCustomPathRecoveryTime is set to $($UseCustomPathRecoveryTime)."
        Write-Log -Message "UseCustomPathRecoveryTime is set to $($UseCustomPathRecoveryTime)." -Severity Failed
        $resp = Read-Host "REQUIRED ACTION: Set the UseCustomPathRecoveryTime to Enabled? Y/N"
        if ($resp.ToUpper() -eq 'Y') {
            Set-MPIOSetting -CustomPathRecovery Enabled
            Write-Log -Message "UseCustomPathRecoveryTime is set to $($UseCustomPathRecoveryTime) per user request." -Severity Information
        }
        else {
            Write-Host "WARNING" -ForegroundColor Yellow
            Write-Host ": Not changing the UseCustomPathRecoveryTime to Enabled could cause unexpected path recovery issues."
            Write-Log -Message "Not changing the UseCustomPathRecoveryTime to Enabled could cause unexpected path recovery issues." -Severity Warning
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": UseCustomPathRecoveryTime is set to Enabled. No action required."
        Write-Log -Message "UseCustomPathRecoveryTime is set to Enabled. No action required." -Severity Passed
    }

    if ($CustomPathRecoveryTime -ne '20') {
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
        Write-Host ": CustomPathRecoveryTime is set to $($CustomPathRecoveryTime)."
        Write-Log -Message "CustomPathRecoveryTime is set to $($CustomPathRecoveryTime)." -Severity Failed
        $resp = Read-Host "REQUIRED ACTION: Set the CustomPathRecoveryTime to a value of 20? Y/N"
        if ($resp.ToUpper() -eq 'Y') {
            Set-MPIOSetting -NewPathRecoveryInterval 20
            Write-Log -Message "CustomPathRecoveryTime is set to $($UseCustomPathRecoveryTime) per user request." -Severity Information
        }
        else {
            Write-Host "WARNING" -ForegroundColor Yellow
            Write-Host ": Not changing the CustomPathRecoveryTime to a value of 20 could cause unexpected path recovery issues."
            Write-Log -Message "Not changing the CustomPathRecoveryTime to a value of 20 could cause unexpected path recovery issues." -Severity Warning
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": CustomPathRecoveryTime is set to $($CustomPathRecoveryTime). No action required."
        Write-Log -Message "CustomPathRecoveryTime is set to $($CustomPathRecoveryTime). No action required." -Severity Passed
    }

    # DiskTimeOutValue
    if ($DiskTimeOutValue -ne '60') {
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
        Write-Host ": DiskTimeOutValue is set to $($DiskTimeOutValue)."
        Write-Log -Message "DiskTimeOutValue is set to $($DiskTimeOutValue)." -Severity Failed
        $resp = Read-Host "REQUIRED ACTION: Set the DiskTimeOutValue to a value of 60? Y/N"
        if ($resp.ToUpper() -eq 'Y') {
            Set-MPIOSetting -NewDiskTimeout 60
            Write-Log -Message "DiskTimeOutValue is set to $($DiskTimeOutValue) per user request." -Severity Information
        }
        else {
            Write-Host "WARNING" -ForegroundColor Yellow
            Write-Host ": Not changing the DiskTimeOutValue to a value of 60 could cause unexpected path recovery issues."
            Write-Log -Message "Not changing the DiskTimeOutValue to a value of 60 could cause unexpected path recovery issues." -Severity Warning
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": DiskTimeOutValue is set to $($DiskTimeOutValue). No action required."
        Write-Log -Message "DiskTimeOutValue is set to $($DiskTimeOutValue). No action required." -Severity Passed
    }

    Write-Host ''
    Write-Host '========================================='
    Write-Host 'TRIM/UNMAP Verification'
    Write-Host '========================================='
    # DisableDeleteNotification
    $DisableDeleteNotification = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\FileSystem' -Name 'DisableDeleteNotification')
    if ($DisableDeleteNotification.DisableDeleteNotification -eq 0) {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": Delete Notification is Enabled"
        Write-Log -Message "Delete Notification is Enabled. No action required." -Severity Passed
    }
    else {
        Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
        Write-Host ": Delete Notification is Disabled. Pure Storage Best Practice is to enable delete notifications."
        Write-Log -Message "Delete Notification is Disabled. Pure Storage Best Practice is to enable delete notifications." -Severity Warning
    }
    Write-Host " "
    Write-Host "MPIO settings tests complete. Continuing..." -ForegroundColor Green
    Write-Log -Message "MPIO settings tests complete. Continuing..." -Severity Information
    # iSCSI tests
    if ($EnableIscsiTests) {
        Write-Host ''
        Write-Host '========================================='
        Write-Host 'iSCSI Settings Verification'
        Write-Host '========================================='
        Write-Log -Message "iSCSI testing enabled. Continuing..." -Severity Information
        $AdapterNames = @()
        Write-Host "All available adapters: "
        Write-Host " "
        $adapters = Get-NetAdapter | Sort-Object Name | Format-Table -Property "Name", "InterfaceDescription", "MacAddress", "Status"
        $adapters | Out-File -FilePath $OutFile -Append
        $adapters
        Write-Host " "
        $AdapterNames = Read-Host "Please enter all iSCSI adapter names to be tested. Use a comma to seperate the names - ie. NIC1,NIC2,NIC3"
        $AdapterNames = $AdapterNames.Split(',')
        Write-Host " "
        Write-Host "Adapter names being configured: "
        $AdapterNames
        Write-Host "==============================="
        foreach ($adapter in $AdapterNames) {
            $adapterGuid = (Get-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword "NetCfgInstanceId" -AllProperties).RegistryValue
            $RegKeyPath = "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$adapterGuid\"
            $TAFRegKey = "TcpAckFrequency"
            $TNDRegKey = "TcpNoDelay"
            ## TcpAckFrequency
            if ((Get-ItemProperty $RegkeyPath).$TAFRegKey -eq "1") {
                Write-Host "PASSED" -ForegroundColor Green -NoNewline
                Write-Host ": TcpAckFrequency is set to disabled (1). No action required."
                Write-Log -Message "TcpAckFrequency is set to disabled (1). No action required." -Severity Passed
            }
            if (-not (Get-ItemProperty $RegkeyPath $TAFRegKey -ErrorAction SilentlyContinue)) {
                Write-Host "FAILED" -ForegroundColor Red -NoNewline
                Write-Host ": TcpAckFrequency key does not exist."
                Write-Log -Message "TcpAckFrequency key does not exist." -Severity Failed
                Write-Host "REQUIRED ACTION: Set the TcpAckFrequency registry value to 1 for $adapter ?" -NoNewline
                $resp = Read-Host -Prompt "Y/N?"
                if ($resp.ToUpper() -eq 'Y') {
                    Write-Host "Creating Registry key and setting to disabled..."
                    New-ItemProperty -Path $RegKeyPath -Name 'TcpAckFrequency' -Value '1' -PropertyType DWORD -Force -ErrorAction SilentlyContinue
                    Write-Log -Message "Creating Registry key and setting to disabled per user request." -Severity Information
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": TcpAckFrequency registry key exists but is enabled. Changing to disabled."
                    Set-ItemProperty -Path $RegKeyPath -Name 'TcpAckFrequency' -Value '1' -Type DWORD -Force -ErrorAction SilentlyContinue
                    Write-Log -Message "TcpAckFrequency registry key exists but is enabled. Changing to disabled." -Severity Warning
                }
            }
            if ($resp.ToUpper() -eq 'N') {
                Write-Host "ABORTED" -ForegroundColor Yellow -NoNewline
                Write-Host ": Registry key not created or altered by request of user."
                Write-Log -Message "Registry key not created or altered by request of user." -Severity Warning

            }
            ## TcpNoDelay
            if ((Get-ItemProperty $RegkeyPath).$TNDRegKey -eq "1") {
                Write-Host "PASSED" -ForegroundColor Green -NoNewline
                Write-Host ": TcpNoDelay (Nagle) is set to disabled (1). No action required."
                Write-Log -Message "TcpNoDelay (Nagle) is set to disabled (1). No action required." -Severity Passed
            }
            if (-not (Get-ItemProperty $RegkeyPath $TNDRegKey -ErrorAction SilentlyContinue)) {
                Write-Host "REQUIRED ACTION: Set the TcpNodelay (Nagle) registry value to 1 for $adapter ?" -NoNewline
                $resp = Read-Host -Prompt "Y/N?"
                if ($resp.ToUpper() -eq 'Y') {
                    Write-Host "TcpNoDelay registry key does not exist. Creating..."
                    New-ItemProperty -Path $RegKeyPath -Name 'TcpNoDelay' -Value '1' -PropertyType DWORD -Force -ErrorAction SilentlyContinue
                    Write-Log -Message "TcpNoDelay registry key does not exist. Creating per user request." -Severity Information
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": TcpNoDelay registry key exists. Setting value to 1."
                    Set-ItemProperty -Path $RegKeyPath -Name 'TcpNoDelay' -Value '1' -Type DWORD -Force -ErrorAction SilentlyContinue
                    Write-Log -Message "TcpNoDelay registry key exists. Setting value to 1." -Severity Warning
                }
            }
            if ($resp.ToUpper() -eq 'N') {
                Write-Host "ABORTED" -ForegroundColor Yellow -NoNewline
                Write-Host ": TcpNoDelay registry key not created or altered by request of user."
                Write-Log -Message "TcpNoDelay registry key not created or altered by request of user." -Severity Warning
            }
        }
    }
    else {
        Write-host " "
        Write-Host "The -EnableIscsiTests parameter not present. No iSCSI tests will be run." -ForegroundColor Yellow
        Write-Host " "
        Write-Log -Message "The -EnableIscsiTests parameter not present. No iSCSI tests will be run." -Severity Information
    }
    Write-Host ''
    Write-Host "The Test-WindowsBestPractices cmdlet has completed. The log file has been created for reference." -ForegroundColor Green
    Write-Host ''
    Write-Log -Message "The Test-WindowsBestPractices cmdlet has completed." -Severity Information
}
#endregion

#region Set-WindowsPowerScheme
function Set-WindowsPowerScheme() {
    <#
    .SYNOPSIS
    Cmdlet to set the Power scheme for the Windows OS to High Performance.
    .DESCRIPTION
    Cmdlet to set the Power scheme for the Windows OS to High Performance.
    .PARAMETER ComputerName
    Optional. The computer name to run the cmdlet against. It defaults to the local computer name.
    .INPUTS
    None
    .OUTPUTS
    Current power scheme and optional confirmation to alter the setting in the Windows registry.
    .EXAMPLE
    Set-WindowsPowerScheme

    Retrieves the current Power Scheme setting, and if not set to High Performance, asks for confirmation to set it.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)] [string] $ComputerName = "$env:COMPUTERNAME"
    )
    $PowerScheme = Get-WmiObject -Class WIN32_PowerPlan -Namespace 'root\cimv2\power' -ComputerName $ComputerName -Filter "isActive='true'"
    if ($PowerScheme.ElementName -ne "High performance") {
        Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
        Write-Host ": Computer Power Scheme is not set to High Performance. Pure Storage best practice is to set this power plan as default."
        Write-Host " "
        Write-Host "REQUIRED ACTION: Set the Power Plan to High Performance?"
        $resp = Read-Host -Prompt "Y/N?"
        if ($resp.ToUpper() -eq 'Y') {
            $planId = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            powercfg -setactive "$planId"
        }
    }
    else {
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
        Write-Host ": Computer Power Scheme is already set to High Performance. Exiting."
    }
}
#endregion

#region Get-QuickFixEngineering
function Get-QuickFixEngineering() {
    <#
    .SYNOPSIS
    Retrieves all the Windows OS QFE patches applied.
    .DESCRIPTION
    Retrieves all the Windows OS QFE patches applied.
    .INPUTS
    None
    .OUTPUTS
    Outputs a listing of QFE patches applied.
    .EXAMPLE
    Get-QuickFixEngineering
    #>
    Get-WmiObject -Class Win32_QuickFixEngineering | Select-Object -Property Description, HotFixID, InstalledOn | Format-Table -Wrap
}
#endregion

#region Get-HostBusAdapter
function Get-HostBusAdapter() {
    <#
    .SYNOPSIS
    Retrieves host Bus Adapater (HBA) information.
    .DESCRIPTION
    Retrieves host Bus Adapater (HBA) information for the host.
    .PARAMETER ComputerName
    Optional. The computer name to run the cmdlet against. It defaults to the local computer name.
    .INPUTS
    Computer name is optional.
    .OUTPUTS
    Host Bus Adapter information.
    .EXAMPLE
    Get-HostBusAdapter -ComputerName myComputer
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)] [string] $ComputerName  = "$env:COMPUTERNAME"
    )

    try {
        $port = Get-WmiObject -Class MSFC_FibrePortHBAAttributes -Namespace 'root\WMI' -ComputerName $ComputerName
        $hbas = Get-WmiObject -Class MSFC_FCAdapterHBAAttributes -Namespace 'root\WMI' -ComputerName $ComputerName
        $hbaProp = $hbas | Get-Member -MemberType Property, AliasProperty | Select-Object -ExpandProperty name | Where-Object { $_ -notlike '__*' }
        $hbas = $hbas | Select-Object -ExpandProperty $hbaProp
        $hbas | ForEach-Object { $_.NodeWWN = ((($_.NodeWWN) | ForEach-Object { '{0:x2}' -f $_ }) -join ':').ToUpper() }

        ForEach ($hba in $hbas) {
            Add-Member -MemberType NoteProperty -InputObject $hba -Name FabricName -Value (($port | Where-Object { $_.instancename -eq $hba.instancename }).attributes | Select-Object @{ Name = 'Fabric Name'; Expression = { (($_.fabricname | ForEach-Object { '{0:x2}' -f $_ }) -join ':').ToUpper() } }, @{ Name = 'Port WWN'; Expression = { (($_.PortWWN | ForEach-Object { '{0:x2}' -f $_ }) -join ':').ToUpper() } }) -PassThru
        }
    }
    catch {

    }
}
#endregion

#region Register-HostVolumes
function Register-HostVolumes() {
    <#
    .SYNOPSIS
    Sets Pure FlashArray connected disks to online.
    .DESCRIPTION
    This cmdlet will set any FlashArray volumes (disks) to online in Windows using the diskpart command.
    .PARAMETER ComputerName
    Optional. The computer name to run the cmdlet against. It defaults to the local computer name.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Register-HostVolumes -ComputerName myComputer

    Sets all FlashArray disks for myComputer to online.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)] [string]$ComputerName = "$env:COMPUTERNAME"
    )

    $cmds = "`"RESCAN`""
    $scriptblock = [string]::Join(',', $cmds)
    $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
    $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $diskpart
    $disks = Invoke-Command -ComputerName $ComputerName { Get-Disk }
#    $i = 0
    ForEach ($disk in $disks) {
        If ($disk.FriendlyName -like 'PURE FlashArray*') {
            If ($disk.OperationalStatus -ne 1) {
                $disknumber = $disk.Number
                $cmds = "`"SELECT DISK $disknumber`"",
                "`"ATTRIBUTES DISK CLEAR READONLY`"",
                "`"ONLINE DISK`""
                $scriptblock = [string]::Join(',', $cmds)
                $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
                $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $diskpart -ErrorAction Stop
            }
        }
    }
}
#endregion

#region Unregister-HostVolumes
function Unregister-HostVolumes() {
    <#
    .SYNOPSIS
    Sets Pure FlashArray connected disks to offline.
    .DESCRIPTION
    This cmdlet will set any FlashArray volumes (disks) to offline in Windows using the diskpart command.
    .PARAMETER ComputerName
    Optional. The computer name to run the cmdlet against. It defaults to the local computer name.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Unregister-HostVolumes -ComputerName myComputer

    Offlines all FlashArray disks from myComputer.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)] [string]$Computername = "$env:COMPUTERNAME"
    )

    $cmds = "`"RESCAN`""
    $scriptblock = [string]::Join(',', $cmds)
    $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
    $result = Invoke-Command -ComputerName $Computername -ScriptBlock $diskpart
    $disks = Invoke-Command -ComputerName $Computername { Get-Disk }
    ForEach ($disk in $disks) {
        If ($disk.FriendlyName -like 'PURE FlashArray*') {
            If ($disk.OperationalStatus -ne 1) {
                $disknumber = $disk.Number
                $cmds = "`"SELECT DISK $disknumber`"",
                "`"OFFLINE DISK`""
                $scriptblock = [string]::Join(',', $cmds)
                $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
                $result = Invoke-Command -ComputerName $Computername -ScriptBlock $diskpart -ErrorAction Stop
            }
        }
    }
}
#endregion

#region Get-MPIODiskLBPolicy
function Get-MPIODiskLBPolicy() {
    <#
    .SYNOPSIS
    Retrieves the current MPIO Load Balancing policy for Pure FlashArray disk(s).
    .DESCRIPTION
    This cmdlet will retrieve the current MPIO Load Balancing policy for connected Pure FlashArrays disk(s) using the mpclaim.exe utlity.
    .PARAMETER DiskID
    Optional. If specified, retrieves only the policy for the that disk ID. Otherwise, returns all disks.
    DiskID is the 'Number' identifier of the disk from the cmdlet 'Get-Disk'.
    .PARAMETER OutFile
    Optional. File name to output results to. Defaults to %TEMP%\MPIOLBPolicy.txt
    .INPUTS
    None
    .OUTPUTS
    Outputs $OutFile contents.
    .EXAMPLE
    Get-MPIODiskLBPolicy -DiskID 1

    Returns the current MPIO LB policy for disk ID 1.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)][string]$DiskId,
        [Parameter(Mandatory = $False)][string]$OutFile = "$env:Temp\output.txt"
    )
    if ($DiskId) {
        Write-Host "Getting MPIO Load Balancing Policy for" + $DiskId
        Start-Process "$env:WINDIR\system32\mpclaim.exe" -ArgumentList "-s -d $DiskId" -NoNewWindow -Wait -RedirectStandardOutput $OutFile
    }
    else {
        Write-Host "Getting MPIO Load Balancing Policy for all MPIO disks."
        Start-Process "$env:WINDIR\system32\mpclaim.exe" -ArgumentList "-s -d" -NoNewWindow -Wait -RedirectStandardOutput $OutFile
        Get-Content -Path $OutFile
    }
}
#endregion

#region Set-MPIODiskLBPolicy
function Set-MPIODiskLBPolicy() {
    <#
    .SYNOPSIS
    Sets the MPIO Load Balancing policy for FlashArray disks.
    .DESCRIPTION
    This cmdlet will set the MPIO Load Balancing policy for all connected Pure FlashArrays disks to the desired setting using the mpclaim.exe utlity.
    The default Windows OS setting is RR.
    .PARAMETER Policy
    Required. No default. The Policy type must be specified by the letter acronym for the policy name (ex. "RR" for Round Robin). Available options are:
        LQD = Least Queue Depth
        RR = Round Robin
        FO = Fail Over Only
        RRWS = Round Robin with Subset
        WP = Weighted Paths
        LB = Least Blocks
        clear = clears current policy and sets to Windows OS default of RR
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Set-MPIODiskLBPolicy -Policy LQD

    Sets the MPIO load balancing policy for all Pure disks to Least Queue Depth.

    .EXAMPLE
    Set-MPIODiskLBPolicy -Policy clear

    Clears the current MPIO policy for all Pure disks and sets to the default of RR.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)][ValidateSet('LQD','RR','clear','FO','RRWS','WP','LB',IgnoreCase = $true)][string]$Policy
    )
    If ($Policy -eq "LQD") { $pn = "4" }
    elseif ($Policy -eq "RR") { $pn = "2" }
    elseif ($Policy -like "clear") { $pn = "0" }
    elseif ($Policy -eq "FO") { $pn = "1" }
    elseif ($Policy -eq "RRWS") { $pn = "3" }
    elseif ($Policy -eq "WP") { $pn = "5" }
    elseif ($Policy -eq "LB") { $pn = "6" }
    else {
        Write-Host "Required policy type parameter of LQD, RR, FO, RRWS, WP LB, or clear not supplied. Exiting."
        break
    }
    Write-Host "Setting MPIO Load Balancing Policy to" + $pn + " for all Pure FlashArray disks."
    $puredisks = Get-PhysicalDisk | Where-Object FriendlyName -Match "PURE"
    foreach ($puredisk in $puredisks) {
        $subtract = "0"    # set to 0 if numbers match in the test above.
        $id = (($ssd.DeviceId) - $subtract).ToString()
        Start-Process "%WINDIR%\system32\mpclaim.exe" -ArgumentList "-l -d $id $pn" -NoNewWindow -Wait -RedirectStandardOutput $env:tmp\output.txt
        Get-Content -Path $env:tmp\output.txt
    }
}
#endregion

#region Get-VolumeShadowCopy
function Get-VolumeShadowCopy() {
    <#
    .SYNOPSIS
    Retrieves the volume shadow copy informaion using the Diskhadow command.
    .DESCRIPTION

    .PARAMETER ExposeAs
    Required. Drive letter, share, or mount point to expose the shadow copy.
    .PARAMETER ScriptName
    Optional. Script text file name created to pass to the Diskshadow command. defaults to 'PUREVSS-SNAP'.
    .PARAMETER ShadowCopyAlias
    Required. Name of the shadow copy alias.
    .PARAMETER MetadataFile
    Required. Full filename for the metadata .cab file. It must exist in the current working folder.
    .PARAMETER VerboseMode
    Optional. "On" or "Off". If set to 'off', verbose mode for the Diskshadow command is disabled. Default is 'On'.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Get-VolumeShadowCopy -MetadataFile myFile.cab -ShadowCopyAlias MyAlias -ExposeAs MyShadowCopy

    Exposes the MyAias shadow copy as drive latter G: using the myFie.cab metadata file.

    .NOTES
    See https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/diskshadow for more information on the Diskshadow utility.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)][string]$ScriptName = "PUREVSS-SNAP",
        [Parameter(Mandatory = $True)][string]$MetadataFile,
        [Parameter(Mandatory = $True)][string]$ShadowCopyAlias,
        [Parameter(Mandatory = $True)][string]$ExposeAs,
        [ValidateSet("On", "Off")][string]$VerboseMode = "On"
    )
    $dsh = "./$ScriptName.PFA"
    "SET VERBOSE $VerboseMode",
    'RESET',
    "LOAD METADATA $MetadataFile.cab",
    'IMPORT',
    "EXPOSE %$ShadowCopyAlias% $ExposeAs",
    'EXIT' | Set-Content $dsh
    DISKSHADOW /s $dsh
    Remove-Item $dsh
}
#endregion

#region New-VolumeShadowCopy
function New-VolumeShadowCopy() {
    <#
    .SYNOPSIS
    Creates a new volume shadow copy using Diskshadow.
    .DESCRIPTION
    This cmdlet will create a new volume shadow copy using the Diskshadow command, passing the variables specified.
    .PARAMETER Volume
    Required.
    .PARAMETER Scriptname
    Optional. Script text file name created to pass to the Diskshadow command. Pre-defined as 'PUREVSS-SNAP'.
    .PARAMETER ShadowCopyAlias
    Required. Name of the shadow copy alias.
    .PARAMETER VerboseMode
    Optional. "On" or "Off". If set to 'off', verbose mode for the Diskshadow command is disabled. Default is 'on'.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    New-VolumeShadowCopy -Volume Volume01 -ShadowCopyAlias MyAlias

    Adds a new volume shadow copy of Volume01 using Diskshadow with an alias of 'MyAlias'.

    .NOTES
    See https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/diskshadow for more information on the Diskshadow utility.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string[]]$Volume,
        [Parameter(Mandatory = $False)][string]$ScriptName = "PUREVSS-SNAP",
        [Parameter(Mandatory = $True)][string]$ShadowCopyAlias,
        [ValidateSet("On", "Off")][string]$VerboseMode = "On"
    )

    $dsh = "./$ScriptName.PFA"

    foreach ($Vol in $Volume) {
        "ADD VOLUME $Vol ALIAS $ShadowCopyAlias PROVIDER {781c006a-5829-4a25-81e3-d5e43bd005ab}"
    }
    'RESET',
    'SET CONTEXT PERSISTENT',
    'SET OPTION TRANSPORTABLE',
    "SET VERBOSE $VerboseMode",
    'BEGIN BACKUP',
    "ADD VOLUME $Volume ALIAS $ShadowCopyAlias PROVIDER {781c006a-5829-4a25-81e3-d5e43bd005ab}",
    'CREATE',
    'END BACKUP' | Set-Content $dsh
    DISKSHADOW /s $dsh
    Remove-Item $dsh
}
#endregion

#region Update-DriveInformation
function Update-DriveInformation() {
    <#
    .SYNOPSIS
    Updates drive letters and assigns a label.
    .DESCRIPTION
    Thsi cmdlet will update the current drive letter to the new drive letter, and assign a new drive label if specified.
    .PARAMETER NewDriveLetter
    Required. Drive lettwre without the colon.
    .PARAMETER CurrentDriveLetter
    Required. Drive lettwre without the colon.
    .PARAMETER NewDriveLabel
    Optional. Drive label text. Defaults to "NewDrive".
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    Update-DriveInformation -NewDriveLetter S -CurrentDriveLetter M

    Updates the drive letter from M: to S: and labels S: to NewDrive.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string]$NewDriveLetter,
        [Parameter(Mandatory = $True)][string]$CurrentDriveLetter,
        [Parameter(Mandatory = $False)][string]$NewDriveLabel = "NewDrive"
        )

    $Drive = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq "$($CurrentDriveLetter):" }
    if (!($NewDriveLabel)) {
        Set-WmiInstance -Input $Drive -Arguments @{ DriveLetter = "$($NewDriveLetter):" } | Out-Null
    }
    else {
        Set-WmiInstance -Input $Drive -Arguments @{ DriveLetter = "$($NewDriveLetter):"; Label = "$($NewDriveLabel)" } | Out-Null
    }
}
#endregion

#region Set-TlsVersions
function Set-TlsVersions() {
    <#
    .SYNOPSIS
    Sets the TLS Version in the local registry.
    .DESCRIPTION
    This cmdlet disables TLS version 1.0 and enables TLS Versions 1.1, 1.2, and 1.3 in the local registry. It will prompt for creating a backup of the registry before execution for recovery purposes.
    .INPUTS
    None
    .OUTPUTS
    Backup of the registry before the changes are implemented.
    .EXAMPLE
    Set-TlsVersions

    Prompts for creation of a registry backup, disables TLS version 1.0, and enables TLS versions 1.1, 1.2, and 1.3.
    #>
    [CmdletBinding()]
    Param (
    )
    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
    Write-Host ": This cmdlet will change TLS protocol settings in the Registry. It is ***highly*** recommended to make a backup of your registry before executing this cmdlet."
    Write-Host " "
    Write-Host ": Would you like to create a complete registry backup file before proceeding?"
    $resp = Read-Host -Prompt "Y/N?"
    if ($resp.ToUpper() -eq 'Y') {
        Write-Host "A registry backup is being generated. It will be located in your $env:temp folder as registrybackup.reg."
        cmd /c regedit /E $env:temp\registrybackup.reg
        if (!(Test-Path $env:temp\registrybackup.reg -PathType leaf)) {
            Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
            Write-Host ": Registry backup failed. Please proceed with caution or manually backup the registry."
        }
        else {
            Write-Host "SUCCESS" -ForegroundColor Green -NoNewline
            Write-Host ": The registry backup was successful."
        }
    }
    Write-Host " "
    Write-Host "REQUIRED ACTION: Disable TLS 1.0 and enable TLS versions 1.1, 1.2, and 1.3 on this computer?"
    $resp = Read-Host -Prompt "Y/N?"
    if ($resp.ToUpper() -eq 'Y') {
        # Disable TLS v1.0
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Force | Out-Null
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Name 'Enabled' -Value '0' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Name 'DisabledByDefault' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Name 'Enabled' -Value '0' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Name 'DisabledByDefault' -Value '1' –PropertyType 'DWORD' | Out-Null
        Write-Host "SUCCESS" -ForegroundColor Green -NoNewline
        Write-Host ": TLS version 1.0 disabled."
        # Enable TLS v1.1
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Force | Out-Null
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        Write-Host "SUCCESS" -ForegroundColor Green -NoNewline
        Write-Host ": TLS version 1.1 enabled."
        # Enable TLS v1.2
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        Write-Host "SUCCESS" -ForegroundColor Green -NoNewline
        Write-Host ": TLS version 1.2 enabled."
        # Enable TLS v1.3
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Force | Out-Null
        New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Name 'Enabled' -Value '1' –PropertyType 'DWORD' | Out-Null
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Name 'DisabledByDefault' -Value '0' –PropertyType 'DWORD' | Out-Null
        Write-Host "SUCCESS" -ForegroundColor Green -NoNewline
        Write-Host ": TLS version 1.3 enabled."
    }
    else {
        Write-Host "CANCELLED" -ForegroundColor Yellow -NoNewline
        Write-Host ": Action cancelled at user request."
    }
}
#endregion

### DBA TOOLKIT FUNCTIONS
### migrated from the Pure Storage DBA Toolkit module in July 2021

#region Invoke-PfaDbRefresh
function Invoke-PfaDbRefresh {
<#
.SYNOPSIS
A PowerShell function to refresh one or more SQL Server databases (the destination) from either a snapshot or database.

.DESCRIPTION
A PowerShell function to refresh one or more SQL Server databases either from:
- a snapshot specified by its name
- a snapshot picked from a list associated with the volume the source database resides on
- a source database directly

This  function will detect and repair orpaned users in refreshed databases and optionally
apply data masking, based on either:
- the dynamic data masking functionality available in SQL Server version 2016 onwards,
- static data masking built into dbatools from version 0.9.725, refer to https://dbatools.io/mask/

.PARAMETER RefreshDatabase
Required. The name of the database to refresh, note that it is assumed that source and target database(s) are named the same.

.PARAMETER RefreshSource
Required. If the RefreshFromSnapshot flag is specified, this parameter takes the name of a snapshot, otherwise this takes the
name of the source SQL Server instance.

.PARAMETER DestSqlInstance
Required. This can be one or multiple SQL Server instance(s) that host the database(s) to be refreshed, in the case that the
function is invoked  to refresh databases across more than one instance, the list of target instances should be
spedcified as an array of strings, otherwise a single string representing the target instance will suffice.

.PARAMETER Endpoint
Required. The IP address representing the FlashArray that the volumes for the source and refresh target databases reside on.

.PARAMETER PollJobInterval
Optional. Interval at which background job status is poll, if this is ommited polling will not take place. Note that this parameter
is not applicable is the PromptForSnapshot switch is specified.

.PARAMETER PromptForSnapshot
Optional. This is an optional flag that if specified will result in a list of snapshots being displayed for the database volume on
the FlashArray that the user can select one from. Despite the source of the refresh operation being an existing snapshot,
 the source instance still has to be specified by the RefreshSource parameter in order that the function can determine
which FlashArray volume to list existing snapshots for.

.PARAMETER RefreshFromSnapshot
Optional. This is an optional flag that if specified causes the function to expect the RefreshSource parameter to be supplied with
the name of an existing snapshot.

.PARAMETER NoPsRemoting
Optional. The commands that off and online the windows volumes associated with the refresh target databases will use Invoke-Command
with powershell remoting unless this flag is specified. Certain tools that can invoke PowerShell, Ansible for example, do
not permit double-hop authentication unless CredSSP authentication is used. For security purposes Kerberos is recommended
over CredSSP, however this does not support double-hop authentication, in which case this flag should be specified.

.PARAMETER ApplyDataMasks
Optional. Specifying this optional masks will cause data masks to be applied , as per the dynamic data masking feature first
introduced with SQL Server 2016, this results in this function invoking the Invoke-DynamicDataMasking function to be invoked.
For documentation on Invoke-DynamicDataMasking, use the command Get-Help Invoke-DynamicDataMasking -Detailed.

.PARAMETER ForceDestDbOffline
Optional. Specifying this switch will cause refresh target databases for be forced offline via WITH ROLLBACK IMMEDIATE.

.PARAMETER StaticDataMaskFile
Optional. If this parameter is present and has a file path associated with it, the data masking available in version 0.9.725 of the
dbatools module onwards will be applied  to the refreshed database. The use of this is contigent on the data mask file
being created and populated in the first place as per this blog post: https://dbatools.io/mask/ .

.EXAMPLE
Invoke-PfaDbRefresh -RefreshDatabase tpch-no-compression -RefreshSource z-sql2016-devops-prd -DestSqlInstance z-sql2016-devops-tst -Endpoint 10.225.112.10 `
-PromptForSnapshot

Refresh a single database from a snapshot selected from a list of snapshots associated with the volume specified by the RefreshSource parameter.
.EXAMPLE
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -RefreshDatabase tpch-no-compression -RefreshSource z-sql2016-devops-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-PromptForSnapshot

Refresh multiple databases from a snapshot selected from a list of snapshots associated with the volume specified by the RefreshSource parameter.
.EXAMPLE
Invoke-PfaDbRefresh -RefreshDatabase tpch-no-compression -RefreshSource source-snap -DestSqlInstance z-sql2016-devops-tst -Endpoint 10.225.112.10 `
-RefreshFromSnapshot

Refresh a single database using the snapshot specified by the RefreshSource parameter.
.EXAMPLE
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -RefreshDatabase tpch-no-compression -RefreshSource source-snap -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-RefreshFromSnapshot

Refresh multiple databases using the snapshot specified by the RefreshSource parameter.
.EXAMPLE
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance z-sql2016-devops-tst -Endpoint 10.225.112.10

Refresh a single database from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource.
.EXAMPLE
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `

Refresh multiple databases from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource.
.EXAMPLE
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-ApplyDataMasks

Refresh multiple databases from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource.
.EXAMPLE
$StaticDataMaskFile = "D:\apps\datamasks\z-sql-prd.tpch-no-compression.tables.json"
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-StaticDataMaskFile $StaticDataMaskFile

Refresh multiple databases from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource and apply SQL Server dynamic data masking to each database.
.EXAMPLE
$StaticDataMaskFile = "D:\apps\datamasks\z-sql-prd.tpch-no-compression.tables.json"
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-ForceDestDbOffline -StaticDataMaskFile $StaticDataMaskFile

Refresh multiple databases from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource and apply SQL Server dynamic data masking to each database.
All databases to be refreshed are forced offline prior to their underlying FlashArray volumes being overwritten.
.EXAMPLE
$StaticDataMaskFile = "D:\apps\datamasks\z-sql-prd.tpch-no-compression.tables.json"
$Targets = @("z-sql2016-devops-tst", "z-sql2016-devops-dev")
Invoke-PfaDbRefresh -$RefreshDatabase tpch-no-compression -RefreshSource z-sql-prd -DestSqlInstance $Targets -Endpoint 10.225.112.10 `
-PollJobInterval 10 -ForceDestDbOffline -StaticDataMaskFile $StaticDataMaskFile

Refresh multiple databases from the database specified by the SourceDatabase parameter residing on the instance specified by RefreshSource and apply SQL Server dynamic data masking to each database.
All databases to be refreshed are forced offline prior to their underlying FlashArray volumes being overwritten. Poll the status of the refresh jobs once every 10 seconds.
.NOTES
FlashArray Credentials - A global variable $Creds may be used as described in the release notes for this module. If neither is specified, the module will prompt for credentials.

Known Restrictions
------------------
1. This function does not work for databases associated with failover cluster instances.
2. This function cannot be used to seed secondary replicas in availability groups using databases in the primary replica.
3. The function assumes that all database files and the transaction log reside on a single FlashArray volume.

Note that it has dependencies on the dbatools and PureStoragePowerShellSDK modules which are installed by this module.
#>
    param(
        [parameter(mandatory = $true)][string]$RefreshDatabase,
        [parameter(mandatory = $true)][string]$RefreshSource,
        [parameter(mandatory = $true)][string[]]$DestSqlInstances,
        [parameter(mandatory = $true)][string]$Endpoint,
        [parameter(mandatory = $false)][int]$PollJobInterval,
        [parameter(mandatory = $false)][switch]$PromptForSnapshot,
        [parameter(mandatory = $false)][switch]$RefreshFromSnapshot,
        [parameter(mandatory = $false)][switch]$NoPsRemoting,
        [parameter(mandatory = $false)][switch]$ApplyDataMasks,
        [parameter(mandatory = $false)][switch]$ForceDestDbOffline,
        [parameter(mandatory = $false)][string]$StaticDataMaskFile
    )

    $StartMs = Get-Date

    Get-Sdk1Module
    Get-DbaToolsModule

    if ( $PromptForSnapshot.IsPresent.Equals($false) -And $RefreshFromSnapshot.IsPresent.Equals($false) ) {
        try {
            $SourceDb = Get-DbaDatabase -SqlInstance $RefreshSource -Database $RefreshDatabase
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to source database $RefreshSource.$Database with: $ExceptionMessage"
            Return
        }

        Write-Color -Text "Source SQL Server instance: ", $RefreshSource, " - CONNECTED" -Color Yellow, Green, Green

        try {
            $SourceServer = (Connect-DbaInstance -SqlInstance $RefreshSource).ComputerNamePhysicalNetBIOS
        }
        catch {
            Write-Error "Failed to determine target server name with: $ExceptionMessage"
        }
    }
    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    Write-Color -Text "FlashArray endpoint       : ", "CONNECTED" -ForegroundColor Yellow, Green

    $GetDbDisk = { param ( $Db )
        $DbDisk = Get-Partition -DriveLetter $Db.PrimaryFilePath.Split(':')[0] | Get-Disk
        return $DbDisk
    }

    $Snapshots = $(Get-PfaAllVolumeSnapshots $FlashArray)
    $FilteredSnapshots = $Snapshots.where( { ([string]$_.Source) -eq $RefreshSource })

    if ( $PromptForSnapshot.IsPresent ) {
        Write-Host ' '
        for ($i = 0; $i -lt $FilteredSnapshots.Count; $i++) {
            Write-Host 'Snapshot ' $i.ToString()
            $FilteredSnapshots[$i]
        }

        $SnapshotId = Read-Host -Prompt 'Enter the number of the snapshot to be used for the database refresh'
    }
    elseif ( $RefreshFromSnapshot.IsPresent.Equals( $false ) ) {
        try {
            if ( $NoPsRemoting.IsPresent ) {
                $SourceDisk = Invoke-Command -ScriptBlock $GetDbDisk -ArgumentList $SourceDb
            }
            else {
                $SourceDisk = Invoke-Command -ComputerName $SourceServer -ScriptBlock $GetDbDisk -ArgumentList $SourceDb
            }
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to determine source disk with: $ExceptionMessage"
            Return
        }

        try {
            $SourceVolume = Get-PfaVolumes -Array $FlashArray | Where-Object { $_.serial -eq $SourceDisk.SerialNumber } | Select-Object name
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to determine source volume with: $ExceptionMessage"
            Return
        }
    }

    if ( $PromptForSnapshot.IsPresent ) {
        Foreach ($DestSqlInstance in $DestSqlInstances) {
            Invoke-DbRefresh -DestSqlInstance $DestSqlInstance `
                -RefreshDatabase $RefreshDatabase `
                -Endpoint     $Endpoint     `
                -Creds  $Creds  `
                -SourceVolume    $FilteredSnapshots[$SnapshotId]
        }
    }
    else {
        $JobNumber = 1
        Foreach ($DestSqlInstance in $DestSqlInstances) {
            $JobName = "DbRefresh" + $JobNumber
            Write-Colour -Text "Refresh background job    : ", $JobName, " - ", "PROCESSING" -Color Yellow, Green, Green, Green
            If ( $RefreshFromSnapshot.IsPresent ) {
                Start-Job -Name $JobName -ScriptBlock $Function:DbRefresh -ArgumentList $DestSqlInstance   , `
                    $RefreshDatabase   , `
                    $Endpoint       , `
                    $Creds    , `
                    $RefreshSource     , `
                    $StaticDataMaskFile, `
                    $ForceDestDbOffline.IsPresent, `
                    $NoPsRemoting.IsPresent      , `
                    $PromptForSnapshot.IsPresent , `
                    $ApplyDataMasks.IsPresent | Out-Null
            }
            else {
                Start-Job -Name $JobName -ScriptBlock $Function:DbRefresh -ArgumentList $DestSqlInstance   , `
                    $RefreshDatabase   , `
                    $Endpoint       , `
                    $Creds    , `
                    $SourceVolume.Name , `
                    $StaticDataMaskFile, `
                    $ForceDestDbOffline.IsPresent, `
                    $NoPsRemoting.IsPresent      , `
                    $PromptForSnapshot.IsPresent , `
                    $ApplyDataMasks.IsPresent | Out-Null
            }
            $JobNumber += 1;
        }

        While (Get-Job -State Running | Where-Object { $_.Name.Contains("DbRefresh") }) {
            if ($PSBoundParameters.ContainsKey('PollJobInterval')) {
                Get-Job -State Running | Where-Object { $_.Name.Contains("DbRefresh") } | Receive-Job
                Start-Sleep -Seconds $PollJobInterval
            }
            else {
                Start-Sleep -Seconds 1
            }
        }

        Write-Colour -Text "Refresh background jobs   : ", "COMPLETED" -Color Yellow, Green

        foreach ($job in (Get-Job | Where-Object { $_.Name.Contains("DbRefresh") })) {
            $result = Receive-Job $job
            Write-Host $result
        }

        Remove-Job -State Completed
    }

    $EndMs = Get-Date
    Write-Host " "
    Write-Host "-------------------------------------------------------"         -ForegroundColor Green
    Write-Host " "
    Write-Host "D A T A B A S E      R E F R E S H      C O M P L E T E"         -ForegroundColor Green
    Write-Host " "
    Write-Host "              Duration (s) = " ($EndMs - $StartMs).TotalSeconds  -ForegroundColor White
    Write-Host " "
    Write-Host "-------------------------------------------------------"         -ForegroundColor Green
}
function DbRefresh {
    param(
        [parameter(mandatory = $true)][string]$DestSqlInstance,
        [parameter(mandatory = $true)][string]$RefreshDatabase,
        [parameter(mandatory = $true)][string]$Endpoint,
        [parameter(mandatory = $true)][string]$SourceVolume,
        [parameter(mandatory = $false)][string]$StaticDataMaskFile,
        [parameter(mandatory = $false)][bool]$ForceDestDbOffline,
        [parameter(mandatory = $false)][bool]$NoPsRemoting,
        [parameter(mandatory = $false)][bool]$PromptForSnapshot,
        [parameter(mandatory = $false)][bool]$ApplyDataMasks
    )

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    try {
        $DestDb = Get-DbaDatabase -SqlInstance $DestSqlInstance -Database $RefreshDatabase
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to connect to destination database $DestSqlInstance.$Database with: $ExceptionMessage"
        Return
    }

    Write-Host " "
    Write-Colour -Text "Target SQL Server instance: ", $DestSqlInstance, "- CONNECTED" -ForegroundColor Yellow, Green, Green

    try {
        $TargetServer = (Connect-DbaInstance -SqlInstance $DestSqlInstance).ComputerNamePhysicalNetBIOS
    }
    catch {
        Write-Error "Failed to determine target server name with: $ExceptionMessage"
    }

    Write-Colour -Text "Target SQL Server host    : ", $TargetServer -ForegroundColor Yellow, Green

    $GetDbDisk = { param ( $Db )
        $DbDisk = Get-Partition -DriveLetter $Db.PrimaryFilePath.Split(':')[0] | Get-Disk
        return $DbDisk
    }

    $GetVolumeLabel = { param ( $Db )
        Write-Verbose "Target database drive letter = $Db.PrimaryFilePath.Split(':')[0]"
        $VolumeLabel = $(Get-Volume -DriveLetter $Db.PrimaryFilePath.Split(':')[0]).FileSystemLabel
        Write-Verbose "Target database windows volume label = <$VolumeLabel>"
        return $VolumeLabel
    }

    try {
        if ( $NoPsRemoting ) {
            $DestDisk = Invoke-Command -ScriptBlock $GetDbDisk -ArgumentList $DestDb
            $DestVolumeLabel = Invoke-Command -ScriptBlock $GetVolumeLabel -ArgumentList $DestDb
        }
        else {
            $DestDisk = Invoke-Command -ComputerName $TargetServer -ScriptBlock $GetDbDisk -ArgumentList $DestDb
            $DestVolumeLabel = Invoke-Command -ComputerName $TargetServer -ScriptBlock $GetVolumeLabel -ArgumentList $DestDb
        }
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to determine destination database disk with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target drive letter       : ", $DestDb.PrimaryFilePath.Split(':')[0] -ForegroundColor Yellow, Green

    try {
        $DestVolume = Get-PfaVolumes -Array $FlashArray | Where-Object { $_.serial -eq $DestDisk.SerialNumber } | Select-Object name

        if (!$DestVolume) {
            throw "Failed to determine destination FlashArray volume, check that source and destination volumes are on the SAME array"
        }
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to determine destination FlashArray volume with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target Pfa volume         : ", $DestVolume.name -ForegroundColor Yellow, Green

    $OfflineDestDisk = { param ( $DiskNumber, $Status )
        Set-Disk -Number $DiskNumber -IsOffline $Status
    }

    try {
        if ( $ForceDestDbOffline ) {
            $ForceDatabaseOffline = "ALTER DATABASE [$RefreshDatabase] SET OFFLINE WITH ROLLBACK IMMEDIATE"
            Invoke-DbaQuery -ServerInstance $DestSqlInstance -Database $RefreshDatabase -Query $ForceDatabaseOffline
        }
        else {
            $DestDb.SetOffline()
        }
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to offline database $Database with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target database           : ", "OFFLINE" -ForegroundColor Yellow, Green

    try {
        if ( $NoPsRemoting ) {
            Invoke-Command -ScriptBlock $OfflineDestDisk -ArgumentList $DestDisk.Number, $True
        }
        else {
            Invoke-Command -ComputerName $TargetServer -ScriptBlock $OfflineDestDisk -ArgumentList $DestDisk.Number, $True
        }
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to offline disk with : $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target windows disk       : ", "OFFLINE" -ForegroundColor Yellow, Green

    $StartCopyVolMs = Get-Date

    try {
        Write-Colour -Text "Source Pfa volume         : ", $SourceVolume -ForegroundColor Yellow, Green
        New-PfaVolume -Array $FlashArray -VolumeName $DestVolume.name -Source $SourceVolume -Overwrite
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to refresh test database volume with : $ExceptionMessage"
        Set-Disk -Number $DestDisk.Number -IsOffline $False
        $DestDb.SetOnline()
        Return
    }

    Write-Colour -Text "Volume overwrite          : ", "SUCCESSFUL" -ForegroundColor Yellow, Green
    $EndCopyVolMs = Get-Date
    Write-Colour -Text "Overwrite duration (ms)   : ", ($EndCopyVolMs - $StartCopyVolMs).TotalMilliseconds -Color Yellow, Green

    $SetVolumeLabel = { param ( $Db, $DestVolumeLabel )
        Set-Volume -DriveLetter $Db.PrimaryFilePath.Split(':')[0] -NewFileSystemLabel $DestVolumeLabel
    }

    try {
        if ( $NoPsRemoting ) {
            Invoke-Command -ScriptBlock $OfflineDestDisk -ArgumentList $DestDisk.Number, $False
            Invoke-Command -ScriptBlock $SetVolumeLabel -ArgumentList $DestDb, $DestVolumeLabel
        }
        else {
            Invoke-Command -ComputerName $TargetServer -ScriptBlock $OfflineDestDisk -ArgumentList $DestDisk.Number, $False
            Invoke-Command -ComputerName $TargetServer -ScriptBlock $SetVolumeLabel -ArgumentList $DestDb, $DestVolumeLabel
        }
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to online disk with : $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target windows disk       : ", "ONLINE" -ForegroundColor Yellow, Green

    try {
        $DestDb.SetOnline()
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to online database $Database with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target database           : ", "ONLINE" -ForegroundColor Yellow, Green

    if ( $ApplyDataMasks ) {
        Write-Host "Applying SQL Server dynamic data masks to $RefreshDatabase on SQL Server instance $DestSqlInstance" -ForegroundColor Yellow

        try {
            Invoke-DynamicDataMasking -SqlInstance $DestSqlInstance -Database $RefreshDatabase
            Write-Host "SQL Server dynamic data masking has been applied" -ForegroundColor Yellow
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to apply SQL Server dynamic data masks to $Database on $DestSqlInstance with: $ExceptionMessage"
            Return
        }
    }
    elseif ([System.IO.File]::Exists($StaticDataMaskFile)) {
        Write-Color -Text "Static data mask target   : ", $DestSqlInstance, " - ", $RefreshDatabase -Color Yellow, Green, Green, Green

        try {
            Invoke-StaticDataMasking -SqlInstance $DestSqlInstance -Database $RefreshDatabase -DataMaskFile $StaticDataMaskFile
            Write-Color -Text "Static data masking       : ", "APPLIED" -ForegroundColor Yellow, Green

        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to apply static data masking to $Database on $DestSqlInstance with: $ExceptionMessage"
            Return
        }
    }

    Repair-DbaDbOrphanUser -SqlInstance $DestSqlInstance -Database $RefreshDatabase | Out-Null
    Write-Color -Text "Orphaned users            : ", "REPAIRED" -ForegroundColor Yellow, Green
}
# endregion

#region Invoke-StaticDataMasking
function Invoke-StaticDataMasking {
<#
.SYNOPSIS
A PowerShell function to statically mask data in char, varchar and/or nvarchar columns using a MD5 hashing function.

.DESCRIPTION
This PowerShell function uses as input a JSON file created by calling the New-DbaDbMaskingConfig PowerShell function.
Data in the columns specified in this file which are of the type char, varchar or nvarchar are envrypted using a MD5
hash.

.PARAMETER SqlInstance
Required. The SQL Server instance of the database that static data masking is to be applied to.

.PARAMETER Database
Required. The database that static data masking is to be applied to.

.PARAMETER DataMaskFile
Required. Absolute path to the JSON file generated by invoking New-DbaDbMaskingConfig. The file can be subsequently editted by
hand to suit the data masking requirements of this function's user. Currently, static data masking is only supported for columns with char, varchar, nvarchar, int and bigint data types.

.EXAMPLE
Invoke-StaticDataMasking -SqlInstance  Z-STN-WIN2016-A\DEVOPSDEV -Database tpch-no-compression -DataMaskFile 'C:\Users\devops\Documents\tpch-no-compression.tables.json'

.NOTES
Note that it has dependencies on the dbatools module which are installed with this module.
#>
    param(
        [parameter(mandatory = $true)] [string] $SqlInstance,
        [parameter(mandatory = $true)] [string] $Database,
        [parameter(mandatory = $true)] [string] $DataMaskFile
    )

    Get-DbaToolsModule

    if ($DataMaskFile.ToString().StartsWith('http')) {
        $tables = Invoke-RestMethod -Uri $DataMaskFile
    }
    else {
        # Check if the destination is accessible
        if (-not (Test-Path -Path $DataMaskFile)) {
            Write-Error "Could not find data mask config file $DataMaskFile"
            Return
        }
    }

    # Get all the items that should be processed
    try {
        $tables = Get-Content -Path $DataMaskFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "Could not parse masking config file: $DataMaskFile" -ErrorRecord $_
    }

    foreach ($tabletest in $tables.Tables) {
        if ($Table -and $tabletest.Name -notin $Table) {
            continue
        }

        $ColumnIndex = 0
        $UpdateStatement = ""

        foreach ($columntest in $tabletest.Columns) {
            if ($columntest.ColumnType -in 'varchar', 'char', 'nvarchar') {
                if ($ColumnIndex -eq 0) {
                    $UpdateStatement = 'UPDATE ' + $tabletest.Name + ' SET ' + $columntest.Name + ' = SUBSTRING(CONVERT(VARCHAR, HASHBYTES(' + '''' + 'MD5' + '''' + ', ' + $columntest.Name + '), 1), 1, ' + $columntest.MaxValue + ')'
                }
                else {
                    $UpdateStatement += ', ' + $columntest.Name + ' = SUBSTRING(CONVERT(VARCHAR, HASHBYTES(' + '''' + 'MD5' + '''' + ', ' + $columntest.Name + '), 1), 1, ' + $columntest.MaxValue + ')'
                }
            }
            elseif ($columntest.ColumnType -eq 'int') {
                if ($ColumnIndex -eq 0) {
                    $UpdateStatement = 'UPDATE ' + $tabletest.Name + ' SET ' + $columntest.Name + ' = ABS(CHECKSUM(NEWID())) % 2147483647'
                }
                else {
                    $UpdateStatement += ', ' + $columntest.Name + ' = ABS(CHECKSUM(NEWID())) % 2147483647'
                }
            }
            elseif ($columntest.ColumnType -eq 'bigint') {
                if ($ColumnIndex -eq 0) {
                    $UpdateStatement = 'UPDATE ' + $tabletest.Name + ' SET ' + $columntest.Name + ' = ABS(CHECKSUM(NEWID()))'
                }
                else {
                    $UpdateStatement += ', ' + $columntest.Name + ' = ABS(CHECKSUM(NEWID()))'
                }
            }
            else {
                Write-Error "$columntest.ColumnType is not supported, please remove the column $columntest.Name from the $tabletest.Name table"
                Return
            }
            $ColumnIndex += 1
        }

        Write-Verbose "Statically masking table $tabletest.Name using $UpdateStatement"
        Invoke-DbaQuery -ServerInstance $SqlInstance -Database $Database -Query $UpdateStatement -QueryTimeout 999999
    }
}
#endregion

#region Invoke-DynamicDataMasking
function Invoke-DynamicDataMasking {
    <#
.SYNOPSIS
A PowerShell function to apply data masks to database columns using the SQL Server dynamic data masking feature.

.DESCRIPTION
This function uses the information stored in the extended properties of a database:
sys.extended_properties.name = 'DATAMASK' to obtain the dynamic data masking function to apply
at column level. Columns of the following data type are currently supported:

- int
- bigint
- char
- nchar
- varchar
- nvarchar

Using the c_address column in the tpch customer table as an example, the DATAMASK extended property can be applied
to the column as follows:

exec sp_addextendedproperty
     @name = N'DATAMASK'
    ,@value = N'(FUNCTION = 'partial(0, "XX", 20)''
    ,@level0type = N'Schema', @level0name = 'dbo'
    ,@level1type = N'Table',  @level1name = 'customer'
    ,@level2type = N'Column', @level2name = 'c_address'
GO

.PARAMETER SqlInstance
Required. The SQL Server instance of the database that data masking is to be applied to.

.PARAMETER Database
Required. The database that data masking is to be applied to.

.EXAMPLE
Invoke-DynamicDataMasking -SqlInstance Z-STN-WIN2016-A\DEVOPSDEV -Database tpch-no-compression

.NOTES
Note that it has dependencies on the dbatools and PureStoragePowerShellSDK  modules which are installed as part of this module.
#>
    param(
        [parameter(mandatory = $true)][string] $SqlInstance,
        [parameter(mandatory = $true)][string] $Database
    )

    Get-DbaToolsModule

    $sql = @"
BEGIN
	DECLARE  @sql_statement nvarchar(1024)
	        ,@error_message varchar(1024)

	DECLARE apply_data_masks CURSOR FOR
	SELECT       'ALTER TABLE ' + tb.name + ' ALTER COLUMN ' + c.name +
			   + ' ADD MASKED WITH '
			   + CAST(p.value AS char) + ''')'
	FROM       sys.columns c
	JOIN       sys.types t
	ON         c.user_type_id = t.user_type_id
	LEFT JOIN  sys.index_columns ic
	ON         ic.object_id = c.object_id
	AND        ic.column_id = c.column_id
	LEFT JOIN  sys.indexes i
	ON         ic.object_id = i.object_id
	AND        ic.index_id  = i.index_id
	JOIN       sys.tables tb
	ON         tb.object_id = c.object_id
	JOIN       sys.extended_properties AS p
	ON         p.major_id   = tb.object_id
	AND        p.minor_id   = c.column_id
	AND        p.class      = 1
	WHERE      t.name IN ('int', 'bigint', 'char', 'nchar', 'varchar', 'nvarchar');

	OPEN apply_data_masks
	FETCH NEXT FROM apply_data_masks INTO @sql_statement;

	WHILE @@FETCH_STATUS = 0
	BEGIN
	    PRINT 'Applying data mask: ' + @sql_statement;

		BEGIN TRY
		    EXEC sp_executesql @stmt = @sql_statement
		END TRY
		BEGIN CATCH
		    SELECT @error_message = ERROR_MESSAGE();
			PRINT 'Application of data mask failed with: ' + @error_message;
		END CATCH;

		FETCH NEXT FROM apply_data_masks INTO @sql_statement
	END;

	CLOSE apply_data_masks
	DEALLOCATE apply_data_masks;
END;
"@

    Invoke-DbaSqlQuery -SqlInstance $SqlInstance -Database $Database -Query $sql
}
#endregion

#region New-PfaDbSnapshot
function New-PfaDbSnapshot {
    <#
.SYNOPSIS
A PowerShell function to create a FlashArray snapshot of the volume that a database resides on.

.DESCRIPTION
A PowerShell function to create a FlashArray snapshot of the volume that a database resides on, based in the
values of the following parameters:

.PARAMETER Database
Required. The name of the database to refresh, note that it is assumed that source and target database(s) are named the same.

.PARAMETER SqlInstance
Required. This can be one or multiple SQL Server instance(s) that host the database(s) to be refreshed, in the case that the
function is invoked  to refresh databases  across more than one instance, the list of target instances should be
spedcified as an array of strings, otherwise a single string representing the target instance will suffice.

.PARAMETER Endpoint
Required. The IP address representing the FlashArray that the volumes for the source and refresh target databases reside on.

.EXAMPLE
New-PfaDbSnapshot -Database tpch-no-compression -SqlInstance z-sql2016-devops-prd -Endpoint 10.225.112.10 -Creds $Creds

Create a snapshot of FlashArray volume that stores the tpch-no-compression database on the z-sql2016-devops-prd instance

.NOTES

FlashArray Credentials - A global variable $Creds may be used as described in the release notes for this module. If neither is specified, the module will prompt for credentials.

Known Restrictions
------------------
1. This function does not work for databases associated with failover cluster instances.
2. This function cannot be used to seed secondary replicas in availability groups using databases in the primary replica.
3. The function assumes that all database files and the transaction log reside on a single FlashArray volume.

Note that it has dependencies on the dbatools and PureStoragePowerShellSDK modules which are installed as part of this module.
#>
    param(
        [parameter(mandatory = $true)] [string] $Database,
        [parameter(mandatory = $true)] [string] $SqlInstance,
        [parameter(mandatory = $true)] [string] $Endpoint
    )

    Get-Sdk1Module
    Get-DbaToolsModule

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if ( ! $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ) {
        Write-Error "This function needs to be invoked within a PowerShell session with elevated admin rights"
        Return
    }

    # Connect to FlashArray
    if (!($Creds)) {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials (Get-Credential) -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }
    else {
        try {
            $FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials $Creds -IgnoreCertificateError
        }
        catch {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "Failed to connect to FlashArray endpoint $Endpoint with: $ExceptionMessage"
            Return
        }
    }

    Write-Colour -Text "FlashArray endpoint       : ", "CONNECTED" -Color Yellow, Green

    try {
        $DestDb = Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to connect to destination database $SqlInstance.$Database with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target SQL Server instance: ", $SqlInstance, " - ", "CONNECTED" -Color Yellow, Green, Green, Green
    Write-Colour -Text "Target windows drive      : ", $DestDb.PrimaryFilePath.Split(':')[0] -Color Yellow, Green

    try {
        $TargetServer = (Connect-DbaInstance -SqlInstance $SqlInstance).ComputerNamePhysicalNetBIOS
    }
    catch {
        Write-Error "Failed to determine target server name with: $ExceptionMessage"
    }

    Write-Colour -Text "Target SQL Server host    : ", $TargetServer -ForegroundColor Yellow, Green

    $GetDbDisk = { param ( $Db )
        $DbDisk = Get-Partition -DriveLetter $Db.PrimaryFilePath.Split(':')[0] | Get-Disk
        return $DbDisk
    }

    try {
        $TargetDisk = Invoke-Command -ComputerName $TargetServer -ScriptBlock $GetDbDisk -ArgumentList $DestDb
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to determine the windows disk snapshot target with: $ExceptionMessage"
        Return
    }

    Write-Colour -Text "Target disk serial number : ", $TargetDisk.SerialNumber -Color Yellow, Green

    try {
        $TargetVolume = Get-PfaVolumes -Array $FlashArray | Where-Object { $_.serial -eq $TargetDisk.SerialNumber } | Select-Object name
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to determine snapshot FlashArray volume with: $ExceptionMessage"
        Return
    }

    $SnapshotSuffix = $SqlInstance.Replace('\', '-') + '-' + $Database + '-' + $(Get-Date).Hour + $(Get-Date).Minute + $(Get-Date).Second
    Write-Colour -Text "Snapshot target Pfa volume: ", $TargetVolume.name -Color Yellow, Green
    Write-Colour -Text "Snapshot suffix           : ", $SnapshotSuffix -Color Yellow, Green

    try {
        New-PfaVolumeSnapshots -Array $FlashArray -Sources $TargetVolume.name -Suffix $SnapshotSuffix
    }
    catch {
        $ExceptionMessage = $_.Exception.Message
        Write-Error "Failed to create snapshot for target database FlashArray volume with: $ExceptionMessage"
        Return
    }
}
#endregion

#### END DBATOOLS FUNCTIONS

#### End Exported Functions

# Declare Exports
Export-ModuleMember -Function Get-AllHostVolumeInfo
Export-ModuleMember -Function Set-WindowsPowerScheme
Export-ModuleMember -Function Get-HostBusAdapter
Export-ModuleMember -Function Register-HostVolumes
Export-ModuleMember -Function Unregister-HostVolumes
Export-ModuleMember -Function Get-QuickFixEngineering
Export-ModuleMember -Function Test-WindowsBestPractices
Export-ModuleMember -Function New-VolumeShadowCopy
Export-ModuleMember -Function Get-VolumeShadowCopy
Export-ModuleMember -Function New-FlashArrayCapacityReport
Export-ModuleMember -Function Update-DriveInformation
Export-ModuleMember -Function Sync-FlashArrayHosts
Export-ModuleMember -Function Get-FlashArraySerialNumbers
Export-ModuleMember -Function New-HypervClusterVolumeReport
Export-ModuleMember -Function Set-TlsVersions
Export-ModuleMember -Function Get-MPIODiskLBPolicy
Export-ModuleMember -Function Set-MPIODiskLBPolicy
Export-ModuleMember -Function Get-FlashArrayStaleSnapshots
Export-ModuleMember -Function Get-FlashArrayDisconnectedVolumes
Export-ModuleMember -Function Get-FlashArraySpace
Export-ModuleMember -Function Show-FlashArrayPgroupsConfig
Export-ModuleMember -Function Remove-FlashArrayPendingDeletes
Export-ModuleMember -Function Get-FlashArrayConfig
Export-ModuleMember -Function Get-FlashArrayHierarchy
Export-ModuleMember -Function Get-PfaSerialNumbers
Export-ModuleMember -Function New-PfaDbSnapshot
Export-ModuleMember -Function Invoke-DynamicDataMasking
Export-ModuleMember -Function Invoke-StaticDataMasking
Export-ModuleMember -Function Invoke-PfaDbRefresh

# END