################################################################################
#
#  bifrost-http-install
#
#  Install/Update Bifrost LLM Gateway for current user. This also works as a version manager.
#
#  Homepage: https://www.getmaxim.ai/bifrost
#
#  Usage:
#    bifrost-http-install <version>
#
#  Example:
#    bifrost-http-install 1.7.1
#    bifrost-http-install v1.7.1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "maximhq"
$GITHUB_REPO = "bifrost"
$PROGRAM_ID = "Bifrost HTTP"
$PROGRAM_EXEC = "bifrost-http.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_URI_AMD64 = "https://downloads.getmaxim.ai/bifrost/v${INSTALL_VERSION}/windows/amd64/bifrost-http.exe"
	$BIN_URI_ARM64 = ""
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
