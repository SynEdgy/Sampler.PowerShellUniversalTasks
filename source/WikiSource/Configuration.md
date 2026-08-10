# Configuration

The tasks resolve explicit task parameters first, then values from the
`UniversalServer` section of `build.yaml`. Server URL and token values can also
come from build environment variables.

## UniversalServer settings

```yaml
UniversalServer:
  UniversalServerUrl: https://psu.example.test
  UniversalPSResourceRepositoryName: output
  UniversalPSResourceRepositoryUrl: ./output/
  UniversalPSResourceRepositoryAutoRemove: true
  UniversalRepositoryStagingDirectoryName: PsuRepository
  UniversalRepositoryZipName:
  UniversalRepositoryAsModule: false
  UniversalUnpinned: true
  UniversalSkipCertificateCheck: false
  UniversalDeploymentNotificationDelaySeconds: 2
  UniversalDeploymentNotificationLookbackSeconds: 120
  UniversalDeploymentNotificationFilter:
```

| Setting | Default | Description |
|---|---|---|
| `UniversalServerUrl` | None | Base URL of the PowerShell Universal server. |
| `UniversalServerAppToken` | None | Application token. Prefer an environment variable or `secrets.local.ps1` instead of committing it. |
| `UniversalPSResourceRepositoryName` | `output` | Resource repository name used for module installation. |
| `UniversalPSResourceRepositoryUrl` | `./output/` | Repository URL or local path. Relative paths resolve from the consumer repository root. |
| `UniversalPSResourceRepositoryAutoRemove` | `true` | Remove the resource repository after the installation attempt. |
| `UniversalRepositoryStagingDirectoryName` | `PsuRepository` | Staging directory created below the build output directory. |
| `UniversalRepositoryZipName` | `<ProjectName>.<ModuleVersion>.zip` | Optional explicit offline repository package name. |
| `UniversalRepositoryAsModule` | `false` | Value sent to the deployment endpoint's `asModule` query parameter. |
| `UniversalUnpinned` | `true` | Value sent to the deployment endpoint's `unpinned` query parameter. |
| `UniversalSkipCertificateCheck` | `false` | Bypass TLS certificate validation for requests to the PowerShell Universal server. Useful for self-signed certificates. On PowerShell 6 and above this uses the native `Invoke-RestMethod -SkipCertificateCheck` parameter; on Windows PowerShell it temporarily disables `ServicePointManager` certificate validation for the request. |
| `UniversalDeploymentNotificationDelaySeconds` | `2` | Seconds to wait before querying notifications after deployment. Valid range: 0-300. |
| `UniversalDeploymentNotificationLookbackSeconds` | `120` | Fallback lookback window when no deployment start time was recorded in the current workflow. Valid range: 1-3600. |
| `UniversalDeploymentNotificationFilter` | Empty | Optional text that must appear in a deployment error title or description. |

## Authentication

The deployment tasks require `UniversalServerAppToken`. In CI, map a secret to
the environment variable:

```yaml
env:
  UniversalServerAppToken: ${{ secrets.UniversalServerAppToken }}
```

For local development, use the ignored `secrets.local.ps1` file:

```powershell
$UniversalServerAppToken = '<token>'
```

The token is used only by build and deployment tasks. It is not intended for
PowerShell Universal runtime scripts, apps, or dashboard endpoints.

## PowerShell resource repository deployment

`publish_module_from_psresource_repos_to_universal_server` queries the server
for `UniversalPSResourceRepositoryName`.

- A matching trusted repository is reused.
- A differing repository is removed and recreated when
  `UniversalPSResourceRepositoryAutoRemove` is `true`.
- A missing repository is created.
- The module is installed synchronously from that repository.
- The repository is removed after deployment when auto-remove is enabled.

## Offline automation repository layout

`package_universal_automation_repository` creates:

```text
PsuRepository/
|-- MyModule.psd1
`-- Modules/
    |-- MyModule/
    |   `-- 1.0.0/
    `-- MyDependency/
        `-- 2.0.0/
```

The zip contains the project module and transitively resolved `RequiredModules`
dependencies. Dependencies are processed through an iterative queue, matching
Sampler's packaging approach and avoiding nested recursive calls. The first
discovery order is retained; when the same module is required again, its
selection changes only if the newly resolved version is higher.
`<ModuleName>.psd1` identifies the project module that PowerShell Universal
should load from the `Modules` directory. It is named after the project
module rather than a fixed `repository.psd1` name so that PowerShell Universal
displays the correct module name and prerelease tag during deployment.

Keep `UniversalRepositoryAsModule` set to `false` for this full repository
layout.

## Post-deployment validation

Add `assert_universal_deployment_succeeded` immediately after a deployment
task. The deployment tasks record their UTC start time, and the assertion task
queries:

```text
GET /api/v1/notification/last
```

The workflow fails when a newer deployment, module, or configuration
notification:

- has level `Error`;
- contains `failed` or `error`; or
- contains `Invalid configuration`.

If the assertion task runs without a deployment task in the same InvokeBuild
workflow, it uses `UniversalDeploymentNotificationLookbackSeconds`.

Use `UniversalDeploymentNotificationFilter` when multiple deployments can run
against the same PSU instance concurrently and notifications contain a stable
module or project identifier.

For example, restrict deployment errors to notifications containing the module
name:

```yaml
UniversalServer:
  UniversalDeploymentNotificationFilter: MyModule
```

The filter is case-insensitive and applies to the combined notification title
and description. Leave it empty to consider every recent deployment error.
Only set a filter when PSU includes that value in relevant error notifications;
a filter intentionally excludes generic deployment errors that do not contain
the configured text.
