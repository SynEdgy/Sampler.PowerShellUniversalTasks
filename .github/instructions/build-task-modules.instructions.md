---
description: 'Build task module authoring instructions'
applyTo: 'source/Tasks/*.build.ps1'
---

# Build Task Module Development Guidelines

## File layout

- Keep shipped build task files under `source/Tasks/`.
- Name task files `<Purpose>.<Subsystem>.build.ps1`.
- Put helper functions in one-function-per-file module files under `source/Public` or `source/Private`.
- Do not create sibling task `.psm1` helper modules.
- Keep the `.build.ps1` file focused on task parameters, task definitions, and task-scoped logging.
- Keep `Write-Build` calls in task files.

## Parameter block

- Start every `.build.ps1` task file with a `param` block.
- Use InvokeBuild `property` defaults for task parameters.
- Always include `$BuildInfo = (property BuildInfo @{ })`.
- Use fully qualified .NET types such as `[System.String]` and `[System.Management.Automation.SwitchParameter]`.
- Do not hard-code output, source, or manifest paths in task parameters.

```powershell
param
(
    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)
```

## Shared task variables

- At the start of each task body, dot-source `Set-SamplerTaskVariable`.
- Add the standard Sampler comment before dot-sourcing task variables.
- Use `-AsNewBuild` only for tasks that start a new build context.
- Use `-ArtifactContext` only when the task is building or packaging a non-default artifact from the same source tree.
- Do not re-derive `$ProjectName`, `$SourcePath`, `$ModuleVersion`, `$BuiltModuleManifest`, or related build context inside custom tasks.

```powershell
task My_Task {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable
}
```

```powershell
# Preferred: compose tasks shipped by this module.
task Deploy_And_Validate Deploy_Module, Assert_Deployment

# Avoid: consumer workflows and unrelated external tasks are not portable.
task Deploy_And_Validate build, package_module_nupkg, Deploy_Module, Assert_Deployment
```

## Task definitions

- Prefix each task body with a `# Synopsis:` comment.
- Use compound tasks without a body when a task only sequences other tasks.
- Treat compound tasks as the stable public surface for local workflows.
- Keep compound and meta-task dependencies within tasks shipped by this module.
- Do not depend on consumer `build.yaml` workflow names such as `build`, `test`, `pack`, or `publish`.
- Do not depend on tasks from other task modules unless they are deliberate, stable Sampler atomic tasks or meta-task APIs.
- Prefer leaving external build/package prerequisites to the consumer workflow instead of coupling this module to them.
- Use `Write-Build -Color <Color> -Text <message>` for task output.
- Use `Green` for success, `Yellow` for warnings, and `DarkGray` for verbose detail.
- Keep `Write-Build` calls in the task file, not in helper modules.

```powershell
# Synopsis: Run local workspace dependency linking.
task Link_Local_Workspace_Dependencies {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable
}
```

## Paths and build context

- Resolve task-facing paths with `Get-SamplerAbsolutePath` when the path can come from `build.yaml` or task parameters.
- Use Sampler task variables and built-manifest discovery instead of hard-coded `output\...` assumptions.
- Fail fast when a task requires built module output and that output is missing.
- Keep source kind and artifact kind separate; do not infer artifact context by probing folders.

## Task export

- Add task-file alias definitions to `source/prefix.ps1`.
- Point the alias at the task file under the built module's `Tasks` directory.
- Add the alias name to `AliasesToExport` in `build.yaml`.
- Keep `prefix: prefix.ps1` enabled.
- Do not use alias-only files under `source/Public`.
