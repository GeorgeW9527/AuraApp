//
//  FitnessTrackerView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import Charts
import FirebaseAuth

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
    @State private var timeframe: ActivityTimeframe = .day
    @State private var workoutHistory: [WorkoutSession] = []
    @State private var isLoadingCloud = false

    private let firebaseManager = FirebaseManager.shared
    private let localStorage = LocalStorageManager.shared

    private var calendar: Calendar { Calendar.current }

    /// 当前时间段内的运动记录
    private var filteredWorkouts: [WorkoutSession] {
        let now = Date()
        switch timeframe {
        case .day:
            return workoutHistory.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            return workoutHistory.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .month:
            return workoutHistory.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        }
    }

    private var totalCalories: Int {
        filteredWorkouts.reduce(0) { $0 + $1.calories }
    }

    /// 用于图表的 24 小时热量分布（当日）
    private var hourlyData: [HourlyCaloriePoint] {
        let dayWorkouts = workoutHistory.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
        var values = Array(repeating: 0.0, count: 24)
        for w in dayWorkouts {
            let h = calendar.component(.hour, from: w.date)
            if h >= 0 && h < 24 { values[h] += Double(w.calories) }
        }
        if values.allSatisfy({ $0 == 0 }) {
            values = [0, 0, 0, 0, 0, 80, 120, 200, 280, 220, 180, 200, 250, 220, 180, 160, 200, 240, 180, 120, 80, 40, 20, 0]
        }
        return values.enumerated().map { HourlyCaloriePoint(hour: $0.offset, value: $0.element) }
    }

    /// AI 识别出的活动（由最近运动记录映射 + 占位）
    private var recognizedActivities: [RecognizedActivityItem] {
        let fromHistory = filteredWorkouts.prefix(2).map { w -> RecognizedActivityItem in
            let (name, subtitle, iconColor, iconName) = activityDisplay(for: w.type)
            let match = 80 + (w.duration % 20)
            return RecognizedActivityItem(
                name: name,
                subtitle: subtitle,
                durationMin: w.duration,
                matchPercent: match,
                iconColor: iconColor,
                iconName: iconName
            )
        }
        if fromHistory.count >= 2 { return Array(fromHistory) }
        if fromHistory.count == 1 {
            return fromHistory + [RecognizedActivityItem(
                name: "Swimming (Laps)",
                subtitle: "Stroke recognition",
                durationMin: 20,
                matchPercent: 82,
                iconColor: Color(red: 0.2, green: 0.5, blue: 0.9),
                iconName: "figure.pool.swim"
            )]
        }
        return [
            RecognizedActivityItem(name: "Outdoor Running", subtitle: "GPS & IMU tracked", durationMin: 45, matchPercent: 98, iconColor: Color.auraGreen, iconName: "figure.run"),
            RecognizedActivityItem(name: "Swimming (Laps)", subtitle: "Stroke recognition", durationMin: 20, matchPercent: 82, iconColor: Color(red: 0.2, green: 0.5, blue: 0.9), iconName: "figure.pool.swim")
        ]
    }

    private func activityDisplay(for type: WorkoutType) -> (String, String, Color, String) {
        switch type {
        case .running: return ("Outdoor Running", "GPS & IMU tracked", Color.auraGreen, "figure.run")
        case .swimming: return ("Swimming (Laps)", "Stroke recognition", Color(red: 0.2, green: 0.5, blue: 0.9), "figure.pool.swim")
        case .cycling: return ("Cycling", "GPS tracked", Color.blue, "bicycle")
        case .walking: return ("Walking", "Step count", Color.auraGreen, "figure.walk")
        default: return (type.name, "Tracked", type.color, type.icon)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    timeframeSelector
                    calorieConsumptionCard
                    aiActivitySection
                    vitalSignsSection
                    optimalRecoveryCard
                }
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .task { await loadCloudWorkoutHistory() }
        }
    }

    // MARK: - Header（与 Tab1/Tab2 一致）

    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                ProfileHeaderAvatarView(size: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("Activity Center")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGreen)
                Text("LIVE TRACKING")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .fill(Color(white: 0.92))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "applewatch").font(.title3).foregroundColor(Color.auraGrayDark))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Day / Week / Month

    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ActivityTimeframe.allCases, id: \.self) { option in
                Button {
                    timeframe = option
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(timeframe == option ? Color.auraGrayDark : Color.auraGrayLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(timeframe == option ? Color.white : Color(white: 0.94))
                        .cornerRadius(8)
                        .shadow(color: timeframe == option ? .black.opacity(0.06) : .clear, radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(white: 0.94))
        .cornerRadius(10)
        .padding(.horizontal, 20)
    }

    // MARK: - Calorie Consumption 卡片 + 折线图

    private var calorieConsumptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calorie Consumption")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                    Text("\(totalCalories.formatted()) kcal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.auraGrayDark)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Still Consumption")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                    Text("450 kcal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.auraGrayDark)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                    Text("12%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.auraGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(white: 0.92))
                .cornerRadius(6)
            }

            Chart(hourlyData) { point in
                LineMark(
                    x: .value("Time", point.timeLabel),
                    y: .value("kcal", point.value)
                )
                .foregroundStyle(Color.auraGreen)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Time", point.timeLabel),
                    y: .value("kcal", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.auraGreen.opacity(0.4), Color.auraGreen.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 6)) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.auraGrayLight)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(Color.auraGrayLight.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.auraGrayLight)
                }
            }
            .frame(height: 140)

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
            .font(.caption2)
            .foregroundColor(Color.auraGrayLight)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    // MARK: - AI Activity Recognition

    private var aiActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI ACTIVITY RECOGNITION")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            ForEach(recognizedActivities) { item in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.iconColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: item.iconName).font(.title2).foregroundColor(item.iconColor))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(Color.auraGrayDark)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundColor(Color.auraGrayLight)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(item.durationMin) min")
                            .font(.headline)
                            .foregroundColor(item.iconColor)
                        Text("\(item.matchPercent)% Match")
                            .font(.caption)
                            .foregroundColor(Color.auraGrayLight)
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Vital Signs Monitor

    private var vitalSignsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VITAL SIGNS MONITOR")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                heartRateCard
                spo2Card
            }
            .padding(.horizontal, 20)
        }
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(Color.auraRed)
                Spacer()
                Text("HEART RATE")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
            Text("72 bpm")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == 3 ? Color.auraRed : Color.auraRed.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var spo2Card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9))
                Spacer()
                Text("SPO2")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
            Text("94%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.orange)
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(Color.orange)
                Text("LOW LEVEL")
                    .font(.caption2)
                    .foregroundColor(Color.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Optimal Recovery

    private var optimalRecoveryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.auraGreen, lineWidth: 4)
                    .frame(width: 64, height: 64)
                Text("84")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGreen)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Optimal Recovery")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                Text("Your body is ready for high-intensity training today based on HRV data.")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(16)
        .background(Color.auraGreenLight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.auraGreen.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
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

    var name: String { rawValue }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        case .walking: return "figure.walk"
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
}
