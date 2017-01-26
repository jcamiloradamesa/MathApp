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

REM CD %BASE_DIR%\
REM mkdir .\output\installers\MathApp\
REM xcopy /s .\dotNet\MathApp\bin\Debug\MathApp.exe .\output\installers\MathApp\

REM set msBuildDir=
exit /b 0;
