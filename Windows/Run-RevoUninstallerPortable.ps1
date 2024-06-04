# Run iex (New-Object Net.WebClient).DownloadString('https://github.com/TheTechNetwork/Scripts-Public/raw/752854633e6a2590b3fd11a140650d1bee8fbd29/Windows/Run-RevoUninstallerPortable.ps1')


cd "C:\Temp"
wget -o "C:\temp\revoportable.zip" -Uri "https://download.revouninstaller.com/download/RevoUninstaller_Portable.zip"
Expand-Archive -Path "C:\temp\revoportable.zip" -DestinationPath "C:\temp\"
cd C:\Temp\RevoUninstaller_Portable\
