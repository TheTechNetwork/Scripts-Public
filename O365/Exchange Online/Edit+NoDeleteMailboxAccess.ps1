#Source https://www.reddit.com/r/Office365/comments/f69wd2/comment/fi4x50u/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
#This is the shared mailbox we are targeting
$SharedMailbox = username@company.com

#This is the user we are granting access to
$Targetuser = username@company.com


#Give user access to the mailbox with Read Only permissions
Add-mailboxpermission -identity $SharedMailbox -user $Targetuser -accessrights ReadPermission -inheritancetype all



#Give user access to the top of information store with Read and Edit 
Add-mailboxfolderpermission $SharedMailbox -user $Targetuser -accessrights ReadItems, EditAllItems



# List of folders to apply permissions to
$targetFolders = @(
    "Inbox",
    "Drafts",
    "Sent Items",
    "Deleted Items",
    "Archive",
    "Outbox",
    "Inbound",
    "Outbound",
    "Contacts",
    "Junk Email"
)

# Get mailbox folder statistics
$folders = Get-MailboxFolderStatistics -Identity $SharedMailbox

foreach ($folder in $folders) {
    # Extract the folder name and replace slashes with backslashes
    $folderName = $folder.FolderPath -replace "/", "\"
    
    # Check if the folder name matches any of the target folders
    if ($targetFolders -contains $folder.Name) {
        $folderIdentity = "$SharedMailbox:" + $folderName

        # Remove existing permissions for the user
        Remove-MailboxFolderPermission -Identity $folderIdentity -User $Targetuser -Confirm:$false

        # Add new permissions: Full read access, edit all items
        Add-MailboxFolderPermission -Identity $folderIdentity -User $Targetuser -AccessRights ReadItems, EditAllItems
    }
}

