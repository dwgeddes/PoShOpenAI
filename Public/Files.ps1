#region File Functions
function Add-OpenAIFile {
    <#
    .SYNOPSIS
    Uploads a file to OpenAI (PowerShell 7 optimized with proper multipart support)
    .PARAMETER FilePath
    Path to the file to upload
    .PARAMETER Purpose
    Purpose of the file (fine-tune, assistants, etc.)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string[]]$FilePath,
        [Parameter(Mandatory = $true)]
        [ValidateSet("assistants", "batch", "fine-tune", "vision")]
        [string]$Purpose
    )
    
    process {
        foreach ($Path in $FilePath) {
            $PlainTextKey = $null
            try {
                # Get API key securely
                if (-not $Global:OpenAIConfig.ApiKey) {
                    throw [System.InvalidOperationException]::new("OpenAI API key not configured. Use Set-OpenAIKey first.")
                }
                
                $PlainTextKey = Convert-SecureStringToPlainText -SecureString $Global:OpenAIConfig.ApiKey
                
                $Uri = "$($Global:OpenAIConfig.BaseUrl)/files"
                $Headers = @{
                    "Authorization" = "Bearer $PlainTextKey"
                }
                
                if ($Global:OpenAIConfig.Organization) {
                    $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
                }
                
                # PowerShell 7 improved multipart form data handling
                $FileItem = Get-Item $Path
                $Form = @{
                    file = $FileItem
                    purpose = $Purpose
                }
                
                $Response = Invoke-RestMethod -Uri $Uri -Method POST -Form $Form -Headers $Headers -TimeoutSec $Global:OpenAIConfig.TimeoutSec
                
                [PSCustomObject]@{
                    Id = $Response.id
                    FileName = $Response.filename
                    Purpose = $Response.purpose
                    Bytes = $Response.bytes
                    CreatedAt = [DateTimeOffset]::FromUnixTimeSeconds($Response.created_at).DateTime
                    Status = $Response.status
                    LocalPath = $Path
                    Success = $true
                    ProcessingInfo = @{
                        UploadedAt = Get-Date
                        FileSizeMB = [Math]::Round($Response.bytes / 1MB, 2)
                        ContentType = if ($FileItem.Extension) { $FileItem.Extension } else { "Unknown" }
                    }
                }
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                $ErrorMessage = if ($_.ErrorDetails.Message) {
                    ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
                } else {
                    $_.Exception.Message
                }
                throw [System.Net.Http.HttpRequestException]::new("Failed to upload file '$Path': $ErrorMessage", $_.Exception)
            }
            catch {
                throw [System.Exception]::new("Unexpected error uploading file '$Path': $($_.Exception.Message)", $_.Exception)
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

function Get-OpenAIFiles {
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
