param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive',[string]$Destination,[switch]$IncludeLocalDependencies)
. (Join-Path $PSScriptRoot 'Core.ps1')
. (Join-Path $PSScriptRoot 'Archives.ps1')
try {
    if($Mode -eq 'Help'){Write-Host 'Build a clean folder and ZIP without tests, logs, user inputs or backups. See BUILD_DISTRIBUTION.md. --defaults excludes local program binaries.';exit 0}
    $catalog=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($tool in $catalog){$bat=Join-Path $script:ProjectRoot $tool.Path;if(-not (Test-Path -LiteralPath $bat) -or -not (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($bat,'.md')))){throw ('Missing BAT/manual: '+$tool.Name)}}
    if($Mode -eq 'Check'){Write-Host ('[OK] '+$catalog.Count+' tools with individual manuals.');exit 0}
    if($Mode -eq 'Interactive'){
        Write-Host "`n============================================================"
        Write-Host '                BUILD CLEAN DISTRIBUTION'
        Write-Host '============================================================'
        Write-Host 'Original inputs and tracked test backups remain untouched.'
        Write-Host 'Including System\Bin copies only complete local distributions already in this project. Review their redistribution licenses.'
        $choice=Read-LocalChoice $Mode @('Tools and START_HERE (no program binaries)','Tools plus existing local System\Bin distributions')
        $IncludeLocalDependencies=$choice -eq 2
    }
    if(-not $Destination){$Destination=Join-Path $script:ProjectRoot ('dist\tOOls Bat '+[datetime]::Now.ToString('yyyyMMdd-HHmmss-fff'))}
    $Destination=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
    $zipDestination=$Destination+'.zip'
    if(Test-Path -LiteralPath $Destination){throw 'Choose a NEW output folder. Existing distributions are preserved.'}
    if(Test-Path -LiteralPath $zipDestination){throw 'The distribution ZIP already exists; choose a new destination.'}
    $parent=[IO.Path]::GetDirectoryName($Destination)
    $ancestor=$parent
    while($ancestor){if((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked destination folders are not accepted.'};$ancestor=[IO.Path]::GetDirectoryName($ancestor)}
    Ensure-Directory $parent
    $work=New-WorkDirectory $parent
    try {
        $stage=Join-Path $work 'package';Ensure-Directory $stage
        $shared=Join-Path $stage 'System\Shared';Ensure-Directory $shared
        foreach($name in @('Core.ps1','Archives.ps1','Download.ps1','Setup.ps1','Check.ps1','Validate.ps1','ToolRunner.ps1','NewTool.ps1','Build.ps1','tools.json','packages.json')){[IO.File]::Copy((Join-Path $PSScriptRoot $name),(Join-Path $shared $name),$false)}
        foreach($name in @('START_HERE.bat','START_HERE.md','BUILD_DISTRIBUTION.bat','BUILD_DISTRIBUTION.md')){[IO.File]::Copy((Join-Path $script:ProjectRoot $name),(Join-Path $stage $name),$false)}
        $seen=@{}
        foreach($tool in $catalog){
            $relative=Split-Path $tool.Path
            if($seen.ContainsKey($relative)){continue};$seen[$relative]=$true
            $source=Join-Path $script:ProjectRoot $relative;$target=Join-Path $stage $relative;Ensure-Directory $target
            foreach($file in (Get-SafeFiles $source @('.bat','.cmd','.ps1','.md'))){[IO.File]::Copy($file.FullName,(Join-Path $target $file.Name),$false)}
            foreach($name in @('Input','Output')){Ensure-Directory (Join-Path $target $name)}
            if(Test-Path -LiteralPath (Join-Path $source 'Watermark')){Ensure-Directory (Join-Path $target 'Watermark')}
            if($tool.Name -in @('Folder Compare','Image Compare')){Ensure-Directory (Join-Path $target 'Input\Left');Ensure-Directory (Join-Path $target 'Input\Right')}
            if($tool.Name -in @('Video Subtitles Burn','Video Add Subtitle Track')){Ensure-Directory (Join-Path $target 'Input\Subtitles')}
        }
        $docDir=Join-Path $stage 'System\Docs';Ensure-Directory $docDir
        foreach($name in @('DEPENDENCIES.md','DISTRIBUTION.md')){[IO.File]::Copy((Join-Path $script:ProjectRoot ('System\Docs\'+$name)),(Join-Path $docDir $name),$false)}
        $bin=Join-Path $stage 'System\Bin';Ensure-Directory $bin
        if($IncludeLocalDependencies){
            $source=Join-Path $script:ProjectRoot 'System\Bin'
            $files=@(Get-SafeFiles $source $null -Recurse)
            if($files.Count){Test-FreeSpace $parent ([long]($files|Measure-Object Length -Sum).Sum*3+16MB)}
            foreach($directory in (Get-SafeDirectories $source)){Ensure-Directory (Join-Path $bin (Get-RelativeName $source $directory.FullName))}
            foreach($file in $files){$target=Join-Path $bin (Get-RelativeName $source $file.FullName);Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($file.FullName,$target,$false)}
        }
        $readme=@('# tOOls Bat - Portable distribution','','Windows 10/11; Windows PowerShell 5.1. No Administrator required.','',('Tools: '+$catalog.Count),'- Run START_HERE.bat to check and prepare only the programs you need.','- START_HERE.bat --portable offers consented copies of already installed full program trees.','- Put source files in the chosen tool Input folder; run its BAT; find results in Output.','- Read the individual MD beside each BAT for menus, examples, limits and errors.','- Existing outputs and original files are preserved.','- Read System/Docs/DEPENDENCIES.md before redistributing bundled programs.','- This folder contains no development tests or source backups.','','## Tools','')
        foreach($tool in $catalog){$readme+='- ['+$tool.Name+'](<'+([IO.Path]::ChangeExtension($tool.Path,'.md').Replace('\','/'))+'>)'}
        [IO.File]::WriteAllLines((Join-Path $stage 'README.md'),$readme,(New-Object Text.UTF8Encoding($true)))
        $manifest=@(Get-SafeFiles $stage $null -Recurse|ForEach-Object{[pscustomobject]@{Path=(Get-RelativeName $stage $_.FullName);Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
        ConvertTo-Json -InputObject $manifest -Depth 4|Set-Content -LiteralPath (Join-Path $stage 'distribution-manifest.json') -Encoding UTF8
        $zip=Join-Path $work 'package.zip'
        Zip-Create @(Get-SafeFiles $stage $null -Recurse) $stage $zip
        [IO.Directory]::Move($stage,$Destination)
        [IO.File]::Move($zip,$zipDestination)
        Write-Host ('[SUCCESS] Folder: '+$Destination);Write-Host ('[SUCCESS] ZIP: '+$zipDestination)
        Write-Host ('Tools: '+$catalog.Count+'; manifest entries: '+$manifest.Count+'; no download or system installation performed.')
    }finally{Remove-WorkDirectory $work $parent}
    exit 0
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
