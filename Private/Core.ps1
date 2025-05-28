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
    
    try {
        $Uri = "$($Global:OpenAIConfig.BaseUrl)/$Endpoint"
        $Headers = @{
            "Authorization" = "Bearer $PlainTextApiKey"
            "Content-Type" = $ContentType
        }
        
        if ($Global:OpenAIConfig.Organization) {
            $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
        }
        
        $RequestParams = @{
            Uri = $Uri
            Method = $Method
            Headers = $Headers
            TimeoutSec = $Global:OpenAIConfig.TimeoutSec
        }
        
        if ($Method -ne "GET" -and $Body.Count -gt 0) {
            $RequestParams.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
        }
        
        if ($Stream) {
            # Streaming not implemented in this version
            Write-Warning "Streaming not yet implemented, using standard request"
        }
        
        $Response = Invoke-RestMethod @RequestParams
        return $Response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $ErrorMessage = "OpenAI API Error"
        if ($_.ErrorDetails.Message) {
            try {
                $ErrorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                $ErrorMessage = $ErrorObj.error.message
            }
            catch {
                $ErrorMessage = $_.ErrorDetails.Message
            }
        }
        throw [System.Net.Http.HttpRequestException]::new($ErrorMessage, $_.Exception)
    }
    catch {
        throw [System.Exception]::new("Unexpected error calling OpenAI API: $($_.Exception.Message)", $_.Exception)
    }
    finally {
        # Clear API key from memory
        if ($PlainTextApiKey) {
            Clear-Variable -Name PlainTextApiKey -Force -ErrorAction SilentlyContinue
        }
    }
}

function Convert-SecureStringToPlainText {
    <#
    .SYNOPSIS
    Converts SecureString to plain text (helper function)
    #>
    param([SecureString]$SecureString)
    
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    )
}

function Test-OpenAIConnection {
    <#
    .SYNOPSIS
    Tests the OpenAI API connection and key validity
    .PARAMETER Quiet
    Suppress output messages
    #>
    [CmdletBinding()]
    param([switch]$Quiet)
    
    if (-not $Global:OpenAIConfig.ApiKey) {
        if (-not $Quiet) {
            Write-Host "❌ No API key configured" -ForegroundColor Red
        }
        return $false
    }
    
    try {
        $Models = Invoke-OpenAIRequest -Endpoint "models" -Method "GET"
        if ($Models.data.Count -gt 0) {
            if (-not $Quiet) {
                Write-Host "✅ OpenAI API connection successful" -ForegroundColor Green
            }
            return $true
        }
        else {
            if (-not $Quiet) {
                Write-Host "❌ API returned no models" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        if (-not $Quiet) {
            Write-Host "❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

function New-OpenAIThread {
    <#
    .SYNOPSIS
    Creates a new conversation thread
    .PARAMETER Metadata
    Optional metadata for the thread
    #>
    [CmdletBinding()]
    param([hashtable]$Metadata = @{})
    
    $Body = @{
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads" -Body $Body
}

function Remove-OpenAIThread {
    <#
    .SYNOPSIS
    Deletes a conversation thread
    .PARAMETER ThreadId
    ID of the thread to delete
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId" -Method "DELETE"
}

#endregion
