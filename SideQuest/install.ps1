Param( [Parameter()] [String[]] $installPath )
$adb=$false
$fastboot=$false

if (Get-Command "adb" -ErrorAction SilentlyContinue){
$adb=$true
}
if (Get-Command "fastboot" -ErrorAction SilentlyContinue){
$fastboot=$true
}

if($installPath.Length.Equals(0)){
if(!$adb -and $fastboot){
Write-Output "fastboot installed without adb"
Write-Output "Checking fastboot location via --version ..."
$installPath=fastboot --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
}
if($adb){
Write-Output "adb installed, checking location via --version ..."
$installPath=adb --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
}
if($installPath.Length.Equals(0)){
Write-Output "platform-tools location not found"
$installPath="$HOME\AppData\Roaming\SideQuest\platform-tools\"
}
}
Write-Output "installPath=$installPath"

if(!$adb -and !$fastboot){
Write-Output "Adding $installPath to `$PATH ..."
$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$newpath = "$oldpath;$installPath"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

Write-Output "Checking Windows Defender Status..."
$defender=cmd /c sc query Windefend
if ( "$defender" -like "*RUNNING*" ){
Write-Output "Defender is running, adding exclusions for adb..."
Add-MpPreference -ExclusionPath $installPath
Add-MpPreference -ExclusionProcess "adb.exe"
} else {
Write-Output "Defender is not running, skipping exclusions"
}

Write-Output "Downloading platform-tools-latest-windows.zip to $env:temp ..."
Import-Module BitsTransfer
Start-BitsTransfer -Source "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -Destination "$env:temp\platform-tools-latest-windows.zip"
Write-Output "Extracting $env:temp\platform-tools-latest-windows.zip to $installPath ..."
Expand-Archive -Path "$env:temp\platform-tools-latest-windows.zip" -DestinationPath "$installPath" -Force
Write-Output "Installing Quest ADB Driver"
$PSScriptRootLegacy=split-path -parent $MyInvocation.MyCommand.Definition
Start-Process $PSScriptRootLegacy/android_winusb.inf -Verb Install
Write-Output "Done!"
Read-Host -Prompt "Press Enter to continue"