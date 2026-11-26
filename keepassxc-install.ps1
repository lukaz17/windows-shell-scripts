################################################################################
#
#  keepassxc-install
#
#  Install/Update KeePassXC for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://keepassxc.org/
#
#  Usage:
#    keepassxc-install [<version>]
#
#  Example:
#    keepassxc-install
#    keepassxc-install 2.8.0
#    keepassxc-install v2.8.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "KeePassXC"
$PROGRAM_NAME = "KeePassXC"
$PROGRAM_EXEC = "KeePassXC.exe"

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
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	$BIN_AMD64_TAG = if (Test-VersionAtLeast -Version "${INSTALL_VERSION}" -Anchor "2.8") { "x64" } else { "Win64" }
	Move-ItemPerArch -Amd64Path "$($InstallEnv.TempTarget)\KeePassXC-${INSTALL_VERSION}-${BIN_AMD64_TAG}" -Arm64Path "$($InstallEnv.TempTarget)\KeePassXC-${INSTALL_VERSION}-ARM64" -OutputPath "$($InstallEnv.TempTarget)\KeePassXC-${INSTALL_VERSION}"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)\KeePassXC-${INSTALL_VERSION}\.portable"
	Move-Item2 -From "$($InstallEnv.TempTarget)\KeePassXC-${INSTALL_VERSION}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
