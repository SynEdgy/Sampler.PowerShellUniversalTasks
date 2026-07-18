---
description: 'Module class export and type accelerator instructions'
applyTo: '{source/suffix.ps1,source/Classes/*.ps1,source/Enum/*.ps1}'
---

# Classes and Type Accelerators Guidelines

## Purpose

- Use `source/suffix.ps1` to expose selected PowerShell classes as type accelerators after module import.
- Use this pattern when consumers need classes without a `using module` statement.

## Registration rules

- Keep type-accelerator registration in `source/suffix.ps1`, after classes are available.
- Use `$TypesToExportAsIs` only for classes that require a bare accelerator name.
- Prefer module-qualified accelerators through `$TypesToExportWithNamespace`.
- Resolve the module name dynamically.
- Resolve classes by name with `-as [System.Type]`; do not use type literals.
- Throw when a configured class cannot be resolved.
- Remove and replace an existing accelerator with the same name during module reload.
- Emit `Write-Verbose` when replacing an accelerator.

## Build wiring

- Enable `suffix: suffix.ps1` in `build.yaml` when type accelerators are used.
- Verify the suffix is merged into the built root module.

## Cleanup

- Remove registered accelerators from the module `OnRemove` handler.
- Keep cleanup aligned with every registered accelerator.

## Change safety

- Update `source/suffix.ps1`, class files, and tests together when adding, renaming, or removing exported classes.
- Keep the implementation compatible with Windows PowerShell 5.1 and PowerShell 7.
