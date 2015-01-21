<#
.SYNOPSIS
	Collect pre-defined performance counters from a local or remote system.
.DESCRIPTION
	Collect pre-defined performance counters from a local or remote system.

	Pre-Defined counters have been defined and stored in variables, defined in the BEGIN block of this script/function.

	The default counter set is 'Summary' and the default Computer is localhost.

	Optionally, you can supply a number of minutes you want to collect counters using the -RunTimeInMinutes parameter, which will collect
	the counters every 30 seconds, until the number of minutes that you provide expires. A .CSV file is generated and the data is appended 
	to it on each 30 second iteration.
.PARAMETER ComputerName
	Name of remote system (FQDN preferred)
.PARAMETER RunTimeInMinutes
	Number of minutes to query for counters
.PARAMETER ReportPath
	Optionally supply a new path for the .CSV export generated as part of a time period scan
.PARAMETER Counters
	Selecte the desired counter set. Valid options are:
	- Memory
	- Processor
	- LogicalDisk
	- PhysicalDisk
	- Network
	- Processes
	- Summary
.NOTES
	20140925	K. Kirkpatrick		Created


	GitHub:	 https://github.com/vScripter
	Twitter:  @vScripter
	Email:	 kevin@vMotioned.com

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

[cmdletbinding(PositionalBinding = $true)]
param (
	[parameter(Mandatory = $false, Position = 0)]
	[validatescript({ Test-Connection -ComputerName $_ -Count 2 -Quiet })]
	[string]$ComputerName = "$(hostname)",
	
	[parameter(Mandatory = $false, ParameterSetName = "Collection")]
	[int]$RunTimeInMinutes,
	
	[parameter(Mandatory = $false, ParameterSetName = "Collection")]
	[string]$ReportPath = 'C:\DiskIOStats.csv',
	
	[parameter(Mandatory = $false)]
	[ValidateSet("Memory", "Processor", "LogicalDisk", "PhysicalDisk", "Network", "Processes", "Summary")]
	[string]$Counters = "Summary"
)


BEGIN
{
	#Requires -Version 3
	
	Set-StrictMode -Version Latest
		# Setup preferences and variables
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	
	$windowTitle = $host.ui.RawUI.WindowTitle
	
	$TimeStart = Get-Date
	
	$TimeEnd = $timeStart.addminutes($RunTimeInMinutes)
	
	Function logstamp
	{		# function to capture the current time in a custom format	
		$now = Get-Date -Format T
		Write-Output $now
	}# function logstamp
	
	function Get-CounterStats
	{
		[cmdletbinding()]
		param (
			[parameter()]
			[string]$System,
			[parameter()]
			[string[]]$PerfCounters
		)
		
		BEGIN
		{
				# Function that queries counters, based on what is supplied to the function
			if (!($PerfCounters))
			{		# Write a warning if for some reason no value is passed to the $PerfCounters variable
				Write-Warning -Message "A counter was not specified; please specify a counter switch parameter and try again."
				return
			}
		}
		
		PROCESS
		{
			try
			{
					# define the results array
				$Result = @()
					# query for counters and store the results
				$ioQuery = (Get-Counter -ComputerName $System -Counter $PerfCounters -ErrorAction 'SilentlyContinue').countersamples
					# Cycle through each counter and add assign the results to a custom object
				foreach ($sample in $ioQuery)
				{
						# clear the $col array on each cycle through the loop
					$col = @()
					
						# define custom object and properties
					$ioObj = [PSCustomObject] @{
						TimeStamp = "$(logstamp)"
						Counter = $sample.path
						Instance = $sample.InstanceName
						Value = $sample.cookedvalue
					}# end $ioObj
					
						# assign the object to a temporary array
					$col += $ioObj
					
						# assign the data in the temporary array to the final results array
					$result += $col
					
				}# end foreach
			} catch
			{
					# write any errors to the console
				Write-Warning -Message " Error in Get-CounterStats function: $_"
				
			}# try/catch
		}# PROCESS
		
		END
		{
				# sort the order of the results
			$result
			
		}# END
	}# Get-CounterStats
	
	#region Counter Variables
	$summaryCounters = @(
	'\Network Interface(*)\Bytes Total/sec',
	'\Processor(_total)\% Processor Time',
	'\Memory\% Committed Bytes In Use',
	'\memory\cache faults/sec',
	'\PhysicalDisk(_total)\% Disk Time',
	'\physicaldisk(_total)\current disk queue length'
	)
	
	$ramCounters = @(
	'\Memory\% Committed Bytes In Use',
	'\Memory\Available MBytes',
	'\memory\cache faults/sec'
	)
	
	$processCounters = @(
	'\Process(*)\IO Read Operations/sec',
	'\Process(*)\IO Write Operations/sec',
	'\Process(*)\IO Data Operations/sec',
	'\Process(*)\IO Other Operations/sec'
	)
	
	$processorCounters = @(
	'\Processor(*)\% Processor Time',
	'\Processor Performance(*)\% of Maximum Frequency'
	)
	
	$diskLogicalCounters = @(
	'\LogicalDisk(*)\Disk Transfers/sec',
	'\LogicalDisk(*)\Disk Reads/sec',
	'\LogicalDisk(*)\Disk Writes/sec',
	'\LogicalDisk(*)\% Disk Read Time',
	'\LogicalDisk(*)\% Disk Write Time',
	'\LogicalDisk(*)\Disk Bytes/sec',
	'\LogicalDisk(*)\Disk Read Bytes/sec',
	'\LogicalDisk(*)\Disk Write Bytes/sec',
	'\LogicalDisk(*)\Current Disk Queue Length',
	'\LogicalDisk(*)\Avg. Disk Read Queue Length',
	'\LogicalDisk(*)\Avg. Disk Write Queue Length',
	'\LogicalDisk(*)\% Disk Time',
	'\LogicalDisk(*)\% Disk Read Time',
	'\LogicalDisk(*)\% Disk Write Time',
	'\LogicalDisk(*)\Split IO/Sec',
	'\LogicalDisk(*)\Disk Bytes/sec',
	'\LogicalDisk(*)\Avg. Disk Bytes/Read',
	'\LogicalDisk(*)\Avg. Disk Bytes/Write',
	'\LogicalDisk(*)\Disk Read Bytes/sec',
	'\LogicalDisk(*)\Disk Write Bytes/sec'
	)
	
	$diskPhysicalCounters = @(
	'\PhysicalDisk(*)\Disk Transfers/sec',
	'\PhysicalDisk(*)\Disk Reads/sec',
	'\PhysicalDisk(*)\Disk Writes/sec',
	'\PhysicalDisk(*)\% Disk Read Time',
	'\PhysicalDisk(*)\% Disk Write Time',
	'\PhysicalDisk(*)\Disk Bytes/sec',
	'\PhysicalDisk(*)\Disk Read Bytes/sec',
	'\PhysicalDisk(*)\Disk Write Bytes/sec',
	'\PhysicalDisk(*)\Current Disk Queue Length',
	'\PhysicalDisk(*)\Avg. Disk Read Queue Length',
	'\PhysicalDisk(*)\Avg. Disk Write Queue Length',
	'\PhysicalDisk(*)\% Disk Time',
	'\PhysicalDisk(*)\% Disk Read Time',
	'\PhysicalDisk(*)\% Disk Write Time',
	'\PhysicalDisk(*)\Split IO/Sec',
	'\PhysicalDisk(*)\Disk Bytes/sec',
	'\PhysicalDisk(*)\Disk Read Bytes/sec',
	'\PhysicalDisk(*)\Disk Write Bytes/sec',
	'\PhysicalDisk(*)\Avg. Disk Bytes/Read',
	'\PhysicalDisk(*)\Avg. Disk Bytes/Write'
	)
	
	$networkCounters = @(
	'\Network Interface(*)\Bytes Total/sec',
	'\Network Interface(*)\Bytes Received/sec',
	'\Network Interface(*)\Packets Received Discarded',
	'\Network Interface(*)\Packets Received Errors',
	'\Network Interface(*)\Bytes Sent/sec',
	'\Network Interface(*)\Packets Outbound Discarded',
	'\Network Interface(*)\Packets Outbound Errors',
	'\Network Interface(*)\Output Queue Length'
	)
	#endregion Counter Variables
}# BEGIN

PROCESS
{
	try
	{
			# if a run time was specified, execute this script block
		if ($RunTimeInMinutes)
		{
				# set the console window title message
			$host.ui.RawUI.WindowTitle = "Gathering Counter Statistics. Do Not Close Window."
			
				# if the report exists, delete it so no new data is appended to a sheet with old data
			if (Test-Path -Path $ReportPath)
			{
				Write-Warning -Message "Export file exists; removing now..."
				
				Remove-Item $ReportPath -Force | Out-Null
			}# if
			
			Write-Verbose -Message "Collecting counters from $ComputerName..."
			Write-Verbose -Message "The collection will end at $timeEnd"
			
			Do
			{
					# grab the start time that the loop was entered
				$TimeNow = Get-Date
				
				if ($TimeEnd -gt $TimeStart)
				{
						# switch block that reads the string value assigned to the -Counters param and runs the associated counters collection
					switch ($Counters)
					{
						"Memory" {
							Get-CounterStats -System $ComputerName -PerfCounters $ramCounters |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"Processor" {
							Get-CounterStats -System $ComputerName -PerfCounters $processorCounters |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"LogicalDisk" {
							Get-CounterStats -System $ComputerName -PerfCounters $diskLogicalCounters |
							Where-Object { $_.Instance -notlike 'harddiskvolume*' } |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"PhysicalDisk" {
							Get-CounterStats -System $ComputerName -PerfCounters $diskPhysicalCounters |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"Network" { # do some filtering on network devices I don't care about
							Get-CounterStats -System $ComputerName -PerfCounters $networkCounters |
							Where-Object { $_.Instance -notlike 'isatap*' -and $_.Instance -notlike '*virtual wifi*' -and $_.Instance -notlike 'teredo*' } |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"Processes" {
							Get-CounterStats -System $ComputerName -PerfCounters $processCounters |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
						"Summary" { # do some filtering on network devices I don't care about
							Get-CounterStats -System $ComputerName -PerfCounters $summaryCounters |
							Where-Object { $_.Instance -notlike 'isatap*' -and $_.Instance -notlike '*virtual wifi*' -and $_.Instance -notlike 'teredo*' } |
							Export-Csv $ReportPath -Append -NoTypeInformation
						}
					}# switch
					
				}# if
				
					# wait 30 seconds before looping through the funcion, again
				Start-Sleep -Seconds 30
				
			}# Do
			
				# when the current time is past the set end time, stop the collection
			until ($TimeNow -ge $TimeEnd)
			
		} else
		{
				# if no run time value was supplied, simply output to the console
			switch ($Counters)
			{
				"Memory" {
					Get-CounterStats -System $ComputerName -PerfCounters $ramCounters
				}
				"Processor" {
					Get-CounterStats -System $ComputerName -PerfCounters $processorCounters
				}
				"LogicalDisk" {
					Get-CounterStats -System $ComputerName -PerfCounters $diskLogicalCounters |
					Where-Object { $_.Instance -notlike 'harddiskvolume*' }
				}
				"PhysicalDisk" {
					Get-CounterStats -System $ComputerName -PerfCounters $diskPhysicalCounters
				}
				"Network" { # do some filtering on network devices I don't care about
					Get-CounterStats -System $ComputerName -PerfCounters $networkCounters |
					Where-Object { $_.Instance -notlike 'isatap*' -and $_.Instance -notlike '*virtual wifi*' -and $_.Instance -notlike 'teredo*' }
				}
				"Processes" {
					Get-CounterStats -System $ComputerName -PerfCounters $processCounters
				}
				"Summary" { # do some filtering on network devices I don't care about
					Get-CounterStats -System $ComputerName -PerfCounters $summaryCounters |
					Where-Object { $_.Instance -notlike 'isatap*' -and $_.Instance -notlike '*virtual wifi*' -and $_.Instance -notlike 'teredo*' }
				}
			}# switch 
			
		}# if/else
	} catch
	{
		Write-Warning -Message "$_"
	}# try/catch
	
}# PROCESS

END
{
	Write-Verbose -Message "Script Execution Complete..."
	
	$host.ui.RawUI.WindowTitle = $windowTitle
}# END
