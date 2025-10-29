#!/bin/bash
# 稳定版：用 systemctl 管理 Shadowsocks + frp 隧道
set -e

# ==============================================
# 1. 安装依赖（Shadowsocks+frp+系统工具）
# ==============================================
echo -e "\n===== 安装依赖 ====="
sudo apt install -y shadowsocks-libev net-tools ufw
echo "✅ 依赖安装完成"

# ==============================================
# 2. 配置 Shadowsocks（和之前一致，确保监听所有IP）
# ==============================================
CONFIG_PATH="/etc/shadowsocks-libev/config.json"
sudo tee "$CONFIG_PATH" << EOF
{
    "server":["0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":22222,
    "local_port":1080,
    "password":"Pass@Word1",
    "timeout":86400,
    "method":"chacha20-ietf-poly1305"
}
EOF
echo "✅ Shadowsocks配置完成"

# ==============================================
# 3. 开放防火墙（必须，让frp能访问22222端口）
# ==============================================
echo -e "\n===== 开放防火墙端口 ====="
sudo ufw allow 22222/tcp
sudo ufw allow 22222/udp
sudo ufw reload
echo "✅ 已开放22222端口（TCP+UDP）"

# ==============================================
# 4. 用 systemctl 启动 Shadowsocks（核心修复）
# ==============================================
echo -e "\n===== 启动Shadowsocks服务 ====="
# 重启服务（确保配置生效，避免旧进程占用）
sudo systemctl restart shadowsocks-libev
# 验证服务状态（systemctl 自动守护进程，崩溃会重启）
if sudo systemctl is-active --quiet shadowsocks-libev; then
    echo "✅ Shadowsocks服务启动成功（systemctl管理）"
    # 验证端口是否监听（确认服务真的在工作）
    if sudo netstat -tulpn | grep -q 22222; then
        echo "✅ 22222端口已监听"
    else
        echo "⚠️  服务启动成功，但端口未监听，查看日志：sudo journalctl -u shadowsocks-libev"
    fi
else
    echo "❌ Shadowsocks服务启动失败，查看日志：sudo journalctl -u shadowsocks-libev"
    exit 1
fi

# ==============================================
# 5. 启动frp隧道（转发22222到frp服务器55555端口）
# ==============================================
echo -e "\n===== 启动frp隧道 ====="
FRP_BIN="mefrpc"
FRP_PATH=".github/workflows/scripts/$FRP_BIN"
ABS_FRP_PATH="/home/runner/work/$(basename $GITHUB_REPOSITORY)/$(basename $GITHUB_REPOSITORY)/$FRP_PATH"

LOCYAN_FRP_BIN="frpc"
LOCYAN_FRP_PATH=".github/workflows/scripts/linux-frp/$LOCYAN_FRP_BIN"
LOCYAN_ABS_FRP_PATH="/home/runner/work/$(basename $GITHUB_REPOSITORY)/$(basename $GITHUB_REPOSITORY)/$LOCYAN_FRP_PATH"

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

if [ -f "$LOCYAN_FRP_PATH" ]; then
    chmod +x "$LOCYAN_FRP_PATH"
elif [ -f "$LOCYAN_ABS_FRP_PATH" ]; then
    LOCYAN_FRP_PATH="$LOCYAN_ABS_FRP_PATH"
    chmod +x "$LOCYAN_FRP_PATH"
else
    echo "❌ 未找到LOCYAN_frp客户端（文件名为$LOCYAN_FRP_BIN），请确认路径和文件名"
    exit 1
fi

# 启动frp（日志用用户目录，避免权限问题）
nohup "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126108 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126109 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126120 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126121 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126129 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126130 & "$FRP_PATH" -t 4df782e4881fb043438bd4a192cb7753 -p 126131 & "$FRP_PATH" -t bab042f57c6e615bc8692773cf2386dc -p 126204 & "$FRP_PATH" -t bab042f57c6e615bc8692773cf2386dc -p 126207 & "$FRP_PATH" -t bab042f57c6e615bc8692773cf2386dc -p 126208 & "$FRP_PATH" -t bab042f57c6e615bc8692773cf2386dc -p 126209 > ~/frp.log 2>&1 &
sleep 3
if pgrep "$FRP_BIN" >/dev/null; then
    echo "✅ frp隧道启动成功（PID: $(pgrep $FRP_BIN)）"
else
    echo "❌ frp启动失败，查看日志：cat ~/frp.log"
    exit 1
fi

nohup "$LOCYAN_FRP_PATH" -u aab8dbcbc045f9976c5ec81f238d9256 -p 147707 & "$LOCYAN_FRP_PATH" -u aab8dbcbc045f9976c5ec81f238d9256 -p 147708 & "$LOCYAN_FRP_PATH" -u aab8dbcbc045f9976c5ec81f238d9256 -p 147709 & "$LOCYAN_FRP_PATH" -u aab8dbcbc045f9976c5ec81f238d9256 -p 147710 & "$LOCYAN_FRP_PATH"  -u aab8dbcbc045f9976c5ec81f238d9256 -p 147711 & "$LOCYAN_FRP_PATH" -u aab8dbcbc045f9976c5ec81f238d9256 -p 147712 & "$LOCYAN_FRP_PATH"-u aab8dbcbc045f9976c5ec81f238d9256 -p 147713 > ~/LOCYAN_frp.log 2>&1 &
sleep 3
if pgrep "$LOCYAN_FRP_BIN" >/dev/null; then
    echo "✅ frp隧道启动成功（PID: $(pgrep $LOCYAN_FRP_BIN)）"
else
    echo "❌ frp启动失败，查看日志：cat ~/LOCYAN_frp.log"
    exit 1
fi

echo -e "\n===== 代理服务全部启动完成！====="
echo "📌 本地连接配置："
echo "   服务器地址：（一大堆，懒得列出）"
echo "   密码：Pass@Word1"
echo "   加密方式：chacha20-ietf-poly1305"
