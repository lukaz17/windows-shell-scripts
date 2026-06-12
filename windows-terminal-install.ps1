################################################################################
#
#  windows-terminal-install
#
#  Install/Update Windwos Terminal for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://learn.microsoft.com/vi-vn/windows/terminal/
#
#  Usage:
#    windows-terminal-install [<version>]
#
#  Example:
#    windows-terminal-install
#    windows-terminal-install 1.24.11321.0
#    windows-terminal-install v1.24.11321.0
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "microsoft"
$GITHUB_REPO = "terminal"
$PROGRAM_ID = "Windows Terminal"
$PROGRAM_NAME = "Windows Terminal"
$PROGRAM_EXEC = "WindowsTerminal.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "${GITHUB_OWNER}" -Repo "${GITHUB_REPO}" -FallbackVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}" -IsApplication

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${INSTALL_VERSION}/Microsoft.WindowsTerminal_${INSTALL_VERSION}_x64.zip"
	$BIN_ARCH_URI_ARM64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/v${INSTALL_VERSION}/Microsoft.WindowsTerminal_${INSTALL_VERSION}_arm64.zip"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)", "terminal-${INSTALL_VERSION}"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
$TARGET_EXE=[IO.Path]::Combine($($InstallEnv.ActiveTarget), ${PROGRAM_EXEC})
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.DesktopRoot)"
New-AppShortcut -ProgramName "${PROGRAM_NAME}" -TargetExe "${TARGET_EXE}" -WorkingDir "$($InstallEnv.ActiveTarget)" -Destination "$($InstallEnv.StartMenuRoot)"

Set-PSDebug -Trace 0
