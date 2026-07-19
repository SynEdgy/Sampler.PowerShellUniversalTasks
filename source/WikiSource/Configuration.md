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
|-- repository.psd1
`-- Modules/
    |-- MyModule/
    |   `-- 1.0.0/
    `-- MyDependency/
        `-- 2.0.0/
```

The zip contains the project module and recursively resolved `RequiredModules`
dependencies. `repository.psd1` identifies the project module that PowerShell
Universal should load from the `Modules` directory.

Keep `UniversalRepositoryAsModule` set to `false` for this full repository
layout.
