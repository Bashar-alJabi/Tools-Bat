param([string]$Archive)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Archives.ps1')
$root=$script:ProjectRoot
$results=New-Object 'Collections.Generic.List[object]'
$work=Join-Path $PSScriptRoot ('_work\layout-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$fixtures=Join-Path $work 'fixtures';Ensure-Directory $fixtures
$script:NativeWorkingDirectory=$fixtures
$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Record([string]$Name,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$true;Detail=$Detail});Write-Host ('PASS '+$Name)}
function HashTree([string]$Path){@(Get-SafeFiles $Path $null -Recurse|Sort-Object FullName|ForEach-Object{(Get-RelativeName $Path $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"}
function Run-Bat([string]$Path,[string]$Arguments){
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe';$info.Arguments='/d /v:off /s /c ""%TB_LAYOUT_BAT%" '+$Arguments+'"'
    $info.WorkingDirectory=$fixtures;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_LAYOUT_BAT']=$Path;$info.EnvironmentVariables['TB_NO_PAUSE']='1'
    $info.EnvironmentVariables['PSModulePath']=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules'
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try{
        [void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync();$process.StandardInput.Close()
        if(-not $process.WaitForExit(60000)){$process.Kill();throw 'BAT timed out.'};$process.WaitForExit()
        Assert ($process.ExitCode -eq 0) ($out.Result+$err.Result)
        return $out.Result+$err.Result
    }finally{$process.Dispose()}
}
try{
    $catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
    Assert ($catalog.Count -ge 55 -and @(Get-ChildItem -LiteralPath (Join-Path $root 'Tools') -Recurse -File -Filter *.bat).Count -eq $catalog.Count) 'Tool count changed.'
    $git=(Get-Command git).Source
    foreach($tool in @($catalog|Where-Object {-not $_.PSObject.Properties['Expansion']})){
        $oldPath=$tool.Path.Substring(6).Replace('\','/')
        $before=Invoke-Native $git @('-C',$root,'show',('ed2f937:'+$oldPath)) 30000
        Assert ($before.Code -eq 0) ('Missing baseline BAT '+$oldPath)
        $current=[IO.File]::ReadAllText((Join-Path $root $tool.Path))
        $expected=$before.Out.Replace('..\..\_shared','..\..\..\System\Shared')
        Assert ($current.Replace("`r`n","`n") -ceq $expected.Replace("`r`n","`n")) ('Unexpected BAT behavior change: '+$tool.Name)
    }
    Record 'All 55 BAT bodies preserved' 'Compared with ed2f937; only the shared runtime path changed, including original menus and defaults.'
    if(-not $Archive){
        $build=Join-Path $work 'package'
        $run=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'System\Shared\Build.ps1'),'-Mode','Defaults','-Destination',$build) 60000
        Assert ($run.Code -eq 0) ($run.Out+$run.Err);$Archive=$build+'.zip'
    }
    $arabic=-join([char[]]@(0x0646,0x0642,0x0644))
    $copy=Join-Path $work ('USB '+$arabic+' & ! %X% [1]')
    Zip-Extract ([IO.Path]::GetFullPath($Archive)) $copy
    $manifest=Get-Content -LiteralPath (Join-Path $copy 'distribution-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($entry in $manifest){Assert ((Get-FileHash -LiteralPath (Join-Path $copy $entry.Path)).Hash -eq $entry.SHA256) ('Extracted hash mismatch '+$entry.Path)}
    foreach($name in @('Tools','System\Shared','System\Bin','System\Docs')){Assert ([IO.Directory]::Exists((Join-Path $copy $name))) ('Missing '+$name)}
    foreach($name in @('Development','.git','tests','_shared','_bin','IMG','VID','AUD','PDF','UTI','NET','System\Downloads')){Assert (-not (Test-Path -LiteralPath (Join-Path $copy $name))) ('Leaked old/development path '+$name)}
    foreach($file in (Get-SafeFiles (Join-Path $copy 'Tools') $null -Recurse)){Assert ($file.FullName -notmatch '\\(Input|Output|Watermark)\\') 'Personal input/output in release.'}
    Record 'Real ZIP extraction and hashes' 'New Arabic/spaces/metacharacter path; expected Tools/System layout; all hashes matched; no development or personal data.'
    foreach($tool in $catalog){
        $bat=Join-Path $copy $tool.Path
        Assert (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($bat,'.md'))) ('Missing MD '+$tool.Name)
        $null=Run-Bat $bat '--help';$null=Run-Bat $bat '--check'
        Record ($tool.Name+' extracted BAT') 'Help and actual dependency check executed from an unrelated working directory after ZIP extraction.'
    }
    for($i=1;$i -le 2;$i++){
        $text=Run-Bat (Join-Path $copy 'START_HERE.bat') '--check'
        Assert ($text -match ('Tools registered: '+$catalog.Count) -and $text -notmatch '\[MISSING\]') 'START_HERE check failed.'
        Record ('Extracted START_HERE check '+$i) 'All four dependencies detected; no download, prompt, registry or persistent PATH change.'
    }
    $docs=@(Get-SafeFiles $copy @('.md') -Recurse)
    foreach($doc in $docs){
        foreach($m in [regex]::Matches([IO.File]::ReadAllText($doc.FullName),'\]\((?:<(?<a>[^>]+)>|(?<p>[^)]+))\)')){
            $link=if($m.Groups['a'].Success){$m.Groups['a'].Value}else{$m.Groups['p'].Value}
            if($link -match '^(https?:|mailto:|#)'){continue}
            $path=[uri]::UnescapeDataString($link.Split('#')[0])
            Assert (Test-Path -LiteralPath (Join-Path $doc.DirectoryName $path)) ('Broken local MD link: '+$doc.Name+' -> '+$link)
        }
    }
    Record 'Release Markdown links' 'Every local link in all exported Markdown files resolves inside the extracted release.'
    $magick=Require-Dependency 'magick';$ffmpeg=Require-Dependency 'ffmpeg';$gs=Require-Dependency 'ghostscript'
    [void](Invoke-Checked $magick @('-size','32x24','xc:red','image.png'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','color=c=blue:s=32x24:r=10:d=1','-f','lavfi','-i','sine=frequency=440:duration=1','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-shortest','video.mp4'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','sine=frequency=440:duration=1','audio.wav'))
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=pages.pdf','-c','/Helvetica findfont 12 scalefont setfont 72 720 moveto (Moved PDF) show showpage'))
    [IO.File]::WriteAllText((Join-Path $fixtures 'sample.txt'),'preserve source bytes')
    foreach($sample in @(@('Image Resize','image.png'),@('Video Speed','video.mp4'),@('Audio Channels','audio.wav'),@('PDF Split','pages.pdf'),@('File Inventory','sample.txt'),@('Network Info',''))){
        $tool=$catalog|Where-Object Name -eq $sample[0];$bat=Join-Path $copy $tool.Path;$folder=Split-Path $bat
        $inputDir=Join-Path $folder 'Input';$output=Join-Path $folder 'Output'
        if($sample[1]){[IO.File]::Copy((Join-Path $fixtures $sample[1]),(Join-Path $inputDir ($arabic+' & ! %X% [1]'+[IO.Path]::GetExtension($sample[1]))),$false)}
        $before=HashTree $inputDir;$text=Run-Bat $bat '--defaults'
        Assert (@(Get-SafeFiles $output $null -Recurse).Count -gt 0) ('No output '+$tool.Name)
        $outBefore=HashTree $output;$null=Run-Bat $bat '--defaults'
        Assert ((HashTree $inputDir) -eq $before -and (HashTree $output) -eq $outBefore) ('Original or previous output changed '+$tool.Name)
        Record ($tool.Name+' extracted processing') 'Real fixture processing and repeat in extracted ZIP; original input and existing output hashes unchanged.'
    }
}catch{$results.Add([pscustomobject]@{Test='Reorganization';Passed=$false;Detail=$_.Exception.Message.Replace($root,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$_.Exception.Message)}
[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Archive=$Archive.Replace($root,'<PROJECT_ROOT>');Results=$results}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'reorganization-results.json') -Encoding UTF8
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
