<# 
    .SYNOPSIS

        Script is used to create dotCover coverage builder

        creation date: 09/28/2016
        author: alexander.danilov@aurea.com 

#>

$ModuleName = 'DOTCOVER'

function Run-TestsWithCoverage($session)
{
    Write-LogInfo $ModuleName "Using 'DotCover' coverage tool"                                
    
    $managedAssemblies = @()

    New-DotCoverSettings -Path $session.DotCoverSettingsTempFile -TargetExecutable $session.CoverageSession.TargetExecutable -TargetWorkingDir $session.CoverageSession.TargetWorkingDir -TargetArguments $session.CoverageSession.TargetArguments -Output $session.DotCoverOutput -ScopeEntry $managedAssemblies                
         
    $ErrorActionPreference = "Continue"        

    $dotCoverArgs = @(
        'cover',
        $session.DotCoverSettingsTempFile            
    )

    if(-Not [string]::IsNullOrWhiteSpace($session.DotCoverFilter))
    {
        $dotCoverArgs += "/Filters=$($session.DotCoverFilter)"
    }    
    
    if(-Not [string]::IsNullOrWhiteSpace($session.DotCoverAttributeFilter))
    {
        $dotCoverArgs += "/AttributeFilters=$($session.DotCoverAttributeFilter)"
    }            

    &$session.DotCover $dotCoverArgs | Out-DotCover

    $ExitCode = $LastExitCode
         
    Write-LogInfo $ModuleName "dotcover.exe exited with $ExitCode"

    $ErrorActionPreference = 'Stop'         
    
    Get-DotCoverXml $session.DotCover -Source $session.DotCoverOutput -Output $session.DotCoverXmlOutput                               
}

function Run-PublishCoverageResults($session)
{
    if($session.ReportTool -eq 'RG')
    {                    
        $reportOutput = Join-Path $session.BaseDir "dc-coverage-report"

        Publish-CoverageReport -ReportTool $session.ReportGenerator -Reports $session.DotCoverXmlOutput -Zip $session.CoverageZip -Output $reportOutput                     
    }
    else
    {
        Publish-DotCoverResults -Path $session.DotCoverOutput
    }     
}