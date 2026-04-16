################################################################################
#
#  install-common
#  Libraries to support *-install scripts
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

# ------------------------------------------------------------------------------
# Create a directory safely
# ------------------------------------------------------------------------------
function New-Directory2 {
	param(
		[Parameter(Mandatory)] [string] $Path
	)

	if (!(Test-Path "${Path}" -PathType Container)) {
		New-Item -ItemType Directory -Path "${Path}" -Force | Out-Null
	}
}

# ------------------------------------------------------------------------------
# Remove file/folder safely
# ------------------------------------------------------------------------------
function Remove-Item2 {
	param(
		[Parameter(Mandatory)] [string] $Path
	)

	if (Test-Path "${Path}") {
		Remove-Item "${Path}" -Recurse -Force
	}
}

# ------------------------------------------------------------------------------
# Copy file/folder safely
# ------------------------------------------------------------------------------
function Copy-Item2 {
	param(
		[Parameter(Mandatory)] [string] $From,
		[Parameter(Mandatory)] [string] $To,
		[switch] $Overwrite
	)

	if (${Overwrite}) {
		Remove-Item2 "${To}"
	}

	Copy-Item -Path "${From}" -Destination "${To}" -Recurse
}

# ------------------------------------------------------------------------------
# Move file/folder safely
# ------------------------------------------------------------------------------
function Move-Item2 {
	param(
		[Parameter(Mandatory)] [string] $From,
		[Parameter(Mandatory)] [string] $To,
		[switch] $Overwrite
	)

	if (${Overwrite}) {
		Remove-Item2 "${To}"
	}

	Move-Item -Path "${From}" -Destination "${To}"
}

# ------------------------------------------------------------------------------
# Create file/folder junction safely
# ------------------------------------------------------------------------------
function Link-Item2 {
	param(
		[Parameter(Mandatory)] [string] $From,
		[Parameter(Mandatory)] [string] $To,
		[Parameter()] [string] $Type = "Junction",
		[switch] $Overwrite
	)

	if (${Overwrite}) {
		Remove-Item2 "${To}"
	}

	New-Item -ItemType "${Type}" -Target "${From}" -Path "${To}"
}

# ------------------------------------------------------------------------------
# Download from URI
# ------------------------------------------------------------------------------
function Download-Uri {
	param(
		[Parameter(Mandatory)] [string] $Uri,
		[Parameter(Mandatory)] [string] $OutFile
	)
	$curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
	if ($curl -and $($curl.Source) -ne "") {
		& "$($curl.Source)" -fSL "${Uri}" -o "${OutFile}"
		if (${LASTEXITCODE} -ne 0) {
			Write-Output "curl failed with exit code ${LASTEXITCODE}"
			exit 1
		}
		return
	}

	$ProgressPreference = "SilentlyContinue"
	Invoke-WebRequest -Uri "${Uri}" -OutFile "${OutFile}"
	$ProgressPreference = "Continue"
}

# ------------------------------------------------------------------------------
# Normalize install version for consistency
# ------------------------------------------------------------------------------
function Normalize-InstallVersion {
	param(
		[Parameter()] [string] $Version = ""
	)

	if ("${Version}" -eq "") {
		Write-Output "Normalize-InstallVersion: Install version is not specified"
		exit 1
	}

	return ${Version}.TrimStart("v")
}

# ------------------------------------------------------------------------------
# Get latest version from GitHub
# ------------------------------------------------------------------------------
function Get-InstallVersionFromGithub {
	param(
		[Parameter(Mandatory)] [string] $Owner,
		[Parameter(Mandatory)] [string] $Repo,
		[string] $FallbackVersion = ""
	)

	if ("${FallbackVersion}" -eq "") {
		$version = (Invoke-WebRequest "https://api.github.com/repos/${Owner}/${Repo}/releases/latest" | ConvertFrom-Json).tag_name
	} else {
		$version = ${FallbackVersion}
	}

	return Normalize-InstallVersion "${version}"
}

# ------------------------------------------------------------------------------
# Initialize environment for the install and pre-populate root dirs
# ------------------------------------------------------------------------------
function Initialize-InstallEnv {
	param(
		[Parameter(Mandatory)] [string] $ProgramId,
		[Parameter(Mandatory)] [string] $Version,
		[switch] $IsApplication
	)

	$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	$arch = ${env:PROCESSOR_ARCHITECTURE}

	if (${isAdmin}) {
		$installRoot = [IO.Path]::Combine(${env:PROGRAMFILES}, ${ProgramId})
		$desktopRoot = [IO.Path]::Combine(${env:ALLUSERSPROFILE}, "Desktop")
		$startMenuRoot = [IO.Path]::Combine(${env:ALLUSERSPROFILE}, "Start Menu", "Apps")
	} else {
		$installRoot = [IO.Path]::Combine(${env:USERPROFILE}, ".local", "share", ${ProgramId})
		$desktopRoot = [IO.Path]::Combine(${env:USERPROFILE}, "Desktop")
		$startMenuRoot = [IO.Path]::Combine(${env:USERPROFILE}, "Start Menu", "Apps")
	}
	$tempRoot = ${env:TEMP}

	if (${env:CLIINST_USR_LOCAL_SHARE} -ne "") {
		$installRoot = [IO.Path]::Combine(${env:CLIINST_USR_LOCAL_SHARE}, ${ProgramId})
	}
	if (${env:CLIINST_TEMP} -ne "") {
		$tempRoot = ${env:CLIINST_TEMP}
	}

	$installTarget = [IO.Path]::Combine(${installRoot}, "${ProgramId}-v${Version}")
	$activeTarget  = [IO.Path]::Combine(${installRoot}, "active-release")
	$tempTarget  = [IO.Path]::Combine(${tempRoot}, "${ProgramId}-v${Version}")

	New-Directory2 "${installRoot}"
	New-Directory2 "${tempRoot}"
	if (${IsApplication}) {
		New-Directory2 "${startMenuRoot}"
	}

	return @{
		IsAdmin = ${isAdmin}
		Arch = ${arch}
		InstallRoot = ${installRoot}
		DesktopRoot = ${desktopRoot}
		StartMenuRoot = ${startMenuRoot}
		TempRoot = ${tempRoot}
		InstallTarget = ${installTarget}
		ActiveTarget = ${activeTarget}
		TempTarget = ${tempTarget}
	}
}

# ------------------------------------------------------------------------------
# Download different file based on current system architecture
# ------------------------------------------------------------------------------
function Download-UriPerArch {
	param(
		[string] $Amd64Uri = "",
		[string] $Arm64Uri = "",
		[Parameter(Mandatory)] [string] $OutputPath
	)

	if ("${Amd64Uri}" -eq "" -and "${Arm64Uri}" -eq "") {
		Write-Output "Download-UriPerArch: Invalid arguments"
		exit 1
	}

	$arch = ${env:PROCESSOR_ARCHITECTURE}
	if ("${arch}" -eq "AMD64") {
		if ("${Amd64Uri}" -eq "") {
			Write-Output "Download-UriPerArch: Unsupported architecture: ${arch}"
			exit 1
		}
		Download-Uri -Uri "${Amd64Uri}" -OutFile "${OutputPath}"
	} elseif ("${arch}" -eq "ARM64") {
		if ("${Arm64Uri}" -eq "") {
			Write-Output "Download-UriPerArch: Unsupported architecture: ${arch}"
			exit 1
		}
		Download-Uri -Uri "${Arm64Uri}" -OutFile "${OutputPath}"
	} else {
		Write-Output "Download-UriPerArch: Unsupported architecture: ${arch}"
		exit 1
	}
}

# ------------------------------------------------------------------------------
# Move file/folder based on current system architecture
# ------------------------------------------------------------------------------
function Move-ItemPerArch {
	param(
		[string] $Amd64Path = "",
		[string] $Arm64Path = "",
		[Parameter(Mandatory)] [string] $OutputPath
	)

	if ("${Amd64Path}" -eq "" -and "${Arm64Path}" -eq "") {
		Write-Output "Move-ItemPerArch: Invalid arguments"
		exit 1
	}

	$arch = ${env:PROCESSOR_ARCHITECTURE}
	if ("${arch}" -eq "AMD64") {
		if ("${Amd64Path}" -eq "") {
			Write-Output "Move-ItemPerArch: Unsupported architecture: ${arch}"
			exit 1
		}
		Move-Item2 -From "${Amd64Path}" -To "${OutputPath}"
	} elseif ("${arch}" -eq "ARM64") {
		if ("${Arm64Path}" -eq "") {
			Write-Output "Move-ItemPerArch: Unsupported architecture: ${arch}"
			exit 1
		}
		Move-Item2 -From "${Arm64Path}" -To "${OutputPath}"
	} else {
		Write-Output "Move-ItemPerArch: Unsupported architecture: ${arch}"
		exit 1
	}
}

# ------------------------------------------------------------------------------
# Extract archive
# ------------------------------------------------------------------------------
function Extract-Archive {
	param(
		[Parameter(Mandatory)] [string] $ArchivePath,
		[Parameter(Mandatory)] [string] $DestinationPath,
		[Parameter(Mandatory)] [string] $ScriptRoot
	)

	$arch = ${env:PROCESSOR_ARCHITECTURE}
	if ("${arch}" -eq "AMD64") {
		$7zCli = [IO.Path]::Combine(${ScriptRoot}, "7z-amd64", "7z.exe")
	} elseif ("${arch}" -eq "ARM64") {
		$7zCli = [IO.Path]::Combine(${ScriptRoot}, "7z-arm64", "7z.exe")
	} else {
		Write-Output "Unsupported architecture: ${arch}"
		exit 1
	}

	New-Directory2 "${DestinationPath}"
	& "${7zCli}" x "${ArchivePath}" "-o${DestinationPath}" | Out-Null
}

# ------------------------------------------------------------------------------
# Appends a bin path to the CLIINST_PATH environment variable, deduplicates
# and sorts the entries, then persists the value at Machine scope (system-wide)
# or User scope (per-user).
# Uses a temp file (CLIINST_PATH_MACHINE.txt or CLIINST_PATH_USER.txt) as an
# intermediary cache to read/write the path list.
# ------------------------------------------------------------------------------
function Update-CliinstPath {
	param(
		[Parameter(Mandatory)] [string] $BinPath,
		[Parameter()] [bool] $IsSystemWide = $false
	)

	$fileName = if (${IsSystemWide}) { "CLIINST_PATH_MACHINE.txt" } else { "CLIINST_PATH_USER.txt" }
	$filePath = [IO.Path]::Combine(${env:TEMP}, ${fileName})
	if (-not (Test-Path ${filePath})) {
		$envValue = ${env:CLIINST_PATH}
		if ($null -ne ${envValue}) {
			Set-Content -Path ${filePath} -Value ${envValue} -Encoding UTF8
		}
	}

	$cliinstPath = if (Test-Path ${filePath}) { Get-Content -Path ${filePath} -Raw } else { $null }
	if ($null -ne ${cliinstPath}) {
		$cliinstPath = $cliinstPath.Trim()
	}
	if ($null -eq ${cliinstPath} -or ${cliinstPath} -eq "") {
		$cliinstPath = ${BinPath}
	} else {
		$paths = ${cliinstPath}.Split(";")
		if (${paths}.IndexOf(${BinPath}) -eq -1) {
			$paths += ${BinPath}
		}
		$paths = ${paths} | Sort-Object -Unique
		$cliinstPath = ${paths} -Join ";"
		$cliinstPath = $cliinstPath.Trim(";")
	}

	$scope = if (${IsSystemWide}) { "Machine" } else { "User" }
	[Environment]::SetEnvironmentVariable("CLIINST_PATH", ${cliinstPath}, ${scope})
	Set-Content -Path "${filePath}" -Value "${cliinstPath}" -Encoding UTF8
}

# ------------------------------------------------------------------------------
# Create shortcut for desktop application
# ------------------------------------------------------------------------------
function New-AppShortcut {
	param(
		[Parameter(Mandatory)] [string] $ProgramName,
		[Parameter(Mandatory)] [string] $TargetExe,
		[Parameter(Mandatory)] [string] $WorkingDir,
		[Parameter(Mandatory)] [string] $Destination
	)

	$shortcutPath = [IO.Path]::Combine(${Destination}, "${ProgramName}.lnk")
	Remove-Item2 "${shortcutPath}"
	$wshShell = New-Object -ComObject WScript.Shell
	$shortcut = ${wshShell}.CreateShortcut($shortcutPath)
	${shortcut}.TargetPath = ${TargetExe}
	${shortcut}.WorkingDirectory = ${WorkingDir}
	${shortcut}.Save()
}
