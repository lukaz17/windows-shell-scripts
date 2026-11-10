################################################################################
#
#  nginx-install
#
#  Install/Update nginx for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://nginx.org/
#
#  Usage:
#    nginx-install [<version>]
#
#  Example:
#    nginx-install
#    nginx-install 1.30.6
#    nginx-install v1.30.6
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "NGINX"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$InstallSrc = Get-InstallSource -ProgramId "${PROGRAM_ID}"
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "$($InstallArgs.Version)" -TagPrefix "release-"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)\nginx-${INSTALL_VERSION}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Setup shared config
$CONFIG_TARGET = "$($InstallEnv.InstallRoot)\conf"
$CONFIG_DIR = "$($InstallEnv.InstallTarget)\conf"
if (!(Test-Path "${CONFIG_TARGET}" -PathType Container)) {
	if ($null -ne (Get-Item "${CONFIG_DIR}").LinkType) {
		Write-Output "Cannot create shared config using ${CONFIG_DIR}"
		exit 1
	}
	Copy-Item2 -From "${CONFIG_DIR}" -To "${CONFIG_TARGET}"
}
if ($null -eq (Get-Item "${CONFIG_DIR}").LinkType) {
	Link-Item2 -From "${CONFIG_TARGET}" -To "${CONFIG_DIR}" -Overwrite
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
