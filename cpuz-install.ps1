################################################################################
#
#  cpuz-install
#
#  Install/Update CPU-Z for current user. This also works as a version manager.
#
#  Homepage: https://www.cpuid.com/softwares/cpu-z.html
#
#  Usage:
#    cpuz-install <version>
#
#  Example:
#    cpuz-install 2.17
#    cpuz-install v2.17
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

# Application info
$PROGRAM_ID="CPU-Z"
$PROGRAM_NAME="CPU-Z"
$PROGRAM_EXEC="cpuz_x64.exe"

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Process arguments
$LATEST_VERSION = ""
if (${args}.Count -ge 1) {
	$LATEST_VERSION = ${args}[0].ToString()
}

# Determine version to install
if ( "${LATEST_VERSION}" -eq "" ) {
	echo "Error: Version must be explicitly specified"
	exit 1
}
$LATEST_VERSION = ${LATEST_VERSION}.TrimStart("v")

# Installation environment
$IS_ADMIN = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$ARCH = ${env:PROCESSOR_ARCHITECTURE}
if (${IS_ADMIN}) {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:PROGRAMFILES}", "${PROGRAM_ID}")
	$DESKTOP_ROOT = [IO.Path]::Combine("${env:ALLUSERSPROFILE}", "Desktop")
	$STARTMENU_ROOT = [IO.Path]::Combine("${env:ALLUSERSPROFILE}", "Start Menu", "Apps")
	$TEMP_ROOT = "${env:TEMP}"
} else {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:USERPROFILE}", ".local", "share", "${PROGRAM_ID}")
	$DESKTOP_ROOT = [IO.Path]::Combine("${env:USERPROFILE}", "Desktop")
	$STARTMENU_ROOT = [IO.Path]::Combine("${env:USERPROFILE}", "Start Menu", "Apps")
	$TEMP_ROOT = "${env:TEMP}"
}
if (${env:CLIINST_USR_LOCAL_SHARE} -ne $null) {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:CLIINST_USR_LOCAL_SHARE}", "${PROGRAM_ID}")
}
if (${env:CLIINST_TEMP} -ne $null) {
	$TEMP_ROOT = "${env:CLIINST_TEMP}"
}
$INSTALL_TARGET = [IO.Path]::Combine("${INSTALL_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}")
$ACTIVE_TARGET = [IO.Path]::Combine("${INSTALL_ROOT}", "active-release")

if (!(Test-Path "${INSTALL_ROOT}" -PathType Container)) {
	New-Item -ItemType Directory -Path "${INSTALL_ROOT}" -Force
}
if (!(Test-Path "${TEMP_ROOT}" -PathType Container)) {
	New-Item -ItemType Directory -Path "${TEMP_ROOT}" -Force
}

# Download and install binaries
if (!(Test-Path "${INSTALL_TARGET}" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://download.cpuid.com/cpu-z/cpu-z_${LATEST_VERSION}-en.zip"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = [IO.Path]::Combine("${TEMP_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}.zip")

	$ProgressPreference = "SilentlyContinue"
	if ("${ARCH}" -eq "AMD64") {
		Invoke-WebRequest -Uri "${BIN_ARCH_URI_AMD64}" -OutFile "${BIN_ARCH_TMP_FILE}"
	}
	elseif ("${ARCH}" -eq "ARM64") {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	else {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}

	$TEMP_TARGET = [IO.Path]::Combine("${TEMP_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}")
	New-Item -ItemType Directory -Path "${TEMP_TARGET}"
	if ("${ARCH}" -eq "AMD64") {
		$7ZCLI = [IO.Path]::Combine("${PSScriptRoot}", "7z-amd64", "7z.exe")
		& "${7ZCLI}" x "${BIN_ARCH_TMP_FILE}" -o"${TEMP_TARGET}"
	}
	elseif ("${ARCH}" -eq "ARM64") {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	else {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	Remove-Item "${BIN_ARCH_TMP_FILE}" -Force
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("${TEMP_TARGET}"))
	Move-Item "${TEMP_TARGET_FINAL}" "${INSTALL_TARGET}"
	if (Test-Path "${TEMP_TARGET}") {
		Remove-Item "${TEMP_TARGET}" -Recurse -Force
	}
	$ProgressPreference = "Continue"
}

# Set active release
if (Test-Path "${ACTIVE_TARGET}") {
	Remove-Item "${ACTIVE_TARGET}" -Recurse -Force
}
Copy-Item -Path "${INSTALL_TARGET}" -Destination "${ACTIVE_TARGET}" -Recurse

# Create shortcuts for quick access
$ACTIVE_TARGET_BIN = [IO.Path]::Combine("${ACTIVE_TARGET}", "${PROGRAM_EXEC}")
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut([IO.Path]::Combine("${DESKTOP_ROOT}", "${PROGRAM_NAME}.lnk"))
$Shortcut.TargetPath = "${ACTIVE_TARGET_BIN}"
$Shortcut.WorkingDirectory = "${ACTIVE_TARGET}"
$Shortcut.Save()
if (!(Test-Path "${STARTMENU_ROOT}")) {
	New-Item -ItemType Directory -Path "${STARTMENU_ROOT}"
}
$Shortcut = $WshShell.CreateShortcut([IO.Path]::Combine("${STARTMENU_ROOT}", "${PROGRAM_NAME}.lnk"))
$Shortcut.TargetPath = "${ACTIVE_TARGET_BIN}"
$Shortcut.WorkingDirectory = "${ACTIVE_TARGET}"
$Shortcut.Save()

Set-PSDebug -Trace 0
