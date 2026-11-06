################################################################################
#
#  install-source
#  Libraries to support *-install scripts
#
#  MIT License.
#  Copyright (C) 2025 Nguyen Nhat Tung.
#
################################################################################

Set-StrictMode -Version Latest

# ------------------------------------------------------------------------------
# Known program sources.
# ------------------------------------------------------------------------------
$Script:ProgramSourceTable = @{
	"7-Zip" = @{
		GithubOwner      = "ip7z"
		GithubRepo       = "7zip"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/ip7z/7zip/releases/download/${version}/7z$(${version}.Replace('.',''))-x64.exe" }
		Arm64Uri         = { param($version) "https://github.com/ip7z/7zip/releases/download/${version}/7z$(${version}.Replace('.',''))-arm64.exe" }
	}
	"Bifrost HTTP" = @{
		GithubOwner      = "maximhq"
		GithubRepo       = "bifrost"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://downloads.getmaxim.ai/bifrost/v${version}/windows/amd64/bifrost-http.exe" }
		Arm64Uri         = { param($version) "" }
	}
	"Bun" = @{
		GithubOwner      = "oven-sh"
		GithubRepo       = "bun"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-windows-x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-windows-aarch64.zip" }
	}
	"Circom" = @{
		GithubOwner      = "iden3"
		GithubRepo       = "circom"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/iden3/circom/releases/download/v${version}/circom-windows-amd64.exe" }
		Arm64Uri         = { param($version) "" }
	}
	"CPU-Z" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://download.cpuid.com/cpu-z/cpu-z_${version}-en.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"FanControl" = @{
		GithubOwner      = "Rem0o"
		GithubRepo       = "FanControl.Releases"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) Get-FanControlUri -Version "${version}" }
		Arm64Uri         = { param($version) Get-FanControlUri -Version "${version}" }
	}
	"FFmpeg" = @{
		GithubOwner      = "GyanD"
		GithubRepo       = "codexffmpeg"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/GyanD/codexffmpeg/releases/download/${version}/ffmpeg-${version}-full_build.7z" }
		Arm64Uri         = { param($version) "" }
	}
	"Foundry" = @{
		GithubOwner      = "foundry-rs"
		GithubRepo       = "foundry"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/foundry-rs/foundry/releases/download/v${version}/foundry_v${version}_win32_amd64.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"Gitea" = @{
		GithubOwner      = "go-gitea"
		GithubRepo       = "gitea"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-${version}-windows-4.0-amd64.exe.xz" }
		Arm64Uri         = { param($version) "https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-${version}-windows-4.0-arm64.exe.xz" }
	}
	"Go" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://go.dev/dl/go${version}.windows-amd64.zip" }
		Arm64Uri         = { param($version) "https://go.dev/dl/go${version}.windows-arm64.zip" }
	}
	"GolangCI Lint" = @{
		GithubOwner      = "golangci"
		GithubRepo       = "golangci-lint"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-windows-amd64.zip" }
		Arm64Uri         = { param($version) "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-windows-arm64.zip" }
	}
	"Hugo" = @{
		GithubOwner      = "gohugoio"
		GithubRepo       = "hugo"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_extended_withdeploy_${version}_windows-amd64.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"HWiNFO" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = "hwinfo"
		Amd64Uri         = { param($version) "https://sourceforge.net/projects/hwinfo/files/Windows_Portable/hwi_$(${version}.Replace('.','')).zip/download" }
		Arm64Uri         = { param($version) "" }
	}
	"HWMonitor" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://download.cpuid.com/hwmonitor/hwmonitor_${version}.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"Jellyfin" = @{
		GithubOwner      = "jellyfin"
		GithubRepo       = "jellyfin"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://repo.jellyfin.org/files/server/windows/stable/v${version}/amd64/jellyfin_${version}-amd64.zip" }
		Arm64Uri         = { param($version) "https://repo.jellyfin.org/files/server/windows/stable/v${version}/arm64/jellyfin_${version}-arm64.zip" }
	}
	"Kilo Code" = @{
		GithubOwner      = "Kilo-Org"
		GithubRepo       = "kilocode"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/Kilo-Org/kilocode/releases/download/v${version}/kilo-windows-x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/Kilo-Org/kilocode/releases/download/v${version}/kilo-windows-arm64.zip" }
	}
	"MariaDB" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) Get-MariaDbUri -Version "${version}" }
		Arm64Uri         = { param($version) "" }
	}
	"Mozilla Firefox" = @{
		GithubOwner      = "mozilla-firefox"
		GithubRepo       = "firefox"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://ftp.mozilla.org/pub/firefox/releases/${version}/win64/en-US/Firefox%20Setup%20${version}.exe" }
		Arm64Uri         = { param($version) "https://ftp.mozilla.org/pub/firefox/releases/${version}/win64-aarch64/en-US/Firefox%20Setup%20${version}.exe" }
	}
	"Mozilla Thunderbird" = @{
		GithubOwner      = "thunderbird"
		GithubRepo       = "thunderbird-desktop"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://ftp.mozilla.org/pub/thunderbird/releases/${version}/win64/en-US/Thunderbird%20Setup%20${version}.exe" }
		Arm64Uri         = { param($version) "" }
	}
	"Nodejs" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://nodejs.org/dist/v${version}/node-v${version}-win-x64.zip" }
		Arm64Uri         = {
			param($version)
			# Windows ARM64 builds start at 19.9.0
			if (Test-VersionAtLeast -Version "${version}" -Anchor "19.9.0") {
				"https://nodejs.org/dist/v${version}/node-v${version}-win-arm64.zip"
			} else {
				""
			}
		}
	}
	"Notepad++" = @{
		GithubOwner      = "notepad-plus-plus"
		GithubRepo       = "notepad-plus-plus"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v${version}/npp.${version}.portable.x64.7z" }
		Arm64Uri         = { param($version) "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v${version}/npp.${version}.portable.arm64.zip" }
	}
	"Ollama" = @{
		GithubOwner      = "ollama"
		GithubRepo       = "ollama"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/ollama/ollama/releases/download/v${version}/ollama-windows-amd64.zip" }
		Arm64Uri         = { param($version) "https://github.com/ollama/ollama/releases/download/v${version}/ollama-windows-amd64.zip" }
	}
	"OpenCode" = @{
		GithubOwner      = "anomalyco"
		GithubRepo       = "opencode"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-windows-x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-windows-arm64.zip" }
	}
	"pnpm" = @{
		GithubOwner      = "pnpm"
		GithubRepo       = "pnpm"
		SourceForgeProj  = ""
		Amd64Uri         = {
			param($version)
			if (Test-VersionAtLeast -Version "${version}" -Anchor "11") {
				"https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-win32-x64.zip"
			} else {
				"https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-win-x64.exe"
			}
		}
		Arm64Uri         = {
			param($version)
			if (Test-VersionAtLeast -Version "${version}" -Anchor "11") {
				"https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-win32-arm64.zip"
			} else {
				"https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-win-arm64.exe"
			}
		}
	}
	"PostgreSQL" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://get.enterprisedb.com/postgresql/postgresql-${version}-1-windows-x64-binaries.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"Qdrant" = @{
		GithubOwner      = "qdrant"
		GithubRepo       = "qdrant"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-x86_64-pc-windows-msvc.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"rustup" = @{
		GithubOwner      = "rust-lang"
		GithubRepo       = "rustup"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://static.rust-lang.org/rustup/archive/${version}/x86_64-pc-windows-msvc/rustup-init.exe" }
		Arm64Uri         = { param($version) "https://static.rust-lang.org/rustup/archive/${version}/aarch64-pc-windows-msvc/rustup-init.exe" }
	}
	"Sass" = @{
		GithubOwner      = "sass"
		GithubRepo       = "dart-sass"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/sass/dart-sass/releases/download/${version}/dart-sass-${version}-windows-x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/sass/dart-sass/releases/download/${version}/dart-sass-${version}-windows-arm64.zip" }
	}
	"ShareX" = @{
		GithubOwner      = "ShareX"
		GithubRepo       = "ShareX"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/ShareX/ShareX/releases/download/v${version}/ShareX-${version}-portable-x64.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"Tabby" = @{
		GithubOwner      = "Eugeny"
		GithubRepo       = "tabby"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-portable-x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-portable-arm64.zip" }
	}
	"TFunifiler" = @{
		GithubOwner      = "tforceaio"
		GithubRepo       = "tf-unifiler"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/tforceaio/tf-unifiler/releases/download/v${version}/unifiler-v${version}-windows-amd64.zip" }
		Arm64Uri         = { param($version) "https://github.com/tforceaio/tf-unifiler/releases/download/v${version}/unifiler-v${version}-windows-arm64.zip" }
	}
	"Unikey" = @{
		GithubOwner      = ""
		GithubRepo       = ""
		SourceForgeProj  = "unikey"
		Amd64Uri         = { param($version) "" }
		Arm64Uri         = { param($version) "" }
	}
	"uv" = @{
		GithubOwner      = "astral-sh"
		GithubRepo       = "uv"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/astral-sh/uv/releases/download/${version}/uv-x86_64-pc-windows-msvc.zip" }
		Arm64Uri         = { param($version) "https://github.com/astral-sh/uv/releases/download/${version}/uv-aarch64-pc-windows-msvc.zip" }
	}
	"w64devkit" = @{
		GithubOwner      = "skeeto"
		GithubRepo       = "w64devkit"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/skeeto/w64devkit/releases/download/v${version}/w64devkit-x64-${version}.7z.exe" }
		Arm64Uri         = { param($version) "" }
	}
	"WezTerm" = @{
		GithubOwner      = "wezterm"
		GithubRepo       = "wezterm"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/wezterm/wezterm/releases/download/${version}/WezTerm-windows-${version}.zip" }
		Arm64Uri         = { param($version) "" }
	}
	"Windows Terminal" = @{
		GithubOwner      = "microsoft"
		GithubRepo       = "terminal"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/microsoft/terminal/releases/download/v${version}/Microsoft.WindowsTerminal_${version}_x64.zip" }
		Arm64Uri         = { param($version) "https://github.com/microsoft/terminal/releases/download/v${version}/Microsoft.WindowsTerminal_${version}_arm64.zip" }
	}
	"yt-dlp" = @{
		GithubOwner      = "yt-dlp"
		GithubRepo       = "yt-dlp"
		SourceForgeProj  = ""
		Amd64Uri         = { param($version) "https://github.com/yt-dlp/yt-dlp/releases/download/${version}/yt-dlp.exe" }
		Arm64Uri         = { param($version) "https://github.com/yt-dlp/yt-dlp/releases/download/${version}/yt-dlp_arm64.exe" }
	}
}

$Script:ProgramUriTable = @{
	"Unikey" = @{
		"4.6-rc2" = @{
			Amd64Uri = "https://sourceforge.net/projects/unikey/files/unikey-win/4.6%20RC2/unikey46RC2-230919-win64.zip/download"
			Arm64Uri = ""
		}
		"4.6-rc1" = @{
			Amd64Uri = "https://sourceforge.net/projects/unikey/files/unikey-win/4.6%20RC1/unikey46RC1-230912-win64.zip/download"
			Arm64Uri = ""
		}
	}
}

# ------------------------------------------------------------------------------
# Return FanControl binaries download URL.
# ------------------------------------------------------------------------------
function Get-FanControlUri {
	param(
		[Parameter(Mandatory)] [string] $Version
	)

	if (Test-VersionAtLeast -Version "${Version}" -Anchor "248") {
		$asset = "FanControl_${Version}_net_10_0.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "183") {
		$asset = "FanControl_${Version}_net_8_0.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "174") {
		$asset = "FanControl_net_8_0.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "137") {
		$asset = "FanControl_net_7_0.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "134") {
		$asset = "FanControl_net6.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "131") {
		$asset = "FanControlnet60.zip"
	} elseif (Test-VersionAtLeast -Version "${Version}" -Anchor "128") {
		$asset = "FanControl-net6.0.zip"
	} else {
		$asset = "FanControl.zip"
	}

	return "https://github.com/Rem0o/FanControl.Releases/releases/download/V${Version}/${asset}"
}

# ------------------------------------------------------------------------------
# Return MariaDB binaries download URL.
# ------------------------------------------------------------------------------
function Get-MariaDbUri {
	param(
		[Parameter(Mandatory)] [string] $Version
	)

	# The URL follows a pattern, but only the API tells whether a release has a Windows ZIP, so it must not be built from the version
	$apiResponse = Invoke-WebRequest -UseBasicParsing "https://downloads.mariadb.org/rest-api/mariadb/${Version}" | ConvertFrom-Json
	$matchedFile =$($apiResponse.release_data.${Version}.files) | Where-Object {
		$_.package_type -eq "ZIP file" -and
		$_.os -eq "Windows" -and
		$_.cpu -eq "x86_64" -and
		$_.file_name -notmatch "debugsymbols"
	} | Select-Object -First 1
	if ($null -eq ${matchedFile}) {
		Write-Output "Get-MariaDbUri: No matching file found for version ${Version}"
		exit 1
	}

	return $($matchedFile.file_download_url)
}

# ------------------------------------------------------------------------------
# Return source info for a Program ID.
# ------------------------------------------------------------------------------
function Get-InstallSource {
	param(
		[Parameter(Mandatory)] [string] $ProgramId
	)

	$entry = $Script:ProgramSourceTable[${ProgramId}]
	if ($null -eq ${entry}) {
		Write-Output "Get-InstallSource: Unknown Program ID ${ProgramId}"
		exit 1
	}

	return @{
		GithubOwner = $($entry.GithubOwner)
		GithubRepo  = $($entry.GithubRepo)
	}
}

# ------------------------------------------------------------------------------
# Return the download URI for AMD64 for a Program ID.
# ------------------------------------------------------------------------------
function Get-Amd64Uri {
	param(
		[Parameter(Mandatory)] [string] $ProgramId,
		[Parameter(Mandatory)] [string] $InstallVersion
	)

	$uriEntry = $Script:ProgramUriTable[$ProgramId]
	if ($null -ne $uriEntry) {
		$versionEntry = $uriEntry[$InstallVersion]
		if ($null -ne $versionEntry -and ![string]::IsNullOrEmpty($versionEntry.Amd64Uri)) {
			return $versionEntry.Amd64Uri
		}
	}

	$entry = $Script:ProgramSourceTable[${ProgramId}]
	if ($null -eq ${entry}) {
		Write-Output "Get-Amd64Uri: Unknown Program ID ${ProgramId}"
		exit 1
	}
	if ($null -eq $($entry.Amd64Uri)) {
		Write-Output "Get-Amd64Uri: No AMD64 URI configured for ${ProgramId}"
		exit 1
	}

	return & $entry.Amd64Uri ${InstallVersion}
}

# ------------------------------------------------------------------------------
# Return the download URI for ARM64 for a Program ID.
# ------------------------------------------------------------------------------
function Get-Arm64Uri {
	param(
		[Parameter(Mandatory)] [string] $ProgramId,
		[Parameter(Mandatory)] [string] $InstallVersion
	)

	$uriEntry = $Script:ProgramUriTable[$ProgramId]
	if ($null -ne $uriEntry) {
		$versionEntry = $uriEntry[$InstallVersion]
		if ($null -ne $versionEntry -and ![string]::IsNullOrEmpty($versionEntry.Arm64Uri)) {
			return $versionEntry.Arm64Uri
		}
	}

	$entry = $Script:ProgramSourceTable[${ProgramId}]
	if ($null -eq ${entry}) {
		Write-Output "Get-Arm64Uri: Unknown Program ID ${ProgramId}"
		exit 1
	}
	if ($null -eq $($entry.Arm64Uri)) {
		Write-Output "Get-Arm64Uri: No ARM64 URI configured for ${ProgramId}"
		exit 1
	}

	return & $entry.Arm64Uri ${InstallVersion}
}
