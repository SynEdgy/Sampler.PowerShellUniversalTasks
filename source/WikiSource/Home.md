# Sampler.PowerShellUniversalTasks

<sup>*Sampler.PowerShellUniversalTasks v#.#.#*</sup>

`Sampler.PowerShellUniversalTasks` provides reusable Sampler and InvokeBuild tasks
for packaging and deploying PowerShell modules to PowerShell Universal.

## Start here

- [Getting Started](Getting-Started.md) - install the module, import its task file, and add tasks
  to a Sampler workflow.
- [Configuration](Configuration.md) - configure the PowerShell Universal server, resource
  repository, offline repository package, and deployment behavior.
- [Task Reference](Task-Reference.md) - prerequisites, behavior, and outputs for every exported
  InvokeBuild task.

## Available tasks

| Task | Purpose |
|---|---|
| `publish_packed_module_to_universal_server` | Upload a packed module directly to the PowerShell Universal module deployment endpoint. |
| `publish_module_from_psresource_repos_to_universal_server` | Register or reconcile a PowerShell resource repository and install the module from it. |
| `package_universal_automation_repository` | Package the built module and its dependencies as an offline automation repository. |
| `publish_universal_automation_repository_to_server` | Upload and activate an offline automation repository package. |
| `assert_universal_deployment_succeeded` | Query PSU notifications and fail the workflow when a deployment error is reported. |
| `publish_psu_pull_module_from_psresourcerepo` | Build, package, install from a PSU resource repository, and validate deployment. |
| `publish_psu_push_repository` | Build, package, push an offline PSU repository, and validate deployment. |

## Task discovery

The module exports the `Task.Publish_PowerShellUniversal` alias. Sampler loads
the task file through `ModuleBuildTasks`:

```yaml
ModuleBuildTasks:
  Sampler.PowerShellUniversalTasks:
    - 'Task.*'
```

Generated command pages and `_Sidebar.md` are rebuilt from `build.yaml`. Keep
hand-authored wiki content in `source/WikiSource`.
