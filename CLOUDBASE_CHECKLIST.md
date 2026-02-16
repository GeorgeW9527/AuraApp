# ✅ 腾讯云开发 CloudBase 配置检查清单

按照这个清单逐步完成腾讯云配置，确保云端功能正常工作。

## 📋 配置步骤

### ☐ 1. 注册腾讯云账号

- [ ] 访问 [腾讯云官网](https://cloud.tencent.com/)
- [ ] 注册账号（手机号或微信）
- [ ] 完成实名认证（必需）

### ☐ 2. 创建云开发环境

- [ ] 进入 [云开发控制台](https://console.cloud.tencent.com/tcb)
- [ ] 点击"新建环境"
- [ ] 输入环境名称：`aura-health`
- [ ] 选择计费方式：按量计费
- [ ] 选择地域：上海（或离你最近的）
- [ ] 点击"立即开通"
- [ ] **记录环境 ID**（格式如：`aura-xxxxx`）

### ☐ 3. 在 Xcode 中添加 CloudBase SDK

- [ ] 打开 `Aura.xcodeproj`
- [ ] 选择 `File` → `Add Package Dependencies...`
- [ ] 输入 URL：`https://github.com/TencentCloudBase/cloudbase-ios-sdk.git`
- [ ] 选择版本：`1.0.0` 或更高
- [ ] 勾选 `CloudBase` 产品
- [ ] 点击 "Add Package"

### ☐ 4. 配置环境 ID

- [ ] 打开 `Aura/Services/CloudBaseManager.swift`
- [ ] 找到文件末尾的 `CloudBaseConfig`
- [ ] 将 `YOUR_ENV_ID` 替换为你的环境 ID
- [ ] 根据选择的地域修改 `region`

```swift
struct CloudBaseConfig {
    static let envId = "aura-xxxxx"  // 替换为你的环境 ID
    static let region = "ap-shanghai"  // 根据地域修改
}
```

**地域代码：**
- 上海：`ap-shanghai`
- 广州：`ap-guangzhou`
- 北京：`ap-beijing`

### ☐ 5. 启用邮箱登录

- [ ] 在云开发控制台，进入你的环境
- [ ] 点击左侧菜单"用户管理"
- [ ] 点击"登录方式"标签
- [ ] 启用"邮箱登录"
- [ ] 保存设置

### ☐ 6. 创建数据库集合

- [ ] 点击左侧菜单"数据库"
- [ ] 点击"新建集合"
- [ ] 创建以下集合：
  - [ ] `nutritionRecords`
  - [ ] `userProfiles`
  - [ ] `fitnessRecords`
  - [ ] `dailySummaries`

### ☐ 7. 配置数据库权限

对每个集合：
- [ ] 点击集合名称
- [ ] 点击"权限设置"
- [ ] 选择"自定义安全规则"
- [ ] 粘贴以下规则：

```json
{
  "read": "auth.uid != null && doc.userId == auth.uid",
  "write": "auth.uid != null && doc.userId == auth.uid"
}
```

- [ ] 保存

### ☐ 8. 启用云存储

- [ ] 点击左侧菜单"云存储"
- [ ] 如果未开通，点击"立即开通"
- [ ] 点击"权限设置"
- [ ] 选择"自定义权限"
- [ ] 粘贴以下规则：

```json
{
  "read": true,
  "write": "auth.uid != null && resource.startsWith('users/' + auth.uid + '/')"
}
```

- [ ] 保存

### ☐ 9. 测试应用

- [ ] 在 Xcode 中按 `Cmd + R` 运行应用
- [ ] 看到登录界面（说明初始化成功）
- [ ] 注册一个测试账号
- [ ] 登录成功后进入主界面
- [ ] 拍摄食物照片并分析
- [ ] 在腾讯云控制台查看：
  - [ ] 数据库中有新的营养记录
  - [ ] 云存储中有上传的照片

## 🎯 验证清单

### 功能测试

- [ ] 可以注册新用户
- [ ] 可以登录已有用户
- [ ] 可以退出登录
- [ ] 营养分析结果自动保存到云端
- [ ] 照片自动上传到云存储
- [ ] 可以查看历史记录
- [ ] 可以删除记录

### 控制台检查

在 Xcode 控制台中应该看到：
- [ ] `☁️ 腾讯云 CloudBase 初始化完成`
- [ ] `🔐 用户已登录: [用户ID]` 或 `🔐 用户未登录`
- [ ] `✅ 注册成功` 或 `✅ 登录成功`
- [ ] `📤 开始上传图片到云端...`
- [ ] `✅ 图片上传成功`
- [ ] `💾 保存营养记录到云数据库...`
- [ ] `✅ 云端保存成功`

## ❌ 常见问题排查

### 问题 1：编译错误 - 找不到 CloudBase 模块

**解决方案：**
- [ ] 确认已正确添加 CloudBase SDK
- [ ] 清理构建：`Product` → `Clean Build Folder`
- [ ] 重启 Xcode
- [ ] 检查 Package Dependencies 是否正确

### 问题 2：运行时错误 - 环境 ID 无效

**解决方案：**
- [ ] 检查 `CloudBaseManager.swift` 中的环境 ID
- [ ] 确保环境 ID 格式正确（如：`aura-xxxxx`）
- [ ] 在腾讯云控制台确认环境 ID

### 问题 3：认证失败

**解决方案：**
- [ ] 确认腾讯云控制台中启用了邮箱登录
- [ ] 检查网络连接
- [ ] 查看 Xcode 控制台的错误信息
- [ ] 密码至少 6 位

### 问题 4：数据保存失败

**解决方案：**
- [ ] 检查数据库集合是否已创建
- [ ] 检查权限规则是否正确配置
- [ ] 确保用户已登录
- [ ] 查看腾讯云控制台的使用情况
- [ ] 检查网络连接

### 问题 5：照片上传失败

**解决方案：**
- [ ] 检查云存储是否已开通
- [ ] 检查权限规则是否正确配置
- [ ] 确认用户已登录
- [ ] 查看 Xcode 控制台的错误信息
- [ ] 检查网络连接

## 📞 获取帮助

如果遇到问题：

1. **查看日志**：Xcode 控制台有详细的日志输出
2. **查看文档**：
   - [CLOUDBASE_SETUP.md](CLOUDBASE_SETUP.md) - 详细配置指南
   - [CLOUD_FEATURES.md](CLOUD_FEATURES.md) - 功能使用指南
3. **腾讯云文档**：[https://cloud.tencent.com/document/product/876](https://cloud.tencent.com/document/product/876)
4. **检查配置**：确保所有步骤都已完成

## 💡 重要提示

### 环境 ID
- 环境 ID 是连接应用和腾讯云的关键
- 格式通常为：`环境名-随机字符`（如：`aura-8g7h9j`）
- 可以在云开发控制台的环境列表中找到

### 地域选择
- 建议选择离你最近的地域
- 上海、广州、北京都是不错的选择
- 地域代码必须与你创建环境时选择的一致

### 权限规则
- 数据库和存储的权限规则非常重要
- 确保用户只能访问自己的数据
- 测试时可以先用宽松的规则，正式使用时改为严格规则

## 🎉 配置完成！

当所有检查项都完成后，你的 Aura 应用就拥有了完整的云端功能！

**优势：**
- ✅ 国内访问速度快
- ✅ 无需翻墙
- ✅ 中文文档和支持
- ✅ 免费额度慷慨
- ✅ 稳定可靠

开始享受无缝的数据同步体验吧！ 🚀
