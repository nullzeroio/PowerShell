<#
	.SYNOPSIS
		Get the status of a given service on a given computer or multiple computers
	.DESCRIPTION
		Get the status of a given service on a single or multiple computers.

		The output will return to the console, with only minimal formatting to order the properties.

		Exporting should be used via available Export-* cmdlets.

		The script was written with some more robust error handling that could be useful in an enterprise environment where execution times
		may be longer and an admin needs to know exactly what happened, without having to re-run the script.
	.PARAMETER  ComputerName
		Short name or FQDN of desired computer/server to query
	.PARAMETER ServiceName
		Name of service you wish to query for
	.EXAMPLE
		.\Get-ServiceStatus -ComputerName client01.company.com -ServiceName snmp -Verbose

		Check for the SNMP service and it's associated status
	.EXAMPLE
		.\Get-ServiceStatus -ComputerName client01.company.com,server01.company.com -ServiceName bits -Verbose

		Check for the BITS service and it's associated status
	.EXAMPLE
		.\Get-ServiceStatus -ComputerName (Get-Content C:\ServiceQueryPCList.txt) -ServiceName termservice -Verbose

		Check all computers in the text file for the Remote Desktop Service and it's status
	.EXAMPLE
		.\Get-ServiceStatus -ComputerName (Get-Content C:\ServiceQueryPCList.txt) -ServiceName termservice -Verbose | Export-Csv "C:\ServiceStatusReport.csv" -NoTypeInformation -Encoding UTF8

		Check all computers in the text file for the Remote Desktop Service and it's status and then export that list to a .CSV file
	.INPUTS
		System.String
	.OUTPUTS
		Selected.System.Management.Automation.PSCustomObject
	.NOTES
		Created:	20140908		K. Kirkpatrick
		
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
			   ValueFromPipelineByPropertyName = $true,
			   ParameterSetName = "Default")]
	[alias("comp", "cname")]
	[string[]]$ComputerName = "localhost",
	
	[parameter(Mandatory = $true,
			   Position = 1,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   ParameterSetName = "Default")]
	[alias("svc", "service", "svcname")]
	[string]$ServiceName
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

foreach ($C in $ComputerName)
{
	# Create counter variable and increment by 1 for each item in the collection
	$i++
	
	# Call out variables and set/reset values
	$ServiceQuery = $null
	$ObjCollection = @()
	
	# If connectivity to remote system is successful, continue
	if (Test-Connection $C -Count 2 -Quiet)
	{
		# Begin try/catch block
		try
		{
			Write-Verbose -Message "Running Service Check on $C..."
						
			$ServiceQuery = Get-Service -Name $ServiceName -ComputerName $C -ErrorAction 'SilentlyContinue'
			
			# Create obj for reachable systems
			$SNMPObj = New-Object -TypeName PSObject -Property @{
				SystemName = [string]$C
				ServiceName = $ServiceQuery.Name
				Status = $ServiceQuery.Status
				DisplayName = $ServiceQuery.DisplayName
				Error = if ($ServiceQuery.Name -eq $null) { "The service '$ServiceName' does not appear to exist" }
			}# end $SNMPObj
			
			# Add the results to the $ObjCollection array
			$ObjCollection += $SNMPObj
			
			# Add the contents of the $ObjCollection array to the $Results variable. This may seem redundant
			# but we are clearing the the $ObjCollection variable on each interation through foreach, in order
			# to maintain data integrety. The $Results variable is storing the summation of all interations
			$Results += $ObjCollection
			
			
		} catch
		{
			Write-Warning -Message "$C - $_"
			
			# Create obj for systems that are reachable but incur an error
			$WarnObj = New-Object -TypeName PSObject -Property @{
				SystemName = [string]$C
				Error = $_
			}# end $WarnObj
			
			# See the comment in the first 'try' block for detail on $ObjCollection & $Results variables
			$ObjCollection += $WarnObj
			$Results += $ObjCollection
			
		}# end try/catch
		
	}# end if
	
	else
	{
		Write-Warning -Message "$C is unreachable"
		
		# Create obj for systems that are not reachable
		$DownObj = New-Object -TypeName PSObject -Property @{
			SystemName = [string]$C
			Error = "$C is unreachable"
		}# end $DownObj
		
		# See the comment in the first 'try' block for detail on $ObjCollection & $Results variables
		$ObjCollection += $DownObj
		$Results += $ObjCollection
		
	}# end else
	
	# Write total progress to progress bar
	$TotalServers = $ComputerName.Length
	$PercentComplete = [int](($i / $TotalServers) * 100)
	Write-Progress -Activity "Working..." -CurrentOperation "$PercentComplete% Complete" -Status "Percent Complete" -PercentComplete $PercentComplete
	
}# end foreach

# Call the results and format the order
$Results | Select-Object SystemName, ServiceName, Status, DisplayName, Error
