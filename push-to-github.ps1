# 一键把 github-test 推送到 GitHub
#
# 用法（在你自己的 PowerShell 窗口里运行）：
#     cd "C:\Users\zjq\Documents\deepseek-harness\default-workspace\github-test"
#     powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 -RepoName "github-test"
#
# 如果你的仓库名不是 github-test，把 -RepoName 后面换成你实际用的名字。
# 脚本会自动用你已配置好的 git 身份拼出正确地址。

[CmdletBinding()]
param(
    # 你在 GitHub 上创建的空仓库名字
    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    # 你的 GitHub 用户名；不填则从 git 全局配置读取（当前是 zjq-alice02）
    [string]$User,

    # 只想检查、不真正推送时加上这个开关
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# --- 0. 定位仓库目录 -------------------------------------------------------
$repoDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $repoDir
Write-Host "仓库目录: $repoDir" -ForegroundColor Cyan

# --- 1. 确认这确实是 git 仓库 ---------------------------------------------
if (-not (Test-Path (Join-Path $repoDir '.git'))) {
    throw "这里不是 git 仓库（找不到 .git 目录）。请先 cd 到 github-test 再运行。"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "找不到 git 命令。请新开一个 PowerShell 窗口（旧窗口的 PATH 不会自动更新）。"
}

# --- 2. 取出 GitHub 用户名 -------------------------------------------------
if (-not $User) { $User = (& git config --global user.name).Trim() }
if (-not $User) { throw "拿不到 GitHub 用户名。请加参数 -User 你的用户名" }
Write-Host "GitHub 用户名: $User" -ForegroundColor Cyan

$remoteUrl = "https://github.com/$User/$RepoName.git"
Write-Host "远程地址: $remoteUrl" -ForegroundColor Cyan

# --- 3. 有未提交的改动就先提交 --------------------------------------------
if (& git status --porcelain) {
    Write-Host ''
    Write-Host '检测到未提交的改动，正在提交...' -ForegroundColor Yellow
    & git add .
    & git commit -m "更新内容"
}

# --- 4. 确认本地至少有一次提交 --------------------------------------------
$head = & git rev-parse --verify HEAD 2>$null
if ($LASTEXITCODE -ne 0 -or -not $head) {
    throw "本地还没有任何提交。请先 git add . 再 git commit -m '第一次提交'"
}

# --- 5. 配置远程地址 -------------------------------------------------------
if ((& git remote) -contains 'origin') {
    Write-Host 'origin 已存在，更新地址...' -ForegroundColor Yellow
    & git remote set-url origin $remoteUrl
} else {
    & git remote add origin $remoteUrl
}

# --- 6. 确保分支名是 main --------------------------------------------------
& git branch -M main

# --- 7. 推送 ---------------------------------------------------------------
if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun：已跳过推送。以上步骤全部正常。' -ForegroundColor Green
    & git remote -v
    exit 0
}

Write-Host ''
Write-Host ('=' * 58)
Write-Host ' 正在推送。首次推送会弹出浏览器窗口要求登录 GitHub，' -ForegroundColor Green
Write-Host ' 点「授权 / Authorize」即可，之后不会再问。' -ForegroundColor Green
Write-Host ('=' * 58)
Write-Host ''

& git push -u origin main
$code = $LASTEXITCODE

Write-Host ''
if ($code -eq 0) {
    Write-Host '推送成功！' -ForegroundColor Green
    Write-Host "打开看看: https://github.com/$User/$RepoName" -ForegroundColor Green
} else {
    Write-Host "推送失败（退出码 $code）。" -ForegroundColor Red
    Write-Host '把上面的报错发给我，我帮你判断。' -ForegroundColor Yellow
}
exit $code
