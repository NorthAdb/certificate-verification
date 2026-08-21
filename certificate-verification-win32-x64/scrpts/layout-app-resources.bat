@echo off
setlocal EnableExtensions

set "REPO_ROOT=D:\20240429certificate-verification"
set "TLCP_ROOT=%REPO_ROOT%\tlcp-pqc"
set "APP_ROOT=%REPO_ROOT%\certificate-verification-win32-x64\resources\app"

echo === Layout Tongsuo runtime into Electron app ===

mkdir "%APP_ROOT%\tongsuo\bin" 2>nul
mkdir "%APP_ROOT%\providers" 2>nul
mkdir "%APP_ROOT%\config" 2>nul
mkdir "%APP_ROOT%\scripts" 2>nul

echo --- Tongsuo ---
copy /Y "%TLCP_ROOT%\bin\openssl.exe" "%APP_ROOT%\tongsuo\bin\" >nul
if errorlevel 1 (
    echo ERROR: tlcp-pqc\bin\openssl.exe not found.
    exit /b 1
)
copy /Y "%TLCP_ROOT%\bin\libcrypto-3-x64.dll" "%APP_ROOT%\tongsuo\bin\" >nul
copy /Y "%TLCP_ROOT%\bin\libssl-3-x64.dll" "%APP_ROOT%\tongsuo\bin\" >nul

echo --- Providers ---
copy /Y "%TLCP_ROOT%\providers\pqmagic.dll" "%APP_ROOT%\providers\" >nul
copy /Y "%TLCP_ROOT%\providers\libml_dsa_sm2_provider.dll" "%APP_ROOT%\providers\" >nul
copy /Y "%TLCP_ROOT%\providers\cert_verify.dll" "%APP_ROOT%\providers\" >nul
if exist "%TLCP_ROOT%\providers\aigis.dll" copy /Y "%TLCP_ROOT%\providers\aigis.dll" "%APP_ROOT%\providers\" >nul

echo --- Sample certs ---
call :sync_chain "Pure PQC Certificate\mlkemdsa"
call :sync_chain "Hybrid Concatenated Certificate\mlkemdsa"
call :sync_chain "Hybrid Using Extensions Certificate\mlkemdsa"
call :sync_chain "Pure PQC Certificate\aigis"
call :sync_chain "Hybrid Concatenated Certificate\aigissm2"
call :sync_chain "Hybrid Using Extensions Certificate\sm2extaigis"

echo NOTE: openssl-all-providers.cnf is auto-generated on app startup.
echo === DONE ===
exit /b 0

:sync_chain
set "REL=%~1"
set "SRC=%TLCP_ROOT%\certs\%REL%"
set "DST=%APP_ROOT%\certs\%REL%"
if not exist "%SRC%\root.crt" (
  echo SKIP missing: %REL%
  exit /b 0
)
mkdir "%DST%" 2>nul
for %%F in (root.crt yunying.crt user_sig.crt user_enc.crt) do if exist "%SRC%\%%F" copy /Y "%SRC%\%%F" "%DST%\" >nul
echo synced %REL%
exit /b 0