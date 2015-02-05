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
	20150204	K. Kirkpatrick
	[+] Removed redundant array that stored all obj data until the end; objects now get thrown straight to the pipeline
	[+] Change default value of -ComputerName param from 'localhost' to "$ENV:COMPUTERNAME"
	[+] Renamed $c variable to $computer
	[+] Misc. syntax cleanup

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
	[Parameter(Position = 0,
			   Mandatory = $false)]
	[System.string[]] $ComputerName = "$ENV:COMPUTERNAME"
)

BEGIN {
	
	Set-StrictMode -Version Latest	
	
} # end BEGIN block

PROCESS {
	
	foreach ($computer in $ComputerName) {
		
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
		
		if (Test-Connection $computer -Count 2 -Quiet) {
			try {
				Write-Verbose -Message "Working on $computer..."
				
				$wmiWin32CompSys = Get-WmiObject -Query "SELECT Name,Domain,Model FROM win32_computersystem" -ComputerName $computer
				$wmiWin32OpSys = Get-WmiObject -Query "SELECT LastBootupTime,Description,Caption,ServicePackMajorVersion FROM Win32_operatingsystem" -ComputerName $computer
				$wmiWin32BIOS = Get-WmiObject -Query "SELECT Manufacturer,SerialNumber FROM win32_BIOS" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$wmiWin32SysEncl = Get-WmiObject -Query "SELECT SMBIOSAssetTag FROM win32_SystemEnclosure" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$wmiHPQiloVersion = Get-WmiObject -Query "SELECT Caption FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$wmiHPQiloIPAddress = Get-WmiObject -Query "SELECT IPAddress FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$wmiHPQiloHostname = Get-WmiObject -Query "SELECT HostName FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$wmiHPQiloLicenseKey = Get-WmiObject -Query "SELECT LicenseKey FROM HP_ManagementProcessor" -Namespace "root\HPQ" -ComputerName $computer -ErrorAction 'SilentlyContinue'
				$NBUVersionFilePath = Get-Content "\\$computer\c$\Program Files\veritas\netbackup\version.txt" -ErrorAction 'SilentlyContinue'
				if ($NBUVersionFilePath) {
					$NBUVersion = $NBUVersionFilePath | Out-String
					$NBUVersion = $NBUVersion.split()[6]
				} else {
					$NBUVersion = 'N/A'
				} # end if/else $NBUVersionFilePath
				$ComputerShortName = $wmiWin32CompSys.Name
				$ComputerIPv4 = Get-WmiObject -Query "SELECT IPEnabled,IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder FROM Win32_NetworkAdapterConfiguration" -ComputerName $computer | Where-Object { $_.IPEnabled -eq $true }
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
					NetBackupClientVersion = $NBUVersion
					iLOVersion = if ($wmiHPQiloVersion) { $wmiHPQiloVersion.Caption } else { 'N/A' }
					iLOIPAddress = if ($wmiHPQiloIPAddress) { $wmiHPQiloIPAddress.IPAddress } else { 'N/A' }
					iLOHostname = if ($wmiHPQiloHostname) { $wmiHPQiloHostname.Hostname } else { 'N/A' }
					iLOLicenseKey = if ($wmiHPQiloLicenseKey) { $wmiHPQiloLicenseKey.LicenseKey } else { 'N/A' }
					Ping = 'Up'
					Error = $null
				} # end $ObjComptuer
				
				$objComputer
			} # end try
			
			catch {
				Write-Warning -Message "Error querying WMI on $computer : $_"
				
				$objComputer = [PSCustomObject] @{
					ComputerName = $computer
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
				
				$objComputer
			} # end catch
		} else {
			Write-Warning -Message "$computer is unreachable"
			
			$objComputer = [PSCustomObject] @{
				ComputerName = $computer
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
			
			$objComputer			
		} # end else
	} # end foreach
	
} # end PROCESS

END {
	
} # end END
