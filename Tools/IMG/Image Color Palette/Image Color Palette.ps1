param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Color Palette' $PSScriptRoot $Mode 'magick' 'Image Color Palette: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('8 representative colors','16 colors','4 colors')
$count=@('8','16','4')[$choice-1]
$files=@(Get-SafeFiles $script:InputDir $imageExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.palette'} {
 param($source,$result)
 $alias=[IO.Path]::GetFileName($source);$frames=Invoke-Checked $script:Engine @('identify','-format','%n ',$alias)
 if([int]($frames.Trim().Split(' ')[0]) -ne 1){throw 'Single-frame images only.'}
 $hist=Invoke-Checked $script:Engine @($alias,'-background','white','-alpha','remove','-colorspace','sRGB','-colors',$count,'-depth','8','-format','%c','histogram:info:-')
 $rows=@(@(foreach($line in ($hist -split '[\r\n]+')){if($line -match '^\s*(\d+):.*(#[0-9A-Fa-f]{6})\b'){[pscustomobject]@{Pixels=[long]$Matches[1];RGB=$Matches[2]}}})|Sort-Object Pixels -Descending)
 if(-not $rows.Count){throw 'No RGB palette was produced.'}
 $rows|Export-Csv -LiteralPath (Join-Path $result 'colors.csv') -NoTypeInformation -Encoding UTF8
 $args=@();foreach($row in $rows){$args+=@('-size','80x80',('xc:'+$row.RGB))}
 [void](Invoke-Checked $script:Engine ($args+@('+append','result/swatches.png')))
} -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
