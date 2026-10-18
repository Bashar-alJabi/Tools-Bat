param(
    [Parameter(Mandatory=$true)][string]$Tool,
    [Parameter(Mandatory=$true)][string]$ToolDir,
    [switch]$Defaults,
    [string]$SettingsFile
)
. (Join-Path $PSScriptRoot 'Core.ps1')
. (Join-Path $PSScriptRoot 'Archives.ps1')
$script:ReportNativeProgress=$true
$imageExt = @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif')
$videoExt = @('.mp4','.mov','.mkv','.avi','.m4v','.webm')
$audioExt = @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')
$script:Options = @{}
$script:OptionTools = @{
    FORMAT=@('Image Convert','Audio Converter'); QUALITY=@('Image Convert','Image Compression')
    WIDTH=@('Image Resize','Video Resolution Converter'); HEIGHT=@('Image Resize','Video Resolution Converter')
    RATIO=@('Image Crop'); SHARPEN=@('Image Enhance'); COLOR=@('Background Color Remover'); FUZZ=@('Background Color Remover')
    TYPE=@('Image Watermark'); COUNT=@('Image Watermark'); SIZE=@('Image Watermark'); OPACITY=@('Image Watermark'); ROTATION=@('Image Watermark'); WATERMARK_TEXT=@('Image Watermark')
    MODE=@('Compress Video'); CRF=@('Compress Video'); AUDIO_BITRATE=@('Compress Video'); FPS=@('Video FPS Converter'); SPEED=@('Video Speed')
    VOLUME=@('Increase Volume'); AUDIO_VOLUME=@('Merge Audio'); PRESET=@('Compress PDF'); COLUMNS=@('Image Contact Sheet'); LABEL=@('Video Resolution Converter')
}
if ($SettingsFile) {
    $settings = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($property in $settings.PSObject.Properties) { $script:Options[$property.Name] = [string]$property.Value }
}
function Option([string]$Name,[string]$Fallback,[string]$Pattern) {
    $value = $Fallback
    $relevant = ($script:OptionTools.ContainsKey($Name) -and $Tool -in $script:OptionTools[$Name]) -or ($Name -match '^GRAVITY[1-9]$' -and $Tool -eq 'Image Watermark')
    if ($relevant -and -not $Defaults -and [Environment]::GetEnvironmentVariable($Name)) { $value = [Environment]::GetEnvironmentVariable($Name) }
    if ($script:Options.ContainsKey($Name)) { $value = $script:Options[$Name] }
    if ($Pattern -and $value -notmatch $Pattern) { throw "Invalid setting: $Name" }
    $value
}
function Number([string]$Name,[int]$Fallback,[int]$Min,[int]$Max) {
    $value = Option $Name ([string]$Fallback) '^\d{1,8}$'
    if ([long]$value -lt $Min -or [long]$value -gt $Max) { throw "Out-of-range setting: $Name" }
    [int]$value
}
function IM([string[]]$Arguments) { [void](Invoke-Checked $script:Engine $Arguments) }
function FF([string[]]$Arguments) { [void](Invoke-Checked $script:Engine (@('-hide_banner','-loglevel','error','-nostdin','-n') + $Arguments)) }
function Get-Media([string]$Path) {
    $probe = Require-Dependency 'ffprobe'
    (Invoke-Checked $probe @('-v','error','-show_format','-show_streams','-of','json',$Path)) | ConvertFrom-Json
}
function Write-CSV([object[]]$Rows,[string]$Path,[string[]]$Headers) {
    if ($Rows.Count) { $Rows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8 }
    else { ('"' + ($Headers -join '","') + '"') | Set-Content -LiteralPath $Path -Encoding UTF8 }
}
function Run-Image([IO.FileInfo]$File,[string]$Result) {
    # Work with literal ASCII aliases: ImageMagick interprets brackets and percent
    # signs as filename syntax even when shell quoting is correct.
    $source = 'source' + $File.Extension
    Copy-Item -LiteralPath $File.FullName -Destination (Join-Path $script:Work $source)
    $frames = Invoke-Checked $script:Engine @('identify','-format','%n\n',$source)
    $frameCount = [int](($frames.Trim() -split '\s+')[0])
    if ($frameCount -gt 1 -and [IO.Path]::GetExtension($Result) -notin @('.gif','.tiff','.tif','.webp')) { throw 'Multiple frames/pages need GIF, WebP or TIFF output; split them separately first.' }
    $args = @($source)
    switch ($Tool) {
        'Image Convert' {
            if ($script:Format -eq 'jpg') { $args += @('-background','white','-alpha','remove','-alpha','off') }
            if ($script:Format -in @('jpg','webp','avif')) { $args += @('-quality',[string]$script:Quality) }
        }
        'Image Compression' {
            $args += '-strip'
            switch ($File.Extension.ToLowerInvariant()) {
                '.png' { $args += @('-define','png:compression-level=9') }
                { $_ -in @('.tif','.tiff') } { $args += @('-compress','Zip') }
                default { $args += @('-quality',[string]$script:Quality) }
            }
        }
        'Image Resize' { $args += @('-resize',("{0}x{1}>" -f $script:Width,$script:Height)) }
        'Image Crop' { $args += @('-gravity','center','-crop',($script:Ratio + '!'),'+repage') }
        'Image Enhance' { $args += @('-auto-orient','-filter','Lanczos','-resize','200%','-unsharp',$script:Sharpen) }
        'Image Metadata Cleaner' { $args += '-strip' }
        'Background Color Remover' { $args += @('-alpha','on','-fuzz',$script:Fuzz,'-transparent',$script:Color) }
        'Image Watermark' {
            if ($frameCount -gt 1) { throw 'Watermark currently requires a single-frame image.' }
            $args += '-auto-orient'
            IM ($args + @('work.png'))
            if ($script:Type -eq '1') {
                $text = Option 'WATERMARK_TEXT' 'Copyright' '^[^\x00-\x1f%\[\]@]{1,300}$'
                IM @('-background','none','-fill','white','-font','Arial','-pointsize',([string]$script:Size),'-gravity','center',('label:' + $text),'-trim','+repage','mark.png')
            } else {
                $logo = @(Get-SafeFiles (Join-Path $ToolDir 'Watermark') $imageExt)
                if ($logo.Count -ne 1) { throw 'Keep exactly ONE image in the Watermark folder.' }
                Copy-Item -LiteralPath $logo[0].FullName -Destination (Join-Path $script:Work ('logo' + $logo[0].Extension))
                $w = [int](Invoke-Checked $script:Engine @('identify','-format','%w','work.png')).Trim()
                $logoWidth = [Math]::Max(1,[int]($w * $script:Size / 100))
                IM @(('logo' + $logo[0].Extension),'-resize',($logoWidth.ToString() + 'x'),'mark.png')
            }
            $alpha = ($script:Opacity / 100.0).ToString('0.00',[Globalization.CultureInfo]::InvariantCulture)
            IM @('mark.png','-alpha','set','-channel','A','-evaluate','multiply',$alpha,'+channel','-background','none','-rotate',$script:Rotation,'+repage','mark-ready.png')
            $args = @('work.png')
            for ($i=1; $i -le $script:Count; $i++) {
                $gravity = Option ('GRAVITY' + $i) 'southeast' '^(northwest|north|northeast|west|center|east|southwest|south|southeast)$'
                $args += @('mark-ready.png','-gravity',$gravity,'-geometry','+30+30','-composite')
            }
        }
    }
    IM ($args + @($Result))
}
function Run-Video([IO.FileInfo]$File,[string]$Result) {
    $args = @('-i',$File.FullName,'-map','0:v:0','-map','0:a?')
    $audio = @('-c:a','aac','-b:a','192k')
    $encode = @('-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p')
    switch ($Tool) {
        'Compress Video' {
            $codec = if ($script:Mode -eq 'H.265') { 'libx265' } else { 'libx264' }
            $hardware = if ($script:Mode -eq 'H.265') { 'hevc_nvenc' } else { 'h264_nvenc' }
            # An advertised encoder is not proof of a working GPU/driver.
            try { $test = Invoke-Native $script:Engine @('-v','error','-nostdin','-f','lavfi','-i','color=size=64x64:rate=1','-frames:v','1','-c:v',$hardware,'-f','null','-') 15000 }
            catch { $test=[pscustomobject]@{Code=1} }
            if ($test.Code -eq 0) {
                try { FF ($args + @('-c:v',$hardware,'-cq',$script:Crf,'-preset','p5','-pix_fmt','yuv420p','-c:a','aac','-b:a',$script:AudioBitrate,'-movflags','+faststart',$Result)); return }
                catch { Write-Host '[INFO] GPU encode failed; retrying on CPU.'; if (Test-Path -LiteralPath (Join-Path $script:Work $Result)) { Remove-Item -LiteralPath (Join-Path $script:Work $Result) -Force } }
            }
            Write-Host ('[INFO] CPU encoder: ' + $codec)
            $encode = @('-c:v',$codec,'-preset','medium','-crf',$script:Crf,'-pix_fmt','yuv420p')
            $audio = @('-c:a','aac','-b:a',$script:AudioBitrate)
        }
        'Video FPS Converter' { $args += @('-vf',('fps=' + $script:Fps)) }
        'Video Resolution Converter' { $args += @('-vf',("scale={0}:{1}:force_original_aspect_ratio=decrease:force_divisible_by=2" -f $script:Width,$script:Height),'-sws_flags','lanczos'); $encode[5]='16'; $audio[3]='128k' }
        'Video Speed' { $args += @('-vf',('setpts=PTS/' + $script:Speed),'-af',('atempo=' + $script:Speed)) }
        'Remove Audio' { FF @('-i',$File.FullName,'-map','0:v:0','-an','-c:v','copy',$Result); return }
        'Extract Audio' { FF @('-i',$File.FullName,'-map','0:a:0','-vn','-c:a','libmp3lame','-q:a','2',$Result); return }
        'Convert Audio' { $args = @('-i',$File.FullName,'-map','0:v:0','-map','0:a:0'); $encode = @('-c:v','copy') }
        'Normalize Audio' { $args = @('-i',$File.FullName,'-map','0:v:0','-map','0:a:0','-af','loudnorm'); $encode = @('-c:v','copy') }
        'Increase Volume' { $args = @('-i',$File.FullName,'-map','0:v:0','-map','0:a:0','-af',('volume=' + $script:Volume)); $encode = @('-c:v','copy') }
        'Replace Audio' { FF @('-i',$File.FullName,'-i',$script:AddedAudio.FullName,'-map','0:v:0','-map','1:a:0','-c:v','copy','-c:a','aac','-b:a','192k','-movflags','+faststart','-shortest',$Result); return }
        'Merge Audio' { FF @('-i',$File.FullName,'-i',$script:AddedAudio.FullName,'-filter_complex',("[1:a:0]volume={0}[added];[0:a:0][added]amix=inputs=2:duration=first:dropout_transition=2[aout]" -f $script:AddedVolume),'-map','0:v:0','-map','[aout]','-c:v','copy','-c:a','aac','-b:a','192k','-movflags','+faststart','-shortest',$Result); return }
        'Video Thumbnail' { FF @('-i',$File.FullName,'-map','0:v:0','-frames:v','1','-an',$Result); return }
    }
    FF ($args + $encode + $audio + @('-map_metadata','0','-movflags','+faststart',$Result))
}

$work = $null
try {
    $ToolDir = [IO.Path]::GetFullPath($ToolDir).TrimEnd('\')
    $inputDir = Join-Path $ToolDir 'Input'
    $outputDir = Join-Path $ToolDir 'Output'
    Ensure-Directory $inputDir
    Ensure-Directory $outputDir
    $images = @('Image Convert','Image Compression','Image Resize','Image Crop','Image Enhance','Image Metadata Cleaner','Background Color Remover','Image Watermark','Image Contact Sheet')
    $videos = @('Compress Video','Video FPS Converter','Video Resolution Converter','Video Speed','Remove Audio','Extract Audio','Convert Audio','Normalize Audio','Increase Volume','Replace Audio','Merge Audio','Video Thumbnail')
    $utilities = @('File Hashes','Duplicate Finder','File Inventory','ZIP Backup','ZIP Extract')
    $ext = $null
    if ($Tool -in $images) { $script:Engine = Require-Dependency 'magick'; $ext = $imageExt }
    elseif ($Tool -in $videos -or $Tool -eq 'Audio Converter') { $script:Engine = Require-Dependency 'ffmpeg'; $ext = if ($Tool -eq 'Audio Converter') { $audioExt } else { $videoExt } }
    elseif ($Tool -in @('Compress PDF','Merge PDF')) { $script:Engine = Require-Dependency 'ghostscript'; $ext = @('.pdf') }
    elseif ($Tool -eq 'Media Info') { $script:Engine = Require-Dependency 'ffprobe'; $ext = $videoExt + $audioExt }
    elseif ($Tool -notin $utilities) { throw 'Unknown tool.' }
    if($Tool -eq 'Image Compression'){$ext=@('.jpg','.jpeg','.png','.webp','.tif','.tiff','.avif')}
    $files = @(Get-SafeFiles $inputDir $ext -Recurse:($Tool -in $utilities -and $Tool -ne 'ZIP Extract'))
    if ($Tool -eq 'ZIP Extract') { $files = @(Get-SafeFiles $inputDir @('.zip')) }
    if (-not $files.Count) { Write-Host '[INFO] No supported input files. Add files to Input and run again.'; exit 0 }
    $script:Format = 'jpg'
    if ($Tool -eq 'Image Convert') { $script:Format = Option 'FORMAT' 'jpg' '^(jpg|png|webp|tiff|bmp|gif|avif)$' }
    if ($Tool -eq 'Audio Converter') { $script:Format = Option 'FORMAT' 'mp3' '^(mp3|wav|flac|m4a|opus)$' }
    $script:Quality = Number 'QUALITY' 85 1 100
    $script:Width = Number 'WIDTH' 1920 1 32768
    $script:Height = Number 'HEIGHT' 1080 1 32768
    $script:Ratio = Option 'RATIO' '1:1' '^(1:1|4:5|16:9|9:16)$'
    $script:Sharpen = Option 'SHARPEN' '0x1.2+1+0.05' '^0x(0\.8\+0\.8\+0\.03|1\.2\+1\+0\.05|1\.6\+1\+0\.08)$'
    $script:Color = Option 'COLOR' 'white' '^(#[a-fA-F0-9]{6}|[a-zA-Z]{1,30})$'
    $script:Fuzz = (Option 'FUZZ' '10%' '^\d{1,3}(\.\d{1,2})?%?$').TrimEnd('%')
    if ([double]::Parse($script:Fuzz,[Globalization.CultureInfo]::InvariantCulture) -gt 100) { throw 'Fuzz must be 0-100%.' }
    $script:Fuzz += '%'
    $script:Type = Option 'TYPE' '1' '^[12]$'
    $script:Count = Number 'COUNT' 1 1 9
    $script:Size = Number 'SIZE' 64 1 2000
    if ($Tool -eq 'Image Watermark' -and $script:Type -eq '2' -and $script:Size -gt 100) { throw 'Logo size must be 1-100%.' }
    $script:Opacity = Number 'OPACITY' 60 10 100
    $script:Rotation = Option 'ROTATION' '0' '^(-8|0|8)$'
    $script:Mode = Option 'MODE' 'H.264' '^H\.(264|265)$'
    $script:Crf = [string](Number 'CRF' 23 0 51)
    $script:AudioBitrate = Option 'AUDIO_BITRATE' '128k' '^(128k|160k|192k)$'
    $script:Fps = Option 'FPS' '30' '^(24|25|30|50|60)$'
    $script:Speed = Option 'SPEED' '1.5' '^(0\.5|0\.75|1\.25|1\.5|2)$'
    $script:Volume = Option 'VOLUME' '6dB' '^(3|6|9|12)dB$'
    $script:AddedVolume = Option 'AUDIO_VOLUME' '0.50' '^0\.(25|50|75)$'
    $preset = Option 'PRESET' '/ebook' '^/(screen|ebook|printer|prepress|default)$'
    $columns = Number 'COLUMNS' 4 3 5
    if ($Tool -in @('Replace Audio','Merge Audio')) {
        $added = @(Get-SafeFiles $inputDir $audioExt)
        if ($files.Count -ne 1 -or $added.Count -ne 1) { throw 'Keep exactly ONE video and ONE audio file in Input. Ambiguous input is not selected automatically.' }
        $script:AddedAudio = $added[0]
    }
    Write-Host "`n============================================================"
    Write-Host ('                    ' + $Tool.ToUpperInvariant())
    Write-Host "============================================================"
    Write-Host ('Input : ' + $inputDir)
    Write-Host ('Output: ' + $outputDir)
    [int]$success=0; [int]$failed=0; [int]$skipped=0
    $aggregate = $Tool -in @('Image Contact Sheet','Merge PDF','File Hashes','Duplicate Finder','File Inventory','ZIP Backup')
    $items = if ($aggregate) { @(,$files) } else { $files }
    foreach ($item in $items) {
        $work = $null
        try {
            $file = if ($aggregate) { $files[0] } else { $item }
            $outName = $file.Name
            switch ($Tool) {
                'Image Convert' { $outName = $file.BaseName + '.' + $script:Format }
                'Background Color Remover' { $outName = $file.BaseName + '.png' }
                'Image Contact Sheet' { $outName = 'contact-sheet.png' }
                'Compress Video' { $outName = $file.BaseName + '.mp4' }
                'Video FPS Converter' { $outName = $file.BaseName + '_' + $script:Fps + 'fps.mp4' }
                'Video Resolution Converter' { $label = Option 'LABEL' '1080p' '^(4K|1080p|720p|480p)$'; $outName = $file.BaseName + '_' + $label + '.mp4' }
                'Video Speed' { $outName = $file.BaseName + '_' + $script:Speed + 'x.mp4' }
                { $_ -in @('Remove Audio','Convert Audio','Normalize Audio','Increase Volume') } { $outName = $file.BaseName + '.mp4' }
                'Extract Audio' { $outName = $file.BaseName + '.mp3' }
                'Replace Audio' { $outName = 'replaced.mp4' }
                'Merge Audio' { $outName = 'merged.mp4' }
                'Video Thumbnail' { $outName = $file.BaseName + '.png' }
                'Merge PDF' { $outName = 'merged.pdf' }
                'Audio Converter' { $outName = $file.BaseName + '.' + $script:Format }
                'Media Info' { $outName = $file.Name + '.json' }
                'File Hashes' { $outName = 'hashes.csv' }
                'Duplicate Finder' { $outName = 'duplicates.csv' }
                'File Inventory' { $outName = 'inventory.csv' }
                'ZIP Backup' { $outName = 'backup.zip' }
                'ZIP Extract' { $outName = $file.Name + '.extracted' }
            }
            $destination = Join-Path $outputDir $outName
            if (Test-Path -LiteralPath $destination) { Write-Host ('[SKIPPED] ' + $outName + ' already exists.'); $skipped++; continue }
            if ($file.FullName.Length -gt 240 -or $destination.Length -gt 240) { throw 'Path exceeds the supported limit (240 characters). Move the project/input to a shorter path.' }
            Write-Host ('Processing: ' + $(if ($aggregate) { "$($files.Count) files" } else { $file.Name }))
            [long]$inputSize = if ($aggregate) { ($files | Measure-Object Length -Sum).Sum } else { $file.Length }
            Test-FreeSpace $outputDir ([Math]::Max(16MB,$inputSize * 3))
            $work = New-WorkDirectory $outputDir
            $script:Work = $work
            $script:NativeWorkingDirectory = $work
            $result = 'result' + [IO.Path]::GetExtension($outName)
            $resultPath = Join-Path $work $result
            if ($Tool -in $images -and $Tool -ne 'Image Contact Sheet') { Run-Image $file $result }
            elseif ($Tool -in $videos) { Run-Video $file $result }
            else {
                switch ($Tool) {
                    'Image Contact Sheet' {
                        $thumbs = @(); $i=0
                        foreach ($picture in $files) {
                            $i++; $alias = 'image' + $i + $picture.Extension; $thumb = 'thumb' + $i + '.png'
                            Copy-Item -LiteralPath $picture.FullName -Destination (Join-Path $work $alias)
                            $literalLabel = ' ' + $picture.Name.Replace('%','%%')
                            IM @('(',($alias + '[0]'),'-thumbnail','300x300',')','-background','white','-fill','black','-font','Arial','-pointsize','16','-gravity','center','-splice','0x30','-gravity','south','-annotate','+0+0',$literalLabel,$thumb)
                            $thumbs += $thumb
                        }
                        # ASCII response list avoids cmd's 8191-character limit and OEM encodings.
                        [IO.File]::WriteAllLines((Join-Path $work 'thumbs.txt'),$thumbs,(New-Object Text.UTF8Encoding($false)))
                        IM @('montage','@thumbs.txt','-tile',($columns.ToString() + 'x'),'-geometry','300x330+20+15','-background','white',$result)
                    }
                    { $_ -in @('Compress PDF','Merge PDF') } {
                        $pdfArgs = @('-dSAFER','-sDEVICE=pdfwrite','-dCompatibilityLevel=1.4','-dNOPAUSE','-dQUIET','-dBATCH',('-sOutputFile=' + $result))
                        if ($Tool -eq 'Compress PDF') { $pdfArgs += '-dPDFSETTINGS=' + $preset }
                        $pdfs = if ($Tool -eq 'Merge PDF') { $files } else { @($file) }
                        $i=0; $response = @()
                        foreach ($pdf in $pdfs) { $i++; $alias='document' + $i + '.pdf'; Copy-Item -LiteralPath $pdf.FullName -Destination (Join-Path $work $alias); $response += $alias }
                        [IO.File]::WriteAllLines((Join-Path $work 'pdfs.txt'),$response,(New-Object Text.ASCIIEncoding))
                        [void](Invoke-Checked $script:Engine ($pdfArgs + '@pdfs.txt'))
                    }
                    'Audio Converter' {
                        $encoding = switch ($script:Format) { 'mp3' { @('-c:a','libmp3lame','-q:a','2') }; 'wav' { @('-c:a','pcm_s16le') }; 'flac' { @('-c:a','flac') }; 'm4a' { @('-c:a','aac','-b:a','192k') }; 'opus' { @('-c:a','libopus','-b:a','128k') } }
                        FF (@('-i',$file.FullName,'-map','0:a:0','-vn') + $encoding + @($result))
                    }
                    'Media Info' { [IO.File]::WriteAllText($resultPath,(Invoke-Checked $script:Engine @('-v','error','-show_format','-show_streams','-of','json',$file.FullName)),(New-Object Text.UTF8Encoding($false))) }
                    'File Hashes' {
                        $rows = @(foreach ($entry in $files) { [pscustomobject]@{ Path=(Get-RelativeName $inputDir $entry.FullName); Bytes=$entry.Length; SHA256=(Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash } })
                        Write-CSV $rows $resultPath @('Path','Bytes','SHA256')
                    }
                    'Duplicate Finder' {
                        $rows = @(); $groupId=0
                        foreach ($sizeGroup in ($files | Group-Object Length | Where-Object Count -gt 1)) {
                            $hashes = foreach ($entry in $sizeGroup.Group) { [pscustomobject]@{ Path=(Get-RelativeName $inputDir $entry.FullName); Bytes=$entry.Length; SHA256=(Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash } }
                            foreach ($hashGroup in ($hashes | Group-Object SHA256 | Where-Object Count -gt 1)) { $groupId++; foreach ($row in $hashGroup.Group) { $rows += [pscustomobject]@{ Group=$groupId; Path=$row.Path; Bytes=$row.Bytes; SHA256=$row.SHA256 } } }
                        }
                        Write-CSV $rows $resultPath @('Group','Path','Bytes','SHA256')
                    }
                    'File Inventory' {
                        $rows = @(foreach ($entry in $files) { [pscustomobject]@{ Path=(Get-RelativeName $inputDir $entry.FullName); Extension=$entry.Extension; Bytes=$entry.Length; ModifiedUTC=$entry.LastWriteTimeUtc.ToString('o') } })
                        Write-CSV $rows $resultPath @('Path','Extension','Bytes','ModifiedUTC')
                    }
                    'ZIP Backup' { Zip-Create $files $inputDir $resultPath }
                    'ZIP Extract' { $resultPath=Join-Path $work 'unpacked'; Zip-Extract $file.FullName $resultPath }
                }
            }
            if ($Tool -eq 'ZIP Extract') { [IO.Directory]::Move($resultPath,$destination) }
            else { Publish-File $resultPath $destination }
            Write-Host ('[SUCCESS] ' + $outName)
            if ($Tool -eq 'Compress Video') { $size=(Get-Item -LiteralPath $destination).Length; Write-Host ('Original: {0:N2} MB; Output: {1:N2} MB; Saved: {2:N2} MB' -f ($file.Length/1MB),($size/1MB),(($file.Length-$size)/1MB)) }
            $success++
        } catch { Write-Host ('[FAILED] ' + $_.Exception.Message); $failed++ }
        finally { if ($work) { Remove-WorkDirectory $work $outputDir }; $work=$null }
    }
    Write-Host "`n============================================================"
    Write-Host '                         SUMMARY'
    Write-Host "============================================================"
    Write-Host "Total: $($files.Count)  Successful: $success  Failed: $failed  Skipped: $skipped"
    if ($failed) { exit 1 }
    exit 0
} catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 2 }
