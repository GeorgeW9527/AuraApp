//
//  NutritionAnalysisView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import PhotosUI

struct NutritionAnalysisView: View {
    @StateObject private var viewModel = NutritionViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceSelection = false
    @State private var showingFoodRecord = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - 日历视图
                        CalendarSectionView(
                            selectedDate: $selectedDate,
                            recordDates: viewModel.recordDateSet
                        )
                        
                        // MARK: - 当日摘要
                        DailySummaryCard(
                            records: viewModel.recordsForDate(selectedDate),
                            date: selectedDate
                        )
                        
                        // MARK: - 当日记录列表
                        let records = viewModel.recordsForDate(selectedDate)
                        if records.isEmpty {
                            EmptyDayView(date: selectedDate)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("饮食记录")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(records) { item in
                                    NavigationLink(destination: RecordDetailView(item: item)) {
                                        HistoryItemRow(item: item)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100) // 给底部浮动按钮留空间
                }
                .navigationTitle("营养分析")
                
                // MARK: - 右下角浮动相机按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingSourceSelection = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .confirmationDialog("记录美食", isPresented: $showingSourceSelection) {
                Button("拍照") {
                    showingFoodRecord = true
                    showingCamera = true
                }
                Button("从相册选择") {
                    showingFoodRecord = true
                    showingImagePicker = true
                }
                Button("取消", role: .cancel) {}
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $viewModel.selectedImage, onImageCaptured: {
                    showingFoodRecord = true
                })
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, onImageSelected: {
                    showingFoodRecord = true
                })
            }
            .fullScreenCover(isPresented: $showingFoodRecord) {
                if viewModel.selectedImage != nil {
                    FoodRecordView(viewModel: viewModel, isPresented: $showingFoodRecord)
                }
            }
        }
    }
}

// MARK: - 日历区域

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
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
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
                                        isToday ? .blue :
                                        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .primary : .gray.opacity(0.4)
                                    )
                                
                                // 有记录的日期显示小圆点
                                Circle()
                                    .fill(isSelected ? Color.white : Color.orange)
                                    .frame(width: 5, height: 5)
                                    .opacity(hasRecord ? 1 : 0)
                            }
                            .frame(width: 36, height: 40)
                            .background(
                                isSelected ?
                                Circle().fill(Color.blue) as AnyView :
                                Circle().fill(Color.clear) as AnyView
                            )
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
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
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
                    .background(Color.blue.opacity(0.1))
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
            ScrollView {
                VStack(spacing: 20) {
                    // 已选图片
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                    
                    // 分析中
                    if viewModel.isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("AI正在分析中...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                    }
                    
                    // 错误信息
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            
                            Text("分析失败")
                                .font(.headline)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("重试") {
                                viewModel.analyzeImage()
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                        .padding()
                    }
                    
                    // 分析结果
                    if let result = viewModel.analysisResult {
                        NutritionResultCard(result: result)
                            .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.saveToHistory()
                            // 关闭页面
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("保存记录")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
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

// MARK: - 记录详情页

struct RecordDetailView: View {
    let item: NutritionHistoryItem
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 图片
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                // 时间
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(item.date, style: .date)
                        .foregroundColor(.secondary)
                    Text(item.date, style: .time)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .font(.subheadline)
                .padding(.horizontal)
                
                // 营养结果卡片
                NutritionResultCard(result: item.result)
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle(item.result.foodName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 历史记录行

struct HistoryItemRow: View {
    let item: NutritionHistoryItem
    
    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .cornerRadius(12)
                .clipped()
            
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
                    Text("\(result.calories)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                    + Text(" kcal")
                        .font(.headline)
                        .foregroundColor(.secondary)
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
