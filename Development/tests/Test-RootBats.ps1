$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
$root=$script:ProjectRoot
$expectedCatalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
$expectedCount=$expectedCatalog.Count
$results=New-Object 'Collections.Generic.List[object]'
$binRoot=Join-Path $root 'System\Bin'
$binBefore=@(Get-SafeFiles $binRoot $null -Recurse|ForEach-Object{(Get-RelativeName $binRoot $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"
function Run-RootBat([string]$Name,[string]$Arguments,[string]$InputText=''){
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe';$info.Arguments='/d /v:off /s /c ""%TB_ROOT_BAT%" '+$Arguments+'"'
    $info.WorkingDirectory=$env:SystemRoot;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_ROOT_BAT']=Join-Path $root $Name;$info.EnvironmentVariables['TB_NO_PAUSE']='1'
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try{[void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync();if($InputText){$process.StandardInput.Write($InputText)};$process.StandardInput.Close();if(-not $process.WaitForExit(60000)){$process.Kill();throw 'Root BAT timeout.'};$process.WaitForExit();if($process.ExitCode -ne 0){throw ($out.Result+$err.Result)};$out.Result}finally{$process.Dispose()}
}
try {
    foreach($mode in @('--help','--check','--defaults')){
        $text=Run-RootBat 'BUILD_DISTRIBUTION.bat' $mode
        if($mode -eq '--defaults' -and $text -notmatch '\[SUCCESS\] ZIP:'){throw 'Distribution BAT did not build a ZIP.'}
        $results.Add([pscustomobject]@{Test=('BUILD_DISTRIBUTION '+$mode);Passed=$true;Detail='Real BAT launched from Windows directory; expected successful mode.'})
    }
    $null=Run-RootBat 'START_HERE.bat' '--help'
    $results.Add([pscustomobject]@{Test='START_HERE help';Passed=$true;Detail='Real help BAT ran successfully.'})
    $text=Run-RootBat 'START_HERE.bat' '--portable' "n`nn`nn`nn`n"
    if($text -notmatch ('Tools registered: '+$expectedCount) -or $text -notmatch '\[SUCCESS\] All project requirements'){throw 'Portable consent/readiness flow failed.'}
    $binAfter=@(Get-SafeFiles $binRoot $null -Recurse|ForEach-Object{(Get-RelativeName $binRoot $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"
    if($binAfter -cne $binBefore){throw 'Declined copies changed production System\Bin.'}
    $results.Add([pscustomobject]@{Test='START_HERE portable decline';Passed=$true;Detail='All catalog tools registered; declined each copy; full readiness rescan succeeded; no production program copy or download.'})
}catch{$results.Add([pscustomobject]@{Test='Root BAT';Passed=$false;Detail=$_.Exception.Message.Replace($root,'<PROJECT_ROOT>')})}
$results|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'root-bat-results.json') -Encoding UTF8
$results|ForEach-Object{Write-Host ($(if($_.Passed){'PASS '}else{'FAIL '})+$_.Test)}
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
