################################################################################
#
#  cliinst-install
#
#  Configure initial settings for CliInst.
#
#  Usage:
#    cliinst-install [-UsrLocalShare <path>] [-Tmp <path>]
#
#  If a parameter is omitted, the corresponding variable is left as-is.
#  If a parameter is an empty string (""), the variable is removed.
#
#  Example:
#    cliinst-install -UsrLocalShare "C:\Users\user\.local\share" -Tmp "C:\Users\user\AppData\Local\Temp"
#    cliinst-install -UsrLocalShare ""   # Remove CLIINST_USR_LOCAL_SHARE
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
	[string] $Tmp
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Trace 2

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# Set environment variables
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (${PSBoundParameters}.ContainsKey("UsrLocalShare")) {
	if (${UsrLocalShare} -eq "") {
		Remove-EnvVariable "CLIINST_USR_LOCAL_SHARE" ${isAdmin}
	} else {
		Set-EnvVariable "CLIINST_USR_LOCAL_SHARE" "${UsrLocalShare}" ${isAdmin}
	}
}
if (${PSBoundParameters}.ContainsKey("Tmp")) {
	if (${Tmp} -eq "") {
		Remove-EnvVariable "CLIINST_TEMP" ${isAdmin}
	} else {
		Set-EnvVariable "CLIINST_TEMP" "${Tmp}" ${isAdmin}
	}
}
Install-CliinstPath ${isAdmin}

Set-PSDebug -Trace 0
