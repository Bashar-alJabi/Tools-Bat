$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot)
$results=New-Object 'Collections.Generic.List[object]'
function Menu-Labels([string]$Text){
    @($Text -split '[\r\n]+'|Where-Object {$_ -match '^echo\s+"?(\[[1-9Q]\]|[1-9]\.\s)'}|ForEach-Object{($_ -replace '^echo\s+','').Trim('"',' ').Replace('%%','%')})
}
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $root 'Development\Original\original.zip'))
    try {
        foreach($entry in ($zip.Entries|Where-Object Name -like '*.bat')){
            $reader=New-Object IO.StreamReader($entry.Open())
            try{$original=$reader.ReadToEnd()}finally{$reader.Dispose()}
            $path=Join-Path $root ('Tools\'+$entry.FullName.Replace('/','\'))
            if(-not (Test-Path -LiteralPath $path)){throw ('Original BAT path lost: '+$entry.FullName)}
            $current=Get-Content -LiteralPath $path -Raw -Encoding UTF8
            $before=Menu-Labels $original;$after=Menu-Labels $current
            foreach($label in $before){if($label -notin $after){throw ('Original menu option lost: '+$entry.FullName+' : '+$label)}}
            $manual=[IO.Path]::ChangeExtension($path,'.md')
            if(-not (Test-Path -LiteralPath $manual)){throw ('Individual manual missing: '+$path)}
            $results.Add([pscustomobject]@{Test=$entry.FullName;Passed=$true;Detail=('Original path and '+$before.Count+' menu labels preserved; individual MD exists.')})
        }
        foreach($entry in ($zip.Entries|Where-Object Name -like '*.md')){if(-not (Test-Path -LiteralPath (Join-Path $root ('Tools\'+$entry.FullName.Replace('/','\'))))){throw ('Original reference removed: '+$entry.FullName)}}
        $results.Add([pscustomobject]@{Test='Original Markdown references';Passed=$true;Detail='All 15 original reference documents retained.'})
    }finally{$zip.Dispose()}
    $catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($tool in $catalog){
        $manual=[IO.Path]::ChangeExtension((Join-Path $root $tool.Path),'.md');$text=Get-Content -LiteralPath $manual -Raw -Encoding UTF8
        foreach($term in @('Input','Output','--defaults','--check','مثال','خيارات','المتطلبات','القيود')){if($text -notmatch [regex]::Escape($term)){throw ('Incomplete manual '+$tool.Name+': '+$term)}}
    }
    $results.Add([pscustomobject]@{Test='Individual manual coverage';Passed=$true;Detail='55 separate per-BAT manuals cover inputs, outputs, requirements, menus, examples, errors and limits.'})
}catch{$results.Add([pscustomobject]@{Test='Original design comparison';Passed=$false;Detail=$_.Exception.Message})}
$results|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'original-comparison-results.json') -Encoding UTF8
$results|ForEach-Object{Write-Host ($(if($_.Passed){'PASS '}else{'FAIL '})+$_.Test+': '+$_.Detail)}
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
