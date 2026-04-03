################################################################################
#
#  ffmpeg-install
#
#  Install/Update FFmpeg for current user. This also works as a version manager.
#
#  Homepage: https://www.gyan.dev/ffmpeg/builds/
#
#  Usage:
#    ffmpeg-install <version>
#
#  Example:
#    ffmpeg-install 7.1
#    ffmpeg-install v7.1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

# Application info
$GITHUB_OWNER="GyanD"
$GITHUB_REPO="codexffmpeg"
$PROGRAM_ID="FFmpeg"
$PROGRAM_NAME="FFmpeg"
$PROGRAM_EXEC="ffmpeg.exe"

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
	$BIN_ARCH_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/ffmpeg-${LATEST_VERSION}-full_build.7z"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = [IO.Path]::Combine(${TEMP_ROOT}, "${PROGRAM_ID}-v${LATEST_VERSION}.7z")

	$ProgressPreference = "SilentlyContinue"
	if ("${ARCH}" -eq "AMD64") {
		Invoke-WebRequest -Uri "${BIN_ARCH_URI_AMD64}" -OutFile "${BIN_ARCH_TMP_FILE}"
	}
	elseif ("${ARCH}" -eq "ARM64") {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	else {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}

	$TEMP_TARGET = [IO.Path]::Combine("${TEMP_ROOT}", "${PROGRAM_ID}-v${LATEST_VERSION}")
	New-Item -ItemType Directory -Path "${TEMP_TARGET}"
	if ("${ARCH}" -eq "AMD64") {
		$7ZCLI = [IO.Path]::Combine("${PSScriptRoot}", "7z-amd64", "7z.exe")
		& "${7ZCLI}" x "${BIN_ARCH_TMP_FILE}" -o"${TEMP_TARGET}"
	}
	elseif ("${ARCH}" -eq "ARM64") {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	else {
		Write-Output "Unsupported architecture: ${ARCH}"
		exit 1
	}
	Remove-Item "${BIN_ARCH_TMP_FILE}" -Force
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("${TEMP_TARGET}", "ffmpeg-${LATEST_VERSION}-full_build"))
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
$ACTIVE_TARGET_BIN = [IO.Path]::Combine("${ACTIVE_TARGET}", "bin")
$CLIINST_PATH = ${env:CLIINST_PATH}
if (${CLIINST_PATH} -eq $null) {
	$CLIINST_PATH = "${ACTIVE_TARGET_BIN}"
}
else {
	$CLIINST_PATHS = ${CLIINST_PATH}.Split(";")
	if (${CLIINST_PATHS}.IndexOf("${ACTIVE_TARGET_BIN}") -eq -1) {
		$CLIINST_PATH = "${CLIINST_PATH};${ACTIVE_TARGET_BIN}"
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
Write-Output "Installation completed"
Write-Output "New terminal session must be started before installing other applications using this script to avoid lost ENVAR issue"

Set-PSDebug -Trace 0
