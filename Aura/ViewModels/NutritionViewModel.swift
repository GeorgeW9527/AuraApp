//
//  NutritionViewModel.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import Combine
import FirebaseAuth

struct NutritionResult: Codable, Identifiable {
    let id: UUID
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let description: String
    
    init(id: UUID = UUID(), foodName: String, calories: Int, protein: Double, carbs: Double, fat: Double, description: String) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.description = description
    }
}

struct NutritionHistoryItem: Identifiable {
    let id: UUID
    let image: UIImage
    let result: NutritionResult
    let date: Date
    
    init(id: UUID = UUID(), image: UIImage, result: NutritionResult, date: Date = Date()) {
        self.id = id
        self.image = image
        self.result = result
        self.date = date
    }
}

@MainActor
class NutritionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult: NutritionResult?
    @Published var isAnalyzing = false
    @Published var history: [NutritionHistoryItem] = []
    @Published var errorMessage: String?
    
    // 云端同步
    private let firebaseManager = FirebaseManager.shared
    @Published var cloudRecords: [NutritionRecord] = []
    @Published var isSyncing = false
    
    func analyzeImage() {
        guard let selectedImage = selectedImage else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        // 调用真实的AI API
        Task {
            do {
                let result = try await analyzeWithAI(image: selectedImage)
                await MainActor.run {
                    self.analysisResult = result
                    self.isAnalyzing = false
                }
            } catch let error as NSError {
                await MainActor.run {
                    // 更友好的错误提示
                    if error.code == NSURLErrorTimedOut || error.domain == NSURLErrorDomain {
                        self.errorMessage = "请求超时，请检查网络连接或稍后重试"
                    } else if error.code == NSURLErrorNotConnectedToInternet {
                        self.errorMessage = "网络未连接，请检查网络设置"
                    } else {
                        self.errorMessage = "分析失败: \(error.localizedDescription)"
                    }
                    self.isAnalyzing = false
                    print("❌ AI分析错误: \(error)")
                    print("❌ 错误代码: \(error.code)")
                    print("❌ 错误域: \(error.domain)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "分析失败: \(error.localizedDescription)"
                    self.isAnalyzing = false
                    print("❌ AI分析错误: \(error)")
                }
            }
        }
    }
    
    func analyzeWithAI(image: UIImage) async throws -> NutritionResult {
        print("\n========== 🚀 开始AI分析 ==========")
        print("⏰ 当前时间: \(Date())")
        
        // 先缩小图片尺寸
        print("📐 原始图片尺寸: \(image.size.width) x \(image.size.height)")
        let resizedImage = resizeImage(image, maxSize: 1024)
        
        // 压缩图片
        print("🗜️ 开始压缩图片，质量: \(APIConfig.imageCompressionQuality)")
        guard let imageData = resizedImage.jpegData(compressionQuality: APIConfig.imageCompressionQuality) else {
            print("❌ 图片压缩失败")
            throw NSError(domain: "ImageError", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "无法处理图片"])
        }
        
        print("✅ 图片压缩成功: \(imageData.count) bytes (\(imageData.count / 1024) KB)")
        
        print("🔄 开始Base64编码...")
        let base64Image = imageData.base64EncodedString()
        print("✅ Base64编码完成，长度: \(base64Image.count) 字符")
        
        // 构建API请求
        print("\n📡 构建API请求...")
        print("🌐 API端点: \(APIConfig.openAIEndpoint)")
        print("🤖 模型: \(APIConfig.openAIModel)")
        print("🔑 API密钥: \(APIConfig.openAIAPIKey)")
        print("🔑 密钥长度: \(APIConfig.openAIAPIKey.count) 字符")
        
        guard let url = URL(string: APIConfig.openAIEndpoint) else {
            print("❌ URL无效")
            throw NSError(domain: "URLError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无效的API端点"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 标准OpenAI格式请求头（适用于中转API）
        request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 添加标准HTTP头避免被拦截
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        // 关键：使用真实的User-Agent
        request.setValue("Aura-Health-App/1.0 (iOS 17.0; iPhone)", forHTTPHeaderField: "User-Agent")
        
        // 设置缓存策略
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        request.timeoutInterval = APIConfig.requestTimeout
        
        print("⏱️ 超时设置: \(APIConfig.requestTimeout) 秒")
        print("🔧 使用标准HTTP请求头（适配中转API）")
        print("⚠️ 注意：您使用的是中转API服务，不是官方API")
        
        print("\n📋 请求头详情:")
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                if key == "Authorization" {
                    print("   - \(key): Bearer \(String(value.dropFirst(7).prefix(10)))...")
                } else {
                    print("   - \(key): \(value)")
                }
            }
        }
        
        // 构建请求体
        print("\n📦 构建请求体...")
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": """
                        请分析这张食物图片，提供以下信息（用中文回答）：
                        1. 食物名称
                        2. 估算的总卡路里（整数）
                        3. 蛋白质含量（克，保留一位小数）
                        4. 碳水化合物含量（克，保留一位小数）
                        5. 脂肪含量（克，保留一位小数）
                        6. 简短的营养描述和建议（50字以内）
                        
                        请严格按照以下JSON格式返回，不要包含其他内容：
                        {
                            "foodName": "食物名称",
                            "calories": 数值,
                            "protein": 数值,
                            "carbs": 数值,
                            "fat": 数值,
                            "description": "描述文字"
                        }
                        """
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": APIConfig.openAIModel,
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let requestBodySize = request.httpBody?.count ?? 0
        print("✅ 请求体构建完成: \(requestBodySize) bytes (\(requestBodySize / 1024) KB)")
        print("📊 请求参数:")
        print("   - model: \(APIConfig.openAIModel)")
        print("   - max_tokens: 500")
        print("   - temperature: 0.7")
        print("   - 图片Base64长度: \(base64Image.count)")
        
        print("\n🚀 发送HTTP请求...")
        print("⏰ 开始时间: \(Date())")
        
        let startTime = Date()
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("✅ 收到响应! 耗时: \(String(format: "%.2f", elapsed)) 秒")
            
            // 检查HTTP响应
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 响应类型错误")
                throw NSError(domain: "ResponseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
            }
            
            print("\n📡 HTTP响应详情:")
            print("   - 状态码: \(httpResponse.statusCode)")
            print("   - 响应大小: \(data.count) bytes")
            print("   - Content-Type: \(httpResponse.allHeaderFields["Content-Type"] ?? "未知")")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                print("❌ API返回错误状态码: \(httpResponse.statusCode)")
                print("❌ 完整错误响应: \(errorMessage)")
                
                // 特别处理403错误
                if httpResponse.statusCode == 403 {
                    print("⚠️ 403 Forbidden - 可能的原因:")
                    print("   1. API密钥无效或过期")
                    print("   2. 中转服务的Cloudflare防护")
                    print("   3. IP被限制")
                    print("   4. 模型名称不支持: \(APIConfig.openAIModel)")
                    print("💡 建议:")
                    print("   - 检查中转服务商的控制台")
                    print("   - 确认API密钥是否有效")
                    print("   - 尝试更换模型名称")
                    print("   - 联系中转服务商客服")
                }
                
                throw NSError(domain: "APIError", code: httpResponse.statusCode,
                             userInfo: [NSLocalizedDescriptionKey: "API返回错误 (\(httpResponse.statusCode)): \(errorMessage)"])
            }
            
            print("\n🔍 开始解析响应...")
            
            // 先打印原始响应（前500字符）
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(500))
                print("📄 响应预览: \(preview)...")
            }
            
            // 解析响应
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ 无法解析为JSON对象")
                throw NSError(domain: "ParseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "无法解析API响应"])
            }
            
            print("✅ JSON解析成功")
            print("📋 JSON keys: \(json.keys.joined(separator: ", "))")
            
            guard let choices = json["choices"] as? [[String: Any]] else {
                print("❌ 找不到choices字段")
                throw NSError(domain: "ParseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "响应格式错误：缺少choices"])
            }
            
            print("✅ 找到choices数组，数量: \(choices.count)")
            
            guard let firstChoice = choices.first else {
                print("❌ choices数组为空")
                throw NSError(domain: "ParseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "响应格式错误：choices为空"])
            }
            
            guard let message = firstChoice["message"] as? [String: Any] else {
                print("❌ 找不到message字段")
                throw NSError(domain: "ParseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "响应格式错误：缺少message"])
            }
            
            guard let content = message["content"] as? String else {
                print("❌ 找不到content字段")
                throw NSError(domain: "ParseError", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "响应格式错误：缺少content"])
            }
            
            print("✅ 成功提取AI回复内容")
            print("📝 内容长度: \(content.count) 字符")
            print("📝 内容预览: \(String(content.prefix(100)))...")
            
            print("\n🍎 开始解析营养信息...")
            
            // 解析营养信息JSON
            // 尝试提取JSON部分（可能包含在markdown代码块中）
            var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 原始内容: \(jsonString)")
            
            if jsonString.contains("```json") {
                print("🔧 检测到markdown代码块，正在提取...")
                jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                                       .replacingOccurrences(of: "```", with: "")
                                       .trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ 提取后: \(jsonString)")
            }
            
            guard let contentData = jsonString.data(using: .utf8) else {
                print("❌ 无法转换为Data")
                throw NSError(domain: "ParseError", code: -2,
                             userInfo: [NSLocalizedDescriptionKey: "无法解析营养信息"])
            }
            
            guard let nutritionJSON = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
                print("❌ 无法解析营养信息JSON")
                print("❌ 尝试解析的字符串: \(jsonString)")
                throw NSError(domain: "ParseError", code: -2,
                             userInfo: [NSLocalizedDescriptionKey: "无法解析营养信息"])
            }
            
            print("✅ 营养信息JSON解析成功")
            print("📋 字段: \(nutritionJSON.keys.joined(separator: ", "))")
            
            // 构建结果
            print("\n🔨 构建结果对象...")
            let foodName = nutritionJSON["foodName"] as? String ?? "未知食物"
            let calories = nutritionJSON["calories"] as? Int ?? 0
            let protein = nutritionJSON["protein"] as? Double ?? 0.0
            let carbs = nutritionJSON["carbs"] as? Double ?? 0.0
            let fat = nutritionJSON["fat"] as? Double ?? 0.0
            let description = nutritionJSON["description"] as? String ?? ""
            
            print("✅ 结果提取完成:")
            print("   - 食物: \(foodName)")
            print("   - 卡路里: \(calories) kcal")
            print("   - 蛋白质: \(protein)g")
            print("   - 碳水: \(carbs)g")
            print("   - 脂肪: \(fat)g")
            print("   - 描述: \(description)")
            
            let totalElapsed = Date().timeIntervalSince(startTime)
            print("\n🎉 分析完成! 总耗时: \(String(format: "%.2f", totalElapsed)) 秒")
            print("========== ✅ 分析结束 ==========\n")
            
            return NutritionResult(
                foodName: foodName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                description: description
            )
            
        } catch let error as NSError {
            let elapsed = Date().timeIntervalSince(startTime)
            print("\n❌ 请求失败! 耗时: \(String(format: "%.2f", elapsed)) 秒")
            print("❌ 错误类型: \(error.domain)")
            print("❌ 错误代码: \(error.code)")
            print("❌ 错误描述: \(error.localizedDescription)")
            
            if error.code == NSURLErrorTimedOut {
                print("⏰ 超时原因分析:")
                print("   - 网络速度慢")
                print("   - 图片太大: \(imageData.count / 1024) KB")
                print("   - API服务器响应慢")
                print("   - 超时设置: \(APIConfig.requestTimeout) 秒")
            }
            
            print("========== ❌ 分析失败 ==========\n")
            throw error
        }
    }
    
    func saveToHistory() {
        guard let image = selectedImage, let result = analysisResult else { return }
        
        let historyItem = NutritionHistoryItem(
            image: image,
            result: result
        )
        
        history.insert(historyItem, at: 0)
        
        // 限制历史记录数量
        if history.count > 20 {
            history = Array(history.prefix(20))
        }
    }
    
    func clearAnalysis() {
        selectedImage = nil
        analysisResult = nil
        errorMessage = nil
    }
    
    // 缩小图片尺寸以加快上传速度
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        // 如果图片已经够小，直接返回
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        // 计算缩放比例
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // 创建新图片
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        print("📏 图片缩放: \(size.width)x\(size.height) → \(newSize.width)x\(newSize.height)")
        
        return resizedImage
    }
    
    // MARK: - 云端同步功能
    
    /// 保存分析结果到云端
    func saveToCloud(result: NutritionResult, image: UIImage) async {
        guard let userId = firebaseManager.currentUser?.uid else {
            print("⚠️ 用户未登录，跳过云端保存")
            return
        }
        
        isSyncing = true
        
        do {
            // 1. 上传图片到 Storage
            print("📤 开始上传图片到云端...")
            let imagePath = "nutrition/\(UUID().uuidString).jpg"
            let imageURL = try await firebaseManager.uploadImage(image, path: imagePath)
            
            // 2. 创建云端记录
            let record = NutritionRecord.from(
                result: result,
                imageURL: imageURL,
                userId: userId
            )
            
            // 3. 保存到 Firestore
            print("💾 保存营养记录到 Firestore...")
            try await firebaseManager.saveData(
                collection: "nutritionRecords",
                documentId: record.id ?? UUID().uuidString,
                data: record
            )
            
            print("✅ 云端保存成功")
            
            // 4. 刷新云端记录列表
            await loadCloudRecords()
            
        } catch {
            print("❌ 云端保存失败: \(error.localizedDescription)")
            errorMessage = "云端保存失败: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
    
    /// 从云端加载记录
    func loadCloudRecords() async {
        guard firebaseManager.currentUser != nil else {
            print("⚠️ 用户未登录，跳过云端加载")
            return
        }
        
        isSyncing = true
        
        do {
            print("📥 从云端加载营养记录...")
            let records = try await firebaseManager.fetchCollection(
                collection: "nutritionRecords",
                as: NutritionRecord.self
            )
            
            // 按时间倒序排列
            cloudRecords = records.sorted { $0.timestamp > $1.timestamp }
            print("✅ 加载了 \(cloudRecords.count) 条云端记录")
            
        } catch {
            print("❌ 云端加载失败: \(error.localizedDescription)")
            errorMessage = "云端加载失败: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
    
    /// 删除云端记录
    func deleteCloudRecord(_ record: NutritionRecord) async {
        guard let recordId = record.id else { return }
        
        isSyncing = true
        
        do {
            // 1. 删除 Firestore 记录
            try await firebaseManager.deleteData(
                collection: "nutritionRecords",
                documentId: recordId
            )
            
            // 2. 删除 Storage 图片
            if let imageURL = record.imageURL,
               let url = URL(string: imageURL),
               let path = url.pathComponents.dropFirst(4).joined(separator: "/") as String? {
                try? await firebaseManager.deleteImage(path: path)
            }
            
            // 3. 刷新列表
            await loadCloudRecords()
            
            print("✅ 云端记录删除成功")
            
        } catch {
            print("❌ 云端删除失败: \(error.localizedDescription)")
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
}
