#region Core API Functions

function Invoke-OpenAIRequest {
    <#
    .SYNOPSIS
    Core function for making API requests to OpenAI (PowerShell 7 optimized)
    .PARAMETER Endpoint
    API endpoint (e.g., "chat/completions")
    .PARAMETER Method
    HTTP method (GET, POST, etc.)
    .PARAMETER Body
    Request body as hashtable
    .PARAMETER ContentType
    Content type for the request
    .PARAMETER Stream
    Enable streaming response
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [string]$Method = "POST",
        [hashtable]$Body = @{},
        [string]$ContentType = "application/json",
        [switch]$Stream
    )
    
    if (-not $Global:OpenAIConfig.ApiKey) {
        throw [System.InvalidOperationException]::new("OpenAI API key not configured. Use Set-OpenAIKey first.")
    }
    
    # Convert SecureString to plain text for API call
    $PlainTextApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Global:OpenAIConfig.ApiKey)
    )
    
    $Uri = "$($Global:OpenAIConfig.BaseUrl)/$Endpoint"
    
    $Headers = @{
        "Authorization" = "Bearer $PlainTextApiKey"
        "Content-Type" = $ContentType
        "User-Agent" = "PowerShell-OpenAI-Wrapper/2.0"
    }
    
    if ($Global:OpenAIConfig.Organization) {
        $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
    }
    
    try {
        $RequestParams = @{
            Uri = $Uri
            Method = $Method
            Headers = $Headers
            TimeoutSec = $Global:OpenAIConfig.TimeoutSec
            ResponseHeadersVariable = 'ResponseHeaders'
            StatusCodeVariable = 'StatusCode'
        }
        
        if ($Body.Count -gt 0 -and $Method -ne "GET") {
            if ($ContentType -eq "application/json") {
                # PowerShell 7 optimized JSON conversion with better depth handling
                $RequestParams.Body = ($Body | ConvertTo-Json -Depth 20 -Compress)
            } else {
                $RequestParams.Body = $Body
            }
        }
        
        if ($Stream) {
            # PowerShell 7 streaming support
            Write-Warning "Streaming responses require custom handling in PowerShell 7"
            # For streaming, we'd need to use HttpClient directly or handle SSE
        }
        
        $Response = Invoke-RestMethod @RequestParams
        
        # Add response metadata (PowerShell 7 feature)
        if ($Response -and $ResponseHeaders) {
            $Response | Add-Member -NotePropertyName '_ResponseHeaders' -NotePropertyValue $ResponseHeaders -Force
            $Response | Add-Member -NotePropertyName '_StatusCode' -NotePropertyValue $StatusCode -Force
        }
        
        return $Response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        # PowerShell 7 structured error handling
        $ErrorDetails = $_.ErrorDetails.Message
        if ($ErrorDetails) {
            try {
                $ErrorObj = $ErrorDetails | ConvertFrom-Json
                $ErrorMessage = "$($ErrorObj.error.message) (Type: $($ErrorObj.error.type), Code: $($ErrorObj.error.code))"
            }
            catch {
                $ErrorMessage = $ErrorDetails
            }
        } else {
            $ErrorMessage = $_.Exception.Message
        }
        
        throw [System.Net.Http.HttpRequestException]::new("OpenAI API Error: $ErrorMessage", $_.Exception)
    }
    catch {
        throw [System.InvalidOperationException]::new("Request failed: $($_.Exception.Message)", $_.Exception)
    }
    finally {
        # Clear the plain text API key from memory
        if ($PlainTextApiKey) {
            $PlainTextApiKey = $null
            [System.GC]::Collect()
        }
    }
}

#endregion
