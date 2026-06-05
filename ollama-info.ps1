################################################################################
#
#  ollama-info
#
#  Load a model into memory and print its runtime info from an Ollama server.
#
#  Usage:
#    ollama-info -Model <model:tag> [-HostUrl <url>]
#
#  Example:
#    ollama-info qwen3.6:27b-q8_0
#    ollama-info -Model qwen3.6:27b-q8_0 -HostUrl http://ollama.local
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$Model,

	[Parameter(Mandatory = $false)]
	[string]$HostUrl
)

$OLLAMA_HOST = "http://127.0.0.1:11434"
if ("${env:OLLAMA_HOST}" -ne "") {
	$OLLAMA_HOST = "${env:OLLAMA_HOST}"
}
if ($HostUrl) {
	$OLLAMA_HOST = $HostUrl
}

function Get-ParameterFromResponse($showResponse, $paramName) {
	if ($showResponse.PSObject.Properties['parameters']) {
		foreach ($line in $($showResponse.parameters) -split "`n") {
			if (${line}.Trim() -match "^${paramName}\s+(.+)") {
				return [int]${matches}[1]
			}
		}
	}
	return $null
}

function Get-ModelInfoFromResponse($showResponse, $keyPattern) {
	if ($showResponse.PSObject.Properties['model_info']) {
		foreach ($key in $($showResponse.model_info.PSObject.Properties.Name)) {
			if (${key} -match $keyPattern) {
				return $($showResponse.model_info.${key})
			}
		}
	}
	return $null
}

Write-Host "> Check model capabilities."
try {
	$showBody = @{ name = $Model } | ConvertTo-Json
	$showResponse = Invoke-RestMethod -Uri "${OLLAMA_HOST}/api/show" -Method Post -Body ${showBody} -ContentType "application/json"
} catch {
	throw "Failed to query /api/show: $_"
}
$isEmbedding = $false
if ($null -ne $showResponse.capabilities) {
	foreach ($cap in $showResponse.capabilities) {
		if ($cap -eq "embedding") {
			$isEmbedding = $true
			break
		}
	}
}
$architecture = Get-ModelInfoFromResponse $showResponse "general.architecture"
$parameter_count = Get-ModelInfoFromResponse $showResponse "general.parameter_count"
$contextLength = Get-ModelInfoFromResponse $showResponse "$($showResponse.details.family).context_length"
$capabilities = "$([System.String]::Join(', ', $($showResponse.capabilities)))"

Write-Host "> Load model into memory."
if ($isEmbedding) {
	try {
		$null = & ollama run $Model "hello world" 2>&1 | Out-Null
	} catch {
		throw "Failed to load model into memory: $_"
	}
} else {
	$loadBody = @{
		model      = $Model
		messages   = @()
		keep_alive = 300
	} | ConvertTo-Json

	try {
		Invoke-RestMethod -Uri "${OLLAMA_HOST}/api/chat" -Method Post -Body ${loadBody} -ContentType "application/json" | Out-Null
	} catch {
		throw "Failed to load model into memory: $_"
	}
}

Write-Host "> Query model details."
try {
	$psResponse = Invoke-RestMethod `
		-Uri    "${OLLAMA_HOST}/api/ps" `
		-Method Get
} catch {
	throw "Failed to query /api/ps: $_"
}

$first = $psResponse.models | Where-Object { $_.model -eq $Model } | Select-Object -First 1
if ($null -eq $first) {
	throw "Model not found in /api/ps"
}

Write-Host "Name               : $($first.name)"
Write-Host "Family             : $($first.details.family)"
Write-Host "Architecture       : ${architecture}"
Write-Host "Parameter Size     : $($first.details.parameter_size)"
Write-Host "Parameter Count    : ${parameter_count}"
Write-Host "Quantization       : $($first.details.quantization_level)"
Write-Host "Context Length     : ${contextLength}"
Write-Host "Context Allocated  : $($first.context_length) ($(($first.context_length / $contextLength).ToString("P1")))"
Write-Host "Context Memory     : $($first.size)"
Write-Host "VRAM Usage         : $($first.size_vram) ($(($first.size_vram / $first.size).ToString("P1")))"
Write-Host "Capabilities       : ${capabilities}"
Write-Host "> Success."
