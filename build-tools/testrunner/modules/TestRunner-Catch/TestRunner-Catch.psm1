<# 
    .SYNOPSIS

        Script is used to run unit tests using vstest.console.exe
        (it isn't fully completed, but it's possible to extend it)

        creation date: 05/20/2016
        author: alexander.danilov@aurea.com 

#>

Import-Module TestRunner-Log
Import-Module TestRunner-Tools

$ModuleName = 'CATCH'

function Setup-Tests($session)
{      
    $tests = @()
    $testArguments = @()

    for($i = 0; $i -lt $session.AssembliesToTest.Length; $i++)
    {
        $test = $session.AssembliesToTest[$i];

        $tests += $test
      
        $args = @()                
        $args += "-r junit"
        $args += "-o $([System.IO.Path]::GetFileNameWithoutExtension($test)).xml"

        $argObject = @{
            Args = $args
        }

        $testArguments += $argObject
    }

    $coverageSession = @{                        
            Tests = $tests
            TestsArguments = $testArguments
    }

    $session.CoverageSession = $coverageSession       
}

function Run-Tests($session)
{              
    # run without coverage    
}


function Run-PublishTestResults($session)
{    
    foreach($test in $session.AssembliesToTest)
    {
        $xmlToImport = "$([System.IO.Path]::GetFileNameWithoutExtension($test)).xml"

        $xmlToImportFull = Join-Path $session.BaseDir $xmlToImport

        Write-Teamcity "importData type='junit' path='$xmlToImportFull'"
    }
}

Export-ModuleMember Setup-Tests
Export-ModuleMember Run-Tests
Export-ModuleMember Run-PublishTestResults