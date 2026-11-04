# Coding Conventions

## General

The principles below are for all languages. They use camelCase for demonstration purposes; adapt casing to the language's style.

When a language's established idiom contradicts a principle below, follow the idiom even when its section doesn't name it (e.g. PowerShell's `-Force` switch parameter).

### Formats

- Let the project's formatter own the format: run the formatter declared in [context.md's Supporting Tools](../.attunic/context.md#supporting-tools), if any; its check mode must report no file to change.
- Follow `.editorconfig` for indentation, line endings, charset, and final newline; it wins over editor and community defaults (e.g. tab indentation where a language has no official rule).
- Use ASCII punctuation and straight quotes by default in code, comments, and docs; use non-ASCII characters only where the content requires them (names, quoted text, symbols with no ASCII form, box-drawing in layout trees).
- Order file content top-down: high-level intent first, details descending; in a code file: file-level constants and variables, then exported identifiers, then private helpers.
- Keep related things close: local declarations near first use, callers near callees.
- Never pad comments or docs outside quoted text with filler (e.g. `simply`, `really`, `in order to`), meaningless words, or a sentence restating the one before it.
<!-- Project-specific / Formats -->
- Start top-level `.ps1` scripts with a standard banner comment: program name, purpose, `Usage:`, `Example:`, then the MIT license block; see any existing script, consistency matters more than wording.

### Names

- Use one word per concept across the codebase; never one word for two concepts.
- Use intention-revealing names: the name says why it exists and what it does, with no mental mapping from a terse abbreviation to a concept.
- Include units in names where the type does not carry them (e.g. `timeoutMs`, `maxBytes`); a value typed as a duration or size needs none.
- Start the name of a function that performs an action with a verb that discloses its side effects (`save`, `delete`, `publish`, `mutate`); name a side-effect-free accessor for what it returns (`owner`, `totalPrice`).
- Case acronyms consistently, following the language's convention; never mix forms in one codebase (`userId` beside `userID`).
- Name booleans as predicates (`isReady`, `hasItems`, `canRetry`), never as negations (`isNotReady`).
- Never write a vague name (`data`, `info`, `obj`, `temp`, `result`) when a domain name exists; a loop index, a lambda or callback parameter, a caught error, or an established short form may stay short; nothing else may.
- Never write a bare-verb function with no object (`handle`, `process`); a method's receiver counts as its object (`file.close()`).
- Never number or version a name instead of replacing the original (`user2`, `dataV2`, `_new`, `_final`, `_copy`).
- Never suffix a type with a noise word (`Manager`, `Helper`, `Util`) or name it after a verb (`ProcessOrder`).
- Avoid magic numbers or strings; use a named constant for the meaning, or attach an inline *why* comment.
<!-- Project-specific / Names -->

### Packages

- Use the narrowest visibility; export only what another module must use.
- Name a module for the domain concept it owns; never add to a catch-all `utils`, `helpers`, or `common`.
<!-- Project-specific / Packages -->

### Types

- Avoid unnecessary abstraction: introduce an interface, trait, protocol, or abstract base only once two implementations exist; a test double counts as one.
<!-- Project-specific / Types -->

### Functions

- Keep functions small, at one level of abstraction; extract a named function instead of nesting another branch or commenting a block.
- Keep positional parameters to three or fewer; past that, group related values into one parameter object.
- Prefer early exits for invalid or terminal cases over nested conditionals.
- Never switch behavior on a boolean parameter; write two functions or take a small enum.
- Never mutate an input the caller does not expect to change; return a new value instead.
<!-- Project-specific / Functions -->

### Comments

- Document every exported identifier with a doc comment stating its contract: what it is or does, and what a caller must know.
- Write inline comments explaining *why*, not *what*.
- Cut hedging from comments, and articles from inline comments; keep IDs, numbers, links, and warnings whole.
- Keep inline comments short: one to three lines; longer explanations belong in a doc file the comment points to, or an extracted function.
- Keep comments up to date with the code: a stale comment is worse than no comment.
- Keep comments about: non-obvious constraints, legal requirements, algorithmic tradeoffs, external system quirks, warnings of consequences, and TODOs with context and ownership.
- Never write comment noise: redundant restatements, change journals, attributions, banner or position markers, closing-brace labels, and commented-out code.
- Never delete or reword comments a tool reads (shebangs, encoding lines, license and SPDX headers, build and compiler directives, suppressions, doctests, generated-file headers).
<!-- Project-specific / Comments -->

### Errors

- Handle each error once, where a meaningful decision can be made; elsewhere propagate it, and never log and rethrow it at every frame.
- Wrap errors with original cause and context when propagating.
- Model an expected outcome (not found, declined, empty) as a value, an optional, or a result type, never a sentinel value (`-1`, `""`); reserve the language's error mechanism for genuine failures.
- Reserve crashes (panic, abort, process exit) for programmer errors the caller cannot act on; never crash library code on an expected failure.
- Write user-facing error messages as actionable sentences; never expose internals (stack traces, queries, file paths) in them.
- Never swallow errors or catch broadly without handling, wrapping, or propagating with context.
<!-- Project-specific / Errors -->

### Concurrency

- Give every concurrent task an owner that can wait for it or cancel it; never start one that nothing can stop.
- Keep shared mutable state to a minimum; hold a lock as briefly as possible, and never across a suspension point.
- Treat every suspension point as a place where shared state can change; re-check invariants after it.
- Never block an event loop or async runtime with blocking I/O or long computation; hand it to an async API, a worker, or a blocking-task pool.
<!-- Project-specific / Concurrency -->

## PowerShell

### PowerShell-Formats

<!-- Project-specific / PowerShell-Formats -->
- Let EditorConfig format layout per `.editorconfig`: tabs for indent, LF, UTF-8, final newline.
- Use `"${VAR}"` for a variable, `"$($Expr.Property)"` for member access; never pass a bare `$var` as an argument or write `$item.Prop` inside a string.

### PowerShell-Names

- Name every function `Verb-Noun` with an approved verb (`Get-Verb` lists them) and a singular noun (`Get-User`, never `Get-Users` or `List-Users`).
- Add a vendor or module prefix to the noun to avoid colliding with a built-in or another module's command (`Get-MyAppUser`).
- Name parameters in PascalCase for their meaning, matching cmdlet convention (`-Path`, `-Force`), never an abbreviation only the author understands.
- Never hide a verb in a cmdlet's noun (`Get-ProcessOrder`); the verb names the action.
<!-- Project-specific / PowerShell-Names -->
- Name every function `Verb-Noun` form but with relaxed rules, all verbs are accepted.

### PowerShell-Packages

- Ship a module as a `.psm1` plus a `.psd1` manifest that lists `FunctionsToExport`; never export with a wildcard.
- Split exported functions (`Public/`) from internal helpers (`Private/`); export only the public folder.
- Keep a function private unless another script or module is meant to call it.
<!-- Project-specific / PowerShell-Packages -->

### PowerShell-Types

<!-- Project-specific / PowerShell-Types -->

### PowerShell-Functions

- Start every function with `[CmdletBinding()]` (add `SupportsShouldProcess` when it changes state) so common parameters, `-Verbose`, and `-WhatIf` come for free.
- Type every parameter and validate it declaratively (`[ValidateNotNullOrEmpty()]`, `[ValidateRange()]`, `[ValidateSet()]`) instead of an early `if` that throws.
- Accept pipeline input with `[Parameter(ValueFromPipeline)]` and a `process` block; never require a caller to assign a variable to loop over it.
- Emit objects (`[PSCustomObject]`, a typed class, or a domain type) from a function that returns data; never format it as a string for a caller to re-parse.
- Use `Write-Host` only for output meant for a human; use the pipeline (or `Write-Output`), `Write-Verbose`, and `Write-Warning` for everything else.
- Split a function that both decides whether to act and performs the action; gate the action with `$PSCmdlet.ShouldProcess(...)` rather than a boolean parameter.
- Never rely on a `$global:` variable to pass state between functions; pass parameters and return values instead.
<!-- Project-specific / PowerShell-Functions -->
- Use `Write-Host` with a `> Label:` status line as the CLI progress channel; return objects for data.

### PowerShell-Comments

<!-- Project-specific / PowerShell-Comments -->

### PowerShell-Errors

- Set `$ErrorActionPreference = 'Stop'` at script scope so a cmdlet's non-terminating error becomes catchable; pass `-ErrorAction Stop` to calls inside a shared module.
- Catch specific exception types (`catch [System.IO.IOException]`) before a general `catch`; never catch everything to swallow it.
- Re-raise from a function with `$PSCmdlet.ThrowTerminatingError($_)` so the original `ErrorRecord`, category, and target survive for the caller.
- Return an expected alternate outcome (not found, already exists) as a value or a `-PassThru` result, not a thrown error.
<!-- Project-specific / PowerShell-Errors -->
- Check `$LASTEXITCODE` after every native command and fail fast; a CLI script stops with a clear message and non-zero exit instead of swallowing the failure.

### PowerShell-Concurrency

<!-- Project-specific / PowerShell-Concurrency -->

## Project-specific

<!-- Project-specific / Project-specific -->
