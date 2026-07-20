---
description: 'Task module alias export instructions'
applyTo: '{source/prefix.ps1,source/Tasks/*.build.ps1,build.yaml}'
---

# InvokeBuild Task Alias Export Guidelines

## Purpose

- Keep shipped InvokeBuild task files under `source/Tasks`.
- Define exported task-file aliases in `source/prefix.ps1`.
- The alias pattern must remain compatible with Sampler `ModuleBuildTasks`.

## Export rules

- Point each alias at its task file under the built module's `Tasks` directory.
- Name aliases with the `Task.` prefix.
- List every task alias under `AliasesToExport` in `build.yaml`.
- Do not place alias-only scripts under `source/Public`; ModuleBuilder can incorrectly add their basenames to `FunctionsToExport`.
- Keep the implementation compatible with Windows PowerShell 5.1 and PowerShell 7.

## Build wiring

- Keep `Tasks` in `CopyPaths`.
- Keep `prefix: prefix.ps1` enabled in `build.yaml`.
- Put reusable task logic in one-function-per-file module functions under `source/Public` or `source/Private`.
- Do not add sibling task helper modules.
- Verify the built module exports every configured alias and ships every task file.
