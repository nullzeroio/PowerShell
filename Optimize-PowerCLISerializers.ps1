<#
.SYNOPSIS
	Pre-compile the PowerCLI XML serializers which helps speed up cmdlet execution
.DESCRIPTION
	Pre-compile the PowerCLI XML serializers which helps speed up cmdlet execution

	This is a very basic script that simply aggregates the commands mentioned in the
	referenced PowerCLI blog post about speeding up the first cmdlet when loading PowerCLI
.EXAMPLE
	.\Optimize-PowerCLISerializers.ps1 -Verbose
.NOTES
	20140914	K. Kirkpatrick		Created

	TAG:PUBLIC

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
.LINK
	http://blogs.vmware.com/PowerCLI/2011/06/how-to-speed-up-the-execution-of-the-first-powercli-cmdlet.html
#>

#Requires -Version 3

[cmdletbinding()]
param ()

PROCESS
{
	try
	{
		Write-Verbose -Message "Compiling Serializers..."

		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe' -ArgumentList { install "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe' -ArgumentList { install "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe' -ArgumentList { install "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe' -ArgumentList { install "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe' -ArgumentList { install "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
		Start-Process -FilePath 'C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe' -ArgumentList { install "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f" }
	} catch
	{
		Write-Warning -Message "$_"
	}
}

END
{
	Write-Verbose -Message "Compilation Complete."
}