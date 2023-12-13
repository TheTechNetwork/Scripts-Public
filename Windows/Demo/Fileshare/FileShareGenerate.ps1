# PowerShell Script to Create Realistic Dummy File Share Structure

# Configuration
$rootPath = "C:\Shares\Share" # Change this to your desired path
$numberOfDirs = 5             # Total number of directories to create at each level
$depth = 5                    # Maximum depth of directory tree
$filesPerDir = 25             # Number of files to create in each directory
$fileSizeKb = 10              # Size of each file in KB
$maxPathLength = 260          # Maximum path length for Windows

# Expanded list of common names for directories and files
$dirNames = @("Projects", "Finance", "HR", "Marketing", "Sales", "IT", "Admin", "Reports", "Meetings", "Research",
              "Development", "Design", "Legal", "Operations", "CustomerService", "Strategy", "Training", "Compliance",
              "Procurement", "Logistics", "ProductManagement", "QualityAssurance", "TechnicalSupport", "PublicRelations",
              "HumanResources", "Innovation", "DataAnalysis", "Security", "Networking", "Software", "Hardware")

$fileNames = @("Report", "MeetingNotes", "Budget", "Plan", "Summary", "Proposal", "Analysis", "Log", "Info", "Document",
               "Presentation", "Spreadsheet", "Memo", "Chart", "Graph", "Schedule", "Invoice", "Email", "Guideline",
               "Manual", "Policy", "Strategy", "Overview", "Update", "Newsletter", "Agenda", "Minutes", "Feedback",
               "Assessment", "Review")

# Function to create a directory with files
function CreateDirWithFiles($path, $depth) {
    if ($depth -le 0) {
        return
    }

    1..$global:numberOfDirs | ForEach-Object {
        $dirIndex = Get-Random -Maximum $dirNames.Length
        $newDirName = $dirNames[$dirIndex] + "$_"
        $newDir = Join-Path $path $newDirName

        # Check if the directory path length is within the Windows limit
        if ($newDir.Length -lt 248) {
            New-Item -ItemType Directory -Path $newDir -Force | Out-Null

            1..$global:filesPerDir | ForEach-Object {
                $fileIndex = Get-Random -Maximum $fileNames.Length
                $fileExtension = Get-Random -InputObject @("txt", "docx", "xlsx", "pdf", "pptx")
                $fileName = $fileNames[$fileIndex] + "$_.$fileExtension"
                $filePath = Join-Path $newDir $fileName

                # Check if the file path length is within the Windows limit
                if ($filePath.Length -lt $maxPathLength) {
                    $null = New-Item -ItemType File -Path $filePath -Force

                    # Generate random content for the file
                    $content = New-Object byte[] ($fileSizeKb * 1024)
                    (New-Object Random).NextBytes($content)
                    [System.IO.File]::WriteAllBytes($filePath, $content)
                }
            }
        }

        CreateDirWithFiles $newDir ($depth - 1)
    }
}

# Create root directory if it doesn't exist
New-Item -ItemType Directory -Path $rootPath -Force | Out-Null

# Start creating directories and files
CreateDirWithFiles $rootPath $depth

Write-Host "Realistic dummy file share structure created at $rootPath"
