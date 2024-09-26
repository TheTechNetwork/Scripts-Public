#Edits the Date file was last modified to look like its older to be able to test cleanup scripts

# Define the base path for all users
$usersPath = "C:\Users"

# Get all user profiles except for system-related ones
$users = Get-ChildItem -Path $usersPath | Where-Object { $_.PSIsContainer -and $_.Name -notin @("Public", "Default", "Default User", "All Users") }

# Number of dummy files per day for the last 30 days
$filesPerDay = 3
# Number of extra files to create randomly on certain days
$extraFilesPerDay = 5
# Number of dummy files per month before the last 30 days
$filesPerMonth = 10
# Number of days to go back for daily files
$daysBack = 60
# Number of months to go back for monthly files
$monthsBack = 12

# Array to hold the names of users for whom files were created
$usersProcessed = @()

# Generate an array of random days within the last 30 days to add extra files
$randomDays = Get-Random -Count 20 -InputObject (0..$daysBack)  # Adjust the count if you want more random days

# Loop through each user and create dummy files in their Downloads folder
foreach ($user in $users) {
    $downloadsPath = Join-Path -Path $user.FullName -ChildPath "Downloads"
    
    # Ensure the Downloads directory exists
    if (Test-Path -Path $downloadsPath) {
        Write-Host "Creating dummy files in $downloadsPath for user $($user.Name)"

        # Add user to processed list
        $usersProcessed += $user.Name

        # Create files for the last 30 days
        for ($dayOffset = 0; $dayOffset -lt $daysBack; $dayOffset++) {
            $date = (Get-Date).AddDays(-$dayOffset)
            for ($i = 1; $i -le $filesPerDay; $i++) {
                # Define the file name
                $fileName = "dummyfile_$(($dayOffset * $filesPerDay + $i)).txt"
                $filePath = Join-Path -Path $downloadsPath -ChildPath $fileName
                
                # Create the file
                New-Item -ItemType File -Path $filePath -Force
                
                # Set the LastWriteTime to the current date minus the day offset
                Set-ItemProperty -Path $filePath -Name LastWriteTime -Value $date
            }

            # Check if the current day is in the random days list to add extra files
            if ($randomDays -contains $dayOffset) {
                for ($j = 1; $j -le $extraFilesPerDay; $j++) {
                    # Define the extra file name
                    $extraFileName = "extradummyfile_$(($dayOffset * $extraFilesPerDay + $j)).txt"
                    $extraFilePath = Join-Path -Path $downloadsPath -ChildPath $extraFileName

                    # Create the extra file
                    New-Item -ItemType File -Path $extraFilePath -Force

                    # Set the LastWriteTime to the current date minus the day offset
                    Set-ItemProperty -Path $extraFilePath -Name LastWriteTime -Value $date
                }
            }
        }

        # Create files for the previous months
        for ($monthOffset = 1; $monthOffset -le $monthsBack; $monthOffset++) {
            $date = (Get-Date).AddMonths(-$monthOffset)
            for ($i = 1; $i -le $filesPerMonth; $i++) {
                # Define the file name
                $fileName = "monthly_dummyfile_$(($monthOffset * $filesPerMonth + $i)).txt"
                $filePath = Join-Path -Path $downloadsPath -ChildPath $fileName
                
                # Create the file
                New-Item -ItemType File -Path $filePath -Force
                
                # Set the LastWriteTime to the current date minus the month offset
                Set-ItemProperty -Path $filePath -Name LastWriteTime -Value $date
            }
        }

    } else {
        Write-Host "Downloads folder not found for $($user.Name)"
    }
}

# Output the users for whom dummy files were created
if ($usersProcessed.Count -gt 0) {
    Write-Host "Dummy files created for the following users: $($usersProcessed -join ', ')"
} else {
    Write-Host "No dummy files were created because no valid users were found with a Downloads folder."
}
