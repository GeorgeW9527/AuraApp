//
//  ContentView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("仪表盘")
                }
                .tag(0)
            
            NutritionAnalysisView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("营养分析")
                }
                .tag(1)
            
            FitnessTrackerView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("运动追踪")
                }
                .tag(2)
            
            DeviceManagementView()
                .tabItem {
                    Image(systemName: "applewatch")
                    Text("设备管理")
                }
                .tag(3)
            
            UserProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("用户中心")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
