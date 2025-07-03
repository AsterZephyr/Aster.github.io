# 📝 博客文章发布工作流程指南

## 🎯 概述

这套工作流程让您可以轻松添加新文章，自动处理图片，并快速发布到博客。

## 🚀 快速开始

### 方法一：添加新文章（推荐）

```bash
# 1. 创建新文章（自动生成模板）
./add-new-post.sh "Redis集群架构设计"

# 2. 从现有Markdown文件创建文章
./add-new-post.sh "Kubernetes实战指南" ./my-k8s-article.md
```

### 方法二：快速发布流程

```bash
# 一键测试和发布
./quick-publish.sh
```

## 📋 详细使用说明

### 1. 添加新文章 (`add-new-post.sh`)

**功能：**
- ✅ 自动生成Hugo格式的文章
- ✅ 智能识别并生成标签
- ✅ 自动处理图片资源
- ✅ 生成SEO友好的描述
- ✅ 可选择立即提交到Git

**使用方法：**

```bash
# 基础用法 - 创建空白文章
./add-new-post.sh "文章标题"

# 高级用法 - 从现有文件创建
./add-new-post.sh "文章标题" /path/to/your/article.md
```

**文件结构要求：**
```
your-article-folder/
├── article.md          # 主文章文件
├── images/             # 图片文件夹
│   ├── diagram1.png
│   └── screenshot.jpg
└── ...
```

**支持的图片格式：** PNG, JPG, JPEG, GIF, SVG

### 2. 修复图片链接 (`fix-images.sh`)

**功能：**
- 🔧 修复现有文章中损坏的图片链接
- 🔍 自动查找static目录中的图片
- 🔄 更新文章中的图片路径

**使用场景：**
- 导入的文章图片路径不正确
- 图片显示404错误
- 批量修复多篇文章的图片

### 3. 快速发布 (`quick-publish.sh`)

**功能：**
- 🔧 自动修复图片
- 🧪 启动本地测试服务器
- 📤 提交并推送到远程仓库

**流程：**
1. 修复所有图片链接
2. 启动本地服务器 (http://localhost:1314)
3. 等待您确认效果
4. 自动提交和推送

## 🏷️ 智能标签系统

脚本会根据文章标题和内容自动生成标签：

| 关键词 | 生成标签 |
|--------|----------|
| Redis, 缓存, Cache | "Redis", "缓存" |
| MySQL, 数据库, Database | "数据库", "MySQL" |
| 分布式, 微服务, 架构 | "分布式系统", "系统架构" |
| 性能, 优化, Performance | "性能优化" |
| 网络, TCP, UDP, HTTP | "网络协议", "网络编程" |
| Go, Golang | "Go语言" |
| K8S, Kubernetes, 容器, Docker | "云原生", "容器技术" |
| AI, 机器学习, 深度学习 | "人工智能", "机器学习" |

## 📁 目录结构

```
Aster.github.io/
├── content/posts/           # 文章目录
├── static/images/           # 图片资源
│   └── article-slug/        # 每篇文章的图片文件夹
├── add-new-post.sh         # 添加新文章脚本
├── fix-images.sh           # 修复图片脚本
├── quick-publish.sh        # 快速发布脚本
└── WORKFLOW-GUIDE.md       # 本指南
```

## 🔧 故障排除

### 问题1：脚本权限错误
```bash
chmod +x *.sh
```

### 问题2：图片无法显示
```bash
# 手动修复图片
./fix-images.sh
```

### 问题3：Hugo服务器启动失败
```bash
# 检查Hugo是否安装
hugo version

# 手动启动测试
hugo server -D --port 1314
```

### 问题4：Git推送失败
```bash
# 检查Git状态
git status

# 手动推送
git add .
git commit -m "更新文章"
git push origin main
```

## 💡 最佳实践

### 1. 文章编写建议
- 使用清晰的标题层级 (H1, H2, H3)
- 添加代码块语法高亮
- 使用相对路径引用图片
- 保持图片文件名简洁明了

### 2. 图片优化建议
- 图片大小控制在1MB以内
- 使用WebP格式提升加载速度
- 为图片添加有意义的alt文本

### 3. SEO优化
- 标题包含关键词
- 描述控制在150字以内
- 使用合适的标签分类

## 🎉 示例工作流程

```bash
# 1. 准备文章和图片
mkdir my-new-article
cd my-new-article
# 编写 article.md 和准备图片

# 2. 添加到博客
cd /path/to/Aster.github.io
./add-new-post.sh "我的新技术文章" ./my-new-article/article.md

# 3. 快速发布
./quick-publish.sh

# 完成！文章已发布到 https://asterzephyr.github.io
```

## 📞 支持

如果遇到问题，请检查：
1. 脚本权限是否正确
2. Hugo是否正确安装
3. Git仓库状态是否正常
4. 图片文件是否存在

---

**Happy Blogging! 🎉**
