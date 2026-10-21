# Dot-source after Core.ps1 and Archives.ps1. Tests can inject a local fetcher.
function Receive-HTTPS([string]$Url,[string]$Destination) {
    $uri=[uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -notin @('www.gyan.dev','github.com','raw.githubusercontent.com')) { throw 'Unapproved download source.' }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $oldProgress=$ProgressPreference
    try {
        $ProgressPreference='SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $Destination -TimeoutSec 60 -MaximumRedirection 5 -Headers @{'User-Agent'='ToolsBat-Setup/1'}
    } finally { $ProgressPreference=$oldProgress }
}
function Confirm-PackageHash([string]$Path,[string]$Expected) {
    if ($Expected -notmatch '^[A-Fa-f0-9]{64}$') { throw 'A valid SHA-256 checksum is required.' }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw 'SHA-256 mismatch. The file will NOT be extracted or executed.' }
}
function Install-PortablePackage($Package,[string]$Root,[scriptblock]$Fetcher={ param($url,$path) Receive-HTTPS $url $path }) {
    # Consent belongs to Setup.ps1; this function only handles the selected item.
    $cache=Join-Path $Root 'System\Downloads'
    $bin=Join-Path $Root 'System\Bin'
    Ensure-Directory $cache; Ensure-Directory $bin
    $destination=Join-Path $bin $Package.Folder
    $filename=[IO.Path]::GetFileName(([uri]$Package.Url).AbsolutePath)
    $download=Join-Path $cache $filename
    $work=$null
    try {
        if($Package.Kind -eq 'traineddata' -and -not (Test-Path -LiteralPath (Join-Path $bin 'Tesseract\tesseract.exe') -PathType Leaf)){throw 'Prepare the complete local Tesseract package first, then approve languages. No language download started.'}
        $work=New-WorkDirectory $cache
        $hash=[string]$Package.SHA256
        if (-not $hash) {
            $hashPath=Join-Path $work 'expected.sha256'
            & $Fetcher $Package.HashUrl $hashPath
            $hashText=[IO.File]::ReadAllText($hashPath).Trim()
            if ($hashText -notmatch '^([a-fA-F0-9]{64})(?:\s|$)') { throw 'Publisher checksum is missing or invalid.' }
            $hash=$Matches[1]
        }
        if (Test-Path -LiteralPath $download) { Confirm-PackageHash $download $hash; Write-Host '[OK] Reusing verified cached package.' }
        else {
            Test-FreeSpace $cache ([long]$Package.ApproxMB * 1MB * 6)
            $partial=Join-Path $work 'download.partial'
            & $Fetcher $Package.Url $partial
            Confirm-PackageHash $partial $hash
            [IO.File]::Move($partial,$download)
        }
        if($Package.Kind -eq 'traineddata'){
            $data=Join-Path $bin 'Tesseract\tessdata';Ensure-Directory $data
            $target=Join-Path $data $filename
            if(Test-Path -LiteralPath $target){Confirm-PackageHash $target $hash;Write-Host '[OK] Language already prepared.';return}
            [IO.File]::Copy($download,$target,$false);Confirm-PackageHash $target $hash
            Write-Host ('[SUCCESS] Language prepared: '+$filename);return
        }
        if ($Package.Kind -eq 'installer') {
            Write-Host ('[MANUAL] Verified installer saved: ' + $download)
            Write-Host 'No installer was run. Install it yourself only if desired, or supply a complete licensed local Ghostscript tree.'
            return
        }
        Test-FreeSpace $cache ([long]$Package.ApproxMB * 1MB * 6)
        if (Test-Path -LiteralPath $destination) { throw "Existing local folder preserved: $destination . Rename it manually if it is broken, then retry." }
        $stage=Join-Path $work 'unpacked'
        if($Package.Kind -eq 'nsis-portable'){
            # The selected Tesseract package consent includes these named, pinned
            # extraction helpers. The Tesseract/7-Zip installers are NEVER run.
            foreach($helper in $Package.Extractors){
                $helperPath=Join-Path $work $helper.Name
                & $Fetcher $helper.Url $helperPath;Confirm-PackageHash $helperPath $helper.SHA256
            }
            $helperDirectory=Join-Path $work '7zip'
            [void](Invoke-Checked (Join-Path $work '7zr.exe') @('x',(Join-Path $work '7zip.exe'),('-o'+$helperDirectory),'-y'))
            $seven=Join-Path $helperDirectory '7z.exe'
            if(-not (Test-Path -LiteralPath $seven -PathType Leaf)){throw 'Complete extractor was not created.'}
            $listing=Invoke-Checked $seven @('l','-slt','-sccUTF-8',$download)
            if($listing -match '(?m)^(Symbolic Link|Hard Link) ='){throw 'Linked package entries refused.'}
            foreach($match in [regex]::Matches($listing,'(?m)^Path = (.+)\r?$')){
                $name=$match.Groups[1].Value.TrimEnd("`r")
                if($name -eq $download){continue}
                if($name -match '(^[\\/]|:|(^|[\\/])\.\.([\\/]|$))'){throw 'Unsafe package member.'}
            }
            $unpacked=Join-Path $work 'nsis'
            [void](Invoke-Checked $seven @('x',$download,('-o'+$unpacked),'-y'))
            Ensure-Directory $stage
            foreach($file in (Get-SafeFiles $unpacked $null -Recurse)){
                $relative=Get-RelativeName $unpacked $file.FullName
                if($relative -like '$PLUGINSDIR\*' -or $file.Name -eq 'tesseract-uninstall.exe'){continue}
                $target=Join-Path $stage $relative;Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($file.FullName,$target,$false)
            }
            if(-not (Test-Path -LiteralPath (Join-Path $stage 'tessdata\pdf.ttf')) -or -not @(Get-SafeFiles $stage @('.dll')).Count -or -not (Test-Path -LiteralPath (Join-Path $stage 'doc\LICENSE'))){throw 'Incomplete Tesseract runtime/resources/license.'}
        }
        elseif ($Package.Kind -eq 'zip') { Zip-Extract $download $stage }
        elseif ($Package.Kind -eq '7z') {
            $tar=Join-Path $env:SystemRoot 'System32\tar.exe'
            if (-not (Test-Path -LiteralPath $tar)) { throw 'Windows tar.exe is needed for this 7z package. Extract the verified archive manually into System\Bin\imagemagick.' }
            $listing=Invoke-Checked $tar @('-tf',$download)
            $details=Invoke-Checked $tar @('-tvf',$download)
            if ($details -match '(?m)^[lh]') { throw 'Linked archive entries are not accepted.' }
            foreach ($name in ($listing -split '[\r\n]+' | Where-Object { $_ })) {
                if ($name -match '(^[\\/]|:|(^|[\\/])\.\.([\\/]|$))') { throw 'Unsafe archive path.' }
            }
            Ensure-Directory $stage
            [void](Invoke-Checked $tar @('-xf',$download,'-C',$stage))
        } else { throw 'Unsupported package type.' }
        $exeName=if ($Package.Id -eq 'ffmpeg') { 'ffmpeg.exe' } elseif($Package.Id -eq 'qpdf'){'qpdf.exe'} elseif($Package.Id -eq 'tesseract'){'tesseract.exe'} else { 'magick.exe' }
        $exe=@(Get-ChildItem -LiteralPath $stage -Filter $exeName -Recurse -File)
        if (-not $exe.Count) { throw 'Package does not contain the expected executable.' }
        $check=Invoke-Native $exe[0].FullName @($(if($Package.Id -in @('qpdf','tesseract')){'--version'}else{'-version'})) 15000
        if ($check.Code -ne 0 -or ($check.Out+$check.Err) -notmatch [regex]::Escape($Package.Version)) { throw 'Package executable failed version validation.' }
        if ($Package.Id -eq 'ffmpeg' -and -not (Get-ChildItem -LiteralPath $stage -Filter 'ffprobe.exe' -Recurse -File)) { throw 'FFprobe is missing from the FFmpeg package.' }
        # Preserve the whole distribution, including licensing and resources.
        [IO.Directory]::Move($stage,$destination)
        Write-Host ('[SUCCESS] Portable package prepared: ' + $Package.Name)
    } finally { if ($work) { Remove-WorkDirectory $work $cache } }
}

function Copy-InstalledDependency($Dependency,[string]$Root) {
    # Called only after explicit consent from START_HERE --portable. No installer,
    # registry, Windows files or global PATH changes; preserve the entire tree.
    if($Dependency.Local){Write-Host ('[OK] Already portable: '+$Dependency.Name);return}
    $folder=if($Dependency.Name -eq 'magick'){'imagemagick'}else{$Dependency.Name}
    if($folder -notin @('ffmpeg','imagemagick','ghostscript','qpdf','tesseract')){throw 'Copy the FFmpeg package for FFprobe.'}
    $exeDir=[IO.Path]::GetDirectoryName($Dependency.Path)
    $source=if([IO.Path]::GetFileName($exeDir) -ieq 'bin'){[IO.Path]::GetDirectoryName($exeDir)}else{$exeDir}
    $leaf=[IO.Path]::GetFileName($source)
    $allowed=switch($folder){'ffmpeg'{$leaf -match '^ffmpeg'};'imagemagick'{$leaf -match '^ImageMagick'};'ghostscript'{$leaf -match '^gs\d+\.\d+'};'qpdf'{$leaf -match '^qpdf'};'tesseract'{$leaf -match '^Tesseract'}}
    if(-not $allowed){throw 'The installation folder cannot be identified safely. Supply the full portable tree manually.'}
    Ensure-Directory $source
    $files=@(Get-SafeFiles $source $null -Recurse)
    if(-not $files.Count -or $files.Count -gt 20000){throw 'Unexpected installation size.'}
    $bytes=($files|Measure-Object Length -Sum).Sum
    if($bytes -gt 4GB){throw 'Installation exceeds the 4 GB copy limit.'}
    $bin=Join-Path $Root 'System\Bin';Ensure-Directory $bin
    $destination=Join-Path $bin $folder
    if(Test-Path -LiteralPath $destination){throw 'Existing local folder preserved. Move or repair it manually before retrying.'}
    Test-FreeSpace $bin ([long]$bytes+16MB)
    $work=New-WorkDirectory $bin
    try {
        $stage=Join-Path $work 'package';Ensure-Directory $stage
        foreach($directory in (Get-SafeDirectories $source)){Ensure-Directory (Join-Path $stage (Get-RelativeName $source $directory.FullName))}
        foreach($file in $files){$target=Join-Path $stage (Get-RelativeName $source $file.FullName);Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($file.FullName,$target,$false);if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Copied dependency checksum differs.'}}
        $exe=Join-Path $stage (Get-RelativeName $source $Dependency.Path)
        $arguments=if($folder -eq 'ghostscript'){@('-q','-dSAFER','-dNODISPLAY','-c','quit')}elseif($folder -in @('qpdf','tesseract')){@('--version')}else{@('-version')}
        $check=Invoke-Native $exe $arguments 15000
        if($check.Code -ne 0){throw 'Copied program failed a local startup check.'}
        [IO.Directory]::Move($stage,$destination)
        Write-Host ('[SUCCESS] Complete installed tree copied to '+$destination)
    } finally {Remove-WorkDirectory $work $bin}
}

function Install-OptionalOCRLanguage($Model,[string]$Root,[scriptblock]$Fetcher={param($url,$path) Receive-HTTPS $url $path}) {
    if($Model.Code -notmatch '^[a-z_]+$' -or $Model.GitBlobSHA1 -notmatch '^[a-f0-9]{40}$' -or $Model.Url -notmatch '^https://raw\.githubusercontent\.com/tesseract-ocr/tessdata_fast/65727574dfcd264acbb0c3e07860e4e9e9b22185/[a-z_]+\.traineddata$'){throw 'Unpinned optional OCR model.'}
    $data=Join-Path $Root 'System\Bin\Tesseract\tessdata';$exe=Join-Path $Root 'System\Bin\Tesseract\tesseract.exe'
    if(-not (Test-Path -LiteralPath $exe)){throw 'Prepare the complete local Tesseract runtime first.'}
    Ensure-Directory $data;$target=Join-Path $data ($Model.Code+'.traineddata')
    if(Test-Path -LiteralPath $target){Write-Host '[SKIPPED] Existing language preserved.';return}
    $parent=Join-Path $Root 'System\Downloads';Ensure-Directory $parent;$work=New-WorkDirectory $parent
    try {
        Test-FreeSpace $parent ([long]$Model.Bytes*3+16MB)
        $path=Join-Path $work ($Model.Code+'.traineddata');& $Fetcher $Model.Url $path
        $bytes=[IO.File]::ReadAllBytes($path);if($bytes.Length -ne [long]$Model.Bytes){throw 'Optional model size mismatch.'}
        $header=[Text.Encoding]::ASCII.GetBytes(('blob '+$bytes.Length+[char]0));$sha=[Security.Cryptography.SHA1]::Create()
        try{$gitHash=[BitConverter]::ToString($sha.ComputeHash(([byte[]]($header+$bytes)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
        if($gitHash -ne $Model.GitBlobSHA1){throw 'Pinned official Git content hash mismatch; model not published.'}
        $test=Invoke-TesseractData $exe $work @('-l',$Model.Code,'--oem','1','--print-parameters')
        if($test.Code -ne 0 -or $test.Err -match 'Failed loading|Error opening data'){throw 'Optional model cannot initialize.'}
        $hash=(Get-FileHash -LiteralPath $path).Hash
        Publish-File $path $target
        Write-Host ('[SUCCESS] Optional language '+$Model.Code+' | SHA-256 '+$hash)
        Write-Host 'Integrity anchor: fixed official Git commit/blob SHA-1; no publisher SHA-256 was provided for this optional model. SHA-256 above is computed locally, not a publisher signature.'
    }finally{Remove-WorkDirectory $work $parent}
}
