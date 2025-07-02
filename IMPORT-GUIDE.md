# Notion文章快速导入指南

## 🚀 一键导入脚本

已为你创建自动化脚本 `auto-import-deploy.sh`，可以：
- 批量导入所有Notion文章
- 自动处理图片资源
- 生成Hugo格式的Front Matter
- 测试构建并自动部署

## 📋 使用方法

### 方法一：一键执行（推荐）

```bash
# 直接运行脚本
./auto-import-deploy.sh
```

### 方法二：分步执行

```bash
# 1. 只导入文章（不部署）
./auto-import-deploy.sh --import-only

# 2. 测试本地构建
hugo server -D

# 3. 手动提交部署
git add .
git commit -m "Add imported articles"
git push
```

## 🔧 脚本功能

### ✅ 自动处理项目
- [x] 批量导入91篇技术文章
- [x] 转换为Hugo兼容格式
- [x] 自动生成文件名和标题
- [x] 复制图片到static目录
- [x] 清理无效文件
- [x] 测试Hugo构建
- [x] Git提交和推送

### 📊 预期结果
- 📄 ~90篇技术文章导入
- 🖼️ 所有图片资源就位
- 🌐 自动部署到GitHub Pages
- ⚡ 5分钟内完成全部流程

## 🐛 故障排除

### 问题1：权限错误
```bash
chmod +x auto-import-deploy.sh
```

### 问题2：Hugo未安装
```bash
# macOS
brew install hugo

# 或跳过构建测试，直接推送让GitHub处理
```

### 问题3：路径错误
检查Notion导出目录路径是否正确：
```bash
ls -la "04365f2c-e0a0-4f82-b394-bf72ea67d998_Export-872eace1-bda6-43ea-950e-15d7cb75a5c5"
```

## 🎯 下一步

运行完成后：
1. 访问你的GitHub Pages站点查看效果
2. 用 `hugo server -D` 本地预览
3. 根据需要调整文章分类和标签

---

**时间节省：** 手动导入需要2-3小时，脚本执行仅需5分钟！