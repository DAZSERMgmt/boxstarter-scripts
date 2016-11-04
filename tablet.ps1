# Start a new Tablet

function Test-PendingReboot {
  if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
  if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
  if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
  try { 
    $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
    $status = $util.DetermineIfRebootPending()
    if(($status -ne $null) -and $status.RebootPending){
      return $true
    }
  } catch {}
  return $false
}

function Invoke-Reboot {
  #Need to create startup to call install.ps1 again
  Write-Output "Writing Restart file"
  $startup = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup"
  Invoke-WebRequest https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/install.ps1 -OutFile $env:USERPROFILE\Desktop\install.ps1
  $restartScript = "powershell.exe -File '$env:USERPROFILE\Desktop\install.ps1'"
  New-Item "$startup\post-restart.bat" -type file -force -value $restartScript | Out-Null

  Restart-Computer -Force
}

# Windows Stuff
  # Update the timezone and time
  $time = tzutil /g
  if (!($time -eq "Eastern Standard Time")) {
    Write-Output "Setting Time Zone to EST"
    tzutil /s "Eastern Standard Time"
  }

  Write-Output "Setting Local Policy to RemoteSigned"
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
  
  # Install chocolatey
  iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex

  # Set computer name
  If (!(Test-Path C:\computerNamed)) {
    $name = Read-Host "What is your computer name?"
    Rename-Computer -NewName $name
    echo $name >> C:\computerNamed
    if (Test-PendingReboot) { Invoke-Reboot }
  }

  # Add my Choco source
  choco source add "https://www.myget.org/F/dazser/api/v2" -n=dazser

# Updates & Backend
  choco install powershell --source=chocolatey -y
  choco install javaruntime --source=chocolatey -y

# Tools
  #choco install emet -y
  # Configure EMET
  #Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/EMET-Settings.xml" -OutFile ${Env:ProgramFiles(x86)}"\EMET 5.5\MyEMETSettings.xml"
  #$path = ${Env:ProgramFiles(x86)}+"\EMET 5.5"
  #& $path\EMET_Conf.exe --import $path\MyEMETSettings.xml

  choco install btsync -y
  # BTSync starts after install, so kill it.
  Stop-Process -ProcessName btsync
  # Next, run btsync.ps1 to generate btsync.conf
  # Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/btsync.ps1" -UseBasicParsing | Invoke-Expression
  # Run btsync
  # $env:appdata+"\Bittorrent Sync\btsync.exe /config btsync.conf"

  #choco install followmee -y
  # Get FollowMee settings & Start the service
  #Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/FollowMee-Settings.xml" -OutFile ${Env:ProgramFiles(x86)}"\FollowMee\Settings.xml"
  #Start-Service FMEEService

  choco install networx -y
  try {
    Write-Output "Stopping networx"
    Stop-Process -ProcessName networx
  } catch {}
  # Now get the OpenSSL files
  $file = "$env:TEMP\openssl.zip"
  Invoke-WebRequest -Uri "https://indy.fulgan.com/SSL/openssl-1.0.2j-x64_86-win64.zip" -OutFile $file
  # Unzip the file to specified location
  $shell_app = New-Object -Com Shell.Application 
  $zip_file = $shell_app.namespace($file)
  $path = $Env:ProgramFiles+"\Networx\"
  $destination = $shell_app.namespace($path) 
  $destination.Copyhere($zip_file.items())
  Remove-Item $file
  # Now get the settings database file
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/networx.db" -OutFile $Env:ProgramFiles"\NetWorx\NetWorx.db"

# Applications
  choco install libreoffice -y
  choco install skype -y
  choco install slack -y
  choco install zoom -y

# Browsers
  choco install googlechrome -y
  # Copy master_preferences to Chrome profile
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/master_preferences" -OutFile ${Env:ProgramFiles(x86)}"\Google\Chrome\Application\master_preferences"
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/initialbookmarks.html" -OutFile ${Env:ProgramFiles(x86)}"\Google\Chrome\Application\initialbookmarks.html"

$Shell = New-Object -ComObject ("WScript.Shell")

$App = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\DAZSER Web App.url")
$App.TargetPath = "https://www.dazser.net"
$App.IconLocation = "$env:windir\System32\shell32.dll, 13"
$App.Save()

$Mail = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Web Mail.url")
$Mail.TargetPath = "https://mail.dazser.com"
$Mail.IconLocation = "$env:windir\System32\shell32.dll, 42"
$Mail.Save()

# Windows Stuff
  #Show Powershell on Win+X instead of Command Prompt #kill explorer
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name DontUsePowerShellOnWinX -Value 0
  #File Explorer preferences
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1

Remove-Item C:\computerNamed