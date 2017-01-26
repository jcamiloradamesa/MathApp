<# 
    .SYNOPSIS

        Script is used to create generic runner

        creation date: 05/20/2016
        author: alexander.danilov@aurea.com 

#>

function New-Session()
{
    param
    (
        [Parameter(Mandatory)]
        [string] $Runner,
        [Parameter(Mandatory)]
        [string] $CoverageTool,
        $Options
    )

    # import test runner module
    Import-Module -DisableNameChecking -Force $Runner        

    $script:CoverageEnabled = $false

    # import code coverage module
    if($CoverageTool -ne 'None')
    {
        Import-Module -DisableNameChecking -Force "TestRunner-$CoverageTool"
        $script:CoverageEnabled = $true
    }

    $script:Session = @{}

    $script:Session += $Options

    $script:Session | Add-Member -MemberType ScriptMethod -Name Setup -Value {
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        Write-LogNotice "SETUP" "Setting up ..."
        Write-Teamcity "blockOpened name='Setup'"

        # get all assemblies to test
        Get-AssembliesToTest $script:Session

        # call the method exported by the runner
        Setup-Tests $script:Session

        $sw.Stop()

        Write-Teamcity "blockClosed name='Setup'"
        Write-LogNotice "SETUP" "Set up after $($sw.Elapsed)."
    }

    $script:Session | Add-Member -MemberType ScriptMethod -Name Run -Value {
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        Write-LogNotice "RUN" "Running ..."
        Write-Teamcity "blockOpened name='Run'"

        # call the method exported by the runner
        if($script:CoverageEnabled)
        {
            Run-TestsWithCoverage $script:Session
        }
        else
        {
            Run-Tests $script:Session
        }

        $sw.Stop()

        Write-Teamcity "blockClosed name='Run'"
        Write-LogNotice "RUN" "Finished after $($sw.Elapsed)."
    }

    $script:Session | Add-Member -MemberType ScriptMethod -Name PublishTestResults -Value {
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        Write-LogNotice "PUBLISH" "Publishing test results ..."
        Write-Teamcity "blockOpened name='Publishing'"

        # call the method exported by the runner               
        Run-PublishTestResults $script:Session
        
        $sw.Stop()

        Write-Teamcity "blockClosed name='Publishing'"
        Write-LogNotice "PUBLISH" "Finished after $($sw.Elapsed)."
    }

    $script:Session | Add-Member -MemberType ScriptMethod -Name PublishCoverageResults -Value {
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        Write-LogNotice "COVERAGE" "Publishing code coverate results ..."
        Write-Teamcity "blockOpened name='Coverage'"

        # call the method exported by the runner               
        Run-PublishCoverageResults $script:Session
        
        $sw.Stop()

        Write-Teamcity "blockClosed name='Coverage'"
        Write-LogNotice "COVERAGE" "Finished after $($sw.Elapsed)."
    }

    return $script:Session
}

function Get-Session()
{
    return $script:Session
}

function Get-AssembliesToTest($session)
{
   $testAssemblies = Get-TestAssemblies($session) 

   [string[]] $tests = $testAssemblies | ForEach-Object { $_.FullName }      

   Write-LogInfo "RUN" "Found $($tests.Length) tests: "

   $session.AssembliesToTest = $tests
}

Export-ModuleMember -function New-Session
Export-ModuleMember -function Get-Session