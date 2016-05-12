param(
	[Parameter(Mandatory=$true)] [string] $Source,
	[Parameter(Mandatory=$true)] [string] $Destination
)

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
$Compression = [System.IO.Compression.CompressionLevel]::Optimal
$IncludeBaseDirectory = $false

[System.IO.Compression.ZipFile]::CreateFromDirectory($Source,$Destination,$Compression,$IncludeBaseDirectory)