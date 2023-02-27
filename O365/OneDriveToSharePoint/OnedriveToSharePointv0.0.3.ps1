#Prereqs
Install-Module -Name "PnP.PowerShell"
#Install-Module -Name "Microsoft.Online.SharePoint.PowerShell"

#Parameters
$UPN = Read-Host -Prompt 'Input the Username Replace any Symbols with an Underscore'
$OneDriveSiteURL = "https://proudmomentsaba-my.sharepoint.com/personal/$UPN"
$DownloadPath ="C:\Temp\OneDrive\$UPN"
$SharePointSiteURL = "https://proudmomentsaba.sharepoint.com/sites/EliB-Test/"
$TargetSharePointFolder = "Documents/OneDriveDump/$UPN"

#Download Onedrive Content to "C:\Temp\OneDrive\$UPN"
Try {
    #Connect to OneDrive site
    Connect-PnPOnline $OneDriveSiteURL -Interactive
    $Web = Get-PnPWeb
 
    #Get the "Documents" library where all OneDrive files are stored
    $List = Get-PnPList -Identity "Documents"
  
    #Get all Items from the Library - with progress bar
    $global:counter = 0
    $ListItems = Get-PnPListItem -List $List -PageSize 500 -Fields ID -ScriptBlock { Param($items) $global:counter += $items.Count; Write-Progress -PercentComplete `
                ($global:Counter / ($List.ItemCount) * 100) -Activity "Getting Items from OneDrive:" -Status "Processing Items $global:Counter to $($List.ItemCount)";} 
    Write-Progress -Activity "Completed Retrieving Files and Folders from OneDrive!" -Completed
  
    #Get all Subfolders of the library
    $SubFolders = $ListItems | Where {$_.FileSystemObjectType -eq "Folder" -and $_.FieldValues.FileLeafRef -ne "Forms"}
    $SubFolders | ForEach-Object {
        #Ensure All Folders in the Local Path
        $LocalFolder = $DownloadPath + ($_.FieldValues.FileRef.Substring($Web.ServerRelativeUrl.Length)) -replace "/","\"
        #Create Local Folder, if it doesn't exist
        If (!(Test-Path -Path $LocalFolder)) {
                New-Item -ItemType Directory -Path $LocalFolder | Out-Null
        }
        Write-host -f Yellow "Ensured Folder '$LocalFolder'"
    }
  
    #Get all Files from the folder
    $FilesColl =  $ListItems | Where {$_.FileSystemObjectType -eq "File"}
  
    #Iterate through each file and download
    $FilesColl | ForEach-Object {
        $FileDownloadPath = ($DownloadPath + ($_.FieldValues.FileRef.Substring($Web.ServerRelativeUrl.Length)) -replace "/","\").Replace($_.FieldValues.FileLeafRef,'')
        Get-PnPFile -ServerRelativeUrl $_.FieldValues.FileRef -Path $FileDownloadPath -FileName $_.FieldValues.FileLeafRef -AsFile -force
        Write-host -f Green "Downloaded File from '$($_.FieldValues.FileRef)'"
    }
}
Catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}

#Upload Content To Sharepoint File Dump

#Connect with SharePoint Online
#Connect-PnPOnline -Url $SharePointSiteURL -Interactive

#Function to upload all files from a local folder to SharePoint Online Folder
Function Upload-PnPFolder($DownloadPath, $TargetSharePointFolder)
{
    Write-host "Processing Folder:"$DownloadPath -f Yellow
    #Get All files and SubFolders from the local disk
    $Files = Get-ChildItem -Path $DownloadPath -File
 
    #Ensure the target folder
    Resolve-PnPFolder -SiteRelativePath $TargetSharePointFolder | Out-Null
 
    #Upload All files from the local folder to SharePoint Online Folder
    ForEach ($File in $Files)
    {
        Add-PnPFile -Path "$($File.Directory)\$($File.Name)" -Folder $TargetSharePointFolder -Values @{"Title" = $($File.Name)} | Out-Null
        Write-host "`tUploaded File:"$File.FullName -f Green
    }
}
 
#Call the function to upload the Root Folder
Upload-PnPFolder -DownloadPath $DownloadPath -TargetSharePointFolder $TargetSharePointFolder
 
#Get all Folders from given source path 
Get-ChildItem -Path $DownloadPath -Recurse -Directory | ForEach-Object {
    $FolderToUpload = ($TargetSharePointFolder+$_.FullName.Replace($DownloadPath,[string]::Empty)).Replace("\","/")
    Upload-PnPFolder -DownloadPath $_.FullName -TargetSharePointFolder $FolderToUpload
}
