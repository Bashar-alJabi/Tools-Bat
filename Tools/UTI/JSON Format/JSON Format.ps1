param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'JSON Format' $PSScriptRoot $Mode '' 'Validate and indent JSON objects/arrays up to 50 levels; output is a separate UTF-8 file.'
    $choice=Read-LocalChoice $Mode @('Indented JSON','Compact JSON')
    $files=@(Get-SafeFiles $script:InputDir @('.json'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.formatted.json'} {
        param($source,$result)
        if((Get-Item -LiteralPath $source).Length -gt 8MB){throw 'JSON formatting limit is 8 MB.'}
        $text=[IO.File]::ReadAllText($source,(New-Object Text.UTF8Encoding($false,$true)))
        if($text.TrimStart() -notmatch '^[\[{]'){throw 'Only JSON objects and arrays are supported.'}
        # Strict token grammar: preserve numeric lexemes (including 64-bit values)
        # instead of parsing and reserializing values through floating point.
        $tokenPattern='\G[ \t\r\n]*("(?:[^"\\\x00-\x1f]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*"|-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?|true|false|null|[{}\[\],:])'
        $script:JsonTokens=New-Object 'Collections.Generic.List[string]';$position=0
        $regex=New-Object Text.RegularExpressions.Regex($tokenPattern,[Text.RegularExpressions.RegexOptions]::None,[TimeSpan]::FromSeconds(2))
        while($position -lt $text.Length){
            $match=$regex.Match($text,$position)
            if(-not $match.Success -or $match.Index -ne $position){if($text.Substring($position) -match '^[ \t\r\n]*$'){break};throw 'Invalid JSON token.'}
            $script:JsonTokens.Add($match.Groups[1].Value);$position+=$match.Length
            if($script:JsonTokens.Count -gt 500000){throw 'JSON exceeds 500000 tokens.'}
        }
        $script:JsonIndex=0
        function Read-JsonValue([int]$Depth){
            if($Depth -gt 50 -or $script:JsonIndex -ge $script:JsonTokens.Count){throw 'Invalid/deep JSON value.'}
            $token=$script:JsonTokens[$script:JsonIndex];$script:JsonIndex++
            if($token -eq '{' -or $token -eq '['){
                $end=if($token -eq '{'){'}'}else{']'}
                if($script:JsonIndex -lt $script:JsonTokens.Count -and $script:JsonTokens[$script:JsonIndex] -eq $end){$script:JsonIndex++;return}
                while($true){
                    if($token -eq '{'){
                        if($script:JsonIndex -ge $script:JsonTokens.Count -or $script:JsonTokens[$script:JsonIndex][0] -ne '"'){throw 'JSON object key must be quoted.'};$script:JsonIndex++
                        if($script:JsonIndex -ge $script:JsonTokens.Count -or $script:JsonTokens[$script:JsonIndex] -ne ':'){throw 'Missing JSON colon.'};$script:JsonIndex++
                    }
                    Read-JsonValue ($Depth+1)
                    if($script:JsonIndex -ge $script:JsonTokens.Count){throw 'Unclosed JSON container.'}
                    $separator=$script:JsonTokens[$script:JsonIndex];$script:JsonIndex++
                    if($separator -eq $end){return};if($separator -ne ','){throw 'Invalid JSON separator.'}
                }
            }
            elseif($token -in @('}',']',',',':')){throw 'Expected JSON value.'}
        }
        Read-JsonValue 1
        if($script:JsonIndex -ne $script:JsonTokens.Count){throw 'Unexpected content after JSON.'}
        $builder=New-Object Text.StringBuilder;$indent=0;$inString=$false;$escape=$false
        for($i=0;$i -lt $text.Length;$i++){
            $c=$text[$i]
            if($inString){[void]$builder.Append($c);if($escape){$escape=$false}elseif($c -eq '\'){$escape=$true}elseif($c -eq '"'){$inString=$false};continue}
            if([char]::IsWhiteSpace($c)){continue}
            if($c -eq '"'){$inString=$true;[void]$builder.Append($c);continue}
            if($c -eq '{' -or $c -eq '['){$indent++;if($indent -gt 50){throw 'JSON nesting exceeds 50 levels.'};[void]$builder.Append($c);if($choice -eq 1){[void]$builder.Append("`n"+('  '*$indent))}}
            elseif($c -eq '}' -or $c -eq ']'){$indent--;if($choice -eq 1){[void]$builder.Append("`n"+('  '*$indent))};[void]$builder.Append($c)}
            elseif($c -eq ','){[void]$builder.Append($c);if($choice -eq 1){[void]$builder.Append("`n"+('  '*$indent))}}
            elseif($c -eq ':'){[void]$builder.Append($c);if($choice -eq 1){[void]$builder.Append(' ')}}
            else{[void]$builder.Append($c)}
        }
        [IO.File]::WriteAllText($result,$builder.ToString()+"`n",(New-Object Text.UTF8Encoding($false)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
