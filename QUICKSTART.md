# 🚀 Aura - 快速启动指南

## ⚡ 5分钟快速体验

### 第1步：打开项目 (30秒)

**方法A：从Finder打开**
1. 打开访达（Finder）
2. 导航到桌面的 `Aura` 文件夹
3. 双击 `Aura.xcodeproj` 文件

**方法B：从终端打开**
```bash
cd ~/Desktop/Aura
open Aura.xcodeproj
```

### 第2步：等待索引 (1-2分钟)

Xcode会在后台索引项目文件，请等待右上角的索引进度完成。

### 第3步：选择设备 (10秒)

在Xcode顶部工具栏：
- 点击设备选择器（显示为"Aura > iPhone 15 Pro"之类）
- 选择任意iPhone模拟器
- 推荐：iPhone 15 Pro 或 iPhone 16

### 第4步：运行项目 (30秒)

点击左上角的 ▶️ 播放按钮，或按 `⌘R` (Command + R)

### 第5步：体验功能 (2分钟)

模拟器启动后：

1. **查看首页** - 每日仪表盘
   - 查看步数、卡路里、饮水、睡眠数据
   - 美观的进度条动画

2. **尝试营养分析** - 点击底部第2个Tab
   - 点击"拍摄或选择食物照片"
   - 选择"从相册选择"
   - 选择模拟器中的任意图片
   - 查看AI分析结果（当前为演示数据）

3. **浏览其他功能**
   - Tab 3：运动追踪
   - Tab 4：设备管理
   - Tab 5：用户中心

## 🎯 完成！

恭喜！您已经成功运行了Aura健康管理APP！

## 📚 接下来做什么？

### 如果您是用户：
→ 阅读《使用指南.md》了解详细功能

### 如果您是开发者：
→ 阅读《AI集成指南.md》启用真实AI分析  
→ 阅读《README.md》了解项目架构  
→ 阅读《项目总结.md》查看完整信息

## ⚠️ 常见问题

### Q: 模拟器启动失败？
**A:** 重启Xcode，或者在菜单栏选择 `Product → Clean Build Folder`

### Q: 编译错误？
**A:** 
- 确保使用Xcode 16+和iOS 17+ SDK
- 如果遇到Info.plist冲突错误，请查看《问题解决记录.md》
- 尝试：Product → Clean Build Folder (⇧⌘K)

### Q: 相机功能不可用？
**A:** 模拟器不支持真实相机，只能使用相册。要测试相机，请在真机上运行。

### Q: 在真机上运行？
**A:** 
1. 连接iPhone到Mac
2. 在设备选择器中选择您的iPhone
3. 可能需要在 `Signing & Capabilities` 中配置开发团队

## 📱 在真机上测试（可选）

如果您想在真实iPhone上运行：

1. 用数据线连接iPhone到Mac
2. 在iPhone上：设置 → 隐私与安全 → 开发者模式 → 开启
3. 在Xcode中选择您的iPhone作为目标设备
4. 在项目设置中配置签名：
   - 点击项目名称 "Aura"
   - 选择 "Signing & Capabilities"
   - Team：选择您的Apple ID
5. 点击运行

首次运行需要在iPhone上信任开发者证书：
- 设置 → 通用 → VPN与设备管理 → 信任

## 🎨 自定义体验

### 修改主题颜色

打开 `Aura/Assets.xcassets/AccentColor.colorset/Contents.json`

### 修改初始数据

打开 `Aura/Views/DailyDashboardView.swift`，修改：
```swift
@State private var steps = 6542  // 改为您想要的值
@State private var calories = 1850
@State private var water = 6
@State private var sleep = 7.5
```

### 添加更多运动类型

打开 `Aura/Views/FitnessTrackerView.swift`，在 `WorkoutType` 枚举中添加。

## 🔥 启用真实AI分析

最重要的进阶功能！

### 快速配置（5分钟）

1. **打开配置文件**
   ```
   Aura/Config.swift
   ```

2. **填入API密钥**
   ```swift
   static let openAIAPIKey = "sk-your-key-here"  // 替换为你的密钥
   static let currentService: AIService = .openAI  // 启用OpenAI
   ```

3. **修改ViewModel**
   在 `NutritionViewModel.swift` 中启用真实API调用

4. **测试**
   运行应用，拍摄食物照片

**详细步骤：** 查看 [配置API密钥指南.md](配置API密钥指南.md)

**获取密钥：** https://platform.openai.com/api-keys  
**成本：** 每张照片约 $0.01-0.03

## 📊 项目文件说明

| 文件 | 用途 |
|------|------|
| README.md | 项目整体说明 |
| 使用指南.md | 用户操作手册 |
| AI集成指南.md | 开发者技术文档 |
| 项目总结.md | 完整项目信息 |
| QUICKSTART.md | 本文件 - 快速开始 |

## ✅ 检查清单

- [ ] Xcode已安装（16.0+）
- [ ] 项目成功打开
- [ ] 编译无错误
- [ ] 模拟器成功启动
- [ ] 五个Tab都能正常切换
- [ ] 相册选择功能可用
- [ ] 已阅读使用指南

## 🎓 学习路径

### 第1天：熟悉功能
- 运行项目
- 体验所有功能
- 阅读使用指南

### 第2天：理解代码
- 查看项目结构
- 阅读主要文件
- 理解MVVM架构

### 第3天：集成AI
- 获取API密钥
- 按照指南集成
- 测试真实分析

### 第4-7天：扩展功能
- 添加数据持久化
- 集成HealthKit
- 自定义功能

## 🌟 享受Aura！

您现在拥有一个完整的、可运行的健康管理APP！

**有问题？** 查看其他文档或在代码中搜索注释。

**祝您开发愉快！** 💪✨
