#!/bin/bash

# Notion 文章导入脚本
NOTION_DIR="/Users/hxz/code/Aster.github.io/04365f2c-e0a0-4f82-b394-bf72ea67d998_Export-872eace1-bda6-43ea-950e-15d7cb75a5c5/技术笔记库 14f4bf1cd99881ba9ebae896b116dcf2"
BLOG_DIR="/Users/hxz/code/Aster.github.io"
ZH_POSTS_DIR="$BLOG_DIR/content/zh/posts"
STATIC_DIR="$BLOG_DIR/static"

echo "开始处理 Notion 导出的文章..."

# 确保目标目录存在
mkdir -p "$ZH_POSTS_DIR"
mkdir -p "$STATIC_DIR"

# 计数器
count=0
processed=0

# 遍历所有 .md 文件
find "$NOTION_DIR" -name "*.md" -type f | while read -r file; do
    count=$((count + 1))
    filename=$(basename "$file")
    echo "处理第 $count 个文件: $filename"
    
    # 提取文章标题（去掉 Notion ID）
    title=$(echo "$filename" | sed 's/ [a-f0-9]\{32\}\.md$//')
    
    # 创建 slug（URL友好的文件名）
    slug=$(echo "$title" | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    # 目标文件路径
    target_file="$ZH_POSTS_DIR/${slug}.md"
    
    # 检查是否已存在
    if [ -f "$target_file" ]; then
        echo "  跳过: $title (已存在)"
        continue
    fi
    
    # 创建 Front Matter
    cat > "$target_file" << EOF
---
title: "$title"
date: $(date -Iseconds)
draft: false
tags: ["技术"]
author: "Aster"
description: "$title"
---

EOF
    
    # 添加原文内容
    cat "$file" >> "$target_file"
    
    processed=$((processed + 1))
    echo "  ✅ 已处理: $title"
    
    # 处理对应的图片文件夹
    img_dir="${file%.md}"
    if [ -d "$img_dir" ]; then
        # 创建静态图片目录
        static_img_dir="$STATIC_DIR/$slug"
        mkdir -p "$static_img_dir"
        
        # 复制图片
        cp -r "$img_dir"/* "$static_img_dir/" 2>/dev/null
        echo "  📸 图片已复制到: $static_img_dir"
    fi
    
    # 限制批次处理，避免一次性处理太多
    if [ $processed -ge 10 ]; then
        echo "本批次已处理 $processed 篇文章，请检查结果..."
        break
    fi
done

echo "批量处理完成！"
echo "处理了 $processed 篇文章"