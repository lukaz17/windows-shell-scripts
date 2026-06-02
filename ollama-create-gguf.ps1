################################################################################
#
#  ollama-create-gguf
#
#  Create a custom model for Ollama from an local gguf file.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-create-gguf -Model <model:tag> -Src <path> -Src2 [<path>] [-ContextSize <KB>] [-KVCache <fp16/f16/q8_0/q4_0>] [-Verify <0/1>]
#
#  Example:
#    ollama-create-gguf qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf
#    ollama-create-gguf qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -Verify 1
#    ollama-create-gguf qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -ContextSize 256 -Verify 1
#    ollama-create-gguf qwen3.6-vl:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-create-gguf -Model qwen3.6-vl:27b-q8_0 -Src .\Qwen3.6-27B-Q8_0.gguf -Src2 .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Model,

    [Parameter(Mandatory = $true)]
    [string[]]$Src,

    [Parameter(Mandatory = $false)]
    [string[]]$Src2,

    [Parameter(Mandatory = $false)]
    [int]$ContextSize,

	[Parameter(Mandatory = $false)]
	[string]$KVCache,

	[Parameter(Mandatory = $false)]
	[int]$Verify = $false
)

$NEW_MODEL = "${Model}"
$MODEL_GGUF = "${Src}"
$MODEL_GGUF_2 = "${Src2}"

$mfFile = [IO.Path]::Combine(${env:TEMP}, "ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile")
$mfContent = "FROM ${MODEL_GGUF}"
if ($PSBoundParameters.ContainsKey('Src2')) {
	$mfContent += "`nFROM ${MODEL_GGUF_2}"
}
if ($PSBoundParameters.ContainsKey('ContextSize')) {
	$mfContent += "`nPARAMETER num_ctx $(${ContextSize} * 1024)"
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
} finally {
	Remove-Item -Path ${mfFile} -ErrorAction SilentlyContinue
}

$params = @{
	Model = $Model
}
if ($PSBoundParameters.ContainsKey('ContextSize')) { $params['ContextSize'] = $ContextSize }
if ($PSBoundParameters.ContainsKey('KVCache'))     { $params['KVCache']     = $KVCache }
if ($PSBoundParameters.ContainsKey('Verify'))      { $params['Verify']      = $Verify }

& "$PSScriptRoot\ollama-create.ps1" @params
