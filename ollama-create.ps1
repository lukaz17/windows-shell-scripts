################################################################################
#
#  ollama-create
#
#  Create a custom model for Ollama from an existing tags in Ollama repository.
#  If version is not specified, the latest version will be installed.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-create -Model <model:tag> [-ContextSize <KB>] [-RepeatPenalty <float>] [-Temperature <float>] [-TopK <int>] [-TopP <float>] [-MinP <float>] [-BaseModel <model:tag>] [-KVCache <fp16/f16/q8_0/q4_0>] [-Verify <0/1>]
#
#  Example:
#    ollama-create qwen3.6:27b-q8_0 -ContextSize 256
#    ollama-create qwen3.6:27b-q8_0 qwen3.6:27b-q8_0 256
#    ollama-create qwen3.6:27b-q8_0 -ContextSize 256 -Verify 1
#    ollama-create -Model qwen3.6:27b-q8_0 -ContextSize 256 -Temperature 0.7 -TopK 40 -TopP 0.9 -MinP 0.05 -RepeatPenalty 1.1
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
	[string]$BaseModel,

	[Parameter(Mandatory = $false)]
	[int]$ContextSize,

	[Parameter(Mandatory = $false)]
	[float]$RepeatPenalty,

	[Parameter(Mandatory = $false)]
	[float]$Temperature,

	[Parameter(Mandatory = $false)]
	[int]$TopK,

	[Parameter(Mandatory = $false)]
	[float]$TopP,

	[Parameter(Mandatory = $false)]
	[float]$MinP,

	[Parameter(Mandatory = $false)]
	[string]$KVCache,

	[Parameter(Mandatory = $false)]
	[int]$Verify = $false
)

$NEW_MODEL = "${Model}"
$BASE_MODEL = "${BaseModel}"
if ("${BASE_MODEL}" -eq "") {
	$BASE_MODEL = "${Model}"
}
$CONTEXT_LENGTH_KB = ${ContextSize}
$REPEAT_PENALTY = ${RepeatPenalty}
$TEMPERATURE = ${Temperature}
$TOP_K = ${TopK}
$TOP_P = ${TopP}
$MIN_P = ${MinP}
$KV_CACHE = "${KVCache}"
$LOAD_N_VERIFY = $(${Verify} -ne 0)

$mfFile = [IO.Path]::Combine(${env:TEMP}, "ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile")
$mfContent = "FROM ${BASE_MODEL}"
if ($PSBoundParameters.ContainsKey('ContextSize')) {
	$mfContent += "`nPARAMETER num_ctx $(${CONTEXT_LENGTH_KB} * 1024)"
}
if ($PSBoundParameters.ContainsKey('RepeatPenalty')) {
	$mfContent += "`nPARAMETER repeat_penalty ${REPEAT_PENALTY}"
}
if ($PSBoundParameters.ContainsKey('Temperature')) {
	$mfContent += "`nPARAMETER temperature ${TEMPERATURE}"
}
if ($PSBoundParameters.ContainsKey('TopK')) {
	$mfContent += "`nPARAMETER top_k ${TOP_K}"
}
if ($PSBoundParameters.ContainsKey('TopP')) {
	$mfContent += "`nPARAMETER top_p ${TOP_P}"
}
if ($PSBoundParameters.ContainsKey('MinP')) {
	$mfContent += "`nPARAMETER min_p ${MIN_P}"
}
if ($PSBoundParameters.ContainsKey('KVCache')) {
	$mfContent += "`nPARAMETER kv_cache ${KV_CACHE}"
}
Set-Content -Path ${mfFile} -Value ${mfContent} -Encoding UTF8

try {
	Write-Host "> Creating new model: ${NEW_MODEL}"
	ollama create ${NEW_MODEL} -f ${mfFile}
	if ($LASTEXITCODE -ne 0) {
		throw "ollama create failed with exit code $LASTEXITCODE"
	}

	if (${LOAD_N_VERIFY}) {
		Write-Host "> Load model into memory."
		$loadBody = @{
			model      = $Model
			messages   = @()
			keep_alive = 60
		} | ConvertTo-Json

		try {
			Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/chat"-Method Post -Body ${loadBody} -ContentType "application/json" | Out-Null
		} catch {
			throw "Failed to load model into memory: $_"
		}

		Write-Host "> Query model details."
		try {
			$psResponse = Invoke-RestMethod `
				-Uri    "http://127.0.0.1:11434/api/ps" `
				-Method Get
		} catch {
			throw "Failed to query /api/ps: $_"
		}

		$first = $psResponse.models | Select-Object -First 1
		if ($null -eq $first) {
			throw "Model not found in /api/ps"
		}

		Write-Host "Name               : $($first.name)"
		Write-Host "Parameter Size     : $($first.details.parameter_size)"
		Write-Host "Quantization Level : $($first.details.quantization_level)"
		Write-Host "Family             : $($first.details.family)"
		Write-Host "Context Size       : $($first.context_length)"
		Write-Host "Memory             : $($first.size)"
		Write-Host "> Success."
	} else {
		Write-Host "> Success."
		Start-Sleep -Seconds 1
	}
} finally {
	Remove-Item -Path ${mfFile} -ErrorAction SilentlyContinue
}
Write-Host ""
