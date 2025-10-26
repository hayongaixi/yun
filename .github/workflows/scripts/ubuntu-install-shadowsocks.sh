#!/bin/bash
# 功能：安装 shadowsocks-libev + 配置服务 + 启动 frp 客户端
set -e  # 遇到错误立即退出，避免后续步骤无效执行

# ==============================================
# 1. 安装 shadowsocks-libev（自动确认依赖）
# ==============================================
echo -e "\n===== 开始安装 shadowsocks-libev ====="
sudo apt update -y  # 更新软件源（避免旧源导致安装失败）
sudo apt install shadowsocks-libev -y
echo "✅ shadowsocks-libev 安装完成"

# ==============================================
# 2. 备份原有配置 + 写入新配置文件
# ==============================================
echo -e "\n===== 配置 shadowsocks-libev ====="
CONFIG_PATH="/etc/shadowsocks-libev/config.json"

# 备份原有配置（若存在），避免覆盖后无法恢复
if [ -f "$CONFIG_PATH" ]; then
    sudo cp "$CONFIG_PATH" "${CONFIG_PATH}.bak"
    echo "📋 已备份原有配置到 ${CONFIG_PATH}.bak"
fi

# 写入用户指定的新配置（覆盖原有文件）
sudo cat > "$CONFIG_PATH" << EOF
{
    "server":["::1", "0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":22222,
    "local_port":1080,
    "password":"Pass@Word1",
    "timeout":86400,
    "method":"chacha20-ietf-poly1305"
}
EOF

echo "✅ 配置文件已更新：$CONFIG_PATH"
cat "$CONFIG_PATH"  # 打印配置确认（可选，可删除）

# ==============================================
# 3. 重启 shadowsocks-libev 服务，应用配置
# ==============================================
echo -e "\n===== 重启 shadowsocks-libev 服务 ====="
sudo systemctl restart shadowsocks-libev
# 验证服务状态（确保重启成功）
if sudo systemctl is-active --quiet shadowsocks-libev; then
    echo "✅ shadowsocks-libev 服务已启动"
else
    echo "❌ shadowsocks-libev 服务启动失败"
    exit 1
fi

# ==============================================
# 4. 启动 frp 客户端（修复路径和权限问题）
# ==============================================
echo -e "\n===== 启动 frp 客户端 ====="
# 先打印当前目录和文件列表，排查路径问题（方便调试）
echo "🔍 当前执行目录：$(pwd)"
echo "🔍 .github/workflows/scripts/ 目录内容："
ls -la .github/workflows/scripts/ 2>/dev/null || echo "该目录不存在"

# 定义 frp 路径（若相对路径不行，用绝对路径）
FRP_PATH=".github/workflows/scripts/mefrpc"
# 尝试绝对路径（GitHub Actions 中仓库默认在 /home/runner/work/仓库名/仓库名/）
ABS_FRP_PATH="/home/runner/work/$(basename $GITHUB_REPOSITORY)/$(basename $GITHUB_REPOSITORY)/$FRP_PATH"

# 优先用相对路径，若不存在则尝试绝对路径
if [ -f "$FRP_PATH" ]; then
    echo "✅ 找到 frp 客户端（相对路径）：$FRP_PATH"
    # 添加执行权限（关键！避免存在但不可执行的情况）
    chmod +x "$FRP_PATH"
elif [ -f "$ABS_FRP_PATH" ]; then
    echo "✅ 找到 frp 客户端（绝对路径）：$ABS_FRP_PATH"
    FRP_PATH="$ABS_FRP_PATH"
    chmod +x "$FRP_PATH"
else
    echo "❌ 未找到 frp 客户端！"
    echo "请确认以下路径是否存在文件："
    echo "1. 相对路径：$FRP_PATH"
    echo "2. 绝对路径：$ABS_FRP_PATH"
    exit 1
fi

# 后台启动（用绝对路径确保执行）
nohup sh -c "$FRP_PATH -t bab042f57c6e615bc8692773cf2386dc -p 124913" > /dev/null 2>&1 &
FRP_PID=$!
echo "✅ frp 客户端已后台启动（PID: $FRP_PID）"
echo -e "\n===== 所有操作执行完成！====="
