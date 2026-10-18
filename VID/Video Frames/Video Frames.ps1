param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Video Frames' $PSScriptRoot $Mode 'ffmpeg' 'Export evenly spaced PNG frames into a new folder; maximum 1000 frames.'
    $choice=Read-LocalChoice $Mode @('One frame each second','One frame each 5 seconds','One frame each 10 seconds')
    $fps=@('1','1/5','1/10')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.m4v','.webm'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.frames'} {
        param($source,$result)
        # image2 treats percent signs anywhere in a full path as sequence syntax.
        # The process already runs in our work folder, so keep its pattern relative.
        Invoke-LocalFF @('-i',$source,'-map','0:v:0','-vf',('fps='+$fps),'-frames:v','1000','-an','result\frame-%06d.png')
    } -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
