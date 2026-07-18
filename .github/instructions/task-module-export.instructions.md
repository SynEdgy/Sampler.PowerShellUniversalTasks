---
description: 'Task module alias export instructions'
applyTo: '{source/Public/Task.*.ps1,source/Tasks/*.build.ps1,build.yaml}'
---

# InvokeBuild Task Alias Export Guidelines

## Purpose

- Keep shipped InvokeBuild task files under `source/Tasks`.
- Define each exported task-file alias in a `source/Public/Task.*.ps1` file.
- The alias pattern must remain compatible with Sampler `ModuleBuildTasks`.

## Export rules

- Point each alias at its task file under the built module's `Tasks` directory.
- Name aliases with the `Task.` prefix.
- List every task alias under `AliasesToExport` in `build.yaml`.
- Keep the implementation compatible with Windows PowerShell 5.1 and PowerShell 7.

## Build wiring

- Keep `Tasks` in `CopyPaths`.
- Put reusable task logic in one-function-per-file module functions under `source/Public` or `source/Private`.
- Do not add sibling task helper modules.
- Verify the built module exports every configured alias and ships every task file.
