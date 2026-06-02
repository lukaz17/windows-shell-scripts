################################################################################
#
#  ollama-prune
#
#  Remove unused blobs from an Ollama model store that are not referenced by
#  any manifest.
#
#  Usage:
#    ollama-prune [-Path <workspace>] [-Delete <0/1>]
#
#  Example:
#    ollama-prune
#    ollama-prune -Path .\ollama-workspace
#    ollama-prune -Path .\ollama-workspace -Delete 1
#    ollama-prune -Path C:\Users\Me\.ollama
#    ollama-prune -Path C:\Users\Me\.ollama -Delete 1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[string]$Path,

	[Parameter(Mandatory = $false)]
	[int]$Delete = $false
)

$DO_DELETE = $(${Delete} -ne 0)

if (-not $Path) {
	$Path = $env:OLLAMA_MODELS
}
if (-not $Path) {
	Write-Error "No path specified. Provide -Path or set OLLAMA_MODELS.";
	return 1
}

if (-not (Test-Path -LiteralPath ${Path} -PathType Container)) {
	throw "Path not found: ${Path}"
}

$blobsDir = [IO.Path]::Combine(${Path}, "blobs")
$manifestsDir = [IO.Path]::Combine(${Path}, "manifests")

if (-not (Test-Path -LiteralPath ${blobsDir} -PathType Container)) {
	throw "Blobs directory not found: ${blobsDir}"
}

$allBlobs = @(Get-ChildItem -LiteralPath ${blobsDir} -File | ForEach-Object { $_.Name })
Write-Host "> Found $($allBlobs.Count) blob(s) in store."

$referencedDigests = [System.Collections.Generic.HashSet[string]]::new()
$manifestFiles = @()

if (Test-Path -LiteralPath ${manifestsDir} -PathType Container) {
	$manifestFiles = @(Get-ChildItem -LiteralPath ${manifestsDir} -Recurse -File)
	foreach ($mf in ${manifestFiles}) {
		try {
			$content = Get-Content -LiteralPath $mf.FullName -Raw | ConvertFrom-Json
			if ($content.config -and $content.config.digest) {
				[void]$referencedDigests.Add(($content.config.digest -replace ':', '-'))
			}
			if ($content.layers) {
				foreach ($layer in $content.layers) {
					if ($layer.digest) {
						[void]$referencedDigests.Add(($layer.digest -replace ':', '-'))
					}
				}
			}
		} catch {
			Write-Warning "Failed to parse manifest: $($mf.FullName): $_"
		}
	}
}

Write-Host "> Found $($referencedDigests.Count) referenced blob(s) from $($manifestFiles.Count) manifest(s)."

$unusedBlobs = @($allBlobs | Where-Object { -not $referencedDigests.Contains($_) })

if ($unusedBlobs.Count -eq 0) {
	Write-Host "> No unused blobs found."
	Write-Host ""
	return
}

Write-Host "> Found $($unusedBlobs.Count) unused blob(s):"
foreach ($blob in ${unusedBlobs}) {
	Write-Host ">   ${blob}"
}

if (${DO_DELETE}) {
	foreach ($blob in ${unusedBlobs}) {
		$blobPath = [IO.Path]::Combine(${blobsDir}, ${blob})
		Write-Host "> Removing: ${blob}"
		Remove-Item -LiteralPath ${blobPath} -Force
	}
	Write-Host "> Done. Removed $($unusedBlobs.Count) unused blob(s)."
} else {
	$answer = Read-Host "> Delete these $($unusedBlobs.Count) blob(s)? [y/N]"
	if ($answer -eq 'y' -or $answer -eq 'Y') {
		foreach ($blob in ${unusedBlobs}) {
			$blobPath = [IO.Path]::Combine(${blobsDir}, ${blob})
			Write-Host "> Removing: ${blob}"
			Remove-Item -LiteralPath ${blobPath} -Force
		}
		Write-Host "> Done. Removed $($unusedBlobs.Count) unused blob(s)."
	} else {
		Write-Host "> Skipped. Run with -Delete 1 to delete without prompting."
	}
}
Write-Host ""
