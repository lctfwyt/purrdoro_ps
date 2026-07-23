param(
    [switch]$NoGui,
    [int]$Count = 4,
    [int]$WorkMinutes = 25,
    [int]$RestMinutes = 5
)

# ========================================
# 基础配置
# ========================================

# 兼容 .ps1 直接运行和打包后的 .exe：均指向文件所在目录
$script:BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

$script:WorkWav = Join-Path $BaseDir "work.wav"
$script:RestWav = Join-Path $BaseDir "rest.wav"

# ========================================
# 音频工具函数
# ========================================

function Test-AudioFiles {
    $ok = $true
    if (-not (Test-Path $WorkWav)) {
        Write-Warning "缺少音频文件: $WorkWav"
        $ok = $false
    }
    if (-not (Test-Path $RestWav)) {
        Write-Warning "缺少音频文件: $RestWav"
        $ok = $false
    }
    return $ok
}

function Invoke-Bell {
    param([string]$Path)
    try {
        $player = New-Object System.Media.SoundPlayer $Path
        $player.Play()
    } catch {
        # 音频播放失败不中断流程，仅静默跳过
    }
}

# ========================================
# 计时核心逻辑（供 Start-Job / 命令行调用）
# ========================================

$script:TimerLogic = {
    param([string]$WorkWav, [string]$RestWav, [int]$Count, [int]$WorkMinutes, [int]$RestMinutes)

    Add-Type -AssemblyName System.Windows.Forms

    function Invoke-Bell {
        param([string]$Path)
        try {
            $player = New-Object System.Media.SoundPlayer $Path
            $player.Play()
        } catch {}
    }

    for ($i = 1; $i -le $Count; $i++) {
        $isLast = ($i -eq $Count)

        # --- 工作阶段 ---
        Write-Output "WORK|$i|$Count|$WorkMinutes"
        Invoke-Bell -Path $WorkWav
        Start-Sleep -Seconds ($WorkMinutes * 60)

        # --- 休息阶段（最后一个周期不休息）---
        if (-not $isLast) {
            Write-Output "REST|$RestMinutes"
            Invoke-Bell -Path $RestWav
            Start-Sleep -Seconds ($RestMinutes * 60)
        }
    }

    # --- 全部结束 ---
    Write-Output "DONE"
    Invoke-Bell -Path $RestWav
}

# ========================================
# 无 GUI 模式（命令行直接运行）
# ========================================

if ($NoGui) {
    if (-not (Test-AudioFiles)) { exit 1 }

    Write-Host "开始番茄钟 × $Count" -ForegroundColor Green
    Write-Host "工作 ${WorkMinutes}min / 休息 ${RestMinutes}min" -ForegroundColor Gray
    Write-Host "─" * 30

    & $TimerLogic -WorkWav $WorkWav -RestWav $RestWav -Count $Count -WorkMinutes $WorkMinutes -RestMinutes $RestMinutes |
        ForEach-Object {
            switch -Regex ($_) {
                '^WORK\|(\d+)\|(\d+)\|(\d+)$' {
                    Write-Host "[工作] 第 $($Matches[1])/$($Matches[2]) 轮 ($($Matches[3])分钟)" -ForegroundColor Yellow
                }
                '^REST\|(\d+)$' {
                    Write-Host "[休息] $($Matches[1]) 分钟" -ForegroundColor Cyan
                }
                '^DONE$' {
                    Write-Host "全部完成！" -ForegroundColor Green
                }
            }
        }
    return
}

# ========================================
# GUI 模式
# ========================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 辅助函数：快速创建标签
function New-Label {
    param([string]$Text, [int]$X, [int]$Y)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text
    $lbl.Location = New-Object System.Drawing.Point($X, $Y)
    $lbl.AutoSize = $true
    return $lbl
}

# 辅助函数：快速创建 NumericUpDown
function New-NumberInput {
    param([int]$X, [int]$Y, [int]$Min, [int]$Max, [int]$Value)
    $nud = New-Object System.Windows.Forms.NumericUpDown
    $nud.Location = New-Object System.Drawing.Point($X, $Y)
    $nud.Size = New-Object System.Drawing.Size(80, 20)
    $nud.Minimum = $Min
    $nud.Maximum = $Max
    $nud.Value = $Value
    return $nud
}

# ---------- 窗口 ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "🐱 猫猫番茄钟"
$form.Size = New-Object System.Drawing.Size(320, 280)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# ---------- 输入区域 ----------
$form.Controls.Add((New-Label "番茄钟个数:" 20 20))
$inputCount = New-NumberInput 150 18 1 20 4
$form.Controls.Add($inputCount)

$form.Controls.Add((New-Label "工作时长(分钟):" 20 55))
$inputWork = New-NumberInput 150 53 1 180 25
$form.Controls.Add($inputWork)

$form.Controls.Add((New-Label "休息时长(分钟):" 20 90))
$inputRest = New-NumberInput 150 88 1 60 5
$form.Controls.Add($inputRest)

# ---------- 状态显示 ----------
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = if (Test-AudioFiles) { "准备就绪" } else { "警告：缺少音频文件" }
$labelStatus.Location = New-Object System.Drawing.Point(20, 130)
$labelStatus.AutoSize = $true
$labelStatus.ForeColor = if (Test-AudioFiles) { "Blue" } else { "Red" }
$form.Controls.Add($labelStatus)

# ---------- 进度显示 ----------
$labelProgress = New-Object System.Windows.Forms.Label
$labelProgress.Text = ""
$labelProgress.Location = New-Object System.Drawing.Point(20, 155)
$labelProgress.AutoSize = $true
$labelProgress.ForeColor = "Gray"
$form.Controls.Add($labelProgress)

# ---------- 按钮 ----------
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Text = "开始"
$buttonStart.Location = New-Object System.Drawing.Point(20, 190)
$buttonStart.Size = New-Object System.Drawing.Size(120, 38)
$form.Controls.Add($buttonStart)

$buttonStop = New-Object System.Windows.Forms.Button
$buttonStop.Text = "停止"
$buttonStop.Location = New-Object System.Drawing.Point(160, 190)
$buttonStop.Size = New-Object System.Drawing.Size(120, 38)
$buttonStop.Enabled = $false
$form.Controls.Add($buttonStop)

# ---------- 后台 Job 管理 ----------
$script:CurrentJob = $null

function Stop-PomodoroJob {
    if ($script:CurrentJob) {
        Stop-Job $script:CurrentJob -ErrorAction SilentlyContinue
        Remove-Job $script:CurrentJob -ErrorAction SilentlyContinue
        $script:CurrentJob = $null
    }
}

function Set-UiRunning {
    param([bool]$Running)
    $buttonStart.Enabled = -not $Running
    $buttonStop.Enabled = $Running
}

# ---------- 按钮事件 ----------
$buttonStart.Add_Click({
    $count = [int]$inputCount.Value
    $work = [int]$inputWork.Value
    $rest = [int]$inputRest.Value

    $labelStatus.Text = "运行中..."
    $labelStatus.ForeColor = "Green"
    $labelProgress.Text = ""
    Set-UiRunning -Running $true

    $script:CurrentJob = Start-Job -ScriptBlock $TimerLogic -ArgumentList $WorkWav, $RestWav, $count, $work, $rest
})

$buttonStop.Add_Click({
    Stop-PomodoroJob
    $labelStatus.Text = "已停止"
    $labelStatus.ForeColor = "Blue"
    $labelProgress.Text = ""
    Set-UiRunning -Running $false
})

# ---------- 定时轮询 Job 输出 ----------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if (-not $script:CurrentJob) { return }

    # 读取并处理输出
    $outputs = Receive-Job $script:CurrentJob
    foreach ($line in $outputs) {
        switch -Regex ($line) {
            '^WORK\|(\d+)\|(\d+)\|(\d+)$' {
                $labelStatus.Text = "工作中..."
                $labelStatus.ForeColor = "Orange"
                $labelProgress.Text = "第 $($Matches[1])/$($Matches[2]) 轮 · $($Matches[3]) 分钟"
            }
            '^REST\|(\d+)$' {
                $labelStatus.Text = "休息中..."
                $labelStatus.ForeColor = "Cyan"
                $labelProgress.Text = "$($Matches[1]) 分钟休息"
            }
            '^DONE$' {
                $labelStatus.Text = "全部完成！"
                $labelStatus.ForeColor = "Green"
                $labelProgress.Text = ""
            }
        }
    }

    # 检查 Job 终态
    if ($script:CurrentJob.State -eq "Completed") {
        Stop-PomodoroJob
        Set-UiRunning -Running $false
    }
    elseif ($script:CurrentJob.State -eq "Failed") {
        $labelStatus.Text = "运行出错"
        $labelStatus.ForeColor = "Red"
        $labelProgress.Text = ""
        Stop-PomodoroJob
        Set-UiRunning -Running $false
    }
})
$timer.Start()

# ---------- 窗口关闭时清理 ----------
$form.Add_FormClosing({
    $timer.Stop()
    Stop-PomodoroJob
})

# ---------- 运行 ----------
[void]$form.ShowDialog()
