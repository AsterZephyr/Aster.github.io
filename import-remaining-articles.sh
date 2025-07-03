#!/bin/bash

# 导入遗漏文章的脚本
# 处理在static/images目录中的Markdown文件

set -e

# 配置变量
BLOG_DIR="/Users/hxz/code/Aster.github.io"
POSTS_DIR="$BLOG_DIR/content/posts"
STATIC_DIR="$BLOG_DIR/static"
SOURCE_DIR="$STATIC_DIR/images/技术笔记库 14f4bf1cd99881ba9ebae896b116dcf2"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 导入遗漏的文章...${NC}"

# 智能标签生成函数
generate_tags() {
    local title="$1"
    local content="$2"
    local tags=()
    
    # 基于标题和内容的关键词匹配
    if [[ "$title" =~ (图计算|反欺诈|风控) ]] || [[ "$content" =~ (图计算|反欺诈|风控) ]]; then
        tags+=("图计算" "风控系统" "反欺诈")
    fi
    
    if [[ "$title" =~ (复杂业务|模型|抽象|架构) ]] || [[ "$content" =~ (复杂业务|模型|抽象|架构) ]]; then
        tags+=("系统架构" "业务建模")
    fi
    
    if [[ "$title" =~ (工程估算|性能建模) ]] || [[ "$content" =~ (工程估算|性能建模) ]]; then
        tags+=("性能优化" "工程管理")
    fi
    
    if [[ "$title" =~ (数据指标|压测|技术方案) ]] || [[ "$content" =~ (数据指标|压测|技术方案) ]]; then
        tags+=("性能测试" "数据分析")
    fi
    
    if [[ "$title" =~ (搜索引擎|工作原理) ]] || [[ "$content" =~ (搜索引擎|工作原理) ]]; then
        tags+=("搜索引擎" "信息检索")
    fi
    
    if [[ "$title" =~ (风控系统|架构梳理) ]] || [[ "$content" =~ (风控系统|架构梳理) ]]; then
        tags+=("风控系统" "系统架构")
    fi
    
    if [[ "$title" =~ (广告|事件聚合|系统设计) ]] || [[ "$content" =~ (广告|事件聚合|系统设计) ]]; then
        tags+=("广告系统" "系统设计" "事件处理")
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

# 处理单个文件
process_single_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo -e "${YELLOW}📝 处理文件: $filename${NC}"
    
    # 提取标题（去掉 Notion ID）
    local title=$(echo "$filename" | sed 's/ [a-f0-9]\{32\}\.md$//')
    
    # 生成 slug（URL友好的文件名）
    local slug=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]')
    
    # 目标文件路径
    local target_file="$POSTS_DIR/${slug}.md"
    
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

# 主函数
main() {
    # 检查源目录是否存在
    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo -e "${RED}❌ 源目录不存在: $SOURCE_DIR${NC}"
        exit 1
    fi
    
    # 创建必要目录
    mkdir -p "$POSTS_DIR"
    
    # 处理所有Markdown文件
    local processed=0
    local skipped=0
    
    find "$SOURCE_DIR" -name "*.md" | while read -r file; do
        if process_single_file "$file"; then
            processed=$((processed + 1))
        else
            skipped=$((skipped + 1))
        fi
    done
    
    echo ""
    echo -e "${GREEN}✨ 处理完成！${NC}"
    echo "   处理: $processed 篇"
    echo "   跳过: $skipped 篇"
}

# 运行主函数
main "$@"
