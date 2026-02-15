# ✅ Firebase 配置检查清单

按照这个清单逐步完成 Firebase 配置，确保云端功能正常工作。

## 📋 配置步骤

### ☐ 1. 创建 Firebase 项目

- [ ] 访问 [Firebase 控制台](https://console.firebase.google.com/)
- [ ] 点击"添加项目"
- [ ] 输入项目名称（如 `Aura`）
- [ ] 完成项目创建

### ☐ 2. 添加 iOS 应用

- [ ] 在 Firebase 项目中点击 iOS 图标
- [ ] 输入 Bundle ID：`com.aura.health`
- [ ] 下载 `GoogleService-Info.plist` 文件
- [ ] 将文件拖入 Xcode 项目的 `Aura` 文件夹
- [ ] 确保勾选 "Copy items if needed"
- [ ] 确保 Target 选择了 "Aura"

### ☐ 3. 在 Xcode 中添加 Firebase SDK

- [ ] 打开 `Aura.xcodeproj`
- [ ] 选择 `File` → `Add Package Dependencies...`
- [ ] 输入 URL：`https://github.com/firebase/firebase-ios-sdk.git`
- [ ] 选择版本：`10.20.0` 或更高
- [ ] 勾选以下产品：
  - [ ] `FirebaseAuth`
  - [ ] `FirebaseFirestore`
  - [ ] `FirebaseStorage`
- [ ] 点击 "Add Package"

### ☐ 4. 启用 Firebase Authentication

- [ ] 在 Firebase 控制台，进入 "Authentication"
- [ ] 点击 "Get started"
- [ ] 在 "Sign-in method" 中启用 "Email/Password"
- [ ] 保存设置

### ☐ 5. 启用 Firestore Database

- [ ] 在 Firebase 控制台，进入 "Firestore Database"
- [ ] 点击 "Create database"
- [ ] 选择"生产模式"（推荐）
- [ ] 选择数据库位置（如 `asia-east1`）
- [ ] 点击"启用"

### ☐ 6. 配置 Firestore 安全规则

- [ ] 在 Firestore Database 页面，点击"规则"标签
- [ ] 复制以下规则并粘贴：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /nutritionRecords/{userId}/items/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /fitnessRecords/{userId}/items/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /dailySummaries/{userId}/items/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /deviceInfo/{userId}/items/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

- [ ] 点击"发布"

### ☐ 7. 启用 Firebase Storage

- [ ] 在 Firebase 控制台，进入 "Storage"
- [ ] 点击 "Get started"
- [ ] 选择"生产模式"
- [ ] 选择存储位置（与 Firestore 相同）
- [ ] 点击"完成"

### ☐ 8. 配置 Storage 安全规则

- [ ] 在 Storage 页面，点击"规则"标签
- [ ] 复制以下规则并粘贴：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

- [ ] 点击"发布"

### ☐ 9. 测试应用

- [ ] 在 Xcode 中按 `Cmd + R` 运行应用
- [ ] 看到登录界面（说明 Firebase 初始化成功）
- [ ] 注册一个测试账号
- [ ] 登录成功后进入主界面
- [ ] 拍摄食物照片并分析
- [ ] 在 Firebase 控制台查看：
  - [ ] Firestore 中有新的营养记录
  - [ ] Storage 中有上传的照片

## 🎯 验证清单

### 功能测试

- [ ] 可以注册新用户
- [ ] 可以登录已有用户
- [ ] 可以退出登录
- [ ] 营养分析结果自动保存到云端
- [ ] 照片自动上传到 Storage
- [ ] 可以查看历史记录
- [ ] 可以删除记录

### 控制台检查

在 Xcode 控制台中应该看到：
- [ ] `🔥 Firebase 初始化完成`
- [ ] `🔐 认证状态变化: [邮箱]`
- [ ] `✅ 注册成功` 或 `✅ 登录成功`
- [ ] `📤 开始上传图片到云端...`
- [ ] `✅ 图片上传成功`
- [ ] `💾 保存营养记录到 Firestore...`
- [ ] `✅ 数据保存成功`

## ❌ 常见问题排查

### 问题 1：编译错误 - 找不到 Firebase 模块

**解决方案：**
- [ ] 确认已正确添加 Firebase SDK
- [ ] 清理构建：`Product` → `Clean Build Folder`
- [ ] 重启 Xcode
- [ ] 检查 Package Dependencies 是否正确

### 问题 2：运行时错误 - Firebase 配置失败

**解决方案：**
- [ ] 检查 `GoogleService-Info.plist` 是否在项目中
- [ ] 确保文件在 "Copy Bundle Resources" 中
- [ ] 检查 Bundle ID 是否与 Firebase 配置一致

### 问题 3：认证失败

**解决方案：**
- [ ] 确认 Firebase 控制台中启用了 Email/Password 认证
- [ ] 检查网络连接
- [ ] 查看 Xcode 控制台的错误信息
- [ ] 密码至少 6 位

### 问题 4：数据保存失败

**解决方案：**
- [ ] 检查 Firestore 安全规则是否正确配置
- [ ] 确保用户已登录
- [ ] 查看 Firebase 控制台的使用情况
- [ ] 检查网络连接

### 问题 5：照片上传失败

**解决方案：**
- [ ] 检查 Storage 安全规则是否正确配置
- [ ] 确认 Storage 已启用
- [ ] 检查网络连接
- [ ] 查看 Xcode 控制台的错误信息

## 📞 获取帮助

如果遇到问题：

1. **查看日志**：Xcode 控制台有详细的日志输出
2. **查看文档**：
   - [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - 详细配置指南
   - [CLOUD_FEATURES.md](CLOUD_FEATURES.md) - 功能使用指南
3. **Firebase 文档**：[https://firebase.google.com/docs](https://firebase.google.com/docs)
4. **检查配置**：确保所有步骤都已完成

## 🎉 配置完成！

当所有检查项都完成后，你的 Aura 应用就拥有了完整的云端功能！

开始享受无缝的数据同步体验吧！ 🚀
