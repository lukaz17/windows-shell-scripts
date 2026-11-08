################################################################################
#
#  php-install
#
#  Install/Update PHP for current user. This also works as a version manager.
#
#  Homepage: https://www.php.net/
#
#  Prerequisites:
#    - Microsoft Visual C++ Redistributable
#
#  Usage:
#    php-install <version> [--default]
#
#    --default makes this minor version the one on PATH, later updates of that minor version follow.
#
#  Example:
#    php-install 8.4
#    php-install 8.4.27
#    php-install 8.4 --default
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "PHP"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get newest PHP build of a minor version or of a full version.
# ------------------------------------------------------------------------------
function Get-InstallVersionFromPhp {
	param(
		[Parameter(Mandatory)] [string] $Version
	)

	if ("${Version}" -notmatch "^\d+\.\d+(\.\d+)?$") {
		Write-Output "Get-InstallVersionFromPhp: Expected a minor version such as 8.4 or a full version such as 8.4.27, got: ${Version}"
		exit 1
	}

	$escapedVersion = [regex]::Escape("${Version}")
	$buildPattern = if ("${Version}" -match "^\d+\.\d+$") { "^${escapedVersion}\.\d+(-\d+)?$" } else { "^${escapedVersion}(-\d+)?$" }
	$latestVersion = (Get-PhpArchiveUri).Keys | Where-Object { $_ -match ${buildPattern} } | Sort-Object { Get-VersionSortKey -Version $_ } -Descending | Select-Object -First 1
	if ($null -eq ${latestVersion}) {
		Write-Output "Get-InstallVersionFromPhp: No build found for ${Version}"
		exit 1
	}

	Write-Host "> Latest Version:  ${latestVersion}"
	return ${latestVersion}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Normalize-InstallVersion -Version "$($InstallArgs.Version)"
$INSTALL_VERSION = Get-InstallVersionFromPhp -Version "${INSTALL_VERSION}"
$INSTALL_MINOR = Get-VersionMinor -Version "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v${INSTALL_MINOR}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Setup shared config
$CONFIG_TARGET = "$($InstallEnv.InstallRoot)\config-v${INSTALL_MINOR}"
New-Directory2 -Path "${CONFIG_TARGET}"
if (!(Test-Path "${CONFIG_TARGET}\php.ini" -PathType Leaf)) {
	Copy-Item2 -From "$($InstallEnv.InstallTarget)\php.ini-production" -To "${CONFIG_TARGET}\php.ini"
}
if (!(Test-Path "$($InstallEnv.InstallTarget)\php.ini")) {
	Link-Item2 -From "${CONFIG_TARGET}\php.ini" -To "$($InstallEnv.InstallTarget)\php.ini" -Type "HardLink"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
if ($($InstallArgs.IsDefault)) {
	Link-Item2 -From "$($InstallEnv.ActiveTarget)" -To "$($InstallEnv.DefaultTarget)" -Overwrite
	Update-CliinstPath -BinPath "$($InstallEnv.DefaultTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
}
Finalize-Install
