#This script reports on all patches installed on Windows Servers in a particular organization
#It reports on the previous month's patch scans and installations
#For example running the report on any day in August would give you patch scan and installation numbers for July.
 
# API authentication - insert your client ID and client secret
$body = @{
grant_type = "client_credentials"
client_id = "INSERT_CLIENT_APP_ID"
client_secret = "INSERT_CLIENT_SECRET"
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
 
#Finding the first and last day of the preceding month
$CurrentDate = Get-Date
$FirstDayOfCurrentMonth = (Get-Date -Year $CurrentDate.Year -Month $CurrentDate.Month -Day 1)
$LastDayOfPrecedingMonth = $FirstDayOfCurrentMonth.AddDays(-1)
$LastDayString = $LastDayOfPrecedingMonth.ToString('yyyyMMdd')
$FirstDayOfPrecedingMonth = (Get-Date -Year $CurrentDate.Year -Month $CurrentDate.AddMonths(-1).Month -Day 1)
$FirstDayString = $FirstDayOfPrecedingMonth.ToString('yyyyMMdd')
 
# Get date of today
$today = Get-Date -format "yyyyMMdd"
 
# file path where CSV will be output
$patchinfo_report = "/Users/jeffhunter/" + $today + "_Patch_Report.csv"
 
# define ninja urls
$devices_url = "https://app.ninjarmm.com/v2/devices"
$organizations_url = "https://app.ninjarmm.com/v2/organizations"
# the patch report URL has been configured to report only on patches installed on servers that are within a particular organization - in this case org 10 for Sunnyside
$patchreport_url = " https://app.ninjarmm.com/api/v2/queries/os-patch-installs?df=class%3DWINDOWS_SERVER%20AND%20org%3D10&status=Installed&installedBefore=" + $LastDayString + "&installedAfter=" + $FirstDayString
 
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
 
# Export to CSV
$patchinstalls | Select-Object name,status,installedAt,kbNumber,DeviceName,OrgName | Export-CSV -NoTypeInformation -Path $patchinfo_report
 
