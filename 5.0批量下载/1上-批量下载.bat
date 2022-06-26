@echo off

@for /l %%i in (1,1,93) do @(
    @echo "%%i" 
    you-get --format=dash-flv720 https://www.bilibili.com/video/BV1nf4y1F7Bn?p=%%i
)

del *.xml

pause