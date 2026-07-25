@echo off
setlocal

set "REPO_ROOT=D:\20240429certificate-verification"
set "TLCP_ROOT=%REPO_ROOT%\tlcp-pqc"
set "APP_ROOT=%REPO_ROOT%\certificate-verification-win32-x64\resources\app"

echo === Layout Tongsuo runtime into Electron app ===

mkdir "%APP_ROOT%\tongsuo\bin" 2>nul
mkdir "%APP_ROOT%\providers" 2>nul
mkdir "%APP_ROOT%\config" 2>nul
mkdir "%APP_ROOT%\certs\1" 2>nul
mkdir "%APP_ROOT%\certs\2" 2>nul
mkdir "%APP_ROOT%\certs\3" 2>nul
mkdir "%APP_ROOT%\scripts" 2>nul

echo --- Tongsuo (from tlcp-pqc\bin after layout-tlcp-pqc.bat) ---
copy /Y "%TLCP_ROOT%\bin\openssl.exe" "%APP_ROOT%\tongsuo\bin\" >nul
if errorlevel 1 (
    echo ERROR: tlcp-pqc\bin\openssl.exe not found. Run build-tongsuo.bat and layout-tlcp-pqc.bat first.
    exit /b 1
)
copy /Y "%TLCP_ROOT%\bin\libcrypto-3-x64.dll" "%APP_ROOT%\tongsuo\bin\" >nul
copy /Y "%TLCP_ROOT%\bin\libssl-3-x64.dll" "%APP_ROOT%\tongsuo\bin\" >nul

echo --- Providers ---
copy /Y "%TLCP_ROOT%\providers\pqmagic.dll" "%APP_ROOT%\providers\" >nul
copy /Y "%TLCP_ROOT%\providers\libml_dsa_sm2_provider.dll" "%APP_ROOT%\providers\" >nul
copy /Y "%TLCP_ROOT%\providers\cert_verify.dll" "%APP_ROOT%\providers\" >nul
if exist "%TLCP_ROOT%\providers\aigis_enc.dll" (
    copy /Y "%TLCP_ROOT%\providers\aigis_enc.dll" "%APP_ROOT%\providers\" >nul
)

echo --- Sample certs ---
for %%S in (1 2 3) do (
    copy /Y "%TLCP_ROOT%\certs\%%S\root.crt" "%APP_ROOT%\certs\%%S\" >nul
    copy /Y "%TLCP_ROOT%\certs\%%S\yunying.crt" "%APP_ROOT%\certs\%%S\" >nul
    copy /Y "%TLCP_ROOT%\certs\%%S\user_sig.crt" "%APP_ROOT%\certs\%%S\" >nul
    copy /Y "%TLCP_ROOT%\certs\%%S\user_enc.crt" "%APP_ROOT%\certs\%%S\" >nul
)

echo NOTE: openssl-all-providers.cnf is auto-generated on app startup.
echo === DONE: %APP_ROOT% ===
exit /b 0
