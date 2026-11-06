################################################################################
#
#  ollama-info
#
#  Load a model into memory and return its runtime info from an Ollama server.
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

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$KEEP_ALIVE_SECONDS = 300
$LOAD_INPUT = "hello world"

$OLLAMA_HOST = "http://127.0.0.1:11434"
if ("${env:OLLAMA_HOST}" -ne "") {
	$OLLAMA_HOST = "${env:OLLAMA_HOST}"
}
if ($HostUrl) {
	$OLLAMA_HOST = $HostUrl
}

# ------------------------------------------------------------------------------
# Get the first model_info value whose key matches a regex, or $null if none does.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Get a part as a percentage of its total, to 1 decimal place, or $null if the total is missing or 0.
# ------------------------------------------------------------------------------
function Get-PercentageOfTotal($part, $total) {
	if (-not $total) {
		return $null
	}
	return [math]::Round($part / $total * 100, 1)
}

Write-Host "> Check model capabilities."
try {
	$showBody = @{ model = $Model } | ConvertTo-Json
	$showResponse = Invoke-RestMethod -Uri "${OLLAMA_HOST}/api/show" -Method Post -Body ${showBody} -ContentType "application/json"
} catch {
	throw "Failed to query /api/show: ${_}"
}
$capabilityList = @()
if ($showResponse.PSObject.Properties['capabilities']) {
	$capabilityList = @($showResponse.capabilities)
}
$isEmbedding = $capabilityList -contains "embedding"
$architecture = Get-ModelInfoFromResponse ${showResponse} "general.architecture"
$parameterCount = Get-ModelInfoFromResponse ${showResponse} "general.parameter_count"
$contextLength = Get-ModelInfoFromResponse ${showResponse} "${architecture}.context_length"

Write-Host "> Load model into memory."
$loadRequest = @{
	model      = $Model
	keep_alive = $KEEP_ALIVE_SECONDS
}
if ($isEmbedding) {
	$loadUri = "${OLLAMA_HOST}/api/embed"
	$loadRequest['input'] = $LOAD_INPUT
} else {
	$loadUri = "${OLLAMA_HOST}/api/chat"
	$loadRequest['messages'] = @()
}
$loadBody = $loadRequest | ConvertTo-Json

try {
	Invoke-RestMethod -Uri ${loadUri} -Method Post -Body ${loadBody} -ContentType "application/json" | Out-Null
} catch {
	throw "Failed to load model into memory: ${_}"
}

Write-Host "> Query model details."
try {
	$psResponse = Invoke-RestMethod `
		-Uri    "${OLLAMA_HOST}/api/ps" `
		-Method Get
} catch {
	throw "Failed to query /api/ps: ${_}"
}

$loadedModel = $psResponse.models | Where-Object { $_.model -eq $Model } | Select-Object -First 1
if ($null -eq $loadedModel) {
	throw "Model ${Model} is not loaded on ${OLLAMA_HOST}. Check that the name includes its tag, for example llama3:latest."
}

[PSCustomObject]@{
	Name                    = $loadedModel.name
	Family                  = $loadedModel.details.family
	Architecture            = $architecture
	ParameterSize           = $loadedModel.details.parameter_size
	ParameterCount          = $parameterCount
	Quantization            = $loadedModel.details.quantization_level
	ContextLength           = $contextLength
	ContextAllocated        = $loadedModel.context_length
	ContextAllocatedPercent = Get-PercentageOfTotal $($loadedModel.context_length) ${contextLength}
	TotalMemoryBytes        = $loadedModel.size
	VramUsageBytes          = $loadedModel.size_vram
	VramUsagePercent        = Get-PercentageOfTotal $($loadedModel.size_vram) $($loadedModel.size)
	Capabilities            = $capabilityList -join ', '
}
Write-Host "> Success."
