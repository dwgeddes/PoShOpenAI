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
        [ValidateSet("All", "Setup", "Chat", "Images", "Audio", "Embeddings", "Moderation", "Parallel", "Assistants", "Analytics", "Advanced")]
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
    
    if ($Category -eq "All" -or $Category -eq "Analytics") {
        Write-Host @"

📈 ANALYTICS & COST TRACKING
============================
"@ -ForegroundColor Yellow
        
        Write-Host @"
36. Comprehensive cost analysis:
    `$chat_results = Get-Content "queries.txt" | Send-ChatMessage -Model "gpt-4o"
    `$total_cost = (`$chat_results | Measure-Object EstimatedCost -Sum).Sum
    `$avg_tokens = (`$chat_results | Measure-Object TotalTokens -Average).Average

37. Response quality analysis:
    `$results = Get-Content "questions.txt" | Send-ChatMessage
    `$complete = `$results | Where-Object FinishReason -eq "stop"
    `$truncated = `$results | Where-Object FinishReason -eq "length"

38. Token efficiency analysis:
    `$results | Select-Object Input, Response, @{N='Efficiency';E={`$_.Response.Length/`$_.TotalTokens}}

39. Model performance comparison:
    `$gpt4_results = `$questions | Send-ChatMessage -Model "gpt-4o"
    `$gpt4mini_results = `$questions | Send-ChatMessage -Model "gpt-4o-mini"
    # Compare costs and quality

"@ -ForegroundColor Cyan
    }
    
    if ($Category -eq "All" -or $Category -eq "Advanced") {
        Write-Host @"

🚀 ADVANCED SCENARIOS
====================
"@ -ForegroundColor Yellow
        
        Write-Host @"
40. Multi-modal content creation:
    `$story = Send-ChatMessage -Message "Write a short story about space"
    `$image = New-OpenAIImage -Prompt "Illustrate: `$(`$story.Response.Substring(0,100))"
    `$audio = ConvertTo-OpenAISpeech -Text `$story.Response -Voice "nova"

41. Content pipeline with validation:
    `$content = Get-Content "drafts.txt" | Send-ChatMessage -SystemMessage "Improve this text"
    `$moderated = `$content | Test-OpenAIModeration
    `$safe_content = `$moderated.Results | Where-Object {-not `$_.Flagged}

42. Automated documentation generation:
    `$code_files = Get-ChildItem "*.ps1" | Get-Content -Raw
    `$docs = `$code_files | Send-ChatMessage -SystemMessage "Generate documentation for this code"

43. Intelligent data processing:
    `$raw_data = Import-Csv "data.csv"
    `$processed = `$raw_data | ForEach-Object {
        Send-ChatMessage -Message "Analyze this record: `$(`$_ | ConvertTo-Json)"
    }

44. Save comprehensive results:
    `$all_results | Save-OpenAIResponse -FilePath "analysis_results.json" -IncludeMetadata
    `$all_results | Save-OpenAIResponse -FilePath "summary.csv" -Format csv

"@ -ForegroundColor Cyan
    }
    
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
