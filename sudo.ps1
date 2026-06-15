################################################################################
#
#  sudo
#
#  Run a command with elevated (administrator) permissions.
#
#  Usage:
#    sudo <command> [args...]
#
#  Example:
#    sudo notepad
#    sudo cmd /c whoami
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($args.Count -eq 0) {
	Write-Error "Usage: sudo <command> [args...]"
	exit 1
}

function Quote-Arg($arg) {
	if (${arg} -match ' ' -and ${arg} -notmatch '^".*"$') {
		return '"' + ${arg} + '"'
	}
	return ${arg}
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (${isAdmin}) {
	if ($args.Count -gt 1) {
		$subArgs = $args[1..($args.Count - 1)]
		& $args[0] @subArgs
	} else {
		& $args[0]
	}
} else {
	if ($args.Count -gt 1) {
		$subArgs = $args[1..($args.Count - 1)] | ForEach-Object { Quote-Arg $_ }
		Start-Process $args[0] -Verb RunAs -ArgumentList ${subArgs} -Wait
	} else {
		Start-Process $args[0] -Verb RunAs -Wait
	}
}
