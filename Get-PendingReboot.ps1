<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.
.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from either Microsoft Patching or a Software Installation.
    For Windows 2008+ the function will query the CBS registry key as another factor in determining
    pending reboot state.  "PendingFileRenameOperations" and "Auto Update\RebootRequired" are observed
    as being consistant across Windows Server 2003 & 2008.

    CBServicing = Component Based Servicing (Windows 2008)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003 / 2008)
    PendFileRename = PendingFileRenameOperations (Windows 2003 / 2008)
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).
.PARAMETER ErrorLog
    A single path to send error data to a log file.
.EXAMPLE
    .\Get-PendingReboot.ps1 -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize

    Computer CBServicing WindowsUpdate PendFileRename  RebootPending
    -------- ----------- ------------- --------------  -------------
    DC01           False         False  		False          False
    DC02           False         False          False          False
    FS01           False         False          False          False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design
.EXAMPLE
    .\Get-PendingReboot.ps1

    Computer       : WKS01
    CBServicing    : False
    WindowsUpdate  : True
    PendFileRename : False
    RebootPending  : True

    This example will query the local machine for pending reboot information.
.EXAMPLE
    $Servers = Get-Content C:\Servers.txt
    C:\PS>.\Get-PendingReboot.ps1 -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation

    This example will create a report that contains pending reboot information.
.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx

    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx


.NOTES
    Author:  Kevin Kirkpatrick
    Date:    01/30/2015
    PSVer:   2.0/3.0/4.0
    Updated: 02/10/2015
    Update Notes:
        [+] Fixed an issue that wasn't properly checking 'Pending Filename Rename Operation'
        [+] Renamed most of the variabled
        [+] Updated some syntax formatting
        [-] Removed logging parameter and associated log options

	#TAG:PUBLIC

			GitHub: https://github.com/vScripter
			Twitter: @vScripter
			Email: kevin@vmotioned.com
			Blog: www.vMotioned.com

	[-------------------------------------DISCLAIMER-------------------------------------]
	 All script are provided as-is with no implicit
	 warranty or support. It's always considered a best practice
	 to test scripts in a DEV/TEST environment, before running them
	 in production. In other words, I will not be held accountable
	 if one of my scripts is responsible for an RGE (Resume Generating Event).
	 If you have questions or issues, please reach out/report them on
	 my GitHub page. Thanks for your support!
	[-------------------------------------DISCLAIMER-------------------------------------]


	Original Author
	--------------------------
    Author:  Brian Wilhite
    Email:   bwilhite1@carolina.rr.com
    Date:    08/29/2012
    PSVer:   2.0/3.0
    Updated: 05/30/2013
    UpdNote:
#>

[CmdletBinding(PositionalBinding = $true)]
param (
	[Parameter(Position = 0,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[Alias('CN', 'Computer')]
	[String[]]$ComputerName = "$env:COMPUTERNAME"
)

BEGIN {

	<# Adjusting ErrorActionPreference to stop on all errors, since using [Microsoft.Win32.RegistryKey]
	 does not have a native ErrorAction Parameter, this may need to be changed if used within another
	 function. #>
	$defaultEAPref = $ErrorActionPreference
	$ErrorActionPreference = 'Stop'

} # end BEGIN block

PROCESS {

	foreach ($computer in $ComputerName) {

		try {

			# Setting pending values to false to cut down on the number of else statements
			[bool]$pendingFileRename = $false
			[bool]$pending = $false

			# Setting cbsRebootPending to null since not all versions of Windows has this value
			$cbsRebootPending = $null

			# Querying WMI for build version
			$wmiWin32Os = Get-WmiObject -ComputerName $computer -Query 'SELECT BuildNumber,CSName FROM win32_OperatingSystem'

			# Making registry connection to the local/remote computer
			$regConnection = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]'LocalMachine', $computer)

			# If Vista/2008 & Above query the CBS Reg Key
			if ($wmiWin32Os.BuildNumber -ge 6001) {

				$regCbsSubkey = $regConnection.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\').GetSubKeyNames()
				$cbsRebootPending = $regCbsSubkey -contains 'RebootPending'

			} #End if $wmiWin32Os.BuildNumber

			# Query WUAU from the registry
			$regWindowsUpdate = $regConnection.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
			$regWindowsUpdateKeys = $regWindowsUpdate.GetSubKeyNames()
			$windowsUpdateRebootPending = $regWindowsUpdateKeys -contains 'RebootRequired'

			# Query PendingFileRenameOperations from the registry
			$regPendingFileRename = $regConnection.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\')
			$regPFROQuery = $regPendingFileRename.GetValue('PendingFileRenameOperations', $null)
			$regPFROValue = $regPFROQuery | Out-String

			# Closing registry connection
			$regConnection.Close()

			# if any of the variables are true, set $Pending variable to $true
			if ($cbsRebootPending -or $windowsUpdateRebootPending -or $pendingFileRename) {

				$pending = $true

			} # end if

			$objPendingReboot = [PSCustomObject] @{
				Computer = $wmiWin32Os.CSName
				CBServicing = $cbsRebootPending
				WindowsUpdate = $windowsUpdateRebootPending
				PendFileRename = $pendingFileRename
				RebootPending = $pending
			} # end $objPendingReboot

			$objPendingReboot

		} #End Try

		Catch {

			Write-Warning "[$computer][ERROR] $_"

		} # End Catch

	} # End Foreach ($Computer in $ComputerName)

} # End PROCESS

END {
	# Resetting ErrorActionPref
	$ErrorActionPreference = $defaultEAPref
} # End END block