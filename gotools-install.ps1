################################################################################
#
#  gotools-install
#
#  Install/Update common Go tools in the bin dir of the active Go, next to `go` and `gofmt`:
#  - dlv
#  - goimports
#  - gopls
#  - govulncheck
#  - staticcheck
#  Each tool is built with the active Go, at the newest version it can build.
#  Go versions keep separate tools, so run this for each version that needs them.
#
#  Prerequisites:
#  - Go installed by go-install, using the same account or admin mode as this script
#
#  Usage:
#    gotools-install
#
#  Example:
#    gotools-install
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Application info
$GO_PROGRAM_ID = "Go"

# Shared library
. "${PSScriptRoot}\shared\install-common.ps1"

# ------------------------------------------------------------------------------
# Set environment variables of this process and return their previous values
# ------------------------------------------------------------------------------
function Set-ProcessEnvVariable {
	param(
		[Parameter(Mandatory)] [hashtable] $Variables
	)

	$previousValues = @{}
	foreach ($name in ${Variables}.Keys) {
		$previousValues[${name}] = [Environment]::GetEnvironmentVariable(${name})
		[Environment]::SetEnvironmentVariable(${name}, ${Variables}[${name}])
	}
	return ${previousValues}
}

# ------------------------------------------------------------------------------
# Get the version of the active Go, failing if it cannot be found or invoked
# ------------------------------------------------------------------------------
function Get-ActiveGoVersion {
	param(
		[Parameter(Mandatory)] [string] $GoExec
	)

	if (!(Test-Path "${GoExec}" -PathType Leaf)) {
		Write-Host "Error: Go not found at ${GoExec}. Install it with go-install."
		exit 1
	}

	# The check below reports a failed run, and go's own stderr stays visible
	try {
		$goVersionLine = & "${GoExec}" version
	} catch [System.Management.Automation.ApplicationFailedException] {
		$goVersionLine = ""
	}
	if ("${goVersionLine}" -notmatch "^go version go(\d\S*)") {
		Write-Host "Error: Go at ${GoExec} cannot be invoked. Reinstall it with go-install."
		exit 1
	}

	$version = ${Matches}[1]
	Write-Host "> Active Go:    ${version}"
	return ${version}
}

# ------------------------------------------------------------------------------
# Get the newest release of a module, equal or greater than floor version
# ------------------------------------------------------------------------------
function Get-ToolVersionFromGoProxy {
	param(
		[Parameter(Mandatory)] [string] $Module,
		[Parameter(Mandatory)] [string] $FloorVersion,
		[Parameter(Mandatory)] [string] $GoVersion
	)

	$moduleUri = "https://proxy.golang.org/${Module}/@v"
	$versions = (Invoke-WebRequest -UseBasicParsing "${moduleUri}/list").Content -Split "`n" | Where-Object { "${_}" -ne "" -and "${_}" -notmatch "-" }
	foreach ($version in (${versions} | Sort-Object { Get-VersionSortKey -Version "${_}" } -Descending)) {
		# Releases run newest first, so the rest are below the floor too
		if (!(Test-VersionAtLeast -Version "${version}" -Anchor "${FloorVersion}")) {
			return $null
		}
		$goMod = (Invoke-WebRequest -UseBasicParsing "${moduleUri}/${version}.mod").Content
		# A module without a go line has no minimum, and an empty version is below any Go
		$requiredGo = if (${goMod} -match "(?m)^go (\S+)") { ${Matches}[1] } else { "" }
		if (Test-VersionAtMost -Version "${requiredGo}" -Anchor "${GoVersion}") {
			return ${version}
		}
	}
	return $null
}

# ------------------------------------------------------------------------------
# Build a tool from its module with the active Go, and install it in GOBIN
# ------------------------------------------------------------------------------
function Install-GoTool {
	param(
		[Parameter(Mandatory)] [hashtable] $ActiveGo,
		[Parameter(Mandatory)] [string] $Module,
		[Parameter(Mandatory)] [string] $Package,
		[Parameter(Mandatory)] [string] $FloorVersion
	)

	$toolVersion = Get-ToolVersionFromGoProxy -Module "${Module}" -FloorVersion "${FloorVersion}" -GoVersion "$($ActiveGo.Version)"
	if ($null -eq ${toolVersion}) {
		Write-Host "> Skip Item:    ${Package} must be ${FloorVersion} or higher"
		return
	}

	Write-Host "> Build Item:   ${Package}@${toolVersion} -> ${env:GOBIN}"
	& "$($ActiveGo.Exec)" install "${Package}@${toolVersion}"
	if (${LASTEXITCODE} -ne 0) {
		Write-Host "Error: Could not install ${Package}. Fix the problem go reported above, then run gotools-install again."
		exit 1
	}
}

# ------------------------------------------------------------------------------
# Remove the module cache in GOMODCACHE
# ------------------------------------------------------------------------------
function Remove-GoModuleCache {
	param(
		[Parameter(Mandatory)] [string] $GoExec
	)

	if (!(Test-Path "${env:GOMODCACHE}")) {
		return
	}

	Write-Host "> Remove Item:  ${env:GOMODCACHE}"
	& "${GoExec}" clean -modcache
	if (${LASTEXITCODE} -ne 0) {
		Write-Warning "Remove-GoModuleCache: go clean failed with exit code ${LASTEXITCODE}"
	}
}

# Tool versions follow the active Go, so a version argument has no meaning here
if (${args}.Count -ne 0) {
	Write-Host "Error: gotools-install takes no arguments. Use go-install to choose the Go version."
	exit 1
}

# Prepare environment
$InstallEnv = Initialize-InstallEnv -ProgramId "${GO_PROGRAM_ID}" -Version "active-release"
$GO_EXEC = "$($InstallEnv.ActiveTarget)\bin\go.exe"
$GOTOOLS_BUILD_ROOT = "$($InstallEnv.TempRoot)\gotools_$([IO.Path]::GetRandomFileName())"
$PreviousEnv = Set-ProcessEnvVariable -Variables @{
	CGO_ENABLED = "0"
	GOBIN = "$($InstallEnv.ActiveTarget)\bin"
	GOCACHE = "${GOTOOLS_BUILD_ROOT}\cache"
	GOFLAGS = "-modcacherw"
	GOMODCACHE = "${GOTOOLS_BUILD_ROOT}\mod"
	GOROOT = "$($InstallEnv.ActiveTarget)"
	GOTOOLCHAIN = "local"
}

try {
	$ActiveGo = @{
		Exec = ${GO_EXEC}
		Version = Get-ActiveGoVersion -GoExec "${GO_EXEC}"
	}
	New-Directory2 -Path "${GOTOOLS_BUILD_ROOT}"

	# Build and install tools, each with its floor version
	Install-GoTool -ActiveGo ${ActiveGo} -Module "golang.org/x/tools" -Package "golang.org/x/tools/cmd/goimports" -FloorVersion "v0.1.0"
	Install-GoTool -ActiveGo ${ActiveGo} -Module "golang.org/x/tools/gopls" -Package "golang.org/x/tools/gopls" -FloorVersion "v0.16.0"
	Install-GoTool -ActiveGo ${ActiveGo} -Module "golang.org/x/vuln" -Package "golang.org/x/vuln/cmd/govulncheck" -FloorVersion "v1.1.3"
	Install-GoTool -ActiveGo ${ActiveGo} -Module "github.com/go-delve/delve" -Package "github.com/go-delve/delve/cmd/dlv" -FloorVersion "v0.1.0"
	Install-GoTool -ActiveGo ${ActiveGo} -Module "honnef.co/go/tools" -Package "honnef.co/go/tools/cmd/staticcheck" -FloorVersion "v0.1.0"
} finally {
	Remove-GoModuleCache -GoExec "${GO_EXEC}"
	Set-ProcessEnvVariable -Variables ${PreviousEnv} | Out-Null
	Remove-Item2 -Path "${GOTOOLS_BUILD_ROOT}"
}

# Finalize install
Finalize-Install
