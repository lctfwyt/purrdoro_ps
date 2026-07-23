## 猫猫番茄钟（Windows桌面版）

随时随地开始连续番茄钟！

聆听古筝铃声的指引，定时工作和休息，劳逸结合，张弛有度。

陪伴你长期耕耘，实现梦想。

只需要双击 purrdoro.exe，设置好番茄个数、工作和休息时长，即可开始，小巧方便！

使用需下载以下三个文件：
- purrdoro.exe 应用入口，双击开启
- work.exe 开工铃，可以自行更换，需保持文件名不变
- rest.exe 休息铃，可以自行更换，需保持文件名不变

## 开发笔记

使用 WinForms 绘制简易 UI，使用 PowerShell 进行系统级精确计时、调用系统 API 播放音乐文件，比 Web 应用稳定，最小化运行不再也不用担心吞铃声。

PowerShell -> exe 打包命令（PowerShell）：
```
# 安装打包工具
Install-Module -Name ps2exe -Scope CurrentUser -Force

# 打包
CurrentUser -Force
Invoke-PS2EXE `
    -InputFile "Purrdoro.ps1" `
    -OutputFile "Purrdoro.exe" `
    -IconFile "tomato.ico" `
    -noConsole `
    -title "猫猫番茄钟"
```