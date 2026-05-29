################################################################################
#
#  postgresql-install
#
#  Install/Update PostgreSQL Community Server for current user. This also works as a version manager.
#
#  Homepage: https://www.postgresql.org/
#
#  Usage:
#    postgresql-install <version>
#
#  Example:
#    postgresql-install 17.7
#    postgresql-install v17.7
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "postgres"
$GITHUB_REPO = "postgres"
$PROGRAM_ID = "PostgreSQL"
$PROGRAM_EXEC = "bin\postgres.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v$($INSTALL_VERSION.Split('.')[0])"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://get.enterprisedb.com/postgresql/postgresql-${INSTALL_VERSION}-1-windows-x64-binaries.zip"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "pgsql"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite

Set-PSDebug -Trace 0
