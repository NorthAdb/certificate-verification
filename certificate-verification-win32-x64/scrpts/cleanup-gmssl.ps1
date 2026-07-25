$ErrorActionPreference = 'SilentlyContinue'
$root = 'D:\20240429certificate-verification\certificate-verification-win32-x64'
$app = Join-Path $root 'resources\app'

Write-Host '=== Remove directories ===' -ForegroundColor Cyan
foreach ($dir in @(
    (Join-Path $app 'GmSSL'),
    (Join-Path $app 'demoCA'),
    (Join-Path $root 'demoCA')
)) {
    if (Test-Path $dir) {
        Remove-Item -LiteralPath $dir -Recurse -Force
        Write-Host "Removed: $dir"
    }
}

Write-Host '=== Remove root files ===' -ForegroundColor Cyan
$rootFiles = @(
    'gmssl.exe', 'libcrypto-1_1.dll', 'libssl-1_1.dll',
    'gmssl.pdb', 'libcrypto-1_1.pdb', 'libssl-1_1.pdb',
    'c_rehash.pl', 'crl.crl', 'chain.pem', 'baidu.pem', '1.txt',
    'chain - 副本.pem'
)
foreach ($f in $rootFiles) {
    $p = Join-Path $root $f
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Force
        Write-Host "Deleted: $f"
    }
}

Write-Host '=== Remove app files ===' -ForegroundColor Cyan
$appFiles = @(
    'gmssl.exe', 'libcrypto-1_1.dll', 'libssl-1_1.dll',
    'gmssl.pdb', 'libcrypto-1_1.pdb', 'libssl-1_1.pdb',
    'c_rehash.pl', 'ROOTCA.cer', 'XIDIANCA.cer', '2.pem', 'require.js'
)
foreach ($f in $appFiles) {
    $p = Join-Path $app $f
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Force
        Write-Host "Deleted: resources\app\$f"
    }
}

Write-Host '=== Verify ===' -ForegroundColor Cyan
$checks = @{
    'GmSSL gone' = -not (Test-Path (Join-Path $app 'GmSSL'))
    'demoCA app gone' = -not (Test-Path (Join-Path $app 'demoCA'))
    'gmssl.exe app gone' = -not (Test-Path (Join-Path $app 'gmssl.exe'))
    'tongsuo openssl OK' = Test-Path (Join-Path $app 'tongsuo\bin\openssl.exe')
    'providers OK' = Test-Path (Join-Path $app 'providers\pqmagic.dll')
    'certs OK' = Test-Path (Join-Path $app 'certs\1\root.crt')
}
foreach ($k in $checks.Keys) {
    $ok = $checks[$k]
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "$k : $(if($ok){'OK'}else{'FAIL'})" -ForegroundColor $color
}
