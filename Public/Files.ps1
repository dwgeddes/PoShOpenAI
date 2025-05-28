#region File Functions
function Add-OpenAIFile {
    <#
    .SYNOPSIS
    Uploads a file to OpenAI (PowerShell 7 optimized with proper multipart support)
    .DESCRIPTION
    User-friendly file upload supporting pipeline from file objects or paths. Abstracts common purposes with switches.
    .PARAMETER Path
    Path to the file to upload (accepts string or file object with FullName)
    .PARAMETER Purpose
    Purpose of the file (fine-tune, assistants, etc.) [Advanced]
    .PARAMETER ForAssistant
    Shortcut: Set file purpose to 'assistants'
    .PARAMETER ForFineTune
    Shortcut: Set file purpose to 'fine-tune'
    .PARAMETER ForBatch
    Shortcut: Set file purpose to 'batch'
    .PARAMETER ForVision
    Shortcut: Set file purpose to 'vision'
    .EXAMPLE
    Get-ChildItem *.json | Add-OpenAIFile -ForFineTune
    .EXAMPLE
    Add-OpenAIFile -Path "data.json" -ForAssistant
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'ByPath')]
        [Alias('FullName')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string[]]$Path,

        [Parameter(ParameterSetName = 'ByPath')]
        [ValidateSet("assistants", "batch", "fine-tune", "vision")]
        [string]$Purpose,

        [Parameter(ParameterSetName = 'ByPath')]
        [switch]$ForAssistant,
        [Parameter(ParameterSetName = 'ByPath')]
        [switch]$ForFineTune,
        [Parameter(ParameterSetName = 'ByPath')]
        [switch]$ForBatch,
        [Parameter(ParameterSetName = 'ByPath')]
        [switch]$ForVision
    )
    process {
        foreach ($InputPath in $Path) {
            $PlainTextKey = $null
            try {
                # Get API key securely
                if (-not $Global:OpenAIConfig.ApiKey) {
                    Write-Error "OpenAI API key not configured. Use Set-OpenAIKey first."
                    return
                }
                $PlainTextKey = Convert-SecureStringToPlainText -SecureString $Global:OpenAIConfig.ApiKey
                $Uri = "$($Global:OpenAIConfig.BaseUrl)/files"
                $Headers = @{ "Authorization" = "Bearer $PlainTextKey" }
                if ($Global:OpenAIConfig.Organization) {
                    $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
                }
                # Determine purpose
                $resolvedPurpose = $null
                if ($ForAssistant) { $resolvedPurpose = 'assistants' }
                elseif ($ForFineTune) { $resolvedPurpose = 'fine-tune' }
                elseif ($ForBatch) { $resolvedPurpose = 'batch' }
                elseif ($ForVision) { $resolvedPurpose = 'vision' }
                elseif ($Purpose) { $resolvedPurpose = $Purpose }
                else {
                    Write-Error "You must specify a file purpose (e.g., -ForAssistant, -ForFineTune, -ForBatch, -ForVision, or -Purpose)."
                    return
                }
                # PowerShell 7 improved multipart form data handling
                $FileItem = Get-Item $InputPath
                $Form = @{ file = $FileItem; purpose = $resolvedPurpose }
                $Response = $null
                try {
                    $Response = Invoke-RestMethod -Uri $Uri -Method POST -Form $Form -Headers $Headers -TimeoutSec $Global:OpenAIConfig.TimeoutSec
                } catch {
                    Write-Error "Failed to upload file '$InputPath': $($_.Exception.Message)"
                    [PSCustomObject]@{
                        Path = $InputPath
                        Purpose = $resolvedPurpose
                        Success = $false
                        Error = $_.Exception.Message
                        Timestamp = Get-Date
                    }
                    continue
                }
                [PSCustomObject]@{
                    Id = $Response.id
                    FileName = $Response.filename
                    Purpose = $Response.purpose
                    Bytes = $Response.bytes
                    CreatedAt = [DateTimeOffset]::FromUnixTimeSeconds($Response.created_at).DateTime
                    Status = $Response.status
                    Path = $InputPath
                    Success = $true
                    ProcessingInfo = @{
                        UploadedAt = Get-Date
                        FileSizeMB = [Math]::Round($Response.bytes / 1MB, 2)
                        ContentType = if ($FileItem.Extension) { $FileItem.Extension } else { "Unknown" }
                    }
                }
            }
            finally {
                # Clear API key from memory
                if ($PlainTextKey) {
                    Clear-Variable -Name PlainTextKey -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Import-OpenAIAssistantData {
    <#
    .SYNOPSIS
    User-friendly upload for assistant data files (purpose=assistants)
    .PARAMETER Path
    Path(s) to upload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
        [Alias('FullName')]
        [string[]]$Path
    )
    process {
        foreach ($p in $Path) {
            Add-OpenAIFile -Path $p -ForAssistant
        }
    }
}

function Import-OpenAIFineTuneData {
    <#
    .SYNOPSIS
    User-friendly upload for fine-tuning data files (purpose=fine-tune)
    .PARAMETER Path
    Path(s) to upload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
        [Alias('FullName')]
        [string[]]$Path
    )
    process {
        foreach ($p in $Path) {
            Add-OpenAIFile -Path $p -ForFineTune
        }
    }
}

function Import-OpenAIBatchData {
    <#
    .SYNOPSIS
    User-friendly upload for batch data files (purpose=batch)
    .PARAMETER Path
    Path(s) to upload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
        [Alias('FullName')]
        [string[]]$Path
    )
    process {
        foreach ($p in $Path) {
            Add-OpenAIFile -Path $p -ForBatch
        }
    }
}

function Import-OpenAIVisionData {
    <#
    .SYNOPSIS
    User-friendly upload for vision data files (purpose=vision)
    .PARAMETER Path
    Path(s) to upload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
        [Alias('FullName')]
        [string[]]$Path
    )
    process {
        foreach ($p in $Path) {
            Add-OpenAIFile -Path $p -ForVision
        }
    }
}

function Get-OpenAIFileList {
    <#
    .SYNOPSIS
    Lists uploaded files
    #>
    return Invoke-OpenAIRequest -Endpoint "files" -Method "GET"
}

function Get-OpenAIFile {
    <#
    .SYNOPSIS
    Gets information about a specific file
    .PARAMETER FileId
    ID of the file to retrieve
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileId
    )
    
    return Invoke-OpenAIRequest -Endpoint "files/$FileId" -Method "GET"
}

function Remove-OpenAIFile {
    <#
    .SYNOPSIS
    Deletes a file
    .PARAMETER FileId
    ID of the file to delete
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileId
    )
    
    return Invoke-OpenAIRequest -Endpoint "files/$FileId" -Method "DELETE"
}

function Get-OpenAIFileContent {
    <#
    .SYNOPSIS
    Downloads the content of a file
    .PARAMETER FileId
    ID of the file to download
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileId
    )
    
    return Invoke-OpenAIRequest -Endpoint "files/$FileId/content" -Method "GET"
}
#endregion
