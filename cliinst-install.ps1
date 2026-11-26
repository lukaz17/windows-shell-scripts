################################################################################
#
#  cliinst-install
#
#  Configure initial settings for CliInst.
#
#  Usage:
#    cliinst-install [-UsrLocalShare <path>] [-UsrProfile <path>] [-Tmp <path>]
#
#  If a parameter is omitted, the corresponding variable is left as-is.
#  If a parameter is an empty string (""), the variable is removed.
#  If no parameter is given, each variable is prompted for in turn:
#  Enter keeps it as-is, a path sets it, "-" removes it.
#
#  CLIINST_USR_PROFILE is always set for the current user, even when elevated.
#
#  Example:
#    cliinst-install
#    cliinst-install -UsrLocalShare "C:\Users\user\.local\share" -Tmp "C:\Users\user\AppData\Local\Temp"
#    cliinst-install -UsrProfile "D:\Profile"
#    cliinst-install -UsrLocalShare "" # Remove CLIINST_USR_LOCAL_SHARE
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter()]
	[string] $UsrLocalShare,

	[Parameter()]
	[string] $UsrProfile,

	[Parameter()]
	[string] $Tmp
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Prompt answer that removes a variable, as "" does for a parameter
$REMOVE_ANSWER = "-"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# ------------------------------------------------------------------------------
# Prompt for each setting in turn, return the new values by variable name.
# A setting answered with Enter is left out (kept), "-" maps to "" (removed).
# ------------------------------------------------------------------------------
function Read-CliinstSetting {
	param(
		[Parameter(Mandatory)] [hashtable[]] $Settings
	)

	Write-Host "> Enter a path to set a variable, Enter to keep it, ${REMOVE_ANSWER} to remove it."
	$newValues = @{}
	foreach ($setting in ${Settings}) {
		$scope = if ($setting.IsSystemWide) { "Machine" } else { "User" }
		$currentValue = [Environment]::GetEnvironmentVariable("$($setting.Name)", ${scope})
		$shownValue = if ("${currentValue}" -ne "") { "${currentValue}" } else { "not set" }
		# Paths copied from Explorer come quoted
		$answer = "$(Read-Host "> $($setting.Name) [${shownValue}]")".Trim().Trim('"')
		if (${answer} -eq "") {
			continue
		}
		$newValues[$setting.Name] = if (${answer} -eq ${REMOVE_ANSWER}) { "" } else { ${answer} }
	}
	return ${newValues}
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# CLIINST_USR_PROFILE holds account data, which is never set system-wide
$settings = @(
	@{ Parameter = "UsrLocalShare"; Name = "CLIINST_USR_LOCAL_SHARE"; IsSystemWide = ${isAdmin} }
	@{ Parameter = "UsrProfile"; Name = "CLIINST_USR_PROFILE"; IsSystemWide = $false }
	@{ Parameter = "Tmp"; Name = "CLIINST_TEMP"; IsSystemWide = ${isAdmin} }
)

# New values by variable name: a variable left out is kept, "" removes it
$newValues = @{}
foreach ($setting in ${settings}) {
	if (${PSBoundParameters}.ContainsKey("$($setting.Parameter)")) {
		$newValues[$setting.Name] = ${PSBoundParameters}["$($setting.Parameter)"]
	}
}
if (${newValues}.Count -eq 0) {
	$newValues = Read-CliinstSetting -Settings ${settings}
}

# Set environment variables
foreach ($setting in ${settings}) {
	if (!${newValues}.ContainsKey("$($setting.Name)")) {
		continue
	}
	$newValue = ${newValues}["$($setting.Name)"]
	if (${newValue} -eq "") {
		Remove-EnvVariable "$($setting.Name)" -IsSystemWide $($setting.IsSystemWide)
	} else {
		Set-EnvVariable "$($setting.Name)" "${newValue}" -IsSystemWide $($setting.IsSystemWide)
	}
}
Install-CliinstPath -IsSystemWide ${isAdmin}
Update-CliinstPath -BinPath "${PSScriptRoot}" -IsSystemWide ${isAdmin}
Finalize-Install
