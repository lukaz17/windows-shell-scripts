################################################################################
#
#  registry-export
#
#  Export a Registry key into PowerShell script.
#
#  Usage:
#    registry-export -Key <registry_key> -File [<file_path>]
#
#  Example:
#    registry-export HKEY_CURRENT_USER\SOFTWARE\Microsoft\Notepad
#    registry-export HKEY_CURRENT_USER\SOFTWARE\Microsoft\Notepad .\Notepad.ps1
#    registry-export -Key HKEY_CURRENT_USER\SOFTWARE\Microsoft\Notepad -File .\Notepad.ps1
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$Key,

	[Parameter(Mandatory = $false)]
	[string]$File
)

# ------------------------------------------------------------------------------
# Get registry path in PowerShell format
# ------------------------------------------------------------------------------
function Get-RegPSPath {
	param (
		[Parameter(Mandatory)] [string] $Key
	)
	return ${Key} `
		-replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\' `
		-replace '^HKEY_CURRENT_USER\\',  'HKCU:\' `
		-replace '^HKEY_CLASSES_ROOT\\',   'HKCR:\' `
		-replace '^HKEY_USERS\\',          'HKU:\' `
		-replace '^HKEY_CURRENT_CONFIG\\','HKCC:\' `
		-replace '^HKLM\\',               'HKLM:\' `
		-replace '^HKCU\\',               'HKCU:\' `
		-replace '^HKCR\\',               'HKCR:\' `
		-replace '^HKU\\',                'HKU:\' `
		-replace '^HKCC\\',               'HKCC:\'
}

# ------------------------------------------------------------------------------
# Get registry value type in PowerShell format
# ------------------------------------------------------------------------------
function Get-RegValueType($kind) {
	switch (${kind}) {
		'String'       { 'String' }
		'ExpandString' { 'ExpandString' }
		'Binary'       { 'Binary' }
		'DWord'        { 'DWord' }
		'MultiString'  { 'MultiString' }
		'QWord'        { 'QWord' }
		default        { 'Unknown' }
	}
}

# ------------------------------------------------------------------------------
# Get registry value data in PowerShell format
# ------------------------------------------------------------------------------
function Get-RegValueData($raw, $kind) {
	switch (${kind}) {
		'DWord' {
			'0x{0:X8}' -f [int32]${raw}
		}
		'QWord' {
			'0x{0:X16}' -f [int64]${raw}
		}
		'Binary' {
			if (${raw}.Length -eq 0) {
				'[byte[]] @()'
			} else {
				'[byte[]] @(' + ((${raw} | ForEach-Object { '0x{0:X2}' -f $_ }) -join ', ') + ')'
			}
		}
		'MultiString' {
			if (${raw}.Length -eq 0) {
				'[string[]] @()'
			} else {
				'[string[]] @(' + ((${raw} | ForEach-Object { '"' + ($_ -replace '"', '`"') + '"' }) -join ', ') + ')'
			}
		}
		default {
			'"' + (${raw} -replace '(["`$])', '`$1') + '"'
		}
	}
}

# ------------------------------------------------------------------------------
# Export values of a registry key and its sub-keys to PowerShell commands
# ------------------------------------------------------------------------------
function Export-RegKey($key) {
	$lines = [System.Collections.Generic.List[string]]::new()
	$psPath = ${key}.Name `
		-replace '^HKEY_LOCAL_MACHINE\\',  'HKLM:\' `
		-replace '^HKEY_CURRENT_USER\\',   'HKCU:\' `
		-replace '^HKEY_CLASSES_ROOT\\',   'HKCR:\' `
		-replace '^HKEY_USERS\\',          'HKU:\' `
		-replace '^HKEY_CURRENT_CONFIG\\', 'HKCC:\'

	${lines}.Add("")
	${lines}.Add('$regPath = "' + (${psPath} -replace '(["`$])', '`$1') + '"')
	${lines}.Add('Create-RegistryKey $regPath')

	foreach ($valueName in (${key}.GetValueNames() | Sort-Object)) {
		$kind     = ${key}.GetValueKind(${valueName})
		$raw      = ${key}.GetValue(${valueName}, $null, [Microsoft.Win32.RegistryValueOptions]'DoNotExpand')
		$typeName = Get-RegValueType ${kind}
		$value    = Get-RegValueData ${raw} ${kind}

		$quotedName = if (${valueName} -eq '') {
			'"(default)"'
		} else {
			'"' + (${valueName} -replace '(["`$])', '`$1') + '"'
		}

		${lines}.Add("Set-ItemProperty -Path `$regPath -Name ${quotedName} -Type ${typeName} -Value ${value}")
	}

	foreach ($subKeyName in (${key}.GetSubKeyNames() | Sort-Object)) {
		$subKey = ${key}.OpenSubKey(${subKeyName})
		if ($null -ne ${subKey}) {
			$subLines = Export-RegKey ${subKey}
			for ($i = 0; $i -lt ${subLines}.Count; $i++) {
				${lines}.Add(${subLines}[$i])
			}
			${subKey}.Close()
		}
	}

	return ${lines}
}

$psPath = Get-RegPSPath ${Key}

if (${psPath} -match '^(HKLM|HKCU|HKCR|HKU|HKCC):\\?$') {
	Write-Error "Cannot export root registry hive: ${Key}"
	exit 1
}

if ("${File}" -eq "") {
	if (${Key} -match '.+\\(.+)') {
		$File = "$(${Matches}[1]).ps1"
	} else {
		Write-Error "Cannot derive filename from root registry hive: ${Key}"
		exit 1
	}
}

if (-not (Test-Path ${psPath})) {
	Write-Error "Registry key not found: ${Key}"
	exit 1
}

$hiveMap = @{
	'HKLM' = [Microsoft.Win32.Registry]::LocalMachine
	'HKCU' = [Microsoft.Win32.Registry]::CurrentUser
	'HKCR' = [Microsoft.Win32.Registry]::ClassesRoot
	'HKU'  = [Microsoft.Win32.Registry]::Users
	'HKCC' = [Microsoft.Win32.Registry]::CurrentConfig
}

if (${psPath} -notmatch '^([^:\\]+):\\(.+)$') {
	Write-Error "Cannot parse registry path: ${psPath}"
	exit 1
}
$hiveStr   = $Matches[1]
$subKeyStr = $Matches[2]

if (-not ${hiveMap}.ContainsKey(${hiveStr})) {
	Write-Error "Unrecognised hive '${hiveStr}' in key path: ${Key}"
	exit 1
}

$rootKey = ${hiveMap}[${hiveStr}].OpenSubKey(${subKeyStr})
if ($null -eq ${rootKey}) {
	Write-Error "Could not open registry key: ${Key}"
	exit 1
}

$lines = [System.Collections.Generic.List[string]]::new()
${lines}.Add(@"
function Create-RegistryKey($path, [switch]$overwrite) {
	if ($overwrite -and (Test-Path $path)) {
		Remove-Item -Path $path -Recurse -Force
	}
	if (-not (Test-Path $path)) {
		New-Item -Path $path -Force | Out-Null
	}
}
"@)

$subLines = Export-RegKey ${rootKey}
for ($i = 0; $i -lt ${subLines}.Count; $i++) {
	${lines}.Add(${subLines}[$i])
}
${rootKey}.Close()

${lines} | Set-Content -Path ${File} -Encoding UTF8

Write-Host "> Exported '${Key}' -> '${File}'"
