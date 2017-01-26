<# 
    .SYNOPSIS

        Script is used to build and to run unit tests

        creation date: 05/20/2016
        author: alexander.danilov@aurea.com 

#>

[CmdletBinding(SupportsShouldProcess)]
param
(
    # The log level (default 'Debug')
    [ValidateSet('Debug', 'Info', 'Notice', 'Warning', 'Error')]
    [string] $LogLevel = 'Debug',
    
    [string] $PathToTests = './',

    [ValidateSet('VSTest', 'MSTest', 'NUnit', 'Catch')]
    [string] $TestRunner = 'VSTest',

    [ValidateSet('VS', 'DotCover', 'OpenCover', 'None', 'OpenCppCover')]
    [string] $CoverageTool = 'VS',

    [ValidateSet('CS', 'CPP')]
    [string] $CodeBase = 'CS',    
    
    [switch] $EnableProfiler = $false,        

    [string] $VSInstrExcludeList = '',

    [string] $IncludeFilter = '*Tests.dll',

    [string] $ExcludeFilter = '',

    [string] $VSVersion = '14.0',

    [string] $OpenCoverFilter = '+[*]* -[*Test*]* -[*Specs]* -[*Entities]* -[*DBModel]*',

    [string] $OpenCoverXmlOutput = 'openCoverOutput.xml',

    [string] $DotCoverFilter = '',

    [string] $DotCoverAttributeFilter = '',

    [string] $VSCoverSettings = 'AureaSoftwarePlatform.UnitTests.sln.runsettings',    

    [string] $VSTestCaseFilter = '',

    [string] $NUnitWhereExpression = '',

    [ValidateSet('RG','AureaRG','TC')]
    [string] $ReportTool = 'RG',

    [ValidateSet(0,1)]
    [int] $DonNotPublishReport = 0,

    [string] $DotCoverSettingsTempFile = 'dotCoverTempSettings.xml',

    [string] $DotCoverOutput = 'dotCoverOutput.dcvr',

    [string] $DotCoverXmlOutput = 'dotCoverOutput.xml',

    [string] $NUnitOutput = 'NUnitResults.xml',

    [string] $MSTestOutput = 'mstest-results.trx',

    [string] $CoverageZip = 'coverage.zip',

    [string] $VSTestResults =  'TestResults',

    [string] $VSCoverXmlOutput = 'vsCoverOutput.xml',

    [string] $DotCoverPath = 'c:\BuildAgent\tools\dotCover\dotcover.exe',
    
    [string] $OpenCoverPath = 'c:\Users\Administrator\AppData\Local\Apps\OpenCover\OpenCover.Console.exe',

    [string] $ReportGenerator = 'c:\ReportGenerator\bin\ReportGenerator.exe',

    [string] $AureaReportGenerator = 'c:\CodeCoverageToHtml\CodeCoverageToHtml.exe',

    [string] $NUnitPath = '.\packages\NUnit.ConsoleRunner.3.2.1\tools\nunit3-console.exe',

    [string] $OpenCppPath = 'c:\Program Files\OpenCppCoverage\OpenCppCoverage.exe',

    [string] $OpenCppExcludeModules = '*Tests.exe',

    [switch] $X86 = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\include\Init.ps1"

[Environment]::CurrentDirectory = $script:BaseDir
[Environment]::SetEnvironmentVariable("CLRMONITOR_EXTERNAL_PROFILERS", "{1542C21D-80C3-45E6-A56C-A9C1E4BEB7B8}", "user")
Set-Location $script:BaseDir

$session = @{
  BaseDir = $BaseDir
  TestsDir = Join-Path $BaseDir $PathToTests
  TestRunner = $TestRunner
  VSTest = "c:\Program Files (x86)\Microsoft Visual Studio $VSVersion\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
  MSTest = "c:\Program Files (x86)\Microsoft Visual Studio $VSVersion\Common7\IDE\mstest.exe"
  NUnit = $NUnitPath
  VSToolsPath = "c:\Program Files (x86)\Microsoft Visual Studio $VSVersion\Team Tools\Performance Tools"
  Dumpbin = "c:\Program Files (x86)\Microsoft Visual Studio $VSVersion\VC\bin\x86_amd64\dumpbin.exe"
  DotCover = $DotCoverPath
  OpenCover = $OpenCoverPath
  VSCodeCoverage = "c:\Program Files (x86)\Microsoft Visual Studio $VSVersion\Team Tools\Dynamic Code Coverage Tools\CodeCoverage.exe"
  OpenCppCoverage = $OpenCppPath
  ReportGenerator = $ReportGenerator
  AureaReportGenerator = $AureaReportGenerator
  ReportTool = $ReportTool
  CoverageTool = $CoverageTool
  CodeBase = $CodeBase
  EnableProfiler = $EnableProfiler
  VSInstrExcludeList = $VSInstrExcludeList
  IncludeFilter = $IncludeFilter
  ExcludeFilter = $ExcludeFilter
  OpenCoverFilter = $OpenCoverFilter
  OpenCoverXmlOutput = $OpenCoverXmlOutput
  DotCoverFilter = $DotCoverFilter
  DotCoverAttributeFilter = $DotCoverAttributeFilter
  VSCoverSettings = Join-Path $BaseDir $VSCoverSettings  
  VSTestCaseFilter = $VSTestCaseFilter
  NUnitWhereExpression = $NUnitWhereExpression
  DonNotPublishReport = $DonNotPublishReport
  DotCoverSettingsTempFile = Join-Path $BaseDir $DotCoverSettingsTempFile
  DotCoverOutput = Join-Path $BaseDir $DotCoverOutput
  DotCoverXmlOutput = Join-Path $BaseDir $DotCoverXmlOutput
  NUnitOutput = Join-Path $BaseDir $NUnitOutput
  MSTestOutput = Join-Path $BaseDir $MSTestOutput
  CoverageZip = Join-Path $BaseDir $CoverageZip
  VSTestResults = Join-Path $BaseDir $VSTestResults
  VSCoverXmlOutput = Join-Path $BaseDir $VSCoverXmlOutput
  OpenCppExcludeModules = $OpenCppExcludeModules
  X86 = $X86
  AssembliesToTest = @()  
}

Import-Module TestRunner-Log
Import-Module TestRunner-Tools
Import-Module TestRunner-Runner

# setup logging
if ($LogLevel)
{
    Set-LogLevel $LogLevel
}

try
{    
    Write-LogInfo 'SETUP' 'Validating base tools...'

    # validate input
    if(-Not (Test-Path($session.TestsDir)))
    {
        throw "Tests directory not found '$($session.TestsDir)'"
    }

    # conditions for VSTests
    if($TestRunner -eq 'VSTest')
    {
        if(-Not (Test-Path($session.VSTest)))
        {
            throw "VSTest not found '$($session.VSTest)'"
        }

        if(($CoverageTool -eq 'DotCover'))
        {
            throw "DotCover for VS runner aren't supported at this moment"
        }
    }

    # conditions for MSTest
    if($TestRunner -eq 'MSTest')
    {
        if(-Not (Test-Path($session.MSTest)))
        {
            throw "MSTest not found '$($session.MSTest)'"
        }

        if(($CoverageTool -eq 'VS'))
        {
            throw "MSTest doesn't support VS Coverage"
        }
    }

    # conditions for NUnit
    if($TestRunner -eq 'NUnit')
    {
        if(-Not (Test-Path($session.NUnit)))
        {
            throw "NUnit not found '$($session.NUnit)'"
        }
        
        if(($CoverageTool -eq 'VS'))
        {
            throw "NUnit doesn't support VS Coverage"
        }       
    }

    if(($CoverageTool -eq 'VS') -and ($ReportTool -eq 'RG') -and -Not (Test-Path($session.VSCodeCoverage)))
    {             
        throw "VSCodeCoverage not found '$($session.VSCodeCoverage)'"        
    }

    if(($CoverageTool -eq 'OpenCover') -and (-Not (Test-Path($session.OpenCover))))
    {
        throw "OpenCover not found '$($session.OpenCover)'"
    }

    if(($CoverageTool -eq 'DotCover') -and (-Not (Test-Path($session.DotCover))))
    {
        throw "DotCover not found '$($session.DotCover)'"
    }

    if(($ReportTool -eq 'RG') -and (-Not (Test-Path($session.ReportGenerator))))
    {
        throw "ReportGenerator not found '$($session.ReportGenerator)'"
    }

    if(($ReportTool -eq 'AureaRG') -and (-Not (Test-Path($session.AureaReportGenerator))))
    {
        throw "Aurea report generator not found '$($session.AureaReportGenerator)'"
    }    

    if($CoverageTool -eq 'None')
    {
        $session.DonNotPublishReport = $true
    }
               
    $session = New-Session -Runner "TestRunner-$TestRunner" -CoverageTool $CoverageTool -Options $session
     
    $session.Setup()
    $session.Run()    
    $session.PublishTestResults()

    if(-Not $session.DonNotPublishReport)
    {
        $session.PublishCoverageResults()                                    
    }
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
    Remove-Module TestRunner-Runner    
}