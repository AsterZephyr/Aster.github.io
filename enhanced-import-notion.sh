#!/bin/bash

# 增强版 Notion 文章导入脚本
# 功能：智能分类、批量处理、质量检查

set -e

# 配置变量
NOTION_DIR="/Users/hxz/code/Aster.github.io/04365f2c-e0a0-4f82-b394-bf72ea67d998_Export-872eace1-bda6-43ea-950e-15d7cb75a5c5/技术笔记库 14f4bf1cd99881ba9ebae896b116dcf2"
BLOG_DIR="/Users/hxz/code/Aster.github.io"
ZH_POSTS_DIR="$BLOG_DIR/content/zh/posts"
STATIC_DIR="$BLOG_DIR/static"
BATCH_SIZE=10  # 每批处理的文章数量

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 增强版 Notion 文章导入工具${NC}"
echo "=================================================="

# 智能标签生成函数
generate_tags() {
    local title="$1"
    local content="$2"
    local tags=()
    
    # 基于标题和内容的关键词匹配
    if [[ "$title" =~ (WebRTC|RTC|实时通信) ]] || [[ "$content" =~ (WebRTC|RTC|实时通信) ]]; then
        tags+=("WebRTC" "实时通信")
    fi
    
    if [[ "$title" =~ (分布式|微服务|架构) ]] || [[ "$content" =~ (分布式|微服务|架构) ]]; then
        tags+=("分布式系统" "系统架构")
    fi
    
    if [[ "$title" =~ (数据库|MySQL|Redis|存储) ]] || [[ "$content" =~ (数据库|MySQL|Redis|存储) ]]; then
        tags+=("数据库" "存储")
    fi
    
    if [[ "$title" =~ (网络|TCP|UDP|HTTP) ]] || [[ "$content" =~ (网络|TCP|UDP|HTTP) ]]; then
        tags+=("网络协议" "网络编程")
    fi
    
    if [[ "$title" =~ (Go|Golang) ]] || [[ "$content" =~ (Go|Golang) ]]; then
        tags+=("Go语言")
    fi
    
    if [[ "$title" =~ (K8S|Kubernetes|容器|Docker) ]] || [[ "$content" =~ (K8S|Kubernetes|容器|Docker) ]]; then
        tags+=("云原生" "容器技术")
    fi
    
    if [[ "$title" =~ (性能|优化|高并发) ]] || [[ "$content" =~ (性能|优化|高并发) ]]; then
        tags+=("性能优化" "高并发")
    fi
    
    if [[ "$title" =~ (AI|机器学习|深度学习) ]] || [[ "$content" =~ (AI|机器学习|深度学习) ]]; then
        tags+=("人工智能" "机器学习")
    fi
    
    # 如果没有匹配到特定标签，使用通用标签
    if [ ${#tags[@]} -eq 0 ]; then
        tags+=("技术笔记")
    fi
    
    # 输出标签数组
    printf '%s\n' "${tags[@]}"
}

# 生成文章摘要
generate_description() {
    local content="$1"
    local title="$2"
    
    # 提取第一段作为描述，限制长度
    local first_paragraph=$(echo "$content" | grep -v '^#' | grep -v '^$' | head -1 | cut -c1-100)
    
    if [[ -n "$first_paragraph" ]]; then
        echo "$first_paragraph..."
    else
        echo "$title - 技术笔记"
    fi
}

# 检查文件质量
check_file_quality() {
    local file="$1"
    local issues=()
    
    # 检查文件大小
    local size=$(wc -c < "$file")
    if [ $size -lt 100 ]; then
        issues+=("文件过小($size bytes)")
    fi
    
    # 检查是否包含实际内容
    local content_lines=$(grep -v '^#' "$file" | grep -v '^$' | wc -l)
    if [ $content_lines -lt 3 ]; then
        issues+=("内容行数过少($content_lines lines)")
    fi
    
    # 输出问题
    if [ ${#issues[@]} -gt 0 ]; then
        echo "质量问题: ${issues[*]}"
        return 1
    fi
    
    return 0
}

# 处理单个文件
process_single_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo -e "${YELLOW}📝 处理文件: $filename${NC}"
    
    # 质量检查
    if ! check_file_quality "$file"; then
        echo -e "${RED}⚠️  跳过低质量文件: $filename${NC}"
        return 1
    fi
    
    # 提取标题（去掉 Notion ID）
    local title=$(echo "$filename" | sed 's/ [a-f0-9]\{32\}\.md$//')
    
    # 生成 slug（URL友好的文件名）
    local slug=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]')
    
    # 目标文件路径
    local target_file="$ZH_POSTS_DIR/${slug}.md"
    
    # 检查是否已存在
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}⏭️  跳过已存在: $title${NC}"
        return 0
    fi
    
    # 读取文件内容
    local content=$(cat "$file")
    
    # 生成智能标签
    local tags_array=($(generate_tags "$title" "$content"))
    local tags_str=""
    for tag in "${tags_array[@]}"; do
        tags_str="$tags_str\"$tag\", "
    done
    tags_str=${tags_str%, }  # 移除最后的逗号和空格
    
    # 生成描述
    local description=$(generate_description "$content" "$title")
    
    # 获取文件修改时间
    local file_date=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$file")
    
    # 创建新文件
    cat > "$target_file" << EOF
---
title: "$title"
date: $file_date
draft: false
tags: [$tags_str]
author: "Aster"
description: "$description"
---

$content
EOF
    
    echo -e "${GREEN}✅ 已处理: $title${NC}"
    
    # 处理对应的图片文件夹
    local img_dir="${file%.md}"
    if [ -d "$img_dir" ]; then
        local static_img_dir="$STATIC_DIR/images/$slug"
        mkdir -p "$static_img_dir"
        
        # 复制图片并优化路径
        if cp -r "$img_dir"/* "$static_img_dir/" 2>/dev/null; then
            echo -e "${GREEN}📸 图片已复制到: $static_img_dir${NC}"
            
            # 更新文章中的图片路径
            sed -i '' "s|$img_dir/|/images/$slug/|g" "$target_file"
        fi
    fi
    
    return 0
}

# 批量处理文件
batch_process() {
    local batch_num="$1"
    local start_index="$2"
    
    echo -e "${BLUE}📦 开始处理第 $batch_num 批文章...${NC}"
    
    local processed=0
    local skipped=0
    local errors=0
    
    find "$NOTION_DIR" -name "*.md" -type f | tail -n +$start_index | head -n $BATCH_SIZE | while read -r file; do
        if process_single_file "$file"; then
            processed=$((processed + 1))
        else
            skipped=$((skipped + 1))
        fi
    done
    
    echo -e "${GREEN}✨ 第 $batch_num 批处理完成${NC}"
    echo "   处理: $processed 篇"
    echo "   跳过: $skipped 篇"
}

# 生成统计报告
generate_report() {
    echo -e "${BLUE}📊 生成统计报告...${NC}"
    
    local total_posts=$(find "$ZH_POSTS_DIR" -name "*.md" | wc -l)
    local total_images=$(find "$STATIC_DIR/images" -type f 2>/dev/null | wc -l || echo 0)
    local notion_files=$(find "$NOTION_DIR" -name "*.md" | wc -l)
    
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 导入统计报告${NC}"
    echo "=================================================="
    echo "📄 Notion文件总数: $notion_files"
    echo "📝 已导入文章数: $total_posts"
    echo "🖼️ 已处理图片数: $total_images"
    echo "📁 文章目录: $ZH_POSTS_DIR"
    echo "🌐 本地预览: hugo server -D"
    echo "=================================================="
}

# 主函数
main() {
    # 检查目录
    if [[ ! -d "$NOTION_DIR" ]]; then
        echo -e "${RED}❌ Notion导出目录不存在: $NOTION_DIR${NC}"
        exit 1
    fi
    
    # 创建必要目录
    mkdir -p "$ZH_POSTS_DIR"
    mkdir -p "$STATIC_DIR/images"
    
    # 获取总文件数
    local total_files=$(find "$NOTION_DIR" -name "*.md" | wc -l)
    local total_batches=$(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))
    
    echo "📊 发现 $total_files 个Markdown文件"
    echo "📦 将分 $total_batches 批处理，每批 $BATCH_SIZE 个文件"
    echo ""
    
    # 询问用户确认
    read -p "🤔 是否开始导入？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ 用户取消操作"
        exit 0
    fi
    
    # 分批处理
    for ((batch=1; batch<=total_batches; batch++)); do
        local start_index=$(( (batch - 1) * BATCH_SIZE + 1 ))
        batch_process $batch $start_index
        
        # 每批处理后询问是否继续
        if [ $batch -lt $total_batches ]; then
            echo ""
            read -p "🤔 是否继续处理下一批？(Y/n): " continue_confirm
            if [[ $continue_confirm =~ ^[Nn]$ ]]; then
                echo "⏸️  用户暂停处理"
                break
            fi
        fi
    done
    
    generate_report
}

# 运行主函数
main "$@"
