<#
.SYNOPSIS
This script will saturate a specified number of CPU cores to 100% utilization. 
.DESCRIPTION
This script will saturate a specified number of CPU cores to 100% utilization.

The parameter 'NumHyperCores' is required and you need to specify, at minimum,
the total number of cores on the computer/server you wish to test. If hyper-threading is enabled
you need to ensure that you select the proper number or total saturation will not occur.
Selecting a higher number of cores can further ensure total saturation occurs. Once executed,
it will prompt you to hit 'Y' to confirm that you want to run the script.

The maximum supported value for the 'NumHyperCores' parameter is 2147483647, which is the highest value
allowed by int32.
.PARAMETER <NumHyperCores>

.INPUTS
None.
.EXAMPLE
.\Invoke-CPUStressTest.ps1 -NumHyperCores 4

This will execute the script against 4 cores. In this case, it may be a 2-core CPU with hyper-threading enabled. 

#>

[cmdletbinding()]
param(
[parameter(mandatory=$true)]
[int]$NumHyperCores
)

$Log = "C:\CPUStressTest.ps1.log"
$StartDate = Get-Date
Write-Output "============= CPU Stress Test Started: $StartDate =============" >> $Log
Write-Output "Started By: $env:username" >> $Log
Write-Warning "This script will potentially saturate CPU utilization!"
$Prompt = Read-Host "Are you sure you want to proceed? (Y/N)"

if ($Prompt -eq 'Y')
{
	Write-Warning "To cancel execution of all jobs, close the PowerShell Host Window."
	Write-Output "Hyper Core Count: $NumHyperCores" >> $Log
	
foreach ($loopnumber in 1..$NumHyperCores){
    Start-Job -ScriptBlock{
    $result = 1
        foreach ($number in 1..2147483647){
            $result = $result * $number
        }# end foreach 
    }# end Start-Job
}# end foreach

Wait-Job *
Clear-Host
Receive-Job *
Remove-Job *
}# end if

else{
	Write-Output "Cancelled!"
}

$EndDate = Get-Date
Write-Output "============= CPU Stress Test Complete: $EndDate =============" >> $Log