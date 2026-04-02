################################################################################
#
#  pnpm-install
#
#  Install/Update PNPM for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://pnpm.io/
#
#  Usage:
#    pnpm-install [<version>]
#
#  Example:
#    pnpm-install
#    pnpm-install 10.25.0
#    pnpm-install v10.25.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

# Application info
$GITHUB_OWNER="pnpm"
$GITHUB_REPO="pnpm"
$PROGRAM_ID="pnpm"
$PROGRAM_EXEC="pnpm.exe"

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Process arguments
$LATEST_VERSION = ""
if (${args}.Count -ge 1) {
	$LATEST_VERSION = ${args}[0].ToString()
}

# Determine version to install
if ( "${LATEST_VERSION}" -eq "" ) {
	$LATEST_VERSION = (Invoke-WebRequest "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest" | ConvertFrom-Json).tag_name
}
$LATEST_VERSION = ${LATEST_VERSION}.TrimStart("v")

# Installation environment
$IS_ADMIN = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$ARCH = ${env:PROCESSOR_ARCHITECTURE}
if (${IS_ADMIN}) {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:PROGRAMFILES}", "${PROGRAM_ID}")
	$TEMP_ROOT = "${env:TEMP}"
} else {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:USERPROFILE}", ".local", "share", "${PROGRAM_ID}")
	$TEMP_ROOT = "${env:TEMP}"
}
if (${env:CLIINST_USR_LOCAL_SHARE} -ne $null) {
	$INSTALL_ROOT = [IO.Path]::Combine("${env:CLIINST_USR_LOCAL_SHARE}", "${PROGRAM_ID}")
}
if (${env:CLIINST_TEMP} -ne $null) {
	$TEMP_ROOT = "${env:CLIINST_TEMP}"
}
$INSTALL_TARGET = [IO.Path]::Combine("${INSTALL_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}")
$ACTIVE_TARGET = [IO.Path]::Combine("${INSTALL_ROOT}", "active-release")

if (!(Test-Path "${INSTALL_ROOT}" -PathType Container)) {
	New-Item -ItemType Directory -Path "${INSTALL_ROOT}" -Force
}
if (!(Test-Path "${TEMP_ROOT}" -PathType Container)) {
	New-Item -ItemType Directory -Path "${TEMP_ROOT}" -Force
}

# Download and install binaries
if (!(Test-Path "${INSTALL_TARGET}" -PathType Container)) {
	$BIN_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/pnpm-win-x64.exe"
	$BIN_URI_ARM64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/pnpm-win-arm64.exe"
	$BIN_TMP_FILE = [IO.Path]::Combine("${TEMP_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}.exe")

	$ProgressPreference = "SilentlyContinue"
	if ("${ARCH}" -eq "AMD64") {
		Invoke-WebRequest -Uri "${BIN_URI_AMD64}" -OutFile "${BIN_TMP_FILE}"
	}
	elseif ("${ARCH}" -eq "ARM64") {
		Invoke-WebRequest -Uri "${BIN_URI_ARM64}" -OutFile "${BIN_TMP_FILE}"
	}
	else {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}

	$TEMP_TARGET = [IO.Path]::Combine("${TEMP_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}")
	New-Item -ItemType Directory -Path "${TEMP_TARGET}"
	Move-Item "${BIN_TMP_FILE}" $([IO.Path]::Combine("${TEMP_TARGET}", "${PROGRAM_EXEC}"))
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("${TEMP_TARGET}"))
	Move-Item "${TEMP_TARGET_FINAL}" "${INSTALL_TARGET}"
	if (Test-Path "${TEMP_TARGET}") {
		Remove-Item "${TEMP_TARGET}" -Recurse -Force
	}
	$ProgressPreference = "Continue"
}

# Set active release
if (Test-Path "${ACTIVE_TARGET}") {
	Remove-Item "${ACTIVE_TARGET}" -Recurse -Force
}
New-Item -ItemType Junction -Target "${INSTALL_TARGET}" -Path "${ACTIVE_TARGET}"

# Update PATH for quick access
$CLIINST_PATH = ${env:CLIINST_PATH}
if (${CLIINST_PATH} -eq $null) {
	$CLIINST_PATH = "${ACTIVE_TARGET}"
}
else {
	$CLIINST_PATHS = ${CLIINST_PATH}.Split(";")
	if (${CLIINST_PATHS}.IndexOf("${ACTIVE_TARGET}") -eq -1) {
		$CLIINST_PATH = "${CLIINST_PATH};${ACTIVE_TARGET}"
		$CLIINST_PATHS = ${CLIINST_PATH}.Split(";")
	}
	$CLIINST_PATHS = ${CLIINST_PATHS} | Sort-Object -Unique
	$CLIINST_PATH = $CLIINST_PATHS -Join ";"
}
if (${IS_ADMIN}) {
	[Environment]::SetEnvironmentVariable("CLIINST_PATH", "${CLIINST_PATH}", "Machine")
}
else {
	[Environment]::SetEnvironmentVariable("CLIINST_PATH", "${CLIINST_PATH}", "User")
}

Set-PSDebug -Trace 0
