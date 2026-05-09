################################################################################
#
#  ollama-create-gguf
#
#  Create a custom model for Ollama from an local gguf file.
#  If version is not specified, the latest version will be installed.
#  The script won't handle input validations and delegate it to Ollama.
#
#  Usage:
#    ollama-create-gguf <model:tag> -Src <path> [-ContextSize <KB>] [-Verify <0/1>]
#
#  Example:
#    ollama-create-gguf llama-3.3-nemotron-super:49b-it-q4_K_M .\Llama-3_3-Nemotron-Super-49B-v1_5-Q4_K_M.gguf 128
#    ollama-create-gguf llama-3.3-nemotron-super:49b-it-q4_K_M .\Llama-3_3-Nemotron-Super-49B-v1_5-Q4_K_M.gguf 128 1
#    ollama-create-gguf llama-3.3-nemotron-super:49b-it-q4_K_M -Src .\Llama-3_3-Nemotron-Super-49B-v1_5-Q4_K_M.gguf -ContextSize 128
#    ollama-create-gguf llama-3.3-nemotron-super:49b-it-q4_K_M -Src .\Llama-3_3-Nemotron-Super-49B-v1_5-Q4_K_M.gguf -ContextSize 128 -Verify 1
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
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$Src,

    [Parameter(Mandatory = $false)]
    [int]$ContextSize,

	[Parameter(Mandatory = $false)]
	[int]$Verify = $false
)

$NEW_MODEL = "${Model}"
$MODEL_GGUF = "${Src}"
$LOAD_N_VERIFY = $(${Verify} -ne 0)

# Create temporary Modelfile
$mfFile = [IO.Path]::Combine(${env:TEMP}, "ollama_$([System.IO.Path]::GetRandomFileName()).Modelfile")
$mfContent = "FROM ${MODEL_GGUF}"
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
