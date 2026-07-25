$r = 'D:\20240429certificate-verification\certificate-verification-win32-x64'
$app = Join-Path $r 'resources\app'

Write-Host '=== Root files ===' -ForegroundColor Cyan
Get-ChildItem $r -File | ForEach-Object {
    Write-Host ('{0,-40} {1,8:N1} KB' -f $_.Name, ($_.Length/1KB))
}

Write-Host "`n=== App subdirs ===" -ForegroundColor Cyan
foreach ($name in @('tongsuo','providers','certs','config','scripts','node_modules')) {
    $p = Join-Path $app $name
    if (Test-Path $p) {
        $files = Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue
        $sum = ($files | Measure-Object Length -Sum).Sum
        Write-Host ('{0,-20} {1,4} files  {2,8:N2} MB' -f $name, $files.Count, ($sum/1MB))
    } else {
        Write-Host "$name : MISSING"
    }
}

Write-Host "`n=== tongsuo/bin vs tongsuo/lib (duplicate DLLs?) ===" -ForegroundColor Cyan
$bin = Join-Path $app 'tongsuo\bin'
$lib = Join-Path $app 'tongsuo\lib'
if (Test-Path $bin) { Get-ChildItem $bin | ForEach-Object { Write-Host "bin: $($_.Name)" } }
if (Test-Path $lib) { Get-ChildItem $lib | ForEach-Object { Write-Host "lib: $($_.Name)" } }

Write-Host "`n=== App loose files ===" -ForegroundColor Cyan
Get-ChildItem $app -File -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ('{0,-30} {1,8:N1} KB' -f $_.Name, ($_.Length/1KB))
}

Write-Host "`n=== Root markdown/docs ===" -ForegroundColor Cyan
Get-ChildItem $r -Filter '*.md' -File | ForEach-Object { Write-Host $_.Name }
