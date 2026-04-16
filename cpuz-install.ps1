################################################################################
#
#  cpuz-install
#
#  Install/Update CPU-Z for current user. This also works as a version manager.
#
#  Homepage: https://www.cpuid.com/softwares/cpu-z.html
#
#  Usage:
#    cpuz-install <version>
#
#  Example:
#    cpuz-install 2.17
#    cpuz-install v2.17
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$PROGRAM_ID = "CPU-Z"
$PROGRAM_NAME = "CPU-Z"
$PROGRAM_EXEC = "cpuz_x64.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Normalize-InstallVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -IsApplication

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://download.cpuid.com/cpu-z/cpu-z_${INSTALL_VERSION}-en.zip"
	$BIN_ARCH_URI_ARM64 = ""
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Copy-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
$TARGET_EXE=[IO.Path]::Combine($($InstallEnv.ActiveTarget), ${PROGRAM_EXEC})
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"

Set-PSDebug -Trace 0
