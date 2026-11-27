################################################################################
#
#  innounp-install
#
#  Install/Update innounp, the Inno Setup Unpacker, for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#  Only the versions mapped in shared\install-source.ps1 can be installed, as its releases are tagged with the GUI version.
#
#  Homepage: https://www.rathlev-home.de/tools/prog-e.html#unpack
#
#  Usage:
#    innounp-install [<version>]
#
#    <version> is a series, such as 2.67, for its newest build, or a full version, such as 2.67.9.
#
#  Example:
#    innounp-install
#    innounp-install 2.67
#    innounp-install v2.67.9
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "innounp"
$PROGRAM_EXEC = "innounp.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get newest mapped innounp version of all, of a series, or of a full version.
# ------------------------------------------------------------------------------
function Get-InstallVersionFromInnounp {
	param(
		[Parameter()] [string] $Version = ""
	)

	if ("${Version}" -ne "" -and "${Version}" -notmatch "^\d+\.\d+(\.\d+)?$") {
		Write-Output "Get-InstallVersionFromInnounp: Expected a series such as 2.67 or a full version such as 2.67.11, got: ${Version}"
		exit 1
	}

	$escapedVersion = [regex]::Escape("${Version}")
	if ("${Version}" -eq "") {
		$buildPattern = ""
	} elseif ("${Version}" -match "^\d+\.\d+$") {
		$buildPattern = "^${escapedVersion}\.\d+$"
	} else {
		$buildPattern = "^${escapedVersion}$"
	}
	$mappedVersions = @(Get-MappedVersion -ProgramId "${PROGRAM_ID}" | Sort-Object { Get-VersionSortKey -Version $_ } -Descending)
	$latestVersion = ${mappedVersions} | Where-Object { $_ -match ${buildPattern} } | Select-Object -First 1
	if ($null -eq ${latestVersion}) {
		Write-Output "Get-InstallVersionFromInnounp: No mapped version for ${Version}, mapped versions: $(${mappedVersions} -join ', ')"
		exit 1
	}

	Write-Host "> Latest Version:  ${latestVersion}"
	return ${latestVersion}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$REQUESTED_VERSION = "$($InstallArgs.Version)".TrimStart("v")
$INSTALL_VERSION = Get-InstallVersionFromInnounp -Version "${REQUESTED_VERSION}"
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
	# A release can get a newer archive in place, a mismatch would install under the wrong version folder
	$DOWNLOADED_VERSION = (Get-Item "$($InstallEnv.TempTarget)\${PROGRAM_EXEC}").VersionInfo.FileVersion
	if ("${DOWNLOADED_VERSION}" -ne "${INSTALL_VERSION}") {
		Remove-Item2 -Path "$($InstallEnv.TempTarget)"
		Write-Output "innounp-install: Expected version ${INSTALL_VERSION}, but its release now holds version ${DOWNLOADED_VERSION}, update the innounp versions in shared\install-source.ps1"
		exit 1
	}
	Move-Item2 -From "$($InstallEnv.TempTarget)" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Finalize-Install
