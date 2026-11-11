################################################################################
#
#  librewolf-install
#
#  Install/Update LibreWolf for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://librewolf.net/
#
#  Usage:
#    librewolf-install [<version>]
#
#  Example:
#    librewolf-install
#    librewolf-install 157.0
#    librewolf-install v157.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "LibreWolf"
$PROGRAM_NAME = "LibreWolf"
$PROGRAM_EXEC = "librewolf.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get latest LibreWolf version
# ------------------------------------------------------------------------------
function Get-InstallVersionFromCodeberg {
	param(
		[Parameter()] [string] $FallbackVersion = ""
	)

	if ("${FallbackVersion}" -eq "") {
		$version = (Invoke-WebRequest -UseBasicParsing "https://codeberg.org/api/v1/repos/librewolf/bsys6/releases/latest" | ConvertFrom-Json).tag_name
	} else {
		$version = ${FallbackVersion}
	}

	$version = Normalize-InstallVersion -Version "${version}"
	Write-Host "> Latest Version:  ${version}"
	return ${version}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Get-InstallVersionFromCodeberg -FallbackVersion "$($InstallArgs.Version)"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -IsApplication

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 -Path "${BIN_ARCH_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)\librewolf" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
# Copy, not link: LibreWolf derives installation ID from exe path; junction resolves to versioned path, which breaks user profiles.
Copy-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"
Finalize-Install
