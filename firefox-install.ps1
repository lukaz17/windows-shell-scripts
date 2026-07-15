################################################################################
#
#  firefox-install
#
#  Install/Update Mozilla Firefox for current user. This also works as a version manager.
#
#  Homepage: https://www.firefox.com/
#
#  Usage:
#    firefox-install <version>
#
#  Example:
#    firefox-install 151.0.3
#    firefox-install v151.0.3
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Mozilla Firefox"
$PROGRAM_NAME = "Mozilla Firefox"
$PROGRAM_EXEC = "firefox.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -IsApplication

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).exe"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "core"))
	Remove-Item2 "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "maintenanceservice.exe"))"
	Remove-Item2 "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "maintenanceservice_installer.exe"))"
	Remove-Item2 "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "updater.exe"))"
	Remove-Item2 "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "updater.ini"))"
	Remove-Item2 "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "update-settings.ini"))"
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Copy-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
$TARGET_EXE=[IO.Path]::Combine($($InstallEnv.ActiveTarget), ${PROGRAM_EXEC})
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Finalize-Install
