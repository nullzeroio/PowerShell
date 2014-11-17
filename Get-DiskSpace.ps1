<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER
.INPUT
.OUTPUT
.EXAMPLE
.EXAMPLE
.NOTES

	20141117	K. Kirkpatrick		Created


	#TAG:PUBLIC

	GitHub:	 https://github.com/vN3rd
	Twitter:  @vN3rd
	Email:	 kevin@pinelabs.co

[-------------------------------------DISCLAIMER-------------------------------------]
	All script are provided as-is with no implicit
	warranty or support. It's always considered a best practice
	to test scripts in a DEV/TEST environment, before running them
	in production. In other words, I will not be held accountable
	if one of my scripts is responsible for an RGE (Resume Generating Event).
	If you have questions or issues, please reach out/report them on
	my GitHub page. Thanks for your support!
[-------------------------------------DISCLAIMER-------------------------------------]

#>

[cmdletbinding(PositionalBinding = $true,
			   DefaultParameterSetName = "Default")]
param (
	[parameter(mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   Position = 0)]
	[alias("Comp")]
	[string[]]$ComputerName
)

BEGIN
{
	#Requires -Version 3

	$SizeInGB = @{ Name = "SizeGB"; Expression = { "{0:N2}" -f ($_.Size/1GB) } }
	$FreespaceInGB = @{ Name = "FreespaceGB"; Expression = { "{0:N2}" -f ($_.Freespace/1GB) } }
	$PercentFree = @{ name = "PercentFree"; Expression = { [int](($_.FreeSpace/$_.Size) * 100) } }

	$objResults = @()

}# BEGIN

PROCESS
{
	foreach ($c in $ComputerName)
	{
		Write-Verbose -Message "Working on $c"

		if (Test-Connection -ComputerName $c -Count 2 -Quiet)
		{
			try
			{
				$diskQuery = $null

				$diskQuery = Get-WmiObject -ComputerName $c -Query "SELECT SystemName,Caption,VolumeName,Size,Freespace,DriveType FROM win32_logicaldisk" |
				Where-Object { $_.drivetype -eq '3' } |
				Select-Object SystemName, Caption, VolumeName, $SizeInGB, $FreespaceInGB, $PercentFree

				foreach ($item in $diskQuery)
				{
					$colDiskInfo = @()
					$objDiskInfo = @()

					$objDiskInfo = [PSCustomObject] @{
						SystemName = $item.SystemName
						DriveLetter = $item.Caption
						VolumeName = $item.VolumeName
						SizeGB = $item.SizeGB
						FreeSpaceGB = $item.FreeSpaceGB
						PercentFree = $item.PercentFree
					}# $objDiskInfo

					$colDiskInfo += $objDiskInfo
					$objResults += $colDiskInfo
				}# foreach

			} catch
			{
				Write-Warning -Message "$c - $_"
			}# try/catch

		} else
		{
			Write-Warning -Message "$c - Unreachable via Ping"
		}# if/else
	}# foreach

}# PROCESS

END
{
	$objResults
}# END