#Source https://www.reddit.com/r/Office365/comments/f69wd2/comment/fi4x50u/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

#Gives Permission to mailbox itself
Add-mailboxpermission -identity SHAREDMAILBOX -user EMPLOYEE -accessrights ReadPermission -inheritancetype all
#Gives Permission to top-level folder
Add-mailboxfolderpermission SHAREDMAILBOX -user EMPLOYEE -accessrights Reviewer
#gets the names of each folder and sub folder in the entire mailbox. It then does a mailboxfolderpermission on that folder. Rinse and repeat.
foreach($folder in (Get-MailboxFolderStatistics -identity SHAREDMAILBOX)) {$fname="FULLNAMESHAREDMAILBOX:"+$folder.folderpath.replace("/","\"); add-mailboxfolderpermission $fname -user EMPLOYEE -accessrights Reviewer


#For a more Restricted way we can specify the folders to grant to 
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

$username = username@company.com 
# Get mailbox folder statistics
$folders = Get-MailboxFolderStatistics -Identity $username
 
foreach ($folder in $folders) {
    # Extract the folder name and replace slashes with backslashes
    $folderName = $folder.FolderPath -replace "/", "\"
    # Check if the folder name matches any of the target folders
    if ($targetFolders -contains $folder.Name) {
        $folderIdentity = "$username:" + $folderName
 
        # Remove existing permissions for the user
        Remove-MailboxFolderPermission -Identity $folderIdentity -User $username -Confirm:$false
 
        # Add new permissions: Full read access, edit all items
        Add-MailboxFolderPermission -Identity $folderIdentity -User $username -AccessRights ReadItems, EditAllItems
    }
}
