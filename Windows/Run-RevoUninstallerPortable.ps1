# Run iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/TheTechNetwork/Scripts-Public/main/Windows/Run-RevoUninstallerPortable.ps1')


cd "C:\Temp"
wget -o "C:\temp\revoportable.zip" -Uri "https://download.revouninstaller.com/download/RevoUninstaller_Portable.zip"
Expand-Archive -Path "C:\temp\revoportable.zip" -DestinationPath "C:\temp\"
cd C:\Temp\RevoUninstaller_Portable\
.\RevoUPort.exe
