@echo off
call build.bat 0 0
if %errorlevel% neq 0 exit /b
call run.bat