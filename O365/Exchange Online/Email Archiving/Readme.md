To enable Archive Auto Expand run 

Connect-ExchangeOnline

Set-OrganizationConfig -AutoExpandingArchive

Manually Start the Managed folder assistant 

Start-ManagedFolderAssistant -Identity "user@domain.com"
