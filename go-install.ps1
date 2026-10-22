################################################################################
#
#  go-install
#
#  Install/Update Go for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://go.dev/
#
#  Usage:
#    go-install [<version>]
#
#  Example:
#    go-install
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

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get latest Go version
# ------------------------------------------------------------------------------
function Get-InstallVersionFromGoDev {
	param(
		[Parameter()] [string] $FallbackVersion = ""
	)

	if ("${FallbackVersion}" -eq "") {
		$version = ((Invoke-WebRequest -UseBasicParsing "https://go.dev/VERSION?m=text").Content -Split "`n")[0]
	} else {
		$version = ${FallbackVersion}
	}

	$version = ${version}.TrimStart("go")
	Write-Host "> Latest Version:  ${version}"
	return Normalize-InstallVersion -Version "${version}"
}

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Get-InstallVersionFromGoDev -FallbackVersion "${INSTALL_VERSION}"
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
	Move-Item2 -From "$($InstallEnv.TempTarget)\go" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)\bin" -IsSystemWide $($InstallEnv.IsAdmin)
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)\cache\bin" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable -Name "GOROOT" -Value "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable -Name "GOPATH" -Value "$($InstallEnv.ActiveTarget)\cache" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
