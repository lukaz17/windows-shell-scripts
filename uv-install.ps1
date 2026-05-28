################################################################################
#
#  uv-install
#
#  Install/Update UV for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#
#  Homepage: https://docs.astral.sh/uv/
#
#  Usage:
#    uv-install [<version>]
#
#  Example:
#    uv-install
#    uv-install 0.11.11
#    uv-install v0.11.11
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Application info
$GITHUB_OWNER = "astral-sh"
$GITHUB_REPO = "uv"
$PROGRAM_ID = "uv"
$PROGRAM_EXEC = "uv.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Prepare environment
$INSTALL_VERSION = ""
if (${args}.Count -ge 1) {
	$INSTALL_VERSION = ${args}[0].ToString()
}
$INSTALL_VERSION = Get-InstallVersionFromGithub -Owner "${GITHUB_OWNER}" -Repo "${GITHUB_REPO}" -FallbackVersion "${INSTALL_VERSION}"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_ARCH_URI_AMD64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${INSTALL_VERSION}/uv-x86_64-pc-windows-msvc.zip"
	$BIN_ARCH_URI_ARM64 = "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${INSTALL_VERSION}/uv-aarch64-pc-windows-msvc.zip"
	$BIN_ARCH_TMP_FILE = "$($InstallEnv.TempTarget).zip"
	Download-UriPerArch -Amd64Uri "${BIN_ARCH_URI_AMD64}" -Arm64Uri "${BIN_ARCH_URI_ARM64}" -OutputPath "${BIN_ARCH_TMP_FILE}"
	New-Directory2 "$($InstallEnv.TempTarget)"
	Extract-Archive -ArchivePath "${BIN_ARCH_TMP_FILE}" -DestinationPath "$($InstallEnv.TempTarget)" -ScriptRoot "${PSScriptRoot}"
	Remove-Item2 "${BIN_ARCH_TMP_FILE}"
	$TEMP_TARGET_FINAL = $([IO.Path]::Combine("$($InstallEnv.TempTarget)"))
	Move-Item2 -From "${TEMP_TARGET_FINAL}" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 "$($InstallEnv.TempTarget)"
}

# Finalize install
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable "UV_INSTALL_DIR" "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable "UV_PYTHON_INSTALL_DIR" "$([IO.Path]::Combine("$($InstallEnv.InstallRoot)", "Python"))" -IsSystemWide $($InstallEnv.IsAdmin)
Set-EnvVariable "UV_TOOL_DIR" "$([IO.Path]::Combine("$($InstallEnv.InstallRoot)", "Tool"))" -IsSystemWide $($InstallEnv.IsAdmin)

Set-PSDebug -Trace 0
