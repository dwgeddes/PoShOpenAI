#region Audio Functions

function ConvertTo-OpenAISpeech {
    <#
    .SYNOPSIS
    Converts text to speech using OpenAI's TTS with full pipeline support
    .PARAMETER Text
    Text to convert to speech - supports pipeline input
    .PARAMETER Voice
    Voice to use for speech generation
    .PARAMETER Model
    TTS model to use (tts-1 for speed, tts-1-hd for quality)
    .PARAMETER ResponseFormat
    Audio format for the output
    .PARAMETER Speed
    Speed of speech (0.25 to 4.0)
    .PARAMETER OutputPath
    Base path for saving audio files (will be modified for multiple inputs)
    .EXAMPLE
    ConvertTo-OpenAISpeech -Text "Hello world" -Voice "nova"
    .EXAMPLE
    "Text 1", "Text 2" | ConvertTo-OpenAISpeech -Model "tts-1-hd" -ResponseFormat "opus"
    .EXAMPLE
    Get-Content script.txt | ConvertTo-OpenAISpeech -Voice "alloy" -Speed 1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Text,
        
        [Parameter()]
        [ValidateSet("alloy", "echo", "fable", "onyx", "nova", "shimmer")]
        [string]$Voice = "alloy",  # Neutral, clear voice
        
        [Parameter()]
        [ValidateSet("tts-1", "tts-1-hd")]
        [string]$Model = "tts-1",  # Faster and cheaper, still good quality
        
        [Parameter()]
        [ValidateSet("mp3", "opus", "aac", "flac")]
        [string]$ResponseFormat = "mp3",  # Most compatible format
        
        [Parameter()]
        [ValidateRange(0.25, 4.0)]
        [double]$Speed = 1.0,
        
        [Parameter()]
        [string]$OutputPath = "speech",  # Base filename (extension added automatically)
        
        [Parameter()]
        [string]$OutputDirectory = "."  # Directory to save files
    )
    
    begin {
        $ProcessedCount = 0
        
        # Ensure output directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        }
    }
    
    process {
        foreach ($TextItem in $Text) {
            if (-not $Global:OpenAIConfig.ApiKey) {
                throw [System.InvalidOperationException]::new("OpenAI API key not configured. Use Set-OpenAIKey first.")
            }
            
            $Uri = "$($Global:OpenAIConfig.BaseUrl)/audio/speech"
            $Headers = @{
                "Authorization" = "Bearer $($Global:OpenAIConfig.ApiKey)"
                "Content-Type" = "application/json"
            }
            
            if ($Global:OpenAIConfig.Organization) {
                $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
            }
            
            $Body = @{
                model = $Model
                input = $TextItem
                voice = $Voice
                response_format = $ResponseFormat
                speed = $Speed
            } | ConvertTo-Json -Compress
            
            try {
                # Generate unique filename for multiple texts
                $FileExtension = ".$ResponseFormat"
                $UniqueFileName = if ($Text.Count -gt 1) {
                    "$OutputPath`_$ProcessedCount$FileExtension"
                } else {
                    "$OutputPath$FileExtension" 
                }
                
                $FullOutputPath = Join-Path $OutputDirectory $UniqueFileName
                
                # Generate speech and save to file
                Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers -Body $Body -OutFile $FullOutputPath -TimeoutSec $Global:OpenAIConfig.TimeoutSec
                
                $FileInfo = Get-Item $FullOutputPath
                
                [PSCustomObject]@{
                    InputText = $TextItem
                    OutputPath = $FullOutputPath
                    FileName = $FileInfo.Name
                    FileSizeBytes = $FileInfo.Length
                    Voice = $Voice
                    Model = $Model
                    ResponseFormat = $ResponseFormat
                    Speed = $Speed
                    ProcessedAt = Get-Date
                    Index = $ProcessedCount
                }
                
                $ProcessedCount++
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                $ErrorMessage = if ($_.ErrorDetails.Message) {
                    ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
                } else {
                    $_.Exception.Message
                }
                
                [PSCustomObject]@{
                    InputText = $TextItem
                    OutputPath = $null
                    Error = $ErrorMessage
                    Voice = $Voice
                    Model = $Model
                    ProcessedAt = Get-Date
                    Index = $ProcessedCount
                }
                
                $ProcessedCount++
            }
        }
    }
}

function ConvertFrom-OpenAISpeech {
    <#
    .SYNOPSIS
    Transcribes audio to text using Whisper (PowerShell 7 optimized)
    .PARAMETER AudioPath
    Path to the audio file
    .PARAMETER Model
    Whisper model to use
    .PARAMETER Language
    Language of the audio (optional)
    .PARAMETER ResponseFormat
    Format of the response (json, text, srt, verbose_json, vtt)
    .PARAMETER Temperature
    Temperature for randomness
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string[]]$AudioPath,
        [ValidateSet("whisper-1")]
        [string]$Model = "whisper-1",
        [string]$Language = $null,
        [ValidateSet("json", "text", "srt", "verbose_json", "vtt")]
        [string]$ResponseFormat = "json",
        [ValidateRange(0, 1)]
        [double]$Temperature = 0
    )
    
    process {
        foreach ($Path in $AudioPath) {
            if (-not $Global:OpenAIConfig.ApiKey) {
                throw [System.InvalidOperationException]::new("OpenAI API key not configured. Use Set-OpenAIKey first.")
            }
            
            $Uri = "$($Global:OpenAIConfig.BaseUrl)/audio/transcriptions"
            $Headers = @{
                "Authorization" = "Bearer $($Global:OpenAIConfig.ApiKey)"
            }
            
            if ($Global:OpenAIConfig.Organization) {
                $Headers["OpenAI-Organization"] = $Global:OpenAIConfig.Organization
            }
            
            try {
                $FileItem = Get-Item $Path
                $Form = @{
                    file = $FileItem
                    model = $Model
                    response_format = $ResponseFormat
                    temperature = $Temperature
                }
                
                if ($Language) {
                    $Form.language = $Language
                }
                
                $Response = Invoke-RestMethod -Uri $Uri -Method POST -Form $Form -Headers $Headers -TimeoutSec $Global:OpenAIConfig.TimeoutSec
                
                # Return structured output based on response format
                if ($ResponseFormat -eq "json" -or $ResponseFormat -eq "verbose_json") {
                    [PSCustomObject]@{
                        AudioFile = $Path
                        Text = $Response.text
                        Language = if ($Response.language) { $Response.language } else { $Language }
                        Duration = if ($Response.duration) { $Response.duration } else { $null }
                        Segments = if ($Response.segments) { $Response.segments } else { $null }
                        Model = $Model
                        ResponseFormat = $ResponseFormat
                    }
                } else {
                    # For text, srt, vtt formats, return the raw response
                    [PSCustomObject]@{
                        AudioFile = $Path
                        Content = $Response
                        Model = $Model
                        ResponseFormat = $ResponseFormat
                    }
                }
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                $ErrorMessage = if ($_.ErrorDetails.Message) {
                    ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
                } else {
                    $_.Exception.Message
                }
                throw [System.Net.Http.HttpRequestException]::new("Failed to transcribe audio '$Path': $ErrorMessage", $_.Exception)
            }
        }
    }
}
#endregion
