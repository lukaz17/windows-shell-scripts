# Project Structure

Here are standard project structures of languages and frameworks, kept for reference.

The file holding the layout attuned to this project is [context.md](../.attunic/context.md).

The files holding the rules for working with this project are [coding-conventions.md](coding-conventions.md) and [development-guideline.md](development-guideline.md).

## PowerShell structure

### Guideline

- Mirror the module layout the project uses (`Public/`, `Private/`, `Classes/`, `Tests/`); never add a loose top-level `.ps1` that duplicates a module function.
- Keep one function per file under `Public/`/`Private/` when the project follows it, named identically to the function.
- Keep build and packaging scripts (`build.ps1`) at the repository root, thin, and free of business logic.
<!-- Project-specific / Guideline -->

### Layout

```
├── .agents/        # shared AI agent instructions (coding conventions, PR/task checklists, project structure)
├── .github/        # GitHub-specific config (workflows, issue/PR templates)
├── .vscode/        # VS Code editor/workspace settings
├── docs/           # design and user documents
├── examples/       # examples for applications and/or public libraries
├── src/            # module source: one folder per module, each with Public/, Private/, Classes/, <Module>.psd1, <Module>.psm1
├── tests/          # Pester suites, fixtures, and test data
├── .editorconfig   # editor formatting rules
├── .gitignore      # git ignore patterns
├── AGENTS.md       # instructions for AI coding agents
├── build.ps1       # build/packaging entry script (thin, no business logic)
├── CLAUDE.md       # instructions specific for Claude coding agents
├── CONTRIBUTING.md # contribution guidelines
├── README.md       # project overview and pointing entry
<!-- Project-specific / Layout -->
```

### Layer Dependencies

Notes for declaring layers in the `Layer Dependencies` section of `.attunic/context.md`; adjust them to the project before declaring.

- Keep a public function a Humble Object: parameter binding, `ShouldProcess`, and formatting only; call into a `Classes/` type or a private function for any rule with branching.
- Keep cmdlet-shaped types (`[PSCustomObject]`, a .NET type from a module you call) out of a domain class's public surface; convert at the boundary.
- Keep module import and dependency wiring (`Import-Module`, `using module`) at the script or manifest level, never inside a function that also does the work.
- Check by hand: a public function containing branching business rules instead of delegating to `Classes/` types or `Private/` helpers is a violation.
<!-- Project-specific / Layer Dependencies -->

## Project-specific

<!-- Project-specific -->
