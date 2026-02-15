//
//  DailyDashboardView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

struct DailyDashboardView: View {
    @State private var steps = 6542
    @State private var calories = 1850
    @State private var water = 6
    @State private var sleep = 7.5
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting Section
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("早上好")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("今天也要元气满满!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Main Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        DashboardCard(
                            title: "步数",
                            value: "\(steps)",
                            unit: "步",
                            icon: "figure.walk",
                            color: .blue,
                            progress: Double(steps) / 10000
                        )
                        
                        DashboardCard(
                            title: "卡路里",
                            value: "\(calories)",
                            unit: "kcal",
                            icon: "flame.fill",
                            color: .orange,
                            progress: Double(calories) / 2500
                        )
                        
                        DashboardCard(
                            title: "饮水",
                            value: "\(water)",
                            unit: "杯",
                            icon: "drop.fill",
                            color: .cyan,
                            progress: Double(water) / 8
                        )
                        
                        DashboardCard(
                            title: "睡眠",
                            value: String(format: "%.1f", sleep),
                            unit: "小时",
                            icon: "moon.fill",
                            color: .purple,
                            progress: sleep / 8
                        )
                    }
                    .padding(.horizontal)
                    
                    // Today's Goals Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今日目标")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            GoalRow(title: "完成10000步", progress: Double(steps) / 10000, color: .blue)
                            GoalRow(title: "饮水8杯", progress: Double(water) / 8, color: .cyan)
                            GoalRow(title: "睡眠8小时", progress: sleep / 8, color: .purple)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(color)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}

struct GoalRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(color)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    DailyDashboardView()
}
