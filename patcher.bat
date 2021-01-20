@ECHO OFF
setlocal
cd /d %~dp0
type CMake-MS-static-patch.txt >> %1
