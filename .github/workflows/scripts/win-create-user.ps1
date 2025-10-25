<#
.SYNOPSIS
合并脚本：设置系统语言区域为中文（中国）、执行注册表操作，并创建 RDP 管理员用户
#>

# 要求管理员权限（系统设置和用户创建均需管理员权限）
#Requires -RunAsAdministrator

try {
    # ==============================================
    # 第一部分：设置系统语言、区域和注册表
    # ==============================================
    Write-Host "`n===== 开始设置系统语言和区域 =====" -ForegroundColor Cyan

    # 1. 导入国际设置模块
    Import-Module International -ErrorAction Stop

    # 2. 设置系统首选语言为中文（简体）- 移除无效的 Speech/Handwriting 属性赋值
    Write-Host "设置系统语言为中文（简体）..."
    $chineseLang = New-WinUserLanguageList -Language "zh-CN"
    Set-WinUserLanguageList -LanguageList $chineseLang -Force -ErrorAction Stop

    # 3. 设置区域格式为中文（中国）
    Write-Host "设置区域格式为中文（中国）..."
    Set-Culture -CultureInfo "zh-CN" -ErrorAction Stop

    # 4. 设置国家/地区为中国
    Write-Host "设置国家/地区为中国..."
    Set-WinHomeLocation -GeoId 286  # 286 是中国的 GeoID
    Set-WinSystemLocale -SystemLocale "zh-CN" -ErrorAction Stop

    # 5. 执行指定的注册表操作（HKCU 对应当前用户）
    Write-Host "执行注册表添加命令..."
    $regPath = "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    $regResult = reg add "$regPath" /f /ve 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "注册表操作失败: $regResult"
    }

    Write-Host "系统语言、区域和注册表操作完成`n" -ForegroundColor Green


    # ==============================================
    # 第二部分：创建 RDP 管理员用户
    # ==============================================
    Write-Host "===== 开始创建 RDP 管理员用户 =====" -ForegroundColor Cyan

    # 1. 定义用户名和密码（使用指定的密码）
    $userName = "administrator"
    $plainPassword = "Pass@Word1"

    # 2. 转换密码为安全字符串
    Write-Host "准备用户密码..."
    $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    # 3. 创建本地用户（账户永不过期）
    Write-Host "创建用户 $userName..."
    New-LocalUser -Name $userName -Password $securePass -AccountNeverExpires -ErrorAction Stop

    # 4. 添加到管理员组和远程桌面用户组
    Write-Host "赋予用户管理员权限和远程登录权限..."
    Add-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction Stop
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $userName -ErrorAction Stop

    # 5. 记录凭据到 GitHub 环境变量
    Write-Host "记录登录凭据..."
    echo "RDP_CREDS=User: $userName | Password: $plainPassword" >> $env:GITHUB_ENV

    # 6. 验证用户是否创建成功
    if (-not (Get-LocalUser -Name $userName -ErrorAction Stop)) {
        throw "用户 $userName 创建失败"
    }

    Write-Host "`n所有操作完成！`n- 系统语言区域已设置为中文（中国）`n- RDP 用户 $userName 创建成功`n部分设置需注销后生效。" -ForegroundColor Green
}
catch {
    Write-Host "`n操作失败: $_" -ForegroundColor Red
    exit 1
}
