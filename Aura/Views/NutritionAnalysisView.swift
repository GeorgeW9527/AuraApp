//
//  NutritionAnalysisView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import PhotosUI

struct NutritionAnalysisView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NutritionViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceSelection = false
    @State private var showingFoodRecord = false
    @State private var showingDietReport = false
    @State private var selectedDate = Date()

    private static let dailyCalGoal = 2200
    private static let dailyProteinGoal = 150.0
    private static let dailyCarbsGoal = 220.0
    private static let dailyFatGoal = 75.0

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        foodLogSection
                    }
                    .padding(.bottom, 100)
                }
                .refreshable { await viewModel.syncHistoryFromCloud() }
                .background(Color.white)

            // 右下角浮动相机按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingSourceSelection = true }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.auraGreen)
                            .clipShape(Circle())
                            .shadow(color: Color.auraGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .confirmationDialog("记录美食", isPresented: $showingSourceSelection) {
                        Button("拍照") { showingCamera = true }
                        Button("从相册选择") { showingImagePicker = true }
                        Button("取消", role: .cancel) {}
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $viewModel.selectedImage, onImageCaptured: { showingFoodRecord = true })
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, onImageSelected: { showingFoodRecord = true })
            }
            .fullScreenCover(isPresented: $showingFoodRecord) {
                if viewModel.selectedImage != nil {
                    FoodRecordView(viewModel: viewModel, isPresented: $showingFoodRecord)
                }
            }
            .task {
                viewModel.ensureLocalDataLoaded()
                await viewModel.syncHistoryFromCloud()
            }
            .sheet(isPresented: $showingDietReport) {
                DietStructureReportView(history: viewModel.history)
            }
            }
        }
    }

    // MARK: - 顶部 Header（截图样式）
    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                ProfileHeaderAvatarView(size: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("Life Audit Log")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGreen)
                Text("Health & Nutrition")
                    .font(.caption)
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

    // MARK: - Food Log 主区域
    private var foodLogSection: some View {
        let records = viewModel.recordsForDate(selectedDate)
        return VStack(alignment: .leading, spacing: 16) {
            // 标题：Food Log
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundColor(Color.auraGreen)
                Text("Food Log")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
            }
            .padding(.horizontal, 20)

            // 日期行：October 2023 + 日历图标（长按打开饮食结构图）
            HStack {
                Text(monthYearString)
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Button {
                    showingDietReport = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(Color.auraGreen)
                }
            }
            .padding(.horizontal, 20)

            // 横向日期丸 (MON 12, TUE 13...)
            FoodLogDayPills(selectedDate: $selectedDate, recordDates: viewModel.recordDateSet)
                .padding(.horizontal, 20)

            // Daily Goal Progress 卡片
            DailyGoalProgressCard(
                records: records,
                calGoal: Self.dailyCalGoal,
                proteinGoal: Self.dailyProteinGoal,
                carbsGoal: Self.dailyCarbsGoal,
                fatGoal: Self.dailyFatGoal
            )
            .padding(.horizontal, 20)

            // Logged Today 分隔
            HStack {
                Rectangle().fill(Color.auraGrayLight.opacity(0.4)).frame(height: 1)
                Text("Logged Today")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Rectangle().fill(Color.auraGrayLight.opacity(0.4)).frame(height: 1)
            }
            .padding(.horizontal, 40)

            // 食物记录卡片列表
            if records.isEmpty {
                EmptyDayView(date: selectedDate)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(records) { item in
                        NavigationLink(destination: EditMealView(item: item, viewModel: viewModel)) {
                            FoodLogEntryCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: selectedDate)
    }
}

// MARK: - 横向日期丸 (MON 12, TUE 13...)

struct FoodLogDayPills: View {
    @Binding var selectedDate: Date
    let recordDates: Set<String>
    private let calendar = Calendar.current

    private var dayItems: [(Date, String)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        formatter.locale = Locale(identifier: "en_US")
        var result: [(Date, String)] = []
        let start = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let end = calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        var current = start
        while current <= end {
            result.append((current, formatter.string(from: current).uppercased()))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return result
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dayItems, id: \.0) { date, label in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 4) {
                            Text(label.split(separator: " ").first.map(String.init) ?? "")
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                            Text(label.split(separator: " ").dropFirst().joined())
                                .font(.caption2)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .foregroundColor(isSelected ? Color.auraGreen : Color.auraGrayLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.auraGreenLight : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.auraGreen : Color.clear, lineWidth: 1.5)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
}

// MARK: - Daily Goal Progress 卡片（截图样式）

struct DailyGoalProgressCard: View {
    let records: [NutritionHistoryItem]
    let calGoal: Int
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double

    private var totalCal: Int { records.reduce(0) { $0 + $1.result.calories } }
    private var totalProtein: Double { records.reduce(0) { $0 + $1.result.protein } }
    private var totalCarbs: Double { records.reduce(0) { $0 + $1.result.carbs } }
    private var totalFat: Double { records.reduce(0) { $0 + $1.result.fat } }
    private var isOnTrack: Bool { totalCal <= calGoal }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DAILY GOAL PROGRESS")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)

            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(totalCal.formatted())")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.auraGreen)
                    Text("/ \(calGoal.formatted()) kcal")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayLight)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                    Text("ON TRACK")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.auraGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.auraGreenLight)
                .cornerRadius(20)
            }

            VStack(alignment: .leading, spacing: 8) {
                MacroProgressRow(label: "PROTEIN", current: totalProtein, goal: proteinGoal, color: Color.auraYellow)
                MacroProgressRow(label: "CARBS", current: totalCarbs, goal: carbsGoal, color: Color.auraPurple)
                MacroProgressRow(label: "FATS", current: totalFat, goal: fatGoal, color: Color.auraGreen)
            }
        }
        .padding(16)
        .background(Color.auraGreenLight)
        .cornerRadius(14)
    }
}

struct MacroProgressRow: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color
    private var progress: Double { goal > 0 ? min(1, current / goal) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.auraGrayLight)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.9))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 6)
            Text("\(Int(current))g / \(Int(goal))g")
                .font(.caption2)
                .foregroundColor(Color.auraGrayLight)
        }
    }
}

// MARK: - 食物记录卡片（截图样式：圆形图+kcal+标签）

struct FoodLogEntryCard: View {
    let item: NutritionHistoryItem

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: item.date)
    }

    private var foodTag: String {
        if item.result.protein > 20 && item.result.carbs < 15 { return "Protein Rich" }
        if item.result.carbs > item.result.protein && item.result.carbs > item.result.fat { return "Carbs" }
        return "Whole Food"
    }

    private var showWarning: Bool { item.result.calories > 500 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 圆形图片 + 右下角图标
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = item.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color(UIColor.secondarySystemBackground)
                            }
                        }
                    } else {
                        Color(UIColor.secondarySystemBackground)
                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())

                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                } else {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.auraGreen)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.result.foodName)
                    .font(.headline)
                    .foregroundColor(Color.auraGrayDark)
                HStack(spacing: 4) {
                    Text("\(item.result.calories) kcal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGreen)
                    Text("•")
                        .foregroundColor(Color.auraGrayLight)
                    Text(foodTag)
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                }
                HStack(spacing: 6) {
                    Text("P: \(Int(item.result.protein))g")
                        .font(.caption2)
                        .foregroundColor(Color.auraGrayLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(white: 0.95))
                        .cornerRadius(4)
                    Text("C: \(Int(item.result.carbs))g")
                        .font(.caption2)
                        .foregroundColor(Color.auraGrayLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(white: 0.95))
                        .cornerRadius(4)
                    Text("F: \(Int(item.result.fat))g")
                        .font(.caption2)
                        .foregroundColor(Color.auraGrayLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(white: 0.95))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(timeString)
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 日历区域（保留供智能报告等使用）

struct CalendarSectionView: View {
    @Binding var selectedDate: Date
    let recordDates: Set<String>
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        return f
    }()
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份导航
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(Color.auraGreen)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(Color.auraGreen)
                }
            }
            .padding(.horizontal, 8)
            
            // 星期标题
            let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let hasRecord = recordDates.contains(dayFormatter.string(from: date))
                        
                        Button(action: { selectedDate = date }) {
                            VStack(spacing: 3) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(
                                        isSelected ? .white :
                                        isToday ? Color.auraGreen :
                                        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .primary : .gray.opacity(0.4)
                                    )
                                
                                // 有记录的日期显示小圆点
                                Circle()
                                    .fill(isSelected ? Color.white : Color.auraGreen)
                                    .frame(width: 5, height: 5)
                                    .opacity(hasRecord ? 1 : 0)
                            }
                            .frame(width: 36, height: 40)
                            .background {
                                if isSelected {
                                    Circle().fill(Color.auraGreen)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("")
                            .frame(width: 36, height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func changeMonth(_ delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentMonth = newDate
            }
        }
    }
    
    private func generateDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var days: [Date?] = []
        
        // 填充月初空白
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // 填充当月日期
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - 每日摘要卡片

struct DailySummaryCard: View {
    let records: [NutritionHistoryItem]
    let date: Date
    
    private var totalCalories: Int {
        records.reduce(0) { $0 + $1.result.calories }
    }
    
    private var totalProtein: Double {
        records.reduce(0) { $0 + $1.result.protein }
    }
    
    private var totalCarbs: Double {
        records.reduce(0) { $0 + $1.result.carbs }
    }
    
    private var totalFat: Double {
        records.reduce(0) { $0 + $1.result.fat }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(records.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.auraGreen.opacity(0.15))
                    .cornerRadius(10)
            }
            
            if !records.isEmpty {
                HStack(spacing: 0) {
                    // 总卡路里
                    VStack(spacing: 4) {
                        Text("\(totalCalories)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.orange)
                        Text("千卡")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 蛋白质
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", totalProtein))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                        Text("蛋白质(g)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 碳水
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", totalCarbs))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                        Text("碳水(g)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 脂肪
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", totalFat))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("脂肪(g)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - 空日期视图

struct EmptyDayView: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(Calendar.current.isDateInToday(date) ? "今天还没有记录" : "当天没有记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if Calendar.current.isDateInToday(date) {
                Text("点击右下角的相机按钮开始记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 美食记录页面（拍照后的分析页面）

struct FoodRecordView: View {
    @ObservedObject var viewModel: NutritionViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.16),
                        Color.purple.opacity(0.14),
                        Color.orange.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        if let image = viewModel.selectedImage {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("本次拍摄", systemImage: "camera.viewfinder")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(Date(), style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        LinearGradient(
                                            colors: [.clear, .black.opacity(0.22)],
                                            startPoint: .center,
                                            endPoint: .bottom
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    )
                            }
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 10)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        if viewModel.isAnalyzing {
                            AIAnalyzingView()
                                .padding(.horizontal)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                Text("分析失败")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("重试分析") {
                                    viewModel.analyzeImage()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal)
                        }

                        if let result = viewModel.analysisResult {
                            NutritionResultCard(result: result)
                                .padding(.horizontal)

                            Button(action: {
                                viewModel.saveToHistory()
                                isPresented = false
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("保存到我的饮食记录")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 6)
                            }
                            .padding(.horizontal)
                        } else if !viewModel.isAnalyzing && viewModel.errorMessage == nil {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                Text("已上传图片，AI 即将返回营养分析结果")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("美食记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.selectedImage = nil
                        viewModel.analysisResult = nil
                        viewModel.errorMessage = nil
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if viewModel.selectedImage != nil && viewModel.analysisResult == nil && !viewModel.isAnalyzing {
                    viewModel.analyzeImage()
                }
            }
        }
    }
}

struct AIAnalyzingView: View {
    @State private var spin = false
    @State private var breathe = false
    @State private var stageIndex = 0

    private let stages = [
        "上传图片到云端",
        "识别食物种类",
        "估算卡路里与营养素",
        "生成健康建议"
    ]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 10)
                    .frame(width: 88, height: 88)

                Circle()
                    .trim(from: 0.15, to: 0.9)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .blue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spin)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
                    .scaleEffect(breathe ? 1.05 : 0.92)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: breathe)
            }

            VStack(spacing: 6) {
                Text("AI 营养引擎分析中")
                    .font(.headline)
                Text(stages[stageIndex])
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index <= stageIndex ? Color.blue : Color.gray.opacity(0.25))
                        .frame(width: index == stageIndex ? 28 : 16, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: stageIndex)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            spin = true
            breathe = true

            Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { timer in
                stageIndex += 1
                if stageIndex >= stages.count {
                    stageIndex = 0
                }
                if !spin {
                    timer.invalidate()
                }
            }
        }
        .onDisappear {
            spin = false
            breathe = false
        }
    }
}

// MARK: - 记录详情页（支持编辑食物名称与热量）

struct RecordDetailView: View {
    let item: NutritionHistoryItem
    @ObservedObject var viewModel: NutritionViewModel
    @State private var showingEdit = false

    private var currentItem: NutritionHistoryItem {
        viewModel.history.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 图片
                if let image = currentItem.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .padding(.horizontal)
                } else if let imageURL = currentItem.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .padding(.horizontal)
                } else {
                    placeholderImage
                        .padding(.horizontal)
                }
                
                // 摄入时间
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(currentItem.date, style: .date)
                        .foregroundColor(.secondary)
                    Text(currentItem.date, style: .time)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .font(.subheadline)
                .padding(.horizontal)
                
                // 营养结果卡片
                NutritionResultCard(result: currentItem.result)
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle(currentItem.result.foodName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") {
                    showingEdit = true
                }
                .foregroundColor(Color.auraGreen)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditFoodRecordSheet(
                item: currentItem,
                viewModel: viewModel,
                isPresented: $showingEdit
            )
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.secondarySystemBackground))
            .frame(height: 220)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - 编辑食物名称与热量

struct EditFoodRecordSheet: View {
    let item: NutritionHistoryItem
    @ObservedObject var viewModel: NutritionViewModel
    @Binding var isPresented: Bool
    @State private var foodName: String = ""
    @State private var caloriesText: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("食物名称") {
                    TextField("名称", text: $foodName)
                }
                Section("热量 (kcal)") {
                    TextField("热量", text: $caloriesText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveAndDismiss()
                    }
                    .disabled(isSaving || foodName.isEmpty || Int(caloriesText) == nil)
                    .foregroundColor(Color.auraGreen)
                }
            }
            .onAppear {
                foodName = item.result.foodName
                caloriesText = "\(item.result.calories)"
            }
        }
    }

    private func saveAndDismiss() {
        guard let cal = Int(caloriesText), cal > 0 else { return }
        isSaving = true
        Task {
            await viewModel.updateHistoryItem(item, foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines), calories: cal, protein: item.result.protein, carbs: item.result.carbs, fat: item.result.fat)
            await MainActor.run {
                isSaving = false
                isPresented = false
            }
        }
    }
}

// MARK: - 周/月度饮食结构图（智能报告）

struct DietStructureReportView: View {
    let history: [NutritionHistoryItem]
    @State private var isWeekly = true
    @Environment(\.dismiss) private var dismiss

    private var calendar: Calendar { Calendar.current }
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private var rangeStart: Date {
        if isWeekly {
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        } else {
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }
    }

    private var filteredHistory: [NutritionHistoryItem] {
        history.filter { $0.date >= rangeStart && $0.date <= Date() }
    }

    private var totalProtein: Double { filteredHistory.reduce(0) { $0 + $1.result.protein } }
    private var totalCarbs: Double { filteredHistory.reduce(0) { $0 + $1.result.carbs } }
    private var totalFat: Double { filteredHistory.reduce(0) { $0 + $1.result.fat } }
    private var totalCal: Double { filteredHistory.reduce(0) { $0 + Double($1.result.calories) } }
    private var totalG: Double { totalProtein + totalCarbs + totalFat }
    private var proteinPct: Double { totalG > 0 ? totalProtein / totalG : 0 }
    private var carbsPct: Double { totalG > 0 ? totalCarbs / totalG : 0 }
    private var fatPct: Double { totalG > 0 ? totalFat / totalG : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("范围", selection: $isWeekly) {
                        Text("近一周").tag(true)
                        Text("近一月").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredHistory.isEmpty {
                        Text("该时段暂无饮食记录")
                            .foregroundColor(Color.auraGrayLight)
                            .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("宏量营养素占比")
                                .font(.headline)
                            HStack(spacing: 12) {
                                ReportBar(label: "蛋白质", value: proteinPct, color: .red)
                                ReportBar(label: "碳水", value: carbsPct, color: .blue)
                                ReportBar(label: "脂肪", value: fatPct, color: .orange)
                            }
                            Text("总摄入 \(Int(totalCal)) kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("饮食结构图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(Color.auraGreen)
                }
            }
        }
    }
}

struct ReportBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(value, 1)))
                }
            }
            .frame(height: 8)
            Text("\(label) \(Int(value * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 历史记录行

struct HistoryItemRow: View {
    let item: NutritionHistoryItem
    
    var body: some View {
        HStack(spacing: 14) {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)
                    .clipped()
            } else if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        Color(UIColor.secondarySystemBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    case .empty:
                        Color(UIColor.secondarySystemBackground)
                            .overlay(ProgressView())
                    @unknown default:
                        Color(UIColor.secondarySystemBackground)
                    }
                }
                .frame(width: 56, height: 56)
                .cornerRadius(12)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(item.result.foodName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text("\(item.result.calories) kcal")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("蛋白\(String(format: "%.0f", item.result.protein))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 营养结果卡片

struct NutritionResultCard: View {
    let result: NutritionResult
    
    var body: some View {
        VStack(spacing: 15) {
            // Food Name
            HStack {
                Text(result.foodName)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Calories
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("总卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(result.calories)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                        Text("kcal")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            
            Divider()
            
            // Macronutrients
            HStack(spacing: 20) {
                MacroNutrientView(name: "蛋白质", value: result.protein, color: .red)
                MacroNutrientView(name: "碳水", value: result.carbs, color: .blue)
                MacroNutrientView(name: "脂肪", value: result.fat, color: .yellow)
            }
            
            // Description
            if !result.description.isEmpty {
                Divider()
                
                Text(result.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}

struct MacroNutrientView: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NutritionAnalysisView()
}
