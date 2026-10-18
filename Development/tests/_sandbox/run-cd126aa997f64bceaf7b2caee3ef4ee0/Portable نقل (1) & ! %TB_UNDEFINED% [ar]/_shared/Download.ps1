# Dot-source after Core.ps1 and Archives.ps1. Tests can inject a local fetcher.
function Receive-HTTPS([string]$Url,[string]$Destination) {
    $uri=[uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -notin @('www.gyan.dev','github.com')) { throw 'Unapproved download source.' }
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
    $cache=Join-Path $Root '_downloads'
    $bin=Join-Path $Root '_bin'
    Ensure-Directory $cache; Ensure-Directory $bin
    $destination=Join-Path $bin $Package.Folder
    $filename=[IO.Path]::GetFileName(([uri]$Package.Url).AbsolutePath)
    $download=Join-Path $cache $filename
    $work=$null
    try {
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
        if ($Package.Kind -eq 'installer') {
            Write-Host ('[MANUAL] Verified installer saved: ' + $download)
            Write-Host 'No installer was run. Install it yourself only if desired, or supply a complete licensed local Ghostscript tree.'
            return
        }
        Test-FreeSpace $cache ([long]$Package.ApproxMB * 1MB * 6)
        if (Test-Path -LiteralPath $destination) { throw "Existing local folder preserved: $destination . Rename it manually if it is broken, then retry." }
        $stage=Join-Path $work 'unpacked'
        if ($Package.Kind -eq 'zip') { Zip-Extract $download $stage }
        elseif ($Package.Kind -eq '7z') {
            $tar=Join-Path $env:SystemRoot 'System32\tar.exe'
            if (-not (Test-Path -LiteralPath $tar)) { throw 'Windows tar.exe is needed for this 7z package. Extract the verified archive manually into _bin\imagemagick.' }
            $listing=Invoke-Checked $tar @('-tf',$download)
            $details=Invoke-Checked $tar @('-tvf',$download)
            if ($details -match '(?m)^[lh]') { throw 'Linked archive entries are not accepted.' }
            foreach ($name in ($listing -split '[\r\n]+' | Where-Object { $_ })) {
                if ($name -match '(^[\\/]|:|(^|[\\/])\.\.([\\/]|$))') { throw 'Unsafe archive path.' }
            }
            Ensure-Directory $stage
            [void](Invoke-Checked $tar @('-xf',$download,'-C',$stage))
        } else { throw 'Unsupported package type.' }
        $exeName=if ($Package.Id -eq 'ffmpeg') { 'ffmpeg.exe' } else { 'magick.exe' }
        $exe=@(Get-ChildItem -LiteralPath $stage -Filter $exeName -Recurse -File)
        if (-not $exe.Count) { throw 'Package does not contain the expected executable.' }
        $check=Invoke-Native $exe[0].FullName @('-version') 15000
        if ($check.Code -ne 0 -or ($check.Out+$check.Err) -notmatch [regex]::Escape($Package.Version)) { throw 'Package executable failed version validation.' }
        if ($Package.Id -eq 'ffmpeg' -and -not (Get-ChildItem -LiteralPath $stage -Filter 'ffprobe.exe' -Recurse -File)) { throw 'FFprobe is missing from the FFmpeg package.' }
        # Preserve the whole distribution, including licensing and resources.
        [IO.Directory]::Move($stage,$destination)
        Write-Host ('[SUCCESS] Portable package prepared: ' + $Package.Name)
    } finally { if ($work) { Remove-WorkDirectory $work $cache } }
}
