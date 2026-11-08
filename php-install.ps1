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
#    php-install <version>[-ts] [--default]
#
#    -ts installs the Thread Safe build, side by side with the Non Thread Safe build of the same version.
#    --default makes this minor version and build the one on PATH, later updates of it follow.
#
#  Example:
#    php-install 8.4
#    php-install 8.4.27
#    php-install 8.4 --default
#    php-install 8.4-ts
#    php-install 8.4.27-ts
#    php-install 8.4-ts --default
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

	if ("${Version}" -notmatch "^\d+\.\d+(\.\d+)?(-ts)?$") {
		Write-Output "Get-InstallVersionFromPhp: Expected a minor version such as 8.4 or a full version such as 8.4.27, with -ts for the Thread Safe build, got: ${Version}"
		exit 1
	}

	$coreVersion = "${Version}" -replace "-ts$", ""
	$threadSafeSuffix = if ("${coreVersion}" -ne "${Version}") { "-ts" } else { "" }
	$escapedVersion = [regex]::Escape("${coreVersion}")
	$buildPattern = if ("${coreVersion}" -match "^\d+\.\d+$") { "^${escapedVersion}\.\d+(-\d+)?${threadSafeSuffix}$" } else { "^${escapedVersion}(-\d+)?${threadSafeSuffix}$" }
	$latestVersion = (Get-PhpArchiveUri).Keys | Where-Object { $_ -match ${buildPattern} } | Sort-Object { Get-VersionSortKey -Version ("$_" -replace "-ts$", "") } -Descending | Select-Object -First 1
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
$THREAD_SAFE_SUFFIX = if ("${INSTALL_VERSION}" -match "-ts$") { "-ts" } else { "" }
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -ActiveTag "v${INSTALL_MINOR}${THREAD_SAFE_SUFFIX}"

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
$CONFIG_FILE = "${CONFIG_TARGET}\php${THREAD_SAFE_SUFFIX}.ini"
New-Directory2 -Path "${CONFIG_TARGET}"
if (!(Test-Path "${CONFIG_FILE}" -PathType Leaf)) {
	Copy-Item2 -From "$($InstallEnv.InstallTarget)\php.ini-production" -To "${CONFIG_FILE}"
}
if (!(Test-Path "$($InstallEnv.InstallTarget)\php.ini")) {
	Link-Item2 -From "${CONFIG_FILE}" -To "$($InstallEnv.InstallTarget)\php.ini" -Type "HardLink"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
if ($($InstallArgs.IsDefault)) {
	Link-Item2 -From "$($InstallEnv.ActiveTarget)" -To "$($InstallEnv.DefaultTarget)" -Overwrite
	Update-CliinstPath -BinPath "$($InstallEnv.DefaultTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
}
Finalize-Install
