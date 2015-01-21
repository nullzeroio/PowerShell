<#
.SYNOPSIS
	Return detailed status report of NetApp Aggregates
.DESCRIPTION
	Return detailed status report of NetApp Aggregates

	This scipt/function was meant to expand the default output of Get-NaAggr to include additional detail about NetApp Aggregates.

	It also was meant to provide an easier means to gather aggr details from multiple controllers and provide simplistic error handling.

	This script was developed against systems running 7-Mode.
.PARAMETER Controller
	Name of NetApp Filer/Controller/s
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-NAAggrDetail.ps1 -Controller NETAPP01 -Verbose | Format-Table -AutoSize -Property *
.EXAMPLE
	.\Get-NAAggrDetail.ps1 -Controller NETAPP01,NETAPP02 -Verbose | Out-GridView
.EXAMPLE
	.\Get-NAAggrDetail.ps1 -Controller (Get-Content C:\NetAppFilerList.txt) -Verbose | Export-Csv C:\NetApp_Aggr_Report.csv -NoTypeInformation
.NOTES
	20141121	K. Kirkpatrick		Created

	#TAG:PUBLIC
#>

#Requires -Version 3
#Requires -Module DataONTAP

[cmdletbinding(PositionalBinding = $true)]
param (
	[parameter(Mandatory = $true,
			   Position = 0,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[alias('Filer')]
	[string[]]$Controller
)

BEGIN
{
	Set-StrictMode -Version Latest
	# force all errors to be terminating for better error handling in try/catch blocks
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	# set/assign final results array
	$colFinalResults = @()

	# define custom hash tables
	$totalSize = @{ Label = 'TotalSize'; Expression = { ConvertTo-FormattedNumber $_.SizeTotal DataSize "0.0" } }
	$available = @{ Label = 'AvailableSpace'; Expression = { ConvertTo-FormattedNumber $_.SizeAvailable DataSize "0.0" } }
	$used = @{ Label = 'PercentUsed'; Expression = { ConvertTo-FormattedNumber $_.SizePercentageUsed Percent } }

}# BEGIN

PROCESS
{
	foreach ($system in $Controller)
	{
		Write-Verbose -Message "Working on $($system.toupper())"

		if (Test-Connection -ComputerName $system -Count 2 -Quiet)
		{
			try
			{
				# set/clear variables on each interation
				$aggrQuery = $null
				$versionQuery = $null
				$ontapSupported = $null
				$connectController = $null


				# turn off verbose messages while DataONTAP commands are running to keep the console messages clean if -Verbose is specified
				$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

				# query for the volume details
				$aggrQuery = Get-NAAggr -Controller (Connect-NaController $system) |
				Select-Object Name, State, $totalSize, $used, $available, Disks, RaidType, MirrorStatus

				# interate through each volume
				foreach ($aggregate in $aggrQuery)
				{

					# set/clear on each interation
					$colVol = @()
					$objVol = @()

					# create custom obj to store data
					$objAggr = [PSCustomObject] @{
						Controller = $(($global:CurrentNaController.name.toupper()))
						AggrName = $aggregate.Name
						PercentUsed = $aggregate.PercentUsed
						TotalSize = $aggregate.TotalSize
						Available = $aggregate.AvailableSpace
						DiskCount = $aggregate.Disks
						RaidType = $aggregate.RaidType
						MirrorStatus = $aggregate.MirrorStatus
					}# $objAggr

					# store obj results in final array
					$colFinalResults += $objAggr

				}# foreach

				# turn verbose messages back on
				$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue

			} catch
			{
				Write-Warning -Message "$system - $_"
			}# try/catch

		} else
		{
			Write-Warning -Message "$system - Unreachable"
		}# if/else
	}# foreach
}# PROCESS

END
{
	$colFinalResults

	Write-Verbose -Message "Done"
}# END
