<#
.SYNOPSIS
	Lists basic Computer/Server information from WMI queries.
.DESCRIPTION
	Lists basic Computer/Server information from WMI queries.

	This script accepts a single computer as input, or multiple computers. If no value is given, 'localhost' us used as the default value.
.PARAMETER  Computer
	Name of computer or server. Preferably, use Fully Qualified Domain Names
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-ComputerInfo.ps1
.EXAMPLE
	.\Get-ComputerInfo.ps1 -Computer compa.something.com
.Example
	.\Get-ComputerInfo.ps1 -Computer compa.company.com,compb.company.com
.Example
	.\Get-ComputerInfo.ps1 -Computer (Get-Content C:\ListOfComputers.txt)
.NOTES


	#TAG:PUBLIC
	
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

.LINK
	https://github.com/vScripter
.LINK
about_WMI
.LINK
about_Wmi_Cmdlets

#>


[CmdletBinding()]
param (
	[Parameter(Position = 0, Mandatory = $false)]
	[System.string[]] $ComputerName = 'localhost'
)

BEGIN {
	#Set-StrictMode -Version Latest
	
	$objFinalResults = @()

} # end BEGIN

PROCESS {
	foreach ($C in $ComputerName) {
		
		$objComputer = @()
		$wmiWin32CompSys = $null
		$wmiWin32OpSys = $null
		$wmiWin32BIOS = $null
		$wmiWin32SysEncl = $null
		$wmiHPQiloVersion = $null
		$wmiHPQiloIPAddress = $null
		$wmiHPQiloHostname = $null
		$wmiHPQiloLicenseKey = $null
		$NBUVersionFilePath = $null
		$NBUVersion = $null
		$ComputerShortName = $null
		$ComputerIPv4 = $null
		$UptimeData = $null
		
		if (Test-Connection $C -Count 2 -Quiet) {
			try {
				Write-Verbose -Message "Working on $C..."
				
				$wmiWin32CompSys = Get-WmiObject -Query "SELECT Caption,Domain,Model FROM win32_computersystem" -ComputerName $C
				$wmiWin32OpSys = Get-WmiObject -Query "SELECT LastBootupTime,Description,Caption,ServicePackMajorVersion FROM Win32_operatingsystem" -ComputerName $C
				$wmiWin32BIOS = Get-WmiObject -Query "SELECT Manufacturer,SerialNumber FROM win32_BIOS" -ComputerName $C
				$wmiWin32SysEncl = Get-WmiObject -Query "SELECT SMBIOSAssetTag FROM win32_SystemEnclosure" -ComputerName $C
				$wmiHPQiloVersion = Get-WmiObject -Query "SELECT Caption FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $C -ErrorAction 'SilentlyContinue'
				$wmiHPQiloIPAddress = Get-WmiObject -Query "SELECT IPAddress FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $C -ErrorAction 'SilentlyContinue'
				$wmiHPQiloHostname = Get-WmiObject -Query "SELECT HostName FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $C -ErrorAction 'SilentlyContinue'
				$wmiHPQiloLicenseKey = Get-WmiObject -Query "SELECT LicenseKey FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $C -ErrorAction 'SilentlyContinue'
				$NBUVersionFilePath = Get-Content "\\$C\c$\Program Files\veritas\netbackup\version.txt" -ErrorAction 'SilentlyContinue'
				$NBUVersion = $NBUVersionFilePath | Out-String
				$ComputerShortName = $wmiWin32CompSys.Caption
				$ComputerIPv4 = Get-WmiObject -Query "SELECT IPEnabled,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder FROM Win32_NetworkAdapterConfiguration" -ComputerName $C | Where-Object { $_.IPEnabled -eq $true }
				$UptimeData = (get-date) - $wmiWin32OpSys.converttodatetime($wmiWin32OpSys.lastbootuptime)
				
				$objComputer = [PSCustomObject] @{
					ComputerName = $ComputerShortName.ToUpper()
					Domain = $wmiWin32CompSys.Domain
					IPAddress = $ComputerIPv4.IPAddress[0]
					SubnetMask = $ComputerIPv4.ipsubnet[0]
					DefaultGateway = $ComputerIPv4.DefaultIPGateway[0]
					PrimaryDNS = $ComputerIPv4.DNSServerSearchOrder[0]
					SecondaryDNS = $ComputerIPv4.DNSServerSearchOrder[1]
					UptimeInDays = $UptimeData.Days
					Model = $wmiWin32CompSys.Model
					Description = $wmiWin32OpSys.Description
					OperatingSystem = $wmiWin32OpSys.Caption
					ServicePack = $wmiWin32OpSys.ServicePackMajorVersion
					Manufacturer = $wmiWin32BIOS.Manufacturer
					SerialNumber = $wmiWin32BIOS.SerialNumber
					AssetTag = $wmiWin32SysEncl.SMBIOSAssetTag
					NetBackupClientVersion = $NBUVersion.split()[6]
					iLOVersion = $wmiHPQiloVersion.Caption
					iLOIPAddress = $wmiHPQiloIPAddress.IPAddress
					iLOHostname = $wmiHPQiloHostname.Hostname
					iLOLicenseKey = $wmiHPQiloLicenseKey.LicenseKey
					Ping = 'Up'
					Error = $null
				} # end $ObjComptuer
				
				$objFinalResults += $objComputer
			} # end try
			
			catch {
				Write-Warning -Message "Error querying WMI on $C : $_"
				
				$objComputer = [PSCustomObject] @{
					ComputerName = $C
					Domain = $null
					IPAddress = $null
					SubnetMask = $null
					DefaultGateway = $null
					PrimaryDNS = $null
					SecondaryDNS = $null
					UptimeInDays = $null
					Model = $null
					Description = $null
					OperatingSystem = $null
					ServicePack = $null
					Manufacturer = $null
					SerialNumber = $null
					AssetTag = $null
					NetBackupClientVersion = $null
					iLOVersion = $null
					iLOIPAddress = $null
					iLOHostname = $null
					iLOLicenseKey = $null
					Ping = 'Up'
					Error = "Error querying WMI : $_"
				} # end $ObjComptuer
				
				$objFinalResults += $objComputer
			} # end catch
		} else {
			Write-Warning -Message "$C is unreachable"
			
			$objComputer = [PSCustomObject] @{
				ComputerName = $C
				Domain = $null
				IPAddress = $null
				SubnetMask = $null
				DefaultGateway = $null
				PrimaryDNS = $null
				SecondaryDNS = $null
				UptimeInDays = $null
				Model = $null
				Description = $null
				OperatingSystem = $null
				ServicePack = $null
				Manufacturer = $null
				SerialNumber = $null
				AssetTag = $null
				NetBackupClientVersion = $null
				iLOVersion = $null
				iLOIPAddress = $null
				iLOHostname = $null
				iLOLicenseKey = $null
				Ping = 'Down'
				Error = 'Unreachable by ICMP (ping)'
			} # end $ObjComptuer
			
			$objFinalResults += $objComputer
			#>
		} # end else
	} # end foreach
	
} # end PROCESS

END {
	$objFinalResults
} # end END
