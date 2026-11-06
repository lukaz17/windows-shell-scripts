################################################################################
#
#  ollama-import
#
#  Import GGUF file(s) into Ollama model.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-import -Model <model:tag> -Src <path> [-Src2 <path>] [-Src3 <path>] [-Src4 <path>] [-Src5 <path>] [-ContextSize <KB>] [-Verify <0/1>] [-HostUrl <url>]
#
#  Example:
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -Verify 1
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -ContextSize 256 -Verify 1
#    ollama-import qwen3.6-vl:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-import -Model qwen3.6-vl:27b-q8_0 -Src .\Qwen3.6-27B-Q8_0.gguf -Src2 .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-import -Model mymodel:v1 -Src .\file1.gguf -Src2 .\file2.gguf -Src3 .\file3.gguf -Src4 .\file4.gguf -Src5 .\file5.gguf
#    ollama-import -Model qwen3.6:27b-q8_0 -Src .\Qwen3.6-27B-Q8_0.gguf -HostUrl http://ollama.local
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
	[string]$Src,

	[Parameter(Mandatory = $false)]
	[string]$Src2,

	[Parameter(Mandatory = $false)]
	[string]$Src3,

	[Parameter(Mandatory = $false)]
	[string]$Src4,

	[Parameter(Mandatory = $false)]
	[string]$Src5,

	[Parameter(Mandatory = $false)]
	[int]$ContextSize,

	[Parameter(Mandatory = $false)]
	[int]$Verify = $false,

	[Parameter(Mandatory = $false)]
	[string]$HostUrl
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$NEW_MODEL = "${Model}"
$LOAD_N_VERIFY = $(${Verify} -ne 0)

$modelfilePath = "${env:TEMP}\ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile"
$modelfileContent = ""
foreach ($source in @(${Src}, ${Src2}, ${Src3}, ${Src4}, ${Src5})) {
	if ($source) {
		$modelfileContent += "FROM $((Convert-Path -LiteralPath ${source}).Replace('\', '/'))`n"
	}
}
if ($PSBoundParameters.ContainsKey('ContextSize')) {
	$modelfileContent += "PARAMETER num_ctx $(${ContextSize} * 1024)`n"
}
Set-Content -Path ${modelfilePath} -Value ${modelfileContent} -Encoding UTF8

$previousHost = $env:OLLAMA_HOST
try {
	if ($HostUrl) {
		$env:OLLAMA_HOST = "${HostUrl}"
	}
	Write-Host "> Creating new model: ${NEW_MODEL}"
	ollama create ${NEW_MODEL} -f ${modelfilePath}
	if ($LASTEXITCODE -ne 0) {
		throw "ollama create failed with exit code ${LASTEXITCODE}"
	}
} finally {
	$env:OLLAMA_HOST = $previousHost
	Remove-Item -Path ${modelfilePath} -ErrorAction SilentlyContinue
}

if ($LOAD_N_VERIFY) {
	& "${PSScriptRoot}\ollama-info.ps1" -Model ${Model} -HostUrl ${HostUrl}
} else {
	Write-Host "> Success."
}
Write-Host ""
