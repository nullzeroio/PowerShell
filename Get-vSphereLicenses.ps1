<#
.SYNOPSIS
    Basic script to show current licensing status
.DESCRIPTION
    Basic script to show current licensing status.

	You must be connected to a VI server prior to running this script
.NOTES

    20140904    K. Kirkpatrick      Re-factored script for Github repo

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
        https://github.com/vN3rd/PowerShell-Scripts

#>

#Requires -Version 3

[cmdletbinding()]
param ()

PROCESS
{
	
	try
	{
		$vSphereLicInfo = @()
		$ServiceInstance = Get-View ServiceInstance
		Foreach ($LicenseMan in Get-View ($ServiceInstance | Select-Object -First 1).Content.LicenseManager)
		{
			Foreach ($License in ($LicenseMan | Select-Object -ExpandProperty Licenses))
			{
				$Details = "" | Select-Object VC, Name, Key, Total, Used, ExpirationDate, Information
				$Details.VC = ([Uri]$LicenseMan.Client.ServiceUrl).Host
				$Details.Name = $License.Name
				$Details.Key = $License.LicenseKey
				$Details.Total = $License.Total
				$Details.Used = $License.Used
				$Details.Information = $License.Labels | Select-Object -expand Value
				$Details.ExpirationDate = $License.Properties | Where-Object { $_.key -eq "expirationDate" } | Select-Object -ExpandProperty Value
				$vSphereLicInfo += $Details
			}# end foreach
			
		}# end foreach
	} catch
	{
		Write-Warning -Message "$_"
	}# end try/catch
	
}# end PROCESS

END
{
	$vSphereLicInfo
}