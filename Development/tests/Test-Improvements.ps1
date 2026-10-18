param([ValidateSet('All','ImagesVideo','AudioPDF','FilesNetwork')][string]$Batch='All',[switch]$Extended,[string]$Only)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
$root=$script:ProjectRoot
$catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
$catalog=@($catalog|Where-Object {$_.PSObject.Properties['Standalone'] -and $_.Standalone})
if($Batch -eq 'ImagesVideo'){$catalog=@($catalog|Where-Object {$_.Path -match '^Tools\\(IMG|VID)\\'})}
if($Batch -eq 'AudioPDF'){$catalog=@($catalog|Where-Object {$_.Path -match '^Tools\\(AUD|PDF)\\'})}
if($Batch -eq 'FilesNetwork'){$catalog=@($catalog|Where-Object {$_.Path -match '^Tools\\(UTI|NET)\\'})}
if($Only){$catalog=@($catalog|Where-Object Name -eq $Only)}
$work=Join-Path $PSScriptRoot ('_work\new-'+[guid]::NewGuid().ToString('N').Substring(0,8))
Ensure-Directory $work
$arabic=-join([char[]]@(0x0639,0x0631,0x0628,0x064A))
$project=Join-Path $work ('p '+$arabic+' & ! %X% [1]')
Ensure-Directory $project
Ensure-Directory (Join-Path $project 'System')
Copy-Item -LiteralPath (Join-Path $root 'System\Shared') -Destination (Join-Path $project 'System\Shared') -Recurse
$fixtures=Join-Path $work 'fixtures';Ensure-Directory $fixtures
$results=New-Object 'Collections.Generic.List[object]'
function Record([string]$Name,[bool]$Passed,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$Passed;Detail=$Detail.Replace($root,'<PROJECT_ROOT>')});Write-Host ($(if($Passed){'PASS '}else{'FAIL '})+$Name+': '+$Detail)}
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Run-Bat([string]$Path,[string]$Arguments='--defaults',[string]$InputText='',[bool]$LocalOnly=$false){
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe'
    $info.Arguments='/d /v:off /s /c ""%TB_TEST_BAT%" '+$Arguments+'"'
    $info.WorkingDirectory=$fixtures;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_TEST_BAT']=$Path;$info.EnvironmentVariables['TB_NO_PAUSE']='1';$info.EnvironmentVariables['TB_LOCAL_ONLY']=$(if($LocalOnly){'1'}else{'0'})
    $info.EnvironmentVariables['PSModulePath']=(Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules')
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try{[void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync();if($InputText){$process.StandardInput.Write($InputText)};$process.StandardInput.Close();if(-not $process.WaitForExit(60000)){$process.Kill();throw 'BAT timed out.'};$process.WaitForExit();[pscustomobject]@{Code=$process.ExitCode;Text=$out.Result+$err.Result}}finally{$process.Dispose()}
}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-of','json',$Path))|ConvertFrom-Json}
function HashTree([string]$Path){@(Get-SafeFiles $Path $null -Recurse|ForEach-Object{(Get-RelativeName $Path $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"}
function Invalid-File([string]$Label,[string]$Extension,[byte[]]$Bytes,[string]$Answers=''){
    $name='invalid-'+[guid]::NewGuid().ToString('N').Substring(0,8)+$Extension
    $path=Join-Path $inputDir $name
    [IO.File]::WriteAllBytes($path,$Bytes)
    $hash=(Get-FileHash -LiteralPath $path).Hash;$savedOutput=$null
    if($tool.Name -eq 'Audio Concatenate'){
        # An existing aggregate result intentionally skips processing. Test the
        # bad clip against a fresh Output, retaining the good prior result safely.
        $savedOutput=Join-Path $fixtures ('aggregate-'+[guid]::NewGuid().ToString('N'))
        Assert ($output.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase) -and $savedOutput.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe test move.'
        [IO.Directory]::Move($output,$savedOutput);Ensure-Directory $output
    }
    try {
        $before=HashTree $output
        $arguments=if($Answers){''}else{'--defaults'}
        $run=Run-Bat $bat $arguments $Answers
        Assert ($run.Code -in @(1,2)) ('Invalid input accepted: '+$run.Text)
        Assert ((HashTree $output) -eq $before) 'Failed processing published or changed output.'
        Assert ((Get-FileHash -LiteralPath $path).Hash -eq $hash) 'Invalid source modified.'
        [IO.File]::Move($path,(Join-Path $fixtures $name))
    } finally {
        if($savedOutput){[IO.Directory]::Move($output,(Join-Path $fixtures ('failed-'+[guid]::NewGuid().ToString('N'))));[IO.Directory]::Move($savedOutput,$output)}
    }
    Record ($tool.Name+' '+$Label) $true 'Rejected; source unchanged, prior results preserved, no partial result published.'
}
try {
    Assert ($catalog.Count -gt 0) 'No tools were selected for this batch.'
    $ffmpeg=Require-Dependency 'ffmpeg';$probe=Require-Dependency 'ffprobe';$magick=Require-Dependency 'magick';$gs=Require-Dependency 'ghostscript'
    $script:NativeWorkingDirectory=$fixtures
    [void](Invoke-Checked $magick @('-size','96x64','xc:red','-fill','blue','-draw','rectangle 48,0 95,63','picture.png'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','testsrc=size=96x64:rate=10:duration=2','-f','lavfi','-i','sine=frequency=440:duration=2','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-shortest','video.mp4'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','sine=frequency=440:duration=2','-ar','44100','-ac','2','audio.wav'))
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=pages.pdf','-c','/Helvetica findfont 16 scalefont setfont 72 720 moveto (Tools Bat page one) show showpage 72 720 moveto (Tools Bat page two) show showpage'))
    foreach($tool in $catalog){
        try {
            $sourceDir=Split-Path (Join-Path $root $tool.Path);$bat=Join-Path $project $tool.Path;$dir=Split-Path $bat
            Ensure-Directory $dir;foreach($name in @('Input','Output')){Ensure-Directory (Join-Path $dir $name);[IO.File]::WriteAllText((Join-Path $dir ($name+'\.gitkeep')),'')}
            foreach($extension in @('.bat','.ps1','.md')){Copy-Item -LiteralPath (Join-Path $sourceDir ($tool.Name+$extension)) -Destination (Join-Path $dir ($tool.Name+$extension))}
            $special=$arabic+' ! %X% & (1) [x]'
            $inputDir=Join-Path $dir 'Input';$output=Join-Path $dir 'Output'
            if($tool.Path -match '^Tools\\IMG\\'){Copy-Item -LiteralPath (Join-Path $fixtures 'picture.png') -Destination (Join-Path $inputDir ($special+'.png'))}
            elseif($tool.Path -match '^Tools\\VID\\'){Copy-Item -LiteralPath (Join-Path $fixtures 'video.mp4') -Destination (Join-Path $inputDir ($special+'.mp4'))}
            elseif($tool.Path -match '^Tools\\AUD\\'){Copy-Item -LiteralPath (Join-Path $fixtures 'audio.wav') -Destination (Join-Path $inputDir ($special+'.wav'));if($tool.Name -eq 'Audio Concatenate'){Copy-Item -LiteralPath (Join-Path $fixtures 'audio.wav') -Destination (Join-Path $inputDir '002.wav')}}
            elseif($tool.Path -match '^Tools\\PDF\\'){Copy-Item -LiteralPath (Join-Path $fixtures 'pages.pdf') -Destination (Join-Path $inputDir ($special+'.pdf'))}
            elseif($tool.Name -eq 'Folder Compare'){
                foreach($side in @('Left','Right')){Ensure-Directory (Join-Path $inputDir $side);[IO.File]::WriteAllText((Join-Path $inputDir ($side+'\same.txt')),'same');[IO.File]::WriteAllText((Join-Path $inputDir ($side+'\different.txt')),$side)}
                [IO.File]::WriteAllText((Join-Path $inputDir 'Left\left.txt'),'left');[IO.File]::WriteAllText((Join-Path $inputDir 'Right\right.txt'),'right')
            }elseif($tool.Name -eq 'JSON Format'){[IO.File]::WriteAllText((Join-Path $inputDir ($special+'.json')),'{"number":123456789012345678901234567890,"array":[true,null,"text\\\"x"],"empty":{}}',(New-Object Text.UTF8Encoding($false)))}
            elseif($tool.Name -eq 'Text Encoding'){[IO.File]::WriteAllText((Join-Path $inputDir ($special+'.txt')),$arabic+"`r`ntext",[Text.Encoding]::Unicode)}
            elseif($tool.Path -match '^Tools\\UTI\\'){[IO.File]::WriteAllText((Join-Path $inputDir ($special+'.txt')),'first');[IO.File]::WriteAllText((Join-Path $inputDir '002.csv'),'second')}
            $before=HashTree $inputDir
            $help=Run-Bat $bat '--help';Assert ($help.Code -eq 0) 'Help failed.'
            $check=Run-Bat $bat '--check';Assert ($check.Code -eq 0) ('Check failed: '+$check.Text)
            $run=Run-Bat $bat;Assert ($run.Code -eq 0 -and $run.Text -match '\[SUCCESS\]') ('Processing failed: '+$run.Text)
            $outputs=@(Get-SafeFiles $output $null -Recurse);Assert ($outputs.Count -gt 0) 'No output produced.'
            $first=$outputs[0].FullName
            if($tool.Path -match '^Tools\\IMG\\'){$nativeCopy=Join-Path $fixtures ('checked'+$outputs[0].Extension);Copy-Item -LiteralPath $first -Destination $nativeCopy -Force;$first=$nativeCopy}
            $script:NativeWorkingDirectory=$fixtures
            switch($tool.Name){
                'Image Rotate' {Assert ((Invoke-Checked $magick @('identify','-format','%wx%h',$first)).Trim() -eq '64x96') 'Rotation dimensions wrong.'}
                'Image Flip' {$pixel=Invoke-Checked $magick @($first,'-format','%[pixel:p{0,0}]','info:');Assert ($pixel -match '255\)|blue|0,0,255') ('Mirror pixel wrong: '+$pixel)}
                'Image Grayscale' {Assert ((Invoke-Checked $magick @('identify','-format','%[colorspace]',$first)) -match 'Gray') 'Grayscale colorspace wrong.'}
                'Image Border' {Assert ((Invoke-Checked $magick @('identify','-format','%wx%h',$first)).Trim() -eq '136x104') 'Border size wrong.'}
                'Image Info' {Assert ((Get-Content -LiteralPath $first -Raw) -match '96x64') 'Image report lacks dimensions.'}
                'Video Trim' {Assert ([double](Probe $first).format.duration -gt 1.8) 'Trim duration wrong.'}
                'Video Rotate' {$stream=(Probe $first).streams|Where-Object codec_type -eq 'video';Assert ($stream.width -eq 64 -and $stream.height -eq 96) 'Video rotation dimensions wrong.'}
                'Video To GIF' {Assert ((Probe $first).streams[0].codec_name -eq 'gif') 'GIF codec wrong.';$count=(Invoke-Checked $probe @('-v','error','-count_frames','-select_streams','v:0','-show_entries','stream=nb_read_frames','-of','default=nw=1:nk=1',$first)).Trim();Assert ([int]$count -gt 1) 'GIF is not animated.'}
                'Video Remux' {$source=(Get-SafeFiles $inputDir @('.mp4')|Select-Object -First 1).FullName;$args=@('-v','error','-i',$source,'-map','0:v:0','-c','copy','-f','md5','-');$a=Invoke-Checked $ffmpeg $args;$args[3]=$first;$b=Invoke-Checked $ffmpeg $args;Assert ($a -eq $b) 'Remux changed encoded video samples.'}
                'Video Frames' {Assert ($outputs.Count -eq 2) 'Expected two PNG frame samples.'}
                'Audio Trim' {Assert ([double](Probe $first).format.duration -gt 1.9) 'Audio trim duration wrong.'}
                'Audio Normalize' {Assert ((Probe $first).streams[0].sample_rate -eq '48000') 'Normalize sample rate wrong.';$a=Invoke-Native $ffmpeg @('-v','info','-i',(Join-Path $fixtures 'audio.wav'),'-af','volumedetect','-f','null','-');$b=Invoke-Native $ffmpeg @('-v','info','-i',$first,'-af','volumedetect','-f','null','-');Assert ($a.Err -match 'mean_volume: (-?[\d.]+) dB') 'No reference volume.';$v=[double]$Matches[1];Assert ($b.Err -match 'mean_volume: (-?[\d.]+) dB') 'No normalized volume.';Assert ([double]$Matches[1] -gt ($v+3)) 'Normalization did not increase this quiet fixture volume.'}
                'Audio Fade' {$a=Invoke-Native $ffmpeg @('-v','info','-i',(Join-Path $fixtures 'audio.wav'),'-t','0.1','-af','volumedetect','-f','null','-');$b=Invoke-Native $ffmpeg @('-v','info','-i',$first,'-t','0.1','-af','volumedetect','-f','null','-');Assert ($a.Err -match 'mean_volume: (-?[\d.]+) dB') 'No reference volume.';$v=[double]$Matches[1];Assert ($b.Err -match 'mean_volume: (-?[\d.]+) dB') 'No faded volume.';Assert ([double]$Matches[1] -lt ($v-6)) 'Fade did not reduce opening volume.'}
                'Audio Channels' {Assert ((Probe $first).streams[0].channels -eq 1) 'Mono conversion failed.'}
                'Audio Concatenate' {Assert ([double](Probe $first).format.duration -gt 3.9) 'Audio concatenation duration wrong.'}
                'PDF Split' {Assert ($outputs.Count -eq 2 -and @($outputs|Where-Object Extension -eq '.pdf').Count -eq 2) 'PDF split pages wrong.'}
                'PDF To Images' {Assert ($outputs.Count -eq 2 -and @($outputs|Where-Object Extension -eq '.png').Count -eq 2) 'PDF rendering pages wrong.'}
                'PDF Text' {$text=Get-Content -LiteralPath $first -Raw;Assert ($text -match 'page one' -and $text -match 'page two') 'PDF text content wrong.'}
                'Rename Copies' {$map=@(Import-Csv -LiteralPath (Join-Path $output 'renamed\rename-map.csv') -Encoding UTF8);Assert ($map.Count -eq 2) 'Rename map wrong.';foreach($row in $map){Assert ((Get-FileHash -LiteralPath (Join-Path $inputDir $row.Original)).Hash -eq (Get-FileHash -LiteralPath (Join-Path $output ('renamed\'+$row.Copy))).Hash) 'Renamed copy differs.'}}
                'Sort Copies' {Assert ([IO.Directory]::Exists((Join-Path $output 'sorted\ext-txt')) -and [IO.Directory]::Exists((Join-Path $output 'sorted\ext-csv'))) 'Sorted folders missing.'}
                'Text Encoding' {Assert ([IO.File]::ReadAllText($first) -eq ($arabic+"`r`ntext")) 'Unicode text changed.';Assert ([IO.File]::ReadAllBytes($first)[0] -ne 239) 'Unexpected UTF-8 BOM.'}
                'Folder Compare' {$rows=Import-Csv -LiteralPath $first;Assert ((@($rows|Select-Object -ExpandProperty Status -Unique)).Count -eq 4) 'Folder comparison states incomplete.'}
                'JSON Format' {$text=[IO.File]::ReadAllText($first);$null=$text|ConvertFrom-Json;Assert ($text -match '123456789012345678901234567890') 'JSON number changed.'}
                'Network Info' {$rows=@(Get-Content -LiteralPath $first -Raw|ConvertFrom-Json);Assert ($rows.Count -gt 0) 'No network adapters reported.'}
                'Ping Host' {$rows=@(Import-Csv -LiteralPath $first);Assert ($rows.Count -eq 4 -and @($rows|Where-Object Status -eq 'Success').Count -gt 0) 'Loopback ping failed.'}
            }
            Assert ((HashTree $inputDir) -eq $before) 'Original files changed.'
            $outBefore=HashTree $output;$repeat=Run-Bat $bat;Assert ($repeat.Code -eq 0 -and (HashTree $output) -eq $outBefore) 'Repeat overwrote output.'
            Record $tool.Name $true 'Real BAT help/check/process/repeat; semantic output checked; moved Arabic/special path; originals unchanged.'
            if($tool.Dependency){$missing=Run-Bat $bat '--check' '' $true;Assert ($missing.Code -ne 0) 'Missing dependency not detected.';Record ($tool.Name+' missing dependency') $true 'Local-only mode refused absent dependency without downloads.'}
            if($Extended){
                $menu=Run-Bat $bat '' "1&whoami`nQ`n"
                Assert ($menu.Code -eq 0 -and $menu.Text -match 'Invalid selection') 'Malformed menu choice not rejected safely.'
                Record ($tool.Name+' menu validation') $true 'Invalid metacharacter input rejected; Q exited without processing.'
                if($tool.Path -match '^Tools\\IMG\\'){
                    Invalid-File 'corrupt image' '.png' ([Text.Encoding]::UTF8.GetBytes('not an image'))
                    if($tool.Name -ne 'Image Info'){
                        $animated=Join-Path $fixtures 'animated.gif'
                        if(-not (Test-Path -LiteralPath $animated)){[void](Invoke-Checked $magick @('-size','10x10','xc:red','-size','10x10','xc:blue','-delay','10','-loop','0',$animated))}
                        Invalid-File 'animation guard' '.gif' ([IO.File]::ReadAllBytes($animated))
                    }
                }elseif($tool.Path -match '^Tools\\VID\\'){Invalid-File 'corrupt video' '.mp4' ([Text.Encoding]::UTF8.GetBytes('not video'))}
                elseif($tool.Path -match '^Tools\\AUD\\'){Invalid-File 'corrupt audio' '.wav' ([Text.Encoding]::UTF8.GetBytes('not audio'))}
                elseif($tool.Path -match '^Tools\\PDF\\'){Invalid-File 'corrupt PDF' '.pdf' ([Text.Encoding]::UTF8.GetBytes('not a PDF'))}
                if($tool.Name -in @('Video Trim','Audio Trim')){
                    $extension=if($tool.Name -eq 'Video Trim'){'.mp4'}else{'.wav'}
                    $fixture=if($extension -eq '.mp4'){'video.mp4'}else{'audio.wav'}
                    Invalid-File 'range beyond end' $extension ([IO.File]::ReadAllBytes((Join-Path $fixtures $fixture))) "2`n1000`n1`n"
                    $customName='custom-'+[guid]::NewGuid().ToString('N').Substring(0,8)+$extension
                    $customInput=Join-Path $inputDir $customName
                    [IO.File]::Copy((Join-Path $fixtures $fixture),$customInput,$false)
                    $run=Run-Bat $bat '' "2`n0.5`n0.5`n"
                    Assert ($run.Code -eq 0) ('Custom trim failed: '+$run.Text)
                    $trimPath=Join-Path $output ($customName+'.trim'+$extension)
                    $seconds=[double](Probe $trimPath).format.duration
                    Assert ($seconds -ge 0.45 -and $seconds -le 0.65) 'Custom trim range was not applied.'
                    Assert ((Get-FileHash -LiteralPath $customInput).Hash -eq (Get-FileHash -LiteralPath (Join-Path $fixtures $fixture)).Hash) 'Custom trim source changed.'
                    [IO.File]::Move($customInput,(Join-Path $fixtures $customName))
                    Record ($tool.Name+' custom range') $true 'Interactive start=0.5/duration=0.5 produced a measured half-second clip; original bytes preserved.'
                }
                if($tool.Name -eq 'Text Encoding'){
                    Invalid-File 'invalid UTF-8' '.txt' ([byte[]]@(192,175))
                    Invalid-File 'UTF-32 guard' '.txt' ([byte[]]@(255,254,0,0,65,0,0,0))
                }
                if($tool.Name -eq 'JSON Format'){
                    foreach($bad in @('{"key":1,}','{"key":01}','{key:1}','{"key":/*comment*/1}','[true false]','{"key":"bad\x"}',(([string][char]160)+'{}'))){Invalid-File 'strict JSON grammar' '.json' ([Text.Encoding]::UTF8.GetBytes($bad))}
                }
                if($tool.Name -eq 'Ping Host'){$bad=Run-Bat $bat '' "2`n127.0.0.1 & whoami`n";Assert ($bad.Code -eq 2) 'Invalid ping target accepted.';Record 'Ping Host target validation' $true 'Shell syntax in a target was refused before any ICMP request.'}
                if($tool.Path -notmatch '^Tools\\NET\\'){
                    $saved=Join-Path $fixtures ('saved-'+$tool.Name);$empty=Join-Path $fixtures ('empty-'+$tool.Name)
                    Assert ($inputDir.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase) -and $saved.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe test folder move.'
                    [IO.Directory]::Move($inputDir,$saved)
                    try{
                        Ensure-Directory $inputDir
                        if($tool.Name -eq 'Folder Compare'){Ensure-Directory (Join-Path $inputDir 'Left');Ensure-Directory (Join-Path $inputDir 'Right')}
                        $run=Run-Bat $bat;Assert ($run.Code -eq 0 -and $run.Text -match 'No supported input') 'Empty Input not handled.'
                    }finally{[IO.Directory]::Move($inputDir,$empty);[IO.Directory]::Move($saved,$inputDir)}
                    Record ($tool.Name+' empty input') $true 'Empty input handled without processing or source loss.'
                }
            }
        }catch{Record $tool.Name $false $_.Exception.Message}
    }
} catch {Record 'Harness' $false $_.Exception.Message}
$summary=[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Batch=$Batch;Windows=[Environment]::OSVersion.Version.ToString();PowerShell=$PSVersionTable.PSVersion.ToString();Results=$results}
$suffix=if($Only){'-'+($Only -replace '[^A-Za-z0-9]','')}else{''}
$summary|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot ('improvements-'+$Batch+$suffix+'-results.json')) -Encoding UTF8
Write-Host ('Passed: '+@($results|Where-Object Passed).Count+'; Failed: '+@($results|Where-Object {-not $_.Passed}).Count)
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
