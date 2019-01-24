@ECHO OFF
REM This is the parent directory of the directory containing this script (resolves to :install_root/Bolt/bin)
SET BOLT_DIR=%~dp0..

REM Avoid the nasty \..\ littering the paths.
SET BOLT_DIR=%PL_BASEDIR:\bin\..=%

REM Add bolt's bindir to the PATH
SET PATH=%BOLT_DIR%\bin:%PATH%

REM Set the RUBY LOAD_PATH using the RUBYLIB environment variable
SET RUBYLIB=%PBOLT_DIR%\lib;%RUBYLIB%

REM Set SSL variables to ensure trusted locations are used
SET SSL_CERT_FILE=%BOLT_DIR%\ssl\cert.pem
SET SSL_CERT_DIR=%BOLT_DIR%\ssl\certs
SET OPENSSL_CONF=%BOLT_DIR%\ssl\openssl.cnf
