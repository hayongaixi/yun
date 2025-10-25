<#
.SYNOPSIS
合并脚本：设置系统语言区域为中文（中国）、执行注册表操作，并创建 RDP 管理员用户
#>

# 要求管理员权限
#Requires -RunAsAdministrator

try {
    # ==============================================
    # 第一部分：设置系统语言、区域和注册表
    # ==============================================
    Write-Host "`n===== 开始设置系统语言和区域 =====" -ForegroundColor Cyan

    # 1. 导入国际设置模块
    Import-Module International -ErrorAction Stop

    # 2. 设置系统首选语言为中文（简体）
    Write-Host "设置系统语言为中文（简体）..."
    $chineseLang = New-WinUserLanguageList -Language "zh-CN"
    Set-WinUserLanguageList -LanguageList $chineseLang -Force -ErrorAction Stop

    # 3. 设置区域格式为中文（中国）（控制日期、时间、数字格式）
    Write-Host "设置区域格式为中文（中国）..."
    Set-Culture -CultureInfo "zh-CN" -ErrorAction Stop

    # 4. 设置国家/地区为中国（简化操作，避免GeoID警告）
    Write-Host "设置国家/地区为中国..."
    Set-WinHomeLocation -GeoId 286 -ErrorAction Stop  # 286为中国GeoID

    # 5. 移除可能引发异常的系统区域设置（服务器环境非必需）
    # （原Set-WinSystemLocale命令在此处删除，避免冲突）

    # 6. 执行注册表操作
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

    $userName = "administrator"
    $plainPassword = "Pass@Word1"

    # 转换密码为安全字符串
    Write-Host "准备用户密码..."
    $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    # 创建本地用户
    Write-Host "创建用户 $userName..."
    New-LocalUser -Name $userName -Password $securePass -AccountNeverExpires -ErrorAction Stop

    # 赋予权限
    Write-Host "赋予用户管理员权限和远程登录权限..."
    Add-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction Stop
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $userName -ErrorAction Stop

    # 记录凭据
    Write-Host "记录登录凭据..."
    echo "RDP_CREDS=User: $userName | Password: $plainPassword" >> $env:GITHUB_ENV

    # 验证用户创建
    if (-not (Get-LocalUser -Name $userName -ErrorAction Stop)) {
        throw "用户 $userName 创建失败"
    }

    Write-Host "`n所有操作完成！`n- 系统语言区域已设置为中文（中国）`n- RDP 用户 $userName 创建成功`n部分设置需注销后生效。" -ForegroundColor Green
}
catch {
    Write-Host "`n操作失败: $_" -ForegroundColor Red
    exit 1
}
