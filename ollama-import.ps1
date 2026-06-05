################################################################################
#
#  ollama-import
#
#  Import GGUF file(s) into Ollama model.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-import -Model <model:tag> -Src <path> -Src2 [<path>] [-ContextSize <KB>] [-Verify <0/1>]
#
#  Example:
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -Verify 1
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -ContextSize 256 -Verify 1
#    ollama-import qwen3.6-vl:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-import -Model qwen3.6-vl:27b-q8_0 -Src .\Qwen3.6-27B-Q8_0.gguf -Src2 .\mmproj-F16.gguf -ContextSize 256 -Verify 1
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
	[int]$Verify = $false,

	[Parameter(Mandatory = $false)]
	[string]$HostUrl
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

$ollamaCreateParams = @{
	Model = $Model
}
if ($PSBoundParameters.ContainsKey('ContextSize')) { $ollamaCreateParams['ContextSize'] = $ContextSize }
if ($PSBoundParameters.ContainsKey('KVCache'))     { $ollamaCreateParams['KVCache']     = $KVCache }
if ($PSBoundParameters.ContainsKey('Verify'))      { $ollamaCreateParams['Verify']      = $Verify }
if ($PSBoundParameters.ContainsKey('HostUrl'))     { $ollamaCreateParams['HostUrl']     = $HostUrl }

& "$PSScriptRoot\ollama-create.ps1" @ollamaCreateParams
