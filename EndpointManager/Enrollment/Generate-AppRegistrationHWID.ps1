# Support: $MspName="MSP1"; irm https://url | iex
if (-not $MspName) {
    throw "You must define `$MspName before running this script. Example:`n`$MspName='MSP1'; irm https://urltoscript.ps1 | iex"
}

$MaximumVariableCount = 8192
$MaximumFunctionCount = 8192

$ErrorActionPreference = "Stop"

# Default OutputDir when running via irm|iex (no script file path)
if (-not $OutputDir -or [string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $env:USERPROFILE "Downloads"
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$AppName = "Intune HWID Upload ($MspName)"
$SecretLifetimeDays = 730

# Ensure required Microsoft Graph sub-modules.
# Importing the full Microsoft.Graph meta-module is slow and frequently fails
# to load its RequiredModules (e.g. "Microsoft.Graph.Authentication is not
# loaded"). The script only needs these three, so install/import them directly.
$GraphModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Applications",
    "Microsoft.Graph.Identity.DirectoryManagement"
)
foreach ($m in $GraphModules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module $m -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $m -Force
}


$scopes = @(
  "Application.ReadWrite.All",
  "Directory.ReadWrite.All",
  "AppRoleAssignment.ReadWrite.All",
  "Domain.Read.All"
)

Write-Host "Signing in to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $scopes | Out-Null

$ctx = Get-MgContext
$tenantId = $ctx.TenantId

# Detect tenant name
$domain = Get-MgDomain | Where-Object { $_.IsDefault -eq $true }
if (-not $domain) { throw "Could not determine default tenant domain." }
$tenantName = ($domain.Id -split "\.")[0]

Write-Host "Tenant detected: $tenantName" -ForegroundColor Green
Write-Host "Creating app: $AppName" -ForegroundColor Cyan

# Microsoft Graph SP
$graphAppId = "00000003-0000-0000-c000-000000000000"
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"
if (-not $graphSp) { throw "Microsoft Graph service principal not found." }

# Required permissions
$requiredRoleValues = @(
  "DeviceManagementConfiguration.ReadWrite.All",
  "DeviceManagementServiceConfig.ReadWrite.All"
)

$roles = foreach ($val in $requiredRoleValues) {
    $role = $graphSp.AppRoles | Where-Object {
        $_.Value -eq $val -and $_.AllowedMemberTypes -contains "Application"
    }
    if (-not $role) { throw "Graph role not found: $val" }
    $role
}

$requiredResourceAccess = @(
  @{
    resourceAppId  = $graphAppId
    resourceAccess = @($roles | ForEach-Object { @{ id = $_.Id; type = "Role" } })
  }
)

# Create App + SP
$app = New-MgApplication -DisplayName $AppName -RequiredResourceAccess $requiredResourceAccess
$sp  = New-MgServicePrincipal -AppId $app.AppId

# Long-lived secret
$endDate = (Get-Date).AddDays($SecretLifetimeDays)
$pwd = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
    displayName = "OOBE-HWID-Secret"
    endDateTime = $endDate
}

# Grant admin consent
Write-Host "Granting admin consent..." -ForegroundColor Cyan
foreach ($role in $roles) {
    New-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $sp.Id `
        -PrincipalId $sp.Id `
        -ResourceId $graphSp.Id `
        -AppRoleId $role.Id | Out-Null
}

# Generate OOBE Script (clean)
$fileName = "$tenantName-Intune-HWID-OOBE.ps1"
$filePath = Join-Path $OutputDir $fileName

$endpointScript = @"
# Autopilot HWID Upload Script (OOBE)
# App: $AppName
# Tenant: $tenantName
# Secret Expires: $($endDate.ToString("yyyy-MM-dd"))

`$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

`$TenantID          = "$tenantId"
`$ApplicationID     = "$($app.AppId)"
`$ApplicationSecret = "$($pwd.SecretText)"

try {
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default
    }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue | Out-Null
} catch {}

Install-Script -Name Get-WindowsAutoPilotInfo -Force -Scope AllUsers

Get-WindowsAutoPilotInfo -Online -TenantId $TenantID -AppId $ApplicationID -AppSecret $ApplicationSecret

Write-Host "HWID upload completed successfully." -ForegroundColor Green
"@

$endpointScript | Out-File -FilePath $filePath -Encoding UTF8 -Force

Write-Host ""
Write-Host "====================================="
Write-Host "OOBE Script Generated:"
Write-Host $filePath
Write-Host "Secret expires: $($endDate.ToString("yyyy-MM-dd"))"
Write-Host "====================================="
