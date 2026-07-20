# Sampler.PowerShellUniversalTasks

Sampler InvokeBuild tasks for packaging and deploying PowerShell Universal modules.

## Usage

Add the module to `RequiredModules.psd1`, then load its exported task aliases from `build.yaml`:

```yaml
ModuleBuildTasks:
  Sampler.PowerShellUniversalTasks:
    - 'Task.*'
```

The module provides tasks to:

- publish a packed module directly to a PowerShell Universal server;
- install a module from a PowerShell resource repository;
- package a module and its dependencies as an offline automation repository;
- deploy an offline automation repository package;
- fail a workflow when PSU reports a deployment error notification.

Consumer workflows can use the compound tasks
`publish_psu_pull_module_from_psresourcerepo` or
`publish_psu_push_repository` to group this module's deployment and validation
steps. Consumer build and package prerequisites remain in the consumer workflow.

```yaml
BuildWorkflow:
  deploy:
    - pack
    - publish_psu_pull_module_from_psresourcerepo

  deploy_repository:
    - build
    - publish_psu_push_repository
```

Configure the server under `UniversalServer` in `build.yaml`. Supply
`UniversalServerAppToken` through the build environment or a local secrets file;
do not commit tokens.

## Documentation

See the [GitHub wiki](https://github.com/SynEdgy/Sampler.PowerShellUniversalTasks/wiki)
for installation, configuration, and task reference documentation.
