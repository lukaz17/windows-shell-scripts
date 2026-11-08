# Windows Shell Scripts

Collection of cmd and ps1 for convenience.

## How to use

The scripts can be run from any folder, but must stay in this repository, because they load `shared` and the bundled 7-Zip from it.

Each script is a `.ps1` file with a `.cmd` wrapper of the same name, so it runs by name in both PowerShell and Command Prompt. The comment at the top of each `.ps1` file describes its usage.

The scripts run on Windows PowerShell 5.1, which comes with Windows 10 and 11. Downloads use `curl.exe` if available and PowerShell otherwise. Archives are extracted with `7z` from your `PATH` if available and the bundled 7-Zip otherwise. The only tool you may need to add is `git`, to check out and update this repository:

```
winget install --id Git.Git --exact --source winget
```

Windows 10 and 11 block PowerShell scripts by default, and that blocks the `.cmd` wrappers too. Allow scripts for your account:

```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Check out this repository in the folder where you want to keep it, then run `cliinst-install` once to add it to your `PATH`:

```
git clone https://github.com/lukaz17/windows-shell-scripts.git D:\Bin\CliInst
D:\Bin\CliInst\cliinst-install
```

Open a new terminal to run the scripts by name. To update them later, run `cliinst-update`.

### Installing programs

Run an installer by name for the latest version, or pass a version, with or without the leading `v`:

```
go-install
go-install 1.27.1
```

These installers cannot look up the latest version, so the version is required: `cpuz-install`, `ffmpeg-install`, `firefox-install`, `hwinfo-install`, `hwmonitor-install`, `mariadb-install`, `php-install`, `postgresql-install`, `thunderbird-install`, and `unikey-install`.

Each version stays in its own `<Program>-v<version>` folder, and `active-release` next to it is the version in use. Run an installer with another version to switch to it. A version already on disk is not downloaded again. `mariadb-install`, `nodejs-install`, and `postgresql-install` keep one `active-release-v<major>` per major version, and `php-install` keeps one `active-release-v<minor>`, such as `active-release-v8.4`, per minor version.

`mariadb-install`, `nodejs-install`, `php-install`, and `postgresql-install` add nothing to `PATH` unless you pass `--default`, which makes that major version the default, or that minor version for `php-install`. `active-release` then points to its `active-release-v<major>` or `active-release-v<minor>`, so later updates of that version carry over, and `active-release\bin` goes on `PATH`, or `active-release` itself for `nodejs-install` and `php-install`. Pass `--default` with another version to switch:

```
postgresql-install 17.7 --default
```

`nodejs-install --default` also sets `npm_config_cache` to `.Nodejs\cache` and `npm_config_prefix` to `.Nodejs` in the `CLIINST_USR_PROFILE` folder, and adds `.Nodejs` to `CLIINST_USR_PATH`, so the npm cache and global packages are shared by all major versions and stay in your account's folder, even for a systemwide install.

`php-install` takes a minor version, such as `8.4`, for its newest build, or a full version, such as `8.4.27`. It installs the Non Thread Safe build, which runs `php` from the command line and `php-cgi` as a FastCGI server, as Windows has no `php-fpm`. Each minor version keeps its `php.ini` in `config-v<minor>` next to `active-release-v<minor>`, created from `php.ini-production` the first time, and every version of it gets a hard link to that file as its own `php.ini`, so your settings carry over to later updates. Most editors keep the link when saving, but one that saves by replacing the file breaks it. PHP needs the Microsoft Visual C++ Redistributable, which Windows does not include; you can install it with the [Visual C++ Redistributable Runtimes All-in-One](https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/) package.

Installers support AMD64 and ARM64, and stop with `Unsupported architecture` if a program has no build for your system.

### Install scope

Run a script by name to install for your account only. This installs into `%USERPROFILE%\.local\share\<Program>`, and adds command-line programs to `CLIINST_USR_PATH`, which is on your `PATH`.

To install systemwide, run the script from an elevated terminal, opened with Run as administrator. This installs into `%ProgramFiles%\<Program>`, and adds command-line programs to `CLIINST_PATH`, which is on the system `PATH`.

Every installer also creates `%USERPROFILE%\.local\bin` and adds it to `CLIINST_USR_PATH`, for both install scopes.

Open a new terminal to use a newly installed command. Desktop programs also get shortcuts on the Desktop and in the `Apps` folder of the Start Menu, for your account or for all users.

Some installers also set environment variables. The command decides where they go:

| Command | Installs | Environment variables go to |
|---------|----------|-----------------------------|
| `go-install` | For your account | Your account |
| `go-install` in an elevated terminal | Systemwide | System |
| `sudo go-install` | Systemwide | System |

Variables for data that belongs to an account, such as `GOPATH`, `RUSTUP_HOME`, and `CARGO_HOME`, always go to the account running the script, and the installer creates their folders.

To run the scripts by name from any administrator account, run `D:\Bin\CliInst\cliinst-install` once from an elevated terminal. This adds the repository to the system `PATH`. Scripts in this folder run as administrator, so keep it writable by trusted users only.

### Using sudo

`sudo` runs a command as administrator:

```
sudo go-install 1.27.1
```

In an elevated terminal, it runs the command in place. In a normal terminal, it shows the UAC prompt and runs the command in a new window. That window closes when the command ends, so use an elevated terminal if you need the output.

### Settings

`cliinst-install` stores these settings as environment variables, for your account or, from an elevated terminal, for the system. Omit a parameter to keep its setting, or pass `""` to remove it.

```
cliinst-install -UsrLocalShare "D:\Bin" -Tmp "E:\Workspace-CliInst"
```

| Environment variable | Parameter | Default | Purpose |
|----------------------|-----------|---------|---------|
| `CLIINST_USR_LOCAL_SHARE` | `-UsrLocalShare` | Depends on the install scope | Folder that programs install into, for both install scopes |
| `CLIINST_TEMP` | `-Tmp` | `%TEMP%` | Folder for downloads and extraction |
| `CLIINST_USR_PROFILE` | None, set it yourself | `%USERPROFILE%\.local` | Folder for data that belongs to an account, such as `GOPATH` |

### Repairing environment variables

After you delete a program's folder, its paths stay in the environment variables. `cliinst-repair` lists the variables set by the installers, and the entries of `CLIINST_PATH` and `CLIINST_USR_PATH`, that point to a path no longer on disk. An `active-release` junction to a deleted version counts as missing. Pass `-Apply` to remove what is listed:

```
cliinst-repair
cliinst-repair -Apply
```

Run `cliinst-repair -Apply` from an elevated terminal to repair system variables as well as those of your account. A path that cannot be checked, such as one on a drive that is not mounted, stays in place with a warning. The settings above are not repaired.

If a variable is removed for a program you still use, run its installer again to restore it. Open a new terminal to see the changes.

## License

Windows Shell Scripts is licensed under the MIT license. See LICENSE file for more details.

### 7-Zip

The 7-Zip 25.01 binaries in `7z-amd64` and `7z-arm64` are third-party software and are not covered by the MIT license. See the `License.txt` file in each folder for their license. Their [source code](https://www.7-zip.org/a/7z2501-src.7z) is available from the 7-Zip website.
