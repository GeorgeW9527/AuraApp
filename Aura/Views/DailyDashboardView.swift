//
//  DailyDashboardView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

// MARK: - Theme (截图配色)
extension Color {
    static let auraGreen = Color(red: 0.204, green: 0.78, blue: 0.349)      // 主绿色
    static let auraGreenLight = Color(red: 0.91, green: 0.96, blue: 0.91)  // 浅绿背景
    static let auraGrayLight = Color(red: 0.65, green: 0.65, blue: 0.65)
    static let auraGrayDark = Color(red: 0.25, green: 0.25, blue: 0.25)
    static let auraRed = Color(red: 0.9, green: 0.25, blue: 0.25)
    static let auraYellow = Color(red: 0.99, green: 0.85, blue: 0.21)   // 蛋白质条
    static let auraPurple = Color(red: 0.58, green: 0.46, blue: 0.80) // 碳水条
}

struct DailyDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedDayIndex: Int = 3
    @State private var steps = 8432
    @State private var stepsGoal = 10000
    @State private var heartRate = 72
    @State private var intake = 760
    @State private var intakeGoal = 1220
    @State private var burned = 1200
    @State private var burnedGoal = 1800
    @State private var kcalRemaining = 500

    private let weekDays = ["MON 12", "TUE 13", "WED 14", "THU 15", "MON 12", "TUE 13", "WED 14"]
    private var displayName: String { authViewModel.userProfile?.displayName ?? "Alex Rivera" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    goalInsightSection
                    calorieRingSection
                    activityHistorySection
                    activityCardsSection
                    aiInsightSection
                }
                .padding(.bottom, 24)
            }
            .background(Color.white)
        }
    }

    // MARK: - 顶部：头像 + Health Profile + 设备
    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(white: 0.92))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(Color.auraGrayLight)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health Profile")
                            .font(.caption)
                            .foregroundColor(Color.auraGrayLight)
                        Text(displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.auraGrayDark)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .fill(Color(white: 0.92))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "applewatch")
                            .font(.title3)
                            .foregroundColor(Color.auraGrayDark)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Goal Insight 横幅
    private var goalInsightSection: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Goal Insight")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayLight)
                    Circle()
                        .fill(Color.auraRed)
                        .frame(width: 6, height: 6)
                }
                Text("Keep going to close your ring today.")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayDark)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.auraGreenLight)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - 热量环 + 剩余 kcal
    private var calorieRingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.auraGreen)
                    .frame(width: 8, height: 8)
                Text("Green Zone: Healthy Deficit")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayDark)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.auraGreenLight)
            .cornerRadius(8)

            ZStack(alignment: .bottom) {
                CalorieRingView(progress: 0.45)
                    .frame(width: 220, height: 130)
                VStack(spacing: 0) {
                    Text("\(kcalRemaining)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Color.auraGrayDark)
                    Text("kcal remaining")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayLight)
                }
                .offset(y: -20)
                Circle()
                    .fill(Color.auraGreen)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").font(.body).foregroundColor(.white))
                    .offset(y: 38)
            }
            .frame(height: 180)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTAKE")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(intake)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.auraGreen)
                        Text("/\(intakeGoal)")
                            .font(.subheadline)
                            .foregroundColor(Color.auraGrayDark)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BURNED")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(burned.formatted())")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.auraGrayDark)
                        Text("/\(burnedGoal)")
                            .font(.subheadline)
                            .foregroundColor(Color.auraGrayDark)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Activity History + 日期选择
    private var activityHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVITY HISTORY")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Text("ALL")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.auraGreen)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        let isSelected = index == selectedDayIndex
                        Button {
                            selectedDayIndex = index
                        } label: {
                            Text(day)
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? Color.auraGrayDark : Color.auraGrayLight)
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
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 步数 + 心率 卡片
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
                Image(systemName: "figure.walk")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGreen)
                Text("STEPS")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
            }
            Text("\(steps.formatted())")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.auraGrayDark)
            Text("\(Int(pct * 100))% of daily goal")
                .font(.caption)
                .foregroundColor(Color.auraGreen)
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < 3 ? Color.auraGreenLight : Color.auraGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(white: 0.96))
        .cornerRadius(14)
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.subheadline)
                    .foregroundColor(Color.auraRed)
                Text("HEART RATE")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(heartRate)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.auraGrayDark)
                Text("BPM")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
            }
            Text("Normal Resting")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
            HeartRateMiniChart()
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(white: 0.96))
        .cornerRadius(14)
    }

    // MARK: - AI Health Insight
    private var aiInsightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGreen)
                Text("AI HEALTH INSIGHT")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.auraGreen)
            }
            Text("You're **200 steps ahead** of yesterday! Your protein intake is optimal today. Consider a 15-minute light walk after dinner.")
                .font(.subheadline)
                .foregroundColor(Color.auraGrayDark)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraGreenLight)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - 半圆热量环
struct CalorieRingView: View {
    let progress: Double
    private let lineWidth: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let ringSize = min(geo.size.width, geo.size.height * 2) - lineWidth
            let halfHeight = ringSize / 2
            ZStack {
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(360))
                    .stroke(Color(white: 0.88), lineWidth: lineWidth)
                    .frame(width: ringSize, height: halfHeight)
                    .offset(x: (geo.size.width - ringSize) / 2, y: geo.size.height - halfHeight - lineWidth / 2)
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(180 + 180 * min(progress, 1)))
                    .stroke(Color.auraGreen, lineWidth: lineWidth)
                    .frame(width: ringSize, height: halfHeight)
                    .offset(x: (geo.size.width - ringSize) / 2, y: geo.size.height - halfHeight - lineWidth / 2)
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
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return p
    }
}

// MARK: - 心率迷你折线
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
            .stroke(Color.auraRed, lineWidth: 2)
        }
    }
}

#Preview {
    NavigationStack {
        DailyDashboardView()
            .environmentObject(AuthViewModel())
    }
}
