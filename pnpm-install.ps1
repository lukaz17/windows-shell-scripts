################################################################################
#
#  pnpm-install
#
#  Install/Update PNPM for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://pnpm.io/
#
#  Usage:
#    pnpm-install [<version>]
#
#  Example:
#    pnpm-install
#    pnpm-install 10.34.0
#    pnpm-install v10.34.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "pnpm"
$PROGRAM_EXEC = "pnpm.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$InstallSrc = Get-InstallSource -ProgramId "${PROGRAM_ID}"
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "$($InstallArgs.Version)"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	if (Test-VersionAtLeast -Version "${INSTALL_VERSION}" -Anchor "11") {
		$BIN_TMP_FILE = "$($InstallEnv.TempTarget).zip"
		Download-UriPerArch -Amd64Uri "${BIN_URI_AMD64}" -Arm64Uri "${BIN_URI_ARM64}" -OutputPath "${BIN_TMP_FILE}"
		New-Directory2 -Path "$($InstallEnv.TempTarget)"
		Extract-Archive -ArchivePath "${BIN_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
		Remove-Item2 -Path "${BIN_TMP_FILE}"
	} else {
		$BIN_TMP_FILE = "$($InstallEnv.TempTarget).exe"
		Download-UriPerArch -Amd64Uri "${BIN_URI_AMD64}" -Arm64Uri "${BIN_URI_ARM64}" -OutputPath "${BIN_TMP_FILE}"
		New-Directory2 -Path "$($InstallEnv.TempTarget)"
		Move-Item2 -From "${BIN_TMP_FILE}" -To "$($InstallEnv.TempTarget)\${PROGRAM_EXEC}"
	}
	Move-Item2 -From "$($InstallEnv.TempTarget)" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
$PNPM_USER_TARGET = "$($InstallEnv.UserProfileData)\.${PROGRAM_ID}"
if (Test-VersionAtLeast -Version "${INSTALL_VERSION}" -Anchor "11") {
	$PNPM_CACHE_KEY = "pnpm_config_cache_dir"
	$PNPM_BIN_TARGET = "${PNPM_USER_TARGET}\bin"
} else {
	$PNPM_CACHE_KEY = "npm_config_cache_dir"
	$PNPM_BIN_TARGET = "${PNPM_USER_TARGET}"
}
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-Directory2 -Path "${PNPM_USER_TARGET}"
New-Directory2 -Path "${PNPM_USER_TARGET}\cache"
New-Directory2 -Path "${PNPM_BIN_TARGET}"
Set-EnvVariable -Name "PNPM_HOME" -Value "${PNPM_USER_TARGET}" -IsSystemWide $false
Set-EnvVariable -Name "${PNPM_CACHE_KEY}" -Value "${PNPM_USER_TARGET}\cache" -IsSystemWide $false
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Update-CliinstPath -BinPath "${PNPM_BIN_TARGET}" -IsSystemWide $false
Finalize-Install
