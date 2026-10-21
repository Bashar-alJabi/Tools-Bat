param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 Show-LocalTool 'PDF Unlock' $PSScriptRoot $Mode 'qpdf' 'Decrypt a new PDF copy using its known password; no guessing or cracking.'
 $null=Read-LocalChoice $Mode @('Decrypt using the correct known password')
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'));if(-not $files.Count){Write-Host '[INFO] No supported input files.';exit 0}
 $password=Read-PrivatePassword 'Known PDF password'
 try {
  Invoke-LocalBatch $files {param($f)$f.Name+'.unlocked.pdf'} {
   param($source,$result)
   $encrypted=Invoke-Native $script:Engine @('--is-encrypted','source.pdf');if($encrypted.Code -ne 0){throw 'Input is not an encrypted PDF.'}
   $before=Invoke-QPDFJob $script:Engine @{inputFile='source.pdf';password=$password;showNpages=''}
   $null=Invoke-QPDFJob $script:Engine @{inputFile='source.pdf';outputFile='result.pdf';password=$password;decrypt=''}
   $after=Invoke-Native $script:Engine @('--show-npages','result.pdf');if($after.Code -ne 0 -or $after.Out.Trim() -ne $before.Out.Trim()){throw 'Decrypted page count differs.'}
   $check=Invoke-Native $script:Engine @('--is-encrypted','result.pdf');if($check.Code -ne 2){throw 'Output is still encrypted or invalid.'}
   $null=Invoke-QPDFJob $script:Engine @{inputFile='result.pdf';check=''}
  }
 }finally{$password=$null}
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
