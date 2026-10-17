# Project Context

Part of the project memory layer: human-readable memory of what this project is and what has been confirmed.

The reading and writing rules for this file and the rest of `.attunic/` are defined in [attunic-protocol.md](../.agents/attunic-protocol.md).

## Abstract

A newcomer should be able to tell what the software does without knowing what it is built with. One paragraph that describes the domain, not the technology, in simple terms:
<!-- Project-specific / Abstract -->

Collection of installers and utility scripts for Windows, written in PowerShell.

- The installer scripts automate the process of querying the new version, downloading and extracting open-source software.
- The utility scripts automate the common repetitive tasks with configurable parameters.

## Technical Specifications

A brief overview of the ingredients used for developing this project. These are things developers should know when developing the project.

Typical ingredients include, but are not limited to: primary language, frameworks, architecture styles, environment prerequisites, libraries, test runners, tools, databases...

<!-- Project-specific / Technical Specifications -->

- Language: PowerShell.
- Framework: None.
- Build system: None.
- Test runner: None.
- Linter: None.

## Layout

Layout of this project; [project-structure.md](../.agents/project-structure.md) holds the language's standard map, kept for reference.

List of important folders, files and their roles in the project:

- They visualize the actual file system where source files live.
- If a top-level file/folder is missing from the list, prompt the user to update it.
<!-- Project-specific / Layout -->
- Top-level *.ps1, and all *.cmd are exception, it is not necessary to include all of them in the Layout.


```
├── .agents/                  # project AI agent instructions (attunic protocol, coding-conventions, development-guideline, pull-request-guideline)
├── .attunic/                 # project AI agent memory (context, memory, wip)
├── 7z-amd64/                 # bundled 7-Zip CLI for AMD64
│   ├── 7z.dll
│   └── 7z.exe
├── 7z-arm64/                 # bundled 7-Zip CLI for ARM64
│   ├── 7z.dll
│   └── 7z.exe
├── shared/                   # support libraries dot-sourced by top-level scripts
│   ├── install-common.ps1    # installer script shared functions: safe file ops, install env initialization, extraction, shortcuts, PATH, finalization
│   └── install-source.ps1    # installer script download sources and version lookup
├── .copier-answers.yml       # project Copier answers
├── .editorconfig             # editor formatting rules
├── .gitignore                # git ignore patterns
├── README.md                 # project README
├── cliinst-install.ps1       # configure initial CliInst settings (env vars, CLIINST_PATH)
├── cliinst-update.ps1        # update this repository via git pull
├── registry-export.ps1       # export a Registry key as a PowerShell script
├── sudo.ps1                  # run a command with elevated permissions
├── *.ps1                     # installer scripts
```

## Layer Dependencies

List of layers and their relationships:

- Declare the innermost layer first.
- A layer may depend on itself and on any layer declared before it, and on nothing declared after it.
- If a layer appears in the table below, the dependency graph must be enforced.

| Layer | Path | Depends on | Must never contain |
|-------|------|------------|--------------------|
<!-- Project-specific / Layer Dependencies -->

### Deliberate Exceptions

List of documented exceptions that cannot follow the architecture rules above:

- Any place the rules above are knowingly broken, with the reason and the condition for fixing it.
- An undocumented exception is a defect; a documented one is a decision.

| What | Why | Revisit-if |
|------|-----|------------|
<!-- Project-specific / Deliberate Exceptions -->

## Supporting Tools

All the supporting tools declared here are opinionated for the sake of consistent results across development environments.

List each required tool/library under its own heading, followed by the commands for each use case.
Common use cases include: Build, Test, Lint, Format, Install, ...

<!-- Project-specific / Supporting Tools -->

There is no build, test, lint, or format pipeline; PowerShell scripts are executed directly from the repository root. Format consistency is governed by `.editorconfig` (tabs for this project).

## Confirmed Facts

Facts about the project which have been confirmed; they outrank anything derived or guessed.

| Fact | Reason |
|------|--------|
<!-- Project-specific / Confirmed Facts -->

## Project-specific

<!-- Project-specific -->
