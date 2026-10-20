param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'PDF Metadata Cleaner' $PSScriptRoot $Mode 'ghostscript' 'PDF Metadata Cleaner: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$null=Read-LocalChoice $Mode @('Clear Title, Author, Subject, Keywords, Creator; omit Info dates and generated XMP')
$files=@(Get-SafeFiles $script:InputDir @('.pdf'))
Invoke-LocalBatch $files {param($f) $f.Name+'.metadata-cleaned.pdf'} {
 param($source,$result)
 Write-Host '[INFO] Selected descriptive fields only. Producer remains. This is not redaction or a guarantee of anonymity.'
 [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dOmitInfoDate=true','-dOmitXMP=true','-dOmitID=true','-sOutputFile=result.pdf','-f',[IO.Path]::GetFileName($source),'-c','[ /Title () /Author () /Subject () /Keywords () /Creator () /DOCINFO pdfmark'))
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
