# Getting Started

## Prerequisites

- A PowerShell module repository based on Sampler.
- PowerShell 7 or Windows PowerShell 5.1.
- Access to a PowerShell Universal server for deployment tasks.
- A PowerShell Universal application token for authenticated deployments.

## Install the task module

Add the module to the consumer repository's `RequiredModules.psd1`:

```powershell
@{
    Sampler.PowerShellUniversalTasks = 'latest'
}
```

For released versions, the module can also be installed directly:

```powershell
Install-PSResource -Name Sampler.PowerShellUniversalTasks
```

## Import the task file

Add the module to `ModuleBuildTasks` in the consumer repository's `build.yaml`:

```yaml
ModuleBuildTasks:
  Sampler.PowerShellUniversalTasks:
    - 'Task.*'
```

Sampler imports the module and dot-sources the task file through the exported
`Task.Publish_PowerShellUniversal` alias.

## Configure the server

Add a `UniversalServer` section:

```yaml
UniversalServer:
  UniversalServerUrl: https://psu.example.test
  UniversalPSResourceRepositoryName: output
  UniversalPSResourceRepositoryUrl: ./output/
  UniversalPSResourceRepositoryAutoRemove: true
  UniversalRepositoryStagingDirectoryName: PsuRepository
  UniversalRepositoryAsModule: false
  UniversalUnpinned: true
```

Do not store `UniversalServerAppToken` in `build.yaml`. Supply it as an
environment variable in CI:

```powershell
$env:UniversalServerAppToken = '<token>'
```

For local development, the tasks also dot-source `secrets.local.ps1` from the
consumer repository root when that ignored file exists:

```powershell
$UniversalServerAppToken = '<token>'
```

## Add workflows

Package and deploy the module directly:

```yaml
BuildWorkflow:
  deploy:
    - pack
    - publish_psu_pull_module_from_psresourcerepo
```

Package and deploy a complete offline automation repository:

```yaml
BuildWorkflow:
  deploy_repository:
    - build
    - publish_psu_push_repository
```

The compound tasks intentionally contain only tasks exported by this module.
Keep consumer-specific workflows such as `build` and `pack` in the consumer
`build.yaml` so the task module remains reusable across repositories.

Run workflows through the Sampler entry point:

```powershell
./build.ps1 -Tasks deploy
./build.ps1 -Tasks deploy_repository
```

Review [Configuration](Configuration.md) before deployment and
[Task Reference](Task-Reference.md) for task prerequisites and output details.
