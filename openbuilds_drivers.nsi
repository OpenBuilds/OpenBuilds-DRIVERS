# Import some useful functions.
!include WinVer.nsh   # Windows version detection.
!include x64.nsh      # X86/X64 version detection.

!define VERSION 1.0.0.0

# Set attributes that describe the installer.
Icon "Assets\openbuilds.ico"
Caption "OpenBuilds USB to UART drivers"
Name "OpenBuilds USB Drivers"
Outfile "openbuilds_usb_drivers_${VERSION}.exe"
ManifestSupportedOS "all"
SpaceTexts "none"
ShowInstDetails "show"

# Install driver files to a temporary location (then dpinst will handle the real install).
InstallDir "$TEMP\openbuilds_drivers"

# Set properties on the installer exe that will be generated.
VIAddVersionKey /LANG=1033 "ProductName" "OpenBuilds USB to UART drivers"
VIAddVersionKey /LANG=1033 "CompanyName" "OpenBuilds"
VIAddVersionKey /LANG=1033 "LegalCopyright" "OpenBuilds"
VIAddVersionKey /LANG=1033 "FileDescription" "OpenBuilds USB to UART drivers (FTDI and Silicon Labs)"
VIAddVersionKey /LANG=1033 "FileVersion" "1.0.0.0"
VIProductVersion ${VERSION}
VIFileVersion ${VERSION}

# Define variables used in sections.
Var dpinst   # Will hold the path and name of dpinst being used (x86 or x64).

# Define the standard pages in the installer.
# License page shows the contents of license.rtf.
PageEx license
  LicenseData "license.rtf"
PageExEnd

# Components page allows user to pick the drivers to install.
PageEx components
  ComponentText "Select the drivers that you would like to install below.  Click install to start the installation.  If in doubt, select all of them." \
    "" "Select drivers to install:"
PageExEnd

# Instfiles page does the actual installation.
Page instfiles


# Sections define the components (drivers) that can be installed.
# The section name is displayed in the component select screen and if selected
# the code in the section will be executed during the install.
# Note that /o before the name makes the section optional and not selected by default.

# This first section is hidden and always selected so it runs first and bootstraps
# the install by copying all the files and dpinst to the temp folder location.
Section
  DetailPrint "Extract Drivers..."
  # Copy all the drivers and dpinst exes to the temp location.
  SetOutPath $INSTDIR
  File /r "Drivers"
  File "dpinst-x64.exe"
  File "dpinst-x86.exe"
  # Set dpinst variable based on the current OS type (x86/x64).
  ${If} ${RunningX64}
    StrCpy $dpinst "$INSTDIR\dpinst-x64.exe"
  ${Else}
    StrCpy $dpinst "$INSTDIR\dpinst-x86.exe"
  ${EndIf}
SectionEnd

Section "FTDI USB to Serial"
  DetailPrint "Installing FTDI USB to Serial drivers..."
  ${If} ${AtLeastWin10}
    ${If} ${RunningX64}
      ExecWait '"$dpinst"  /q /se /path "$INSTDIR\Drivers\FTDI_UNI\x64"'
    ${Else}
      ExecWait '"$dpinst"  /q /se /path "$INSTDIR\Drivers\FTDI_UNI\x86"'
    ${EndIf}
  ${Else}
    ExecWait '"$dpinst"  /q /se /path "$INSTDIR\Drivers\FTDI_VCP_PORT"'
    ExecWait '"$dpinst"  /q /se /path "$INSTDIR\Drivers\FTDI_VCP_BUS"'
  ${EndIf}
SectionEnd

Section "Silicon Labs USB Uart"
  DetailPrint "Installing Silicon Labs USB Uart drivers..."
  ${If} ${AtMostWinVista}
    # Use older driver for XP & Vista.
    ExecWait '"$dpinst" /sw /path "$INSTDIR\Drivers\SiLabs_CP210x\WinVista"'
  ${ElseIf} ${AtLeastWin10}
      ExecWait '"$dpinst" /sw /path "$INSTDIR\Drivers\SiLabs_CP210x\Win1011"'
  ${Else}
    # User newer driver for 7 and beyond.
    ExecWait '"$dpinst" /sw /path "$INSTDIR\Drivers\SiLabs_CP210x\Win7"'
  ${EndIf}
SectionEnd

Function .onRebootFailed
   MessageBox MB_OK|MB_ICONSTOP "Reboot failed. Please reboot manually." /SD IDOK
 FunctionEnd

Function .onInstSuccess
  MessageBox MB_YESNO|MB_ICONQUESTION "Would you like to Reboot?   A reboot is required to complete the Installation of the OpenBuilds USB to UART drivers.  We strongly recommend you reboot now." IDNO +2
  Reboot
FunctionEnd

# Unselect, disable, and hide the given section.
!macro HideSectionMacro SectionId
  SectionSetFlags ${SectionId} ${SF_RO}
  SectionSetText ${SectionId} ""
!macroend

!define HideSection '!insertMacro HideSectionMacro'
