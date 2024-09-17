#Source https://www.reddit.com/r/Office365/comments/f69wd2/comment/fi4x50u/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

#Gives Permission to mailbox itself
Add-mailboxpermission -identity SHAREDMAILBOX -user EMPLOYEE -accessrights ReadPermission -inheritancetype all
#Gives Permission to top-level folder
Add-mailboxfolderpermission SHAREDMAILBOX -user EMPLOYEE -accessrights Reviewer
#gets the names of each folder and sub folder in the entire mailbox. It then does a mailboxfolderpermission on that folder. Rinse and repeat.
foreach($folder in (Get-MailboxFolderStatistics -identity SHAREDMAILBOX)) {$fname="FULLNAMESHAREDMAILBOX:"+$folder.folderpath.replace("/","\"); add-mailboxfolderpermission $fname -user EMPLOYEE -accessrights Reviewer
