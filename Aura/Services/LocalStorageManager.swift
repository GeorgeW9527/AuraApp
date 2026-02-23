//
//  LocalStorageManager.swift
//  Aura
//
//  本地数据持久化管理器
//  使用 UserDefaults + 文件系统，保证数据在无网络时也能持久化
//

import Foundation
import UIKit

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        // 确保文档目录存在
        createDirectoryIfNeeded(nutritionImagesDirectory)
        print("📦 LocalStorageManager 初始化完成")
    }
    
    // MARK: - 目录路径
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var nutritionImagesDirectory: URL {
        documentsDirectory.appendingPathComponent("NutritionImages", isDirectory: true)
    }
    
    private func createDirectoryIfNeeded(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let userProfile = "aura_user_profile"
        static let nutritionRecords = "aura_nutrition_records"
        static let workoutHistory = "aura_workout_history"
    }
    
    // MARK: - 用户资料
    
    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try encoder.encode(profile)
            defaults.set(data, forKey: Keys.userProfile)
            defaults.synchronize()
            print("💾 用户资料已保存到本地")
        } catch {
            print("❌ 保存用户资料失败: \(error.localizedDescription)")
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: Keys.userProfile) else {
            print("ℹ️ 本地没有用户资料")
            return nil
        }
        do {
            let profile = try decoder.decode(UserProfile.self, from: data)
            print("✅ 从本地加载用户资料成功: \(profile.displayName ?? "无昵称")")
            return profile
        } catch {
            print("❌ 解析本地用户资料失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 营养记录
    
    /// 本地存储用的营养记录结构（包含图片文件名而非 UIImage）
    struct LocalNutritionRecord: Codable {
        var id: String
        var foodName: String
        var calories: Int
        var protein: Double
        var carbs: Double
        var fat: Double
        var description: String
        var imageFileName: String? // 本地图片文件名
        var imageURL: String?      // 云端图片URL
        var timestamp: Date
    }
    
    func saveNutritionRecords(_ records: [LocalNutritionRecord]) {
        do {
            let data = try encoder.encode(records)
            defaults.set(data, forKey: Keys.nutritionRecords)
            defaults.synchronize()
            print("💾 营养记录已保存到本地: \(records.count) 条")
        } catch {
            print("❌ 保存营养记录失败: \(error.localizedDescription)")
        }
    }
    
    func loadNutritionRecords() -> [LocalNutritionRecord] {
        guard let data = defaults.data(forKey: Keys.nutritionRecords) else {
            print("ℹ️ 本地没有营养记录")
            return []
        }
        do {
            let records = try decoder.decode([LocalNutritionRecord].self, from: data)
            print("✅ 从本地加载营养记录成功: \(records.count) 条")
            return records
        } catch {
            print("❌ 解析本地营养记录失败: \(error.localizedDescription)")
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
            try data.write(to: fileURL)
            print("💾 图片已保存到本地: \(fileName)")
            return fileName
        } catch {
            print("❌ 保存图片失败: \(error.localizedDescription)")
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
    
    struct LocalWorkoutRecord: Codable {
        var id: String
        var type: String       // WorkoutType.rawValue
        var duration: Int
        var calories: Int
        var date: Date
    }
    
    func saveWorkoutRecords(_ records: [LocalWorkoutRecord]) {
        do {
            let data = try encoder.encode(records)
            defaults.set(data, forKey: Keys.workoutHistory)
            defaults.synchronize()
            print("💾 运动记录已保存到本地: \(records.count) 条")
        } catch {
            print("❌ 保存运动记录失败: \(error.localizedDescription)")
        }
    }
    
    func loadWorkoutRecords() -> [LocalWorkoutRecord] {
        guard let data = defaults.data(forKey: Keys.workoutHistory) else {
            print("ℹ️ 本地没有运动记录")
            return []
        }
        do {
            let records = try decoder.decode([LocalWorkoutRecord].self, from: data)
            print("✅ 从本地加载运动记录成功: \(records.count) 条")
            return records
        } catch {
            print("❌ 解析本地运动记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 清除所有本地数据（退出登录时调用）
    
    func clearAll() {
        defaults.removeObject(forKey: Keys.userProfile)
        defaults.removeObject(forKey: Keys.nutritionRecords)
        defaults.removeObject(forKey: Keys.workoutHistory)
        defaults.synchronize()
        
        // 清除图片文件
        try? fileManager.removeItem(at: nutritionImagesDirectory)
        createDirectoryIfNeeded(nutritionImagesDirectory)
        
        print("🗑️ 已清除所有本地数据")
    }
}
