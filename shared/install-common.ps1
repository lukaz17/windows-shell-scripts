################################################################################
#
#  install-common
#  Libraries to support *-install scripts
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

Set-PSDebug -Trace 0

# ------------------------------------------------------------------------------
# Create a directory safely
# ------------------------------------------------------------------------------
function New-Directory2 {
	param(
		[Parameter(Mandatory)] [string] $Path
	)

	if (!(Test-Path "${Path}" -PathType Container)) {
		Write-Host "> Create Dir:   ${Path}"
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
		Write-Host "> Remove Item:  ${Path}"
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

	Write-Host "> Copy Item:    ${From} -> ${To}"
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

	Write-Host "> Move Item:    ${From} -> ${To}"
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

	Write-Host "> Link Item:    ${From} -> ${To}"
	New-Item -ItemType "${Type}" -Target "${From}" -Path "${To}"
	Write-Host ""
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
		Write-Host "> Download Uri: ${Uri} -> ${OutFile}"
		& "$($curl.Source)" -fSL "${Uri}" -o "${OutFile}"
		if (${LASTEXITCODE} -ne 0) {
			Write-Output "curl failed with exit code ${LASTEXITCODE}"
			exit 1
		}
		return
	}

	$ProgressPreference = "SilentlyContinue"
	Write-Host "> Request Uri:  ${Uri} -> ${OutFile}"
	Invoke-WebRequest -UseBasicParsing -Uri "${Uri}" -OutFile "${OutFile}"
	$ProgressPreference = "Continue"
}

# ------------------------------------------------------------------------------
# Normalize install version for consistency
# ------------------------------------------------------------------------------
function Normalize-InstallVersion {
	param(
		[Parameter()] [string] $Version = "",
		[Parameter()] [string] $TagPrefix = ""
	)

	if ("${Version}" -eq "") {
		Write-Output "Normalize-InstallVersion: Install version is not specified"
		exit 1
	}

	if ("${TagPrefix}" -ne "" -and ${Version}.StartsWith(${TagPrefix})) {
		$Version = ${Version}.Substring(${TagPrefix}.Length)
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
		[string] $TagPrefix = "",
		[string] $FallbackVersion = ""
	)

	if ("${FallbackVersion}" -eq "") {
		$version = (Invoke-WebRequest -UseBasicParsing "https://api.github.com/repos/${Owner}/${Repo}/releases/latest" | ConvertFrom-Json).tag_name
	} else {
		$version = ${FallbackVersion}
	}

	Write-Host "> Latest Version:  ${version}"
	return Normalize-InstallVersion "${version}" -TagPrefix "${TagPrefix}"
}

# ------------------------------------------------------------------------------
# Initialize environment for the install and pre-populate root dirs
# ------------------------------------------------------------------------------
function Initialize-InstallEnv {
	param(
		[Parameter(Mandatory)] [string] $ProgramId,
		[Parameter(Mandatory)] [string] $Version,
		[string] $ActiveTag,
		[switch] $IsApplication
	)

	$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	$arch = ${env:PROCESSOR_ARCHITECTURE}
	Write-Host "> Init InstEnv: ${ProgramId} v${Version} ${arch}"

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
	$userProfileData = [IO.Path]::Combine(${env:USERPROFILE}, ".local")

	if ("${env:CLIINST_USR_LOCAL_SHARE}" -ne "") {
		$installRoot = [IO.Path]::Combine(${env:CLIINST_USR_LOCAL_SHARE}, ${ProgramId})
	}
	if ("${env:CLIINST_USR_PROFILE}" -ne "") {
		$userProfileData = "${env:CLIINST_USR_PROFILE}"
	}
	if ("${env:CLIINST_TEMP}" -ne "") {
		$tempRoot = "${env:CLIINST_TEMP}"
	}

	$installTarget = [IO.Path]::Combine(${installRoot}, "${ProgramId}-v${Version}")
	$activeSuffix = if ("${ActiveTag}" -ne "") { "-${ActiveTag}" } else { "" }
	$activeTarget  = [IO.Path]::Combine(${installRoot}, "active-release${activeSuffix}")
	$tempTarget  = [IO.Path]::Combine(${tempRoot}, "${ProgramId}-v${Version}")

	New-Directory2 "${installRoot}"
	New-Directory2 "${tempRoot}"
	New-Directory2 "${userProfileData}"
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
		UserProfileData = ${userProfileData}
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

	$7zSys = Get-Command "7z" -ErrorAction SilentlyContinue
	if ($7zSys) {
		$7zCli = "$($7zSys.Source)"
	} else {
		$arch = ${env:PROCESSOR_ARCHITECTURE}
		if ("${arch}" -eq "AMD64") {
			$7zCli = [IO.Path]::Combine(${ScriptRoot}, "7z-amd64", "7z.exe")
		} elseif ("${arch}" -eq "ARM64") {
			$7zCli = [IO.Path]::Combine(${ScriptRoot}, "7z-arm64", "7z.exe")
		} else {
			Write-Output "Unsupported architecture: ${arch}"
			exit 1
		}
	}

	New-Directory2 "${DestinationPath}"
	Write-Host "> Exract Arch:  ${ArchivePath} -> ${DestinationPath}"
	& "${7zCli}" x "${ArchivePath}" "-o${DestinationPath}"
}

# ------------------------------------------------------------------------------
# Set environment variable
# ------------------------------------------------------------------------------
function Set-EnvVariable {
	param(
		[Parameter(Mandatory)] [string] $Name,
		[Parameter(Mandatory)] [string] $Value,
		[Parameter()] [bool] $IsSystemWide = $false
	)

	$scope = if (${IsSystemWide}) { "Machine" } else { "User" }
	Write-Host "> Set EnvVar:   ${Name}"
	[Environment]::SetEnvironmentVariable("${Name}", "${Value}", ${scope})
}

# ------------------------------------------------------------------------------
# Remove environment variable
# ------------------------------------------------------------------------------
function Remove-EnvVariable {
	param(
		[Parameter(Mandatory)] [string] $Name,
		[Parameter()] [bool] $IsSystemWide = $false
	)

	$scope = if (${IsSystemWide}) { "Machine" } else { "User" }
	Write-Host "> Rem EnvVar:   ${Name}"
	[Environment]::SetEnvironmentVariable("${Name}", $null, ${scope})
}

# ------------------------------------------------------------------------------
# Prepend %CLIINST_PATH% (Machine) or %CLIINST_USR_PATH% (User) to PATH.
# Uses the registry, as [Environment] would expand PATH and write it as REG_SZ.
# ------------------------------------------------------------------------------
function Install-CliinstPath {
	param(
		[Parameter()] [bool] $IsSystemWide = $false
	)

	$envTag = if (${IsSystemWide}) { "%CLIINST_PATH%" } else { "%CLIINST_USR_PATH%" }
	$regPath = if (${IsSystemWide}) { "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" } else { "HKCU:\Environment" }
	$currentPath = (Get-Item -Path "${regPath}").GetValue("Path", "", "DoNotExpandEnvironmentNames")

	$entries = ${currentPath}.Split(";")
	foreach ($entry in ${entries}) {
		if (${entry}.Trim().ToLower() -eq ${envTag}.ToLower()) {
			return
		}
	}

	$newPath = "${envTag};${currentPath}"
	Set-ItemProperty -Path "${regPath}" -Name "Path" -Value "${newPath}" -Type ExpandString
}

# ------------------------------------------------------------------------------
# Append a bin path to CLIINST_PATH (Machine) or CLIINST_USR_PATH (User).
# ------------------------------------------------------------------------------
function Update-CliinstPath {
	param(
		[Parameter(Mandatory)] [string] $BinPath,
		[Parameter()] [bool] $IsSystemWide = $false
	)

	Write-Host "> Add Path:     ${BinPath}"
	$envName = if (${IsSystemWide}) { "CLIINST_PATH" } else { "CLIINST_USR_PATH" }
	$scope = if (${IsSystemWide}) { "Machine" } else { "User" }
	$cliinstPath = [Environment]::GetEnvironmentVariable(${envName}, ${scope})
	if ("${cliinstPath}".Trim() -eq "") {
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

	Install-CliinstPath -IsSystemWide ${IsSystemWide}
	Set-EnvVariable ${envName} ${cliinstPath} ${IsSystemWide}
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
	Write-Host "> New Shortcut: ${TargetExe} -> ${shortcutPath}"
	$wshShell = New-Object -ComObject WScript.Shell
	$shortcut = ${wshShell}.CreateShortcut($shortcutPath)
	${shortcut}.TargetPath = ${TargetExe}
	${shortcut}.WorkingDirectory = ${WorkingDir}
	${shortcut}.Save()
}

# ------------------------------------------------------------------------------
# Finalize install.
# ------------------------------------------------------------------------------
function Finalize-Install {
	Write-Host "> Success."
}
