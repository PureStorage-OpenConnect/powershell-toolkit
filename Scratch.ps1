function New-FlashArrayReportPiechart() {
	Param (
		[string]$FileName,
        [float]$CapacitySpace,
        [float]$SnapshotSpace,
        [float]$VolumeSpace
	)
		
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
	
	$chart = New-Object System.Windows.Forms.DataVisualization.charting.chart
    $chart.Width = 900
    $chart.Height = 600
    $chart.Left = 10
    $chart.Top = 10

	$chartArea = New-Object System.Windows.Forms.DataVisualization.charting.chartArea
	$chart.chartAreas.Add($chartArea) 
	[void]$chart.Series.Add("Data") 
	
   	$legend = New-Object system.Windows.Forms.DataVisualization.charting.Legend
   	$legend.Name = "Legend"
    $legend.Font = "Proxima Nova"
   	$legend.Alignment = "Center"
   	$legend.Docking = "top"
   	$legend.Bordercolor = "#FE5000"
   	$legend.Legendstyle = "row"
    $chart.Legends.Add($legend)

	$datapoint = New-Object System.Windows.Forms.DataVisualization.charting.DataPoint(0, $capacitySpace)
	$datapoint.AxisLabel = "Physical Capacity " + "(" + $("{0:N0}" -f $capacitySpace) + " GB)"
	$chart.Series["Data"].Points.Add($datapoint)
		
	$datapoint = New-Object System.Windows.Forms.DataVisualization.charting.DataPoint(0, $snapSpace)
	$datapoint.AxisLabel = "SnapShots " + "(" + $snapSpace + " GB)"
	$chart.Series["Data"].Points.Add($datapoint)
		
	$datapoint = New-Object System.Windows.Forms.DataVisualization.charting.DataPoint(0, $volumeSpace)
	$datapoint.AxisLabel = "Volumes " + "(" + $volumeSpace + " GB)"
	$chart.Series["Data"].Points.Add($datapoint)
		
	$chart.Series["Data"].chartType = [System.Windows.Forms.DataVisualization.charting.SerieschartType]::Pie
	$chart.Series["Data"]["PieLabelStyle"] = "Outside" 
	$chart.Series["Data"]["PieLineColor"] = "#FE5000" 
	$chart.Series["Data"]["PieDrawingStyle"] = "Concave" 
	($chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

	$Title = New-Object System.Windows.Forms.DataVisualization.charting.Title 
	$chart.Titles.Add($Title) 
	$chart.Titles[0].Text = "Capacity Usage Visualization"
    $chart.SaveImage($FileName + ".png","png")

    $Script:PiechartImgSrc = ConvertTo-Base64 ($FileName + ".png")
    Remove-Item -Path ($FileName + ".png")
}