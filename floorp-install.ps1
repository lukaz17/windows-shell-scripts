################################################################################
#
#  floorp-install
#
#  Install/Update Floorp for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://floorp.app/
#
#  Usage:
#    floorp-install [<version>]
#
#  Example:
#    floorp-install
#    floorp-install 12.21.1
#    floorp-install v12.21.1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Floorp"
$PROGRAM_NAME = "Floorp"
$PROGRAM_EXEC = "floorp.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$InstallSrc = Get-InstallSource -ProgramId "${PROGRAM_ID}"
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "$($InstallArgs.Version)"
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
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\updater.exe"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\updater.ini"
	Remove-Item2 -Path "${TEMP_CORE_TARGET}\update-settings.ini"
	Move-Item2 -From "${TEMP_CORE_TARGET}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
# Copy, not link: Floorp derives installation ID from exe path; junction resolves to versioned path, which breaks user profiles.
Copy-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Finalize-Install
