# Aura - 健康管理APP

一个功能完整、界面美观的iOS健康管理应用，帮助用户追踪和管理日常健康数据。

## 功能特点

### 📊 每日仪表盘 (DailyDashboard)
- 实时显示步数、卡路里、饮水量和睡眠时间
- 可视化进度条展示目标完成情况
- 每日目标追踪和提醒

### 🍎 营养分析 (NutritionAnalysis)
- **相机拍摄功能**：使用手机相机拍摄食物照片
- **相册选择功能**：从相册中选择食物图片
- **AI营养分析**：调用云端大模型分析食物营养成分
  - 识别食物名称
  - 估算卡路里含量
  - 分析蛋白质、碳水化合物、脂肪含量
  - 提供营养建议
- **历史记录**：保存分析历史，随时查看

### 🏃 运动追踪 (FitnessTracker)
- 支持多种运动类型：跑步、骑行、游泳、瑜伽、力量训练、步行
- 实时记录运动时长和消耗卡路里
- 本周运动数据可视化图表
- 运动历史记录和统计

### ⌚ 设备管理 (DeviceManagement)
- 连接智能手表、手环、体重秤等健康设备
- 实时同步设备数据
- 查看设备电量和连接状态
- 健康数据自动同步

### 👤 用户中心 (UserProfile)
- 个人信息管理（身高、体重、年龄等）
- BMI指数自动计算和分析
- 成就徽章系统
- 个性化设置选项

## 技术特点

- **SwiftUI框架**：现代化的UI框架，流畅的用户体验
- **MVVM架构**：清晰的代码结构，易于维护
- **腾讯云开发 CloudBase**：云端用户认证和数据同步（国内访问快）
- **Charts框架**：美观的数据可视化
- **相机集成**：原生相机和相册访问
- **响应式设计**：适配不同尺寸的iPhone

## 使用说明

### 系统要求
- iOS 17.0 或更高版本
- Xcode 16.0 或更高版本
- Swift 6.0

### 安装步骤

1. 克隆或下载项目到本地
2. 配置腾讯云开发（详见 [CLOUDBASE_SETUP.md](CLOUDBASE_SETUP.md)）
3. 使用Xcode打开 `Aura.xcodeproj`
4. 在 Xcode 中添加 CloudBase SDK（File → Add Package Dependencies）
5. 配置环境 ID（在 `CloudBaseManager.swift` 中）
6. 选择目标设备或模拟器
7. 点击运行按钮 (⌘R) 编译并运行

### 权限配置

应用需要以下权限（已在项目配置中设置）：
- **相机访问权限**：用于拍摄食物照片
- **相册访问权限**：用于选择已有照片

注：权限说明已通过 `INFOPLIST_KEY_*` 在项目配置中设置，无需单独的Info.plist文件

## AI营养分析集成说明

### 当前状态
项目中包含了完整的UI和数据流程，但AI分析功能使用模拟数据演示。

### 🔑 配置API密钥

**配置文件位置：** `Aura/Config.swift`

**快速配置步骤：**
1. 打开 `Aura/Config.swift`
2. 将你的OpenAI API密钥填入 `openAIAPIKey`
3. 修改 `currentService = .openAI`
4. 在 `NutritionViewModel.swift` 中启用真实API调用

**详细说明：** 查看 [配置API密钥指南.md](配置API密钥指南.md)

### 集成云端AI模型

要启用真实的AI营养分析功能，需要在 `NutritionViewModel.swift` 的 `analyzeWithAI` 方法中集成云端AI服务。

#### 推荐的AI服务选项：

1. **OpenAI GPT-4 Vision**
   - 优点：识别准确度高，营养分析详细
   - API: `https://api.openai.com/v1/chat/completions`

2. **Google Gemini Vision**
   - 优点：支持多语言，响应速度快
   - API: Google Cloud Vision API

3. **Azure Computer Vision**
   - 优点：企业级稳定性，支持私有部署
   - API: Azure Cognitive Services

4. **自定义模型**
   - 可以训练专门的食物识别和营养分析模型

#### 集成步骤：

1. 在 `NutritionViewModel.swift` 中找到 `analyzeWithAI` 方法
2. 取消注释示例代码并替换为实际的API端点和密钥
3. 根据选择的AI服务调整请求格式和响应解析
4. 测试并优化提示词以获得最佳分析结果

示例代码已在文件中提供，只需替换 `YOUR_API_KEY` 并根据具体服务调整即可。

## 项目结构

```
Aura/
├── AuraApp.swift                  # 应用入口
├── ContentView.swift              # 主界面（底部导航）
├── Config.swift                   # 配置文件（API密钥等）
├── Views/                         # 视图文件
│   ├── AuthView.swift             # 登录/注册界面
│   ├── DailyDashboardView.swift
│   ├── NutritionAnalysisView.swift
│   ├── FitnessTrackerView.swift
│   ├── DeviceManagementView.swift
│   └── UserProfileView.swift
├── ViewModels/                    # 视图模型
│   ├── AuthViewModel.swift        # 认证视图模型
│   └── NutritionViewModel.swift
├── Models/                        # 数据模型
│   └── CloudModels.swift          # 云端数据模型
├── Services/                      # 服务层
│   └── CloudBaseManager.swift     # 腾讯云管理器
└── Helpers/                       # 辅助工具
    ├── CameraView.swift
    └── ImagePicker.swift
```

## ☁️ 云端功能（已实现）

### 用户认证
- ✅ 邮箱注册和登录
- ✅ 密码重置
- ✅ 退出登录
- ✅ 认证状态管理

### 数据同步
- ✅ 营养分析记录自动保存到云端
- ✅ 食物照片上传到腾讯云存储
- ✅ 从云端加载历史记录
- ✅ 跨设备数据同步
- ✅ 用户配置云端存储

### 配置说明
详细的腾讯云配置步骤请查看：
- [CLOUDBASE_SETUP.md](CLOUDBASE_SETUP.md) - 详细配置指南
- [CLOUDBASE_CHECKLIST.md](CLOUDBASE_CHECKLIST.md) - 快速配置清单

### 为什么选择腾讯云？
- ✅ **国内访问速度快** - 无需翻墙，访问稳定
- ✅ **中文文档完善** - 易于理解和使用
- ✅ **免费额度慷慨** - 个人应用完全够用
- ✅ **技术支持本地化** - 更好的服务体验

## 未来规划

- [ ] 集成HealthKit以同步Apple健康数据
- [ ] 添加社交功能，与好友分享健康成就
- [ ] 支持多语言国际化
- [ ] 添加Apple Watch应用
- [ ] 更多的数据分析和健康建议
- [ ] 离线模式支持

## 开发者信息

- 创建日期：2026年2月10日
- 开发者：jiazhen yan
- 框架：SwiftUI
- 语言：Swift

## 许可证

本项目仅供学习和参考使用。

---

**注意**：实际使用时需要配置真实的AI API密钥，并确保遵守相关服务的使用条款和隐私政策。
