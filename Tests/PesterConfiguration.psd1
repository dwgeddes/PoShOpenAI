@{
    Run = @{
        Path = 'Tests'
        ExcludePath = @()
        Output = 'Detailed'
    }
    TestResult = @{
        Enabled = $true
        OutputPath = 'Tests/TestResults.xml'
    }
}
