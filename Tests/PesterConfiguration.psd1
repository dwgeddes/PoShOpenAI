@{
    Run = @{
        Path = 'Tests'
        ExcludePath = @()
        Output = 'Detailed'
    }
    TestResult = @{
        Enabled = $false
        OutputPath = 'Tests/TestResults.xml'
    }
}
