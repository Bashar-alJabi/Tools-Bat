param([switch]$CheckOnly,[switch]$MakePortable)
. (Join-Path $PSScriptRoot 'Core.ps1')
. (Join-Path $PSScriptRoot 'Archives.ps1')
. (Join-Path $PSScriptRoot 'Download.ps1')
. (Join-Path $PSScriptRoot 'OCR.ps1')
function Show-Dependencies {
    $missing=New-Object 'Collections.Generic.List[string]'
    foreach ($name in @('ffmpeg','ffprobe','magick','ghostscript','qpdf','tesseract')) {
        $dependency=Get-Dependency $name
        if ($dependency) {
            Write-Host ('[OK] {0} | {1} | {2}' -f $name,$(if($dependency.Local){'project local'}else{'system'}),$dependency.Path); Write-Host ('     ' + $dependency.Version)
            if($name -eq 'ffmpeg' -and @($script:ToolCatalog|Where-Object Name -eq 'Video Subtitles Burn').Count){
                $filters=Invoke-Native $dependency.Path @('-hide_banner','-filters') 15000
                if($filters.Code -ne 0 -or $filters.Out -notmatch '\bsubtitles\s'){
                    Write-Host '[MISSING CAPABILITY] Video Subtitles Burn needs an FFmpeg build with subtitles/libass. Other FFmpeg tools may still work.'
                    $missing.Add('ffmpeg')
                }else{Write-Host '     subtitles/libass filter: available; Arabic rendering still depends on fonts.'}
            }
        }
        else { Write-Host ('[MISSING] ' + $name); $missing.Add($name) }
        $users=@($script:ToolCatalog | Where-Object {$_.Dependency -eq $name -or ($_.PSObject.Properties['AdditionalDependencies'] -and $name -in $_.AdditionalDependencies)} | ForEach-Object Name)
        if($users.Count){Write-Host ('     Used by: ' + ($users -join ', '))}
    }
    try {
        $ocr=Get-OCRConfiguration
        foreach($language in @('ara','eng','osd')){
            if($language -notin $ocr.Languages){Write-Host ('[MISSING] Tesseract language '+$language+'; affects PDF OCR / Image OCR, orientation detection needs osd.');$missing.Add('tessdata-'+$language)}
            elseif($language -ne 'osd'){
                try{Test-OCRLanguages $ocr $language;Write-Host ('[OK] Tesseract language '+$language+' initialized.')}
                catch{Write-Host ('[INCOMPATIBLE] Tesseract language '+$language);$missing.Add('tessdata-'+$language)}
            }else{
                $test=Invoke-TesseractData $ocr.Engine.Path $ocr.Data @('-l','osd','--oem','0','--print-parameters')
                if($test.Code -ne 0 -or $test.Err -match 'Failed loading|Error opening data'){Write-Host '[INCOMPATIBLE] osd model.';$missing.Add('tessdata-osd')}else{Write-Host '[OK] osd model initialized; orientation quality depends on page content.'}
            }
        }
        Write-Host ('     Installed models: '+($ocr.Languages -join ', '))
        if(-not (Test-Path -LiteralPath (Join-Path $ocr.Data 'pdf.ttf'))){Write-Host '[MISSING] pdf.ttf resource; PDF OCR cannot produce its text layer.';if('tesseract' -notin $missing){$missing.Add('tesseract')}}
    }catch{Write-Host ('[MISSING] OCR configuration: '+$_.Exception.Message);foreach($language in @('ara','eng','osd')){$missing.Add('tessdata-'+$language)}}
    return ,$missing
}
try {
    if ([Environment]::OSVersion.Version.Major -lt 10 -or $PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Windows 10/11 and Windows PowerShell 5.1 are required.' }
    $architecture=if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    Write-Host "`n============================================================"
    Write-Host '                     tOOls Bat - START HERE'
    Write-Host "============================================================"
    Write-Host ('Project: ' + $script:ProjectRoot)
    Write-Host ('Windows: ' + [Environment]::OSVersion.Version + ' | Architecture: ' + $architecture)
    Write-Host ('PowerShell: ' + $PSVersionTable.PSVersion)
    Write-Host 'Administrator is not required. No PATH, Registry or Windows settings are changed.'
    $packages=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packages.json') -Raw | ConvertFrom-Json
    $script:ToolCatalog=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host ('Tools registered: '+$script:ToolCatalog.Count)
    if(-not (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\tar.exe'))){Write-Host '[MANUAL] Windows tar.exe is unavailable; the verified ImageMagick 7z archive will need manual extraction.'}
    if($MakePortable -and -not $CheckOnly){
        foreach($name in @('ffmpeg','magick','ghostscript','qpdf','tesseract')){
            $dependency=Get-Dependency $name
            if(-not $dependency -or $dependency.Local){continue}
            Write-Host ("`nInstalled: "+$dependency.Path)
            Write-Host 'Copy the complete installation tree into this project for offline use. Preserve and review its license and source obligations.'
            $answer=Read-Host 'Prepare this installed program as a local copy? [Y/N; default N]'
            if($answer -match '^[Yy]$'){try{Copy-InstalledDependency $dependency $script:ProjectRoot}catch{Write-Host ('[FAILED] '+$_.Exception.Message)}}
        }
    }
    do {
        $missing=Show-Dependencies
        if ($CheckOnly) { if ($missing.Count) { exit 3 }; exit 0 }
        if (-not $missing.Count) { Write-Host '[SUCCESS] All project requirements are available.' }
        else {
            Write-Host 'Only choose packages for the tools you intend to use. Offline/manual setup is supported.'
            foreach ($package in $packages) {
                $needsLocalOCR=$package.Id -eq 'tesseract' -and @($missing|Where-Object {$_ -like 'tessdata-*'}).Count -gt 0 -and -not (Get-Dependency tesseract -LocalOnly)
                if ($package.Id -notin $missing -and -not ($package.Id -eq 'ffmpeg' -and 'ffprobe' -in $missing) -and -not $needsLocalOCR) { continue }
                if ($architecture -ne $package.Arch) { Write-Host ('[MANUAL] No automatic package for ' + $package.Name + ' on ' + $architecture + '. See System\Docs\DEPENDENCIES.md.'); continue }
                Write-Host ("`n{0}, fixed version {1}, approximately {2} MB" -f $package.Name,$package.Version,$package.ApproxMB)
                Write-Host ('Source : ' + $package.Source)
                Write-Host ('File   : ' + $package.Url)
                Write-Host ('License: ' + $package.License)
                if($package.Kind -eq 'nsis-portable'){Write-Host 'This consent includes the named pinned 7-Zip helper EXE files (~2.2 MB) used ONLY to extract complete runtime files. No installer is executed.';foreach($helper in $package.Extractors){Write-Host ('Helper: '+$helper.Url+' | SHA-256 '+$helper.SHA256)}}
                $answer=Read-Host 'Download this package? [Y/N; default N]'
                if ($answer -cne 'Y' -and $answer -cne 'y') { continue }
                try { Install-PortablePackage $package $script:ProjectRoot }
                catch { Write-Host ('[FAILED] ' + $_.Exception.Message); Write-Host 'Previous setup was preserved. Check disk space, permissions and internet access, then retry.' }
            }
        }
        Write-Host "`nAfter setup: open the relevant BAT, place files in its Input folder, select options. Results are in Output."
        Write-Host 'README.md lists all tools and defaults. Every BAT supports --help and --check.'
        Write-Host 'For offline transfer: START_HERE.bat --portable can copy a complete detected installation after your consent, then BUILD_DISTRIBUTION.bat can include System\Bin.'
        $missing=Show-Dependencies
        $extra=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ocr-extra-languages.json') -Raw -Encoding UTF8|ConvertFrom-Json
        Write-Host ('Optional extra OCR models: '+(($extra|ForEach-Object Code) -join ', ')+'. No extra model is downloaded automatically.')
        $code=Read-Host 'Optional model code to download, or Enter to skip'
        if($code){
            $model=$extra|Where-Object Code -ceq $code
            if(-not $model){Write-Host '[INFO] Unknown optional code; install a trusted model manually if needed.'}
            else{
                Write-Host ($model.Code+' | '+$model.Bytes+' bytes | '+$model.Url)
                Write-Host ('Integrity anchor: pinned official Git blob SHA-1 '+$model.GitBlobSHA1+'. No upstream SHA-256 manifest for this optional file; baseline ara/eng/osd have pinned SHA-256.')
                if((Read-Host 'Download this optional model? [Y/N; default N]') -match '^[Yy]$'){try{Install-OptionalOCRLanguage $model $script:ProjectRoot}catch{Write-Host ('[FAILED] '+$_.Exception.Message)}}
            }
        }
        $again=Read-Host 'Recheck / retry missing packages? [Y/N; default N]'
    } while ($again -match '^[Yy]$')
    if ($missing.Count) { Write-Host '[INFO] Setup is partial. Tools whose requirements are present can be used.'; exit 3 }
    exit 0
} catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 2 }
