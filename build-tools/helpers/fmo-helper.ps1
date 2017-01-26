[CmdletBinding(SupportsShouldProcess)]
param
(         
    [string] $PathToSources = './'
)

$files = @('build_vcx.cmd','build_cs.cmd')
$oldMSBuild = '%systemroot%\Microsoft.NET\Framework\v4.0.30319\'
$oldMSBuild2 = '%systemroot%\Microsoft.NET\Framework64\v4.0.30319\'
$newMSBuild = '"%programfiles(x86)%"\MSBuild\14.0\Bin\'

function ReplaceMSBuild
{
    param
    (
        [string] $file,
        [string] $oldValue,
        [string] $newValue
    )

    $content = Get-Content $file    
    $content = $content.Replace($oldValue, $newValue);
    [System.IO.File]::WriteAllLines($file, $content)    
}

$files | ForEach-Object {
	$file = Join-Path $PathToSources $_
    ReplaceMSBuild $file $oldMSBuild $newMSBuild
	ReplaceMSBuild $file $oldMSBuild2 $newMSBuild
}