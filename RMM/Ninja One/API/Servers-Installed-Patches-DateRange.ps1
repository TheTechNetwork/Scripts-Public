#The API Creds and permissions required are 
#APP Platform = Web
#Redirect URI = https://localhost
#Scopes = Monitoring
#Allowed Grant Types = Client Credentials

#This script reports on all patches installed on Windows Servers in a particular organization
#It reports on the previous year patch scans and installations
#For example the dates now will give us from 01/01/2023 to 12/31/2023.
 
# API authentication
$body = @{
grant_type = "client_credentials"
client_id = ""
client_secret = ""
redirect_uri = "https://localhost"
scope = "monitoring"
}
 
$API_AuthHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$API_AuthHeaders.Add("accept", 'application/json')
$API_AuthHeaders.Add("Content-Type", 'application/x-www-form-urlencoded')
 
$auth_token = Invoke-RestMethod -Uri https://app.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $body
$access_token = $auth_token | Select-Object -ExpandProperty 'access_token' -EA 0
 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("accept", 'application/json')
$headers.Add("Authorization", "Bearer $access_token")
 
# Set timerange to report on
$LastDayString = '20231231'
$FirstDayString = '20230101'
 
# Get date of today
$today = Get-Date -format "yyyyMMdd"
 
# file path where CSV will be output
$patchinfo_report = "/Users/EliBrody/" + $today + "_Patch_Report.csv"
 
# define ninja urls
$devices_url = "https://app.ninjarmm.com/v2/devices"
$organizations_url = "https://app.ninjarmm.com/v2/organizations"
$patchreport_url = " https://app.ninjarmm.com/api/v2/queries/os-patch-installs?df=class%3DWINDOWS_SERVER%20AND%20org%3D149&status=Installed&installedBefore=" + $LastDayString + "&installedAfter=" + $FirstDayString
 
# call ninja urls
$devices = Invoke-RestMethod -Uri $devices_url -Method GET -Headers $headers
$patchinstalls = Invoke-RestMethod -Uri $patchreport_url -Method GET -Headers $headers
$organizations = Invoke-RestMethod -Uri $organizations_url -Method GET -Headers $headers
 
#Create table where each organization has its own row
Foreach ($organization in $organizations) {
    Add-Member `
         -InputObject $organization `
         -NotePropertyName "Workstations" `
         -NotePropertyValue @()
         Add-Member `
         -InputObject $organization `
         -NotePropertyName "Servers" `
         -NotePropertyValue @()
         Add-Member `
         -InputObject $organization `
         -NotePropertyName "PatchScans" `
         -NotePropertyValue @()
         Add-Member `
         -InputObject $organization `
         -NotePropertyName "PatchScanFailures" `
         -NotePropertyValue @()
         Add-Member `
         -InputObject $organization `
         -NotePropertyName "PatchInstalls" `
         -NotePropertyValue @() 
   }
 
   Foreach ($device in $devices) {
    $currentOrg = $organizations | Where {$_.id -eq $device.organizationId}
    if ($device.nodeClass.EndsWith("_SERVER")) {
        $currentOrg.Servers += $device.systemName
    } elseif ($device.nodeClass.EndsWith("_WORKSTATION") -or $device.nodeClass -eq "MAC") {
        $currentOrg.Workstations += $device.systemName
    }
}
 
$patchinstalls = $patchinstalls.results
 
Foreach ($patchinstall in $patchinstalls) {
    $currentDevice = $devices | Where {$_.id -eq $patchinstall.deviceId} | Select-Object -First 1
    Add-Member -InputObject $patchinstall -NotePropertyName "OrgID" -NotePropertyValue ""
    Add-Member -InputObject $patchinstall -NotePropertyName "OrgName" -NotePropertyValue ""
    Add-Member -InputObject $patchinstall -NotePropertyName "DeviceName" -NotePropertyValue ""
    $patchinstall.OrgID += $currentDevice.organizationId
    $patchinstall.DeviceName += $currentDevice.systemName
    $currentOrg = $organizations | Where {$_.id -eq $patchinstall.OrgID}
    $patchinstall.OrgName += $currentOrg.name
    $currentOrg.PatchInstalls += $patchinstall
    $patchinstall.installedAt = (([System.DateTimeOffset]::FromUnixTimeSeconds($patchinstall.installedAt)).DateTime).ToString()
    $patchinstall.timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($patchinstall.timestamp)).DateTime).ToString()
 
  }
 
Write-Output $patchinstalls | Select-Object name,status,installedAt,kbNumber,DeviceName,OrgName | Format-Table
 
$patchinstalls | Select-Object name,status,installedAt,kbNumber,DeviceName,OrgName | Export-CSV -NoTypeInformation -Path $patchinfo_report
 
