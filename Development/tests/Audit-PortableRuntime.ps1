param([string]$Project,[string]$ReportDirectory)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
if(-not $Project){$Project=$script:ProjectRoot}
$script:ProjectRoot=[IO.Path]::GetFullPath($Project)
if(-not $ReportDirectory){$ReportDirectory=Join-Path $PSScriptRoot '_work\portable-audit'}
$ReportDirectory=[IO.Path]::GetFullPath($ReportDirectory)
Ensure-Directory $ReportDirectory
$bin=Join-Path $script:ProjectRoot 'System\Bin'
function Relative([string]$Path){$Path.Replace($script:ProjectRoot,'<PROJECT_ROOT>')}
function Read-Imports([string]$Path){
    $bytes=[IO.File]::ReadAllBytes($Path)
    if($bytes.Length -lt 256 -or [BitConverter]::ToUInt16($bytes,0) -ne 0x5a4d){return}
    $pe=[BitConverter]::ToInt32($bytes,60)
    if([BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550){throw 'Invalid PE signature.'}
    $sections=[BitConverter]::ToUInt16($bytes,$pe+6);$optional=$pe+24
    $sectionTable=$optional+[BitConverter]::ToUInt16($bytes,$pe+20)
    $magic=[BitConverter]::ToUInt16($bytes,$optional)
    $data=$optional+$(if($magic -eq 0x20b){112}else{96})
    function Offset([uint32]$Rva){
        for($s=0;$s -lt $sections;$s++){
            $at=$sectionTable+40*$s;$va=[BitConverter]::ToUInt32($bytes,$at+12)
            $size=[Math]::Max([BitConverter]::ToUInt32($bytes,$at+8),[BitConverter]::ToUInt32($bytes,$at+16))
            if($Rva -ge $va -and $Rva -lt $va+$size){return [int]($Rva-$va+[BitConverter]::ToUInt32($bytes,$at+20))}
        }
        throw ('Unmapped PE RVA '+$Rva)
    }
    foreach($table in @(@{Index=1;Stride=20;NameOffset=12},@{Index=13;Stride=32;NameOffset=4})){
        $rva=[BitConverter]::ToUInt32($bytes,$data+8*$table.Index)
        if(-not $rva){continue};$at=Offset $rva
        while([BitConverter]::ToUInt32($bytes,$at+$table.NameOffset)){
            $nameRva=[BitConverter]::ToUInt32($bytes,$at+$table.NameOffset)
            # These x64 images use RVA-based delay import descriptors.
            if($table.Index -eq 13 -and ([BitConverter]::ToUInt32($bytes,$at) -band 1) -eq 0){throw 'Unsupported VA-based delay descriptor.'}
            $nameAt=Offset $nameRva;$end=$nameAt
            while($bytes[$end] -ne 0){$end++}
            [Text.Encoding]::ASCII.GetString($bytes,$nameAt,$end-$nameAt)
            $at+=$table.Stride
        }
    }
}
$files=@(Get-SafeFiles $bin $null -Recurse)
$inventory=@($files|ForEach-Object{[pscustomobject]@{Path=Get-RelativeName $bin $_.FullName;Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
$inventory|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $ReportDirectory 'bin-inventory.json') -Encoding UTF8
$imports=New-Object 'Collections.Generic.List[object]'
$byProgram=@{}
foreach($file in $files){
    $key=(Get-RelativeName $bin $file.FullName).Split('\')[0]+'|'+$file.Name
    if(-not $byProgram.ContainsKey($key)){$byProgram[$key]=New-Object 'Collections.Generic.List[object]'}
    $byProgram[$key].Add($file)
}
foreach($file in @($files|Where-Object Extension -in @('.exe','.dll'))){
    $program=(Get-RelativeName $bin $file.FullName).Split('\')[0]
    foreach($name in @(Read-Imports $file.FullName|Select-Object -Unique)){
        $local=@(if($byProgram.ContainsKey($program+'|'+$name)){$byProgram[$program+'|'+$name].ToArray()})
        $resolution=if($local.Count){'Bundled'}elseif($name -match '^(api|ext)-ms-'){'Windows API set'}elseif(Test-Path -LiteralPath (Join-Path $env:SystemRoot ('System32\'+$name))){'Windows System32'}else{'Unresolved'}
        $imports.Add([pscustomobject]@{Binary=Get-RelativeName $bin $file.FullName;Import=$name;Resolution=$resolution;Candidates=@($local|ForEach-Object{Get-RelativeName $bin $_.FullName})})
    }
}
$imports.ToArray()|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $ReportDirectory 'pe-imports.json') -Encoding UTF8
$versions=New-Object 'Collections.Generic.List[object]'
$probes=New-Object 'Collections.Generic.List[object]'
$oldPath=$env:PATH;$oldLocal=$env:TB_LOCAL_ONLY
try{
    $env:PATH=$env:SystemRoot+'\System32;'+$env:SystemRoot;$env:TB_LOCAL_ONLY='1'
    $localGS=Get-Dependency ghostscript -LocalOnly
    $script:NativeWorkingDirectory=$ReportDirectory
    [void](Invoke-Checked $localGS.Path @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=audit.pdf','-c','/Helvetica findfont 12 scalefont setfont 72 720 moveto (LOCAL DLL AUDIT) show showpage'))
    foreach($name in @('ffmpeg','ffprobe','magick','ghostscript','qpdf','tesseract')){
        $dep=Get-Dependency $name -LocalOnly
        if(-not $dep -or -not $dep.Local){throw ('Local runtime rejected: '+$name)}
        $versions.Add([pscustomobject]@{Name=$name;Version=$dep.Version;Path=Relative $dep.Path})
        $args=switch($name){
            ffmpeg {@('-v','error','-i','pipe:0','-f','null','-')}
            ffprobe {@('-v','error','-i','pipe:0')}
            magick {@('audit.pdf[0]','png:-','null:')}
            ghostscript {@('-q','-dNODISPLAY','-')}
            qpdf {@('@-')}
            tesseract {@('stdin','stdout','--tessdata-dir','.','-l','eng','--psm','6')}
        }
        $info=New-Object Diagnostics.ProcessStartInfo
        $info.FileName=$dep.Path;$info.Arguments=($args|ForEach-Object{ConvertTo-NativeArgument $_}) -join ' '
        $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
        $info.WorkingDirectory=$ReportDirectory
        if($name -eq 'tesseract'){$info.WorkingDirectory=Join-Path $bin 'Tesseract\tessdata'}
        foreach($key in @($info.EnvironmentVariables.Keys|Where-Object {$_ -match '^(MAGICK_|GS_|TESSDATA_|FONTCONFIG_|FFREPORT$)'})){$info.EnvironmentVariables.Remove($key)}
        if($name -eq 'ghostscript'){
            $gsDirectory=Split-Path $dep.Path
            Set-GhostscriptProcessEnvironment $info (Split-Path $gsDirectory) (Join-Path $gsDirectory 'gsdll64.dll')
        }
        if($name -eq 'magick'){
            $imRoot=Split-Path $dep.Path;$info.EnvironmentVariables['MAGICK_HOME']=$imRoot;$info.EnvironmentVariables['MAGICK_CONFIGURE_PATH']=$imRoot;$info.EnvironmentVariables['MAGICK_CODER_MODULE_PATH']=Join-Path $imRoot 'modules\coders'
            $gsDirectory=Split-Path $localGS.Path
            $baseUri=New-Object Uri($ReportDirectory.TrimEnd('\')+'\')
            $gsUri=New-Object Uri($gsDirectory.TrimEnd('\')+'\')
            $relative=[uri]::UnescapeDataString($baseUri.MakeRelativeUri($gsUri).ToString()).Replace('/','\')
            $info.EnvironmentVariables['MAGICK_GHOSTSCRIPT_PATH']=if($relative -notmatch '%'){$relative}else{$gsDirectory}
            Set-GhostscriptProcessEnvironment $info (Split-Path $gsDirectory) (Join-Path $gsDirectory 'gsdll64.dll')
        }
        $process=New-Object Diagnostics.Process;$process.StartInfo=$info
        try{
            [void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync()
            Start-Sleep -Milliseconds 400
            if($process.HasExited){throw ('Module probe exited before snapshot: '+$name+' | '+$err.Result)}
            $modules=@($process.Modules|ForEach-Object{$_.FileName}|Sort-Object -Unique)
            $unexpected=@($modules|Where-Object {-not $_.StartsWith($bin+'\',[StringComparison]::OrdinalIgnoreCase) -and -not $_.StartsWith($env:SystemRoot+'\',[StringComparison]::OrdinalIgnoreCase)})
            if($name -eq 'magick' -and -not @($modules|Where-Object {$_ -ieq (Join-Path (Split-Path $localGS.Path) 'gsdll64.dll')})){throw 'ImageMagick PDF delegate did not load the local GS DLL.'}
            $probes.Add([pscustomobject]@{Program=$name;Modules=@($modules|ForEach-Object{Relative $_});Unexpected=$unexpected;BundledModules=@($modules|Where-Object {$_.StartsWith($bin+'\',[StringComparison]::OrdinalIgnoreCase)}).Count})
            $process.StandardInput.Close()
            if(-not $process.WaitForExit(10000)){$process.Kill();$process.WaitForExit()}
            if($name -eq 'magick' -and $err.Result -match 'Postscript delegate failed'){throw 'PDF delegate failed during module probe.'}
        }finally{$process.Dispose()}
    }
}finally{$env:PATH=$oldPath;$env:TB_LOCAL_ONLY=$oldLocal}
$summary=[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Project='<PROJECT_ROOT>';Files=$files.Count;Bytes=[long]($files|Measure-Object Length -Sum).Sum;Versions=$versions.ToArray();PEImports=$imports.Count;Unresolved=@($imports|Where-Object Resolution -eq Unresolved);ModuleProbes=$probes.ToArray();Licenses=@($files|Where-Object Name -match 'licen[cs]e|notice|copying|copyright'|ForEach-Object{Get-RelativeName $bin $_.FullName});Limits='PE inventory is static and does not prove every optional delegate. Module snapshots cover six entry points waiting on stdin, plus separate real-operation tests. Windows DLLs, fonts, .NET and this machine remain available; not a clean Windows VM.'}
$summary|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $ReportDirectory 'runtime-audit.json') -Encoding UTF8
Write-Host ('Files '+$files.Count+'; bytes '+$summary.Bytes+'; unresolved imports '+$summary.Unresolved.Count+'; unexpected loaded modules '+@($probes|Where-Object {$_.Unexpected.Count}).Count)
if($summary.Unresolved.Count -or @($probes|Where-Object {$_.Unexpected.Count}).Count){exit 1};exit 0
