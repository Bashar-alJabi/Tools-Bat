# Development record: the one-time, in-place transformation used for the review.
# Refuses to run on anything except the exact original files in manifest.json.
$ErrorActionPreference='Stop'
$root = Split-Path $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest | Where-Object Path -Like '*.bat') {
    $path=Join-Path $root $entry.Path
    if ((Get-FileHash -LiteralPath $path).Hash -ne $entry.SHA256) { throw "Not the original file: $path" }
}
$cuts=@{
    'Background Color Remover'='(?m)^:PROCESS\s*$'; 'Image Compression'='(?m)^:START_COMPRESSION\s*$'
    'Image Convert'='(?m)^:START_CONVERSION\s*$'; 'Image Crop'='(?m)^set /a SUCCESS=0\s*$'
    'Image Enhance'='(?m)^:PROCESS\s*$'; 'Image Contact Sheet'='(?m)^if exist "%LIST%" del /Q "%LIST%" >nul 2>&1\s*$'
    'Image Metadata Cleaner'='(?m)^:START_CLEANING\s*$'; 'Image Resize'='(?m)^:START_RESIZE\s*$'
    'Image Watermark'='(?m)^:PROCESS\s*$'; 'Compress PDF'='(?m)^:PROCESS\s*$'
    'Compress Video'='(?m)^:START_COMPRESSION\s*$'; 'Video FPS Converter'='(?m)^set /a TOTAL=0\s*$'
    'Video Resolution Converter'='(?m)^set /a TOTAL=0\s*$'; 'Video Speed'='(?m)^set /a TOTAL=0\s*$'
    'Convert Audio'='(?m)^set /a CURRENT=0\s*$'; 'Extract Audio'='(?m)^set /a CURRENT=0\s*$'
    'Increase Volume'='(?m)^:PROCESS\s*$'; 'Merge Audio'='(?m)^:PROCESS\s*$'
    'Normalize Audio'='(?m)^set /a CURRENT=0\s*$'; 'Remove Audio'='(?m)^set /a CURRENT=0\s*$'
    'Replace Audio'='(?m)^set "OUTPUT_FILE=.*$'
}
foreach ($entry in $manifest | Where-Object Path -Like '*.bat') {
    $path=Join-Path $root $entry.Path
    $tool=[IO.Path]::GetFileNameWithoutExtension($path)
    $text=[IO.File]::ReadAllText($path).Replace("`r`n","`n")
    $match=[regex]::Match($text,$cuts[$tool])
    if (-not $match.Success) { throw "No processing boundary: $tool" }
    $boundary=$match.Index
    # Keep the destination label so that all existing menu jumps still work.
    $label=if ($match.Value.StartsWith(':')) { $match.Value.Trim()+"`n" } else { '' }
    $text=$text.Substring(0,$boundary)+$label+"goto TB_PROCESS`n"
    $dependency=if ($entry.Path.StartsWith('IMG')) { 'magick' } elseif ($entry.Path.StartsWith('PDF')) { 'ghostscript' } else { 'ffmpeg' }
    $text=[regex]::Replace($text,'(?ms)^where (magick|ffmpeg|gswin64c) >nul 2>&1\s*if errorlevel 1 \(.*?^\)\s*',@'
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name DEPENDENCY
if errorlevel 1 exit /b 3

'@.Replace('DEPENDENCY',$dependency))
    $text=$text.Replace('setlocal EnableExtensions EnableDelayedExpansion','setlocal EnableExtensions DisableDelayedExpansion').Replace("setlocal EnableExtensions`n","setlocal EnableExtensions DisableDelayedExpansion`n")
    $text=[regex]::Replace($text,'(?m)^set "LIST=.*\n','')
    # Do not claim GPU support from the encoder list. The runner tests an encode.
    $text=[regex]::Replace($text,'(?ms)^ffmpeg -hide_banner -encoders.*?(?=^:MENU)','')
    $text=[regex]::Replace($text,'(?m)^(if errorlevel \d+) (set .+ & .+)$','$1 ($2)')
    # Delayed expansion is now deliberately off, even for menu variables.
    $text=[regex]::Replace($text,'!([A-Z_]+)!','%$1%')
    # Validate immediately, before cmd ever expands user-entered data.
    $text=[regex]::Replace($text,'(?mi)^(\s*set /p "([A-Z_]+)=[^\n]*\n)',{
        param($m)
        $m.Value+'"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable '+$m.Groups[2].Value+"`nif errorlevel 1 exit /b 2`n"
    })
    # Quoting path/text displays prevents & and parentheses in directory names
    # from becoming cmd operators. Filenames never go through CALL any more.
    $text=[regex]::Replace($text,'(?m)^(\s*echo) ([^\n]*%[^\n]*)$',{
        param($m)
        $m.Groups[1].Value+' "'+$m.Groups[2].Value.Replace('"','')+'"'
    })
    $header=@'
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TB_SHARED=%~dp0..\..\_shared"
if not exist "%TB_PS%" exit /b 3
if /i "%~1"=="--help" (
    echo Put files in this tool's Input folder. Results are saved in Output.
    echo --check: dependency check. --defaults: process with documented defaults.
    exit /b 0
)
if /i "%~1"=="--check" goto TB_CHECK
if /i "%~1"=="--defaults" goto TB_DEFAULTS

'@.Replace('DEPENDENCY',$dependency)
    $text=$text.Replace("DisableDelayedExpansion`n","DisableDelayedExpansion`n"+$header+"`n")
    $footer=@'

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "TOOLNAME" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "TOOLNAME" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name DEPENDENCY
exit /b %errorlevel%
'@.Replace('TOOLNAME',$tool).Replace('DEPENDENCY',$dependency)
    [IO.File]::WriteAllText($path,($text+$footer).Replace("`n","`r`n"),(New-Object Text.ASCIIEncoding))
}
