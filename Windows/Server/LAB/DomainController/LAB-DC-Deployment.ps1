#Set Static IP first
# Import required modules
Import-Module ServerManager

# Check if the script is run as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run PowerShell as Administrator."
    break
}

# Install Active Directory Domain Services and DNS Server Roles if not already installed
$features = @("AD-Domain-Services", "DNS")
foreach ($feature in $features) {
    if (-Not (Get-WindowsFeature -Name $feature).Installed)
    {
        Write-Host "Installing $feature Role..."
        Install-WindowsFeature -Name $feature -IncludeManagementTools
    }
}

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Prompt for the type of installation
$dcType = Read-Host "Enter the DC type (NewForest, NewDomain, ReplicaOrNewChild, ReadOnlyReplica)"
$domainName = Read-Host "Enter the domain name (e.g., example.com)"

# Function to install based on type
switch ($dcType)
{
    "NewForest" {
        $safeModeAdminPassword = Read-Host "Enter the Safe Mode Administrator Password" -AsSecureString
        Install-ADDSForest -DomainName $domainName -DomainNetbiosName (Read-Host "Enter NetBIOS name") -InstallDNS -SafeModeAdministratorPassword $safeModeAdminPassword -Force
    }
    "NewDomain" {
        $safeModeAdminPassword = Read-Host "Enter the Safe Mode Administrator Password" -AsSecureString
        Install-ADDSDomain -NewDomainName $domainName -InstallDNS -SafeModeAdministratorPassword $safeModeAdminPassword -Force
    }
    "ReplicaOrNewChild" {
        $safeModeAdminPassword = Read-Host "Enter the Safe Mode Administrator Password" -AsSecureString
        $parentDomainName = Read-Host "Enter the parent domain name"
        Install-ADDSDomainController -DomainName $parentDomainName -InstallDNS -SafeModeAdministratorPassword $safeModeAdminPassword -Force
    }
    "ReadOnlyReplica" {
        $safeModeAdminPassword = Read-Host "Enter the Safe Mode Administrator Password" -AsSecureString
        Install-ADDSDomainController -DomainName $domainName -ReadOnlyReplica -InstallDNS -SafeModeAdministratorPassword $safeModeAdminPassword -Force
    }
    default {
        Write-Host "Invalid domain controller type entered."
    }
}

# Confirm completion
Write-Host "Domain Controller and DNS setup complete."
