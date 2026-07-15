################################################################################
#
#  go-install
#
#  Install/Update Go for current user. This also works as a version manager.
#
#  Homepage: https://go.dev/
#
#  Usage:
#    go-install <version>
#
#  Example:
#    go-install 1.27.12
#    go-install v1.27.12
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Go"
$PROGRAM_EXEC = "bin\go.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
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
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "go"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
$ACTIVE_TARGET_BIN = $([IO.Path]::Combine("$($InstallEnv.ActiveTarget)", "bin"))
Update-CliinstPath -BinPath "${ACTIVE_TARGET_BIN}" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable "GOROOT" "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable "GOPATH" "$([IO.Path]::Combine("$($InstallEnv.ActiveTarget)", "Cache"))" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
