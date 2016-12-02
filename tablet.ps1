# Start a new Tablet

function Test-PendingReboot {
  If (Test-Path C:\rebootNeeded) {
    Remove-Item C:\rebootNeeded
    return $true
  }
  return $false
}

function Invoke-Reboot {
  #Need to create startup to call install.ps1 again
  Write-Output "Writing Restart file"
  $startup = "C:\Users\User\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
  Invoke-WebRequest https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/install.ps1 -OutFile C:\Users\User\Desktop\install.ps1
  $restartScript = 'powershell.exe -File "C:\Users\User\Desktop\install.ps1"'
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

# Set computer name
  If (!(Test-Path C:\computerNamed)) {
    $name = Read-Host "What is your computer name?"
    Rename-Computer -NewName $name
    echo $name >> C:\computerNamed
    echo "" >> C:\rebootNeeded
    if (Test-PendingReboot) { Invoke-Reboot }
  }

# Install K9 in the foreground while the script continues in the background
# Don't reboot after install
  Write-Output "Installing K9 Web Filter"
  Write-Output "Don't reboot after install"
  iwr https://raw.githubusercontent.com/DAZSERMgmt/boxstarter-scripts/master/FilterCodes.html -UseBasicParsing -OutFile C:\Users\User\Desktop\FilterCodes.html
  iwr http://download.k9webprotection.com/k9-webprotection.exe -UseBasicParsing -OutFile $env:TEMP\k9.exe
  Start-Process -FilePath "$env:TEMP\k9.exe"

# Install chocolatey
  #iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex

  RefreshEnv.cmd

# Add my Choco source
  choco source add -s="https://www.myget.org/F/dazser/api/v2" -n=dazser

# Updates & Backend
  #choco install powershell --source=chocolatey -y
  #choco install javaruntime --source=chocolatey -y

# Tools
  #choco install emet -y
  # Configure EMET
  #Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/EMET-Settings.xml" -OutFile ${Env:ProgramFiles(x86)}"\EMET 5.5\MyEMETSettings.xml"
  #$path = ${Env:ProgramFiles(x86)}+"\EMET 5.5"
  #& $path\EMET_Conf.exe --import $path\MyEMETSettings.xml

  #choco install resilio-sync --source=dazser -y
  # Next, run btsync.ps1 to generate btsync.conf
  iwr https://raw.githubusercontent.com/DAZSERMgmt/boxstarter-scripts/master/BTSyncKeys.html -UseBasicParsing -OutFile C:\Users\User\Desktop\BTSyncKeys.html
  Invoke-WebRequest "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/btsync.ps1" -UseBasicParsing | Invoke-Expression
  # Run btsync
  $env:appdata+"\Resilio Sync\btsync.exe /config btsync.conf"

  choco install networx --version=5.5.5.20161128 -y
  Write-Output "Stopping networx"
  $proc = Get-Process networx -ErrorAction SilentlyContinue
  if ($proc) {
    # try gracefully first
    $proc.CloseMainWindow()
    # kill after five seconds
    Sleep 5
    if (!$proc.HasExited) {
      $proc | Stop-Process -Force
    }
  }
  Remove-Variable proc
  # Now get the OpenSSL files
  $file = "$env:TEMP\openssl.zip"
  Write-Output "Grabbing OpenSSL"
  Invoke-WebRequest -Uri "https://indy.fulgan.com/SSL/openssl-1.0.2j-x64_86-win64.zip" -OutFile $file
  # Unzip the file to specified location
  $shell_app = New-Object -Com Shell.Application 
  $zip_file = $shell_app.namespace($file)
  $path = $Env:ProgramFiles+"\Networx\"
  $destination = $shell_app.namespace($path) 
  $destination.Copyhere($zip_file.items())
  Write-Output "OpenSSL Installed"
  Remove-Item $file
  # Now get the settings database file
  Invoke-WebRequest "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/networx.db" -OutFile $Env:ProgramData"\SoftPerfect\NetWorx\NetWorx.db"

# Applications
  #choco install libreoffice -y
  #choco install skype -y
  #choco install slack -y
  #choco install zoom -y

# Browsers
  choco install googlechrome -y
  # Copy master_preferences to Chrome profile
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/master_preferences" -OutFile ${Env:ProgramFiles(x86)}"\Google\Chrome\Application\master_preferences"
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/initialbookmarks.html" -OutFile ${Env:ProgramFiles(x86)}"\Google\Chrome\Application\initialbookmarks.html"

  $Shell = New-Object -ComObject ("WScript.Shell")

  $App = $Shell.CreateShortcut("C:\Users\User\Desktop\DAZSER Web App.url")
  $App.TargetPath = "https://www.dazser.net"
  #$App.IconLocation = "$env:windir\System32\shell32.dll, 13"
  $App.Save()

  $Mail = $Shell.CreateShortcut("C:\Users\User\Desktop\Web Mail.url")
  $Mail.TargetPath = "https://mail.dazser.com"
  #$Mail.IconLocation = "$env:windir\System32\shell32.dll, 42"
  $Mail.Save()

# Windows Stuff
  #Show Powershell on Win+X instead of Command Prompt #kill explorer
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name DontUsePowerShellOnWinX -Value 0
  #File Explorer preferences
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1

  Invoke-WebRequest "https://raw.githubusercontent.com/Sparticuz/boxstarter-scripts/master/task.ps1" -UseBasicParsing | Invoke-Expression