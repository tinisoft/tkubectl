; TKubectl Installer
!include "MUI2.nsh"
!include "LogicLib.nsh"

;--------------------------------
; Variables
!define APP_NAME "TKubectl"
!define EXE_NAME "tkubectl.exe"

;--------------------------------
; General Settings
Name "${APP_NAME}${VERSION}"
OutFile "dist\${APP_NAME}${VERSION}.exe"
InstallDir "C:\Apps\TKubectl"
ShowInstDetails show
RequestExecutionLevel admin
!define MUI_ICON "assets\images\app_icon.ico"
;--------------------------------
; Pages
!insertmacro MUI_PAGE_WELCOME
Page directory
Page instfiles
!insertmacro MUI_PAGE_FINISH

; Set Finish page options
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE_NAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Run ${APP_NAME} now"

;--------------------------------
; Modern UI Settings
!insertmacro MUI_LANGUAGE "English"
!define MUI_WELCOMEPAGE_TITLE "Welcome to the ${APP_NAME} Setup"
!define MUI_WELCOMEPAGE_TEXT "This will install ${APP_NAME} on your computer.$\n$\n${APP_NAME} is a Kubernetes cluster management tool with a dark console-like interface."

;--------------------------------
Section "Install"
  ; Set output path
  SetOutPath "$INSTDIR"

  ; Copy all files from Release folder
  File /r "build\windows\x64\runner\Release\*"

  ; Get the installation directory and escape it for config.yaml
  StrCpy $R0 "$INSTDIR"
  StrCpy $R1 ""
  StrLen $R2 $R0
  StrCpy $R3 0

  ; Manual escape loop for installation path (escape backslashes)
  EscapeLoop:
    IntCmp $R3 $R2 EscapeDone
    StrCpy $R4 $R0 1 $R3
    StrCmp $R4 "\" AddEscape AddNormal
    AddEscape:
      StrCpy $R1 "$R1\\"
      Goto NextChar
    AddNormal:
      StrCpy $R1 "$R1$R4"
    NextChar:
      IntOp $R3 $R3 + 1
      Goto EscapeLoop
  EscapeDone:

  ; Check if config.yaml already exists
  IfFileExists "$INSTDIR\config.yaml" ConfigExists CreateNewConfig

  CreateNewConfig:
    ; Write default config.yaml with escaped paths (only if it doesn't exist)
    FileOpen $0 "$INSTDIR\config.yaml" w
    FileWrite $0 "kube-configs:$\r$\n"
    FileWrite $0 "  - name: $\"default-cluster$\"$\r$\n"
    FileWrite $0 "    path: $\"$R1\\.kube\\config$\"$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "# Optional: default cluster to load at startup$\r$\n"
    FileWrite $0 "default-cluster: $\"default-cluster$\"$\r$\n"
    FileClose $0
    Goto ConfigDone

  ConfigExists:
    ; Backup existing config with timestamp
    ; Get timestamp - using tick count as simple timestamp
    System::Call 'kernel32::GetTickCount() i .r1'
    CopyFiles /SILENT "$INSTDIR\config.yaml" "$INSTDIR\config.yaml.backup-$1"
    DetailPrint "Existing config.yaml preserved (backup created: config.yaml.backup-$1)"

  ConfigDone:

  ; Create Desktop Shortcut
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${EXE_NAME}"

  ; Create Start Menu Shortcut
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${EXE_NAME}"

  ; Create Uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

;--------------------------------
; Uninstaller Section
Section "Uninstall"
  ; Remove files
  RMDir /r "$INSTDIR"

  ; Remove shortcuts
  Delete "$DESKTOP\${APP_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APP_NAME}"
SectionEnd
