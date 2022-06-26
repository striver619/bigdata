@echo off

@for /l %%i in (1,1,153) do @(
    @echo "%%i" 
    you-get --format=dash-flv720 https://www.bilibili.com/video/BV1yY411b72x?p=%%i
)

del *.xml

pause