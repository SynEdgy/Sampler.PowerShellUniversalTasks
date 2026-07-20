function Get-UniversalDeploymentError
{
    <#
        .SYNOPSIS
            Gets PowerShell Universal deployment error notifications.

        .DESCRIPTION
            Queries recent PowerShell Universal notifications and returns
            deployment-related errors created on or after a specified time.

        .PARAMETER ServerUrl
            Base URL of the PowerShell Universal server.

        .PARAMETER AppToken
            Application token used to authenticate the notification request.

        .PARAMETER Since
            Earliest notification creation time to include.

        .PARAMETER FilterText
            Optional text that must appear in the notification title or description.

        .EXAMPLE
            Get-UniversalDeploymentError -ServerUrl $url -AppToken $token -Since $startedAt
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AppToken,

        [Parameter(Mandatory = $true)]
        [System.DateTimeOffset]
        $Since,

        [Parameter()]
        [System.String]
        $FilterText
    )

    $requestParameters = @{
        Uri     = '{0}/api/v1/notification/last' -f $ServerUrl.TrimEnd('/')
        Headers = @{
            Authorization = 'Bearer {0}' -f $AppToken
        }
        Method  = 'Get'
    }
    $response = Invoke-RestMethod @requestParameters
    $notifications = if ($null -ne $response.page)
    {
        @($response.page)
    }
    elseif ($response -is [System.Array])
    {
        @($response)
    }
    elseif ($null -ne $response)
    {
        @($response)
    }
    else
    {
        @()
    }

    foreach ($notification in $notifications)
    {
        $createdTime = [System.DateTimeOffset]::MinValue
        if (-not [System.DateTimeOffset]::TryParse(
                [System.String] $notification.CreatedTime,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal,
                [ref] $createdTime
            ))
        {
            continue
        }

        if ($createdTime -lt $Since)
        {
            continue
        }

        $title = [System.String] $notification.Title
        $description = [System.String] $notification.Description
        $level = [System.String] $notification.Level
        $notificationText = '{0} {1}' -f $title, $description
        $isDeploymentNotification = $notificationText -match '(?i)deployment|module|configuration'
        $isErrorNotification = $level -match '(?i)^error$' -or
            $notificationText -match '(?i)\bfailed\b|\berror\b|invalid configuration'

        if (-not $isDeploymentNotification -or -not $isErrorNotification)
        {
            continue
        }

        if (-not [System.String]::IsNullOrWhiteSpace($FilterText) -and
            $notificationText -notmatch [System.Text.RegularExpressions.Regex]::Escape($FilterText))
        {
            continue
        }

        $notification
    }
}
