<# 
    .SYNOPSIS

        Script is used to create OpenCover coverage builder

        creation date: 09/28/2016
        author: alexander.danilov@aurea.com 

#>

$ModuleName = 'OPENCOVER'

# run tests using specified tests runner
function Run-TestsWithCoverage($session)
{
    Write-LogInfo $ModuleName "Using 'OpenCover' coverage tool"                                
        
    $openCoverArgs = @(
        "-target:$($session.CoverageSession.TargetExecutable)",
        "-targetargs:$($session.CoverageSession.TargetArguments)",
        "-targetdir:$($session.CoverageSession.TargetWorkingDir)",
        "-register",
        "-mergebyhash",
        "-output:$($session.OpenCoverXmlOutput)"                      
    )

    if(-Not [string]::IsNullOrWhiteSpace($session.OpenCoverFilter))
    {
        $openCoverArgs += "-filter:$($session.OpenCoverFilter)"
    }         

    $ErrorActionPreference = "Continue"   

    Write-LogDebug 'OPENCOVER' "Args: $openCoverArgs"

    &$session.OpenCover $openCoverArgs | Out-OpenCover

    $ExitCode = $LastExitCode
         
    Write-LogInfo 'OPENCOVER' "opencover.console.exe exited with $ExitCode"

    $ErrorActionPreference = 'Stop'             
}

function Run-PublishCoverageResults($session)
{
    if($session.ReportTool -eq 'RG')
    {                    
        $reportOutput = Join-Path $session.BaseDir "oc-coverage-report"                                                

        Publish-CoverageReport -ReportTool $session.ReportGenerator -Reports $session.OpenCoverXmlOutput -Zip $session.CoverageZip -Output $reportOutput
    }
    else
    {
        Publish-DotCoverResults -Path $session.DotCoverOutput
    }     
}