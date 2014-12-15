<#
.SYNOPSIS
	Search a computer/s for the install status of a particular Microsoft HotFix (Patch)
.DESCRIPTION
	Search a computer/s for the install status of a particular Microsoft HotFix (Patch)

	You must supply the patch name in the format of KBxxxxxxx (EX: KB3011780)
.PARAMETER ComputerName
	Name of computer / computers
.PARAMETER HotFixID
	Name of HotFix to search for
.PARAMETER MostRecent
	Use this switch param to identify what the last patch installed was and when it was installed
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-WindowsPatch.ps1 -ComputerName SERVER1.corp.com, SERVER2.corp.com -PatchID KB3011780 -Verbose | Format-Table -Autosize
.EXAMPLE
	.\Get-WindowsPatch.ps1 -ComputerName SERVER1.corp.com -PatchID KB3011780 -Verbose
.EXAMPLE
	.\Get-WindowsPatch.ps1 -ComputerName SERVER1.corp.com, SERVER2.corp.com -PatchID KB3011780 -Verbose | Out-GridView
.EXAMPLE
	.\Get-WindowsPatch.ps1 -ComputerName (Get-Content C:\ServerList.txt) -PatchID KB3011780 -Verbose | Export-Csv C:\ServerPatchReport.csv -NoTypeInformation
.NOTES
	20141119	K. Kirkpatrick
		[+] Added ValidatePattern REGEX
	20141124	K. Kirkpatrick
		[+] Cleaned up the way objects get stored to final $Results array
		[+] Added -MostRecent switch variable which will return the most recent installed patch
	20141125	K. Kirkpatrick
		[+] Renamed from Get-HotFixStatus to Get-Patch
		[+] Renamed -HotFixID to -PatchID
		[+] Renamed variables and properties that used 'HotFix' to 'Patch'
		[+] Added SystemUptimeDays to report uptime (Days)
	20141126	K. Kirkpatrick
		[+] Changed spacing
	20141211	K. Kirkpatrick
		[+] minor change to comments and spacing
		[+] Renamed UptimeInDays to SystemUptimeDays

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

[cmdletbinding(DefaultParameterSetName = "Default")]
param (
	[parameter(Mandatory = $false,
			   Position = 0,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[alias("Comp", "CN")]
	[string[]]$ComputerName = "localhost",

	[parameter(Mandatory = $true,
			   Position = 1,
			   ValueFromPipeline = $false,
			   ValueFromPipelineByPropertyName = $false,
			   HelpMessage = "Enter full patch (HotFix) ID (ex: KB1234567) ",
			   ParameterSetName = "Default")]
	[alias("HotFix", "Patch")]
	[validatepattern('^KB\d{7}$')]
	[string]$PatchID,

	[parameter(Mandatory = $false,
			   ParameterSetName = "MostRecent")]
	[switch]$MostRecent
)

BEGIN {
	<#
	- Set global EA pref so that all errors are treated as terminating errors and get caught in the 'catch' block
	- Define variables
	- Define array of properties to pull from Get-HotFix command
	#>

	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

	$Results = @()

	$patchProperties = @(
	"CSName",
	"Description",
	"HotFixID",
	"InstalledOn",
	"InstalledBy",
	"Caption")
}# BEGIN

PROCESS {
	foreach ($C in $ComputerName) {
		<#
		- Increment by 1 for each item in the collection
		- Call out variables and set/reset values
		- If the system respons to ping, continue
		#>

		$i++

		$patchQuery = $null
		$objPatch = @()
		$uptimeQuery = $null
		$calcUptime = $null
		$uptime = $null

		if (Test-Connection $C -Count 2 -Quiet) {
			try {
				$uptimeQuery = Get-WmiObject -ComputerName $C -Class Win32_OperatingSystem -Property LastBootUpTime
				$calcUptime = (Get-Date) - ($uptimeQuery.converttodatetime($uptimeQuery.LastBootUpTime))
				$uptime = $calcUptime.Days
			} catch {
				<#
				- Store data in obj for systems that are reachable but incur an error
				- add data (obj) to finalResults array
				#>

				$objPatch = [PSCustomObject] @{
					ComputerName = $C.ToUpper()
					Description = $null
					PatchID = $null
					InstalledBy = $null
					InstalledOn = $null
					Link = $null
					SystemUptimeDays = $null
					Error = "Uptime Query Error: $_ "
				}# objPatch

				$Results += $objPatch

			}# try/catch

			if ($MostRecent) {
				try {
					Write-Verbose -Message "Searching for most recent patch on $($C.toupper())"

					$patchQuery = (Get-HotFix -ComputerName $C -ErrorAction 'SilentlyContinue' |
					Select-Object $patchProperties |
					Where-Object { $_.InstalledOn -ne $null } |
					Sort-Object InstalledOn -Descending)[0]

					$objPatch = [PSCustomObject] @{
						ComputerName = $C.ToUpper()
						Description = $patchQuery.Description
						PatchID = $patchQuery.HotFixID
						InstalledBy = $patchQuery.InstalledBy
						InstalledOn = $patchQuery.InstalledOn
						Link = $patchQuery.Caption
						SystemUptimeDays = if ($uptime -ne $null) { $uptime } else { $null }
						Error = if ($patchQuery.HotFixID -eq $null) { "System reachable but errors may have been encountered collecting patch details" }
					}# $objSvc

					$Results += $objPatch
				} catch {
					Write-Warning -Message "$C - $_"

					$objPatch = [PSCustomObject] @{
						ComputerName = $C.ToUpper()
						Description = $null
						PatchID = $null
						InstalledBy = $null
						InstalledOn = $null
						Link = $null
						SystemUptimeDays = $null
						Error = "Recent Patch Query Error: $_"
					}# objPatch

					$Results += $objPatch
				}# try/catch
			} else {
				try {
					Write-Verbose -Message "Searching for patch $($PatchID.toupper()) on $($C.toupper())"

					$patchQuery = Get-HotFix -Id $PatchID -ComputerName $C -ErrorAction 'SilentlyContinue' |
					Select-Object $patchProperties |
					Where-Object { $_.HotFixID -ne 'File 1' }

					$objPatch = [PSCustomObject] @{
						ComputerName = $C.ToUpper()
						Description = $patchQuery.Description
						PatchID = $patchQuery.HotFixID
						InstalledBy = $patchQuery.InstalledBy
						InstalledOn = $patchQuery.InstalledOn
						Link = $patchQuery.Caption
						SystemUptimeDays = if ($uptime -ne $null) { $uptime } else { $null }
						Error = if ($patchQuery.HotFixID -eq $null) { "Patch $($PatchID.toupper()) does not appear to be installed" }
					}# $objSvc

					$Results += $objPatch
				} catch {
					Write-Warning -Message "$C - $_"

					$objPatch = [PSCustomObject] @{
						ComputerName = $C.ToUpper()
						Description = $null
						PatchID = $null
						InstalledBy = $null
						InstalledOn = $null
						Link = $null
						SystemUptimeDays = $null
						Error = "Patch Query Error: $_"
					}# objPatch

					$Results += $objPatch
				}# try/catch
			}# if/else
		} else {
			Write-Warning -Message "$C is unreachable"

			$objPatch = [PSCustomObject] @{
				ComputerName = $C.ToUpper()
				Description = $null
				PatchID = $null
				InstalledBy = $null
				InstalledOn = $null
				Link = $null
				SystemUptimeDays = $null
				Error = "$C is unreachable"
			}# $objPatch

			$Results += $objPatch
		}# else

		# Write total progress to progress bar
		$TotalServers = $ComputerName.Length
		$PercentComplete = [int](($i / $TotalServers) * 100)
		Write-Progress -Activity "Working..." -CurrentOperation "$PercentComplete% Complete" -Status "Percent Complete" -PercentComplete $PercentComplete
	}# foreach
}# PROCESS

END {
	$Results
}# END