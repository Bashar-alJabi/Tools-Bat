@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Duplicate Finder
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TB_MODE=Interactive"
if /i "%~1"=="--defaults" set "TB_MODE=Defaults"
if /i "%~1"=="--check" set "TB_MODE=Check"
if /i "%~1"=="--help" set "TB_MODE=Help"
if /i "%~1"=="--verify" set "TB_MODE=Verify"
if not exist "%TB_PS%" exit /b 3
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\_shared\NewTool.ps1" -Tool "Duplicate Finder" -ToolDir "%~dp0." -Mode "%TB_MODE%"
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%