# Coding Conventions

## General

The principles below are for all languages. They use camelCase for demonstration purposes; adapt casing to the language's style.

### Formats

- Keep file content reads top-down: high-level intent first, details descending (newspaper metaphor).
- Keep related things close: declarations near first use, callers near callees.
- Always brace control-flow bodies (if/else, for, while, do, switch, when) even for a single statement; never rely on brace-less bodies.
<!-- Project-specific / Formats -->

### Names

- Use one word per concept across the codebase; never one word for two concepts.
- Use intention-revealing names: the name says why it exists and what it does, with no mental mapping from a terse abbreviation to a concept.
- Include units in names where values carry them (e.g. `timeoutMs`, `maxBytes`).
- Function names: start with a verb, and disclose side effects (`save`, `delete`, `publish`, or `mutate`).
- Acronyms: stay consistently cased (e.g. `ID`, `URL`, `HTTP`, not `Id`, `Url`, `Http`).
- Booleans: name as predicates (`isReady`, `hasItems`, `canRetry`).
- Avoid generic names: (`data`, `manager`, `helper`, `util`, `info`, `result`) when a domain name exists.
- Avoid noise: names that differ only by noise words or loose abbreviations.
<!-- Project-specific / Names -->

### Comments

- Document every exported identifier (constants, vars, types, methods, functions) with a doc comment.
- Write comments explaining *why*, not *what*; the code already shows what it does.
- Cut articles, filler, and hedging; keep IDs, numbers, links, and warnings whole.
- Keep comments short and concise: they should be one to three lines; longer explanations belong in a doc file the comment points to, or an extracted function.
- Keep comments up to date with the code: a stale comment is worse than no comment.
- Keep comments about: non-obvious constraints, legal requirements, algorithmic tradeoffs, external system quirks, warnings of consequences, and TODOs with context and ownership.
- Delete comment noise: redundant restatements, change journals, attributions, banner or position markers, closing-brace labels, and commented-out code.
- Never delete or reword comments a tool reads (shebangs, encoding lines, license and SPDX headers, build and compiler directives, suppressions, doctests, generated-file headers). An unexplained suppression is a finding, not a comment to delete.
<!-- Project-specific / Comments -->

### Errors

- Handle errors explicitly where a meaningful decision can be made.
- Wrap errors with original cause and context when propagating.
- Error strings should be lowercase and not end with punctuation (they're often composed into larger messages).
- Make retry, fallback, timeout, and cancellation behavior explicit.
- Never log secrets, tokens, and sensitive data in error messages and logs.
- Never swallow errors or catch broadly without handling, wrapping, or propagating with context.
<!-- Project-specific / Errors -->

## PowerShell

### Formats

- Format every `.ps1`/`.psm1`/`.psd1` file with PSScriptAnalyzer's `Invoke-Formatter`; never hand-format what it owns.
<!-- Project-specific / PowerShell-Formats -->

### Names

- Name every function `Verb-Noun` with an approved verb (`Get-Verb` lists them) and a singular noun (`Get-User`, never `Get-Users` or `List-Users`).
- Add a vendor or module prefix to the noun to avoid colliding with a built-in or another module's command (`Get-MyAppUser`).
- Name parameters in PascalCase for their meaning, matching cmdlet convention (`-Path`, `-Force`), never an abbreviation only the author understands.
- Never noun a function `Data`, `Info`, or `Item`, or hold one value in `$data`/`$temp`; keep a name that short only for a loop index or `$_`.
- Never carry a Hungarian tag into a variable (`$strName`, `$iCount`), or leave a rename half-done with a `V2` noun or a `-Final` switch.
- Never hide a verb in a cmdlet's noun (`Get-ProcessOrder`) — the verb names the action — and never a noun alone `Manager`, `Helper`, or `Util(s)`.
<!-- Project-specific / PowerShell-Names -->

### Functions And Types

- Start every function with `[CmdletBinding()]` (add `SupportsShouldProcess` when it changes state) so common parameters, `-Verbose`, and `-WhatIf` come for free.
- Type every parameter and validate it declaratively (`[ValidateNotNullOrEmpty()]`, `[ValidateRange()]`, `[ValidateSet()]`) instead of an early `if` that throws.
- Accept pipeline input with `[Parameter(ValueFromPipeline)]` and a `process` block; never require a caller to assign a variable to loop over it.
- Emit objects (`[PSCustomObject]`, a typed class, or a domain type) from a function that returns data; never format it as a string for a caller to re-parse.
- Use `Write-Host` only for output meant for a human; use the pipeline (or `Write-Output`), `Write-Verbose`, and `Write-Warning` for everything else.
- Split a function that both decides whether to act and performs the action; gate the action with `$PSCmdlet.ShouldProcess(...)` rather than a boolean parameter.
<!-- Project-specific / PowerShell-Functions-And-Types -->

### Errors

- Set `$ErrorActionPreference = 'Stop'` at script scope so a cmdlet's non-terminating error becomes catchable; pass `-ErrorAction Stop` to calls inside a shared module.
- Catch specific exception types (`catch [System.IO.IOException]`) before a general `catch`; never catch everything to swallow it.
- Re-raise from a function with `$PSCmdlet.ThrowTerminatingError($_)` so the original `ErrorRecord`, category, and target survive for the caller.
- Model an expected alternate outcome (not found, already exists) as a return value or a `-PassThru` result; reserve a thrown error for what the caller did not ask for.
<!-- Project-specific / PowerShell-Errors -->

### Modules And Visibility

- Ship a module as a `.psm1` plus a `.psd1` manifest that lists `FunctionsToExport`; never export with a wildcard.
- Split `Public/` (one file per exported function) from `Private/` (internal helpers); export only the public folder.
- Keep a function private unless another script or module is meant to call it.
- Never rely on a `$global:` variable to pass state between functions; pass parameters and return values instead.
<!-- Project-specific / PowerShell-Modules-And-Visibility -->

### Tests

- Use Pester (5 or 6); existing `Should -Be` assertions keep working on either, so match whichever the project has installed.
- Structure specs `Describe`/`Context`/`It` around behavior, and mock the filesystem, network, or registry a function calls rather than hitting them for real (F.I.R.S.T.).
- Test parameter validation and the `ShouldProcess` branch explicitly; `-WhatIf` must produce no side effect.
<!-- Project-specific / PowerShell-Tests -->

### Tooling

- Target PowerShell 7.4+ (7.6 LTS current); write Windows PowerShell 5.1-compatible syntax only where a host requires it.
- Run PSScriptAnalyzer in CI (`Invoke-ScriptAnalyzer -Recurse`) with at least `PSUseApprovedVerbs`, `PSAvoidUsingCmdletAliases`, `PSAvoidUsingWriteHost`, `PSUseShouldProcessForStateChangingFunctions`, and `PSAvoidGlobalVars` enabled.
- Run `Invoke-Formatter` in CI or a pre-commit hook so layout never bikesheds a review.
- Run Pester in CI, with coverage on `Public/` and `Private/` functions, not a manual run before release.
<!-- Project-specific / PowerShell-Tooling -->

### Smells

- An alias (`gci`, `%`, `?`, `echo`) left in a script instead of the full cmdlet name.
- A function that writes formatted text and expects a caller to regex-parse it back into data instead of returning an object.
- `Invoke-Expression` building a command from string concatenation, where a script block or splatted parameters would do.
- A state-changing function with no `SupportsShouldProcess`, so `-WhatIf` and `-Confirm` silently do nothing.
- A verb outside the approved list (`Create-`, `Delete-`, `Update-`) forcing an import warning.
- A `$global:` variable standing in for a parameter or a module-scoped value.
<!-- Project-specific / PowerShell-Smells -->

## Project-specific

<!-- Project-specific -->
