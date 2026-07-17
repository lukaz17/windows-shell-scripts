################################################################################
#
#  cliinst-update
#
#  Update CliInst to latest version.
#
#  Usage:
#    cliinst-update
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$gitDir = Join-Path $PSScriptRoot ".git"
if (Test-Path -LiteralPath "${gitDir}" -PathType Container) {
	Write-Host "> Check for update from git."
	if (Get-Command git -ErrorAction SilentlyContinue) {
		try {
			git -C "${PSScriptRoot}" pull --rebase
			Write-Host "> Success."
		} catch {
			Write-Warning "Failed to update: $_"
		}
	} else {
		Write-Warning "Git command not found."
	}
} else {
	Write-Warning "This is not a git repository."
}
