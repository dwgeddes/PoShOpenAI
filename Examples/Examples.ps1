#region Example Usage Functions

function Show-OpenAIExample {
    <#
    .SYNOPSIS
    Displays comprehensive usage examples for the PSOpenAI module with real-world scenarios
    .PARAMETER Category
    Show examples for a specific category (Chat, Images, Audio, Embeddings, etc.)
    .EXAMPLE
    Show-OpenAIExample
    .EXAMPLE
    Show-OpenAIExample -Category "Chat"
    #>
    param(
        [Parameter()]
        [ValidateSet("All", "Setup", "Chat", "Images", "Audio", "Embeddings", "Moderation", "Parallel", "Assistants", "Analytics", "Advanced", "Vision", "UnifiedPrompts", "BestPractices")]
        [string]$Category = "All"
    )
    
    if ($Category -eq "All" -or $Category -eq "Setup") {
        Write-Host @"

🔧 SETUP & CONFIGURATION
========================
"@ -ForegroundColor Yellow
        
        Write-Host @"
1. Configure API key (SecureString):
   Set-OpenAIKey -ApiKey (Read-Host -AsSecureString -Prompt "OpenAI API Key")

2. Test connection:
   Test-OpenAIConnection

3. Set cost-effective defaults:
   Set-OpenAIDefaults -Model "gpt-4o-mini" -MaxTokens 500 -Temperature 0.7

4. View current configuration:
   Get-OpenAIConfig

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Chat") {
        Write-Host @"

💬 CHAT COMPLETIONS
===================
"@ -ForegroundColor Yellow
        
        Write-Host @"
5. Simple chat message:
   Send-ChatMessage -Message "Explain PowerShell in simple terms"

6. Pipeline processing with system context:
   "Question 1", "Question 2" | Send-ChatMessage -SystemMessage "You are a helpful coding assistant"

7. Batch processing from file with cost tracking:
   `$results = Get-Content "questions.txt" | Send-ChatMessage -Model "gpt-4o-mini"
   `$totalCost = (`$results | Measure-Object EstimatedCost -Sum).Sum
   Write-Host "Total cost: `$`$totalCost"

8. Interactive conversation:
   Start-ChatConversation -SystemMessage "You are a PowerShell expert"

9. Advanced chat with custom parameters:
   Send-ChatMessage -Message "Write a function" -Model "gpt-4o" -MaxTokens 1000 -Temperature 0.3

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Images") {
        Write-Host @"

🖼️ IMAGE GENERATION
===================
"@ -ForegroundColor Yellow
        
        Write-Host @"
10. Generate high-quality image:
    New-OpenAIImage -Prompt "A serene mountain landscape at sunset" -Quality "hd" -Size "1792x1024"

11. Multiple images with cost analysis:
    `$images = New-OpenAIImage -Prompt "Abstract digital art" -Count 2 -Size "1024x1024"
    `$images.Summary.EstimatedCost

12. Pipeline image generation:
    "Landscape", "Portrait", "Abstract" | New-OpenAIImage -Style "vivid" -Quality "standard"

13. Image editing (requires source image):
    Edit-OpenAIImage -ImagePath "source.png" -Prompt "Add a rainbow" -MaskPath "mask.png"

14. Image variations:
    New-OpenAIImageVariation -ImagePath "original.png" -Count 3 -Size "512x512"

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Audio") {
        Write-Host @"

🔊 AUDIO PROCESSING
==================
"@ -ForegroundColor Yellow
        
        Write-Host @"
15. Text to speech with different voices:
    ConvertTo-OpenAISpeech -Text "Hello, this is a test" -Voice "alloy" -OutputPath "hello.mp3"
    ConvertTo-OpenAISpeech -Text "Welcome to PowerShell" -Voice "nova" -Speed 1.2

16. Batch text to speech:
    Get-Content "scripts.txt" | ConvertTo-OpenAISpeech -Voice "echo" -OutputDirectory "audio"

17. Speech to text transcription:
    ConvertFrom-OpenAISpeech -AudioPath "meeting.mp3" -Model "whisper-1" -Language "en"

18. Detailed transcription with timestamps:
    ConvertFrom-OpenAISpeech -AudioPath "interview.wav" -ResponseFormat "verbose_json"

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Embeddings") {
        Write-Host @"

📊 EMBEDDINGS & SIMILARITY
==========================
"@ -ForegroundColor Yellow
        
        Write-Host @"
19. Create embeddings for similarity analysis:
    `$embedding = New-OpenAIEmbedding -Input "PowerShell is a task automation framework"

20. Batch embedding with analytics:
    `$results = Get-Content "documents.txt" | New-OpenAIEmbedding -Model "text-embedding-3-small"
    `$results.Summary.ProcessingMetrics

21. Document similarity analysis:
    `$docs = @("Text 1", "Text 2", "Text 3")
    `$embeddings = `$docs | New-OpenAIEmbedding
    # Calculate cosine similarity between embeddings

22. Semantic search setup:
    `$knowledge_base = Get-Content "kb.txt" | New-OpenAIEmbedding -IncludeAnalytics

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Moderation") {
        Write-Host @"

🛡️ CONTENT MODERATION
=====================
"@ -ForegroundColor Yellow
        
        Write-Host @"
23. Content safety check:
    Test-OpenAIModeration -Input "Content to check for policy violations"

24. Batch moderation with risk analysis:
    `$results = Get-Content "user_posts.txt" | Test-OpenAIModeration
    `$high_risk = `$results.Results | Where-Object RiskScore -gt 0.8

25. Compliance reporting:
    `$moderation = Test-OpenAIModeration -Input "Various texts" -IncludeAnalytics
    `$moderation.ComplianceReport

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Parallel") {
        Write-Host @"

⚡ PARALLEL PROCESSING
=====================
"@ -ForegroundColor Yellow
        
        Write-Host @"
26. Parallel chat processing:
    Get-Content "questions.txt" | Invoke-OpenAIParallelChat -ThrottleLimit 3 -Model "gpt-4o-mini"

27. Parallel embeddings for large datasets:
    Get-Content "large_dataset.txt" | Invoke-OpenAIParallelEmbedding -BatchSize 100 -ThrottleLimit 2

28. Mixed parallel workload:
    `$questions = 1..50 | ForEach-Object { "Question `$_" }
    `$results = `$questions | Invoke-OpenAIParallelChat -SystemMessage "Be concise"

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Assistants") {
        Write-Host @"

🤖 ASSISTANTS & VISION
======================
"@ -ForegroundColor Yellow
        
        Write-Host @"
29. Create a vision-capable assistant:
    `$assistant = New-VisionAssistant -Name "Image Analyzer" -Instructions "You are an expert at analyzing images."

30. Simple text query to assistant:
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "What is PowerShell?"

31. Vision analysis with single image:
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "What do you see?" -ImagePaths @("photo.jpg")

32. Compare multiple images:
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "Compare these images" -ImagePaths @("img1.jpg", "img2.png")

33. Interactive assistant conversation:
    Start-AssistantConversation -AssistantId "asst_123"

34. Batch image processing with assistant:
    Get-ChildItem "*.jpg" | ForEach-Object {
        Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "Briefly describe this image" -ImagePaths @(`$_.FullName)
    }

35. Advanced assistant with response analysis:
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "Analyze composition" -ImagePaths @("photo.jpg")
    if (`$result.Success) {
        Write-Host "Vision support: `$(`$result.SupportsVision)"
        Write-Host "Processing time: `$(`$result.ProcessingTime)"
    }

"@ -ForegroundColor Cyan
    }
    
    #region Vision Examples (from Examples-AssistantVision.ps1)
    if ($Category -eq "All" -or $Category -eq "Vision") {
        Write-Host @"

👁️ VISION ASSISTANT EXAMPLES
============================
"@ -ForegroundColor Yellow

        Write-Host @"
1. Create a vision-capable assistant:
   `$visionAssistant = New-VisionAssistant -Name "Image Analyzer" -Instructions @"
You are an expert image analyst. When users share images with you, provide detailed descriptions including:
- Main subjects and objects in the image
- Colors, lighting, and composition
- Mood or atmosphere
- Any text or writing visible
- Technical aspects if relevant (camera settings, etc.)
Be thorough but concise in your analysis.
"@

2. Text-only assistant interaction:
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "What is PowerShell?"

   `$questions = @(
       "What are the benefits of PowerShell?",
       "How does PowerShell differ from Bash?",
       "What are PowerShell objects?"
   )
   `$results = `$questions | Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id"

   # Continue a conversation with the same thread
   `$result1 = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Tell me about PowerShell"
   `$result2 = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Can you give me an example?" -ThreadId `$result1.ThreadId

3. Vision analysis with images:
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "What do you see in this image?" -ImagePaths @("./photo.jpg")
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Compare these images and tell me the differences" -ImagePaths @("./image1.jpg", "./image2.png")
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Analyze the composition and lighting in this photograph" -ImagePaths @("./photo.jpg")
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "What text can you read in this image?" -ImagePaths @("./document.png")

4. Interactive conversation:
   Start-AssistantConversation -AssistantId "asst_your_assistant_id"
   Start-AssistantConversation -AssistantId "asst_your_vision_assistant_id" -Instructions "Be extra detailed in your image analysis"

5. Advanced usage with response analysis:
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Describe this image" -ImagePaths @("./photo.jpg")
   if (`$result.Success) {
       Write-Host "✅ Analysis completed successfully"
       Write-Host "Response: `$(`$result.Response)"
       Write-Host "Model used: `$(`$result.Model)"
       Write-Host "Processing time: `$(`$result.ProcessingTime)"
       Write-Host "Vision support: `$(`$result.SupportsVision)"
       Write-Host "Images processed: `$(`$result.ImageCount)"
       if (`$result.PromptTokens) {
           Write-Host "Tokens used - Prompt: `$(`$result.PromptTokens), Completion: `$(`$result.CompletionTokens), Total: `$(`$result.TotalTokens)"
       }
   } else {
       Write-Host "❌ Analysis failed: `$(`$result.Error)"
   }

   # Batch processing multiple images
   `$imageFiles = Get-ChildItem "*.jpg", "*.png" | Select-Object -First 5
   `$results = `$imageFiles | ForEach-Object {
       Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Briefly describe this image" -ImagePaths @(`$_.FullName)
   }
   `$successful = (`$results | Where-Object Success).Count
   `$failed = (`$results | Where-Object { -not `$_.Success }).Count
   Write-Host "Processed `$(`$imageFiles.Count) images: `$successful successful, `$failed failed"

6. Error handling and best practices:
   if (-not `$Global:OpenAIConfig.ApiKey) {
       Write-Warning "Please configure your OpenAI API key first: Set-OpenAIKey 'your-key'"
       return
   }
   `$imagePaths = @("./image1.jpg", "./image2.png")
   `$validImages = `$imagePaths | Where-Object { Test-Path `$_ -PathType Leaf }
   if (`$validImages.Count -eq 0) {
       Write-Warning "No valid image files found"
       return
   }
   try {
       `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Analyze these images" -ImagePaths `$validImages -MaxWaitSeconds 120
       if (`$result.Success) {
           `$result.Response
       } else {
           Write-Warning "Assistant processing failed: `$(`$result.Error)"
       }
   } catch {
       Write-Error "Unexpected error: `$(`$_.Exception.Message)"
   }
   `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Test" -ImagePaths @("./test.jpg") -Verbose
   `$results = @()
   1..10 | ForEach-Object {
       `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Quick analysis" -ImagePaths @("./image`$_.jpg")
       `$results += `$result
   }
   `$totalTokens = (`$results | Where-Object Success | Measure-Object -Property TotalTokens -Sum).Sum
   Write-Host "Total tokens used: `$totalTokens"

"@ -ForegroundColor Cyan
    }
    #endregion

    #region Unified Prompt Examples (from Examples-UnifiedPrompts.ps1)
    if ($Category -eq "All" -or $Category -eq "UnifiedPrompts") {
        Write-Host @"

🟦 UNIFIED PROMPT EXAMPLES
==========================
"@ -ForegroundColor Yellow

        Write-Host @"
1. Basic text generation:
   `$response1 = Invoke-OpenAIPrompt -Prompt "What is the capital of France?"
   `$response2 = Invoke-OpenAIPrompt -Prompt "Write a short poem about autumn leaves" -Temperature 0.9
   `$response3 = Invoke-OpenAIPrompt -Prompt "Explain recursion" -SystemMessage "You are a computer science professor. Explain concepts clearly with examples."
   `$response4 = Invoke-OpenAIPrompt -Prompt "Summarize the theory of relativity in one sentence" -Model "gpt-4o"

2. Image generation:
   `$image1 = Invoke-OpenAIPrompt -Prompt "A serene mountain landscape at sunset with a lake reflection" -ImageGen
   `$image2 = Invoke-OpenAIPrompt -Prompt "A modern minimalist workspace with plants" -ImageGen -Quality "hd" -Size "1024x1024"
   `$image3 = Invoke-OpenAIPrompt -Prompt "A cat sitting by a window on a rainy day" -ImageGen -Size "1792x1024" -Style "natural"

3. Vision analysis (requires image file):
   `$TestImagePath = Join-Path `$PWD "test-image.png"
   if (Test-Path `$TestImagePath) {
       `$vision1 = Invoke-OpenAIPrompt -Prompt "What do you see in this image?" -ImagePath `$TestImagePath -VisionAnalysis
       `$vision2 = Invoke-OpenAIPrompt -Prompt "Describe this image in detail, including colors, objects, composition, and mood" -ImagePath `$TestImagePath -VisionAnalysis -ImageDetail "high"
       `$vision3 = Invoke-OpenAIPrompt -Prompt "How many people are in this image and what are they doing?" -ImagePath `$TestImagePath -VisionAnalysis -Model "gpt-4o"
   }

4. Assistant conversations:
   `$assistant1 = Invoke-OpenAIAssistantPrompt -Prompt "Hello! Can you help me understand machine learning?"
   `$assistant2 = Invoke-OpenAIAssistantPrompt -Prompt "Can you give me a specific example?" -AssistantId `$assistant1.AssistantId -ThreadId `$assistant1.ThreadId
   `$codingAssistant = Invoke-OpenAIAssistantPrompt -Prompt "Help me write a Python function to calculate fibonacci numbers" -AssistantName "Python Expert" -Instructions "You are an expert Python developer. Provide clean, well-commented code with explanations." -Tools @("code_interpreter")
   `$mathAssistant = Invoke-OpenAIAssistantPrompt -Prompt "Calculate the derivative of x^3 + 2x^2 - 5x + 1 and plot it" -AssistantName "Math Tutor" -Instructions "You are a mathematics tutor. Solve problems step by step and use code when helpful." -Tools @("code_interpreter") -Model "gpt-4o"

5. Pipeline and advanced usage:
   `$topics = @("artificial intelligence", "quantum computing", "blockchain technology")
   `$summaries = `$topics | ForEach-Object {
       $result = Invoke-OpenAIPrompt -Prompt "Write a one-paragraph summary of $_" -MaxTokens 150
       [PSCustomObject]@{
           Topic = $_
           Summary = $result.choices[0].message.content
           Tokens = $result.usage.total_tokens
       }
   }
   # Multi-step workflow
   `$story = Invoke-OpenAIPrompt -Prompt "Write a short science fiction story about time travel" -MaxTokens 300 -Temperature 0.8
   `$analysis = Invoke-OpenAIPrompt -Prompt "Analyze the following story for its themes, writing style, and literary devices: `n`n$($story.choices[0].message.content)" -SystemMessage "You are a literature professor analyzing creative writing."

6. Error handling and edge cases:
   try {
       `$invalidVision = Invoke-OpenAIPrompt -Prompt "What's in this image?" -ImagePath "nonexistent.jpg" -VisionAnalysis
   } catch {
       Write-Host "✅ Error properly caught: $($_.Exception.Message)"
   }
   try {
       `$limitationTest = Invoke-OpenAIPrompt -Prompt "Analyze this image" -ImagePath `$TestImagePath -VisionAnalysis -Model "gpt-3.5-turbo"
   } catch {
       Write-Host "✅ Model limitation properly handled: $($_.Exception.Message)"
   }

7. Configuration and defaults:
   `$config = Get-OpenAIConfig
   Set-OpenAIDefaults -Model "gpt-4o" -Temperature 0.5 -MaxTokens 1500
   `$testDefault = Invoke-OpenAIPrompt -Prompt "Test message with new defaults"
   Set-OpenAIDefaults -Model "gpt-4o-mini" -Temperature 0.7 -MaxTokens 1000

"@ -ForegroundColor Cyan
    }
    #endregion

    #region Best Practices and Summary (from Examples-AssistantVision.ps1)
    if ($Category -eq "All" -or $Category -eq "BestPractices") {
        Write-Host @"

🛡️ BEST PRACTICES & SUMMARY
===========================
"@ -ForegroundColor Yellow

        Write-Host @"
• Always check for API key configuration before making requests.
• Validate image files before processing.
• Use try-catch for robust error handling.
• Use verbose output for debugging.
• Monitor token usage for cost management.

✨ PoShOpenAI Vision Capabilities:
• Text-based assistant interactions
• Vision analysis with automatic image upload
• Support for multiple image formats (jpg, jpeg, png, gif, webp)
• Interactive conversation mode
• Comprehensive response metadata
• Automatic file cleanup
• Error handling and validation
• Token usage tracking

🎯 Use Cases:
• Image analysis and description
• Document text extraction
• Photo composition analysis
• Multi-image comparison
• Interactive AI conversations
• Batch image processing
• Educational content analysis

🚀 Getting Started:
1. Set-OpenAIKey "your-api-key"
2. `$assistant = New-VisionAssistant -Name "My Analyzer" -Instructions "..."
3. `$result = Invoke-OpenAIAssistant -AssistantId `$assistant.id -Message "Analyze this" -ImagePaths @("image.jpg")

Ready to use for production workloads! 🎉
"@ -ForegroundColor White
    }
    #endregion

    Write-Host @"

💡 TIPS & BEST PRACTICES
========================
• Use gpt-4o-mini for cost-effective processing
• Implement batching for large datasets
• Monitor token usage and costs regularly
• Use SecureString for API key storage
• Leverage parallel processing for performance
• Save results for analysis and auditing
• Test moderation for user-generated content

📚 For detailed documentation and updates:
   https://github.com/your-repo/PSOpenAI

"@ -ForegroundColor Green
}

#endregion
