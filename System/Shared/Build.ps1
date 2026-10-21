param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive',[string]$Destination,[switch]$IncludeLocalDependencies)
. (Join-Path $PSScriptRoot 'Core.ps1')
. (Join-Path $PSScriptRoot 'Archives.ps1')
try {
    if($Mode -eq 'Help'){Write-Host 'Build a clean folder and ZIP without tests, logs, user inputs or backups. --light / --defaults exclude programs; --portable requires all six local executables and OCR resources. See BUILD_DISTRIBUTION.md.';exit 0}
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
    $edition=if($IncludeLocalDependencies){'portable'}else{'light'}
    if(-not $Destination){$Destination=Join-Path $script:ProjectRoot ('dist\tOOls Bat '+$catalog.Count+' '+$edition+' '+[datetime]::Now.ToString('yyyyMMdd-HHmmss-fff'))}
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
        foreach($name in @('Core.ps1','PDF.ps1','OCR.ps1','Archives.ps1','Download.ps1','Setup.ps1','Check.ps1','Validate.ps1','ToolRunner.ps1','NewTool.ps1','Build.ps1','tools.json','packages.json','ocr-extra-languages.json')){[IO.File]::Copy((Join-Path $PSScriptRoot $name),(Join-Path $shared $name),$false)}
        foreach($name in @('START_HERE.bat','START_HERE.md','BUILD_DISTRIBUTION.bat','BUILD_DISTRIBUTION.md')){[IO.File]::Copy((Join-Path $script:ProjectRoot $name),(Join-Path $stage $name),$false)}
        $seen=@{}
        foreach($tool in $catalog){
            $relative=Split-Path $tool.Path
            if($seen.ContainsKey($relative)){continue};$seen[$relative]=$true
            $source=Join-Path $script:ProjectRoot $relative;$target=Join-Path $stage $relative;Ensure-Directory $target
            foreach($file in (Get-SafeFiles $source @('.bat','.cmd','.ps1','.md'))){[IO.File]::Copy($file.FullName,(Join-Path $target $file.Name),$false)}
            foreach($name in @('Input','Output')){Ensure-Directory (Join-Path $target $name)}
            if(Test-Path -LiteralPath (Join-Path $source 'Watermark')){Ensure-Directory (Join-Path $target 'Watermark')}
            if($tool.Name -in @('Folder Compare','Image Compare','PDF Compare')){Ensure-Directory (Join-Path $target 'Input\Left');Ensure-Directory (Join-Path $target 'Input\Right')}
            if($tool.Name -in @('Video Subtitles Burn','Video Add Subtitle Track')){Ensure-Directory (Join-Path $target 'Input\Subtitles')}
            if($tool.Name -eq 'Audio to Video'){Ensure-Directory (Join-Path $target 'Input\Picture')}
            if($tool.Name -eq 'Document Scanner'){Ensure-Directory (Join-Path $target 'Input\Corners')}
        }
        $docDir=Join-Path $stage 'System\Docs';Ensure-Directory $docDir
        foreach($name in @('DEPENDENCIES.md','DISTRIBUTION.md','PORTABILITY.md')){[IO.File]::Copy((Join-Path $script:ProjectRoot ('System\Docs\'+$name)),(Join-Path $docDir $name),$false)}
        $bin=Join-Path $stage 'System\Bin';Ensure-Directory $bin
        if($IncludeLocalDependencies){
            foreach($required in @('ffmpeg','ffprobe','magick','ghostscript','qpdf','tesseract')){
                if(-not (Get-Dependency $required -LocalOnly)){throw ('Full portable edition requires a compatible LOCAL '+$required+'. No installed fallback or download is used by the builder.')}
            }
            Write-Host '[INFO] Binary inclusion preserves supplied licenses/notices. See System/Docs/PORTABILITY.md for reviewed licenses and remaining redistribution obligations; this is not a public redistribution clearance.'
            foreach($directory in (Get-ChildItem -LiteralPath (Join-Path $script:ProjectRoot 'System\Bin') -Directory)){
                $name=if($directory.Name -ieq 'imagemagick'){'magick'}else{$directory.Name.ToLowerInvariant()}
                if($name -notin @('ffmpeg','magick','ghostscript','qpdf','tesseract')){throw 'Unrecognized local runtime; review its contents and license before including it.'}
                if(-not (Get-Dependency $name -LocalOnly)){throw ('Local runtime is incomplete or incompatible: '+$name)}
                if($name -eq 'tesseract'){
                    . (Join-Path $PSScriptRoot 'OCR.ps1')
                    $configuration=Get-OCRConfiguration;Test-OCRLanguages $configuration 'ara+eng'
                    if('osd' -notin $configuration.Languages -or -not (Test-Path -LiteralPath (Join-Path $configuration.Data 'pdf.ttf'))){throw 'Complete Tesseract resources/models are required for binary inclusion.'}
                }
            }
            $source=Join-Path $script:ProjectRoot 'System\Bin'
            $files=@(Get-SafeFiles $source $null -Recurse)
            if($files.Count){Test-FreeSpace $parent ([long]($files|Measure-Object Length -Sum).Sum*3+16MB)}
            foreach($directory in (Get-SafeDirectories $source)){Ensure-Directory (Join-Path $bin (Get-RelativeName $source $directory.FullName))}
            foreach($file in $files){$target=Join-Path $bin (Get-RelativeName $source $file.FullName);Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($file.FullName,$target,$false)}
        }
        $readme=@(('# tOOls Bat - '+$edition+' distribution'),'','Windows 10/11; Windows PowerShell 5.1. No Administrator required.','',('Tools: '+$catalog.Count),('Edition: '+$edition+'; included local programs: '+[bool]$IncludeLocalDependencies),'- Run START_HERE.bat --check first. The portable edition includes existing local runtime trees; the light edition needs dependency preparation.','- START_HERE.bat --portable offers consented copies of complete installed trees when a local runtime is missing.','- Put source files in the chosen tool Input folder; run its BAT; find results in Output.','- Read the individual MD beside each BAT for menus, examples, limits and errors.','- Existing outputs and original files are preserved.','- Read System/Docs/PORTABILITY.md and DEPENDENCIES.md before transferring or redistributing bundled programs.','- This folder contains no development tests or source backups.','','## Tools','')
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
