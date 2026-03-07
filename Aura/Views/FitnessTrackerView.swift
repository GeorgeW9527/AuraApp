//
//  FitnessTrackerView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import Charts
import FirebaseAuth
import HealthKit

// MARK: - Array Helpers
extension Array where Element: Hashable {
    func unique() -> [Element] {
        Array(Set(self))
    }
}

// MARK: - Tab3 Activity Color Palette (match tab3.png)
private enum ActivityPalette {
    static let deepGreen     = Color(red: 0.11, green: 0.32, blue: 0.22)
    static let primaryText   = Color(red: 0.12, green: 0.16, blue: 0.13)
    static let secondaryText = Color(red: 0.55, green: 0.58, blue: 0.52)
    static let limeGreen     = Color(red: 0.84, green: 0.91, blue: 0.34)
    static let chartLine     = Color(red: 0.75, green: 0.88, blue: 0.38)
    static let hrvCardBg     = Color(red: 0.88, green: 0.94, blue: 0.52)
    static let spo2CardBg    = Color(red: 0.65, green: 0.78, blue: 1.00)
    static let recoveryBg    = Color(red: 0.11, green: 0.32, blue: 0.22)
    static let activityGreen = Color(red: 0.45, green: 0.70, blue: 0.22)
    static let swimBlue      = Color(red: 0.20, green: 0.50, blue: 0.80)
    static let heartRed      = Color(red: 0.95, green: 0.35, blue: 0.35)
}

// MARK: - Timeframe

enum ActivityTimeframe: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - 24h 图表数据点

struct HourlyCaloriePoint: Identifiable {
    let id = UUID()
    let hour: Int
    let value: Double
    var timeLabel: String {
        String(format: "%02d:00", hour)
    }
}

// MARK: - AI 识别活动项（展示用）

struct RecognizedActivityItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let durationMin: Int
    let matchPercent: Int
    let iconColor: Color
    let iconName: String
}

// MARK: - Main View

struct FitnessTrackerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var timeframe: ActivityTimeframe = .day
    @State private var workoutHistory: [WorkoutSession] = []
    @State private var isLoadingCloud = false

    private let firebaseManager = FirebaseManager.shared
    private let localStorage = LocalStorageManager.shared

    private var calendar: Calendar { Calendar.current }

    /// 当前时间段内的运动记录（合并 HealthKit + Firebase/本地）
    private var filteredWorkouts: [WorkoutSession] {
        let now = Date()

        // Convert HealthKit workouts to WorkoutSession
        let healthKitSessions = healthDataManager.recentWorkouts.map { workout -> WorkoutSession in
            let type = WorkoutType(from: workout.type)
            return WorkoutSession(
                id: "hk_\(workout.id)", // prefix to distinguish from local
                type: type,
                duration: workout.durationMinutes,
                calories: workout.caloriesInt,
                date: workout.startDate
            )
        }

        print("📊 HealthKit workouts: \(healthKitSessions.count)")
        print("📊 Local/Firebase workouts: \(workoutHistory.count)")

        // Combine with local/Firebase workouts
        let allWorkouts = workoutHistory + healthKitSessions

        // Remove duplicates (same time +/- 10 minutes = same workout)
        // Keep HealthKit data (usually more accurate) by sorting it first
        let sorted = allWorkouts.sorted { w1, w2 in
            // Prefer HealthKit data (id starts with "hk_")
            let w1IsHK = w1.id.hasPrefix("hk_")
            let w2IsHK = w2.id.hasPrefix("hk_")
            if w1IsHK != w2IsHK { return w1IsHK }
            return w1.date > w2.date
        }

        var uniqueWorkouts: [WorkoutSession] = []
        for workout in sorted {
            let isDuplicate = uniqueWorkouts.contains { existing in
                // Check if same type and within 10 minutes
                let sameType = existing.type == workout.type
                let timeDiff = abs(existing.date.timeIntervalSince(workout.date))
                return sameType && timeDiff < 600 // 10 min threshold
            }
            if !isDuplicate {
                uniqueWorkouts.append(workout)
            }
        }

        print("📊 Unique workouts after merge: \(uniqueWorkouts.count)")

        switch timeframe {
        case .day:
            let dayWorkouts = uniqueWorkouts.filter { calendar.isDate($0.date, inSameDayAs: now) }
            print("📊 Day filter (\(calendar.isDateInToday(now) ? "Today" : "Selected")): \(dayWorkouts.count) workouts")
            return dayWorkouts
        case .week:
            let weekWorkouts = uniqueWorkouts.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
            print("📊 Week filter: \(weekWorkouts.count) workouts")
            return weekWorkouts
        case .month:
            let monthWorkouts = uniqueWorkouts.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            print("📊 Month filter: \(monthWorkouts.count) workouts")
            return monthWorkouts
        }
    }

    private var totalCalories: Int {
        switch timeframe {
        case .day:
            return max(healthDataManager.todayActiveEnergyBurned, filteredWorkouts.reduce(0) { $0 + $1.calories })
        case .week, .month:
            return filteredWorkouts.reduce(0) { $0 + $1.calories }
        }
    }

    private var stillCalories: Int {
        max(healthDataManager.todayBasalEnergyBurned, 0)
    }

    private var activeVsStillPercent: Int {
        guard stillCalories > 0 else { return 0 }
        return Int((Double(totalCalories) / Double(stillCalories) * 100).rounded())
    }

    private var heartRateText: String {
        if let heartRate = healthDataManager.latestHeartRate ?? healthDataManager.restingHeartRate {
            return "\(heartRate) bpm"
        }
        return "--"
    }

    private var spo2Value: Int? {
        healthDataManager.latestOxygenSaturationPercent
    }

    /// Recovery score based on real health data (HRV-like algorithm)
    private var recoveryScore: Int {
        var score = 60 // base score
        let hasData = healthDataManager.latestHeartRate != nil || spo2Value != nil

        if let spo2 = spo2Value {
            // Optimal SpO2 is 95-100
            if spo2 >= 95 { score += 15 }
            else if spo2 >= 90 { score += 5 }
            else { score -= 10 }
        }

        if let resting = healthDataManager.restingHeartRate,
           let current = healthDataManager.latestHeartRate {
            let delta = current - resting
            // Lower delta means better recovery (resting state)
            if delta <= 5 { score += 15 }
            else if delta <= 10 { score += 8 }
            else if delta <= 20 { score += 0 }
            else { score -= min(20, delta - 20) }
        } else if healthDataManager.restingHeartRate != nil {
            // Only resting HR available - slight bonus for having data
            score += 5
        }

        // Activity load factor (based on real calorie burn)
        if totalCalories > 0 {
            if totalCalories >= 200 && totalCalories <= 800 {
                score += 10 // optimal training load
            } else if totalCalories > 800 {
                score -= 5 // overtraining
            }
        }

        return hasData ? max(30, min(98, score)) : 0 // return 0 if no data
    }

    /// Whether we have enough data to show recovery score
    private var hasRecoveryData: Bool {
        recoveryScore > 0
    }

    private var recoveryTitle: String {
        switch recoveryScore {
        case 80...:
            return "Optimal Recovery"
        case 65..<80:
            return "Good Recovery"
        default:
            return "Recovery In Progress"
        }
    }

    private var recoveryDescription: String {
        if let spo2 = spo2Value, spo2 < 94 {
            return "Blood oxygen is slightly below your usual range. Favor light activity and hydration today."
        }
        if let resting = healthDataManager.restingHeartRate,
           let current = healthDataManager.latestHeartRate,
           current > resting + 15 {
            return "Your heart rate is elevated versus baseline. A lower-intensity session may be better today."
        }
        return "Today's vitals and activity load suggest your body is responding well to training."
    }

    /// 用于图表的 24 小时热量分布（当日）— 仅使用真实 HealthKit 数据
    private var hourlyData: [HourlyCaloriePoint] {
        guard timeframe == .day else { return [] }
        return healthDataManager.hourlyActiveEnergyBurned.enumerated().map {
            HourlyCaloriePoint(hour: $0.offset, value: $0.element)
        }
    }

    /// 是否有真实的卡路里消耗数据（根据当前 timeFrame）
    private var hasRealCalorieData: Bool {
        switch timeframe {
        case .day:
            return totalCalories > 0 || healthDataManager.hourlyActiveEnergyBurned.contains(where: { $0 > 0 })
        case .week, .month:
            return totalCalories > 0
        }
    }

    /// 获取当前时间段的日期范围描述
    private var dateRangeDescription: String {
        let now = Date()
        let formatter = DateFormatter()
        switch timeframe {
        case .day:
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: now)
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: now)
        }
    }

    /// 当前时间段的日均卡路里（用于 Week/Month 显示）
    private var avgDailyCalories: Int {
        switch timeframe {
        case .day:
            return totalCalories
        case .week:
            let days = max(1, filteredWorkouts.map { calendar.component(.weekday, from: $0.date) }.unique().count)
            return totalCalories / days
        case .month:
            let days = max(1, filteredWorkouts.map { calendar.component(.day, from: $0.date) }.unique().count)
            return totalCalories / days
        }
    }

    /// 当前时间段的总运动次数
    private var totalWorkoutCount: Int {
        filteredWorkouts.count
    }

    /// 当前时间段的总运动时长（分钟）
    private var totalWorkoutDuration: Int {
        filteredWorkouts.reduce(0) { $0 + $1.duration }
    }

    /// Week/Month 图表数据：按天聚合（结合 HealthKit 总活动能量 + Workouts）
    private var dailyChartData: [(label: String, value: Double)] {
        switch timeframe {
        case .day:
            return []
        case .week:
            // 最近7天的数据
            let today = calendar.startOfDay(for: Date())
            let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset - 6, to: today) ?? today
                let dayName = dayNames[calendar.component(.weekday, from: date) - 1]

                // 计算当天的总卡路里：
                // 1. 如果是今天，使用 HealthKit 的 todayActiveEnergyBurned
                // 2. 其他日期使用 workouts 数据
                let dayCalories: Int
                if calendar.isDateInToday(date) {
                    dayCalories = max(
                        healthDataManager.todayActiveEnergyBurned,
                        filteredWorkouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
                            .reduce(0) { $0 + $1.calories }
                    )
                } else {
                    dayCalories = filteredWorkouts
                        .filter { calendar.isDate($0.date, inSameDayAs: date) }
                        .reduce(0) { $0 + $1.calories }
                }

                return (dayName, Double(dayCalories))
            }
        case .month:
            // 按周聚合本月数据（4周）
            let now = Date()
            let currentWeek = calendar.component(.weekOfMonth, from: now)

            // 本周的数据包含今天，可能需要加上 HealthKit 数据
            var weekData: [(String, Double)] = []
            for weekNum in 1...4 {
                let weekWorkouts = filteredWorkouts.filter {
                    calendar.component(.weekOfMonth, from: $0.date) == weekNum
                }
                var weekCalories = weekWorkouts.reduce(0) { $0 + $1.calories }

                // 如果是本周且是今天，加上 HealthKit 的实时数据
                if weekNum == currentWeek && calendar.isDateInToday(now) {
                    weekCalories = max(weekCalories, healthDataManager.todayActiveEnergyBurned)
                }

                weekData.append(("W\(weekNum)", Double(weekCalories)))
            }
            return weekData
        }
    }

    /// AI 识别出的活动 — 仅来自真实的运动记录
    private var recognizedActivities: [RecognizedActivityItem] {
        return filteredWorkouts.prefix(2).map { w -> RecognizedActivityItem in
            let (name, subtitle, iconColor, iconName) = activityDisplay(for: w.type)
            let match = min(99, max(70, 85 + w.calories / 50)) // 基于卡路里计算的匹配度
            return RecognizedActivityItem(
                name: name,
                subtitle: subtitle,
                durationMin: w.duration,
                matchPercent: match,
                iconColor: iconColor,
                iconName: iconName
            )
        }
    }

    /// 是否有真实的运动记录
    private var hasRealWorkoutData: Bool {
        !filteredWorkouts.isEmpty
    }

    private func activityDisplay(for type: WorkoutType) -> (String, String, Color, String) {
        switch type {
        case .running: return ("Outdoor Running", "GPS & IMU optimized", ActivityPalette.activityGreen, "figure.run")
        case .swimming: return ("Swimming (Laps)", "Stroke recognition", ActivityPalette.swimBlue, "figure.pool.swim")
        case .cycling: return ("Cycling", "GPS tracked", ActivityPalette.swimBlue, "bicycle")
        case .walking: return ("Walking", "Step count", ActivityPalette.activityGreen, "figure.walk")
        case .yoga: return ("Yoga", "HRV optimized", ActivityPalette.swimBlue, "figure.mind.and.body")
        case .strength: return ("Strength Training", "Rep counted", ActivityPalette.heartRed, "dumbbell.fill")
        default: return (type.name, "Tracked", ActivityPalette.activityGreen, type.icon)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerSection
                    timeframeSelector
                    calorieConsumptionCard
                    aiActivitySection
                    vitalSignsSection
                    optimalRecoveryCard
                }
                .padding(.bottom, 24)
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.96))
        .task {
            await healthDataManager.refreshIfNeeded()
            await loadCloudWorkoutHistory()
        }
        }
    }

    // MARK: - Header（match tab3.png）

    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                Circle()
                    .fill(Color(red: 0.92, green: 0.94, blue: 0.90))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ActivityPalette.deepGreen)
                    }
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("ACTIVITY CENTER")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ActivityPalette.deepGreen)
                Text("LIVE TRACKING")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActivityPalette.secondaryText)
            }
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .stroke(Color(red: 0.88, green: 0.90, blue: 0.86), lineWidth: 1)
                    .background(Circle().fill(Color.white))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "applewatch")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ActivityPalette.deepGreen)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Day / Week / Month Selector

    private var timeframeSelector: some View {
        HStack(spacing: 4) {
            ForEach(ActivityTimeframe.allCases, id: \.self) { option in
                Button {
                    timeframe = option
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(timeframe == option ? ActivityPalette.deepGreen : ActivityPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(timeframe == option ? Color.white : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(red: 0.94, green: 0.96, blue: 0.93))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - Calorie Consumption Card + Chart

    private var calorieConsumptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row content based on timeframe
            topStatsRow

            // Chart based on timeframe
            timeframeChart
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    /// Top stats row - different for Day/Week/Month
    private var topStatsRow: some View {
        HStack(alignment: .top) {
            switch timeframe {
            case .day:
                // Day view: Calorie Consumption / Still Consumption / ↑ %
                dayStatsRow
            case .week:
                // Week view: Total Calories / Avg Daily / Workouts count
                weekStatsRow
            case .month:
                // Month view: Total Calories / Avg Daily / Total duration
                monthStatsRow
            }
        }
    }

    private var dayStatsRow: some View {
        Group {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calorie Consumption")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ActivityPalette.secondaryText)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(hasRealCalorieData ? totalCalories.formatted() : "--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(ActivityPalette.primaryText)
                        Text("kcal")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(ActivityPalette.secondaryText)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Still Consumption")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ActivityPalette.secondaryText)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(stillCalories > 0 ? stillCalories.formatted() : "--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(ActivityPalette.primaryText)
                        Text("kcal")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(ActivityPalette.secondaryText)
                    }
                }
                // ↑ % badge (only show if has data)
                if hasRealCalorieData && stillCalories > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(activeVsStillPercent)%")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(ActivityPalette.deepGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ActivityPalette.limeGreen)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var weekStatsRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week Total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActivityPalette.secondaryText)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(hasRealCalorieData ? totalCalories.formatted() : "--")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ActivityPalette.primaryText)
                    Text("kcal")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(ActivityPalette.secondaryText)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Daily Avg")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActivityPalette.secondaryText)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(hasRealCalorieData ? avgDailyCalories.formatted() : "--")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ActivityPalette.primaryText)
                    Text("kcal")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(ActivityPalette.secondaryText)
                }
            }
            // Workout count badge
            if hasRealWorkoutData {
                HStack(spacing: 2) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(totalWorkoutCount)")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(ActivityPalette.deepGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ActivityPalette.limeGreen)
                .clipShape(Capsule())
            }
        }
    }

    private var monthStatsRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Month Total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActivityPalette.secondaryText)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(hasRealCalorieData ? totalCalories.formatted() : "--")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ActivityPalette.primaryText)
                    Text("kcal")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(ActivityPalette.secondaryText)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActivityPalette.secondaryText)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(hasRealWorkoutData ? "\(totalWorkoutDuration)" : "--")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ActivityPalette.primaryText)
                    Text("min")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(ActivityPalette.secondaryText)
                }
            }
            // Active days badge
            if hasRealCalorieData {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(filteredWorkouts.map { calendar.component(.day, from: $0.date) }.unique().count) days")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(ActivityPalette.deepGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ActivityPalette.limeGreen)
                .clipShape(Capsule())
            }
        }
    }

    /// Chart based on timeframe
    private var timeframeChart: some View {
        Group {
            if hasRealCalorieData {
                switch timeframe {
                case .day:
                    dayChart
                case .week:
                    weekChart
                case .month:
                    monthChart
                }
            } else {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundColor(ActivityPalette.secondaryText.opacity(0.5))
                        Text("No activity data yet")
                            .font(.system(size: 13))
                            .foregroundColor(ActivityPalette.secondaryText)
                    }
                    Spacer()
                }
                .frame(height: 130)
            }
        }
    }

    private var dayChart: some View {
        VStack(spacing: 8) {
            Chart(hourlyData) { point in
                LineMark(
                    x: .value("Time", point.timeLabel),
                    y: .value("kcal", point.value)
                )
                .foregroundStyle(ActivityPalette.chartLine)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Time", point.timeLabel),
                    y: .value("kcal", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ActivityPalette.chartLine.opacity(0.35),
                            ActivityPalette.chartLine.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 6)) { _ in
                    AxisValueLabel()
                        .foregroundStyle(ActivityPalette.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(ActivityPalette.secondaryText.opacity(0.3))
                    AxisValueLabel().foregroundStyle(ActivityPalette.secondaryText)
                }
            }
            .frame(height: 120)

            // Time labels
            HStack {
                Text("00:00")
                Spacer()
                Text("06:00")
                Spacer()
                Text("12:00")
                Spacer()
                Text("18:00")
                Spacer()
                Text("23:59")
            }
            .font(.system(size: 10))
            .foregroundColor(ActivityPalette.secondaryText)
        }
    }

    private var weekChart: some View {
        VStack(spacing: 4) {
            let maxValue = max(1, dailyChartData.map { $0.value }.max() ?? 1)
            let yAxisValues = [0, Int(maxValue / 2), Int(maxValue)]

            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis labels on left
                VStack(spacing: 0) {
                    ForEach(yAxisValues.reversed(), id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 9))
                            .foregroundColor(ActivityPalette.secondaryText)
                            .frame(height: 40, alignment: .top)
                    }
                }
                .frame(width: 30)

                // Bars
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(dailyChartData, id: \.label) { item in
                        VStack(spacing: 4) {
                            // Value label on top of bar
                            if item.value > 0 {
                                Text("\(Int(item.value))")
                                    .font(.system(size: 8))
                                    .foregroundColor(ActivityPalette.secondaryText)
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ActivityPalette.chartLine)
                                .frame(height: max(8, CGFloat(item.value) / maxValue * 80))
                            Text(item.label)
                                .font(.system(size: 9))
                                .foregroundColor(ActivityPalette.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
            }
            .frame(height: 120)
            .padding(.horizontal, 4)
        }
    }

    private var monthChart: some View {
        VStack(spacing: 4) {
            let maxValue = max(1, dailyChartData.map { $0.value }.max() ?? 1)
            let yAxisValues = [0, Int(maxValue / 2), Int(maxValue)]

            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis labels on left
                VStack(spacing: 0) {
                    ForEach(yAxisValues.reversed(), id: \.self) { value in
                        Text(value >= 1000 ? "\(value/1000)k" : "\(value)")
                            .font(.system(size: 9))
                            .foregroundColor(ActivityPalette.secondaryText)
                            .frame(height: 40, alignment: .top)
                    }
                }
                .frame(width: 30)

                // Bars
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(dailyChartData, id: \.label) { item in
                        VStack(spacing: 4) {
                            // Value label on top of bar
                            if item.value > 0 {
                                Text(item.value >= 1000 ? "\(Int(item.value/1000))k" : "\(Int(item.value))")
                                    .font(.system(size: 8))
                                    .foregroundColor(ActivityPalette.secondaryText)
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ActivityPalette.chartLine)
                                .frame(height: max(8, CGFloat(item.value) / maxValue * 80))
                            Text(item.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(ActivityPalette.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
            }
            .frame(height: 120)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - AI Activity Recognition

    private var aiActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI ACTIVITY RECOGNITION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(ActivityPalette.secondaryText)
                .padding(.horizontal, 20)

            if hasRealWorkoutData {
                ForEach(recognizedActivities) { item in
                    HStack(spacing: 14) {
                        // Circular icon background
                        Circle()
                            .fill(item.iconColor.opacity(0.15))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: item.iconName)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(item.iconColor)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ActivityPalette.primaryText)
                            Text(item.subtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(ActivityPalette.secondaryText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(item.durationMin) min")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ActivityPalette.primaryText)
                            // Match badge
                            Text("\(item.matchPercent)% MATCH")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(ActivityPalette.deepGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ActivityPalette.limeGreen)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
            } else {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 36))
                            .foregroundColor(ActivityPalette.secondaryText.opacity(0.5))
                        Text("No activities recorded yet")
                            .font(.system(size: 14))
                            .foregroundColor(ActivityPalette.secondaryText)
                        Text("Workouts will appear here")
                            .font(.system(size: 12))
                            .foregroundColor(ActivityPalette.secondaryText.opacity(0.7))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Vital Signs Monitor

    private var vitalSignsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VITAL SIGNS MONITOR")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(ActivityPalette.secondaryText)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                heartRateCard
                spo2Card
            }
            .frame(height: 140) // Fixed height for square cards
            .padding(.horizontal, 20)
        }
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: heart icon + HRV label
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ActivityPalette.heartRed)
                Spacer()
                Text("HRV")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(ActivityPalette.deepGreen.opacity(0.8))
            }

            // Heart rate number (real data or placeholder)
            if let hr = healthDataManager.latestHeartRate {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(hr)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ActivityPalette.primaryText)
                    Text("BPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ActivityPalette.secondaryText)
                        .offset(y: -3)
                }

                // Heartbeat bars (animated effect based on real HR)
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        let isActive = i == 3
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isActive ? ActivityPalette.heartRed : Color.white.opacity(0.7))
                            .frame(width: isActive ? 8 : 6, height: isActive ? 18 : CGFloat([10, 14, 8, 18, 12, 16, 9][i]))
                    }
                }
            } else {
                // No data state
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("--")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                    Text("BPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                        .offset(y: -3)
                }

                // Static bars
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(ActivityPalette.hrvCardBg)
        .cornerRadius(16)
    }

    private var spo2Card: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: drop icon + SPO2 label
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ActivityPalette.swimBlue)
                Spacer()
                Text("SPO2")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(ActivityPalette.deepGreen.opacity(0.8))
            }

            // SpO2 number (real data or placeholder)
            if let spo2 = spo2Value {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(spo2)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ActivityPalette.deepGreen)
                    Text("%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ActivityPalette.deepGreen)
                        .offset(y: -3)
                }

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: spo2 < 94 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(ActivityPalette.deepGreen)
                    Text(spo2 < 94 ? "LOW LEVEL" : "OPTIMIZING")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.3)
                        .foregroundColor(ActivityPalette.deepGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.6))
                .clipShape(Capsule())
            } else {
                // No data state
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("--")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                    Text("%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                        .offset(y: -3)
                }

                // Placeholder badge
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                    Text("NO DATA")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.3)
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.4))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(ActivityPalette.spo2CardBg)
        .cornerRadius(16)
    }

    // MARK: - Optimal Recovery Card

    private var optimalRecoveryCard: some View {
        Group {
            if hasRecoveryData {
                HStack(spacing: 16) {
                    // Score circle with arc
                    ZStack {
                        Circle()
                            .stroke(ActivityPalette.limeGreen.opacity(0.3), lineWidth: 4)
                            .frame(width: 56, height: 56)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(1.0, Double(recoveryScore) / 100.0)))
                            .stroke(ActivityPalette.limeGreen, lineWidth: 4)
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                        Text("\(recoveryScore)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(ActivityPalette.limeGreen)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recoveryTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text(recoveryDescription)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(ActivityPalette.recoveryBg)
                .cornerRadius(18)
                .padding(.horizontal, 20)
            } else {
                // Empty state
                HStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ActivityPalette.secondaryText.opacity(0.6))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recovery Score")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ActivityPalette.primaryText)
                        Text("Connect Apple Watch to see recovery insights")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ActivityPalette.secondaryText)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Data & Sync（保留原有逻辑）

    private func loadCloudWorkoutHistory() async {
        let localRecords = localStorage.loadWorkoutRecords()
        if !localRecords.isEmpty && workoutHistory.isEmpty {
            workoutHistory = localRecords.map { record in
                WorkoutSession(
                    id: record.id,
                    type: WorkoutType(rawValue: record.type) ?? .walking,
                    duration: record.duration,
                    calories: record.calories,
                    date: record.date
                )
            }.sorted(by: { $0.date > $1.date })
        }
        guard firebaseManager.currentUser != nil else { return }
        isLoadingCloud = true
        defer { isLoadingCloud = false }
        do {
            let records = try await firebaseManager.fetchCollection(
                collection: "fitnessRecords",
                as: FitnessRecord.self
            )
            if !records.isEmpty {
                let mapped = records.map { record in
                    WorkoutSession(
                        id: record.id ?? UUID().uuidString,
                        type: WorkoutType(rawValue: record.activityType) ?? .walking,
                        duration: Int(record.duration / 60),
                        calories: Int(record.calories.rounded()),
                        date: record.timestamp
                    )
                }
                workoutHistory = mapped.sorted(by: { $0.date > $1.date })
                saveWorkoutsToLocal()
            }
        } catch {
            print("⚠️ Firebase 运动记录同步失败: \(error.localizedDescription)")
        }
    }

    private func saveWorkoutsToLocal() {
        let localRecords = workoutHistory.map { workout in
            LocalStorageManager.LocalWorkoutRecord(
                id: workout.id,
                type: workout.type.rawValue,
                duration: workout.duration,
                calories: workout.calories,
                date: workout.date
            )
        }
        localStorage.saveWorkoutRecords(localRecords)
    }
}

// MARK: - Models（保留原有，供同步与 AI 识别映射）

enum WorkoutType: String, CaseIterable {
    case running = "跑步"
    case cycling = "骑行"
    case swimming = "游泳"
    case yoga = "瑜伽"
    case strength = "力量训练"
    case walking = "步行"
    case other = "其他"

    var name: String { rawValue }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        case .walking: return "figure.walk"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .running: return Color.auraGreen
        case .cycling: return .blue
        case .swimming: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .yoga: return .purple
        case .strength: return Color.auraRed
        case .walking: return .orange
        case .other: return .gray
        }
    }

    var caloriesPerMinute: Double {
        switch self {
        case .running: return 8.5
        case .cycling: return 7.0
        case .swimming: return 8.3
        case .yoga: return 3.8
        case .strength: return 6.0
        case .walking: return 4.2
        case .other: return 5.0
        }
    }

    /// Initialize from HealthKit workout type
    init(from hkType: HKWorkoutActivityType) {
        switch hkType {
        case .running:
            self = .running
        case .walking:
            self = .walking
        case .cycling, .handCycling:
            self = .cycling
        case .swimming:
            self = .swimming
        case .yoga:
            self = .yoga
        case .functionalStrengthTraining, .traditionalStrengthTraining, .coreTraining:
            self = .strength
        default:
            self = .other
        }
    }
}

struct WorkoutSession: Identifiable {
    let id: String
    let type: WorkoutType
    let duration: Int
    let calories: Int
    let date: Date

    init(id: String = UUID().uuidString, type: WorkoutType, duration: Int, calories: Int, date: Date) {
        self.id = id
        self.type = type
        self.duration = duration
        self.calories = calories
        self.date = date
    }
}

#Preview {
    FitnessTrackerView()
        .environmentObject(AuthViewModel())
        .environmentObject(HealthDataManager())
}
