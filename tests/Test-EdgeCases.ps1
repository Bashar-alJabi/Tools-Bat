. (Join-Path $PSScriptRoot '..\_shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\_shared\Archives.ps1')
. (Join-Path $PSScriptRoot '..\_shared\Download.ps1')
$sourceRoot=$script:ProjectRoot
$last=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'results.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$fixtures=Join-Path $last.Sandbox 'fixtures'
$script:NativeWorkingDirectory=$fixtures
$edgeRoot=New-WorkDirectory (Join-Path $PSScriptRoot '_sandbox')
$results=New-Object 'Collections.Generic.List[object]'
function Edge([string]$Name,[scriptblock]$Test) {
    try{& $Test; $results.Add([pscustomobject]@{Test=$Name;Passed=$true;Detail='Expected behavior verified.'}); Write-Host ('PASS '+$Name)}
    catch{$results.Add([pscustomobject]@{Test=$Name;Passed=$false;Detail=$_.Exception.Message}); Write-Host ('FAIL '+$Name+': '+$_.Exception.Message)}
}
function Require([bool]$Condition,[string]$Text){if(-not $Condition){throw $Text}}
function Run-EdgeTool([string]$Name,[string]$Directory){
    Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $sourceRoot '_shared\ToolRunner.ps1'),'-Tool',$Name,'-ToolDir',$Directory,'-Defaults') 60000
}
try {
    Edge 'Unsupported input ignored' {
        $dir=Join-Path $edgeRoot 'unsupported'; Ensure-Directory (Join-Path $dir 'Input')
        [IO.File]::WriteAllText((Join-Path $dir 'Input\unsupported.txt'),'ordinary text')
        $run=Run-EdgeTool 'Image Resize' $dir
        Require ($run.Code -eq 0 -and $run.Out -match 'No supported input') ($run.Out+$run.Err)
        Require (@(Get-SafeFiles (Join-Path $dir 'Output') $null -Recurse).Count -eq 0) 'Unexpected output.'
    }
    Edge 'Long path rejected safely' {
        $dir=Join-Path $edgeRoot 'long'; $inputDir=Join-Path $dir 'Input'; Ensure-Directory $inputDir
        $name=('x' * (242-$inputDir.Length-1-4))+'.png'
        $path=Join-Path $inputDir $name
        Copy-Item -LiteralPath (Join-Path $fixtures 'image.png') -Destination $path
        $before=(Get-FileHash -LiteralPath $path).Hash; $run=Run-EdgeTool 'Image Resize' $dir
        Require ($run.Code -eq 1 -and $run.Out -match '240') ($run.Out+$run.Err)
        Require ((Get-FileHash -LiteralPath $path).Hash -eq $before) 'Long-path input changed.'
    }
    Edge 'Unwritable output shape handled' {
        $dir=Join-Path $edgeRoot 'blocked'; Ensure-Directory (Join-Path $dir 'Input')
        Copy-Item -LiteralPath (Join-Path $fixtures 'image.png') -Destination (Join-Path $dir 'Input\image.png')
        [IO.File]::WriteAllText((Join-Path $dir 'Output'),'existing user file')
        $run=Run-EdgeTool 'Image Resize' $dir
        Require ($run.Code -eq 2) ($run.Out+$run.Err)
        Require ([IO.File]::ReadAllText((Join-Path $dir 'Output')) -eq 'existing user file') 'Existing output-path file changed.'
    }
    Edge 'Missing input directory handled' {
        $dir=Join-Path $edgeRoot 'empty'; Ensure-Directory $dir
        $run=Run-EdgeTool 'Image Resize' $dir
        Require ($run.Code -eq 0 -and [IO.Directory]::Exists((Join-Path $dir 'Input'))) ($run.Out+$run.Err)
    }
    Edge 'Invalid local executable falls back to system' {
        $dir=Join-Path $edgeRoot 'invalid-local'; Ensure-Directory (Join-Path $dir '_bin\ffmpeg'); Copy-Item -LiteralPath (Join-Path $sourceRoot '_shared') -Destination (Join-Path $dir '_shared') -Recurse
        [IO.File]::WriteAllText((Join-Path $dir '_bin\ffmpeg\ffmpeg.exe'),'not an executable')
        $run=Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $dir '_shared\Check.ps1'),'-Name','ffmpeg') 30000
        Require ($run.Code -eq 0 -and $run.Out -notmatch 'invalid-local\\_bin') ($run.Out+$run.Err)
    }
    Edge 'Cached corrupt archive preserved and rejected' {
        $dir=Join-Path $edgeRoot 'corrupt-cache'; Ensure-Directory (Join-Path $dir '_downloads')
        $cached=Join-Path $dir '_downloads\fixture.zip'; [IO.File]::WriteAllText($cached,'existing bad cache')
        $hash=(Get-FileHash -LiteralPath $cached).Hash
        $package=[pscustomobject]@{Id='fixture';Folder='fixture';Version='1.0';Name='fixture';Url='https://www.gyan.dev/fixture.zip';HashUrl='';SHA256=('0'*64);ApproxMB=1;Kind='zip'}
        $rejected=$false;try{Install-PortablePackage $package $dir {throw 'Unexpected network request'}}catch{$rejected=$true}
        Require ($rejected -and (Get-FileHash -LiteralPath $cached).Hash -eq $hash) 'Existing cache was replaced.'
    }
    Edge 'ZIP symlink rejected' {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zipPath=Join-Path $edgeRoot 'symlink.zip'; $archive=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
        $entry=$archive.CreateEntry('link'); $entry.ExternalAttributes=0xA0000000
        $writer=New-Object IO.StreamWriter($entry.Open()); $writer.Write('../outside'); $writer.Dispose(); $archive.Dispose()
        $rejected=$false;try{Zip-Extract $zipPath (Join-Path $edgeRoot 'symlink-out')}catch{$rejected=$true}
        Require $rejected 'ZIP link accepted.'
    }
    Edge 'Metadata comment removed' {
        $magick=Require-Dependency 'magick'
        $dir=Join-Path $edgeRoot 'metadata'; Ensure-Directory (Join-Path $dir 'Input')
        [void](Invoke-Checked $magick @('image.jpg','-set','comment','toolsbat-private','private.jpg'))
        Copy-Item -LiteralPath (Join-Path $fixtures 'private.jpg') -Destination (Join-Path $dir 'Input\private.jpg')
        $before=(Invoke-Checked $magick @('identify','-format','%c','private.jpg')).Trim()
        Require ($before -eq 'toolsbat-private') 'Fixture did not contain metadata.'
        $run=Run-EdgeTool 'Image Metadata Cleaner' $dir; Require ($run.Code -eq 0) ($run.Out+$run.Err)
        Copy-Item -LiteralPath (Join-Path $dir 'Output\private.jpg') -Destination (Join-Path $fixtures 'clean-inspect.jpg')
        $after=(Invoke-Checked $magick @('identify','-format','%c','clean-inspect.jpg')).Trim()
        Require (-not $after) 'Metadata was not stripped.'
    }
    Edge 'MP4 stream removal and MP3 extraction' {
        $probe=Require-Dependency 'ffprobe'
        foreach($tool in @('Remove Audio','Extract Audio')){
            $dir=Join-Path $edgeRoot ($tool.Replace(' ','')); Ensure-Directory (Join-Path $dir 'Input')
            Copy-Item -LiteralPath (Join-Path $fixtures 'video.mp4') -Destination (Join-Path $dir 'Input\video.mp4')
            $run=Run-EdgeTool $tool $dir; Require ($run.Code -eq 0) ($run.Out+$run.Err)
            $out=@(Get-SafeFiles (Join-Path $dir 'Output') $null)[0]
            $data=(Invoke-Checked $probe @('-v','error','-show_streams','-of','json',$out.FullName)) | ConvertFrom-Json
            if($tool -eq 'Remove Audio'){Require (@($data.streams | Where-Object codec_type -eq 'audio').Count -eq 0) 'Audio still present.'}
            else{Require ($data.streams[0].codec_name -eq 'mp3') 'Wrong extraction codec.'}
        }
    }
} finally {
    [pscustomobject]@{DateUTC=[DateTime]::UtcNow.ToString('o');Results=@($results.ToArray())} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'edge-results.json') -Encoding UTF8
    Remove-WorkDirectory $edgeRoot (Join-Path $PSScriptRoot '_sandbox')
}
if(@($results|Where-Object{-not $_.Passed}).Count){exit 1};exit 0
