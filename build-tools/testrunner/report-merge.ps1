<# 
    .SYNOPSIS

        Script is used to build and to run unit tests

        creation date: 09/22/2016
        author: alexander.danilov@aurea.com 
#>


[CmdletBinding(SupportsShouldProcess)]
param
(
    # The log level (default 'Debug')
    [ValidateSet('Debug', 'Info', 'Notice', 'Warning', 'Error')]
    [string] $LogLevel = 'Debug',
    
    [string] $ReportsToMerge = 'dotCoverOutput.xml;results.xml',

    [string] $OutputFolder = 'merge-coverage',

    [string] $ReportType = 'HtmlSummary;XmlSummary',
      
    [string] $CoverageZip = 'coverage.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\include\Init.ps1"

[Environment]::CurrentDirectory = $script:BaseDir
Set-Location $script:BaseDir

$session = @{
  BaseDir = $BaseDir  
  ReportGenerator = 'c:\ReportGenerator\bin\ReportGenerator.exe' 
}

Import-Module TestRunner-Log
Import-Module TestRunner-Tools

# setup logging
if ($LogLevel)
{
    Set-LogLevel $LogLevel
}

try
{    
    Write-LogInfo 'MERGE' 'Validating base tools...'
   
    if(-Not (Test-Path($session.ReportGenerator)))
    {
         throw "ReportGenerator not found '$($session.ReportGenerator)'"
    }

    if([string]::IsNullOrWhiteSpace($ReportsToMerge))
    {
        throw "Please specify xml reports for building combined report"
    }
  
    $reports = $ReportsToMerge -split ';'

    $preparedReports = @()

    foreach($report in $reports)
    {
        $reportFile = Join-Path $session.BaseDir $report

        if(Test-Path($reportFile))
        {
            $preparedReports += $reportFile
        }
        else
        {            
            Write-LogError 'MERGE' "Report $reportFile not found"
        }
    }

    if($preparedReports.Length -lt 1)
    {
        Write-LogError 'MERGE' 'No reports to be merged'
        throw ''
    }

    $reportsArg = $preparedReports -join ';'
    
    Publish-CoverageReport -ReportTool $session.ReportGenerator -Reports $reportsArg -Zip $CoverageZip -Output $OutputFolder                        
}
catch
{
    $ErrorMessage = $_.Exception.Message    
    Write-Host $ErrorMessage -ForegroundColor Red    
    Write-Host "##teamcity[buildStatus status='FAILURE' text='Build failed. See errors in log']"
    
    exit(1)
}
finally
{
    # remove all used modules (for debugging purpose)
    Remove-Module TestRunner-Log        
    Remove-Module TestRunner-Tools    
}