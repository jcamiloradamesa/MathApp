<# 
    .SYNOPSIS

        Script is used to create vs coverage builder

        creation date: 09/29/2016
        author: alexander.danilov@aurea.com 

#>

$ModuleName = 'VS'

function Run-TestsWithCoverage($session)
{
    Write-LogInfo 'VSTEST' "Using 'VS' coverage tool"                                                  

    $ErrorActionPreference = "Continue"

    &$session.VSTest $session.CoverageSession.TargetArguments "/Enablecodecoverage" | Out-VSTest

    $ExitCode = $LastExitCode
         
    Write-LogInfo $ModuleName "vstest.console.exe exited with $ExitCode"         

    $ErrorActionPreference = 'Stop'            
                                         
    Get-VSCoverageXml -CoverageTool $session.VSCodeCoverage -Path $session.VSTestResults -Destination $session.VSCoverXmlOutput -Single             
}

function Run-PublishCoverageResults($session)
{      
    if($session.ReportTool -eq 'RG')
    {                               
        $reportOutput = Join-Path $session.BaseDir 'vs-coverage-report'
                
        Publish-CoverageReport -ReportTool $session.ReportGenerator -Reports $session.VSCoverXmlOutput -Zip $session.CoverageZip -Output $reportOutput
    }

    if($session.ReportTool -eq 'AureaRG')
    {      
        $totalXml = Join-Path $session.BaseDir 'totalcoverage.xml'
                   
        Publish-CoverageReportAurea -ReportTool $session.AureaReportGenerator -Path $session.VSTestResults -Zip $session.CoverageZip -TotalXml $session.VSCoverXmlOutput                         
    }   
}