<#
    .SYNOPSIS
        This module provides command lets for working with ZIP archives.

#>

Import-Module TestRunner-Log

function Invoke-InstrumentAssemblies()
{
    <#
        .SYNOPSIS
            Instruments c++ assemblies.
    #>
    param
    (
        [Parameter(Mandatory, Position=0)]
        [string] $dllsPath,     

        [Parameter(Position=1)]
        [string] $VSInstrExcludeList
    )
         
    $vsinstrPath =  Join-Path $session.VSToolsPath 'vsinstr.exe'    
          
    If (Test-Path $vsinstrPath)
    {
        Write-LogNotice 'SETUP' "Instrumenting c++ DLLs in $dllsPath."
        
        $foldersToInstrument = @($dllsPath)
        
        $assembliesToInstrument = @()

        $foldersToInstrument | Foreach-object {
            $currentFolder = $_
            
            # get dll list
            Get-ChildItem -path $currentFolder -Filter *.dll -Recurse | Foreach-object{

                if ((Get-IsManagedAssembly($_.FullName)))
                {
                    # exclude managed dlls
                    return;
                }

                $pdbName = $_ -replace ".dll$", '.pdb'
                
                $pdbPath = Join-Path $currentFolder $pdbName
                
                If (Test-Path $pdbPath)
                {
                    $assembliesToInstrument += Join-Path $currentFolder $_ 
                }
            }
            
            # get executables list
            Get-ChildItem -path $currentFolder -Filter *.exe -Recurse | Foreach-object{ 
                
                if ((Get-IsManagedAssembly($_.FullName)))
                {
                    # exclude managed executables
                    return;
                }
                
                $pdbName = $_ -replace ".exe$", '.pdb'
                
                $pdbPath = Join-Path $currentFolder $pdbName
                
                If (Test-Path $pdbPath)
                {
                    $assembliesToInstrument += Join-Path $currentFolder $_ 
                }            
            }
        }
        
        Write-Teamcity "blockOpened name='VSInstr'"

        $VSInstrExcludeArgs = ''

        $VSInstrExcludeList -split ',' | ForEach-Object {
            if(-Not ([string]::IsNullOrWhiteSpace($_)))
            {
                $VSInstrExcludeArgs += "/exclude:$($_) "
            }
        }

        $assembliesToInstrument | Foreach-object {
            $assemblyName = $_
            
            Write-LogNotice 'SETUP' "Instrumenting $assemblyName"
            
            Try
            {                
                Invoke-SimpleProcess -FileName $vsinstrPath -Arguments "$assemblyName /coverage $VSInstrExcludeArgs" -CreateNoWindow                                
            }
            Catch [Exception]
            {
                $errorMessage = $_.Exception.Message
                Write-LogError 'SETUP' "Error instrumenting '$assemblyName': $errorMessage"
            }
        }

        Write-Teamcity "blockClosed name='VSInstr'"
        Write-LogNotice 'SETUP' 'DLLs instrumented.'
    }
    else
    {
        Write-LogWarning 'SETUP' "vsinstr.exe not found at '$vsinstrPath'."
    }
}

function Start-Profiler()
{
    <#
        .SYNOPSIS
            Starts profiling c++ assemblies.
    #>
    
    param
    (
        [Parameter(Position=0)]
        [string] $coverageOutput        
    )    
    
    $vsperfcmdPath = Join-Path $session.VSToolsPath 'vsperfcmd.exe'

    If (Test-Path $vsperfcmdPath)
    {
        # starting monitoring
        Write-LogNotice 'SETUP' 'Start monitoring c++ DLLs'
        
        if(-Not (Test-Path($coverageOutput)))
        {
            Write-LogNotice 'SETUP' "Creating folder for coverage reports '$coverageOutput'"
            New-Item -Path $coverageOutput -ItemType Directory | Out-Null
        }

        $cppCoverageFile = Join-Path $coverageOutput 'CppCoverage.coverage'
        
        # shutdown profiler if it is running already
        Try
        {
            & $vsperfcmdPath /shutdown | Out-Null
        }
        Catch [Exception]
        {
        }

        $fileArg = '/output:"{0}"' -f $cppCoverageFile
        
        Invoke-SimpleProcess -FileName $vsperfcmdPath -Arguments "/start:coverage /CS $fileArg" -DoNotWaitForExit -CreateNoWindow
                
        start-sleep -s 2
    }
    else
    {
        Write-LogWarning 'SETUP' "vsperfcmd.exe not found at '$vsperfcmdPath'."
    }
}

function Stop-Profiler()
{
    <#
        .SYNOPSIS
            Stops profiling c++ assemblies.
    #>       
   
    $vsperfcmdPath = Join-Path $session.VSToolsPath 'vsperfcmd.exe'

    If (Test-Path $vsperfcmdPath)
    {
        # collecting code coverage of c++ dlls
        Write-LogNotice 'RUN' 'Stop monitoring c++ DLLs'
        
        & $vsperfcmdPath /shutdown | Out-Null     
    }
}

function Out-VSInstr()
{
    param(
        [Parameter(ValueFromPipeline)] $whatever
    )
    process
    {
        Write-LogDebug 'VSInstr' $whatever
    }
}

function Invoke-SimpleProcess
{
    param
    (
        [Parameter(Mandatory)]
        [string] $FileName,

        [string] $Arguments,

        [switch] $CreateNoWindow,
        
        [switch] $DoNotWaitForExit
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $FileName
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $CreateNoWindow    
    $pinfo.Arguments = $Arguments
    
                
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo
    $process.Start() | Out-Null
    
    if(-Not $DoNotWaitForExit)
    {
      $process.WaitForExit()
      
      $stderr = $process.StandardError.ReadToEnd()             
    
      if($process.ExitCode -ne 0)   
      {
          throw $stderr
      }  
    }                          
}

function Get-IsManagedAssembly
{
    param
    (
      [Parameter(Mandatory)]
      [string] $assembly
    )
    
    if(-Not (Test-Path($session.Dumpbin)))
    {
        throw "Dumpbin utility not found at $($session.Dumpbin)"
    }
    
    $dumpBinResult = &$session.Dumpbin '/dependents' $assembly | Out-String
            
    $isManaged = $dumpBinResult.ToLowerInvariant().Contains('mscoree.dll');
    
    return $isManaged       
}

Export-ModuleMember -function Invoke-InstrumentAssemblies
Export-ModuleMember -function Start-Profiler
Export-ModuleMember -function Stop-Profiler
Export-ModuleMember -function Invoke-SimpleProcess
Export-ModuleMember -function Get-IsManagedAssembly