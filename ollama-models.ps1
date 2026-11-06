################################################################################
#
#  ollama-models
#
#  Get info of all models provided by an Ollama server instance.
#
#  Usage:
#    ollama-models [-HostUrl <url>]
#
#  Example:
#    ollama-models
#    ollama-models http://ollama.local
#    ollama-models -HostUrl http://ollama.local
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[string]$HostUrl
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$OLLAMA_HOST = "http://127.0.0.1:11434"
if ("${env:OLLAMA_HOST}" -ne "") {
	$OLLAMA_HOST = "${env:OLLAMA_HOST}"
}
if ($HostUrl) {
	$OLLAMA_HOST = $HostUrl
}

# ------------------------------------------------------------------------------
# Get an integer parameter from an /api/show response, or $null if it is not set.
# ------------------------------------------------------------------------------
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

try {
	$tagsResponse = Invoke-RestMethod -Uri "${OLLAMA_HOST}/api/tags" -Method Get
} catch {
	throw "Failed to query /api/tags: ${_}"
}
$models = $($tagsResponse.models)

$modelSummaries = @()

foreach ($model in $models) {
	$modelName = $($model.name)

	$showBody = @{ model = $modelName } | ConvertTo-Json -Compress
	try {
		$showResponse = Invoke-RestMethod -Body ${showBody} -ContentType "application/json" -Method Post -Uri "${OLLAMA_HOST}/api/show"
	} catch {
		throw "Failed to query /api/show for ${modelName}: ${_}"
	}

	$capabilityList = @()
	if ($showResponse.PSObject.Properties['capabilities']) {
		$capabilityList = @($showResponse.capabilities)
	}
	$numCtx = Get-ParameterFromResponse ${showResponse} "num_ctx"
	$architecture = Get-ModelInfoFromResponse ${showResponse} "general.architecture"
	$parameterCount = Get-ModelInfoFromResponse ${showResponse} "general.parameter_count"
	$contextLength = Get-ModelInfoFromResponse ${showResponse} "${architecture}.context_length"

	$modelSummary = [PSCustomObject]@{
		name            = $modelName
		family          = $($showResponse.details.family)
		architecture    = $architecture
		parameter_size  = $($showResponse.details.parameter_size)
		parameter_count = $parameterCount
		quantization    = $($showResponse.details.quantization_level)
		context_length  = $contextLength
		context_limit   = $numCtx
		capabilities    = $capabilityList -join ', '
	}

	$modelSummaries += $modelSummary
}

ConvertTo-Json -InputObject @($modelSummaries) -Depth 10
