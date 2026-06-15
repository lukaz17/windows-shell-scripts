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
	[float]$Temperature,

	[Parameter(Mandatory = $false)]
	[int]$TopK,

	[Parameter(Mandatory = $false)]
	[float]$TopP,

	[Parameter(Mandatory = $false)]
	[float]$RepeatPenalty,

	[Parameter(Mandatory = $false)]
	[float]$MinP,

	[Parameter(Mandatory = $false)]
	[string]$KVCache,

	[Parameter(Mandatory = $false)]
	[int]$Verify = $false,

	[Parameter(Mandatory = $false)]
	[string]$HostUrl
)

$NEW_MODEL = "${Model}"
$BASE_MODEL = "${BaseModel}"
if ("${BASE_MODEL}" -eq "") {
	$BASE_MODEL = "${Model}"
}
$CONTEXT_LENGTH_KB = ${ContextSize}
$TEMPERATURE = ${Temperature}
$TOP_K = ${TopK}
$TOP_P = ${TopP}
$REPEAT_PENALTY = ${RepeatPenalty}
$MIN_P = ${MinP}
$KV_CACHE = "${KVCache}"
$LOAD_N_VERIFY = $(${Verify} -ne 0)

$OLLAMA_HOST = "http://127.0.0.1:11434"
if ("${env:OLLAMA_HOST}" -ne "") {
	$OLLAMA_HOST = "${env:OLLAMA_HOST}"
}
if ($HostUrl) {
	$OLLAMA_HOST = $HostUrl
}

$mfFile = [IO.Path]::Combine(${env:TEMP}, "ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile")
$mfContent = "FROM ${BASE_MODEL}"
if ($PSBoundParameters.ContainsKey('ContextSize')) {
	$mfContent += "`nPARAMETER num_ctx $(${CONTEXT_LENGTH_KB} * 1024)"
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
if ($PSBoundParameters.ContainsKey('RepeatPenalty')) {
	$mfContent += "`nPARAMETER repeat_penalty ${REPEAT_PENALTY}"
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

	if ($LOAD_N_VERIFY) {
		& "$PSScriptRoot\ollama-info.ps1" -Model $Model -HostUrl $OLLAMA_HOST
	} else {
		Write-Host "> Success."
		Start-Sleep -Seconds 1
	}
} finally {
	Remove-Item -Path ${mfFile} -ErrorAction SilentlyContinue
}
Write-Host ""
