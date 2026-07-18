function New-UniversalAutomationRepositoryManifest
{
    <#
        .SYNOPSIS
            Creates the descriptor for a PowerShell Universal repository package.

        .DESCRIPTION
            Writes repository.psd1 with the module name and metadata required by
            PowerShell Universal when activating an offline automation repository.

        .PARAMETER Path
            Destination path for repository.psd1.

        .PARAMETER Module
            Built module information used to populate repository metadata.

        .PARAMETER ModuleVersion
            Module version written to the repository descriptor.

        .EXAMPLE
            New-UniversalAutomationRepositoryManifest -Path $path -Module $module -ModuleVersion $version
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Module,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion
    )

    $manifestParameters = @{
        Path              = $Path
        RootModule        = $Module.Name
        ModuleVersion     = ($ModuleVersion -replace '-.*$', '')
        Guid              = (New-Guid)
        Author            = $Module.Author
        CompanyName       = $Module.CompanyName
        Copyright         = $Module.Copyright
        Description       = $Module.Description
        FunctionsToExport = '*'
        CmdletsToExport   = '*'
        VariablesToExport = '*'
        AliasesToExport   = '*'
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Create PowerShell Universal repository manifest'))
    {
        New-ModuleManifest @manifestParameters
    }
}
