//
//  LocalStorageManager.swift
//  Aura
//
//  本地数据持久化管理器
//  使用文件系统（Documents 目录）存 JSON，保证数据在无网络时也能持久化
//  不依赖 Firebase 的 @DocumentID，使用纯净的本地模型
//

import Foundation
import UIKit

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    private init() {
        // 确保所有目录存在
        createDirectoryIfNeeded(dataDirectory)
        createDirectoryIfNeeded(nutritionImagesDirectory)
        print("📦 LocalStorageManager 初始化完成, 数据目录: \(dataDirectory.path)")
    }
    
    // MARK: - 目录路径
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataDirectory: URL {
        documentsDirectory.appendingPathComponent("AuraData", isDirectory: true)
    }
    
    private var nutritionImagesDirectory: URL {
        documentsDirectory.appendingPathComponent("NutritionImages", isDirectory: true)
    }
    
    private var userProfileFile: URL {
        dataDirectory.appendingPathComponent("user_profile.json")
    }
    
    private var nutritionRecordsFile: URL {
        dataDirectory.appendingPathComponent("nutrition_records.json")
    }
    
    private var workoutRecordsFile: URL {
        dataDirectory.appendingPathComponent("workout_records.json")
    }
    
    private func createDirectoryIfNeeded(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - 纯净本地模型（不含 @DocumentID）
    
    struct LocalUserProfile: Codable {
        var userId: String
        var displayName: String?
        var email: String
        var avatarURL: String?
        var age: Int?
        var gender: String?
        var height: Double?
        var weight: Double?
        var targetWeight: Double?
        var dailyCalorieGoal: Double?
        var createdAt: Date
        var updatedAt: Date
    }
    
    struct LocalNutritionRecord: Codable {
        var id: String
        var foodName: String
        var calories: Int
        var protein: Double
        var carbs: Double
        var fat: Double
        var description: String
        var imageFileName: String?
        var imageURL: String?
        var timestamp: Date
    }
    
    struct LocalWorkoutRecord: Codable {
        var id: String
        var type: String
        var duration: Int
        var calories: Int
        var date: Date
    }
    
    // MARK: - 用户资料
    
    func saveUserProfile(_ profile: UserProfile) {
        let local = LocalUserProfile(
            userId: profile.userId,
            displayName: profile.displayName,
            email: profile.email,
            avatarURL: profile.avatarURL,
            age: profile.age,
            gender: profile.gender,
            height: profile.height,
            weight: profile.weight,
            targetWeight: profile.targetWeight,
            dailyCalorieGoal: profile.dailyCalorieGoal,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
        
        do {
            let data = try encoder.encode(local)
            try data.write(to: userProfileFile, options: .atomic)
            print("💾 用户资料已保存到本地文件: \(userProfileFile.lastPathComponent)")
            print("   - 昵称: \(local.displayName ?? "无"), 身高: \(local.height ?? 0), 体重: \(local.weight ?? 0)")
        } catch {
            print("❌ 保存用户资料失败: \(error)")
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        guard fileManager.fileExists(atPath: userProfileFile.path) else {
            print("ℹ️ 本地用户资料文件不存在: \(userProfileFile.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: userProfileFile)
            let local = try decoder.decode(LocalUserProfile.self, from: data)
            
            let profile = UserProfile(
                userId: local.userId,
                displayName: local.displayName,
                email: local.email,
                avatarURL: local.avatarURL,
                age: local.age,
                gender: local.gender,
                height: local.height,
                weight: local.weight,
                targetWeight: local.targetWeight,
                dailyCalorieGoal: local.dailyCalorieGoal,
                createdAt: local.createdAt,
                updatedAt: local.updatedAt
            )
            
            print("✅ 从本地文件加载用户资料成功")
            print("   - 昵称: \(local.displayName ?? "无"), 身高: \(local.height ?? 0), 体重: \(local.weight ?? 0)")
            return profile
        } catch {
            print("❌ 解析本地用户资料失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 营养记录
    
    func saveNutritionRecords(_ records: [LocalNutritionRecord]) {
        do {
            let data = try encoder.encode(records)
            try data.write(to: nutritionRecordsFile, options: .atomic)
            print("💾 营养记录已保存到本地文件: \(records.count) 条")
        } catch {
            print("❌ 保存营养记录失败: \(error)")
        }
    }
    
    func loadNutritionRecords() -> [LocalNutritionRecord] {
        guard fileManager.fileExists(atPath: nutritionRecordsFile.path) else {
            print("ℹ️ 本地营养记录文件不存在")
            return []
        }
        
        do {
            let data = try Data(contentsOf: nutritionRecordsFile)
            let records = try decoder.decode([LocalNutritionRecord].self, from: data)
            print("✅ 从本地文件加载营养记录成功: \(records.count) 条")
            return records
        } catch {
            print("❌ 解析本地营养记录失败: \(error)")
            return []
        }
    }
    
    /// 保存图片到本地文件系统，返回文件名
    func saveNutritionImage(_ image: UIImage, id: String) -> String? {
        let fileName = "\(id).jpg"
        let fileURL = nutritionImagesDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            print("❌ 图片压缩失败")
            return nil
        }
        
        do {
            try data.write(to: fileURL, options: .atomic)
            print("💾 图片已保存到本地: \(fileName) (\(data.count / 1024) KB)")
            return fileName
        } catch {
            print("❌ 保存图片失败: \(error)")
            return nil
        }
    }
    
    /// 从本地文件系统加载图片
    func loadNutritionImage(fileName: String) -> UIImage? {
        let fileURL = nutritionImagesDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 运动记录
    
    func saveWorkoutRecords(_ records: [LocalWorkoutRecord]) {
        do {
            let data = try encoder.encode(records)
            try data.write(to: workoutRecordsFile, options: .atomic)
            print("💾 运动记录已保存到本地文件: \(records.count) 条")
        } catch {
            print("❌ 保存运动记录失败: \(error)")
        }
    }
    
    func loadWorkoutRecords() -> [LocalWorkoutRecord] {
        guard fileManager.fileExists(atPath: workoutRecordsFile.path) else {
            print("ℹ️ 本地运动记录文件不存在")
            return []
        }
        
        do {
            let data = try Data(contentsOf: workoutRecordsFile)
            let records = try decoder.decode([LocalWorkoutRecord].self, from: data)
            print("✅ 从本地文件加载运动记录成功: \(records.count) 条")
            return records
        } catch {
            print("❌ 解析本地运动记录失败: \(error)")
            return []
        }
    }
    
    // MARK: - 清除所有本地数据（退出登录时调用）
    
    func clearAll() {
        try? fileManager.removeItem(at: userProfileFile)
        try? fileManager.removeItem(at: nutritionRecordsFile)
        try? fileManager.removeItem(at: workoutRecordsFile)
        try? fileManager.removeItem(at: nutritionImagesDirectory)
        createDirectoryIfNeeded(nutritionImagesDirectory)
        print("🗑️ 已清除所有本地数据")
    }
    
    // MARK: - 调试：检查本地文件状态
    
    func debugPrintStatus() {
        print("\n========== 📦 本地存储状态 ==========")
        print("数据目录: \(dataDirectory.path)")
        print("用户资料: \(fileManager.fileExists(atPath: userProfileFile.path) ? "✅ 存在" : "❌ 不存在")")
        print("营养记录: \(fileManager.fileExists(atPath: nutritionRecordsFile.path) ? "✅ 存在" : "❌ 不存在")")
        print("运动记录: \(fileManager.fileExists(atPath: workoutRecordsFile.path) ? "✅ 存在" : "❌ 不存在")")
        
        if let contents = try? fileManager.contentsOfDirectory(at: nutritionImagesDirectory, includingPropertiesForKeys: nil) {
            print("饮食照片: \(contents.count) 张")
        }
        print("====================================\n")
    }
}
