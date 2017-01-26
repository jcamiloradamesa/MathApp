<# 
    .SYNOPSIS

        Script is used to create OpenCppCover coverage builder

        creation date: 11/07/2016
        author: alexander.danilov@aurea.com 

#>

$ModuleName = 'OPENCPPCOVER'

# run tests using specified tests runner
function Run-TestsWithCoverage($session)
{
    Write-LogInfo $ModuleName "Using 'OpenCppCover' coverage tool"                                
              
    $ErrorActionPreference = "Continue"   

    $previous = ''

    for($i = 0; $i -lt $session.CoverageSession.Tests.Length; $i++)
    {
        $test = $session.CoverageSession.Tests[$i];

        Write-LogDebug $ModuleName  "Running: $([System.IO.Path]::GetFileName($test))"

        $args = @('--export_type=binary', "--excluded_modules=$($session.OpenCppExcludeModules)", '-q')

        if($i -eq $session.AssembliesToTest.Length - 1)
        {
            $args += '--export_type=html:OpenCppOutput'        
        }  

        if(-Not [System.String]::IsNullOrWhiteSpace($previous))
        {
             $args += "--input_coverage=$previous.cov"
        }
   
        $args += "--"
        $args += $test        
   
        Write-LogDebug $ModuleName  "Args: $args $($session.CoverageSession.TestsArguments[$i].Args)"

        &$session.OpenCppCoverage $args $session.CoverageSession.TestsArguments[$i].Args | Out-OpenCppCover
                                         
        $previous = [System.IO.Path]::GetFileNameWithoutExtension($test);                 
    }

    $ErrorActionPreference = 'Stop'             
}

function Run-PublishCoverageResults($session)
{
    $sourcePattern = "OpenCppOutput\\*"

    Compress-Archive -Path $sourcePattern -DestinationPath $session.CoverageZip -Force
    
    Write-Teamcity "publishArtifacts '$($session.CoverageZip)'"   
}