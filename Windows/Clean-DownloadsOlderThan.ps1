#moves files older than 30 days to Secure Folder and keeps it there for another 30 before deleting

# Define the number of days for moving and deleting files
$moveThresholdDays = 30  # Move files older than this
$deleteThresholdDays = 60  # Delete files older than this

# Define the base secure folder path where permissions will be applied
$secureBaseFolder = "C:\ProgramData\EONMSP\Backups"
$secureFolder = Join-Path $secureBaseFolder "Downloads"
$adminGroup = "Administrators"

# List of system users to exclude (excluding 'Administrator')
$systemUsers = @('Default', 'DefaultAppPool', 'Public', 'All Users')

# Ensure the base secure folder exists
if (-not (Test-Path $secureBaseFolder)) {
    New-Item -ItemType Directory -Path $secureBaseFolder
}

# Ensure the 'Downloads' folder exists
if (-not (Test-Path $secureFolder)) {
    New-Item -ItemType Directory -Path $secureFolder
}

# Remove the 'Hidden' attribute from the base folder if it exists
if ((Get-ItemProperty $secureBaseFolder -Name Attributes).Attributes -band [System.IO.FileAttributes]::Hidden) {
    Set-ItemProperty -Path $secureBaseFolder -Name Attributes -Value ((Get-ItemProperty $secureBaseFolder -Name Attributes).Attributes -bxor [System.IO.FileAttributes]::Hidden)
}

# Get the current Access Control List (ACL) for the base folder
$acl = Get-Acl $secureBaseFolder

# Disable inheritance and remove all inherited permissions on the base folder
$acl.SetAccessRuleProtection($true, $false)

# Remove any existing access control entries for non-administrators
$acl.Access | ForEach-Object {
    if ($_.IdentityReference -notmatch "$adminGroup") {
        $acl.RemoveAccessRule($_)
    }
}

# Set full control access for administrators
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)

# Apply the updated ACL to the base folder (Backups)
Set-Acl -Path $secureBaseFolder -AclObject $acl

# Get a list of all user profile downloads folders, excluding system users (but including Administrator)
$downloadsFolders = Get-ChildItem "C:\Users\" -Directory | Where-Object { 
    $systemUsers -notcontains $_.Name
} | ForEach-Object {
    @{
        Username = $_.Name
        DownloadFolder = Join-Path $_.FullName "Downloads"
    }
}

# Move files older than $moveThresholdDays from each user's Downloads folder into subfolders
foreach ($folder in $downloadsFolders) {
    if (Test-Path $folder.DownloadFolder) {
        # Get files older than $moveThresholdDays
        $filesToMove = Get-ChildItem $folder.DownloadFolder -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$moveThresholdDays) }

        # Only proceed if there are files to move
        if ($filesToMove) {
            # Create a subfolder for the user in the secure folder if it doesn't exist
            $userSecureFolder = Join-Path $secureFolder $folder.Username
            if (-not (Test-Path $userSecureFolder)) {
                New-Item -ItemType Directory -Path $userSecureFolder
            }

            # Copy files to the user's subfolder, renaming if the file already exists
            $filesToMove | ForEach-Object {
                $destinationFile = Join-Path $userSecureFolder $_.Name

                # If the file already exists, rename the new file by appending a timestamp
                if (Test-Path $destinationFile) {
                    $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                    $fileExtension = [System.IO.Path]::GetExtension($_.Name)
                    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                    $newFileName = "$fileBaseName-$timestamp$fileExtension"
                    $destinationFile = Join-Path $userSecureFolder $newFileName
                }

                # Copy the file to the destination folder instead of Move-Item
                Copy-Item $_.FullName -Destination $destinationFile

                # Retain the original LastWriteTime and CreationTime using Set-ItemProperty
                $originalLastWriteTime = $_.LastWriteTime
                $originalCreationTime = $_.CreationTime
                
                Set-ItemProperty -Path $destinationFile -Name LastWriteTime -Value $originalLastWriteTime
                Set-ItemProperty -Path $destinationFile -Name CreationTime -Value $originalCreationTime

                # Verify that the properties were set correctly
                $updatedFile = Get-Item $destinationFile
                if ($updatedFile.LastWriteTime -eq $originalLastWriteTime -and $updatedFile.CreationTime -eq $originalCreationTime) {
                    # If copy and timestamp retention was successful, delete the original file
                    Remove-Item $_.FullName
                } else {
                    Write-Host "Failed to update timestamps for: $destinationFile"
                }
            }
        }
    }
}

# Delete files older than $deleteThresholdDays from each user's subfolder in the secure folder
Get-ChildItem $secureFolder -Directory | ForEach-Object {
    Get-ChildItem $_.FullName -File | ForEach-Object {
        # Check if the file is older than the delete threshold
        if ($_.LastWriteTime -lt (Get-Date).AddDays(-$deleteThresholdDays)) {
            # If the file is old enough, delete it
            Remove-Item $_.FullName
        } else {
            # Otherwise, reset the LastWriteTime and CreationTime to their current values
            $currentLastWriteTime = $_.LastWriteTime
            $currentCreationTime = $_.CreationTime
            
            # Use Set-ItemProperty to set these values again (refreshing them)
            Set-ItemProperty -Path $_.FullName -Name LastWriteTime -Value $currentLastWriteTime
            Set-ItemProperty -Path $_.FullName -Name CreationTime -Value $currentCreationTime
        }
    }
}
