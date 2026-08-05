# Changelog for Sampler.PowerShellUniversalTasks

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-08-05

### Added

- Added reusable Sampler tasks for packaging and deploying PowerShell Universal modules.
- Added task-file alias exports compatible with `ModuleBuildTasks` in Sampler repositories.
- Added WikiSource documentation and DscResource.DocGenerator build and publish workflows.
- Added post-deployment notification validation that fails the build when PowerShell Universal reports a deployment error.
- Added module-scoped compound tasks for pulling a packaged module from a PSU resource repository or packaging and pushing a complete offline repository, including post-deployment validation.

### Changed

- Converted the generated sample module into an InvokeBuild task module.

### Deprecated

- For soon-to-be removed features.

### Removed

- Removed generated sample functions, classes, and tests.

### Fixed

- For any bug fix.

### Security

- In case of vulnerabilities.
