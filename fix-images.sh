#!/bin/bash

# 修复现有文章中的图片链接
# 使用方法: ./fix-images.sh

set -e

BLOG_DIR="/Users/hxz/code/Aster.github.io"
POSTS_DIR="$BLOG_DIR/content/posts"
STATIC_IMAGES_DIR="$BLOG_DIR/static/images"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 开始修复文章图片链接...${NC}"

# 创建images目录
mkdir -p "$STATIC_IMAGES_DIR"

# 遍历所有文章
for post_file in "$POSTS_DIR"/*.md; do
    if [ -f "$post_file" ]; then
        post_name=$(basename "$post_file" .md)
        echo -e "${YELLOW}📝 检查文章: $post_name${NC}"
        
        # 查找损坏的图片链接
        broken_images=$(grep -o '!\[.*\]([^)]*\.(png\|jpg\|jpeg\|gif\|svg))' "$post_file" | grep -v '^!\[.*\](/images/' || true)
        
        if [ -n "$broken_images" ]; then
            echo "$broken_images" | while read -r img_ref; do
                # 提取图片路径和文件名
                img_path=$(echo "$img_ref" | sed 's/.*(\([^)]*\))/\1/')
                img_filename=$(basename "$img_path")
                
                echo -e "${YELLOW}  🔍 处理图片: $img_filename${NC}"
                
                # 在static目录中查找同名图片
                found_img=$(find "$BLOG_DIR/static" -name "$img_filename" -type f | head -1)
                
                if [ -n "$found_img" ]; then
                    # 计算相对于static的路径
                    relative_path=$(echo "$found_img" | sed "s|$BLOG_DIR/static||")
                    
                    # 更新文章中的图片路径
                    escaped_old_path=$(echo "$img_path" | sed 's/[[\.*^$()+?{|]/\\&/g')
                    sed -i '' "s|$escaped_old_path|$relative_path|g" "$post_file"
                    
                    echo -e "${GREEN}    ✅ 修复: $img_filename -> $relative_path${NC}"
                else
                    echo -e "${RED}    ❌ 未找到图片: $img_filename${NC}"
                fi
            done
        else
            echo -e "${GREEN}  ✅ 图片链接正常${NC}"
        fi
    fi
done

echo -e "${GREEN}🎉 图片修复完成！${NC}"
