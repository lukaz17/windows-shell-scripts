################################################################################
#
#  sass-install
#
#  Install/Update Dart Sass for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://sass-lang.com/
#
#  Usage:
#    sass-install [<version>]
#
#  Example:
#    sass-install
#    sass-install 1.77.0
#    sass-install v1.77.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "sass"
$GITHUB_REPO = "dart-sass"
$PROGRAM_ID = "Sass"
$PROGRAM_EXEC = "sass.bat"

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
	$BIN_ARCH_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${INSTALL_VERSION}/dart-sass-${INSTALL_VERSION}-windows-x64.zip"
	$BIN_ARCH_URI_ARM64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${INSTALL_VERSION}/dart-sass-${INSTALL_VERSION}-windows-arm64.zip"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "dart-sass"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)

Set-PSDebug -Trace 0
