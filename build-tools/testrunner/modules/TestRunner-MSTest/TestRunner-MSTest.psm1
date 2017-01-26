<# 
    .SYNOPSIS

        Script is used to run unit tests using mstest.exe
        (it isn't fully completed, but it's possible to extend it)

        creation date: 06/1/2016
        author: alexander.danilov@aurea.com 

#>


Import-Module TestRunner-Log
Import-Module TestRunner-Tools

$ModuleName = 'MSTEST'

function Setup-Tests($session)
{   
    $testResults = Join-Path $session.TestsDir 'TestResults'

    if(Test-Path($testResults))
    {
        Remove-Item -Path $testResults -ErrorAction SilentlyContinue -Force -Recurse | Out-Null
    }

    New-Item -Path $testResults -ItemType Directory | Out-Null   

    $args = @()
      
    foreach($test in $session.AssembliesToTest)
    {
        $args += "/testcontainer:$test"
        Write-LogInfo $ModuleName $test 
    }

    if(Test-Path($session.MSTestOutput))
    {
        Remove-Item -Path $session.MSTestOutput -ErrorAction SilentlyContinue -Force | Out-Null
    }

    $args += "/category:""!Integration"""
    $args += "/resultsfile:$($session.MSTestOutput)"
      
    $coverageSession = @{
        TargetExecutable =$session.MSTest
        TargetWorkingDir =$session.BaseDir
        TargetArguments = $args
    }

    $session.CoverageSession= $coverageSession
}

function Run-Tests($session)
{      
    # run without coverage
    Write-LogInfo $ModuleName "Executing: $($session.CoverageSession.TargetExecutable)  $($session.CoverageSession.TargetArguments)"

    &$session.CoverageSession.TargetExecutable  $session.CoverageSession.TargetArguments | Out-MSTest  
}


function Run-PublishTestResults($session)
{
    if(Test-Path($session.MSTestOutput))
    {
        Publish-TrxResults -Path $session.MSTestOutput 
    }
    else
    {
        Write-LogWarning $ModuleName "MSTest test results has not been found at $($session.MSTestOutput)"
    }
}

Export-ModuleMember Setup-Tests
Export-ModuleMember Run-Tests
Export-ModuleMember Run-PublishTestResults