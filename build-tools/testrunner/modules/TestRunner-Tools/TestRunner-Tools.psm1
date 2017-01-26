<# 
    .SYNOPSIS

        Tools for test runner

        creation date: 05/20/2016
        author: alexander.danilov@aurea.com 

#>

Import-Module TestRunner-Log
Import-Module TestRunner-VSInst

function Publish-TrxResults
{
    param
    (
        [string] $Path
    )
    
    Get-ChildItem -Path $Path -Filter '*.trx' -Recurse | ForEach-Object {
        Write-Teamcity "importData type='mstest' path='$($_.FullName)'"
    }
}

function Get-VSCoverageXml
{
    param
    (
        [string] $CoverageTool,
        [string] $Path,
        [string] $Destination,
        [switch] $Single
    )

    if(-Not(Test-Path($CoverageTool)))
    {
        throw "Coverage tool not found '$CoverageTool'"
    }

    if(Test-Path($Destination))
    {
        Remove-Item $Destination -Force -ErrorAction SilentlyContinue
    }
   
    $coverages = Get-CoverageFiles $Path

    if($Single -and ($coverages.Length -gt 0))
    {
        $coverages = $coverages | Select -Index 0
    }

    &$CoverageTool analyze "/output:$Destination" $coverages     
}

function Get-CoverageFiles
{
    param
    (      
        [string] $Path            
    )

    $coverageFiles = Get-ChildItem -Path $Path -Filter '*.coverage' -Recurse

    $coverageFilesNames = @{}

    $coverages = @()

    # filter additional coverage files
    foreach($coverageFile in $coverageFiles)
    {
        if($coverageFilesNames.ContainsKey($coverageFile.Name))
        {
            continue
        }

        $coverageFilesNames.Add($coverageFile.Name, '')     
        
        $coverages += $coverageFile.FullName
    }

    return $coverages
}

function Get-DotCoverXml
{
    param
    (
        [string] $DotCoverTool,

        [string] $Source,

        [string] $Output,

        [string] $ReportType = 'DetailedXML'
    )

    Write-LogInfo 'DOTCOVER' "Executing: $DotCoverTool report /Source=$Source /Output=$Output /ReportType=$ReportType"

    &$DotCoverTool 'report' "/Source=$Source" "/Output=$Output" "/ReportType=$ReportType" | Out-DotCover

    $ExitCode = $LASTEXITCODE

    if($ExitCode -ne 0)
    {
        throw "Failed to build dotCover xml from $Source"
    }
}

function Publish-CoverageReport
{
    param
    (
        [string] $ReportTool,

        [string] $Reports,

        [string] $Zip,

        [string] $Output,        
        
        [string] $Type = 'HtmlSummary;XmlSummary',
        
        [switch] $RenameSummaryToIndex = $true        
    )
    
    if(-Not(Test-Path($ReportTool)))
    {
        throw "Report tool not found '$ReportTool'"
    }

    if(Test-Path($Output))
    {
        Remove-Item $Output -Force -ErrorAction SilentlyContinue -Recurse
    }

    Write-LogInfo 'RG' "Executing: $ReportTool -reports:$Reports -targetdir:$Output -reporttypes:$Type"

    &$ReportTool "-reports:$Reports" "-targetdir:$Output" "-reporttypes:$Type" | Out-Null
   
    if($RenameSummaryToIndex)
    {
        $summaryHtml = Join-Path $Output 'summary.htm'

        if(Test-Path($summaryHtml))
        {
            Rename-Item -Path $summaryHtml -NewName "index.html" -ErrorAction SilentlyContinue -Force
        }
    }

    $sourcePattern = "$Output\\*.*"

    Compress-Archive -Path $sourcePattern -DestinationPath $Zip -Force
    
    Write-Teamcity "publishArtifacts '$Zip'"

    $summaryXml = Join-Path $Output 'Summary.xml'

    Publish-SummaryData $summaryXml
}

function Publish-CoverageReportAurea
{
    param
    (
        [string] $ReportTool,

        [string] $Path,

        [string] $Zip,

        [string] $TotalXml                               
    )

    $coverageArgs = Get-CoverageFiles $Path | ForEach-Object { "-coverage=""$($_)""" }
    
    $command = "$ReportTool $coverageArgs -result=""$Zip"" -total=$TotalXml"   
    
    Write-Host $command     

    Invoke-Expression $command | Out-Report      

    Write-TeamCity "publishArtifacts '$Zip'"
    Write-TeamCity "publishArtifacts '$TotalXml'"
}

function Publish-SummaryData
{
    param
    (
        [string] $Path
    )

    if(-Not (Test-Path($Path)))
    {
        Write-LogWarning 'PUBLISH' "Summary report not found $Path"
        return
    }

    [xml] $summary = Get-Content $Path

    $coveredClasses = $summary.SelectNodes("//Class[@coveredlines > 0]");   

    Write-TeamCity "buildStatisticValue key='CodeCoverageAbsCTotal' value='$($summary.CoverageReport.Summary.Classes)'"
    Write-TeamCity "buildStatisticValue key='CodeCoverageAbsCCovered' value='$($coveredClasses.Count)'"
 
    Write-TeamCity "buildStatisticValue key='CodeCoverageAbsLTotal' value='$($summary.CoverageReport.Summary.Coverablelines)'"
    Write-TeamCity "buildStatisticValue key='CodeCoverageAbsLCovered' value='$($summary.CoverageReport.Summary.Coveredlines)'"
}

function Publish-DotCoverResults
{
    param
    (
        [string] $Path
    )

    Write-TeamCity "importData type='dotNetCoverage' tool='dotcover' path='$Path'"
    Write-TeamCity "publishArtifacts path='$Path'"
}

function Publish-NUnitResults
{
    param
    (
        [string] $Path
    )
    
    Write-TeamCity "importData type='nunit' path='$Path'"   
}

function New-DotCoverSettings
{
    param
    (
        [string] $Path,

        [string] $TargetExecutable,

        [string] $TargetWorkingDir,

        [string] $TargetArguments,

        [string] $Output,

        [string[]] $ScopeEntry
    )  
    
    $XmlWriter = New-Object System.XMl.XmlTextWriter($Path,$Null)  
    
    $xmlWriter.Formatting = "Indented"  
    $xmlWriter.Indentation = "4"       
    
    $xmlWriter.WriteStartDocument();

    $xmlWriter.WriteStartElement("CoverageParams")          

        $xmlWriter.WriteElementString("TargetExecutable", $TargetExecutable)  
        $xmlWriter.WriteElementString("TargetWorkingDir", $TargetWorkingDir)  
        $xmlWriter.WriteElementString("TargetArguments", $TargetArguments)    
        $xmlWriter.WriteElementString("Output", $Output)   
    
        
        $xmlWriter.WriteStartElement("Scope")  

            $ScopeEntry | ForEach-Object {
                $xmlWriter.WriteElementString("ScopeEntry", $_)
            }
            
        $xmlWriter.WriteEndElement()
    
     $xmlWriter.WriteEndElement()
    
     $xmlWriter.WriteEndDocument()  
     
     $xmlWriter.Flush()  
     $xmlWriter.Close()  
}

function Get-ManagedAssemblies
{
    param
    (
        [string] $Path
    )

    $managedAssemblies = @()

    Get-ChildItem -Path $Path -Filter '*.dll' -Recurse | ForEach-Object {
      if(Get-IsManagedAssembly($_.FullName))
      {
          $managedAssemblies += $_.FullName
      }
    }

    Get-ChildItem -Path $Path -Filter '*.exe' -Recurse | ForEach-Object {
      if(Get-IsManagedAssembly($_.FullName))
      {
          $managedAssemblies += $_.FullName
      }
    }

    return $managedAssemblies
}

function Get-Tests
{
    param
    (
        $session
    )
    
    $tests = @()
    $excludeTests = @()

    $includeFilters = $session.IncludeFilter -split ','

    $excludeFilters = $session.ExcludeFilter -split ','

    Write-LogInfo 'TOOLS' "Filter test assemblies (include) using: $includeFilters"
    Write-LogInfo 'TOOLS' "Filter test assemblies (exclude) using: $excludeFilters"
    
    #todo: get tests in new method

    foreach($filter in $excludeFilters)
    {
        if([string]::IsNullOrWhiteSpace($filter))
        {
            continue
        }

        Get-ChildItem -Path $session.TestsDir -Filter $filter -Recurse | ForEach-Object {         
            $excludeTests += $_.Name
                 
        }
    }

    foreach($filter in $includeFilters)
    {
        Get-ChildItem -Path $session.TestsDir -Filter $filter -Recurse | ForEach-Object {   
            if(-Not $excludeTests.Contains($_.Name))      
            {
                $tests += $_.Name        
            }
        }
    }      
     
    return $tests
}

function Get-TestAssemblies
{
    param
    (
        $session
    )
    
    $tests = @()    

    if([string]::IsNullOrWhiteSpace($session.IncludeFilter))
    {
        Write-LogError 'TOOLS' 'You must specify IncludeFilter'
        throw ''
    }

    Write-LogInfo 'TOOLS' "Getting the list of test assemblies (include) using: $($session.IncludeFilter)"

    [string[]]$includeFilters = $session.IncludeFilter -split ',' | ForEach-Object { Get-MatchPattern $_ }

    [string[]] $excludeFilters = @()

    if(-Not [string]::IsNullOrWhiteSpace($session.ExcludeFilter))
    {
        $excludeFilters = $session.ExcludeFilter -split ',' | ForEach-Object { Get-MatchPattern $_ }
        Write-LogInfo 'TOOLS' "Getting the list of test assemblies (exclude) using: $($session.ExcludeFilter)"        
    }        
             
    Get-ChildItem -Path $session.TestsDir -Recurse | ForEach-Object {         
        
        $doExclude = Get-IsFilterMatch $_.FullName $excludeFilters

        if(-Not $doExclude) {

            $doInclude = Get-IsFilterMatch $_.FullName $includeFilters

            if($doInclude) {
                $tests += $_
            }            
        }        
    }
    
    return $tests
}

function Get-IsFilterMatch
{
    param
    (
        [string] $text,

        [string[]] $filters
    )

    $filters | ForEach-Object {
        if((-Not [string]::IsNullOrWhiteSpace($_)) -and ($text -match $_)) {
            return $true
        }
    }

    return $false
}

function Get-MatchPattern
{
    param
    (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $pattern
    )
      
    if([string]::IsNullOrWhiteSpace($pattern))
    {
        return $pattern
    }

    $pattern = $pattern -replace '([^\*])\*([^\*])','$1[^/]*$2'
    $pattern = $pattern -replace '^\*([^\*])','[^/]*$1'
    $pattern = $pattern -replace '\.','\.'
    $pattern = $pattern -replace '\*\*','.*'   
    $pattern = $pattern -replace '/','\\'   
    
    return "$pattern$"
}


Export-ModuleMember *-*