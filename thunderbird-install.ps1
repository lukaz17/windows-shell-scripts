################################################################################
#
#  thunderbird-install
#
#  Install/Update Mozilla Thunderbird for current user. This also works as a version manager.
#
#  Homepage: https://www.thunderbird.net/
#
#  Usage:
#    thunderbird-install <version>
#
#  Example:
#    thunderbird-install 151.0.1
#    thunderbird-install v151.0.1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Mozilla Thunderbird"
$PROGRAM_NAME = "Mozilla Thunderbird"
$PROGRAM_EXEC = "thunderbird.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Normalize-InstallVersion -Version "$($InstallArgs.Version)"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -IsApplication

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).exe"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	$TEMP_CORE_TARGET = "$($InstallEnv.TempTarget)\core"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\maintenanceservice.exe"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\maintenanceservice_installer.exe"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\updater.exe"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\updater.ini"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\update-settings.ini"
	Move-Item2 -From "${TEMP_CORE_TARGET}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Copy-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
$TARGET_EXE = "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Finalize-Install
