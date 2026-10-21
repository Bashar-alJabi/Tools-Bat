param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
 if($Mode -ne 'Help'){$script:Probe=Require-Dependency 'ffprobe';$script:Magick=Require-Dependency 'magick'}
 Show-LocalTool 'Video Contact Sheet' $PSScriptRoot $Mode 'ffmpeg' 'Create a time-labelled summary image for each video: 12 evenly distributed snapshots, or a custom grid up to 36.'
 $choice=Read-LocalChoice $Mode @('12 frames, 4 columns','Custom frame count and columns')
 $count=12;$columns=4
 if($choice -eq 2){$n=Read-LocalNumber 'Frame count integer 2-36' 2 36;$c=Read-LocalNumber 'Columns integer 1-6' 1 6;if($n -notmatch '^\d+$' -or $c -notmatch '^\d+$'){throw 'Integers required.'};$count=[int]$n;$columns=[int]$c}
 $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.webm','.m4v','.wmv'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.contact-sheet'} {
  param($source,$result)
  $media=(Invoke-Checked $script:Probe @('-v','error','-show_streams','-show_format','-of','json',$source))|ConvertFrom-Json
  $duration=[double]::Parse([string]$media.format.duration,[Globalization.CultureInfo]::InvariantCulture)
  if($duration -le 0 -or $duration -gt 86400 -or -not @($media.streams|Where-Object codec_type -eq 'video').Count){throw 'Need a finite video duration between 0 and 24 hours.'}
  $tiles=@();$rows=@(for($i=0;$i -lt $count;$i++){
   $seconds=$duration*($i+1)/($count+1);$time=$seconds.ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)
   $frame='frame'+$i+'.png';$tile='tile'+$i+'.png';$label=[timespan]::FromSeconds($seconds).ToString('hh\:mm\:ss\.fff')
   # Input seeking decodes only a short GOP even in long videos; precise seeking
   # remains enabled during PNG transcoding. Scratch frames never enter Output.
   Invoke-LocalFF @('-ss',$time,'-i',$source,'-frames:v','1','-vf','scale=320:180:force_original_aspect_ratio=decrease,pad=320:180:(ow-iw)/2:(oh-ih)/2:black',$frame)
   [void](Invoke-Checked $script:Magick @($frame,'-background','black','-gravity','south','-splice','0x26','-font','Arial','-pointsize','16','-fill','white','-annotate','+0+4',$label,$tile));$tiles+=$tile
   [pscustomobject]@{Frame=$i+1;Seconds=$time;Timestamp=$label}
  })
  [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'tiles.txt'),$tiles,(New-Object Text.ASCIIEncoding))
  [void](Invoke-Checked $script:Magick @('montage','@tiles.txt','-tile',($columns.ToString()+'x'),'-geometry','+4+4','-background','#202020','result/contact-sheet.jpg'))
  $rows|Export-Csv -LiteralPath (Join-Path $result 'timestamps.csv') -NoTypeInformation -Encoding UTF8
 } -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
