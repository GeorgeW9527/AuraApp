//
//  NutritionAnalysisView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import PhotosUI

// MARK: - Tab2 Nutrition color scheme (match tab2.png exactly)
private enum NutritionPalette {
    // deep forest green — header text, icon, progress bar fill
    static let deepGreen       = Color(red: 0.11, green: 0.32, blue: 0.22)
    // calendarHighlight — lime-yellow capsule (same as tab1)
    static let calendarHighlight = Color(red: 0.84, green: 0.91, blue: 0.34)
    // card background — very light mint
    static let cardBg          = Color(red: 0.93, green: 0.97, blue: 0.92)
    // primary dark text
    static let primaryText     = Color(red: 0.12, green: 0.16, blue: 0.13)
    // secondary/grey text
    static let secondaryText   = Color(red: 0.60, green: 0.62, blue: 0.58)
    // ON TRACK badge background (deep green — same as deepGreen)
    static let onTrackBg       = Color(red: 0.11, green: 0.32, blue: 0.22)
    // Macro progress bars
    static let proteinBar      = Color(red: 0.11, green: 0.32, blue: 0.22)  // deep green
    static let carbsBar        = Color(red: 0.75, green: 0.88, blue: 0.30)  // lime-green
    static let fatBar          = Color(red: 0.48, green: 0.58, blue: 0.82)  // soft blue-purple
    // kcal accent (lime-green for normal, orange for warning)
    static let calorieGreen    = Color(red: 0.45, green: 0.70, blue: 0.22)
    static let warningOrange   = Color(red: 1.00, green: 0.55, blue: 0.20)
    // badge icon background (lime rounded square)
    static let badgeLime       = Color(red: 0.70, green: 0.86, blue: 0.28)
}

struct NutritionAnalysisView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NutritionViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceSelection = false
    @State private var showingFoodRecord = false
    @State private var showingDietReport = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

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
                .background(Color(red: 0.97, green: 0.98, blue: 0.96))

            // Floating camera button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingSourceSelection = true }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 58, height: 58)
                            .background(NutritionPalette.deepGreen)
                            .clipShape(Circle())
                            .shadow(color: NutritionPalette.deepGreen.opacity(0.45), radius: 10, x: 0, y: 5)
                    }
                    .confirmationDialog("Record Food", isPresented: $showingSourceSelection) {
                        Button("Take Photo") { showingCamera = true }
                        Button("Choose from Library") { showingImagePicker = true }
                        Button("Cancel", role: .cancel) {}
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 28)
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

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                Circle()
                    .fill(Color(red: 0.92, green: 0.94, blue: 0.90))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NutritionPalette.deepGreen)
                    }
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("LIFE AUDIT LOG")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(NutritionPalette.deepGreen)
                Text("HEALTH & NUTRITION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(NutritionPalette.secondaryText)
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
                            .foregroundColor(NutritionPalette.deepGreen)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Food Log 主区域
    private var foodLogSection: some View {
        let records = viewModel.recordsForDate(selectedDate)
        return VStack(alignment: .leading, spacing: 14) {

            // ── "Food Log" title row ─────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(NutritionPalette.deepGreen)
                Text("Food Log")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(NutritionPalette.primaryText)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // ── month + calendar icon ────────────────────────────────
            HStack {
                Text(monthYearString.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(NutritionPalette.secondaryText)
                Spacer()
                Button {
                    showingDietReport = true
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(NutritionPalette.cardBg)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(NutritionPalette.deepGreen)
                        )
                }
            }
            .padding(.horizontal, 20)

            // ── Day pills ────────────────────────────────────────────
            FoodLogDayPills(selectedDate: $selectedDate, recordDates: viewModel.recordDateSet)

            // ── Daily Goal Progress card ─────────────────────────────
            DailyGoalProgressCard(
                records: records,
                calGoal: Self.dailyCalGoal,
                proteinGoal: Self.dailyProteinGoal,
                carbsGoal: Self.dailyCarbsGoal,
                fatGoal: Self.dailyFatGoal
            )
            .padding(.horizontal, 20)

            // ── Logged Today divider ─────────────────────────────────
            HStack(spacing: 8) {
                Rectangle()
                    .fill(NutritionPalette.secondaryText.opacity(0.25))
                    .frame(height: 1)
                Text("Logged Today")
                    .font(.caption)
                    .foregroundColor(NutritionPalette.secondaryText)
                    .fixedSize()
                Rectangle()
                    .fill(NutritionPalette.secondaryText.opacity(0.25))
                    .frame(height: 1)
            }
            .padding(.horizontal, 36)

            // ── Food record cards ────────────────────────────────────
            if records.isEmpty {
                EmptyDayView(date: selectedDate)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
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

// MARK: - Day Pills

struct FoodLogDayPills: View {
    @Binding var selectedDate: Date
    let recordDates: Set<String>
    private let calendar = Calendar.current

    private var dayItems: [(Date, String)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        formatter.locale = Locale(identifier: "en_US")
        var result: [(Date, String)] = []
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -14, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 14, to: today) ?? today
        var current = start
        while current <= end {
            result.append((current, formatter.string(from: current).uppercased()))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(dayItems, id: \.0) { date, label in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let parts = label.split(separator: " ")
                        let dayName = parts.first.map(String.init) ?? ""
                        let dayNum  = parts.dropFirst().joined()
                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: 5) {
                                Text(dayName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(isSelected ? NutritionPalette.deepGreen : NutritionPalette.secondaryText)
                                Text(dayNum)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(isSelected ? NutritionPalette.primaryText : NutritionPalette.secondaryText)
                            }
                            .frame(width: 44, height: 60)
                            .background(
                                Capsule()
                                    .fill(isSelected ? NutritionPalette.calendarHighlight : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(calendar.startOfDay(for: date))
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                let todayStart = calendar.startOfDay(for: Date())
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(todayStart, anchor: .center)
                }
            }
            .onChange(of: selectedDate) { _, newValue in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
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

// MARK: - Daily Goal Progress Card

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
            // "DAILY GOAL PROGRESS" + ON TRACK badge
            HStack(alignment: .center) {
                Text("DAILY GOAL PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(NutritionPalette.secondaryText)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("ON TRACK")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(NutritionPalette.onTrackBg)
                .clipShape(Capsule())
            }

            // Big calorie number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(totalCal.formatted())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(NutritionPalette.deepGreen)
                Text("/ \(calGoal.formatted()) kcal")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(NutritionPalette.secondaryText)
            }

            // Macro rows (spacing +80% from original)
            VStack(alignment: .leading, spacing: 18) {
                MacroProgressRow(label: "PROTEIN", current: totalProtein, goal: proteinGoal,
                                 color: NutritionPalette.proteinBar)
                MacroProgressRow(label: "CARBS",   current: totalCarbs,   goal: carbsGoal,
                                 color: NutritionPalette.carbsBar)
                MacroProgressRow(label: "FATS",    current: totalFat,     goal: fatGoal,
                                 color: NutritionPalette.fatBar)
            }
        }
        .padding(16)
        .background(NutritionPalette.cardBg)
        .cornerRadius(16)
    }
}

struct MacroProgressRow: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color
    private var progress: Double { goal > 0 ? min(1, current / goal) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(NutritionPalette.secondaryText)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(Int(current))g")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(NutritionPalette.deepGreen)
                    Text("/ \(Int(goal))g")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NutritionPalette.secondaryText)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.88))
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, geo.size.width * CGFloat(progress)))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Food Log Entry Card
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
        if item.result.carbs > item.result.protein && item.result.carbs > item.result.fat { return "Veggie Rich" }
        return "Whole Food"
    }

    private var showWarning: Bool { item.result.calories > 500 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // ── Thumbnail + bottom-right badge ──────────────────────
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
                            default: Color(red: 0.93, green: 0.95, blue: 0.91)
                            }
                        }
                    } else {
                        Color(red: 0.93, green: 0.95, blue: 0.91)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundColor(NutritionPalette.deepGreen.opacity(0.4))
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Small icon badge (lime rounded-square)
                RoundedRectangle(cornerRadius: 7)
                    .fill(showWarning ? NutritionPalette.warningOrange : NutritionPalette.badgeLime)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: showWarning ? "exclamationmark.triangle.fill" : "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 5, y: 5)
            }
            .frame(width: 64, height: 64)

            // ── Text content ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 5) {
                Text(item.result.foodName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NutritionPalette.primaryText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(item.result.calories) kcal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(showWarning ? NutritionPalette.warningOrange : NutritionPalette.calorieGreen)
                    Text("•")
                        .foregroundColor(NutritionPalette.secondaryText)
                    Text(foodTag)
                        .font(.system(size: 12))
                        .foregroundColor(NutritionPalette.secondaryText)
                }

                HStack(spacing: 6) {
                    macroPill("P: \(Int(item.result.protein))g")
                    macroPill("C: \(Int(item.result.carbs))g")
                    macroPill("F: \(Int(item.result.fat))g")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ── Time ─────────────────────────────────────────────────
            Text(timeString)
                .font(.system(size: 11))
                .foregroundColor(NutritionPalette.secondaryText)
                .padding(.top, 2)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func macroPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(NutritionPalette.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.94, green: 0.96, blue: 0.93))
            .cornerRadius(6)
    }
}

// MARK: - Empty Day View

struct EmptyDayView: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(Calendar.current.isDateInToday(date) ? "No records yet today" : "No records for this day")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if Calendar.current.isDateInToday(date) {
                Text("Tap the camera button to start logging")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Food Record View (post-capture analysis)

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
                                    Label("Photo Captured", systemImage: "camera.viewfinder")
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
                                Text("Analysis Failed")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry Analysis") {
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
                                    Text("Save to My Diet Log")
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
                                Text("Image uploaded. AI nutrition analysis incoming...")
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
            .navigationTitle("Food Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
        "Uploading image",
        "Identifying food items",
        "Estimating calories & nutrients",
        "Generating health insights"
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
                Text("AI Nutrition Analysis")
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

// MARK: - Diet Structure Report

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
                    Picker("Range", selection: $isWeekly) {
                        Text("Past Week").tag(true)
                        Text("Past Month").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredHistory.isEmpty {
                        Text("No diet records for this period")
                            .foregroundColor(Color.auraGrayLight)
                            .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Macronutrient Breakdown")
                                .font(.headline)
                            HStack(spacing: 12) {
                                ReportBar(label: "Protein", value: proteinPct, color: .red)
                                ReportBar(label: "Carbs", value: carbsPct, color: .blue)
                                ReportBar(label: "Fat", value: fatPct, color: .orange)
                            }
                            Text("Total intake: \(Int(totalCal)) kcal")
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
            .navigationTitle("Diet Structure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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

// MARK: - Nutrition Result Card

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
                    Text("Total Calories")
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
                MacroNutrientView(name: "Protein", value: result.protein, color: .red)
                MacroNutrientView(name: "Carbs", value: result.carbs, color: .blue)
                MacroNutrientView(name: "Fat", value: result.fat, color: .yellow)
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
