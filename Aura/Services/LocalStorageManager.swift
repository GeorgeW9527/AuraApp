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
        createDirectoryIfNeeded(dataDirectory)
        print("📦 LocalStorageManager 初始化完成, 数据目录: \(dataDirectory.path)")
    }
    
    // MARK: - 目录路径
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataDirectory: URL {
        documentsDirectory.appendingPathComponent("AuraData", isDirectory: true)
    }
    
    private var userProfileFile: URL {
        dataDirectory.appendingPathComponent("user_profile.json")
    }

    private var userAvatarFile: URL {
        dataDirectory.appendingPathComponent("user_avatar.jpg")
    }
    
    private func nutritionRecordsFile(userId: String) -> URL {
        dataDirectory.appendingPathComponent("nutrition_records_\(userId).json")
    }

    private static let legacyNutritionRecordsFile = "nutrition_records.json"

    private var workoutRecordsFile: URL {
        dataDirectory.appendingPathComponent("workout_records.json")
    }

    private func nutritionImagesDirectory(userId: String) -> URL {
        dataDirectory.appendingPathComponent("NutritionImages_\(userId)")
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
        var restingHeartRate: Int?
        var healthGoal: String?
        var useMetric: Bool?
        var hasCompletedQuestionnaire: Bool?
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
            restingHeartRate: profile.restingHeartRate,
            healthGoal: profile.healthGoal,
            useMetric: profile.useMetric,
            hasCompletedQuestionnaire: profile.hasCompletedQuestionnaire,
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
                restingHeartRate: local.restingHeartRate,
                healthGoal: local.healthGoal,
                useMetric: local.useMetric,
                hasCompletedQuestionnaire: local.hasCompletedQuestionnaire,
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
    
    // MARK: - 营养记录（按 userId 分文件存储，切换账号后数据保留）

    func saveNutritionRecords(_ records: [LocalNutritionRecord], userId: String) {
        guard !userId.isEmpty else { return }
        createDirectoryIfNeeded(dataDirectory)
        let fileURL = nutritionRecordsFile(userId: userId)
        do {
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
            print("💾 营养记录已保存到本地: \(records.count) 条 (userId: \(userId.prefix(8))...)")
        } catch {
            print("❌ 保存营养记录失败: \(error)")
        }
    }

    func loadNutritionRecords(userId: String) -> [LocalNutritionRecord] {
        guard !userId.isEmpty else { return [] }
        let fileURL = nutritionRecordsFile(userId: userId)
        if fileManager.fileExists(atPath: fileURL.path) {
            return loadNutritionRecordsFrom(fileURL: fileURL, userId: userId)
        }
        let legacyURL = dataDirectory.appendingPathComponent(Self.legacyNutritionRecordsFile)
        if fileManager.fileExists(atPath: legacyURL.path) {
            let records = loadNutritionRecordsFrom(fileURL: legacyURL, userId: userId)
            if !records.isEmpty {
                saveNutritionRecords(records, userId: userId)
                try? fileManager.removeItem(at: legacyURL)
                print("📦 已迁移旧版营养记录到当前账号")
            }
            return records
        }
        return []
    }

    private func loadNutritionRecordsFrom(fileURL: URL, userId: String) -> [LocalNutritionRecord] {
        do {
            let data = try Data(contentsOf: fileURL)
            let records = try decoder.decode([LocalNutritionRecord].self, from: data)
            print("✅ 从本地加载营养记录: \(records.count) 条")
            return records
        } catch {
            print("❌ 解析营养记录失败: \(error)")
            return []
        }
    }

    /// 保存图片到本地（按 userId 分目录）
    func saveNutritionImage(_ image: UIImage, id: String, userId: String) -> String? {
        guard !userId.isEmpty else { return nil }
        let dir = nutritionImagesDirectory(userId: userId)
        createDirectoryIfNeeded(dir)
        let fileName = "\(id).jpg"
        let fileURL = dir.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.7) else {
            print("❌ 图片压缩失败")
            return nil
        }

        do {
            try data.write(to: fileURL, options: .atomic)
            print("💾 图片已保存到本地: \(fileName)")
            return fileName
        } catch {
            print("❌ 保存图片失败: \(error)")
            return nil
        }
    }

    /// 从本地加载图片（按 userId 分目录，兼容旧版路径）
    func loadNutritionImage(fileName: String, userId: String) -> UIImage? {
        guard !fileName.isEmpty else { return nil }
        // 1. 优先从 per-user 目录加载
        if !userId.isEmpty {
            let fileURL = nutritionImagesDirectory(userId: userId).appendingPathComponent(fileName)
            if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
                return img
            }
        }
        // 2. 回退到旧版路径 Documents/NutritionImages 或 AuraData/NutritionImages（迁移前存储位置）
        for legacyDir in [
            documentsDirectory.appendingPathComponent("NutritionImages", isDirectory: true),
            dataDirectory.appendingPathComponent("NutritionImages", isDirectory: true)
        ] {
            let legacyURL = legacyDir.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: legacyURL.path),
               let data = try? Data(contentsOf: legacyURL),
               let img = UIImage(data: data) {
                if !userId.isEmpty {
                    let id = (fileName as NSString).deletingPathExtension
                    _ = saveNutritionImage(img, id: id, userId: userId)
                }
                return img
            }
        }
        return nil
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
    
    // MARK: - 用户头像（本地缓存）

    func saveUserAvatar(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            try data.write(to: userAvatarFile, options: .atomic)
            print("💾 用户头像已保存到本地")
        } catch {
            print("❌ 保存用户头像失败: \(error)")
        }
    }

    func loadUserAvatar() -> UIImage? {
        guard fileManager.fileExists(atPath: userAvatarFile.path),
              let data = try? Data(contentsOf: userAvatarFile) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - 清除当前账号的会话数据（退出登录时调用）
    // 注意：营养记录、运动记录按 userId 分文件存储，不在此清除，切换账号后可恢复

    func clearAll() {
        try? fileManager.removeItem(at: userProfileFile)
        try? fileManager.removeItem(at: userAvatarFile)
        try? fileManager.removeItem(at: workoutRecordsFile)
        try? fileManager.removeItem(at: dataDirectory.appendingPathComponent(Self.legacyNutritionRecordsFile))
        print("🗑️ 已清除当前会话数据（营养记录按账号保留）")
    }
    
    // MARK: - 调试：检查本地文件状态
    
    func debugPrintStatus() {
        print("\n========== 📦 本地存储状态 ==========")
        print("数据目录: \(dataDirectory.path)")
        print("用户资料: \(fileManager.fileExists(atPath: userProfileFile.path) ? "✅ 存在" : "❌ 不存在")")
        let nutritionFiles = (try? fileManager.contentsOfDirectory(atPath: dataDirectory.path))?.filter { $0.hasPrefix("nutrition_records_") } ?? []
        print("营养记录文件: \(nutritionFiles.count) 个账号")
        print("运动记录: \(fileManager.fileExists(atPath: workoutRecordsFile.path) ? "✅ 存在" : "❌ 不存在")")
        
        let nutritionDirs = (try? fileManager.contentsOfDirectory(atPath: dataDirectory.path))?.filter { $0.hasPrefix("NutritionImages_") } ?? []
        print("饮食照片目录: \(nutritionDirs.count) 个账号")
        print("====================================\n")
    }
}
