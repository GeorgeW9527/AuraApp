//
//  CloudModels.swift
//  Aura
//
//  云端数据模型
//

import Foundation
import FirebaseFirestore

// MARK: - 营养记录（云端版本）

struct NutritionRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var description: String
    var imageURL: String?
    var timestamp: Date
    var userId: String
    
    init(id: String? = nil,
         foodName: String,
         calories: Double,
         protein: Double,
         carbs: Double,
         fat: Double,
         description: String,
         imageURL: String? = nil,
         timestamp: Date = Date(),
         userId: String) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.description = description
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.userId = userId
    }
    
    /// 从本地 NutritionResult 创建云端记录
    static func from(result: NutritionResult, imageURL: String?, userId: String) -> NutritionRecord {
        return NutritionRecord(
            foodName: result.foodName,
            calories: Double(result.calories),
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            description: result.description,
            imageURL: imageURL,
            userId: userId
        )
    }
}

// MARK: - 运动记录

struct FitnessRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var activityType: String      // 运动类型：跑步、游泳、骑行等
    var duration: TimeInterval    // 持续时间（秒）
    var distance: Double?         // 距离（米）
    var calories: Double          // 消耗卡路里
    var heartRate: Int?           // 平均心率
    var timestamp: Date
    var userId: String
    var notes: String?
    
    init(id: String? = nil,
         activityType: String,
         duration: TimeInterval,
         distance: Double? = nil,
         calories: Double,
         heartRate: Int? = nil,
         timestamp: Date = Date(),
         userId: String,
         notes: String? = nil) {
        self.id = id
        self.activityType = activityType
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.userId = userId
        self.notes = notes
    }
}

// MARK: - 用户配置

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var displayName: String?
    var email: String
    var avatarURL: String?
    var age: Int?
    var gender: String?           // "male", "female", "other"
    var height: Double?           // 身高（厘米）
    var weight: Double?           // 体重（千克）
    var targetWeight: Double?     // 目标体重
    var dailyCalorieGoal: Double? // 每日卡路里目标
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String? = nil,
         userId: String,
         displayName: String? = nil,
         email: String,
         avatarURL: String? = nil,
         age: Int? = nil,
         gender: String? = nil,
         height: Double? = nil,
         weight: Double? = nil,
         targetWeight: Double? = nil,
         dailyCalorieGoal: Double? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.dailyCalorieGoal = dailyCalorieGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 设备信息

struct DeviceInfo: Codable, Identifiable {
    @DocumentID var id: String?
    var deviceType: String        // "Apple Watch", "iPhone", "iPad"
    var deviceName: String
    var deviceModel: String
    var systemVersion: String
    var isConnected: Bool
    var lastSyncTime: Date?
    var userId: String
    
    init(id: String? = nil,
         deviceType: String,
         deviceName: String,
         deviceModel: String,
         systemVersion: String,
         isConnected: Bool = false,
         lastSyncTime: Date? = nil,
         userId: String) {
        self.id = id
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.systemVersion = systemVersion
        self.isConnected = isConnected
        self.lastSyncTime = lastSyncTime
        self.userId = userId
    }
}

// MARK: - 每日统计

struct DailySummary: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var totalCaloriesConsumed: Double    // 摄入卡路里
    var totalCaloriesBurned: Double      // 消耗卡路里
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var totalExerciseTime: TimeInterval  // 运动时长
    var stepCount: Int?                  // 步数
    var waterIntake: Double?             // 饮水量（毫升）
    var userId: String
    
    init(id: String? = nil,
         date: Date = Date(),
         totalCaloriesConsumed: Double = 0,
         totalCaloriesBurned: Double = 0,
         totalProtein: Double = 0,
         totalCarbs: Double = 0,
         totalFat: Double = 0,
         totalExerciseTime: TimeInterval = 0,
         stepCount: Int? = nil,
         waterIntake: Double? = nil,
         userId: String) {
        self.id = id
        self.date = date
        self.totalCaloriesConsumed = totalCaloriesConsumed
        self.totalCaloriesBurned = totalCaloriesBurned
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.totalExerciseTime = totalExerciseTime
        self.stepCount = stepCount
        self.waterIntake = waterIntake
        self.userId = userId
    }
}
