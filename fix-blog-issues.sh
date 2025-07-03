#!/bin/bash

# 博客问题修复脚本
# 修复图片路径、文件名和英文内容问题

set -e

# 配置变量
BLOG_DIR="/Users/hxz/code/Aster.github.io"
ZH_POSTS_DIR="$BLOG_DIR/content/zh/posts"
EN_POSTS_DIR="$BLOG_DIR/content/en/posts"
STATIC_DIR="$BLOG_DIR/static"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 博客问题修复工具${NC}"
echo "=================================================="

# 1. 修复图片路径问题
fix_image_paths() {
    echo -e "${YELLOW}📸 修复图片路径问题...${NC}"
    
    find "$ZH_POSTS_DIR" -name "*.md" | while read -r file; do
        if [[ -f "$file" ]]; then
            # 获取文件名（不含扩展名）
            filename=$(basename "$file" .md)
            
            # 检查是否有对应的图片目录
            img_dir="$STATIC_DIR/images/$filename"
            if [[ -d "$img_dir" ]]; then
                # 修复文章中的图片路径
                # 将相对路径和URL编码路径替换为正确的路径
                sed -i '' -E "s|!\[([^\]]*)\]\([^)]*[/\\]([^/\\)]+\.(png|jpg|jpeg|gif|webp|svg))\)|![\1](/images/$filename/\2)|g" "$file"
                
                echo -e "${GREEN}  ✅ 修复图片路径: $(basename "$file")${NC}"
            fi
        fi
    done
}

# 2. 修复文件名问题
fix_filenames() {
    echo -e "${YELLOW}📝 修复文件名问题...${NC}"
    
    find "$ZH_POSTS_DIR" -name "*.md" | while read -r file; do
        filename=$(basename "$file")
        
        # 检查是否是问题文件名（只有符号或过短）
        if [[ "$filename" =~ ^[-_.]+\.md$ ]] || [[ "${#filename}" -lt 5 ]]; then
            # 从文件内容中提取标题
            title=$(grep -m 1 '^title:' "$file" | sed 's/^title: *["'"'"']*\(.*\)["'"'"']*$/\1/')
            
            if [[ -n "$title" ]]; then
                # 生成新的文件名
                new_filename=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]' | cut -c1-50).md
                new_filepath="$ZH_POSTS_DIR/$new_filename"
                
                # 避免重名
                counter=1
                while [[ -f "$new_filepath" ]]; do
                    new_filename=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]' | cut -c1-45)-$counter.md
                    new_filepath="$ZH_POSTS_DIR/$new_filename"
                    counter=$((counter + 1))
                done
                
                mv "$file" "$new_filepath"
                echo -e "${GREEN}  ✅ 重命名: $filename -> $new_filename${NC}"
            fi
        fi
    done
}

# 3. 创建英文版本
create_english_versions() {
    echo -e "${YELLOW}🌐 创建英文版本...${NC}"
    
    # 确保英文目录存在
    mkdir -p "$EN_POSTS_DIR"
    
    # 复制重要文章到英文版本
    important_articles=(
        "webrtc-"
        "deepspeed-"
        "tcp-"
        "sctp-"
        "mysql-"
        "kafka-"
        "k8s-"
        "go-"
    )
    
    for pattern in "${important_articles[@]}"; do
        find "$ZH_POSTS_DIR" -name "*$pattern*.md" | head -3 | while read -r zh_file; do
            if [[ -f "$zh_file" ]]; then
                filename=$(basename "$zh_file")
                en_file="$EN_POSTS_DIR/$filename"
                
                # 如果英文版本不存在，创建一个
                if [[ ! -f "$en_file" ]]; then
                    # 复制文件并修改语言相关内容
                    cp "$zh_file" "$en_file"
                    
                    # 修改Front Matter中的语言相关内容
                    sed -i '' 's/tags: \[/tags: [/' "$en_file"
                    sed -i '' 's/author: "Aster"/author: "Aster"/' "$en_file"
                    
                    echo -e "${GREEN}  ✅ 创建英文版本: $filename${NC}"
                fi
            fi
        done
    done
}

# 4. 清理重复和无效文件
cleanup_files() {
    echo -e "${YELLOW}🧹 清理无效文件...${NC}"
    
    # 删除空文件
    find "$ZH_POSTS_DIR" -name "*.md" -size 0 -delete 2>/dev/null || true
    
    # 删除没有title的文件
    find "$ZH_POSTS_DIR" -name "*.md" -exec grep -L "title:" {} \; | while read -r file; do
        echo -e "${RED}  🗑️  删除无效文件: $(basename "$file")${NC}"
        rm -f "$file"
    done
    
    # 清理图片目录中的重复文件
    find "$STATIC_DIR/images" -name "*.csv" -delete 2>/dev/null || true
    find "$STATIC_DIR/images" -name "*_all.csv" -delete 2>/dev/null || true
}

# 5. 优化图片目录结构
optimize_image_structure() {
    echo -e "${YELLOW}🖼️ 优化图片目录结构...${NC}"
    
    # 移动孤立的图片到对应目录
    find "$STATIC_DIR/images" -maxdepth 1 -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | while read -r img; do
        img_name=$(basename "$img")
        # 创建通用图片目录
        mkdir -p "$STATIC_DIR/images/common"
        mv "$img" "$STATIC_DIR/images/common/"
        echo -e "${GREEN}  📁 移动图片到通用目录: $img_name${NC}"
    done
}

# 6. 生成修复报告
generate_report() {
    echo -e "${BLUE}📊 生成修复报告...${NC}"
    
    zh_posts=$(find "$ZH_POSTS_DIR" -name "*.md" | wc -l)
    en_posts=$(find "$EN_POSTS_DIR" -name "*.md" | wc -l)
    total_images=$(find "$STATIC_DIR/images" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) | wc -l)
    
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 修复完成！统计报告：${NC}"
    echo "=================================================="
    echo "📝 中文文章数: $zh_posts"
    echo "🌐 英文文章数: $en_posts"
    echo "🖼️ 图片文件数: $total_images"
    echo "📁 博客目录: $BLOG_DIR"
    echo "🌐 本地预览: hugo server -D"
    echo "=================================================="
}

# 主执行流程
main() {
    echo "🔍 开始修复博客问题..."
    echo ""
    
    # 询问用户确认
    read -p "🤔 是否开始修复？这将修改文件名和图片路径 (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ 用户取消操作"
        exit 0
    fi
    
    # 执行修复步骤
    fix_image_paths
    fix_filenames
    create_english_versions
    cleanup_files
    optimize_image_structure
    
    generate_report
    
    echo ""
    echo -e "${GREEN}✨ 所有修复完成！建议运行 'hugo server -D' 测试效果${NC}"
}

# 运行主函数
main "$@"
