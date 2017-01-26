<# 
    .SYNOPSIS

        Script is used to run unit tests using NUnit
        (it isn't fully completed, but it's possible to extend it)

        creation date: 09/21/2016
        author: alexander.danilov@aurea.com 

#>

Import-Module TestRunner-Log
Import-Module TestRunner-Tools

$ModuleName = 'NUNIT'

function Setup-Tests($session)
{       
    $args = @()

    foreach($test in $session.AssembliesToTest)
    {
        $args += $test
        Write-LogInfo $ModuleName $test 
    }      

    if($session.X86) {
        $args += "--x86"
        Write-LogInfo $ModuleName " force x86"
    }
	
    if(-Not [string]::IsNullOrWhiteSpace($session.NUnitWhereExpression)) {
        $args += "--where:$($session.NUnitWhereExpression)"
    }
    
    $args += "--result:$($session.NUnitOutput);format=nunit3"

    $args = $args | Where { -Not ([String]::IsNullOrWhiteSpace($_)) }   

    $coverageSession = @{
        TargetExecutable =$session.NUnit
        TargetWorkingDir =$session.BaseDir
        TargetArguments = $args
    }

    $session.CoverageSession= $coverageSession
}

function Run-Tests($session)
{               
    # run without coverage
    &$session.CoverageSession.TargetExecutable  $session.CoverageSession.TargetArguments | Out-NUnit  
}

function Run-PublishTestResults($session)
{
    if(Test-Path($session.NUnitOutput))
    {
        Publish-NUnitResults $session.NUnitOutput 
    }
    else
    {
        Write-LogWarning $ModuleName "NUnit test results has not been found at $($session.NUnitOutput)"
    }
}

Export-ModuleMember Setup-Tests
Export-ModuleMember Run-Tests
Export-ModuleMember Run-PublishTestResults