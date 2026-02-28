//
//  SmartReportView.swift
//  Aura
//
//  Smart Report - 参考 SmartReport-Week.png / SmartReport-Month.png
//

import SwiftUI
import Charts

private let auraOrange = Color(red: 1, green: 0.6, blue: 0.2)

enum SmartReportPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct SmartReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var period: SmartReportPeriod = .week

    // 示例数据
    private let proteinPct: Double = 0.40
    private let carbsPct: Double = 0.35
    private let fatsPct: Double = 0.25
    private let weeklyAchievement: [Double] = [78, 85, 92, 98, 88, 90, 95]
    private let avgAchievement = 92
    private let monthlySuccessRate = 85
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                periodSelector
                dietaryStructureSection
                goalAchievementSection
                keyAIInsightsSection
                exportButton
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .navigationTitle("Smart Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // TODO: share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color.auraGrayDark)
                }
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(SmartReportPeriod.allCases, id: \.self) { p in
                Button {
                    period = p
                } label: {
                    Text(p.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(period == p ? Color.auraGrayDark : Color.auraGrayLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(period == p ? Color.white : Color(white: 0.94))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(white: 0.94))
        .cornerRadius(10)
        .padding(.top, 8)
    }

    // MARK: - Dietary Structure

    private var dietaryStructureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DIETARY STRUCTURE")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Text("Fat Loss Optimized")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.auraGreen)
                    .cornerRadius(12)
            }

            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Chart {
                        SectorMark(
                            angle: .value("P", proteinPct * 360),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.auraGreen)
                        SectorMark(
                            angle: .value("C", carbsPct * 360),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.auraPurple)
                        SectorMark(
                            angle: .value("F", fatsPct * 360),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(auraOrange)
                    }
                    .frame(width: 120, height: 120)

                    VStack(spacing: 2) {
                        Text("BALANCE")
                            .font(.caption2)
                            .foregroundColor(Color.auraGrayLight)
                        Text("Good")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.auraGrayDark)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    legendRow(color: Color.auraGreen, label: "Lean Protein", value: "40%")
                    legendRow(color: Color.auraPurple, label: "Fiber Carbs", value: "35%")
                    legendRow(color: auraOrange, label: "Healthy Fats", value: "25%")
                }
                Spacer()
            }
            .padding(16)
            .background(Color(white: 0.98))
            .cornerRadius(12)
        }
    }

    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(Color.auraGrayDark)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.auraGrayDark)
        }
    }

    // MARK: - Goal Achievement

    private var goalAchievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GOAL ACHIEVEMENT")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Text("Avg \(avgAchievement)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.auraGreen)
            }

            if period == .week {
                weeklyBarChart
            } else {
                monthlyCalendar
            }
        }
    }

    private var weeklyBarChart: some View {
        Chart {
            ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { i, label in
                BarMark(
                    x: .value("Day", label),
                    y: .value("Achievement", weeklyAchievement[i])
                )
                .foregroundStyle(Color.auraGreen)
            }
        }
        .frame(height: 160)
        .padding(16)
        .background(Color(white: 0.98))
        .cornerRadius(12)
    }

    private var monthlyCalendar: some View {
        let month = Date()
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f
        }()
        let weekdaySymbols = calendar.shortWeekdaySymbols

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Goal Consistency")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGrayDark)
                    Text(monthFormatter.string(from: month))
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(monthlySuccessRate)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.auraGreen)
                    Text("SUCCESS RATE")
                        .font(.caption2)
                        .foregroundColor(Color.auraGrayLight)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(String(sym.prefix(1)))
                        .font(.caption2)
                        .foregroundColor(Color.auraGrayLight)
                }
                ForEach(Array(monthCalendarDays(month).enumerated()), id: \.offset) { idx, day in
                    Group {
                        if day != nil {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.auraGreen.opacity(0.3 + Double(idx % 7) * 0.1))
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.auraGrayLight.opacity(0.4))
                    .frame(width: 12, height: 12)
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.auraGreen)
                    .frame(width: 12, height: 12)
                Text("More")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
        }
        .padding(16)
        .background(Color(white: 0.98))
        .cornerRadius(12)
    }

    private func monthCalendarDays(_ date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in range {
            if let day = calendar.date(byAdding: .day, value: d - 1, to: firstDay) {
                days.append(day)
            }
        }
        return days
    }

    // MARK: - Key AI Insights

    private var keyAIInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KEY AI INSIGHTS")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)

            insightCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color.auraGrayLight,
                iconBg: Color(white: 0.92),
                title: "Weight Trend",
                description: "You've lost ",
                highlight: "1.2kg",
                suffix: " this week. Your steady progress indicates a healthy rate of sustainable weight loss."
            )

            insightCard(
                icon: "leaf.fill",
                iconColor: Color.auraGreen,
                iconBg: Color.auraGreenLight,
                title: "Caloric Deficit",
                description: "Daily average deficit of 450 kcal maintained. This aligns perfectly with your \"Sustainable\" profile setting.",
                highlight: nil,
                suffix: nil
            )

            insightCard(
                icon: "bolt.fill",
                iconColor: auraOrange,
                iconBg: Color(red: 1, green: 0.95, blue: 0.8),
                title: "Fat Burn Efficiency",
                description: "Your metabolic rate is 8% higher during morning fasts. Continue prioritizing high-protein breakfasts to maintain this efficiency.",
                highlight: nil,
                suffix: nil
            )
        }
    }

    private func insightCard(
        icon: String,
        iconColor: Color,
        iconBg: Color,
        title: String,
        description: String,
        highlight: String?,
        suffix: String?
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconBg)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                )
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                if let h = highlight, let s = suffix {
                    (Text(description) + Text(h).foregroundColor(Color.auraGreen).fontWeight(.medium) + Text(s))
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                } else {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 0.9), lineWidth: 1)
        )
    }

    // MARK: - Export & Footer

    private var exportButton: some View {
        Button {
            // TODO: export PDF
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.fill")
                    .font(.title3)
                Text("Export PDF Report")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.auraGreen)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        Text("REPORT GENERATED BY BIOAI ENGINE")
            .font(.caption2)
            .foregroundColor(Color.auraGrayLight)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SmartReportView()
    }
}
