<#	
        ===========================================================================
        Created by:   	barkz@purestorage.com
        Organization: 	Pure Storage, Inc.
        Filename:     	PowerShell-Toolkit.psm1
        Copyright:		(c) 2016 Pure Storage, Inc.
		Github:			https://github.com/purestorage/PowerShell-Toolkit
        -------------------------------------------------------------------------
        Module Name: PowerShell-Toolkit
		Development Tool: https://github.com/adamdriscoll/poshtools
		Installer Tool: http://wixtoolset.org/

        Disclaimer
        The sample script and documentation are provided AS IS and are not supported by 
        the author or the author�s employer, unless otherwise agreed in writing. You bear 
        all risk relating to the use or performance of the sample script and documentation. 
        The author and the author�s employer disclaim all express or implied warranties 
        (including, without limitation, any warranties of merchantability, title, infringement 
        or fitness for a particular purpose). In no event shall the author, the author�s employer 
        or anyone else involved in the creation, production, or delivery of the scripts be liable 
        for any damages whatsoever arising out of the use or performance of the sample script and 
        documentation (including, without limitation, damages for loss of business profits, 
        business interruption, loss of business information, or other pecuniary loss), even if 
        such person has been advised of the possibility of such damages.
        ===========================================================================
#>

<# 	Base requirement for Pure Storage PowerShell Toolkit 3.x is PowerShell 3.0 which provides
    support for the Invoke-RestMethod cmdlet. See http://technet.microsoft.com/en-us/library/hh849971.aspx
    for full details.
#>
#Requires -Version 3
#Requires -Module PureStoragePowerShellSDK


#
#  TODO -- Add welcome message with getting started information. 
#

# 
#region UNDER_DEVELOPMENT -- New-FlashArrayReport Functions
<#function New-FlashArrayReport() {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string] $Array, 
		[Parameter()][ValidateNotNullOrEmpty()][string] $Username, 
		[Parameter()][ValidateNotNullOrEmpty()][string] $Password) 
			
	$ErrorActionPreference = "SilentlyContinue"

	$timestamp = Get-Date -format d    
	#$list = $args[0] #This accepts the argument you add to your scheduled task for the list of servers. i.e. list.txt
	#$pfaArrays = get-content $list #grab the names of the servers/pfaArrays to check from the list.txt file.
	$Script:ListOfAttachments = @()
	$Script:Report = @()
	$Script:CurrentTime = Get-Date
}

#region Helper-functions
function New-PieChart() {
	param([string]$FileName)
		
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
	
	$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
	$Chart.Width = 650
	$Chart.Height = 370 
	$Chart.Left = 10
	$Chart.Top = 10

	$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$Chart.ChartAreas.Add($ChartArea) 
	[void]$Chart.Series.Add("Data") 
	
   	$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
   	$legend.name = "Legend"
   	$legend.alignment = "Center"
   	$legend.docking = "top"
   	$legend.bordercolor ="orange"
   	$legend.legendstyle = "row"
   	$chart.Legends.Add($legend)

	$datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $capacitySpace)
	$datapoint.AxisLabel = "Physical Capacity" + "(" + $capacitySpace + " GB)"
	$Chart.Series["Data"].Points.Add($datapoint)
		
	$datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $snapSpace)
	$datapoint.AxisLabel = "SnapShots" + "(" + $snapSpace + " GB)"
	$Chart.Series["Data"].Points.Add($datapoint)
		
	$datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $volumeSpace)
	$datapoint.AxisLabel = "Volumes" + "(" + $volumeSpace + " GB)"
	$Chart.Series["Data"].Points.Add($datapoint)
		
	$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
	$Chart.Series["Data"]["PieLabelStyle"] = "Outside" 
	$Chart.Series["Data"]["PieLineColor"] = "Orange" 
	$Chart.Series["Data"]["PieDrawingStyle"] = "Concave" 
	($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

	$Title = new-object System.Windows.Forms.DataVisualization.Charting.Title 
	$Chart.Titles.Add($Title) 
	$Chart.Titles[0].Text = "Capacity Usage Chart (Capacity/Volumes/SnapShots)"

	$Chart.SaveImage($FileName + ".png","png")
}

function Convert-Size { 
{
    [CmdletBinding()]
    Param (
		[validateset("Bytes","KB","MB","GB","TB")]            
		[string]$From,            
		[validateset("Bytes","KB","MB","GB","TB")]            
		[string]$To,            
		[Parameter(Mandatory=$true)]            
		[double]$Value,            
		[int]$Precision = 4)
	           
		switch($From) {            
			"Bytes" {$value = $Value }            
			"KB" {$value = $Value * 1024 }            
			"MB" {$value = $Value * 1024 * 1024}            
			"GB" {$value = $Value * 1024 * 1024 * 1024}            
			"TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}            
		}            
            
		switch ($To) {            
			"Bytes" {return $value}            
			"KB" {$Value = $Value/1KB}            
			"MB" {$Value = $Value/1MB}            
			"GB" {$Value = $Value/1GB}            
			"TB" {$Value = $Value/1TB}                        
		}            
            
	return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)            
}         

function Get-Volumes {
	$Script:numVols = $MyVol.length
	$Script:startVol = 0
	$Script:provisioned = 0

	while ($startVol -le $numVols) {
		if ($MyVol[$startVol].name){
				$printVol = $MyVol[$startVol].name 
				$VolSize=$MyVol[$startVol].size/1GB
				$Script:provisioned =  ($provisioned + $VolSize)
				$Script:VolumeInfo += "<tr><td>$printVol</td> <td>$volSize</td></tr>"				
				$startVol++
			}else { 
				Break
			}
				$endVol = $endVol + 1
	}
	$Script:provisioned =  Convert-Size -From GB -To TB $provisioned -Precision 2
}

function Get-Snapshots {
# Note SnapShots start at 0 not 1	
	$Script:numSnaps = $MyPfaSnaps.length
	$Script:startSnap = 0
	$Script:provisioned = 0

	while ($startSnap -le $numSnaps) {
		if ($MyPfaSnaps[$startSnap].name){
				$printSnap = $MyPfaSnaps[$startSnap].name 
				$SnapSize=$MyPfaSnaps[$startSnap].size/1GB
				$Script:provisioned =  ($provisioned + $SnapSize)
				$Script:SnapInfo += "<tr><td>$printSnap</td> <td>$SnapSize</td></tr>"
				$startSnap++
			}else { 
					Break # If there are no volumes to report, then exit the loop
			}
				$endSnap = $endSnap + 1
	}
$Script:provisioned =  Convert-Size -From GB -To TB $provisioned -Precision 2
}
#endregion

function Connect-PfaFlashArray () {
try
{	

	write-output  "Importing data from live system - $FlashArray, please wait........"
	$Creds = Get-Credential
    $FlashArray = New-PfaArray -EndPoint $FlashArray -Credentials $Creds -IgnoreCertificateError
    # OLD--$MyToken = Get-PfaAPIToken -FlashArray $FlashArray -Username $Username -Password $Password -RestAPI "1.2" -ErrorAction Stop
	# OLD--$MySession = Connect-PfaController -FlashArray $FlashArray -API_Token $MyToken.api_token -ErrorAction Stop
    $MyPfaSpace = Get-PfaArraySpaceMetrics -Array $FlashArray
	# OLD--$MyPfaSpace = Get-PfaSpace -FlashArray $FlashArray -Session $MySession  -ErrorAction Stop
    ######$MyPfaArray = Get-PfaConfiguration -FlashArray $FlashArray -Session $MySession  -ErrorAction Stop
	# OLD--$MyPfaSpace = Get-PfaSpace -FlashArray $FlashArray -Session $MySession  -ErrorAction Stop
    $MyPfaConfig = Get-PfaArrayAttributes -Array $FlashArray
    # OLD--$MyPfaConfig = Get-PfaConfiguration -FlashArray $FlashArray -Session $MySession  -ErrorAction Stop
	$MyPfaVolumes = Get-PfaVolumes -Array $FlashArray
	#OLD--$MyPfaVolumes = Get-PfaVolumes -FlashArray $FlashArray -Session $MySession -ErrorAction Stop
    $MyPfaSnaps = Get-PfaAllVolumeSnapshots -Array $FlashArray
    # OLD--$MyPfaSnaps = Get-PfaSnapShots -FlashArray $FlashArray -Session $MySession -ErrorAction Stop
	Write-Host "Snapshots" -ForegroundColor DarkBlue
	Write-Host $MyPfaSnaps[0]
	Write-Host "..........................." -ForegroundColor DarkBlue
    Disconnect-PfaArray -Array $FlashArray
	# OLD--Disconnect-PfaController -FlashArray $FlashArray -Session $MySession -ErrorAction Stop
	
	#region Array Variables
	$Script:hostname = 			$MyPfaSpace.hostname 
	$Script:capacitySpace = 	Convert-Size -From Bytes -To GB $MyPfaSpace.capacity -Precision 2
	$Script:snapSpace = 		Convert-Size -From Bytes -To GB $MyPfaSpace.snapshots -Precision 2
 	$Script:volumeSpace = 		Convert-Size -From Bytes -To GB $MyPfaSpace.volumes -Precision 2
 	$Script:data_reduction = 	Convert-Size -From Bytes -To GB $MyPfaSpace.data_reduction -Precision 2
 	$Script:totalSpace = 		Convert-Size -From Bytes -To GB $MyPfaSpace.total -Precision 2
 	$Script:shared_space = 		Convert-Size -From Bytes -To GB $MyPfaSpace.shared_space -Precision 0
 	$Script:thin_prov = 		Convert-Size -From Bytes -To GB $MyPfaSpace.thin_provisioning -Precision 2
	$Script:myVol =				$MyPfaVolumes
	$Script:total_reduction = 	[system.Math]::Round($MyPfaSpace.total_reduction,1)
	#Endregion
	

	Write-Host "............................................................." -ForegroundColor DarkRed
	Write-Host "Total  = $totalSpace (TB)"
	Write-Host "Total Capacity = $capacitySpace (GB)"
	Write-Host "Total Volumes = $volumeSpace (TB)"
	Write-Host "Total Snapshots = $SnapSpace (GB)"
	Write-Host "Total DataReduction = $data_reduction (GB)"
	Write-Host "Total Reduction = $total_reduction :1 "
	
	# Create the chart using our Chart function
	Create-PieChart -FileName ((Get-Location).Path + "\chart-$hostname") $capacitySpace, $volumeSpace, $SnapSpace 
	$Script:ListOfAttachments += "chart-$hostname.png"
 
	Get-Volumes
	Get-SnapShots

} # End Try
catch [system.exception]
{
   	write-output "Error:"+$($_.Exception.Message)
	write-host $Error[0]
} # End Catch
}

$ListOfAttachments = ((Get-Location).Path + "\" + $listofattachments)

Connect-PfaFlashArray

# Assemble the HTML Header and CSS for our Report
$HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>$hostname Capacity Report</title>
<style type="text/css">
<!--
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

    #report { width: 900px; }

    table{
	border-collapse: collapse;
	border: none;
	font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
	color: black;
	margin-bottom: 10px;
}

    table td{
	font-size: 12px;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

    table th {
	font-size: 12px;
	font-weight: bold;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

h2{ clear: both; font-size: 130%; }

h3{
	clear: both;
	font-size: 115%;
	margin-left: 20px;
	margin-top: 30px;
}

p{ margin-left: 20px; font-size: 12px; }

hr{ background-color: orange }

table.list{ float: left; }
    table.list td:nth-child(1){
	font-weight: bold;
	border-right: 1px grey solid;
	text-align: right;
}

table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
div.column { width: 400px; float: left; }
div.first{ padding-right: 20px; border-right: 1px  grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
-->
</style>
</head>
<body>

"@


# Create HTML Report for the current System being looped through
$CurrentSystemHTML = @"
	<hr noshade size=3 width="100%">
	
	<div id="report">
	<p><h2>$hostname Capacity Report</p></h2>
	<h3>System Info</h3>
	<img src="chart-$hostname.png">
	<table class="list">
	<tr>
	<td>Total Capacity (GB)</td>
	<td>$capacitySpace</td>
	</tr>
	<tr>
	<td>Total Snapshots (GB)</td>
	<td>$snapspace</td>
	</tr>
	<tr>
	<td>Total Volumes (GB)</td>
	<td>$volumespace</td>
	</tr>
	<tr>
	<td>Data Reduction</td>
	<td>$total_reduction :1</td>
	</tr>
	<tr>
	<td>Provisioned (TB)</td>
	<td>$provisioned</td>
	</tr>
	</table>
	
	<h3>Volume Info</h3>
	<p>Volumes(s) and sizes (GB) listed below.</p>
	<table class="list">$VolumeInfo</table>
	
	<h3>SnapShot Info</h3>
	<p>SnapShot(s) and sizes (GB) listed below.</p>
	<table class="list">$SnapInfo</table>
	<br></br>	

"@

# Add the current System HTML Report into the final HTML Report body
$HTMLMiddle += $CurrentSystemHTML
	


# Assemble the closing HTML for our report.
$HTMLEnd = @"
</div>
<hr noshade size=3 width="100%">
</body>
</html>
"@

# Assemble the final report from all our HTML sections
$HTMLmessage = $HTMLHeader + $HTMLMiddle + $HTMLEnd
# Save the report out to a file in the current path
$HTMLmessage | Out-File ((Get-Location).Path + "\report.html")

# Email our report out

$EmailFrom = "someone@somewhere.com"
$EmailTo = "someone@somewhere.com" 
$Subject = "Pure Storage Capacity Report For $hostname" 
$Body = "Capacity notification email from $hostname .." 
$SMTPServer = "your.domain.com" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("username", "password"); 

$emailMessage = New-Object System.Net.Mail.MailMessage
$emailMessage.From = $EmailFrom
$emailMessage.To.Add($EmailTo)
$emailMessage.Subject = $Subject
$emailMessage.Body = $HTMLmessage
$emailMessage.IsBodyHTML = $true

$attachment = New-Object System.Net.Mail.Attachment �ArgumentList $ListOfAttachments
$attachment.ContentDisposition.Inline = $True
$attachment.ContentDisposition.DispositionType = "Inline"
$attachment.ContentType.MediaType = "image/jpg"
$attachment.ContentId = 'image1.jpg'

$emailMessage.Attachments.Add( $attachment )

$SMTPClient.Send($emailMessage) 
$attachment.Dispose();
$emailMessage.Dispose();#>
#endregion

# 
# UNDER DEVELOPMENT -- Test-WindowsBestPractices
function Test-WindowsBestPractices()
{
	<#[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True)][string]$ComputerName
	)#>
	
		Clear
		
		Write-Output '============================================================'
		Write-Output 'Pure Storage Windows Server Best Practice Analyzer'
		Write-Output '============================================================'
	
		<#TODO -- Add to output
			VERSION #
			VERSION # output to screeen
			LINK at bottom
			HBA
			CHECK WINDOWS VERSION
		$Windows2008R2 = @(
		'KB979711', 'KB2520235', 'KB2528357',
		'KB2684681', 'KB2718576', 'KB2522766',
		'KB2528357', 'KB2684681', 'KB2754704', 'KB2990170')
		$Windows2012 = @('KB2796995', 'KB2990170')
		$Windows2012R2 = @('KB2990170')
		$Windows2016 = @('KB2967917', 'KB2961072', 'KB2998527')
		
		$HotfixIds = Get-HotFix
		
		ForEach ($Hotfix in $Windows2016)
		{
			#Write-Host $Hotfix '---' $HotfixId  
		}
		#>
		
		Write-Output ''
		Write-Output '=============================='
		Write-Output 'Host Information'
		Write-Output '=============================='
		Get-SilComputer
		#Get-SilWindowsUpdate | Format-Table -AutoSize
		
		Write-Output ''
		Write-Output '=============================='
		Write-Output 'Multipath-IO Verificaton'
		Write-Output '=============================='
		if (!(Get-WindowsFeature -Name 'Multipath-IO').InstalledStatus -eq 'Installed')
		{
			Write-Output 'PASS: Multipath I/O is installed.'
		}
		else
		{
			Write-Warning 'FAIL: Please install Multipath-IO.'
			break
		}
		
		Write-Output ''
		Write-Output '=============================='
		Write-Output 'MPIO Setting Verification'
		Write-Output '=============================='
		
		ForEach ($DSM in Get-MSDSMSupportedHW)
		{
			if (!(($DSM).VendorId -eq 'PURE' -and ($DSM).ProductId -eq 'FlashArray'))
			{
				Write-Output 'PASS: Microsoft Device Specific Module (MSDSM) is configured for Pure Storage FlashArray.'
				
				$MPIO = Get-MPIOSetting | Out-String -Stream
				
				if (($MPIO[4] -replace " ", "") -ceq 'PDORemovePeriod:60')
				{
					#30
					Write-Output 'PASS: MPIO PDORemovePeriod passes Windows Server Best Practice check.'
				}
				else
				{
					Write-Warning 'FAIL: MPIO PDORemovePeriod does NOT pass Windows Server Best Practice check.'
				}
				if (($MPIO[7] -replace " ", "") -ceq 'UseCustomPathRecoveryTime:Enabled')
				{
					#Enabled
					Write-Output 'PASS: MPIO UseCustomPathRecoveryTime passes Windows Server Best Practice check.'
				}
				else
				{
					Write-Warning 'FAIL: MPIO UseCustomPathRecoveryTime does NOT pass Windows Server Best Practice check.'
				}
				if (($MPIO[8] -replace " ", "") -ceq 'CustomPathRecoveryTime:20')
				{
					#20
					Write-Output 'PASS: MPIO CustomPathRecoveryTime passes Windows Server Best Practice check.'
				}
				else
				{
					Write-Warning 'FAIL: MPIO CustomPathRecoveryTime does NOT pass Windows Server Best Practice check.'
				}
				if (($MPIO[9] -replace " ", "") -ceq 'DiskTimeoutValue:60')
				{
					#60
					Write-Output 'PASS: MPIO DiskTimeoutValue passes Windows Server Best Practice check.'
				}
				else
				{
					Write-Warning 'FAIL: MPIO PDiskTimeoutValue does NOT pass Windows Server Best Practice check.'
				}
				
        <#RESEARCH -- Support for Windows Server 2008 R2. 
	        $Paths = (Get-ChildItem -Path "hklm:\SYSTEM\CurrentControlSet\Services\msdsm\Parameters\DsmLoadBalanceSettings").Name
	        ForEach ($Path in $Paths) {
	            $PureVolumePath = $Path.Substring(93)
	            (Get-ChildItem -Path "hklm:\SYSTEM\CurrentControlSet\Services\msdsm\Parameters\DsmLoadBalanceSettings\$PureVolumePath").Name.Substring(93) | Select Name
	        }
	        $DsmContext = Get-WmiObject -Namespace 'root/WMI' -Class MPIO_REGISTERED_DSM
	        $DsmCounters = Get-Wmiobject -ComputerName $ComputerName -NameSpace root/WMI -Class MPIO_TIMERS_COUNTERS             
	        Invoke-WmiMethod -Class MPIO_WMI_METHODS -Name SetDSMCounters -ArgumentList $DsmContext#, $DsmCounters
	        Invoke-WmiMethod -Class MPIO_TIMERS_COUNTERS -Name PDORemovePeriod -ArgumentList @{PDORemovePeriod=60}
	        Set-WmiInstance -Class MPIO_TIMERS_COUNTERS -Arguments @{PDORemovePeriod=60}
	        Get-WmiObject -Query 'SELECT InstanceName from MPIO_WMI_METHODS'
	        Get-WmiObject -Namespace 'root/WMI' -Class MPIO_ADAPTER_INFORMATION -ComputerName $env:COMPUTERNAME
	        Get-WmiObject -Namespace 'root/WMI' -Query 'SELECT PathList FROM MPIO_PATH_INFORMATION'
	        Get-WmiObject -Namespace 'root/WMI' -Query 'SELECT NumberPaths FROM MPIO_PATH_INFORMATION' -ComputerName $env:COMPUTERNAME
	        Get-WmiObject -Namespace 'root/WMI' -Query 'SELECT DsmParameters FROM MPIO_REGISTERED_DSM' -ComputerName $env:COMPUTERNAME
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_DISK_HEALTH_INFO
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_DISK_INFO 
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_PATH_HEALTH_INFO
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_PATH_INFORMATION
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_REGISTERED_DSM
	        Get-Wmiobject -ComputerName CSG-WS2012R2-01 -NameSpace root/WMI -Class MPIO_TIMERS_COUNTERS ######             
	        Get-WmiObject -Namespace 'root/cimv2' -Class DSM_Load_Balance_Policy
        #>
				
			}
			else
			{
				if ($DSM.VendorId -eq 'Vendor 8')
				{
					Write-Warning "RECOMMENDATION: Remove the sample DSM entry (VendorId=$DSM.VendorId and ProductId=$DSM.ProductId)"
				}
				else
				{
					Write-Warning 'Microsoft Device Specific Module (MSDSM) is NOT configured for Pure Storage FlashArray.'
				}
			}
		}
		
		Write-Output ''
		Write-Output '=============================='
		Write-Output 'TRIM/UNMAP Verification'
		Write-Output '=============================='
		if (!(Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\FileSystem' -Name 'DisableDeleteNotification') -eq 0)
		{
			Write-Output 'PASS: Delete Notification Enabled'
		}
		else
		{
			Write-Warning 'Delete Notification Disabled. Pure Storage Best Practice is to enable delete notifications.'
		}
		
		#TODO: iSCSI
		#TODO: Create Analysis report using New-Report cmdlets
	}
} #>

# 
# UNDER DEVELOPMENT -- Optimize-Unmap
<#function Optimize-Unmap()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$vCenterUser,
        [Parameter(Mandatory = $True)][string]$vCenterPassword,
        [Parameter(Mandatory = $True)][string[]]$FlashArrays,
        [Parameter(Mandatory = $True)][PSCredential]$Creds,
		[Parameter(Mandatory = $True)][string]$LogPath,
		[Parameter(Mandatory = $True)][string]$LogFile
    )

	#Important PowerCLI if not done and connect to vCenter
	Add-PsSnapin VMware.VimAutomation.Core

	#Create log folder if non-existent
	If (!(Test-Path -Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath }
	$LogFile = $LogPath + (Get-Date -Format o |ForEach-Object {$_ -Replace ':', '.'}) + $LogFile

	#Connect to FlashArray via REST
	$facount=0
	$purevols=$null
	$purevol=$null
	$EndPoint= @()

	#$Pwd = ConvertTo-SecureString $pureuserpwd -AsPlainText -Force
	#$Creds = New-Object System.Management.Automation.PSCredential ($pureuser, $pwd)

	foreach ($flasharray in $flasharrays)
	{
		if ($facount -eq 0)
		{
			$EndPoint = @(New-PfaArray -EndPoint $flasharray -Credentials $Creds -IgnoreCertificateError)
			$purevolumes = @(Get-PfaVolumes -Array $EndPoint[$facount])
			$tempvols = @(Get-PfaVolumes -Array $EndPoint[$facount])  
			$arraysnlist = @(@{$tempvols[0].serial.substring(0,16) = $facount})
		}
		else
		{
			$EndPoint += New-PfaArray -EndPoint $flasharray -Credentials $Creds -IgnoreCertificateError
			$purevolumes += Get-PfaVolumes -Array $EndPoint[$facount]
			$tempvols = Get-PfaVolumes -Array $EndPoint[$facount]   
			$arraysnlist += @{$tempvols[0].serial.substring(0,16) = $facount}
		}
		$facount = $facount + 1
	}

	add-content $LogFile 'Connected to FlashArray:'
	add-content $LogFile $purevip
	add-content $LogFile '----------------'

	#Set-PowerCLIConfiguration -invalidcertificateaction 'ignore' -confirm:$false |out-null
	#Set-PowerCLIConfiguration -Scope Session -WebOperationTimeoutSeconds -1 -confirm:$false |out-null
	connect-viserver -Server $vCenter -username $vCenterUser -password $vCenterPassword | Out-Null
	add-content $LogFile 'Connected to vCenter:'
	add-content $LogFile $vCenter
	add-content $LogFile '----------------'

	#Gather VMFS Datastores and identify how many are Pure Storage volumes
	$datastores = get-datastore
	add-content $LogFile 'Found the following datastores:'
	add-content $LogFile $datastores
	add-content $LogFile '***************'

	#Starting UNMAP Process on datastores
	$volcount=0
	$purevol = $null
	foreach ($datastore in $datastores)
	{
		$esx = $datastore | get-vmhost | where-object {($_.version -like '5.5.*') -or ($_.version -like '6.0.*')} | Select-Object -last 1
		if ($datastore.Type -ne 'VMFS')
		{
			add-content $LogFile 'This volume is not a VMFS volume and cannot be reclaimed. Skipping...'
			add-content $LogFile $datastore.Type
		}
		else
		{
			$lun = get-scsilun -datastore $datastore | select-object -last 1
			$esxcli=get-esxcli -VMHost $esx
			add-content $LogFile 'The following datastore is being examined:'
			add-content $LogFile $datastore 
			add-content $LogFile 'The following ESXi is the chosen source:'
			add-content $LogFile $esx 

			if ($lun.canonicalname -like 'naa.624a9370*')
			{
				$volserial = ($lun.CanonicalName.ToUpper()).substring(12)
				$purevol = $purevolumes | where-object { $_.serial -eq $volserial }
				$arraychoice = $arraysnlist.($volserial.substring(0,16))
				$volinfo = Get-PfaVolumeSpaceMetrics -Array $EndPoint[$arraychoice] -VolumeName $purevol.name
				$volreduction = '{0:N3}' -f ($volinfo.data_reduction)
				$volphysicalcapacity = '{0:N3}' -f ($volinfo.volumes/1024/1024/1024)
				add-content $LogFile 'This datastore is a Pure Storage Volume.'
				add-content $LogFile $lun.CanonicalName
				add-content $LogFile 'The current data reduction for this volume prior to UNMAP is:'
				add-content $LogFile $volreduction
				add-content $LogFile 'The current physical space consumption in GB of this device prior to UNMAP is:'
				add-content $LogFile $volphysicalcapacity
        
				$blockcount = [math]::floor($datastore.FreeSpaceMB * .01)
				add-content $LogFile 'The maximum allowed block count for this datastore is'
				add-content $LogFile $blockcount
				$esxcli.storage.vmfs.unmap($blockcount, $datastore.Name, $null) |out-null
				Start-Sleep -s 10
				$volinfo = Get-PfaVolumeSpaceMetrics -Array $EndPoint[$arraychoice] -VolumeName $purevol.name
				$volreduction = '{0:N3}' -f ($volinfo.data_reduction)
				$volphysicalcapacitynew = '{0:N3}' -f ($volinfo.volumes/1024/1024/1024)
				$unmapsavings = ($volphysicalcapacity - $volphysicalcapacitynew)
				$volcount=$volcount+1
				add-content $LogFile 'The new data reduction for this volume after UNMAP is:'
				add-content $LogFile $volreduction
				add-content $LogFile 'The new physical space consumption in GB of this device after UNMAP is:'
				add-content $LogFile $volphysicalcapacitynew
				add-content $LogFile 'The following capacity in GB has been reclaimed from the FlashArray from this volume:'
				add-content $LogFile $unmapsavings
				add-content $LogFile '---------------------'
				Start-Sleep -s 5
			}
			else
			{
				add-content $LogFile 'This datastore is NOT a Pure Storage Volume. Skipping...'
				add-content $LogFile $lun.CanonicalName
				add-content $LogFile '---------------------'
			}
		}
	}

	#disconnecting sessions
	$facount=0
	foreach ($flasharray in $flasharrays)
	{
		Disconnect-PfaArray -Array $flasharray
		$facount = $facount + 1
	}
}
#>
#endregion

#region Miscellenaous-Cmdlets

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-WindowsPowerScheme()
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName
	)
	
	try
	{
		$PowerScheme = Get-WmiObject -Class WIN32_PowerPlan -Namespace 'root\cimv2\power' -ComputerName $ComputerName -Filter "isActive='true'"
		Write-Warning $ComputerName 'is set to' $PowerScheme.ElementName
	}
	catch
	{
		
	}
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Open-PureStorageGitHub
{
    try
    {
        $link = 'https://github.com/purestorage-openconnect/powershell-toolkit'
        $browserProcess = [System.Diagnostics.Process]::Start($link)
    }
    catch
    {
	
    }
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Set-QueueDepth()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][int] $Qd
    )
    try
    {
        $DriverParam = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\ql2300\Parameters\Device\'
        If (!$DriverParam.DriverParameter)
        {
            $Confirm = Read-Host 'The Queue Depth setting for the QLogic Driver (ql2300.sys) does not exist would you like to create it? Y/N'
            switch ($Confirm)
            {
                'Y' { Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\ql2300\Parameters\Device' -Name 'DriverParameter' -Value "qd=$Qd" }
                'N' { }
            }
        }
        Else
        {
            $CurrentQD = $DriverParam.DriverParameter
            $Confirm = Read-Host "QLogic Driver Queue Depth is $CurrentQD. Do you want to update to $Qd ? Y/N"
            switch ($Confirm)
            {
                'Y' { Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\ql2300\Parameters\Device' -Name 'DriverParameter' -Value "qd=$Qd" }
                'N' { }
            }
        }
    }
    catch
    {

    }
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-QuickFixEngineering
{
    Get-WmiObject -Class Win32_QuickFixEngineering | Select-Object -Property Description, HotFixID, InstalledOn | Format-Table -Wrap
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-QueueDepth()
{
    try {
        $DriverParam = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\ql2300\Parameters\Device\'
        'Queue Depth is ' + $DriverParam.DriverParameter
    } catch {

    }
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-HostBusAdapter()
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $ComputerName
	)
	
	try
	{
		$port = Get-WmiObject -Class MSFC_FibrePortHBAAttributes -Namespace 'root\WMI' -ComputerName $ComputerName
		$hbas = Get-WmiObject -Class MSFC_FCAdapterHBAAttributes -Namespace 'root\WMI' -ComputerName $ComputerName
		$hbaProp = $hbas | Get-Member -MemberType Property, AliasProperty | Select-Object -ExpandProperty name | Where-Object { $_ -notlike '__*' }
		$hbas = $hbas | Select-Object $hbaProp
		$hbas | %{ $_.NodeWWN = ((($_.NodeWWN) | % { '{0:x2}' -f $_ }) -join ':').ToUpper() }
		
		ForEach ($hba in $hbas)
		{
			Add-Member -MemberType NoteProperty -InputObject $hba -Name FabricName -Value (($port | Where-Object { $_.instancename -eq $hba.instancename }).attributes | Select-Object @{ Name = 'Fabric Name'; Expression = { (($_.fabricname | % { '{0:x2}' -f $_ }) -join ':').ToUpper() } }, @{ Name = 'Port WWN'; Expression = { (($_.PortWWN | % { '{0:x2}' -f $_ }) -join ':').ToUpper() } }) -passThru
		}
	}
	catch
	{
		
	}
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Register-HostVolumes ()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [string]$Computername
    )
	
    $cmds = "`"RESCAN`""
    $scriptblock = [string]::Join(',', $cmds)
    $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
    $result = Invoke-Command -ComputerName $Computername -ScriptBlock $diskpart
	
    $disks = Invoke-Command -Computername $Computername { Get-Disk }
    $i = 0
    ForEach ($disk in $disks)
    {
        If ($disk.FriendlyName -like 'PURE FlashArray*')
        {
            If ($disk.OperationalStatus -ne 1)
            {
                $disknumber = $disk.Number
                $cmds = "`"SELECT DISK $disknumber`"",
                "`"ATTRIBUTES DISK CLEAR READONLY`"",
                "`"ONLINE DISK`""
                $scriptblock = [string]::Join(',', $cmds)
                $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
                $result = Invoke-Command -ComputerName $Computername -ScriptBlock $diskpart -ErrorAction Stop
            }
        }
    }
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Unregister-HostVolumes ()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [string]$Computername
    )
	
    $cmds = "`"RESCAN`""
    $scriptblock = [string]::Join(',', $cmds)
    $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
    $result = Invoke-Command -ComputerName $Computername -ScriptBlock $diskpart
	
    $disks = Invoke-Command -Computername $Computername { Get-Disk }
    $i = 0
    ForEach ($disk in $disks)
    {
        If ($disk.FriendlyName -like 'PURE FlashArray*')
        {
            If ($disk.OperationalStatus -ne 1)
            {
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

#region PureStorage-VSS-Cmdlets

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-ShadowCopy()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string]$ScriptName = 'PUREVSS-SNAP',
        [Parameter(Mandatory = $True)][string]$MetadataFile,
        [Parameter(Mandatory = $True)][string]$ShadowCopyAlias,
        [Parameter(Mandatory = $True)][string]$ExposeAs
    )
	
    $dsh = "./$ScriptName.PFA"
    'RESET',
    "LOAD METADATA $MetadataFile.cab",
    'IMPORT',
    "EXPOSE %$ShadowCopyAlias% $ExposeAs",
    'EXIT' | Set-Content $dsh
    DISKSHADOW /s $dsh
    Remove-Item $dsh
}

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function New-ShadowCopy()
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string[]]$Volume,
        [Parameter(Mandatory = $True)][string]$ScriptName = 'PUREVSS-SNAP',
        [Parameter(Mandatory = $True)][string]$MetadataFile,
        [Parameter(Mandatory = $True)][string]$ShadowCopyAlias,
        [ValidateSet('On', 'Off')][string]$VerboseMode = 'On'
    )
    $dsh = "./$ScriptName.PFA"
	
    foreach ($Vol in $Volume)
    {
        "ADD VOLUME $Vol ALIAS $ShadowCopyAlias PROVIDER {781c006a-5829-4a25-81e3-d5e43bd005ab}"
    }
	
	
    'RESET',
    'SET CONTEXT PERSISTENT',
    'SET OPTION TRANSPORTABLE',
    "SET METADATA $MetadataFile.cab",
    "SET VERBOSE $VerboseMode",
    'BEGIN BACKUP',
    "ADD VOLUME $Volume ALIAS $ShadowCopyAlias PROVIDER {781c006a-5829-4a25-81e3-d5e43bd005ab}",
    'CREATE',
    'END BACKUP' | Set-Content $dsh
    DISKSHADOW /s $dsh
    Remove-Item $dsh
}
#endregion

#region PureStoragePowerShellSDK-Cmdlets

#.ExternalHelp PowerShell-Toolkit.psm1-help.xml
function Get-BlockSize ()
{

}
#endregion

#Export-ModuleMember -function Optimize-Unmap 
Export-ModuleMember -function Get-WindowsPowerScheme
Export-ModuleMember -function Get-HostBusAdapter
Export-ModuleMember -function Register-HostVolumes
Export-ModuleMember -function Unregister-HostVolumes
Export-ModuleMember -function Get-QuickFixEngineering
Export-ModuleMember -function Test-WindowsBestPractices
#Export-ModuleMember -function Get-BlockSize
Export-ModuleMember -function Get-HostBusAdapter
Export-ModuleMember -function Set-QueueDepth
Export-ModuleMember -function New-VolumeShadowCopy
Export-ModuleMember -function Get-VolumeShadowCopy
Export-ModuleMember -function New-FlashArraySpaceReport