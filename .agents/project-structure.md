# Project Structure

Here are standard project structures of languages and frameworks, kept for reference.

The file holding the layout attuned to this project is [context.md](../.attunic/context.md).

The files holding the rules for working with this project are [coding-conventions.md](coding-conventions.md) and [development-guideline.md](development-guideline.md).

## General structure

### Layout

Entries a project commonly has at its root, whatever its languages; each layout below lists only what its language or framework adds:

```
├── .agents/            # shared AI agent instructions (coding conventions, PR/task checklists, project structure)
├── .attunic/           # project memory (context, confirmed facts, questions, work in progress)
├── .github/            # GitHub-specific config (workflows, issue/PR templates)
├── .vscode/            # VS Code editor/workspace settings
├── .copier-answers.yml # Copier answers replayed by `copier update`; never edited by hand
├── .editorconfig       # editor formatting rules
├── .gitignore          # git ignore patterns
├── AGENTS.md           # instructions for AI coding agents
├── CLAUDE.md           # points to AGENTS.md
├── CONTRIBUTING.md     # contribution guidelines
├── COPYING             # license text for GPL, LGPL, and AGPL
├── COPYING.LESSER      # LGPL additions, beside COPYING
├── LICENSE             # license text for other licenses (e.g. MIT, Apache-2.0)
├── README.md           # project overview
<!-- Project-specific / Layout -->
```

## PowerShell

### PowerShell-Guideline

- Mirror the module layout the project uses (`Public/`, `Private/`, `Classes/`, `tests/`); never add a loose top-level `.ps1` that duplicates a module function.
- Keep one function per file under `Public/`/`Private/` when the project follows it, named identically to the function.
- Keep build and packaging scripts (`build.ps1`) at the repository root, thin, and free of business logic.
<!-- Project-specific / PowerShell-Guideline -->

### PowerShell-Layout

```
├── docs/           # design and user documents
├── examples/       # examples for applications and/or public libraries
├── src/            # module source: one folder per module, each with Public/, Private/, Classes/, <Module>.psd1, <Module>.psm1
├── tests/          # test suites, fixtures, and test data
├── build.ps1       # build/packaging entry script (thin, no business logic)
<!-- Project-specific / PowerShell-Layout -->
```

### PowerShell-Layer Dependencies

Notes for declaring architecture layers in the `Layer Dependencies` section of `.attunic/context.md`; adjust them to the project before declaring.

- Keep a public function a Humble Object: parameter binding, `ShouldProcess`, and formatting only; call into a `Classes/` type or a private function for any rule with branching.
- Keep cmdlet-shaped types (`[PSCustomObject]`, a .NET type from a module you call) out of a domain class's public surface; convert at the boundary.
- Keep module import and dependency wiring (`Import-Module`, `using module`) at the script or manifest level, never inside a function that also does the work.
- Check by hand: a public function containing branching business rules instead of delegating to `Classes/` types or `Private/` helpers is a violation.
<!-- Project-specific / PowerShell-Layer Dependencies -->

## Project-specific

<!-- Project-specific / Project-specific -->
