#!/bin/bash
# 极简版：仅启动Shadowsocks+frp隧道，不依赖systemctl
set -e

# ==============================================
# 1. 安装必要依赖（仅Shadowsocks+frp所需）
# ==============================================
echo -e "\n===== 安装依赖 ====="
sudo apt install -y shadowsocks-libev net-tools ufw  # ufw用于开放端口

# ==============================================
# 2. 配置Shadowsocks（本地端口22222，frp转发用）
# ==============================================
CONFIG_PATH="/etc/shadowsocks-libev/config.json"
sudo tee "$CONFIG_PATH" << EOF
{
    "server":["0.0.0.0"],  # 监听所有本地IP，允许frp转发
    "mode":"tcp_and_udp",
    "server_port":22222,   # 本地端口（frp要转发的端口）
    "local_port":1080,
    "password":"Pass@Word1",
    "timeout":86400,
    "method":"chacha20-ietf-poly1305"
}
EOF
echo "✅ Shadowsocks配置完成"

# ==============================================
# 3. 开放防火墙（关键！允许frp访问22222端口）
# ==============================================
echo -e "\n===== 开放防火墙端口 ====="
sudo ufw allow 22222/tcp
sudo ufw allow 22222/udp
sudo ufw reload
echo "✅ 已开放22222端口（TCP+UDP）"

# ==============================================
# 4. 启动Shadowsocks（修复日志权限：用用户目录日志）
# ==============================================
echo -e "\n===== 启动Shadowsocks ====="
# 杀死旧进程（避免端口占用）
sudo pkill -f ss-server || true
# 日志路径改成用户目录（~/代表当前用户目录，有写入权限）
nohup ss-server -c "$CONFIG_PATH" > ~/ss.log 2>&1 &
sleep 3  # 等待启动
# 验证是否启动成功
if pgrep ss-server >/dev/null; then
    echo "✅ Shadowsocks启动成功（PID: $(pgrep ss-server)）"
else
    echo "❌ Shadowsocks启动失败，查看日志：cat ~/ss.log"
    exit 1
fi

# ==============================================
# 5. 启动frp隧道（转发22222到frp服务器55555端口）
# ==============================================
echo -e "\n===== 启动frp隧道 ====="
FRP_BIN="mefrpc"  # 你的frp客户端文件名（必须和仓库里一致）
FRP_PATH=".github/workflows/scripts/$FRP_BIN"
# 绝对路径兜底（防止相对路径找不到）
ABS_FRP_PATH="/home/runner/work/$(basename $GITHUB_REPOSITORY)/$(basename $GITHUB_REPOSITORY)/$FRP_PATH"

# 查找并启动frp
if [ -f "$FRP_PATH" ]; then
    chmod +x "$FRP_PATH"
elif [ -f "$ABS_FRP_PATH" ]; then
    FRP_PATH="$ABS_FRP_PATH"
    chmod +x "$FRP_PATH"
else
    echo "❌ 未找到frp客户端（文件名为$FRP_BIN），请确认路径和文件名"
    exit 1
fi

# 启动frp（日志也用用户目录，避免权限问题）
nohup "$FRP_PATH" -t bab042f57c6e615bc8692773cf2386dc -p 55555 > ~/frp.log 2>&1 &
sleep 3
if pgrep "$FRP_BIN" >/dev/null; then
    echo "✅ frp隧道启动成功（PID: $(pgrep $FRP_BIN)）"
else
    echo "❌ frp启动失败，查看日志：cat ~/frp.log"
    exit 1
fi

echo -e "\n===== 代理服务已全部启动！====="
