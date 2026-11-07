################################################################################
#
#  nodejs-install
#
#  Install/Update Node.js for current user. This also works as a version manager.
#  If version is not specified, the latest stable version will be installed.
#
#  Homepage: https://nodejs.org/
#
#  Usage:
#    nodejs-install [<version>] [--default]
#
#    --default makes this major version the active-release.
#
#  Example:
#    nodejs-install
#    nodejs-install 24
#    nodejs-install 24.22
#    nodejs-install 24.22.2
#    nodejs-install v24
#    nodejs-install v24.22
#    nodejs-install v24.22.2
#    nodejs-install 24 --default
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "Nodejs"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get latest stable Node.js version of a series, a full version resolves to itself
# ------------------------------------------------------------------------------
function Get-InstallVersionFromNodeJs {
	param(
		[Parameter()] [string] $Version = ""
	)

	$seriesPrefix = ""
	if ("${Version}" -ne "") {
		$Version = Normalize-InstallVersion -Version "${Version}"
		$seriesPrefix = "${Version}."
	}

	$apiResponse = Invoke-WebRequest -UseBasicParsing "https://nodejs.org/dist/index.json" | ConvertFrom-Json
	$versions = @(${apiResponse} | ForEach-Object { Normalize-InstallVersion -Version "$($_.version)" })
	if (${versions} -contains "${Version}") {
		$latestVersion = ${Version}
	} else {
		# The index lists pre-releases such as 27.0.0-alpha.0.0.0, only a full version may select one
		$latestVersion = ${versions} | Where-Object { $_ -match "^\d+\.\d+\.\d+$" -and $_.StartsWith(${seriesPrefix}) } | Sort-Object {[version]$_} -Descending | Select-Object -First 1
	}
	if ($null -eq ${latestVersion}) {
		Write-Output "Get-InstallVersionFromNodeJs: No stable release found for ${Version}"
		exit 1
	}

	Write-Host "> Latest Version:  ${latestVersion}"
	return ${latestVersion}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Get-InstallVersionFromNodeJs -Version "$($InstallArgs.Version)"
$INSTALL_MAJOR = Get-VersionMajor -Version "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v${INSTALL_MAJOR}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	Move-ItemPerArch -Amd64Path "$($InstallEnv.TempTarget)\node-v${INSTALL_VERSION}-win-x64" -Arm64Path "$($InstallEnv.TempTarget)\node-v${INSTALL_VERSION}-win-arm64" -OutputPath "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
$NODEJS_USER_TARGET = "$($InstallEnv.UserProfileData)\.${PROGRAM_ID}"
$NPM_CACHE_TARGET = "${NODEJS_USER_TARGET}\cache"
$NPM_PREFIX_TARGET = "${NODEJS_USER_TARGET}"
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
if ($($InstallArgs.IsDefault)) {
	New-Directory2 -Path "${NPM_CACHE_TARGET}"
	New-Directory2 -Path "${NPM_PREFIX_TARGET}"
	Link-Item2 -From "$($InstallEnv.ActiveTarget)" -To "$($InstallEnv.DefaultTarget)" -Overwrite
	Set-EnvVariable -Name "npm_config_cache" -Value "${NPM_CACHE_TARGET}" -IsSystemWide $false
	Set-EnvVariable -Name "npm_config_prefix" -Value "${NPM_PREFIX_TARGET}" -IsSystemWide $false
	Update-CliinstPath -BinPath "$($InstallEnv.DefaultTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
	Update-CliinstPath -BinPath "${NPM_PREFIX_TARGET}" -IsSystemWide $false
}
Finalize-Install
