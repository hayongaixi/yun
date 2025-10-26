#!/bin/bash
# 功能：安装 shadowsocks-libev + 配置服务 + 启动 frp 客户端
set -e  # 遇到错误立即退出

# ==============================================
# 1. 安装 shadowsocks-libev
# ==============================================
echo -e "\n===== 开始安装 shadowsocks-libev ====="
sudo apt update -y
sudo apt install shadowsocks-libev -y
echo "✅ shadowsocks-libev 安装完成"

# ==============================================
# 2. 配置文件写入（必须用 sudo tee，否则权限不足）
# ==============================================
echo -e "\n===== 配置 shadowsocks-libev ====="
CONFIG_PATH="/etc/shadowsocks-libev/config.json"

# 备份原有配置（若存在）
if [ -f "$CONFIG_PATH" ]; then
    sudo cp "$CONFIG_PATH" "${CONFIG_PATH}.bak"
    echo "📋 已备份原有配置到 ${CONFIG_PATH}.bak"
fi

# 关键：用 sudo tee 写入，绝对不能用 sudo cat >
sudo tee "$CONFIG_PATH" << EOF
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
cat "$CONFIG_PATH"

# ==============================================
# 3. 重启服务
# ==============================================
echo -e "\n===== 重启 shadowsocks-libev 服务 ====="
sudo systemctl restart shadowsocks-libev
if sudo systemctl is-active --quiet shadowsocks-libev; then
    echo "✅ shadowsocks-libev 服务已启动"
else
    echo "❌ shadowsocks-libev 服务启动失败"
    exit 1
fi

# ==============================================
# 4. 启动 frp 客户端（适配 GitHub Actions 路径）
# ==============================================
echo -e "\n===== 启动 frp 客户端 ====="
FRP_PATH=".github/workflows/scripts/mefrpc"
ABS_FRP_PATH="/home/runner/work/$(basename $GITHUB_REPOSITORY)/$(basename $GITHUB_REPOSITORY)/$FRP_PATH"

# 路径检测 + 执行权限
if [ -f "$FRP_PATH" ]; then
    chmod +x "$FRP_PATH"
    echo "✅ 找到 frp 客户端（相对路径）"
elif [ -f "$ABS_FRP_PATH" ]; then
    FRP_PATH="$ABS_FRP_PATH"
    chmod +x "$FRP_PATH"
    echo "✅ 找到 frp 客户端（绝对路径）"
else
    echo "❌ 未找到 frp 客户端，跳过启动（不影响 shadowsocks 使用）"
    exit 0  # 若 frp 非必需，可改为 exit 0 避免脚本失败
fi

# 后台启动 frp
nohup sh -c "$FRP_PATH -t bab042f57c6e615bc8692773cf2386dc -p 124913" > /dev/null 2>&1 &
echo "✅ frp 客户端已后台启动"
echo -e "\n===== 所有操作执行完成！====="
