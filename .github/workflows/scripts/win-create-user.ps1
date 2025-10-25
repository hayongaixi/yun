<#
.SYNOPSIS
简化版：优先创建 RDP 管理员用户，基础设置中文环境，避免复杂配置冲突
#>

# 要求管理员权限
#Requires -RunAsAdministrator

try {
    # ==============================================
    # 第一部分：仅保留最基础的中文环境设置（避免冲突）
    # ==============================================
    Write-Host "`n===== 开始基础中文环境设置 =====" -ForegroundColor Cyan

    # 1. 导入国际设置模块
    Import-Module International -ErrorAction Stop

    # 2. 设置系统首选语言为中文（简体）（核心显示语言）
    Write-Host "设置系统语言为中文（简体）..."
    $chineseLang = New-WinUserLanguageList -Language "zh-CN"
    Set-WinUserLanguageList -LanguageList $chineseLang -Force -ErrorAction Stop

    # 3. 设置区域格式为中文（中国）（控制日期、时间格式）
    Write-Host "设置区域格式为中文（中国）..."
    Set-Culture -CultureInfo "zh-CN" -ErrorAction Stop

    # 暂时移除“设置国家/地区”和“注册表操作”（避免触发异常）
    Write-Host "跳过可能引发冲突的国家/地区和注册表设置`n" -ForegroundColor Yellow


    # ==============================================
    # 第二部分：确保 RDP 用户创建（核心功能）
    # ==============================================
    Write-Host "===== 开始创建 RDP 管理员用户 =====" -ForegroundColor Cyan

    $userName = "administrator"
    $plainPassword = "Pass@Word1"

    # 转换密码为安全字符串
    Write-Host "准备用户密码..."
    $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    # 创建本地用户（若已存在则忽略错误，避免重复创建失败）
    Write-Host "创建/验证用户 $userName..."
    $existingUser = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        New-LocalUser -Name $userName -Password $securePass -AccountNeverExpires -ErrorAction Stop
    } else {
        Write-Host "用户 $userName 已存在，跳过创建" -ForegroundColor Yellow
    }

    # 赋予管理员和远程登录权限
    Write-Host "赋予用户权限..."
    Add-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction Stop
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $userName -ErrorAction Stop

    # 记录凭据到环境变量
    Write-Host "记录登录凭据..."
    echo "RDP_CREDS=User: $userName | Password: $plainPassword" >> $env:GITHUB_ENV

    # 最终验证
    if (-not (Get-LocalUser -Name $userName -ErrorAction Stop)) {
        throw "用户 $userName 验证失败"
    }

    Write-Host "`n核心操作完成！`n- 基础中文环境已设置（需注销生效）`n- RDP 用户 $userName 已就绪" -ForegroundColor Green
}
catch {
    Write-Host "`n操作失败: $_" -ForegroundColor Red
    exit 1
}
