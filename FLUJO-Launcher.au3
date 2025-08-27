#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\FLUJO\public\favicon.ico
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Description=FLUJO Launcher/Installer
#AutoIt3Wrapper_Res_Fileversion=1.0.0.1
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_CompanyName=FLUJO.org
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sf /sv
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; *** Start added by AutoIt3Wrapper ***
#include <AutoItConstants.au3>
; *** End added by AutoIt3Wrapper ***
; ===============================================
; FLUJO Launcher - Interactive Version
; Launcher for FLUJO Next.js application with selective installation
; ===============================================

#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <InetConstants.au3>

; ===============================================
; CONFIGURATION SECTION
; ===============================================
Global $FLUJO_REPO = "https://github.com/mario-andreschak/FLUJO.git"
Global $INSTALL_DIR = @ScriptDir & "\FLUJO\" ; Will be updated from INI file
Global $TEMP_DIR = @TempDir & "\FLUJO-Launcher"
Global $LOG_FILE = $TEMP_DIR & "\launcher.log"
Global $INI_FILE = @ScriptDir & "\FLUJO-Launcher.ini"


; GUI Controls
Global $hGUI, $hProgress, $hStatus, $hLog, $hLogEdit
Global $hBtnInstallSelected, $hBtnStartFLUJO, $hBtnCancel, $hBtnSettings, $hBtnViewLog, $hBtnRefresh
Global $hChkGit, $hChkNode, $hChkPython, $hChkFLUJO, $hChkBuild
Global $hLblGitStatus, $hLblNodeStatus, $hLblPythonStatus, $hLblFLUJOStatus, $hLblBuildStatus
Global $hLblInstallDir ; Reference to install directory label for dynamic updates
Global $bCancelled = False
Global $bLogVisible = False
Global $bInstalling = False

; Status tracking
Global $sGitStatus = "Checking..."
Global $sNodeStatus = "Checking..."
Global $sPythonStatus = "Checking..."
Global $sFLUJOStatus = "Checking..."
Global $sBuildStatus = "Checking..."

; ===============================================
; GUI CREATION SECTION
; ===============================================
Func CreateGUI()
	$hGUI = GUICreate("FLUJO Launcher v1.0", 700, 550, -1, -1, $WS_OVERLAPPEDWINDOW)
	GUISetBkColor(0xF0F0F0)

	; Title
	GUICtrlCreateLabel("FLUJO Launcher", 20, 20, 660, 30, $SS_CENTER)
	GUICtrlSetFont(-1, 16, 600)
	GUICtrlSetColor(-1, 0x2E7D32)

	; Subtitle
	GUICtrlCreateLabel("AI Workflow Orchestration Platform", 20, 50, 660, 20, $SS_CENTER)
	GUICtrlSetFont(-1, 9)
	GUICtrlSetColor(-1, 0x666666)

	; Dependencies section
	GUICtrlCreateLabel("Dependencies Status:", 40, 90, 200, 20)
	GUICtrlSetFont(-1, 10, 600)

	; Git
	$hChkGit = GUICtrlCreateCheckbox("", 40, 120, 20, 20)
	GUICtrlCreateLabel("Git for Windows", 70, 122, 150, 20)
	$hLblGitStatus = GUICtrlCreateLabel($sGitStatus, 230, 122, 200, 20)
	GUICtrlSetColor(-1, 0x666666)

	; Node.js
	$hChkNode = GUICtrlCreateCheckbox("", 40, 150, 20, 20)
	GUICtrlCreateLabel("Node.js LTS", 70, 152, 150, 20)
	$hLblNodeStatus = GUICtrlCreateLabel($sNodeStatus, 230, 152, 200, 20)
	GUICtrlSetColor(-1, 0x666666)

	; Python
	$hChkPython = GUICtrlCreateCheckbox("", 40, 180, 20, 20)
	GUICtrlCreateLabel("Python 3.11", 70, 182, 150, 20)
	$hLblPythonStatus = GUICtrlCreateLabel($sPythonStatus, 230, 182, 200, 20)
	GUICtrlSetColor(-1, 0x666666)

	; FLUJO Repository
	$hChkFLUJO = GUICtrlCreateCheckbox("", 40, 210, 20, 20)
	GUICtrlCreateLabel("FLUJO Repository", 70, 212, 150, 20)
	$hLblFLUJOStatus = GUICtrlCreateLabel($sFLUJOStatus, 230, 212, 200, 20)
	GUICtrlSetColor(-1, 0x666666)

	; Build Status
	$hChkBuild = GUICtrlCreateCheckbox("", 40, 240, 20, 20)
	GUICtrlCreateLabel("Build Application", 70, 242, 150, 20)
	$hLblBuildStatus = GUICtrlCreateLabel($sBuildStatus, 230, 242, 200, 20)
	GUICtrlSetColor(-1, 0x666666)

	; Action buttons section
	GUICtrlCreateLabel("Actions:", 40, 280, 200, 20)
	GUICtrlSetFont(-1, 10, 600)

	; Main action buttons
	$hBtnRefresh = GUICtrlCreateButton("🔄 Refresh Status", 40, 310, 120, 35)
	GUICtrlSetFont(-1, 9, 400)

	$hBtnInstallSelected = GUICtrlCreateButton("⚙️ Install/Update Selected", 170, 310, 150, 35)
	GUICtrlSetFont(-1, 9, 600)
	GUICtrlSetBkColor(-1, 0x4CAF50)
	GUICtrlSetColor(-1, 0xFFFFFF)

	$hBtnStartFLUJO = GUICtrlCreateButton("🚀 Start FLUJO", 330, 310, 120, 35)
	GUICtrlSetFont(-1, 9, 600)
	GUICtrlSetBkColor(-1, 0x2196F3)
	GUICtrlSetColor(-1, 0xFFFFFF)

	; Progress bar
	$hProgress = GUICtrlCreateProgress(40, 360, 610, 25, $PBS_SMOOTH)
	GUICtrlSetColor(-1, 0x4CAF50)

	; Status label
	$hStatus = GUICtrlCreateLabel("Ready - Click 'Refresh Status' to check dependencies", 40, 395, 610, 20)
	GUICtrlSetFont(-1, 9)
	GUICtrlSetColor(-1, 0x333333)

	; Utility buttons
	$hBtnViewLog = GUICtrlCreateButton("View Log", 40, 430, 80, 30)
	$hBtnSettings = GUICtrlCreateButton("Settings", 130, 430, 80, 30)
	$hBtnCancel = GUICtrlCreateButton("Exit", 580, 430, 80, 30)

	; Installation directory
	GUICtrlCreateLabel("Install Directory:", 40, 480, 100, 20)
	$hLblInstallDir = GUICtrlCreateLabel($INSTALL_DIR, 150, 480, 500, 20)
	GUICtrlSetColor(-1, 0x666666)

	; FLUJO Status
	GUICtrlCreateLabel("FLUJO Status:", 40, 500, 100, 20)
	Global $hFLUJORunning = GUICtrlCreateLabel("Not Running", 150, 500, 200, 20)
	GUICtrlSetColor(-1, 0xF44336)

	; Log window (initially hidden)
	$hLog = GUICreate("Launcher Log", 700, 400, -1, -1, $WS_OVERLAPPEDWINDOW, -1, $hGUI)
	$hLogEdit = GUICtrlCreateEdit("", 10, 10, 680, 350, $ES_MULTILINE + $ES_READONLY + $WS_VSCROLL)
	GUICtrlCreateButton("Close", 610, 370, 80, 25)

	GUISetState(@SW_SHOW, $hGUI)
	WriteLog("FLUJO Launcher started")

	; Initial status check
	CheckAllDependencies()
	CheckFLUJOStatus()
EndFunc   ;==>CreateGUI

; ===============================================
; UTILITY FUNCTIONS SECTION
; ===============================================
Func WriteLog($sMessage)
	Local $sTimestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	Local $sLogEntry = "[" & $sTimestamp & "] " & $sMessage & @CRLF

	; Write to file
	If Not FileExists($TEMP_DIR) Then DirCreate($TEMP_DIR)
	FileWrite($LOG_FILE, $sLogEntry)

	; Update log window if visible
	If $bLogVisible Then
		GUICtrlSetData($hLogEdit, GUICtrlRead($hLogEdit) & $sLogEntry)
	EndIf
EndFunc   ;==>WriteLog

Func UpdateStatus($sMessage, $iProgress = -1)
	GUICtrlSetData($hStatus, $sMessage)
	If $iProgress >= 0 Then GUICtrlSetData($hProgress, $iProgress)
	WriteLog($sMessage)
EndFunc   ;==>UpdateStatus

Func UpdateDependencyStatus($sDep, $sStatus, $sColor = 0x666666)
	Switch $sDep
		Case "git"
			GUICtrlSetData($hLblGitStatus, $sStatus)
			GUICtrlSetColor($hLblGitStatus, $sColor)
		Case "node"
			GUICtrlSetData($hLblNodeStatus, $sStatus)
			GUICtrlSetColor($hLblNodeStatus, $sColor)
		Case "python"
			GUICtrlSetData($hLblPythonStatus, $sStatus)
			GUICtrlSetColor($hLblPythonStatus, $sColor)
		Case "flujo"
			GUICtrlSetData($hLblFLUJOStatus, $sStatus)
			GUICtrlSetColor($hLblFLUJOStatus, $sColor)
		Case "build"
			GUICtrlSetData($hLblBuildStatus, $sStatus)
			GUICtrlSetColor($hLblBuildStatus, $sColor)
	EndSwitch
EndFunc   ;==>UpdateDependencyStatus

Func CheckInternetConnection()
	Local $iPing = Ping("8.8.8.8", 3000)
	Return $iPing > 0
EndFunc   ;==>CheckInternetConnection

Func IsProcessRunning($sProcessName)
	Local $aProcessList = ProcessList($sProcessName)
	Return $aProcessList[0][0] > 0
EndFunc   ;==>IsProcessRunning

; ===============================================
; SETTINGS MANAGEMENT FUNCTIONS
; ===============================================
Func LoadSettings()
	WriteLog("Loading settings from: " & $INI_FILE)

	; Check if INI file exists
	If FileExists($INI_FILE) Then
		; Read install path from INI file
		Local $sSavedPath = IniRead($INI_FILE, "Settings", "InstallPath", "")
		If $sSavedPath <> "" And FileExists($sSavedPath) Then
			$INSTALL_DIR = $sSavedPath
			WriteLog("Loaded install path from INI: " & $INSTALL_DIR)
		Else
			WriteLog("Invalid path in INI file, using default: " & $INSTALL_DIR)
		EndIf
	Else
		WriteLog("INI file not found, using default path: " & $INSTALL_DIR)
		; Create INI file with default settings
		SaveSettings()
	EndIf
EndFunc   ;==>LoadSettings

Func SaveSettings()
	WriteLog("Saving settings to: " & $INI_FILE)

	; Write install path to INI file
	IniWrite($INI_FILE, "Settings", "InstallPath", $INSTALL_DIR)

	; Add timestamp for reference
	IniWrite($INI_FILE, "Settings", "LastUpdated", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)

	WriteLog("Settings saved successfully")
EndFunc   ;==>SaveSettings

Func InitializeInstallDir()
	; Load settings from INI file first
	LoadSettings()

	; If no valid path was loaded, ensure we have a default
	If $INSTALL_DIR = "" Then
		$INSTALL_DIR = @ScriptDir
		SaveSettings()
	EndIf

	WriteLog("Install directory initialized to: " & $INSTALL_DIR)
EndFunc   ;==>InitializeInstallDir

Func UpdateInstallDirDisplay()
	; Update the install directory label in the GUI
	If $hLblInstallDir <> 0 Then
		GUICtrlSetData($hLblInstallDir, $INSTALL_DIR)
		WriteLog("Updated install directory display to: " & $INSTALL_DIR)
	EndIf
EndFunc   ;==>UpdateInstallDirDisplay

; ===============================================
; DEPENDENCY CHECK FUNCTIONS
; ===============================================
Func CheckAllDependencies()
	UpdateStatus("Checking dependencies...", 10)

	; Check Git
	If IsGitInstalled() Then
		Local $sVersion = GetGitVersion()
		UpdateDependencyStatus("git", "✅ Installed (" & $sVersion & ")", 0x4CAF50)
	Else
		UpdateDependencyStatus("git", "❌ Not Installed", 0xF44336)
		GUICtrlSetState($hChkGit, $GUI_CHECKED)
	EndIf

	; Check Node.js
	If IsNodeInstalled() Then
		Local $sVersion = GetNodeVersion()
		UpdateDependencyStatus("node", "✅ Installed (" & $sVersion & ")", 0x4CAF50)
	Else
		UpdateDependencyStatus("node", "❌ Not Installed", 0xF44336)
		GUICtrlSetState($hChkNode, $GUI_CHECKED)
	EndIf

	; Check Python
	If IsPythonInstalled() Then
		Local $sVersion = GetPythonVersion()
		UpdateDependencyStatus("python", "✅ Installed (" & $sVersion & ")", 0x4CAF50)
	Else
		UpdateDependencyStatus("python", "❌ Not Installed", 0xF44336)
		GUICtrlSetState($hChkPython, $GUI_CHECKED)
	EndIf

	; Check FLUJO Repository
	If FileExists($INSTALL_DIR & "\package.json") Then
		UpdateDependencyStatus("flujo", "✅ Repository Found", 0x4CAF50)

		; Check if built
		If FileExists($INSTALL_DIR & "\.next") Then
			UpdateDependencyStatus("build", "✅ Built", 0x4CAF50)
		Else
			UpdateDependencyStatus("build", "⚠️ Not Built", 0xFF9800)
			GUICtrlSetState($hChkBuild, $GUI_CHECKED)
		EndIf
	Else
		UpdateDependencyStatus("flujo", "❌ Not Found", 0xF44336)
		UpdateDependencyStatus("build", "❌ No Repository", 0xF44336)
		GUICtrlSetState($hChkFLUJO, $GUI_CHECKED)
		GUICtrlSetState($hChkBuild, $GUI_CHECKED)
	EndIf

	UpdateStatus("Dependency check completed", 100)
	Sleep(1000)
	UpdateStatus("Ready - Select items to install/update, or start FLUJO", 0)
EndFunc   ;==>CheckAllDependencies

Func IsGitInstalled()
	Local $sGitPath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows", "InstallPath")
	If @error Then $sGitPath = RegRead("HKEY_CURRENT_USER\SOFTWARE\GitForWindows", "InstallPath")

	If Not @error And FileExists($sGitPath & "\bin\git.exe") Then
		Return True
	EndIf

	; Check PATH
	Local $sResult = RunWait(@ComSpec & " /c git --version", "", @SW_HIDE, $STDOUT_CHILD)
	Return $sResult = 0
EndFunc   ;==>IsGitInstalled

Func IsNodeInstalled()
	Local $sResult = RunWait(@ComSpec & " /c node --version", "", @SW_HIDE, $STDOUT_CHILD)
	Return $sResult = 0
EndFunc   ;==>IsNodeInstalled

Func IsPythonInstalled()
	Local $sResult = RunWait(@ComSpec & " /c python --version", "", @SW_HIDE, $STDOUT_CHILD)
	Return $sResult = 0
EndFunc   ;==>IsPythonInstalled

Func GetGitVersion()
	Local $sOutput = ""
	Local $iPID = Run(@ComSpec & " /c git --version", "", @SW_HIDE, $STDOUT_CHILD)
	While ProcessExists($iPID)
		$sOutput &= StdoutRead($iPID)
		Sleep(10)
	WEnd
	Return StringRegExpReplace($sOutput, "git version ([0-9.]+).*", "$1")
EndFunc   ;==>GetGitVersion

Func GetNodeVersion()
	Local $sOutput = ""
	Local $iPID = Run(@ComSpec & " /c node --version", "", @SW_HIDE, $STDOUT_CHILD)
	While ProcessExists($iPID)
		$sOutput &= StdoutRead($iPID)
		Sleep(10)
	WEnd
	Return StringStripWS($sOutput, 3)
EndFunc   ;==>GetNodeVersion

Func GetPythonVersion()
	Local $sOutput = ""
	Local $iPID = Run(@ComSpec & " /c python --version", "", @SW_HIDE, $STDOUT_CHILD)
	While ProcessExists($iPID)
		$sOutput &= StdoutRead($iPID)
		Sleep(10)
	WEnd
	Return StringRegExpReplace($sOutput, "Python ([0-9.]+).*", "$1")
EndFunc   ;==>GetPythonVersion

; ===============================================
; INSTALLATION FUNCTIONS
; ===============================================
Func InstallSelectedItems()
	$bInstalling = True
	GUICtrlSetState($hBtnInstallSelected, $GUI_DISABLE)
	GUICtrlSetState($hBtnStartFLUJO, $GUI_DISABLE)

	Local $iProgress = 0
	Local $iTotalSteps = 0

	; Count selected items
	If GUICtrlRead($hChkGit) = $GUI_CHECKED Then $iTotalSteps += 1
	If GUICtrlRead($hChkNode) = $GUI_CHECKED Then $iTotalSteps += 1
	If GUICtrlRead($hChkPython) = $GUI_CHECKED Then $iTotalSteps += 1
	If GUICtrlRead($hChkFLUJO) = $GUI_CHECKED Then $iTotalSteps += 1
	If GUICtrlRead($hChkBuild) = $GUI_CHECKED Then $iTotalSteps += 1

	If $iTotalSteps = 0 Then
		UpdateStatus("No items selected for installation", 0)
		$bInstalling = False
		GUICtrlSetState($hBtnInstallSelected, $GUI_ENABLE)
		GUICtrlSetState($hBtnStartFLUJO, $GUI_ENABLE)
		Return
	EndIf

	Local $iCurrentStep = 0
	Local $bRestart = False

	; Install Git
	If GUICtrlRead($hChkGit) = $GUI_CHECKED Then
		$iCurrentStep += 1
		UpdateStatus("Installing Git... (" & $iCurrentStep & "/" & $iTotalSteps & ")", ($iCurrentStep / $iTotalSteps) * 100)
		If InstallGit() Then
			GUICtrlSetState($hChkGit, $GUI_UNCHECKED)
			$bRestart = True
		EndIf
	EndIf

	; Install Node.js
	If GUICtrlRead($hChkNode) = $GUI_CHECKED Then
		$iCurrentStep += 1
		UpdateStatus("Installing Node.js... (" & $iCurrentStep & "/" & $iTotalSteps & ")", ($iCurrentStep / $iTotalSteps) * 100)
		If InstallNodeJS() Then
			GUICtrlSetState($hChkNode, $GUI_UNCHECKED)
			$bRestart = True
		EndIf
	EndIf

	; Install Python
	If GUICtrlRead($hChkPython) = $GUI_CHECKED Then
		$iCurrentStep += 1
		UpdateStatus("Installing Python... (" & $iCurrentStep & "/" & $iTotalSteps & ")", ($iCurrentStep / $iTotalSteps) * 100)
		If InstallPython() Then
			GUICtrlSetState($hChkPython, $GUI_UNCHECKED)
			$bRestart = True
		EndIf
	EndIf

	If $bRestart = True Then
		MsgBox(0, "Restart Launcher", "FLUJO Launcher will re-start after Installation of Git, Node or Python")
		If Not @Compiled Then ShellExecute(@AutoItExe, @ScriptFullPath)
		If @Compiled Then ShellExecute(@AutoItExe)
		Exit
	EndIf

	; Clone/Update FLUJO
	If GUICtrlRead($hChkFLUJO) = $GUI_CHECKED Then
		$iCurrentStep += 1
		UpdateStatus("Setting up FLUJO... (" & $iCurrentStep & "/" & $iTotalSteps & ")", ($iCurrentStep / $iTotalSteps) * 100)
		If CloneFLUJO() Then
			GUICtrlSetState($hChkFLUJO, $GUI_UNCHECKED)
		EndIf
	EndIf

	; Build FLUJO
	If GUICtrlRead($hChkBuild) = $GUI_CHECKED Then
		$iCurrentStep += 1
		UpdateStatus("Building FLUJO... (" & $iCurrentStep & "/" & $iTotalSteps & ")", ($iCurrentStep / $iTotalSteps) * 100)
		If BuildFLUJO() Then
			GUICtrlSetState($hChkBuild, $GUI_UNCHECKED)
		EndIf
	EndIf

	UpdateStatus("Installation completed! Refreshing status...", 100)
	Sleep(1000)
	CheckAllDependencies()

	$bInstalling = False
	GUICtrlSetState($hBtnInstallSelected, $GUI_ENABLE)
	GUICtrlSetState($hBtnStartFLUJO, $GUI_ENABLE)
EndFunc   ;==>InstallSelectedItems


; ===============================================
; WINGET INSTALLATION FUNCTIONS
; ===============================================
Func InstallGit()
	If IsGitInstalled() Then
		WriteLog("Git is already installed")
		Return True
	EndIf

	WriteLog("Installing Git using winget")


	Local $sCmd = "winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements"
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	WriteLog("Git installation completed via winget")
	Return True
EndFunc   ;==>InstallGit

Func InstallNodeJS()
	If IsNodeInstalled() Then
		WriteLog("Node.js is already installed")
		Return True
	EndIf

	WriteLog("Installing Node.js using winget")

	Local $sCmd = "winget install -e --id OpenJS.NodeJS"
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	WriteLog("Node.js installation completed via winget")
	Return True
EndFunc   ;==>InstallNodeJS

Func InstallPython()
	If IsPythonInstalled() Then
		WriteLog("Python is already installed")
		Return True
	EndIf

	WriteLog("Installing Python using winget")

	Local $sCmd = "winget install --id Python.Python.3.11 -e --source winget --accept-package-agreements --accept-source-agreements"
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	WriteLog("Python installation completed via winget")
	Return True
EndFunc   ;==>InstallPython

Func CloneFLUJO()
	WriteLog("Setting up FLUJO repository to: " & $INSTALL_DIR)

	; Check if directory exists and handle appropriately
	If FileExists($INSTALL_DIR) Then
		; Check if it's already a git repository
		If FileExists($INSTALL_DIR & "\.git") Then
			WriteLog("Git repository already exists, updating...")
			Local $sCmd = "git -C " & Chr(34) & $INSTALL_DIR & Chr(34) & " pull origin main"
		ElseIf FileExists($INSTALL_DIR & "\package.json") Then
			WriteLog("FLUJO directory exists but not a git repo, updating via git pull...")
			Local $sCmd = "git -C " & Chr(34) & $INSTALL_DIR & Chr(34) & " pull origin main"
		Else
			; Directory exists but is not empty and not a FLUJO repo
			Local $aFileList = _FileListToArray($INSTALL_DIR)
			If IsArray($aFileList) And $aFileList[0] > 0 Then
				WriteLog("Directory is not empty and not a FLUJO repository. Cannot clone.")
				MsgBox(48, "Directory Not Empty", "The installation directory is not empty and does not contain a FLUJO repository." & @CRLF & @CRLF & "Please select an empty directory or a directory with an existing FLUJO repository.")
				Return False
			Else
				; Directory is empty, safe to clone
				Local $sCmd = "git clone " & $FLUJO_REPO & " " & Chr(34) & $INSTALL_DIR & Chr(34)
			EndIf
		EndIf
	Else
		; Directory doesn't exist, create it and clone
		WriteLog("Creating directory and cloning repository...")
		Local $sCmd = "git clone " & $FLUJO_REPO & " " & Chr(34) & $INSTALL_DIR & Chr(34)
	EndIf

	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	Return FileExists($INSTALL_DIR & "\.git")
EndFunc   ;==>CloneFLUJO

Func BuildFLUJO()
	WriteLog("Building FLUJO application")

	; Run npm install
	Local $sCmd = "npm install"
	Local $iPID = Run(@ComSpec & " /c cd /d " & Chr(34) & $INSTALL_DIR & Chr(34) & " && " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	; Run npm run build
	$sCmd = "npm run build"
	$iPID = Run(@ComSpec & " /c cd /d " & Chr(34) & $INSTALL_DIR & Chr(34) & " && " & $sCmd, "", @SW_SHOW)

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	Return FileExists($INSTALL_DIR & "\.next")
EndFunc   ;==>BuildFLUJO

Func DownloadFile($sURL, $sDestination, $sDescription = "file")
	WriteLog("Downloading " & $sDescription & " from: " & $sURL)

	Local $hDownload = InetGet($sURL, $sDestination, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)

	While Not InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
		If $bCancelled Then
			InetClose($hDownload)
			Return False
		EndIf
		Sleep(100)
	WEnd

	InetClose($hDownload)
	Return FileExists($sDestination) And FileGetSize($sDestination) > 0
EndFunc   ;==>DownloadFile

Func RunSilentInstaller($sInstaller, $sArgs, $sDescription)
	WriteLog("Installing " & $sDescription & ": " & $sInstaller & " " & $sArgs)

	Local $iPID = Run($sInstaller & " " & $sArgs, "", @SW_HIDE)

	If $iPID = 0 Then
		WriteLog("Failed to start installer for " & $sDescription)
		Return False
	EndIf

	While ProcessExists($iPID)
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf
		Sleep(1000)
	WEnd

	WriteLog("Installation of " & $sDescription & " completed")
	Return True
EndFunc   ;==>RunSilentInstaller

; ===============================================
; FLUJO STATUS CHECK FUNCTIONS
; ===============================================
Func CheckFLUJOStatus()
	WriteLog("Checking FLUJO status via web connection to localhost:4200")

	; Try to connect to localhost:4200
	Local $hDownload = InetRead("http://localhost:4200")

	If @error Then
		; FLUJO is not running
		GUICtrlSetData($hFLUJORunning, "Not Running")
		GUICtrlSetColor($hFLUJORunning, 0xF44336)
		WriteLog("FLUJO is not running - no response from localhost:4200")
	Else
		; FLUJO is running
		GUICtrlSetData($hFLUJORunning, "✅ Running on localhost:4200")
		GUICtrlSetColor($hFLUJORunning, 0x4CAF50)
		WriteLog("FLUJO is running - successfully connected to localhost:4200")
	EndIf

	InetClose($hDownload)
EndFunc   ;==>CheckFLUJOStatus

; ===============================================
; FLUJO MANAGEMENT FUNCTIONS
; ===============================================
Func StartFLUJO()
	If Not FileExists($INSTALL_DIR & "\package.json") Then
		MsgBox(48, "FLUJO Not Found", "FLUJO repository not found. Please install FLUJO first.")
		Return False
	EndIf

	UpdateStatus("Starting FLUJO server...", 50)
	WriteLog("Starting FLUJO application")

	; Start npm start in background
	Local $sCmd = "npm start"
	Local $iPID = Run(@ComSpec & " /c cd /d " & Chr(34) & $INSTALL_DIR & Chr(34) & " && " & $sCmd, "", @SW_HIDE)

	; Wait for server to start (check for port 4200)
	Local $iTimeout = 30
	Local $iCounter = 0

	While $iCounter < $iTimeout
		If $bCancelled Then
			ProcessClose($iPID)
			Return False
		EndIf

		; Check if port 4200 is listening
		Local $sResult = RunWait(@ComSpec & " /c netstat -an | findstr :4200", "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
		If $sResult = 0 Then
			WriteLog("FLUJO server is running on port 4200")
			UpdateStatus("FLUJO started successfully! Opening browser...", 100)

			; Open browser
			ShellExecute("http://localhost:4200")

			Sleep(2000)
			UpdateStatus("FLUJO is running at http://localhost:4200", 0)
			Return True
		EndIf

		Sleep(1000)
		$iCounter += 1
		UpdateStatus("Starting FLUJO server... (" & $iCounter & "/" & $iTimeout & ")", 50)
	WEnd

	WriteLog("Timeout waiting for FLUJO server to start")
	UpdateStatus("Failed to start FLUJO - check if dependencies are installed", 0)
	Return False
EndFunc   ;==>StartFLUJO

; ===============================================
; GUI EVENT HANDLING
; ===============================================
Func HandleEvents()
	While True
		Local $nMsg = GUIGetMsg(1) ; Get extended info to identify which window

		Switch $nMsg[1] ; Check which window the event came from
			Case $hGUI ; Main window events
				Switch $nMsg[0]
					Case $GUI_EVENT_CLOSE
						$bCancelled = True
						Exit

					Case $hBtnCancel
						$bCancelled = True
						Exit

					Case $hBtnRefresh
						If Not $bInstalling Then
							CheckAllDependencies()
							CheckFLUJOStatus()
						EndIf

					Case $hBtnInstallSelected
						If Not $bInstalling Then
							InstallSelectedItems()
						EndIf

					Case $hBtnStartFLUJO
						If Not $bInstalling Then
							StartFLUJO()
						EndIf

					Case $hBtnViewLog
						If Not $bLogVisible Then
							If FileExists($LOG_FILE) Then
								Local $sLogContent = FileRead($LOG_FILE)
								GUICtrlSetData($hLogEdit, $sLogContent)
							EndIf
							GUISetState(@SW_SHOW, $hLog)
							$bLogVisible = True
						Else
							GUISetState(@SW_HIDE, $hLog)
							$bLogVisible = False
						EndIf

					Case $hBtnSettings
						Local $sNewDir = FileSelectFolder("Select FLUJO Installation Directory", "", 0, $INSTALL_DIR)
						If $sNewDir <> "" Then
							$INSTALL_DIR = $sNewDir
							SaveSettings()
							UpdateInstallDirDisplay()
							CheckAllDependencies()
						EndIf
				EndSwitch

			Case $hLog ; Log window events
				Switch $nMsg[0]
					Case $GUI_EVENT_CLOSE
						; Just hide the log window, don't exit the application
						GUISetState(@SW_HIDE, $hLog)
						$bLogVisible = False
					Case Else
						; Handle log window button clicks (Close button)
						If $nMsg[0] > 0 Then ; It's a control ID
							GUISetState(@SW_HIDE, $hLog)
							$bLogVisible = False
						EndIf
				EndSwitch

			Case 0 ; No window (shouldn't happen with extended mode)
				; Handle any other events that don't belong to specific windows
		EndSwitch

		Sleep(10)
	WEnd
EndFunc   ;==>HandleEvents

; ===============================================
; MAIN EXECUTION
; ===============================================
; Initialize install directory from INI file before creating GUI
InitializeInstallDir()

CreateGUI()
HandleEvents()
