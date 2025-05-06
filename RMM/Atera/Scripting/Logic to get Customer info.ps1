#We can see the logic used to get device info using PSAtera the output relevant looks like the below

#FolderName          : Onboarding
#CustomerID          : 24
#CustomerName        : Client Name

$AteraAPIKey = 'xxxxxxxxxxxxx'

#The download location to obtain the AutoElevate MSI file from
$AESetupURI = 'xxxxxxxxxx'

#Your Autoelevate Licence Key
$AELicenseKey = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

#The filename of the MSI which will be downloaded.
$MSIFilename = 'AESetup.msi'

#############################################

#Install and load the right version of Atera
Find-Package -Name 'Nuget' -ForceBootstrap -IncludeDependencies
if (!(Get-Module -ListAvailable PSAtera)) {
Install-Module -Name PSAtera -MinimumVersion 1.3.1 -Force
}
Import-Module -Name PSAtera -MinimumVersion 1.3.1

Set-AteraAPIKey -APIKey $AteraAPIKey

#Get the agent information for the PC that's running the script
$agent = Get-AteraAgent

#Get the value from the Customer endpoint
$AECompanyName = $(Get-AteraCustomer -CustomerID $agent.CustomerID).CustomerName
$AEInitials = -join ($AECompanyName.ToCharArray() | Select-Object -First 2)

#Download AutoElevate Installer to temp path
$AESetupMSI = Join-Path -Path $env:TEMP -ChildPath $MSIFilename
Invoke-WebRequest -Uri $AESetupURI -OutFile $AESetupMSI

(Start-Process "msiexec.exe" -ArgumentList "/i $AESetupMSI /quiet /lv AEInstallLog.log LICENSE_KEY=""$AELicenseKey"" COMPANY_NAME=""$AECompanyName"" COMPANY_INITIALS=""$AEInitials"" LOCATION_NAME=""Automatic"" AGENT_MODE=""audit""" -NoNewWindow -Wait -PassThru).ExitCode
