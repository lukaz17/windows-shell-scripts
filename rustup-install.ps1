################################################################################
#
#  rustup-install
#
#  Install/Update Rustup for current user. This also works as a version manager.
#  If version is not specified, the latest version will be installed.
#  Rust toolchains are installed separately for each user, e.g. rustup default stable.
#
#  Homepage: https://rustup.rs/
#
#  Usage:
#    rustup-install [<version>]
#
#  Example:
#    rustup-install
#    rustup-install 1.29.3
#    rustup-install v1.29.3
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$PROGRAM_ID = "rustup"
$PROGRAM_EXEC = "rustup.exe"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"
. "${PSScriptRoot}\shared\install-source.ps1"

# ------------------------------------------------------------------------------
# Get latest Rustup version
# ------------------------------------------------------------------------------
function Get-InstallVersionFromRustLang {
	param(
		[Parameter()] [string] $FallbackVersion = ""
	)

	if ("${FallbackVersion}" -eq "") {
		# Served as binary/octet-stream, which Windows PowerShell returns as bytes in Content
		$response = Invoke-WebRequest -UseBasicParsing "https://static.rust-lang.org/rustup/release-stable.toml"
		$manifest = [Text.Encoding]::UTF8.GetString(${response}.RawContentStream.ToArray())
		if (${manifest} -notmatch "(?m)^version = '(\d+\.\d+\.\d+)'") {
			Write-Host "Get-InstallVersionFromRustLang: No version found in release manifest"
			exit 1
		}
		$version = ${Matches}[1]
	} else {
		$version = ${FallbackVersion}
	}

	$version = Normalize-InstallVersion -Version "${version}"
	Write-Host "> Latest Version:  ${version}"
	return ${version}
}

# ------------------------------------------------------------------------------
# Run a Rustup executable and stop on failure
# ------------------------------------------------------------------------------
function Invoke-RustupExecutable {
	param(
		[Parameter(Mandatory)] [string] $Path,
		[Parameter(Mandatory)] [string[]] $Arguments
	)

	& "${Path}" @Arguments
	if (${LASTEXITCODE} -ne 0) {
		Write-Output "Invoke-RustupExecutable: ${Path} failed with exit code ${LASTEXITCODE}"
		exit 1
	}
}

# Prepare environment
$InstallArgs = Get-InstallArgument -Arguments ${args}
$INSTALL_VERSION = Get-InstallVersionFromRustLang -FallbackVersion "$($InstallArgs.Version)"
$InstallEnv = Initialize-InstallEnv -ProgramId "${PROGRAM_ID}" -Version "${INSTALL_VERSION}"

# Download and install binaries
if (!(Test-Path "$($InstallEnv.InstallTarget)" -PathType Container)) {
	$BIN_URI_AMD64 = Get-Amd64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	$BIN_URI_ARM64 = Get-Arm64Uri -ProgramId "${PROGRAM_ID}" -InstallVersion "${INSTALL_VERSION}"
	# Rustup picks its behavior from the executable name, so it must stay rustup-init
	$BIN_TMP_FILE = "$($InstallEnv.TempRoot)\rustup-init.exe"
	Download-UriPerArch -Amd64Uri "${BIN_URI_AMD64}" -Arm64Uri "${BIN_URI_ARM64}" -OutputPath "${BIN_TMP_FILE}"
	New-Directory2 -Path "$($InstallEnv.TempTarget)"
	$env:CARGO_HOME = "$($InstallEnv.TempTarget)\cargo"
	$env:RUSTUP_HOME = "$($InstallEnv.TempTarget)\rustup"
	$env:RUSTUP_INIT_SKIP_PATH_CHECK = "yes"
	Invoke-RustupExecutable -Path "${BIN_TMP_FILE}" -Arguments "-y", "--no-modify-path", "--default-toolchain", "none"
	Remove-Item2 -Path "${BIN_TMP_FILE}"
	Move-Item2 -From "$($InstallEnv.TempTarget)\cargo\bin" -To "$($InstallEnv.InstallTarget)"
	Remove-Item2 -Path "$($InstallEnv.TempTarget)"
}

# Finalize install
$CARGO_USER_TARGET = "$($InstallEnv.UserProfileData)\.cargo"
$RUSTUP_USER_TARGET = "$($InstallEnv.UserProfileData)\.${PROGRAM_ID}"
Link-Item2 -From "$($InstallEnv.InstallTarget)" -To "$($InstallEnv.ActiveTarget)" -Overwrite
New-Directory2 -Path "${CARGO_USER_TARGET}\bin"
New-Directory2 -Path "${RUSTUP_USER_TARGET}"
Set-EnvVariable -Name "CARGO_HOME" -Value "${CARGO_USER_TARGET}" -IsSystemWide $false
Set-EnvVariable -Name "RUSTUP_HOME" -Value "${RUSTUP_USER_TARGET}" -IsSystemWide $false
Update-CliinstPath -BinPath "$($InstallEnv.ActiveTarget)" -IsSystemWide $($InstallEnv.IsAdmin)
Update-CliinstPath -BinPath "${CARGO_USER_TARGET}\bin" -IsSystemWide $false
$env:CARGO_HOME = "${CARGO_USER_TARGET}"
$env:RUSTUP_HOME = "${RUSTUP_USER_TARGET}"
Invoke-RustupExecutable -Path "$($InstallEnv.ActiveTarget)\${PROGRAM_EXEC}" -Arguments "set", "auto-self-update", "disable"
Finalize-Install
