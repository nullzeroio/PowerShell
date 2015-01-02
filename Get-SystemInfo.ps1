<#
.SYNOPSIS
	Run systeminfo.exe against a computer specified in the -ComputerName parameter
.DESCRIPTION
	systeminfo.exe will run against the desired computer and the output will be piped to the Out-Notepad function and displayed in a temporary .txt file.

	The Out-Notepad function was written by Jeff Hicks (see function help for details)
.INPUTS
	System.String
.OUTPUTS
	Temp .txt file with output
.PARAMETER ComputerName
.EXAMPLE
	Get-SystemInfo -ComputerName SERVER1.corp.com
.NOTES
	20141230	K. Kirkpatrick
	[+] Created

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

.LINK
	https://github.com/vN3rd
#>

#Requires -Version 3

[cmdletbinding(PositionalBinding = $true)]
param (
	[parameter(Mandatory = $false,
			   Position = 0,
			   ValueFromPipeline = $false,
			   ValueFromPipelineByPropertyName = $false)]
	[alias('CN')]
	[validatescript({ Test-Connection -ComputerName $_ -Count 1 -Quiet })]
	[string]$ComputerName = 'localhost'
)

BEGIN {
	
	Function Out-Notepad {
		<#
		.SYNOPSIS
  			Pipe PowerShell output to a temp file and open the file in Notepad
		.DESCRIPTION
  			This function creates a temporary file from pipelined input and opens it in Notepad.exe.
	
			The temp file will be deleted after closing the text editor. If you want to
  			save the OUTPUT you'll need to give it a new name.
		.PARAMETER InputObject
  			Any pipelined input
		.EXAMPLE
  			PS C:\> ps | out-notepad

  			Take the output from Get-Process and send it to Notepad.
		.INPUTS
  			Accepts pipelined input
		.OUTPUTS
  			None
		.LINK
  			Out-File
  			Out-Printer
  			OUt-GridView
		.NOTES
  			NAME:      Out-Notepad
  			VERSION:   2.0
  			AUTHOR:    Jeffery Hicks http://jdhitsolutions.com/blog
  			LASTEDIT:  10/7/2009
		#>
		
		[CmdletBinding()]		
		param (
			[Parameter(ValueFromPipeline = $True,
					   Position = 0, Mandatory = $True,
					   HelpMessage = "Pipelined input.")]
			[object[]]$InputObject
		)
		
		BEGIN {
			
			$Editor = 'notepad.exe'
			
			Write-Debug "Beginning"
			Write-Verbose "Beginning"
			
			#get a temporary filename
			Write-Debug "Getting the temp filename"
			Write-Verbose "Getting the temp filename"
			$tempfile = [System.IO.Path]::GetTempFileName()
			
			Write-Debug "Temp filename is $tempfile"
			Write-Verbose "Temp filename is $tempfile"
			
			#initialize a placeholder array
			$data = @()
		} #end Begin scriptblock
		
		PROCESS {
			#save incoming objects to a variable
			if ($InputObject) {
				$data += $InputObject
			} else {
				$data += $_
			}
		} #end Process scriptblock
		
		END {
			
			Write-Debug "Writing data to $tempfile"
			Write-Verbose "Writing data to $tempfile"
			#write data to the temp file
			$data | Out-File $tempfile
			
			#open the tempfile with the specified editor and monitor the process
			Write-Debug "Opening $tempfile with $editor"
			Write-Verbose "Opening $tempfile with $editor"
			
			#wait for the editor to close because it may have a lock on the file
			#once closed the temp file can then be deleted.
			
			Start-Process $Editor $tempfile -wait
			
			#sleep for 3 seconds before continuing on with the script. Some editors like
			#Write.exe will actually launch another process, wordpad.exe, in which case
			#command will return to the script almost immediately, deleting the temp file
			#before the editor has had a chance to open it.
			Write-Verbose "Sleeping for 3 seconds"
			Start-Sleep -Seconds 3
			
			
			#Delete the temp file. It should still exist but we'll use an IF statement just to be neat about it.
			
			if (Test-Path $tempfile) {
				Write-Debug "Deleting $tempfile"
				Write-Verbose "Deleting $tempfile"
				
				Remove-Item $tempfile
			}
			
			Write-Debug "Exiting"
			Write-Verbose "Exiting"
		} #end End scriptblock
	} #end Function Out-Notepad
	
} # end BEGIN

PROCESS {
	
	systeminfo.exe /S $ComputerName /FO LIST | Out-Notepad
	
} # end PROCESS

END {
	# Cleanup work
} # end END

