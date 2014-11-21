<#
.SYNOPSIS
	Return detailed status report of NetApp volumes
.DESCRIPTION
	Return detailed status report of NetApp volumes

	This scipt/function was meant to expand the default output of Get-NaVol to include additional detail about NetApp volumes.

	It also was meant to provide an easier means to gather vol details from multiple controllers and provide simplistic error handling.

	NOTE: Any system running DataONTAP older than 8.2, will return "N/A" for some fields due lack of API support.

	This script was developed against systems running 7-Mode.

	When using "| Format-Table", note that by default only 10 properties will be returned, by default. You need to do: "| Format-Table -Property *" to get them all (see example)
.PARAMETER Controller
	Name of NetApp Filer/Controller/s
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-NAVolDetail.ps1 -Controller NETAPP01 -Verbose | Format-Table -AutoSize -Property *
.EXAMPLE
	.\Get-NAVolDetail.ps1 -Controller NETAPP01,NETAPP02 -Verbose | Out-GridView
.EXAMPLE
	.\Get-NAVolDetail.ps1 -Controller (Get-Content C:\NetAppFilerList.txt) -Verbose | Export-Csv C:\NetApp_Vol_Report.csv -NoTypeInformation
.EXAMPLE
	.\Get-NAVolDetail.ps1 -Controller NETAPP01
	
## Output from ONTAP verions < 8.2 ##

Controller            : NETAPP01
VolName               : netapp01_nfs1
PercentUsed           : 21%
TotalSize             : 1.0 TB
Available             : 812.4 GB
VolState              : online
Dedupe                : True
TotalFootPrint        : N/A
VolDataFootPrint      : N/A
VolGuaranteeFootPrint : N/A
FilesUsed             : 370
FilesTotal            : 32M
vFiler                : vfiler0
Aggr                  : LEWNA01_NFS01
AggrSize              : N/A

## Output from ONTAP verions > 8.2 ##

Controller            : NETAPP01
VolName               : cifs_p_data
PercentUsed           : 71%
TotalSize             : 4.8 TB
Available             : 1.4 TB
VolState              : online
Dedupe                : True
TotalFootPrint        : 4 TB
VolDataFootPrint      : 4 TB
VolGuaranteeFootPrint : 0
FilesUsed             : 16M
FilesTotal            : 32M
vFiler                : cifsvf1
Aggr                  : aggr1
AggrSize              : 22 TB

.NOTES
	20141121	K. Kirkpatrick		Created

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
	$used = @{ Label = 'PercentUsed'; Expression = { ConvertTo-FormattedNumber $_.PercentageUsed Percent } }
	$filesUsed = @{ Label = 'FilesUsed'; Expression = { ConvertTo-FormattedNumber $_.FilesUsed } }
	$filesTotal = @{ Label = 'FilesTotal'; Expression = { ConvertTo-FormattedNumber $_.FilesTotal } }
	$totalFootprint = @{ Label = 'TotalFootPrint'; Expression = { ConvertTo-FormattedNumber $_.TotalFootprint DataSize } }
	$volumeDataFootPrint = @{ Label = 'VolDataFootPrint'; Expression = { ConvertTo-FormattedNumber $_.VolumeDataFootprint DataSize } }
	$flexVolMetaDataFootPrint = @{ Label = 'FlexvolMetadataFootprint'; Expression = { ConvertTo-FormattedNumber $_.FlexvolMetadataFootprint DataSize } }
	$aggregateSize = @{ Label = 'AggregateSize'; Expression = { ConvertTo-FormattedNumber $_.AggregateSize DataSize } }

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
				$volQuery = $null
				$versionQuery = $null
				$ontapSupported = $null
				$connectController = $null


				# turn off verbose messages while DataONTAP commands are running to keep the console messages clean if -Verbose is specified
				$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

				# query for the volume details
				$volQuery = Get-NAVol -Controller (Connect-NaController $system) |
				Select-Object OwningVfiler, Name, State, $totalSize, $used, $available, Dedupe, $filesUsed, $filesTotal, ContainingAggregate

				# Grab the version of Data ONTAP; versions older than 8.2 do not support the 'volume-footprint-list-info-iter-start' API; assign a boolean value for later use
				if ($(Get-NaSystemVersion -Controller (Connect-NaController $system)) -like '*8.2*')
				{
					$ontapSupported = $true
				} else
				{
					$ontapSupported = $false
				}# if/else

				# interate through each volume
				foreach ($vol in $volQuery)
				{

					# set/clear on each interation
					$colVol = @()
					$objVol = @()

					# create custom obj to store data
					$objVol = [PSCustomObject] @{
						Controller = $(($global:CurrentNaController.name.toupper()))
						VolName = $vol.Name
						PercentUsed = $vol.PercentUsed
						TotalSize = $vol.TotalSize
						Available = $vol.AvailableSpace
						VolState = $vol.State
						Dedupe = $vol.Dedupe
						TotalFootPrint = if ($ontapSupported)
						{
							$(ConvertTo-FormattedNumber -Value $((Get-NaVolFootprint -Controller (Connect-NaController $system) -Name $($vol.name)).TotalFootPrint) -Type DataSize)
						} else
						{
							"N/A"
						}
						VolDataFootPrint = if ($ontapSupported)
						{
							$(ConvertTo-FormattedNumber -Value $((Get-NaVolFootprint -Controller (Connect-NaController $system) -Name $($vol.name)).VolumeDataFootPrint) -Type DataSize)
						} else
						{
							"N/A"
						}
						VolGuaranteeFootPrint = if ($ontapSupported)
						{
							$(ConvertTo-FormattedNumber -Value $((Get-NaVolFootprint -Controller (Connect-NaController $system) -Name $($vol.name)).VolumeGuaranteeFootPrint) -Type DataSize)
						} else
						{
							"N/A"
						}
						FilesUsed = $vol.FilesUsed
						FilesTotal = $vol.FilesTotal
						vFiler = $vol.OwningvFiler
						Aggr = $vol.ContainingAggregate
						AggrSize = if ($ontapSupported)
						{
							$(ConvertTo-FormattedNumber -Value $((Get-NaVolFootprint -Controller (Connect-NaController $system) -Name $($vol.name)).AggregateSize) -Type DataSize)
						} else
						{
							"N/A"
						}
					}# $objVol

					# store obj results in final array
					$colFinalResults += $objVol

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
