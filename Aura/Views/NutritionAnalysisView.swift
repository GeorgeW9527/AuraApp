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
            .fullScreenCover(isPresented: $showingCamera) {
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
        NavigationStack {
            ZStack {
                foodRecordBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let image = viewModel.selectedImage {
                            FoodCaptureHeroCard(image: image)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }

                        if viewModel.isAnalyzing {
                            AIAnalyzingView()
                                .padding(.horizontal)
                                .transition(.identity)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(NutritionPalette.warningOrange)
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
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        if let result = viewModel.analysisResult {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(NutritionPalette.deepGreen)
                                Text("Analysis complete. Review the nutrition details below.")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(NutritionPalette.primaryText)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal)

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
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [NutritionPalette.deepGreen, Color(red: 0.27, green: 0.73, blue: 0.54)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: NutritionPalette.deepGreen.opacity(0.28), radius: 14, x: 0, y: 8)
                            }
                            .padding(.horizontal)
                        } else if !viewModel.isAnalyzing && viewModel.errorMessage == nil {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(NutritionPalette.deepGreen)
                                Text("Photo received. Aura is preparing your nutrition breakdown...")
                                    .font(.subheadline)
                                    .foregroundColor(NutritionPalette.secondaryText)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 28)
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if viewModel.selectedImage != nil && viewModel.analysisResult == nil && !viewModel.isAnalyzing {
                    viewModel.analyzeImage()
                }
            }
        }
    }

    private var foodRecordBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.99),
                    Color(red: 0.94, green: 0.98, blue: 0.95),
                    Color(red: 0.99, green: 0.96, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.46, green: 0.70, blue: 1.0).opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 12)
                .offset(x: 120, y: -250)

            Circle()
                .fill(Color(red: 0.72, green: 0.38, blue: 1.0).opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 10)
                .offset(x: -130, y: -120)

            Circle()
                .fill(Color(red: 0.34, green: 0.82, blue: 0.66).opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 10)
                .offset(x: -120, y: 260)
        }
    }
}

struct AIAnalyzingView: View {
    @State private var ringRotation: Double = -90
    @State private var brainScale: CGFloat = 0.94
    @State private var hasStartedAnimations = false
    @State private var stageIndex = 0
    @State private var cycleTask: Task<Void, Never>?

    private let stages = [
        "Uploading image",
        "Identifying food items",
        "Estimating calories & nutrients",
        "Generating health insights"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("AI Nutrition Analysis", systemImage: "sparkles")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(NutritionPalette.primaryText)

                    Text("Aura is inspecting the photo and estimating calories, macros, and meal quality.")
                        .font(.subheadline)
                        .foregroundColor(NutritionPalette.secondaryText)
                }

                Spacer()

                Text("Live")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(red: 0.29, green: 0.57, blue: 1.0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.10), in: Capsule())
            }

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.16),
                                    Color.purple.opacity(0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 58
                            )
                        )
                        .frame(width: 112, height: 112)

                    Circle()
                        .stroke(Color.blue.opacity(0.12), lineWidth: 10)
                        .frame(width: 94, height: 94)

                    Circle()
                        .trim(from: 0.12, to: 0.88)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.53, blue: 1.0),
                                    Color(red: 0.69, green: 0.35, blue: 0.98),
                                    Color(red: 1.0, green: 0.41, blue: 0.70),
                                    Color(red: 0.22, green: 0.53, blue: 1.0)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .frame(width: 94, height: 94)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .fill(Color.white.opacity(0.84))
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.blue.opacity(0.12), radius: 12, x: 0, y: 6)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 0.24, green: 0.52, blue: 0.98))
                        .scaleEffect(brainScale)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(stages[stageIndex])
                        .font(.title3.weight(.semibold))
                        .foregroundColor(NutritionPalette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        AnalysisCapabilityRow(icon: "camera.macro", title: "Food Recognition")
                        AnalysisCapabilityRow(icon: "flame.fill", title: "Calorie Estimate")
                        AnalysisCapabilityRow(icon: "chart.bar.xaxis", title: "Macro Breakdown")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index <= stageIndex ? Color(red: 0.24, green: 0.52, blue: 0.98) : Color.gray.opacity(0.18))
                        .frame(width: index == stageIndex ? 30 : 16, height: 7)
                }
            }

            Text("This usually takes just a moment.")
                .font(.footnote)
                .foregroundColor(NutritionPalette.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
        .onAppear {
            startVisualAnimationsIfNeeded()
            startStageCycle()
        }
        .onDisappear {
            hasStartedAnimations = false
            ringRotation = -90
            brainScale = 0.94
            cycleTask?.cancel()
            cycleTask = nil
        }
    }

    private func startVisualAnimationsIfNeeded() {
        guard !hasStartedAnimations else { return }
        hasStartedAnimations = true

        // Use explicit numeric values to keep the ring stable at startup
        // and avoid initial jitter from boolean-driven state transitions.
        withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
            ringRotation = 270
        }
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            brainScale = 1.06
        }
    }

    private func startStageCycle() {
        cycleTask?.cancel()
        cycleTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_350_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    stageIndex = (stageIndex + 1) % stages.count
                }
            }
        }
    }
}

private struct FoodCaptureHeroCard: View {
    let image: UIImage

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                FoodRecordStatusChip(
                    icon: "camera.viewfinder",
                    title: "Photo Captured",
                    tint: Color(red: 0.31, green: 0.73, blue: 0.51)
                )

                Spacer()

                Text(Date(), style: .time)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(NutritionPalette.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.88), in: Capsule())
            }

            ZStack(alignment: .bottomLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                LinearGradient(
                    colors: [.clear, .black.opacity(0.48)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready for smart meal scan")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Text("A clearer photo helps Aura return better calorie and macro estimates.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(20)
            }

            HStack(spacing: 10) {
                FoodRecordStatusChip(
                    icon: "sparkles",
                    title: "AI Vision",
                    tint: Color(red: 0.50, green: 0.39, blue: 0.98)
                )
                FoodRecordStatusChip(
                    icon: "scalemass.fill",
                    title: "Portion Estimate",
                    tint: Color(red: 0.25, green: 0.62, blue: 0.94)
                )
                FoodRecordStatusChip(
                    icon: "bolt.heart.fill",
                    title: "Nutrition Insights",
                    tint: Color(red: 0.98, green: 0.58, blue: 0.34)
                )
            }
        }
        .padding(18)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
    }
}

private struct FoodRecordStatusChip: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.78)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
    }
}

private struct AnalysisCapabilityRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.24, green: 0.52, blue: 0.98))
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(NutritionPalette.primaryText)
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
