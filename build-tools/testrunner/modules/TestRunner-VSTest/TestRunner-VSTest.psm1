<# 
    .SYNOPSIS

        Script is used to run unit tests using vstest.console.exe
        (it isn't fully completed, but it's possible to extend it)

        creation date: 05/20/2016
        author: alexander.danilov@aurea.com 

#>

Import-Module TestRunner-Log
Import-Module TestRunner-Tools

$ModuleName = 'VSTEST'

function Setup-Tests($session)
{        
    if(Test-Path($session.VSTestResults))
    {
        Write-LogInfo $ModuleName "Clean existing test results"
        Remove-Item -Path $session.VSTestResults -ErrorAction SilentlyContinue -Force -Recurse | Out-Null
    }

    $args = @()

    foreach($test in $session.AssembliesToTest)
    {
       $args += $test
       Write-LogInfo $ModuleName $test 
    }      

    if(-Not [string]::IsNullOrWhiteSpace($session.VSTestCaseFilter))
    {
        $args += "/TestCaseFilter:$($session.VSTestCaseFilter)"
    }

    if(-Not [string]::IsNullOrWhiteSpace($session.VSCoverSettings) -and (Test-Path($session.VSCoverSettings)))
    {
        $args += "/Settings:$($session.VSCoverSettings)"
    }

    $args += "/InIsolation"
    $args += "/UseVsixExtensions:true"
    $args += "/Logger:trx"

    $coverageSession = @{
        TargetExecutable =$session.VSTest
        TargetWorkingDir =$session.BaseDir
        TargetArguments = $args
    }

    $session.CoverageSession= $coverageSession
}

function Run-Tests($session)
{              
    # run without coverage
    &$session.CoverageSession.TargetExecutable  $session.CoverageSession.TargetArguments | Out-VSTest   
}


function Run-PublishTestResults($session)
{
    if(Test-Path($session.VSTestResults))
    {
        Publish-TrxResults -Path $session.VSTestResults 
    }
    else
    {
        Write-LogWarning $ModuleName "MSTest test results has not been found at $($session.VSTestResults)"
    }
}

Export-ModuleMember Setup-Tests
Export-ModuleMember Run-Tests
Export-ModuleMember Run-PublishTestResults