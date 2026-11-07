################################################################################
#
#  cliinst-repair
#
#  List environment variables set by the install scripts, and entries of
#  CLIINST_PATH and CLIINST_USR_PATH, that point to a path no longer on disk.
#
#  Usage:
#    cliinst-repair [-Apply]
#
#    -Apply removes what is listed, without it nothing changes.
#
#  Example:
#    cliinst-repair
#    cliinst-repair -Apply
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter()]
	[switch] $Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Variables that hold paths; the CLIINST_ settings are left out, installers recreate their folders
$ENV_VARIABLES = @(
	"BUN_INSTALL_BIN",
	"BUN_INSTALL_CACHE_DIR",
	"BUN_INSTALL_GLOBAL_DIR",
	"CARGO_HOME",
	"CLIINST_PATH",
	"CLIINST_USR_PATH",
	"GOPATH",
	"GOROOT",
	"npm_config_cache",
	"npm_config_cache_dir",
	"npm_config_prefix",
	"pnpm_config_cache_dir",
	"PNPM_HOME",
	"RUSTUP_HOME",
	"UV_INSTALL_DIR",
	"UV_PYTHON_INSTALL_DIR",
	"UV_TOOL_DIR"
)

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# ------------------------------------------------------------------------------
# Get the state of a path: Present, Missing, or Unknown if it cannot be checked.
# ------------------------------------------------------------------------------
function Get-PathState {
	param(
		[Parameter(Mandatory)] [string] $Path
	)

	$expandedPath = [Environment]::ExpandEnvironmentVariables("${Path}")
	try {
		$root = [IO.Path]::GetPathRoot("${expandedPath}")
	} catch [System.ArgumentException] {
		return "Unknown"
	}

	# An unmounted drive, or a mapped drive an elevated session cannot see, hides paths that still exist
	if ("${root}" -eq "" -or !(Test-Path -LiteralPath "${root}")) {
		return "Unknown"
	}
	if (Test-Path -LiteralPath "${expandedPath}" -PathType Leaf) {
		return "Present"
	}

	# Test-Path reports a junction to a deleted folder as present, listing it fails
	try {
		[IO.Directory]::EnumerateFileSystemEntries("${expandedPath}") | Select-Object -First 1 | Out-Null
		return "Present"
	} catch [System.IO.DirectoryNotFoundException] {
		return "Missing"
	} catch [System.UnauthorizedAccessException] {
		return "Present"
	}
}

# ------------------------------------------------------------------------------
# Get the repair of an environment variable, nothing if none of its paths is missing.
# ------------------------------------------------------------------------------
function Get-EnvRepair {
	param(
		[Parameter(Mandatory)] [string] $Name,
		[Parameter()] [bool] $IsSystemWide = $false
	)

	$scope = if (${IsSystemWide}) { "Machine" } else { "User" }
	$value = [Environment]::GetEnvironmentVariable("${Name}", ${scope})

	$keptPaths = @()
	$missingPaths = @()
	foreach ($entry in "${value}".Split(";")) {
		$path = ${entry}.Trim()
		if ("${path}" -eq "") {
			continue
		}

		$state = Get-PathState -Path "${path}"
		if ("${state}" -eq "Missing") {
			$missingPaths += ${path}
			continue
		}
		if ("${state}" -eq "Unknown") {
			Write-Warning "Keeping ${path} in ${Name}: it cannot be checked, its drive may be unavailable."
		}
		$keptPaths += ${path}
	}

	if (${missingPaths}.Count -gt 0) {
		return [PSCustomObject]@{
			Name = ${Name}
			IsSystemWide = ${IsSystemWide}
			KeptPaths = ${keptPaths}
			MissingPaths = ${missingPaths}
		}
	}
}

# ------------------------------------------------------------------------------
# Write the kept paths of an environment variable, removing it if none is left.
# ------------------------------------------------------------------------------
function Invoke-EnvRepair {
	param(
		[Parameter(Mandatory)] [PSCustomObject] $Repair
	)

	if (${Repair}.KeptPaths.Count -eq 0) {
		Remove-EnvVariable -Name "$($Repair.Name)" -IsSystemWide $($Repair.IsSystemWide)
	} else {
		Set-EnvVariable -Name "$($Repair.Name)" -Value "$(${Repair}.KeptPaths -Join ';')" -IsSystemWide $($Repair.IsSystemWide)
	}
}

# List missing paths
$repairs = @(foreach ($name in ${ENV_VARIABLES}) {
	Get-EnvRepair -Name "${name}" -IsSystemWide $false
	Get-EnvRepair -Name "${name}" -IsSystemWide $true
})
if (${repairs}.Count -eq 0) {
	Write-Host "> No missing paths."
}
foreach ($repair in ${repairs}) {
	foreach ($path in $($repair.MissingPaths)) {
		Write-Host "> Missing:      ${path} ($($repair.Name))"
	}
}

if (!${Apply}) {
	if (${repairs}.Count -gt 0) {
		Write-Host "> Skipped. Run with -Apply to remove them."
	}
	return
}

# Repair environment variables
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$hasSkippedRepair = $false
foreach ($repair in ${repairs}) {
	if ($($repair.IsSystemWide) -and !${isAdmin}) {
		$hasSkippedRepair = $true
		continue
	}
	Invoke-EnvRepair -Repair ${repair}
}

if (${hasSkippedRepair}) {
	Write-Warning "System variables were not changed: run cliinst-repair -Apply from an elevated terminal."
} else {
	Write-Host "> Success."
}
