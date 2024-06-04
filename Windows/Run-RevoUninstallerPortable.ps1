# Run iex (New-Object Net.WebClient).DownloadString('https://github.com/TheTechNetwork/Scripts-Public/blob/main/Windows/Run-RevoUninstallerPortable.ps1')


cd "C:\Temp"
wget -o "C:\temp\revoportable.zip" -Uri "https://download.revouninstaller.com/download/RevoUninstaller_Portable.zip"
Expand-Archive -Path "C:\temp\revoportable.zip" -DestinationPath "C:\temp\"
cd C:\Temp\RevoUninstaller_Portable\
