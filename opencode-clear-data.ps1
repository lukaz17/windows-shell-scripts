################################################################################
#
#  opencode-clear-data
#
#  Clear OpenCode sessions, history and cache for the current user. Login
#  credentials (auth.json, mcp-auth.json) and user config are preserved.
#
#  Homepage: https://opencode.ai/
#
#  Usage:
#    opencode-clear-data [-Session <0/1>] [-History <0/1>] [-Cache <0/1>] [-Delete <0/1>]
#
#  Example:
#    opencode-clear-data
#    opencode-clear-data -Session 1
#    opencode-clear-data -History 1
#    opencode-clear-data -Cache 1
#    opencode-clear-data -Session 1 -History 1 -Cache 1 -Delete 1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[int]$Session = 0,

	[Parameter(Mandatory = $false)]
	[int]$History = 0,

	[Parameter(Mandatory = $false)]
	[int]$Cache = 0,

	[Parameter(Mandatory = $false)]
	[int]$Delete = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$DO_SESSION = $(${Session} -ne 0)
$DO_HISTORY = $(${History} -ne 0)
$DO_CACHE = $(${Cache} -ne 0)
$DO_DELETE = $(${Delete} -ne 0)

# Application directories
$SHARE_DIR = [IO.Path]::Combine($env:USERPROFILE, ".local", "share", "opencode")
$STATE_DIR = [IO.Path]::Combine($env:USERPROFILE, ".local", "state", "opencode")
$CACHE_DIR = [IO.Path]::Combine($env:USERPROFILE, ".cache", "opencode")

# Show usage when no flag is provided
if (-not ${DO_SESSION} -and -not ${DO_HISTORY} -and -not ${DO_CACHE}) {
	Write-Host "Usage: opencode-clear-data [-Session <0/1>] [-History <0/1>] [-Cache <0/1>] [-Delete <0/1>]"
	Write-Host "  SESSION DATA:"
	Write-Host "    ${SHARE_DIR}\opencode.db"
	Write-Host "    ${SHARE_DIR}\opencode.db-shm"
	Write-Host "    ${SHARE_DIR}\opencode.db-wal"
	Write-Host "    ${STATE_DIR}\session.json"
	Write-Host "  HISTORY DATA:"
	Write-Host "    ${STATE_DIR}\frecency.jsonl"
	Write-Host "    ${STATE_DIR}\prompt-history.jsonl"
	Write-Host "  CACHE:"
	Write-Host "    ${SHARE_DIR}\log"
	Write-Host "    ${SHARE_DIR}\repos"
	Write-Host "    ${SHARE_DIR}\snapshot"
	Write-Host "    ${SHARE_DIR}\storage"
	Write-Host "    ${SHARE_DIR}\tool-output"
	Write-Host "    ${CACHE_DIR}\models.json"
	Write-Host ""
	return
}

function Get-PathSize {
	param([string]$Path)
	if (Test-Path -LiteralPath ${Path} -PathType Container) {
		$files = @(Get-ChildItem -LiteralPath ${Path} -Recurse -File -Force -ErrorAction SilentlyContinue)
		if ($files.Count -eq 0) {
			return 0
		}
		$sum = ($files | Measure-Object Length -Sum).Sum
		if ($null -eq ${sum}) {
			return 0
		}
		return ${sum}
	}
	if (Test-Path -LiteralPath ${Path} -PathType Leaf) {
		return (Get-Item -LiteralPath ${Path}).Length
	}
	return 0
}

function Get-SizeString {
	param([long]$Bytes)
	if (${Bytes} -ge 1GB) {
		return "{0:N1} GB" -f (${Bytes} / 1GB)
	}
	if (${Bytes} -ge 1MB) {
		return "{0:N1} MB" -f (${Bytes} / 1MB)
	}
	if (${Bytes} -ge 1KB) {
		return "{0:N1} KB" -f (${Bytes} / 1KB)
	}
	return "${Bytes} B"
}

# Collect delete targets
$deleteTargets = @()

if (${DO_SESSION}) {
	$sessionTargets = @(
		[IO.Path]::Combine(${SHARE_DIR}, "opencode.db"),
		[IO.Path]::Combine(${SHARE_DIR}, "opencode.db-shm"),
		[IO.Path]::Combine(${SHARE_DIR}, "opencode.db-wal"),
		[IO.Path]::Combine(${STATE_DIR}, "session.json")
	)
	foreach ($targetPath in ${sessionTargets}) {
		if (Test-Path -LiteralPath ${targetPath}) {
			$deleteTargets += [PSCustomObject]@{
				Kind = "session"
				Path = ${targetPath}
			}
		}
	}
}

if (${DO_HISTORY}) {
	$historyTargets = @(
		[IO.Path]::Combine(${STATE_DIR}, "frecency.jsonl"),
		[IO.Path]::Combine(${STATE_DIR}, "prompt-history.jsonl")
	)
	foreach ($targetPath in ${historyTargets}) {
		if (Test-Path -LiteralPath ${targetPath}) {
			$deleteTargets += [PSCustomObject]@{
				Kind = "history"
				Path = ${targetPath}
			}
		}
	}
}

if (${DO_CACHE}) {
	$cacheTargets = @(
		[IO.Path]::Combine(${SHARE_DIR}, "log"),
		[IO.Path]::Combine(${SHARE_DIR}, "repos"),
		[IO.Path]::Combine(${SHARE_DIR}, "snapshot"),
		[IO.Path]::Combine(${SHARE_DIR}, "storage"),
		[IO.Path]::Combine(${SHARE_DIR}, "tool-output"),
		[IO.Path]::Combine(${CACHE_DIR}, "models.json")
	)
	foreach ($targetPath in ${cacheTargets}) {
		if (Test-Path -LiteralPath ${targetPath}) {
			$deleteTargets += [PSCustomObject]@{
				Kind = "cache"
				Path = ${targetPath}
			}
		}
	}
}

if ($deleteTargets.Count -eq 0) {
	Write-Host "> Nothing to clear. Selected OpenCode data is already clean."
	Write-Host ""
	return
}

$totalBytes = 0
Write-Host "> Found $($deleteTargets.Count) item(s) to clear:"
foreach ($target in ${deleteTargets}) {
	$size = Get-PathSize -Path "$($target.Path)"
	$totalBytes += ${size}
	Write-Host "> [$($target.Kind)] $($target.Path) ($(Get-SizeString -Bytes ${size}))"
}
Write-Host "> Total: $(Get-SizeString -Bytes ${totalBytes})"

if (${DO_DELETE}) {
	$answer = "y"
} else {
	$answer = Read-Host "> Clear these $($deleteTargets.Count) item(s)? [y/N]"
}

if ($answer -eq 'y' -or $answer -eq 'Y') {
	foreach ($target in ${deleteTargets}) {
		Remove-Item -LiteralPath "$($target.Path)" -Recurse -Force
		Write-Host "> Removed: $($target.Path)"
	}
	Write-Host "> Done. Cleared $(Get-SizeString -Bytes ${totalBytes})."
} else {
	Write-Host "> Skipped. Run with -Delete 1 to clear without prompting."
}
Write-Host ""
