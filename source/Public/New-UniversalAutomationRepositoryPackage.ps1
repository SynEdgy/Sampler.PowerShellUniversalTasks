function New-UniversalAutomationRepositoryPackage
{
    <#
        .SYNOPSIS
            Creates an offline PowerShell Universal automation repository package.

        .DESCRIPTION
            Stages the built module and its required modules using the PowerShell
            Universal repository layout, creates repository.psd1, and compresses it.

        .PARAMETER BuiltModuleManifest
            Path to the manifest of the built project module.

        .PARAMETER OutputDirectory
            Directory where the staging folder and zip package are created.

        .PARAMETER ModuleVersion
            Built module version used for the repository manifest and default zip name.

        .PARAMETER StagingDirectoryName
            Name of the temporary repository staging directory.

        .PARAMETER ZipName
            Optional explicit name for the generated zip package.

        .EXAMPLE
            New-UniversalAutomationRepositoryPackage @packageParameters -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuiltModuleManifest,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputDirectory,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter()]
        [System.String]
        $StagingDirectoryName = 'PsuRepository',

        [Parameter()]
        [System.String]
        $ZipName
    )

    if (-not (Test-Path -Path $BuiltModuleManifest))
    {
        throw "Built module manifest '$BuiltModuleManifest' was not found."
    }

    $module = Test-ModuleManifest -Path $BuiltModuleManifest -ErrorAction Stop
    $stagingDirectory = Join-Path -Path $OutputDirectory -ChildPath $StagingDirectoryName
    $modulesDestination = Join-Path -Path $stagingDirectory -ChildPath 'Modules'
    $resolvedZipName = if ([System.String]::IsNullOrWhiteSpace($ZipName))
    {
        '{0}.{1}.zip' -f $module.Name, $ModuleVersion
    }
    else
    {
        $ZipName
    }
    $zipPath = Join-Path -Path $OutputDirectory -ChildPath $resolvedZipName

    if ($PSCmdlet.ShouldProcess($zipPath, 'Create PowerShell Universal automation repository package'))
    {
        if (Test-Path -Path $stagingDirectory)
        {
            Remove-Item -Path $stagingDirectory -Recurse -Force
        }

        $null = New-Item -Path $modulesDestination -ItemType Directory -Force
        Copy-UniversalRepositoryModule -Module $module -ModulesDestinationPath $modulesDestination -Visited @{ }

        $repositoryManifestPath = Join-Path -Path $stagingDirectory -ChildPath 'repository.psd1'
        New-UniversalAutomationRepositoryManifest -Path $repositoryManifestPath -Module $module -ModuleVersion $ModuleVersion -Confirm:$false

        if (Test-Path -Path $zipPath)
        {
            Remove-Item -Path $zipPath -Force
        }

        Compress-Archive -Path (Join-Path -Path $stagingDirectory -ChildPath '*') -DestinationPath $zipPath -Force
        Get-Item -Path $zipPath
    }
}
