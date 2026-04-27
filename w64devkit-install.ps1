################################################################################
#
#  w64devkit-install
#
#  Install/Update w64devkit for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://github.com/skeeto/w64devkit
#
#  Usage:
#    w64devkit-install [<version>]
#
#  Example:
#    w64devkit-install
#    w64devkit-install 2.7.0
#    w64devkit-install v2.7.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "skeeto"
$GITHUB_REPO = "w64devkit"
$PROGRAM_ID = "w64devkit"
$PROGRAM_EXEC = "bin/gcc"

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
	$BIN_ARCH_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${INSTALL_VERSION}/w64devkit-x64-${INSTALL_VERSION}.7z.exe"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).7z"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "w64devkit"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
$ACTIVE_TARGET_BIN = $([IO.Path]::Combine("$($InstallEnv.ActiveTarget)", "bin"))
Update-CliinstPath -BinPath "${ACTIVE_TARGET_BIN}" -IsSystemWide $($InstallEnv.IsAdmin)

Set-PSDebug -Trace 0
