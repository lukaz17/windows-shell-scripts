################################################################################
#
#  bun-install
#
#  Install/Update Bun for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://bun.sh/
#
#  Usage:
#    bun-install [<version>]
#
#  Example:
#    bun-install
#    bun-install 1.3.14
#    bun-install v1.3.14
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Bun"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$InstallSrc = Get-InstallSource -ProgramId "${PROGRAM_ID}"
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "$($InstallArgs.Version)" -TagPrefix "bun-"
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
	Move-ItemPerArch -Amd64Path "$($InstallEnv.TempTarget)\bun-windows-x64" -Arm64Path "$($InstallEnv.TempTarget)\bun-windows-aarch64" -OutputPath "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
$BUN_USER_TARGET = "$($InstallEnv.UserProfileData)\.${PROGRAM_ID}"
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-Directory2 -Path "${BUN_USER_TARGET}"
New-Directory2 -Path "${BUN_USER_TARGET}\cache"
Set-EnvVariable -Name "BUN_INSTALL_BIN" -Value "${BUN_USER_TARGET}" -IsSystemWide $false
Set-EnvVariable -Name "BUN_INSTALL_CACHE_DIR" -Value "${BUN_USER_TARGET}\cache" -IsSystemWide $false
Set-EnvVariable -Name "BUN_INSTALL_GLOBAL_DIR" -Value "${BUN_USER_TARGET}" -IsSystemWide $false
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Update-CliinstPath -BinPath "${BUN_USER_TARGET}" -IsSystemWide $false
Finalize-Install
