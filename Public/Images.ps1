#region Image Functions

function New-OpenAIImage {
    <#
    .SYNOPSIS
    Generates images using DALL-E with full pipeline support
    .PARAMETER Prompt
    Description of the image to generate - supports pipeline input
    .PARAMETER Model
    DALL-E model to use (dall-e-2 or dall-e-3)
    .PARAMETER Size
    Size of the image
    .PARAMETER Quality
    Quality of the image (standard or hd) - only for dall-e-3
    .PARAMETER Style
    Style of the image (vivid or natural) - only for dall-e-3
    .PARAMETER Count
    Number of images to generate (1-10, max 1 for dall-e-3)
    .PARAMETER ResponseFormat
    Format of response (url or b64_json)
    .PARAMETER User
    Unique user identifier
    .EXAMPLE
    New-OpenAIImage -Prompt "A cat using a computer"
    .EXAMPLE
    "Cat with computer", "Dog with laptop" | New-OpenAIImage -Model "dall-e-3" -Size "1024x1024"
    .EXAMPLE
    Get-Content prompts.txt | New-OpenAIImage -Quality "hd" -Style "natural"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Prompt,
        
        [Parameter()]
        [ValidateSet("dall-e-2", "dall-e-3")]
        [string]$Model = "dall-e-3",  # Best quality, worth the cost
        
        [Parameter()]
        [ValidateSet("256x256", "512x512", "1024x1024", "1792x1024", "1024x1792")]
        [string]$Size = "1024x1024",  # Good default resolution
        
        [Parameter()]
        [ValidateSet("standard", "hd")]
        [string]$Quality = "standard",  # Cheaper option, still good
        
        [Parameter()]
        [ValidateSet("vivid", "natural")]
        [string]$Style = "vivid",  # More creative default
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$Count = 1,
        
        [Parameter()]
        [ValidateSet("url", "b64_json")]
        [string]$ResponseFormat = "url",
        
        [Parameter()]
        [string]$User = $null
    )
    
    process {
        foreach ($PromptText in $Prompt) {
            $Body = @{
                model = $Model
                prompt = $PromptText
                n = $Count
                size = $Size
                response_format = $ResponseFormat
            }
            
            # Track original parameters for comparison
            $OriginalCount = $Count
            $OriginalSize = $Size
            $Warnings = @()
            
            # DALL-E 3 specific parameters
            if ($Model -eq "dall-e-3") {
                $Body.quality = $Quality
                $Body.style = $Style
                
                # DALL-E 3 only supports count of 1
                if ($Count -gt 1) {
                    $Warnings += "DALL-E 3 only supports generating 1 image at a time. Count changed from $Count to 1."
                    $Body.n = 1
                }
                
                # DALL-E 3 size restrictions
                if ($Size -eq "256x256" -or $Size -eq "512x512") {
                    $Warnings += "DALL-E 3 doesn't support $Size. Size changed to 1024x1024."
                    $Body.size = "1024x1024"
                }
            }
            
            # DALL-E 2 size restrictions
            if ($Model -eq "dall-e-2" -and ($Size -eq "1792x1024" -or $Size -eq "1024x1792")) {
                $Warnings += "DALL-E 2 doesn't support $Size. Size changed to 1024x1024."
                $Body.size = "1024x1024"
            }
            
            if ($User) { $Body.user = $User }
            
            try {
                $Response = Invoke-OpenAIRequest -Endpoint "images/generations" -Body $Body
                
                # Return comprehensive structured output for each generated image
                for ($i = 0; $i -lt $Response.data.Count; $i++) {
                    $ImageData = $Response.data[$i]
                    
                    [PSCustomObject]@{
                        # Input Information
                        OriginalPrompt = $PromptText
                        RevisedPrompt = if ($ImageData.revised_prompt) { $ImageData.revised_prompt } else { $PromptText }
                        PromptRevised = ($ImageData.revised_prompt -and $ImageData.revised_prompt -ne $PromptText)
                        
                        # Generated Content
                        ImageUrl = if ($ResponseFormat -eq "url") { $ImageData.url } else { $null }
                        ImageData = if ($ResponseFormat -eq "b64_json") { $ImageData.b64_json } else { $null }
                        ResponseFormat = $ResponseFormat
                        
                        # Model & Configuration Used
                        Model = $Model
                        ActualSize = $Body.size
                        RequestedSize = $OriginalSize
                        SizeChanged = ($Body.size -ne $OriginalSize)
                        Quality = if ($Model -eq "dall-e-3") { $Quality } else { "N/A (DALL-E 2)" }
                        Style = if ($Model -eq "dall-e-3") { $Style } else { "N/A (DALL-E 2)" }
                        
                        # Generation Details
                        ActualCount = $Body.n
                        RequestedCount = $OriginalCount
                        CountChanged = ($Body.n -ne $OriginalCount)
                        ImageIndex = $i
                        TotalImagesGenerated = $Response.data.Count
                        
                        # Cost Estimation (approximate USD)
                        EstimatedCost = switch ($Model) {
                            "dall-e-3" {
                                switch ($Body.size) {
                                    "1024x1024" { if ($Quality -eq "hd") { 0.080 } else { 0.040 } }
                                    "1792x1024" { if ($Quality -eq "hd") { 0.120 } else { 0.080 } }
                                    "1024x1792" { if ($Quality -eq "hd") { 0.120 } else { 0.080 } }
                                    default { 0.040 }
                                }
                            }
                            "dall-e-2" {
                                switch ($Body.size) {
                                    "256x256" { 0.016 }
                                    "512x512" { 0.018 }
                                    "1024x1024" { 0.020 }
                                    default { 0.020 }
                                }
                            }
                            default { $null }
                        }
                        
                        # API Response Metadata
                        Created = if ($Response.created) { [DateTimeOffset]::FromUnixTimeSeconds($Response.created).DateTime } else { $null }
                        
                        # Processing Information
                        GeneratedAt = Get-Date
                        Success = $true
                        Warnings = $Warnings
                        HasWarnings = ($Warnings.Count -gt 0)
                        Error = $null
                        
                        # User Information
                        User = $User
                        
                        # Pipeline Information
                        PipelineIndex = if ($Prompt.Count -gt 1) { [Array]::IndexOf($Prompt, $PromptText) } else { 0 }
                        BatchSize = $Prompt.Count
                        
                        # Advanced Features
                        SupportsHD = ($Model -eq "dall-e-3")
                        SupportsMultiple = ($Model -eq "dall-e-2")
                        SupportsStyleControl = ($Model -eq "dall-e-3")
                        MaxSupportedSize = if ($Model -eq "dall-e-3") { "1792x1024" } else { "1024x1024" }
                        
                        # Helper Properties for Analysis
                        IsLandscape = ($Body.size -eq "1792x1024")
                        IsPortrait = ($Body.size -eq "1024x1792")
                        IsSquare = ($Body.size -eq "1024x1024" -or $Body.size -eq "512x512" -or $Body.size -eq "256x256")
                        IsHighQuality = ($Model -eq "dall-e-3" -and $Quality -eq "hd")
                        PixelCount = switch ($Body.size) {
                            "256x256" { 65536 }
                            "512x512" { 262144 }
                            "1024x1024" { 1048576 }
                            "1792x1024" { 1835008 }
                            "1024x1792" { 1835008 }
                            default { $null }
                        }
                    }
                }
            }
            catch {
                [PSCustomObject]@{
                    # Input Information
                    OriginalPrompt = $PromptText
                    RevisedPrompt = $null
                    
                    # Error Information
                    ImageUrl = $null
                    ImageData = $null
                    Success = $false
                    Error = $_.Exception.Message
                    ErrorType = $_.Exception.GetType().Name
                    
                    # Configuration (for troubleshooting)
                    Model = $Model
                    RequestedSize = $Size
                    RequestedCount = $Count
                    Quality = $Quality
                    Style = $Style
                    ResponseFormat = $ResponseFormat
                    
                    # Processing Information
                    GeneratedAt = Get-Date
                    Warnings = $Warnings
                    
                    # Pipeline Information
                    PipelineIndex = if ($Prompt.Count -gt 1) { [Array]::IndexOf($Prompt, $PromptText) } else { 0 }
                    BatchSize = $Prompt.Count
                }
            }
        }
    }
}

function Edit-OpenAIImage {
    <#
    .SYNOPSIS
    Edits an existing image using DALL-E
    .PARAMETER ImagePath
    Path to the image file to edit
    .PARAMETER Prompt
    Description of the edit to make
    .PARAMETER MaskPath
    Optional path to mask image
    .PARAMETER Size
    Size of the output image
    .PARAMETER Count
    Number of variations to generate
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        [string]$MaskPath = $null,
        [string]$Size = "1024x1024",
        [int]$Count = 1
    )
    
    if (-not (Test-Path $ImagePath)) {
        throw "Image file not found: $ImagePath"
    }
    
    # This would require multipart form data handling
    # Implementation would be more complex for file uploads
    Write-Warning "Image editing requires multipart form data - consider using the REST API directly for file uploads"
}

#endregion