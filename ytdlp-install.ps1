################################################################################
#
#  ytdlp-install
#
#  Install/Update yt-dlp for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://github.com/yt-dlp/yt-dlp
#
#  Usage:
#    ytdlp-install [<version>]
#
#  Example:
#    ytdlp-install
#    ytdlp-install 2025.12.08
#    ytdlp-install v2025.12.08
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "ytdlp"
$PROGRAM_EXEC = "yt-dlp.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$InstallSrc = Get-InstallSource "${PROGRAM_ID}"
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "$($InstallSrc.GithubOwner)" -Repo "$($InstallSrc.GithubRepo)" -FallbackVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_TMP_FILE = "$($InstallEnv.TempTarget).exe"
	Download-UriPerArch -Amd64Uri "${BIN_URI_AMD64}" -Arm64Uri "${BIN_URI_ARM64}" -OutputPath "${BIN_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Move-Item2 -From "${BIN_TMP_FILE}" -To ([IO.Path]::Combine($($InstallEnv.TempTarget), ${PROGRAM_EXEC}))
	Move-Item2 -From "$([IO.Path]::Combine($($InstallEnv.TempTarget)))" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
