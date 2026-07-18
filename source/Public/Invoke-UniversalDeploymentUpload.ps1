function Invoke-UniversalDeploymentUpload
{
    <#
        .SYNOPSIS
            Uploads a deployment package to PowerShell Universal.

        .DESCRIPTION
            Sends a module package or automation repository archive to a
            PowerShell Universal deployment endpoint using bearer authentication.

        .PARAMETER Uri
            Complete PowerShell Universal deployment endpoint URI.

        .PARAMETER AppToken
            Application token used to authenticate the deployment request.

        .PARAMETER Path
            Path to the package that is uploaded as the request body.

        .EXAMPLE
            Invoke-UniversalDeploymentUpload -Uri $uri -AppToken $token -Path $packagePath
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Uri,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AppToken,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    if (-not (Test-Path -Path $Path))
    {
        throw "Deployment package '$Path' was not found."
    }

    $requestParameters = @{
        Uri         = $Uri
        Headers     = @{
            Authorization = 'Bearer {0}' -f $AppToken
        }
        InFile      = $Path
        Method      = 'Put'
        ContentType = 'application/octet-stream; charset=utf-8'
    }

    Invoke-RestMethod @requestParameters
}
