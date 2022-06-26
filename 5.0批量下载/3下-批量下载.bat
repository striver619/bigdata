@echo off

@for /l %%i in (1,1,112) do @(
    @echo "%%i" 
    you-get --format=dash-flv720 https://www.bilibili.com/video/BV1FL411w7Jc?p=%%i
)

del *.xml

pause