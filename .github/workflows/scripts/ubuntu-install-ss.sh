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
