# Aura 项目交接文档

本文面向接手本工程的 iOS 开发者，目标：**完成本地配置后，`git pull` 即可在 Xcode 中编译运行**（含 Firebase 登录/云同步、Tab2 营养分析、Tab4 AI 对话等能力）。

---

## 1. 环境与打开工程

| 项 | 说明 |
|----|------|
| Xcode | 建议使用与工程一致的较新版本（工程曾使用 Xcode 16+ / iOS 17+ SDK） |
| 工程入口 | 根目录 `Aura.xcodeproj` |
| 依赖 | Firebase 通过 **Swift Package Manager** 引入（首次打开 Xcode 会自动解析；若失败：`File` → `Add Package Dependencies` → `https://github.com/firebase/firebase-ios-sdk.git`） |

打开后选择真机或模拟器，`⌘B` 编译、`⌘R` 运行。

---

## 2. 必做：本地密钥文件 `Config.swift`（Poe / 大模型）

### 2.1 为什么仓库里可能没有 `Config.swift`

`Aura/Config.swift` 已在 **`.gitignore`** 中忽略，**不会随 `git pull` 下发**，避免把 API Key 提交到 Git。

接手后必须**本地新建**该文件。

### 2.2 一键创建步骤

1. 复制模板到工程内（与 `AuraApp.swift` 同级目录 `Aura/` 下）：

   ```bash
   cp docs/Config.swift.template Aura/Config.swift
   ```

2. 用 Xcode 或编辑器打开 `Aura/Config.swift`，将 `YOUR_POE_API_KEY` 等占位符改为真实值。

3. 确认 `Aura` 文件夹已被工程同步（本工程使用 **Folder-based** 同步，一般无需手动「Add Files」；若编译报找不到 `APIConfig`，检查文件是否在 `Aura/` 目录下且文件名为 `Config.swift`）。

### 2.3 切换到「新开发者自己的 Poe 账号」

1. 使用接手人的 Poe 账号登录 [Poe](https://poe.com/)。
2. 在 Poe 的 API 页面创建 **API Key**（官方文档入口一般为 [Poe API](https://poe.com/api_key)，以 Poe 当前页面为准）。
3. 在 `Aura/Config.swift` 中修改：

   | 常量 | 含义 |
   |------|------|
   | `openAIAPIKey` | 新账号的 Poe API Key |
   | `openAIEndpoint` | 保持 `https://api.poe.com/v1/chat/completions`（除非 Poe 文档变更） |
   | `openAIModel` | Tab4 AI 建议等**纯文本对话**使用的模型名（Poe 上对应的 bot/model id） |
   | `nutritionModel` | Tab2 **图片营养分析**使用的模型名（需支持多模态；以 Poe 控制台/文档为准） |

4. **模型名必须与 Poe 账号下可用模型一致**；若 403 / model not found，在 Poe 文档或控制台核对名称后修改 `openAIModel` / `nutritionModel`。

### 2.4 代码中哪里用到了这些配置

- Tab2 营养分析：`Aura/ViewModels/NutritionViewModel.swift`（请求体里的 `model` 使用 `APIConfig.nutritionModel`）。
- Tab4 AI 对话：`Aura/Services/AIChatService.swift`（`model` 使用 `APIConfig.openAIModel`）。

---

## 3. 必做：Google Firebase 切换到新开发者/新项目

Firebase 通过 **`Aura/GoogleService-Info.plist`** 绑定到具体 Firebase 项目；要换账号或换项目，需要**替换该 plist**，并保证 **Bundle ID 一致**。

### 3.1 当前工程里的 Bundle ID（以 Xcode 为准）

在 Xcode 中：`Target Aura` → `Signing & Capabilities` → **Bundle Identifier**。

> **注意**：仓库里若存在旧的 `GoogleService-Info.plist`，其中的 `BUNDLE_ID` 可能与当前 Xcode 设置不一致。以 **Xcode 里显示的 Bundle ID** 为准，在 Firebase 控制台注册 iOS 应用时必须填写**同一个** Bundle ID。

### 3.2 新开发者接入自己的 Firebase 的步骤

1. 使用接手人的 Google 账号登录 [Firebase Console](https://console.firebase.google.com/)。
2. **新建项目**（或进入已有项目）→ **添加 iOS 应用**。
3. **iOS Bundle ID** 填写与 Xcode **完全一致**的 Bundle Identifier。
4. 下载新的 **`GoogleService-Info.plist`**。
5. 在工程中 **替换** `Aura/GoogleService-Info.plist`（建议先备份旧文件；拖入 Xcode 时勾选 *Copy items if needed*，并勾选 Target **Aura**）。
6. 在 Firebase 控制台启用与本项目一致的能力（详见下文「功能清单」）。
7. 配置 **Firestore / Storage 安全规则**（可参考仓库内 `FIREBASE_SETUP.md` 中的示例规则；生产环境请按业务收紧权限）。

### 3.3 本项目会用到的 Firebase 能力

| 能力 | 用途 |
|------|------|
| **Authentication** | 邮箱密码注册/登录（Email/Password） |
| **Firestore** | 用户资料、营养记录、运动记录等 |
| **Storage** | 营养分析等食物图片上传 |

代码里出现的集合名示例（便于你对照规则与数据）：`userProfiles`、`nutritionRecords`、`fitnessRecords` 等（以 `Aura/Services/FirebaseManager.swift` 与各 ViewModel 调用为准）。

### 3.4 更详细的 Firebase 图文步骤

请阅读仓库根目录 **`FIREBASE_SETUP.md`**；其中若出现与当前 Bundle ID 不一致的示例文字，以 **你 Xcode + 新下载的 plist** 为准。

---

## 4. Apple 开发者账号与签名

- **Team / 证书**：在 Xcode `Signing & Capabilities` 中改为接手人所属 **Development Team**。
- **HealthKit**：工程含 `Aura/Aura.entitlements` 中的 HealthKit；上架时 Info 中需包含读/写健康数据用途说明（工程已通过 `INFOPLIST_KEY_NSHealthShareUsageDescription` / `INFOPLIST_KEY_NSHealthUpdateUsageDescription` 等配置生成）。

---

## 5. 可选：上架与符号表（dSYM）

若 Organizer 上传时出现 **Firebase 相关 framework 缺少 dSYM** 的提示：

- 一般为 **警告**；可按 Firebase / Apple 文档在 Archive 中确认 **Debug Information Format** 为含 dSYM，并检查 SPM 产物的符号上传方式。
- 不影响时可先以 App Store Connect 实际校验结果为准。

---

## 6. 交接检查清单（建议打印或打勾）

- [ ] `cp docs/Config.swift.template Aura/Config.swift` 并已填入 **Poe API Key**
- [ ] `openAIEndpoint`、`openAIModel`、`nutritionModel` 与 Poe 账号可用模型一致
- [ ] 已用新 Google 账号创建/接入 Firebase，并替换 **`Aura/GoogleService-Info.plist`**
- [ ] Firebase 中 iOS 应用的 **Bundle ID** 与 Xcode **一致**
- [ ] 已启用 **Auth（邮箱密码）**、**Firestore**、**Storage**，规则可读写测试账号数据
- [ ] Xcode **Signing** 已改为接手人 Team，真机可运行
- [ ] 未将 `Config.swift` 或含真实 Key 的 plist **提交到 Git**

---

## 7. 相关文档索引

| 文档 | 内容 |
|------|------|
| `FIREBASE_SETUP.md` | Firebase 创建、SDK、规则示例 |
| `FIREBASE_IMPLEMENTATION_SUMMARY.md` | Firebase 功能实现摘要 |
| `docs/Config.swift.template` | 本地 `Config.swift` 模板（复制即用） |
| `README.md` / `QUICKSTART.md` | 项目说明与快速运行 |

---

## 8. 安全提醒（务必转达接手人）

- **Poe API Key、Firebase plist 中的密钥** 均属敏感信息，勿提交到公开仓库。
- 生产环境更推荐：**App 只调自有后端**，由后端持有第三方 Key。

---

*文档版本：与仓库同步维护；若 Poe/Firebase 控制台流程变更，请以官方最新文档为准。*
