//
//  DailyDashboardView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import FirebaseAuth

// MARK: - Theme
extension Color {
    // Core brand colors
    static let auraGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let auraGreenLight = Color(red: 0.92, green: 0.97, blue: 0.92)
    static let auraGrayLight = Color(red: 0.65, green: 0.65, blue: 0.65)
    static let auraGrayDark = Color(red: 0.20, green: 0.23, blue: 0.22)
    static let auraRed = Color(red: 0.94, green: 0.31, blue: 0.39)
    static let auraYellow = Color(red: 0.99, green: 0.85, blue: 0.21)
    static let auraPurple = Color(red: 0.58, green: 0.46, blue: 0.80)

    // Home tab specific accents (match design)
    static let auraBackground = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let auraLime = Color(red: 0.90, green: 0.96, blue: 0.63)          // Goal Insight banner
    static let auraSoftYellow = Color(red: 1.00, green: 0.96, blue: 0.80)    // Steps card
    static let auraDeepGreen = Color(red: 0.13, green: 0.39, blue: 0.29)     // Heart Rate card
    static let auraInsightIndigo = Color(red: 0.59, green: 0.69, blue: 0.99) // AI Health Insight
}

struct DailyDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var selectedDayIndex: Int = (Calendar.current.component(.weekday, from: Date()) + 5) % 7

    private var displayName: String { authViewModel.userProfile?.displayName ?? "Alex Rivera" }
    private let weekdaySymbols = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    private let localStorage = LocalStorageManager.shared

    private var userId: String {
        authViewModel.currentUser?.uid ?? authViewModel.userProfile?.userId ?? ""
    }

    private var weekDates: [Date] {
        let today = Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        let monday = Calendar.current.date(byAdding: .day, value: -mondayOffset, to: today) ?? today
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
    }

    private var selectedWeekDate: Date {
        weekDates.indices.contains(selectedDayIndex) ? weekDates[selectedDayIndex] : Date()
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: selectedWeekDate).uppercased()
    }

    private var weekdayDates: [Int] {
        weekDates.map { Calendar.current.component(.day, from: $0) }
    }

    private var todayNutritionRecords: [LocalStorageManager.LocalNutritionRecord] {
        guard !userId.isEmpty else { return [] }
        return localStorage.loadNutritionRecords(userId: userId).filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: Date())
        }
    }

    private var intake: Int {
        todayNutritionRecords.reduce(0) { $0 + $1.calories }
    }

    private var proteinIntake: Double {
        todayNutritionRecords.reduce(0) { $0 + $1.protein }
    }

    private var intakeGoal: Int {
        Int((authViewModel.userProfile?.dailyCalorieGoal ?? 1800).rounded())
    }

    private var burned: Int {
        healthDataManager.todayActiveEnergyBurned
    }

    private var burnedGoal: Int {
        max(intakeGoal, 1800)
    }

    private var kcalRemaining: Int {
        max(0, intakeGoal - intake)
    }

    private var steps: Int {
        healthDataManager.todayStepCount
    }

    private var stepsGoal: Int { 10_000 }

    private var heartRate: Int {
        healthDataManager.latestHeartRate
        ?? healthDataManager.restingHeartRate
        ?? authViewModel.userProfile?.restingHeartRate
        ?? 0
    }

    private var heartRateDisplayText: String {
        heartRate > 0 ? "\(heartRate)" : "--"
    }

    private var calorieRingProgress: Double {
        guard intakeGoal > 0 else { return 0 }
        return min(1, Double(intake) / Double(intakeGoal))
    }

    private var goalInsightText: String {
        let remainingSteps = max(0, stepsGoal - steps)
        if remainingSteps > 0 {
            return "Keep going, \(remainingSteps.formatted()) steps left to hit today's goal."
        }
        if kcalRemaining > 0 {
            return "Nice work. You still have \(kcalRemaining.formatted()) kcal left today."
        }
        return "You've already closed today's move target."
    }

    private var aiInsightText: String {
        let stepDelta = steps - healthDataManager.yesterdayStepCount
        let proteinMessage: String
        switch proteinIntake {
        case ..<40:
            proteinMessage = "Protein intake is still a bit low today."
        case 40..<90:
            proteinMessage = "Protein intake is on track today."
        default:
            proteinMessage = "Protein intake is strong today."
        }

        if stepDelta > 0 {
            return "You're **\(stepDelta.formatted()) steps ahead** of yesterday. \(proteinMessage) Consider a 15-minute light walk after dinner."
        } else if stepDelta < 0 {
            return "You're **\(abs(stepDelta).formatted()) steps behind** yesterday. \(proteinMessage) A short evening walk could help close the gap."
        } else {
            return "Your activity is matching yesterday so far. \(proteinMessage) Keep the momentum going this evening."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    goalInsightSection
                    calorieRingSection
                    activityHistorySection
                    activityCardsSection
                    aiInsightSection
                }
                .padding(.top, 22)
                .padding(.bottom, 16)
            }
            .background(HomePalette.contentBackground.ignoresSafeArea())
        }
        .task {
            await healthDataManager.refreshIfNeeded()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(HomePalette.softIconBackground)
                        .frame(width: 38, height: 38)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HomePalette.deepGreen)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health Profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HomePalette.headerSecondaryText)
                        Text(displayName.isEmpty ? "User" : displayName)
                            .font(.system(size: 38 * 0.58, weight: .bold))
                            .foregroundStyle(HomePalette.deepGreen)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .stroke(HomePalette.softIconStroke, lineWidth: 1)
                    .background(Circle().fill(HomePalette.contentBackground))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "applewatch")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HomePalette.deepGreen)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Goal Insight
    private var goalInsightSection: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Goal Insight")
                        .font(.system(size: 18 * 0.75, weight: .bold))
                        .foregroundStyle(HomePalette.goalTitle)
                    Circle()
                        .fill(HomePalette.goalDot)
                        .frame(width: 6, height: 6)
                }
                Text(goalInsightText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HomePalette.goalBody)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(HomePalette.goalCard)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 14)
    }

    // MARK: - Calorie Ring
    private var calorieRingSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Circle()
                    .fill(HomePalette.deepGreen)
                    .frame(width: 8, height: 8)
                Text("Green Zone: Healthy Deficit")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HomePalette.deepGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(HomePalette.contentBackground)
            .overlay(
                Capsule()
                    .stroke(HomePalette.softIconStroke, lineWidth: 1.5)
            )
            .clipShape(Capsule())

            ZStack(alignment: .bottom) {
                CalorieRingView(progress: calorieRingProgress)
                    .frame(width: 312, height: 176)
                    .offset(y: 10)
                VStack(spacing: 0) {
                    Text("\(kcalRemaining)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(HomePalette.numberText)
                    Text("kcal remaining")
                        .font(.system(size: 29 * 0.52, weight: .medium))
                        .foregroundStyle(HomePalette.secondaryLabel)
                }
                .offset(y: -60)
                Circle()
                    .fill(HomePalette.contentBackground)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(HomePalette.deepGreen, lineWidth: 3)
                    }
                    .overlay {
                        Image(systemName: "person")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(HomePalette.deepGreen)
                    }
                    .offset(y: 26)
                    .zIndex(1)
            }
            .frame(height: 210)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTAKE")
                        .font(.system(size: 14 * 0.8, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(HomePalette.secondaryLabel)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(intake)")
                            .font(.system(size: 32 * 0.44, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundStyle(HomePalette.numberText)
                        Text("/\(intakeGoal)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(HomePalette.secondaryLabel)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BURNED")
                        .font(.system(size: 14 * 0.8, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(HomePalette.secondaryLabel)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(burned.formatted())")
                            .font(.system(size: 32 * 0.44, weight: .bold))
                            .foregroundStyle(HomePalette.numberText)
                        Text("/\(burnedGoal)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(HomePalette.secondaryLabel)
                    }
                }
            }
            .padding(.horizontal, 26)
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Activity History
    private var activityHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthYearTitle)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(HomePalette.secondaryLabel)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(HomePalette.iconSoftGreen)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    let isSelected = index == selectedDayIndex
                    Button {
                        selectedDayIndex = index
                    } label: {
                        VStack(spacing: 8) {
                            Text(symbol)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(isSelected ? HomePalette.calendarTextStrong : HomePalette.calendarText)
                            Text("\(weekdayDates[index])")
                                .font(.system(size: 31 * 0.58, weight: .bold))
                                .foregroundStyle(isSelected ? HomePalette.calendarTextStrong : HomePalette.calendarText)
                        }
                        .frame(width: 44, height: 68)
                        .background(isSelected ? HomePalette.goalCard : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Steps & Heart Rate Cards
    private var activityCardsSection: some View {
        HStack(spacing: 12) {
            stepsCard
            heartRateCard
        }
        .padding(.horizontal, 20)
    }

    private var stepsCard: some View {
        let pct = min(1.0, Double(steps) / Double(stepsGoal))
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HomePalette.contentBackground.opacity(0.8))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HomePalette.iconSoftGreen)
                    }
                Text("STEPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HomePalette.secondaryLabel)
            }
            Text("\(steps.formatted())")
                .font(.system(size: 39 * 0.8, weight: .bold))
                .foregroundStyle(HomePalette.numberText)
            Text("\(Int(pct * 100))% of daily goal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HomePalette.iconSoftGreen)
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(i < 4 ? HomePalette.progressTrack : HomePalette.contentBackground)
                        .frame(width: i == 4 ? 18 : 16, height: i == 4 ? 18 : 8)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(HomePalette.goalCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HomePalette.heartRed)
                    }
                Text("HEART RATE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(heartRateDisplayText)
                    .font(.system(size: 39 * 0.78, weight: .bold))
                    .foregroundColor(.white)
                Text("BPM")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
            Text("Normal Resting")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
            HeartRateMiniChart()
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(HomePalette.deepGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - AI Health Insight
    private var aiInsightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(HomePalette.deepGreen)
                Text("AI HEALTH INSIGHT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(HomePalette.deepGreen.opacity(0.95))
            }
            Text(.init(aiInsightText))
                .font(.system(size: 29 * 0.55, weight: .medium))
                .foregroundStyle(HomePalette.deepGreen.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomePalette.aiCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 14)
    }
}

// MARK: - Calorie Ring Shape
struct CalorieRingView: View {
    let progress: Double
    private let lineWidth: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let ringSize = min(geo.size.width, geo.size.height * 2) - lineWidth
            let halfHeight = ringSize / 2
            ZStack {
                ArcShape(startAngle: .degrees(0), endAngle: .degrees(180))
                    .stroke(HomePalette.ringTrack, lineWidth: lineWidth)
                    .frame(width: ringSize, height: halfHeight)
                    .offset(x: (geo.size.width - ringSize) / 2, y: lineWidth / 2 + 8)

                ArcShape(startAngle: .degrees(0), endAngle: .degrees(180 * min(progress, 1)))
                    .stroke(HomePalette.ringAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .frame(width: ringSize, height: halfHeight)
                    .offset(x: (geo.size.width - ringSize) / 2, y: lineWidth / 2 + 8)
            }
        }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height * 2) / 2
        let center = CGPoint(x: rect.midX, y: rect.minY)
        p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return p
    }
}

// MARK: - Heart Rate Mini Chart
struct HeartRateMiniChart: View {
    private let points: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.5, 0.8, 0.6, 0.5, 0.7, 0.4]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(points.count - 1)
            Path { path in
                for (i, v) in points.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h * (1 - v)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(HomePalette.heartRed, lineWidth: 2.5)
        }
    }
}

private enum HomePalette {
    static let pageBackground = Color(red: 0.92, green: 0.92, blue: 0.92)
    static let contentBackground = Color.white
    static let topTitle = Color(red: 0.82, green: 0.82, blue: 0.82)

    static let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    static let numberText = Color(red: 0.16, green: 0.20, blue: 0.30)
    static let secondaryLabel = Color(red: 0.69, green: 0.68, blue: 0.60)
    static let headerSecondaryText = Color(red: 0.76, green: 0.72, blue: 0.54)

    static let softIconBackground = Color(red: 0.96, green: 0.96, blue: 0.93)
    static let softIconStroke = Color(red: 0.92, green: 0.90, blue: 0.84)
    static let iconSoftGreen = Color(red: 0.43, green: 0.84, blue: 0.45)

    static let goalCard = Color(red: 0.84, green: 0.91, blue: 0.34)
    static let goalTitle = Color(red: 0.43, green: 0.45, blue: 0.26)
    static let goalBody = Color(red: 0.29, green: 0.32, blue: 0.20)
    static let goalDot = Color(red: 1.00, green: 0.39, blue: 0.58)

    static let ringTrack = Color(red: 0.91, green: 0.91, blue: 0.90)
    static let ringAccent = Color(red: 0.84, green: 0.90, blue: 0.30)
    static let progressTrack = Color(red: 0.87, green: 0.90, blue: 0.70)
    static let calendarText = Color(red: 0.78, green: 0.79, blue: 0.80)
    static let calendarTextStrong = Color(red: 0.63, green: 0.65, blue: 0.67)

    static let heartRed = Color(red: 0.95, green: 0.29, blue: 0.43)
    static let aiCard = Color(red: 0.54, green: 0.66, blue: 0.95)
}

#Preview {
    NavigationStack {
        DailyDashboardView()
            .environmentObject(AuthViewModel())
            .environmentObject(HealthDataManager())
    }
}
