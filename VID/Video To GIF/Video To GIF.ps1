param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Video To GIF' $PSScriptRoot $Mode 'ffmpeg' 'Create a silent looping GIF from the first 5 or 10 seconds.'
    $choice=Read-LocalChoice $Mode @('5 seconds, 480 pixels, 10 FPS','10 seconds, 640 pixels, 15 FPS')
    $duration=@('5','10')[$choice-1];$width=@('480','640')[$choice-1];$fps=@('10','15')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.m4v','.webm'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.gif'} {
        param($source,$result)
        $filter='[0:v:0]fps='+$fps+',scale='+$width+':-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse[out]'
        Invoke-LocalFF @('-t',$duration,'-i',$source,'-filter_complex',$filter,'-map','[out]','-an','-loop','0',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
