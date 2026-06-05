################################################################################
#
#  ollama-models
#
#  Get info of all models provided by an Ollama server instance.
#
#  Usage:
#    ollama-models [<server_url>]
#
#  Example:
#    ollama-models
#    ollama-models http://ollama.local
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$OLLAMA_HOST = "http://127.0.0.1:11434"
if ("${env:OLLAMA_HOST}" -ne "") {
	$OLLAMA_HOST = "${env:OLLAMA_HOST}"
}
if (${args}.Count -ge 1) {
	$OLLAMA_HOST = ${args}[0].ToString()
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

$tagsResponse = Invoke-RestMethod -Uri "${OLLAMA_HOST}/api/tags" -Method Get
$models = $($tagsResponse.models)

$results = @()

foreach ($model in $models) {
	$modelName = $($model.name)

	$showBody = @{ model = $modelName } | ConvertTo-Json -Compress
	$showResponse = Invoke-RestMethod -Body ${showBody} -ContentType "application/json" -Method Post -Uri "${OLLAMA_HOST}/api/show"

	$numCtx = Get-ParameterFromResponse $showResponse "num_ctx"
	$architecture = Get-ModelInfoFromResponse $showResponse "general.architecture"
	$parameter_count = Get-ModelInfoFromResponse $showResponse "general.parameter_count"
	$contextLength = Get-ModelInfoFromResponse $showResponse "$($showResponse.details.family).context_length"

	$info = [PSCustomObject]@{
		name            = $modelName
		family          = $($showResponse.details.family)
		architecture    = $architecture
		parameter_size  = $($showResponse.details.parameter_size)
		parameter_count = $parameter_count
		quantization    = $($showResponse.details.quantization_level)
		context_length  = $contextLength
		context_limit   = $numCtx
		capabilities    = "$([System.String]::Join(', ', $($showResponse.capabilities)))"
	}

	$results += $info
}

$results | ConvertTo-Json -Depth 10
