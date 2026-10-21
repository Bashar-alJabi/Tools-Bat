param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 Show-LocalTool 'PDF Protect' $PSScriptRoot $Mode 'qpdf' 'Encrypt new PDF copies using AES-256 (revision 6). Password is requested privately, including with --defaults.'
 $null=Read-LocalChoice $Mode @('Protect with AES-256; no viewing/printing restrictions')
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'));if(-not $files.Count){Write-Host '[INFO] No supported input files.';exit 0}
 $password=Read-PrivatePassword 'Open password (12+ characters)';$confirm=Read-PrivatePassword 'Repeat password'
 if($password.Length -lt 12 -or $password -cne $confirm){throw 'Passwords must match and contain at least 12 characters.'}
 $confirm=$null
 try {
  Invoke-LocalBatch $files {param($f)$f.Name+'.protected.pdf'} {
   param($source,$result)
   $owner=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')
   $job=@{inputFile='source.pdf';outputFile='result.pdf';encrypt=@{userPassword=$password;ownerPassword=$owner;'256bit'=@{}}}
   try{$null=Invoke-QPDFJob $script:Engine $job}finally{$job=$null;$owner=$null}
   $bad=Invoke-Native $script:Engine @('@-') 0 ("result.pdf`n--password="+[guid]::NewGuid().ToString('N')+"`n--check`n")
   if($bad.Code -eq 0){throw 'Protection validation failed: wrong password accepted.'}
   $null=Invoke-QPDFJob $script:Engine @{inputFile='result.pdf';password=$password;check=''}
   $raw=[Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($result))
   if($raw -notmatch '/R\s+6\b' -or $raw -notmatch '/Length\s+256\b' -or $raw -notmatch '/AESV3\b'){throw 'AES-256 revision 6 was not confirmed.'}
  }
 }finally{$password=$null}
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
