# 腾讯云开发 CloudBase 配置指南

## 📋 概述

本指南将帮助你配置腾讯云开发 CloudBase 服务，实现用户认证和数据同步功能。

## 🚀 第一步：创建腾讯云账号

1. **访问腾讯云官网**
   - 打开 [https://cloud.tencent.com/](https://cloud.tencent.com/)
   - 点击右上角"注册"
   - 使用手机号或微信注册

2. **实名认证**（必需）
   - 登录后进入控制台
   - 完成个人实名认证
   - 上传身份证照片（仅用于实名验证）

## 📥 第二步：开通云开发服务

1. **进入云开发控制台**
   - 访问 [https://console.cloud.tencent.com/tcb](https://console.cloud.tencent.com/tcb)
   - 或在腾讯云控制台搜索"云开发"

2. **创建环境**
   - 点击"新建环境"
   - 环境名称：`aura-health`（或任意名称）
   - 计费方式：选择"按量计费"（有免费额度）
   - 地域：选择"上海"或离你最近的地域
   - 点击"立即开通"

3. **记录环境 ID**
   - 创建完成后，会显示环境 ID（格式如：`aura-xxxxx`）
   - **重要**：记下这个环境 ID，后面会用到

## 🔧 第三步：在 Xcode 中添加 CloudBase SDK

### 方法 1：使用 Swift Package Manager（推荐）

1. **在 Xcode 中打开项目**
   - 打开 `Aura.xcodeproj`

2. **添加 CloudBase 包**
   - 选择菜单：`File` → `Add Package Dependencies...`
   - 在搜索框中输入：`https://github.com/TencentCloudBase/cloudbase-ios-sdk.git`
   - 选择版本：`1.0.0` 或更高版本
   - 点击 "Add Package"

3. **选择需要的产品**
   - 勾选以下产品：
     - ✅ `CloudBase`（核心库）
   - 点击 "Add Package"

### 方法 2：使用 CocoaPods

如果你更喜欢使用 CocoaPods：

1. **创建 Podfile**
   ```ruby
   platform :ios, '17.0'
   use_frameworks!

   target 'Aura' do
     pod 'CloudBase', '~> 1.0'
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

## 🔐 第四步：配置环境 ID

1. **打开配置文件**
   - 在 Xcode 中打开 `Aura/Services/CloudBaseManager.swift`

2. **修改配置**
   - 找到文件末尾的 `CloudBaseConfig` 结构体
   - 将 `YOUR_ENV_ID` 替换为你的环境 ID

```swift
struct CloudBaseConfig {
    /// 环境 ID（从腾讯云控制台获取）
    static let envId = "aura-xxxxx"  // 替换为你的环境 ID
    
    /// 地域
    static let region = "ap-shanghai"  // 根据你选择的地域修改
}
```

**地域代码对照表：**
- 上海：`ap-shanghai`
- 广州：`ap-guangzhou`
- 北京：`ap-beijing`
- 成都：`ap-chengdu`
- 香港：`ap-hongkong`

## 🔐 第五步：启用认证服务

1. **进入环境管理**
   - 在云开发控制台，点击你创建的环境
   - 进入环境详情页

2. **启用邮箱登录**
   - 点击左侧菜单"用户管理"
   - 点击"登录方式"标签
   - 找到"邮箱登录"，点击启用
   - 保存设置

## 📊 第六步：创建数据库集合

1. **进入数据库管理**
   - 在环境详情页，点击左侧菜单"数据库"
   - 点击"集合"标签

2. **创建集合**
   - 点击"新建集合"
   - 创建以下集合：
     - ✅ `nutritionRecords`（营养记录）
     - ✅ `userProfiles`（用户配置）
     - ✅ `fitnessRecords`（运动记录）
     - ✅ `dailySummaries`（每日统计）

3. **配置权限**
   - 对于每个集合，点击"权限设置"
   - 选择"自定义安全规则"
   - 使用以下规则：

```json
{
  "read": "auth.uid != null && doc.userId == auth.uid",
  "write": "auth.uid != null && doc.userId == auth.uid"
}
```

这个规则确保用户只能访问自己的数据。

## 📁 第七步：启用云存储

1. **进入云存储管理**
   - 在环境详情页，点击左侧菜单"云存储"
   - 如果未开通，点击"立即开通"

2. **创建存储桶**
   - 系统会自动创建一个默认存储桶
   - 记下存储桶名称

3. **配置权限**
   - 点击"权限设置"
   - 选择"自定义权限"
   - 使用以下规则：

```json
{
  "read": true,
  "write": "auth.uid != null && resource.startsWith('users/' + auth.uid + '/')"
}
```

这个规则允许：
- 所有人可以读取（用于显示图片）
- 只有登录用户可以上传到自己的目录

## ✅ 第八步：测试应用

1. **运行应用**
   - 在 Xcode 中按 `Cmd + R` 运行应用
   - 应该会看到登录界面

2. **注册新用户**
   - 输入邮箱和密码（至少 6 位）
   - 点击"注册"
   - 如果成功，会自动跳转到主界面

3. **验证数据同步**
   - 拍摄食物照片并分析
   - 在腾讯云控制台的数据库中查看是否有新数据
   - 在云存储中查看是否上传了图片

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
   - ✅ 食物照片上传到云存储
   - ✅ 从云端加载历史记录
   - ✅ 删除云端记录

3. **用户配置**
   - ✅ 用户资料存储
   - ✅ 健康数据管理
   - ✅ 个性化设置

### 数据结构

#### 数据库集合结构

```
nutritionRecords/
  {documentId}/
    - foodName: String
    - calories: Double
    - protein: Double
    - carbs: Double
    - fat: Double
    - description: String
    - imageURL: String
    - timestamp: Number
    - userId: String

userProfiles/
  {documentId}/
    - userId: String
    - displayName: String
    - email: String
    - age: Number
    - gender: String
    - height: Number
    - weight: Number
    - createdAt: Number
    - updatedAt: Number
```

#### 云存储文件结构

```
users/
  {userId}/
    nutrition/
      {uuid}.jpg
    avatars/
      profile.jpg
```

## 🔍 调试技巧

### 查看日志

应用中已添加详细的日志输出，在 Xcode 控制台中可以看到：

- ☁️ 腾讯云初始化
- 🔐 认证状态变化
- 📝 用户注册/登录
- 💾 数据保存
- 📥 数据加载
- 📤 图片上传
- ❌ 错误信息

### 常见问题

1. **编译错误：找不到 CloudBase 模块**
   - 确保已正确添加 CloudBase SDK
   - 清理构建：`Product` → `Clean Build Folder`
   - 重启 Xcode

2. **运行时错误：环境 ID 无效**
   - 检查 `CloudBaseManager.swift` 中的环境 ID 是否正确
   - 确保环境 ID 格式正确（如：`aura-xxxxx`）

3. **认证失败**
   - 检查腾讯云控制台中是否启用了邮箱登录
   - 检查网络连接
   - 查看 Xcode 控制台的错误信息

4. **数据保存失败**
   - 检查数据库集合是否已创建
   - 检查权限规则是否正确配置
   - 确保用户已登录
   - 查看腾讯云控制台的使用情况

5. **图片上传失败**
   - 检查云存储是否已开通
   - 检查权限规则是否正确配置
   - 确保用户已登录
   - 查看 Xcode 控制台的错误信息

## 💰 费用说明

腾讯云开发提供免费套餐，对于个人项目完全够用：

### 免费额度（按量计费）

- **云数据库**：
  - 存储：2 GB
  - 读操作：50,000 次/天
  - 写操作：30,000 次/天

- **云存储**：
  - 存储：5 GB
  - 下载流量：1 GB/月
  - 上传流量：1 GB/月

- **云函数**：
  - 调用次数：1,000 次/天
  - 资源使用量：4,000 GBs/月

### 预估使用量（单用户/月）

- 营养记录：~100 条 = 100 KB
- 照片存储：~100 张 = 30 MB
- 读取操作：~3,000 次
- 写入操作：~300 次

**结论**：对于个人使用或小规模应用，免费额度完全够用！

## 📚 更多资源

- [腾讯云开发官方文档](https://cloud.tencent.com/document/product/876)
- [CloudBase iOS SDK GitHub](https://github.com/TencentCloudBase/cloudbase-ios-sdk)
- [腾讯云开发社区](https://cloudbase.net/)

## 🎉 完成！

配置完成后，你的 Aura 应用就拥有了完整的云端功能：
- 用户可以注册和登录
- 营养分析数据会自动同步到云端
- 数据在所有设备间同步
- 安全可靠的数据存储
- **国内访问速度快，无需翻墙**

如有问题，请查看 Xcode 控制台的日志输出。
