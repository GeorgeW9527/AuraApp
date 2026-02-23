//
//  FitnessTrackerView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import Charts
import FirebaseAuth

struct FitnessTrackerView: View {
    @State private var selectedWorkout: WorkoutType = .running
    @State private var duration: Double = 30
    @State private var isTracking = false
    @State private var isLoadingCloud = false
    @State private var workoutHistory: [WorkoutSession] = [
        WorkoutSession(type: .running, duration: 45, calories: 380, date: Date().addingTimeInterval(-86400)),
        WorkoutSession(type: .cycling, duration: 60, calories: 420, date: Date().addingTimeInterval(-172800)),
        WorkoutSession(type: .swimming, duration: 30, calories: 250, date: Date().addingTimeInterval(-259200)),
        WorkoutSession(type: .yoga, duration: 40, calories: 150, date: Date().addingTimeInterval(-345600))
    ]
    private let firebaseManager = FirebaseManager.shared

    private var weeklyWorkouts: [WorkoutSession] {
        workoutHistory.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    private var weeklyWorkoutCount: Int {
        weeklyWorkouts.count
    }

    private var weeklyDuration: Int {
        weeklyWorkouts.reduce(0) { $0 + $1.duration }
    }

    private var weeklyCalories: Int {
        weeklyWorkouts.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats
                    HStack(spacing: 15) {
                        QuickStatCard(
                            title: "本周运动",
                            value: "\(weeklyWorkoutCount)",
                            unit: "次",
                            icon: "figure.run.circle.fill",
                            color: .green
                        )
                        
                        QuickStatCard(
                            title: "总时长",
                            value: "\(weeklyDuration)",
                            unit: "分钟",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        QuickStatCard(
                            title: "消耗",
                            value: "\(weeklyCalories)",
                            unit: "kcal",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Start Workout Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("开始运动")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 20) {
                            // Workout Type Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(WorkoutType.allCases, id: \.self) { type in
                                        WorkoutTypeButton(
                                            type: type,
                                            isSelected: selectedWorkout == type
                                        ) {
                                            selectedWorkout = type
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Duration Slider
                            VStack(alignment: .leading, spacing: 10) {
                                Text("时长: \(Int(duration)) 分钟")
                                    .font(.headline)
                                
                                Slider(value: $duration, in: 5...120, step: 5)
                                    .tint(.green)
                            }
                            .padding(.horizontal)
                            
                            // Start Button
                            Button(action: {
                                startWorkout()
                            }) {
                                HStack {
                                    Image(systemName: isTracking ? "stop.fill" : "play.fill")
                                    Text(isTracking ? "停止运动" : "开始运动")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTracking ? Color.red : Color.green)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Weekly Chart
                    VStack(alignment: .leading, spacing: 15) {
                        Text("本周统计")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack {
                            Chart {
                                ForEach(getWeeklyData()) { data in
                                    BarMark(
                                        x: .value("日期", data.day),
                                        y: .value("时长", data.duration)
                                    )
                                    .foregroundStyle(Color.green.gradient)
                                    .cornerRadius(4)
                                }
                            }
                            .frame(height: 200)
                            .padding()
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // History
                    VStack(alignment: .leading, spacing: 15) {
                        Text("运动历史")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(workoutHistory) { workout in
                            WorkoutHistoryRow(workout: workout)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("运动追踪")
            .task {
                await loadCloudWorkoutHistory()
            }
        }
    }
    
    func startWorkout() {
        isTracking.toggle()
        
        if !isTracking {
            // Save workout
            let newWorkout = WorkoutSession(
                type: selectedWorkout,
                duration: Int(duration),
                calories: Int(duration * selectedWorkout.caloriesPerMinute),
                date: Date()
            )
            workoutHistory.insert(newWorkout, at: 0)
            Task {
                await saveWorkoutToCloud(newWorkout)
            }
        }
    }
    
    func getWeeklyData() -> [WeeklyWorkoutData] {
        let days = ["日", "一", "二", "三", "四", "五", "六"]
        var durations = Array(repeating: 0, count: 7)

        for workout in weeklyWorkouts {
            let weekdayIndex = Calendar.current.component(.weekday, from: workout.date) - 1
            if weekdayIndex >= 0 && weekdayIndex < durations.count {
                durations[weekdayIndex] += workout.duration
            }
        }

        return zip(days, durations).map { day, duration in
            WeeklyWorkoutData(day: day, duration: duration)
        }
    }

    private func saveWorkoutToCloud(_ workout: WorkoutSession) async {
        guard firebaseManager.currentUser != nil else { return }

        let record = FitnessRecord(
            id: workout.id,
            activityType: workout.type.rawValue,
            duration: TimeInterval(workout.duration * 60),
            calories: Double(workout.calories),
            timestamp: workout.date,
            userId: firebaseManager.currentUser?.uid ?? ""
        )

        do {
            try await firebaseManager.saveData(
                collection: "fitnessRecords",
                documentId: workout.id,
                data: record
            )
            print("✅ 运动记录已同步到云端: \(workout.id)")
        } catch {
            print("❌ 运动记录同步失败: \(error.localizedDescription)")
        }
    }

    private func loadCloudWorkoutHistory() async {
        guard firebaseManager.currentUser != nil else { return }
        isLoadingCloud = true
        defer { isLoadingCloud = false }

        do {
            let records = try await firebaseManager.fetchCollection(
                collection: "fitnessRecords",
                as: FitnessRecord.self
            )
            let mapped = records.map { record in
                WorkoutSession(
                    id: record.id ?? UUID().uuidString,
                    type: WorkoutType(rawValue: record.activityType) ?? .walking,
                    duration: Int(record.duration / 60),
                    calories: Int(record.calories.rounded()),
                    date: record.timestamp
                )
            }
            self.workoutHistory = mapped.sorted(by: { $0.date > $1.date })
            print("✅ 已加载 \(mapped.count) 条运动记录")
        } catch {
            print("❌ 加载云端运动记录失败: \(error.localizedDescription)")
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WorkoutTypeButton: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.name)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.green : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: workout.type.icon)
                .font(.title2)
                .foregroundColor(workout.type.color)
                .frame(width: 50, height: 50)
                .background(workout.type.color.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.type.name)
                    .font(.headline)
                Text("\(workout.duration) 分钟 • \(workout.calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(workout.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Models
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
        case .running: return .green
        case .cycling: return .blue
        case .swimming: return .cyan
        case .yoga: return .purple
        case .strength: return .red
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

struct WeeklyWorkoutData: Identifiable {
    let id = UUID()
    let day: String
    let duration: Int
}

#Preview {
    FitnessTrackerView()
}
