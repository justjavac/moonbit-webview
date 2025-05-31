@echo off
set VS2022_DIR="C:\Program Files\Microsoft Visual Studio\2022\Community"
call %VS2022_DIR%\VC\Auxiliary\Build\vcvarsall.bat x64
set CC="cl"
set CC_FLAGS=""
set CC_LINK_FLAGS="/link /LIBPATH:D:\\Code\\moonbit-webview\\lib webview.lib"
