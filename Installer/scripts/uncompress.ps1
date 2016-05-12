param(
	[Parameter(Mandatory=$true)] [string] $Source,
	[Parameter(Mandatory=$true)] [string] $Destination
)

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
$Compression = [System.IO.Compression.CompressionLevel]::Optimal

[System.IO.Compression.ZipFile]::ExtractToDirectory($Source,$Destination)