# Firebase 配置指南

## 📋 概述

本指南将帮助你配置 Firebase 云端服务，实现用户认证和数据同步功能。

## 🚀 第一步：创建 Firebase 项目

1. **访问 Firebase 控制台**
   - 打开 [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - 使用 Google 账号登录

2. **创建新项目**
   - 点击"添加项目"
   - 输入项目名称：`Aura` 或任意名称
   - 选择是否启用 Google Analytics（可选）
   - 点击"创建项目"

3. **添加 iOS 应用**
   - 在项目概览页面，点击 iOS 图标
   - 输入 Bundle ID：`com.aura.health`（必须与 Xcode 中的一致）
   - 输入应用昵称：`Aura`
   - 点击"注册应用"

## 📥 第二步：下载配置文件

1. **下载 GoogleService-Info.plist**
   - 在 Firebase 控制台中，下载 `GoogleService-Info.plist` 文件
   - 这个文件包含了你的 Firebase 项目配置信息

2. **替换项目中的配置文件**
   - 删除 `Aura/GoogleService-Info.plist`（当前是模板文件）
   - 将下载的 `GoogleService-Info.plist` 拖入 Xcode 项目的 `Aura` 文件夹
   - 确保勾选 "Copy items if needed"
   - 确保 Target 选择了 "Aura"

## 🔧 第三步：在 Xcode 中添加 Firebase SDK

### 方法 1：使用 Swift Package Manager（推荐）

1. **在 Xcode 中打开项目**
   - 打开 `Aura.xcodeproj`

2. **添加 Firebase 包**
   - 选择菜单：`File` → `Add Package Dependencies...`
   - 在搜索框中输入：`https://github.com/firebase/firebase-ios-sdk.git`
   - 选择版本：`10.20.0` 或更高版本
   - 点击 "Add Package"

3. **选择需要的产品**
   - 勾选以下产品：
     - ✅ `FirebaseAuth`
     - ✅ `FirebaseFirestore`
     - ✅ `FirebaseStorage`
   - 点击 "Add Package"

### 方法 2：使用 CocoaPods

如果你更喜欢使用 CocoaPods：

1. **创建 Podfile**
   ```ruby
   platform :ios, '17.0'
   use_frameworks!

   target 'Aura' do
     pod 'Firebase/Auth'
     pod 'Firebase/Firestore'
     pod 'Firebase/Storage'
   end
   ```

2. **安装依赖**
   ```bash
   cd /Users/jiazhenyan/Desktop/Aura
   pod install
   ```

3. **打开 .xcworkspace**
   - 关闭 Xcode
   - 打开 `Aura.xcworkspace`（而不是 .xcodeproj）

## 🔐 第四步：启用 Firebase 服务

### 1. 启用 Authentication（认证）

1. 在 Firebase 控制台，点击左侧菜单的 "Authentication"
2. 点击 "Get started"
3. 在 "Sign-in method" 标签页，启用以下登录方式：
   - ✅ **Email/Password**（邮箱密码登录）
   - 点击 "Email/Password" → 启用 → 保存

### 2. 启用 Firestore Database（数据库）

1. 在 Firebase 控制台，点击左侧菜单的 "Firestore Database"
2. 点击 "Create database"
3. 选择模式：
   - **生产模式**（推荐）：更安全，需要配置规则
   - **测试模式**：30 天内允许所有读写（仅用于开发）
4. 选择数据库位置：选择离你最近的区域（如 `asia-east1`）
5. 点击 "启用"

### 3. 配置 Firestore 安全规则

在 Firestore Database 页面，点击 "规则" 标签，使用以下规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
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

点击 "发布" 保存规则。

### 4. 启用 Storage（存储）

1. 在 Firebase 控制台，点击左侧菜单的 "Storage"
2. 点击 "Get started"
3. 选择安全规则模式（建议选择生产模式）
4. 选择存储位置（与 Firestore 相同的区域）
5. 点击 "完成"

### 5. 配置 Storage 安全规则

在 Storage 页面，点击 "规则" 标签，使用以下规则：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 用户只能访问自己的文件
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

点击 "发布" 保存规则。

## ✅ 第五步：测试配置

1. **运行应用**
   - 在 Xcode 中按 `Cmd + R` 运行应用
   - 应该会看到登录界面

2. **注册新用户**
   - 输入邮箱和密码（至少 6 位）
   - 点击"注册"
   - 如果成功，会自动跳转到主界面

3. **验证数据同步**
   - 拍摄食物照片并分析
   - 在 Firebase 控制台的 Firestore Database 中查看是否有新数据
   - 在 Storage 中查看是否上传了图片

## 🎯 功能说明

### 已实现的功能

1. **用户认证**
   - ✅ 邮箱注册
   - ✅ 邮箱登录
   - ✅ 密码重置
   - ✅ 退出登录
   - ✅ 认证状态管理

2. **数据同步**
   - ✅ 营养分析记录云端保存
   - ✅ 食物照片上传到 Storage
   - ✅ 从云端加载历史记录
   - ✅ 删除云端记录

3. **用户配置**
   - ✅ 用户资料存储
   - ✅ 健康数据管理
   - ✅ 个性化设置

### 数据结构

#### Firestore 集合结构

```
nutritionRecords/
  {userId}/
    items/
      {recordId}/
        - foodName: String
        - calories: Double
        - protein: Double
        - carbs: Double
        - fat: Double
        - description: String
        - imageURL: String
        - timestamp: Date
        - userId: String

userProfiles/
  {userId}/
    - displayName: String
    - email: String
    - avatarURL: String
    - age: Int
    - gender: String
    - height: Double
    - weight: Double
    - targetWeight: Double
    - dailyCalorieGoal: Double
    - createdAt: Date
    - updatedAt: Date
```

#### Storage 文件结构

```
users/
  {userId}/
    nutrition/
      {imageId}.jpg
    avatars/
      profile.jpg
```

## 🔍 调试技巧

### 查看日志

应用中已添加详细的日志输出，在 Xcode 控制台中可以看到：

- 🔥 Firebase 初始化
- 🔐 认证状态变化
- 📝 用户注册/登录
- 💾 数据保存
- 📥 数据加载
- 📤 图片上传
- ❌ 错误信息

### 常见问题

1. **编译错误：找不到 Firebase 模块**
   - 确保已正确添加 Firebase SDK
   - 清理构建：`Product` → `Clean Build Folder`
   - 重启 Xcode

2. **运行时错误：Firebase 配置失败**
   - 检查 `GoogleService-Info.plist` 是否正确添加到项目
   - 确保文件在 Xcode 的 "Copy Bundle Resources" 中

3. **认证失败**
   - 检查 Firebase 控制台中是否启用了 Email/Password 认证
   - 检查网络连接
   - 查看 Xcode 控制台的错误信息

4. **数据保存失败**
   - 检查 Firestore 安全规则是否正确配置
   - 确保用户已登录
   - 查看 Firebase 控制台的使用情况

## 💰 费用说明

Firebase 提供免费套餐（Spark Plan），对于个人项目完全够用：

- **Authentication**：无限制（免费）
- **Firestore**：
  - 存储：1 GB
  - 读取：50,000 次/天
  - 写入：20,000 次/天
  - 删除：20,000 次/天
- **Storage**：
  - 存储：5 GB
  - 下载：1 GB/天
  - 上传：无限制

超出免费额度后，会自动升级到按量付费（Blaze Plan），但可以设置预算提醒。

## 📚 更多资源

- [Firebase 官方文档](https://firebase.google.com/docs)
- [Firebase iOS SDK GitHub](https://github.com/firebase/firebase-ios-sdk)
- [Firestore 数据建模最佳实践](https://firebase.google.com/docs/firestore/best-practices)

## 🎉 完成！

配置完成后，你的 Aura 应用就拥有了完整的云端功能：
- 用户可以注册和登录
- 营养分析数据会自动同步到云端
- 数据在所有设备间同步
- 安全可靠的数据存储

如有问题，请查看 Xcode 控制台的日志输出。
