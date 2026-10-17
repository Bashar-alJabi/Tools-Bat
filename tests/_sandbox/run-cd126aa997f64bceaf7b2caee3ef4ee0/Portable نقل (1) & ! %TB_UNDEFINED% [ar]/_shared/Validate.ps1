param([Parameter(Mandatory=$true)][string]$Variable)
$value = [Environment]::GetEnvironmentVariable($Variable)
$valid = $false
switch ($Variable) {
    'QUALITY' { $valid = $value -match '^\d{1,3}$' -and [int]$value -ge 1 -and [int]$value -le 100 }
    'WIDTH' { $valid = $value -match '^\d{1,5}$' -and [int]$value -ge 1 -and [int]$value -le 32768 }
    'HEIGHT' { $valid = $value -match '^\d{1,5}$' -and [int]$value -ge 1 -and [int]$value -le 32768 }
    'SIZE' { $valid = $value -match '^\d{1,4}$' -and [int]$value -ge 1 -and [int]$value -le 2000 }
    'OPACITY' { $valid = -not $value -or ($value -match '^\d{1,3}$' -and [int]$value -ge 10 -and [int]$value -le 100) }
    'COLOR' { $valid = $value -match '^(#[a-fA-F0-9]{6}|[a-zA-Z]{1,30})$' }
    'FUZZ' { $valid = $value -match '^\d{1,3}(\.\d{1,2})?%?$' -and [double]$value.TrimEnd('%') -le 100 }
    'WATERMARK_TEXT' { $valid = $value.Length -ge 1 -and $value.Length -le 300 -and $value -notmatch '["%!?&|<>^@\[\]{}\\]' }
    default { $valid = -not $value -or $value -match '^[0-9QqYyNn]$' }
}
if (-not $valid) { Write-Host "[ERROR] Invalid $Variable. Use the range and format shown in the prompt."; exit 2 }
exit 0
