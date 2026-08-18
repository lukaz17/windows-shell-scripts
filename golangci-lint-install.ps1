################################################################################
#
#  golangci-lint-install
#
#  Install/Update GolangCI Lint for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://golangci-lint.run/
#
#  Usage:
#    golangci-lint-install [<version>]
#
#  Example:
#    golangci-lint-install
#    golangci-lint-install 2.12.2
#    golangci-lint-install v2.12.2
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "GolangCI Lint"
$PROGRAM_EXEC = "golangci-lint.exe"

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
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = "$([IO.Path]::Combine("$($InstallEnv.TempTarget)"))"
	Move-ItemPerArch "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "golangci-lint-${INSTALL_VERSION}-windows-amd64"))" "$([IO.Path]::Combine("${TEMP_TARGET_FINAL}", "golangci-lint-${INSTALL_VERSION}-windows-arm64"))" "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
