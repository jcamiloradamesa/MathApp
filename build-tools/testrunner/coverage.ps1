<# 
    .SYNOPSIS

        Script is used to get total coverage report

        creation date: 05/05/2016
        author: alexander.danilov@aurea.com 

#>

[CmdletBinding(SupportsShouldProcess)]
param
(
    # The log level (default 'Debug')
    [ValidateSet('Debug', 'Info', 'Notice', 'Warning', 'Error')]
    [string] $LogLevel = 'Debug',

    [string] $DotCoverReport = 'NetCoverageReport.dcvr',
    
    [string] $CppTotalXml = 'CppTotal.xml',
    
    [string] $CppReportZip = 'CppCoverage.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\include\Init.ps1"

[Environment]::CurrentDirectory = $script:BaseDir
Set-Location $script:BaseDir

$session = @{
  BaseDir = $BaseDir 
  DotCover = 'c:\BuildAgent\tools\dotCover\dotcover.exe'
  CodeCoverageTool = Join-Path $BaseDir 'Tools\CodeCoverageToHtml\CodeCoverageToHtml.exe'
}

Import-Module TestRunner-Log


# setup logging
if ($LogLevel)
{
    Set-LogLevel $LogLevel
}

try
{
    Write-LogInfo 'REPORT' 'Building total report'

    $DotCoverReport = Join-Path $BaseDir $DotCoverReport
    $CppTotalXml = Join-Path $BaseDir $CppTotalXml
    $CppReportZip = Join-Path $BaseDir $CppReportZip

    $commandArgs = ''

    # check all paths
    if(-Not(Test-Path($DotCoverReport)))
    {
        throw "DotCover report not found at $DotCoverReport"
    }

    if(Test-Path($CppTotalXml))
    {
        Write-LogInfo 'SETUP' "Cpp total xml report found at $CppTotalXml"
        $commandArgs += " -xml=""$CppTotalXml"""
    }

    $skipCppReportPublishing = $false

    if(-Not(Test-Path($CppReportZip)))
    {
        Write-LogInfo 'SETUP' "Cpp coverage zip report not found at $CppReportZip"
        $skipCppReportPublishing = $true
    }

    if(-Not(Test-Path($session.DotCover)))
    {
        throw "Dot cover tool not found at $($session.DotCover)"
    }

    if(-Not(Test-Path($session.CodeCoverageTool)))
    {
        throw "CodeCoverageTool not found at $($session.CodeCoverageTool)"
    }

    # get dot cover xml report
    $dotCoverReportXml = Join-Path $BaseDir 'dotCoverReport.xml'

    &$session.DotCover report "/Source=$($DotCoverReport)" "/Output=$dotCoverReportXml" /ReportType=TeamCityXml | Out-DotCover

    # merge reports
    Write-LogInfo 'REPORT' 'Creating total report'

    $command = "$($session.CodeCoverageTool) -summary -result=""TotalCoverage.zip"" -dotcover=""$dotCoverReportXml""$commandArgs"

    Invoke-Expression $command

    $totalCoverageArtifactPath = Join-Path $(get-location).Path "TotalCoverage.zip"
    Write-TeamCity "publishArtifacts '$totalCoverageArtifactPath'"
    if(-Not $skipCppReportPublishing) { Write-TeamCity "publishArtifacts '$CppReportZip'" }
    Write-TeamCity "importData type='dotNetCoverage' tool='dotcover' path='$DotCoverReport'"
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
}