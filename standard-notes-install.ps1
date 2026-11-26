################################################################################
#
#  standard-notes-install
#
#  Install/Update Standard Notes for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://standardnotes.com/
#
#  Usage:
#    standard-notes-install [<version>]
#
#  Example:
#    standard-notes-install
#    standard-notes-install 3.203.0
#    standard-notes-install v3.203.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Standard Notes"
$PROGRAM_NAME = "Standard Notes"
$PROGRAM_EXEC = "Standard Notes.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$InstallSrc = Get-InstallSource -ProgramId "${PROGRAM_ID}"
# Only desktop releases are non-prerelease in this repo, so the latest release is always a desktop one
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "$($InstallArgs.Version)" -TagPrefix "@standardnotes/desktop@"
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
	# Electron-builder installer packs the app files into a nested archive
	$APP_ARCH_FILE = "$($InstallEnv.TempTarget)\`$PLUGINSDIR\app-64.7z"
	$TEMP_APP_TARGET = "$($InstallEnv.TempTarget)\app"
	Extract-Archive -ArchivePath "${APP_ARCH_FILE}" -DestinationPath "${TEMP_APP_TARGET}" -ScriptRoot "${PSScriptRoot}"
	# Disable auto-update: it runs the official installer, which installs outside the version folders
	Remove-Item2 -Path "${TEMP_APP_TARGET}\resources\app-update.yml"
	Move-Item2 -From "${TEMP_APP_TARGET}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Finalize-Install
