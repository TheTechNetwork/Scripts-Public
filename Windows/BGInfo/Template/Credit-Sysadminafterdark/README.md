# Credits to [SysadminAfterDark](https://gitlab.sysadminafterdark.com/sysadminafterdark/afterdark-bginfo-configuration)

# AfterDark BGInfo Configuration



## What is BGInfo

[BGInfo](https://learn.microsoft.com/en-us/sysinternals/downloads/bginfo) is a small utility part of Microsoft's Sysinternals suite. BGInfo runs at login and displays relevent computer and network information on the user's desktop. This helps systems administrators collect hostname and IP address info over the phone while assisting users and sanely manage multiple RDP connections at a glance. This repository has been created to preserve my personal configuration and share it with others.   

## Manually Deploy BGInfo

1. At the top of this page, next to the blue "Clone" button, click the download button and save this repository to your computer as a zip file. After the download has completed, unzip the files using 7-zip or similar software.
2. Copy the BGInfo directory to C:\Program Files.
3. Copy the Start Bginfo64 On Boot shortcut to C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup.
4. Logout / Login and the script will display information related to your computer and network in the top right hand corner of the screen.

## Deploy BGInfo with Microsoft Active Directory

If you are deploying at scale, or are just plain lazy, like I am, this is the prefered way to deploy BGInfo.

1. RDP or remote into your Microsoft Active Directory server or a jumpbox system using domain administrator credentials.
2. At the top of this page, next to the blue "Clone" button, click the download button and save this repository to your computer as a zip file. After the download has completed, unzip the files using 7-zip or similar software.
3. Copy the BGInfo directory to your SYSVOL scripts folder. For example, mine is as follows: 
 ```
\\internal.sysadminafterdark.com\SYSVOL\internal.sysadminafterdark.com\scripts\BGInfo
 ```
4. With the files in place, open Group Policy Management and create a new group policy called "Deploy BGInfo64". I deploy to all devices on my network, so this policy is linked in the root forest.
5. Right Click "Deploy BGInfo64 and click "Edit"
6. Navigate to User Configuration > Windows Settings > Files. Right click on the white space and clcik on New > File. Create the following entries, subsituting paths for your own environment:

| Name                        | Order | Action | Source                                                                                                           | Destination                                                                                            |
| ----------------------------| ------| -------| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Bginfo64.exe                | 1     | Update | \\internal.sysadminafterdark.com\SYSVOL\internal.sysadminafterdark.com\scripts\BGInfo\Bginfo64.exe               | C:\Program Files\BGInfo\Bginfo64.exe                                                                  |
| Template.bgi                | 2     | Update | \\internal.sysadminafterdark.com\SYSVOL\internal.sysadminafterdark.com\scripts\BGInfo\Template.bgi               | C:\Program Files\BGInfo\Template.bgi                                                                  |
| Start Bginfo64 On Boot.lnk  | 3     | Update | \\internal.sysadminafterdark.com\SYSVOL\internal.sysadminafterdark.com\scripts\BGInfo\Start Bginfo64 On Boot.lnk | C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Start Bginfo64 On Boot.lnk               |
| all VBS files go here                  | 4     | Update | \\internal.sysadminafterdark.com\SYSVOL\internal.sysadminafterdark.com\scripts\BGInfo\*                  | C:\Program Files\BGInfo\*                                                                   |


7. Run gpupdate /force. Logout / Login and the script will display information related to your computer and network in the top right hand corner of the screen.

## Customize my Script

### Create Your Own Template.bgi

You can create your own template by running Binfo64.exe. There is a countdown timer in the upper right hand corner of the application. Click it to stop the program from closing. If you would like to use my template as a base, you may open it from File > Open. Don't forget to save and redistribute the new template. You may also view my custom parameters by clicking the "Custom" button while my template is loaded.

### Change Start Bginfo64 On Boot.lnk Parameters and Use Your Own Template

The Start Bginfo64 On Boot has been created with custom perameters required to work and point to the template file included in this repo. The default is as follows:
```
"C:\Program Files\BGInfo\Bginfo64.exe" "C:\Program Files\BGInfo\Template.bgi" /silent /nolicprompt /timer:0
```
To substitute your own custom template, just change Template.bgi to whatever you named your template. Remember to distribute the file as we did above.

### What's the Deal With ipv4.vbs?

BGInfo (annoyingly) displays inactive network adapters. I found this snippet of code that shows only active adapters.

## Project status

This project has sucessfully been pushed to afterdark production. If you have any questions, comments or concerns, please contact me via my [forum](https://forum.sysadminafterdark.com/).
