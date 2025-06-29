Write-Host "`n>>> Windows Update Registry Configuration Audit (with Explanations)" -ForegroundColor Cyan

# Dictionary of explanations by property name
$explanations = @{
  "ActiveHoursStart" = "Start of active hours to prevent automatic restarts."
  "ActiveHoursEnd" = "End of active hours window."
  "AllowMUUpdateService" = "Allows Windows Update to also check Microsoft Update for other products."
  "AllowRestart" = "Permits automatic restarts after updates outside active hours."
  "AUOptions" = "Defines how Automatic Updates behave (e.g., notify, scheduled install)."
  "BranchReadinessLevel" = "Specifies the release channel for feature updates (e.g., Semi-Annual, Insider)."
  "CachedAUOptions" = "Cached copy of AU behavior as previously configured."
  "CIOptinModified" = "Timestamp for the last change to the Continuous Innovation settings."
  "DeferFeatureUpdates" = "Defers feature updates for the specified number of days."
  "DeferQualityUpdates" = "Defers quality updates (cumulative) for the specified number of days."
  "DeliveryOptimizationMode" = "Controls peer-to-peer update delivery behavior."
  "DetectionFrequency" = "Interval in hours for checking update availability."
  "DetectionFrequencyEnabled" = "Enables custom update detection frequency."
  "ExcludeWUDrivers" = "Disables driver delivery through Windows Update."
  "ExcludeWUDriversInQualityUpdate" = "Prevents driver updates from being bundled into quality updates."
  "FlightingOwnerGUID" = "GUID indicating Insider channel enrollment."
  "IsContinuousInnovationOptedIn" = "Enables ongoing delivery of new features outside of major releases."
  "IsDeferralIsActive" = "Indicates whether update deferral policies are currently active."
  "IsWUfBConfigured" = "Shows whether Windows Update for Business is managing updates."
  "IsWUfBDualScanActive" = "True if both WSUS and Windows Update (dual scan) are active."
  "NoAutoRebootWithLoggedOnUsers" = "Prevents auto-reboots if users are logged on."
  "NoAutoUpdate" = "Disables automatic updates when set to 1."
  "OSUpgradeNotificationTime" = "Timestamp for when the user was notified of an OS upgrade."
  "PauseFeatureUpdatesStartTime" = "Start date of paused feature updates."
  "PauseQualityUpdatesStartTime" = "Start date of paused quality updates."
  "PolicySources" = "Indicates source (GPO, MDM, local) of current policy values."
  "RequireDeferUpgrade" = "Requires deferral policies for OS upgrades."
  "RescheduleWaitTime" = "Delay in minutes before rescheduling a missed update install."
  "ScheduledInstallDay" = "Specifies the day updates install (0 = every day; 1-7 = Sunday-Saturday)."
  "ScheduledInstallTime" = "Hour of day for scheduled update installations."
  "SetPolicyDrivenUpdateSourceForDriverUpdates" = "Specifies driver update source (e.g., WSUS, WUfB)."
  "SetPolicyDrivenUpdateSourceForFeatureUpdates" = "Specifies the update channel for feature updates."
  "SetPolicyDrivenUpdateSourceForOtherUpdates" = "Defines update source for miscellaneous updates."
  "SetPolicyDrivenUpdateSourceForQualityUpdates" = "Specifies the update source for quality patches."
  "ShutdownFlyoutOptions" = "Controls what update-related options show in shutdown UI."
  "SmartSchedulerPredictedStartTimePoint" = "Predicted start of install window (UTC timestamp)."
  "SmartSchedulerPredictedEndTimePoint" = "Predicted end of install window (UTC timestamp)."
  "SmartSchedulerPredictedConfidence" = "System confidence (%) in install prediction."
  "TargetReleaseVersion" = "When enabled, restricts the OS version the device should remain on."
  "TargetReleaseVersionInfo" = "The specific Windows version string (e.g., '22H2') to stay on."
  "UseUpdateClassPolicySource" = "Chooses policy source (WSUS, Microsoft Update) per update class."
  "UseWUServer" = "When 1, enforces use of WSUS server."
  "WUServer" = "URL of the configured WSUS server to fetch updates."
  "WUStatusServer" = "URL of the server where client reports update status."
  "UpdateServiceUrlAlternate" = "Custom update endpoint configured by policy or MDM."
  "AUState" = "Numeric code representing internal AU client state."
}

# Extended key list
$registryChecks = @(
    @{ Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Desc = "General Windows Update policy (GPO)" },
    @{ Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Desc = "Automatic Updates Policy (GPO)" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; Desc = "UX Settings and User Choices" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState"; Desc = "Effective update policy settings" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update"; Desc = "MDM-driven Update policies" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy"; Desc = "Current Windows Update states" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\StateVariables"; Desc = "State variables used by UX scheduling" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator"; Desc = "Orchestrator restart and scheduling" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\DeliveryOptimization\Config"; Desc = "Delivery Optimization configuration" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"; Desc = "Legacy auto update config" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Desc = "Deferral/pause and UX restrictions" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\FlightSettings"; Desc = "Insider program settings" },
    @{ Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade"; Desc = "Upgrade-related settings" }
)

# Exclude standard properties
$excludedProps = @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')

foreach ($reg in $registryChecks) {
    Write-Host "`nRegistry Key: $($reg.Key)" -ForegroundColor Yellow
    Write-Host "Description: $($reg.Desc)" -ForegroundColor Gray

    if (Test-Path $reg.Key) {
        $props = Get-ItemProperty -Path $reg.Key
        foreach ($prop in $props.PSObject.Properties) {
            if ($excludedProps -notcontains $prop.Name) {
                Write-Host " - $($prop.Name): $($prop.Value)"
                if ($explanations.ContainsKey($prop.Name)) {
                    Write-Host "   > $($explanations[$prop.Name])" -ForegroundColor DarkGray
                }
            }
        }
    } else {
        Write-Host " - (Key not found)" -ForegroundColor DarkGray
    }
}
