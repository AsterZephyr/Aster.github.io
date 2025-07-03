#!/bin/bash

# 快速发布脚本 - 一键测试和部署
# 使用方法: ./quick-publish.sh

set -e

BLOG_DIR="/Users/hxz/code/Aster.github.io"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 快速发布流程开始...${NC}"

cd "$BLOG_DIR"

# 1. 修复图片
echo -e "${YELLOW}🔧 修复图片链接...${NC}"
./fix-images.sh

# 2. 本地测试
echo -e "${YELLOW}🧪 启动本地测试服务器...${NC}"
hugo server -D --port 1314 &
SERVER_PID=$!

# 等待服务器启动
sleep 3

echo -e "${GREEN}✅ 本地服务器已启动: http://localhost:1314${NC}"
echo -e "${YELLOW}请在浏览器中检查网站效果，确认无误后按任意键继续...${NC}"
read -n 1 -s

# 停止本地服务器
kill $SERVER_PID 2>/dev/null || true

# 3. 提交和推送
echo -e "${YELLOW}📤 提交更改...${NC}"
git add .

# 检查是否有更改
if git diff --staged --quiet; then
    echo -e "${YELLOW}ℹ️  没有检测到更改${NC}"
else
    echo -e "${BLUE}📝 请输入提交信息 (直接回车使用默认信息):${NC}"
    read -r commit_message
    
    if [ -z "$commit_message" ]; then
        commit_message="更新博客内容和图片资源"
    fi
    
    git commit -m "$commit_message"
    git push origin main
    
    echo -e "${GREEN}✅ 已推送到远程仓库${NC}"
fi

echo -e "${GREEN}🎉 发布完成！${NC}"
echo -e "${BLUE}🌐 网站地址: https://asterzephyr.github.io${NC}"
