################################################################################
#
#  jellyfin-install
#
#  Install/Update Jellyfin for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://jellyfin.org/
#
#  Usage:
#    jellyfin-install [<version>]
#
#  Example:
#    jellyfin-install
#    jellyfin-install 10.10.7
#    jellyfin-install v10.10.7
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "jellyfin"
$GITHUB_REPO = "jellyfin"
$PROGRAM_ID = "Jellyfin"
$PROGRAM_EXEC = "jellyfin.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "${GITHUB_OWNER}" -Repo "${GITHUB_REPO}" -FallbackVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://repo.jellyfin.org/files/server/windows/stable/v${INSTALL_VERSION}/amd64/jellyfin_${INSTALL_VERSION}-amd64.zip"
	$BIN_ARCH_URI_ARM64 = "https://repo.jellyfin.org/files/server/windows/stable/v${INSTALL_VERSION}/arm64/jellyfin_${INSTALL_VERSION}-arm64.zip"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "jellyfin"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)

Set-PSDebug -Trace 0
