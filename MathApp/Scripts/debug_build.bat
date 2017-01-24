REM store current working directory in order to get back after build
set CUR_DIR=%CD%

REM set msBuildDir=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319
set msBuildDir=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319

REM =====module 1===========
CD %CUR_DIR%\dotNet\

REM  build 
call %msBuildDir%\msbuild.exe %DF_MSBUILD_BUILD_STATS_OPTS% MathApp.sln  /t:Build /p:Configuration=Debug

REM exit if the above does not succeed
if %errorlevel% neq 0 exit /b %errorlevel%

CD %BASE_DIR%\
mkdir .\output\installers\MathApp\
xcopy /s .\dotNet\MathApp\bin\Debug\MathApp.exe .\output\installers\MathApp\

set msBuildDir=
exit /b 0;
