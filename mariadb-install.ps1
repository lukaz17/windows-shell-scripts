################################################################################
#
#  mariadb-install
#
#  Install/Update MariaDB Community Server for current user. This also works as a version manager.
#
#  Homepage: https://mariadb.com/
#
#  Usage:
#    mariadb-install <version>
#
#  Example:
#    mariadb-install 12.2
#    mariadb-install 12.2.2
#    mariadb-install v12.2
#    mariadb-install v12.2.2
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "MariaDB"
$GITHUB_REPO = "server"
$PROGRAM_ID = "MariaDB"
$PROGRAM_EXEC = "bin\mariadb.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
$apiResponse = Invoke-WebRequest -UseBasicParsing "https://downloads.mariadb.org/rest-api/mariadb/${INSTALL_VERSION}" | ConvertFrom-Json
if ($apiResponse.PSObject.Properties.Name -contains 'releases') {
	$latestKey = (@($apiResponse.releases.PSObject.Properties.Name) | Sort-Object {[version]$_} -Descending)[0]
	$INSTALL_VERSION = ${latestKey}
	$files = $($apiResponse.releases.$latestKey.files)
} else {
	$singleKey = @($apiResponse.release_data.PSObject.Properties.Name)[0]
	$INSTALL_VERSION = ${singleKey}
	$files = $($apiResponse.release_data.$singleKey.files)
}
$matchedFile = (${files} | Where-Object {
	$_.package_type -eq "ZIP file" -and
	$_.os -eq "Windows" -and
	$_.cpu -eq "x86_64" -and
	$_.file_name -notmatch "debugsymbols"
})[0]
if (-not $matchedFile) {
	Write-Error "No matching file found for version ${INSTALL_VERSION}"
	exit 1
}

$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v$($INSTALL_VERSION.Split('.')[0])"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "$($matchedFile.file_download_url)"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "mariadb-${INSTALL_VERSION}-winx64"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite

Set-PSDebug -Trace 0
