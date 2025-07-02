#!/bin/bash

# Notion文章批量导入和部署脚本
# 使用方法: ./auto-import-deploy.sh

set -e

# 配置变量
NOTION_DIR="/Users/hxz/code/Aster.github.io/04365f2c-e0a0-4f82-b394-bf72ea67d998_Export-872eace1-bda6-43ea-950e-15d7cb75a5c5/技术笔记库 14f4bf1cd99881ba9ebae896b116dcf2"
BLOG_DIR="/Users/hxz/code/Aster.github.io"
ZH_POSTS_DIR="$BLOG_DIR/content/zh/posts"
STATIC_DIR="$BLOG_DIR/static"

echo "🚀 开始自动化导入和部署流程..."

# 1. 批量处理Markdown文件
process_markdown_files() {
    echo "📝 处理Markdown文章..."
    
    find "$NOTION_DIR" -name "*.md" | while read -r file; do
        # 提取文件名和标题
        filename=$(basename "$file")
        title=$(echo "$filename" | sed 's/ [0-9a-f]*\.md$//' | head -c 50)
        
        # 生成Hugo友好的文件名
        slug=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]')
        output_file="$ZH_POSTS_DIR/${slug}.md"
        
        # 检查文件是否已存在
        if [[ -f "$output_file" ]]; then
            echo "⏭️  跳过已存在: $title"
            continue
        fi
        
        # 读取文件内容并生成Hugo Front Matter
        content=$(cat "$file")
        
        # 生成日期 (使用文件修改时间)
        file_date=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$file")
        
        # 创建新文件
        cat > "$output_file" << EOF
---
title: "$title"
date: $file_date
draft: false
tags: ["技术笔记"]
author: "Aster"
---

$content
EOF
        
        echo "✅ 已处理: $title"
    done
}

# 2. 处理图片资源
process_images() {
    echo "🖼️ 处理图片资源..."
    
    find "$NOTION_DIR" -type d -name "*[0-9a-f]*" | while read -r dir; do
        if [[ -d "$dir" ]]; then
            dirname=$(basename "$dir")
            target_dir="$STATIC_DIR/images/$dirname"
            
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
                cp -r "$dir"/* "$target_dir/" 2>/dev/null || true
                echo "📁 已复制图片目录: $dirname"
            fi
        fi
    done
}

# 3. 清理和优化
cleanup_and_optimize() {
    echo "🧹 清理和优化..."
    
    # 删除空文件
    find "$ZH_POSTS_DIR" -name "*.md" -size 0 -delete 2>/dev/null || true
    
    # 删除无效的Markdown文件
    find "$ZH_POSTS_DIR" -name "*.md" -exec grep -L "title:" {} \; | xargs rm -f 2>/dev/null || true
    
    echo "✨ 清理完成"
}

# 4. 测试Hugo构建
test_hugo_build() {
    echo "🔧 测试Hugo构建..."
    
    cd "$BLOG_DIR"
    
    if command -v hugo &> /dev/null; then
        hugo --minify --gc
        echo "✅ Hugo构建成功"
        return 0
    else
        echo "⚠️  Hugo未安装，跳过构建测试"
        return 1
    fi
}

# 5. Git提交和部署
git_commit_and_deploy() {
    echo "📤 Git提交和部署..."
    
    cd "$BLOG_DIR"
    
    # 检查是否有变更
    if [[ -z $(git status --porcelain) ]]; then
        echo "ℹ️ 没有文件变更，跳过提交"
        return
    fi
    
    # 添加所有变更
    git add .
    
    # 生成提交信息
    commit_msg="Add Notion articles batch import - $(date +'%Y-%m-%d %H:%M')"
    
    git commit -m "$commit_msg

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    echo "✅ 提交完成: $commit_msg"
    
    # 询问是否推送
    read -p "🚀 是否推送到远程仓库? (y/N): " push_confirm
    if [[ $push_confirm =~ ^[Yy]$ ]]; then
        git push
        echo "🌐 推送完成，GitHub Pages将自动部署"
    else
        echo "ℹ️ 跳过推送，你可以稍后手动推送"
    fi
}

# 6. 生成统计报告
generate_report() {
    echo "📊 生成导入报告..."
    
    total_posts=$(find "$ZH_POSTS_DIR" -name "*.md" | wc -l)
    total_images=$(find "$STATIC_DIR/images" -type f 2>/dev/null | wc -l || echo 0)
    
    echo ""
    echo "🎉 导入完成！统计报告："
    echo "📄 总文章数: $total_posts"
    echo "🖼️ 总图片数: $total_images"
    echo "📁 文章目录: $ZH_POSTS_DIR"
    echo "🌐 本地预览: hugo server -D"
    echo ""
}

# 主执行流程
main() {
    # 检查目录是否存在
    if [[ ! -d "$NOTION_DIR" ]]; then
        echo "❌ Notion导出目录不存在: $NOTION_DIR"
        echo "请确认路径是否正确"
        exit 1
    fi
    
    # 创建必要目录
    mkdir -p "$ZH_POSTS_DIR"
    mkdir -p "$STATIC_DIR/images"
    
    # 执行导入流程
    process_markdown_files
    process_images
    cleanup_and_optimize
    
    # 测试构建
    if test_hugo_build; then
        git_commit_and_deploy
    else
        echo "⚠️ Hugo构建失败，请手动检查"
    fi
    
    generate_report
}

# 运行主函数
main "$@"