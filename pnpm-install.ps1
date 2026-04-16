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
#    pnpm-install 10.25.0
#    pnpm-install v10.25.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "pnpm"
$GITHUB_REPO = "pnpm"
$PROGRAM_ID = "pnpm"
$PROGRAM_EXEC = "pnpm.exe"

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
	$BIN_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${INSTALL_VERSION}/pnpm-win-x64.exe"
	$BIN_URI_ARM64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${INSTALL_VERSION}/pnpm-win-arm64.exe"
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

Set-PSDebug -Trace 0
