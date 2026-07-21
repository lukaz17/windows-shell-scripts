################################################################################
#
#  ollama-import
#
#  Import GGUF file(s) into Ollama model.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-import -Model <model:tag> -Src <path> [-Src2 <path>] [-Src3 <path>] [-Src4 <path>] [-Src5 <path>] [-ContextSize <KB>] [-Verify <0/1>]
#
#  Example:
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -Verify 1
#    ollama-import qwen3.6:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf -ContextSize 256 -Verify 1
#    ollama-import qwen3.6-vl:27b-q8_0 .\Qwen3.6-27B-Q8_0.gguf .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-import -Model qwen3.6-vl:27b-q8_0 -Src .\Qwen3.6-27B-Q8_0.gguf -Src2 .\mmproj-F16.gguf -ContextSize 256 -Verify 1
#    ollama-import -Model mymodel:v1 -Src .\file1.gguf -Src2 .\file2.gguf -Src3 .\file3.gguf -Src4 .\file4.gguf -Src5 .\file5.gguf
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

$NEW_MODEL = "${Model}"
$MODEL_GGUF = (Convert-Path -Path ${Src}).Replace('\', '/')

$files = @()
if ($PSBoundParameters.ContainsKey('Src2')) {
	$files += (Convert-Path -Path ${Src2}).Replace('\', '/')
}
if ($PSBoundParameters.ContainsKey('Src3')) {
	$files += (Convert-Path -Path ${Src3}).Replace('\', '/')
}
if ($PSBoundParameters.ContainsKey('Src4')) {
	$files += (Convert-Path -Path ${Src4}).Replace('\', '/')
}
if ($PSBoundParameters.ContainsKey('Src5')) {
	$files += (Convert-Path -Path ${Src5}).Replace('\', '/')
}

$mfFile = [IO.Path]::Combine(${env:TEMP}, "ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile")
$mfContent = "FROM ${MODEL_GGUF}"
foreach ($file in $files) {
	$mfContent += "`nFROM ${file}"
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
if ($PSBoundParameters.ContainsKey('ContextSize')) {
	$ollamaCreateParams['ContextSize'] = $ContextSize
}
if ($PSBoundParameters.ContainsKey('Verify')) {
	$ollamaCreateParams['Verify'] = $Verify
}
if ($PSBoundParameters.ContainsKey('HostUrl')) {
	$ollamaCreateParams['HostUrl'] = $HostUrl
}

& "$PSScriptRoot\ollama-create.ps1" @ollamaCreateParams
