################################################################################
#
#  mariadb-install
#
#  Install/Update MariaDB Community Server for current user. This also works as a version manager.
#
#  Homepage: https://mariadb.com/
#
#  Usage:
#    mariadb-install <version> [--default]
#
#    --default makes this major version the one on PATH, later updates of that major version follow.
#
#  Example:
#    mariadb-install 12.2
#    mariadb-install 12.2.2
#    mariadb-install v12.2
#    mariadb-install v12.2.2
#    mariadb-install 12.2 --default
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "MariaDB"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get latest MariaDB version of a series, a full version resolves to itself
# ------------------------------------------------------------------------------
function Get-InstallVersionFromMariaDb {
	param(
		[Parameter(Mandatory)] [string] $Version
	)

	$apiResponse = Invoke-WebRequest -UseBasicParsing "https://downloads.mariadb.org/rest-api/mariadb/${Version}" | ConvertFrom-Json
	if ($apiResponse.PSObject.Properties.Name -contains "releases") {
		$latestVersion = @($apiResponse.releases.PSObject.Properties.Name | Sort-Object {[version]$_} -Descending)[0]
	} else {
		$latestVersion = @($apiResponse.release_data.PSObject.Properties.Name)[0]
	}

	Write-Host "> Latest Version:  ${latestVersion}"
	return ${latestVersion}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Normalize-InstallVersion -Version "$($InstallArgs.Version)"
$INSTALL_VERSION = Get-InstallVersionFromMariaDb -Version "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v$($INSTALL_VERSION.Split('.')[0])"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)\mariadb-${INSTALL_VERSION}-winx64" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
if ($($InstallArgs.IsDefault)) {
	Link-Item2 -From "$($InstallEnv.ActiveTarget)" -To "$($InstallEnv.DefaultTarget)" -Overwrite
	Update-CliinstPath -BinPath "$($InstallEnv.DefaultTarget)\bin" -IsSystemWide $($InstallEnv.IsAdmin)
}
Finalize-Install
